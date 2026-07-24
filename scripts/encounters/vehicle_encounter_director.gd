class_name VehicleEncounterDirector
extends RefCounted

## Shared squad steering and beat-aware combat-pressure limits.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const THREAT_BUDGET := 7.5
const MAX_RANGED_COMMITS := 3
const MAX_DENIAL_COMMITS := 2
const ENEMY_HEALTH_MULTIPLIER := 1.12
const ENEMY_SPEED_MULTIPLIER := 1.20
const HOSTILE_PROJECTILE_SPEED_MULTIPLIER := 0.82
const ENEMY_DAMAGE_MULTIPLIER := 1.35
const ENEMY_RECOVERY_RATE := 1.28
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const BOSS_PROJECTILE_RESERVE := 24
const EFFECT_CAP := 96

const ACTIVE_CAPS := [1, 48, 60, 68, 72]
const THREAT_BUDGETS := [1.0, 3.0, 4.5, 5.25, 6.25]


static func active_cap_for(beat: int) -> int:
	return int(ACTIVE_CAPS[clampi(beat, 0, ACTIVE_CAPS.size() - 1)])


static func active_cap(_stage_id: StringName = &"stage_1") -> int:
	return active_cap_for(4)


static func threat_budget_for(beat: int) -> float:
	return float(THREAT_BUDGETS[clampi(beat, 0, THREAT_BUDGETS.size() - 1)])


static func squad_gap_multiplier(beat: int) -> float:
	return spawn_pace_multiplier(beat)


static func spawn_pace_multiplier(beat: int) -> float:
	if beat <= 0:
		return 1.0
	return 0.34


static func effective_hostile_projectile_speed(base_speed: float) -> float:
	return maxf(0.0, base_speed) * HOSTILE_PROJECTILE_SPEED_MULTIPLIER


static func can_commit(current_points: float, ranged_count: int, denial_count: int, enemy: EnemyState, budget: float = THREAT_BUDGET, ranged_cap: int = MAX_RANGED_COMMITS, denial_cap: int = MAX_DENIAL_COMMITS) -> bool:
	var cost := enemy.threat_cost
	var kind := enemy.threat_kind
	if current_points + cost > budget + 0.001:
		return false
	if kind == &"ranged" and ranged_count >= ranged_cap:
		return false
	if kind == &"denial" and denial_count >= denial_cap:
		return false
	return true


static func squad_motion_snapshot(active_enemies: Array[EnemyState]) -> Dictionary:
	var snapshot := {}
	for candidate in active_enemies:
		if not candidate.alive or not candidate.active:
			continue
		var squad_id := candidate.squad_id
		if squad_id.is_empty():
			continue
		var summary: Dictionary = snapshot.get(squad_id, {"position_sum":Vector2.ZERO, "members":0})
		summary["position_sum"] = Vector2(summary["position_sum"]) + candidate.pos
		summary["members"] = int(summary["members"]) + 1
		snapshot[squad_id] = summary
	for squad_id in snapshot:
		var summary: Dictionary = snapshot[squad_id]
		summary["centroid"] = Vector2(summary["position_sum"]) / float(maxi(1, int(summary["members"])))
		summary.erase("position_sum")
		snapshot[squad_id] = summary
	return snapshot


static func cohesion_velocity(enemy: EnemyState, squad_snapshot: Dictionary, role_velocity: Vector2) -> Vector2:
	if enemy.phase in [&"startup", &"active"]:
		return role_velocity
	var squad_id := enemy.squad_id
	if squad_id.is_empty() or role_velocity.length_squared() <= 0.001:
		return role_velocity
	var summary: Dictionary = squad_snapshot.get(squad_id, {})
	var members := int(summary.get("members", 0))
	if members <= 1:
		return role_velocity
	var centroid := Vector2(summary["centroid"])
	var slot_target := centroid + enemy.formation_offset
	var to_slot := slot_target - enemy.pos
	if enemy.pos.distance_to(centroid) > 220.0:
		to_slot = centroid - enemy.pos
	if to_slot.length_squared() <= 1.0:
		return role_velocity
	var cohesion := to_slot.normalized() * role_velocity.length()
	return (role_velocity * 0.70 + cohesion * 0.30).limit_length(role_velocity.length())


static func tuning_contract() -> Dictionary:
	return {
		"threat_budget": THREAT_BUDGET,
		"active_caps": ACTIVE_CAPS,
		"threat_budgets": THREAT_BUDGETS,
		"max_ranged": MAX_RANGED_COMMITS,
		"max_denial": MAX_DENIAL_COMMITS,
		"enemy_health_multiplier": ENEMY_HEALTH_MULTIPLIER,
		"enemy_speed_multiplier": ENEMY_SPEED_MULTIPLIER,
		"projectile_speed_multiplier": HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"boss_projectile_reserve": BOSS_PROJECTILE_RESERVE,
		"enemy_damage_multiplier": ENEMY_DAMAGE_MULTIPLIER,
		"enemy_recovery_rate": ENEMY_RECOVERY_RATE,
		"spawn_pace": spawn_pace_multiplier(1),
	}
