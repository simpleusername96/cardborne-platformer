extends SceneTree

const MAIN_MENU_SCENE := "res://scenes/ui/production/MainMenu.tscn"
const RUN_RESULT_SCENE := "res://scenes/ui/production/RunResult.tscn"
const PAUSE_MENU_SCENE := "res://scenes/ui/PauseMenu.tscn"
const SETTINGS_SCENE := "res://scenes/ui/SettingsPopup.tscn"
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _errors: PackedStringArray = []
var _game: Node
var _profile_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null("Game")
	_profile_state = root.get_node_or_null("ProfileState")
	if _game == null or _profile_state == null:
		push_error("Shell UI validation requires the Game and ProfileState autoloads.")
		quit(1)
		return
	_profile_state.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	for viewport_size in VIEWPORTS:
		root.size = viewport_size
		DisplayServer.window_set_size(viewport_size)
		await process_frame
		await _validate_main_menu(viewport_size)
		await _validate_run_result(viewport_size)
		await _validate_pause_menu(viewport_size)
		await _validate_settings(viewport_size)

	if _errors.is_empty():
		print("SHELL_UI_VALIDATION_OK viewports=3 screens=4 states=victory>defeat>abandon>remap")
		quit(0)
		return
	for message in _errors:
		push_error(message)
	quit(1)


func _validate_main_menu(viewport_size: Vector2i) -> void:
	var screen := await _mount(MAIN_MENU_SCENE)
	if screen == null:
		return
	var new_run := screen.get_node("%NewRunButton") as Button
	var settings := screen.get_node("%SettingsButton") as Button
	var quit_button := screen.get_node("%QuitButton") as Button
	_assert_inside(new_run, viewport_size, "Main menu primary action")
	_assert_target(new_run, 44.0, "Main menu primary action")
	_assert_target(settings, 44.0, "Main menu settings action")
	_assert_target(quit_button, 44.0, "Main menu exit action")
	_assert_true(root.gui_get_focus_owner() == new_run, "Main menu must focus Begin Expedition.")

	var calls := {"new": 0, "settings": 0, "quit": 0}
	screen.connect(&"new_run_requested", func() -> void: calls["new"] += 1)
	screen.connect(&"settings_requested", func() -> void: calls["settings"] += 1)
	screen.connect(&"quit_requested", func() -> void: calls["quit"] += 1)
	new_run.pressed.emit()
	settings.pressed.emit()
	quit_button.pressed.emit()
	_assert_true(calls == {"new": 1, "settings": 1, "quit": 1}, "Main menu signals must emit once.")
	await _unmount(screen)


func _validate_run_result(viewport_size: Vector2i) -> void:
	var screen := await _mount(RUN_RESULT_SCENE)
	if screen == null:
		return
	var settlement := _victory_settlement()
	screen.call("configure", true, "Traveler", settlement)
	await process_frame

	var retry := screen.get_node("%RetryButton") as Button
	var menu := screen.get_node("%MenuButton") as Button
	var summary_panel := screen.get_node("%SummaryPanel") as Control
	_assert_inside(summary_panel, viewport_size, "Run result summary")
	_assert_target(retry, 44.0, "Run result retry action")
	_assert_target(menu, 44.0, "Run result menu action")
	_assert_true(root.gui_get_focus_owner() == retry, "Run result must focus its retry action.")
	var victory_text := _visible_label_text(screen)
	_assert_contains(victory_text, "VICTORY", "Victory result needs a clear outcome.")
	_assert_contains(victory_text, "Dash Wake", "Result build must use card display names.")
	_assert_contains(victory_text, "Traveler Sword", "Result build must include equipped item names.")
	_assert_contains(victory_text, "Boss Core", "Victory result must show kept rewards.")
	_assert_not_contains(victory_text, "Seed", "Run seed must not be player-facing.")
	_assert_not_contains(victory_text, "73021", "Run seed value must not be player-facing.")
	_assert_not_contains(victory_text, "dash_wake", "Card IDs must not be player-facing.")

	var calls := {"retry": 0, "menu": 0}
	screen.connect(&"retry_requested", func() -> void: calls["retry"] += 1)
	screen.connect(&"menu_requested", func() -> void: calls["menu"] += 1)
	retry.pressed.emit()
	menu.pressed.emit()
	_assert_true(calls == {"retry": 1, "menu": 1}, "Run result actions must emit once.")

	settlement["victory"] = false
	settlement["terminal_reason"] = "run_abandoned"
	settlement["boss_reached"] = false
	settlement["stage_reached"] = 2
	screen.call("configure", false, "Traveler", settlement)
	await process_frame
	var defeat_text := _visible_label_text(screen)
	_assert_contains(defeat_text, "DEFEAT", "Defeat result needs a clear outcome.")
	_assert_contains(defeat_text, "Secured materials were kept", "Abandon result must explain retained rewards.")
	_assert_not_contains(defeat_text, "run_abandoned", "Terminal reason IDs must not be player-facing.")
	await _unmount(screen)


