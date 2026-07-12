class_name ProfileCommandResult
extends RefCounted

var ok: bool
var changed: bool
var duplicate: bool
var code: StringName
var message: String
var payload: Dictionary


func _init(
	succeeded: bool = false,
	did_change: bool = false,
	result_code: StringName = &"rejected",
	result_message: String = "",
	result_payload: Dictionary = {},
	was_duplicate: bool = false
) -> void:
	ok = succeeded
	changed = did_change
	duplicate = was_duplicate
	code = result_code
	message = result_message
	payload = result_payload.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"ok": ok,
		"changed": changed,
		"duplicate": duplicate,
		"code": String(code),
		"message": message,
		"payload": payload.duplicate(true),
	}
