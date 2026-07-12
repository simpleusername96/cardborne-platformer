extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const MIN_LANDING_WIDTH := 220.0
const EXPECTED_ROOM_IDS: Array[StringName] = [&"lr_charge_lane", &"lr_patrol_gallery"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load(MAIN_SCENE) as PackedScene
	_expect(packed_main != null, "main scene should load for production stage validation")
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
	_expect(run_director.start_production_run(0), "production Warrior run should start")
	await process_frame
	await process_frame
	var stage: Variant = game.current_stage
	_expect(stage != null, "production stage should instantiate through Game")
	if stage == null:
		_finish()
		return

	_expect(stage.stage_id == "ruin_approach", "production stage should use Ruin Approach ID")
	_expect(game.current_stage_path == STAGE_PATH, "production run should use the production stage path")
	_expect(stage.get_node_or_null("PlayerSpawn") != null, "production stage needs PlayerSpawn")
	_expect(stage.get_node_or_null("Rooms") != null, "production stage needs authored Rooms container")
	_expect(stage.get_node_or_null("Actors") != null, "production stage needs Actors container")
	_expect(stage.player != null, "production stage should spawn the selected player")

	_validate_rooms(stage)
	_validate_surfaces(stage, run_state)
	_validate_required_enemies(stage)
	await _validate_hud(run_director, game)
	await _validate_exit_flow(stage, run_director, game)

	run_director.show_main_menu()
	main_instance.queue_free()
	await process_frame
	_finish()


func _validate_rooms(stage: Variant) -> void:
	var room_ids: Array[StringName] = stage.get_room_ids()
	_expect(
		room_ids.size() == EXPECTED_ROOM_IDS.size()
		and room_ids.has(&"lr_patrol_gallery")
		and room_ids.has(&"lr_charge_lane"),
		"production slice should assemble patrol and charge rooms"
	)
	for room_id in EXPECTED_ROOM_IDS:
		var room: Variant = stage.get_room_host(room_id)
		_expect(room != null, "room %s should instantiate" % room_id)
		if room == null:
			continue
		_expect(room.template_data != null, "room %s should retain typed metadata" % room_id)
		for root_name in [
			"Terrain", "OneWay", "Hazards", "DecorBack", "DecorFront", "Anchors",
			"CameraBounds", "Validation",
		]:
			_expect(room.get_node_or_null(root_name) != null, "room %s needs %s" % [room_id, root_name])
		for anchor_group in ["Sockets", "Enemy", "Hazard", "Reward", "Objective", "Recovery"]:
			_expect(
				room.get_node_or_null("Anchors/%s" % anchor_group) != null,
				"room %s needs anchor group %s" % [room_id, anchor_group]
			)

	var charge_room: Variant = stage.get_room_host(&"lr_charge_lane")
	if charge_room != null:
		var validation: Node = charge_room.get_node_or_null("Validation")
		_expect(
			float(validation.get_meta("minimum_charge_lane", 0.0)) >= 520.0,
			"charge room needs a 520 px lane"
		)
		_expect(
			int(validation.get_meta("escape_route_count", 0)) >= 2,
			"charge room needs two escape elevations"
		)


func _validate_surfaces(stage: Variant, run_state: Node) -> void:
	var surfaces: Array = stage.get_critical_surface_contract()
	var route_limits: Dictionary = run_state.call("get_required_route_limits")
	var max_step_delta := float(route_limits.get("max_required_ledge", 80.0))
	_expect(surfaces.size() == 4, "production slice should expose four critical rock masses")
	for surface_index in surfaces.size():
		var surface: Dictionary = surfaces[surface_index]
		_expect(
			float(surface.get("width", 0.0)) >= MIN_LANDING_WIDTH,
			"critical landing %s is too narrow" % surface.get("id", surface_index)
		)
		_expect(float(surface.get("top", 999.0)) < 720.0, "critical terrain must be visible")
		if surface_index == 0:
			continue
		var previous: Dictionary = surfaces[surface_index - 1]
		var previous_end := float(previous["x"]) + float(previous["width"])
		_expect(
			is_equal_approx(previous_end, float(surface["x"])),
			"critical rock masses must meet without hidden gaps or overlap"
		)
		_expect(
			absf(float(previous["top"]) - float(surface["top"])) <= max_step_delta,
			"critical surface step exceeds shared movement contract"
		)


func _validate_required_enemies(stage: Variant) -> void:
	var enemies: Array = stage.get_required_enemies()
	_expect(enemies.size() == 2, "production slice should contain two required enemies")
	var seen_variants: Dictionary = {}
	var surfaces: Array = stage.get_critical_surface_contract()
	for enemy in enemies:
		_expect(enemy.resolved_spec != null, "%s should have a resolved enemy spec" % enemy.name)
		_expect(not enemy.auto_reset_on_defeat, "%s cannot auto-reset" % enemy.name)
		if enemy.resolved_spec == null:
			continue
		seen_variants[String(enemy.resolved_spec.variant_id)] = true
		var support_top := _support_top_at(enemy.global_position.x, surfaces)
		_expect(is_finite(support_top), "%s should stand over critical support" % enemy.name)
		_expect(
			absf(enemy.global_position.y - support_top) <= 1.0,
			"%s should not float or start inside terrain" % enemy.name
		)
	_expect(seen_variants.has("walker_ruin"), "production slice needs walker_ruin")
	_expect(seen_variants.has("charger_ruin"), "production slice needs charger_ruin")


func _validate_hud(run_director: Node, game: Node) -> void:
	var hud: Variant = run_director.current_hud
	_expect(hud != null, "production run should mount its HUD")
	if hud == null:
		return
	var objective := hud.get("objective_label") as Label
	var combat := hud.get("combat_label") as Label
	_expect(objective != null and objective.text.contains("Defeat enemies  2"), "HUD should show live encounter count")
	_expect(
		combat != null
		and combat.text.contains("Cleave")
		and combat.text.contains("Breaker")
		and combat.text.contains("Shield Rush"),
		"HUD should show only the working Warrior actions, got '%s'"
		% (combat.text if combat != null else "missing label")
	)
	var bus := root.get_node_or_null("/root/SignalBus")
	_expect(bus != null, "HUD validation needs SignalBus autoload")
	if bus == null:
		return
	bus.emit_signal("interaction_prompt_changed", "Enter gate", true)
	await process_frame
	var prompt_panel := hud.get("prompt_panel") as PanelContainer
	var prompt := hud.get("prompt_label") as Label
	var interaction_binding: String = str(game.call("get_action_binding_text", "interact", "E"))
	_expect(prompt_panel != null and prompt_panel.visible, "active interaction prompt should be visible")
	_expect(
		prompt != null and prompt.text.begins_with(interaction_binding),
		"interaction prompt should use the current binding, got '%s'"
		% (prompt.text if prompt != null else "missing label")
	)
	bus.emit_signal("interaction_prompt_changed", "", false)


func _validate_exit_flow(stage: Variant, run_director: Node, game: Node) -> void:
	var charge_room: Variant = stage.get_room_host(&"lr_charge_lane")
	var exit: Variant = charge_room.get_exit_portal() if charge_room != null else null
	_expect(exit != null, "charge room needs its authored exit portal")
	_expect(not stage.is_exit_enabled(), "exit should start locked")
	if exit == null:
		return
	exit.interact(stage.player)
	await process_frame
	_expect(run_director.get_phase_name() == "run_active", "locked exit cannot complete the run")

	for enemy in stage.get_required_enemies():
		enemy.receive_damage(DamageInfo.new(enemy.current_health, stage.player))
	await process_frame
	_expect(stage.get_remaining_enemy_count() == 0, "all required defeats should settle once")
	_expect(stage.is_exit_enabled(), "exit should unlock after required enemies are defeated")

	exit.interact(stage.player)
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "run_result", "unlocked exit should complete the run")
	_expect(game.current_stage == null, "completed production run should unload its stage")


func _support_top_at(world_x: float, surfaces: Array) -> float:
	for surface in surfaces:
		var start := float(surface["x"])
		var end := start + float(surface["width"])
		if world_x >= start and world_x <= end:
			return float(surface["top"])
	return INF


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
