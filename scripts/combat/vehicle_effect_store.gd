class_name VehicleEffectStore
extends RefCounted

## Fixed-capacity ownership for short-lived combat presentation state.
## Live order and retirement use the historical swap-removal contract.

const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const MAX_LIVE_EFFECTS := 96
const EMP_CHARGE_KIND := &"player_emp_charge"
const EMP_RELEASE_KIND := &"player_emp_release"
const THERMAL_BURST_IMPACT_KIND := &"thermal_burst_impact"
const MAX_LIVE_THERMAL_IMPACTS := 24
const DROP_MINE_DETONATION_KIND := &"drop_mine_detonation"
const MAX_LIVE_DROP_MINE_DETONATIONS := 8
const EXPLOSIVE_SEEKER_IMPACT_KIND := &"explosive_seeker_impact"
const MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS := 8
const MYSTERY_PURGE_PULSE_KIND := &"mystery_projectile_purge"
const MAX_LIVE_MYSTERY_PURGE_PULSES := 3

var live: Array[VehicleEffectState] = []

var _pool: Array[VehicleEffectState] = []
var _state_instances_created := 0
var _acquisitions := 0
var _evictions := 0
var _rejected_capacity := 0
var _thermal_recycles := 0
var _rejected_thermal_capacity := 0
var _drop_mine_recycles := 0
var _rejected_drop_mine_capacity := 0
var _explosive_seeker_recycles := 0
var _rejected_explosive_seeker_capacity := 0
var _mystery_purge_recycles := 0
var _rejected_mystery_purge_capacity := 0


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


func add_emp_footprint(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	damage_stun_radius: float,
	projectile_clear_radius: float
) -> VehicleEffectState:
	if kind != EMP_CHARGE_KIND and kind != EMP_RELEASE_KIND:
		push_error("EMP footprint requires a charge or release event kind")
		return null
	if live.size() >= MAX_LIVE_EFFECTS:
		remove_at_swap(0)
		_evictions += 1
	return _acquire_configured(
		kind,
		position,
		color,
		duration,
		damage_stun_radius,
		Vector2.ZERO,
		0.0,
		1.0,
		projectile_clear_radius
	)


func add_thermal_burst_impact(
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	## Thermal is cosmetic and may recycle only its own oldest receipt. It must
	## never displace EMP or another higher-priority transient from the store.
	return _add_bounded_cosmetic(
		THERMAL_BURST_IMPACT_KIND,
		MAX_LIVE_THERMAL_IMPACTS,
		position,
		color,
		duration,
		radius
	)


func add_drop_mine_detonation(
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	## Mine feedback is cosmetic and may recycle only another mine receipt.
	return _add_bounded_cosmetic(
		DROP_MINE_DETONATION_KIND,
		MAX_LIVE_DROP_MINE_DETONATIONS,
		position,
		color,
		duration,
		radius
	)


func add_explosive_seeker_impact(
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	## Seeker feedback is cosmetic and may recycle only another Seeker receipt.
	return _add_bounded_cosmetic(
		EXPLOSIVE_SEEKER_IMPACT_KIND,
		MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS,
		position,
		color,
		duration,
		radius
	)


func add_mystery_purge_pulse(
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	return _add_bounded_cosmetic(
		MYSTERY_PURGE_PULSE_KIND,
		MAX_LIVE_MYSTERY_PURGE_PULSES,
		position,
		color,
		duration,
		radius
	)


func _add_bounded_cosmetic(
	kind: StringName,
	max_live: int,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float
) -> VehicleEffectState:
	var kind_count := 0
	var oldest_index := -1
	var oldest_remaining := INF
	for index in live.size():
		var state := live[index]
		if state.kind != kind:
			continue
		kind_count += 1
		if state.time < oldest_remaining:
			oldest_remaining = state.time
			oldest_index = index
	if kind_count >= max_live or live.size() >= MAX_LIVE_EFFECTS:
		if oldest_index < 0:
			_note_bounded_cosmetic_rejection(kind)
			return null
		remove_at_swap(oldest_index)
		_note_bounded_cosmetic_recycle(kind)
	return _acquire_configured(kind, position, color, duration, radius)


func _note_bounded_cosmetic_recycle(kind: StringName) -> void:
	match kind:
		THERMAL_BURST_IMPACT_KIND:
			_thermal_recycles += 1
		DROP_MINE_DETONATION_KIND:
			_drop_mine_recycles += 1
		EXPLOSIVE_SEEKER_IMPACT_KIND:
			_explosive_seeker_recycles += 1
		MYSTERY_PURGE_PULSE_KIND:
			_mystery_purge_recycles += 1


func _note_bounded_cosmetic_rejection(kind: StringName) -> void:
	match kind:
		THERMAL_BURST_IMPACT_KIND:
			_rejected_thermal_capacity += 1
		DROP_MINE_DETONATION_KIND:
			_rejected_drop_mine_capacity += 1
		EXPLOSIVE_SEEKER_IMPACT_KIND:
			_rejected_explosive_seeker_capacity += 1
		MYSTERY_PURGE_PULSE_KIND:
			_rejected_mystery_purge_capacity += 1


func _acquire_configured(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float,
	direction: Vector2 = Vector2.ZERO,
	value: float = 0.0,
	multiplier: float = 1.0,
	secondary_radius: float = 0.0
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
		multiplier,
		secondary_radius
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
		and count_kind(DROP_MINE_DETONATION_KIND)
			<= MAX_LIVE_DROP_MINE_DETONATIONS
		and count_kind(EXPLOSIVE_SEEKER_IMPACT_KIND)
			<= MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS
		and count_kind(MYSTERY_PURGE_PULSE_KIND)
			<= MAX_LIVE_MYSTERY_PURGE_PULSES
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
		"drop_mine_live":count_kind(DROP_MINE_DETONATION_KIND),
		"drop_mine_capacity":MAX_LIVE_DROP_MINE_DETONATIONS,
		"drop_mine_recycles":_drop_mine_recycles,
		"rejected_drop_mine_capacity":_rejected_drop_mine_capacity,
		"explosive_seeker_live":count_kind(EXPLOSIVE_SEEKER_IMPACT_KIND),
		"explosive_seeker_capacity":MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS,
		"explosive_seeker_recycles":_explosive_seeker_recycles,
		"rejected_explosive_seeker_capacity":_rejected_explosive_seeker_capacity,
		"mystery_purge_live":count_kind(MYSTERY_PURGE_PULSE_KIND),
		"mystery_purge_capacity":MAX_LIVE_MYSTERY_PURGE_PULSES,
		"mystery_purge_recycles":_mystery_purge_recycles,
		"rejected_mystery_purge_capacity":_rejected_mystery_purge_capacity,
	}
