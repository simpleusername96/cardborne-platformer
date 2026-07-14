extends Node

const BINDING_SAVE_PATH := "user://input_bindings.cfg"
const META_SECTION := "meta"
const KEYBOARD_SECTION := "keyboard"
const SAVE_VERSION := 1
const INPUT_DEVICE_KEYBOARD_MOUSE: StringName = &"keyboard_mouse"
const INPUT_DEVICE_GAMEPAD: StringName = &"gamepad"
const GAMEPAD_AXIS_SWITCH_THRESHOLD := 0.5
const MOUSE_MOTION_SWITCH_THRESHOLD_SQUARED := 4.0

const ACTION_DEFINITIONS := [
	{"name": "move_left", "label": "move left", "default_keys": [KEY_A, KEY_LEFT]},
	{"name": "move_right", "label": "move right", "default_keys": [KEY_D, KEY_RIGHT]},
	{"name": "jump", "label": "jump", "default_keys": [KEY_SPACE]},
	{"name": "dash", "label": "dash", "default_keys": [KEY_K, KEY_SHIFT]},
	{"name": "attack", "label": "attack", "default_keys": [KEY_F]},
	{"name": "guard", "label": "guard", "default_keys": [KEY_G]},
	{"name": "use_consumable", "label": "consumable", "default_keys": [KEY_H]},
	{"name": "climb_up", "label": "climb up", "default_keys": [KEY_W, KEY_UP]},
	{"name": "climb_down", "label": "climb down", "default_keys": [KEY_S, KEY_DOWN]},
	{"name": "climb_cancel", "label": "dismount", "default_keys": [KEY_C]},
	{"name": "crouch", "label": "crouch/drop", "default_keys": [KEY_S, KEY_DOWN]},
	{"name": "drop_through", "label": "drop through", "default_keys": [], "hidden": true},
	{"name": "interact", "label": "interact", "default_keys": [KEY_E, KEY_ENTER]},
	{"name": "pause", "label": "settings", "default_keys": [KEY_ESCAPE]},
]

# Axes are [axis, signed strength]. Buttons and axes accept every connected pad.
const GAMEPAD_LAYOUT := {
	"move_left": {"axes": [[JOY_AXIS_LEFT_X, -1.0]], "buttons": [JOY_BUTTON_DPAD_LEFT]},
	"move_right": {"axes": [[JOY_AXIS_LEFT_X, 1.0]], "buttons": [JOY_BUTTON_DPAD_RIGHT]},
	"jump": {"buttons": [JOY_BUTTON_A]},
	"dash": {"buttons": [JOY_BUTTON_B]},
	"attack": {"buttons": [JOY_BUTTON_X]},
	"guard": {"buttons": [JOY_BUTTON_Y]},
	"use_consumable": {"axes": [[JOY_AXIS_TRIGGER_RIGHT, 1.0]]},
	"climb_up": {"axes": [[JOY_AXIS_LEFT_Y, -1.0]], "buttons": [JOY_BUTTON_DPAD_UP]},
	"climb_down": {"axes": [[JOY_AXIS_LEFT_Y, 1.0]], "buttons": [JOY_BUTTON_DPAD_DOWN]},
	"climb_cancel": {"buttons": [JOY_BUTTON_B]},
	"crouch": {"axes": [[JOY_AXIS_LEFT_Y, 1.0]], "buttons": [JOY_BUTTON_DPAD_DOWN]},
	"drop_through": {"axes": [[JOY_AXIS_LEFT_Y, 1.0]], "buttons": [JOY_BUTTON_DPAD_DOWN]},
	"interact": {"buttons": [JOY_BUTTON_RIGHT_STICK]},
	"pause": {"buttons": [JOY_BUTTON_START]},
}

var _definitions_by_name: Dictionary = {}
var _active_input_device: StringName = INPUT_DEVICE_KEYBOARD_MOUSE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_input_map()


func _input(event: InputEvent) -> void:
	var input_device := _input_device_for_event(event)
	if input_device != &"":
		_set_active_input_device(input_device)


