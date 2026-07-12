extends SceneTree

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const RETIRED_TESTBED_STAGE_PATH := "res://scenes/stages/MotionTestStage.tscn"

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
	var game := root.get_node_or_null("Game")
	var screen_root := main_instance.get_node_or_null("UILayer/ScreenRoot")
	var hud_root := main_instance.get_node_or_null("UILayer/HUDRoot")
	_expect(run_director != null, "RunDirector autoload should exist")
	_expect(game != null, "Game autoload should exist")
	_expect(screen_root != null and hud_root != null, "main scene should expose production UI roots")
	if run_director == null or game == null or screen_root == null or hud_root == null:
		_finish()
		return

	_expect(run_director.get_phase_name() == "main_menu", "default boot should open the main menu")
	_expect(game.current_stage == null, "default boot must not instantiate a stage")
	_expect(not ResourceLoader.exists(RETIRED_TESTBED_STAGE_PATH), "retired integrated testbed should stay removed")
	_expect(_has_child_named(screen_root, "MainMenu"), "main menu screen should be mounted")
	var main_menu := screen_root.get_node_or_null("MainMenu") as Control
	var menu_backdrop := main_menu.get_node_or_null("Backdrop") as Control if main_menu != null else null
	_expect(
		menu_backdrop != null and menu_backdrop.size.is_equal_approx(Vector2(root.size)),
		"production backdrop should fill the viewport"
	)

	run_director.show_character_select()
	await process_frame
	_expect(run_director.get_phase_name() == "character_select", "new run should open character select")
	_expect(_has_child_named(screen_root, "CharacterSelect"), "character select screen should be mounted")

	_expect(run_director.start_production_run(0), "valid Warrior build should start a production run")
	await process_frame
	await process_frame
	_expect(run_director.get_phase_name() == "stage_active", "production stage should become active")
	_expect(game.current_stage_path == PRODUCTION_STAGE_PATH, "run should load only the production stage host")
	_expect(game.current_stage != null, "production stage should instantiate")
	_expect(_has_child_named(hud_root, "ProductionHUD"), "production HUD should replace debug HUD")

	run_director.show_run_result(true)
	await process_frame
	_expect(run_director.get_phase_name() == "run_clear", "victory result should use run-clear phase")
	_expect(game.current_stage == null, "run result should unload gameplay")
	_expect(_has_child_named(screen_root, "RunResult"), "run result screen should be mounted")

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
