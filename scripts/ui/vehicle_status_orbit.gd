class_name VehicleStatusOrbit
extends Control

## Three shape-coded recurring upgrade timers placed inside the threat radar.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const BADGE_RADIUS := 12.0
const ORBIT_RADIUS := 62.0
const ANGLES := [-2.22, -1.57, -0.92]

var snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_snapshot(value: Dictionary) -> void:
	snapshot = value
	queue_redraw()


func _draw() -> void:
	var states: Array = snapshot.get("states", [])
	if states.is_empty():
		return
	var center: Vector2 = snapshot.get("center", size * 0.5)
	center.x = clampf(center.x, 112.0, size.x - 112.0)
	center.y = clampf(center.y, 112.0, size.y - 112.0)
	for index in mini(3, states.size()):
		var state: Dictionary = states[index]
		var badge_center := center + Vector2.RIGHT.rotated(float(ANGLES[index])) * ORBIT_RADIUS
		_draw_badge(badge_center, state)


func _draw_badge(center: Vector2, state: Dictionary) -> void:
	var upgrade_id := StringName(state.get("id", &""))
	var active := bool(state.get("active", false))
	var progress := clampf(float(state.get("progress", 0.0)), 0.0, 1.0)
	var color := Art.MINT if upgrade_id == &"aegis_cycle" else (Art.CORAL if upgrade_id == &"overclock_cycle" else Art.MUSTARD)
	draw_circle(center, BADGE_RADIUS + 3.0, Color(Art.COBALT_DEEP, 0.92))
	draw_circle(center, BADGE_RADIUS, Art.IVORY_BRIGHT)
	draw_arc(center, BADGE_RADIUS + 2.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, color, 3.5, true)
	if active:
		draw_arc(center, BADGE_RADIUS - 2.0, 0.0, TAU, 16, Color(color, 0.50), 2.0, true)
	match upgrade_id:
		&"aegis_cycle":
			draw_colored_polygon(_polygon(center, 7.0, 6, PI / 6.0), color)
		&"overclock_cycle":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -8.0), center + Vector2(7.0, 6.0), center,
				center + Vector2(-7.0, 6.0),
			]), color)
		&"thruster_cycle":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-7.0, -6.0), center + Vector2(1.0, 0.0), center + Vector2(-7.0, 6.0),
				center + Vector2(0.0, 6.0), center + Vector2(8.0, 0.0), center + Vector2(0.0, -6.0),
			]), color)


func _polygon(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in sides:
		result.append(center + Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return result


func debug_contract() -> Dictionary:
	return {"maximum_badges":3, "badge_diameter":24.0, "orbit_radius":ORBIT_RADIUS, "shape_coded":true}
