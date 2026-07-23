class_name VehicleFieldLayoutGenerator
extends RefCounted

## Builds one bounded field variant before play and rejects invalid placements.

const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Layout = preload("res://scripts/vehicle/vehicle_field_layout.gd")

const MAX_ATTEMPTS := 32
const GRID_SIZE := 96.0
const ORDINARY_RADIUS := 36.0
const BOSS_RADIUS := 76.0
const COVER_CLEARANCE := 176.0
const SOCKET_COVER_CLEARANCE := 96.0
const ITEM_PAIR_CLEARANCE := 200.0
const STATIONARY_ITEM_CLEARANCE := 180.0
const RECALL_CLEARANCE := 1200.0
const QUADRANTS: Array[StringName] = [&"nw", &"ne", &"sw", &"se"]
const OUTER_COURTS: Array[Vector2] = [
	Vector2(520,960), Vector2(5080,960), Vector2(520,2440), Vector2(5080,2440),
]

static var _walkable_rects_cache: Array[Rect2] = []
static var _water_rects_cache: Array[Rect2] = []
static var _grid_cache_by_radius: Dictionary = {}


static func generate(layout_seed: int, stage_ids: Array[StringName] = CombatStages.STAGE_IDS) -> VehicleFieldLayout:
	var cover_rng := _rng_for(layout_seed, "cover:v1")
	for _attempt in MAX_ATTEMPTS:
		var selected_ids := _random_cover_ids(cover_rng)
		var selected_rects := _rects_for_ids(selected_ids)
		if _validate_cover_selection(selected_rects).is_empty():
			var generated := _build_layout(layout_seed, selected_ids, selected_rects, stage_ids, false)
			if generated != null:
				return generated
	var fallback_rects := _rects_for_ids(Field.FALLBACK_COVER_IDS)
	var fallback_errors := _validate_cover_selection(fallback_rects)
	if not fallback_errors.is_empty():
		push_error("Field layout fallback is invalid: %s" % "; ".join(fallback_errors))
		return null
	var fallback := _build_layout(
		layout_seed, Field.FALLBACK_COVER_IDS, fallback_rects, stage_ids, true
	)
	if fallback == null:
		push_error("Field layout fallback could not place required stage objects")
	return fallback


static func validate_cover_ids(cover_ids: Array[StringName]) -> PackedStringArray:
	return _validate_cover_selection(_rects_for_ids(cover_ids))


static func cover_ids_for_mask(mask: Array[int]) -> Array[StringName]:
	var result: Array[StringName] = []
	for quadrant_index in QUADRANTS.size():
		var candidates := _cover_candidates_for(QUADRANTS[quadrant_index])
		var combinations := [[0,1], [0,2], [0,3], [1,2], [1,3], [2,3]]
		var pair: Array = combinations[clampi(mask[quadrant_index], 0, combinations.size() - 1)]
		result.append(StringName(candidates[int(pair[0])]["id"]))
		result.append(StringName(candidates[int(pair[1])]["id"]))
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func _build_layout(
	layout_seed: int,
	cover_ids: Array[StringName],
	cover_rects: Array[Rect2],
	stage_ids: Array[StringName],
	used_fallback: bool
) -> VehicleFieldLayout:
	var ordinary := _valid_reachable_points(
		Field.ORDINARY_SPAWN_CANDIDATES, ORDINARY_RADIUS, cover_rects, true
	)
	var bosses := _valid_reachable_points(
		Field.BOSS_ARRIVAL_ANCHORS, BOSS_RADIUS, cover_rects, false
	)
	if ordinary.size() < 16 or bosses.size() != Field.BOSS_ARRIVAL_ANCHORS.size():
		return null
	var objects_by_stage := {}
	var encounter_seeds := {}
	for stage_id in stage_ids:
		var stage_objects := _build_stage_objects(layout_seed, stage_id, cover_rects)
		if stage_objects.is_empty():
			return null
		objects_by_stage[stage_id] = stage_objects
		encounter_seeds[stage_id] = _sub_seed(layout_seed, "%s:encounter:v1" % String(stage_id))
	var layout := Layout.new()
	layout.configure(
		layout_seed, cover_ids, cover_rects, ordinary, bosses,
		objects_by_stage, encounter_seeds, used_fallback
	)
	return layout


