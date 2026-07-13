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
	_validate_connection_openings(errors, plan, catalog, hosts)
	_validate_optional_return(errors, plan, catalog, hosts, movement_limits)
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


static func _validate_connection_openings(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	hosts: Dictionary
) -> void:
	for connection in plan.get_connections():
		var from_room := plan.get_room(connection.from_room_id)
		var to_room := plan.get_room(connection.to_room_id)
		if from_room == null or to_room == null:
			continue
		var from_data := catalog.get_room_by_id(from_room.template_id)
		var to_data := catalog.get_room_by_id(to_room.template_id)
		if from_data == null or to_data == null:
			continue
		_validate_connected_socket_clearance(
			errors,
			connection,
			hosts.get(String(from_room.id)) as RoomTemplateHost,
			_find_socket(from_data.exit_sockets, connection.from_socket_id),
			&"source"
		)
		_validate_connected_socket_clearance(
			errors,
			connection,
			hosts.get(String(to_room.id)) as RoomTemplateHost,
			_find_socket(to_data.entry_sockets, connection.to_socket_id),
			&"target"
		)


static func _validate_connected_socket_clearance(
	errors: PackedStringArray,
	connection: PlannedConnection,
	host: RoomTemplateHost,
	socket: RoomSocketData,
	endpoint: StringName
) -> void:
	if host == null or socket == null:
		return
	for blocker in host.get_socket_clearance_blockers(socket):
		errors.append(
			"Connection '%s' %s socket '%s/%s' is blocked by '%s'."
			% [connection.id, endpoint, host.room_id, socket.id, blocker]
		)


