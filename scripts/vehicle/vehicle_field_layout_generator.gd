class_name VehicleFieldLayoutGenerator
extends RefCounted

## Builds one bounded field variant before play and rejects invalid placements.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Layout = preload("res://scripts/vehicle/vehicle_field_layout.gd")
const TacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")

const GRID_SIZE := 96.0
const ORDINARY_RADIUS := 36.0
const BOSS_RADIUS := 76.0
const INNER_WALL_GROUP_COUNT := 5
const MYSTERY_DEVICE_COUNT := 3
const WALL_CLEARANCE := 384.0
const DEVICE_PAIR_CLEARANCE := 960.0
const REPAIR_HEAL_MIN := 40.0
const REPAIR_HEAL_MAX := 50.0

static var _field: Dictionary = {}
static var _walkable_rects_cache: Array[Rect2] = []
static var _void_rects_cache: Array[Rect2] = []
static var _grid_cache_by_radius: Dictionary = {}
static var _reachable_cache_by_radius: Dictionary = {}
static var _scatter_candidates_cache: Array[Vector2] = []


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
	var base_definition := FieldRegistry.definition(field_id)
	_configure_field(base_definition)
	var generated_features := _build_run_features(layout_seed)
	if generated_features.is_empty():
		push_error("Field structure placement could not compile %s" % _field["id"])
		return null
	var combined_features: Array = Array(_field.get("features", [])).duplicate(true)
	combined_features.append_array(generated_features)
	_field["features"] = combined_features
	var feature_errors := _validate_feature_contract()
	if not feature_errors.is_empty():
		push_error("Field features are invalid: %s" % "; ".join(feature_errors))
		return null
	var layouts_by_stage := _build_shared_stage_layouts(
		layout_seed,
		stage_ids
	)
	if layouts_by_stage.size() != stage_ids.size():
		# A rejected seeded scatter falls back to the field's fixed, audited layout.
		_configure_field(base_definition)
		var fallback_features := _fallback_run_features(layout_seed)
		if fallback_features.is_empty():
			push_error("Field layout could not compile %s" % _field["id"])
			return null
		var fallback_combined: Array = Array(_field.get("features", [])).duplicate(true)
		fallback_combined.append_array(fallback_features)
		_field["features"] = fallback_combined
		layouts_by_stage = _build_shared_stage_layouts(layout_seed, stage_ids)
		if layouts_by_stage.size() != stage_ids.size():
			# Preserve the previously audited completion guarantee if none of the
			# seed-specific fallback candidates leaves enough stage-object space.
			_configure_field(base_definition)
			var canonical_features := _canonical_fallback_run_features()
			if canonical_features.is_empty():
				push_error("Field layout could not compile %s" % _field["id"])
				return null
			var canonical_combined: Array = Array(_field.get("features", [])).duplicate(true)
			canonical_combined.append_array(canonical_features)
			_field["features"] = canonical_combined
			layouts_by_stage = _build_shared_stage_layouts(layout_seed, stage_ids)
			if layouts_by_stage.size() != stage_ids.size():
				push_error("Field layout could not compile %s" % _field["id"])
				return null
	var layout := Layout.new()
	layout.configure(
		layout_seed,
		StringName(_field["id"]),
		_field,
		layouts_by_stage
	)
	return layout


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


static func _build_shared_stage_layouts(
	layout_seed: int,
	stage_ids: Array[StringName]
) -> Dictionary:
	return _compile_stage_set(layout_seed, stage_ids)


static func _compile_stage_set(
	layout_seed: int,
	stage_ids: Array[StringName]
) -> Dictionary:
	var result := {}
	for stage_id in stage_ids:
		var tactical := _compile_stage_layout(
			layout_seed,
			stage_id
		)
		if tactical == null:
			return {}
		result[stage_id] = tactical
	return result


