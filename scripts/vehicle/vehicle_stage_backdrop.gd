class_name VehicleStageBackdrop
extends Node2D

## Cached stage geometry. Combat state stays in VehicleRun so this canvas
## only redraws when the authored stage theme changes.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")

var stage_id: StringName = &"stage_1"
var _layout: VehicleFieldLayout
var _layout_fingerprint := 0


func _ready() -> void:
	z_index = -20
	show_behind_parent = true


func configure(value: StringName, layout: VehicleFieldLayout = null) -> void:
	var next_fingerprint := layout.fingerprint if layout != null else 0
	if stage_id == value and _layout_fingerprint == next_fingerprint and is_node_ready():
		return
	stage_id = value
	_layout = layout
	_layout_fingerprint = next_fingerprint
	queue_redraw()


func _draw() -> void:
	_draw_world()
	_draw_water_and_floor()
	_draw_boundary_walls()
	_draw_cover()


func _draw_world() -> void:
	draw_rect(Rules.world_rect(stage_id), Art.COBALT_VOID)
	for region in Rules.get_floor_regions(stage_id):
		draw_colored_polygon(PackedVector2Array(region["polygon"]), Art.IVORY)


func _draw_water_and_floor() -> void:
	for water in Rules.get_water_rects(stage_id):
		draw_rect(water, Art.COBALT_WATER)
		var wave_y := water.get_center().y
		draw_line(Vector2(water.position.x + 28.0, wave_y), Vector2(water.end.x - 28.0, wave_y), Color(Art.IVORY_BRIGHT, 0.22), 8.0, true)


func _draw_cover() -> void:
	for polygon in Rules.get_cover_polygons(false, stage_id):
		_draw_wall_polygon(PackedVector2Array(polygon))
	if _layout != null:
		for rectangle in _layout.cover_rects:
			_draw_wall_polygon(PackedVector2Array(StageGeometry.rect_polygon(rectangle)))


func _draw_boundary_walls() -> void:
	if _layout == null or _layout.geometry_snapshot == null:
		return
	var segments: PackedVector2Array = _layout.geometry_snapshot.wall_segments
	for index in range(0, segments.size(), 2):
		draw_line(
			segments[index] + Art.WALL_SHADOW_OFFSET,
			segments[index + 1] + Art.WALL_SHADOW_OFFSET,
			Art.WALL_SHADOW,
			Art.WALL_RAIL_WIDTH,
			true
		)
	for index in range(0, segments.size(), 2):
		draw_line(
			segments[index],
			segments[index + 1],
			Art.WALL_FILL,
			Art.WALL_RAIL_WIDTH,
			true
		)


func _draw_wall_polygon(polygon: PackedVector2Array) -> void:
	var shadow := PackedVector2Array()
	for point in polygon:
		shadow.append(point + Art.WALL_SHADOW_OFFSET)
	draw_colored_polygon(shadow, Art.WALL_SHADOW)
	draw_colored_polygon(polygon, Art.WALL_FILL)


func debug_contract() -> Dictionary:
	return {
		"stage_id": stage_id,
		"static_cached": not is_processing() and not is_physics_processing(),
		"behind_gameplay": show_behind_parent and z_index < 0,
		"world_rect": Rules.world_rect(stage_id),
		"walkable_count": Rules.get_floor_regions(stage_id).size(),
		"cover_count": Rules.get_cover_rects(false, stage_id).size(),
		"layout_fingerprint":_layout_fingerprint,
		"runtime_cover_count":_layout.cover_rects.size() if _layout != null else 0,
	}
