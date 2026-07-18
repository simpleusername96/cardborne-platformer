class_name PivotRoot
extends Node


func _enter_tree() -> void:
	_register_input_map()


func _register_input_map() -> void:
	_replace_action("move_left", [_key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_replace_action("move_right", [_key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_replace_action("move_up", [_key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_replace_action("move_down", [_key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_replace_action("melee", [_key(KEY_SHIFT), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
	_replace_action("ranged", [_key(KEY_Z), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_replace_action("dash", [_key(KEY_SPACE), _joy_button(JOY_BUTTON_A)])
	_replace_action("guard", [_key(KEY_X), _joy_button(JOY_BUTTON_LEFT_SHOULDER)])
	_replace_action("potion", [_key(KEY_C), _joy_button(JOY_BUTTON_Y)])
	_replace_action("interact", [_key(KEY_V), _joy_button(JOY_BUTTON_X)])
	_replace_action("pause", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_START)])
	_replace_action("reset_training", [_key(KEY_R)])


func _replace_action(action_name: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	else:
		InputMap.action_erase_events(action_name)
	for event in events:
		InputMap.action_add_event(action_name, event)


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
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
