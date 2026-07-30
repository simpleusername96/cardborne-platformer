class_name VehicleStageCatalog
extends RefCounted

## Validated facade joining the active run field with five combat profiles.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Geometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")

const STAGE_IDS: Array[StringName] = CombatStages.STAGE_IDS
const REQUIRED_FIELDS := [
	"id", "field_id", "title_key", "number", "boss_name_key", "quota",
	"world_rect", "player_start", "start_clearance", "walkable_regions",
	"cover_rects", "void_rects", "ordinary_spawn_anchors",
	"boss_arrival_anchors", "static_enemies", "packets",
]

static var _active_field_id: StringName = FieldRegistry.FIELD_IDS[0]
static var _active_field: Dictionary = FieldRegistry.definition(_active_field_id)
static var _definition_cache: Dictionary = {}
static var _definition_build_counts: Dictionary = {}
static var _walkable_rect_cache: Array[Rect2] = []
static var _cover_rect_cache: Array[Rect2] = []
static var _void_rect_cache: Array[Rect2] = []
static var _floor_polygon_cache: Array = []
static var _cover_polygon_cache: Array = []
static var _void_polygon_cache: Array = []
static var _floor_cells: Dictionary = {}
static var _cover_cells: Dictionary = {}
static var _void_cells: Dictionary = {}
static var _safe_motion_cells_36: Dictionary = {}
static var _spatial_cache_ready := false

const COLLISION_CELL_SIZE := 80.0
const COLLISION_CACHE_MARGIN := 96.0


static func normalized_id(stage_id: StringName) -> StringName:
	return CombatStages.normalized_id(stage_id)


static func index_of(stage_id: StringName) -> int:
	return CombatStages.index_of(stage_id)


static func definition(stage_id: StringName) -> Dictionary:
	var normalized := normalized_id(stage_id)
	if _definition_cache.has(normalized):
		return _definition_cache[normalized]
	var result := CombatStages.definition(normalized, _active_field)
	var errors := validate_definition(result, normalized)
	if not errors.is_empty():
		push_error("Registered combat stage %s is invalid: %s" % [normalized, "; ".join(errors)])
		return {}
	_definition_cache[normalized] = result
	_definition_build_counts[normalized] = int(_definition_build_counts.get(normalized, 0)) + 1
	return result


static func validate_definition(value: Dictionary, expected_id: StringName = &"") -> PackedStringArray:
	var errors := PackedStringArray()
	for field in REQUIRED_FIELDS:
		if not value.has(field):
			errors.append("missing %s" % field)
	if not errors.is_empty():
		return errors
	if not expected_id.is_empty() and StringName(value["id"]) != expected_id:
		errors.append("id does not match registry")
	if StringName(value["field_id"]) != _active_field_id:
		errors.append("stage does not reference the shared field")
	if Rect2(value["world_rect"]) != Rect2(_active_field["world_rect"]):
		errors.append("world_rect differs from the shared field")
	if Vector2(value["player_start"]) != Vector2(_active_field["player_start"]):
		errors.append("player_start differs from the shared center")
	if int(value["quota"]) <= 0:
		errors.append("quota must be positive")
	if not value["walkable_regions"] is Array or value["walkable_regions"].is_empty():
		errors.append("walkable_regions must not be empty")
	if Array(value["ordinary_spawn_anchors"]).size() != 32:
		errors.append("field requires thirty-two ordinary spawn candidates")
	if Array(value["boss_arrival_anchors"]).size() != 12:
		errors.append("field requires twelve boss arrival anchors")
	return errors


static func profile(stage_id: StringName) -> Dictionary:
	return CombatStages.profile(stage_id, _active_field_id)


static func field_id(_stage_id: StringName = &"stage_1") -> StringName:
	return _active_field_id


static func world_rect(_stage_id: StringName = &"stage_1") -> Rect2:
	return Rect2(_active_field["world_rect"])


static func player_start(_stage_id: StringName = &"stage_1") -> Vector2:
	return Vector2(_active_field["player_start"])


