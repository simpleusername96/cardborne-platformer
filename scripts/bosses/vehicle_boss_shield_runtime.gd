class_name VehicleBossShieldRuntime
extends RefCounted

## Owns the boss-attached shield window and phase floors. Direct boss attacks
## lower the shield for one bounded focus-fire window; no external actor or
## destructible objective participates in the state transition.

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

const EXPOSED_DAMAGE_MULTIPLIER := 1.00
const SHIELD_DOWN_SECONDS := 4.0
const HINT_REPEAT_COOLDOWN := 2.0

var stage_id: StringName = &"stage_1"
var stage_index := 0
var phase := 1
var shield_up := true
var shield_down_remaining := 0.0

var _phase_history := PackedInt32Array()
var _phase_skip_count := 0
var _shield_down_windows := 0
var _shielded_time := 0.0
var _exposed_time := 0.0
var _adds_spawned := 0
var _maximum_live_adds := 0
var _pending_hint_key := ""
var _last_hint_key := ""
var _last_hint_elapsed := HINT_REPEAT_COOLDOWN


func configure(next_stage_id: StringName, starting_phase: int = 1) -> void:
	stage_id = next_stage_id
	stage_index = StageDifficulty.stage_index_from_id(stage_id)
	phase = clampi(starting_phase, 1, 3)
	shield_up = Catalog.uses_shield(stage_id)
	shield_down_remaining = 0.0
	_phase_history = PackedInt32Array([phase])
	_phase_skip_count = 0
	_shield_down_windows = 0
	_shielded_time = 0.0
	_exposed_time = 0.0
	_adds_spawned = 0
	_maximum_live_adds = 0
	_pending_hint_key = ""
	_last_hint_key = ""
	_last_hint_elapsed = HINT_REPEAT_COOLDOWN


func begin_phase(requested_phase: int = -1) -> Dictionary:
	if requested_phase >= 1:
		if requested_phase > phase + 1:
			_phase_skip_count += 1
		phase = clampi(requested_phase, 1, 3)
		if _phase_history.is_empty() or _phase_history[-1] != phase:
			_phase_history.append(phase)
	shield_up = Catalog.uses_shield(stage_id)
	shield_down_remaining = 0.0
	if shield_up:
		_queue_state_hint("BOSS_SHIELD_UP_HINT")
	return {
		"phase":phase,
		"add_roles":Catalog.add_roles(stage_id, phase),
		"tactic_id":Catalog.tactic_id(stage_id, phase),
	}


func advance(delta: float) -> void:
	var bounded_delta := maxf(0.0, delta)
	_last_hint_elapsed += bounded_delta
	if not Catalog.uses_shield(stage_id):
		return
	if shield_up:
		_shielded_time += bounded_delta
		return
	_exposed_time += bounded_delta
	shield_down_remaining = maxf(0.0, shield_down_remaining - bounded_delta)
	if shield_down_remaining <= 0.0:
		shield_up = true
		_queue_state_hint("BOSS_SHIELD_UP_HINT")


func lower_after_direct_attack() -> bool:
	if not Catalog.uses_shield(stage_id) or not shield_up:
		return false
	shield_up = false
	shield_down_remaining = SHIELD_DOWN_SECONDS
	_shield_down_windows += 1
	_queue_state_hint("BOSS_SHIELD_DOWN_HINT")
	return true


func boss_damage_multiplier() -> float:
	return (
		StageDifficulty.boss_shielded_damage_multiplier(stage_index)
		if Catalog.uses_shield(stage_id) and shield_up else EXPOSED_DAMAGE_MULTIPLIER
	)


func state() -> StringName:
	if not Catalog.uses_shield(stage_id):
		return &"none"
	return &"shield_up" if shield_up else &"shield_down"


func try_advance_phase(health: float, max_health: float) -> Dictionary:
	if phase >= 3:
		return {}
	if health > max_health * Catalog.phase_floor(phase) + 0.001:
		return {}
	var previous := phase
	phase += 1
	_phase_history.append(phase)
	return {"from":previous, "phase":phase}


func take_state_entry_hint() -> String:
	var result := _pending_hint_key
	if result.is_empty():
		return ""
	_pending_hint_key = ""
	_last_hint_key = result
	_last_hint_elapsed = 0.0
	return result


func note_adds_spawned(count: int, live_count: int) -> void:
	_adds_spawned += maxi(0, count)
	_maximum_live_adds = maxi(_maximum_live_adds, maxi(0, live_count))


func variant() -> StringName:
	return Catalog.variant(stage_id)


func snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"stage_index":stage_index,
		"variant":variant(),
		"shield_kind":Catalog.shield_kind(stage_id),
		"phase":phase,
		"phase_history":Array(_phase_history),
		"phase_skip_count":_phase_skip_count,
		"state":state(),
		"shield_up":shield_up,
		"damage_multiplier":boss_damage_multiplier(),
		"shield_down_remaining":shield_down_remaining,
		"shield_down_windows":_shield_down_windows,
		"shielded_time":_shielded_time,
		"exposed_time":_exposed_time,
		"adds_spawned":_adds_spawned,
		"maximum_live_adds":_maximum_live_adds,
	}


func _queue_state_hint(hint_key: String) -> void:
	if hint_key.is_empty() or hint_key == _pending_hint_key:
		return
	if hint_key == _last_hint_key and _last_hint_elapsed < HINT_REPEAT_COOLDOWN:
		return
	_pending_hint_key = hint_key
