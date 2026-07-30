class_name VehicleStageGeometry
extends RefCounted

## Canonical polygon helpers for authored vehicle-stage geometry.
## Stage definitions remain editor-friendly Rect2 values, but every runtime
## consumer receives the same derived polygons for drawing and collision.

const CIRCLE_UNION_SAMPLES := 16


static func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point in polygon:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)


static func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	if _is_axis_aligned_rectangle(polygon):
		return point.x >= polygon[0].x and point.x <= polygon[2].x \
			and point.y >= polygon[0].y and point.y <= polygon[2].y
	return polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon)


static func circle_inside_polygon(center: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
	if _is_axis_aligned_rectangle(polygon):
		return center.x - radius >= polygon[0].x and center.x + radius <= polygon[2].x \
			and center.y - radius >= polygon[0].y and center.y + radius <= polygon[2].y
	if not point_in_polygon(center, polygon):
		return false
	if radius <= 0.0:
		return true
	for index in polygon.size():
		var next_index := (index + 1) % polygon.size()
		if point_segment_distance(center, polygon[index], polygon[next_index]) < radius:
			return false
	return true


static func circle_inside_polygon_union(center: Vector2, radius: float, polygons: Array) -> bool:
	if not _point_in_any_polygon(center, polygons):
		return false
	if radius <= 0.0:
		return true
	# Sixteen perimeter samples keep the maximum edge error below half a world unit
	# at the 24 px player radius while avoiding a costly physics-frame hot path.
	for index in CIRCLE_UNION_SAMPLES:
		var sample := center + Vector2.RIGHT.rotated(TAU * float(index) / float(CIRCLE_UNION_SAMPLES)) * radius * 0.999
		if not _point_in_any_polygon(sample, polygons):
			return false
	return true


static func _point_in_any_polygon(point: Vector2, polygons: Array) -> bool:
	for polygon in polygons:
		if point_in_polygon(point, polygon):
			return true
	return false


static func circle_overlaps_polygon(center: Vector2, radius: float, polygon: PackedVector2Array) -> bool:
	if _is_axis_aligned_rectangle(polygon):
		var closest := Vector2(
			clampf(center.x, polygon[0].x, polygon[2].x),
			clampf(center.y, polygon[0].y, polygon[2].y)
		)
		return center.distance_squared_to(closest) < radius * radius
	if point_in_polygon(center, polygon):
		return true
	for index in polygon.size():
		var next_index := (index + 1) % polygon.size()
		if point_segment_distance(center, polygon[index], polygon[next_index]) < radius:
			return true
	return false


static func _is_axis_aligned_rectangle(polygon: PackedVector2Array) -> bool:
	return polygon.size() == 4 \
		and is_equal_approx(polygon[0].y, polygon[1].y) \
		and is_equal_approx(polygon[1].x, polygon[2].x) \
		and is_equal_approx(polygon[2].y, polygon[3].y) \
		and is_equal_approx(polygon[3].x, polygon[0].x)


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.00001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)


static func segment_polygon_hit(from: Vector2, to: Vector2, polygon: PackedVector2Array, padding: float = 0.0) -> Dictionary:
	# Authored blockers are currently orthogonal rectangles. Using their exact
	# polygon bounds keeps swept-circle collision fast while retaining one source.
	return segment_rect_hit(from, to, polygon_bounds(polygon), padding)


static func segment_rect_hit(from: Vector2, to: Vector2, rect: Rect2, padding: float = 0.0) -> Dictionary:
	var target := rect.grow(padding)
	if target.has_point(from):
		return {"hit":true, "t":0.0, "normal":_inside_normal(from, target), "point":from}
	var delta := to - from
	var t_min := 0.0
	var t_max := 1.0
	var entering_normal := Vector2.ZERO
	for axis in 2:
		var origin := from[axis]
		var direction := delta[axis]
		var lower := target.position[axis]
		var upper := target.end[axis]
		if absf(direction) < 0.00001:
			if origin < lower or origin > upper:
				return {"hit":false}
			continue
		var near_t := (lower - origin) / direction
		var far_t := (upper - origin) / direction
		var near_normal := Vector2.ZERO
		near_normal[axis] = -1.0
		if near_t > far_t:
			var temporary := near_t
			near_t = far_t
			far_t = temporary
			near_normal[axis] = 1.0
		if near_t > t_min:
			t_min = near_t
			entering_normal = near_normal
		t_max = minf(t_max, far_t)
		if t_min > t_max:
			return {"hit":false}
	if t_min < 0.0 or t_min > 1.0:
		return {"hit":false}
	return {"hit":true, "t":t_min, "normal":entering_normal, "point":from + delta * t_min}


static func _inside_normal(point: Vector2, rect: Rect2) -> Vector2:
	var distances := [
		{"distance":absf(point.x - rect.position.x), "normal":Vector2.LEFT},
		{"distance":absf(point.x - rect.end.x), "normal":Vector2.RIGHT},
		{"distance":absf(point.y - rect.position.y), "normal":Vector2.UP},
		{"distance":absf(point.y - rect.end.y), "normal":Vector2.DOWN},
	]
	distances.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	return Vector2(distances[0]["normal"])
