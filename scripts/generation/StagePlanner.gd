class_name StagePlanner
extends RefCounted

var _last_report: GenerationReport

var last_report: GenerationReport:
	get:
		return _last_report


func build_plan(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary,
	generation_attempt: int = 0
) -> StagePlan:
	var catalog_version := catalog.content_version if catalog != null else 0
	var profile_version := profile.content_version if profile != null else 0
	var streams := NamedRngStreams.new(
		run_seed,
		stage_index,
		catalog_version,
		profile_version,
		generation_attempt
	)
	_last_report = GenerationReport.new(
		run_seed,
		stage_index,
		profile.id if profile != null else &"",
		profile_version,
		catalog.id if catalog != null else &"",
		catalog_version,
		streams.get_stream_seeds(),
		generation_attempt
	)
	if catalog == null or profile == null:
		_last_report.record_failure(&"missing_input", "Stage planning needs a catalog and profile.")
		return null

	var preflight_errors := PackedStringArray()
	_append_errors(preflight_errors, catalog.validate_catalog(), "Room catalog")
	_append_errors(preflight_errors, profile.validate_definition(), "Stage profile")
	_append_errors(
		preflight_errors,
		RoomSocketCompatibility.validate_movement_limits(movement_limits),
		"Movement limits"
	)
	if not preflight_errors.is_empty():
		_last_report.record_validation_errors(preflight_errors)
		return null

	var graph_rng := streams.create_rng(&"room_graph")
	var optional_branch_count := _pick_branch_count(profile.optional_branch_count, graph_rng)
	var candidates_by_role: Array = []
	for role in profile.required_roles:
		var candidates := catalog.get_rooms_for_role(profile.id, role, true)
		candidates = _filter_budget_compatible(candidates, profile)
		_shuffle(candidates, graph_rng)
		if candidates.is_empty():
			_last_report.record_failure(
				&"missing_required_role",
				"No eligible room can satisfy required role '%s'." % role
			)
			return null
		candidates_by_role.append(candidates)

	var optional_candidates := catalog.get_rooms_for_role(
		profile.id,
		profile.optional_room_role,
		false
	)
	optional_candidates = _filter_budget_compatible(optional_candidates, profile)
	_shuffle(optional_candidates, graph_rng)
	if optional_candidates.size() < optional_branch_count:
		_last_report.record_failure(
			&"missing_optional_room",
			"Stage needs %d unique optional rooms, but only %d are eligible."
			% [optional_branch_count, optional_candidates.size()]
		)
		return null

	var selection := _search_route(
		0,
		candidates_by_role,
		optional_candidates,
		optional_branch_count,
		[],
		{},
		movement_limits
	)
	if selection.is_empty():
		_last_report.record_failure(
			&"no_compatible_route",
			"No unique required route with %d compatible rejoining optional branches exists."
			% optional_branch_count
		)
		return null

	var required_templates: Array[RoomTemplateData] = selection["required_rooms"]
	var optional_templates: Array[RoomTemplateData] = selection["optional_rooms"]
	var planned_rooms: Array[PlannedRoom] = []
	var encounter_rng := streams.create_rng(&"encounter")
	var hazard_rng := streams.create_rng(&"hazard")
	var reward_rng := streams.create_rng(&"reward")
	for room_index in required_templates.size():
		planned_rooms.append(
			_plan_room(
				required_templates[room_index],
				true,
				room_index,
				profile,
				encounter_rng,
				hazard_rng,
				reward_rng
			)
		)
	for branch_index in optional_templates.size():
		planned_rooms.append(
			_plan_room(
				optional_templates[branch_index],
				false,
				branch_index,
				profile,
				encounter_rng,
				hazard_rng,
				reward_rng
			)
		)

	var connections: Array[PlannedConnection] = selection["connections"]
	var encounters: Array[PlannedEncounter] = []
	var stage_plan := StagePlan.new(
		run_seed,
		stage_index,
		profile.id,
		profile.content_version,
		catalog.id,
		catalog.content_version,
		streams.get_stream_seeds(),
		planned_rooms,
		connections,
		encounters,
		StagePlan.CURRENT_SCHEMA_VERSION,
		generation_attempt
	)
	var validation_errors := StagePlanValidator.validate_plan(
		stage_plan,
		catalog,
		profile,
		movement_limits
	)
	if not validation_errors.is_empty():
		_last_report.record_validation_errors(validation_errors)
		return null

	var required_ids: Array[String] = []
	for room in required_templates:
		required_ids.append(String(room.id))
	_last_report.record_decision(&"required_route", {"room_ids": required_ids})
	var branch_decisions: Array[Dictionary] = []
	for branch_index in optional_templates.size():
		var branch_connection := _connection_by_id(
			connections,
			StringName("optional_branch_%d" % branch_index)
		)
		var return_connection := _connection_by_id(
			connections,
			StringName("optional_return_%d" % branch_index)
		)
		branch_decisions.append({
			"branch_index": branch_index,
			"room_id": String(optional_templates[branch_index].id),
			"from_room_id": String(branch_connection.from_room_id),
			"to_room_id": String(return_connection.to_room_id),
		})
	_last_report.record_decision(
		&"optional_branches",
		{"count": optional_templates.size(), "branches": branch_decisions}
	)
	return stage_plan


