extends SceneTree

var _failures: Array[String] = []
var _bindings: Node
var _device_change_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_bindings = root.get_node_or_null("/root/InputBindings")
	if _bindings == null:
		_failures.append("InputBindings autoload is unavailable.")
		_finish()
		return

	_bindings.ensure_input_map()
	_validate_complete_layout()
	_validate_prompt_switching()
	await _validate_settings_copy()
	_finish()


func _validate_complete_layout() -> void:
	var expected_layout := _expected_layout()
	for action_name in expected_layout:
		if not InputMap.has_action(action_name):
			_failures.append("Missing gameplay action: %s." % action_name)
			continue
		var expected: Array[String] = []
		for signature in expected_layout[action_name]:
			expected.append(str(signature))
		expected.sort()
		var actual := _gamepad_event_signatures(action_name)
		if actual != expected:
			_failures.append(
				"%s gamepad layout expected %s but got %s." % [action_name, expected, actual]
			)

	var constant_map: Dictionary = _bindings.get_script().get_script_constant_map()
	var definitions: Variant = constant_map.get("ACTION_DEFINITIONS", [])
	if not (definitions is Array):
		_failures.append("Input action definitions are unavailable to validation.")
		return
	for definition_value in definitions:
		if not (definition_value is Dictionary):
			continue
		var action_name := str((definition_value as Dictionary).get("name", ""))
		if not expected_layout.has(action_name):
			_failures.append("Gameplay action lacks a validated fixed gamepad mapping: %s." % action_name)


func _validate_prompt_switching() -> void:
	var bus := root.get_node_or_null("/root/SignalBus")
	if bus == null:
		_failures.append("SignalBus autoload is unavailable.")
		return
	bus.input_bindings_changed.connect(_on_input_bindings_changed)

	_bindings.call("_input", _key_event(KEY_F, true))
	_device_change_count = 0
	_expect_device(&"keyboard_mouse", "keyboard input should select keyboard/mouse prompts")
	_expect_binding("jump", "Space", "keyboard jump prompt")
	_expect_row_binding("jump", "Space", "keyboard input-guide row")

	_bindings.call("_input", _button_event(JOY_BUTTON_A, true))
	_expect_device(&"gamepad", "pressed gamepad button should select gamepad prompts")
	_expect_binding("jump", "A", "gamepad jump prompt")
	_expect_row_binding("jump", "A", "gamepad input-guide row")
	_expect_contains(
		str(_bindings.get_input_guide_text()),
		"Move LS/D-pad",
		"gamepad guide should summarize analog stick and D-pad movement"
	)
	_expect_contains(
		str(_bindings.get_input_guide_text()),
		"Attack X | Guard Y",
		"gamepad guide should show production combat actions"
	)
	_expect_contains(
		str(_bindings.get_input_guide_text()),
		"Consumable RT",
		"gamepad guide should show the consumable action"
	)
	_expect(_device_change_count == 1, "first device switch should emit one binding-change signal")

	_bindings.call("_input", _button_event(JOY_BUTTON_A, true))
	_bindings.call("_input", _key_event(KEY_F, false))
	_expect(_device_change_count == 1, "same-device input and key release should not emit a switch")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(3.0, 0.0)
	_bindings.call("_input", mouse_motion)
	_expect_device(&"keyboard_mouse", "meaningful mouse motion should select keyboard/mouse prompts")
	_expect_binding("jump", "Space", "mouse-selected jump prompt")
	_expect(_device_change_count == 2, "mouse switch should emit one binding-change signal")

	_bindings.call("_input", _motion_event(JOY_AXIS_TRIGGER_LEFT, -1.0))
	_expect_device(&"keyboard_mouse", "released trigger baseline should not switch prompts")
	_expect(_device_change_count == 2, "released trigger baseline should not emit a switch")

	_bindings.call("_input", _motion_event(JOY_AXIS_LEFT_X, 0.2))
	_expect_device(&"keyboard_mouse", "stick drift below threshold should not switch prompts")
	_expect(_device_change_count == 2, "stick drift should not emit a binding-change signal")

	_bindings.call("_input", _motion_event(JOY_AXIS_LEFT_X, 0.8))
	_expect_device(&"gamepad", "deliberate stick motion should select gamepad prompts")
	_expect_binding("move_right", "LS Right/D-pad Right", "gamepad movement prompt")
	_expect(_device_change_count == 3, "deliberate stick motion should emit one switch")

	_bindings.call("_input", _mouse_button_event(MOUSE_BUTTON_LEFT, false))
	_expect_device(&"gamepad", "mouse release should not switch prompts")
	_bindings.call("_input", _mouse_button_event(MOUSE_BUTTON_LEFT, true))
	_expect_device(&"keyboard_mouse", "pressed mouse button should select keyboard/mouse prompts")
	_expect(_device_change_count == 4, "pressed mouse button should emit one switch")

	var game := root.get_node_or_null("/root/Game")
	if game == null:
		_failures.append("Game autoload is unavailable.")
	else:
		_expect(
			StringName(game.get_active_input_device()) == &"keyboard_mouse",
			"Game should expose the active prompt device"
		)
		_expect(not bool(game.is_gamepad_input_active()), "Game should expose gamepad-active state")

	bus.input_bindings_changed.disconnect(_on_input_bindings_changed)


