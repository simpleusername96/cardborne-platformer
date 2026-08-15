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
const ENEMY_DAMAGE_MULTIPLIER := 1.755
const ENEMY_RECOVERY_RATE := 1.28
const PLAYER_PROJECTILE_CAP := 240
const HOSTILE_PROJECTILE_CAP := 120
const BOSS_PROJECTILE_RESERVE := 24
const EFFECT_CAP := 96

## Authored pressure remains the pacing contract. Only the smaller materialized
## cap becomes live combat actors; the scheduler keeps the rest as packet data.
const AUTHORED_PRESSURE_CAPS := [6, 124, 172, 224, 276]
const MATERIALIZED_ACTIVE_CAPS := [6, 44, 56, 64, 72]
const ACTIVE_CAPS := MATERIALIZED_ACTIVE_CAPS
const THREAT_BUDGETS := [1.0, 3.0, 4.5, 5.25, 6.25]

## Stage pressure is deliberately separate from packet beats. Beats choose the
## shape and timing of an encounter; stages set the run's bounded live pressure.
const STAGE_THREAT_BUDGETS := [1.0, 2.0, 3.0, 3.75, 4.5, 5.0, 5.5, 6.0]
const STAGE_MATERIALIZED_ACTIVE_CAPS := [32, 44, 56, 64, 72, 72, 72, 72]
const STAGE_REFILL_FLOORS := [12, 16, 20, 24, 28, 32, 36, 40]
const STAGE_MAX_RANGED_COMMITS := [3, 3, 3, 3, 3, 4, 4, 4]
const STAGE_MAX_DENIAL_COMMITS := [2, 2, 2, 2, 2, 3, 3, 3]


static func active_cap_for(beat: int) -> int:
	return materialized_active_cap_for(beat)


static func materialized_active_cap_for(beat: int) -> int:
	return int(MATERIALIZED_ACTIVE_CAPS[clampi(beat, 0, MATERIALIZED_ACTIVE_CAPS.size() - 1)])


static func authored_pressure_cap_for(beat: int) -> int:
	return int(AUTHORED_PRESSURE_CAPS[clampi(beat, 0, AUTHORED_PRESSURE_CAPS.size() - 1)])


static func active_cap(_stage_id: StringName = &"stage_1") -> int:
	return active_cap_for(4)


static func threat_budget_for(beat: int) -> float:
	return float(THREAT_BUDGETS[clampi(beat, 0, THREAT_BUDGETS.size() - 1)])


static func stage_materialized_active_cap(stage_index: int) -> int:
	return (
		int(STAGE_MATERIALIZED_ACTIVE_CAPS[stage_index])
		if stage_index >= 0 and stage_index < STAGE_MATERIALIZED_ACTIVE_CAPS.size()
		else 0
	)


static func stage_refill_floor(stage_index: int) -> int:
	return (
		int(STAGE_REFILL_FLOORS[stage_index])
		if stage_index >= 0 and stage_index < STAGE_REFILL_FLOORS.size()
		else 0
	)


static func stage_threat_budget(stage_index: int) -> float:
	return (
		float(STAGE_THREAT_BUDGETS[stage_index])
		if stage_index >= 0 and stage_index < STAGE_THREAT_BUDGETS.size()
		else 0.0
	)


static func stage_ranged_commit_cap(stage_index: int) -> int:
	return (
		int(STAGE_MAX_RANGED_COMMITS[stage_index])
		if stage_index >= 0 and stage_index < STAGE_MAX_RANGED_COMMITS.size()
		else 0
	)


static func stage_denial_commit_cap(stage_index: int) -> int:
	return (
		int(STAGE_MAX_DENIAL_COMMITS[stage_index])
		if stage_index >= 0 and stage_index < STAGE_MAX_DENIAL_COMMITS.size()
		else 0
	)


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
		"active_caps": MATERIALIZED_ACTIVE_CAPS,
		"materialized_active_caps": MATERIALIZED_ACTIVE_CAPS,
		"authored_pressure_caps": AUTHORED_PRESSURE_CAPS,
		"threat_budgets": THREAT_BUDGETS,
		"stage_threat_budgets": STAGE_THREAT_BUDGETS,
		"stage_materialized_active_caps": STAGE_MATERIALIZED_ACTIVE_CAPS,
		"stage_refill_floors": STAGE_REFILL_FLOORS,
		"stage_max_ranged_commits": STAGE_MAX_RANGED_COMMITS,
		"stage_max_denial_commits": STAGE_MAX_DENIAL_COMMITS,
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
