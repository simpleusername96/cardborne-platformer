class_name VehicleRewardRuntime
extends RefCounted

## Owns reward queueing, active transaction state, and run-scoped terminal outcomes.

const LEVEL_UP_SOURCE: StringName = &"level_up"

var _current_source: StringName = &""
var _offer_serial := 0
var _level_up_offer_count := 0
var _current_level_up_offer_index := -1
var _terminal_outcomes: Dictionary = {}
var _pending_sources: Array[StringName] = []


func reset_run() -> void:
	_clear_active()
	_offer_serial = 0
	_level_up_offer_count = 0
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


func begin(stage_id: StringName, source_id: StringName) -> int:
	if source_id.is_empty() or not is_idle():
		return -1
	if source_id != LEVEL_UP_SOURCE and is_resolved(stage_id, source_id):
		return -1

	var serial := _offer_serial
	_offer_serial += 1
	_current_source = source_id
	_current_level_up_offer_index = -1
	if source_id == LEVEL_UP_SOURCE:
		_current_level_up_offer_index = _level_up_offer_count
		_level_up_offer_count += 1
	return serial


func claim(stage_id: StringName) -> StringName:
	var source_id := _current_source
	if source_id.is_empty():
		return &""
	if source_id != LEVEL_UP_SOURCE:
		_terminal_outcomes[_transaction_id(stage_id, source_id)] = &"claimed"
	_clear_active()
	return source_id


func has_claimed(stage_id: StringName, source_id: StringName) -> bool:
	return outcome(stage_id, source_id) == &"claimed"


func is_resolved(stage_id: StringName, source_id: StringName) -> bool:
	return _terminal_outcomes.has(_transaction_id(stage_id, source_id))


func outcome(stage_id: StringName, source_id: StringName) -> StringName:
	return StringName(_terminal_outcomes.get(_transaction_id(stage_id, source_id), &""))


func current_source() -> StringName:
	return _current_source


func current_level_up_offer_index() -> int:
	return _current_level_up_offer_index


func is_idle() -> bool:
	return _current_source.is_empty()


func campaign_receipt() -> Dictionary:
	return {
		"idle":is_idle(),
		"current_source":_current_source,
		"pending_sources":_pending_sources.duplicate(),
		"offer_serial":_offer_serial,
		"level_up_offer_count":_level_up_offer_count,
		"current_level_up_offer_index":_current_level_up_offer_index,
	}


static func valid_campaign_receipt(receipt: Dictionary) -> bool:
	if not (
		receipt.has("idle")
		and receipt.has("current_source")
		and receipt.has("pending_sources")
		and receipt.has("offer_serial")
		and receipt.has("level_up_offer_count")
		and receipt.has("current_level_up_offer_index")
	):
		return false
	var idle := bool(receipt["idle"])
	var source := StringName(receipt["current_source"])
	return (
		idle == source.is_empty()
		and receipt["pending_sources"] is Array
		and int(receipt["offer_serial"]) >= 0
		and int(receipt["level_up_offer_count"]) >= 0
		and int(receipt["current_level_up_offer_index"]) >= -1
		and (
			int(receipt["current_level_up_offer_index"]) == -1
			or source == LEVEL_UP_SOURCE
		)
	)


func _clear_active() -> void:
	_current_source = &""
	_current_level_up_offer_index = -1


func _transaction_id(stage_id: StringName, source_id: StringName) -> StringName:
	return StringName("%s:%s" % [stage_id, source_id])
