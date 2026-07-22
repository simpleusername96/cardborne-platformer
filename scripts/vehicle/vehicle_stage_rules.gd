class_name VehicleStageRules
extends RefCounted

## Shared geometry and authored-layout helpers for the vehicle run.
## Gameplay and validation consume the same data so collision checks cannot drift.

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


static func get_cover_rects(include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> Array[Rect2]:
	var rects: Array[Rect2] = Catalog.cover_rects(stage_id)
	if include_boss_gate:
		rects = rects.duplicate()
		rects.append(boss_gate(stage_id))
	return rects


static func get_cover_polygons(include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> Array:
	var polygons: Array = Catalog.cover_polygons(stage_id)
	if include_boss_gate:
		polygons = polygons.duplicate()
		polygons.append(Geometry.rect_polygon(boss_gate(stage_id)))
	return polygons


static func world_rect(stage_id: StringName = &"flooded_works") -> Rect2:
	return Catalog.world_rect(stage_id)


static func player_start(stage_id: StringName = &"flooded_works") -> Vector2:
	return Catalog.player_start(stage_id)


static func boss_arena(stage_id: StringName = &"flooded_works") -> Rect2:
	return Catalog.boss_arena(stage_id)


static func boss_gate(stage_id: StringName = &"flooded_works") -> Rect2:
	return Catalog.boss_gate(stage_id)


static func landmark(landmark_id: String, stage_id: StringName = &"flooded_works") -> Vector2:
	return Catalog.landmark(stage_id, landmark_id)


static func objective_triggers(stage_id: StringName = &"flooded_works") -> Dictionary:
	return Catalog.objective_triggers(stage_id)


static func get_water_rects(stage_id: StringName = &"flooded_works") -> Array[Rect2]:
	return Catalog.water_rects(stage_id)


static func get_floor_regions(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.floor_regions(stage_id, {"light": FLOOR_LIGHT, "mid": FLOOR_MID, "dark": FLOOR_DARK})


static func is_position_walkable(position: Vector2, radius: float = 0.0, stage_id: StringName = &"flooded_works") -> bool:
	if not Catalog.position_is_walkable(stage_id, position, radius):
		return false
	for polygon in get_cover_polygons(false, stage_id):
		if Geometry.circle_overlaps_polygon(position, radius, polygon):
			return false
	return true


static func get_landmarks(stage_id: StringName = &"flooded_works") -> Dictionary:
	return Catalog.landmarks(stage_id)


static func get_enemy_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.enemy_blueprint(stage_id)


static func get_pickup_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.pickup_blueprint(stage_id)


static func get_crate_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.crate_blueprint(stage_id)


static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	return Geometry.circle_overlaps_polygon(center, radius, Geometry.rect_polygon(rect))


static func segment_rect_hit(from: Vector2, to: Vector2, rect: Rect2, padding: float = 0.0) -> Dictionary:
	return Geometry.segment_rect_hit(from, to, rect, padding)


static func _inside_normal(point: Vector2, rect: Rect2) -> Vector2:
	var distances := [
		{"d": absf(point.x - rect.position.x), "n": Vector2(-1.0, 0.0)},
		{"d": absf(point.x - rect.end.x), "n": Vector2(1.0, 0.0)},
		{"d": absf(point.y - rect.position.y), "n": Vector2(0.0, -1.0)},
		{"d": absf(point.y - rect.end.y), "n": Vector2(0.0, 1.0)},
	]
	distances.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	return distances[0]["n"]


static func first_cover_hit(from: Vector2, to: Vector2, radius: float, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> Dictionary:
	return first_cover_hit_with_extra(from, to, radius, include_boss_gate, stage_id, [])


static func first_cover_hit_with_extra(from: Vector2, to: Vector2, radius: float, include_boss_gate: bool, stage_id: StringName, extra_cover: Array) -> Dictionary:
	var best := {"hit": false, "t": 2.0}
	var polygons: Array = get_cover_polygons(include_boss_gate, stage_id)
	if not extra_cover.is_empty():
		polygons = polygons.duplicate()
	for value in extra_cover:
		polygons.append(Geometry.rect_polygon(Rect2(value)))
	for polygon in polygons:
		var hit := Geometry.segment_polygon_hit(from, to, polygon, radius)
		if bool(hit.get("hit", false)) and float(hit["t"]) < float(best["t"]):
			best = hit
			best["rect"] = Geometry.polygon_bounds(polygon)
			best["polygon"] = polygon
	return best


static func has_line_of_sight(from: Vector2, to: Vector2, padding: float = 0.0, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> bool:
	return not bool(first_cover_hit(from, to, padding, include_boss_gate, stage_id).get("hit", false))


static func has_line_of_sight_with_extra(from: Vector2, to: Vector2, padding: float, include_boss_gate: bool, stage_id: StringName, extra_cover: Array) -> bool:
	return not bool(first_cover_hit_with_extra(from, to, padding, include_boss_gate, stage_id, extra_cover).get("hit", false))


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.00001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)


static func move_circle(position: Vector2, motion: Vector2, radius: float, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> Vector2:
	return move_circle_with_extra(position, motion, radius, include_boss_gate, stage_id, [])


static func move_circle_with_extra(position: Vector2, motion: Vector2, radius: float, include_boss_gate: bool, stage_id: StringName, extra_cover: Array) -> Vector2:
	var polygons: Array = get_cover_polygons(include_boss_gate, stage_id)
	if not extra_cover.is_empty():
		polygons = polygons.duplicate()
	for value in extra_cover:
		polygons.append(Geometry.rect_polygon(Rect2(value)))
	var bounds := world_rect(stage_id)
	var result := position
	var attempt_x := Vector2(
		clampf(position.x + motion.x, bounds.position.x + radius, bounds.end.x - radius),
		position.y
	)
	var blocked_x := not Catalog.position_is_walkable(stage_id, attempt_x, radius)
	for polygon in polygons:
		if Geometry.circle_overlaps_polygon(attempt_x, radius, polygon):
			blocked_x = true
			break
	if not blocked_x:
		result.x = attempt_x.x

	var attempt_y := Vector2(
		result.x,
		clampf(position.y + motion.y, bounds.position.y + radius, bounds.end.y - radius)
	)
	var blocked_y := not Catalog.position_is_walkable(stage_id, attempt_y, radius)
	for polygon in polygons:
		if Geometry.circle_overlaps_polygon(attempt_y, radius, polygon):
			blocked_y = true
			break
	if not blocked_y:
		result.y = attempt_y.y
	return result


static func grid_reachable(start: Vector2, goal: Vector2, radius: float = PLAYER_RADIUS, cell_size: float = 70.0, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> bool:
	return grid_reachable_with_extra(start, goal, radius, cell_size, include_boss_gate, stage_id, [])


static func grid_reachable_with_extra(start: Vector2, goal: Vector2, radius: float, cell_size: float, include_boss_gate: bool, stage_id: StringName, extra_cover: Array) -> bool:
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
	var polygons: Array = get_cover_polygons(include_boss_gate, stage_id)
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


static func first_reflector_hit(from: Vector2, to: Vector2, radius: float, orientations: Dictionary, stage_id: StringName, environment_zones: Array = []) -> Dictionary:
	var best := {"hit":false, "t":2.0}
	if stage_id != &"abyssal_observatory":
		return best
	var zones := environment_zones if not environment_zones.is_empty() else Catalog.environment_zones(stage_id)
	for zone in zones:
		if StringName(zone.get("kind", &"")) != &"reflector":
			continue
		var hit := segment_rect_hit(from, to, Rect2(zone["rect"]), radius)
		if not bool(hit.get("hit", false)) or float(hit["t"]) >= float(best["t"]):
			continue
		var reflector_id := StringName(zone["id"])
		var orientation := positive_mod(int(orientations.get(reflector_id, zone.get("initial_orientation", 0))), 4)
		var turn_sign := 1.0 if orientation in [0, 1] else -1.0
		best = hit
		best["reflector_id"] = reflector_id
		best["orientation"] = orientation
		best["turn_sign"] = turn_sign
		best["out_direction"] = (to - from).normalized().rotated(turn_sign * PI * 0.5)
	return best


static func validate_blueprint(stage_id: StringName = &"flooded_works") -> PackedStringArray:
	var errors := PackedStringArray()
	var cover := get_cover_polygons(false, stage_id)
	var landmarks := get_landmarks(stage_id)
	for landmark_id in landmarks.keys():
		var point: Vector2 = landmarks[landmark_id]
		if not Catalog.position_is_walkable(stage_id, point, PLAYER_RADIUS):
			errors.append("Landmark %s is outside walkable floor" % landmark_id)
		for polygon in cover:
			if Geometry.circle_overlaps_polygon(point, PLAYER_RADIUS, polygon):
				errors.append("Landmark %s overlaps solid cover" % landmark_id)
				break

	for enemy_spec in get_enemy_blueprint(stage_id):
		var position: Vector2 = enemy_spec["pos"]
		if not Catalog.position_is_walkable(stage_id, position, 28.0):
			errors.append("Enemy %s is outside walkable floor" % enemy_spec["id"])
		for polygon in cover:
			if Geometry.circle_overlaps_polygon(position, 28.0, polygon):
				errors.append("Enemy %s overlaps solid cover" % enemy_spec["id"])
				break

	for pickup_spec in get_pickup_blueprint(stage_id):
		var position: Vector2 = pickup_spec["pos"]
		if not Catalog.position_is_walkable(stage_id, position, 20.0):
			errors.append("Pickup %s is outside walkable floor" % pickup_spec["id"])
		for polygon in cover:
			if Geometry.circle_overlaps_polygon(position, 20.0, polygon):
				errors.append("Pickup %s overlaps solid cover" % pickup_spec["id"])
				break

	for crate_spec in get_crate_blueprint(stage_id):
		var position: Vector2 = crate_spec["pos"]
		if not Catalog.position_is_walkable(stage_id, position, 31.0):
			errors.append("Crate %s is outside walkable floor" % crate_spec["id"])
		for polygon in cover:
			if Geometry.circle_overlaps_polygon(position, 31.0, polygon):
				errors.append("Crate %s overlaps solid cover" % crate_spec["id"])
				break

	var start := player_start(stage_id)
	for required_id in ["open_entry", "installation_entry", "generator_a", "generator_b", "chest", "boss_gate"]:
		var point: Vector2 = landmarks[required_id]
		if not grid_reachable(start, point, PLAYER_RADIUS, 70.0, false, stage_id):
			errors.append("Required landmark %s is unreachable before boss lock" % required_id)

	if not grid_reachable(start, landmarks["lower_route"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Safe lower route is unreachable")
	if not grid_reachable(start, landmarks["upper_route"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Optional upper route is unreachable")
	if not grid_reachable(start, landmarks["field_boss"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Optional field boss is unreachable")
	if not grid_reachable(landmarks["boss_gate"], landmarks["boss"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Boss arena center is unreachable after the gate opens")
	return errors


static func validate_all_blueprints() -> Dictionary:
	var results := {}
	for stage_id in Catalog.STAGE_IDS:
		results[stage_id] = validate_blueprint(stage_id)
	return results


static func positive_mod(value: int, divisor: int) -> int:
	var result := value % divisor
	return result if result >= 0 else result + divisor