static func _build_run_features(layout_seed: int) -> Array[Dictionary]:
	for attempt in 1:
		var result: Array[Dictionary] = []
		result.assign(_try_build_run_features(_rng_for(layout_seed, "run-structure:%d" % attempt)))
		if not result.is_empty():
			return result
	return _fallback_run_features(layout_seed)


static func _try_build_run_features(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var candidates: Array = Array(_field["item_socket_candidates"]).duplicate()
	_shuffle(candidates, rng)
	var result: Array[Dictionary] = []
	var group_centers: Array[Vector2] = []
	var template_bag: Array[int] = [0, 1, 2, 3, 4, 5]
	_shuffle(template_bag, rng)
	for value in candidates:
		if group_centers.size() == INNER_WALL_GROUP_COUNT:
			break
		var center := _snap_to_grid(Vector2(value))
		var template := template_bag[group_centers.size() % template_bag.size()]
		var rectangles := _wall_template(center, template, rng.randi_range(0, 3))
		if not _wall_group_valid(rectangles, result, group_centers):
			continue
		for rect in rectangles:
			result.append({
				"id":"inner_wall_%02d_%02d" % [group_centers.size() + 1, result.size() + 1],
				"kind":&"structural_wall", "group":group_centers.size() + 1,
				"template":[&"i_short", &"i_long", &"l_small", &"l_large", &"t_small", &"step"][template], "rect":rect,
			})
		group_centers.append(center)
	if group_centers.size() != INNER_WALL_GROUP_COUNT:
		return []
	return result


static func _fallback_run_features(layout_seed: int) -> Array[Dictionary]:
	# Try seed-specific candidates first so ordinary fallback use does not collapse
	# distinct runs onto one shared wall layout.
	for attempt in 24:
		var result: Array[Dictionary] = []
		result.assign(_try_build_run_features(
			_rng_for(layout_seed, "run-structure:fallback:%d" % attempt)
		))
		if not result.is_empty():
			return result
	return _canonical_fallback_run_features()


static func _canonical_fallback_run_features() -> Array[Dictionary]:
	# Last-resort completion fixture retained from the audited pre-seeded fallback.
	for attempt in 24:
		var result: Array[Dictionary] = []
		result.assign(_try_build_run_features(
			_rng_for(0xC4A2B0, "run-structure:%d" % attempt)
		))
		if not result.is_empty():
			return result
	return []


static func _wall_template(center: Vector2, template: int, rotation: int) -> Array[Rect2]:
	var local: Array[Rect2] = []
	match template:
		0: local = [Rect2(-384,-96,768,192)]
		1: local = [Rect2(-576,-96,1152,192)]
		2: local = [Rect2(-384,-288,768,192), Rect2(192,-288,192,576)]
		3: local = [Rect2(-480,-384,960,192), Rect2(288,-384,192,768)]
		4: local = [Rect2(-480,-288,960,192), Rect2(-96,-288,192,576)]
		_: local = [Rect2(-480,-288,576,192), Rect2(-96,96,576,192)]
	var result: Array[Rect2] = []
	for rect in local:
		var rotated := _rotate_rect_90(rect, rotation)
		result.append(Rect2(rotated.position + center, rotated.size))
	return result


static func _rotate_rect_90(rect: Rect2, quarter_turns: int) -> Rect2:
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var rotated := Rect2()
	for index in corners.size():
		var point: Vector2 = corners[index].rotated(float(posmod(quarter_turns, 4)) * PI * 0.5)
		if index == 0: rotated = Rect2(point, Vector2.ZERO)
		else: rotated = rotated.expand(point)
	return rotated


static func _wall_group_valid(rectangles: Array[Rect2], features: Array[Dictionary], centers: Array[Vector2]) -> bool:
	for rect in rectangles:
		if not _rect_inside_floor_union(rect) or _circle_overlaps_rect(Vector2(_field["player_start"]), float(_field["start_clearance"]), rect):
			return false
		for feature in Array(_field.get("features", [])) + features:
			if _single_feature_overlaps_rect(Dictionary(feature), rect):
				return false
	for feature in features:
		if StringName(feature.get("kind", &"")) != &"structural_wall": continue
		for rect in rectangles:
			if _rect_distance(rect, Rect2(feature["rect"])) < WALL_CLEARANCE:
				return false
	return true


static func _snap_to_grid(point: Vector2) -> Vector2:
	return Vector2(roundi(point.x / GRID_SIZE) * GRID_SIZE, roundi(point.y / GRID_SIZE) * GRID_SIZE)


static func _compile_stage_layout(
	layout_seed: int,
	stage_id: StringName
) -> TacticalLayout:
	var ordinary := _valid_reachable_points(
		_field["ordinary_spawn_anchors"], ORDINARY_RADIUS, true
	)
	var bosses := _valid_reachable_points(
		_field["boss_arrival_anchors"], BOSS_RADIUS, false
	)
	if ordinary.size() < 20 or bosses.size() < 8:
		return null
	var stage_objects := _build_stage_objects(
		layout_seed, stage_id
	)
	if stage_objects.is_empty():
		return null
	var layout := TacticalLayout.new()
	layout.configure(
		stage_id,
		_field,
		[],
		[],
		ordinary,
		bosses,
		stage_objects,
		_sub_seed(layout_seed, "%s:encounter:v2" % String(stage_id)),
		false
	)
	return layout


static func _build_stage_objects(layout_seed: int, stage_id: StringName) -> Dictionary:
	for attempt in 2:
		var generated := _try_build_stage_objects(
			_rng_for(layout_seed, "%s:scatter:%d" % [String(stage_id), attempt]),
			stage_id
		)
		if not generated.is_empty():
			return generated
	return _try_build_stage_objects(
		_rng_for(layout_seed, "%s:scatter-fallback" % String(stage_id)),
		stage_id
	)


static func _try_build_stage_objects(
	rng: RandomNumberGenerator,
	stage_id: StringName
) -> Dictionary:
	var reachable := _reachable_cells(Vector2(_field["player_start"]), ORDINARY_RADIUS)
	var candidates: Array = _stage_scatter_candidates()
	_shuffle(candidates, rng)
	var devices: Array[Dictionary] = []
	var reward_pickup_positions: Array[Vector2] = []
	var pickup_positions: Array[Vector2] = []
	for value in candidates:
		if devices.size() == MYSTERY_DEVICE_COUNT:
			break
		var point := _snap_to_grid(Vector2(value))
		if not _stage_point_valid(point, reachable, devices, reward_pickup_positions, pickup_positions, &"mystery_device"):
			continue
		devices.append({
			"id":"%s_mystery_%02d" % [String(stage_id), devices.size() + 1],
			"pos":point,
		})
	for value in candidates:
		if reward_pickup_positions.size() == 8:
			break
		var point := _snap_to_grid(Vector2(value))
		if _stage_point_valid(point, reachable, devices, reward_pickup_positions, pickup_positions, &"reward_pickup"):
			reward_pickup_positions.append(point)
	for value in candidates:
		if pickup_positions.size() == 6:
			break
		var point := _snap_to_grid(Vector2(value))
		if _stage_point_valid(point, reachable, devices, reward_pickup_positions, pickup_positions, &"pickup"):
			pickup_positions.append(point)
	if devices.size() != MYSTERY_DEVICE_COUNT or reward_pickup_positions.size() != 8 or pickup_positions.size() != 6:
		return {}
	_prioritize_separated_recalls(reward_pickup_positions, pickup_positions)
	var pickups: Array[Dictionary] = []
	for index in 6:
		pickups.append({
			"id":"%s_pickup_%02d" % [String(stage_id), index + 1],
			"kind":&"experience_recall" if index < 2 else &"repair",
			"heal_amount":0.0 if index < 2 else REPAIR_HEAL_MAX,
			"pos":pickup_positions[index],
		})
	for index in 8:
		var recall := index < 2
		pickups.append({
			"id":"%s_pickup_%02d" % [String(stage_id), index + 7],
			"kind":&"experience_recall" if recall else &"repair",
			"heal_amount":0.0 if recall else (
				REPAIR_HEAL_MIN if index == 7 else REPAIR_HEAL_MAX
			),
			"pos":reward_pickup_positions[index],
		})
	return {"mystery_devices":devices, "pickups":pickups}


static func _prioritize_separated_recalls(
	reward_pickup_positions: Array[Vector2],
	pickup_positions: Array[Vector2]
) -> void:
	var reward_pickup_index := 0
	var pickup_index := 0
	var greatest_distance := -1.0
	for reward_pickup in reward_pickup_positions.size():
		for pickup in pickup_positions.size():
			var distance := reward_pickup_positions[reward_pickup].distance_squared_to(pickup_positions[pickup])
			if distance > greatest_distance:
				greatest_distance = distance
				reward_pickup_index = reward_pickup
				pickup_index = pickup
	var reward_pickup_first := reward_pickup_positions[0]
	reward_pickup_positions[0] = reward_pickup_positions[reward_pickup_index]
	reward_pickup_positions[reward_pickup_index] = reward_pickup_first
	var pickup_first := pickup_positions[0]
	pickup_positions[0] = pickup_positions[pickup_index]
	pickup_positions[pickup_index] = pickup_first


static func _stage_scatter_candidates() -> Array:
	if not _scatter_candidates_cache.is_empty():
		return _scatter_candidates_cache.duplicate()
	var seen := {}
	for value in Array(_field["item_socket_candidates"]):
		var point := _snap_to_grid(Vector2(value))
		seen[point] = true
	for y in range(576, 3840, 576):
		for x in range(576, 6720, 576):
			var point := Vector2(x, y)
			if _circle_inside_floor_union(point, 54.0):
				seen[point] = true
	for value in seen:
		_scatter_candidates_cache.append(Vector2(value))
	_scatter_candidates_cache.sort_custom(
		func(first: Vector2, second: Vector2) -> bool:
			return first.x < second.x or (is_equal_approx(first.x, second.x) and first.y < second.y)
	)
	return _scatter_candidates_cache.duplicate()


static func _stage_point_valid(
	point: Vector2,
	reachable: Dictionary,
	devices: Array,
	reward_pickup_positions: Array[Vector2],
	pickup_positions: Array[Vector2],
	kind: StringName
) -> bool:
	if not _is_walkable(point, 54.0) or not _reachable_has(reachable, point):
		return false
	if feature_overlaps_circle(_field, point, 54.0):
		return false
	for device in devices:
		var device_clearance := DEVICE_PAIR_CLEARANCE if kind == &"mystery_device" else (576.0 if kind == &"reward_pickup" else 480.0)
		if point.distance_to(Vector2(Dictionary(device)["pos"])) < device_clearance:
			return false
	for reward_pickup in reward_pickup_positions:
		var reward_pickup_clearance := 672.0 if kind == &"reward_pickup" else 384.0
		if point.distance_to(reward_pickup) < reward_pickup_clearance:
			return false
	for pickup in pickup_positions:
		if point.distance_to(pickup) < 384.0:
			return false
	for feature_value in Array(_field.get("features", [])):
		var feature := Dictionary(feature_value)
		if kind == &"mystery_device" and StringName(feature.get("kind", &"")) == &"transit_gate" and point.distance_to(Vector2(feature["pos"])) < 576.0:
			return false
	return true


static func _valid_reachable_points(
	candidates: Array[Vector2],
	radius: float,
	enforce_center_clearance: bool
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var reachable := _reachable_cells(Vector2(_field["player_start"]), radius)
	for candidate in candidates:
		if (
			enforce_center_clearance
			and candidate.distance_to(Vector2(_field["player_start"])) < float(_field["start_clearance"])
		):
			continue
		if (
			_is_walkable(candidate, radius)
			and not feature_overlaps_circle(_field, candidate, radius)
			and _reachable_has(reachable, candidate)
		):
			result.append(candidate)
	return result


static func _is_walkable(position: Vector2, radius: float) -> bool:
	if not _circle_inside_floor_union(position, radius):
		return false
	for void_rect in _void_rects():
		if _circle_overlaps_rect(position, radius, void_rect):
			return false
	return true


static func _reachable_cells(
	start: Vector2,
	radius: float
) -> Dictionary:
	if _reachable_cache_by_radius.has(roundi(radius)):
		return _reachable_cache_by_radius[roundi(radius)]
	var contract := _grid_contract(radius)
	var width := int(contract["width"])
	var height := int(contract["height"])
	var allowed: PackedByteArray = PackedByteArray(contract["walkable"]).duplicate()
	for wall in _structural_wall_rects():
		var min_cell := _world_to_cell(wall.position - Vector2.ONE * radius)
		var max_cell := _world_to_cell(wall.end + Vector2.ONE * radius)
		for y in range(maxi(0, min_cell.y), mini(height - 1, max_cell.y) + 1):
			for x in range(maxi(0, min_cell.x), mini(width - 1, max_cell.x) + 1):
				var index := y * width + x
				if allowed[index] == 1 and _circle_overlaps_rect(_cell_center(Vector2i(x, y)), radius, wall):
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
	var result := {"width":width, "height":height, "visited":visited}
	_reachable_cache_by_radius[roundi(radius)] = result
	return result
static func _structural_wall_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for value in Array(_field.get("features", [])):
		var feature := Dictionary(value)
		if StringName(feature.get("kind", &"")) == &"structural_wall":
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
	for void_rect in _void_rects():
		if _circle_overlaps_rect(position, radius, void_rect):
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
			for void_rect in _void_rects():
				if rectangle.intersects(void_rect, true):
					errors.append("%s overlaps void" % feature_id)
		else:
			var radius := _feature_radius(feature)
			var position := Vector2(feature.get("pos", Vector2.ZERO))
			if radius <= 0.0:
				errors.append("%s has no reserved footprint" % feature_id)
			elif not _circle_inside_floor_union(position, radius):
				errors.append("%s leaves the walkable floor" % feature_id)
			for void_rect in _void_rects():
				if _circle_overlaps_rect(position, radius, void_rect):
					errors.append("%s overlaps void" % feature_id)
		if _single_feature_overlaps_circle(feature, start, start_clearance):
			errors.append("%s breaches player start clearance" % feature_id)
		for other_index in range(index + 1, features.size()):
			var other := Dictionary(features[other_index])
			if (
				StringName(feature.get("kind", &"")) == &"structural_wall"
				and StringName(other.get("kind", &"")) == &"structural_wall"
				and int(feature.get("group", -1)) == int(other.get("group", -2))
			):
				continue
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
			Rect2(first["rect"]).intersects(Rect2(second["rect"]), false)
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
			return 96.0
	return 0.0


static func _void_rects() -> Array[Rect2]:
	if _void_rects_cache.is_empty():
		for value in Array(_field["void_rects"]):
			_void_rects_cache.append(Rect2(value))
	return _void_rects_cache


static func _walkable_rects() -> Array[Rect2]:
	if _walkable_rects_cache.is_empty():
		for region in Array(_field["walkable_regions"]):
			_walkable_rects_cache.append(Rect2(region["rect"]))
	return _walkable_rects_cache


static func _configure_field(definition: Dictionary) -> void:
	var geometry_changed := _field.is_empty() or StringName(_field.get("id", &"")) != StringName(definition.get("id", &""))
	_field = definition.duplicate(true)
	_reachable_cache_by_radius.clear()
	if geometry_changed:
		_walkable_rects_cache.clear()
		_void_rects_cache.clear()
		_grid_cache_by_radius.clear()
		_scatter_candidates_cache.clear()


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
