class_name VehicleStageCatalog
extends RefCounted

## Validated facade over responsibility-shaped authored stage definitions.
## Runtime consumers never silently receive a partial registered stage.

const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const FloodedWorks = preload("res://scripts/vehicle/stages/flooded_works.gd")
const TidalArchive = preload("res://scripts/vehicle/stages/tidal_archive.gd")
const StormDrydock = preload("res://scripts/vehicle/stages/storm_drydock.gd")

const STAGE_IDS: Array[StringName] = [&"flooded_works", &"tidal_archive", &"storm_drydock"]
const REQUIRED_FIELDS := [
	"id", "title_key", "number", "field_boss_name_key", "boss_name_key", "environment",
	"world_rect", "player_start", "start_clearance", "boss_arena", "boss_gate",
	"walkable_regions", "cover_rects", "water_rects", "hazard_regions", "landmarks",
	"objective_triggers", "static_enemies", "pickups", "crates", "reward_anchors",
	"environment_zones", "packets",
]


static func normalized_id(stage_id: StringName) -> StringName:
	return stage_id if stage_id in STAGE_IDS else STAGE_IDS[0]


static func index_of(stage_id: StringName) -> int:
	return maxi(0, STAGE_IDS.find(normalized_id(stage_id)))


static func definition(stage_id: StringName) -> Dictionary:
	var normalized := normalized_id(stage_id)
	var result: Dictionary
	match normalized:
		&"tidal_archive":
			result = TidalArchive.definition()
		&"storm_drydock":
			result = StormDrydock.definition()
		_:
			result = FloodedWorks.definition()
	var errors := validate_definition(result, normalized)
	if not errors.is_empty():
		push_error("Registered stage %s is invalid: %s" % [normalized, "; ".join(errors)])
		return {}
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
	if not value["world_rect"] is Rect2 or Rect2(value["world_rect"]).size.x <= 0.0 or Rect2(value["world_rect"]).size.y <= 0.0:
		errors.append("world_rect must be a positive Rect2")
	if not value["player_start"] is Vector2:
		errors.append("player_start must be Vector2")
	if not value["landmarks"] is Dictionary:
		errors.append("landmarks must be a Dictionary")
	else:
		for landmark in ["start", "open_entry", "installation_entry", "upper_route", "lower_route", "generator_a", "generator_b", "field_boss", "chest", "boss_gate", "boss"]:
			if not value["landmarks"].has(landmark):
				errors.append("missing landmark %s" % landmark)
	if not value["walkable_regions"] is Array or value["walkable_regions"].is_empty():
		errors.append("walkable_regions must not be empty")
	return errors


static func profile(stage_id: StringName) -> Dictionary:
	var data := definition(stage_id)
	return {
		"title_key": data.get("title_key", ""),
		"number": data.get("number", 0),
		"field_boss_name_key": data.get("field_boss_name_key", ""),
		"boss_name_key": data.get("boss_name_key", ""),
		"environment": data.get("environment", &"none"),
	}


static func world_rect(stage_id: StringName) -> Rect2:
	return Rect2(definition(stage_id)["world_rect"])


static func player_start(stage_id: StringName) -> Vector2:
	return Vector2(definition(stage_id)["player_start"])


static func boss_arena(stage_id: StringName) -> Rect2:
	return Rect2(definition(stage_id)["boss_arena"])


static func boss_gate(stage_id: StringName) -> Rect2:
	return Rect2(definition(stage_id)["boss_gate"])


static func landmarks(stage_id: StringName) -> Dictionary:
	return Dictionary(definition(stage_id)["landmarks"]).duplicate(true)


static func landmark(stage_id: StringName, landmark_id: String) -> Vector2:
	return Vector2(definition(stage_id)["landmarks"].get(landmark_id, Vector2.ZERO))


static func objective_triggers(stage_id: StringName) -> Dictionary:
	return Dictionary(definition(stage_id)["objective_triggers"]).duplicate(true)