static func _build_stage_objects(layout_seed: int, stage_id: StringName, covers: Array[Rect2]) -> Dictionary:
	var stationary_rng := _rng_for(layout_seed, "%s:stationary:v1" % String(stage_id))
	var ordinary_reachable := _reachable_cells(Field.CENTER, ORDINARY_RADIUS, covers)
	var stationary_points: Array[Vector2] = []
	for quadrant in QUADRANTS:
		var candidates: Array = Array(Field.STATIONARY_CANDIDATES[quadrant]).duplicate()
		_shuffle(candidates, stationary_rng)
		var selected := Vector2.INF
		for value in candidates:
			var candidate := Vector2(value)
			if (
				candidate.distance_to(Field.CENTER) >= Field.START_CLEARANCE
				and _point_has_cover_clearance(candidate, SOCKET_COVER_CLEARANCE, covers)
				and _is_walkable(candidate, ORDINARY_RADIUS, covers)
				and _reachable_has(ordinary_reachable, candidate)
			):
				selected = candidate
				break
		if selected == Vector2.INF:
			return {}
		stationary_points.append(selected)
	var roles: Array = Array(CombatStages.profile(stage_id)["stationary_roles"]).duplicate()
	_shuffle(roles, stationary_rng)
	var stationary: Array[Dictionary] = []
	for index in stationary_points.size():
		stationary.append({
			"id":"%s_stationary_%02d" % [String(stage_id), index + 1],
			"role":StringName(roles[index]),
			"pos":stationary_points[index],
			"zone":"field",
			"active":true,
		})

	var item_rng := _rng_for(layout_seed, "%s:items:v1" % String(stage_id))
	var item_candidates: Array = Array(Field.ITEM_SOCKET_CANDIDATES).duplicate()
	_shuffle(item_candidates, item_rng)
	var sockets: Array[Vector2] = []
	for value in item_candidates:
		var candidate := Vector2(value)
		if not _is_valid_item_socket(
			candidate, sockets, stationary_points, covers, ordinary_reachable
		):
			continue
		sockets.append(candidate)
		if sockets.size() == 8:
			break
	if sockets.size() != 8:
		return {}
	var recall_pair := _farthest_pair(sockets)
	if recall_pair.x < 0 or sockets[recall_pair.x].distance_to(sockets[recall_pair.y]) < RECALL_CLEARANCE:
		return {}
	var pickup_sockets: Array[Vector2] = []
	pickup_sockets.append(sockets[recall_pair.x])
	for index in sockets.size():
		if index in [recall_pair.x, recall_pair.y]:
			continue
		pickup_sockets.append(sockets[index])
		if pickup_sockets.size() == 3:
			break
	var crate_sockets: Array[Vector2] = [sockets[recall_pair.y]]
	for socket in sockets:
		if socket in pickup_sockets or socket == sockets[recall_pair.y]:
			continue
		crate_sockets.append(socket)
	var pickups: Array[Dictionary] = [
		{"id":"%s_pickup_recall" % String(stage_id), "kind":&"experience_recall", "pos":pickup_sockets[0]},
		{"id":"%s_pickup_repair_1" % String(stage_id), "kind":&"repair", "heal_amount":35.0, "pos":pickup_sockets[1]},
		{"id":"%s_pickup_repair_2" % String(stage_id), "kind":&"repair", "heal_amount":70.0, "pos":pickup_sockets[2]},
	]
	var crates: Array[Dictionary] = []
	for index in crate_sockets.size():
		crates.append({
			"id":"%s_crate_%02d" % [String(stage_id), index + 1],
			"pos":crate_sockets[index],
			"drop":&"experience_recall" if index == 0 else &"repair",
		})
	return {"stationary":stationary, "pickups":pickups, "crates":crates}


