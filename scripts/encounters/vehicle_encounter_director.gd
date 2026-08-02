class_name VehicleEncounterDirector
extends RefCounted

## Beat-aware combat-pressure limits and ordinary movement tuning.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const THREAT_BUDGET := 7.5
const MAX_RANGED_COMMITS := 3
const MAX_DENIAL_COMMITS := 2
const ENEMY_HEALTH_MULTIPLIER := 1.12
# Ordinary navigation pace is tuned independently from committed attacks and bosses.
const ORDINARY_MOVEMENT_SPEED_MULTIPLIER := 1.40
const ENEMY_SPEED_MULTIPLIER := 1.20
const HOSTILE_PROJECTILE_SPEED_MULTIPLIER := 0.82
const ENEMY_DAMAGE_MULTIPLIER := 1.35
const ENEMY_RECOVERY_RATE := 1.28
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const BOSS_PROJECTILE_RESERVE := 24
const EFFECT_CAP := 96

const ACTIVE_CAPS := [1, 124, 172, 224, 276]
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


static func tuning_contract() -> Dictionary:
	return {
		"threat_budget": THREAT_BUDGET,
		"active_caps": ACTIVE_CAPS,
		"threat_budgets": THREAT_BUDGETS,
		"max_ranged": MAX_RANGED_COMMITS,
		"max_denial": MAX_DENIAL_COMMITS,
		"enemy_health_multiplier": ENEMY_HEALTH_MULTIPLIER,
		"ordinary_movement_speed_multiplier": ORDINARY_MOVEMENT_SPEED_MULTIPLIER,
		"enemy_speed_multiplier": ENEMY_SPEED_MULTIPLIER,
		"projectile_speed_multiplier": HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"boss_projectile_reserve": BOSS_PROJECTILE_RESERVE,
		"enemy_damage_multiplier": ENEMY_DAMAGE_MULTIPLIER,
		"enemy_recovery_rate": ENEMY_RECOVERY_RATE,
		"spawn_pace": spawn_pace_multiplier(1),
	}
