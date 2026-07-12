class_name PlannedConnection
extends RefCounted

var _id: StringName
var _from_room_id: StringName
var _from_socket_id: StringName
var _to_room_id: StringName
var _to_socket_id: StringName
var _route_role: StringName

var id: StringName:
	get:
		return _id
var from_room_id: StringName:
	get:
		return _from_room_id
var from_socket_id: StringName:
	get:
		return _from_socket_id
var to_room_id: StringName:
	get:
		return _to_room_id
var to_socket_id: StringName:
	get:
		return _to_socket_id
var route_role: StringName:
	get:
		return _route_role


func _init(
	connection_id: StringName = &"",
	source_room_id: StringName = &"",
	source_socket_id: StringName = &"",
	target_room_id: StringName = &"",
	target_socket_id: StringName = &"",
	connection_route_role: StringName = &"critical"
) -> void:
	_id = connection_id
	_from_room_id = source_room_id
	_from_socket_id = source_socket_id
	_to_room_id = target_room_id
	_to_socket_id = target_socket_id
	_route_role = connection_route_role


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"from_room_id": String(_from_room_id),
		"from_socket_id": String(_from_socket_id),
		"to_room_id": String(_to_room_id),
		"to_socket_id": String(_to_socket_id),
		"route_role": String(_route_role),
	}


static func from_dictionary(data: Dictionary) -> PlannedConnection:
	return PlannedConnection.new(
		StringName(str(data.get("id", ""))),
		StringName(str(data.get("from_room_id", ""))),
		StringName(str(data.get("from_socket_id", ""))),
		StringName(str(data.get("to_room_id", ""))),
		StringName(str(data.get("to_socket_id", ""))),
		StringName(str(data.get("route_role", "critical")))
	)
