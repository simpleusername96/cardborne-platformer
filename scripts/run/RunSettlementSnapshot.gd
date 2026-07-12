class_name RunSettlementSnapshot
extends RefCounted

const OUTCOME_VICTORY := &"victory"
const OUTCOME_DEATH := &"death"

var _data: Dictionary


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func get_outcome() -> StringName:
	return StringName(_data.get("outcome", ""))


func is_victory() -> bool:
	return get_outcome() == OUTCOME_VICTORY


func get_value(key: StringName, fallback: Variant = null) -> Variant:
	var value: Variant = _data.get(String(key), fallback)
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)
