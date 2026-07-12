class_name PlayerBuildSnapshot
extends RefCounted

var _values: Dictionary
var _source_breakdown: Dictionary
var _validation_errors: Array


func _init(
	values: Dictionary = {},
	source_breakdown: Dictionary = {},
	validation_errors: Array = []
) -> void:
	_values = values.duplicate(true)
	_source_breakdown = source_breakdown.duplicate(true)
	_validation_errors = validation_errors.duplicate(true)


func get_values() -> Dictionary:
	return _values.duplicate(true)


func has_stat(stat_id: StringName) -> bool:
	return _values.has(String(stat_id))


func get_stat(stat_id: StringName, fallback: float = 0.0) -> float:
	return float(_values.get(String(stat_id), fallback))


func get_source_breakdown() -> Dictionary:
	return _source_breakdown.duplicate(true)


func get_source_effects(source_id: StringName) -> Array:
	var records: Variant = _source_breakdown.get(String(source_id), [])
	if records is Array:
		return records.duplicate(true)
	return []


func get_validation_errors() -> Array:
	return _validation_errors.duplicate(true)


func is_valid() -> bool:
	return _validation_errors.is_empty()