func ensure_input_map() -> void:
	_index_definitions()
	_restore_defaults_without_saving()
	_load_saved_bindings()
	SignalBus.input_bindings_changed.emit()


func get_input_guide_text() -> String:
	var move_binding := (
		"LS/D-pad"
		if is_gamepad_active()
		else get_binding_text("move_left", "A/Left") + "/" + get_binding_text("move_right", "D/Right")
	)
	var climb_binding := (
		"LS/D-pad"
		if is_gamepad_active()
		else get_binding_text("climb_up", "W/Up") + "/" + get_binding_text("climb_down", "S/Down")
	)
	return "\n".join([
		"Controls",
		"Move %s | Crouch/drop %s" % [
			move_binding,
			get_binding_text("crouch", "S/Down"),
		],
		"Jump %s | Dash %s | Attack %s | Guard %s" % [
			get_binding_text("jump", "Space"),
			get_binding_text("dash", "K/Shift"),
			get_binding_text("attack", "F"),
			get_binding_text("guard", "G"),
		],
		"Consumable %s" % [
			get_binding_text("use_consumable", "H"),
		],
		"Climb %s | Dismount %s" % [
			climb_binding,
			get_binding_text("climb_cancel", "C"),
		],
		"Interact %s | Settings %s" % [
			get_binding_text("interact", "E/Enter"),
			get_binding_text("pause", "Esc"),
		],
	])


func get_input_binding_lines() -> Array[String]:
	var lines: Array[String] = []
	for definition in ACTION_DEFINITIONS:
		if bool(definition.get("hidden", false)):
			continue
		var action_name := str(definition["name"])
		lines.append("%s: %s" % [str(definition["label"]), get_binding_text(action_name, "unbound")])
	return lines


func get_input_binding_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for definition in ACTION_DEFINITIONS:
		if bool(definition.get("hidden", false)):
			continue
		var action_name := str(definition["name"])
		rows.append({
			"action": action_name,
			"label": str(definition["label"]),
			"binding": get_binding_text(action_name, "unbound"),
			"keyboard_binding": get_binding_text_for_device(
				action_name,
				INPUT_DEVICE_KEYBOARD_MOUSE,
				"unbound"
			),
			"gamepad_binding": get_binding_text_for_device(
				action_name,
				INPUT_DEVICE_GAMEPAD,
				"unbound"
			),
			"input_device": _active_input_device,
		})
	return rows


func get_action_label(action_name: String) -> String:
	_index_definitions()
	var definition: Dictionary = _definitions_by_name.get(action_name, {})
	return str(definition.get("label", action_name))


func get_binding_text(action_name: String, fallback: String = "unbound") -> String:
	return get_binding_text_for_device(action_name, _active_input_device, fallback)


func get_binding_text_for_device(
	action_name: String,
	input_device: StringName,
	fallback: String = "unbound"
) -> String:
	if not InputMap.has_action(action_name):
		return fallback

	var labels: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		if input_device == INPUT_DEVICE_KEYBOARD_MOUSE and event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := _keycode_from_event(key_event)
			if keycode != KEY_NONE:
				labels.append(OS.get_keycode_string(keycode))
		elif input_device == INPUT_DEVICE_KEYBOARD_MOUSE and event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			labels.append("Mouse%d" % mouse_event.button_index)
		elif input_device == INPUT_DEVICE_GAMEPAD:
			var gamepad_label := _gamepad_event_label(event)
			if not gamepad_label.is_empty():
				labels.append(gamepad_label)

	labels = _dedupe_strings(labels)
	if labels.is_empty():
		return fallback
	return "/".join(labels)


func get_active_input_device() -> StringName:
	return _active_input_device


func is_gamepad_active() -> bool:
	return _active_input_device == INPUT_DEVICE_GAMEPAD


