extends SceneTree

const TEST_SEED := 93117

var _failures: Array[String] = []


func _initialize() -> void:
	var fixture := _build_fixture()
	var catalog: RoomCatalog = fixture["catalog"]
	var profile: StageProfile = fixture["profile"]
	var movement_limits: Dictionary = fixture["movement_limits"]

	_expect(catalog.validate_catalog().is_empty(), "in-memory room catalog should validate")
	_expect(profile.validate_definition().is_empty(), "in-memory stage profile should validate")
	_validate_named_streams(catalog, profile)

	var planner := StagePlanner.new()
	var plan := planner.build_plan(catalog, profile, TEST_SEED, 0, movement_limits)
	_expect(plan != null, "planner should build a valid six-room route and optional branch")
	if plan != null:
		_validate_planned_route(plan, catalog, profile, movement_limits)
		_validate_serialization(plan)
		_validate_rejections(plan, catalog, profile, movement_limits)
		_validate_seed_variety(catalog, profile, movement_limits)
	_expect(planner.last_report != null, "planner should expose its generation report")
	if planner.last_report != null:
		_expect(planner.last_report.is_successful(), "successful planning report should have no failures")
		_expect(
			planner.last_report.get_decisions().size() == 2,
			"generation report should explain required and optional room decisions"
		)
		var decisions := planner.last_report.get_decisions()
		decisions.clear()
		_expect(
			planner.last_report.get_decisions().size() == 2,
			"generation report collections should be copy-safe"
		)

	_validate_planned_encounter_value()
	_validate_shipped_stage_resources()
	_finish()


func _validate_named_streams(catalog: RoomCatalog, profile: StageProfile) -> void:
	var first := NamedRngStreams.new(TEST_SEED, 0, catalog.content_version, profile.content_version)
	var second := NamedRngStreams.new(TEST_SEED, 0, catalog.content_version, profile.content_version)
	var retry := NamedRngStreams.new(TEST_SEED, 0, catalog.content_version, profile.content_version, 1)
	_expect(
		first.get_stream_seeds() == second.get_stream_seeds(),
		"named stream seeds should reproduce from identical inputs"
	)
	_expect(
		first.seed_for(&"encounter") != first.seed_for(&"reward"),
		"different stream names should derive independent seeds"
	)
	_expect(
		first.seed_for(&"room_graph") != retry.seed_for(&"room_graph"),
		"deterministic retries should derive a different room graph stream"
	)
	var first_rng := first.create_rng(&"room_graph")
	var second_rng := second.create_rng(&"room_graph")
	for draw_index in 4:
		_expect(
			first_rng.randi() == second_rng.randi(),
			"named stream draw %d should reproduce" % draw_index
		)


func _validate_planned_route(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary
) -> void:
	var errors := StagePlanValidator.validate(plan, catalog, profile, movement_limits)
	_expect(errors.is_empty(), "planned route should validate: %s" % "; ".join(errors))
	var required_rooms: Array[PlannedRoom] = []
	var optional_rooms: Array[PlannedRoom] = []
	for room in plan.get_rooms():
		if room.required_route:
			required_rooms.append(room)
		else:
			optional_rooms.append(room)
	_expect(required_rooms.size() == 6, "plan should contain six required rooms")
	_expect(optional_rooms.size() == 1, "plan should contain one optional room")
	for role_index in mini(required_rooms.size(), profile.required_roles.size()):
		_expect(
			required_rooms[role_index].role == profile.required_roles[role_index],
			"required route role %d should match the profile" % role_index
		)
	var critical_count := 0
	var branch_count := 0
	var return_count := 0
	for connection in plan.get_connections():
		match connection.route_role:
			&"critical":
				critical_count += 1
			&"optional":
				branch_count += 1
			&"return":
				return_count += 1
	_expect(critical_count == 5, "six required rooms should have five critical connections")
	_expect(branch_count == 1 and return_count == 1, "optional room should branch and rejoin once")