static func walkable_regions(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in definition(stage_id)["walkable_regions"]:
		result.append(Dictionary(region).duplicate(true))
	return result


static func cover_rects(stage_id: StringName) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in definition(stage_id)["cover_rects"]:
		result.append(Rect2(rect))
	return result


static func water_rects(stage_id: StringName) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in definition(stage_id)["water_rects"]:
		result.append(Rect2(rect))
	return result


static func hazard_regions(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in definition(stage_id)["hazard_regions"]:
		result.append(Dictionary(region).duplicate(true))
	return result


static func floor_regions(stage_id: StringName, colors: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in walkable_regions(stage_id):
		var tone := StringName(region.get("tone", &"mid"))
		result.append({
			"id": region.get("id", "floor"),
			"name": region.get("name", "Floor"),
			"rect": Rect2(region["rect"]),
			"color": colors.get(tone, colors["mid"]),
		})
	return result


static func enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var data := definition(stage_id)
	var result: Array[Dictionary] = []
	for spec in data["static_enemies"]:
		result.append(Dictionary(spec).duplicate(true))
	var legacy_groups: Array[Dictionary] = []
	for group in data.get("legacy_swarm_groups", []):
		legacy_groups.append(Dictionary(group).duplicate(true))
	var swarms := EncounterDirector.expand_groups(legacy_groups)
	_fit_swarm_spawns(stage_id, swarms, result)
	result.append_array(swarms)
	return result


static func _fit_swarm_spawns(stage_id: StringName, swarms: Array[Dictionary], base_spawns: Array[Dictionary]) -> void:
	var cover := cover_rects(stage_id)
	var occupied: Array[Vector2] = []
	for spec in base_spawns:
		occupied.append(Vector2(spec["pos"]))
	var radius_offsets := [0.0, -18.0, 18.0, -36.0, 36.0, 54.0, 72.0]
	for index in swarms.size():
		var spec: Dictionary = swarms[index]
		var original := Vector2(spec["pos"])
		if _spawn_position_clear(stage_id, original, cover, occupied):
			occupied.append(original)
			continue
		var anchor := Vector2(spec["formation_anchor"])
		var base_offset := original - anchor
		var resolved := original
		var found := false
		for radius_offset in radius_offsets:
			var candidate_radius := maxf(34.0, base_offset.length() + float(radius_offset))
			for angle_step in 32:
				var candidate_angle := base_offset.angle() + TAU * float(angle_step + 1) / 32.0
				var candidate := anchor + Vector2.RIGHT.rotated(candidate_angle) * candidate_radius
				if _spawn_position_clear(stage_id, candidate, cover, occupied):
					resolved = candidate
					found = true
					break
			if found:
				break
		spec["pos"] = resolved
		swarms[index] = spec
		occupied.append(resolved)


static func _spawn_position_clear(stage_id: StringName, position: Vector2, cover: Array[Rect2], occupied: Array[Vector2]) -> bool:
	const VALIDATION_RADIUS := 28.0
	if not position_is_walkable(stage_id, position, VALIDATION_RADIUS):
		return false
	for rect in cover:
		if _circle_overlaps_rect(position, VALIDATION_RADIUS, rect):
			return false
	for other in occupied:
		if position.distance_to(other) < 25.0:
			return false
	return true


static func position_is_walkable(stage_id: StringName, position: Vector2, radius: float = 0.0) -> bool:
	var inside_floor := false
	for region in definition(stage_id)["walkable_regions"]:
		if Rect2(region["rect"]).grow(-radius).has_point(position):
			inside_floor = true
			break
	if not inside_floor:
		return false
	for water in water_rects(stage_id):
		if _circle_overlaps_rect(position, radius, water):
			return false
	return true


static func _circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_squared_to(closest) < radius * radius


static func pickup_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(stage_id)["pickups"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func crate_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(stage_id)["crates"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func reward_anchors(stage_id: StringName) -> Dictionary:
	return Dictionary(definition(stage_id)["reward_anchors"]).duplicate(true)


static func environment_zones(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for zone in definition(stage_id)["environment_zones"]:
		result.append(Dictionary(zone).duplicate(true))
	return result


static func packets(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for packet in definition(stage_id)["packets"]:
		result.append(Dictionary(packet).duplicate(true))
	return result
