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
	if profile.required_roles.size() != 6:
		preflight_errors.append("Stage planner requires a six-role required route.")
	if not profile.supports_one_optional_branch():
		preflight_errors.append("Stage planner requires a profile that allows one optional branch.")
	if not preflight_errors.is_empty():
		_last_report.record_validation_errors(preflight_errors)
		return null

	var graph_rng := streams.create_rng(&"room_graph")
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
	if optional_candidates.is_empty():
		_last_report.record_failure(&"missing_optional_room", "No eligible optional room is available.")
		return null

	var selection := _search_route(
		0,
		candidates_by_role,
		optional_candidates,
		[],
		{},
		movement_limits
	)
	if selection.is_empty():
		_last_report.record_failure(
			&"no_compatible_route",
			"No unique six-room route with a compatible rejoining optional branch exists."
		)
		return null

	var required_templates: Array[RoomTemplateData] = selection["required_rooms"]
	var optional_template: RoomTemplateData = selection["optional_room"]
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
	planned_rooms.append(
		_plan_room(
			optional_template,
			false,
			0,
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
	_last_report.record_decision(
		&"optional_branch",
		{
			"room_id": String(optional_template.id),
			"from_room_id": String(connections[-2].from_room_id),
			"to_room_id": String(connections[-1].to_room_id),
		}
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
		var branch := _find_optional_branch(
			required_templates,
			optional_candidates,
			route_connections["used_sockets"],
			movement_limits
		)
		if branch.is_empty():
			return {}
		var connections: Array[PlannedConnection] = route_connections["connections"]
		connections.append_array(branch["connections"])
		return {
			"required_rooms": required_templates,
			"optional_room": branch["room"],
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


func _find_optional_branch(
	required_rooms: Array[RoomTemplateData],
	optional_candidates: Array[RoomTemplateData],
	reserved_sockets: Dictionary,
	movement_limits: Dictionary
) -> Dictionary:
	var choice_index := -1
	for room_index in required_rooms.size():
		if required_rooms[room_index].role == &"choice":
			choice_index = room_index
			break
	if choice_index < 0:
		return {}
	var branch_source := required_rooms[choice_index]
	for optional_room in optional_candidates:
		if required_rooms.has(optional_room):
			continue
		var used := reserved_sockets.duplicate()
		var branch_pair := _find_available_pair(
			branch_source,
			optional_room,
			&"optional",
			movement_limits,
			used
		)
		if branch_pair.is_empty():
			continue
		_reserve_pair(used, branch_source, optional_room, branch_pair)
		var return_pair := _find_available_pair(
			optional_room,
			branch_source,
			&"return",
			movement_limits,
			used
		)
		if return_pair.is_empty():
			continue
		var branch_from: RoomSocketData = branch_pair["from"]
		var branch_to: RoomSocketData = branch_pair["to"]
		var return_from: RoomSocketData = return_pair["from"]
		var return_to: RoomSocketData = return_pair["to"]
		var branch_connections: Array[PlannedConnection] = [
			PlannedConnection.new(
				&"optional_branch_0",
				branch_source.id,
				branch_from.id,
				optional_room.id,
				branch_to.id,
				&"optional"
			),
			PlannedConnection.new(
				&"optional_return_0",
				optional_room.id,
				return_from.id,
				branch_source.id,
				return_to.id,
				&"return"
			),
		]
		return {"room": optional_room, "connections": branch_connections}
	return {}


func _find_available_pair(
	from_room: RoomTemplateData,
	to_room: RoomTemplateData,
	route_role: StringName,
	movement_limits: Dictionary,
	used_sockets: Dictionary
) -> Dictionary:
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
				return {"from": from_socket, "to": to_socket}
	return {}


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
