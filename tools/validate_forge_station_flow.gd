extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main/Main.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	var run_director := root.get_node_or_null("/root/RunDirector")
	var game := root.get_node_or_null("/root/Game")
	_expect(
		profile_state != null and run_state != null and run_director != null and game != null,
		"Forge fixture needs production autoloads."
	)
	if profile_state == null or run_state == null or run_director == null or game == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	profile_state.grant_material_command("rusted_scrap", 6)
	profile_state.grant_material_command("common_timber", 7)
	profile_state.unlock_blueprint(&"hunting_spear", &"fixture:intermission_forge:spear")

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	_expect(packed_main != null, "Forge fixture should load the main scene.")
	if packed_main == null:
		_finish()
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await process_frame
	_expect(run_director.start_production_run(0), "Forge fixture should start a production run.")
	await process_frame
	await process_frame
	var combat_stage: Node = game.current_stage
	_expect(combat_stage != null, "Forge fixture should load Stage 1.")
	if combat_stage == null:
		_finish()
		return
	_expect(
		combat_stage.find_children("*", "ForgeStationInteractable", true, false).is_empty(),
		"Monster stages cannot own Forge interactables."
	)
	_expect(
		combat_stage.find_children("*", "MerchantInteractable", true, false).is_empty(),
		"Monster stages cannot own Merchant interactables."
	)

	game.unload_current_stage()
	_expect(
		run_director.call("_set_phase", RunPhase.Value.STAGE_CARD_REWARD),
		"Fixture should reach the card-reward boundary."
	)
	run_state.set("current_stage_index", 1)
	_expect(run_director.call("_load_safe_intermission"), "Safe Intermission should load.")
	await process_frame
	await process_frame
	var intermission: Node = game.current_stage
	_expect(
		intermission != null
		and intermission.has_method("is_setup_complete")
		and bool(intermission.call("is_setup_complete")),
		"Safe Intermission should be playable."
	)
	if intermission == null:
		_finish()
		return
	var forges := intermission.find_children("*", "ForgeStationInteractable", true, false)
	var merchants := intermission.find_children("*", "MerchantInteractable", true, false)
	_expect(forges.size() == 1, "Safe Intermission should own exactly one Forge NPC.")
	_expect(merchants.size() == 1, "Safe Intermission should own exactly one Merchant NPC.")
	_expect(
		intermission.has_method("has_combat_content")
		and not bool(intermission.call("has_combat_content")),
		"Safe Intermission cannot expose combat content."
	)
	if forges.is_empty():
		_finish()
		return

	forges[0].call("interact", intermission.get("player"))
	await process_frame
	_expect(run_director.get_phase_name() == "intermission_active", "Forge should remain inside the intermission phase.")
	_expect(game.reward_choice_open and paused, "Forge interaction should pause intermission movement.")
	_expect(
		run_director.current_screen != null
		and run_director.current_screen.has_method("configure")
		and run_director.current_screen.has_signal("equipment_action_requested"),
		"Forge NPC should open the Forge screen."
	)
	run_director.call(
		"_on_forge_equipment_action_requested",
		&"craft",
		&"hunting_spear",
		&"melee"
	)
	await process_frame
	var decision: Dictionary = profile_state.get_equipment_decision_snapshot(&"hunting_spear")
	_expect(bool(decision.get("crafted", false)), "Forge should craft through ProfileState.")
	run_director.call(
		"_on_forge_equipment_action_requested",
		&"equip",
		&"hunting_spear",
		&"melee"
	)
	await process_frame
	_expect(
		String(profile_state.get_hero_loadout().get("melee", "")) == "hunting_spear",
		"Forge should equip the crafted model."
	)
	_expect(
		String(run_state.get_hero_combat_loadout_snapshot().get("loadout", {}).get("melee", "")) == "hunting_spear",
		"Active run should synchronize the equipped model."
	)
	run_director.call("_on_forge_leave_requested")
	await process_frame
	_expect(not game.reward_choice_open and not paused, "Leaving Forge should resume intermission movement.")
	_expect(game.current_stage == intermission, "Leaving Forge should retain the safe map.")
	_expect(run_director.current_screen == null, "Forge screen should close cleanly.")

	run_director.show_main_menu()
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	paused = false
	if _failures.is_empty():
		print("FORGE_STATION_FLOW_VALIDATION_OK field=0 intermission=1 craft=equip resume=safe_map")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
