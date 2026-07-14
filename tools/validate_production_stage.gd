extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const REQUIRED_ROOM_COUNT := 8
const TOTAL_ROOM_COUNT := 9
const MIN_LANDING_WIDTH := 220.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load(MAIN_SCENE) as PackedScene
	_expect(packed_main != null, "main scene should load for production validation")
	if packed_main == null:
		_finish()
		return
	var main_instance := packed_main.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var run_director := root.get_node_or_null("/root/RunDirector")
	var game := root.get_node_or_null("/root/Game")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(run_director != null and game != null and run_state != null, "production autoloads should exist")
	if run_director == null or game == null or run_state == null:
		_finish()
		return
	_expect(run_director.start_production_run(0), "production Traveler run should start")
	await process_frame
	await process_frame
	var stage: Variant = game.current_stage
	_expect(stage != null and stage.is_setup_complete(), "generated production stage should finish setup")
	if stage == null or not stage.is_setup_complete():
		_finish()
		return

	_expect(stage.stage_id == "ruin_approach", "production stage should use Ruin Approach ID")
	_expect(game.current_stage_path == STAGE_PATH, "production run should use the production stage path")
	_expect(stage.player != null, "generated stage should spawn the selected player")
	_validate_plan_and_rooms(stage)
	_validate_surfaces(stage)
	_validate_runtime_content(stage)
	await _validate_fall_reset(stage, run_state)
	await _validate_hud(run_director, game, stage)
	await _validate_exit_flow(stage, run_director, game, run_state)

	run_director.show_main_menu()
	main_instance.queue_free()
	await process_frame
	_finish()


func _validate_plan_and_rooms(stage: Variant) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	_expect(plan != null, "runtime stage should retain its accepted StagePlan")
	_expect(stage.get_generation_report() != null, "runtime stage should retain its GenerationReport")
	if plan == null:
		return
	var rooms := plan.get_rooms()
	var required_count := 0
	var optional_count := 0
	var choice_room: PlannedRoom
	var optional_room: PlannedRoom
	for room in rooms:
		if room.required_route:
			required_count += 1
		else:
			optional_count += 1
			optional_room = room
		if room.role == &"choice":
			choice_room = room
		var host: RoomTemplateHost = stage.get_room_host(room.id)
		_expect(host != null and host.template_data != null, "room %s should retain typed data" % room.id)
		if host == null:
			continue
		for root_name in [
			"Terrain", "OneWay", "Hazards", "DecorBack", "DecorFront", "Anchors",
			"CameraBounds", "Validation",
		]:
			_expect(host.get_node_or_null(root_name) != null, "room %s needs %s" % [room.id, root_name])
		if room.role != &"exit":
			_expect(host.get_exit_portal() == null, "only the terminal room may own an exit portal")
	_expect(rooms.size() == TOTAL_ROOM_COUNT, "Stage 1 should contain eight required rooms and one optional room")
	_expect(required_count == REQUIRED_ROOM_COUNT and optional_count == 1, "Stage 1 route ownership should be 8+1")
	_expect(stage.get_room_ids().size() == TOTAL_ROOM_COUNT, "all planned rooms should instantiate")
	if choice_room != null and optional_room != null:
		var choice_host: RoomTemplateHost = stage.get_room_host(choice_room.id)
		var optional_host: RoomTemplateHost = stage.get_room_host(optional_room.id)
		_expect(
			optional_host.position.is_equal_approx(choice_host.position + Vector2(0.0, 720.0)),
			"optional room should occupy the reviewed lower branch lane"
		)
	_validate_room_bounds_do_not_overlap(stage, rooms)


func _validate_room_bounds_do_not_overlap(stage: Variant, rooms: Array[PlannedRoom]) -> void:
	for first_index in rooms.size():
		var first := rooms[first_index]
		var first_host: RoomTemplateHost = stage.get_room_host(first.id)
		var first_rect := Rect2(
			first_host.position + first_host.template_data.bounds.position,
			first_host.template_data.bounds.size
		)
		for second_index in range(first_index + 1, rooms.size()):
			var second := rooms[second_index]
			var second_host: RoomTemplateHost = stage.get_room_host(second.id)
			var second_rect := Rect2(
				second_host.position + second_host.template_data.bounds.position,
				second_host.template_data.bounds.size
			)
			_expect(not first_rect.intersects(second_rect), "assembled room bounds cannot overlap")


