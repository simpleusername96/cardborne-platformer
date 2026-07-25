class_name VehicleFieldLayoutGenerator
extends RefCounted

## Builds one bounded field variant before play and rejects invalid placements.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Layout = preload("res://scripts/vehicle/vehicle_field_layout.gd")
const TacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

const MAX_ATTEMPTS := 32
const GRID_SIZE := 96.0
const ORDINARY_RADIUS := 36.0
const BOSS_RADIUS := 76.0
const COVER_CLEARANCE := 176.0
const SOCKET_COVER_CLEARANCE := 64.0
const ITEM_PAIR_CLEARANCE := 180.0
const STATIONARY_ITEM_CLEARANCE := 120.0
const RECALL_CLEARANCE := 1200.0
const STATIONARY_FEATURE_RADIUS := 54.0
const SOCKET_FEATURE_RADIUS := 54.0
const SECTORS: Array[StringName] = [&"nw", &"n", &"ne", &"sw", &"s", &"se"]

static var _field: Dictionary = {}
static var _walkable_rects_cache: Array[Rect2] = []
static var _water_rects_cache: Array[Rect2] = []
static var _grid_cache_by_radius: Dictionary = {}


static func generate(
	layout_seed: int,
	stage_ids: Array[StringName] = CombatStages.STAGE_IDS,
	field_id_override: StringName = &""
) -> VehicleFieldLayout:
	var field_id := (
		FieldRegistry.select_id(layout_seed)
		if field_id_override.is_empty()
		else FieldRegistry.normalized_id(field_id_override)
	)
	_configure_field(FieldRegistry.definition(field_id))
	var feature_errors := _validate_feature_contract()
	if not feature_errors.is_empty():
		push_error("Field features are invalid: %s" % "; ".join(feature_errors))
		return null
	var layouts_by_stage := {}
	var previous_cover_ids: Array[StringName] = []
	for stage_id in stage_ids:
		var tactical := _build_stage_layout(
			layout_seed, stage_id, previous_cover_ids
		)
		if tactical == null:
			push_error(
				"Field layout could not compile %s/%s" % [_field["id"], stage_id]
			)
			return null
		layouts_by_stage[stage_id] = tactical
		previous_cover_ids = tactical.cover_ids.duplicate()
	var layout := Layout.new()
	layout.configure(
		layout_seed,
		StringName(_field["id"]),
		_field,
		layouts_by_stage
	)
	return layout


static func validate_cover_ids(cover_ids: Array[StringName]) -> PackedStringArray:
	return _validate_cover_selection(_rects_for_ids(cover_ids))


static func validate_feature_contract(definition: Dictionary) -> PackedStringArray:
	_configure_field(definition)
	return _validate_feature_contract()


static func feature_overlaps_circle(
	definition: Dictionary,
	position: Vector2,
	radius: float
) -> bool:
	for value in Array(definition.get("features", [])):
		if _single_feature_overlaps_circle(Dictionary(value), position, radius):
			return true
	return false


static func feature_overlaps_rect(
	definition: Dictionary,
	rectangle: Rect2
) -> bool:
	for value in Array(definition.get("features", [])):
		if _single_feature_overlaps_rect(Dictionary(value), rectangle):
			return true
	return false


static func cover_ids_for_mask(mask: Array[int]) -> Array[StringName]:
	var result: Array[StringName] = []
	if _field.is_empty():
		_configure_field(FieldRegistry.definition(FieldRegistry.FIELD_IDS[0]))
	for sector_index in SECTORS.size():
		var candidates := _cover_candidates_for(SECTORS[sector_index])
		var choice := mask[sector_index] if sector_index < mask.size() else 0
		result.append(StringName(candidates[posmod(choice, candidates.size())]["id"]))
	for sector_index in [0, 5]:
		var candidates := _cover_candidates_for(SECTORS[sector_index])
		var choice := mask[sector_index] if sector_index < mask.size() else 0
		result.append(StringName(candidates[posmod(choice + 1, candidates.size())]["id"]))
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func _build_stage_layout(
	layout_seed: int,
	stage_id: StringName,
	previous_cover_ids: Array[StringName]
) -> TacticalLayout:
	var cover_rng := _rng_for(
		layout_seed, "%s:cover:v2" % String(stage_id)
	)
	for _attempt in MAX_ATTEMPTS:
		var selected_ids := _random_cover_ids(cover_rng)
		if selected_ids == previous_cover_ids:
			continue
		var selected_rects := _rects_for_ids(selected_ids)
		if _validate_cover_selection(selected_rects).is_empty():
			var generated := _compile_stage_layout(
				layout_seed, stage_id, selected_ids, selected_rects, false
			)
			if generated != null:
				return generated
	return _enumerated_stage_fallback(
		layout_seed, stage_id, previous_cover_ids
	)


