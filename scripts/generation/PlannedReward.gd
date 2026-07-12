class_name PlannedReward
extends RefCounted

var _id: StringName
var _room_id: StringName
var _anchor_id: StringName
var _reward_table_id: StringName
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
var reward_table_id: StringName:
	get:
		return _reward_table_id
var content_version: int:
	get:
		return _content_version
var budget_cost: int:
	get:
		return _budget_cost


func _init(
	placement_id: StringName = &"",
	placement_room_id: StringName = &"",
	placement_anchor_id: StringName = &"",
	table_id: StringName = &"",
	table_content_version: int = 0,
	exact_budget_cost: int = 0
) -> void:
	_id = placement_id
	_room_id = placement_room_id
	_anchor_id = placement_anchor_id
	_reward_table_id = table_id
	_content_version = table_content_version
	_budget_cost = exact_budget_cost


func to_dictionary() -> Dictionary:
	return {
		"id": String(_id),
		"room_id": String(_room_id),
		"anchor_id": String(_anchor_id),
		"reward_table_id": String(_reward_table_id),
		"content_version": _content_version,
		"budget_cost": _budget_cost,
	}


static func from_dictionary(data: Dictionary) -> PlannedReward:
	return PlannedReward.new(
		StringName(str(data.get("id", ""))),
		StringName(str(data.get("room_id", ""))),
		StringName(str(data.get("anchor_id", ""))),
		StringName(str(data.get("reward_table_id", ""))),
		int(data.get("content_version", 0)),
		int(data.get("budget_cost", 0))
	)
