class_name VehicleStageTelemetry
extends RefCounted

## Bounded numeric combat accounting. It never stores live actor references.

const MAX_DAMAGE_SOURCES := 32
const MAX_ARCHETYPES := 32
const MAX_TACTIC_EVENTS := 32
const DAMAGE_ATTRIBUTES: Array[StringName] = [
	&"kinetic", &"thermal", &"toxin", &"cryo", &"arc",
]

var stage_outgoing: Dictionary = {}
var stage_attributes: Dictionary = {}
var stage_status_applications: Dictionary = {}
var stage_incoming: Dictionary = {}
var stage_defeats: Dictionary = {}
var stage_elites: Dictionary = {}
var stage_tactics: Dictionary = {}
var run_outgoing: Dictionary = {}
var run_attributes: Dictionary = {}
var run_status_applications: Dictionary = {}
var run_incoming: Dictionary = {}
var run_defeats: Dictionary = {}
var run_tactics: Dictionary = {}
var last_incoming_source: StringName = &""
var last_incoming_damage := 0.0
var _frozen_stage: Dictionary = {}


func reset_run() -> void:
	run_outgoing.clear()
	run_attributes.clear()
	run_status_applications.clear()
	run_incoming.clear()
	run_defeats.clear()
	run_tactics.clear()
	reset_stage()


func reset_stage() -> void:
	stage_outgoing.clear()
	stage_attributes.clear()
	stage_status_applications.clear()
	stage_incoming.clear()
	stage_defeats.clear()
	stage_elites.clear()
	stage_tactics.clear()
	last_incoming_source = &""
	last_incoming_damage = 0.0
	_frozen_stage.clear()


func record_outgoing(
	source_id: StringName,
	attribute: StringName,
	applied_damage: float
) -> void:
	if applied_damage <= 0.0:
		return
	if attribute not in DAMAGE_ATTRIBUTES:
		push_error("Unknown player damage attribute: %s" % attribute)
		return
	_add_bounded(stage_outgoing, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	_add_bounded(run_outgoing, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	_add_bounded(stage_attributes, attribute, applied_damage, DAMAGE_ATTRIBUTES.size())
	_add_bounded(run_attributes, attribute, applied_damage, DAMAGE_ATTRIBUTES.size())


func record_status_application(kind: StringName) -> void:
	if kind not in [&"burn", &"poison", &"chill"]:
		return
	_add_bounded(stage_status_applications, kind, 1, 3)
	_add_bounded(run_status_applications, kind, 1, 3)


func record_incoming(source_id: StringName, applied_damage: float) -> void:
	if applied_damage <= 0.0:
		return
	_add_bounded(stage_incoming, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	_add_bounded(run_incoming, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	last_incoming_source = source_id
	last_incoming_damage = applied_damage


func record_defeat(archetype_id: StringName, elite_trait: StringName = &"") -> void:
	if archetype_id == &"":
		archetype_id = &"other"
	_add_bounded(stage_defeats, archetype_id, 1, MAX_ARCHETYPES)
	_add_bounded(run_defeats, archetype_id, 1, MAX_ARCHETYPES)
	if elite_trait != &"":
		var elite_key := StringName(
			"%s:%s" % [String(archetype_id), String(elite_trait)]
		)
		_add_bounded(stage_elites, elite_key, 1, MAX_ARCHETYPES)


func record_tactic_event(tactic_id: StringName, phase: StringName) -> void:
	if tactic_id.is_empty() or phase.is_empty():
		return
	var key := StringName("%s:%s" % [String(tactic_id), String(phase)])
	_add_bounded(stage_tactics, key, 1, MAX_TACTIC_EVENTS)
	_add_bounded(run_tactics, key, 1, MAX_TACTIC_EVENTS)


func freeze_stage() -> Dictionary:
	_frozen_stage = _stage_snapshot()
	return _frozen_stage.duplicate(true)


func stage_snapshot() -> Dictionary:
	if not _frozen_stage.is_empty():
		return _frozen_stage.duplicate(true)
	return _stage_snapshot()


func run_snapshot() -> Dictionary:
	return {
		"outgoing":run_outgoing.duplicate(),
		"attributes":run_attributes.duplicate(),
		"status_applications":run_status_applications.duplicate(),
		"incoming":run_incoming.duplicate(),
		"defeats":run_defeats.duplicate(),
		"tactics":run_tactics.duplicate(),
	}


func _stage_snapshot() -> Dictionary:
	return {
		"outgoing":stage_outgoing.duplicate(),
		"attributes":stage_attributes.duplicate(),
		"status_applications":stage_status_applications.duplicate(),
		"incoming":stage_incoming.duplicate(),
		"defeats":stage_defeats.duplicate(),
		"elites":stage_elites.duplicate(),
		"tactics":stage_tactics.duplicate(),
		"last_incoming_source":last_incoming_source,
		"last_incoming_damage":last_incoming_damage,
	}


func _add_bounded(
	target: Dictionary,
	key: StringName,
	value: Variant,
	capacity: int
) -> void:
	if target.has(key):
		target[key] = target[key] + value
		return
	if target.size() >= capacity:
		key = &"other"
	target[key] = target.get(key, 0) + value
