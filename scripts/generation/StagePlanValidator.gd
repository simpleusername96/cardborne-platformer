class_name StagePlanValidator
extends RefCounted


static func validate(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary,
	enemy_catalog: EnemyCatalog = null,
	require_allocated_encounters: bool = false
) -> PackedStringArray:
	return validate_plan(
		plan,
		catalog,
		profile,
		movement_limits,
		enemy_catalog,
		require_allocated_encounters
	)


static func validate_plan(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary,
	enemy_catalog: EnemyCatalog = null,
	require_allocated_encounters: bool = false
) -> PackedStringArray:
	var errors := PackedStringArray()
	if plan == null:
		errors.append("Stage Plan cannot be null.")
		return errors
	if catalog == null:
		errors.append("Stage Plan validation needs a RoomCatalog.")
	if profile == null:
		errors.append("Stage Plan validation needs a StageProfile.")
	if catalog == null or profile == null:
		return errors

	_append_errors(errors, catalog.validate_catalog(), "Room catalog")
	_append_errors(errors, profile.validate_definition(), "Stage profile")
	_append_errors(
		errors,
		RoomSocketCompatibility.validate_movement_limits(movement_limits),
		"Movement limits"
	)
	_validate_header(errors, plan, catalog, profile)
	var room_context := _validate_rooms(errors, plan, catalog, profile)
	_validate_connections(errors, plan, room_context, profile, movement_limits)
	_validate_encounters(
		errors,
		plan,
		room_context,
		profile,
		enemy_catalog,
		require_allocated_encounters
	)
	return errors


static func validate_complete(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary,
	enemy_catalog: EnemyCatalog,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog
) -> PackedStringArray:
	var errors := validate_plan(
		plan,
		catalog,
		profile,
		movement_limits,
		enemy_catalog,
		true
	)
	if plan == null or catalog == null or profile == null:
		return errors
	var room_context := _resolved_room_context(plan, catalog)
	_validate_hazards(errors, plan, room_context, profile, hazard_catalog)
	_validate_rewards(errors, plan, room_context, reward_catalog)
	return errors


static func _validate_header(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile
) -> void:
	if plan.schema_version != StagePlan.CURRENT_SCHEMA_VERSION:
		errors.append(
			"Stage Plan schema version %d does not match supported version %d."
			% [plan.schema_version, StagePlan.CURRENT_SCHEMA_VERSION]
		)
	if plan.stage_index < 0:
		errors.append("Stage Plan stage index cannot be negative.")
	if plan.generation_attempt < 0:
		errors.append("Stage Plan generation attempt cannot be negative.")
	ContentId.validate(errors, "Stage Plan profile ID", plan.profile_id)
	ContentId.validate(errors, "Stage Plan room catalog ID", plan.room_catalog_id)
	if plan.profile_id != profile.id:
		errors.append(
			"Stage Plan profile ID '%s' does not match '%s'." % [plan.profile_id, profile.id]
		)
	if plan.profile_content_version != profile.content_version:
		errors.append(
			"Stage Plan profile version %d does not match '%s' version %d."
			% [plan.profile_content_version, profile.id, profile.content_version]
		)
	if plan.room_catalog_id != catalog.id:
		errors.append(
			"Stage Plan room catalog ID '%s' does not match '%s'."
			% [plan.room_catalog_id, catalog.id]
		)
	if plan.room_catalog_content_version != catalog.content_version:
		errors.append(
			"Stage Plan room catalog version %d does not match '%s' version %d."
			% [plan.room_catalog_content_version, catalog.id, catalog.content_version]
		)

	var stream_seeds := plan.get_rng_stream_seeds()
	var expected_seeds := NamedRngStreams.new(
		plan.run_seed,
		plan.stage_index,
		catalog.content_version,
		profile.content_version,
		plan.generation_attempt
	).get_stream_seeds()
	for stream_name in NamedRngStreams.DEFAULT_STREAM_NAMES:
		var stream_key := String(stream_name)
		if not stream_seeds.has(stream_key):
			errors.append("Stage Plan is missing RNG stream seed '%s'." % stream_name)
		elif int(stream_seeds[stream_key]) != int(expected_seeds[stream_key]):
			errors.append("Stage Plan RNG stream seed '%s' does not match its inputs." % stream_name)