func remap_action_to_event(action_name: String, event: InputEventKey) -> Dictionary:
	if not is_tracked_action(action_name):
		return {"ok": false, "message": "Unknown action: %s" % action_name}

	var keycode := _keycode_from_event(event)
	if keycode == KEY_NONE:
		return {"ok": false, "message": "Only keyboard keys are supported in this pass."}

	var conflict := get_conflict_for_key(action_name, keycode)
	if not conflict.is_empty():
		return {
			"ok": false,
			"message": "%s is already used by %s." % [OS.get_keycode_string(keycode), conflict],
		}

	_apply_keycodes(action_name, [keycode])
	_save_bindings()
	SignalBus.input_bindings_changed.emit()
	return {"ok": true, "message": "%s set to %s." % [get_action_label(action_name), OS.get_keycode_string(keycode)]}


func restore_action_default(action_name: String) -> Dictionary:
	if not is_tracked_action(action_name):
		return {"ok": false, "message": "Unknown action: %s" % action_name}

	var definition: Dictionary = _definitions_by_name[action_name]
	_apply_keycodes(action_name, _to_int_array(definition.get("default_keys", [])))
	_apply_gamepad_events(action_name)
	_save_bindings()
	SignalBus.input_bindings_changed.emit()
	return {"ok": true, "message": "%s keyboard binding restored." % get_action_label(action_name)}


func restore_all_defaults() -> void:
	_restore_defaults_without_saving()
	_save_bindings()
	SignalBus.input_bindings_changed.emit()


func is_tracked_action(action_name: String) -> bool:
	_index_definitions()
	return _definitions_by_name.has(action_name)


func get_conflict_for_key(action_name: String, keycode: int) -> String:
	for definition in ACTION_DEFINITIONS:
		var other_action := str(definition["name"])
		if _is_allowed_overlap(action_name, other_action):
			continue
		if _keycodes_for_action(other_action).has(keycode):
			return str(definition["label"])
	return ""


func _conflict_for_keycodes(action_name: String, keycodes: Array[int]) -> String:
	for keycode in keycodes:
		var conflict := get_conflict_for_key(action_name, keycode)
		if not conflict.is_empty():
			return conflict
	return ""


func _index_definitions() -> void:
	if not _definitions_by_name.is_empty():
		return
	for definition in ACTION_DEFINITIONS:
		_definitions_by_name[str(definition["name"])] = definition


func _restore_defaults_without_saving() -> void:
	_index_definitions()
	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		_apply_keycodes(action_name, _to_int_array(definition.get("default_keys", [])))
		_apply_gamepad_events(action_name)


func _load_saved_bindings() -> void:
	var config := ConfigFile.new()
	var error := config.load(BINDING_SAVE_PATH)
	if error != OK:
		return

	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		if not config.has_section_key(KEYBOARD_SECTION, action_name):
			continue
		var saved_value: Variant = config.get_value(KEYBOARD_SECTION, action_name)
		if not (saved_value is Array):
			continue
		var keycodes := _to_int_array(saved_value)
		if keycodes.is_empty() and not bool(definition.get("hidden", false)):
			continue
		var conflict := _conflict_for_keycodes(action_name, keycodes)
		if not conflict.is_empty():
			push_warning("Ignoring saved binding for %s because it conflicts with %s." % [action_name, conflict])
			continue
		_apply_keycodes(action_name, keycodes)


func _save_bindings() -> void:
	var config := ConfigFile.new()
	config.set_value(META_SECTION, "version", SAVE_VERSION)
	for definition in ACTION_DEFINITIONS:
		var action_name := str(definition["name"])
		config.set_value(KEYBOARD_SECTION, action_name, _keycodes_for_action(action_name))
	var error := config.save(BINDING_SAVE_PATH)
	if error != OK:
		push_warning("Unable to save input bindings: %s" % error_string(error))


