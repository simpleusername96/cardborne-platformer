class_name VehicleMinimapMeshBuilder
extends RefCounted

## Compiles one bounded minimap snapshot into a single vertex-colored draw mesh.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")


static func build(snapshot: Dictionary, canvas_size: Vector2) -> ArrayMesh:
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
	_append_clusters(vertices, colors, indices, snapshot, cell_size)
	_append_support_fields(vertices, colors, indices, snapshot, world_size, canvas_size)
	_append_player(vertices, colors, indices, snapshot, world_size, canvas_size)
	return _mesh(vertices, colors, indices)


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
	var concealment_color := Color(Art.COBALT_VOID, 0.82)
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
		var marker_color: Color = marker.get("color", Art.MUSTARD)
		var kind := String(marker.get("kind", "point"))
		match kind:
			"boss":
				_append_boss(vertices, colors, indices, point, marker_color, StringName(marker.get("variant", &"colossus")))
			"objective":
				_append_rect(vertices, colors, indices, Rect2(point - Vector2(4.5, 4.5), Vector2(9.0, 9.0)), marker_color)
			"reward":
				_append_polygon(vertices, colors, indices, _diamond(point, 6.5), marker_color)
			"elite":
				_append_polygon(vertices, colors, indices, _diamond(point, 7.0), marker_color)
				_append_rect(vertices, colors, indices, Rect2(point - Vector2.ONE, Vector2(2.0, 2.0)), Art.IVORY_BRIGHT)
			"stationary":
				_append_rect(vertices, colors, indices, Rect2(point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), marker_color)
			"crate":
				_append_rect(vertices, colors, indices, Rect2(point - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Art.INK_MUTED)
			"pickup":
				_append_circle(vertices, colors, indices, point, 6.5, marker_color)
			"mechanic":
				var direction := Vector2.RIGHT.rotated(float(int(marker.get("orientation", 0))) * PI * 0.5)
				_append_circle(vertices, colors, indices, point, 5.0, marker_color)
				_append_line(vertices, colors, indices, point - direction * 6.0, point + direction * 6.0, 2.5, Art.IVORY_BRIGHT)
			"blocker":
				_append_rect(vertices, colors, indices, Rect2(point - Vector2(5.0, 2.5), Vector2(10.0, 5.0)), marker_color)
			_:
				_append_circle(vertices, colors, indices, point, 4.0, marker_color)


static func _append_boss(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	point: Vector2,
	color: Color,
	variant: StringName
) -> void:
	if variant == &"titan":
		_append_rect(vertices, colors, indices, Rect2(point - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), color)
	elif variant == &"crown":
		_append_polygon(vertices, colors, indices, _diamond(point, 7.0), color)
		_append_circle(vertices, colors, indices, point, 2.0, Art.INK_MUTED)
	elif variant in [&"leviathan", &"behemoth"]:
		_append_polygon(vertices, colors, indices, PackedVector2Array([
			point + Vector2(7.0, 0.0),
			point + Vector2(-5.0, -5.0),
			point + Vector2(-2.0, 0.0),
			point + Vector2(-5.0, 5.0),
		]), color)
	else:
		_append_polygon(vertices, colors, indices, PackedVector2Array([
			point + Vector2(0.0, -5.0),
			point + Vector2(5.0, 4.0),
			point + Vector2(-5.0, 4.0),
		]), color)


static func _append_clusters(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	snapshot: Dictionary,
	cell_size: Vector2
) -> void:
	for cluster_variant in snapshot.get("enemy_clusters", []):
		var cluster: Dictionary = cluster_variant
		var point := (Vector2(Vector2i(cluster["cell"])) + Vector2(0.5, 0.5)) * cell_size
		var count := int(cluster["count"])
		var radius := 3.0 if count == 1 else (5.0 if count <= 4 else 7.0)
		_append_circle(vertices, colors, indices, point, radius, Art.CORAL)
		var average_velocity := Vector2(cluster.get("average_velocity", Vector2.ZERO))
		if average_velocity.length_squared() > 1.0:
			var tick := average_velocity.normalized() * clampf(average_velocity.length() / 42.0, 4.0, 7.0)
			_append_line(vertices, colors, indices, point, point + tick, 1.5, Art.IVORY_BRIGHT)


static func _append_support_fields(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	snapshot: Dictionary,
	world_size: Vector2,
	canvas_size: Vector2
) -> void:
	for support_variant in snapshot.get("support_fields", []):
		var support: Dictionary = support_variant
		var state := StringName(support["state"])
		if state in [&"initial_delay", &"depleted"]:
			continue
		var point := _map_point(Vector2(support["position"]), world_size, canvas_size)
		var kind := StringName(support["kind"])
		var color := Art.MINT if kind == &"repair" else Art.MUSTARD
		var progress := clampf(float(support["phase_progress"]), 0.0, 1.0)
		_append_arc(
			vertices, colors, indices, point, 7.0,
			-PI * 0.5, -PI * 0.5 + TAU * (1.0 - progress), 2.0, color
		)
		if kind == &"repair":
			_append_line(vertices, colors, indices, point - Vector2(3.0, 0.0), point + Vector2(3.0, 0.0), 2.0, Art.IVORY_BRIGHT)
			_append_line(vertices, colors, indices, point - Vector2(0.0, 3.0), point + Vector2(0.0, 3.0), 2.0, Art.IVORY_BRIGHT)
		else:
			_append_line(vertices, colors, indices, point + Vector2(-3.0, 2.0), point + Vector2(0.0, -2.0), 2.0, Art.IVORY_BRIGHT)
			_append_line(vertices, colors, indices, point + Vector2(0.0, -2.0), point + Vector2(3.0, 2.0), 2.0, Art.IVORY_BRIGHT)


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
	_append_line(vertices, colors, indices, point, point + facing * 11.0, 2.5, Art.MUSTARD)
	var side := facing.rotated(PI * 0.5)
	_append_polygon(vertices, colors, indices, PackedVector2Array([
		point + facing * 7.5,
		point - facing * 5.0 + side * 5.0,
		point - facing * 5.0 - side * 5.0,
	]), Art.MUSTARD)


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
		points.append(center + Vector2.RIGHT.rotated(TAU * float(index) / float(segments)) * radius)
	_append_polygon(vertices, colors, indices, points, color)


static func _append_arc(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	width: float,
	color: Color
) -> void:
	var sweep := end_angle - start_angle
	if absf(sweep) <= 0.001:
		return
	var segments := maxi(2, ceili(absf(sweep) / TAU * 18.0))
	var half_width := width * 0.5
	for index in segments:
		var angle_a := lerpf(start_angle, end_angle, float(index) / float(segments))
		var angle_b := lerpf(start_angle, end_angle, float(index + 1) / float(segments))
		var radial_a := Vector2.RIGHT.rotated(angle_a)
		var radial_b := Vector2.RIGHT.rotated(angle_b)
		_append_polygon(vertices, colors, indices, PackedVector2Array([
			center + radial_a * (radius - half_width),
			center + radial_b * (radius - half_width),
			center + radial_b * (radius + half_width),
			center + radial_a * (radius + half_width),
		]), color)


static func _append_line(
	vertices: Array[Vector3],
	colors: Array[Color],
	indices: Array[int],
	from: Vector2,
	to: Vector2,
	width: float,
	color: Color
) -> void:
	var direction := to - from
	if direction.is_zero_approx():
		return
	var side := direction.normalized().rotated(PI * 0.5) * width * 0.5
	_append_polygon(vertices, colors, indices, PackedVector2Array([
		from - side, to - side, to + side, from + side,
	]), color)


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


static func _diamond(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
