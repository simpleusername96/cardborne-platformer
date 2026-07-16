class_name StageAssembler
extends RefCounted

const SOCKET_ALIGNMENT_TOLERANCE := 1.0


static func assemble(
	plan: StagePlan,
	catalog: RoomCatalog,
	rooms_root: Node2D
) -> StageAssemblyResult:
	var errors := PackedStringArray()
	if plan == null or catalog == null or rooms_root == null:
		errors.append("Stage assembly needs a plan, room catalog, and rooms root.")
		return StageAssemblyResult.new(false, Rect2(), {}, {}, errors)

	var positions := _resolve_room_positions(plan, catalog, errors)
	if not errors.is_empty():
		return StageAssemblyResult.new(false, Rect2(), {}, positions, errors)
	var active_exit_socket_ids := _active_exit_socket_ids(plan)
	var hosts: Dictionary = {}
	var bounds := Rect2()
	var has_bounds := false
	for planned_room in plan.get_rooms():
		var data := catalog.get_room_by_id(planned_room.template_id)
		if data == null or data.scene == null:
			errors.append("Planned room '%s' has no authored scene." % planned_room.id)
			break
		var host := data.scene.instantiate() as RoomTemplateHost
		if host == null:
			errors.append("Room '%s' did not instantiate as RoomTemplateHost." % data.id)
			break
		host.position = positions[String(planned_room.id)]
		rooms_root.add_child(host)
		var host_errors := host.configure(data)
		if not host_errors.is_empty():
			for host_error in host_errors:
				errors.append("Room '%s': %s" % [data.id, host_error])
			break
		host.configure_active_exit_routes(
			active_exit_socket_ids.get(String(planned_room.id), [])
		)
		hosts[String(planned_room.id)] = host
		var room_bounds := Rect2(host.position + data.bounds.position, data.bounds.size)
		bounds = room_bounds if not has_bounds else bounds.merge(room_bounds)
		has_bounds = true

	if not errors.is_empty():
		_cleanup_hosts(hosts)
		return StageAssemblyResult.new(false, Rect2(), {}, positions, errors)
	return StageAssemblyResult.new(true, bounds, hosts, positions, errors)


static func _active_exit_socket_ids(plan: StagePlan) -> Dictionary:
	var result: Dictionary = {}
	for connection in plan.get_connections():
		var room_key := String(connection.from_room_id)
		var socket_ids: Array = result.get(room_key, [])
		if not socket_ids.has(connection.from_socket_id):
			socket_ids.append(connection.from_socket_id)
		result[room_key] = socket_ids
	return result


static func _resolve_room_positions(
	plan: StagePlan,
	catalog: RoomCatalog,
	errors: PackedStringArray
) -> Dictionary:
	var positions: Dictionary = {}
	var required_rooms: Array[PlannedRoom] = []
	var optional_rooms: Array[PlannedRoom] = []
	for room in plan.get_rooms():
		if room.required_route:
			required_rooms.append(room)
		else:
			optional_rooms.append(room)
	required_rooms.sort_custom(
		func(left: PlannedRoom, right: PlannedRoom) -> bool:
			return left.route_index < right.route_index
	)
	if required_rooms.is_empty():
		errors.append("Stage assembly needs a required route.")
		return positions
	positions[String(required_rooms[0].id)] = Vector2.ZERO
	for route_index in range(required_rooms.size() - 1):
		var from_room := required_rooms[route_index]
		var to_room := required_rooms[route_index + 1]
		var connection := _find_connection(
			plan,
			from_room.id,
			to_room.id,
			&"critical"
		)
		if connection == null:
			errors.append("Required rooms '%s' and '%s' have no connection." % [from_room.id, to_room.id])
			return positions
		var aligned := _aligned_position(
			catalog,
			connection,
			positions[String(from_room.id)],
			errors
		)
		positions[String(to_room.id)] = aligned

	for optional_room in optional_rooms:
		var branch := _find_connection_to(plan, optional_room.id, &"optional")
		var return_connection := _find_connection_from(plan, optional_room.id, &"return")
		if branch == null or return_connection == null:
			errors.append("Optional room '%s' needs branch and return connections." % optional_room.id)
			continue
		if not positions.has(String(branch.from_room_id)):
			errors.append("Optional branch source '%s' is not positioned." % branch.from_room_id)
			continue
		var optional_position := _aligned_position(
			catalog,
			branch,
			positions[String(branch.from_room_id)],
			errors
		)
		positions[String(optional_room.id)] = optional_position
		if not positions.has(String(return_connection.to_room_id)):
			errors.append("Optional return target '%s' is not positioned." % return_connection.to_room_id)
			continue
		var expected_target_position := _aligned_position(
			catalog,
			return_connection,
			optional_position,
			errors
		)
		var actual_target_position: Vector2 = positions[String(return_connection.to_room_id)]
		if expected_target_position.distance_to(actual_target_position) > SOCKET_ALIGNMENT_TOLERANCE:
			errors.append(
				"Optional room '%s' return socket misses '%s' by %.2f px."
				% [
					optional_room.id,
					return_connection.to_room_id,
					expected_target_position.distance_to(actual_target_position),
				]
			)
	return positions


static func _aligned_position(
	catalog: RoomCatalog,
	connection: PlannedConnection,
	from_position: Vector2,
	errors: PackedStringArray
) -> Vector2:
	var from_data := catalog.get_room_by_id(connection.from_room_id)
	var to_data := catalog.get_room_by_id(connection.to_room_id)
	var from_socket := _find_socket(from_data, connection.from_socket_id, false)
	var to_socket := _find_socket(to_data, connection.to_socket_id, true)
	if from_socket == null or to_socket == null:
		errors.append("Connection '%s' references a missing socket." % connection.id)
		return from_position
	return from_position + from_socket.local_position - to_socket.local_position


static func _find_socket(
	data: RoomTemplateData,
	socket_id: StringName,
	is_entry: bool
) -> RoomSocketData:
	if data == null:
		return null
	var sockets := data.entry_sockets if is_entry else data.exit_sockets
	for socket in sockets:
		if socket != null and socket.id == socket_id:
			return socket
	return null


static func _find_connection(
	plan: StagePlan,
	from_room_id: StringName,
	to_room_id: StringName,
	route_role: StringName
) -> PlannedConnection:
	for connection in plan.get_connections():
		if (
			connection.from_room_id == from_room_id
			and connection.to_room_id == to_room_id
			and connection.route_role == route_role
		):
			return connection
	return null


static func _find_connection_to(
	plan: StagePlan,
	to_room_id: StringName,
	route_role: StringName
) -> PlannedConnection:
	for connection in plan.get_connections():
		if connection.to_room_id == to_room_id and connection.route_role == route_role:
			return connection
	return null


static func _find_connection_from(
	plan: StagePlan,
	from_room_id: StringName,
	route_role: StringName
) -> PlannedConnection:
	for connection in plan.get_connections():
		if connection.from_room_id == from_room_id and connection.route_role == route_role:
			return connection
	return null


static func _cleanup_hosts(hosts: Dictionary) -> void:
	for host in hosts.values():
		if is_instance_valid(host):
			var parent: Node = host.get_parent()
			if parent != null:
				parent.remove_child(host)
			host.queue_free()
