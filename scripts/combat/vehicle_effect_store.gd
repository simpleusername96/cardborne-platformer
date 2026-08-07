class_name VehicleEffectStore
extends RefCounted

## Fixed-capacity ownership for short-lived combat presentation state.
## Live order and retirement use the historical swap-removal contract.

const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const MAX_LIVE_EFFECTS := 96

var live: Array[VehicleEffectState] = []

var _pool: Array[VehicleEffectState] = []
var _state_instances_created := 0
var _acquisitions := 0
var _evictions := 0
var _rejected_capacity := 0


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
	}
