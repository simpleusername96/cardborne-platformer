class_name VehicleStageDifficulty
extends RefCounted

## Bounded stage-to-stage stat progression. Boss startup, active time, recovery,
## projectile speed, and the exposed shield window remain pattern-owned so later
## stages can add pressure without invalidating reaction windows.

const HEALTH := [0.85, 0.917, 0.983, 1.05, 1.117, 1.183, 1.25, 1.317, 1.383, 1.45]
const DAMAGE := [1.0, 1.013, 1.027, 1.04, 1.053, 1.067, 1.08, 1.093, 1.107, 1.12]
const SPEED := [1.0, 1.004, 1.009, 1.013, 1.018, 1.022, 1.027, 1.031, 1.036, 1.04]
# Ease Stage 1 onboarding, then exceed the previous ordinary-enemy pressure curve.
const ORDINARY_HEALTH_PRESSURE := [1.15, 1.244, 1.339, 1.433, 1.528, 1.622, 1.717, 1.811, 1.906, 2.0]
const ORDINARY_DAMAGE_PRESSURE := [0.98, 1.056, 1.131, 1.207, 1.282, 1.358, 1.433, 1.509, 1.584, 1.66]
const ORDINARY_HEALTH_MULTIPLIER := 2.60
# The reduced materialized population uses one final durability policy instead
# of duplicating a 20% change across every archetype row.
const ORDINARY_DURABILITY_MULTIPLIER := 1.20

const BOSS_BASE_HEALTH := [1250.0, 1294.444, 1338.889, 1383.333, 1427.778, 1472.222, 1516.667, 1561.111, 1605.556, 1650.0]
const BOSS_HEALTH_MULTIPLIERS := [4.20, 4.244, 4.289, 4.333, 4.378, 4.422, 4.467, 4.511, 4.556, 4.60]
const BOSS_DAMAGE_MULTIPLIERS := [1.50, 1.544, 1.589, 1.633, 1.678, 1.722, 1.767, 1.811, 1.856, 1.90]
const BOSS_SHIELDED_DAMAGE_MULTIPLIERS := [0.110, 0.108, 0.106, 0.103, 0.101, 0.099, 0.097, 0.094, 0.092, 0.090]
const BOSS_CADENCE_SCALES := [0.95, 0.928, 0.906, 0.883, 0.861, 0.839, 0.817, 0.794, 0.772, 0.75]
const BOSS_COVERAGE_SCALES := [1.05, 1.072, 1.094, 1.117, 1.139, 1.161, 1.183, 1.206, 1.228, 1.25]


static func multipliers(stage_index: int) -> Dictionary:
	if stage_index < 0 or stage_index >= HEALTH.size():
		return {}
	var index := stage_index
	return {
		"health":HEALTH[index],
		"damage":DAMAGE[index],
		"speed":SPEED[index],
		"ordinary_health_pressure":ORDINARY_HEALTH_PRESSURE[index],
		"ordinary_damage_pressure":ORDINARY_DAMAGE_PRESSURE[index],
	}


static func boss_health(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_BASE_HEALTH[index] * BOSS_HEALTH_MULTIPLIERS[index] if index >= 0 else 0.0


static func boss_damage_multiplier(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_DAMAGE_MULTIPLIERS[index] if index >= 0 else 0.0


static func boss_shielded_damage_multiplier(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_SHIELDED_DAMAGE_MULTIPLIERS[index] if index >= 0 else 0.0


static func boss_cadence_scale(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_CADENCE_SCALES[index] if index >= 0 else 0.0


static func boss_coverage_scale(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_COVERAGE_SCALES[index] if index >= 0 else 0.0


static func stage_index_from_id(stage_id: StringName) -> int:
	var stage_number := String(stage_id).trim_prefix("stage_").to_int()
	var index := stage_number - 1
	return index if index >= 0 and index < HEALTH.size() else -1


static func boss_profile(stage_index: int) -> Dictionary:
	var index := _bounded_stage_index(stage_index)
	if index < 0:
		return {}
	return {
		"health":boss_health(index),
		"health_multiplier":BOSS_HEALTH_MULTIPLIERS[index],
		"damage_multiplier":boss_damage_multiplier(index),
		"shielded_damage_multiplier":boss_shielded_damage_multiplier(index),
		"cadence_scale":boss_cadence_scale(index),
		"coverage_scale":boss_coverage_scale(index),
	}


static func debug_contract() -> Dictionary:
	return {
		"health":HEALTH.duplicate(),
		"damage":DAMAGE.duplicate(),
		"speed":SPEED.duplicate(),
		"ordinary_health_pressure":ORDINARY_HEALTH_PRESSURE.duplicate(),
		"ordinary_damage_pressure":ORDINARY_DAMAGE_PRESSURE.duplicate(),
		"ordinary_health_multiplier":ORDINARY_HEALTH_MULTIPLIER,
		"ordinary_durability_multiplier":ORDINARY_DURABILITY_MULTIPLIER,
		"boss_base_health":BOSS_BASE_HEALTH.duplicate(),
		"boss_health_multipliers":BOSS_HEALTH_MULTIPLIERS.duplicate(),
		"boss_damage_multipliers":BOSS_DAMAGE_MULTIPLIERS.duplicate(),
		"boss_shielded_damage_multipliers":BOSS_SHIELDED_DAMAGE_MULTIPLIERS.duplicate(),
		"boss_cadence_scales":BOSS_CADENCE_SCALES.duplicate(),
		"boss_coverage_scales":BOSS_COVERAGE_SCALES.duplicate(),
	}


static func _bounded_stage_index(stage_index: int) -> int:
	return stage_index if stage_index >= 0 and stage_index < BOSS_BASE_HEALTH.size() else -1
