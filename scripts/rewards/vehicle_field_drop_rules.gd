class_name VehicleFieldDropRules
extends RefCounted

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
## The field only carries readable recovery and XP affordances. All temporary
## combat modifiers belong to the upgrade system instead of random pickups.

const PICKUP_TYPES: Array[StringName] = [&"experience_recall"]


static func experience_for_enemy(enemy: EnemyState) -> int:
	var role := enemy.role
	if role == &"boss":
		return 24
	var base := 5
	match enemy.health_class:
		&"swarm": base = 3
		&"priority": base = 10
	return ceili(float(base) * (1.5 if enemy.family_trait.is_empty() else 1.0))


static func pickup_is_valid(kind: StringName) -> bool:
	return kind in PICKUP_TYPES
