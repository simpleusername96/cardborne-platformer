extends SceneTree

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var defaults := InputProfile.default_descriptors()
	InputProfile.apply_input_map(defaults)
	_expect(_has_mouse(&"primary_fire", MOUSE_BUTTON_LEFT), "fresh primary is not Mouse 1")
	_expect(not _has_key(&"primary_fire", KEY_SHIFT), "Shift still fires the primary weapon")
	_expect(not _has_key(&"primary_fire", KEY_Z), "Z still fires the primary weapon")
	_expect(_has_key(&"dash", KEY_SPACE), "fresh dash is not Space")
	_expect(_has_key(&"active_skill", KEY_SHIFT), "fresh EMP is not Left Shift")
	_expect(not _has_key(&"active_skill", KEY_Z), "Z still triggers EMP by default")
	_expect(_has_key(&"move_left", KEY_A) and _has_key(&"move_left", KEY_LEFT), "movement defaults changed")
	_expect(_has_key(&"pause", KEY_ESCAPE), "Escape pause default changed")
	_expect(_has_joy_button(&"dash", JOY_BUTTON_A), "gamepad dash default changed")
	_expect(_has_joy_button(&"active_skill", JOY_BUTTON_Y), "gamepad EMP default changed")
	_expect(InputProfile.conflict_action(defaults[&"dash"], defaults, &"active_skill") == &"dash", "duplicate remappable input was not detected")
	_expect(InputProfile.conflict_action("key:%d" % KEY_W, defaults, &"dash") == &"move_up", "reserved movement input was not detected")
	var custom := defaults.duplicate(true)
	custom[&"active_skill"] = "key:%d" % KEY_Q
	InputProfile.apply_input_map(custom)
	_expect(_has_key(&"active_skill", KEY_Q) and not _has_key(&"active_skill", KEY_SHIFT), "custom EMP binding was not applied")
	InputProfile.apply_input_map(defaults)
	if failures.is_empty():
		print("PASS: vehicle input defaults, gamepad preservation, conflict guards, and saved override application")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false


func _has_mouse(action: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == button:
			return true
	return false


func _has_joy_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
