class_name VehicleWorldMeshBuilder
extends Node2D

## Geometry-fed flat world presentation. Stage data remains authoritative for
## walkability, cover, navigation, sockets, and terrain behavior; this node
## compiles only immutable vertex-colored presentation batches.

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

const MAX_VISUAL_BATCHES := 12
const DECORATION_BUDGET := SurfacePatternCompiler.MAX_SERVICE_RAILS

var _stage_id: StringName = &""
var _field_id: StringName = &""
var _layout_fingerprint := -1
var _batch_count := 0
var _decoration_count := 0
var _geometry_fingerprint := ""
var _surface_pattern_contract: Dictionary = {}


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
		"decoration_count": _decoration_count,
		"decoration_budget": DECORATION_BUDGET,
		"decoration_budget_ok": _decoration_count <= DECORATION_BUDGET,
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
			"service_rail_count": int(
				_surface_pattern_contract.get("service_rail_count", 0)
			),
			"service_rail_budget": int(
				_surface_pattern_contract.get("service_rail_budget", 0)
			),
		},
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_batch_count = 0
	_decoration_count = 0
	_surface_pattern_contract.clear()
	var snapshot: Object = layout.geometry_snapshot if layout != null else null
	var walkable_polygons: Array[PackedVector2Array] = []
	for region in Rules.get_floor_regions(_stage_id):
		walkable_polygons.append(PackedVector2Array(region["polygon"]))
	_add_batch(
		"FloorMass",
		_layers_for_polygons(walkable_polygons, Art.SURFACE),
		0
	)
	var void_polygons: Array[PackedVector2Array] = []
	for void_rect in Rules.get_void_rects(_stage_id):
		void_polygons.append(
			PackedVector2Array(StageGeometry.rect_polygon(void_rect))
		)
	_add_batch(
		"VoidMass",
		_layers_for_polygons(void_polygons, Art.SPACE_BLACK),
		1
	)
	var cover_polygons: Array[PackedVector2Array] = []
	for polygon in Rules.get_cover_polygons(false, _stage_id):
		cover_polygons.append(PackedVector2Array(polygon))
	if layout != null:
		for rectangle in layout.cover_rects:
			cover_polygons.append(_rect_points(Rect2(rectangle)))
	_add_batch(
		"CoverShadow",
		_offset_layers(cover_polygons, Art.WALL_SHADOW_OFFSET, Art.WALL_SHADOW),
		2
	)
	_add_batch(
		"CoverMass",
		_layers_for_polygons(cover_polygons, Art.WALL_FILL),
		3
	)
	_add_batch(
		"CoverRails",
		_cover_rail_layers(cover_polygons),
		4
	)
	if snapshot != null:
		var wall_segments := PackedVector2Array(snapshot.get("wall_segments"))
		_add_batch(
			"BoundaryShadow",
			_segment_layers(
				wall_segments,
				Art.WALL_RAIL_WIDTH + 18.0,
				Art.WALL_SHADOW_OFFSET,
				Art.WALL_SHADOW
			),
			2
		)
		_add_batch(
			"BoundaryRail",
			_segment_layers(
				wall_segments,
				Art.WALL_RAIL_WIDTH,
				Vector2.ZERO,
				Art.RAISED
			),
			3
		)
		_add_batch(
			"BoundaryEdge",
			_segment_layers(
				wall_segments,
				6.0,
				Vector2.ZERO,
				Art.LINE
			),
			4
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
		var surface_layers: Array[Dictionary] = []
		surface_layers.assign(
			Array(surface_pattern.get("layers", []))
		)
		_decoration_count = int(
			surface_pattern.get("service_rail_count", 0)
		)
		_add_batch("SurfacePattern", surface_layers, 1)
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
			"service_rail_count": surface_pattern.get(
				"service_rail_count",
				0
			),
			"service_rail_budget": surface_pattern.get(
				"service_rail_budget",
				0
			),
		}
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


func _cover_rail_layers(polygons: Array[PackedVector2Array]) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	for polygon in polygons:
		if polygon.size() < 3:
			continue
		var bounds := _polygon_bounds(polygon).grow(-18.0)
		if not bounds.has_area():
			continue
		var horizontal := bounds.size.x >= bounds.size.y
		var from := (
			Vector2(bounds.position.x, bounds.get_center().y)
			if horizontal
			else Vector2(bounds.get_center().x, bounds.position.y)
		)
		var to := (
			Vector2(bounds.end.x, bounds.get_center().y)
			if horizontal
			else Vector2(bounds.get_center().x, bounds.end.y)
		)
		layers.append({
			"points": _line_quad(from, to, 5.0),
			"color": Art.LINE,
		})
	return layers


func _segment_layers(
	segments: PackedVector2Array,
	width: float,
	offset: Vector2,
	color: Color
) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	for index in segments.size() / 2:
		layers.append({
			"points": _line_quad(
				segments[index * 2] + offset,
				segments[index * 2 + 1] + offset,
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


func _offset_layers(
	polygons: Array[PackedVector2Array],
	offset: Vector2,
	color: Color
) -> Array[Dictionary]:
	var shifted: Array[PackedVector2Array] = []
	for polygon in polygons:
		var points := PackedVector2Array()
		for point in polygon:
			points.append(point + offset)
		shifted.append(points)
	return _layers_for_polygons(shifted, color)


func _polygon_mesh(layers: Array[Dictionary]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for layer in layers:
		var points := PackedVector2Array(layer.get("points", PackedVector2Array()))
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