static func _validate_rooms(
	errors: PackedStringArray,
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile
) -> Dictionary:
	var room_map: Dictionary = {}
	var template_map: Dictionary = {}
	var seen_template_ids: Dictionary = {}
	var required_rooms: Array[PlannedRoom] = []
	var optional_rooms: Array[PlannedRoom] = []
	var start_count := 0
	var terminal_count := 0

	for room in plan.get_rooms():
		ContentId.validate(errors, "Planned room ID", room.id)
		ContentId.validate(errors, "Planned room template ID", room.template_id)
		var room_key := String(room.id)
		var template_key := String(room.template_id)
		if room_map.has(room_key):
			errors.append("Stage Plan repeats planned room ID '%s'." % room.id)
		else:
			room_map[room_key] = room
		if seen_template_ids.has(template_key):
			errors.append("Stage Plan repeats room template '%s'." % room.template_id)
		seen_template_ids[template_key] = true

		var template := catalog.get_room_by_id(room.template_id)
		if template == null:
			errors.append("Planned room '%s' references missing template '%s'." % [room.id, room.template_id])
			continue
		template_map[room_key] = template
		if room.template_content_version != template.content_version:
			errors.append(
				"Planned room '%s' template version %d does not match catalog version %d."
				% [room.id, room.template_content_version, template.content_version]
			)
		if room.role != template.role:
			errors.append(
				"Planned room '%s' role '%s' does not match template role '%s'."
				% [room.id, room.role, template.role]
			)
		if not template.stage_tags.has(profile.id):
			errors.append(
				"Planned room '%s' is not eligible for stage '%s'." % [room.id, profile.id]
			)
		if room.required_route != template.required_route:
			errors.append(
				"Planned room '%s' route ownership does not match its template." % room.id
			)
		_validate_room_budgets(errors, room, template, profile)

		if room.required_route:
			required_rooms.append(room)
		else:
			optional_rooms.append(room)
		if room.role == &"start":
			start_count += 1
		if room.role == profile.terminal_room_role:
			terminal_count += 1

	required_rooms.sort_custom(
		func(first: PlannedRoom, second: PlannedRoom) -> bool:
			return first.route_index < second.route_index
	)
	if required_rooms.size() != profile.required_room_count:
		errors.append(
			"Stage Plan needs %d required rooms, found %d."
			% [profile.required_room_count, required_rooms.size()]
		)
	for route_index in required_rooms.size():
		var room := required_rooms[route_index]
		if room.route_index != route_index:
			errors.append(
				"Required route index %d is missing or duplicated near room '%s'."
				% [route_index, room.id]
			)
		if route_index < profile.required_roles.size():
			var expected_role := profile.required_roles[route_index]
			if room.role != expected_role:
				errors.append(
					"Required room %d needs role '%s', found '%s'."
					% [route_index, expected_role, room.role]
				)
	if (
		optional_rooms.size() < profile.optional_branch_count.x
		or optional_rooms.size() > profile.optional_branch_count.y
	):
		errors.append(
			"Stage Plan optional room count %d is outside profile range %s."
			% [optional_rooms.size(), profile.optional_branch_count]
		)
	optional_rooms.sort_custom(
		func(first: PlannedRoom, second: PlannedRoom) -> bool:
			return first.route_index < second.route_index
	)
	for branch_index in optional_rooms.size():
		var room := optional_rooms[branch_index]
		if room.role != profile.optional_room_role:
			errors.append(
				"Optional planned room '%s' needs role '%s'."
				% [room.id, profile.optional_room_role]
			)
		if room.route_index != branch_index:
			errors.append(
				"Optional branch index %d is missing or duplicated near room '%s'."
				% [branch_index, room.id]
			)
	if start_count != 1:
		errors.append("Stage Plan needs exactly one start room, found %d." % start_count)
	if terminal_count != 1:
		errors.append(
			"Stage Plan needs exactly one terminal '%s' room, found %d."
			% [profile.terminal_room_role, terminal_count]
		)
	return {
		"room_map": room_map,
		"template_map": template_map,
		"required_rooms": required_rooms,
		"optional_rooms": optional_rooms,
	}


