extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const FIXTURE_SEED := 90731
const STAGES: Array[Dictionary] = [
	{"id": "ruin_approach", "policy": &"terminal_encounter"},
	{"id": "flooded_works", "policy": &"arrival"},
	{"id": "broken_sanctum", "policy": &"terminal_encounter"},
]

var _failures: Array[String] = []
var _run_state: Node
var _room_clear_events: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	_expect(_run_state != null and signal_bus != null, "progression fixture needs run autoloads")
	if _run_state == null or signal_bus == null:
		_finish()
		return
	var room_callback := Callable(self, "_on_required_room_cleared")
	signal_bus.required_room_encounter_cleared.connect(room_callback)
	for stage_index in STAGES.size():
		_run_state.start_new_run(0, FIXTURE_SEED + stage_index)
		_run_state.current_stage_index = stage_index
		await _validate_stage(stage_index, STAGES[stage_index])
	await _validate_same_stage_retry_knowledge()
	if signal_bus.required_room_encounter_cleared.is_connected(room_callback):
		signal_bus.required_room_encounter_cleared.disconnect(room_callback)
	_finish()


func _validate_stage(stage_index: int, expected: Dictionary) -> void:
	var stage := await _instantiate_stage()
	_expect(stage != null, "%s stage should instantiate" % expected["id"])
	if stage == null:
		return
	_expect(stage.stage_id == expected["id"], "%s should load the expected stage" % expected["id"])
	_expect(
		stage.get_exit_policy_id() == expected["policy"],
		"%s should use %s terminal policy" % [expected["id"], expected["policy"]]
	)
	_validate_map_contract(stage, expected)
	var terminal_room_id := _terminal_room_id(stage)
	var terminal_enemies: Array = []
	var prior_enemies: Array = []
	for enemy in stage.get_required_enemies():
		if StringName(enemy.get_meta("planned_room_id", &"")) == terminal_room_id:
			terminal_enemies.append(enemy)
		else:
			prior_enemies.append(enemy)
	_expect(not prior_enemies.is_empty(), "%s should retain bypassable earlier combat" % expected["id"])

	if expected["policy"] == &"arrival":
		_expect(stage.is_exit_enabled(), "%s arrival exit should be ready immediately" % expected["id"])
	else:
		_expect(not terminal_enemies.is_empty(), "%s terminal room should own combat" % expected["id"])
		_expect(not stage.is_exit_enabled(), "%s terminal encounter should start locked" % expected["id"])
		_room_clear_events.clear()
		for enemy in terminal_enemies:
			_defeat(enemy, stage.player)
		await process_frame
		_expect(
			stage.get_remaining_enemy_count() > 0,
			"%s should leave prior main-route enemies alive" % expected["id"]
		)
		_expect(
			_room_clear_events.has(String(terminal_room_id)),
			"%s terminal clear should preserve the room-local clear signal" % expected["id"]
		)
		_expect(
			stage.is_exit_enabled(),
			"%s should unlock after only its terminal encounter" % expected["id"]
		)

	var completions := [0]
	stage.stage_completed.connect(
		func(_stage_id: String) -> void:
			completions[0] += 1
	)
	var exit := _terminal_exit(stage)
	_expect(exit != null, "%s should expose a terminal exit" % expected["id"])
	if exit != null:
		exit.interact(stage.player)
		exit.interact(stage.player)
		await process_frame
		_expect(completions[0] == 1, "%s stage clear should commit once" % expected["id"])
	stage.queue_free()
	await process_frame


