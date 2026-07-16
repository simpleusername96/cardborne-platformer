extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const RUN_SEED := 2207
const FIXED_LAYOUT_SEED_V1 := 0x43415244
const REQUIRED_ROLES: Array[StringName] = [
	&"start", &"combat", &"hazard", &"combat", &"choice", &"combat", &"safe",
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
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_expect(run_state.start_new_run(0, RUN_SEED), "Traveler fixture should start")
	run_state.current_stage_index = 1

	var packed := load(STAGE_PATH) as PackedScene
	var stage: Variant = packed.instantiate() if packed != null else null
	_expect(stage != null, "Flooded production stage should instantiate")
	if stage == null:
		_finish()
		return
	root.add_child(stage)
	await process_frame
	await physics_frame
	_expect(stage.is_setup_complete(), "Flooded production stage should finish runtime setup")
	if not stage.is_setup_complete():
		stage.queue_free()
		_finish()
		return

	_validate_plan(stage)
	_validate_rooms(stage)
	_validate_content(stage)
	_validate_rope(stage)
	await _validate_exit_unlock(stage)
	stage.queue_free()
	await process_frame
	_finish()


func _validate_plan(stage: Variant) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	_expect(stage.stage_id == "flooded_works", "runtime stage ID should be flooded_works")
	_expect(stage.stage_display_name == "Flooded Works", "runtime stage should publish its profile name")
	_expect(stage.get_clear_reward_table_id() == &"stage_clear_flooded_works", "clear reward should be typed")
	_expect(plan != null and plan.profile_id == &"flooded_works", "runtime should retain the Flooded plan")
	if plan == null:
		return
	_expect(
		plan.run_seed == FIXED_LAYOUT_SEED_V1 and plan.stage_index == 1,
		"plan identity should be fixed; seed=%d stage=%d" % [plan.run_seed, plan.stage_index]
	)
	_expect(plan.get_rooms().size() == 8, "Flooded runtime should assemble its 7+1 graph")
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
	_expect(roles == REQUIRED_ROLES, "Flooded required route should end at the safe room")
	_expect(optional_count == 1, "Flooded route should contain one optional branch")


func _validate_rooms(stage: Variant) -> void:
	_expect(stage.get_room_ids().size() == 8, "every planned Flooded room should instantiate")
	var terminal: RoomTemplateHost
	for room in stage.get_stage_plan().get_rooms():
		var host: RoomTemplateHost = stage.get_room_host(room.id)
		_expect(host != null and host.template_data != null, "room %s should retain typed data" % room.id)
		if room.role == &"safe":
			terminal = host
	_expect(terminal != null, "Flooded runtime should expose its safe terminal room")
	if terminal != null:
		_expect(terminal.get_exit_portal() != null, "safe terminal should own the continuation gate")
		_expect(
			terminal.get_anchor(&"Objective", &"Checkpoint") != null,
			"safe terminal should own the stage checkpoint"
		)


func _validate_content(stage: Variant) -> void:
	var scene_catalog := load("res://data/enemies/enemy_scene_catalog.tres") as EnemySceneCatalog
	var plan: StagePlan = stage.get_stage_plan()
	var enemies: Array = stage.get_all_enemies()
	_expect(enemies.size() == plan.get_encounters().size(), "every Flooded encounter should spawn")
	_expect(not stage.get_required_enemies().is_empty(), "Flooded required route should contain combat")
	for enemy in enemies:
		_expect(enemy.resolved_spec != null, "Flooded enemy should resolve an immutable variant")
		if enemy.resolved_spec == null:
			continue
		var expected := scene_catalog.get_scene(
			enemy.resolved_spec.archetype_id,
			enemy.resolved_spec.variant_id
		)
		_expect(enemy.resolved_spec.stage_id == &"flooded_works", "enemy variant should belong to Flooded Works")
		_expect(
			expected != null and enemy.scene_file_path == expected.resource_path,
			"%s should use its exact variant scene" % enemy.resolved_spec.variant_id
		)
	var hazards: Array = stage.get_spawned_hazards()
	_expect(hazards.size() == plan.get_hazards().size(), "every Flooded hazard should spawn")
	for index in mini(hazards.size(), plan.get_hazards().size()):
		var hazard_id := plan.get_hazards()[index].hazard_id
		_expect(
			(hazard_id == &"timed_poison_vent" and hazards[index] is TimedPoisonVent)
			or (hazard_id == &"crumbling_platform" and hazards[index] is CrumblingPlatform),
			"hazard %s should use its production component" % hazard_id
		)


func _validate_rope(stage: Variant) -> void:
	var host: RoomTemplateHost = stage.get_room_host(&"fw_rope_shaft")
	var rope := host.get_node_or_null("Anchors/Objective/RopeClimb") as Climbable if host != null else null
	_expect(rope != null, "Rope Shaft should instantiate a climbable recovery route")
	if rope == null:
		return
	var before: int = stage.player.climbable_count
	stage.player.enter_climbable(rope)
	_expect(stage.player.climbable_count == before + 1, "player should enter the authored rope")
	stage.player.exit_climbable(rope)
	_expect(stage.player.climbable_count == before, "player should leave the authored rope cleanly")


func _validate_exit_unlock(stage: Variant) -> void:
	_expect(not stage.is_exit_enabled(), "safe-room exit should wait for required combat")
	for enemy in stage.get_required_enemies():
		enemy.receive_damage(DamageInfo.new(enemy.current_health, stage.player))
	await process_frame
	_expect(stage.get_remaining_enemy_count() == 0, "required Flooded defeats should settle once")
	_expect(stage.is_exit_enabled(), "optional branch cannot block the safe-room exit")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_STAGE_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
