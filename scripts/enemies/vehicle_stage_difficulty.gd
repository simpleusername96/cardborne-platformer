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
const BOSS_SHIELDED_DAMAGE_MULTIPLIER := 0.15

const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")

static func multipliers(cycle_index: int) -> Dictionary:
	var index := _bounded_stage_index(cycle_index)
	if index < 0:
		return {}
	return {"health": HEALTH[index], "damage": DAMAGE[index], "speed": SPEED[index], "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE[index], "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE[index]}

static func boss_health(cycle_index: int) -> float:
	return BossProfiles.health(cycle_index)

static func ordinary_health_multiplier(cycle_index: int) -> float:
	var index := _bounded_stage_index(cycle_index)
	return HEALTH[index] if index >= 0 else 0.0

static func boss_shielded_damage_multiplier(cycle_index: int) -> float:
	return BOSS_SHIELDED_DAMAGE_MULTIPLIER if _bounded_stage_index(cycle_index) >= 0 else 0.0

static func boss_move_speed(cycle_index: int) -> float:
	return BossProfiles.move_speed(cycle_index)

static func stage_index_from_id(stage_id: StringName) -> int:
	return BossProfiles.stage_index_from_id(stage_id)

static func boss_profile(cycle_index: int) -> Dictionary:
	return BossProfiles.profile(cycle_index)

static func debug_contract() -> Dictionary:
	return {"health": HEALTH.duplicate(), "damage": DAMAGE.duplicate(), "speed": SPEED.duplicate(), "ordinary_health_pressure": ORDINARY_HEALTH_PRESSURE.duplicate(), "ordinary_damage_pressure": ORDINARY_DAMAGE_PRESSURE.duplicate(), "ordinary_health_multiplier": ORDINARY_HEALTH_MULTIPLIER, "ordinary_durability_multiplier": ORDINARY_DURABILITY_MULTIPLIER, "boss_profiles":BossProfiles.PROFILES.duplicate(true)}

static func _bounded_stage_index(cycle_index: int) -> int:
	return cycle_index if cycle_index >= 0 and cycle_index < HEALTH.size() else -1