func _validate_surfaces(stage: Variant) -> void:
	var surfaces: Array = stage.get_critical_surface_contract()
	var world_bounds: Rect2 = stage.get_world_bounds()
	var rooms_with_support: Dictionary = {}
	_expect(not surfaces.is_empty(), "generated required route should expose critical surfaces")
	for surface in surfaces:
		_expect(float(surface.get("width", 0.0)) >= MIN_LANDING_WIDTH, "critical landing is too narrow")
		_expect(bool(surface.get("critical", false)), "surface report should exclude noncritical recovery masses")
		_expect(
			float(surface.get("top", INF)) >= world_bounds.position.y
			and float(surface.get("top", -INF)) <= world_bounds.end.y,
			"critical surface top should use world-space Y"
		)
		rooms_with_support[String(surface.get("room_id", ""))] = true
	for room in stage.get_stage_plan().get_rooms():
		if room.required_route:
			_expect(rooms_with_support.has(String(room.id)), "required room %s needs critical support" % room.id)
	_expect(stage.player.camera.limit_left == int(world_bounds.position.x), "camera should use generated left bound")
	_expect(stage.player.camera.limit_bottom == int(world_bounds.end.y), "camera should use generated lower bound")


func _validate_runtime_content(stage: Variant) -> void:
	var plan: StagePlan = stage.get_stage_plan()
	var all_enemies: Array = stage.get_all_enemies()
	var required_enemies: Array = stage.get_required_enemies()
	_expect(all_enemies.size() == plan.get_encounters().size(), "every planned encounter should spawn exactly once")
	_expect(required_enemies.size() > 0, "required route should contain combat")
	_expect(stage.get_spawned_hazards().size() == plan.get_hazards().size(), "planned hazards should spawn exactly once")
	_expect(stage.get_spawned_rewards().size() == plan.get_rewards().size(), "planned rewards should spawn exactly once")
	for reward in stage.get_spawned_rewards():
		var context: Dictionary = reward.get_claim_context()
		var placement := _reward_by_id(plan, StringName(context.get("source_id", &"")))
		var room := plan.get_room(placement.room_id) if placement != null else null
		var expected_optional := (
			placement != null
			and (
				placement.reward_role in [&"optional_route", &"route_choice"]
				or (room != null and not room.required_route)
			)
		)
		_expect(placement != null, "spawned reward should retain its planned source identity")
		_expect(
			bool(context.get("optional_route", false)) == expected_optional,
			"spawned reward should retain its route ownership"
		)
	for enemy in all_enemies:
		var encounter_id := StringName(enemy.get_meta("planned_encounter_id", ""))
		var placement := _encounter_by_id(plan, encounter_id)
		_expect(placement != null and enemy.resolved_spec != null, "spawned enemy should resolve its planned variant")
		_expect(not enemy.auto_reset_on_defeat, "production enemies cannot auto-reset")
		_expect(
			not enemy.is_target_within_encounter(stage.player),
			"future-room enemies must not target the player from the start room"
		)
		if placement == null or enemy.resolved_spec == null:
			continue
		_expect(enemy.resolved_spec.variant_id == placement.variant_id, "runtime enemy variant should match StagePlan")
		var host: RoomTemplateHost = stage.get_room_host(placement.room_id)
		var anchor := host.get_anchor_by_id(&"Enemy", placement.anchor_id)
		_expect(enemy.spawn_position.is_equal_approx(anchor.global_position), "enemy should start exactly on its planned anchor")


