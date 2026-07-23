class_name VehicleStageRules
extends RefCounted

## Collision, navigation, and authored-layout helpers for the shared vehicle field.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Geometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")

const PLAYER_RADIUS := 24.0

const CANVAS := Color("#12171A")
const SURFACE := Color("#1C2428")
const RAISED := Color("#263136")
const CYAN := Color("#62A9B5")
const MOSS := Color("#6F8F62")
const AMBER := Color("#D4A33F")
const CORAL := Color("#D9654F")
const OFF_WHITE := Color("#F0F1E8")
const MUTED := Color("#A8B4AE")
const VIOLET := Color("#AA89CF")
const WATER := Color("#153238")
const FLOOR_DARK := Color("#18272A")
const FLOOR_MID := Color("#203437")
const FLOOR_LIGHT := Color("#294247")


static func get_cover_rects(_unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Array[Rect2]:
	return Catalog.cover_rects(stage_id)


static func get_cover_polygons(_unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Array:
	return Catalog.cover_polygons(stage_id)


static func world_rect(stage_id: StringName = &"stage_1") -> Rect2:
	return Catalog.world_rect(stage_id)


static func player_start(stage_id: StringName = &"stage_1") -> Vector2:
	return Catalog.player_start(stage_id)


static func get_water_rects(stage_id: StringName = &"stage_1") -> Array[Rect2]:
	return Catalog.water_rects(stage_id)


static func get_floor_regions(stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	return Catalog.floor_regions(stage_id, {"light": FLOOR_LIGHT, "mid": FLOOR_MID, "dark": FLOOR_DARK})


static func is_position_walkable(position: Vector2, radius: float = 0.0, stage_id: StringName = &"stage_1") -> bool:
	if not Catalog.position_is_walkable(stage_id, position, radius):
		return false
	return not Catalog.circle_overlaps_cover(stage_id, position, radius)


static func get_enemy_blueprint(stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	return Catalog.enemy_blueprint(stage_id)


static func get_pickup_blueprint(stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	return Catalog.pickup_blueprint(stage_id)


static func get_crate_blueprint(stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	return Catalog.crate_blueprint(stage_id)


static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func segment_rect_hit(from: Vector2, to: Vector2, rect: Rect2, padding: float = 0.0) -> Dictionary:
	return Geometry.segment_rect_hit(from, to, rect, padding)


static func first_cover_hit(from: Vector2, to: Vector2, radius: float, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Dictionary:
	return first_cover_hit_with_extra(from, to, radius, false, stage_id, [])


static func first_cover_hit_with_extra(from: Vector2, to: Vector2, radius: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> Dictionary:
	var best := {"hit": false, "t": 2.0}
	var blockers: Array = Catalog.cover_rects_near_motion(stage_id, from, to, radius)
	if not extra_cover.is_empty():
		blockers = blockers.duplicate()
	for value in extra_cover:
		blockers.append(Rect2(value))
	var swept_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	for blocker_value in blockers:
		var blocker := Rect2(blocker_value)
		if not swept_bounds.intersects(blocker.grow(radius), true):
			continue
		var hit := Geometry.segment_rect_hit(from, to, blocker, radius)
		if bool(hit.get("hit", false)) and float(hit["t"]) < float(best["t"]):
			best = hit
			best["rect"] = blocker
			best["polygon"] = Geometry.rect_polygon(blocker)
	return best


static func has_line_of_sight(from: Vector2, to: Vector2, padding: float = 0.0, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> bool:
	return not bool(first_cover_hit(from, to, padding, false, stage_id).get("hit", false))


static func has_line_of_sight_with_extra(from: Vector2, to: Vector2, padding: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> bool:
	return not bool(first_cover_hit_with_extra(from, to, padding, false, stage_id, extra_cover).get("hit", false))


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry.point_segment_distance(point, a, b)


static func move_circle(position: Vector2, motion: Vector2, radius: float, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Vector2:
	return move_circle_with_extra(position, motion, radius, false, stage_id, [])


static func move_circle_with_extra(position: Vector2, motion: Vector2, radius: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> Vector2:
	if extra_cover.is_empty() and Catalog.is_fast_motion_clear(stage_id, position, position + motion, radius):
		return position + motion
	var blockers: Array[Rect2] = get_cover_rects(false, stage_id)
	if not extra_cover.is_empty():
		blockers = blockers.duplicate()
	for value in extra_cover:
		blockers.append(Rect2(value))
	var bounds := world_rect(stage_id)
	var result := position
	var attempt_x := Vector2(
		clampf(position.x + motion.x, bounds.position.x + radius, bounds.end.x - radius),
		position.y
	)
	if _position_clear(attempt_x, radius, stage_id, blockers):
		result.x = attempt_x.x
	var attempt_y := Vector2(
		result.x,
		clampf(position.y + motion.y, bounds.position.y + radius, bounds.end.y - radius)
	)
	if _position_clear(attempt_y, radius, stage_id, blockers):
		result.y = attempt_y.y
	return result


static func _position_clear(position: Vector2, radius: float, stage_id: StringName, blockers: Array[Rect2]) -> bool:
	if not Catalog.position_is_walkable(stage_id, position, radius):
		return false
	if blockers.size() == get_cover_rects(false, stage_id).size():
		return not Catalog.circle_overlaps_cover(stage_id, position, radius)
	for blocker in blockers:
		if circle_overlaps_rect(position, radius, blocker):
			return false
	return true


static func grid_reachable(start: Vector2, goal: Vector2, radius: float = PLAYER_RADIUS, cell_size: float = 70.0, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> bool:
	return grid_reachable_with_extra(start, goal, radius, cell_size, false, stage_id, [])


static func grid_reachable_with_extra(start: Vector2, goal: Vector2, radius: float, cell_size: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> bool:
	var bounds := world_rect(stage_id)
	var min_cell := Vector2i(
		floori((bounds.position.x + radius) / cell_size),
		floori((bounds.position.y + radius) / cell_size)
	)
	var max_cell := Vector2i(
		floori((bounds.end.x - radius) / cell_size),
		floori((bounds.end.y - radius) / cell_size)
	)
	var start_cell := Vector2i(floori(start.x / cell_size), floori(start.y / cell_size))
	var goal_cell := Vector2i(floori(goal.x / cell_size), floori(goal.y / cell_size))
	var queue: Array[Vector2i] = [start_cell]
	var visited := {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var polygons: Array = get_cover_polygons(false, stage_id)
	if not extra_cover.is_empty():
		polygons = polygons.duplicate()
	for value in extra_cover:
		polygons.append(Geometry.rect_polygon(Rect2(value)))
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal_cell:
			return true
		for direction in directions:
			var next := current + direction
			if next.x < min_cell.x or next.y < min_cell.y or next.x > max_cell.x or next.y > max_cell.y:
				continue
			if visited.has(next):
				continue
			var point := (Vector2(next) + Vector2(0.5, 0.5)) * cell_size
			var blocked := not Catalog.position_is_walkable(stage_id, point, radius)
			for polygon in polygons:
				if Geometry.circle_overlaps_polygon(point, radius, polygon):
					blocked = true
					break
			if blocked:
				continue
			visited[next] = true
			queue.append(next)
	return false