static func _validate_room_budgets(
	errors: PackedStringArray,
	room: PlannedRoom,
	template: RoomTemplateData,
	profile: StageProfile
) -> void:
	if not _budget_contains(template.encounter_budget, room.encounter_budget):
		errors.append("Planned room '%s' encounter budget is outside its template range." % room.id)
	if (
		room.role == &"combat"
		and not _budget_contains(profile.encounter_budget_per_combat_room, room.encounter_budget)
	):
		errors.append("Combat room '%s' encounter budget is outside its stage profile." % room.id)
	if (
		not _budget_contains(template.hazard_budget, room.hazard_budget)
		or not _budget_contains(profile.hazard_budget_per_room, room.hazard_budget)
	):
		errors.append("Planned room '%s' hazard budget is outside allowed ranges." % room.id)
	if (
		not _budget_contains(template.reward_budget, room.reward_budget)
		or not _budget_contains(profile.reward_budget_per_room, room.reward_budget)
	):
		errors.append("Planned room '%s' reward budget is outside allowed ranges." % room.id)


static func _validate_connections(
	errors: PackedStringArray,
	plan: StagePlan,
	room_context: Dictionary,
	profile: StageProfile,
	movement_limits: Dictionary
) -> void:
	var room_map: Dictionary = room_context["room_map"]
	var template_map: Dictionary = room_context["template_map"]
	var required_rooms: Array[PlannedRoom] = room_context["required_rooms"]
	var optional_rooms: Array[PlannedRoom] = room_context["optional_rooms"]
	var connections := plan.get_connections()
	var seen_connection_ids: Dictionary = {}
	var used_socket_ends: Dictionary = {}

	for connection in connections:
		ContentId.validate(errors, "Planned connection ID", connection.id)
		ContentId.validate(errors, "Connection source room ID", connection.from_room_id)
		ContentId.validate(errors, "Connection source socket ID", connection.from_socket_id)
		ContentId.validate(errors, "Connection target room ID", connection.to_room_id)
		ContentId.validate(errors, "Connection target socket ID", connection.to_socket_id)
		if seen_connection_ids.has(connection.id):
			errors.append("Stage Plan repeats connection ID '%s'." % connection.id)
		seen_connection_ids[connection.id] = true
		if not RoomSocketData.ROUTE_ROLES.has(connection.route_role):
			errors.append(
				"Connection '%s' has invalid route role '%s'."
				% [connection.id, connection.route_role]
			)

		var from_key := String(connection.from_room_id)
		var to_key := String(connection.to_room_id)
		if not room_map.has(from_key) or not room_map.has(to_key):
			errors.append("Connection '%s' references a missing planned room." % connection.id)
			continue
		if from_key == to_key:
			errors.append("Connection '%s' cannot connect a room to itself." % connection.id)
		if not template_map.has(from_key) or not template_map.has(to_key):
			continue
		var from_template: RoomTemplateData = template_map[from_key]
		var to_template: RoomTemplateData = template_map[to_key]
		var from_socket := _find_socket(from_template.exit_sockets, connection.from_socket_id)
		var to_socket := _find_socket(to_template.entry_sockets, connection.to_socket_id)
		if from_socket == null or to_socket == null:
			errors.append("Connection '%s' references a missing entry or exit socket." % connection.id)
			continue

		var from_end := "%s:exit:%s" % [from_key, connection.from_socket_id]
		var to_end := "%s:entry:%s" % [to_key, connection.to_socket_id]
		if used_socket_ends.has(from_end) or used_socket_ends.has(to_end):
			errors.append("Connection '%s' reuses an occupied socket endpoint." % connection.id)
		used_socket_ends[from_end] = true
		used_socket_ends[to_end] = true
		_append_errors(
			errors,
			RoomSocketCompatibility.get_errors(
				from_socket,
				to_socket,
				connection.route_role,
				movement_limits
			),
			"Connection '%s'" % connection.id
		)

	_validate_required_path(errors, connections, required_rooms)
	_validate_optional_branches(errors, connections, required_rooms, optional_rooms)
	_validate_reachability(errors, connections, required_rooms, room_map)