func plan_stage(
	catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary,
	generation_attempt: int = 0
) -> StagePlan:
	return build_plan(
		catalog,
		profile,
		run_seed,
		stage_index,
		movement_limits,
		generation_attempt
	)


func _search_route(
	role_index: int,
	candidates_by_role: Array,
	optional_candidates: Array[RoomTemplateData],
	optional_branch_count: int,
	selected: Array,
	used_template_ids: Dictionary,
	movement_limits: Dictionary
) -> Dictionary:
	if role_index >= candidates_by_role.size():
		var required_templates: Array[RoomTemplateData] = []
		for selected_room in selected:
			required_templates.append(selected_room)
		var route_connections := _build_required_connections(
			required_templates,
			movement_limits
		)
		if route_connections.is_empty():
			return {}
		var branches := _find_optional_branches(
			required_templates,
			optional_candidates,
			optional_branch_count,
			route_connections["used_sockets"],
			movement_limits
		)
		if branches.is_empty():
			return {}
		var connections: Array[PlannedConnection] = route_connections["connections"]
		connections.append_array(branches["connections"])
		return {
			"required_rooms": required_templates,
			"optional_rooms": branches["rooms"],
			"connections": connections,
		}

	var candidates: Array = candidates_by_role[role_index]
	for candidate_value in candidates:
		var candidate := candidate_value as RoomTemplateData
		if candidate == null or used_template_ids.has(candidate.id):
			continue
		if not selected.is_empty():
			var previous := selected[-1] as RoomTemplateData
			if RoomSocketCompatibility.find_pair(
				previous.exit_sockets,
				candidate.entry_sockets,
				&"critical",
				movement_limits
			).is_empty():
				continue
		selected.append(candidate)
		used_template_ids[candidate.id] = true
		var result := _search_route(
			role_index + 1,
			candidates_by_role,
			optional_candidates,
			optional_branch_count,
			selected,
			used_template_ids,
			movement_limits
		)
		if not result.is_empty():
			return result
		selected.pop_back()
		used_template_ids.erase(candidate.id)
	return {}


func _build_required_connections(
	required_rooms: Array[RoomTemplateData],
	movement_limits: Dictionary
) -> Dictionary:
	var connections: Array[PlannedConnection] = []
	var used_sockets: Dictionary = {}
	for room_index in maxi(required_rooms.size() - 1, 0):
		var from_room := required_rooms[room_index]
		var to_room := required_rooms[room_index + 1]
		var pair := _find_available_pair(
			from_room,
			to_room,
			&"critical",
			movement_limits,
			used_sockets
		)
		if pair.is_empty():
			return {}
		_reserve_pair(used_sockets, from_room, to_room, pair)
		var from_socket: RoomSocketData = pair["from"]
		var to_socket: RoomSocketData = pair["to"]
		connections.append(
			PlannedConnection.new(
				StringName("critical_%d" % room_index),
				from_room.id,
				from_socket.id,
				to_room.id,
				to_socket.id,
				&"critical"
			)
		)
	return {"connections": connections, "used_sockets": used_sockets}


