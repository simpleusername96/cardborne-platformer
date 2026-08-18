class_name VehicleStageDifficulty
extends RefCounted

## Bounded cycle-to-cycle pressure. Ordinary durability carries most of the
## late-run growth while movement reaches a strict 1.30x ceiling.

const HEALTH := [1.00, 1.10, 1.20, 1.35, 1.50, 1.65, 1.82, 2.00, 2.00, 2.00, 2.00, 2.00]
const DAMAGE := [1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.24, 1.27, 1.30, 1.33]
const SPEED := [1.00, 1.04, 1.08, 1.12, 1.17, 1.21, 1.26, 1.30, 1.30, 1.30, 1.30, 1.30]
const ORDINARY_HEALTH_PRESSURE := [1.00, 1.00, 1.00, 1.06, 1.12, 1.19, 1.25, 1.31, 1.38, 1.44, 1.47, 1.50]
const ORDINARY_DAMAGE_PRESSURE := [0.98, 1.08, 1.18, 1.28, 1.38, 1.48, 1.57, 1.66, 1.72, 1.78, 1.84, 1.90]
const ORDINARY_HEALTH_MULTIPLIER := 2.60
const ORDINARY_DURABILITY_MULTIPLIER := 1.20

const BOSS_MAX_HEALTH := [16900.0, 21300.0, 28300.0, 36800.0, 46700.0, 57500.0, 69200.0, 81600.0, 94600.0, 108200.0, 122300.0, 136890.0]
# Compatibility fields remain readable by report code, but maximum health is
# directly authored above instead of composed from a shared base and multiplier.
const BOSS_BASE_HEALTH := BOSS_MAX_HEALTH
const BOSS_HEALTH_MULTIPLIERS := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
const BOSS_DAMAGE_MULTIPLIERS := [1.00, 1.06, 1.12, 1.18, 1.24, 1.31, 1.38, 1.46, 1.54, 1.62, 1.70, 1.78]
const BOSS_MOVE_SPEEDS := [380.0, 395.0, 410.0, 425.0, 440.0, 455.0, 470.0, 485.0, 495.0, 505.0, 515.0, 525.0]
# Existing cycle cadence arc with every downtime owner reduced to roughly
# two-thirds of its previous value. Startup and active windows do not consume it.
const BOSS_CADENCE_SCALES := [0.67, 0.65, 0.63, 0.61, 0.59, 0.57, 0.55, 0.53, 0.52, 0.51, 0.50, 0.49]
const BOSS_COVERAGE_SCALES := [1.00, 1.04, 1.08, 1.12, 1.16, 1.20, 1.24, 1.28, 1.30, 1.32, 1.34, 1.36]
const BOSS_ATTACK_TIME_SCALES := [1.00, 0.98, 0.96, 0.94, 0.92, 0.90, 0.88, 0.86, 0.85, 0.84, 0.83, 0.82]
const BOSS_ATTACK_MOVE_SCALES := [0.62, 0.64, 0.66, 0.68, 0.70, 0.72, 0.74, 0.76, 0.78, 0.80, 0.81, 0.82]
const MIN_BOSS_STARTUP_SECONDS := 0.65
const MIN_BOSS_ACTIVE_SECONDS := 0.45
const BOSS_SHIELDED_DAMAGE_MULTIPLIER := 0.15
# Compatibility readout for guidebook/legacy validators; only shield-owning
# profiles consume it at runtime.
const BOSS_SHIELDED_DAMAGE_MULTIPLIERS := [0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15]

static func multipliers(cycle_index: int) -> Dictionary:
	var index := _bounded_stage_index(cycle_index)
	if index < 0:
		return {}
	return {"health": HEALTH[index], "damage": DAMAGE[index], "speed": SPEED[index], "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE[index], "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE[index]}

static func boss_health(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_MAX_HEALTH[index] if index >= 0 else 0.0

static func ordinary_health_multiplier(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return HEALTH[index] if index >= 0 else 0.0

static func boss_damage_multiplier(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_DAMAGE_MULTIPLIERS[index] if index >= 0 else 0.0

static func boss_shielded_damage_multiplier(cycle_index: int) -> float:
	return BOSS_SHIELDED_DAMAGE_MULTIPLIER if _bounded_stage_index(cycle_index) >= 0 else 0.0

static func boss_move_speed(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_MOVE_SPEEDS[index] if index >= 0 else 0.0

static func boss_cadence_scale(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_CADENCE_SCALES[index] if index >= 0 else 0.0

static func boss_coverage_scale(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_COVERAGE_SCALES[index] if index >= 0 else 0.0

static func boss_attack_time_scale(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_ATTACK_TIME_SCALES[index] if index >= 0 else 0.0

static func boss_attack_move_scale(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_ATTACK_MOVE_SCALES[index] if index >= 0 else 0.0

static func boss_startup_seconds(authored_seconds: float, cycle_index: int) -> float:
	return maxf(MIN_BOSS_STARTUP_SECONDS, authored_seconds * boss_attack_time_scale(cycle_index))

static func boss_active_seconds(authored_seconds: float, cycle_index: int) -> float:
	return maxf(MIN_BOSS_ACTIVE_SECONDS, authored_seconds * boss_attack_time_scale(cycle_index))

static func stage_index_from_id(stage_id: StringName) -> int:
	var index := String(stage_id).trim_prefix("stage_").to_int() - 1
	return index if index >= 0 and index < BOSS_HEALTH_MULTIPLIERS.size() else -1

static func boss_profile(cycle_index: int) -> Dictionary:
	var index := _bounded_stage_index(cycle_index)
	if index < 0:
		return {}
	return {"health": boss_health(index), "health_multiplier": BOSS_HEALTH_MULTIPLIERS[index], "damage_multiplier": boss_damage_multiplier(index), "move_speed": boss_move_speed(index), "cadence_scale": boss_cadence_scale(index), "coverage_scale": boss_coverage_scale(index), "attack_time_scale": boss_attack_time_scale(index), "attack_move_scale": boss_attack_move_scale(index)}

static func debug_contract() -> Dictionary:
	return {"health": HEALTH.duplicate(), "damage": DAMAGE.duplicate(), "speed": SPEED.duplicate(), "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE.duplicate(), "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE.duplicate(), "ordinary_health_multiplier": ORDINARY_HEALTH_MULTIPLIER, "ordinary_durability_multiplier": ORDINARY_DURABILITY_MULTIPLIER, "boss_max_health": BOSS_MAX_HEALTH.duplicate(), "boss_base_health": BOSS_BASE_HEALTH.duplicate(), "boss_health_multipliers": BOSS_HEALTH_MULTIPLIERS.duplicate(), "boss_damage_multipliers": BOSS_DAMAGE_MULTIPLIERS.duplicate(), "boss_move_speeds": BOSS_MOVE_SPEEDS.duplicate(), "boss_cadence_scales": BOSS_CADENCE_SCALES.duplicate(), "boss_coverage_scales": BOSS_COVERAGE_SCALES.duplicate(), "boss_attack_time_scales": BOSS_ATTACK_TIME_SCALES.duplicate(), "boss_attack_move_scales": BOSS_ATTACK_MOVE_SCALES.duplicate(), "minimum_boss_startup_seconds": MIN_BOSS_STARTUP_SECONDS, "minimum_boss_active_seconds": MIN_BOSS_ACTIVE_SECONDS}

static func _bounded_stage_index(cycle_index: int) -> int:
	return cycle_index if cycle_index >= 0 and cycle_index < BOSS_HEALTH_MULTIPLIERS.size() else -1