static func _validate_required_path(
	errors: PackedStringArray,
	connections: Array[PlannedConnection],
	required_rooms: Array[PlannedRoom]
) -> void:
	var critical_connections: Array[PlannedConnection] = []
	for connection in connections:
		if connection.route_role == &"critical":
			critical_connections.append(connection)
	if critical_connections.size() != maxi(required_rooms.size() - 1, 0):
		errors.append("Required route must have exactly one critical edge between each room.")
	for route_index in maxi(required_rooms.size() - 1, 0):
		var from_room := required_rooms[route_index]
		var to_room := required_rooms[route_index + 1]
		var edge_count := 0
		for connection in critical_connections:
			if (
				connection.from_room_id == from_room.id
				and connection.to_room_id == to_room.id
			):
				edge_count += 1
		if edge_count != 1:
			errors.append(
				"Required rooms '%s' and '%s' need exactly one critical connection."
				% [from_room.id, to_room.id]
			)
	for connection in critical_connections:
		var source_index := _required_index(required_rooms, connection.from_room_id)
		var target_index := _required_index(required_rooms, connection.to_room_id)
		if source_index < 0 or target_index != source_index + 1:
			errors.append(
				"Critical connection '%s' does not follow required route order." % connection.id
			)


static func _validate_optional_branches(
	errors: PackedStringArray,
	connections: Array[PlannedConnection],
	required_rooms: Array[PlannedRoom],
	optional_rooms: Array[PlannedRoom]
) -> void:
	var optional_edges := 0
	var return_edges := 0
	for connection in connections:
		if connection.route_role == &"optional":
			optional_edges += 1
		elif connection.route_role == &"return":
			return_edges += 1
	if optional_edges != optional_rooms.size() or return_edges != optional_rooms.size():
		errors.append("Each optional room needs one branch edge and one return edge.")

	for optional_room in optional_rooms:
		var incoming: Array[PlannedConnection] = []
		var outgoing: Array[PlannedConnection] = []
		for connection in connections:
			if connection.route_role == &"optional" and connection.to_room_id == optional_room.id:
				incoming.append(connection)
			if connection.route_role == &"return" and connection.from_room_id == optional_room.id:
				outgoing.append(connection)
		if incoming.size() != 1 or outgoing.size() != 1:
			errors.append(
				"Optional room '%s' must have exactly one incoming branch and one return."
				% optional_room.id
			)
			continue
		var source_index := _required_index(required_rooms, incoming[0].from_room_id)
		var target_index := _required_index(required_rooms, outgoing[0].to_room_id)
		if source_index < 0 or required_rooms[source_index].role != &"choice":
			errors.append("Optional room '%s' must branch from a required choice room." % optional_room.id)
		if target_index != source_index:
			errors.append(
				"Optional room '%s' must rejoin the choice room that owns its branch."
				% optional_room.id
			)


static func _validate_reachability(
	errors: PackedStringArray,
	connections: Array[PlannedConnection],
	required_rooms: Array[PlannedRoom],
	room_map: Dictionary
) -> void:
	if required_rooms.is_empty():
		errors.append("Stage Plan has no reachable start room.")
		return
	var adjacency: Dictionary = {}
	for connection in connections:
		var source := String(connection.from_room_id)
		var targets: Array = adjacency.get(source, [])
		targets.append(String(connection.to_room_id))
		adjacency[source] = targets
	var pending: Array[String] = [String(required_rooms[0].id)]
	var reached: Dictionary = {}
	while not pending.is_empty():
		var room_id: String = pending.pop_front()
		if reached.has(room_id):
			continue
		reached[room_id] = true
		for target in adjacency.get(room_id, []):
			if not reached.has(target):
				pending.append(target)
	for room_id in room_map:
		if not reached.has(room_id):
			errors.append("Planned room '%s' is unreachable from the start." % room_id)
	var exit_id := String(required_rooms[-1].id)
	if not reached.has(exit_id):
		errors.append("Stage Plan terminal exit is unreachable from the start.")