func _validate_serialization(plan: StagePlan) -> void:
	var serialized := plan.to_json()
	var reproduced := StagePlan.from_json(serialized)
	_expect(reproduced != null, "serialized Stage Plan should deserialize")
	if reproduced != null:
		_expect(reproduced.to_json() == serialized, "Stage Plan JSON should round-trip byte-equivalently")

	var room_copy := plan.get_rooms()
	room_copy.clear()
	_expect(plan.get_rooms().size() == 7, "Stage Plan room getter should return a copy")
	var seed_copy := plan.get_rng_stream_seeds()
	seed_copy["room_graph"] = -1
	_expect(
		int(plan.get_rng_stream_seeds()["room_graph"]) >= 0,
		"Stage Plan RNG seed getter should return a copy"
	)
	var dictionary_copy := plan.to_dictionary()
	var copied_rooms: Array = dictionary_copy["rooms"]
	var copied_first_room: Dictionary = copied_rooms[0]
	copied_first_room["template_id"] = "mutated_template"
	_expect(plan.to_json() == serialized, "mutating serialized data must not change the Stage Plan")


func _validate_rejections(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary
) -> void:
	var stale_data := plan.to_dictionary()
	var stale_rooms: Array = stale_data["rooms"]
	stale_rooms[0]["template_content_version"] = 999
	_expect_invalid(
		StagePlan.from_dictionary(stale_data),
		catalog,
		profile,
		movement_limits,
		"template version",
		"stale room versions should fail"
	)

	var role_data := plan.to_dictionary()
	var role_rooms: Array = role_data["rooms"]
	role_rooms[1]["role"] = "hazard"
	_expect_invalid(
		StagePlan.from_dictionary(role_data),
		catalog,
		profile,
		movement_limits,
		"role",
		"wrong planned roles should fail"
	)

	var duplicate_data := plan.to_dictionary()
	var duplicate_rooms: Array = duplicate_data["rooms"]
	duplicate_rooms[1]["template_id"] = duplicate_rooms[0]["template_id"]
	_expect_invalid(
		StagePlan.from_dictionary(duplicate_data),
		catalog,
		profile,
		movement_limits,
		"repeats room template",
		"duplicate room templates should fail"
	)

	var id_data := plan.to_dictionary()
	var id_connections: Array = id_data["connections"]
	id_connections[0]["id"] = "Bad Connection ID"
	_expect_invalid(
		StagePlan.from_dictionary(id_data),
		catalog,
		profile,
		movement_limits,
		"snake_case",
		"invalid plan IDs should fail"
	)

	var socket_data := plan.to_dictionary()
	var socket_connections: Array = socket_data["connections"]
	socket_connections[0]["to_socket_id"] = "missing_socket"
	_expect_invalid(
		StagePlan.from_dictionary(socket_data),
		catalog,
		profile,
		movement_limits,
		"missing entry or exit socket",
		"missing socket references should fail"
	)

	var graph_data := plan.to_dictionary()
	var graph_connections: Array = graph_data["connections"]
	graph_connections.remove_at(0)
	_expect_invalid(
		StagePlan.from_dictionary(graph_data),
		catalog,
		profile,
		movement_limits,
		"unreachable",
		"broken required graph reachability should fail"
	)

	var budget_data := plan.to_dictionary()
	var budget_rooms: Array = budget_data["rooms"]
	budget_rooms[0]["hazard_budget"] = 99
	_expect_invalid(
		StagePlan.from_dictionary(budget_data),
		catalog,
		profile,
		movement_limits,
		"hazard budget",
		"room budgets outside template and profile caps should fail"
	)

	var encounter_data := plan.to_dictionary()
	var combat_room: Dictionary
	for raw_room in encounter_data["rooms"]:
		if raw_room["role"] == "combat":
			combat_room = raw_room
			break
	var oversized_encounter := PlannedEncounter.new(
		&"encounter_over_budget",
		StringName(combat_room["id"]),
		&"enemy_anchor_0",
		&"occupier",
		&"walker",
		&"walker_ruin",
		1,
		int(combat_room["encounter_budget"]) + 1
	)
	var encounter_rows: Array = encounter_data["encounters"]
	encounter_rows.append(oversized_encounter.to_dictionary())
	_expect_invalid(
		StagePlan.from_dictionary(encounter_data),
		catalog,
		profile,
		movement_limits,
		"over planned budget",
		"encounter costs over a room budget should fail"
	)

	var first_connection := plan.get_connections()[0]
	var target_template := catalog.get_room_by_id(first_connection.to_room_id)
	var target_socket := _find_entry_socket(target_template, first_connection.to_socket_id)
	var original_support := target_socket.support_top
	target_socket.support_top = original_support + float(movement_limits["max_required_ledge"]) + 1.0
	var movement_errors := StagePlanValidator.validate(plan, catalog, profile, movement_limits)
	_expect(
		_has_error(movement_errors, "support delta"),
		"connections beyond shared movement limits should fail"
	)
	target_socket.support_top = original_support


