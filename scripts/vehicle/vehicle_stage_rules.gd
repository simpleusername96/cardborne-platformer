class_name VehicleStageRules
extends RefCounted

## Collision, navigation, and authored-layout helpers for the shared vehicle field.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Geometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Visual = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const PLAYER_RADIUS := 24.0

const CANVAS := Visual.WORLD_CANVAS
const SURFACE := Visual.SURFACE
const RAISED := Visual.RAISED
const CYAN := Visual.SYSTEM
const MOSS := Visual.SUPPORT
const AMBER := Visual.PLAYER_REWARD
const CORAL := Visual.DANGER
const OFF_WHITE := Visual.TEXT_PRIMARY
const MUTED := Visual.TEXT_MUTED
const VIOLET := Visual.ARC
const FLOOR_DARK := Visual.WORLD_CANVAS
const FLOOR_MID := Visual.SURFACE
const FLOOR_LIGHT := Visual.RAISED


static func get_cover_rects(_unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Array[Rect2]:
	return Catalog.cover_rects(stage_id)


static func get_cover_polygons(_unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Array:
	return Catalog.cover_polygons(stage_id)


static func world_rect(stage_id: StringName = &"stage_1") -> Rect2:
	return Catalog.world_rect(stage_id)


static func player_start(stage_id: StringName = &"stage_1") -> Vector2:
	return Catalog.player_start(stage_id)


static func get_void_rects(stage_id: StringName = &"stage_1") -> Array[Rect2]:
	return Catalog.void_rects(stage_id)


static func get_floor_regions(stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	return Catalog.floor_regions(stage_id, {"light": FLOOR_LIGHT, "mid": FLOOR_MID, "dark": FLOOR_DARK})


static func is_position_walkable(position: Vector2, radius: float = 0.0, stage_id: StringName = &"stage_1") -> bool:
	if not Catalog.position_is_walkable(stage_id, position, radius):
		return false
	return not Catalog.circle_overlaps_cover(stage_id, position, radius)


static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func segment_rect_hit(from: Vector2, to: Vector2, rect: Rect2, padding: float = 0.0) -> Dictionary:
	return Geometry.segment_rect_hit(from, to, rect, padding)


static func segment_rect_intersects(
	from: Vector2,
	to: Vector2,
	rect: Rect2,
	padding: float = 0.0
) -> bool:
	return Geometry.segment_rect_intersects(from, to, rect, padding)


static func first_cover_hit(from: Vector2, to: Vector2, radius: float, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Dictionary:
	return first_cover_hit_with_extra(from, to, radius, false, stage_id, [])


static func first_cover_hit_with_extra(from: Vector2, to: Vector2, radius: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> Dictionary:
	var best := {"hit": false, "t": 2.0}
	var swept_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	if not Catalog.cover_rects(stage_id).is_empty():
		_consider_cover_hits(
			from, to, radius, swept_bounds,
			Catalog.cover_rects_near_motion(stage_id, from, to, radius), best
		)
	_consider_cover_hits(from, to, radius, swept_bounds, extra_cover, best)
	return best


static func first_cover_hit_with_extra_into(
	from: Vector2,
	to: Vector2,
	radius: float,
	stage_id: StringName,
	extra_cover: Array,
	best: Dictionary,
	candidate: Dictionary
) -> Dictionary:
	best["hit"] = false
	best["t"] = 2.0
	var swept_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	if not Catalog.cover_rects(stage_id).is_empty():
		_consider_cover_hits_into(
			from,
			to,
			radius,
			swept_bounds,
			Catalog.cover_rects_near_motion(stage_id, from, to, radius),
			best,
			candidate
		)
	_consider_cover_hits_into(
		from, to, radius, swept_bounds, extra_cover, best, candidate
	)
	return best


static func _consider_cover_hits(
	from: Vector2,
	to: Vector2,
	radius: float,
	swept_bounds: Rect2,
	blockers: Array,
	best: Dictionary
) -> void:
	for blocker_value in blockers:
		var blocker := Rect2(blocker_value)
		if not swept_bounds.intersects(blocker.grow(radius), true):
			continue
		var hit := Geometry.segment_rect_hit(from, to, blocker, radius)
		if bool(hit.get("hit", false)) and float(hit["t"]) < float(best["t"]):
			best.merge(hit, true)
			best["rect"] = blocker
			best["polygon"] = Geometry.rect_polygon(blocker)


static func _consider_cover_hits_into(
	from: Vector2,
	to: Vector2,
	radius: float,
	swept_bounds: Rect2,
	blockers: Array,
	best: Dictionary,
	candidate: Dictionary
) -> void:
	for blocker_value in blockers:
		var blocker := Rect2(blocker_value)
		if not swept_bounds.intersects(blocker.grow(radius), true):
			continue
		if (
			Geometry.segment_rect_hit_into(
				from, to, blocker, radius, candidate
			)
			and float(candidate["t"]) < float(best["t"])
		):
			best["hit"] = true
			best["t"] = candidate["t"]
			best["normal"] = candidate["normal"]
			best["point"] = candidate["point"]
			best["rect"] = blocker


static func has_line_of_sight(from: Vector2, to: Vector2, padding: float = 0.0, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> bool:
	return has_line_of_sight_with_extra(
		from, to, padding, false, stage_id, []
	)


static func has_line_of_sight_with_extra(from: Vector2, to: Vector2, padding: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> bool:
	var swept_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(padding)
	if not Catalog.cover_rects(stage_id).is_empty():
		for blocker_value in Catalog.cover_rects_near_motion(
			stage_id, from, to, padding
		):
			var blocker := Rect2(blocker_value)
			if (
				swept_bounds.intersects(blocker.grow(padding), true)
				and Geometry.segment_rect_intersects(
					from, to, blocker, padding
				)
			):
				return false
	for blocker_value in extra_cover:
		var blocker := Rect2(blocker_value)
		if (
			swept_bounds.intersects(blocker.grow(padding), true)
			and Geometry.segment_rect_intersects(from, to, blocker, padding)
		):
			return false
	return true


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry.point_segment_distance(point, a, b)


static func move_circle(position: Vector2, motion: Vector2, radius: float, _unused_dynamic_blocker: bool = false, stage_id: StringName = &"stage_1") -> Vector2:
	return move_circle_with_extra(position, motion, radius, false, stage_id, [])


static func move_circle_with_extra(position: Vector2, motion: Vector2, radius: float, _unused_dynamic_blocker: bool, stage_id: StringName, extra_cover: Array) -> Vector2:
	if extra_cover.is_empty() and Catalog.is_fast_motion_clear(stage_id, position, position + motion, radius):
		return position + motion
	return _move_circle_with_extra_exact(position, motion, radius, stage_id, extra_cover)


static func move_circle_with_extra_known_safe(
	position: Vector2,
	motion: Vector2,
	radius: float,
	stage_id: StringName,
	extra_cover: Array,
	known_fast_motion_clear: bool
) -> Vector2:
	## Reuses a caller's exact safe-cell result; all non-safe paths keep the
	## original solver and candidate ordering.
	if extra_cover.is_empty() and known_fast_motion_clear:
		return position + motion
	return _move_circle_with_extra_exact(position, motion, radius, stage_id, extra_cover)


static func _move_circle_with_extra_exact(
	position: Vector2,
	motion: Vector2,
	radius: float,
	stage_id: StringName,
	extra_cover: Array
) -> Vector2:
	var bounds := world_rect(stage_id)
	var result := position
	var attempt_x := Vector2(
		clampf(position.x + motion.x, bounds.position.x + radius, bounds.end.x - radius),
		position.y
	)
	if _position_clear_with_extra(attempt_x, radius, stage_id, extra_cover):
		result.x = attempt_x.x
	var attempt_y := Vector2(
		result.x,
		clampf(position.y + motion.y, bounds.position.y + radius, bounds.end.y - radius)
	)
	if _position_clear_with_extra(attempt_y, radius, stage_id, extra_cover):
		result.y = attempt_y.y
	return result


static func _position_clear_with_extra(
	position: Vector2,
	radius: float,
	stage_id: StringName,
	extra_cover: Array
) -> bool:
	if not Catalog.position_is_walkable(stage_id, position, radius):
		return false
	if Catalog.circle_overlaps_cover(stage_id, position, radius):
		return false
	for blocker_value in extra_cover:
		if circle_overlaps_rect(position, radius, Rect2(blocker_value)):
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
