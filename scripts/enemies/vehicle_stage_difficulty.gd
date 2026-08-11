class_name VehicleStageDifficulty
extends RefCounted

## Bounded stage-to-stage stat progression. Boss startup, active time, recovery,
## projectile speed, and the exposed shield window remain pattern-owned so later
## stages can add pressure without invalidating reaction windows.

const HEALTH := [0.85, 1.00, 1.15, 1.30, 1.45]
const DAMAGE := [1.0, 1.03, 1.06, 1.09, 1.12]
const SPEED := [1.0, 1.01, 1.02, 1.03, 1.04]
const ORDINARY_HEALTH_PRESSURE := [1.35, 1.45, 1.55, 1.65, 1.75]
const ORDINARY_DAMAGE_PRESSURE := [1.15, 1.24, 1.33, 1.42, 1.50]
const ORDINARY_HEALTH_MULTIPLIER := 2.60

const BOSS_BASE_HEALTH := [1250.0, 1350.0, 1450.0, 1550.0, 1650.0]
const BOSS_HEALTH_MULTIPLIERS := [4.20, 4.30, 4.40, 4.50, 4.60]
const BOSS_DAMAGE_MULTIPLIERS := [1.35, 1.42, 1.50, 1.58, 1.70]
const BOSS_SHIELDED_DAMAGE_MULTIPLIERS := [0.110, 0.105, 0.100, 0.095, 0.090]
const BOSS_CADENCE_SCALES := [0.95, 0.90, 0.85, 0.80, 0.75]
const BOSS_COVERAGE_SCALES := [1.05, 1.10, 1.15, 1.20, 1.25]


static func multipliers(stage_index: int) -> Dictionary:
	var index := clampi(stage_index, 0, HEALTH.size() - 1)
	return {
		"health":HEALTH[index],
		"damage":DAMAGE[index],
		"speed":SPEED[index],
		"ordinary_health_pressure":ORDINARY_HEALTH_PRESSURE[index],
		"ordinary_damage_pressure":ORDINARY_DAMAGE_PRESSURE[index],
	}


static func boss_health(stage_index: int) -> float:
	var index := _bounded_stage_index(stage_index)
	return BOSS_BASE_HEALTH[index] * BOSS_HEALTH_MULTIPLIERS[index]


static func boss_damage_multiplier(stage_index: int) -> float:
	return BOSS_DAMAGE_MULTIPLIERS[_bounded_stage_index(stage_index)]


static func boss_shielded_damage_multiplier(stage_index: int) -> float:
	return BOSS_SHIELDED_DAMAGE_MULTIPLIERS[_bounded_stage_index(stage_index)]


static func boss_cadence_scale(stage_index: int) -> float:
	return BOSS_CADENCE_SCALES[_bounded_stage_index(stage_index)]


static func boss_coverage_scale(stage_index: int) -> float:
	return BOSS_COVERAGE_SCALES[_bounded_stage_index(stage_index)]


static func stage_index_from_id(stage_id: StringName) -> int:
	var stage_number := String(stage_id).trim_prefix("stage_").to_int()
	return _bounded_stage_index(stage_number - 1)


static func boss_profile(stage_index: int) -> Dictionary:
	var index := _bounded_stage_index(stage_index)
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
		"boss_base_health":BOSS_BASE_HEALTH.duplicate(),
		"boss_health_multipliers":BOSS_HEALTH_MULTIPLIERS.duplicate(),
		"boss_damage_multipliers":BOSS_DAMAGE_MULTIPLIERS.duplicate(),
		"boss_shielded_damage_multipliers":BOSS_SHIELDED_DAMAGE_MULTIPLIERS.duplicate(),
		"boss_cadence_scales":BOSS_CADENCE_SCALES.duplicate(),
		"boss_coverage_scales":BOSS_COVERAGE_SCALES.duplicate(),
	}


static func _bounded_stage_index(stage_index: int) -> int:
	return clampi(stage_index, 0, BOSS_BASE_HEALTH.size() - 1)
