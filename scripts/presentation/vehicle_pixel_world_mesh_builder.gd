class_name VehiclePixelWorldMeshBuilder
extends Node2D

## Geometry-fed pixel world presentation. Authoritative floor, water, cover,
## and boundary segments stay owned by stage layout data; this node only
## rebuilds repeat-textured visual chunks when that immutable fingerprint
## changes.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")

const FLOOR_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-floor.png")
const WALL_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-wall.png")
const WATER_TEXTURE := preload("res://pixel-art-production/runtime/tiles/hangar-water.png")
# The approved 192 px material masters render at a quiet 384 world-pixel period,
# keeping their authored 1 px details on a crisp 2 world-pixel grid.
const REPEAT_TILE_UV_SCALE := 0.5

var _stage_id: StringName = &""
var _layout_fingerprint := -1
var _chunk_count := 0


func configure(stage_id: StringName, layout: Object) -> void:
	var fingerprint := int(layout.fingerprint) if layout != null else 0
	if _stage_id == stage_id and _layout_fingerprint == fingerprint:
		return
	_stage_id = stage_id
	_layout_fingerprint = fingerprint
	_rebuild(layout)


func debug_contract() -> Dictionary:
	return {
		"stage_id":_stage_id,
		"layout_fingerprint":_layout_fingerprint,
		"chunk_count":_chunk_count,
		"chunk_budget_ok":_chunk_count <= 60,
		"geometry_fed":true,
		"collision_owner":"vehicle_stage_geometry",
		"repeat_tile_uv_scale":REPEAT_TILE_UV_SCALE,
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_chunk_count = 0
	for region in Rules.get_floor_regions(_stage_id):
		_add_polygon(
			PackedVector2Array(region["polygon"]),
			FLOOR_TEXTURE,
			Color.WHITE
		)
	for water in Rules.get_water_rects(_stage_id):
		_add_polygon(
			PackedVector2Array(StageGeometry.rect_polygon(water)),
			WATER_TEXTURE,
			Color.WHITE
		)
	for polygon in Rules.get_cover_polygons(false, _stage_id):
		_add_polygon(PackedVector2Array(polygon), WALL_TEXTURE, Color.WHITE, 2)
	if layout != null:
		for rectangle in layout.cover_rects:
			_add_polygon(
				PackedVector2Array(StageGeometry.rect_polygon(rectangle)),
				WALL_TEXTURE,
				Color.WHITE,
				2
			)
		var segments: PackedVector2Array = layout.geometry_snapshot.wall_segments
		_add_boundary_batch(segments, Art.WALL_SHADOW_OFFSET, Art.WALL_SHADOW, 0)
		_add_boundary_batch(segments, Vector2.ZERO, Art.WALL_FILL, 1)


func _add_polygon(
	points: PackedVector2Array,
	texture: Texture2D,
	color: Color,
	child_z: int = 0
) -> void:
	if points.size() < 3:
		return
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.texture = texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	polygon.texture_scale = Vector2.ONE * REPEAT_TILE_UV_SCALE
	polygon.color = color
	polygon.z_index = child_z
	add_child(polygon)
	_chunk_count += 1


func _add_boundary_batch(
	segments: PackedVector2Array,
	offset: Vector2,
	color: Color,
	child_z: int
) -> void:
	var segment_count := segments.size() / 2
	if segment_count <= 0:
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.instance_count = segment_count
	multimesh.visible_instance_count = segment_count
	multimesh.mesh = Visuals.pixel_quad_mesh()
	multimesh.custom_aabb = AABB(
		Vector3(-8192.0, -8192.0, -1.0),
		Vector3(16384.0, 16384.0, 2.0)
	)
	for index in segment_count:
		var from := segments[index * 2] + offset
		var to := segments[index * 2 + 1] + offset
		var vector := to - from
		var length := vector.length()
		if length <= 0.001:
			continue
		var direction := vector / length
		var perpendicular := direction.rotated(PI * 0.5)
		multimesh.set_instance_transform_2d(
			index,
			Transform2D(
				direction * (length * 0.5),
				perpendicular * (Art.WALL_RAIL_WIDTH * 0.5),
				from + vector * 0.5
			)
		)
		multimesh.set_instance_color(index, color)
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = multimesh
	instance.z_index = child_z
	add_child(instance)
	_chunk_count += 1
