class_name MerchantTransactionReceipt
extends RefCounted

var _data: Dictionary


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func is_applied() -> bool:
	return bool(_data.get("applied", false))


func is_duplicate() -> bool:
	return bool(_data.get("duplicate", false))


func get_message() -> String:
	return String(_data.get("message", ""))


func get_value(key: StringName, fallback: Variant = null) -> Variant:
	var value: Variant = _data.get(String(key), fallback)
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)
