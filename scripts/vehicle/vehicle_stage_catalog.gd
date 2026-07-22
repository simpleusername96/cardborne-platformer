class_name VehicleStageCatalog
extends RefCounted

## Validated facade over responsibility-shaped authored stage definitions.
## Runtime consumers never silently receive a partial registered stage.

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
	var result := static_enemy_blueprint(stage_id)
	result.append_array(packet_enemy_blueprint(stage_id))
	return result


static func static_enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in definition(stage_id)["static_enemies"]:
		result.append(Dictionary(spec).duplicate(true))
	return result


static func packet_enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for packet in packets(stage_id):
		var packet_id := String(packet["id"])
		var anchor := Vector2(packet["anchor"])
		var squads: Array = packet["squads"]
		for squad_index in squads.size():
			var squad: Array = squads[squad_index]
			for unit_index in squad.size():
				result.append({
					"id":"%s_s%02d_u%02d" % [packet_id, squad_index + 1, unit_index + 1],
					"role":StringName(squad[unit_index]), "pos":anchor, "zone":String(packet["zone"]),
					"group_id":"%s_s%02d" % [packet_id, squad_index + 1],
					"formation_anchor":anchor, "leash_rect":Rect2(packet["leash"]),
				})
	return result


static func authored_population(stage_id: StringName) -> int:
	return enemy_blueprint(stage_id).size()


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
