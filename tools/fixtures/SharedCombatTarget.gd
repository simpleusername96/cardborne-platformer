class_name SharedCombatTarget
extends Node2D

var current_health: int = 100
var delayed_damage_events: Array[Dictionary] = []


func receive_damage(damage_info: DamageInfo) -> void:
	current_health = maxi(current_health - damage_info.amount, 0)


func get_combat_snapshot() -> Dictionary:
	return {
		"mitigation": 0.0,
		"staggered": false,
		"lightweight": true,
	}


func apply_delayed_damage(
	source_id: StringName,
	duration: float,
	damage: int,
	source: Node
) -> void:
	delayed_damage_events.append({
		"source_id": source_id,
		"duration": duration,
		"damage": damage,
		"source": source,
	})