func _validate_fall_reset(stage: Variant, run_state: Node) -> void:
	var world_bounds: Rect2 = stage.get_world_bounds()
	var fall_reset := stage.find_child("StageFallReset", true, false) as FallResetZone
	_expect(fall_reset != null, "production stage should own one stage-wide fall reset")
	if fall_reset == null:
		return
	var collision := fall_reset.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rectangle := collision.shape as RectangleShape2D if collision != null else null
	_expect(
		rectangle != null and rectangle.size == Vector2(world_bounds.size.x + 480.0, 180.0),
		"production fall reset collision should span the complete approved stage"
	)
	var before := int(run_state.get("current_health"))
	if before > 1:
		run_state.call("damage_player", 1)
		before -= 1
	stage.player.global_position = Vector2(world_bounds.end.x + 100.0, fall_reset.global_position.y)
	stage.player.velocity = Vector2.ZERO
	for _frame in 3:
		await physics_frame
		await process_frame
	_expect(int(run_state.get("current_health")) == before, "fall reset must not heal the player")
	_expect(
		stage.player.global_position.is_equal_approx(stage.current_checkpoint_position),
		"far-edge fall reset collision should return the player to the checkpoint"
	)

	stage.player.global_position = Vector2(world_bounds.end.x + 600.0, world_bounds.end.y + 720.0)
	stage.player.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	_expect(
		stage.player.global_position.is_equal_approx(stage.current_checkpoint_position),
		"stage Y failsafe should recover a player that misses the reset area"
	)
	_expect(int(run_state.get("current_health")) == before, "fall failsafe must not heal the player")


func _validate_hud(run_director: Node, game: Node, stage: Variant) -> void:
	var hud: Variant = run_director.current_hud
	_expect(hud != null, "production run should mount its HUD")
	if hud == null:
		return
	var layout: Dictionary = hud.call("get_layout_snapshot")
	_expect(
		String(layout.get("objective_detail", "")).contains(
			str(stage.get_remaining_enemy_count())
		),
		"HUD should show the approved required encounter count"
	)
	var slots_by_role: Dictionary = {}
	for slot_value in layout.get("slots", []):
		if slot_value is Dictionary:
			var slot := slot_value as Dictionary
			slots_by_role[String(slot.get("slot_role", ""))] = slot
	var basic: Dictionary = slots_by_role.get("basic", {})
	_expect(
		bool(basic.get("available", false))
		and String(basic.get("label", "")) == "HUNTING BOW",
		"HUD should expose the Traveler's contextual attack"
	)
	var bus := root.get_node_or_null("/root/SignalBus")
	bus.emit_signal("interaction_prompt_changed", "Enter gate", true)
	await process_frame
	layout = hud.call("get_layout_snapshot")
	var binding: String = str(game.call("get_action_binding_text", "interact", "E"))
	_expect(
		bool(layout.get("prompt_visible", false))
		and String(layout.get("prompt_binding", "")) == binding
		and String(layout.get("prompt_text", "")) == "Enter gate",
		"interaction prompt should use current binding and message"
	)
	bus.emit_signal("interaction_prompt_changed", "", false)


func _validate_exit_flow(stage: Variant, run_director: Node, game: Node, run_state: Node) -> void:
	var terminal: RoomTemplateHost
	for room in stage.get_stage_plan().get_rooms():
		if room.role == &"exit":
			terminal = stage.get_room_host(room.id)
	var exit := terminal.get_exit_portal() if terminal != null else null
	_expect(exit != null and not stage.is_exit_enabled(), "terminal exit should start locked")
	if exit == null:
		return
	exit.interact(stage.player)
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "locked exit cannot clear the stage")
	for enemy in stage.get_required_enemies():
		_defeat_for_flow_validation(enemy, stage.player)
	await process_frame
	_expect(stage.get_remaining_enemy_count() == 0, "required defeats should settle exactly once")
	_expect(stage.is_exit_enabled(), "optional content cannot block the terminal exit")
	exit.interact(stage.player)
	await process_frame
	await process_frame
	_expect(game.current_stage == null, "reward flow should unload gameplay")
	for _choice_index in 8:
		if run_director.get_phase_name() != "level_reward":
			break
		var offer: Array = run_state.call("get_pending_level_offer")
		_expect(offer.size() == 3, "level reward should offer three choices")
		if offer.is_empty():
			return
		var pending_before := int(run_state.call("get_pending_level_choice_count"))
		run_director.call("_on_level_choice_requested", offer[0])
		await process_frame
		if int(run_state.call("get_pending_level_choice_count")) >= pending_before:
			_expect(false, "level reward choice should advance the Traveler build")
			return
	_expect(run_director.get_phase_name() == "stage_card_reward", "stage clear should reach card reward")
	var card_offer: Array = run_state.call("get_pending_card_offer")
	_expect(card_offer.size() == 3, "card reward should offer three choices")
	if card_offer.is_empty():
		return
	run_director.call("_on_card_choice_requested", card_offer[0])
	await process_frame
	run_director.call("_on_card_continue_requested")
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "card Continue should load the next stage")
	_expect(game.current_stage != null and game.current_stage.is_setup_complete(), "next generated stage should initialize")
	_expect(int(run_state.get("current_stage_index")) == 1, "card Continue should advance stage index")
	if game.current_stage != null and game.current_stage.is_setup_complete():
		await _validate_flooded_exit_flow(game.current_stage, run_director, game, run_state)


