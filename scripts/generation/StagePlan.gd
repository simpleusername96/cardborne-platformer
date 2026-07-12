class_name StagePlan
extends RefCounted

const CURRENT_SCHEMA_VERSION := 2

var _schema_version: int
var _run_seed: int
var _stage_index: int
var _profile_id: StringName
var _profile_content_version: int
var _room_catalog_id: StringName
var _room_catalog_content_version: int
var _rng_stream_seeds: Dictionary
var _rooms: Array[PlannedRoom]
var _connections: Array[PlannedConnection]
var _encounters: Array[PlannedEncounter]
var _generation_attempt: int
var _hazards: Array[PlannedHazard]
var _rewards: Array[PlannedReward]

var schema_version: int:
	get:
		return _schema_version
var run_seed: int:
	get:
		return _run_seed
var stage_index: int:
	get:
		return _stage_index
var profile_id: StringName:
	get:
		return _profile_id
var profile_content_version: int:
	get:
		return _profile_content_version
var room_catalog_id: StringName:
	get:
		return _room_catalog_id
var room_catalog_content_version: int:
	get:
		return _room_catalog_content_version
var content_version: int:
	get:
		return _room_catalog_content_version
var generation_attempt: int:
	get:
		return _generation_attempt


func _init(
	plan_run_seed: int = 0,
	plan_stage_index: int = 0,
	stage_profile_id: StringName = &"",
	stage_profile_content_version: int = 0,
	catalog_id: StringName = &"",
	catalog_content_version: int = 0,
	stream_seeds: Dictionary = {},
	planned_rooms: Array[PlannedRoom] = [],
	planned_connections: Array[PlannedConnection] = [],
	planned_encounters: Array[PlannedEncounter] = [],
	plan_schema_version: int = CURRENT_SCHEMA_VERSION,
	plan_generation_attempt: int = 0,
	planned_hazards: Array[PlannedHazard] = [],
	planned_rewards: Array[PlannedReward] = []
) -> void:
	_schema_version = plan_schema_version
	_run_seed = plan_run_seed
	_stage_index = plan_stage_index
	_profile_id = stage_profile_id
	_profile_content_version = stage_profile_content_version
	_room_catalog_id = catalog_id
	_room_catalog_content_version = catalog_content_version
	_rng_stream_seeds = _ordered_seed_copy(stream_seeds)
	_rooms = planned_rooms.duplicate()
	_connections = planned_connections.duplicate()
	_encounters = planned_encounters.duplicate()
	_generation_attempt = plan_generation_attempt
	_hazards = planned_hazards.duplicate()
	_rewards = planned_rewards.duplicate()


func get_rng_stream_seeds() -> Dictionary:
	return _rng_stream_seeds.duplicate(true)


func get_rooms() -> Array[PlannedRoom]:
	return _rooms.duplicate()


func get_connections() -> Array[PlannedConnection]:
	return _connections.duplicate()


func get_encounters() -> Array[PlannedEncounter]:
	return _encounters.duplicate()


func get_hazards() -> Array[PlannedHazard]:
	return _hazards.duplicate()


func get_rewards() -> Array[PlannedReward]:
	return _rewards.duplicate()


func get_room(room_id: StringName) -> PlannedRoom:
	for room in _rooms:
		if room.id == room_id:
			return room
	return null


