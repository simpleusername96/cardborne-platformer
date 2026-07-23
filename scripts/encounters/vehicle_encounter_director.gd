class_name VehicleEncounterDirector
extends RefCounted

## Shared squad steering and beat-aware combat-pressure limits.

const THREAT_BUDGET := 7.5
const MAX_RANGED_COMMITS := 3
const MAX_DENIAL_COMMITS := 2
const ENEMY_HEALTH_MULTIPLIER := 1.12
const ENEMY_SPEED_MULTIPLIER := 1.20
const HOSTILE_PROJECTILE_SPEED_MULTIPLIER := 1.18
const ENEMY_DAMAGE_MULTIPLIER := 1.35
const ENEMY_RECOVERY_RATE := 1.28
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const EFFECT_CAP := 96

const STANDARD_ACTIVE_CAPS := [1, 15, 22, 28, 32]
const ONSLAUGHT_ACTIVE_CAPS := [1, 22, 33, 44, 52]
const STANDARD_THREAT_BUDGETS := [1.0, 3.0, 4.5, 5.25, 6.25]

const POPULATION_BANDS := {
	&"stage_1": Vector2i(56,56),
	&"stage_2": Vector2i(64,64),
	&"stage_3": Vector2i(72,72),
	&"stage_4": Vector2i(80,80),
	&"stage_5": Vector2i(88,88),
}


static func active_cap_for(beat: int, preset: StringName = &"standard") -> int:
	var caps := ONSLAUGHT_ACTIVE_CAPS if preset == &"onslaught" else STANDARD_ACTIVE_CAPS
	return int(caps[clampi(beat, 0, caps.size() - 1)])


static func active_cap(_stage_id: StringName = &"stage_1") -> int:
	return active_cap_for(4, &"standard")


static func threat_budget_for(beat: int, preset: StringName = &"standard") -> float:
	if preset == &"onslaught" and beat >= 2:
		return THREAT_BUDGET
	return float(STANDARD_THREAT_BUDGETS[clampi(beat, 0, STANDARD_THREAT_BUDGETS.size() - 1)])


static func squad_gap_multiplier(beat: int, preset: StringName) -> float:
	return spawn_pace_multiplier(beat, preset)


static func spawn_pace_multiplier(beat: int, preset: StringName) -> float:
	if beat <= 0:
		return 1.0
	return 0.28 if preset == &"onslaught" else 0.34


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


static func squad_motion_snapshot(active_enemies: Array[Dictionary]) -> Dictionary:
	var snapshot := {}
	for candidate in active_enemies:
		if not bool(candidate.get("alive", false)) or not bool(candidate.get("active", false)):
			continue
		var squad_id := String(candidate.get("squad_id", ""))
		if squad_id.is_empty():
			continue
		var summary: Dictionary = snapshot.get(squad_id, {"position_sum":Vector2.ZERO, "members":0})
		summary["position_sum"] = Vector2(summary["position_sum"]) + Vector2(candidate["pos"])
		summary["members"] = int(summary["members"]) + 1
		snapshot[squad_id] = summary
	for squad_id in snapshot:
		var summary: Dictionary = snapshot[squad_id]
		summary["centroid"] = Vector2(summary["position_sum"]) / float(maxi(1, int(summary["members"])))
		summary.erase("position_sum")
		snapshot[squad_id] = summary
	return snapshot


static func cohesion_velocity(enemy: Dictionary, squad_snapshot: Dictionary, role_velocity: Vector2) -> Vector2:
	if String(enemy.get("phase", "move")) in ["startup", "active"]:
		return role_velocity
	var squad_id := String(enemy.get("squad_id", ""))
	if squad_id.is_empty() or role_velocity.length_squared() <= 0.001:
		return role_velocity
	var summary: Dictionary = squad_snapshot.get(squad_id, {})
	var members := int(summary.get("members", 0))
	if members <= 1:
		return role_velocity
	var centroid := Vector2(summary["centroid"])
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
		"enemy_health_multiplier": ENEMY_HEALTH_MULTIPLIER,
		"enemy_speed_multiplier": ENEMY_SPEED_MULTIPLIER,
		"projectile_speed_multiplier": HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"enemy_damage_multiplier": ENEMY_DAMAGE_MULTIPLIER,
		"enemy_recovery_rate": ENEMY_RECOVERY_RATE,
		"standard_spawn_pace": spawn_pace_multiplier(1, &"standard"),
		"onslaught_spawn_pace": spawn_pace_multiplier(1, &"onslaught"),
	}