func _validate_flooded_exit_flow(
	stage: Variant,
	run_director: Node,
	game: Node,
	run_state: Node
) -> void:
	_expect(stage.stage_id == "flooded_works", "second production stage should be Flooded Works")
	var terminal: RoomTemplateHost
	for room in stage.get_stage_plan().get_rooms():
		if room.role == &"safe":
			terminal = stage.get_room_host(room.id)
	var exit := terminal.get_exit_portal() if terminal != null else null
	_expect(exit != null and not stage.is_exit_enabled(), "Flooded safe-room exit should start locked")
	if exit == null:
		return
	for enemy in stage.get_required_enemies():
		_defeat_for_flow_validation(enemy, stage.player)
	await process_frame
	_expect(stage.is_exit_enabled(), "Flooded required defeats should unlock the safe-room exit")
	exit.interact(stage.player)
	await process_frame
	await process_frame
	_expect(game.current_stage == null, "Flooded clear should unload gameplay for rewards")
	for _choice_index in 8:
		if run_director.get_phase_name() != "level_reward":
			break
		var level_offer: Array = run_state.call("get_pending_level_offer")
		_expect(level_offer.size() == 3, "Flooded clear level reward should offer three choices")
		if level_offer.is_empty():
			return
		var pending_before := int(run_state.call("get_pending_level_choice_count"))
		run_director.call("_on_level_choice_requested", level_offer[0])
		await process_frame
		if int(run_state.call("get_pending_level_choice_count")) >= pending_before:
			_expect(false, "Flooded level reward choice should advance the Traveler build")
			return
	_expect(run_director.get_phase_name() == "stage_card_reward", "Flooded clear should reach card reward")
	var card_offer: Array = run_state.call("get_pending_card_offer")
	_expect(card_offer.size() == 3, "Flooded card reward should offer three choices")
	if card_offer.is_empty():
		return
	run_director.call("_on_card_choice_requested", card_offer[0])
	await process_frame
	run_director.call("_on_card_continue_requested")
	await process_frame
	_expect(run_director.get_phase_name() == "rest_forge", "Stage 2 card Continue should open the camp forge")
	_expect(run_director.current_screen is ForgeScreen, "camp forge should use the deterministic equipment screen")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var preparation: Dictionary = (
		profile_state.call("get_preparation_snapshot") if profile_state != null else {}
	)
	_expect(
		String(preparation.get("hero_id", "")) == "traveler"
		and (preparation.get("slots", []) as Array).size() == 4,
		"camp forge should expose the saved Traveler equipment state"
	)
	_expect(int(run_state.get("current_stage_index")) == 2, "camp forge should prepare Stage 3")


func _encounter_by_id(plan: StagePlan, encounter_id: StringName) -> PlannedEncounter:
	for encounter in plan.get_encounters():
		if encounter.id == encounter_id:
			return encounter
	return null


func _reward_by_id(plan: StagePlan, reward_id: StringName) -> PlannedReward:
	for reward in plan.get_rewards():
		if reward.id == reward_id:
			return reward
	return null


func _defeat_for_flow_validation(enemy: Variant, source: Node) -> void:
	# Flow validation bypasses defensive AI so it tests settlement, not combat tactics.
	enemy.receive_damage(DamageInfo.new(
		enemy.current_health,
		source,
		Vector2.ZERO,
		["area"],
		&"production_flow_validation"
	))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PRODUCTION_STAGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
