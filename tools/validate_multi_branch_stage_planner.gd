extends SceneTree

const TEST_SEED := 917_203

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_two_branch_contract()
	_validate_zero_branch_contract()
	_validate_missing_content_fails_closed()
	_finish()


func _validate_two_branch_contract() -> void:
	var fixture := _build_fixture(2, 2)
	var planner := StagePlanner.new()
	var plan := planner.build_plan(
		fixture["catalog"],
		fixture["profile"],
		TEST_SEED,
		2,
		fixture["movement_limits"]
	)
	_expect(plan != null, "two-branch profile should produce a plan")
	if plan == null:
		return

	var repeated := StagePlanner.new().build_plan(
		fixture["catalog"],
		fixture["profile"],
		TEST_SEED,
		2,
		fixture["movement_limits"]
	)
	_expect(repeated != null, "same two-branch seed should regenerate")
	if repeated != null:
		_expect(plan.to_json() == repeated.to_json(), "same seed should produce the same two-branch graph")

	var optional_rooms: Array[PlannedRoom] = []
	var branch_edges := 0
	var return_edges := 0
	var socket_ends: Dictionary = {}
	for room in plan.get_rooms():
		if not room.required_route:
			optional_rooms.append(room)
	for connection in plan.get_connections():
		if connection.route_role == &"optional":
			branch_edges += 1
		elif connection.route_role == &"return":
			return_edges += 1
		var from_end := "%s:exit:%s" % [connection.from_room_id, connection.from_socket_id]
		var to_end := "%s:entry:%s" % [connection.to_room_id, connection.to_socket_id]
		_expect(not socket_ends.has(from_end), "connection source sockets must be unique")
		_expect(not socket_ends.has(to_end), "connection target sockets must be unique")
		socket_ends[from_end] = true
		socket_ends[to_end] = true

	optional_rooms.sort_custom(
		func(left: PlannedRoom, right: PlannedRoom) -> bool:
			return left.route_index < right.route_index
	)
	_expect(optional_rooms.size() == 2, "two-branch profile should select two unique optional rooms")
	_expect(branch_edges == 2 and return_edges == 2, "each optional room should branch and rejoin once")
	for branch_index in optional_rooms.size():
		_expect(optional_rooms[branch_index].route_index == branch_index, "optional branch indices should be contiguous")
	var validation_errors := StagePlanValidator.validate_plan(
		plan,
		fixture["catalog"],
		fixture["profile"],
		fixture["movement_limits"]
	)
	_expect(
		validation_errors.is_empty(),
		"two-branch plan should satisfy the full plan contract: %s" % "; ".join(validation_errors)
	)


func _validate_zero_branch_contract() -> void:
	var fixture := _build_fixture(0, 0)
	var plan := StagePlanner.new().build_plan(
		fixture["catalog"],
		fixture["profile"],
		TEST_SEED,
		0,
		fixture["movement_limits"]
	)
	_expect(plan != null, "zero-branch profile should not require optional content")
	if plan == null:
		return
	for room in plan.get_rooms():
		_expect(room.required_route, "zero-branch plan should contain only required rooms")


func _validate_missing_content_fails_closed() -> void:
	var fixture := _build_fixture(2, 1)
	var planner := StagePlanner.new()
	var plan := planner.build_plan(
		fixture["catalog"],
		fixture["profile"],
		TEST_SEED,
		2,
		fixture["movement_limits"]
	)
	_expect(plan == null, "planner should reject a profile with too few unique optional rooms")
	_expect(
		_report_has_failure(planner.last_report, &"missing_optional_room"),
		"missing optional content should have an explicit failure code"
	)


