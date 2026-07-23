class_name VehicleStageBackdrop
extends Node2D

## Cached stage geometry. Combat state stays in VehicleRun so this canvas
## only redraws when the authored stage theme changes.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")

var stage_id: StringName = &"stage_1"


func _ready() -> void:
	z_index = -20
	show_behind_parent = true


func configure(value: StringName) -> void:
	if stage_id == value and is_node_ready():
		return
	stage_id = value
	queue_redraw()


func _draw() -> void:
	_draw_world()
	_draw_water_and_floor()
	_draw_cover()


func _draw_world() -> void:
	draw_rect(Rules.world_rect(stage_id), Art.COBALT_VOID)
	for region in Rules.get_floor_regions(stage_id):
		draw_colored_polygon(PackedVector2Array(region["polygon"]), Art.IVORY)
	_draw_major_motifs()


func _draw_major_motifs() -> void:
	for motif in StageCatalog.motifs(stage_id):
		var kind := StringName(motif["kind"])
		var center := Vector2(motif["center"])
		var radius := float(motif["radius"])
		var rotation := float(motif["rotation"])
		var color := _motif_color(kind)
		if not Rules.is_position_walkable(center, radius, stage_id):
			continue
		match kind:
			&"tide_curl": _draw_tide_curl(center, radius, rotation, color)
			&"split_current": _draw_split_current(center, radius, rotation, color)
			&"relay_flower": _draw_relay_flower(center, radius, rotation, color)
			&"sun_gate": _draw_sun_gate(center, radius, rotation, color)


func _motif_color(kind: StringName) -> Color:
	match kind:
		&"tide_curl": return Art.MINT
		&"split_current": return Art.CORAL
		&"relay_flower": return Art.CERAMIC_GREEN_LIGHT
		&"sun_gate": return Art.MUSTARD
	return Art.MINT


func _draw_tide_curl(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var sweep := PackedVector2Array()
	for index in 18:
		var progress := float(index) / 17.0
		var angle := rotation + progress * PI * 1.55
		var distance := lerpf(radius, radius * 0.16, progress)
		sweep.append(center + Vector2.RIGHT.rotated(angle) * distance)
	for index in range(sweep.size() - 1):
		draw_line(sweep[index], sweep[index + 1], color, lerpf(58.0, 26.0, float(index) / 17.0), true)
	draw_circle(center + Vector2.RIGHT.rotated(rotation + PI * 1.55) * radius * 0.16, radius * 0.13, color)


func _draw_split_current(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array([
			Vector2(-radius * 0.82, side * radius * 0.16),
			Vector2(-radius * 0.18, side * radius * 0.46),
			Vector2(radius * 0.72, side * radius * 0.24),
			Vector2(radius * 0.28, side * radius * 0.02),
			Vector2(-radius * 0.12, side * radius * 0.12),
		])
		for index in points.size():
			points[index] = center + points[index].rotated(rotation)
		draw_colored_polygon(points, color)
	draw_circle(center, radius * 0.18, Color(Art.IVORY, 0.86))


func _draw_relay_flower(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	for index in 4:
		var angle := rotation + TAU * float(index) / 4.0
		var petal_center := center + Vector2.RIGHT.rotated(angle) * radius * 0.42
		draw_colored_polygon(_regular_polygon(petal_center, radius * 0.42, 8, angle), color)
	draw_circle(center, radius * 0.24, Color(Art.IVORY, 0.82))


func _draw_sun_gate(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	draw_circle(center, radius * 0.68, color)
	draw_circle(center, radius * 0.43, Color(Art.IVORY, 0.95))
	for index in 8:
		var angle := rotation + TAU * float(index) / 8.0
		var direction := Vector2.RIGHT.rotated(angle)
		var tangent := direction.rotated(PI * 0.5)
		var root := center + direction * radius * 0.72
		draw_colored_polygon(PackedVector2Array([
			root - tangent * radius * 0.11,
			center + direction * radius,
			root + tangent * radius * 0.11,
		]), color)


func _draw_water_and_floor() -> void:
	for water in Rules.get_water_rects(stage_id):
		draw_rect(water, Art.COBALT_WATER)
		var wave_y := water.get_center().y
		draw_line(Vector2(water.position.x + 28.0, wave_y), Vector2(water.end.x - 28.0, wave_y), Color(Art.IVORY_BRIGHT, 0.22), 8.0, true)


func _draw_cover() -> void:
	for polygon in Rules.get_cover_polygons(false, stage_id):
		draw_colored_polygon(PackedVector2Array(polygon), Art.BLOCKER_FILL)


func _regular_polygon(center: Vector2, radius: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(center + Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return points


func debug_contract() -> Dictionary:
	return {
		"stage_id": stage_id,
		"static_cached": not is_processing() and not is_physics_processing(),
		"behind_gameplay": show_behind_parent and z_index < 0,
		"world_rect": Rules.world_rect(stage_id),
		"walkable_count": Rules.get_floor_regions(stage_id).size(),
		"cover_count": Rules.get_cover_rects(false, stage_id).size(),
	}
