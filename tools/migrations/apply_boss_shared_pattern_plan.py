#!/usr/bin/env python3
"""Apply the active shared-boss-pattern ExecPlan to the current branch.

This is a one-shot, idempotent branch migration. It preserves compatibility APIs
used by older validators while moving the live encounter to the new progression
catalog and defense runtime.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8", newline="\n")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count == 0 and new in text:
        return text
    if count != 1:
        raise RuntimeError(f"{label}: expected one exact match, found {count}")
    return text.replace(old, new, 1)


def replace_regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE | re.DOTALL)
    if count == 0 and re.search(replacement if replacement.startswith("(?") else r"a\A", text):
        return text
    if count != 1:
        raise RuntimeError(f"{label}: expected one regex match, found {count}")
    return updated


PROGRESSION_CATALOG = r'''class_name VehicleBossProgressionCatalog
extends RefCounted

## Defines the cumulative common boss language used by the live encounter.
## Legacy authored stage sequences remain available for compatibility reports.

const BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")

const COMMON_CHARGE: StringName = &"common_charge"
const COMMON_LANE_VOLLEY: StringName = &"common_lane_volley"
const COMMON_BROAD_BARRAGE: StringName = &"common_broad_barrage"
const COMMON_RADIAL_BOMBARDMENT: StringName = &"common_radial_bombardment"
const COMMON_PARALLEL_BEAM: StringName = &"common_parallel_beam"
const COMMON_X_BEAM: StringName = &"common_x_beam"
const COMMON_SQUAD_CALL: StringName = &"common_squad_call"

const COMMON_FAMILIES: Array[StringName] = [
	COMMON_CHARGE,
	COMMON_LANE_VOLLEY,
	COMMON_BROAD_BARRAGE,
	COMMON_RADIAL_BOMBARDMENT,
	COMMON_PARALLEL_BEAM,
	COMMON_X_BEAM,
	COMMON_SQUAD_CALL,
]
const STAGE_ONE_ATTACKS: Array[StringName] = [
	COMMON_CHARGE,
	COMMON_LANE_VOLLEY,
	COMMON_BROAD_BARRAGE,
	COMMON_RADIAL_BOMBARDMENT,
]
const COMPLETE_COMMON_ATTACKS: Array[StringName] = [
	COMMON_CHARGE,
	COMMON_LANE_VOLLEY,
	COMMON_BROAD_BARRAGE,
	COMMON_RADIAL_BOMBARDMENT,
	COMMON_PARALLEL_BEAM,
	COMMON_X_BEAM,
]

const SIGNATURE_PATTERNS := {
	&"stage_1": [],
	&"stage_2": [],
	&"stage_3": [&"shield_counterburst"],
	&"stage_4": [&"switch_sweep"],
	&"stage_5": [&"carrier_wave"],
	&"stage_6": [&"long_bank_barrage"],
	&"stage_7": [&"crossing_weave_a", &"crossing_weave_b"],
	&"stage_8": [&"radial_volley_a", &"radial_volley_b"],
	&"stage_9": [
		&"compression_single", &"compression_shift",
		&"compression_pair", &"compression_reverse",
	],
	# Stages 10-12 are distinguished by reflection, resonance, and overload
	# states while continuing to use the complete common attack language.
	&"stage_10": [],
	&"stage_11": [],
	&"stage_12": [],
}

const SQUAD_INTERVAL_SECONDS := 10.0
const COMMON_ATTACKS_BEFORE_SIGNATURE := 2


static func common_attacks(stage_id: StringName) -> Array[StringName]:
	if stage_id == &"stage_1":
		return STAGE_ONE_ATTACKS.duplicate()
	return COMPLETE_COMMON_ATTACKS.duplicate()


static func common_families(stage_id: StringName) -> Array[StringName]:
	var result := common_attacks(stage_id)
	result.append(COMMON_SQUAD_CALL)
	return result


static func signature_patterns(stage_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for pattern in Array(SIGNATURE_PATTERNS.get(stage_id, [])):
		result.append(StringName(pattern))
	return result


static func is_common(pattern_id: StringName) -> bool:
	return pattern_id in COMMON_FAMILIES


static func is_signature(stage_id: StringName, pattern_id: StringName) -> bool:
	return pattern_id in signature_patterns(stage_id)


static func squad_roles(stage_id: StringName, phase: int) -> Array[StringName]:
	var roles := BossPhaseCatalog.add_roles(stage_id, phase)
	if roles.is_empty():
		roles = BossPhaseCatalog.add_roles(stage_id, 2)
	return roles


static func squad_tactic(stage_id: StringName, phase: int) -> StringName:
	var tactic := BossPhaseCatalog.tactic_id(stage_id, phase)
	if tactic.is_empty():
		tactic = BossPhaseCatalog.tactic_id(stage_id, 2)
	return tactic


static func commit_startup_seconds(
	pattern_id: StringName,
	kind: StringName,
	authored_seconds: float
) -> float:
	# Fast attacks capture once, pause only briefly, then commit. Broad attacks
	# retain their authored warnings because their coverage is harder to escape.
	match kind:
		&"lanes", &"fan", &"cross":
			return minf(authored_seconds, 0.18)
		&"broad_barrage", &"long_banks":
			return minf(authored_seconds, 0.22)
		&"charge":
			return minf(authored_seconds, 0.28)
	return authored_seconds
'''


PROJECTILE_STATE = r'''class_name VehicleProjectileState
extends RefCounted

## Reusable hot-path projectile state. Every field is initialized on acquire so
## pooled objects never carry behavior from a previous shot.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var pos := Vector2.ZERO
var spawn_origin := Vector2.ZERO
var velocity := Vector2.ZERO
var radius := 5.0
var damage := 0.0
var structure_damage := 0.0
var life := 0.0
var color := Color.WHITE
var owner := ""
var pierce := 0
var bounces := 0
var homing := false
var target_id := ""
var explosive := false
var reflected := false
var final_damage := false
var wall_piercing := false
var affinity: StringName = AttackContract.KINETIC
var threat_tier: StringName = AttackContract.THREAT_ORDINARY
var condition_mask := 0
var primary_payload: VehiclePrimaryPayloadProfile
var team: StringName = &""
var spawn_serial := 0
var combat_action_family: StringName = &""
var combat_action_serial := 0
var uses_boss_reserve := false
var facility_hit_mask := 0
var distance_growth_kind: StringName = &""
var distance_traveled := 0.0
var distance_growth_ratio := 0.0
var distance_growth_base_speed := 0.0
var distance_growth_base_radius := 0.0
var distance_growth_base_damage := 0.0
var proximity_armed := false
var detonation_resolved := false
var applies_player_slow := false
var player_slow_duration := 0.0

# The legacy kind is retained for ordinary-enemy compatibility. Stage 6 uses a
# dedicated kind that starts at normal projectile speed and adds proximity fuse.
const DISTANCE_GROWTH_GROWTH_KIND: StringName = &"distance_growth"
const BOSS_DISTANCE_GROWTH_KIND: StringName = &"boss_distance_growth"
const DISTANCE_GROWTH_ARM_DISTANCE := 360.0
const DISTANCE_GROWTH_CAP_DISTANCE := 880.0
const DISTANCE_GROWTH_SPEED_SCALE := Vector2(0.75, 1.35)
const BOSS_DISTANCE_GROWTH_SPEED_SCALE := Vector2(1.0, 1.35)
const DISTANCE_GROWTH_RADIUS_SCALE := Vector2(1.0, 1.5)
const DISTANCE_GROWTH_DAMAGE_SCALE := Vector2(1.0, 1.6)
const BOSS_PROXIMITY_ARM_DISTANCE := 720.0
const BOSS_PROXIMITY_TRIGGER_RADIUS := 96.0
const BOSS_PROXIMITY_EXPLOSION_RADIUS := 132.0


func configure(
	spec: Dictionary,
	team_value: StringName,
	serial: int,
	boss_reserve: bool = false
) -> void:
	pos = Vector2(spec.get("pos", Vector2.ZERO))
	spawn_origin = Vector2(spec.get("spawn_origin", pos))
	velocity = Vector2(spec.get("velocity", Vector2.ZERO))
	radius = float(spec.get("radius", 5.0))
	damage = float(spec.get("damage", 0.0))
	structure_damage = float(spec.get("structure_damage", damage))
	life = float(spec.get("life", 0.0))
	color = Color(spec.get("color", Color.WHITE))
	owner = String(spec.get("owner", ""))
	pierce = int(spec.get("pierce", 0))
	bounces = int(spec.get("bounces", 0))
	homing = bool(spec.get("homing", false))
	target_id = String(spec.get("target_id", ""))
	explosive = bool(spec.get("explosive", false))
	reflected = bool(spec.get("reflected", false))
	final_damage = bool(spec.get("final_damage", false))
	wall_piercing = bool(spec.get("wall_piercing", false))
	affinity = AttackContract.normalize_affinity(StringName(spec.get("affinity", AttackContract.KINETIC)))
	threat_tier = AttackContract.normalize_threat_tier(
		StringName(spec.get("threat_tier", AttackContract.THREAT_ORDINARY))
	)
	condition_mask = int(spec.get("condition_mask", 0)) & AttackContract.CONDITION_MASK
	primary_payload = spec.get("primary_payload") as VehiclePrimaryPayloadProfile
	team = team_value
	spawn_serial = serial
	combat_action_family = StringName(spec.get("combat_action_family", &""))
	combat_action_serial = int(spec.get("combat_action_serial", 0))
	uses_boss_reserve = boss_reserve
	facility_hit_mask = 0
	distance_growth_kind = StringName(spec.get("distance_growth_kind", &""))
	distance_traveled = 0.0
	distance_growth_ratio = 0.0
	distance_growth_base_speed = velocity.length()
	distance_growth_base_radius = radius
	distance_growth_base_damage = damage
	proximity_armed = false
	detonation_resolved = false
	applies_player_slow = bool(spec.get("applies_player_slow", false))
	player_slow_duration = maxf(0.0, float(spec.get("player_slow_duration", 0.0)))
	_apply_distance_growth()


func uses_distance_growth() -> bool:
	return distance_growth_kind in [
		DISTANCE_GROWTH_GROWTH_KIND,
		BOSS_DISTANCE_GROWTH_KIND,
	]


func advance_distance_growth(step_distance: float) -> void:
	if not uses_distance_growth():
		return
	distance_traveled = maxf(0.0, distance_traveled + maxf(0.0, step_distance))
	_apply_distance_growth()
	if distance_growth_kind == BOSS_DISTANCE_GROWTH_KIND:
		proximity_armed = distance_traveled >= BOSS_PROXIMITY_ARM_DISTANCE


func should_proximity_detonate(
	player_position: Vector2,
	player_radius: float = 0.0
) -> bool:
	return (
		distance_growth_kind == BOSS_DISTANCE_GROWTH_KIND
		and proximity_armed
		and not detonation_resolved
		and pos.distance_to(player_position)
			<= BOSS_PROXIMITY_TRIGGER_RADIUS + maxf(0.0, player_radius)
	)


func consume_detonation() -> bool:
	if detonation_resolved:
		return false
	detonation_resolved = true
	return true


func _apply_distance_growth() -> void:
	if not uses_distance_growth():
		return
	distance_growth_ratio = clampf(
		(distance_traveled - DISTANCE_GROWTH_ARM_DISTANCE)
			/ (DISTANCE_GROWTH_CAP_DISTANCE - DISTANCE_GROWTH_ARM_DISTANCE),
		0.0,
		1.0
	)
	var direction := velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var speed_scale := (
		BOSS_DISTANCE_GROWTH_SPEED_SCALE
		if distance_growth_kind == BOSS_DISTANCE_GROWTH_KIND
		else DISTANCE_GROWTH_SPEED_SCALE
	)
	velocity = direction * distance_growth_base_speed * lerpf(
		speed_scale.x, speed_scale.y, distance_growth_ratio
	)
	radius = distance_growth_base_radius * lerpf(
		DISTANCE_GROWTH_RADIUS_SCALE.x, DISTANCE_GROWTH_RADIUS_SCALE.y, distance_growth_ratio
	)
	damage = distance_growth_base_damage * lerpf(
		DISTANCE_GROWTH_DAMAGE_SCALE.x, DISTANCE_GROWTH_DAMAGE_SCALE.y, distance_growth_ratio
	)
'''


SHIELD_RUNTIME = r'''class_name VehicleBossShieldRuntime
extends RefCounted

## Owns every boss-attached segmented defense. Collision and presentation share
## one angular profile, and every defense has attackable gaps plus a full down window.

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

const EXPOSED_DAMAGE_MULTIPLIER := 1.00
const HINT_REPEAT_COOLDOWN := 2.0
const COUNTERBURST_CHARGE_DAMAGE := 180.0
const COUNTERBURST_MAX_MULTIPLIER := 1.75
const REFLECT_DAMAGE_SCALE := 0.35
const REFLECT_DAMAGE_CAP := 24.0

const DEFENSE_PROFILES := {
	&"stage_3": {
		"shield_kind":&"frontal_intercept",
		"effect":&"absorb",
		"segment_count":3,
		"segment_arc":deg_to_rad(80.0),
		"gap_arc":deg_to_rad(40.0),
		"rotation_speed":deg_to_rad(18.0),
		"active_seconds":8.0,
		"down_seconds":2.0,
		"cue_seconds":0.0,
		"starts_active":true,
		"blocked_damage_multiplier":0.15,
	},
	&"stage_10": {
		"shield_kind":&"segmented_reflect",
		"effect":&"reflect",
		"segment_count":3,
		"segment_arc":deg_to_rad(70.0),
		"gap_arc":deg_to_rad(50.0),
		"rotation_speed":deg_to_rad(18.0),
		"active_seconds":5.0,
		"down_seconds":15.0,
		"cue_seconds":1.0,
		"starts_active":false,
		"blocked_damage_multiplier":1.0,
	},
}

var stage_id: StringName = &"stage_1"
var stage_index := 0
var phase := 1
var shield_up := false
var shield_down_remaining := 0.0
var shield_cycle_remaining := 0.0
var shield_rotation := 0.0
var counterburst_charge := 0.0
var _cue_active := false
var _profile: Dictionary = {}

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
	_profile = Dictionary(DEFENSE_PROFILES.get(stage_id, {})).duplicate(true)
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
	_reset_cycle()


func begin_phase(requested_phase: int = -1) -> Dictionary:
	if requested_phase >= 1:
		if requested_phase > phase + 1:
			_phase_skip_count += 1
		phase = clampi(requested_phase, 1, 3)
		if _phase_history.is_empty() or _phase_history[-1] != phase:
			_phase_history.append(phase)
	_reset_cycle()
	if shield_up:
		_queue_state_hint("BOSS_SHIELD_UP_HINT")
	return {
		"phase":phase,
		"add_roles":Catalog.add_roles(stage_id, phase),
		"tactic_id":Catalog.tactic_id(stage_id, phase),
	}


func _reset_cycle() -> void:
	if _profile.is_empty():
		shield_up = false
		_cue_active = false
		shield_cycle_remaining = 0.0
		shield_down_remaining = 0.0
		return
	shield_up = bool(_profile.get("starts_active", false))
	_cue_active = false
	shield_cycle_remaining = (
		float(_profile["active_seconds"])
		if shield_up else float(_profile["down_seconds"])
	)
	shield_down_remaining = 0.0 if shield_up else shield_cycle_remaining


func advance(delta: float) -> void:
	var bounded_delta := maxf(0.0, delta)
	_last_hint_elapsed += bounded_delta
	if _profile.is_empty():
		return
	shield_rotation = fposmod(
		shield_rotation + float(_profile["rotation_speed"]) * bounded_delta,
		TAU
	)
	shield_cycle_remaining = maxf(0.0, shield_cycle_remaining - bounded_delta)
	if shield_up:
		_shielded_time += bounded_delta
		if shield_cycle_remaining <= 0.0:
			shield_up = false
			_cue_active = false
			shield_cycle_remaining = float(_profile["down_seconds"])
			shield_down_remaining = shield_cycle_remaining
			_shield_down_windows += 1
			_queue_state_hint("BOSS_SHIELD_DOWN_HINT")
		return
	_exposed_time += bounded_delta
	shield_down_remaining = shield_cycle_remaining
	_cue_active = (
		float(_profile.get("cue_seconds", 0.0)) > 0.0
		and shield_cycle_remaining <= float(_profile["cue_seconds"])
	)
	if shield_cycle_remaining <= 0.0:
		shield_up = true
		_cue_active = false
		shield_down_remaining = 0.0
		shield_cycle_remaining = float(_profile["active_seconds"])
		_queue_state_hint("BOSS_SHIELD_UP_HINT")


func uses_defense() -> bool:
	return not _profile.is_empty()


func collision_active() -> bool:
	return uses_defense() and shield_up


func cue_active() -> bool:
	return uses_defense() and _cue_active


func _hits_segment(hit_direction: Vector2) -> bool:
	if hit_direction.is_zero_approx() or _profile.is_empty():
		return false
	var count := maxi(1, int(_profile["segment_count"]))
	var sector_arc := TAU / float(count)
	var local_angle := fposmod(
		hit_direction.normalized().angle() - shield_rotation,
		sector_arc
	)
	var gap_arc := float(_profile["gap_arc"])
	var segment_arc := float(_profile["segment_arc"])
	return local_angle >= gap_arc and local_angle < gap_arc + segment_arc


func boss_damage_multiplier(
	hit_direction: Vector2 = Vector2.ZERO,
	_boss_facing: Vector2 = Vector2.RIGHT,
	incoming_damage: float = 0.0
) -> float:
	if (
		not collision_active()
		or StringName(_profile.get("effect", &"")) != &"absorb"
		or not _hits_segment(hit_direction)
	):
		return EXPOSED_DAMAGE_MULTIPLIER
	var blocked_multiplier := float(_profile["blocked_damage_multiplier"])
	counterburst_charge = minf(
		COUNTERBURST_CHARGE_DAMAGE,
		counterburst_charge + maxf(0.0, incoming_damage) * (1.0 - blocked_multiplier)
	)
	return blocked_multiplier


func reflects_projectile(hit_direction: Vector2) -> bool:
	return (
		collision_active()
		and StringName(_profile.get("effect", &"")) == &"reflect"
		and _hits_segment(hit_direction)
	)


func reflection_normal(hit_direction: Vector2) -> Vector2:
	var normal := hit_direction.normalized()
	return normal if not normal.is_zero_approx() else Vector2.RIGHT


func reflected_damage(original_damage: float) -> float:
	return minf(REFLECT_DAMAGE_CAP, maxf(0.0, original_damage) * REFLECT_DAMAGE_SCALE)


func consume_counterburst_multiplier() -> float:
	if StringName(_profile.get("effect", &"")) != &"absorb":
		return 1.0
	var ratio := counterburst_charge / COUNTERBURST_CHARGE_DAMAGE
	counterburst_charge = 0.0
	return lerpf(1.0, COUNTERBURST_MAX_MULTIPLIER, clampf(ratio, 0.0, 1.0))


func state() -> StringName:
	if not uses_defense():
		return &"none"
	# Cue segments are visible but do not yet own collision.
	return &"shield_up" if shield_up or _cue_active else &"shield_down"


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
		"shield_kind":StringName(_profile.get("shield_kind", &"none")),
		"effect":StringName(_profile.get("effect", &"none")),
		"phase":phase,
		"phase_history":Array(_phase_history),
		"phase_skip_count":_phase_skip_count,
		"state":state(),
		"shield_up":shield_up,
		"collision_active":collision_active(),
		"cue_active":cue_active(),
		"damage_multiplier":boss_damage_multiplier(),
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
	output.clear()
	output["shield_kind"] = StringName(_profile.get("shield_kind", &"none"))
	output["effect"] = StringName(_profile.get("effect", &"none"))
	output["state"] = state()
	output["collision_active"] = collision_active()
	output["cue_active"] = cue_active()
	output["segment_count"] = int(_profile.get("segment_count", 0))
	output["segment_arc"] = float(_profile.get("segment_arc", 0.0))
	output["gap_arc"] = float(_profile.get("gap_arc", 0.0))
	output["rotation"] = shield_rotation
	output["alpha"] = 0.19 if cue_active() and not collision_active() else 0.38


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
'''


FOCUSED_VALIDATOR = r'''extends SceneTree

const Progression = preload("res://scripts/bosses/vehicle_boss_progression_catalog.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const LateBossMechanics = preload("res://scripts/bosses/vehicle_late_boss_mechanics.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_expect(Progression.common_attacks(&"stage_1").size() == 4, "Stage 1 teaches four direct common attacks")
	_expect(Progression.common_families(&"stage_1").size() == 5, "Stage 1 also teaches the periodic squad call")
	_expect(Progression.common_attacks(&"stage_2").size() == 6, "Stage 2 adds both beam families")
	for stage_number in range(4, 13):
		var stage_id := StringName("stage_%d" % stage_number)
		_expect(Progression.common_attacks(stage_id).size() == 6, "%s retains every direct common attack" % stage_id)
		for signature in Progression.signature_patterns(stage_id):
			_expect(not Progression.is_common(signature), "%s keeps common and signature IDs separate" % signature)

	_expect(
		is_equal_approx(Progression.commit_startup_seconds(&"x", &"lanes", 1.0), 0.18)
		and is_equal_approx(Progression.commit_startup_seconds(&"x", &"broad_barrage", 1.0), 0.22)
		and is_equal_approx(Progression.commit_startup_seconds(&"x", &"charge", 1.0), 0.28),
		"projectiles and charges use brief committed reads"
	)
	_expect(
		is_equal_approx(Progression.commit_startup_seconds(&"x", &"beam", 1.0), 1.0)
		and is_equal_approx(Progression.commit_startup_seconds(&"x", &"area", 1.0), 1.0),
		"broad attacks retain authored warnings"
	)
	for pattern in Progression.COMPLETE_COMMON_ATTACKS:
		_expect(not Patterns.definition(String(pattern)).is_empty(), "%s resolves a common pattern definition" % pattern)

	var projectile := ProjectileState.new()
	projectile.configure({
		"pos":Vector2.ZERO,
		"velocity":Vector2(520.0, 0.0),
		"radius":8.0,
		"damage":16.0,
		"life":5.0,
		"distance_growth_kind":ProjectileState.BOSS_DISTANCE_GROWTH_KIND,
	}, &"enemy", 1, true)
	_expect(is_equal_approx(projectile.velocity.length(), 520.0), "Stage 6 starts at normal projectile speed")
	_expect(is_equal_approx(projectile.radius, 8.0) and is_equal_approx(projectile.damage, 16.0), "Stage 6 starts at normal size and damage")
	projectile.advance_distance_growth(720.0)
	_expect(projectile.proximity_armed, "Stage 6 arms after the authored travel distance")
	_expect(projectile.velocity.length() > 520.0 and projectile.radius > 8.0 and projectile.damage > 16.0, "Stage 6 grows speed, size, and damage")
	projectile.pos = Vector2(80.0, 0.0)
	_expect(projectile.should_proximity_detonate(Vector2.ZERO, 24.0), "Stage 6 can detonate without body contact")
	_expect(projectile.consume_detonation() and not projectile.consume_detonation(), "Stage 6 has one detonation path")

	var shield := ShieldRuntime.new()
	shield.configure(&"stage_3")
	_expect(shield.collision_active(), "Stage 3 starts with active segmented defense")
	_expect(is_equal_approx(shield.boss_damage_multiplier(Vector2.RIGHT, Vector2.RIGHT, 100.0), 1.0), "Stage 3 exposes a real angular gap")
	var segment_direction := Vector2.RIGHT.rotated(deg_to_rad(60.0))
	_expect(is_equal_approx(shield.boss_damage_multiplier(segment_direction, Vector2.RIGHT, 100.0), 0.15), "Stage 3 segment retains reduced damage")
	shield.advance(8.01)
	_expect(not shield.collision_active(), "Stage 3 provides a complete down window")

	shield.configure(&"stage_10")
	_expect(not shield.collision_active(), "Stage 10 starts fully exposed")
	shield.advance(14.1)
	_expect(shield.cue_active() and not shield.collision_active(), "Stage 10 cues before reflection activates")
	shield.advance(0.91)
	_expect(shield.collision_active(), "Stage 10 reflection becomes active after the exposed window")
	_expect(not shield.reflects_projectile(Vector2.RIGHT), "Stage 10 retains attackable gaps")
	_expect(shield.reflects_projectile(segment_direction), "Stage 10 reflects only on a live segment")
	shield.advance(5.01)
	_expect(not shield.collision_active(), "Stage 10 returns to a complete down window")

	_expect(
		is_equal_approx(LateBossMechanics.STAGE_7_WALL_SPEED_SCALE, 0.70)
		and is_equal_approx(LateBossMechanics.STAGE_7_WALL_DAMAGE_SCALE, 0.70)
		and is_equal_approx(LateBossMechanics.STAGE_9_WALL_SPEED_SCALE, 0.70)
		and is_equal_approx(LateBossMechanics.STAGE_9_WALL_DAMAGE_SCALE, 0.70),
		"Stage 7 and Stage 9 wall speed and damage scales are exactly seventy percent"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_SHARED_PATTERN_DEFENSE_RULES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
'''


def patch_patterns() -> None:
    path = "scripts/bosses/vehicle_boss_patterns.gd"
    text = read(path)
    if '&"common_lane_volley"' not in text:
        block = '''\t&"common_lane_volley": {"kind": &"lanes", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.18, "active": 0.54, "recovery": 0.62, "damage": 14.0},\n\t&"common_radial_bombardment": {"kind": &"area", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 1.10, "active": 0.60, "recovery": 0.95, "damage": 26.0, "radius": 220.0},\n\t&"common_parallel_beam": {"kind": &"cross_corridors", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.95, "active": 0.72, "recovery": 0.95, "damage": 26.0, "width": 72.0},\n\t&"common_x_beam": {"kind": &"cross_corridors", "commit_mode": &"committed", "affinity": &"arc", "startup": 1.05, "active": 0.72, "recovery": 0.95, "damage": 28.0, "width": 76.0},\n'''
        text = replace_once(text, "const EXTRA_PATTERNS := {\n", "const EXTRA_PATTERNS := {\n" + block, "insert common pattern definitions")
    text = re.sub(r'(&"common_charge": \{[^\n]*"startup": )1\.30', r'\g<1>0.28', text, count=1)
    text = re.sub(r'(&"common_broad_barrage": \{[^\n]*"startup": )1\.30', r'\g<1>0.22', text, count=1)
    write(path, text)


def patch_runtime() -> None:
    path = "scripts/bosses/vehicle_boss_runtime.gd"
    text = read(path)
    if "VehicleBossProgressionCatalog" not in text:
        text = replace_once(
            text,
            'const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")\n',
            'const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")\nconst Progression = preload("res://scripts/bosses/vehicle_boss_progression_catalog.gd")\nconst BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")\n',
            "runtime progression preload",
        )
    if "var common_pattern_index" not in text:
        text = replace_once(
            text,
            "var finite_summons_remaining := 6\n",
            "var finite_summons_remaining := 6\nvar common_pattern_index := 0\nvar signature_pattern_index := 0\nvar common_attacks_since_signature := 0\nvar squad_timer := Progression.SQUAD_INTERVAL_SECONDS\nvar squad_serial := 0\n",
            "runtime progression fields",
        )
    if "common_pattern_index = 0" not in text:
        text = replace_once(
            text,
            "\tfinite_summons_remaining = 6\n\t_pending_radial_volleys.clear()\n",
            "\tfinite_summons_remaining = 6\n\tcommon_pattern_index = 0\n\tsignature_pattern_index = 0\n\tcommon_attacks_since_signature = 0\n\tsquad_timer = Progression.SQUAD_INTERVAL_SECONDS\n\tsquad_serial = 0\n\t_pending_radial_volleys.clear()\n",
            "runtime progression reset",
        )
    if "func select_progression_attack" not in text:
        marker = "\n\nfunc advance_direct_phase(\n"
        block = r'''

func select_progression_attack(boss: VehicleEnemyState) -> String:
	var common := Progression.common_attacks(stage_id)
	var signatures := Progression.signature_patterns(stage_id)
	var use_signature := (
		not signatures.is_empty()
		and common_attacks_since_signature
			>= Progression.COMMON_ATTACKS_BEFORE_SIGNATURE
	)
	var candidate := ""
	if use_signature:
		candidate = String(signatures[signature_pattern_index % signatures.size()])
		signature_pattern_index += 1
		common_attacks_since_signature = 0
	elif not common.is_empty():
		candidate = String(common[common_pattern_index % common.size()])
		common_pattern_index += 1
		common_attacks_since_signature += 1
	elif not signatures.is_empty():
		candidate = String(signatures[signature_pattern_index % signatures.size()])
		signature_pattern_index += 1
	if candidate == String(boss.last_pattern):
		if use_signature and signatures.size() > 1:
			candidate = String(signatures[signature_pattern_index % signatures.size()])
			signature_pattern_index += 1
		elif common.size() > 1:
			candidate = String(common[common_pattern_index % common.size()])
			common_pattern_index += 1
	boss.pattern_index += 1
	return candidate
'''
        text = replace_once(text, marker, block + marker, "insert live progression selector")
    if "func advance_progression_systems" not in text:
        marker = "\n\nfunc snapshot() -> Dictionary:\n"
        block = r'''

func advance_progression_systems(
	delta: float,
	boss: VehicleEnemyState,
	player_position: Vector2
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	squad_timer -= maxf(0.0, delta)
	if squad_timer <= 0.0:
		var major_signature_active := (
			boss.phase in [&"boss_startup", &"boss_active"]
			and Progression.is_signature(stage_id, StringName(boss.pattern))
		)
		if major_signature_active:
			squad_timer = 0.25
		else:
			squad_serial += 1
			squad_timer = Progression.SQUAD_INTERVAL_SECONDS
			events.append({
				"id":"boss_squad_%d" % squad_serial,
				"pattern":String(Progression.COMMON_SQUAD_CALL),
				"kind":&"squad",
				"boss_id":boss.id,
				"roles":Progression.squad_roles(stage_id, boss.boss_phase),
				"tactic_id":Progression.squad_tactic(stage_id, boss.boss_phase),
				"commit_mode":&"autonomous",
			})
	for event in advance_autonomous(delta, boss, player_position):
		# Stage 6 owns one distance-growth volley scheduler. The legacy autonomous
		# alias stays queryable for compatibility, but the live encounter skips it.
		if (
			stage_id == &"stage_6"
			and String(event.get("pattern", "")) == "long_bank_barrage"
		):
			continue
		events.append(event)
	return events
'''
        text = replace_once(text, marker, block + marker, "insert progression systems")
    if '"common_pattern_index":common_pattern_index' not in text:
        text = replace_once(
            text,
            '\t\t"finite_summons_remaining":finite_summons_remaining,\n',
            '\t\t"finite_summons_remaining":finite_summons_remaining,\n\t\t"common_pattern_index":common_pattern_index,\n\t\t"signature_pattern_index":signature_pattern_index,\n\t\t"common_attacks_since_signature":common_attacks_since_signature,\n\t\t"squad_timer":squad_timer,\n',
            "runtime snapshot progression",
        )
    write(path, text)


def patch_late_mechanics() -> None:
    path = "scripts/bosses/vehicle_late_boss_mechanics.gd"
    text = read(path)
    if "STAGE_7_WALL_SPEED_SCALE" not in text:
        text = replace_once(
            text,
            "const COMPRESSION_EDGE_CUE_SECONDS := 0.75\n",
            "const COMPRESSION_EDGE_CUE_SECONDS := 0.75\n\nconst STAGE_7_WALL_SPEED_SCALE := 0.70\nconst STAGE_7_WALL_DAMAGE_SCALE := 0.70\nconst STAGE_9_WALL_SPEED_SCALE := 0.70\nconst STAGE_9_WALL_DAMAGE_SCALE := 0.70\n",
            "wall scale constants",
        )
    write(path, text)


def patch_run() -> None:
    path = "scripts/vehicle/vehicle_run.gd"
    text = read(path)
    if "VehicleBossProgressionCatalog" not in text:
        text = replace_once(
            text,
            'const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")\n',
            'const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")\nconst BossProgression = preload("res://scripts/bosses/vehicle_boss_progression_catalog.gd")\n',
            "run progression preload",
        )
    text = text.replace("boss_runtime.advance_autonomous(\n", "boss_runtime.advance_progression_systems(\n", 1)
    text = text.replace("var pattern := boss_runtime.select_direct(boss)", "var pattern := boss_runtime.select_progression_attack(boss)", 1)
    old_startup = '''\tboss.phase_time = AttackContract.warned_startup_seconds(\n\t\tBossPatterns.startup_seconds(pattern, current_stage_index),\n\t\tkind\n\t)'''
    new_startup = '''\tvar authored_startup := AttackContract.warned_startup_seconds(\n\t\tBossPatterns.startup_seconds(pattern, current_stage_index),\n\t\tkind\n\t)\n\tboss.phase_time = BossProgression.commit_startup_seconds(\n\t\tStringName(pattern), kind, authored_startup\n\t)'''
    if old_startup in text:
        text = replace_once(text, old_startup, new_startup, "fast boss commitment")
    if 'if kind == &"squad":' not in text:
        marker = '''\tvar kind := StringName(event.get("kind", BossPatterns.kind(pattern)))\n'''
        addition = marker + '''\tif kind == &"squad":\n\t\tvar squad_boss := _find_enemy_by_id(String(event.get("boss_id", "boss_actor")))\n\t\tif squad_boss != null and squad_boss.alive:\n\t\t\t_spawn_boss_phase_adds(\n\t\t\t\tsquad_boss,\n\t\t\t\tArray(event.get("roles", [])),\n\t\t\t\tStringName(event.get("tactic_id", &""))\n\t\t\t)\n\t\treturn\n'''
        text = replace_once(text, marker, addition, "periodic squad execution")
    phase_spawn = '''\t_spawn_boss_phase_adds(\n\t\tboss,\n\t\tArray(payload.get("add_roles", [])),\n\t\tStringName(payload.get("tactic_id", &""))\n\t)\n'''
    if phase_spawn in text:
        text = replace_once(
            text,
            phase_spawn,
            "\t# Phase changes alter the next periodic squad packet; they no longer\n\t# create an immediate damage-triggered add wave.\n",
            "remove phase-threshold add spawn",
        )
    text = text.replace(
        "ProjectileState.DISTANCE_GROWTH_GROWTH_KIND\n\t\t\t)",
        "ProjectileState.BOSS_DISTANCE_GROWTH_KIND\n\t\t\t)",
        1,
    )
    if "STAGE_7_WALL_SPEED_SCALE" not in text:
        text = replace_once(
            text,
            '\t\t\t\t"motion":axis * (-320.0 * float(wall_index)),\n',
            '\t\t\t\t"motion":axis * (-320.0 * LateBossMechanics.STAGE_7_WALL_SPEED_SCALE * float(wall_index)),\n',
            "Stage 7 wall speed",
        )
        text = replace_once(
            text,
            '\t\t\t\t"damage":float(event["damage"]),\n',
            '\t\t\t\t"damage":float(event["damage"]) * LateBossMechanics.STAGE_7_WALL_DAMAGE_SCALE,\n',
            "Stage 7 wall damage",
        )
    if "boss_compression_speed_scale" not in text:
        text = replace_once(
            text,
            "\tvar motion_speed := 620.0\n",
            "\tvar boss_compression_speed_scale := (\n\t\tLateBossMechanics.STAGE_9_WALL_SPEED_SCALE\n\t\tif StringName(event.get(\"owner_kind\", &\"boss_actor\")) == &\"boss_actor\"\n\t\t\tand current_stage_index == 8\n\t\telse 1.0\n\t)\n\tvar boss_compression_damage_scale := (\n\t\tLateBossMechanics.STAGE_9_WALL_DAMAGE_SCALE\n\t\tif StringName(event.get(\"owner_kind\", &\"boss_actor\")) == &\"boss_actor\"\n\t\t\tand current_stage_index == 8\n\t\telse 1.0\n\t)\n\tvar motion_speed := 620.0 * boss_compression_speed_scale\n",
            "Stage 9 wall scales",
        )
        # Replace the next compression damage assignment after the scale block.
        start = text.index("var boss_compression_speed_scale")
        damage_at = text.index('\t\t\t"damage":float(event["damage"]),', start)
        text = text[:damage_at] + '\t\t\t"damage":float(event["damage"]) * boss_compression_damage_scale,' + text[damage_at + len('\t\t\t"damage":float(event["damage"]),'):]
    proximity_marker = "\t\tprojectile.pos = to\n\t\tif hostile:\n"
    if "should_proximity_detonate" not in text:
        proximity_block = '''\t\tprojectile.pos = to\n\t\tif (\n\t\t\thostile\n\t\t\tand projectile.should_proximity_detonate(\n\t\t\t\tplayer_position, Rules.PLAYER_RADIUS\n\t\t\t)\n\t\t):\n\t\t\tif projectile.consume_detonation():\n\t\t\t\tvar proximity_damage := AttackContract.radial_damage(\n\t\t\t\t\tprojectile.damage,\n\t\t\t\t\tplayer_position.distance_to(projectile.pos),\n\t\t\t\t\tProjectileState.BOSS_PROXIMITY_EXPLOSION_RADIUS\n\t\t\t\t)\n\t\t\t\tif proximity_damage > 0.0:\n\t\t\t\t\t_damage_player(\n\t\t\t\t\t\tproximity_damage, projectile.owner, true, true,\n\t\t\t\t\t\tprojectile.final_damage\n\t\t\t\t\t)\n\t\t\tprojectile_store.remove_hostile_at_swap(index)\n\t\t\tcontinue\n\t\tif hostile:\n'''
        text = replace_once(text, proximity_marker, proximity_block, "Stage 6 proximity collision")
    text = text.replace(
        "if projectile.distance_growth_kind != ProjectileState.DISTANCE_GROWTH_GROWTH_KIND:\n",
        "if not projectile.uses_distance_growth():\n",
        1,
    )
    if 'pattern == "common_parallel_beam"' not in text:
        pattern = r'func _append_boss_cross_corridors\(.*?\n\nfunc _advance_pending_boss_barrage\(delta: float\) -> void:'
        match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
        if match is None:
            raise RuntimeError("parallel beam: could not locate direct corridor function")
        replacement = r'''func _append_boss_cross_corridors(
	boss: EnemyState,
	pattern: String,
	damage: float
) -> void:
	if boss == null or not boss.alive:
		return
	var half_width := BossPatterns.width(pattern, current_stage_index) * 0.5
	if pattern == "common_parallel_beam":
		var axis := Vector2(boss.committed_dir).normalized()
		var tangent := axis.rotated(PI * 0.5)
		for lane_index in [-1, 1]:
			var emitter := boss.pos + tangent * 54.0 * float(lane_index)
			var to := _runtime_attack_path_end(
				emitter, axis, BossPatterns.BEAM_RANGE, half_width
			)
			denied_zones.append({
				"id":"%s_parallel_%d" % [boss.id, lane_index],
				"shape":&"corridor", "from":emitter, "to":to,
				"width":half_width * 2.0, "warning":0.0,
				"warning_total":BossPatterns.startup_seconds(pattern, current_stage_index),
				"duration":BossPatterns.active_seconds(pattern, current_stage_index),
				"duration_total":BossPatterns.active_seconds(pattern, current_stage_index),
				"tick":0.0, "damage":damage, "source":pattern,
				"owner_kind":&"boss_actor", "affinity":BossPatterns.affinity(pattern),
				"commit_mode":&"committed", "final_damage":true,
				"single_hit":true, "hit_committed":false,
				"beam_growth_seconds":AttackContract.EMITTED_BEAM_GROWTH_SECONDS,
				"beam_emission_mode":AttackContract.EMITTED_BEAM_FORWARD,
				"beam_emitter":emitter, "emitter_radius":boss.visual_radius,
			})
		boss.attack_telegraphs.clear()
		return
	for corridor_index in 2:
		var offset := -PI * 0.25 if corridor_index == 0 else PI * 0.25
		var axis := Vector2(boss.committed_dir).rotated(offset).normalized()
		var from := _runtime_attack_path_end(
			boss.pos, -axis, BossPatterns.BEAM_RANGE, half_width
		)
		var to := _runtime_attack_path_end(
			boss.pos, axis, BossPatterns.BEAM_RANGE, half_width
		)
		denied_zones.append({
			"id":"%s_cross_%d" % [boss.id, corridor_index],
			"shape":&"corridor", "from":from, "to":to,
			"width":half_width * 2.0, "warning":0.0,
			"warning_total":BossPatterns.startup_seconds(pattern, current_stage_index),
			"duration":BossPatterns.active_seconds(pattern, current_stage_index),
			"tick":0.0, "damage":damage, "source":pattern,
			"owner_kind":&"boss_actor", "affinity":BossPatterns.affinity(pattern),
			"commit_mode":&"committed", "final_damage":true,
			"single_hit":true, "hit_committed":false,
			"beam_growth_seconds":AttackContract.EMITTED_BEAM_GROWTH_SECONDS,
			"beam_emission_mode":AttackContract.EMITTED_BEAM_BIDIRECTIONAL,
			"beam_emitter":Vector2(boss.pos), "emitter_radius":boss.visual_radius,
			"duration_total":BossPatterns.active_seconds(pattern, current_stage_index),
		})
	boss.attack_telegraphs.clear()


func _advance_pending_boss_barrage(delta: float) -> void:'''
        text = text[:match.start()] + replacement + text[match.end():]
    if "boss_shield_runtime.reflects_projectile" not in text:
        pattern = r'func _try_reflect_direct_projectile\(.*?\n\nfunc _remove_projectile_at\(hostile: bool, index: int\) -> void:'
        match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
        if match is None:
            raise RuntimeError("segmented reflection: could not locate reflection function")
        replacement = r'''func _try_reflect_direct_projectile(
	enemy: EnemyState,
	projectile: ProjectileState
) -> bool:
	if projectile.reflected or projectile.owner != "player_primary":
		return false
	var is_reflect_boss := enemy.role == &"boss" and current_stage_index == 9
	var is_teaching_enemy := (
		enemy.family_trait == &"reflector" and enemy.pack_trait_active
	)
	if not is_reflect_boss and not is_teaching_enemy:
		return false
	var hit_direction := (projectile.pos - enemy.pos).normalized()
	if hit_direction.is_zero_approx():
		hit_direction = -projectile.velocity.normalized()
	var normal := hit_direction
	var reflected_damage := 0.0
	if is_reflect_boss:
		if not boss_shield_runtime.reflects_projectile(hit_direction):
			return false
		normal = boss_shield_runtime.reflection_normal(hit_direction)
		reflected_damage = boss_shield_runtime.reflected_damage(projectile.damage)
	else:
		if not LateBossMechanics.hits_reflection_plate(
			enemy.presentation_facing, projectile.velocity, 0.0
		):
			return false
		normal = enemy.presentation_facing.normalized()
		if normal.is_zero_approx():
			normal = -projectile.velocity.normalized()
		reflected_damage = LateBossMechanics.reflected_damage(projectile.damage)
	var reflected_velocity := projectile.velocity.bounce(normal)
	projectile_store.add_hostile({
		"pos":enemy.pos + normal * (enemy.projectile_hit_radius + projectile.radius + 2.0),
		"spawn_origin":enemy.pos, "velocity":reflected_velocity,
		"radius":projectile.radius, "damage":reflected_damage,
		"structure_damage":0.0, "life":projectile.life,
		"color":Art.CORAL,
		"owner":"boss_reflection" if is_reflect_boss else "ordinary_reflection",
		"pierce":0, "bounces":0, "homing":false, "explosive":false,
		"reflected":true, "final_damage":true, "affinity":projectile.affinity,
		"threat_tier":AttackContract.THREAT_BOSS if is_reflect_boss else AttackContract.THREAT_ORDINARY,
	}, is_reflect_boss)
	_play_sound(&"cover", 1.12)
	return true


func _remove_projectile_at(hostile: bool, index: int) -> void:'''
        text = text[:match.start()] + replacement + text[match.end():]
    old_reflect_state = '''\t\t9:\n\t\t\tboss.mechanic_cue_active = LateBossMechanics.reflection_cue_active(boss.pattern_timer)\n\t\t\tboss.mechanic_state = &"reflect_active" if LateBossMechanics.reflection_active(boss.pattern_timer) else (&"reflect_cue" if boss.mechanic_cue_active else &"reflect_exposed")\n'''
    if old_reflect_state in text:
        text = replace_once(
            text,
            old_reflect_state,
            '''\t\t9:\n\t\t\tboss.mechanic_cue_active = boss_shield_runtime.cue_active()\n\t\t\t# The shared segmented-defense snapshot owns active reflection. Keep\n\t\t\t# only the bounded pre-activation cue in the legacy mechanic channel.\n\t\t\tboss.mechanic_state = &"reflect_cue" if boss.mechanic_cue_active else &""\n''',
            "Stage 10 defense presentation owner",
        )
    write(path, text)


def patch_renderer() -> None:
    path = "scripts/presentation/vehicle_combat_renderer.gd"
    text = read(path)
    text = text.replace(
        'shield_kind != &"frontal_intercept"',
        'shield_kind not in [&"frontal_intercept", &"segmented_reflect"]',
    )
    text = text.replace(
        'shield_kind == &"frontal_intercept"',
        'shield_kind in [&"frontal_intercept", &"segmented_reflect"]',
    )
    # Stage 6 now uses BOSS_DISTANCE_GROWTH_KIND, so the legacy line-tail block
    # remains available to old ordinary fixtures but is never used by this boss.
    write(path, text)


def patch_docs() -> None:
    product_path = "docs/product/vehicle_game_spec.md"
    product = read(product_path)
    marker = "## Shared boss attack progression and defense rules (2026-08-22)"
    if marker not in product:
        product += r'''

## Shared boss attack progression and defense rules (2026-08-22)

- Stage 1 teaches aimed charge, two-lane projectiles, the fast three-row barrage,
  radial bombardment, and the ten-second squad call.
- Stage 2 retains the Stage 1 language and adds parallel and X-shaped emitted beams.
- Stage 3 retains all Stage 2 attacks and adds body-attached segmented defense.
- Stages 4-12 retain the complete common language. Existing signature attacks or
  persistent boss states remain separate from the common pool.
- Projectile volleys, barrages, long-bank ordnance, and charges capture the player
  once and commit after a brief read. Beams, radial bombardments, crossing walls,
  and compression walls retain longer warnings.
- Stage 6 distance-growth ordnance starts at normal projectile speed, size, and
  damage; grows after travel; and gains a one-shot proximity detonation after its
  later arming distance.
- Every boss defense has angular gaps and a complete down window. Stage 10 reflection
  uses this same segmented contract rather than a facing-based frontal plate.
- Stage 7 crossing walls and Stage 9 compression walls use 70% of their previous
  movement speed and contact damage. Boss health and movement profiles are unchanged.
'''
        write(product_path, product)

    visual_path = "docs/design/VISUAL_SYSTEM.md"
    visual = read(visual_path)
    visual = visual.replace(
        "- 보스 방어막은 외부 objective나 별도 actor가 아니라 boss body에 붙은 한 겹의\n  command-color directional boundary다. Stage 3 boss만 세 개의 독립된 두꺼운 arc\n  segment를 사용하며 collision truth도 각 segment의 각도와 gap을 따른다. `shield_up`과\n  `shield_down` 두 상태만 사용하며, 별도 node, pylon, module, objective marker를 만들지 않는다.",
        "- Boss defenses are body-attached, code-native segmented boundaries rather than external objectives or actors. Stage 3 absorption and Stage 10 reflection share collision-true angular segments, attackable gaps, and recurring full-down windows. They use no separate node, pylon, module, or objective marker.",
    )
    visual = visual.replace(
        "- boss body의 고유성은 전체 silhouette와 큰 mass 비율이 소유한다. 방어막은\n  body에 붙은 세 개의 독립된 두꺼운 directional segment로만 표시하며 별도 actor나\n  asset family를 사용하지 않는다. Stage 3 boss만 80-degree segment 세 개와 40-degree\n  gap 세 개를 보여 주며 alpha `0.38`, body radius `+8`를 사용한다. 각 segment의\n  radial thickness는 body silhouette와 분리되어 1x에서 읽혀야 한다. `shield_down`에는\n  표시하지 않는다.",
        "- Boss identity remains owned by the authored silhouette and large mass ratio. Segmented defenses use one body-attached code-native arc set with no separate actor or asset family. Stage 3 keeps three 80-degree segments and three 40-degree gaps. Stage 10 uses three reflection segments with larger attackable gaps. Active alpha is `0.38`; the Stage 10 activation cue uses `0.19`; no segment is shown during the full-down state.",
    )
    visual = visual.replace(
        "- Stage 9 compression uses a 180-world-unit matte danger slab, one dark mass separator,\n  and one large directional edge cut. It never uses a bright laser core. Stage 10 reflection\n  is absent during the first 14 exposed seconds, uses a restrained half-alpha body-attached\n  frontal plate cue during the final exposed second, and uses one full body-attached frontal\n  plate boundary during its five active seconds. Stage 11 shows exactly one filled annulus and\n  its two boundaries, with no decorative repeated circles. Stage 12 overload preserves the\n  authored silhouette and facing while the body becomes near-black with one coral hot edge.",
        "- Stage 9 compression uses a 180-world-unit matte danger slab, one dark mass separator, and one large directional edge cut. It never uses a bright laser core. Stage 10 reflection is absent during the first 14 exposed seconds, previews its future segmented coverage during the final exposed second, and enables collision only on those segments for five seconds. Gaps remain normally attackable. Stage 11 shows exactly one filled annulus and its two boundaries, with no decorative repeated circles. Stage 12 overload preserves the authored silhouette and facing while the body becomes near-black with one coral hot edge.",
    )
    write(visual_path, visual)


def main() -> None:
    write("scripts/bosses/vehicle_boss_progression_catalog.gd", PROGRESSION_CATALOG)
    write("scripts/combat/vehicle_projectile_state.gd", PROJECTILE_STATE)
    write("scripts/bosses/vehicle_boss_shield_runtime.gd", SHIELD_RUNTIME)
    patch_patterns()
    patch_runtime()
    patch_late_mechanics()
    patch_run()
    patch_renderer()
    patch_docs()
    write("tools/validation/validate_vehicle_boss_shared_pattern_defense_rules.gd", FOCUSED_VALIDATOR)
    write("tools/validation/validate_vehicle_boss_shared_pattern_defense_rules.gd.uid", "uid://bd7x2k3p9m4qa\n")
    print("BOSS_SHARED_PATTERN_PLAN_MIGRATION_OK")


if __name__ == "__main__":
    main()
