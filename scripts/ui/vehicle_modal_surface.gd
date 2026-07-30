class_name VehicleModalSurface
extends PanelContainer

## Shared modal chrome drawn by the surface itself, outside the content-layout
## pass. This keeps the semantic rail aligned to the panel edge.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const CORNER_CUT := 12.0
const INNER_INSET := 6.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= CORNER_CUT * 2.0 or size.y <= CORNER_CUT * 2.0:
		return
	var rect := Rect2(Vector2.ONE * 2.0, size - Vector2.ONE * 4.0)
	var perimeter := Art.stepped_rect(rect, CORNER_CUT)
	var closed_perimeter := perimeter.duplicate()
	closed_perimeter.append(perimeter[0])
	# A dark mechanical perimeter and restrained hard highlight reproduce the
	# approved panel depth without texture noise or decorative glow.
	draw_polyline(closed_perimeter, Art.SPACE_BLACK, 6.0, true)
	draw_polyline(closed_perimeter, Art.LINE, 2.0, true)
	draw_line(
		rect.position + Vector2(CORNER_CUT + INNER_INSET, INNER_INSET),
		Vector2(rect.end.x - CORNER_CUT - INNER_INSET, rect.position.y + INNER_INSET),
		Color(Art.TEXT_PRIMARY, 0.16),
		1.0,
		true
	)
	draw_line(
		rect.position + Vector2(INNER_INSET, CORNER_CUT + INNER_INSET),
		Vector2(rect.position.x + INNER_INSET, rect.end.y - CORNER_CUT - INNER_INSET),
		Color(Art.TEXT_PRIMARY, 0.12),
		1.0,
		true
	)
	draw_line(
		Vector2(rect.position.x + CORNER_CUT, rect.end.y - INNER_INSET),
		Vector2(rect.end.x - CORNER_CUT, rect.end.y - INNER_INSET),
		Color(Art.SPACE_BLACK, 0.84),
		2.0,
		true
	)
	draw_rect(
		Rect2(
			Vector2(8.0, CORNER_CUT + 4.0),
			Vector2(
				float(Art.SELECTED_RAIL_WIDTH),
				maxf(0.0, size.y - CORNER_CUT * 2.0 - 8.0)
			)
		),
		Art.SYSTEM
	)
	draw_line(
		Vector2(8.0, CORNER_CUT + 4.0),
		Vector2(22.0, CORNER_CUT + 4.0),
		Art.SYSTEM,
		2.0,
		true
	)
	draw_line(
		Vector2(8.0, size.y - CORNER_CUT - 4.0),
		Vector2(22.0, size.y - CORNER_CUT - 4.0),
		Art.SYSTEM,
		2.0,
		true
	)


func debug_contract() -> Dictionary:
	return {
		"border_width":Art.BORDER_WIDTH,
		"rail_width":Art.SELECTED_RAIL_WIDTH,
		"accent":Art.SYSTEM,
		"layered_depth":true,
		"corner_cut":CORNER_CUT,
	}