func _validate_seed_variety(
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary
) -> void:
	var signatures: Dictionary = {}
	for seed_offset in 16:
		var planner := StagePlanner.new()
		var plan := planner.build_plan(catalog, profile, 1000 + seed_offset, 0, movement_limits)
		_expect(plan != null, "seed %d should produce a valid plan" % seed_offset)
		if plan == null:
			continue
		var ids: Array[String] = []
		for room in plan.get_rooms():
			ids.append(String(room.template_id))
		signatures["|".join(ids)] = true
	_expect(signatures.size() >= 2, "different seeds should vary route or optional template selection")


func _validate_planned_encounter_value() -> void:
	var encounter := PlannedEncounter.new(
		&"walker_fixture",
		&"combat_a",
		&"enemy_anchor_0",
		&"occupier",
		&"walker",
		&"walker_ruin",
		1,
		1
	)
	var reproduced := PlannedEncounter.from_dictionary(encounter.to_dictionary())
	_expect(reproduced.id == encounter.id, "planned encounter ID should serialize")
	_expect(reproduced.variant_id == &"walker_ruin", "planned encounter variant should serialize")
	_expect(reproduced.budget_cost == 1, "planned encounter exact budget should serialize")


func _validate_shipped_stage_resources() -> void:
	var catalog := load("res://data/generation/lower_ruins_room_catalog.tres") as RoomCatalog
	var profile := load("res://data/generation/ruin_approach_profile.tres") as StageProfile
	var characters := load("res://data/characters/character_catalog.tres") as CharacterCatalog
	_expect(catalog != null, "shipped lower ruins room catalog should load")
	_expect(profile != null, "shipped Ruin Approach profile should load")
	_expect(characters != null, "shipped character catalog should load")
	if catalog == null or profile == null or characters == null:
		return

	var movement_limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	movement_limits["minimum_headroom"] = 100.0
	movement_limits["allowed_required_abilities"] = [
		"baseline", "double_jump", "dash", "crouch", "climb",
	]
	for seed in [1103, 29017, 73102]:
		var planner := StagePlanner.new()
		var plan := planner.build_plan(catalog, profile, seed, 0, movement_limits)
		var report_failures: Array[Dictionary] = (
			planner.last_report.get_failures() if planner.last_report != null else []
		)
		_expect(
			plan != null,
			"shipped seed %d should produce a Stage Plan: %s"
			% [seed, JSON.stringify(report_failures)]
		)
		if plan == null:
			continue
		var plan_errors := StagePlanValidator.validate(
			plan,
			catalog,
			profile,
			movement_limits
		)
		_expect(
			plan_errors.is_empty(),
			"shipped seed %d should validate: %s" % [seed, "; ".join(plan_errors)]
		)

		var rooms_root := Node2D.new()
		root.add_child(rooms_root)
		var assembly := StageAssembler.assemble(plan, catalog, rooms_root)
		_expect(
			assembly.success,
			"shipped seed %d should assemble: %s" % [seed, "; ".join(assembly.get_errors())]
		)
		if assembly.success:
			_validate_assembled_layout(plan, catalog, assembly, seed)
			var geometry_errors := StageGeometryValidator.validate_assembly(
				plan,
				catalog,
				assembly,
				movement_limits
			)
			_expect(
				geometry_errors.is_empty(),
				"shipped seed %d geometry should validate: %s"
				% [seed, "; ".join(geometry_errors)]
			)
		rooms_root.queue_free()

	var fallback_builder := CuratedStagePlanBuilder.new()
	var fallback := fallback_builder.build_ruin_approach(
		catalog,
		profile,
		1103,
		0,
		movement_limits
	)
	_expect(
		fallback != null,
		"curated fallback should validate: %s" % "; ".join(fallback_builder.last_errors)
	)
	if fallback != null:
		_expect(
			fallback.generation_attempt == CuratedStagePlanBuilder.FALLBACK_ATTEMPT,
			"curated fallback should preserve its deterministic attempt"
		)


