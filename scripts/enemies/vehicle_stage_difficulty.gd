class_name VehicleStageDifficulty
extends RefCounted

## Bounded stage-to-stage stat progression. Telegraph and projectile timing are
## intentionally excluded so difficulty grows without invalidating reactions.

const HEALTH := [1.0, 1.04, 1.08, 1.12, 1.16]
const DAMAGE := [1.0, 1.03, 1.06, 1.09, 1.12]
const SPEED := [1.0, 1.01, 1.02, 1.03, 1.04]


static func multipliers(stage_index: int) -> Dictionary:
	var index := clampi(stage_index, 0, HEALTH.size() - 1)
	return {"health":HEALTH[index], "damage":DAMAGE[index], "speed":SPEED[index]}


static func boss_health(stage_index: int, field_boss: bool = false) -> float:
	var index := clampi(stage_index, 0, 4)
	return [560.0, 590.0, 620.0, 650.0, 680.0][index] if field_boss else [1250.0, 1350.0, 1450.0, 1550.0, 1650.0][index]


static func debug_contract() -> Dictionary:
	return {"health":HEALTH.duplicate(), "damage":DAMAGE.duplicate(), "speed":SPEED.duplicate()}
