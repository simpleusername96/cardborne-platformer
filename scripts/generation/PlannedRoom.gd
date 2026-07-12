class_name PlannedRoom
extends RefCounted

var _id: StringName
var _template_id: StringName
var _template_content_version: int
var _role: StringName
var _required_route: bool
var _route_index: int
var _encounter_budget: int
var _hazard_budget: int
var _reward_budget: int

var id: StringName:
	get:
		return _id
var template_id: StringName:
	get:
		return _template_id
var template_content_version: int:
	get:
		return _template_content_version
var role: StringName:
	get:
		return _role
var required_route: bool:
	get:
		return _required_route
var route_index: int:
	get:
		return _route_index
var encounter_budget: int:
	get:
		return _encounter_budget
var hazard_budget: int:
	get:
		return _hazard_budget
var reward_budget: int:
	get:
		return _reward_budget


func _init(
	room_id: StringName = &"",
	room_template_id: StringName = &"",
	room_template_content_version: int = 0,
	room_role: StringName = &"",
	is_required_route: bool = true,
	room_route_index: int = -1,
	room_encounter_budget: int = 0,
	room_hazard_budget: int = 0,
	room_reward_budget: int = 0
) -> void:
	_id = room_id
	_template_id = room_template_id
	_template_content_version = room_template_content_version
	_role = room_role
	_required_route = is_required_route
	_route_index = room_route_index
	_encounter_budget = room_encounter_budget
	_hazard_budget = room_hazard_budget
	_reward_budget = room_reward_budget


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"template_id": String(_template_id),
		"template_content_version": _template_content_version,
		"role": String(_role),
		"required_route": _required_route,
		"route_index": _route_index,
		"encounter_budget": _encounter_budget,
		"hazard_budget": _hazard_budget,
		"reward_budget": _reward_budget,
	}


static func from_dictionary(data: Dictionary) -> PlannedRoom:
	return PlannedRoom.new(
		StringName(str(data.get("id", ""))),
		StringName(str(data.get("template_id", ""))),
		int(data.get("template_content_version", 0)),
		StringName(str(data.get("role", ""))),
		bool(data.get("required_route", true)),
		int(data.get("route_index", -1)),
		int(data.get("encounter_budget", 0)),
		int(data.get("hazard_budget", 0)),
		int(data.get("reward_budget", 0))
	)