static func _validate_encounters(
	errors: PackedStringArray,
	plan: StagePlan,
	room_context: Dictionary,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	require_allocated_encounters: bool
) -> void:
	var room_map: Dictionary = room_context["room_map"]
	var template_map: Dictionary = room_context["template_map"]
	var seen_ids: Dictionary = {}
	var spent_by_room: Dictionary = {}
	var used_anchors: Dictionary = {}
	var encounters := plan.get_encounters()
	if not encounters.is_empty() and enemy_catalog == null:
		errors.append("Planned encounter references need an EnemyCatalog to resolve.")
	if enemy_catalog != null:
		_append_errors(errors, enemy_catalog.validate_catalog(), "Enemy catalog")
	for room_key in room_map:
		spent_by_room[room_key] = 0

	for encounter in encounters:
		ContentId.validate(errors, "Planned encounter ID", encounter.id)
		ContentId.validate(errors, "Planned encounter room ID", encounter.room_id)
		ContentId.validate(errors, "Planned encounter anchor ID", encounter.anchor_id)
		ContentId.validate(errors, "Planned encounter pressure role", encounter.pressure_role)
		ContentId.validate(errors, "Planned encounter archetype ID", encounter.archetype_id)
		ContentId.validate(errors, "Planned encounter variant ID", encounter.variant_id)
		if seen_ids.has(encounter.id):
			errors.append("Stage Plan repeats encounter ID '%s'." % encounter.id)
		seen_ids[encounter.id] = true
		var room_key := String(encounter.room_id)
		if not room_map.has(room_key):
			errors.append("Encounter '%s' references missing room '%s'." % [encounter.id, encounter.room_id])
		else:
			var anchor_key := "%s:%s" % [room_key, encounter.anchor_id]
			if used_anchors.has(anchor_key):
				errors.append(
					"Encounter '%s' reuses occupied enemy anchor '%s'."
					% [encounter.id, encounter.anchor_id]
				)
			used_anchors[anchor_key] = true
			var template: RoomTemplateData = template_map.get(room_key)
			var anchor := (
				template.get_enemy_anchor_by_id(encounter.anchor_id)
				if template != null else null
			)
			if anchor == null:
				errors.append(
					"Encounter '%s' references unavailable enemy anchor '%s'."
					% [encounter.id, encounter.anchor_id]
				)
			elif not anchor.allowed_pressure_roles.has(encounter.pressure_role):
				errors.append(
					"Encounter '%s' pressure role '%s' is incompatible with anchor '%s'."
					% [encounter.id, encounter.pressure_role, encounter.anchor_id]
				)
		if encounter.content_version <= 0:
			errors.append("Encounter '%s' needs a positive resolved content version." % encounter.id)
		if encounter.budget_cost <= 0:
			errors.append("Encounter '%s' needs a positive exact budget cost." % encounter.id)
		if (
			not profile.eligible_enemy_archetypes.is_empty()
			and not profile.eligible_enemy_archetypes.has(encounter.archetype_id)
		):
			errors.append(
				"Encounter '%s' archetype '%s' is not eligible for '%s'."
				% [encounter.id, encounter.archetype_id, profile.id]
			)
		spent_by_room[room_key] = int(spent_by_room.get(room_key, 0)) + encounter.budget_cost

		if enemy_catalog != null:
			var archetype := enemy_catalog.get_archetype_by_id(encounter.archetype_id)
			var resolved := enemy_catalog.resolve(
				encounter.archetype_id,
				encounter.variant_id,
				profile.id
			)
			if resolved == null:
				errors.append("Encounter '%s' enemy references do not resolve." % encounter.id)
			elif resolved.variant_content_version != encounter.content_version:
				errors.append("Encounter '%s' resolved content version is stale." % encounter.id)
			elif resolved.budget_cost != encounter.budget_cost:
				errors.append("Encounter '%s' exact budget cost does not match its variant." % encounter.id)
			if room_map.has(room_key) and template_map.has(room_key):
				var template: RoomTemplateData = template_map[room_key]
				var anchor := template.get_enemy_anchor_by_id(encounter.anchor_id)
				if anchor != null and not anchor.supports(archetype, encounter.pressure_role):
					errors.append(
						"Encounter '%s' archetype '%s' does not fit anchor '%s'."
						% [encounter.id, encounter.archetype_id, encounter.anchor_id]
					)

	var require_exact := require_allocated_encounters or not encounters.is_empty()
	for room_key in room_map:
		var planned_room: PlannedRoom = room_map[room_key]
		var spent := int(spent_by_room.get(room_key, 0))
		if spent > planned_room.encounter_budget:
			errors.append(
				"Room '%s' encounters spend %d over planned budget %d."
				% [room_key, spent, planned_room.encounter_budget]
			)
		elif require_exact and spent < planned_room.encounter_budget:
			errors.append(
				"Room '%s' encounters spend %d below exact planned budget %d."
				% [room_key, spent, planned_room.encounter_budget]
			)


