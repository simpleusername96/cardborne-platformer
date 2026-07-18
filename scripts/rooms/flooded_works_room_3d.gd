class_name FloodedWorksRoom3D
extends Node3D

@export var room_id: StringName
@export var map_size_m := Vector2.ZERO
@export var camera_bounds := Rect2()
@export_file("*.tmj") var source_path := ""
@export var source_sha256 := ""


func get_entry_marker(socket_id: StringName) -> Marker3D:
	return get_node_or_null("EntryMarkers/%s" % socket_id) as Marker3D


func get_gates() -> Array[RoomGate3D]:
	var result: Array[RoomGate3D] = []
	for child in get_node("Connections").get_children():
		if child is RoomGate3D:
			result.append(child)
	return result
