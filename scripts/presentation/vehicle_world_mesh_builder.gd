class_name VehicleWorldMeshBuilder
extends Node2D

## Geometry-fed flat world presentation. Stage data remains authoritative for
## walkability, cover, navigation, sockets, and terrain behavior; this node
## batches shared authored textures inside that geometry-owned truth.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const SurfacePatternCompiler = preload(
	"res://scripts/presentation/vehicle_field_surface_pattern_compiler.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const MAX_VISUAL_BATCHES := 12
const DECORATION_BUDGET := 0

var _stage_id: StringName = &""
var _field_id: StringName = &""
var _layout_fingerprint := -1
var _batch_count := 0
var _texture_batches: Dictionary = {}
var _flushed_transform_count := 0
var _flushed_wall_transform_count := 0
var _geometry_fingerprint := ""
var _surface_pattern_contract: Dictionary = {}


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
		"flushed_wall_transform_count": _flushed_wall_transform_count,
		"wall_transforms": _debug_batch_transforms(
			&"world/wall_segment_9", 3
		),
		"decoration_count": 0,
		"decoration_budget": DECORATION_BUDGET,
		"decoration_budget_ok": true,
		"decoration_collision_nodes": 0,
		"geometry_fed": true,
		"collision_owner": "vehicle_stage_geometry",
		"geometry_fingerprint": _geometry_fingerprint,
		"field_id": _field_id,
		"field_descriptor": WorldCatalog.FIELD_DESCRIPTORS.get(_field_id, {}),
		"surface_pattern": {
			"presentation_only": bool(
				_surface_pattern_contract.get("presentation_only", false)
			),
			"fingerprint": String(
				_surface_pattern_contract.get("fingerprint", "")
			),
			"hash_inputs": _surface_pattern_contract.get(
				"hash_inputs",
				PackedStringArray()
			),
			"module_size": float(
				_surface_pattern_contract.get("module_size", 0.0)
			),
			"panel_alpha_range": Vector2(
				_surface_pattern_contract.get(
					"panel_alpha_range",
					Vector2.ZERO
				)
			),
			"module_count": int(
				_surface_pattern_contract.get("module_count", 0)
			),
			"module_type_counts": Dictionary(
				_surface_pattern_contract.get("module_type_counts", {})
			).duplicate(),
		},
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_batch_count = 0
	_texture_batches.clear()
	_flushed_transform_count = 0
	_flushed_wall_transform_count = 0
	_surface_pattern_contract.clear()
	var snapshot: Object = layout.geometry_snapshot if layout != null else null
	# The backdrop owns the single void fill. Fixed world identities below are
	# texture-backed; geometry still supplies their exact placement and clipping.
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
		for segment_index in wall_segments.size() / 2:
			_add_texture_segment(
				"Boundary_%d" % segment_index,
				&"world/wall_segment_9",
				wall_segments[segment_index * 2],
				wall_segments[segment_index * 2 + 1],
				Art.WALL_RAIL_WIDTH + 18.0,
				3
			)
		for feature_variant in Array(snapshot.get("terrain_zones")):
			var feature := Dictionary(feature_variant)
			if StringName(feature.get("kind", &"")) != &"structural_wall":
				continue
			var wall_rect := Rect2(feature.get("rect", Rect2()))
			_add_oriented_texture_rect(
				"StructuralWall_%s" % String(feature.get("id", &"")),
				&"world/wall_segment_9",
				wall_rect,
				3
			)
		var surface_pattern := SurfacePatternCompiler.compile(
			_field_id,
			_layout_fingerprint,
			_typed_rects(Array(snapshot.get("walkable_rects"))),
			_typed_rects(Array(snapshot.get("void_rects"))),
			(
				_typed_rects(Array(layout.cover_rects))
				if layout != null
				else []
			),
			Vector2(snapshot.get("player_start"))
		)
		for module_index in Array(surface_pattern.get("modules", [])).size():
			var module := Dictionary(Array(surface_pattern["modules"])[module_index])
			for fragment_variant in Array(module.get("fragments", [])):
				_add_texture_rect(
					"Surface_%d" % module_index,
					&"world/surface_panel_9",
					Rect2(fragment_variant),
					1
				)
		_surface_pattern_contract = {
			"presentation_only": surface_pattern.get(
				"presentation_only",
				false
			),
			"fingerprint": surface_pattern.get("fingerprint", ""),
			"hash_inputs": surface_pattern.get(
				"hash_inputs",
				PackedStringArray()
			),
			"module_size": surface_pattern.get("module_size", 0.0),
			"panel_alpha_range": surface_pattern.get(
				"panel_alpha_range",
				Vector2.ZERO
			),
			"module_count": surface_pattern.get("module_count", 0),
			"module_type_counts": Dictionary(
				surface_pattern.get("module_type_counts", {})
			).duplicate(),
		}
	_flush_texture_batches()
	_geometry_fingerprint = (
		_compile_geometry_fingerprint(snapshot, layout)
		if snapshot != null
		else ""
	)


func _add_texture_rect(
	_name: String,
	asset_id: StringName,
	rect: Rect2,
	child_z: int,
	rotation: float = 0.0
) -> void:
	if not rect.has_area():
		return
	var canvas := _asset_canvas(asset_id)
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


func _add_oriented_texture_rect(
	name: String,
	asset_id: StringName,
	rect: Rect2,
	child_z: int
) -> void:
	_add_texture_rect(
		name,
		asset_id,
		rect,
		child_z,
		PI * 0.5 if rect.size.y > rect.size.x else 0.0
	)


func _add_texture_segment(
	name: String,
	asset_id: StringName,
	from: Vector2,
	to: Vector2,
	width: float,
	child_z: int
) -> void:
	var vector := to - from
	if vector.is_zero_approx() or width <= 0.0:
		return
	var canvas := _asset_canvas(asset_id)
	if canvas == Vector2.ZERO:
		return
	_append_texture_instance(
		asset_id,
		child_z,
		from + vector * 0.5,
		vector.angle(),
		_scale_for_canvas(Vector2(vector.length(), width), canvas)
	)


func _asset_canvas(asset_id: StringName) -> Vector2:
	var texture := AssetProvider.texture(asset_id)
	var descriptor := AssetProvider.descriptor(asset_id)
	if texture == null or descriptor.is_empty():
		return Vector2.ZERO
	return Vector2(descriptor.get("canvas", texture.get_size()))


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
		if String(batch_key).begins_with("world/wall_segment_9:"):
			_flushed_wall_transform_count += transforms.size()


func _debug_batch_transforms(asset_id: StringName, child_z: int) -> Array:
	var batch_key := "%s:%d" % [String(asset_id), child_z]
	var record := Dictionary(_texture_batches.get(batch_key, {}))
	return Array(record.get("transforms", [])).duplicate()


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


func _typed_rects(values: Array) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for value in values:
		result.append(Rect2(value))
	return result


func _compile_geometry_fingerprint(snapshot: Object, layout: Object) -> String:
	var records := PackedStringArray([
		String(_stage_id),
		str(_layout_fingerprint),
		str(snapshot.get("world_rect")),
		str(snapshot.get("walkable_rects")),
		str(snapshot.get("void_rects")),
		str(snapshot.get("wall_segments")),
		str(layout.cover_rects if layout != null else []),
	])
	return "|".join(records).sha256_text()
