class_name VehicleStageCatalog
extends RefCounted

## Validated facade joining one immutable field with five combat profiles.

const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Geometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")

const STAGE_IDS: Array[StringName] = CombatStages.STAGE_IDS
const REQUIRED_FIELDS := [
	"id", "field_id", "title_key", "number", "boss_name_key", "quota",
	"world_rect", "player_start", "start_clearance", "walkable_regions",
	"cover_rects", "water_rects", "motifs", "ordinary_spawn_anchors",
	"boss_arrival_anchors", "stationary_anchors", "static_enemies", "pickups",
	"crates", "packets",
]

static var _definition_cache: Dictionary = {}
static var _definition_build_counts: Dictionary = {}
static var _walkable_rect_cache: Array[Rect2] = []
static var _cover_rect_cache: Array[Rect2] = []
static var _water_rect_cache: Array[Rect2] = []
static var _floor_polygon_cache: Array = []
static var _cover_polygon_cache: Array = []
static var _water_polygon_cache: Array = []


static func normalized_id(stage_id: StringName) -> StringName:
	return CombatStages.normalized_id(stage_id)


static func index_of(stage_id: StringName) -> int:
	return CombatStages.index_of(stage_id)


static func definition(stage_id: StringName) -> Dictionary:
	var normalized := normalized_id(stage_id)
	if _definition_cache.has(normalized):
		return _definition_cache[normalized]
	var result := CombatStages.definition(normalized)
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
	if StringName(value["field_id"]) != Field.FIELD_ID:
		errors.append("stage does not reference the shared field")
	if Rect2(value["world_rect"]) != Field.WORLD_RECT:
		errors.append("world_rect differs from the shared field")
	if Vector2(value["player_start"]) != Field.CENTER:
		errors.append("player_start differs from the shared center")
	if int(value["quota"]) <= 0:
		errors.append("quota must be positive")
	if not value["walkable_regions"] is Array or value["walkable_regions"].is_empty():
		errors.append("walkable_regions must not be empty")
	if Array(value["ordinary_spawn_anchors"]).size() != 16:
		errors.append("field requires sixteen ordinary spawn anchors")
	if Array(value["boss_arrival_anchors"]).size() != 8:
		errors.append("field requires eight boss arrival anchors")
	return errors


static func profile(stage_id: StringName) -> Dictionary:
	return CombatStages.profile(stage_id)


static func field_id(_stage_id: StringName = &"stage_1") -> StringName:
	return Field.FIELD_ID


static func world_rect(_stage_id: StringName = &"stage_1") -> Rect2:
	return Field.WORLD_RECT


static func player_start(_stage_id: StringName = &"stage_1") -> Vector2:
	return Field.CENTER


static func start_clearance(_stage_id: StringName = &"stage_1") -> float:
	return Field.START_CLEARANCE


static func quota(stage_id: StringName) -> int:
	return int(profile(stage_id)["quota"])


static func ordinary_spawn_anchors(_stage_id: StringName = &"stage_1") -> Array[Vector2]:
	return Field.ORDINARY_SPAWN_ANCHORS.duplicate()


static func boss_arrival_anchors(_stage_id: StringName = &"stage_1") -> Array[Vector2]:
	return Field.BOSS_ARRIVAL_ANCHORS.duplicate()


static func stationary_anchors(_stage_id: StringName = &"stage_1") -> Array[Vector2]:
	return Field.STATIONARY_ANCHORS.duplicate()


static func motifs(_stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for motif in definition(&"stage_1")["motifs"]:
		result.append(Dictionary(motif).duplicate(true))
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


static func water_rects(_stage_id: StringName = &"stage_1") -> Array[Rect2]:
	if _water_rect_cache.is_empty():
		for rect in definition(&"stage_1")["water_rects"]:
			_water_rect_cache.append(Rect2(rect))
	return _water_rect_cache


static func water_polygons(_stage_id: StringName = &"stage_1") -> Array:
	if _water_polygon_cache.is_empty():
		for rect in water_rects():
			_water_polygon_cache.append(Geometry.rect_polygon(rect))
	return _water_polygon_cache


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
	var floor_rectangles := walkable_rects(stage_id)
	if not _point_in_any_rect(position, floor_rectangles):
		return false
	if radius > 0.0:
		# Most actors are wholly inside one authored rectangle. Resolve that exact
		# common case before sampling only the overlapping seams of the union.
		for rectangle in floor_rectangles:
			if position.x - radius >= rectangle.position.x and position.x + radius <= rectangle.end.x \
					and position.y - radius >= rectangle.position.y and position.y + radius <= rectangle.end.y:
				return not _circle_overlaps_any_rect(position, radius, water_rects(stage_id))
		for sample_index in Geometry.CIRCLE_UNION_SAMPLES:
			var sample := position + Vector2.RIGHT.rotated(TAU * float(sample_index) / float(Geometry.CIRCLE_UNION_SAMPLES)) * radius * 0.999
			if not _point_in_any_rect(sample, floor_rectangles):
				return false
	for water in water_rects(stage_id):
		if _circle_overlaps_rect(position, radius, water):
			return false
	return true


static func _point_in_any_rect(point: Vector2, rectangles: Array[Rect2]) -> bool:
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


static func _circle_overlaps_any_rect(center: Vector2, radius: float, rectangles: Array[Rect2]) -> bool:
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
		var anchor := Vector2(packet["anchor"])
		for squad_index in Array(packet["squads"]).size():
			var squad: Array = packet["squads"][squad_index]
			for unit_index in squad.size():
				result.append({
					"id":"%s_s%02d_u%02d" % [packet_id, squad_index + 1, unit_index + 1],
					"role":StringName(squad[unit_index]), "pos":anchor, "zone":"field",
					"group_id":"%s_s%02d" % [packet_id, squad_index + 1],
					"formation_anchor":anchor, "leash_rect":Field.WORLD_RECT,
				})
	return result


static func enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result := static_enemy_blueprint(stage_id)
	result.append_array(packet_enemy_blueprint(stage_id))
	return result


static func authored_population(stage_id: StringName) -> int:
	return enemy_blueprint(stage_id).size()


static func pickup_blueprint(_stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(&"stage_1")["pickups"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func crate_blueprint(_stage_id: StringName = &"stage_1") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(&"stage_1")["crates"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func geometry_fingerprint(_stage_id: StringName = &"stage_1") -> int:
	return hash(var_to_str([
		Field.WORLD_RECT, walkable_regions(), cover_rects(), water_rects(), motifs(),
		ordinary_spawn_anchors(), boss_arrival_anchors(), stationary_anchors(),
	]))


static func debug_cache_contract(stage_id: StringName) -> Dictionary:
	var normalized := normalized_id(stage_id)
	definition(normalized)
	definition(normalized)
	return {
		"stage_id":normalized,
		"field_id":Field.FIELD_ID,
		"definition_build_count":int(_definition_build_counts.get(normalized, 0)),
		"floor_count":floor_polygons().size(),
		"cover_count":cover_rects().size(),
		"water_count":water_rects().size(),
		"geometry_fingerprint":geometry_fingerprint(),
	}