func _validate_pause_menu(viewport_size: Vector2i) -> void:
	var screen := await _mount(PAUSE_MENU_SCENE)
	if screen == null:
		return
	_game.call("set_pause_menu_open", true)
	await process_frame
	var panel := screen.get_node("%PausePanel") as Control
	var resume := screen.get_node("%ResumeButton") as Button
	var keep_playing := screen.get_node("%KeepPlayingButton") as Button
	_assert_true(screen.visible, "Pause menu must become visible from Game state.")
	_assert_inside(panel, viewport_size, "Pause panel")
	_assert_true(panel.global_position.x >= viewport_size.x * 0.5, "Pause panel must preserve the left play view.")
	_assert_target(resume, 44.0, "Pause resume action")
	_assert_true(root.gui_get_focus_owner() == resume, "Pause menu must focus Resume.")

	screen.call("_show_confirmation")
	await process_frame
	_assert_true((screen.get_node("%AbandonConfirmation") as Control).visible, "Abandon confirmation must open.")
	_assert_true(root.gui_get_focus_owner() == keep_playing, "Abandon confirmation must focus its safe action.")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	screen.call("_input", cancel)
	await process_frame
	_assert_true((screen.get_node("%PauseCommands") as Control).visible, "Back must return to pause commands.")
	_assert_true(root.gui_get_focus_owner() == resume, "Returning from confirmation must restore focus.")

	_game.call("set_settings_open", true)
	await process_frame
	_assert_true(not screen.visible, "Settings must replace, not overlap, the pause panel.")
	_game.call("set_settings_open", false)
	await process_frame
	_assert_true(screen.visible, "Closing settings must restore the pause panel.")
	_game.call("close_overlays")
	await _unmount(screen)


