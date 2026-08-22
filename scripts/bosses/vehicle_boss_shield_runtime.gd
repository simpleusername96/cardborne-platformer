class_name VehicleBossShieldRuntime
extends RefCounted

## Owns every boss-attached segmented defense. Collision and presentation read
## the same rotating segment profile, so active defenses always keep real gaps
## and every profile supplies a complete focus-fire window.

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

# Compatibility constants expose the Stage 3 reference profile to focused tests
# and callers. Per-stage runtime values come from Catalog.defense_profile().
const EXPOSED_DAMAGE_MULTIPLIER := 1.00
const SHIELD_UP_SECONDS := 8.0
const SHIELD_DOWN_SECONDS := 2.0
const HINT_REPEAT_COOLDOWN := 2.0
const BLOCKED_DAMAGE_MULTIPLIER := 0.15
const SHIELD_SEGMENT_COUNT := 3
const SHIELD_SEGMENT_ARC := deg_to_rad(80.0)
const SHIELD_GAP_ARC := deg_to_rad(40.0)
const SHIELD_ROTATION_SPEED := deg_to_rad(18.0)
const COUNTERBURST_CHARGE_DAMAGE := 180.0
const COUNTERBURST_MAX_MULTIPLIER := 1.75

const STATE_NONE: StringName = &"none"
const STATE_UP: StringName = &"shield_up"
const STATE_CUE: StringName = &"shield_cue"
const STATE_DOWN: StringName = &"shield_down"

var stage_id: StringName = &"stage_1"
var stage_index := 0
var phase := 1
var shield_up := false
var shield_down_remaining := 0.0
var shield_cycle_remaining := 0.0
var shield_rotation := 0.0
var counterburst_charge := 0.0

var _defense_profile: Dictionary = {}
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
	_defense_profile = Catalog.defense_profile(stage_id)
	shield_rotation = 0.0
	counterburst_charge = 0.0
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
	_reset_defense_cycle(false)


func begin_phase(requested_phase: int = -1) -> Dictionary:
	if requested_phase >= 1:
		if requested_phase > phase + 1:
			_phase_skip_count += 1
		phase = clampi(requested_phase, 1, 3)
		if _phase_history.is_empty() or _phase_history[-1] != phase:
			_phase_history.append(phase)
	_reset_defense_cycle(true)
	return {
		"phase":phase,
		"add_roles":Catalog.squad_roles(stage_id, phase),
		"tactic_id":Catalog.squad_tactic_id(stage_id, phase),
	}


func advance(delta: float) -> void:
	var bounded_delta := maxf(0.0, delta)
	_last_hint_elapsed += bounded_delta
	if _defense_profile.is_empty():
		return
	shield_rotation = fposmod(
		shield_rotation + rotation_speed() * bounded_delta,
		TAU
	)
	shield_cycle_remaining = maxf(0.0, shield_cycle_remaining - bounded_delta)
	if shield_up:
		_shielded_time += bounded_delta
		if shield_cycle_remaining <= 0.0:
			shield_up = false
			shield_cycle_remaining = down_seconds()
			shield_down_remaining = shield_cycle_remaining
			_shield_down_windows += 1
			_queue_state_hint("BOSS_SHIELD_DOWN_HINT")
		return
	_exposed_time += bounded_delta
	shield_down_remaining = shield_cycle_remaining
	if shield_cycle_remaining <= 0.0:
		shield_up = true
		shield_cycle_remaining = active_seconds()
		shield_down_remaining = 0.0
		_queue_state_hint("BOSS_SHIELD_UP_HINT")


func boss_damage_multiplier(
	hit_direction: Vector2 = Vector2.ZERO,
	_boss_facing: Vector2 = Vector2.RIGHT,
	incoming_damage: float = 0.0
) -> float:
	if defense_effect() != &"guard" or not hits_active_segment(hit_direction):
		return EXPOSED_DAMAGE_MULTIPLIER
	var blocked_multiplier := blocked_damage_multiplier()
	counterburst_charge = minf(
		COUNTERBURST_CHARGE_DAMAGE,
		counterburst_charge
			+ maxf(0.0, incoming_damage) * (1.0 - blocked_multiplier)
	)
	return blocked_multiplier


func hits_active_segment(source_direction: Vector2) -> bool:
	if not shield_up or _defense_profile.is_empty() or source_direction.is_zero_approx():
		return false
	var period := segment_arc() + gap_arc()
	if period <= 0.0:
		return false
	# Each repeated sector starts with its real attackable gap, followed by the
	# blocking/reflecting segment. The renderer uses this same offset.
	var local_angle := fposmod(source_direction.normalized().angle() - shield_rotation, period)
	return local_angle >= gap_arc() and local_angle < period


