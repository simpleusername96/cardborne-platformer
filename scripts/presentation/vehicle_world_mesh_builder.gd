class_name VehicleWorldMeshBuilder
extends Node2D

## Geometry-fed flat world presentation. Stage data remains authoritative for
## walkability, cover, navigation, sockets, and terrain behavior; this node
## batches flat map-role colors and retained authored textures inside that truth.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const SurfaceDetailCompiler = preload(
	"res://scripts/presentation/vehicle_surface_detail_compiler.gd"
)

const MAX_VISUAL_BATCHES := 12
const DECORATION_BUDGET := 192

var _stage_id: StringName = &""
var _field_id: StringName = &""
var _layout_fingerprint := -1
var _batch_count := 0
var _texture_batches: Dictionary = {}
var _flushed_transform_count := 0
var _surface_rect_count := 0
var _outer_wall_segment_count := 0
var _inner_wall_rect_count := 0
var _geometry_fingerprint := ""
var _surface_detail_contract: Dictionary = {}


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func configure(stage_id: StringName, layout: Object) -> void:
	var fingerprint := int(layout.fingerprint) if layout != null else 0
	if _stage_id == stage_id and _layout_fingerprint == fingerprint:
		return
	_stage_id = stage_id
	_field_id = (
		StringName(layout.geometry_snapshot.field_id)
		if layout != null and layout.geometry_snapshot != null
		else StageCatalog.field_id(stage_id)
	)
	_layout_fingerprint = fingerprint
	_rebuild(layout)