static func _enumerated_stage_fallback(
	layout_seed: int,
	stage_id: StringName,
	previous_cover_ids: Array[StringName]
) -> TacticalLayout:
	var candidate_counts: Array[int] = []
	var combination_count := 1
	for sector in SECTORS:
		var count := _cover_candidates_for(sector).size()
		if count <= 0:
			return null
		candidate_counts.append(count)
		combination_count *= count
	var start := posmod(
		_sub_seed(layout_seed, "%s:cover-fallback:v2" % String(stage_id)),
		combination_count
	)
	for offset in combination_count:
		var encoded := posmod(start + offset, combination_count)
		var mask: Array[int] = []
		for count in candidate_counts:
			mask.append(encoded % count)
			encoded = floori(float(encoded) / float(count))
		var selected_ids := cover_ids_for_mask(mask)
		if selected_ids == previous_cover_ids:
			continue
		var selected_rects := _rects_for_ids(selected_ids)
		if not _validate_cover_selection(selected_rects).is_empty():
			continue
		var generated := _compile_stage_layout(
			layout_seed, stage_id, selected_ids, selected_rects, true
		)
		if generated != null:
			return generated
	return null


static func _compile_stage_layout(
	layout_seed: int,
	stage_id: StringName,
	cover_ids: Array[StringName],
	cover_rects: Array[Rect2],
	used_fallback: bool
) -> TacticalLayout:
	var ordinary := _valid_reachable_points(
		_field["ordinary_spawn_anchors"], ORDINARY_RADIUS, cover_rects, true
	)
	var bosses := _valid_reachable_points(
		_field["boss_arrival_anchors"], BOSS_RADIUS, cover_rects, false
	)
	if ordinary.size() < 20 or bosses.size() < 8:
		return null
	var stage_objects := _build_stage_objects(
		layout_seed, stage_id, cover_rects
	)
	if stage_objects.is_empty():
		return null
	var support_sockets: Array[Vector2] = []
	support_sockets.assign(stage_objects.get("support_sockets", []))
	stage_objects.erase("support_sockets")
	var layout := TacticalLayout.new()
	layout.configure(
		stage_id,
		_field,
		cover_ids,
		cover_rects,
		ordinary,
		bosses,
		stage_objects,
		support_sockets,
		_sub_seed(layout_seed, "%s:encounter:v2" % String(stage_id)),
		used_fallback
	)
	return layout


static func _build_stage_objects(layout_seed: int, stage_id: StringName, covers: Array[Rect2]) -> Dictionary:
	var stationary_rng := _rng_for(layout_seed, "%s:stationary:v1" % String(stage_id))
	var ordinary_reachable := _reachable_cells(Vector2(_field["player_start"]), ORDINARY_RADIUS, covers)
	var stationary_points: Array[Vector2] = []
	var stationary_sectors: Array = Array(SECTORS).duplicate()
	_shuffle(stationary_sectors, stationary_rng)
	for sector_value in stationary_sectors.slice(0, 4):
		var sector := StringName(sector_value)
		var groups: Dictionary = _field["stationary_candidates"]
		var candidates: Array = Array(groups[sector]).duplicate()
		_shuffle(candidates, stationary_rng)
		var selected := Vector2.INF
		for value in candidates:
			var candidate := Vector2(value)
			if (
				candidate.distance_to(Vector2(_field["player_start"])) >= float(_field["start_clearance"])
				and _point_has_cover_clearance(candidate, SOCKET_COVER_CLEARANCE, covers)
				and not feature_overlaps_circle(
					_field, candidate, STATIONARY_FEATURE_RADIUS
				)
				and _is_walkable(candidate, ORDINARY_RADIUS, covers)
				and _reachable_has(ordinary_reachable, candidate)
			):
				selected = candidate
				break
		if selected == Vector2.INF:
			push_warning("layout stationary placement failed for %s/%s" % [_field["id"], stage_id])
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
	var item_candidates: Array = Array(_field["item_socket_candidates"]).duplicate()
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
		push_warning("layout item placement failed for %s/%s (%d sockets)" % [_field["id"], stage_id, sockets.size()])
		return {}
	var recall_pair := _farthest_pair(sockets)
	if recall_pair.x < 0 or sockets[recall_pair.x].distance_to(sockets[recall_pair.y]) < RECALL_CLEARANCE:
		push_warning("layout recall placement failed for %s/%s" % [_field["id"], stage_id])
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
	var boss_reachable := _reachable_cells(
		Vector2(_field["player_start"]), BOSS_RADIUS, covers
	)
	var support_sockets: Array[Vector2] = []
	for value in item_candidates:
		var candidate := Vector2(value)
		if candidate in sockets:
			continue
		if not _is_valid_support_socket(
			candidate,
			sockets,
			stationary_points,
			support_sockets,
			covers,
			ordinary_reachable,
			boss_reachable
		):
			continue
		support_sockets.append(candidate)
		if support_sockets.size() == 12:
			break
	if support_sockets.size() != 12:
		push_warning(
			"layout support placement failed for %s/%s (%d sockets)" % [
				_field["id"], stage_id, support_sockets.size()
			]
		)
		return {}
	return {
		"stationary":stationary,
		"pickups":pickups,
		"crates":crates,
		"support_sockets":support_sockets,
	}


