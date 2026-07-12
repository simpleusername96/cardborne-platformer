class_name RewardResult
extends RefCounted

var applied: bool
var duplicate: bool
var transaction_id: StringName
var grants: Dictionary
var message: String


func _init(
	was_applied: bool = false,
	was_duplicate: bool = false,
	id: StringName = &"",
	resolved_grants: Dictionary = {},
	result_message: String = ""
) -> void:
	applied = was_applied
	duplicate = was_duplicate
	transaction_id = id
	grants = resolved_grants.duplicate(true)
	message = result_message


func to_dictionary() -> Dictionary:
	return {
		"applied": applied,
		"duplicate": duplicate,
		"transaction_id": String(transaction_id),
		"grants": grants.duplicate(true),
		"message": message,
	}
