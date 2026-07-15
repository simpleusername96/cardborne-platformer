extends SceneTree

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed_main := load(MAIN_SCENE) as PackedScene
	_expect(packed_main != null, "main scene should load")
	if packed_main == null:
		_finish()
		return

	var main_instance := packed_main.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame

	var run_director := root.get_node_or_null("RunDirector")
	var run_state := root.get_node_or_null("RunState")
	var game := root.get_node_or_null("Game")
	var profile_state := root.get_node_or_null("ProfileState")
	var screen_root := main_instance.get_node_or_null("UILayer/ScreenRoot")
	var hud_root := main_instance.get_node_or_null("UILayer/HUDRoot")
	_expect(run_director != null, "RunDirector autoload should exist")
	_expect(run_state != null, "RunState autoload should exist")
	_expect(game != null, "Game autoload should exist")
	_expect(profile_state != null, "ProfileState autoload should exist")
	_expect(screen_root != null and hud_root != null, "main scene should expose production UI roots")
	if run_director == null or run_state == null or game == null or profile_state == null or screen_root == null or hud_root == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)

	_expect(run_director.get_phase_name() == "main_menu", "default boot should open the main menu")
	_expect(
		RunPhase.can_transition(
			RunPhase.Value.STAGE_CARD_REWARD,
			RunPhase.Value.INTERMISSION_LOADING
		)
		and not RunPhase.can_transition(RunPhase.Value.STAGE_CARD_REWARD, RunPhase.Value.RUN_CLEAR),
		"every normal-stage card reward should enter Safe Intermission"
	)
	_expect(game.current_stage == null, "default boot must not instantiate a stage")
	_expect(_has_child_named(screen_root, "MainMenu"), "main menu screen should be mounted")
	var main_menu := screen_root.get_node_or_null("MainMenu") as Control
	var menu_backdrop := main_menu.get_node_or_null("Backdrop") as Control if main_menu != null else null
	_expect(
		menu_backdrop != null and menu_backdrop.size.is_equal_approx(Vector2(root.size)),
		"production backdrop should fill the viewport"
	)

	run_director.show_hero_preparation()
	await process_frame
	_expect(run_director.get_phase_name() == "preparation", "new run should open Traveler preparation")
	_expect(_has_child_named(screen_root, "HeroPreparation"), "Traveler preparation screen should be mounted")
	var preparation := screen_root.get_node_or_null("HeroPreparation") as Control
	_expect(preparation != null, "Traveler preparation should be a Control")
	if preparation != null:
		_expect(
			preparation.find_child("CharacterStrip", true, false) == null,
			"Traveler preparation should not expose class selection"
		)
		_expect(
			preparation.find_child("LoadoutPanel", true, false) != null,
			"Traveler preparation should expose the equipment workspace"
		)
		var start_button := preparation.find_child("StartButton", true, false) as Button
		var trial_button := preparation.find_child("TutorialButton", true, false) as Button
		_expect(start_button != null and not start_button.disabled, "valid base loadout should enable Stage 1")
		_expect(trial_button != null and trial_button.text == "Begin Trial", "fresh profile should offer the Arsenal Trial")
		var focus_owner := root.gui_get_focus_owner()
		_expect(
			focus_owner != null and preparation.is_ancestor_of(focus_owner),
			"Traveler preparation should establish keyboard focus"
		)

	_expect(run_director.start_arsenal_trial(), "fresh profile should enter the fixed Arsenal Trial")
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "trial_active", "Arsenal Trial should become active")
	_expect(game.current_stage_path == "res://scenes/stages/trial/ArsenalTrial.tscn", "Trial should use its fixed scene")
	var skip_result: Dictionary = game.current_stage.call("request_skip")
	_expect(bool(skip_result.get("ok", false)), "Trial Skip should settle the shared baseline")
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "preparation", "Trial Skip should return to preparation")
	_expect(bool(profile_state.get_tutorial_state().get("skipped", false)), "Trial Skip should persist its outcome")

	_expect(run_director.start_production_run(&"traveler"), "valid Traveler loadout should start Stage 1")
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "production stage should become active")
	_expect(game.current_stage_path == PRODUCTION_STAGE_PATH, "run should load only the production stage host")
	_expect(game.current_stage != null, "production stage should instantiate")
	_expect(_has_child_named(hud_root, "ProductionHUD"), "production HUD should replace debug HUD")

	run_director.show_run_result(true)
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "normal-stage victory requests should fail closed")
	run_state.damage_player(999)
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "retry_decision", "player defeat should offer a retry decision")
	_expect(not run_state.has_terminal_settlement(), "retry decision should remain non-terminal")
	_expect(game.current_stage == null, "retry decision should unload the defeated world")
	_expect(_has_child_named(screen_root, "RunResult"), "retry decision screen should be mounted")
	_expect(run_director.end_expedition(), "explicit End Expedition should settle defeat")
	await process_frame
	_expect(run_director.get_phase_name() == "run_death", "End Expedition should use run-death phase")

	game.unload_current_stage()
	main_instance.queue_free()
	await process_frame
	_finish()


func _has_child_named(parent: Node, child_name: String) -> bool:
	return parent.get_node_or_null(child_name) != null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PRODUCTION_BOOT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