func _validate_settings_copy() -> void:
	var popup_scene := load("res://scenes/ui/SettingsPopup.tscn") as PackedScene
	if popup_scene == null:
		_failures.append("SettingsPopup scene could not be loaded.")
		return
	var popup := popup_scene.instantiate() as Control
	root.add_child(popup)
	await process_frame
	var warning_label := popup.get("warning_label") as Label
	_expect(
		warning_label != null
		and warning_label.text.contains("Keyboard keys can be remapped")
		and warning_label.text.contains("Gamepad layout is fixed"),
		"Settings should distinguish keyboard remapping from fixed gamepad controls"
	)
	var row_controls: Dictionary = popup.get("binding_row_controls")
	var jump_controls: Dictionary = row_controls.get("jump", {})
	var jump_keyboard := jump_controls.get("keyboard") as Button
	var jump_gamepad := jump_controls.get("gamepad") as Label
	_expect(
		jump_keyboard != null
		and jump_keyboard.text.contains("Space")
		and jump_gamepad != null
		and jump_gamepad.text == "A",
		"Settings should show the keyboard key and fixed gamepad control together"
	)
	popup.queue_free()
	await process_frame


func _expected_layout() -> Dictionary:
	return {
		"move_left": [_axis_signature(JOY_AXIS_LEFT_X, -1.0), _button_signature(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_axis_signature(JOY_AXIS_LEFT_X, 1.0), _button_signature(JOY_BUTTON_DPAD_RIGHT)],
		"jump": [_button_signature(JOY_BUTTON_A)],
		"dash": [_button_signature(JOY_BUTTON_B)],
		"attack": [_button_signature(JOY_BUTTON_X)],
		"guard": [_button_signature(JOY_BUTTON_Y)],
		"use_consumable": [_axis_signature(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"climb_up": [_axis_signature(JOY_AXIS_LEFT_Y, -1.0), _button_signature(JOY_BUTTON_DPAD_UP)],
		"climb_down": [_axis_signature(JOY_AXIS_LEFT_Y, 1.0), _button_signature(JOY_BUTTON_DPAD_DOWN)],
		"climb_cancel": [_button_signature(JOY_BUTTON_B)],
		"crouch": [_axis_signature(JOY_AXIS_LEFT_Y, 1.0), _button_signature(JOY_BUTTON_DPAD_DOWN)],
		"drop_through": [_axis_signature(JOY_AXIS_LEFT_Y, 1.0), _button_signature(JOY_BUTTON_DPAD_DOWN)],
		"interact": [_button_signature(JOY_BUTTON_RIGHT_STICK)],
		"pause": [_button_signature(JOY_BUTTON_START)],
	}


func _gamepad_event_signatures(action_name: String) -> Array[String]:
	var signatures: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton:
			signatures.append(_button_signature((event as InputEventJoypadButton).button_index))
		elif event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			signatures.append(_axis_signature(motion.axis, motion.axis_value))
	signatures.sort()
	return signatures


func _button_signature(button_index: int) -> String:
	return "button:%d" % button_index


func _axis_signature(axis: int, axis_value: float) -> String:
	return "axis:%d:%.1f" % [axis, axis_value]


func _expect_binding(action_name: String, expected: String, context: String) -> void:
	var actual := str(_bindings.get_binding_text(action_name, "unbound"))
	if actual != expected:
		_failures.append("%s expected %s but got %s." % [context, expected, actual])


func _expect_row_binding(action_name: String, expected: String, context: String) -> void:
	for row_value in _bindings.get_input_binding_rows():
		var row: Dictionary = row_value
		if str(row.get("action", "")) != action_name:
			continue
		if str(row.get("binding", "")) != expected:
			_failures.append(
				"%s expected %s but got %s." % [context, expected, str(row.get("binding", ""))]
			)
		return
	_failures.append("%s could not find action %s." % [context, action_name])


func _expect_device(expected: StringName, context: String) -> void:
	var actual := StringName(_bindings.get_active_input_device())
	if actual != expected:
		_failures.append("%s, expected %s but got %s." % [context, expected, actual])


func _expect_contains(actual: String, expected_fragment: String, context: String) -> void:
	if not actual.contains(expected_fragment):
		_failures.append("%s; missing '%s' in '%s'." % [context, expected_fragment, actual])


func _expect(condition: bool, context: String) -> void:
	if not condition:
		_failures.append(context)


func _key_event(keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _button_event(button_index: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = pressed
	return event


func _motion_event(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	return event


func _mouse_button_event(button_index: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	return event


func _on_input_bindings_changed() -> void:
	_device_change_count += 1


func _finish() -> void:
	if _failures.is_empty():
		print("GAMEPAD_INPUT_VALIDATION_OK actions=%d device_switches=%d" % [
			_expected_layout().size(),
			_device_change_count,
		])
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
