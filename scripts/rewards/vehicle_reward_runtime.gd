class_name VehicleRewardRuntime
extends RefCounted

## Owns reward queueing, active transaction state, and run-scoped terminal outcomes.

const LEVEL_UP_SOURCE: StringName = &"level_up"

var _current_source: StringName = &""
var _current_optional := false
var _offer_serial := 0
var _terminal_outcomes: Dictionary = {}
var _pending_sources: Array[StringName] = []


func reset_run() -> void:
	_clear_active()
	_offer_serial = 0
	_terminal_outcomes.clear()
	_pending_sources.clear()


func reset_stage() -> void:
	_clear_active()
	_pending_sources.clear()


func enqueue(source_id: StringName) -> bool:
	if source_id.is_empty() or source_id == _current_source or source_id in _pending_sources:
		return false
	_pending_sources.append(source_id)
	return true


func has_pending() -> bool:
	return not _pending_sources.is_empty()


func pop_pending() -> StringName:
	if _pending_sources.is_empty():
		return &""
	return StringName(_pending_sources.pop_front())


func begin(stage_id: StringName, source_id: StringName, optional: bool) -> int:
	if source_id.is_empty() or not is_idle():
		return -1
	if source_id != LEVEL_UP_SOURCE and is_resolved(stage_id, source_id):
		return -1

	var serial := _offer_serial
	_offer_serial += 1
	_current_source = source_id
	_current_optional = optional
	return serial


func claim(stage_id: StringName) -> StringName:
	var source_id := _current_source
	if source_id.is_empty():
		return &""
	if source_id != LEVEL_UP_SOURCE:
		_terminal_outcomes[_transaction_id(stage_id, source_id)] = &"claimed"
	_clear_active()
	return source_id


func decline(stage_id: StringName) -> bool:
	if _current_source.is_empty() or not _current_optional or _current_source == LEVEL_UP_SOURCE:
		return false
	_terminal_outcomes[_transaction_id(stage_id, _current_source)] = &"declined"
	_clear_active()
	return true


func has_claimed(stage_id: StringName, source_id: StringName) -> bool:
	return outcome(stage_id, source_id) == &"claimed"


func is_resolved(stage_id: StringName, source_id: StringName) -> bool:
	return _terminal_outcomes.has(_transaction_id(stage_id, source_id))


func outcome(stage_id: StringName, source_id: StringName) -> StringName:
	return StringName(_terminal_outcomes.get(_transaction_id(stage_id, source_id), &""))


func current_source() -> StringName:
	return _current_source


func is_current_optional() -> bool:
	return _current_optional


func is_idle() -> bool:
	return _current_source.is_empty()


func _clear_active() -> void:
	_current_source = &""
	_current_optional = false


func _transaction_id(stage_id: StringName, source_id: StringName) -> StringName:
	return StringName("%s:%s" % [stage_id, source_id])