func debug_contract() -> Dictionary:
	return {
		"stage_id": _stage_id,
		"layout_fingerprint": _layout_fingerprint,
		"batch_count": _batch_count,
		"batch_budget": MAX_VISUAL_BATCHES,
		"batch_budget_ok": _batch_count <= MAX_VISUAL_BATCHES,
		"flushed_transform_count": _flushed_transform_count,
		"decoration_count": int(_surface_detail_contract.get("placement_count", 0)),
		"decoration_budget": DECORATION_BUDGET,
		"decoration_budget_ok": int(_surface_detail_contract.get("placement_count", 0)) <= DECORATION_BUDGET,
		"decoration_collision_nodes": 0,
		"surface_detail": _surface_detail_contract.duplicate(true),
		"geometry_fed": true,
		"collision_owner": "vehicle_stage_geometry",
		"geometry_fingerprint": _geometry_fingerprint,
		"field_id": _field_id,
		"field_descriptor": WorldCatalog.FIELD_DESCRIPTORS.get(_field_id, {}),
		"solid_geometry": {
			"presentation_only": true,
			"surface_color": Art.MAP_SURFACE_FILL,
			"outer_wall_color": Art.MAP_OUTER_WALL_FILL,
			"inner_wall_color": Art.MAP_INNER_WALL_FILL,
			"surface_rect_count": _surface_rect_count,
			"outer_wall_segment_count": _outer_wall_segment_count,
			"inner_wall_rect_count": _inner_wall_rect_count,
		},
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_batch_count = 0
	_texture_batches.clear()
	_flushed_transform_count = 0
	_surface_rect_count = 0
	_outer_wall_segment_count = 0
	_inner_wall_rect_count = 0
	_surface_detail_contract = SurfaceDetailCompiler.compile(null)
	var snapshot: Object = layout.geometry_snapshot if layout != null else null
	var walkable_polygons: Array[PackedVector2Array] = []
	if snapshot != null:
		for rectangle in Array(snapshot.get("walkable_rects")):
			walkable_polygons.append(_rect_points(Rect2(rectangle)))
	else:
		for region in Rules.get_floor_regions(_stage_id):
			walkable_polygons.append(PackedVector2Array(region["polygon"]))
	_surface_rect_count = walkable_polygons.size()
	_add_batch(
		"SurfaceSolid",
		_layers_for_polygons(walkable_polygons, Art.MAP_SURFACE_FILL),
		0
	)
	var void_polygons: Array[PackedVector2Array] = []
	if snapshot != null:
		for rectangle in Array(snapshot.get("void_rects")):
			void_polygons.append(_rect_points(Rect2(rectangle)))
	else:
		for void_rect in Rules.get_void_rects(_stage_id):
			void_polygons.append(
				PackedVector2Array(StageGeometry.rect_polygon(void_rect))
			)
	_add_batch(
		"VoidSolid",
		_layers_for_polygons(void_polygons, Art.SPACE_BLACK),
		1
	)
	var cover_polygons: Array[PackedVector2Array] = []
	for polygon in Rules.get_cover_polygons(false, _stage_id):
		cover_polygons.append(PackedVector2Array(polygon))
	if layout != null:
		for rectangle in layout.cover_rects:
			cover_polygons.append(_rect_points(Rect2(rectangle)))
	for cover_index in cover_polygons.size():
		_add_texture_rect(
			"Cover_%d" % cover_index,
			&"world/terrain_solid_cover_block",
			_polygon_bounds(cover_polygons[cover_index]),
			3
		)
	if snapshot != null:
		var wall_segments := PackedVector2Array(snapshot.get("wall_segments"))
		_outer_wall_segment_count = wall_segments.size() / 2
		_add_batch(
			"OuterWallSolid",
			_segment_layers(
				wall_segments,
				Art.WALL_RAIL_WIDTH + 18.0,
				Art.MAP_OUTER_WALL_FILL
			),
			3
		)
		var inner_wall_polygons: Array[PackedVector2Array] = []
		for feature_variant in Array(snapshot.get("terrain_zones")):
			var feature := Dictionary(feature_variant)
			if StringName(feature.get("kind", &"")) != &"structural_wall":
				continue
			inner_wall_polygons.append(
				_rect_points(Rect2(feature.get("rect", Rect2())))
			)
		_inner_wall_rect_count = inner_wall_polygons.size()
		_add_batch(
			"InnerWallSolid",
			_layers_for_polygons(
				inner_wall_polygons,
				Art.MAP_INNER_WALL_FILL
			),
			3
		)
		_surface_detail_contract = SurfaceDetailCompiler.compile(snapshot)
		for placement_value in Array(_surface_detail_contract["placements"]):
			var placement := Dictionary(placement_value)
			var asset_id := StringName(placement["asset_id"])
			var canvas := _asset_content_size(asset_id)
			if canvas == Vector2.ZERO:
				continue
			var unit_radius := maxf(canvas.x, canvas.y) * 0.5
			_append_texture_instance(
				asset_id,
				2,
				Vector2(placement["position"]),
				float(placement["rotation"]),
				Vector2.ONE * unit_radius * float(placement["scale"])
			)
		_flush_texture_batches()
	_geometry_fingerprint = (
		_compile_geometry_fingerprint(snapshot, layout)
		if snapshot != null
		else ""
	)


func _add_batch(name: String, layers: Array[Dictionary], child_z: int) -> void:
	var mesh := _polygon_mesh(layers)
	if mesh == null:
		return
	var instance := MeshInstance2D.new()
	instance.name = name
	instance.mesh = mesh
	instance.z_index = child_z
	add_child(instance)
	_batch_count += 1


func _segment_layers(
	segments: PackedVector2Array,
	width: float,
	color: Color
) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	for index in segments.size() / 2:
		layers.append({
			"points": _line_quad(
				segments[index * 2],
				segments[index * 2 + 1],
				width
			),
			"color": color,
		})
	return layers


func _layers_for_polygons(
	polygons: Array[PackedVector2Array],
	color: Color
) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	for polygon in polygons:
		layers.append({"points": polygon, "color": color})
	return layers


func _polygon_mesh(layers: Array[Dictionary]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for layer in layers:
		var points := PackedVector2Array(
			layer.get("points", PackedVector2Array())
		)
		if points.size() < 3:
			continue
		var triangles := Geometry2D.triangulate_polygon(points)
		if triangles.is_empty():
			continue
		var offset := vertices.size()
		for point in points:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color(layer.get("color", Color.WHITE)))
		for index in triangles:
			indices.append(offset + index)
	if indices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _line_quad(from: Vector2, to: Vector2, width: float) -> PackedVector2Array:
	var vector := to - from
	if vector.is_zero_approx():
		return PackedVector2Array()
	var side := vector.normalized().rotated(PI * 0.5) * width * 0.5
	return PackedVector2Array([
		from - side,
		to - side,
		to + side,
		from + side,
	])


func _add_texture_rect(
	_name: String,
	asset_id: StringName,
	rect: Rect2,
	child_z: int,
	rotation: float = 0.0
) -> void:
	if not rect.has_area():
		return
	var canvas := _asset_content_size(asset_id)
	if canvas == Vector2.ZERO:
		return
	var local_size := (
		Vector2(rect.size.y, rect.size.x)
		if not is_zero_approx(rotation)
		else rect.size
	)
	_append_texture_instance(
		asset_id,
		child_z,
		rect.get_center(),
		rotation,
		_scale_for_canvas(local_size, canvas)
	)

func _asset_content_size(asset_id: StringName) -> Vector2:
	var texture := AssetProvider.texture(asset_id)
	var descriptor := AssetProvider.descriptor(asset_id)
	if texture == null or descriptor.is_empty():
		return Vector2.ZERO
	var content_rect := Rect2(descriptor.get("content_rect", Rect2()))
	return (
		content_rect.size
		if content_rect.has_area()
		else Vector2(descriptor.get("canvas", texture.get_size()))
	)


func _scale_for_canvas(target_size: Vector2, canvas: Vector2) -> Vector2:
	var unit_radius := maxf(canvas.x, canvas.y) * 0.5
	return Vector2(
		target_size.x * unit_radius / canvas.x,
		target_size.y * unit_radius / canvas.y
	)


func _append_texture_instance(
	asset_id: StringName,
	child_z: int,
	position: Vector2,
	rotation: float,
	scale: Vector2
) -> void:
	var batch_key := "%s:%d" % [String(asset_id), child_z]
	var record := Dictionary(_texture_batches.get(batch_key, {}))
	var multi_mesh: MultiMesh
	if record.is_empty():
		var mesh := AssetProvider.normalized_mesh(asset_id)
		var texture := AssetProvider.texture(asset_id)
		if mesh == null or texture == null:
			return
		multi_mesh = MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
		multi_mesh.mesh = mesh
		var instance := MultiMeshInstance2D.new()
		instance.name = "Raster_%s" % String(asset_id).replace("/", "_")
		instance.texture = texture
		instance.multimesh = multi_mesh
		instance.z_index = child_z
		add_child(instance)
		record = {"multi_mesh":multi_mesh, "transforms":[]}
		_texture_batches[batch_key] = record
		_batch_count += 1
	else:
		multi_mesh = record["multi_mesh"] as MultiMesh
	var transforms := Array(record["transforms"])
	transforms.append(Transform2D(rotation, position).scaled_local(scale))
	record["transforms"] = transforms
	_texture_batches[batch_key] = record


func _flush_texture_batches() -> void:
	for batch_key in _texture_batches:
		var record := Dictionary(_texture_batches[batch_key])
		var multi_mesh := record["multi_mesh"] as MultiMesh
		var transforms := Array(record["transforms"])
		multi_mesh.instance_count = transforms.size()
		for index in transforms.size():
			var instance_transform: Transform2D = transforms[index]
			multi_mesh.set_instance_transform_2d(index, instance_transform)
		multi_mesh.visible_instance_count = transforms.size()
		_flushed_transform_count += transforms.size()


func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(StageGeometry.rect_polygon(rect))


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)

func _compile_geometry_fingerprint(snapshot: Object, layout: Object) -> String:
	var records := PackedStringArray([
		String(_stage_id),
		str(_layout_fingerprint),
		str(snapshot.get("world_rect")),
		str(snapshot.get("walkable_rects")),
		str(snapshot.get("void_rects")),
		str(snapshot.get("wall_segments")),
		str(snapshot.get("terrain_zones")),
		str(layout.cover_rects if layout != null else []),
	])
	return "|".join(records).sha256_text()
