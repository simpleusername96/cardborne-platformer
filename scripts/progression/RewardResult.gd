class_name RewardResult
extends RefCounted

var applied: bool
var duplicate: bool
var transaction_id: StringName
var grants: Dictionary
var equipment_discoveries: Array[Dictionary]
var blueprint_unlocks: Array[Dictionary]
var spirit_stone_unlocks: Array[Dictionary]
var message: String


func _init(
	was_applied: bool = false,
	was_duplicate: bool = false,
	id: StringName = &"",
	resolved_grants: Dictionary = {},
	result_message: String = "",
	resolved_equipment_discoveries: Array = [],
	resolved_blueprint_unlocks: Array = [],
	resolved_spirit_stone_unlocks: Array = []
) -> void:
	applied = was_applied
	duplicate = was_duplicate
	transaction_id = id
	grants = resolved_grants.duplicate(true)
	equipment_discoveries = _dictionary_array(resolved_equipment_discoveries)
	blueprint_unlocks = _dictionary_array(resolved_blueprint_unlocks)
	spirit_stone_unlocks = _dictionary_array(resolved_spirit_stone_unlocks)
	message = result_message


func to_dictionary() -> Dictionary:
	return {
		"applied": applied,
		"duplicate": duplicate,
		"transaction_id": String(transaction_id),
		"grants": grants.duplicate(true),
		"equipment_discoveries": equipment_discoveries.duplicate(true),
		"blueprint_unlocks": blueprint_unlocks.duplicate(true),
		"spirit_stone_unlocks": spirit_stone_unlocks.duplicate(true),
		"message": message,
	}


func _dictionary_array(values: Array) -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for value in values:
		if value is Dictionary:
			copied.append(value.duplicate(true))
	return copied
