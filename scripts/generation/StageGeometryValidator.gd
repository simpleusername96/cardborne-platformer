class_name StageGeometryValidator
extends RefCounted

const MIN_CRITICAL_LANDING_WIDTH := 220.0
const POSITION_TOLERANCE := 1.0


static func validate_assembly(
	plan: StagePlan,
	catalog: RoomCatalog,
	assembly: StageAssemblyResult,
	movement_limits: Dictionary
) -> PackedStringArray:
	var errors := PackedStringArray()
	if plan == null or catalog == null or assembly == null or not assembly.success:
		errors.append("Geometry validation needs a successful StageAssemblyResult.")
		return errors
	var hosts := assembly.get_room_hosts()
	_validate_room_bounds(errors, plan, catalog, assembly.get_room_positions())
	_validate_required_surfaces(errors, plan, hosts, movement_limits)
	_validate_optional_return(errors, plan, catalog, hosts)
	_validate_hazard_recovery(errors, plan, hosts)
	return errors


static func _validate_room_bounds(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	positions: Dictionary
) -> void:
	var rows: Array[Dictionary] = []
	for room in plan.get_rooms():
		var template := catalog.get_room_by_id(room.template_id)
		if template == null or not positions.has(String(room.id)):
			continue
		rows.append({
			"id": room.id,
			"rect": Rect2(
				positions[String(room.id)] + template.bounds.position,
				template.bounds.size
			),
		})
	for first_index in rows.size():
		for second_index in range(first_index + 1, rows.size()):
			var first: Dictionary = rows[first_index]
			var second: Dictionary = rows[second_index]
			if (first["rect"] as Rect2).intersects(second["rect"] as Rect2):
				errors.append(
					"Assembled rooms '%s' and '%s' overlap."
					% [first["id"], second["id"]]
				)


static func _validate_required_surfaces(
	errors: PackedStringArray,
	plan: StagePlan,
	hosts: Dictionary,
	movement_limits: Dictionary
) -> void:
	var max_gap := float(movement_limits.get("max_required_gap", 0.0))
	var max_ledge := float(movement_limits.get("max_required_ledge", 0.0))
	for room in plan.get_rooms():
		if not room.required_route:
			continue
		var host := hosts.get(String(room.id)) as RoomTemplateHost
		if host == null:
			errors.append("Required room '%s' has no assembled host." % room.id)
			continue
		var surfaces: Array[Dictionary] = []
		for surface in host.get_support_surfaces():
			if bool(surface.get("critical", false)):
				surfaces.append(surface)
		surfaces.sort_custom(
			func(left: Dictionary, right: Dictionary) -> bool:
				return float(left["x"]) < float(right["x"])
		)
		if surfaces.is_empty():
			errors.append("Required room '%s' has no critical support surfaces." % room.id)
			continue
		for surface_index in surfaces.size():
			var surface := surfaces[surface_index]
			if float(surface["width"]) < MIN_CRITICAL_LANDING_WIDTH:
				errors.append("Required room '%s' has a narrow critical landing." % room.id)
			if surface_index == 0:
				continue
			var previous := surfaces[surface_index - 1]
			var gap := float(surface["x"]) - (float(previous["x"]) + float(previous["width"]))
			if gap > max_gap:
				errors.append("Required room '%s' has an internal gap beyond route limits." % room.id)
			if absf(float(surface["top"]) - float(previous["top"])) > max_ledge:
				errors.append("Required room '%s' has an internal rise beyond route limits." % room.id)
		_validate_room_socket_access(errors, plan, room, host, surfaces, max_gap)


static func _validate_room_socket_access(
	errors: PackedStringArray,
	plan: StagePlan,
	room: PlannedRoom,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary],
	max_gap: float
) -> void:
	var socket_ids: Array[StringName] = []
	for connection in plan.get_connections():
		if connection.route_role != &"critical":
			continue
		if connection.from_room_id == room.id:
			socket_ids.append(connection.from_socket_id)
		if connection.to_room_id == room.id:
			socket_ids.append(connection.to_socket_id)
	for socket_id in socket_ids:
		var marker_position: Variant = _socket_position(host.template_data, socket_id)
		if marker_position == null:
			continue
		var nearest := INF
		for surface in surfaces:
			var start := float(surface["x"])
			var end := start + float(surface["width"])
			var x := (marker_position as Vector2).x
			var distance := 0.0 if x >= start and x <= end else minf(absf(x - start), absf(x - end))
			nearest = minf(nearest, distance)
		if nearest > max_gap:
			errors.append(
				"Required room '%s' socket '%s' cannot reach critical support."
				% [room.id, socket_id]
			)