func _validate_assembled_layout(
	plan: StagePlan,
	catalog: RoomCatalog,
	assembly: StageAssemblyResult,
	seed: int
) -> void:
	var positions := assembly.get_room_positions()
	var choice_room: PlannedRoom
	var optional_room: PlannedRoom
	var room_rects: Array[Dictionary] = []
	for planned_room in plan.get_rooms():
		var template := catalog.get_room_by_id(planned_room.template_id)
		var position: Vector2 = positions[String(planned_room.id)]
		room_rects.append({
			"id": planned_room.id,
			"rect": Rect2(position + template.bounds.position, template.bounds.size),
		})
		if planned_room.role == &"choice":
			choice_room = planned_room
		elif not planned_room.required_route:
			optional_room = planned_room

	_expect(choice_room != null and optional_room != null, "seed %d needs choice and optional rooms" % seed)
	if choice_room != null and optional_room != null:
		var choice_position: Vector2 = positions[String(choice_room.id)]
		var optional_position: Vector2 = positions[String(optional_room.id)]
		_expect(
			optional_position.is_equal_approx(choice_position + Vector2(0.0, 720.0)),
			"seed %d optional room should occupy the reviewed lower lane" % seed
		)

	for first_index in room_rects.size():
		for second_index in range(first_index + 1, room_rects.size()):
			var first: Dictionary = room_rects[first_index]
			var second: Dictionary = room_rects[second_index]
			_expect(
				not (first["rect"] as Rect2).intersects(second["rect"] as Rect2),
				"seed %d rooms '%s' and '%s' must not overlap"
				% [seed, first["id"], second["id"]]
			)


func _expect_invalid(
	plan: StagePlan,
	catalog: RoomCatalog,
	profile: StageProfile,
	movement_limits: Dictionary,
	error_fragment: String,
	message: String
) -> void:
	var errors := StagePlanValidator.validate(plan, catalog, profile, movement_limits)
	_expect(_has_error(errors, error_fragment), "%s: %s" % [message, "; ".join(errors)])


func _build_fixture() -> Dictionary:
	var profile := StageProfile.new()
	var catalog := RoomCatalog.new()
	catalog.id = &"lower_ruins_fixture"
	catalog.display_name = "Lower Ruins Fixture"
	catalog.content_version = 3

	_add_room(catalog, &"start_a", &"start", true, false, false)
	_add_room(catalog, &"traversal_a", &"traversal", true, false, false)
	_add_room(catalog, &"traversal_b", &"traversal", true, false, false)
	_add_room(catalog, &"combat_a", &"combat", true, false, false)
	_add_room(catalog, &"combat_b", &"combat", true, false, false)
	_add_room(catalog, &"combat_c", &"combat", true, false, false)
	_add_room(catalog, &"choice_a", &"choice", true, true, false)
	_add_room(catalog, &"exit_a", &"exit", true, false, false)
	_add_optional_room(catalog, &"optional_a")
	_add_optional_room(catalog, &"optional_b")

	return {
		"catalog": catalog,
		"profile": profile,
		"movement_limits": {
			"max_required_gap": 320.0,
			"max_required_ledge": 120.0,
			"minimum_headroom": 100.0,
			"allowed_required_abilities": [
				"baseline", "double_jump", "dash", "crouch", "climb",
			],
		},
	}


