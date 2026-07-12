class_name PlannedEncounter
extends RefCounted

var _id: StringName
var _room_id: StringName
var _anchor_id: StringName
var _pressure_role: StringName
var _archetype_id: StringName
var _variant_id: StringName
var _content_version: int
var _budget_cost: int

var id: StringName:
	get:
		return _id
var room_id: StringName:
	get:
		return _room_id
var anchor_id: StringName:
	get:
		return _anchor_id
var pressure_role: StringName:
	get:
		return _pressure_role
var archetype_id: StringName:
	get:
		return _archetype_id
var variant_id: StringName:
	get:
		return _variant_id
var content_version: int:
	get:
		return _content_version
var budget_cost: int:
	get:
		return _budget_cost


func _init(
	encounter_id: StringName = &"",
	encounter_room_id: StringName = &"",
	encounter_anchor_id: StringName = &"",
	encounter_pressure_role: StringName = &"",
	enemy_archetype_id: StringName = &"",
	enemy_variant_id: StringName = &"",
	resolved_content_version: int = 0,
	exact_budget_cost: int = 0
) -> void:
	_id = encounter_id
	_room_id = encounter_room_id
	_anchor_id = encounter_anchor_id
	_pressure_role = encounter_pressure_role
	_archetype_id = enemy_archetype_id
	_variant_id = enemy_variant_id
	_content_version = resolved_content_version
	_budget_cost = exact_budget_cost


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"room_id": String(_room_id),
		"anchor_id": String(_anchor_id),
		"pressure_role": String(_pressure_role),
		"archetype_id": String(_archetype_id),
		"variant_id": String(_variant_id),
		"content_version": _content_version,
		"budget_cost": _budget_cost,
	}


static func from_dictionary(data: Dictionary) -> PlannedEncounter:
	return PlannedEncounter.new(
		StringName(str(data.get("id", ""))),
		StringName(str(data.get("room_id", ""))),
		StringName(str(data.get("anchor_id", ""))),
		StringName(str(data.get("pressure_role", ""))),
		StringName(str(data.get("archetype_id", ""))),
		StringName(str(data.get("variant_id", ""))),
		int(data.get("content_version", 0)),
		int(data.get("budget_cost", 0))
	)
