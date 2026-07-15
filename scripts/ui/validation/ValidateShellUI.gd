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
var _localization: Node
var _original_locale := "en"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null("Game")
	_profile_state = root.get_node_or_null("ProfileState")
	_localization = root.get_node_or_null("UILocalization")
	if _game == null or _profile_state == null or _localization == null:
		push_error("Shell UI validation requires Game, ProfileState, and UILocalization autoloads.")
		quit(1)
		return
	_original_locale = String(_localization.call("get_locale"))
	var supported := _localization.call("supported_locales") as PackedStringArray
	_assert_true(supported.has("en") and supported.has("ko"), "Shell UI must support English and Korean.")
	_profile_state.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	for locale in ["en", "ko"]:
		_localization.call("set_locale", locale)
		await process_frame
		_assert_true(
			String(_localization.call("get_locale")) == locale,
			"Requested shell locale must become active."
		)
		for viewport_size in VIEWPORTS:
			root.size = viewport_size
			DisplayServer.window_set_size(viewport_size)
			await process_frame
			await _validate_main_menu(viewport_size)
			await _validate_run_result(viewport_size)
			await _validate_pause_menu(viewport_size)
			await _validate_settings(viewport_size)

	_localization.call("set_locale", _original_locale)
	await process_frame

	if _errors.is_empty():
		print("SHELL_UI_VALIDATION_OK locales=2 viewports=3 screens=4 states=victory>defeat>retry>abandon>remap")
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
	_assert_true(screen.get_node_or_null("%QuitButton") == null, "Main menu must not expose a browser exit action.")
	_assert_backdrop(
		screen.get_node("Backdrop") as Control,
		"res://art/ui/production/backgrounds/main_menu.png",
		"Main menu"
	)
	_assert_inside(new_run, viewport_size, "Main menu primary action")
	_assert_target(new_run, 44.0, "Main menu primary action")
	_assert_target(settings, 44.0, "Main menu settings action")
	_assert_true(root.gui_get_focus_owner() == new_run, "Main menu must focus Begin Expedition.")
	_assert_true(new_run.text == _t("Begin Expedition"), "Main menu primary action must use the active locale.")
	_assert_true(settings.text == _t("Settings"), "Main menu settings action must use the active locale.")
	_assert_contains(_visible_label_text(screen), _t("LOWER RUINS"), "Main menu region must use the active locale.")
	await _press_ui_action(&"ui_down")
	_assert_true(root.gui_get_focus_owner() == settings, "Down Arrow must move main-menu focus to Settings.")
	new_run.grab_focus()

	var calls := {"new": 0, "settings": 0}
	screen.connect(&"new_run_requested", func() -> void: calls["new"] += 1)
	screen.connect(&"settings_requested", func() -> void: calls["settings"] += 1)
	new_run.pressed.emit()
	settings.pressed.emit()
	_assert_true(calls == {"new": 1, "settings": 1}, "Main menu signals must emit once.")
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
	_assert_backdrop(
		screen.get_node("Backdrop") as Control,
		"res://art/ui/production/backgrounds/run_result.png",
		"Run result"
	)
	_assert_inside(summary_panel, viewport_size, "Run result summary")
	_assert_target(retry, 44.0, "Run result retry action")
	_assert_target(menu, 44.0, "Run result menu action")
	_assert_true(root.gui_get_focus_owner() == retry, "Run result must focus its retry action.")
	var victory_text := _visible_label_text(screen)
	_assert_contains(victory_text, _t("VICTORY"), "Victory result needs a localized clear outcome.")
	_assert_contains(victory_text, _t("Dash Wake"), "Result build must use localized card names.")
	_assert_contains(victory_text, _t("Traveler Sword"), "Result build must include localized equipment names.")
	_assert_contains(victory_text, _t("Boss Core"), "Victory result must show localized kept rewards.")
	_assert_not_contains(victory_text, "Seed", "Run seed must not be player-facing.")
	_assert_not_contains(victory_text, "73021", "Run seed value must not be player-facing.")
	_assert_not_contains(victory_text, "dash_wake", "Card IDs must not be player-facing.")

	var calls := {"retry": 0, "menu": 0, "end": 0}
	screen.connect(&"retry_requested", func() -> void: calls["retry"] += 1)
	screen.connect(&"menu_requested", func() -> void: calls["menu"] += 1)
	screen.connect(&"end_requested", func() -> void: calls["end"] += 1)
	retry.pressed.emit()
	menu.pressed.emit()
	_assert_true(calls == {"retry": 1, "menu": 1, "end": 0}, "Run result actions must emit once.")

	settlement["victory"] = false
	settlement["terminal_reason"] = "run_abandoned"
	settlement["boss_reached"] = false
	settlement["stage_reached"] = 2
	screen.call("configure", false, "Traveler", settlement)
	await process_frame
	var defeat_text := _visible_label_text(screen)
	_assert_contains(defeat_text, _t("DEFEAT"), "Defeat result needs a localized clear outcome.")
	_assert_contains(
		defeat_text,
		_t("{0} ended the expedition. Secured materials were kept.", ["Traveler"]),
		"Abandon result must explain retained rewards in the active locale."
	)
	_assert_not_contains(defeat_text, "run_abandoned", "Terminal reason IDs must not be player-facing.")

	var attempt := {
		"stage_index": 1,
		"boss_attempt": false,
		"run_state": {"run_level": 3, "card_stacks": {}},
	}
	screen.call("configure_retry_decision", "Traveler", attempt)
	await process_frame
	var retry_text := _visible_label_text(screen)
	_assert_contains(retry_text, _t("CHOOSE YOUR NEXT STEP"), "Death flow must present a next-step choice.")
	_assert_contains(retry_text, _t("RETRY RULE"), "Death flow must label the retry rule.")
	_assert_contains(
		retry_text,
		_t("Health, coins, potions, cards, and equipment condition return to stage-entry values. Secured materials stay kept."),
		"Death flow must explain exactly what retry restores."
	)
	_assert_true(retry.text == _t("Retry Stage"), "Stage death must offer a localized same-stage retry.")
	_assert_true(menu.text == _t("End Expedition"), "Stage death must offer a localized expedition exit.")
	_assert_inside(summary_panel, viewport_size, "Retry decision summary")
	menu.pressed.emit()
	_assert_true(calls["end"] == 1, "Death decision must emit End Expedition separately from Main Menu.")

	attempt["boss_attempt"] = true
	screen.call("configure_retry_decision", "Traveler", attempt)
	await process_frame
	_assert_true(retry.text == _t("Retry Boss"), "Boss death must clearly offer a boss retry.")
	await _unmount(screen)


