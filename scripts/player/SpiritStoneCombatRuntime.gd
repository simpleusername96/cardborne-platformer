class_name SpiritStoneCombatRuntime
extends RefCounted

var _definition: SpiritStoneDefinition
var _elapsed: float = 0.0
var _direct_attack_times: Array[float] = []
var _processed_event_ids: Dictionary = {}


func configure(definition: SpiritStoneDefinition) -> void:
	_definition = definition
	reset()


func reset() -> void:
	_elapsed = 0.0
	_direct_attack_times.clear()
	_processed_event_ids.clear()


func update(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	_prune_direct_attacks()


func record_direct_attack(event_id: StringName) -> Dictionary:
	if (
		_definition == null
		or _definition.trigger != SpiritStoneDefinition.TRIGGER_DIRECT_ATTACK_SEQUENCE
		or not _accept_event(event_id)
	):
		return _result(false)
	_prune_direct_attacks()
	_direct_attack_times.append(_elapsed)
	var triggered := _direct_attack_times.size() >= _definition.required_direct_attack_count
	if triggered:
		_direct_attack_times.clear()
	return _result(triggered)


func record_precise_guard(event_id: StringName) -> Dictionary:
	var triggered := (
		_definition != null
		and _definition.trigger == SpiritStoneDefinition.TRIGGER_PRECISE_GUARD
		and _accept_event(event_id)
	)
	return _result(triggered)


func get_state_snapshot() -> Dictionary:
	return {
		"spirit_stone_id": String(_definition.id) if _definition != null else "",
		"trigger": String(_definition.trigger) if _definition != null else "",
		"direct_attack_count": _direct_attack_times.size(),
		"processed_event_count": _processed_event_ids.size(),
	}


func _accept_event(event_id: StringName) -> bool:
	if event_id.is_empty() or _processed_event_ids.has(String(event_id)):
		return false
	_processed_event_ids[String(event_id)] = true
	return true


func _prune_direct_attacks() -> void:
	if _definition == null:
		_direct_attack_times.clear()
		return
	var window := maxf(_definition.direct_attack_window_seconds, 0.0)
	while not _direct_attack_times.is_empty() and _elapsed - _direct_attack_times[0] > window:
		_direct_attack_times.pop_front()


func _result(triggered: bool) -> Dictionary:
	return {
		"triggered": triggered,
		"definition": _definition,
		"state": get_state_snapshot(),
	}
