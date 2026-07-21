class_name VehicleStageRules
extends RefCounted

## Shared geometry, authored layout, and upgrade definitions for the vehicle Stage 1 slice.
## Gameplay and validation consume the same data so collision and progression checks cannot drift.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")

const WORLD_RECT := Catalog.WORLD_RECT
const PLAYER_START := Catalog.PLAYER_START
const PLAYER_RADIUS := 24.0
const BOSS_ARENA := Catalog.BOSS_ARENA
const BOSS_GATE := Catalog.BOSS_GATE
const CHEST_POSITION := Catalog.CHEST_POSITION
const FIELD_BOSS_POSITION := Catalog.FIELD_BOSS_POSITION
const STAGE_BOSS_POSITION := Catalog.STAGE_BOSS_POSITION
const GENERATOR_A_POSITION := Catalog.GENERATOR_A_POSITION
const GENERATOR_B_POSITION := Catalog.GENERATOR_B_POSITION

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
	var rects := Catalog.cover_rects(stage_id)
	if include_boss_gate:
		rects.append(BOSS_GATE)
	return rects


static func get_water_rects(stage_id: StringName = &"flooded_works") -> Array[Rect2]:
	return Catalog.water_rects(stage_id)


static func get_floor_regions(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.floor_regions(stage_id, {"light": FLOOR_LIGHT, "mid": FLOOR_MID, "dark": FLOOR_DARK})


static func get_landmarks() -> Dictionary:
	return {
		"start": PLAYER_START,
		"open_entry": Vector2(760.0, 1100.0),
		"installation_entry": Vector2(1940.0, 1100.0),
		"upper_route": Vector2(2500.0, 520.0),
		"lower_route": Vector2(2500.0, 1670.0),
		"generator_a": GENERATOR_A_POSITION,
		"generator_b": GENERATOR_B_POSITION,
		"field_boss": FIELD_BOSS_POSITION,
		"chest": CHEST_POSITION,
		"boss_gate": Vector2(3860.0, 1100.0),
		"boss": STAGE_BOSS_POSITION,
	}


static func get_upgrade_pool() -> Array[Dictionary]:
	return [
		{
			"id": "ricochet_matrix",
			"title_key": "UPGRADE_RICOCHET_TITLE",
			"family_key": "UPGRADE_FAMILY_PRIMARY",
			"description_key": "UPGRADE_RICOCHET_DESC",
		},
		{
			"id": "phase_lance",
			"title_key": "UPGRADE_PHASE_LANCE_TITLE",
			"family_key": "UPGRADE_FAMILY_PRIMARY",
			"description_key": "UPGRADE_PHASE_LANCE_DESC",
		},
		{
			"id": "forked_muzzle",
			"title_key": "UPGRADE_FORKED_MUZZLE_TITLE",
			"family_key": "UPGRADE_FAMILY_PRIMARY",
			"description_key": "UPGRADE_FORKED_MUZZLE_DESC",
		},
		{
			"id": "twin_seekers",
			"title_key": "UPGRADE_TWIN_SEEKERS_TITLE",
			"family_key": "UPGRADE_FAMILY_PASSIVE",
			"description_key": "UPGRADE_TWIN_SEEKERS_DESC",
		},
		{
			"id": "hunter_firmware",
			"title_key": "UPGRADE_HUNTER_FIRMWARE_TITLE",
			"family_key": "UPGRADE_FAMILY_PASSIVE",
			"description_key": "UPGRADE_HUNTER_FIRMWARE_DESC",
		},
		{
			"id": "ion_wake",
			"title_key": "UPGRADE_ION_WAKE_TITLE",
			"family_key": "UPGRADE_FAMILY_DASH",
			"description_key": "UPGRADE_ION_WAKE_DESC",
		},
		{
			"id": "ram_pulse",
			"title_key": "UPGRADE_RAM_PULSE_TITLE",
			"family_key": "UPGRADE_FAMILY_DASH",
			"description_key": "UPGRADE_RAM_PULSE_DESC",
		},
		{
			"id": "emp_aftershock",
			"title_key": "UPGRADE_EMP_AFTERSHOCK_TITLE",
			"family_key": "UPGRADE_FAMILY_SKILL",
			"description_key": "UPGRADE_EMP_AFTERSHOCK_DESC",
		},
		{
			"id": "circuit_harvest",
			"title_key": "UPGRADE_CIRCUIT_HARVEST_TITLE",
			"family_key": "UPGRADE_FAMILY_BRIDGE",
			"description_key": "UPGRADE_CIRCUIT_HARVEST_DESC",
		},
		{
			"id": "field_converter",
			"title_key": "UPGRADE_FIELD_CONVERTER_TITLE",
			"family_key": "UPGRADE_FAMILY_BRIDGE",
			"description_key": "UPGRADE_FIELD_CONVERTER_DESC",
		},
	]


static func get_upgrade(upgrade_id: StringName) -> Dictionary:
	for upgrade in get_upgrade_pool():
		if StringName(upgrade["id"]) == upgrade_id:
			return upgrade
	return {}


static func get_card_offer(run_index: int) -> Array[Dictionary]:
	var pool := get_upgrade_pool()
	var starts := [0, 3, 6, 1]
	var start_index: int = int(starts[positive_mod(run_index, starts.size())])
	return [
		pool[start_index % pool.size()],
		pool[(start_index + 3) % pool.size()],
		pool[(start_index + 6) % pool.size()],
	]


static func get_enemy_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.enemy_blueprint(stage_id)


static func get_pickup_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.pickup_blueprint(stage_id)


static func get_crate_blueprint(stage_id: StringName = &"flooded_works") -> Array[Dictionary]:
	return Catalog.crate_blueprint(stage_id)


static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func segment_rect_hit(from: Vector2, to: Vector2, rect: Rect2, padding: float = 0.0) -> Dictionary:
	var target := rect.grow(padding)
	if target.has_point(from):
		return {"hit": true, "t": 0.0, "normal": _inside_normal(from, target), "point": from}
	var delta := to - from
	var t_min := 0.0
	var t_max := 1.0
	var entering_normal := Vector2.ZERO

	if absf(delta.x) < 0.00001:
		if from.x < target.position.x or from.x > target.end.x:
			return {"hit": false}
	else:
		var tx1 := (target.position.x - from.x) / delta.x
		var tx2 := (target.end.x - from.x) / delta.x
		var nx1 := Vector2(-1.0, 0.0)
		var nx2 := Vector2(1.0, 0.0)
		if tx1 > tx2:
			var swap_t := tx1
			tx1 = tx2
			tx2 = swap_t
			var swap_n := nx1
			nx1 = nx2
			nx2 = swap_n
		if tx1 > t_min:
			t_min = tx1
			entering_normal = nx1
		t_max = minf(t_max, tx2)
		if t_min > t_max:
			return {"hit": false}

	if absf(delta.y) < 0.00001:
		if from.y < target.position.y or from.y > target.end.y:
			return {"hit": false}
	else:
		var ty1 := (target.position.y - from.y) / delta.y
		var ty2 := (target.end.y - from.y) / delta.y
		var ny1 := Vector2(0.0, -1.0)
		var ny2 := Vector2(0.0, 1.0)
		if ty1 > ty2:
			var swap_t := ty1
			ty1 = ty2
			ty2 = swap_t
			var swap_n := ny1
			ny1 = ny2
			ny2 = swap_n
		if ty1 > t_min:
			t_min = ty1
			entering_normal = ny1
		t_max = minf(t_max, ty2)
		if t_min > t_max:
			return {"hit": false}

	if t_min < 0.0 or t_min > 1.0:
		return {"hit": false}
	return {
		"hit": true,
		"t": t_min,
		"normal": entering_normal,
		"point": from + delta * t_min,
	}


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
	var best := {"hit": false, "t": 2.0}
	for rect in get_cover_rects(include_boss_gate, stage_id):
		var hit := segment_rect_hit(from, to, rect, radius)
		if bool(hit.get("hit", false)) and float(hit["t"]) < float(best["t"]):
			best = hit
			best["rect"] = rect
	return best


static func has_line_of_sight(from: Vector2, to: Vector2, padding: float = 0.0, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> bool:
	return not bool(first_cover_hit(from, to, padding, include_boss_gate, stage_id).get("hit", false))


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.00001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)


static func move_circle(position: Vector2, motion: Vector2, radius: float, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> Vector2:
	var rects := get_cover_rects(include_boss_gate, stage_id)
	var result := position
	var attempt_x := Vector2(
		clampf(position.x + motion.x, WORLD_RECT.position.x + radius, WORLD_RECT.end.x - radius),
		position.y
	)
	var blocked_x := false
	for rect in rects:
		if circle_overlaps_rect(attempt_x, radius, rect):
			blocked_x = true
			break
	if not blocked_x:
		result.x = attempt_x.x

	var attempt_y := Vector2(
		result.x,
		clampf(position.y + motion.y, WORLD_RECT.position.y + radius, WORLD_RECT.end.y - radius)
	)
	var blocked_y := false
	for rect in rects:
		if circle_overlaps_rect(attempt_y, radius, rect):
			blocked_y = true
			break
	if not blocked_y:
		result.y = attempt_y.y
	return result


static func grid_reachable(start: Vector2, goal: Vector2, radius: float = PLAYER_RADIUS, cell_size: float = 70.0, include_boss_gate: bool = false, stage_id: StringName = &"flooded_works") -> bool:
	var min_cell := Vector2i(
		floori((WORLD_RECT.position.x + radius) / cell_size),
		floori((WORLD_RECT.position.y + radius) / cell_size)
	)
	var max_cell := Vector2i(
		floori((WORLD_RECT.end.x - radius) / cell_size),
		floori((WORLD_RECT.end.y - radius) / cell_size)
	)
	var start_cell := Vector2i(floori(start.x / cell_size), floori(start.y / cell_size))
	var goal_cell := Vector2i(floori(goal.x / cell_size), floori(goal.y / cell_size))
	var queue: Array[Vector2i] = [start_cell]
	var visited := {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var rects := get_cover_rects(include_boss_gate, stage_id)

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
			var blocked := false
			for rect in rects:
				if circle_overlaps_rect(point, radius, rect):
					blocked = true
					break
			if blocked:
				continue
			visited[next] = true
			queue.append(next)
	return false


static func validate_blueprint(stage_id: StringName = &"flooded_works") -> PackedStringArray:
	var errors := PackedStringArray()
	var cover := get_cover_rects(false, stage_id)
	for landmark_id in get_landmarks().keys():
		var point: Vector2 = get_landmarks()[landmark_id]
		for rect in cover:
			if circle_overlaps_rect(point, PLAYER_RADIUS, rect):
				errors.append("Landmark %s overlaps solid cover" % landmark_id)
				break

	for enemy_spec in get_enemy_blueprint(stage_id):
		var position: Vector2 = enemy_spec["pos"]
		for rect in cover:
			if circle_overlaps_rect(position, 28.0, rect):
				errors.append("Enemy %s overlaps solid cover" % enemy_spec["id"])
				break

	for pickup_spec in get_pickup_blueprint(stage_id):
		var position: Vector2 = pickup_spec["pos"]
		for rect in cover:
			if circle_overlaps_rect(position, 20.0, rect):
				errors.append("Pickup %s overlaps solid cover" % pickup_spec["id"])
				break

	for crate_spec in get_crate_blueprint(stage_id):
		var position: Vector2 = crate_spec["pos"]
		for rect in cover:
			if circle_overlaps_rect(position, 31.0, rect):
				errors.append("Crate %s overlaps solid cover" % crate_spec["id"])
				break

	var start := PLAYER_START
	for required_id in ["open_entry", "installation_entry", "generator_a", "generator_b", "chest", "boss_gate"]:
		var point: Vector2 = get_landmarks()[required_id]
		if not grid_reachable(start, point, PLAYER_RADIUS, 70.0, false, stage_id):
			errors.append("Required landmark %s is unreachable before boss lock" % required_id)

	if not grid_reachable(start, get_landmarks()["lower_route"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Safe lower route is unreachable")
	if not grid_reachable(start, get_landmarks()["upper_route"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Optional upper route is unreachable")
	if not grid_reachable(start, get_landmarks()["field_boss"], PLAYER_RADIUS, 70.0, false, stage_id):
		errors.append("Optional field boss is unreachable")
	if not grid_reachable(get_landmarks()["boss_gate"], get_landmarks()["boss"], PLAYER_RADIUS, 70.0, false, stage_id):
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