func to_dictionary() -> Dictionary:
	var serialized_rooms: Array[Dictionary] = []
	for room in _rooms:
		serialized_rooms.append(room.to_dictionary())
	var serialized_connections: Array[Dictionary] = []
	for connection in _connections:
		serialized_connections.append(connection.to_dictionary())
	var serialized_encounters: Array[Dictionary] = []
	for encounter in _encounters:
		serialized_encounters.append(encounter.to_dictionary())
	var serialized_hazards: Array[Dictionary] = []
	for hazard in _hazards:
		serialized_hazards.append(hazard.to_dictionary())
	var serialized_rewards: Array[Dictionary] = []
	for reward in _rewards:
		serialized_rewards.append(reward.to_dictionary())
	return {
		"schema_version": _schema_version,
		"run_seed": _run_seed,
		"stage_index": _stage_index,
		"generation_attempt": _generation_attempt,
		"profile_id": String(_profile_id),
		"profile_content_version": _profile_content_version,
		"room_catalog_id": String(_room_catalog_id),
		"room_catalog_content_version": _room_catalog_content_version,
		"content_version": _room_catalog_content_version,
		"rng_stream_seeds": _ordered_seed_copy(_rng_stream_seeds),
		"rooms": serialized_rooms,
		"connections": serialized_connections,
		"encounters": serialized_encounters,
		"hazards": serialized_hazards,
		"rewards": serialized_rewards,
	}


func to_json() -> String:
	return JSON.stringify(to_dictionary())


static func from_dictionary(data: Dictionary) -> StagePlan:
	var planned_rooms: Array[PlannedRoom] = []
	var raw_rooms: Variant = data.get("rooms", [])
	if raw_rooms is Array:
		for raw_room in raw_rooms:
			if raw_room is Dictionary:
				planned_rooms.append(PlannedRoom.from_dictionary(raw_room))

	var planned_connections: Array[PlannedConnection] = []
	var raw_connections: Variant = data.get("connections", [])
	if raw_connections is Array:
		for raw_connection in raw_connections:
			if raw_connection is Dictionary:
				planned_connections.append(PlannedConnection.from_dictionary(raw_connection))

	var planned_encounters: Array[PlannedEncounter] = []
	var raw_encounters: Variant = data.get("encounters", [])
	if raw_encounters is Array:
		for raw_encounter in raw_encounters:
			if raw_encounter is Dictionary:
				planned_encounters.append(PlannedEncounter.from_dictionary(raw_encounter))

	var planned_hazards: Array[PlannedHazard] = []
	var raw_hazards: Variant = data.get("hazards", [])
	if raw_hazards is Array:
		for raw_hazard in raw_hazards:
			if raw_hazard is Dictionary:
				planned_hazards.append(PlannedHazard.from_dictionary(raw_hazard))

	var planned_rewards: Array[PlannedReward] = []
	var raw_rewards: Variant = data.get("rewards", [])
	if raw_rewards is Array:
		for raw_reward in raw_rewards:
			if raw_reward is Dictionary:
				planned_rewards.append(PlannedReward.from_dictionary(raw_reward))

	var stream_seeds: Dictionary = {}
	var raw_stream_seeds: Variant = data.get("rng_stream_seeds", {})
	if raw_stream_seeds is Dictionary:
		stream_seeds = raw_stream_seeds
	return StagePlan.new(
		int(data.get("run_seed", 0)),
		int(data.get("stage_index", 0)),
		StringName(str(data.get("profile_id", ""))),
		int(data.get("profile_content_version", 0)),
		StringName(str(data.get("room_catalog_id", ""))),
		int(data.get("room_catalog_content_version", data.get("content_version", 0))),
		stream_seeds,
		planned_rooms,
		planned_connections,
		planned_encounters,
		int(data.get("schema_version", CURRENT_SCHEMA_VERSION)),
		int(data.get("generation_attempt", 0)),
		planned_hazards,
		planned_rewards
	)


static func from_json(serialized_plan: String) -> StagePlan:
	var parsed: Variant = JSON.parse_string(serialized_plan)
	if not parsed is Dictionary:
		return null
	return StagePlan.from_dictionary(parsed)


static func _ordered_seed_copy(source: Dictionary) -> Dictionary:
	var keys: Array = source.keys()
	keys.sort_custom(func(first: Variant, second: Variant) -> bool: return str(first) < str(second))
	var ordered: Dictionary = {}
	for key in keys:
		ordered[str(key)] = int(source[key])
	return ordered
