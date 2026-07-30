class_name VehicleModalSurface
extends PanelContainer

## Shared modal chrome drawn by the surface itself, outside the content-layout
## pass. This keeps the semantic rail aligned to the panel edge.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Art.LINE, false, float(Art.BORDER_WIDTH))
	draw_rect(
		Rect2(
			Vector2.ZERO,
			Vector2(float(Art.SELECTED_RAIL_WIDTH), size.y)
		),
		Art.SYSTEM
	)


func debug_contract() -> Dictionary:
	return {
		"border_width":Art.BORDER_WIDTH,
		"rail_width":Art.SELECTED_RAIL_WIDTH,
		"accent":Art.SYSTEM,
	}
