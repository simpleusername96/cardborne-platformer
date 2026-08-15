class_name VehicleStageDifficulty
extends RefCounted

## Bounded cycle-to-cycle pressure. Ordinary health increases by an exact
## 30-percent Stage 1 baseline step from Stage 2 onward; bosses own a separate curve.

const HEALTH := [1.00, 1.30, 1.60, 1.90, 2.20, 2.50, 2.80, 3.10]
const DAMAGE := [1.0, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21]
const SPEED := [1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07]
const ORDINARY_HEALTH_PRESSURE := [1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00]
const ORDINARY_DAMAGE_PRESSURE := [0.98, 1.08, 1.18, 1.28, 1.38, 1.48, 1.57, 1.66]
const ORDINARY_HEALTH_MULTIPLIER := 2.60
const ORDINARY_DURABILITY_MULTIPLIER := 1.20

const BOSS_BASE_HEALTH := [5200.0, 5200.0, 5200.0, 5200.0, 5200.0, 5200.0, 5200.0, 5200.0]
const BOSS_HEALTH_MULTIPLIERS := [1.00, 1.12, 1.25, 1.39, 1.54, 1.70, 1.87, 2.05]
const BOSS_DAMAGE_MULTIPLIERS := [1.00, 1.06, 1.12, 1.18, 1.24, 1.31, 1.38, 1.46]
const BOSS_MOVE_SPEEDS := [181.25, 187.5, 193.75, 200.0, 207.5, 215.0, 222.5, 230.0]
const BOSS_CADENCE_SCALES := [1.00, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79]
const BOSS_COVERAGE_SCALES := [1.00, 1.04, 1.08, 1.12, 1.16, 1.20, 1.24, 1.28]
const BOSS_SHIELDED_DAMAGE_MULTIPLIER := 0.10
# Compatibility readout for guidebook/legacy validators; only shield-owning
# profiles consume it at runtime.
const BOSS_SHIELDED_DAMAGE_MULTIPLIERS := [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10]

static func multipliers(cycle_index: int) -> Dictionary:
	var index := _bounded_stage_index(cycle_index)
	if index < 0:
		return {}
	return {"health": HEALTH[index], "damage": DAMAGE[index], "speed": SPEED[index], "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE[index], "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE[index]}

static func boss_health(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return BOSS_BASE_HEALTH[index] * BOSS_HEALTH_MULTIPLIERS[index] if index >= 0 else 0.0

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

static func stage_index_from_id(stage_id: StringName) -> int:
	var index := String(stage_id).trim_prefix("stage_").to_int() - 1
	return index if index >= 0 and index < BOSS_HEALTH_MULTIPLIERS.size() else -1

static func boss_profile(cycle_index: int) -> Dictionary:
	var index := _bounded_stage_index(cycle_index)
	if index < 0:
		return {}
	return {"health": boss_health(index), "health_multiplier": BOSS_HEALTH_MULTIPLIERS[index], "damage_multiplier": boss_damage_multiplier(index), "move_speed": boss_move_speed(index), "cadence_scale": boss_cadence_scale(index), "coverage_scale": boss_coverage_scale(index)}

static func debug_contract() -> Dictionary:
	return {"health": HEALTH.duplicate(), "damage": DAMAGE.duplicate(), "speed": SPEED.duplicate(), "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE.duplicate(), "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE.duplicate(), "ordinary_health_multiplier": ORDINARY_HEALTH_MULTIPLIER, "ordinary_durability_multiplier": ORDINARY_DURABILITY_MULTIPLIER, "boss_base_health": BOSS_BASE_HEALTH.duplicate(), "boss_health_multipliers": BOSS_HEALTH_MULTIPLIERS.duplicate(), "boss_damage_multipliers": BOSS_DAMAGE_MULTIPLIERS.duplicate(), "boss_move_speeds": BOSS_MOVE_SPEEDS.duplicate(), "boss_cadence_scales": BOSS_CADENCE_SCALES.duplicate(), "boss_coverage_scales": BOSS_COVERAGE_SCALES.duplicate()}

static func _bounded_stage_index(cycle_index: int) -> int:
	return cycle_index if cycle_index >= 0 and cycle_index < BOSS_HEALTH_MULTIPLIERS.size() else -1