func _add_room(
	catalog: RoomCatalog,
	room_id: StringName,
	role: StringName,
	required_route: bool,
	with_optional_exit: bool,
	with_return_entry: bool
) -> void:
	var room := _base_room(room_id, role, required_route)
	room.entry_sockets.append(_socket(&"entry_critical", &"left", &"critical"))
	room.exit_sockets.append(_socket(&"exit_critical", &"right", &"critical"))
	if with_optional_exit:
		room.exit_sockets.append(_socket(&"exit_optional", &"branch", &"optional"))
	if with_optional_exit or with_return_entry:
		room.entry_sockets.append(_socket(&"entry_return", &"rejoin", &"return"))
	catalog.rooms.append(room)


func _add_optional_room(catalog: RoomCatalog, room_id: StringName) -> void:
	var room := _base_room(room_id, &"optional", false)
	room.entry_sockets.append(_socket(&"entry_optional", &"branch", &"optional"))
	room.exit_sockets.append(_socket(&"exit_return", &"rejoin", &"return"))
	room.reward_budget = Vector2i(1, 3)
	catalog.rooms.append(room)


func _base_room(
	room_id: StringName,
	role: StringName,
	required_route: bool
) -> RoomTemplateData:
	var room := RoomTemplateData.new()
	room.id = room_id
	room.display_name = String(room_id).replace("_", " ").capitalize()
	room.content_version = 1
	room.scene = PackedScene.new()
	room.role = role
	room.stage_tags = [&"ruin_approach"]
	room.required_route = required_route
	room.bounds = Rect2(0.0, 0.0, 1280.0, 720.0)
	room.encounter_budget = Vector2i(1, 3) if role == &"combat" else Vector2i.ZERO
	room.hazard_budget = Vector2i(0, 1)
	room.reward_budget = Vector2i(0, 3)
	if role == &"combat":
		room.allowed_enemy_tags = [&"occupier"]
		room.enemy_anchors = [_enemy_anchor(&"enemy_anchor_0", &"occupier")]
	room.hazard_anchors = [_hazard_anchor(&"hazard_anchor_0")]
	room.reward_anchors = [_reward_anchor(&"reward_anchor_0")]
	if required_route:
		room.recovery_anchor_ids = [&"recovery_anchor_0"]
	room.estimated_seconds = Vector2i(20, 60)
	return room


func _enemy_anchor(anchor_id: StringName, pressure_role: StringName) -> RoomEnemyAnchorData:
	var anchor := RoomEnemyAnchorData.new()
	anchor.id = anchor_id
	anchor.allowed_pressure_roles = [pressure_role]
	anchor.support_width = 300.0
	anchor.lane_width = 240.0
	anchor.clearance = 180.0
	return anchor


func _hazard_anchor(anchor_id: StringName) -> RoomHazardAnchorData:
	var anchor := RoomHazardAnchorData.new()
	anchor.id = anchor_id
	anchor.allowed_hazard_ids = [&"spike_row"]
	anchor.safe_zone_id = &"recovery_anchor_0"
	return anchor


func _reward_anchor(anchor_id: StringName) -> RoomRewardAnchorData:
	var anchor := RoomRewardAnchorData.new()
	anchor.id = anchor_id
	anchor.reward_role = &"fixture_reward"
	anchor.eligible_table_ids = [&"optional_cache_ruin"]
	return anchor


func _socket(
	socket_id: StringName,
	direction: StringName,
	route_role: StringName
) -> RoomSocketData:
	var socket := RoomSocketData.new()
	socket.id = socket_id
	socket.direction = direction
	socket.route_role = route_role
	socket.local_position = Vector2.ZERO
	socket.opening_size = Vector2(120.0, 120.0)
	socket.support_top = 0.0
	socket.transition_type = &"seam"
	socket.required_ability = &"baseline"
	socket.approach_width = 280.0
	socket.landing_width = 240.0
	socket.headroom = 120.0
	return socket


func _find_entry_socket(room: RoomTemplateData, socket_id: StringName) -> RoomSocketData:
	for socket in room.entry_sockets:
		if socket.id == socket_id:
			return socket
	return null


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.to_lower().contains(fragment.to_lower()):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_GENERATION_CORE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