static func _random_cover_ids(rng: RandomNumberGenerator) -> Array[StringName]:
	var result: Array[StringName] = []
	for quadrant in QUADRANTS:
		var candidates := _cover_candidates_for(quadrant)
		_shuffle(candidates, rng)
		result.append(StringName(candidates[0]["id"]))
		result.append(StringName(candidates[1]["id"]))
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func _cover_candidates_for(quadrant: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for candidate in Field.COVER_CANDIDATES:
		if StringName(candidate["quadrant"]) == quadrant:
			result.append(Dictionary(candidate))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return result


static func _rects_for_ids(ids: Array[StringName]) -> Array[Rect2]:
	var by_id := {}
	for candidate in Field.COVER_CANDIDATES:
		by_id[StringName(candidate["id"])] = Rect2(candidate["rect"])
	var result: Array[Rect2] = []
	for id in ids:
		if by_id.has(id):
			result.append(Rect2(by_id[id]))
	return result


static func _validate_cover_selection(covers: Array[Rect2]) -> PackedStringArray:
	var errors := PackedStringArray()
	if covers.size() != 8:
		errors.append("cover selection must contain exactly eight rectangles")
		return errors
	for index in covers.size():
		var cover := covers[index]
		if not _rect_inside_floor_union(cover):
			errors.append("cover %d leaves the walkable floor" % index)
		if _circle_overlaps_rect(Field.CENTER, Field.START_CLEARANCE, cover):
			errors.append("cover %d breaches center clearance" % index)
		for water in _water_rects():
			if _rect_distance(cover, water) < COVER_CLEARANCE:
				errors.append("cover %d is too close to water" % index)
		for other_index in range(index + 1, covers.size()):
			if _rect_distance(cover, covers[other_index]) < COVER_CLEARANCE:
				errors.append("covers %d and %d are too close" % [index, other_index])
	for radius in [ORDINARY_RADIUS, BOSS_RADIUS]:
		var reachable := _reachable_cells(Field.CENTER, radius, covers)
		for court in OUTER_COURTS:
			if not _is_walkable(court, radius, covers) or not _reachable_has(reachable, court):
				errors.append("radius %d cannot reach outer court" % roundi(radius))
				break
	return errors


static func _valid_reachable_points(
	candidates: Array[Vector2],
	radius: float,
	covers: Array[Rect2],
	enforce_center_clearance: bool
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var reachable := _reachable_cells(Field.CENTER, radius, covers)
	for candidate in candidates:
		if enforce_center_clearance and candidate.distance_to(Field.CENTER) < Field.START_CLEARANCE:
			continue
		if _is_walkable(candidate, radius, covers) and _reachable_has(reachable, candidate):
			result.append(candidate)
	return result


static func _is_valid_item_socket(
	candidate: Vector2,
	selected: Array[Vector2],
	stationary: Array[Vector2],
	covers: Array[Rect2],
	reachable: Dictionary
) -> bool:
	if not _is_walkable(candidate, 24.0, covers):
		return false
	if not _point_has_cover_clearance(candidate, SOCKET_COVER_CLEARANCE, covers):
		return false
	if not _reachable_has(reachable, candidate):
		return false
	for hostile in stationary:
		if candidate.distance_to(hostile) < STATIONARY_ITEM_CLEARANCE:
			return false
	for other in selected:
		if candidate.distance_to(other) < ITEM_PAIR_CLEARANCE:
			return false
	return true


static func _farthest_pair(points: Array[Vector2]) -> Vector2i:
	var result := Vector2i(-1, -1)
	var best := -1.0
	for first in points.size():
		for second in range(first + 1, points.size()):
			var distance := points[first].distance_squared_to(points[second])
			if distance > best:
				best = distance
				result = Vector2i(first, second)
	return result


static func _is_walkable(position: Vector2, radius: float, covers: Array[Rect2]) -> bool:
	if not _circle_inside_floor_union(position, radius):
		return false
	for water in _water_rects():
		if _circle_overlaps_rect(position, radius, water):
			return false
	for cover in covers:
		if _circle_overlaps_rect(position, radius, cover):
			return false
	return true


static func _reachable_cells(start: Vector2, radius: float, covers: Array[Rect2]) -> Dictionary:
	var contract := _grid_contract(radius)
	var width := int(contract["width"])
	var height := int(contract["height"])
	var allowed: PackedByteArray = PackedByteArray(contract["walkable"]).duplicate()
	for cover in covers:
		var min_cell := _world_to_cell(cover.position - Vector2.ONE * radius)
		var max_cell := _world_to_cell(cover.end + Vector2.ONE * radius)
		for y in range(maxi(0, min_cell.y), mini(height - 1, max_cell.y) + 1):
			for x in range(maxi(0, min_cell.x), mini(width - 1, max_cell.x) + 1):
				var index := y * width + x
				if allowed[index] == 1 and _circle_overlaps_rect(_cell_center(Vector2i(x, y)), radius, cover):
					allowed[index] = 0
	var start_cell := _world_to_cell(start)
	var start_index := _cell_index(start_cell, width, height)
	var visited := PackedByteArray()
	visited.resize(width * height)
	if start_index < 0 or allowed[start_index] == 0:
		return {"width":width, "height":height, "visited":visited}
	var queue := PackedInt32Array()
	queue.resize(width * height)
	queue[0] = start_index
	visited[start_index] = 1
	var cursor := 0
	var queue_size := 1
	while cursor < queue_size:
		var current_index := queue[cursor]
		cursor += 1
		var x := current_index % width
		var y := floori(float(current_index) / float(width))
		for next_index in [
			current_index - 1 if x > 0 else -1,
			current_index + 1 if x + 1 < width else -1,
			current_index - width if y > 0 else -1,
			current_index + width if y + 1 < height else -1,
		]:
			if next_index < 0 or visited[next_index] == 1 or allowed[next_index] == 0:
				continue
			visited[next_index] = 1
			queue[queue_size] = next_index
			queue_size += 1
	return {"width":width, "height":height, "visited":visited}


static func _reachable_has(reachable: Dictionary, position: Vector2) -> bool:
	var index := _cell_index(
		_world_to_cell(position),
		int(reachable.get("width", 0)),
		int(reachable.get("height", 0))
	)
	if index < 0:
		return false
	var visited: PackedByteArray = reachable["visited"]
	return visited[index] == 1


static func _grid_contract(radius: float) -> Dictionary:
	var key := roundi(radius)
	if _grid_cache_by_radius.has(key):
		return _grid_cache_by_radius[key]
	var width := ceili(Field.WORLD_RECT.size.x / GRID_SIZE)
	var height := ceili(Field.WORLD_RECT.size.y / GRID_SIZE)
	var walkable := PackedByteArray()
	walkable.resize(width * height)
	for y in height:
		for x in width:
			var point := _cell_center(Vector2i(x, y))
			if Field.WORLD_RECT.has_point(point) and _is_static_walkable(point, radius):
				walkable[y * width + x] = 1
	var contract := {"width":width, "height":height, "walkable":walkable}
	_grid_cache_by_radius[key] = contract
	return contract


static func _is_static_walkable(position: Vector2, radius: float) -> bool:
	if not _circle_inside_floor_union(position, radius):
		return false
	for water in _water_rects():
		if _circle_overlaps_rect(position, radius, water):
			return false
	return true


static func _cell_index(cell: Vector2i, width: int, height: int) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return -1
	return cell.y * width + cell.x


static func _circle_inside_floor_union(position: Vector2, radius: float) -> bool:
	var bounds := Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	for rectangle in _walkable_rects():
		if rectangle.encloses(bounds):
			return true
	for sample_index in 16:
		var point := position + Vector2.RIGHT.rotated(
			TAU * float(sample_index) / 16.0
		) * radius * 0.999
		if not _point_in_floor_union(point):
			return false
	return _point_in_floor_union(position)


static func _point_in_floor_union(point: Vector2) -> bool:
	for rectangle in _walkable_rects():
		if rectangle.has_point(point):
			return true
	return false


static func _rect_inside_floor_union(rectangle: Rect2) -> bool:
	var samples := [
		rectangle.position + Vector2(0.1, 0.1),
		Vector2(rectangle.end.x - 0.1, rectangle.position.y + 0.1),
		Vector2(rectangle.position.x + 0.1, rectangle.end.y - 0.1),
		rectangle.end - Vector2(0.1, 0.1),
		rectangle.get_center(),
	]
	for sample in samples:
		if not _point_in_floor_union(sample):
			return false
	return true


static func _point_has_cover_clearance(point: Vector2, clearance: float, covers: Array[Rect2]) -> bool:
	for cover in covers:
		if _circle_overlaps_rect(point, clearance, cover):
			return false
	return true


static func _water_rects() -> Array[Rect2]:
	if _water_rects_cache.is_empty():
		for value in Field.definition()["water_rects"]:
			_water_rects_cache.append(Rect2(value))
	return _water_rects_cache


static func _walkable_rects() -> Array[Rect2]:
	if _walkable_rects_cache.is_empty():
		for region in Field.definition()["walkable_regions"]:
			_walkable_rects_cache.append(Rect2(region["rect"]))
	return _walkable_rects_cache


static func _circle_overlaps_rect(center: Vector2, radius: float, rectangle: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rectangle.position.x, rectangle.end.x),
		clampf(center.y, rectangle.position.y, rectangle.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func _rect_distance(first: Rect2, second: Rect2) -> float:
	var dx := maxf(maxf(first.position.x - second.end.x, second.position.x - first.end.x), 0.0)
	var dy := maxf(maxf(first.position.y - second.end.y, second.position.y - first.end.y), 0.0)
	return Vector2(dx, dy).length()


static func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / GRID_SIZE), floori(position.y / GRID_SIZE))


static func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * GRID_SIZE


static func _sub_seed(layout_seed: int, label: String) -> int:
	return hash("%d:%s" % [layout_seed, label])


static func _rng_for(layout_seed: int, label: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _sub_seed(layout_seed, label)
	return rng


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held
