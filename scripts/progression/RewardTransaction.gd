class_name RewardTransaction
extends RefCounted

var _id: StringName
var _source_id: StringName
var _grants: Dictionary
var _equipment_discoveries: Array[StringName]
var _blueprint_unlocks: Array[StringName]
var _spirit_stone_unlocks: Array[StringName]

var id: StringName:
	get:
		return _id
var source_id: StringName:
	get:
		return _source_id


func _init(
	transaction_id: StringName = &"",
	reward_source_id: StringName = &"",
	grants: Dictionary = {},
	equipment_discoveries: Array[StringName] = [],
	blueprint_unlocks: Array[StringName] = [],
	spirit_stone_unlocks: Array[StringName] = []
) -> void:
	_id = transaction_id
	_source_id = reward_source_id
	_grants = grants.duplicate(true)
	_equipment_discoveries = equipment_discoveries.duplicate()
	_blueprint_unlocks = blueprint_unlocks.duplicate()
	_spirit_stone_unlocks = spirit_stone_unlocks.duplicate()


func get_grants() -> Dictionary:
	return _grants.duplicate(true)


func get_equipment_discoveries() -> Array[StringName]:
	return _equipment_discoveries.duplicate()


func get_blueprint_unlocks() -> Array[StringName]:
	return _blueprint_unlocks.duplicate()


func get_spirit_stone_unlocks() -> Array[StringName]:
	return _spirit_stone_unlocks.duplicate()


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"source_id": String(_source_id),
		"grants": get_grants(),
		"equipment_discoveries": _names_to_strings(_equipment_discoveries),
		"blueprint_unlocks": _names_to_strings(_blueprint_unlocks),
		"spirit_stone_unlocks": _names_to_strings(_spirit_stone_unlocks),
	}


func _names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