static func _random_cover_ids(rng: RandomNumberGenerator) -> Array[StringName]:
	var result: Array[StringName] = []
	var second_sectors: Array[StringName] = []
	for sector in SECTORS:
		if _cover_candidates_for(sector).size() > 1:
			second_sectors.append(sector)
	_shuffle(second_sectors, rng)
	for sector in SECTORS:
		var candidates := _cover_candidates_for(sector)
		if candidates.is_empty():
			return []
		_shuffle(candidates, rng)
		result.append(StringName(candidates[0]["id"]))
		if sector in second_sectors.slice(0, 2):
			result.append(StringName(candidates[1]["id"]))
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func _cover_candidates_for(sector: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for candidate in Array(_field["cover_candidates"]):
		if StringName(candidate["sector"]) != sector:
			continue
		var typed := Dictionary(candidate)
		if feature_overlaps_rect(_field, Rect2(typed["rect"])):
			continue
		result.append(typed)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return result


static func _rects_for_ids(ids: Array[StringName]) -> Array[Rect2]:
	var by_id := {}
	for candidate in Array(_field["cover_candidates"]):
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
		if _circle_overlaps_rect(
			Vector2(_field["player_start"]), float(_field["start_clearance"]), cover
		):
			errors.append("cover %d breaches center clearance" % index)
		for water in _water_rects():
			if _rect_distance(cover, water) < COVER_CLEARANCE:
				errors.append("cover %d is too close to water" % index)
		if feature_overlaps_rect(_field, cover):
			errors.append("cover %d overlaps functional terrain" % index)
		for other_index in range(index + 1, covers.size()):
			if _rect_distance(cover, covers[other_index]) < COVER_CLEARANCE:
				errors.append("covers %d and %d are too close" % [index, other_index])
	return errors


static func _valid_reachable_points(
	candidates: Array[Vector2],
	radius: float,
	covers: Array[Rect2],
	enforce_center_clearance: bool
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var reachable := _reachable_cells(Vector2(_field["player_start"]), radius, covers)
	for candidate in candidates:
		if (
			enforce_center_clearance
			and candidate.distance_to(Vector2(_field["player_start"])) < float(_field["start_clearance"])
		):
			continue
		if (
			_is_walkable(candidate, radius, covers)
			and not feature_overlaps_circle(_field, candidate, radius)
			and _reachable_has(reachable, candidate)
		):
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
	if feature_overlaps_circle(_field, candidate, SOCKET_FEATURE_RADIUS):
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


static func _is_valid_support_socket(
	candidate: Vector2,
	item_sockets: Array[Vector2],
	stationary: Array[Vector2],
	selected: Array[Vector2],
	covers: Array[Rect2],
	ordinary_reachable: Dictionary,
	boss_reachable: Dictionary
) -> bool:
	if (
		candidate.distance_to(Vector2(_field["player_start"]))
		< float(_field["start_clearance"])
	):
		return false
	if not _is_walkable(candidate, TerrainRuntime.OVERDRIVE_RADIUS, covers):
		return false
	if not _point_has_cover_clearance(
		candidate,
		TerrainRuntime.OVERDRIVE_RADIUS,
		covers
	):
		return false
	if feature_overlaps_circle(
		_field, candidate, TerrainRuntime.OVERDRIVE_RADIUS
	):
		return false
	if (
		not _reachable_has(ordinary_reachable, candidate)
		or not _reachable_has(boss_reachable, candidate)
	):
		return false
	for hostile in stationary:
		if candidate.distance_to(hostile) < TerrainRuntime.OVERDRIVE_RADIUS:
			return false
	for item in item_sockets:
		if candidate.is_equal_approx(item):
			return false
	for other in selected:
		if candidate.distance_to(other) < TerrainRuntime.OVERDRIVE_RADIUS:
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
	var blockers := covers.duplicate()
	blockers.append_array(_intact_bulkhead_rects())
	for cover in blockers:
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


static func _intact_bulkhead_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for value in Array(_field.get("features", [])):
		var feature := Dictionary(value)
		if StringName(feature.get("kind", &"")) == &"breakable_bulkhead":
			result.append(Rect2(feature["rect"]))
	return result


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
	var bounds := Rect2(_field["world_rect"])
	var width := ceili(bounds.size.x / GRID_SIZE)
	var height := ceili(bounds.size.y / GRID_SIZE)
	var walkable := PackedByteArray()
	walkable.resize(width * height)
	for y in height:
		for x in width:
			var point := _cell_center(Vector2i(x, y))
			if bounds.has_point(point) and _is_static_walkable(point, radius):
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


static func _validate_feature_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var features: Array = _field.get("features", [])
	var start := Vector2(_field["player_start"])
	var start_clearance := float(_field["start_clearance"])
	for index in features.size():
		var feature := Dictionary(features[index])
		var feature_id := String(feature.get("id", "feature_%d" % index))
		if _feature_has_rect(feature):
			var rectangle := Rect2(feature["rect"])
			if not _rect_inside_floor_union(rectangle):
				errors.append("%s leaves the walkable floor" % feature_id)
			for water in _water_rects():
				if rectangle.intersects(water, true):
					errors.append("%s overlaps water" % feature_id)
		else:
			var radius := _feature_radius(feature)
			var position := Vector2(feature.get("pos", Vector2.ZERO))
			if radius <= 0.0:
				errors.append("%s has no reserved footprint" % feature_id)
			elif not _circle_inside_floor_union(position, radius):
				errors.append("%s leaves the walkable floor" % feature_id)
			for water in _water_rects():
				if _circle_overlaps_rect(position, radius, water):
					errors.append("%s overlaps water" % feature_id)
		if _single_feature_overlaps_circle(feature, start, start_clearance):
			errors.append("%s breaches player start clearance" % feature_id)
		for other_index in range(index + 1, features.size()):
			var other := Dictionary(features[other_index])
			if _features_overlap(feature, other):
				errors.append(
					"%s overlaps %s" % [
						feature_id,
						String(other.get("id", "feature_%d" % other_index)),
					]
				)
	return errors


static func _features_overlap(first: Dictionary, second: Dictionary) -> bool:
	if _feature_has_rect(first):
		return (
			Rect2(first["rect"]).intersects(Rect2(second["rect"]), true)
			if _feature_has_rect(second)
			else _single_feature_overlaps_rect(second, Rect2(first["rect"]))
		)
	if _feature_has_rect(second):
		return _single_feature_overlaps_rect(first, Rect2(second["rect"]))
	return (
		Vector2(first["pos"]).distance_to(Vector2(second["pos"]))
		< _feature_radius(first) + _feature_radius(second)
	)


static func _single_feature_overlaps_circle(
	feature: Dictionary,
	position: Vector2,
	radius: float
) -> bool:
	if _feature_has_rect(feature):
		return _circle_overlaps_rect(position, radius, Rect2(feature["rect"]))
	return (
		Vector2(feature.get("pos", Vector2.ZERO)).distance_to(position)
		< _feature_radius(feature) + radius
	)


static func _single_feature_overlaps_rect(
	feature: Dictionary,
	rectangle: Rect2
) -> bool:
	if _feature_has_rect(feature):
		return Rect2(feature["rect"]).intersects(rectangle, true)
	return _circle_overlaps_rect(
		Vector2(feature.get("pos", Vector2.ZERO)),
		_feature_radius(feature),
		rectangle
	)


static func _feature_has_rect(feature: Dictionary) -> bool:
	return feature.has("rect") and Rect2(feature["rect"]).has_area()


static func _feature_radius(feature: Dictionary) -> float:
	match StringName(feature.get("kind", &"")):
		&"transit_gate":
			return TerrainRuntime.GATE_RADIUS
		&"repair_basin":
			return TerrainRuntime.REPAIR_RADIUS
		&"overdrive_field":
			return TerrainRuntime.OVERDRIVE_RADIUS
	return 0.0


static func _water_rects() -> Array[Rect2]:
	if _water_rects_cache.is_empty():
		for value in Array(_field["water_rects"]):
			_water_rects_cache.append(Rect2(value))
	return _water_rects_cache


static func _walkable_rects() -> Array[Rect2]:
	if _walkable_rects_cache.is_empty():
		for region in Array(_field["walkable_regions"]):
			_walkable_rects_cache.append(Rect2(region["rect"]))
	return _walkable_rects_cache


static func _configure_field(definition: Dictionary) -> void:
	_field = definition.duplicate(true)
	_walkable_rects_cache.clear()
	_water_rects_cache.clear()
	_grid_cache_by_radius.clear()


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
