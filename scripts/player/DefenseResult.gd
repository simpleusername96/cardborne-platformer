class_name DefenseResult
extends RefCounted

var _blocked: bool
var _precise: bool
var _phase: StringName
var _condition_cost: int
var _stability_cost: int
var _guard_broken: bool
var _reason: StringName
var _tags: Array[StringName]

var blocked: bool:
	get:
		return _blocked
var precise: bool:
	get:
		return _precise
var phase: StringName:
	get:
		return _phase
var condition_cost: int:
	get:
		return _condition_cost
var stability_cost: int:
	get:
		return _stability_cost
var posture_cost: int:
	get:
		return _stability_cost
var guard_broken: bool:
	get:
		return _guard_broken
var reason: StringName:
	get:
		return _reason
var tags: Array[StringName]:
	get:
		return _tags.duplicate()


func _init(
	p_blocked: bool,
	p_precise: bool,
	p_phase: StringName,
	p_condition_cost: int,
	p_stability_cost: int,
	p_guard_broken: bool,
	p_reason: StringName,
	p_tags: Array[StringName] = []
) -> void:
	_blocked = p_blocked
	_precise = p_precise
	_phase = p_phase
	_condition_cost = maxi(p_condition_cost, 0)
	_stability_cost = maxi(p_stability_cost, 0)
	_guard_broken = p_guard_broken
	_reason = p_reason
	_tags = p_tags.duplicate()


func to_snapshot() -> Dictionary:
	return {
		"blocked": _blocked,
		"precise": _precise,
		"phase": _phase,
		"condition_cost": _condition_cost,
		"stability_cost": _stability_cost,
		"posture_cost": _stability_cost,
		"guard_broken": _guard_broken,
		"reason": _reason,
		"tags": _tags.duplicate(),
	}
