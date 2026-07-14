class_name AttackIntent
extends RefCounted

const MODE_MELEE := &"melee"
const MODE_RANGED := &"ranged"

var _mode: StringName
var _tool_id: StringName
var _target_id: StringName
var _origin: Vector2
var _direction: Vector2
var _resource_id: StringName
var _resource_cost: int
var _reason: StringName
var _geometry: Dictionary

var mode: StringName:
	get:
		return _mode
var tool_id: StringName:
	get:
		return _tool_id
var target_id: StringName:
	get:
		return _target_id
var origin: Vector2:
	get:
		return _origin
var direction: Vector2:
	get:
		return _direction
var resource_id: StringName:
	get:
		return _resource_id
var resource_cost: int:
	get:
		return _resource_cost
var resource: Dictionary:
	get:
		return {"id": _resource_id, "cost": _resource_cost}
var reason: StringName:
	get:
		return _reason
var geometry: Dictionary:
	get:
		return _geometry.duplicate(true)


func _init(
	p_mode: StringName,
	p_tool_id: StringName,
	p_target_id: StringName,
	p_origin: Vector2,
	p_direction: Vector2,
	p_resource_cost: int,
	p_reason: StringName,
	p_geometry: Dictionary,
	p_resource_id: StringName = &""
) -> void:
	_mode = p_mode
	_tool_id = p_tool_id
	_target_id = p_target_id
	_origin = p_origin
	_direction = p_direction.normalized() if not p_direction.is_zero_approx() else Vector2.RIGHT
	_resource_id = p_resource_id
	_resource_cost = maxi(p_resource_cost, 0)
	_reason = p_reason
	_geometry = p_geometry.duplicate(true)


func is_targeted() -> bool:
	return not String(_target_id).is_empty()


func to_snapshot() -> Dictionary:
	return {
		"mode": _mode,
		"tool_id": _tool_id,
		"target_id": _target_id,
		"origin": _origin,
		"direction": _direction,
		"resource": {"id": _resource_id, "cost": _resource_cost},
		"resource_id": _resource_id,
		"resource_cost": _resource_cost,
		"reason": _reason,
		"geometry": _geometry.duplicate(true),
	}