static func _validate_optional_return(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	hosts: Dictionary,
	movement_limits: Dictionary
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
		_validate_rope_support_contract(
			errors,
			room.id,
			host,
			target_host,
			rope,
			from_socket,
			to_socket,
			movement_limits
		)


static func _validate_rope_support_contract(
	errors: PackedStringArray,
	room_id: StringName,
	host: RoomTemplateHost,
	target_host: RoomTemplateHost,
	rope: Climbable,
	from_socket: RoomSocketData,
	to_socket: RoomSocketData,
	movement_limits: Dictionary
) -> void:
	var local_surfaces := _collect_support_surfaces(host)
	var target_surfaces := _collect_support_surfaces(target_host)
	var rope_local_x := rope.global_position.x - host.global_position.x
	var target_local_x := rope.global_position.x - target_host.global_position.x
	var entry_support := _surface_for_rope_endpoint(
		local_surfaces,
		StringName(rope.get_meta("entry_support", &"")),
		rope_local_x,
		from_socket.support_top
	)
	var exit_support := _surface_for_rope_endpoint(
		target_surfaces,
		StringName(rope.get_meta("exit_support", &"")),
		target_local_x,
		to_socket.support_top
	)
	if entry_support.is_empty():
		errors.append("Optional room '%s' return rope has no lower mount support." % room_id)
		return
	if exit_support.is_empty():
		errors.append("Optional room '%s' return rope has no upper dismount support." % room_id)
		return

	var required_overlap := float(rope.get_meta("support_overlap", 16.0))
	var rope_half_width := rope.climbable_size.x * 0.5
	if _support_overlap(entry_support, rope_local_x, rope_half_width) < required_overlap:
		errors.append("Optional room '%s' return rope misses its lower mount support." % room_id)
	if _support_overlap(exit_support, target_local_x, rope_half_width) < required_overlap:
		errors.append("Optional room '%s' return rope misses its upper dismount support." % room_id)
	if absf(float(entry_support["top"]) - from_socket.support_top) > POSITION_TOLERANCE:
		errors.append("Optional room '%s' return rope lower support mismatches its socket." % room_id)
	if absf(float(exit_support["top"]) - to_socket.support_top) > POSITION_TOLERANCE:
		errors.append("Optional room '%s' return rope upper support mismatches its socket." % room_id)
	if not bool(exit_support.get("one_way", false)):
		errors.append("Optional room '%s' return rope terminates beneath solid terrain." % room_id)
	_validate_recovery_paths(
		errors,
		room_id,
		host,
		local_surfaces,
		StringName(entry_support["id"]),
		movement_limits
	)


static func _validate_recovery_paths(
	errors: PackedStringArray,
	room_id: StringName,
	host: RoomTemplateHost,
	surfaces: Array[Dictionary],
	return_support_id: StringName,
	movement_limits: Dictionary
) -> void:
	var graph := _build_support_graph(host, surfaces, movement_limits)
	for recovery in host.get_typed_anchors(&"Recovery"):
		var support := _surface_by_id(
			surfaces,
			StringName(recovery.get_meta("support_id", &""))
		)
		if support.is_empty():
			support = _surface_at(surfaces, recovery.position.x, recovery.position.y)
		if support.is_empty():
			errors.append(
				"Optional room '%s' recovery '%s' has no support surface."
				% [room_id, recovery.anchor_id]
			)
			continue
		if not _graph_reaches(graph, StringName(support["id"]), return_support_id):
			errors.append(
				"Optional room '%s' recovery '%s' cannot reach the return rope."
				% [room_id, recovery.anchor_id]
			)


static func _build_support_graph(
	host: RoomTemplateHost,
	surfaces: Array[Dictionary],
	movement_limits: Dictionary
) -> Dictionary:
	var graph: Dictionary = {}
	var max_gap := float(movement_limits.get("max_required_gap", 0.0))
	var max_ledge := float(movement_limits.get("max_required_ledge", 0.0))
	for surface in surfaces:
		graph[String(surface["id"])] = PackedStringArray()
	for from_surface in surfaces:
		for to_surface in surfaces:
			if from_surface["id"] == to_surface["id"]:
				continue
			if _support_transition_is_safe(from_surface, to_surface, max_gap, max_ledge):
				_add_graph_edge(
					graph,
					StringName(from_surface["id"]),
					StringName(to_surface["id"])
				)
	for child in host.find_children("*", "", true, false):
		if not child is Climbable:
			continue
		var entry_id := StringName(child.get_meta("entry_support", &""))
		var exit_id := StringName(child.get_meta("exit_support", &""))
		if graph.has(String(entry_id)) and graph.has(String(exit_id)):
			_add_graph_edge(graph, entry_id, exit_id)
			_add_graph_edge(graph, exit_id, entry_id)
	return graph


static func _add_graph_edge(graph: Dictionary, from_id: StringName, to_id: StringName) -> void:
	var key := String(from_id)
	var neighbors: PackedStringArray = graph.get(key, PackedStringArray())
	if not neighbors.has(String(to_id)):
		neighbors.append(String(to_id))
		graph[key] = neighbors


static func _support_transition_is_safe(
	from_surface: Dictionary,
	to_surface: Dictionary,
	max_gap: float,
	max_ledge: float
) -> bool:
	var from_start := float(from_surface["x"])
	var from_end := from_start + float(from_surface["width"])
	var to_start := float(to_surface["x"])
	var to_end := to_start + float(to_surface["width"])
	var gap := maxf(maxf(from_start, to_start) - minf(from_end, to_end), 0.0)
	var upward_rise := float(from_surface["top"]) - float(to_surface["top"])
	return gap <= max_gap + POSITION_TOLERANCE and upward_rise <= max_ledge + POSITION_TOLERANCE


static func _graph_reaches(graph: Dictionary, start: StringName, target: StringName) -> bool:
	if start == target:
		return true
	var pending := PackedStringArray([String(start)])
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current := pending[0]
		pending.remove_at(0)
		if visited.has(current):
			continue
		visited[current] = true
		for next_id in graph.get(current, PackedStringArray()):
			if next_id == String(target):
				return true
			if not visited.has(next_id):
				pending.append(next_id)
	return false


static func _collect_support_surfaces(host: RoomTemplateHost) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	for root_name in [&"Terrain", &"OneWay"]:
		var surface_root := host.get_node_or_null(String(root_name))
		if surface_root == null:
			continue
		for child in surface_root.get_children():
			if not child is StaticBody2D:
				continue
			var shape_node := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var rectangle := shape_node.shape as RectangleShape2D if shape_node != null else null
			if rectangle == null:
				continue
			var surface_id := StringName(child.get_meta(
				"surface_id",
				"%s/%s" % [root_name, child.name]
			))
			var width := float(child.get_meta("support_width", rectangle.size.x))
			surfaces.append({
				"id": surface_id,
				"x": child.position.x - width * 0.5,
				"width": width,
				"top": float(child.get_meta("support_top", child.position.y)),
				"one_way": (
					root_name == &"OneWay"
					or bool(child.get_meta("one_way", false))
					or shape_node.one_way_collision
				),
			})
	return surfaces


static func _surface_for_rope_endpoint(
	surfaces: Array[Dictionary],
	declared_id: StringName,
	x: float,
	top: float
) -> Dictionary:
	var declared := _surface_by_id(surfaces, declared_id)
	if not declared.is_empty():
		return declared
	return _surface_at(surfaces, x, top)


static func _surface_by_id(
	surfaces: Array[Dictionary],
	surface_id: StringName
) -> Dictionary:
	if surface_id == &"":
		return {}
	for surface in surfaces:
		if StringName(surface["id"]) == surface_id:
			return surface
	return {}


static func _surface_at(
	surfaces: Array[Dictionary],
	x: float,
	top: float
) -> Dictionary:
	for surface in surfaces:
		var start := float(surface["x"])
		var end := start + float(surface["width"])
		if x >= start - POSITION_TOLERANCE and x <= end + POSITION_TOLERANCE:
			if absf(float(surface["top"]) - top) <= POSITION_TOLERANCE:
				return surface
	return {}


static func _support_overlap(surface: Dictionary, rope_x: float, rope_half_width: float) -> float:
	var support_start := float(surface["x"])
	var support_end := support_start + float(surface["width"])
	return maxf(
		minf(support_end, rope_x + rope_half_width)
		- maxf(support_start, rope_x - rope_half_width),
		0.0
	)


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
