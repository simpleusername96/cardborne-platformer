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

const MAX_VISUAL_BATCHES := 12
const DECORATION_BUDGET := 24
const PLAYER_CLEARANCE := 620.0
const DECORATION_SPACING := 420.0

var _stage_id: StringName = &""
var _field_id: StringName = &""
var _layout_fingerprint := -1
var _batch_count := 0
var _decoration_count := 0
var _geometry_fingerprint := ""


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
		"pixel_textures": 0,
		"geometry_fingerprint": _geometry_fingerprint,
		"field_id": _field_id,
		"field_descriptor": WorldCatalog.FIELD_DESCRIPTORS.get(_field_id, {}),
	}


func _rebuild(layout: Object) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_batch_count = 0
	_decoration_count = 0
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
		_add_batch(
			"FieldRhythm",
			_field_rhythm_layers(snapshot),
			1
		)
		var decoration_layers := _decoration_layers(snapshot, layout)
		_add_batch("SparseServicePlates", decoration_layers, 1)
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


func _field_rhythm_layers(snapshot: Object) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	var accent := _field_accent()
	var rect := _primary_walkable_rect(snapshot).grow(-120.0)
	if not rect.has_area():
		return layers
	match _field_id:
		&"drowned_ruin_field":
			for fraction: float in [0.24, 0.76]:
				var x: float = rect.position.x + rect.size.x * fraction
				var y: float = rect.position.y + rect.size.y * fraction
				layers.append({
					"points": _line_quad(
						Vector2(rect.position.x, y),
						Vector2(rect.end.x, y),
						8.0
					),
					"color": Color(accent, 0.30),
				})
				layers.append({
					"points": _line_quad(
						Vector2(x, rect.position.y),
						Vector2(x, rect.end.y),
						6.0
					),
					"color": Color(accent, 0.22),
				})
			var court_center := Vector2(snapshot.get("player_start"))
			layers.append({
				"points": Art.stepped_rect(
					Rect2(
						court_center - Vector2(490.0, 340.0),
						Vector2(980.0, 680.0)
					),
					54.0
				),
				"color": Color(Art.RAISED, 0.24),
			})
		&"tidal_archive_field":
			for normalized_y: float in [0.16, 0.33, 0.50, 0.67, 0.84]:
				var y: float = rect.position.y + rect.size.y * normalized_y
				layers.append({
					"points": _line_quad(
						Vector2(rect.position.x, y),
						Vector2(rect.end.x, y),
						7.0
					),
					"color": Color(accent, 0.28),
				})
		&"storm_drydock_field":
			var center := rect.get_center()
			var horizontal_extent := rect.size.x * 0.42
			for offset: float in [-0.42, -0.28, -0.14, 0.0, 0.14, 0.28, 0.42]:
				var midpoint := center + Vector2(0.0, rect.size.y * offset)
				layers.append({
					"points": _line_quad(
						midpoint + Vector2(-horizontal_extent, -420.0),
						midpoint + Vector2(horizontal_extent, 420.0),
						8.0
					),
					"color": Color(accent, 0.30),
				})
	return layers


func _primary_walkable_rect(snapshot: Object) -> Rect2:
	var result := Rect2()
	var best_area := -1.0
	for value in Array(snapshot.get("walkable_rects")):
		var candidate := Rect2(value)
		var area := candidate.get_area()
		if area > best_area:
			result = candidate
			best_area = area
	return result


func _decoration_layers(snapshot: Object, layout: Object) -> Array[Dictionary]:
	var layers: Array[Dictionary] = []
	var candidates: Array[Vector2] = []
	var player_start := Vector2(snapshot.get("player_start"))
	var covers: Array[Rect2] = []
	if layout != null:
		covers.assign(layout.cover_rects)
	for rect_variant in Array(snapshot.get("walkable_rects")):
		var rect := Rect2(rect_variant)
		for normalized_y in [0.18, 0.38, 0.62, 0.82]:
			for normalized_x in [0.14, 0.32, 0.50, 0.68, 0.86]:
				candidates.append(
					rect.position
					+ rect.size * Vector2(normalized_x, normalized_y)
				)
	candidates.sort_custom(
		func(left: Vector2, right: Vector2) -> bool:
			var left_key := int(left.x * 0.17 + left.y * 0.31)
			var right_key := int(right.x * 0.17 + right.y * 0.31)
			if left_key != right_key:
				return left_key < right_key
			return left.y < right.y
	)
	var selected: Array[Vector2] = []
	for position in candidates:
		if position.distance_to(player_start) < PLAYER_CLEARANCE:
			continue
		if _point_in_rects(position, covers, 110.0):
			continue
		if _point_in_rects(
			position,
			_typed_rects(Array(snapshot.get("void_rects"))),
			110.0
		):
			continue
		var separated := true
		for accepted in selected:
			if accepted.distance_to(position) < DECORATION_SPACING:
				separated = false
				break
		if not separated:
			continue
		selected.append(position)
		if selected.size() >= DECORATION_BUDGET:
			break
	var accent := _field_accent()
	for index in selected.size():
		var position := selected[index]
		var horizontal := index % 2 == 0
		var plate_size := (
			Vector2(154.0, 72.0)
			if horizontal
			else Vector2(72.0, 154.0)
		)
		var rect := Rect2(position - plate_size * 0.5, plate_size)
		layers.append({
			"points": Art.stepped_rect(rect, 18.0),
			"color": Color(Art.RAISED, 0.72),
		})
		var line_from := (
			position - Vector2(46.0, 0.0)
			if horizontal
			else position - Vector2(0.0, 46.0)
		)
		var line_to := (
			position + Vector2(46.0, 0.0)
			if horizontal
			else position + Vector2(0.0, 46.0)
		)
		layers.append({
			"points": _line_quad(line_from, line_to, 4.0),
			"color": Color(accent, 0.44),
		})
	_decoration_count = selected.size()
	return layers


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


func _point_in_rects(
	position: Vector2,
	rectangles: Array[Rect2],
	margin: float
) -> bool:
	for rectangle in rectangles:
		if rectangle.grow(margin).has_point(position):
			return true
	return false


func _field_accent() -> Color:
	match _field_id:
		&"tidal_archive_field":
			return Art.SUPPORT
		&"storm_drydock_field":
			return Art.PLAYER_REWARD
	return Art.SYSTEM


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
