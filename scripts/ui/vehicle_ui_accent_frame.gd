class_name VehicleUiAccentFrame
extends Control

## Presentation-only modal frame: one neutral border and one semantic rail.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var accent_color := Art.SYSTEM


static func attach_to(
	parent: Control,
	color: Color = Art.SYSTEM
) -> VehicleUiAccentFrame:
	var frame := VehicleUiAccentFrame.new()
	frame.accent_color = color
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return frame


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Art.LINE, false, float(Art.BORDER_WIDTH))
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(float(Art.SELECTED_RAIL_WIDTH), size.y)),
		accent_color
	)


func debug_contract() -> Dictionary:
	return {
		"border_width": Art.BORDER_WIDTH,
		"rail_width": Art.SELECTED_RAIL_WIDTH,
		"accent": accent_color,
	}