func _find_optional_branches(
	required_rooms: Array[RoomTemplateData],
	optional_candidates: Array[RoomTemplateData],
	branch_count: int,
	reserved_sockets: Dictionary,
	movement_limits: Dictionary
) -> Dictionary:
	if branch_count == 0:
		var no_rooms: Array[RoomTemplateData] = []
		var no_connections: Array[PlannedConnection] = []
		return {"rooms": no_rooms, "connections": no_connections}
	var branch_sources: Array[RoomTemplateData] = []
	for room in required_rooms:
		if room.role == &"choice":
			branch_sources.append(room)
	if branch_sources.is_empty():
		return {}
	return _search_optional_branches(
		0,
		branch_count,
		branch_sources,
		optional_candidates,
		{},
		reserved_sockets.duplicate(),
		[],
		[],
		movement_limits
	)


func _search_optional_branches(
	branch_index: int,
	branch_count: int,
	branch_sources: Array[RoomTemplateData],
	optional_candidates: Array[RoomTemplateData],
	selected_optional_ids: Dictionary,
	used_sockets: Dictionary,
	selected_rooms: Array[RoomTemplateData],
	selected_connections: Array[PlannedConnection],
	movement_limits: Dictionary
) -> Dictionary:
	if branch_index >= branch_count:
		return {
			"rooms": selected_rooms.duplicate(),
			"connections": selected_connections.duplicate(),
		}
	for branch_source in branch_sources:
		for optional_room in optional_candidates:
			if selected_optional_ids.has(optional_room.id):
				continue
			for branch_pair in _find_available_pairs(
				branch_source,
				optional_room,
				&"optional",
				movement_limits,
				used_sockets
			):
				var branch_used := used_sockets.duplicate()
				_reserve_pair(branch_used, branch_source, optional_room, branch_pair)
				for return_pair in _find_available_pairs(
					optional_room,
					branch_source,
					&"return",
					movement_limits,
					branch_used
				):
					var next_used := branch_used.duplicate()
					_reserve_pair(next_used, optional_room, branch_source, return_pair)
					var branch_from: RoomSocketData = branch_pair["from"]
					var branch_to: RoomSocketData = branch_pair["to"]
					var return_from: RoomSocketData = return_pair["from"]
					var return_to: RoomSocketData = return_pair["to"]
					selected_rooms.append(optional_room)
					selected_optional_ids[optional_room.id] = true
					selected_connections.append(
						PlannedConnection.new(
							StringName("optional_branch_%d" % branch_index),
							branch_source.id,
							branch_from.id,
							optional_room.id,
							branch_to.id,
							&"optional"
						)
					)
					selected_connections.append(
						PlannedConnection.new(
							StringName("optional_return_%d" % branch_index),
							optional_room.id,
							return_from.id,
							branch_source.id,
							return_to.id,
							&"return"
						)
					)
					var result := _search_optional_branches(
						branch_index + 1,
						branch_count,
						branch_sources,
						optional_candidates,
						selected_optional_ids,
						next_used,
						selected_rooms,
						selected_connections,
						movement_limits
					)
					if not result.is_empty():
						return result
					selected_connections.pop_back()
					selected_connections.pop_back()
					selected_optional_ids.erase(optional_room.id)
					selected_rooms.pop_back()
	return {}


func _find_available_pair(
	from_room: RoomTemplateData,
	to_room: RoomTemplateData,
	route_role: StringName,
	movement_limits: Dictionary,
	used_sockets: Dictionary
) -> Dictionary:
	var pairs := _find_available_pairs(
		from_room,
		to_room,
		route_role,
		movement_limits,
		used_sockets
	)
	return {} if pairs.is_empty() else pairs[0]


