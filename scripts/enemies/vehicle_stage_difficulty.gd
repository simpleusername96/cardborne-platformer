class_name VehicleStageDifficulty
extends RefCounted

## Bounded stage-to-stage stat progression. Telegraph and projectile timing are
## intentionally excluded so difficulty grows without invalidating reactions.

const HEALTH := [0.85, 1.00, 1.15, 1.30, 1.45]
const DAMAGE := [1.0, 1.03, 1.06, 1.09, 1.12]
const SPEED := [1.0, 1.01, 1.02, 1.03, 1.04]
const ORDINARY_HEALTH_PRESSURE := [1.35, 1.40, 1.45, 1.50, 1.50]
const ORDINARY_DAMAGE_PRESSURE := [1.15, 1.20, 1.25, 1.30, 1.30]
const ORDINARY_HEALTH_MULTIPLIER := 2.60
const BOSS_HEALTH_MULTIPLIER := 3.90


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
	var index := clampi(stage_index, 0, 4)
	return [1250.0, 1350.0, 1450.0, 1550.0, 1650.0][index] * BOSS_HEALTH_MULTIPLIER


static func debug_contract() -> Dictionary:
	return {
		"health":HEALTH.duplicate(),
		"damage":DAMAGE.duplicate(),
		"speed":SPEED.duplicate(),
		"ordinary_health_pressure":ORDINARY_HEALTH_PRESSURE.duplicate(),
		"ordinary_damage_pressure":ORDINARY_DAMAGE_PRESSURE.duplicate(),
		"ordinary_health_multiplier":ORDINARY_HEALTH_MULTIPLIER,
		"boss_health_multiplier":BOSS_HEALTH_MULTIPLIER,
	}
