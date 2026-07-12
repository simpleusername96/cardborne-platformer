class_name StageAssemblyResult
extends RefCounted

var success: bool
var world_bounds: Rect2
var _room_hosts: Dictionary
var _room_positions: Dictionary
var _errors: PackedStringArray


func _init(
	was_successful: bool = false,
	assembled_bounds: Rect2 = Rect2(),
	room_hosts: Dictionary = {},
	room_positions: Dictionary = {},
	errors: PackedStringArray = PackedStringArray()
) -> void:
	success = was_successful
	world_bounds = assembled_bounds
	_room_hosts = room_hosts.duplicate()
	_room_positions = room_positions.duplicate(true)
	_errors = errors.duplicate()


func get_room_hosts() -> Dictionary:
	return _room_hosts.duplicate()


func get_room_positions() -> Dictionary:
	return _room_positions.duplicate(true)


func get_errors() -> PackedStringArray:
	return _errors.duplicate()
