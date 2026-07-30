class_name VehicleFieldGeometrySnapshot
extends RefCounted

## Immutable geometry compiled once for a run-selected field layout.

const GRID_CELL_SIZE := 96.0
const GRID_WIDTH := 75
const GRID_HEIGHT := 45

var field_id: StringName = &""
var world_rect := Rect2()
var player_start := Vector2.ZERO
var walkable_rects: Array[Rect2] = []
var selected_cover_rects: Array[Rect2] = []
var void_rects: Array[Rect2] = []
var terrain_zones: Array[Dictionary] = []
var wall_segments := PackedVector2Array()
var navigation_occupancy := PackedByteArray()


func configure(definition: Dictionary, cover_rects: Array[Rect2]) -> void:
	field_id = StringName(definition["id"])
	world_rect = Rect2(definition["world_rect"])
	player_start = Vector2(definition["player_start"])
	walkable_rects.clear()
	for region in Array(definition["walkable_regions"]):
		walkable_rects.append(Rect2(region["rect"]))
	selected_cover_rects = cover_rects.duplicate()
	void_rects.clear()
	for value in Array(definition["void_rects"]):
		void_rects.append(Rect2(value))
	terrain_zones.clear()
	for value in Array(definition.get("features", [])):
		terrain_zones.append(Dictionary(value).duplicate(true))
	wall_segments = _compile_union_boundary(walkable_rects)
	navigation_occupancy = _compile_navigation_occupancy()


func _compile_union_boundary(rectangles: Array[Rect2]) -> PackedVector2Array:
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	for rectangle in rectangles:
		xs.append(rectangle.position.x)
		xs.append(rectangle.end.x)
		ys.append(rectangle.position.y)
		ys.append(rectangle.end.y)
	xs.sort()
	ys.sort()
	var unique_x := _unique_values(xs)
	var unique_y := _unique_values(ys)
	var occupied := PackedByteArray()
	var columns := unique_x.size() - 1
	var rows := unique_y.size() - 1
	occupied.resize(maxi(0, columns * rows))
	for y in rows:
		for x in columns:
			var midpoint := Vector2(
				(unique_x[x] + unique_x[x + 1]) * 0.5,
				(unique_y[y] + unique_y[y + 1]) * 0.5
			)
			if _point_in_rectangles(midpoint, rectangles):
				occupied[y * columns + x] = 1
	var result := PackedVector2Array()
	for y in rows:
		for x in columns:
			if occupied[y * columns + x] == 0:
				continue
			var left_open := x == 0 or occupied[y * columns + x - 1] == 0
			var right_open := x + 1 == columns or occupied[y * columns + x + 1] == 0
			var top_open := y == 0 or occupied[(y - 1) * columns + x] == 0
			var bottom_open := y + 1 == rows or occupied[(y + 1) * columns + x] == 0
			if left_open:
				result.append(Vector2(unique_x[x], unique_y[y]))
				result.append(Vector2(unique_x[x], unique_y[y + 1]))
			if right_open:
				result.append(Vector2(unique_x[x + 1], unique_y[y]))
				result.append(Vector2(unique_x[x + 1], unique_y[y + 1]))
			if top_open:
				result.append(Vector2(unique_x[x], unique_y[y]))
				result.append(Vector2(unique_x[x + 1], unique_y[y]))
			if bottom_open:
				result.append(Vector2(unique_x[x], unique_y[y + 1]))
				result.append(Vector2(unique_x[x + 1], unique_y[y + 1]))
	return result


func _compile_navigation_occupancy() -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(GRID_WIDTH * GRID_HEIGHT)
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var point := (Vector2(x, y) + Vector2(0.5, 0.5)) * GRID_CELL_SIZE
			if not _point_in_rectangles(point, walkable_rects):
				continue
			var blocked := false
			for cover in selected_cover_rects:
				if cover.has_point(point):
					blocked = true
					break
			if not blocked:
				result[y * GRID_WIDTH + x] = 1
	return result


func _unique_values(values: PackedFloat32Array) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for value in values:
		if result.is_empty() or not is_equal_approx(result[result.size() - 1], value):
			result.append(value)
	return result


func _point_in_rectangles(point: Vector2, rectangles: Array[Rect2]) -> bool:
	for rectangle in rectangles:
		if rectangle.has_point(point):
			return true
	return false
