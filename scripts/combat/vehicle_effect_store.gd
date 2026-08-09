class_name VehicleEffectStore
extends RefCounted

## Fixed-capacity ownership for short-lived combat presentation state.
## Live order and retirement use the historical swap-removal contract.

const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const MAX_LIVE_EFFECTS := 96
const THERMAL_BURST_IMPACT_KIND := &"thermal_burst_impact"
const MAX_LIVE_THERMAL_IMPACTS := 24

var live: Array[VehicleEffectState] = []

var _pool: Array[VehicleEffectState] = []
var _state_instances_created := 0
var _acquisitions := 0
var _evictions := 0
var _rejected_capacity := 0
var _thermal_recycles := 0
var _rejected_thermal_capacity := 0


func _init() -> void:
	for _index in MAX_LIVE_EFFECTS:
		_pool.append(EffectState.new())
		_state_instances_created += 1


func add(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float,
	direction: Vector2 = Vector2.ZERO,
	value: float = 0.0,
	multiplier: float = 1.0
) -> VehicleEffectState:
	if live.size() >= MAX_LIVE_EFFECTS:
		remove_at_swap(0)
		_evictions += 1
	return _acquire_configured(
		kind, position, color, duration, radius, direction, value, multiplier
	)


func add_thermal_burst_impact(
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	## Thermal is cosmetic and may recycle only its own oldest receipt. It must
	## never displace EMP or another higher-priority transient from the store.
	var thermal_count := 0
	var oldest_thermal_index := -1
	var oldest_remaining := INF
	for index in live.size():
		var state := live[index]
		if state.kind != THERMAL_BURST_IMPACT_KIND:
			continue
		thermal_count += 1
		if state.time < oldest_remaining:
			oldest_remaining = state.time
			oldest_thermal_index = index
	if (
		thermal_count >= MAX_LIVE_THERMAL_IMPACTS
		or live.size() >= MAX_LIVE_EFFECTS
	):
		if oldest_thermal_index < 0:
			_rejected_thermal_capacity += 1
			return null
		remove_at_swap(oldest_thermal_index)
		_thermal_recycles += 1
	return _acquire_configured(
		THERMAL_BURST_IMPACT_KIND,
		position,
		color,
		duration,
		radius
	)


func _acquire_configured(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float,
	direction: Vector2 = Vector2.ZERO,
	value: float = 0.0,
	multiplier: float = 1.0
) -> VehicleEffectState:
	if _pool.is_empty():
		_rejected_capacity += 1
		return null
	var state: VehicleEffectState = _pool.pop_back()
	state.configure(
		kind,
		position,
		color,
		duration,
		radius,
		direction,
		value,
		multiplier
	)
	live.append(state)
	_acquisitions += 1
	return state


func remove_at_swap(index: int) -> void:
	var last_index := live.size() - 1
	if index < 0 or index > last_index:
		return
	var retired: VehicleEffectState = live[index]
	if index != last_index:
		live[index] = live[last_index]
	live.pop_back()
	retired.reset()
	_pool.append(retired)


func clear() -> void:
	while not live.is_empty():
		remove_at_swap(live.size() - 1)


func count_kind(kind: StringName) -> int:
	var count := 0
	for state in live:
		if state.kind == kind:
			count += 1
	return count


func validate_capacity() -> bool:
	return (
		live.size() <= MAX_LIVE_EFFECTS
		and count_kind(THERMAL_BURST_IMPACT_KIND)
			<= MAX_LIVE_THERMAL_IMPACTS
		and live.size() + _pool.size() == MAX_LIVE_EFFECTS
		and _state_instances_created == MAX_LIVE_EFFECTS
	)


func debug_snapshot() -> Dictionary:
	return {
		"live":live.size(),
		"pool":_pool.size(),
		"capacity":MAX_LIVE_EFFECTS,
		"state_instances_created":_state_instances_created,
		"acquisitions":_acquisitions,
		"evictions":_evictions,
		"rejected_capacity":_rejected_capacity,
		"thermal_live":count_kind(THERMAL_BURST_IMPACT_KIND),
		"thermal_capacity":MAX_LIVE_THERMAL_IMPACTS,
		"thermal_recycles":_thermal_recycles,
		"rejected_thermal_capacity":_rejected_thermal_capacity,
	}
