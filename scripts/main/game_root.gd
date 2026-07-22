class_name GameRoot
extends Node

## Registers the vehicle controls before the run enters the tree.


func _enter_tree() -> void:
	_register_input_map()


func _register_input_map() -> void:
	_replace_action("move_left", [
		_key(KEY_LEFT),
		_key(KEY_A),
		_joy_axis(JOY_AXIS_LEFT_X, -1.0),
	])
	_replace_action("move_right", [
		_key(KEY_RIGHT),
		_key(KEY_D),
		_joy_axis(JOY_AXIS_LEFT_X, 1.0),
	])
	_replace_action("move_up", [
		_key(KEY_UP),
		_key(KEY_W),
		_joy_axis(JOY_AXIS_LEFT_Y, -1.0),
	])
	_replace_action("move_down", [
		_key(KEY_DOWN),
		_key(KEY_S),
		_joy_axis(JOY_AXIS_LEFT_Y, 1.0),
	])
	_replace_action("primary_fire", [
		_mouse_button(MOUSE_BUTTON_LEFT),
		_key(KEY_SHIFT),
		_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0),
		_joy_button(JOY_BUTTON_RIGHT_SHOULDER),
	])
	_replace_action("dash", [
		_key(KEY_SPACE),
		_joy_button(JOY_BUTTON_A),
	])
	_replace_action("active_skill", [
		_key(KEY_Z),
		_joy_button(JOY_BUTTON_Y),
	])
	_replace_action("pause", [
		_key(KEY_ESCAPE),
		_joy_button(JOY_BUTTON_START),
	])


func _replace_action(action_name: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	else:
		InputMap.action_erase_events(action_name)
	InputMap.action_set_deadzone(action_name, 0.2)
	for event in events:
		InputMap.action_add_event(action_name, event)


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


func _mouse_button(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
