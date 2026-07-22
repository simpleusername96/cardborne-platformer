class_name VehicleInputProfile
extends RefCounted

## Owns the allowlisted keyboard/mouse descriptors and the complete vehicle
## InputMap registration order. Saved overrides are applied before gamepad
## defaults so a damaged profile cannot remove controller access.

const REMAPPABLE_ACTIONS: Array[StringName] = [
	&"primary_fire",
	&"dash",
	&"active_skill",
]

const PROTECTED_DESCRIPTORS := {
	"key:%d" % KEY_LEFT: &"move_left",
	"key:%d" % KEY_A: &"move_left",
	"key:%d" % KEY_RIGHT: &"move_right",
	"key:%d" % KEY_D: &"move_right",
	"key:%d" % KEY_UP: &"move_up",
	"key:%d" % KEY_W: &"move_up",
	"key:%d" % KEY_DOWN: &"move_down",
	"key:%d" % KEY_S: &"move_down",
	"key:%d" % KEY_ESCAPE: &"pause",
}


static func default_descriptors() -> Dictionary:
	return {
		&"primary_fire": "mouse:%d" % MOUSE_BUTTON_LEFT,
		&"dash": "key:%d" % KEY_SPACE,
		&"active_skill": "key:%d" % KEY_SHIFT,
	}


static func is_remappable(action: StringName) -> bool:
	return REMAPPABLE_ACTIONS.has(action)


static func normalize_descriptor(value: Variant) -> String:
	if not value is String:
		return ""
	var descriptor := String(value).strip_edges()
	var parts := descriptor.split(":", false, 1)
	if parts.size() != 2 or not String(parts[1]).is_valid_int():
		return ""
	var code := int(parts[1])
	match String(parts[0]):
		"key":
			if code <= 0 or code == KEY_ESCAPE:
				return ""
			return "key:%d" % code
		"mouse":
			if code < MOUSE_BUTTON_LEFT or code > MOUSE_BUTTON_XBUTTON2:
				return ""
			return "mouse:%d" % code
	return ""


static func descriptor_from_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return ""
		var code := int(key_event.physical_keycode)
		if code == 0:
			code = int(key_event.keycode)
		return normalize_descriptor("key:%d" % code)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			return normalize_descriptor("mouse:%d" % int(mouse_event.button_index))
	return ""


static func event_from_descriptor(value: Variant) -> InputEvent:
	var descriptor := normalize_descriptor(value)
	if descriptor.is_empty():
		return null
	var parts := descriptor.split(":", false, 1)
	var code := int(parts[1])
	if parts[0] == "key":
		var key_event := InputEventKey.new()
		key_event.keycode = code
		key_event.physical_keycode = code
		return key_event
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = code
	return mouse_event


static func conflict_action(descriptor: String, bindings: Dictionary, except_action: StringName = &"") -> StringName:
	var normalized := normalize_descriptor(descriptor)
	if normalized.is_empty():
		return &"invalid"
	if PROTECTED_DESCRIPTORS.has(normalized):
		return PROTECTED_DESCRIPTORS[normalized]
	for action in REMAPPABLE_ACTIONS:
		if action == except_action:
			continue
		if normalize_descriptor(bindings.get(action, "")) == normalized:
			return action
	return &""


static func display_name(value: Variant) -> String:
	var descriptor := normalize_descriptor(value)
	if descriptor.is_empty():
		return TranslationServer.translate("INPUT_UNBOUND")
	var parts := descriptor.split(":", false, 1)
	var code := int(parts[1])
	if parts[0] == "mouse":
		match code:
			MOUSE_BUTTON_LEFT:
				return TranslationServer.translate("INPUT_MOUSE_LEFT")
			MOUSE_BUTTON_RIGHT:
				return TranslationServer.translate("INPUT_MOUSE_RIGHT")
			MOUSE_BUTTON_MIDDLE:
				return TranslationServer.translate("INPUT_MOUSE_MIDDLE")
		return TranslationServer.translate("INPUT_MOUSE_BUTTON") % code
	var key_name := OS.get_keycode_string(code)
	return key_name if not key_name.is_empty() else TranslationServer.translate("INPUT_UNBOUND")


static func action_display_name(action: StringName, bindings: Dictionary) -> String:
	return display_name(bindings.get(action, default_descriptors().get(action, "")))


static func apply_input_map(bindings: Dictionary) -> void:
	_replace_action(&"move_left", [
		_key(KEY_LEFT),
		_key(KEY_A),
		_joy_axis(JOY_AXIS_LEFT_X, -1.0),
	])
	_replace_action(&"move_right", [
		_key(KEY_RIGHT),
		_key(KEY_D),
		_joy_axis(JOY_AXIS_LEFT_X, 1.0),
	])
	_replace_action(&"move_up", [
		_key(KEY_UP),
		_key(KEY_W),
		_joy_axis(JOY_AXIS_LEFT_Y, -1.0),
	])
	_replace_action(&"move_down", [
		_key(KEY_DOWN),
		_key(KEY_S),
		_joy_axis(JOY_AXIS_LEFT_Y, 1.0),
	])
	_replace_action(&"primary_fire", [
		_resolved_event(&"primary_fire", bindings),
		_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0),
		_joy_button(JOY_BUTTON_RIGHT_SHOULDER),
	])
	_replace_action(&"dash", [
		_resolved_event(&"dash", bindings),
		_joy_button(JOY_BUTTON_A),
	])
	_replace_action(&"active_skill", [
		_resolved_event(&"active_skill", bindings),
		_joy_button(JOY_BUTTON_Y),
	])
	_replace_action(&"pause", [
		_key(KEY_ESCAPE),
		_joy_button(JOY_BUTTON_START),
	])


static func _resolved_event(action: StringName, bindings: Dictionary) -> InputEvent:
	var defaults := default_descriptors()
	var event := event_from_descriptor(bindings.get(action, defaults[action]))
	return event if event != null else event_from_descriptor(defaults[action])


static func _replace_action(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	else:
		InputMap.action_erase_events(action)
	InputMap.action_set_deadzone(action, 0.2)
	for event in events:
		if event != null:
			InputMap.action_add_event(action, event)


static func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


static func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
