class_name VehicleThreatRadar
extends Control

## Screen-space off-screen threat cues inspired by radial audio visualizers.
## Gameplay supplies sampled semantic contacts; this component only aggregates
## them into short project-styled arcs around the projected player.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const DIAMETER := 208.0
const OUTER_RADIUS := DIAMETER * 0.5
const ARC_RADIUS := 96.0
const SECTOR_COUNT := 12
const ARC_HALF_WIDTH := PI / 18.0

var snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_snapshot(value: Dictionary) -> void:
	# The stage creates a fresh snapshot and the UI never mutates contact data.
	snapshot = value.duplicate()
	queue_redraw()


func _draw() -> void:
	if not bool(snapshot.get("visible", false)):
		return
	var center: Vector2 = snapshot.get("center", size * 0.5)
	center.x = clampf(center.x, OUTER_RADIUS + 8.0, size.x - OUTER_RADIUS - 8.0)
	center.y = clampf(center.y, OUTER_RADIUS + 8.0, size.y - OUTER_RADIUS - 8.0)
	var sectors := _aggregate_contacts(snapshot.get("contacts", []), float(snapshot.get("max_distance", 1200.0)))
	for sector in sectors:
		_draw_threat_arc(center, sector, float(snapshot.get("max_distance", 1200.0)))


func _aggregate_contacts(contacts: Array, maximum_distance: float) -> Array[Dictionary]:
	var buckets: Array[Dictionary] = []
	for _index in SECTOR_COUNT:
		buckets.append({})
	for contact_variant in contacts:
		var contact: Dictionary = contact_variant
		var offset: Vector2 = contact.get("offset", Vector2.ZERO)
		var distance := offset.length()
		if distance <= 0.001 or distance > maximum_distance:
			continue
		var angle := offset.angle()
		var sector_index := posmod(floori((angle + PI) / TAU * float(SECTOR_COUNT)), SECTOR_COUNT)
		var existing: Dictionary = buckets[sector_index]
		if existing.is_empty():
			buckets[sector_index] = {
				"angle": angle,
				"distance": distance,
				"count": 1,
				"priority": bool(contact.get("priority", false)),
				"targeted": bool(contact.get("targeted", false)),
			}
			continue
		existing["count"] = int(existing["count"]) + 1
		existing["priority"] = bool(existing["priority"]) or bool(contact.get("priority", false))
		existing["targeted"] = bool(existing["targeted"]) or bool(contact.get("targeted", false))
		if distance < float(existing["distance"]):
			existing["angle"] = angle
			existing["distance"] = distance
		buckets[sector_index] = existing
	var result: Array[Dictionary] = []
	for bucket in buckets:
		if not bucket.is_empty():
			result.append(bucket)
	return result


func _draw_threat_arc(center: Vector2, sector: Dictionary, maximum_distance: float) -> void:
	var angle := float(sector["angle"])
	var proximity := 1.0 - clampf(float(sector["distance"]) / maxf(1.0, maximum_distance), 0.0, 1.0)
	var density := minf(1.0, float(int(sector["count"]) - 1) / 5.0)
	var width := 5.0 + density * 6.0 + proximity * 2.0
	var color := Art.MUSTARD if bool(sector["priority"]) else Art.CORAL
	if bool(sector["targeted"]):
		color = Art.IVORY_BRIGHT
	var alpha := 0.58 + proximity * 0.30
	draw_arc(center, ARC_RADIUS + 2.0, angle - ARC_HALF_WIDTH, angle + ARC_HALF_WIDTH, 12, Color(Art.COBALT_DEEP, 0.82), width + 4.0, true)
	draw_arc(center, ARC_RADIUS, angle - ARC_HALF_WIDTH, angle + ARC_HALF_WIDTH, 12, Color(color, alpha), width, true)
	var direction := Vector2.RIGHT.rotated(angle)
	var tangent := direction.rotated(PI * 0.5)
	var tip := center + direction * (ARC_RADIUS - 10.0)
	if bool(sector["priority"]) or bool(sector["targeted"]):
		draw_colored_polygon(PackedVector2Array([
			tip,
			tip - direction * 13.0 + tangent * 8.0,
			tip - direction * 13.0 - tangent * 8.0,
		]), Art.MUSTARD if not bool(sector["targeted"]) else Art.IVORY_BRIGHT)
	if bool(sector["targeted"]):
		draw_arc(center, ARC_RADIUS + 9.0, angle - ARC_HALF_WIDTH * 0.72, angle + ARC_HALF_WIDTH * 0.72, 10, Art.MUSTARD, 3.0, true)


func debug_contract() -> Dictionary:
	return {
		"diameter": DIAMETER,
		"sector_count": SECTOR_COUNT,
		"maximum_markers": SECTOR_COUNT,
		"offscreen_arcs": true,
		"full_rect": is_zero_approx(anchor_left) and is_zero_approx(anchor_top) and is_equal_approx(anchor_right, 1.0) and is_equal_approx(anchor_bottom, 1.0),
		"mouse_ignored": mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}
