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
const BLOCKED_DAMAGE_MULTIPLIER := 0.10
const DRYDOCK_FRONTAL_HALF_ANGLE := deg_to_rad(55.0)
const DRYDOCK_COUNTERBURST_CHARGE_DAMAGE := 180.0
const DRYDOCK_COUNTERBURST_MAX_MULTIPLIER := 1.75
const CROWN_SECTOR_COUNT := 3
const CROWN_SECTOR_INTEGRITY := 420.0

var stage_id: StringName = &"stage_1"
var stage_index := 0
var phase := 1
var shield_up := true
var shield_down_remaining := 0.0
var drydock_counterburst_charge := 0.0
var crown_sector_integrity := PackedFloat32Array()

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
	drydock_counterburst_charge = 0.0
	crown_sector_integrity.resize(CROWN_SECTOR_COUNT)
	crown_sector_integrity.fill(CROWN_SECTOR_INTEGRITY)
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
	if Catalog.shield_kind(stage_id) == &"relay_sectors":
		crown_sector_integrity.fill(CROWN_SECTOR_INTEGRITY)
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
	if Catalog.shield_kind(stage_id) == &"relay_sectors" and _crown_sectors_broken():
		_exposed_time += bounded_delta
		return
	if shield_up:
		_shielded_time += bounded_delta
		return
	_exposed_time += bounded_delta
	shield_down_remaining = maxf(0.0, shield_down_remaining - bounded_delta)
	if shield_down_remaining <= 0.0:
		shield_up = true
		_queue_state_hint("BOSS_SHIELD_UP_HINT")


func boss_damage_multiplier(
	hit_direction: Vector2 = Vector2.ZERO,
	boss_facing: Vector2 = Vector2.RIGHT,
	incoming_damage: float = 0.0
) -> float:
	if not Catalog.uses_shield(stage_id) or not shield_up:
		return EXPOSED_DAMAGE_MULTIPLIER
	var shield_kind := Catalog.shield_kind(stage_id)
	if hit_direction.is_zero_approx():
		return EXPOSED_DAMAGE_MULTIPLIER
	var facing := boss_facing.normalized()
	if facing.is_zero_approx():
		facing = Vector2.RIGHT
	var incoming := hit_direction.normalized()
	if shield_kind == &"frontal_intercept":
		if absf(facing.angle_to(incoming)) > DRYDOCK_FRONTAL_HALF_ANGLE:
			return EXPOSED_DAMAGE_MULTIPLIER
		drydock_counterburst_charge = minf(
			DRYDOCK_COUNTERBURST_CHARGE_DAMAGE,
			drydock_counterburst_charge + maxf(0.0, incoming_damage) * (1.0 - BLOCKED_DAMAGE_MULTIPLIER)
		)
		return BLOCKED_DAMAGE_MULTIPLIER
	if shield_kind == &"relay_sectors":
		var sector := crown_sector_for_direction(incoming, facing)
		if crown_sector_integrity[sector] <= 0.0:
			return EXPOSED_DAMAGE_MULTIPLIER
		crown_sector_integrity[sector] = maxf(
			0.0,
			crown_sector_integrity[sector] - maxf(0.0, incoming_damage)
		)
		if _crown_sectors_broken():
			shield_up = false
			shield_down_remaining = SHIELD_DOWN_SECONDS
			_shield_down_windows += 1
			_queue_state_hint("BOSS_SHIELD_DOWN_HINT")
		return BLOCKED_DAMAGE_MULTIPLIER
	return EXPOSED_DAMAGE_MULTIPLIER


func consume_counterburst_multiplier() -> float:
	if Catalog.shield_kind(stage_id) != &"frontal_intercept":
		return 1.0
	var ratio := drydock_counterburst_charge / DRYDOCK_COUNTERBURST_CHARGE_DAMAGE
	drydock_counterburst_charge = 0.0
	return lerpf(1.0, DRYDOCK_COUNTERBURST_MAX_MULTIPLIER, clampf(ratio, 0.0, 1.0))


static func crown_sector_for_direction(direction: Vector2, facing: Vector2) -> int:
	var normalized_facing := facing.normalized()
	if normalized_facing.is_zero_approx():
		normalized_facing = Vector2.RIGHT
	var relative := fposmod(normalized_facing.angle_to(direction.normalized()) + PI, TAU) - PI
	return posmod(floori((relative + PI / 3.0) / (TAU / 3.0)), CROWN_SECTOR_COUNT)


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
		"drydock_counterburst_charge":drydock_counterburst_charge,
		"crown_sector_integrity":Array(crown_sector_integrity),
		"shielded_time":_shielded_time,
		"exposed_time":_exposed_time,
		"adds_spawned":_adds_spawned,
		"maximum_live_adds":_maximum_live_adds,
	}


func fill_presentation_snapshot(output: Dictionary) -> void:
	## Fixed scalar fields let the retained renderer draw body-attached defense
	## without inferring collision truth or copying mutable arrays every frame.
	output.clear()
	output["shield_kind"] = Catalog.shield_kind(stage_id)
	output["state"] = state()
	output["frontal_half_angle"] = DRYDOCK_FRONTAL_HALF_ANGLE
	for sector in CROWN_SECTOR_COUNT:
		output["sector_%d_ratio" % sector] = clampf(
			crown_sector_integrity[sector] / CROWN_SECTOR_INTEGRITY,
			0.0,
			1.0
		)


func presentation_snapshot() -> Dictionary:
	var output := {}
	fill_presentation_snapshot(output)
	return output


func _queue_state_hint(hint_key: String) -> void:
	if hint_key.is_empty() or hint_key == _pending_hint_key:
		return
	if hint_key == _last_hint_key and _last_hint_elapsed < HINT_REPEAT_COOLDOWN:
		return
	_pending_hint_key = hint_key


func _crown_sectors_broken() -> bool:
	for integrity in crown_sector_integrity:
		if integrity > 0.0:
			return false
	return true
