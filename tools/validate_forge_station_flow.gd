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
		"forge station fixture needs production autoloads"
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
	profile_state.unlock_blueprint(&"hunting_spear", &"fixture:forge_station:spear")

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	_expect(packed_main != null, "forge fixture should load the main scene")
	if packed_main == null:
		_finish()
		return
	var main := packed_main.instantiate()
	root.add_child(main)
	await process_frame
	_expect(run_director.start_production_run(0), "forge fixture should start production run")
	await process_frame
	await process_frame
	var stage: Node = game.current_stage
	_expect(stage != null, "forge fixture should load Stage 1")
	if stage == null:
		_finish()
		return
	var mid_forge := stage.find_child("MidForge", true, false) as ForgeStationInteractable
	var final_forge := stage.find_child("FinalForge", true, false) as ForgeStationInteractable
	_expect(mid_forge != null and final_forge != null, "Stage 1 should own mid and final forge stations")
	if mid_forge == null:
		_finish()
		return
	mid_forge.interact(stage.get("player"))
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "field forge should preserve stage phase")
	_expect(game.reward_choice_open and paused, "field forge should pause gameplay")
	_expect(run_director.current_screen is ForgeScreen, "field forge should open deterministic screen")

	run_director.call(
		"_on_forge_equipment_action_requested",
		&"craft",
		&"hunting_spear",
		&"melee"
	)
	await process_frame
	var decision: Dictionary = profile_state.get_equipment_decision_snapshot(&"hunting_spear")
	_expect(bool(decision.get("crafted", false)), "field forge should craft through ProfileState")
	run_director.call(
		"_on_forge_equipment_action_requested",
		&"equip",
		&"hunting_spear",
		&"melee"
	)
	await process_frame
	_expect(
		String(profile_state.get_hero_loadout().get("melee", "")) == "hunting_spear",
		"field forge should equip the crafted model"
	)
	_expect(
		String(run_state.get_hero_combat_loadout_snapshot().get("loadout", {}).get("melee", "")) == "hunting_spear",
		"active run should synchronize the equipped model"
	)
	run_director.call("_on_forge_leave_requested")
	await process_frame
	_expect(not game.reward_choice_open and not paused, "leaving field forge should resume gameplay")
	_expect(game.current_stage == stage, "leaving field forge should retain the active stage")
	_expect(run_director.current_screen == null, "field forge screen should close cleanly")

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
		print("FORGE_STATION_FLOW_VALIDATION_OK stations=2 craft=equip resume=stage")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