static func _find_socket(
	sockets: Array[RoomSocketData],
	socket_id: StringName
) -> RoomSocketData:
	for socket in sockets:
		if socket != null and socket.id == socket_id:
			return socket
	return null


static func _resolved_room_context(plan: StagePlan, catalog: RoomCatalog) -> Dictionary:
	var room_map: Dictionary = {}
	var template_map: Dictionary = {}
	for room in plan.get_rooms():
		room_map[String(room.id)] = room
		var template := catalog.get_room_by_id(room.template_id)
		if template != null:
			template_map[String(room.id)] = template
	return {"room_map": room_map, "template_map": template_map}


static func _validate_hazards(
	errors: PackedStringArray,
	plan: StagePlan,
	room_context: Dictionary,
	profile: StageProfile,
	hazard_catalog: HazardCatalog
) -> void:
	if hazard_catalog == null:
		errors.append("Complete Stage Plan validation needs a HazardCatalog.")
		return
	_append_errors(errors, hazard_catalog.validate_catalog(), "Hazard catalog")
	var room_map: Dictionary = room_context["room_map"]
	var template_map: Dictionary = room_context["template_map"]
	var spent: Dictionary = {}
	var seen_ids: Dictionary = {}
	var used_anchors: Dictionary = {}
	for room_key in room_map:
		spent[room_key] = 0
	for placement in plan.get_hazards():
		ContentId.validate(errors, "Planned hazard ID", placement.id)
		if seen_ids.has(placement.id):
			errors.append("Stage Plan repeats hazard placement '%s'." % placement.id)
		seen_ids[placement.id] = true
		var room_key := String(placement.room_id)
		if not room_map.has(room_key) or not template_map.has(room_key):
			errors.append("Hazard '%s' references a missing planned room." % placement.id)
			continue
		var anchor_key := "%s:%s" % [room_key, placement.anchor_id]
		if used_anchors.has(anchor_key):
			errors.append("Hazard '%s' reuses occupied anchor '%s'." % [placement.id, placement.anchor_id])
		used_anchors[anchor_key] = true
		var template: RoomTemplateData = template_map[room_key]
		var anchor := template.get_hazard_anchor_by_id(placement.anchor_id)
		if anchor == null or not anchor.allowed_hazard_ids.has(placement.hazard_id):
			errors.append("Hazard '%s' is incompatible with anchor '%s'." % [placement.id, placement.anchor_id])
		var definition := hazard_catalog.get_hazard(placement.hazard_id)
		if definition == null:
			errors.append("Hazard '%s' references missing definition '%s'." % [placement.id, placement.hazard_id])
		else:
			if not profile.eligible_hazards.has(definition.id):
				errors.append("Hazard '%s' is not eligible for '%s'." % [definition.id, profile.id])
			if definition.content_version != placement.content_version:
				errors.append("Hazard '%s' content version is stale." % placement.id)
			if definition.budget_cost != placement.budget_cost or placement.budget_cost <= 0:
				errors.append("Hazard '%s' exact budget cost is invalid." % placement.id)
		spent[room_key] = int(spent[room_key]) + placement.budget_cost
	for room_key in room_map:
		var room: PlannedRoom = room_map[room_key]
		if int(spent[room_key]) != room.hazard_budget:
			errors.append(
				"Room '%s' hazards spend %d instead of exact planned budget %d."
				% [room_key, int(spent[room_key]), room.hazard_budget]
			)