func _find_available_pairs(
	from_room: RoomTemplateData,
	to_room: RoomTemplateData,
	route_role: StringName,
	movement_limits: Dictionary,
	used_sockets: Dictionary
) -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	for from_socket in from_room.exit_sockets:
		var from_key := _socket_key(from_room.id, &"exit", from_socket.id)
		if used_sockets.has(from_key):
			continue
		for to_socket in to_room.entry_sockets:
			var to_key := _socket_key(to_room.id, &"entry", to_socket.id)
			if used_sockets.has(to_key):
				continue
			if RoomSocketCompatibility.are_compatible(
				from_socket,
				to_socket,
				route_role,
				movement_limits
			):
				pairs.append({"from": from_socket, "to": to_socket})
	return pairs


func _connection_by_id(
	connections: Array[PlannedConnection],
	connection_id: StringName
) -> PlannedConnection:
	for connection in connections:
		if connection.id == connection_id:
			return connection
	return null


func _reserve_pair(
	used_sockets: Dictionary,
	from_room: RoomTemplateData,
	to_room: RoomTemplateData,
	pair: Dictionary
) -> void:
	var from_socket: RoomSocketData = pair["from"]
	var to_socket: RoomSocketData = pair["to"]
	used_sockets[_socket_key(from_room.id, &"exit", from_socket.id)] = true
	used_sockets[_socket_key(to_room.id, &"entry", to_socket.id)] = true


func _socket_key(room_id: StringName, side: StringName, socket_id: StringName) -> String:
	return "%s:%s:%s" % [room_id, side, socket_id]


func _filter_budget_compatible(
	candidates: Array[RoomTemplateData],
	profile: StageProfile
) -> Array[RoomTemplateData]:
	var compatible: Array[RoomTemplateData] = []
	for room in candidates:
		if (
			_budget_range_for(room.encounter_budget, profile, room.role, &"encounter").x >= 0
			and _budget_range_for(room.hazard_budget, profile, room.role, &"hazard").x >= 0
			and _budget_range_for(room.reward_budget, profile, room.role, &"reward").x >= 0
		):
			compatible.append(room)
	return compatible


func _plan_room(
	template: RoomTemplateData,
	required_route: bool,
	route_index: int,
	profile: StageProfile,
	encounter_rng: RandomNumberGenerator,
	hazard_rng: RandomNumberGenerator,
	reward_rng: RandomNumberGenerator
) -> PlannedRoom:
	var encounter_range := _budget_range_for(
		template.encounter_budget,
		profile,
		template.role,
		&"encounter"
	)
	var hazard_range := _budget_range_for(
		template.hazard_budget,
		profile,
		template.role,
		&"hazard"
	)
	var reward_range := _budget_range_for(
		template.reward_budget,
		profile,
		template.role,
		&"reward"
	)
	return PlannedRoom.new(
		template.id,
		template.id,
		template.content_version,
		template.role,
		required_route,
		route_index,
		_pick_budget(encounter_range, encounter_rng),
		_pick_budget(hazard_range, hazard_rng),
		_pick_budget(reward_range, reward_rng)
	)


func _budget_range_for(
	template_budget: Vector2i,
	profile: StageProfile,
	room_role: StringName,
	budget_kind: StringName
) -> Vector2i:
	var profile_budget := template_budget
	match budget_kind:
		&"encounter":
			if room_role == &"combat":
				profile_budget = profile.encounter_budget_per_combat_room
		&"hazard":
			profile_budget = profile.hazard_budget_per_room
		&"reward":
			profile_budget = profile.reward_budget_per_room
	var minimum := maxi(template_budget.x, profile_budget.x)
	var maximum := mini(template_budget.y, profile_budget.y)
	if maximum < minimum:
		return Vector2i(-1, -1)
	return Vector2i(minimum, maximum)


func _pick_budget(budget: Vector2i, rng: RandomNumberGenerator) -> int:
	if budget.x == budget.y:
		return budget.x
	return rng.randi_range(budget.x, budget.y)


func _pick_branch_count(branch_count: Vector2i, rng: RandomNumberGenerator) -> int:
	if branch_count.x == branch_count.y:
		return branch_count.x
	return rng.randi_range(branch_count.x, branch_count.y)


func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


func _append_errors(
	target: PackedStringArray,
	source: PackedStringArray,
	label: String
) -> void:
	for error in source:
		target.append("%s: %s" % [label, error])
