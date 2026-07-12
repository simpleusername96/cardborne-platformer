class_name RunSnapshot
extends RefCounted

var _data: Dictionary


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func get_value(key: StringName, fallback: Variant = null) -> Variant:
	var value: Variant = _data.get(String(key), fallback)
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)