func _validate_pause_menu(viewport_size: Vector2i) -> void:
	var screen := await _mount(PAUSE_MENU_SCENE)
	if screen == null:
		return
	_game.call("set_pause_menu_open", true)
	await process_frame
	var panel := screen.get_node("%PausePanel") as Control
	var resume := screen.get_node("%ResumeButton") as Button
	var settings := screen.get_node("%SettingsButton") as Button
	var end_expedition := screen.get_node("%MainMenuButton") as Button
	var keep_playing := screen.get_node("%KeepPlayingButton") as Button
	var confirm_end := screen.get_node("%ConfirmEndRunButton") as Button
	_assert_true(screen.visible, "Pause menu must become visible from Game state.")
	_assert_inside(panel, viewport_size, "Pause panel")
	_assert_true(panel.global_position.x >= viewport_size.x * 0.5, "Pause panel must preserve the left play view.")
	_assert_target(resume, 44.0, "Pause resume action")
	_assert_target(settings, 44.0, "Pause settings action")
	_assert_target(end_expedition, 44.0, "Pause end-expedition action")
	_assert_true(root.gui_get_focus_owner() == resume, "Pause menu must focus Resume.")
	_assert_true(resume.text == _t("Resume"), "Pause resume action must use the active locale.")
	_assert_true(end_expedition.text == _t("End Expedition"), "Pause exit action must use the active locale.")
	await _press_ui_action(&"ui_down")
	_assert_true(root.gui_get_focus_owner() == settings, "Down Arrow must move pause focus to Settings.")
	resume.grab_focus()

	screen.call("_show_confirmation")
	await process_frame
	_assert_true((screen.get_node("%AbandonConfirmation") as Control).visible, "Abandon confirmation must open.")
	_assert_true(root.gui_get_focus_owner() == keep_playing, "Abandon confirmation must focus its safe action.")
	_assert_target(keep_playing, 44.0, "Pause safe confirmation action")
	_assert_target(confirm_end, 44.0, "Pause destructive confirmation action")
	_assert_contains(
		_visible_label_text(screen),
		_t("Run cards, coins, and stage progress will be lost. Secured materials stay kept."),
		"Pause confirmation must explain loss and retention in the active locale."
	)
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
	var return_focus := Button.new()
	return_focus.text = "Focus sentinel"
	return_focus.custom_minimum_size = Vector2(48.0, 48.0)
	root.add_child(return_focus)
	return_focus.grab_focus()
	await process_frame
	_game.call("set_settings_open", true)
	await process_frame
	var panel := screen.get_node("%SettingsPanel") as Control
	var close_button := screen.get_node("%CloseButton") as Button
	var bindings := screen.get_node("%BindingsBox") as VBoxContainer
	var language_selector := screen.get_node("%LanguageSelector") as OptionButton
	var active_locale := String(_localization.call("get_locale"))
	var shell_backdrop := screen.get_node("%ShellBackdrop") as Control
	_assert_true(screen.visible, "Settings must become visible from Game state.")
	_assert_backdrop(
		shell_backdrop,
		"res://art/ui/production/backgrounds/settings.png",
		"Shell settings"
	)
	_assert_true(shell_backdrop.visible, "Shell settings must show its authored background.")
	_assert_inside(panel, viewport_size, "Settings panel")
	_assert_inside(screen.get_node("%LanguageSelector") as Control, viewport_size, "Settings language selector")
	_assert_target(close_button, 44.0, "Settings close action")
	_assert_target(language_selector, 44.0, "Settings language selector")
	_assert_true(root.gui_get_focus_owner() == close_button, "Settings must focus Close or Back.")
	_assert_true((screen.get_node("%SettingsTitle") as Label).text == _t("SETTINGS"), "Settings title must use the active locale.")
	_assert_true(language_selector.item_count == 2, "Settings must offer exactly English and Korean.")
	_assert_true(
		String(language_selector.get_item_metadata(language_selector.selected)) == active_locale,
		"Language selector must reflect the active locale."
	)
	if active_locale == "ko":
		_assert_true(
			(screen.get_node("%SettingsTitle") as Label).text != "SETTINGS",
			"Korean settings must not display the English title."
		)
	_assert_true(
		bindings.get_child_count() == (_game.call("get_input_binding_rows") as Array).size(),
		"Settings must render every visible input action."
	)
	for row in bindings.get_children():
		for child in row.get_children():
			if child is Button:
				_assert_target(child as Button, 44.0, "Binding row action")

	await _press_ui_action(&"ui_down")
	_assert_true(
		root.gui_get_focus_owner() != null
		and root.gui_get_focus_owner() != close_button
		and screen.is_ancestor_of(root.gui_get_focus_owner()),
		"Down Arrow must move Settings focus into an interactive control."
	)
	close_button.grab_focus()

	screen.call("_begin_capture", "jump", _t("Jump"))
	await process_frame
	_assert_true(
		(screen.get_node("%BindingStatus") as Label).text
		== _t("Press a key for {0}. Esc cancels.", [_t("Jump")]),
		"Remap capture must expose its localized active state."
	)
	_assert_true(String(screen.get("capture_action_name")) == "jump", "Remap capture must own the selected action.")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.physical_keycode = KEY_ESCAPE
	cancel.pressed = true
	screen.call("_input", cancel)
	await process_frame
	_assert_true(String(screen.get("capture_action_name")).is_empty(), "Escape must cancel remap capture.")
	_assert_true(
		(screen.get_node("%BindingStatus") as Label).text == _t("Remap canceled."),
		"Canceled remap must be visible in the active locale."
	)
	screen.call("_begin_capture", "pause", _t("Pause / back"))
	screen.call("_input", cancel)
	await process_frame
	_assert_true(
		String(screen.get("capture_action_name")).is_empty(),
		"Escape must also cancel capture for the pause action; Default restores Escape."
	)

	screen.call("_begin_capture", "jump", _t("Jump"))
	var conflict := InputEventKey.new()
	conflict.keycode = KEY_X
	conflict.physical_keycode = KEY_X
	conflict.pressed = true
	screen.call("_apply_captured_key", conflict)
	await process_frame
	_assert_true(String(screen.get("capture_action_name")) == "jump", "A binding conflict must keep capture active.")
	_assert_true(
		(screen.get_node("%BindingStatus") as Label).text
		== _t("That key is already used. Choose another."),
		"A binding conflict must explain the error in the active locale."
	)
	screen.call("_clear_capture", false)

	var other_index := 1 if active_locale == "en" else 0
	var other_locale := String(language_selector.get_item_metadata(other_index))
	language_selector.select(other_index)
	language_selector.item_selected.emit(other_index)
	await process_frame
	_assert_true(
		String(_localization.call("get_locale")) == other_locale,
		"Language selection must change the active locale immediately."
	)
	_assert_true(
		(screen.get_node("%SettingsTitle") as Label).text == _t("SETTINGS"),
		"An open Settings screen must refresh after a language change."
	)
	_localization.call("set_locale", active_locale)
	await process_frame
	_assert_true(
		String(language_selector.get_item_metadata(language_selector.selected)) == active_locale,
		"Language selector must resynchronize after an external locale change."
	)

	_game.call("set_settings_open", false)
	for _frame in 2:
		await process_frame
	_assert_true(root.gui_get_focus_owner() == return_focus, "Closing Settings must restore prior focus.")
	_game.call("set_pause_menu_open", true)
	_game.call("set_settings_open", true)
	await process_frame
	_assert_true(not shell_backdrop.visible, "In-run settings must preserve the live stage view.")
	_assert_true(close_button.text == _t("Back"), "In-run settings must return to Pause.")
	_game.call("close_overlays")
	for _frame in 2:
		await process_frame
	return_focus.queue_free()
	await process_frame
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


func _press_ui_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _t(source: String, values: Array = []) -> String:
	return String(_localization.call("text", StringName(source), values))


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


func _assert_backdrop(backdrop: Control, expected_path: String, label: String) -> void:
	_assert_true(backdrop != null, "%s backdrop must exist." % label)
	if backdrop == null:
		return
	var texture := backdrop.get("backdrop_texture") as Texture2D
	_assert_true(
		texture != null and texture.resource_path == expected_path,
		"%s must use %s." % [label, expected_path]
	)
	var image := backdrop.get_node_or_null("Image") as TextureRect
	_assert_true(image != null, "%s backdrop must create its image layer." % label)
	if image == null:
		return
	_assert_true(
		image.expand_mode == TextureRect.EXPAND_IGNORE_SIZE
		and image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED
		and image.texture == texture
		and image.visible,
		"%s backdrop must preserve aspect and cover the viewport." % label
	)


func _assert_contains(text: String, expected: String, message: String) -> void:
	if not text.contains(expected):
		_errors.append(message)


func _assert_not_contains(text: String, forbidden: String, message: String) -> void:
	if text.contains(forbidden):
		_errors.append(message)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