func _apply_keycodes(action_name: String, keycodes: Array[int]) -> void:
	_ensure_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)
	for keycode in _dedupe_ints(keycodes):
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _apply_gamepad_events(action_name: String) -> void:
	_ensure_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action_name, event)

	var layout: Dictionary = GAMEPAD_LAYOUT.get(action_name, {})
	for axis_value in layout.get("axes", []):
		if not (axis_value is Array) or axis_value.size() != 2:
			continue
		var motion_event := InputEventJoypadMotion.new()
		motion_event.device = -1
		motion_event.axis = int(axis_value[0])
		motion_event.axis_value = float(axis_value[1])
		InputMap.action_add_event(action_name, motion_event)
	for button_index in layout.get("buttons", []):
		var button_event := InputEventJoypadButton.new()
		button_event.device = -1
		button_event.button_index = int(button_index)
		InputMap.action_add_event(action_name, button_event)


func _ensure_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)


func _keycodes_for_action(action_name: String) -> Array[int]:
	var keycodes: Array[int] = []
	if not InputMap.has_action(action_name):
		return keycodes

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var keycode := _keycode_from_event(event as InputEventKey)
			if keycode != KEY_NONE:
				keycodes.append(keycode)
	return _dedupe_ints(keycodes)


func _keycode_from_event(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


func _to_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if not (value is Array):
		return result
	for item in value:
		if item is int:
			result.append(int(item))
	return _dedupe_ints(result)


func _dedupe_ints(values: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _dedupe_strings(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _gamepad_event_label(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		match button_event.button_index:
			JOY_BUTTON_A:
				return "A"
			JOY_BUTTON_B:
				return "B"
			JOY_BUTTON_X:
				return "X"
			JOY_BUTTON_Y:
				return "Y"
			JOY_BUTTON_LEFT_SHOULDER:
				return "LB"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "RB"
			JOY_BUTTON_LEFT_STICK:
				return "L3"
			JOY_BUTTON_RIGHT_STICK:
				return "R3"
			JOY_BUTTON_START:
				return "Start"
			JOY_BUTTON_DPAD_UP:
				return "D-pad Up"
			JOY_BUTTON_DPAD_DOWN:
				return "D-pad Down"
			JOY_BUTTON_DPAD_LEFT:
				return "D-pad Left"
			JOY_BUTTON_DPAD_RIGHT:
				return "D-pad Right"
			_:
				return "Button %d" % button_event.button_index

	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		match motion_event.axis:
			JOY_AXIS_LEFT_X:
				return "LS Left" if motion_event.axis_value < 0.0 else "LS Right"
			JOY_AXIS_LEFT_Y:
				return "LS Up" if motion_event.axis_value < 0.0 else "LS Down"
			JOY_AXIS_TRIGGER_LEFT:
				return "LT"
			JOY_AXIS_TRIGGER_RIGHT:
				return "RT"
			_:
				var direction := "-" if motion_event.axis_value < 0.0 else "+"
				return "Axis %d%s" % [motion_event.axis, direction]

	return ""


func _input_device_for_event(event: InputEvent) -> StringName:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			return INPUT_DEVICE_KEYBOARD_MOUSE
	elif event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			return INPUT_DEVICE_KEYBOARD_MOUSE
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.relative.length_squared() >= MOUSE_MOTION_SWITCH_THRESHOLD_SQUARED:
			return INPUT_DEVICE_KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			return INPUT_DEVICE_GAMEPAD
	elif event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		var is_trigger := (
			joy_motion.axis == JOY_AXIS_TRIGGER_LEFT
			or joy_motion.axis == JOY_AXIS_TRIGGER_RIGHT
		)
		if (
			is_trigger and joy_motion.axis_value >= GAMEPAD_AXIS_SWITCH_THRESHOLD
			or not is_trigger and absf(joy_motion.axis_value) >= GAMEPAD_AXIS_SWITCH_THRESHOLD
		):
			return INPUT_DEVICE_GAMEPAD
	return &""


func _set_active_input_device(input_device: StringName) -> void:
	if input_device == _active_input_device:
		return
	_active_input_device = input_device
	SignalBus.input_bindings_changed.emit()


func _is_allowed_overlap(action_a: String, action_b: String) -> bool:
	if action_a == action_b:
		return true

	var crouch_climb_down := ["crouch", "climb_down"]
	if crouch_climb_down.has(action_a) and crouch_climb_down.has(action_b):
		return true
	return false