static func _validate_optional_return(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	hosts: Dictionary
) -> void:
	for room in plan.get_rooms():
		if room.required_route:
			continue
		var host := hosts.get(String(room.id)) as RoomTemplateHost
		var return_connection := _connection_from(plan, room.id, &"return")
		if host == null or return_connection == null:
			errors.append("Optional room '%s' needs an authored return route." % room.id)
			continue
		var target_host := hosts.get(String(return_connection.to_room_id)) as RoomTemplateHost
		var optional_data := catalog.get_room_by_id(room.template_id)
		var target_room := _room_by_id(plan, return_connection.to_room_id)
		var target_data := (
			catalog.get_room_by_id(target_room.template_id)
			if target_room != null
			else null
		)
		if optional_data == null or target_data == null:
			errors.append("Optional room '%s' return room references are invalid." % room.id)
			continue
		var from_socket := _find_socket(optional_data.exit_sockets, return_connection.from_socket_id)
		var to_socket := _find_socket(target_data.entry_sockets, return_connection.to_socket_id)
		if target_host == null or from_socket == null or to_socket == null:
			errors.append("Optional room '%s' return socket references are invalid." % room.id)
			continue
		if from_socket.transition_type != &"rope":
			continue
		var rope := _find_climbable(host)
		if rope == null:
			errors.append("Optional room '%s' rope return needs an authored climbable." % room.id)
			continue
		var rope_top := rope.global_position.y - rope.climbable_size.y * 0.5
		var rope_bottom := rope.global_position.y + rope.climbable_size.y * 0.5
		var target_support := target_host.global_position.y + to_socket.support_top
		var optional_support := host.global_position.y + from_socket.support_top
		if rope_top > target_support + POSITION_TOLERANCE:
			errors.append("Optional room '%s' return rope does not reach upper support." % room.id)
		if rope_bottom < optional_support - POSITION_TOLERANCE:
			errors.append("Optional room '%s' return rope does not reach lower support." % room.id)


static func _validate_hazard_recovery(
	errors: PackedStringArray,
	plan: StagePlan,
	hosts: Dictionary
) -> void:
	for room in plan.get_rooms():
		var host := hosts.get(String(room.id)) as RoomTemplateHost
		if host == null or host.template_data == null:
			continue
		for anchor in host.template_data.hazard_anchors:
			if anchor != null and not String(anchor.safe_zone_id).is_empty():
				if host.get_anchor_by_id(&"Recovery", anchor.safe_zone_id) == null:
					errors.append(
						"Room '%s' hazard anchor '%s' has no safe-zone owner."
						% [room.id, anchor.id]
					)


static func _socket_position(data: RoomTemplateData, socket_id: StringName) -> Variant:
	for socket in data.entry_sockets + data.exit_sockets:
		if socket != null and socket.id == socket_id:
			return socket.local_position
	return null


static func _connection_from(
	plan: StagePlan,
	room_id: StringName,
	role: StringName
) -> PlannedConnection:
	for connection in plan.get_connections():
		if connection.from_room_id == room_id and connection.route_role == role:
			return connection
	return null


static func _find_socket(
	sockets: Array[RoomSocketData],
	socket_id: StringName
) -> RoomSocketData:
	for socket in sockets:
		if socket != null and socket.id == socket_id:
			return socket
	return null


static func _room_by_id(plan: StagePlan, room_id: StringName) -> PlannedRoom:
	for room in plan.get_rooms():
		if room.id == room_id:
			return room
	return null


static func _find_climbable(host: Node) -> Climbable:
	var named_return := host.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable
	if named_return != null:
		return named_return
	for child in host.find_children("*", "", true, false):
		if child is Climbable:
			return child as Climbable
	return null
