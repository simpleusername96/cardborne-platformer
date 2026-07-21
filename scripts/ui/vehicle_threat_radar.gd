class_name VehicleThreatRadar
extends Control

## Screen-space combat radar. Gameplay supplies copied contact snapshots; this
## component only aggregates and renders them around the projected player.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const DIAMETER := 156.0
const OUTER_RADIUS := DIAMETER * 0.5
const INNER_RADIUS := 28.0
const SECTOR_COUNT := 24

var snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_snapshot(value: Dictionary) -> void:
	snapshot = value.duplicate(true)
	queue_redraw()


func _draw() -> void:
	if not bool(snapshot.get("visible", false)):
		return
	var center: Vector2 = snapshot.get("center", size * 0.5)
	center.x = clampf(center.x, OUTER_RADIUS + 4.0, size.x - OUTER_RADIUS - 4.0)
	center.y = clampf(center.y, OUTER_RADIUS + 4.0, size.y - OUTER_RADIUS - 4.0)
	draw_circle(center, OUTER_RADIUS, Color(Art.COBALT_VOID, 0.10))
	draw_arc(center, OUTER_RADIUS, 0.0, TAU, 64, Color(Art.MINT_SOFT, 0.78), 2.5)
	draw_arc(center, INNER_RADIUS, 0.0, TAU, 32, Color(Art.MINT_SOFT, 0.30), 1.5)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(
			center + direction * (OUTER_RADIUS - 7.0),
			center + direction * (OUTER_RADIUS + 3.0),
			Color(Art.MINT_SOFT, 0.74),
			2.0
		)

	var sectors: Array[Dictionary] = []
	for index in SECTOR_COUNT:
		sectors.append({})
	var maximum_distance := maxf(1.0, float(snapshot.get("max_distance", 1200.0)))
	for contact_variant in snapshot.get("contacts", []):
		var contact: Dictionary = contact_variant
		var offset: Vector2 = contact.get("offset", Vector2.ZERO)
		var distance := offset.length()
		if distance <= 0.001 or distance > maximum_distance:
			continue
		var angle := offset.angle()
		var sector_index := posmod(floori((angle + PI) / TAU * float(SECTOR_COUNT)), SECTOR_COUNT)
		var existing: Dictionary = sectors[sector_index]
		if existing.is_empty():
			sectors[sector_index] = {
				"angle": angle,
				"distance": distance,
				"count": 1,
				"priority": bool(contact.get("priority", false)),
				"targeted": bool(contact.get("targeted", false)),
			}
		else:
			existing["count"] = int(existing["count"]) + 1
			existing["priority"] = bool(existing["priority"]) or bool(contact.get("priority", false))
			existing["targeted"] = bool(existing["targeted"]) or bool(contact.get("targeted", false))
			if distance < float(existing["distance"]):
				existing["angle"] = angle
				existing["distance"] = distance
			sectors[sector_index] = existing

	for sector in sectors:
		if sector.is_empty():
			continue
		var distance_ratio := sqrt(clampf(float(sector["distance"]) / maximum_distance, 0.0, 1.0))
		var radial_distance := lerpf(INNER_RADIUS + 5.0, OUTER_RADIUS - 8.0, distance_ratio)
		var point := center + Vector2.RIGHT.rotated(float(sector["angle"])) * radial_distance
		var pip_radius := 4.5 + minf(4.0, float(int(sector["count"]) - 1) * 0.85)
		var color := Art.MUSTARD if bool(sector["priority"]) else Art.CORAL
		if bool(sector["targeted"]):
			color = Art.IVORY_BRIGHT
		draw_circle(point + Vector2(2.0, 2.0), pip_radius + 1.5, Color(Art.COBALT_DEEP, 0.82))
		draw_circle(point, pip_radius, Color(color, 0.94))
		if bool(sector["targeted"]):
			draw_arc(point, pip_radius + 3.0, 0.0, TAU, 20, Art.MUSTARD, 2.0)


func debug_contract() -> Dictionary:
	return {
		"diameter": DIAMETER,
		"sector_count": SECTOR_COUNT,
		"inner_radius": INNER_RADIUS,
		"full_rect": is_zero_approx(anchor_left) and is_zero_approx(anchor_top) and is_equal_approx(anchor_right, 1.0) and is_equal_approx(anchor_bottom, 1.0),
		"mouse_ignored": mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}
