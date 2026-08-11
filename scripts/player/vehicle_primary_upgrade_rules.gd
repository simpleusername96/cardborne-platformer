class_name VehiclePrimaryUpgradeRules
extends RefCounted

## Canonical primary-fire behavior rules shared by runtime and card previews.

const MAX_SPLIT_LEVEL := 3
const MAX_PIERCE_LEVEL := 4
const SPLIT_ANGLE := deg_to_rad(7.0)


static func projectiles_per_volley(level: int) -> int:
	return 1 + mini(clampi(level, 0, MAX_SPLIT_LEVEL), 2)


static func projectile_angle(level: int, shot_serial: int, projectile_index: int) -> float:
	var bounded_level := clampi(level, 0, MAX_SPLIT_LEVEL)
	if projectile_index <= 0 or bounded_level <= 0:
		return 0.0
	if bounded_level == 1:
		return (-1.0 if shot_serial % 2 == 0 else 1.0) * SPLIT_ANGLE
	return (-SPLIT_ANGLE if projectile_index == 1 else SPLIT_ANGLE)


static func projectile_damage_scale(level: int, projectile_index: int) -> float:
	var bounded_level := clampi(level, 0, MAX_SPLIT_LEVEL)
	if projectile_index <= 0 or bounded_level <= 0:
		return 1.0
	if bounded_level == 1:
		return 0.40
	return 0.40 if bounded_level == 3 else 0.325


static func total_volley_damage_percent(level: int) -> float:
	var total := 0.0
	for projectile_index in projectiles_per_volley(level):
		total += projectile_damage_scale(level, projectile_index)
	return total * 100.0


static func additional_penetrations(level: int) -> int:
	return clampi(level, 0, MAX_PIERCE_LEVEL)
