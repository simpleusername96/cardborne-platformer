class_name VehicleMinimapMeshBuilder
extends RefCounted

## Compiles one bounded minimap snapshot into a single vertex-colored draw mesh.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const ENEMY_OUTER_RADIUS := 4.0
const ENEMY_INNER_RADIUS := 2.6
const BOSS_OUTER_RADIUS := 10.0
const BOSS_INNER_RADIUS := 7.6


static func build(snapshot: Dictionary, canvas_size: Vector2) -> ArrayMesh:
	var geometry := _build_geometry(snapshot, canvas_size)
	return _mesh(
		geometry["vertices"],
		geometry["colors"],
		geometry["indices"]
	)


static func build_triangle_channels(
	snapshot: Dictionary,
	canvas_size: Vector2
) -> Dictionary:
	var geometry := _build_geometry(snapshot, canvas_size)
	var vertices: Array[Vector3] = geometry["vertices"]
	var colors: Array[Color] = geometry["colors"]
	var indices: Array[int] = geometry["indices"]
	var channels: Dictionary = {}
	for index in indices:
		var vertex_index := int(index)
		var key := colors[vertex_index].to_rgba32()
		var channel: Array[Vector3]
		if channels.has(key):
			channel = channels[key]
		else:
			channel = []
			channels[key] = channel
		channel.append(vertices[vertex_index])
	var packed_channels := {}
	for key in channels:
		packed_channels[key] = PackedVector3Array(channels[key])
	return packed_channels


static func dynamic_colors() -> Array[Color]:
	return [
		Color(Art.SPACE_BLACK, 0.82),
		Art.SPACE_BLACK,
		Art.PLAYER_REWARD,
		Art.SUPPORT,
		Art.DANGER,
		Art.BOSS_COMMAND,
		Art.MUSTARD_DARK,
	]


static func marker_size_contract() -> Dictionary:
	return {
		"enemy_outer":ENEMY_OUTER_RADIUS,
		"enemy_inner":ENEMY_INNER_RADIUS,
		"boss_outer":BOSS_OUTER_RADIUS,
		"boss_inner":BOSS_INNER_RADIUS,
	}


static func _build_geometry(
	snapshot: Dictionary,
	canvas_size: Vector2
) -> Dictionary:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var indices: Array[int] = []
	var cols := maxi(1, int(snapshot.get("cols", 13)))
	var rows := maxi(1, int(snapshot.get("rows", 6)))
	var cell_size := Vector2(canvas_size.x / float(cols), canvas_size.y / float(rows))
	var world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
	world_size.x = maxf(1.0, world_size.x)
	world_size.y = maxf(1.0, world_size.y)
	_append_concealment(vertices, colors, indices, snapshot, cols, rows, cell_size)
	_append_markers(vertices, colors, indices, snapshot, world_size, canvas_size)
	_append_player(vertices, colors, indices, snapshot, world_size, canvas_size)
	return {
		"vertices":vertices,
		"colors":colors,
		"indices":indices,
	}


static func _append_concealment(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	snapshot: Dictionary,
	cols: int,
	rows: int,
	cell_size: Vector2
) -> void:
	var visited_lookup := {}
	for cell_variant in snapshot.get("visited", []):
		visited_lookup[Vector2i(cell_variant)] = true
	var concealment_color := Color(Art.SPACE_BLACK, 0.82)
	for row in rows:
		var concealed_run_start := -1
		for column in range(cols + 1):
			var concealed := column < cols and not visited_lookup.has(Vector2i(column, row))
			if concealed and concealed_run_start < 0:
				concealed_run_start = column
			elif not concealed and concealed_run_start >= 0:
				_append_rect(
					vertices,
					colors,
					indices,
					Rect2(
						Vector2(concealed_run_start, row) * cell_size,
						Vector2(
							float(column - concealed_run_start) * cell_size.x,
							cell_size.y
						) + Vector2.ONE
					),
					concealment_color
				)
				concealed_run_start = -1


static func _append_markers(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	snapshot: Dictionary,
	world_size: Vector2,
	canvas_size: Vector2
) -> void:
	for marker_variant in snapshot.get("markers", []):
		var marker: Dictionary = marker_variant
		if not bool(marker.get("discovered", false)):
			continue
		var point := _map_point(Vector2(marker.get("position", Vector2.ZERO)), world_size, canvas_size)
		var kind := StringName(marker.get("kind", &""))
		match kind:
			&"item":
				_append_diamond_marker(vertices, colors, indices, point)
			&"enemy":
				_append_round_marker(vertices, colors, indices, point)
			&"boss":
				_append_boss_marker(vertices, colors, indices, point)
			&"facility":
				_append_facility_marker(vertices, colors, indices, point)


