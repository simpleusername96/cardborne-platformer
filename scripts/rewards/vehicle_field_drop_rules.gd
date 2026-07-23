class_name VehicleFieldDropRules
extends RefCounted

## The field only carries readable recovery and XP affordances. All temporary
## combat modifiers belong to the upgrade system instead of random pickups.

const PICKUP_TYPES: Array[StringName] = [&"repair", &"experience_recall"]


static func experience_for_enemy(enemy: Dictionary) -> int:
	if String(enemy.get("carrier_id", "")) != "" or bool(enemy.get("summoned", false)):
		return 0
	var role := StringName(enemy.get("role", &""))
	if role == &"boss_pylon":
		return 0
	if role == &"stage_boss":
		return 24
	match StringName(enemy.get("health_class", &"standard")):
		&"swarm": return 1
		&"priority": return 4
		_: return 2


static func pickup_is_valid(kind: StringName) -> bool:
	return kind in PICKUP_TYPES