static func _validate_rewards(
	errors: PackedStringArray,
	plan: StagePlan,
	room_context: Dictionary,
	reward_catalog: RewardCatalog
) -> void:
	if reward_catalog == null:
		errors.append("Complete Stage Plan validation needs a RewardCatalog.")
		return
	_append_errors(errors, reward_catalog.validate_catalog(), "Reward catalog")
	var room_map: Dictionary = room_context["room_map"]
	var template_map: Dictionary = room_context["template_map"]
	var spent: Dictionary = {}
	var seen_ids: Dictionary = {}
	var used_anchors: Dictionary = {}
	for room_key in room_map:
		spent[room_key] = 0
	for placement in plan.get_rewards():
		ContentId.validate(errors, "Planned reward ID", placement.id)
		if seen_ids.has(placement.id):
			errors.append("Stage Plan repeats reward placement '%s'." % placement.id)
		seen_ids[placement.id] = true
		var room_key := String(placement.room_id)
		if not room_map.has(room_key) or not template_map.has(room_key):
			errors.append("Reward '%s' references a missing planned room." % placement.id)
			continue
		var anchor_key := "%s:%s" % [room_key, placement.anchor_id]
		if used_anchors.has(anchor_key):
			errors.append("Reward '%s' reuses occupied anchor '%s'." % [placement.id, placement.anchor_id])
		used_anchors[anchor_key] = true
		var template: RoomTemplateData = template_map[room_key]
		var anchor := template.get_reward_anchor_by_id(placement.anchor_id)
		if anchor == null or not anchor.eligible_table_ids.has(placement.reward_table_id):
			errors.append("Reward '%s' is incompatible with anchor '%s'." % [placement.id, placement.anchor_id])
		var table := reward_catalog.get_table(placement.reward_table_id)
		if table == null:
			errors.append("Reward '%s' references missing table '%s'." % [placement.id, placement.reward_table_id])
		else:
			if table.content_version != placement.content_version:
				errors.append("Reward '%s' table content version is stale." % placement.id)
			if anchor != null and anchor.budget_cost != placement.budget_cost:
				errors.append("Reward '%s' exact budget cost is invalid." % placement.id)
		spent[room_key] = int(spent[room_key]) + placement.budget_cost
	for room_key in room_map:
		var room: PlannedRoom = room_map[room_key]
		if int(spent[room_key]) != room.reward_budget:
			errors.append(
				"Room '%s' rewards spend %d instead of exact planned budget %d."
				% [room_key, int(spent[room_key]), room.reward_budget]
			)


static func _required_index(
	required_rooms: Array[PlannedRoom],
	room_id: StringName
) -> int:
	for room_index in required_rooms.size():
		if required_rooms[room_index].id == room_id:
			return room_index
	return -1


static func _budget_contains(budget: Vector2i, value: int) -> bool:
	return value >= budget.x and value <= budget.y


static func _append_errors(
	target: PackedStringArray,
	source: PackedStringArray,
	label: String
) -> void:
	for error in source:
		target.append("%s: %s" % [label, error])
