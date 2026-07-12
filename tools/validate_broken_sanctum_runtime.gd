extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const RUN_SEED := 41_000
const REQUIRED_ROLES: Array[StringName] = [
	&"start", &"combat", &"objective", &"hazard", &"choice", &"safe", &"combat", &"exit",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "production state autoloads should exist")
	if profile_state == null or run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	for profile_index in 3:
		await _validate_profile_stage(run_state, profile_index)
	_finish()


func _validate_profile_stage(run_state: Node, profile_index: int) -> void:
	_expect(run_state.start_new_run(profile_index, RUN_SEED), "profile %d should start" % profile_index)
	run_state.current_stage_index = 2
	var packed := load(STAGE_PATH) as PackedScene
	var stage: Variant = packed.instantiate() if packed != null else null
	_expect(stage != null, "profile %d Stage 3 should instantiate" % profile_index)
	if stage == null:
		return
	root.add_child(stage)
	await process_frame
	await physics_frame
	_expect(stage.is_setup_complete(), "profile %d Stage 3 should finish setup" % profile_index)
	if stage.is_setup_complete():
		_validate_plan(stage, profile_index)
		_validate_runtime_content(stage, profile_index)
		await _validate_exit_unlock(stage, profile_index)
	stage.queue_free()
	await process_frame


func _validate_plan(stage: Variant, profile_index: int) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	_expect(stage.stage_id == "broken_sanctum", "profile %d should load Broken Sanctum" % profile_index)
	_expect(stage.get_clear_reward_table_id() == &"stage_clear_broken_sanctum", "Stage 3 clear reward should be typed")
	_expect(plan != null and plan.profile_id == &"broken_sanctum", "profile %d should retain Stage 3 plan" % profile_index)
	if plan == null:
		return
	_expect(plan.run_seed == RUN_SEED and plan.stage_index == 2, "Stage 3 plan identity should be stable")
	_expect(plan.get_rooms().size() == 10, "Broken Sanctum should assemble 8+2 rooms")
	var required: Array[PlannedRoom] = []
	var optional_count := 0
	for room in plan.get_rooms():
		if room.required_route:
			required.append(room)
		else:
			optional_count += 1
	required.sort_custom(func(left: PlannedRoom, right: PlannedRoom) -> bool:
		return left.route_index < right.route_index
	)
	var roles: Array[StringName] = []
	for room in required:
		roles.append(room.role)
	_expect(roles == REQUIRED_ROLES, "Stage 3 required role sequence should remain exact")
	_expect(optional_count == 2, "Stage 3 should contain two optional branches")


func _validate_runtime_content(stage: Variant, profile_index: int) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	_expect(stage.get_room_ids().size() == 10, "profile %d should instantiate every Stage 3 room" % profile_index)
	_expect(stage.get_all_enemies().size() == plan.get_encounters().size(), "every Sanctum encounter should spawn")
	for enemy in stage.get_all_enemies():
		_expect(enemy.resolved_spec != null, "Sanctum enemy should retain resolved data")
		if enemy.resolved_spec != null:
			_expect(enemy.resolved_spec.stage_id == &"broken_sanctum", "enemy should use a Sanctum variant")
	_expect(stage.get_spawned_hazards().size() == plan.get_hazards().size(), "every Stage 3 hazard should spawn")
	var rewards: Array = stage.get_spawned_rewards()
	_expect(rewards.size() == 2, "both optional Stage 3 rewards should spawn")
	var has_chest := false
	var has_material_node := false
	for reward in rewards:
		has_chest = has_chest or reward is ChestInteractable
		has_material_node = has_material_node or reward is MaterialNode
	_expect(has_chest and has_material_node, "Stage 3 optional branches should expose chest and material node")
	var gate_room: RoomTemplateHost = stage.get_room_host(&"bs_gate_switch_loop")
	var moving_platforms := gate_room.find_children("*", "MovingPlatform", true, false) if gate_room != null else []
	_expect(moving_platforms.size() == 1, "gate loop should expose one optional moving platform")


func _validate_exit_unlock(stage: Variant, profile_index: int) -> void:
	_expect(not stage.is_exit_enabled(), "profile %d exit should wait for required combat" % profile_index)
	for enemy in stage.get_required_enemies():
		enemy.receive_damage(DamageInfo.new(
			enemy.current_health,
			stage.player,
			Vector2.ZERO,
			["area"],
			&"stage_runtime_validation"
		))
	await process_frame
	_expect(stage.get_remaining_enemy_count() == 0, "profile %d required enemies should settle" % profile_index)
	_expect(stage.is_exit_enabled(), "profile %d should unlock Stage 3 exit" % profile_index)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BROKEN_SANCTUM_RUNTIME_VALIDATION_OK profiles=3")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
