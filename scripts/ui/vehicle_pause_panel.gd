class_name VehiclePausePanel
extends VBoxContainer

## Pause composition. It emits navigation intents and owns no run state.

signal resume_requested
signal restart_requested
signal garage_requested
signal settings_requested
signal guide_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var first_button: Button
var abort_button: Button
var _command_stack: VBoxContainer


func _ready() -> void:
	name = "PausePanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	_build()


func _build() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	var title := Factory.label("PAUSE_TITLE", 38, Art.IVORY_BRIGHT)
	title.theme_type_variation = &"TitleLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var guide := Factory.command_button("?", Factory.COMMAND_SECONDARY)
	guide.tooltip_text = tr("GUIDE_TITLE")
	guide.accessibility_name = tr("GUIDE_TITLE")
	guide.custom_minimum_size = Vector2(48.0, 48.0)
	guide.pressed.connect(func() -> void: guide_requested.emit())
	header.add_child(guide)
	var command_center := CenterContainer.new()
	command_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(command_center)
	_command_stack = VBoxContainer.new()
	_command_stack.name = "CommandStack"
	_command_stack.custom_minimum_size.x = 360.0
	_command_stack.add_theme_constant_override("separation", 12)
	command_center.add_child(_command_stack)
	first_button = Factory.command_button(
		"PAUSE_RESUME",
		Factory.COMMAND_PRIMARY
	)
	first_button.custom_minimum_size = Vector2(360.0, 48.0)
	first_button.add_theme_font_size_override("font_size", 22)
	first_button.pressed.connect(func() -> void: resume_requested.emit())
	_command_stack.add_child(first_button)
	var restart := Factory.command_button(
		"PAUSE_RESTART",
		Factory.COMMAND_SECONDARY
	)
	restart.custom_minimum_size = Vector2(360.0, 48.0)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	_command_stack.add_child(restart)
	var settings := Factory.command_button(
		"PAUSE_SETTINGS",
		Factory.COMMAND_SECONDARY
	)
	settings.custom_minimum_size = Vector2(360.0, 48.0)
	settings.pressed.connect(func() -> void: settings_requested.emit())
	_command_stack.add_child(settings)
	abort_button = Factory.command_button(
		"PAUSE_ABORT",
		Factory.COMMAND_DANGER
	)
	abort_button.custom_minimum_size = Vector2(360.0, 48.0)
	abort_button.pressed.connect(func() -> void: garage_requested.emit())
	_command_stack.add_child(abort_button)


func open() -> void:
	first_button.grab_focus()


func set_compact_mode(compact: bool) -> void:
	add_theme_constant_override("separation", 10 if compact else 16)
	if _command_stack != null:
		_command_stack.add_theme_constant_override(
			"separation",
			8 if compact else 12
		)


func debug_contract() -> Dictionary:
	return {
		"focusables":_focusable_count(),
		"abort_variation":abort_button.theme_type_variation,
		"command_min_height":first_button.custom_minimum_size.y,
		"command_stack_type":_command_stack.get_class(),
		"command_order":_command_stack.get_children().map(
			func(control: Control) -> String: return String(control.text)
		),
		"command_widths":_command_stack.get_children().map(
			func(control: Control) -> float: return control.custom_minimum_size.x
		),
	}


func _focusable_count() -> int:
	var count := 0
	for node in find_children("*", "Control", true, false):
		if (node as Control).focus_mode != Control.FOCUS_NONE:
			count += 1
	return count