static func _append_player(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	snapshot: Dictionary,
	world_size: Vector2,
	canvas_size: Vector2
) -> void:
	var point := _map_point(Vector2(snapshot.get("player", Vector2.ZERO)), world_size, canvas_size)
	var facing := Vector2(snapshot.get("player_facing", Vector2.UP)).normalized()
	if facing.is_zero_approx():
		facing = Vector2.UP
	var side := facing.rotated(PI * 0.5)
	var outer := PackedVector2Array([
		point + facing * 7.0,
		point - facing * 5.0 + side * 5.0,
		point - facing * 2.0,
		point - facing * 5.0 - side * 5.0,
	])
	var inner := PackedVector2Array()
	for outer_point in outer:
		inner.append(point + (outer_point - point) * 0.72)
	_append_polygon(vertices, colors, indices, outer, Art.SPACE_BLACK)
	_append_polygon(vertices, colors, indices, inner, Art.PLAYER_REWARD)


static func _append_diamond_marker(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2
) -> void:
	_append_regular_polygon(
		vertices, colors, indices, center, 6.0, 4, PI * 0.25, Art.SPACE_BLACK
	)
	_append_regular_polygon(
		vertices, colors, indices, center, 4.2, 4, PI * 0.25, Art.SUPPORT
	)


static func _append_round_marker(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2
) -> void:
	_append_circle(
		vertices, colors, indices, center, ENEMY_OUTER_RADIUS, Art.SPACE_BLACK, 10
	)
	_append_circle(
		vertices, colors, indices, center, ENEMY_INNER_RADIUS, Art.DANGER, 10
	)


static func _append_boss_marker(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2
) -> void:
	_append_regular_polygon(
		vertices, colors, indices, center, BOSS_OUTER_RADIUS, 6, 0.0, Art.SPACE_BLACK
	)
	_append_regular_polygon(
		vertices, colors, indices, center, BOSS_INNER_RADIUS, 6, 0.0, Art.BOSS_COMMAND
	)


static func _append_facility_marker(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2
) -> void:
	_append_regular_polygon(
		vertices, colors, indices, center, 8.0, 4, PI * 0.25, Art.SPACE_BLACK
	)
	_append_regular_polygon(
		vertices, colors, indices, center, 6.2, 4, PI * 0.25, Art.MUSTARD
	)
	_append_rect(
		vertices, colors, indices, Rect2(center - Vector2(2.0, 2.0), Vector2(4.0, 4.0)),
		Art.MUSTARD_DARK
	)


static func _append_regular_polygon(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2,
	radius: float,
	segments: int,
	angle_offset: float,
	color: Color
) -> void:
	var points := PackedVector2Array()
	for index in segments:
		points.append(
			center + Vector2.RIGHT.rotated(
				angle_offset + TAU * float(index) / float(segments)
			) * radius
		)
	_append_polygon(vertices, colors, indices, points, color)


static func _append_circle(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2,
	radius: float,
	color: Color,
	segments: int = 10
) -> void:
	var points := PackedVector2Array()
	for index in segments:
		points.append(
			center
			+ Vector2.RIGHT.rotated(TAU * float(index) / float(segments))
			* radius
		)
	_append_polygon(vertices, colors, indices, points, color)


static func _append_rect(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	rect: Rect2,
	color: Color
) -> void:
	_append_polygon(vertices, colors, indices, PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	]), color)


static func _append_polygon(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	points: PackedVector2Array,
	color: Color
) -> void:
	if points.size() < 3:
		return
	var triangles := Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return
	var offset := vertices.size()
	for point in points:
		vertices.append(Vector3(point.x, point.y, 0.0))
		colors.append(color)
	for index in triangles:
		indices.append(offset + index)


static func _mesh(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int]
) -> ArrayMesh:
	if vertices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _map_point(point: Vector2, world_size: Vector2, canvas_size: Vector2) -> Vector2:
	return Vector2(point.x / world_size.x * canvas_size.x, point.y / world_size.y * canvas_size.y)
