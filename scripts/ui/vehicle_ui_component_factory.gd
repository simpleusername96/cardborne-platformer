class_name VehicleUiComponentFactory
extends RefCounted

## Shared construction primitives for runtime UI components. Screen hierarchy,
## state and signals remain inside each owning component.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ModalSurface = preload("res://scripts/ui/vehicle_modal_surface.gd")


static func modal_surface(minimum_size: Vector2) -> PanelContainer:
	var panel := ModalSurface.new()
	panel.theme_type_variation = &"ModalSurface"
	panel.custom_minimum_size = minimum_size
	return panel


static func flat_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"HudStatusGroup"
	return panel


static func label(
	text: String,
	font_size: int,
	color: Color = Art.IVORY_BRIGHT
) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", color)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


static func command_button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.theme_type_variation = variation
	button.text = text
	button.custom_minimum_size.y = 44.0
	button.focus_mode = Control.FOCUS_ALL
	return button


static func section_heading(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var left_rule := HSeparator.new()
	left_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_rule)
	var heading := label(key, 19, Art.MUSTARD)
	heading.theme_type_variation = &"SectionLabel"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(heading)
	var right_rule := HSeparator.new()
	right_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_rule)
	return row