func _build_fixture(required_branches: int, optional_room_count: int) -> Dictionary:
	var profile := StageProfile.new()
	profile.id = &"multi_branch_stage"
	profile.display_name = "Multi Branch Stage"
	profile.required_room_count = 6
	profile.required_roles = [
		&"start", &"traversal", &"combat", &"choice", &"combat", &"exit",
	]
	profile.optional_branch_count = Vector2i(required_branches, required_branches)
	profile.encounter_budget_per_combat_room = Vector2i.ZERO
	profile.hazard_budget_per_room = Vector2i.ZERO
	profile.reward_budget_per_room = Vector2i.ZERO
	profile.fallback_id = &"multi_branch_fallback"

	var catalog := RoomCatalog.new()
	catalog.id = &"multi_branch_rooms"
	catalog.display_name = "Multi Branch Rooms"
	for room_index in profile.required_roles.size():
		var role: StringName = profile.required_roles[room_index]
		var room := _required_room(StringName("required_%d" % room_index), role)
		if role == &"choice":
			for branch_index in required_branches:
				room.exit_sockets.append(
					_socket(
						StringName("branch_exit_%d" % branch_index),
						&"branch",
						&"optional",
						Vector2(400.0, float(branch_index) * 320.0)
					)
				)
				room.entry_sockets.append(
					_socket(
						StringName("return_entry_%d" % branch_index),
						&"rejoin",
						&"return",
						Vector2(400.0, float(branch_index) * 320.0)
					)
				)
		catalog.rooms.append(room)
	for optional_index in optional_room_count:
		catalog.rooms.append(_optional_room(StringName("optional_%d" % optional_index)))

	return {
		"catalog": catalog,
		"profile": profile,
		"movement_limits": {
			"max_required_gap": 320.0,
			"max_required_ledge": 120.0,
			"minimum_headroom": 100.0,
			"allowed_required_abilities": ["baseline"],
		},
	}


func _required_room(room_id: StringName, role: StringName) -> RoomTemplateData:
	var room := _base_room(room_id, role, true)
	room.entry_sockets.append(
		_socket(&"critical_entry", &"left", &"critical", Vector2.ZERO)
	)
	room.exit_sockets.append(
		_socket(&"critical_exit", &"right", &"critical", Vector2(1280.0, 0.0))
	)
	return room


func _optional_room(room_id: StringName) -> RoomTemplateData:
	var room := _base_room(room_id, &"optional", false)
	room.entry_sockets.append(
		_socket(&"optional_entry", &"branch", &"optional", Vector2.ZERO)
	)
	room.exit_sockets.append(
		_socket(&"return_exit", &"rejoin", &"return", Vector2.ZERO)
	)
	return room


func _base_room(
	room_id: StringName,
	role: StringName,
	required_route: bool
) -> RoomTemplateData:
	var room := RoomTemplateData.new()
	room.id = room_id
	room.display_name = String(room_id).replace("_", " ").capitalize()
	room.scene = PackedScene.new()
	room.role = role
	room.stage_tags = [&"multi_branch_stage"]
	room.required_route = required_route
	room.encounter_budget = Vector2i.ZERO
	room.hazard_budget = Vector2i.ZERO
	room.reward_budget = Vector2i.ZERO
	var recovery_anchor_ids: Array[StringName] = []
	if required_route:
		recovery_anchor_ids.append(&"recovery")
	room.recovery_anchor_ids = recovery_anchor_ids
	return room


func _socket(
	socket_id: StringName,
	direction: StringName,
	route_role: StringName,
	local_position: Vector2
) -> RoomSocketData:
	var socket := RoomSocketData.new()
	socket.id = socket_id
	socket.direction = direction
	socket.route_role = route_role
	socket.local_position = local_position
	socket.support_top = local_position.y
	socket.opening_size = Vector2(120.0, 120.0)
	socket.approach_width = 280.0
	socket.landing_width = 240.0
	socket.headroom = 120.0
	return socket


func _report_has_failure(report: GenerationReport, code: StringName) -> bool:
	if report == null:
		return false
	for failure in report.get_failures():
		if StringName(failure.get("code", "")) == code:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MULTI_BRANCH_STAGE_PLANNER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