static func start_clearance(_stage_id: StringName = &"stage_1") -> float:
	return float(_active_field["start_clearance"])


static func quota(stage_id: StringName) -> int:
	return int(profile(stage_id)["quota"])


static func ordinary_spawn_anchors(_stage_id: StringName = &"stage_1") -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.assign(_active_field["ordinary_spawn_anchors"])
	return result


static func boss_arrival_anchors(_stage_id: StringName = &"stage_1") -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.assign(_active_field["boss_arrival_anchors"])
	return result


static func walkable_regions(_stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in definition(&"stage_1")["walkable_regions"]:
		result.append(Dictionary(region).duplicate(true))
	return result


static func walkable_rects(_stage_id: StringName = &"stage_1") -> Array[Rect2]:
	if _walkable_rect_cache.is_empty():
		for region in definition(&"stage_1")["walkable_regions"]:
			_walkable_rect_cache.append(Rect2(region["rect"]))
	return _walkable_rect_cache


static func floor_polygons(_stage_id: StringName = &"stage_1") -> Array:
	if _floor_polygon_cache.is_empty():
		for region in definition(&"stage_1")["walkable_regions"]:
			_floor_polygon_cache.append(Geometry.rect_polygon(Rect2(region["rect"])))
	return _floor_polygon_cache


static func cover_rects(_stage_id: StringName = &"stage_1") -> Array[Rect2]:
	if _cover_rect_cache.is_empty():
		for rect in definition(&"stage_1")["cover_rects"]:
			_cover_rect_cache.append(Rect2(rect))
	return _cover_rect_cache


static func cover_polygons(_stage_id: StringName = &"stage_1") -> Array:
	if _cover_polygon_cache.is_empty():
		for rect in cover_rects():
			_cover_polygon_cache.append(Geometry.rect_polygon(rect))
	return _cover_polygon_cache


static func void_rects(_stage_id: StringName = &"stage_1") -> Array[Rect2]:
	if _void_rect_cache.is_empty():
		for rect in definition(&"stage_1")["void_rects"]:
			_void_rect_cache.append(Rect2(rect))
	return _void_rect_cache


static func void_polygons(_stage_id: StringName = &"stage_1") -> Array:
	if _void_polygon_cache.is_empty():
		for rect in void_rects():
			_void_polygon_cache.append(Geometry.rect_polygon(rect))
	return _void_polygon_cache


static func floor_regions(stage_id: StringName, colors: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in walkable_regions(stage_id):
		var tone := StringName(region.get("tone", &"mid"))
		result.append({
			"id":region.get("id", "floor"),
			"name":region.get("name", "Floor"),
			"rect":Rect2(region["rect"]),
			"polygon":Geometry.rect_polygon(Rect2(region["rect"])),
			"color":colors.get(tone, colors["mid"]),
		})
	return result


static func position_is_walkable(stage_id: StringName, position: Vector2, radius: float = 0.0) -> bool:
	var floor_rectangles := _nearby_rects(_floor_cells, position, stage_id)
	if radius > COLLISION_CACHE_MARGIN:
		floor_rectangles = walkable_rects(stage_id)
	if not _point_in_any_rect(position, floor_rectangles):
		return false
	if radius > 0.0:
		# Most actors are wholly inside one authored rectangle. Resolve that exact
		# common case before sampling only the overlapping seams of the union.
		for rectangle in floor_rectangles:
			if position.x - radius >= rectangle.position.x and position.x + radius <= rectangle.end.x \
					and position.y - radius >= rectangle.position.y and position.y + radius <= rectangle.end.y:
				return not _circle_overlaps_any_rect(position, radius, void_rects(stage_id))
		for sample_index in Geometry.CIRCLE_UNION_SAMPLES:
			var sample := position + Vector2.RIGHT.rotated(TAU * float(sample_index) / float(Geometry.CIRCLE_UNION_SAMPLES)) * radius * 0.999
			var sample_rectangles := _nearby_rects(_floor_cells, sample, stage_id)
			if not _point_in_any_rect(sample, sample_rectangles):
				return false
	var nearby_void := _nearby_rects(_void_cells, position, stage_id)
	if radius > COLLISION_CACHE_MARGIN:
		nearby_void = void_rects(stage_id)
	for void_rect in nearby_void:
		if _circle_overlaps_rect(position, radius, void_rect):
			return false
	return true


static func circle_overlaps_cover(stage_id: StringName, position: Vector2, radius: float) -> bool:
	var nearby_cover := _nearby_rects(_cover_cells, position, stage_id)
	if radius > COLLISION_CACHE_MARGIN:
		nearby_cover = cover_rects(stage_id)
	return _circle_overlaps_any_rect(position, radius, nearby_cover)


static func cover_rects_near_motion(stage_id: StringName, from: Vector2, to: Vector2, radius: float) -> Array:
	# A short swept circle can only touch rectangles registered around its
	# midpoint. Long traces retain the complete authored-cover fallback.
	if from.distance_to(to) * 0.5 + radius > COLLISION_CACHE_MARGIN:
		return cover_rects(stage_id)
	return _nearby_rects(_cover_cells, (from + to) * 0.5, stage_id)


static func motion_may_touch_cover(stage_id: StringName, from: Vector2, to: Vector2, radius: float) -> bool:
	var swept_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	for value in cover_rects_near_motion(stage_id, from, to, radius):
		if swept_bounds.intersects(Rect2(value).grow(radius), true):
			return true
	return false


static func is_fast_motion_clear(stage_id: StringName, from: Vector2, to: Vector2, radius: float) -> bool:
	if radius > 36.0:
		return false
	_ensure_spatial_cache()
	var from_cell := Vector2i(floori(from.x / COLLISION_CELL_SIZE), floori(from.y / COLLISION_CELL_SIZE))
	var to_cell := Vector2i(floori(to.x / COLLISION_CELL_SIZE), floori(to.y / COLLISION_CELL_SIZE))
	return from_cell == to_cell and bool(_safe_motion_cells_36.get(from_cell, false))


static func _nearby_rects(cache: Dictionary, position: Vector2, _stage_id: StringName) -> Array:
	_ensure_spatial_cache()
	var cell := Vector2i(floori(position.x / COLLISION_CELL_SIZE), floori(position.y / COLLISION_CELL_SIZE))
	return cache.get(cell, [])


static func _ensure_spatial_cache() -> void:
	if _spatial_cache_ready:
		return
	_register_rects(_floor_cells, walkable_rects())
	_register_rects(_cover_cells, cover_rects())
	_register_rects(_void_cells, void_rects())
	_build_safe_motion_cells()
	_spatial_cache_ready = true


static func _register_rects(cache: Dictionary, rectangles: Array[Rect2]) -> void:
	for rectangle in rectangles:
		var expanded := rectangle.grow(COLLISION_CACHE_MARGIN)
		var min_cell := Vector2i(
			floori(expanded.position.x / COLLISION_CELL_SIZE),
			floori(expanded.position.y / COLLISION_CELL_SIZE)
		)
		var max_cell := Vector2i(
			floori(expanded.end.x / COLLISION_CELL_SIZE),
			floori(expanded.end.y / COLLISION_CELL_SIZE)
		)
		for y in range(min_cell.y, max_cell.y + 1):
			for x in range(min_cell.x, max_cell.x + 1):
				var cell := Vector2i(x, y)
				if not cache.has(cell):
					cache[cell] = []
				var bucket: Array = cache[cell]
				bucket.append(rectangle)


static func _build_safe_motion_cells() -> void:
	var bounds := world_rect()
	var min_cell := Vector2i(
		floori(bounds.position.x / COLLISION_CELL_SIZE),
		floori(bounds.position.y / COLLISION_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori((bounds.end.x - 1.0) / COLLISION_CELL_SIZE),
		floori((bounds.end.y - 1.0) / COLLISION_CELL_SIZE)
	)
	var floors := walkable_rects()
	var covers := cover_rects()
	var voids := void_rects()
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(Vector2(cell) * COLLISION_CELL_SIZE, Vector2.ONE * COLLISION_CELL_SIZE)
			var clearance_rect := cell_rect.grow(36.0)
			var inside_floor := false
			for floor_rect in floors:
				if floor_rect.encloses(clearance_rect):
					inside_floor = true
					break
			if not inside_floor:
				continue
			var blocked := false
			for cover in covers:
				if clearance_rect.intersects(cover, true):
					blocked = true
					break
			if blocked:
				continue
			for void_rect in voids:
				if clearance_rect.intersects(void_rect, true):
					blocked = true
					break
			if not blocked:
				_safe_motion_cells_36[cell] = true


static func _point_in_any_rect(point: Vector2, rectangles: Array) -> bool:
	for rectangle in rectangles:
		if rectangle.has_point(point):
			return true
	return false


static func _circle_overlaps_rect(center: Vector2, radius: float, rectangle: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rectangle.position.x, rectangle.end.x),
		clampf(center.y, rectangle.position.y, rectangle.end.y)
	)
	return center.distance_squared_to(closest) < radius * radius


static func _circle_overlaps_any_rect(center: Vector2, radius: float, rectangles: Array) -> bool:
	for rectangle in rectangles:
		if _circle_overlaps_rect(center, radius, rectangle):
			return true
	return false


static func static_enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(stage_id)["static_enemies"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func packets(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for packet in definition(stage_id)["packets"]:
		result.append(Dictionary(packet).duplicate(true))
	return result


static func packet_enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for packet in packets(stage_id):
		var packet_id := String(packet["id"])
		var anchor := player_start()
		for squad_index in Array(packet["squads"]).size():
			var squad: Array = packet["squads"][squad_index]
			for unit_index in squad.size():
				result.append({
					"id":"%s_s%02d_u%02d" % [packet_id, squad_index + 1, unit_index + 1],
					"role":StringName(squad[unit_index]), "pos":anchor, "zone":"field",
					"group_id":"%s_s%02d" % [packet_id, squad_index + 1],
					"formation_anchor":anchor, "leash_rect":world_rect(),
				})
	return result


static func enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result := static_enemy_blueprint(stage_id)
	result.append_array(packet_enemy_blueprint(stage_id))
	return result


static func authored_population(stage_id: StringName) -> int:
	return enemy_blueprint(stage_id).size()


static func geometry_fingerprint(_stage_id: StringName = &"stage_1") -> int:
	return hash(var_to_str([
		world_rect(), walkable_regions(), cover_rects(), void_rects(),
		_active_field["cover_candidates"], ordinary_spawn_anchors(), boss_arrival_anchors(),
		_active_field["stationary_candidates"], _active_field["item_socket_candidates"],
	]))


static func debug_cache_contract(stage_id: StringName) -> Dictionary:
	var normalized := normalized_id(stage_id)
	definition(normalized)
	definition(normalized)
	return {
		"stage_id":normalized,
		"field_id":_active_field_id,
		"definition_build_count":int(_definition_build_counts.get(normalized, 0)),
		"floor_count":floor_polygons().size(),
		"cover_count":cover_rects().size(),
		"void_count":void_rects().size(),
		"geometry_fingerprint":geometry_fingerprint(),
	}


static func activate_field(field_id_value: StringName) -> void:
	var normalized := FieldRegistry.normalized_id(field_id_value)
	if normalized == _active_field_id:
		return
	_active_field_id = normalized
	_active_field = FieldRegistry.definition(normalized)
	_clear_geometry_caches()


static func active_field_definition() -> Dictionary:
	return _active_field.duplicate(true)


static func _clear_geometry_caches() -> void:
	_definition_cache.clear()
	_definition_build_counts.clear()
	_walkable_rect_cache.clear()
	_cover_rect_cache.clear()
	_void_rect_cache.clear()
	_floor_polygon_cache.clear()
	_cover_polygon_cache.clear()
	_void_polygon_cache.clear()
	_floor_cells.clear()
	_cover_cells.clear()
	_void_cells.clear()
	_safe_motion_cells_36.clear()
	_spatial_cache_ready = false
