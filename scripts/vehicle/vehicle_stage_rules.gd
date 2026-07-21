class_name VehicleStageRules
extends RefCounted

## Shared geometry, authored layout, and upgrade definitions for the vehicle Stage 1 slice.
## Gameplay and validation consume the same data so collision and progression checks cannot drift.

const WORLD_RECT := Rect2(0.0, 0.0, 5200.0, 2200.0)
const PLAYER_START := Vector2(330.0, 1100.0)
const PLAYER_RADIUS := 24.0
const BOSS_ARENA := Rect2(3970.0, 420.0, 1100.0, 1360.0)
const BOSS_GATE := Rect2(3890.0, 820.0, 70.0, 560.0)
const CHEST_POSITION := Vector2(3470.0, 1120.0)
const FIELD_BOSS_POSITION := Vector2(2860.0, 330.0)
const STAGE_BOSS_POSITION := Vector2(4580.0, 1090.0)
const GENERATOR_A_POSITION := Vector2(2300.0, 570.0)
const GENERATOR_B_POSITION := Vector2(2880.0, 1650.0)

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


static func get_cover_rects(include_boss_gate: bool = false) -> Array[Rect2]:
	var rects: Array[Rect2] = [
		Rect2(0.0, 0.0, 5200.0, 70.0),
		Rect2(0.0, 2130.0, 5200.0, 70.0),
		Rect2(0.0, 0.0, 70.0, 2200.0),
		Rect2(5130.0, 0.0, 70.0, 2200.0),
		# Deployment dock and opening channel.
		Rect2(620.0, 70.0, 70.0, 650.0),
		Rect2(620.0, 1480.0, 70.0, 650.0),
		Rect2(980.0, 540.0, 190.0, 330.0),
		Rect2(1260.0, 1230.0, 300.0, 180.0),
		Rect2(1600.0, 670.0, 180.0, 340.0),
		Rect2(1700.0, 1510.0, 250.0, 160.0),
		# Installation fork: a large center mass creates the upper/lower route choice.
		Rect2(2030.0, 760.0, 930.0, 680.0),
		Rect2(2160.0, 180.0, 260.0, 210.0),
		Rect2(2600.0, 430.0, 250.0, 170.0),
		Rect2(2140.0, 1760.0, 300.0, 190.0),
		Rect2(3040.0, 1510.0, 240.0, 220.0),
		Rect2(3200.0, 530.0, 210.0, 310.0),
		# Relay approach and chest court.
		Rect2(3390.0, 680.0, 210.0, 210.0),
		Rect2(3390.0, 1390.0, 210.0, 210.0),
		Rect2(3660.0, 260.0, 160.0, 440.0),
		Rect2(3660.0, 1500.0, 160.0, 440.0),
		# Boss arena cover, placed to leave broad circulation lanes.
		Rect2(4200.0, 610.0, 170.0, 230.0),
		Rect2(4200.0, 1360.0, 170.0, 230.0),
		Rect2(4740.0, 610.0, 170.0, 230.0),
		Rect2(4740.0, 1360.0, 170.0, 230.0),
	]
	if include_boss_gate:
		rects.append(BOSS_GATE)
	return rects


static func get_water_rects() -> Array[Rect2]:
	return [
		Rect2(690.0, 70.0, 330.0, 430.0),
		Rect2(690.0, 1700.0, 330.0, 430.0),
		Rect2(1220.0, 70.0, 250.0, 360.0),
		Rect2(1500.0, 1750.0, 380.0, 380.0),
		Rect2(1900.0, 70.0, 180.0, 650.0),
		Rect2(1900.0, 1480.0, 180.0, 650.0),
		Rect2(2960.0, 70.0, 200.0, 420.0),
		Rect2(2960.0, 1780.0, 200.0, 350.0),
		Rect2(3820.0, 70.0, 120.0, 640.0),
		Rect2(3820.0, 1490.0, 120.0, 640.0),
	]


