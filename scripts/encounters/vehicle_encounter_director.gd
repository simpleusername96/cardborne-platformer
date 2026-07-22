class_name VehicleEncounterDirector
extends RefCounted

## Shared squad steering and beat-aware combat-pressure limits.

const THREAT_BUDGET := 6.5
const MAX_RANGED_COMMITS := 3
const MAX_DENIAL_COMMITS := 2
const ENEMY_SPEED_MULTIPLIER := 1.15
const HOSTILE_PROJECTILE_SPEED_MULTIPLIER := 1.12
const ENEMY_DAMAGE_MULTIPLIER := 1.25
const ENEMY_RECOVERY_RATE := 1.20
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const EFFECT_CAP := 96

const STANDARD_ACTIVE_CAPS := [1, 12, 16, 20, 24]
const ONSLAUGHT_ACTIVE_CAPS := [1, 16, 24, 32, 40]
const STANDARD_THREAT_BUDGETS := [1.0, 2.5, 3.5, 4.0, 5.0]

const POPULATION_BANDS := {
	&"flooded_works": Vector2i(112,128),
	&"tidal_archive": Vector2i(128,148),
	&"storm_drydock": Vector2i(144,164),
	&"coral_switchyard": Vector2i(152,176),
	&"abyssal_observatory": Vector2i(160,184),
}


static func active_cap_for(beat: int, preset: StringName = &"standard") -> int:
	var caps := ONSLAUGHT_ACTIVE_CAPS if preset == &"onslaught" else STANDARD_ACTIVE_CAPS
	return int(caps[clampi(beat, 0, caps.size() - 1)])


static func active_cap(_stage_id: StringName = &"flooded_works") -> int:
	return active_cap_for(4, &"standard")


static func threat_budget_for(beat: int, preset: StringName = &"standard") -> float:
	if preset == &"onslaught" and beat >= 2:
		return THREAT_BUDGET
	return float(STANDARD_THREAT_BUDGETS[clampi(beat, 0, STANDARD_THREAT_BUDGETS.size() - 1)])


static func squad_gap_multiplier(beat: int, preset: StringName) -> float:
	return 0.78 if preset == &"onslaught" and beat >= 2 else 1.0


static func population_band(stage_id: StringName) -> Vector2i:
	return Vector2i(POPULATION_BANDS.get(stage_id, Vector2i(1, 999)))


static func can_commit(current_points: float, ranged_count: int, denial_count: int, enemy: Dictionary, budget: float = THREAT_BUDGET, ranged_cap: int = MAX_RANGED_COMMITS, denial_cap: int = MAX_DENIAL_COMMITS) -> bool:
	var cost := float(enemy.get("threat_cost", 1.0))
	var kind := StringName(enemy.get("threat_kind", &"melee"))
	if current_points + cost > budget + 0.001:
		return false
	if kind == &"ranged" and ranged_count >= ranged_cap:
		return false
	if kind == &"denial" and denial_count >= denial_cap:
		return false
	return true


static func cohesion_velocity(enemy: Dictionary, active_enemies: Array[Dictionary], role_velocity: Vector2) -> Vector2:
	if String(enemy.get("phase", "move")) in ["startup", "active"]:
		return role_velocity
	var squad_id := String(enemy.get("squad_id", ""))
	if squad_id.is_empty() or role_velocity.length_squared() <= 0.001:
		return role_velocity
	var centroid := Vector2.ZERO
	var members := 0
	for candidate in active_enemies:
		if bool(candidate.get("alive", false)) and bool(candidate.get("active", false)) and String(candidate.get("squad_id", "")) == squad_id:
			centroid += Vector2(candidate["pos"])
			members += 1
	if members <= 1:
		return role_velocity
	centroid /= float(members)
	var slot_target := centroid + Vector2(enemy.get("formation_offset", Vector2.ZERO))
	var to_slot := slot_target - Vector2(enemy["pos"])
	if Vector2(enemy["pos"]).distance_to(centroid) > 220.0:
		to_slot = centroid - Vector2(enemy["pos"])
	if to_slot.length_squared() <= 1.0:
		return role_velocity
	var cohesion := to_slot.normalized() * role_velocity.length()
	return (role_velocity * 0.70 + cohesion * 0.30).limit_length(role_velocity.length())


static func tuning_contract() -> Dictionary:
	return {
		"threat_budget": THREAT_BUDGET,
		"standard_caps": STANDARD_ACTIVE_CAPS,
		"onslaught_caps": ONSLAUGHT_ACTIVE_CAPS,
		"standard_budgets": STANDARD_THREAT_BUDGETS,
		"max_ranged": MAX_RANGED_COMMITS,
		"max_denial": MAX_DENIAL_COMMITS,
		"enemy_speed_multiplier": ENEMY_SPEED_MULTIPLIER,
		"projectile_speed_multiplier": HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"enemy_damage_multiplier": ENEMY_DAMAGE_MULTIPLIER,
		"enemy_recovery_rate": ENEMY_RECOVERY_RATE,
	}