func reflects_projectile(incoming_velocity: Vector2) -> bool:
	if defense_effect() != &"reflect" or incoming_velocity.is_zero_approx():
		return false
	return hits_active_segment(-incoming_velocity.normalized())


func reflection_normal(incoming_velocity: Vector2) -> Vector2:
	var normal := -incoming_velocity.normalized()
	return normal if not normal.is_zero_approx() else Vector2.RIGHT


func consume_counterburst_multiplier() -> float:
	if defense_effect() != &"guard":
		return 1.0
	var ratio := counterburst_charge / COUNTERBURST_CHARGE_DAMAGE
	counterburst_charge = 0.0
	return lerpf(1.0, COUNTERBURST_MAX_MULTIPLIER, clampf(ratio, 0.0, 1.0))


func state() -> StringName:
	if _defense_profile.is_empty():
		return STATE_NONE
	if shield_up:
		return STATE_UP
	if cue_seconds() > 0.0 and shield_cycle_remaining <= cue_seconds():
		return STATE_CUE
	return STATE_DOWN


func defense_effect() -> StringName:
	return StringName(_defense_profile.get("effect", &"none"))


func segment_count() -> int:
	return int(_defense_profile.get("segment_count", 0))


func segment_arc() -> float:
	return float(_defense_profile.get("segment_arc", 0.0))


func gap_arc() -> float:
	return float(_defense_profile.get("gap_arc", 0.0))


func rotation_speed() -> float:
	return float(_defense_profile.get("rotation_speed", 0.0))


func active_seconds() -> float:
	return float(_defense_profile.get("active_seconds", 0.0))


func down_seconds() -> float:
	return float(_defense_profile.get("down_seconds", 0.0))


func cue_seconds() -> float:
	return float(_defense_profile.get("cue_seconds", 0.0))


func blocked_damage_multiplier() -> float:
	return float(_defense_profile.get("blocked_damage_multiplier", 1.0))


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
		"defense_effect":defense_effect(),
		"phase":phase,
		"phase_history":Array(_phase_history),
		"phase_skip_count":_phase_skip_count,
		"state":state(),
		"shield_up":shield_up,
		"damage_multiplier":boss_damage_multiplier(),
		"shield_cycle_remaining":shield_cycle_remaining,
		"shield_down_remaining":shield_down_remaining,
		"shield_down_windows":_shield_down_windows,
		"counterburst_charge":counterburst_charge,
		"shield_rotation":shield_rotation,
		"shielded_time":_shielded_time,
		"exposed_time":_exposed_time,
		"adds_spawned":_adds_spawned,
		"maximum_live_adds":_maximum_live_adds,
	}


func fill_presentation_snapshot(output: Dictionary) -> void:
	## Fixed scalar fields let the retained renderer draw collision-identical
	## body-attached defense without inferring target or facing state.
	output.clear()
	output["shield_kind"] = Catalog.shield_kind(stage_id)
	output["effect"] = defense_effect()
	output["state"] = state()
	output["segment_count"] = segment_count()
	output["segment_arc"] = segment_arc()
	output["gap_arc"] = gap_arc()
	output["rotation"] = shield_rotation
	output["active_seconds"] = active_seconds()
	output["down_seconds"] = down_seconds()
	output["cue_seconds"] = cue_seconds()
	output["cycle_remaining"] = shield_cycle_remaining


func presentation_snapshot() -> Dictionary:
	var output := {}
	fill_presentation_snapshot(output)
	return output


func _reset_defense_cycle(queue_hint: bool) -> void:
	if _defense_profile.is_empty():
		shield_up = false
		shield_cycle_remaining = 0.0
		shield_down_remaining = 0.0
		return
	shield_up = bool(_defense_profile.get("starts_active", true))
	shield_cycle_remaining = active_seconds() if shield_up else down_seconds()
	shield_down_remaining = 0.0 if shield_up else shield_cycle_remaining
	if queue_hint:
		_queue_state_hint(
			"BOSS_SHIELD_UP_HINT" if shield_up else "BOSS_SHIELD_DOWN_HINT"
		)


func _queue_state_hint(hint_key: String) -> void:
	if hint_key.is_empty() or hint_key == _pending_hint_key:
		return
	if hint_key == _last_hint_key and _last_hint_elapsed < HINT_REPEAT_COOLDOWN:
		return
	_pending_hint_key = hint_key
