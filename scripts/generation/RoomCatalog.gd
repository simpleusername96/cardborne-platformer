class_name RoomCatalog
extends Resource

@export var id: StringName = &"lower_ruins_rooms"
@export var display_name: String = "Lower Ruins Rooms"
@export var content_version: int = 1
@export var rooms: Array[RoomTemplateData] = []


func get_room_by_id(room_id: StringName) -> RoomTemplateData:
	for room in rooms:
		if room != null and room.id == room_id:
			return room
	return null


func has_room(room_id: StringName) -> bool:
	return get_room_by_id(room_id) != null


func get_rooms_for_role(
	stage_id: StringName,
	role: StringName,
	required_route: bool
) -> Array[RoomTemplateData]:
	var matches: Array[RoomTemplateData] = []
	for room in rooms:
		if (
			room != null
			and room.role == role
			and room.required_route == required_route
			and room.stage_tags.has(stage_id)
		):
			matches.append(room)
	return matches


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Room catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Room catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Room catalog '%s' needs a positive content version." % id)
	if rooms.is_empty():
		errors.append("Room catalog '%s' needs at least one room." % id)

	var seen_room_ids: Dictionary = {}
	for room_index in rooms.size():
		var room := rooms[room_index]
		if room == null:
			errors.append("Room template at index %d is null." % room_index)
			continue
		ContentId.validate(errors, "Room template ID", room.id)
		if seen_room_ids.has(room.id):
			errors.append("Duplicate room template ID '%s'." % room.id)
		seen_room_ids[room.id] = true
		for definition_error in room.validate_definition():
			errors.append("Room template '%s': %s" % [room.id, definition_error])
		_validate_socket_ids(errors, room)
	return errors


func _validate_socket_ids(errors: PackedStringArray, room: RoomTemplateData) -> void:
	var seen_socket_ids: Dictionary = {}
	for sockets in [room.entry_sockets, room.exit_sockets]:
		for socket in sockets:
			if socket == null:
				continue
			ContentId.validate(errors, "Room '%s' socket ID" % room.id, socket.id)
			if seen_socket_ids.has(socket.id):
				errors.append(
					"Room template '%s' repeats socket ID '%s' across its contract."
					% [room.id, socket.id]
				)
			seen_socket_ids[socket.id] = true