func _validate_map_contract(stage: Node, expected: Dictionary) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(not snapshot.is_empty(), "%s should publish a stage-map snapshot" % expected["id"])
	_expect(
		(snapshot.get("rooms", []) as Array).size() == plan.get_rooms().size(),
		"%s map room count should match StagePlan" % expected["id"]
	)
	_expect(
		(snapshot.get("connections", []) as Array).size() == plan.get_connections().size(),
		"%s map edge count should match StagePlan" % expected["id"]
	)
	var current_count := 0
	var visited_count := 0
	for room_value in snapshot.get("rooms", []):
		var room := room_value as Dictionary
		if bool(room.get("current", false)):
			current_count += 1
		if bool(room.get("visited", false)):
			visited_count += 1
	_expect(current_count == 1 and visited_count >= 1, "%s map should start in one visited room" % expected["id"])
	var visible_exit := false
	var gate_count := 0
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		var marker_type := String(marker.get("type", ""))
		_expect(marker_type not in ["enemy", "hazard"], "%s minimap must not become a radar" % expected["id"])
		if marker_type == "exit":
			visible_exit = bool(marker.get("visible", false))
		if marker_type == "reward":
			_expect(
				not bool(marker.get("visible", false)),
				"%s undiscovered rewards should remain hidden" % expected["id"]
			)
		if marker_type == "gate":
			gate_count += 1
			_expect(
				not bool(marker.get("visible", false)),
				"%s undiscovered gate should remain hidden" % expected["id"]
			)
	_expect(visible_exit, "%s exit marker should be visible from stage start" % expected["id"])
	if expected["id"] == "broken_sanctum":
		_expect(gate_count == 1, "Broken Sanctum map should project its authored gate")


func _validate_same_stage_retry_knowledge() -> void:
	_run_state.start_new_run(0, FIXTURE_SEED)
	_run_state.current_stage_index = 0
	var first := await _instantiate_stage()
	if first == null:
		_expect(false, "retry-knowledge first stage should instantiate")
		return
	var plan: StagePlan = first.get_stage_plan()
	var second_room: PlannedRoom
	for room in plan.get_rooms():
		if room.required_route and room.route_index == 1:
			second_room = room
			break
	var host: RoomTemplateHost = first.get_room_host(second_room.id) if second_room != null else null
	_expect(host != null, "retry-knowledge fixture needs the second room")
	if host == null:
		first.queue_free()
		await process_frame
		return
	first.player.global_position = (
		host.global_position
		+ host.template_data.bounds.position
		+ host.template_data.bounds.size * 0.5
	)
	for _frame in 4:
		await physics_frame
		await process_frame
	var explored := first.get_stage_map_snapshot() as Dictionary
	var explored_count := _visited_room_count(explored)
	_expect(explored_count >= 2, "crossing a room should add exploration knowledge")
	first.queue_free()
	await process_frame

	var retried := await _instantiate_stage()
	_expect(
		retried != null and _visited_room_count(retried.get_stage_map_snapshot()) >= explored_count,
		"same-stage reload should preserve visited rooms"
	)
	if retried != null:
		retried.queue_free()
		await process_frame

	_run_state.start_new_run(0, FIXTURE_SEED)
	_run_state.current_stage_index = 0
	var fresh := await _instantiate_stage()
	_expect(
		fresh != null and _visited_room_count(fresh.get_stage_map_snapshot()) == 1,
		"new run should reset exploration knowledge even for the same content signature"
	)
	if fresh != null:
		fresh.queue_free()
		await process_frame


func _instantiate_stage() -> Node:
	var packed := load(STAGE_PATH) as PackedScene
	if packed == null:
		return null
	var stage := packed.instantiate()
	root.add_child(stage)
	for _frame in 4:
		await process_frame
	if not stage.has_method("is_setup_complete") or not stage.is_setup_complete():
		stage.queue_free()
		await process_frame
		return null
	return stage


func _terminal_room_id(stage: Node) -> StringName:
	var plan: StagePlan = stage.get_stage_plan()
	for room in plan.get_rooms():
		var host: RoomTemplateHost = stage.get_room_host(room.id)
		if host != null and host.get_exit_portal() != null:
			return room.id
	return &""


func _terminal_exit(stage: Node) -> ExitPortal:
	var terminal_id := _terminal_room_id(stage)
	var host: RoomTemplateHost = stage.get_room_host(terminal_id)
	return host.get_exit_portal() if host != null else null


func _visited_room_count(snapshot: Dictionary) -> int:
	var count := 0
	for room_value in snapshot.get("rooms", []):
		if bool((room_value as Dictionary).get("visited", false)):
			count += 1
	return count


func _defeat(enemy: Node, source: Node) -> void:
	enemy.receive_damage(DamageInfo.new(
		int(enemy.get("current_health")),
		source,
		Vector2.ZERO,
		["area"],
		&"terminal_policy_validation"
	))


func _on_required_room_cleared(context: Dictionary) -> void:
	_room_clear_events.append(String(context.get("room_id", "")))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_PROGRESSION_POLICY_VALIDATION_OK stages=3 retry_knowledge=preserved")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
