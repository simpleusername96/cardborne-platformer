class_name VehiclePrimaryUpgradeRules
extends RefCounted

## Canonical primary-fire behavior rules shared by runtime and card previews.

const MAX_SPLIT_LEVEL := 6
const MAX_PIERCE_LEVEL := 7
const SPLIT_ANGLE := deg_to_rad(7.0)


static func projectiles_per_volley(level: int) -> int:
	var bounded_level := clampi(level, 0, MAX_SPLIT_LEVEL)
	return 1 if bounded_level == 0 else (2 if bounded_level <= 2 else 3)


static func projectile_angle(level: int, shot_serial: int, projectile_index: int) -> float:
	var bounded_level := clampi(level, 0, MAX_SPLIT_LEVEL)
	if projectile_index <= 0 or bounded_level <= 0:
		return 0.0
	if bounded_level <= 2:
		return (-1.0 if shot_serial % 2 == 0 else 1.0) * SPLIT_ANGLE
	return (-SPLIT_ANGLE if projectile_index == 1 else SPLIT_ANGLE)


static func projectile_damage_scale(level: int, projectile_index: int) -> float:
	var bounded_level := clampi(level, 0, MAX_SPLIT_LEVEL)
	if projectile_index <= 0 or bounded_level <= 0:
		return 1.0
	if bounded_level <= 2:
		return [0.0, 0.40, 0.55][bounded_level]
	return [0.0, 0.0, 0.0, 0.325, 0.42, 0.52, 0.67][bounded_level]


static func total_volley_damage_percent(level: int) -> float:
	var total := 0.0
	for projectile_index in projectiles_per_volley(level):
		total += projectile_damage_scale(level, projectile_index)
	return total * 100.0


static func additional_penetrations(level: int) -> int:
	var bounded_level := clampi(level, 0, MAX_PIERCE_LEVEL)
	return 0 if bounded_level == 0 else mini(4, ceili(float(bounded_level) * 0.5))