static func get_floor_regions() -> Array[Dictionary]:
	return [
		{"name": "Deployment Dock", "rect": Rect2(70.0, 720.0, 550.0, 760.0), "color": FLOOR_LIGHT},
		{"name": "Foundry Approach", "rect": Rect2(620.0, 390.0, 1360.0, 1420.0), "color": FLOOR_MID},
		{"name": "Drowned Installations", "rect": Rect2(1980.0, 120.0, 1460.0, 1960.0), "color": FLOOR_DARK},
		{"name": "Relay Court", "rect": Rect2(3300.0, 610.0, 650.0, 980.0), "color": FLOOR_MID},
		{"name": "Colossus Basin", "rect": BOSS_ARENA, "color": FLOOR_DARK},
	]


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
			"title": "Ricochet Matrix",
			"family": "PRIMARY",
			"description": "Primary rounds bounce once from solid cover. Bank shots can remove turrets before entering their lane.",
		},
		{
			"id": "phase_lance",
			"title": "Phase Lance",
			"family": "PRIMARY",
			"description": "Primary rounds pierce one enemy. Cover still stops every shot.",
		},
		{
			"id": "forked_muzzle",
			"title": "Forked Muzzle",
			"family": "PRIMARY",
			"description": "Every fifth trigger launches two angled support rounds.",
		},
		{
			"id": "twin_seekers",
			"title": "Twin Seekers",
			"family": "PASSIVE",
			"description": "The passive launcher fires a second missile at another eligible line-of-sight target.",
		},
		{
			"id": "hunter_firmware",
			"title": "Hunter Firmware",
			"family": "PASSIVE",
			"description": "Passive missiles prioritize installations and burst on impact.",
		},
		{
			"id": "ion_wake",
			"title": "Ion Wake",
			"family": "DASH",
			"description": "Dash leaves a damaging trail. Overdrive increases its width and duration.",
		},
		{
			"id": "ram_pulse",
			"title": "Ram Pulse",
			"family": "DASH",
			"description": "Dash arrival emits a close shock pulse that damages enemies and clears projectiles.",
		},
		{
			"id": "emp_aftershock",
			"title": "EMP Aftershock",
			"family": "SKILL",
			"description": "The Z skill repeats a smaller pulse after a short delay.",
		},
		{
			"id": "circuit_harvest",
			"title": "Circuit Harvest",
			"family": "BRIDGE",
			"description": "Destroying an installation immediately advances passive and Z cooldowns.",
		},
		{
			"id": "field_converter",
			"title": "Field Converter",
			"family": "BRIDGE",
			"description": "Temporary pickups last longer and restore a small amount of barrier strength.",
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


static func get_enemy_blueprint() -> Array[Dictionary]:
	return [
		# Open combat field.
		{"id": "approach_chaser_a", "role": "chaser", "pos": Vector2(900.0, 1110.0), "zone": "approach"},
		{"id": "approach_shooter_a", "role": "shooter", "pos": Vector2(1240.0, 690.0), "zone": "approach"},
		{"id": "approach_chaser_b", "role": "chaser", "pos": Vector2(1420.0, 1600.0), "zone": "approach"},
		{"id": "approach_controller", "role": "controller", "pos": Vector2(1730.0, 1210.0), "zone": "approach"},
		{"id": "approach_shooter_b", "role": "shooter", "pos": Vector2(1840.0, 520.0), "zone": "approach"},
		# Installation field.
		{"id": "upper_turret", "role": "turret", "pos": Vector2(2460.0, 370.0), "zone": "installations"},
		{"id": "lower_turret", "role": "turret", "pos": Vector2(2670.0, 1830.0), "zone": "installations"},
		{"id": "upper_arc_mine", "role": "mine", "pos": Vector2(3100.0, 710.0), "zone": "installations"},
		{"id": "lower_arc_mine", "role": "mine", "pos": Vector2(2260.0, 1610.0), "zone": "installations"},
		{"id": "generator_a", "role": "generator", "pos": GENERATOR_A_POSITION, "zone": "installations", "required": true},
		{"id": "generator_b", "role": "generator", "pos": GENERATOR_B_POSITION, "zone": "installations", "required": true},
		{"id": "install_chaser", "role": "chaser", "pos": Vector2(3160.0, 1110.0), "zone": "installations"},
		{"id": "install_shooter", "role": "shooter", "pos": Vector2(3270.0, 1290.0), "zone": "installations"},
		{"id": "install_controller", "role": "controller", "pos": Vector2(3030.0, 1030.0), "zone": "installations"},
		# Optional upper-route elite.
		{"id": "dredge_warden", "role": "field_boss", "pos": FIELD_BOSS_POSITION, "zone": "field_boss", "optional": true},
	]


static func get_pickup_blueprint() -> Array[Dictionary]:
	return [
		{"id": "repair_open", "kind": "repair", "pos": Vector2(1500.0, 1050.0)},
		{"id": "attack_upper", "kind": "attack", "pos": Vector2(2080.0, 470.0)},
		{"id": "overdrive_lower", "kind": "overdrive", "pos": Vector2(2120.0, 1690.0)},
		{"id": "barrier_lower", "kind": "barrier", "pos": Vector2(3170.0, 1780.0)},
		{"id": "repair_relay", "kind": "repair", "pos": Vector2(3660.0, 1110.0)},
	]


static func get_crate_blueprint() -> Array[Dictionary]:
	return [
		{"id": "crate_attack", "pos": Vector2(1110.0, 1510.0), "drop": "attack"},
		{"id": "crate_repair", "pos": Vector2(1880.0, 1130.0), "drop": "repair"},
		{"id": "crate_barrier", "pos": Vector2(3370.0, 1080.0), "drop": "barrier"},
	]


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


static func first_cover_hit(from: Vector2, to: Vector2, radius: float, include_boss_gate: bool = false) -> Dictionary:
	var best := {"hit": false, "t": 2.0}
	for rect in get_cover_rects(include_boss_gate):
		var hit := segment_rect_hit(from, to, rect, radius)
		if bool(hit.get("hit", false)) and float(hit["t"]) < float(best["t"]):
			best = hit
			best["rect"] = rect
	return best


static func has_line_of_sight(from: Vector2, to: Vector2, padding: float = 0.0, include_boss_gate: bool = false) -> bool:
	return not bool(first_cover_hit(from, to, padding, include_boss_gate).get("hit", false))


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.00001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)