func _validate_settings(viewport_size: Vector2i) -> void:
	var screen := await _mount(SETTINGS_SCENE)
	if screen == null:
		return
	_game.call("set_settings_open", true)
	await process_frame
	var panel := screen.get_node("%SettingsPanel") as Control
	var close_button := screen.get_node("%CloseButton") as Button
	var bindings := screen.get_node("%BindingsBox") as VBoxContainer
	_assert_true(screen.visible, "Settings must become visible from Game state.")
	_assert_inside(panel, viewport_size, "Settings panel")
	_assert_target(close_button, 40.0, "Settings close action")
	_assert_true(root.gui_get_focus_owner() == close_button, "Settings must focus Close or Back.")
	_assert_true(
		bindings.get_child_count() == (_game.call("get_input_binding_rows") as Array).size(),
		"Settings must render every visible input action."
	)
	for row in bindings.get_children():
		for child in row.get_children():
			if child is Button:
				_assert_target(child as Button, 40.0, "Binding row action")

	screen.call("_begin_capture", "jump", "Jump")
	await process_frame
	_assert_contains(
		(screen.get_node("%BindingStatus") as Label).text,
		"Press a key",
		"Remap capture must expose its active state."
	)
	_assert_true(String(screen.get("capture_action_name")) == "jump", "Remap capture must own the selected action.")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.physical_keycode = KEY_ESCAPE
	cancel.pressed = true
	screen.call("_input", cancel)
	await process_frame
	_assert_true(String(screen.get("capture_action_name")).is_empty(), "Escape must cancel remap capture.")
	_assert_contains(
		(screen.get_node("%BindingStatus") as Label).text,
		"canceled",
		"Canceled remap must be visible."
	)
	screen.call("_begin_capture", "pause", "Settings")
	screen.call("_input", cancel)
	await process_frame
	_assert_true(
		String(screen.get("capture_action_name")).is_empty(),
		"Escape must also cancel capture for the pause action; Default restores Escape."
	)

	screen.call("_begin_capture", "jump", "Jump")
	var conflict := InputEventKey.new()
	conflict.keycode = KEY_X
	conflict.physical_keycode = KEY_X
	conflict.pressed = true
	screen.call("_apply_captured_key", conflict)
	await process_frame
	_assert_true(String(screen.get("capture_action_name")) == "jump", "A binding conflict must keep capture active.")
	_assert_contains(
		(screen.get_node("%BindingStatus") as Label).text,
		"already used",
		"A binding conflict must explain the error."
	)
	screen.call("_clear_capture", false)
	_game.call("set_settings_open", false)
	await _unmount(screen)


func _mount(scene_path: String) -> Control:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_errors.append("Unable to load %s." % scene_path)
		return null
	var screen := packed.instantiate() as Control
	if screen == null:
		_errors.append("Shell scene root must be Control: %s." % scene_path)
		return null
	root.add_child(screen)
	for _frame in 3:
		await process_frame
	return screen


func _unmount(screen: Control) -> void:
	_game.call("close_overlays")
	if is_instance_valid(screen):
		screen.queue_free()
	for _frame in 2:
		await process_frame


func _victory_settlement() -> Dictionary:
	return {
		"victory": true,
		"terminal_reason": "boss_defeated",
		"seed": 73021,
		"stage_reached": 3,
		"boss_reached": true,
		"duration_seconds": 845.0,
		"profile": {"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true)},
		"run_build": {
			"level": 6,
			"cards": {
				"dash_wake": 2,
				"perfect_punish": 1,
			},
		},
		"persistent_material_delta": {
			"sky_thread": 4,
			"slime_residue": 8,
			"boss_core": 1,
		},
	}


func _visible_label_text(root_node: Node) -> String:
	var parts: Array[String] = []
	_collect_visible_label_text(root_node, parts)
	return "\n".join(parts)


func _collect_visible_label_text(node: Node, parts: Array[String]) -> void:
	if node is Label and (node as Label).is_visible_in_tree():
		parts.append((node as Label).text)
	for child in node.get_children():
		_collect_visible_label_text(child, parts)


func _assert_inside(control: Control, viewport_size: Vector2i, label: String) -> void:
	var rect := control.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
	if not bounds.encloses(rect):
		_errors.append(
			"%s escapes %s: %s min=%s root=%s viewport=%s."
			% [
				label,
				viewport_size,
				rect,
				control.get_combined_minimum_size(),
				root.size,
				control.get_viewport_rect().size,
			]
		)


func _assert_target(control: Control, minimum: float, label: String) -> void:
	if control.size.x < minimum or control.size.y < minimum:
		_errors.append("%s target is too small: %s." % [label, control.size])


func _assert_contains(text: String, expected: String, message: String) -> void:
	if not text.contains(expected):
		_errors.append(message)


func _assert_not_contains(text: String, forbidden: String, message: String) -> void:
	if text.contains(forbidden):
		_errors.append(message)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
