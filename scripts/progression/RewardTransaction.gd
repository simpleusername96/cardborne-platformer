class_name RewardTransaction
extends RefCounted

var _id: StringName
var _source_id: StringName
var _grants: Dictionary

var id: StringName:
	get:
		return _id
var source_id: StringName:
	get:
		return _source_id


func _init(
	transaction_id: StringName = &"",
	reward_source_id: StringName = &"",
	grants: Dictionary = {}
) -> void:
	_id = transaction_id
	_source_id = reward_source_id
	_grants = grants.duplicate(true)


func get_grants() -> Dictionary:
	return _grants.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"source_id": String(_source_id),
		"grants": get_grants(),
	}