static func move_circle(position: Vector2, motion: Vector2, radius: float, include_boss_gate: bool = false) -> Vector2:
	var rects := get_cover_rects(include_boss_gate)
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


static func grid_reachable(start: Vector2, goal: Vector2, radius: float = PLAYER_RADIUS, cell_size: float = 70.0, include_boss_gate: bool = false) -> bool:
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
	var rects := get_cover_rects(include_boss_gate)

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


static func validate_blueprint() -> PackedStringArray:
	var errors := PackedStringArray()
	var cover := get_cover_rects(false)
	for landmark_id in get_landmarks().keys():
		var point: Vector2 = get_landmarks()[landmark_id]
		for rect in cover:
			if circle_overlaps_rect(point, PLAYER_RADIUS, rect):
				errors.append("Landmark %s overlaps solid cover" % landmark_id)
				break

	for enemy_spec in get_enemy_blueprint():
		var position: Vector2 = enemy_spec["pos"]
		for rect in cover:
			if circle_overlaps_rect(position, 28.0, rect):
				errors.append("Enemy %s overlaps solid cover" % enemy_spec["id"])
				break

	for pickup_spec in get_pickup_blueprint():
		var position: Vector2 = pickup_spec["pos"]
		for rect in cover:
			if circle_overlaps_rect(position, 20.0, rect):
				errors.append("Pickup %s overlaps solid cover" % pickup_spec["id"])
				break

	var start := PLAYER_START
	for required_id in ["open_entry", "installation_entry", "generator_a", "generator_b", "chest", "boss_gate"]:
		var point: Vector2 = get_landmarks()[required_id]
		if not grid_reachable(start, point, PLAYER_RADIUS, 70.0, false):
			errors.append("Required landmark %s is unreachable before boss lock" % required_id)

	if not grid_reachable(start, get_landmarks()["lower_route"], PLAYER_RADIUS, 70.0, false):
		errors.append("Safe lower route is unreachable")
	if not grid_reachable(start, get_landmarks()["upper_route"], PLAYER_RADIUS, 70.0, false):
		errors.append("Optional upper route is unreachable")
	if not grid_reachable(get_landmarks()["boss_gate"], get_landmarks()["boss"], PLAYER_RADIUS, 70.0, false):
		errors.append("Boss arena center is unreachable after the gate opens")
	return errors


static func positive_mod(value: int, divisor: int) -> int:
	var result := value % divisor
	return result if result >= 0 else result + divisor
