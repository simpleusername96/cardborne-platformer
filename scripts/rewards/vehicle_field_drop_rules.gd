class_name VehicleFieldDropRules
extends RefCounted

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
## The field only carries readable recovery and XP affordances. All temporary
## combat modifiers belong to the upgrade system instead of random pickups.

const PICKUP_TYPES: Array[StringName] = [&"repair", &"experience_recall"]


static func experience_for_enemy(enemy: EnemyState) -> int:
	if not enemy.carrier_id.is_empty() or enemy.summoned:
		return 0
	var role := enemy.role
	if role == &"boss_pylon":
		return 0
	if role == &"stage_boss":
		return 24
	var base := 2
	match enemy.health_class:
		&"swarm": base = 1
		&"priority": base = 4
	return ceili(float(base) * (1.5 if not enemy.elite_trait.is_empty() else 1.0))


static func pickup_is_valid(kind: StringName) -> bool:
	return kind in PICKUP_TYPES
