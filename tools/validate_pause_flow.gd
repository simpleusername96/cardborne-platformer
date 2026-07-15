extends SceneTree

const MAIN_SCENE := "res://scenes/main/Main.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 540)
	var main_scene := load(MAIN_SCENE) as PackedScene
	_expect(main_scene != null, "main scene should load")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var game := root.get_node_or_null("/root/Game")
	var director := root.get_node_or_null("/root/RunDirector")
	var profile := root.get_node_or_null("/root/ProfileState")
	_expect(game != null and director != null and profile != null, "production autoloads should load")
	if game == null or director == null or profile == null:
		_finish()
		return

	profile.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_expect(bool(director.start_production_run(0)), "test run should start")
	await process_frame

	var pause_menu := main.get_node_or_null("UILayer/PauseMenu") as Control
	var settings := main.get_node_or_null("UILayer/SettingsPopup") as Control
	_expect(pause_menu != null and settings != null, "pause and settings overlays should mount")
	if pause_menu == null or settings == null:
		_finish()
		return

	game.set_pause_menu_open(true)
	await process_frame
	var resume := pause_menu.find_child("ResumeButton", true, false) as Button
	_expect(paused, "opening pause menu should stop gameplay")
	_expect(pause_menu.visible and not settings.visible, "pause menu should own the first overlay state")
	_expect(resume != null and resume.has_focus(), "Resume should receive initial focus")
	_expect(pause_menu.size.is_equal_approx(Vector2(root.size)), "pause overlay should fill compact viewport")

	pause_menu.call("_show_confirmation")
	await process_frame
	var confirmation := pause_menu.find_child("AbandonConfirmation", true, false) as VBoxContainer
	var warning := pause_menu.find_child("AbandonWarning", true, false) as Label
	var keep_playing := pause_menu.find_child("KeepPlayingButton", true, false) as Button
	_expect(confirmation != null and confirmation.visible, "Main Menu should open confirmation")
	_expect(
		warning != null
			and warning.text == _t(
				"Run cards, coins, and stage progress will be lost. Secured materials stay kept."
			),
		"confirmation should state run loss"
	)
	_expect(keep_playing != null and keep_playing.has_focus(), "safe confirmation action should own focus")

	pause_menu.call("_show_menu")
	game.set_settings_open(true)
	await process_frame
	var close_button := settings.get("close_button") as Button
	_expect(paused, "settings opened from pause should keep gameplay stopped")
	_expect(not pause_menu.visible and settings.visible, "settings should replace pause menu visually")
	_expect(close_button != null and close_button.text == _t("Back"), "paused settings should expose Back")

	game.set_settings_open(false)
	await process_frame
	_expect(paused and pause_menu.visible, "closing settings should return to pause menu")
	_expect(resume.has_focus(), "returning from settings should restore Resume focus")

	pause_menu.call("_show_confirmation")
	pause_menu.call("_confirm_main_menu")
	await process_frame
	_expect(not paused, "confirmed run exit should resume the scene tree")
	_expect(director.phase == RunPhase.Value.MAIN_MENU, "confirmed run exit should reach main menu")
	_expect(not game.pause_menu_open and not game.settings_open, "main menu should own no gameplay overlay")
	_expect(
		director.current_screen != null and director.current_screen.name == "MainMenu",
		"confirmed run exit should mount the production main menu"
	)

	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _t(source: StringName, values: Array = []) -> String:
	var localization := root.get_node_or_null("/root/UILocalization")
	return String(localization.call("text", source, values)) if localization != null else String(source)


func _finish() -> void:
	paused = false
	if _failures.is_empty():
		print("PAUSE_FLOW_VALIDATION_OK viewport=960x540 confirmation=1 settings_return=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
