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
var stage_family_defeats: Dictionary = {}
var stage_traits: Dictionary = {}
var stage_family_traits: Dictionary = {}
var stage_tactics: Dictionary = {}
var stage_attack_commits: Dictionary = {}
var stage_progression: Dictionary = {}
var boss_actor: Dictionary = {}
var run_outgoing: Dictionary = {}
var run_attributes: Dictionary = {}
var run_status_applications: Dictionary = {}
var run_incoming: Dictionary = {}
var run_defeats: Dictionary = {}
var run_family_defeats: Dictionary = {}
var run_traits: Dictionary = {}
var run_tactics: Dictionary = {}
var run_attack_commits: Dictionary = {}
var run_progression: Dictionary = {}
var last_incoming_source: StringName = &""
var last_incoming_damage := 0.0
var _frozen_stage: Dictionary = {}
var _upgrade_opened_at := -1.0


func reset_run() -> void:
	run_outgoing.clear()
	run_attributes.clear()
	run_status_applications.clear()
	run_incoming.clear()
	run_defeats.clear()
	run_family_defeats.clear()
	run_traits.clear()
	run_tactics.clear()
	run_attack_commits.clear()
	run_progression.clear()
	reset_stage()


func reset_stage() -> void:
	stage_outgoing.clear()
	stage_attributes.clear()
	stage_status_applications.clear()
	stage_incoming.clear()
	stage_defeats.clear()
	stage_family_defeats.clear()
	stage_traits.clear()
	stage_family_traits.clear()
	stage_tactics.clear()
	stage_attack_commits.clear()
	stage_progression.clear()
	boss_actor.clear()
	last_incoming_source = &""
	last_incoming_damage = 0.0
	_frozen_stage.clear()
	_upgrade_opened_at = -1.0


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
	if kind not in [&"poison", &"chill"]:
		return
	_add_bounded(stage_status_applications, kind, 1, 2)
	_add_bounded(run_status_applications, kind, 1, 2)


func record_incoming(source_id: StringName, applied_damage: float) -> void:
	if applied_damage <= 0.0:
		return
	_add_bounded(stage_incoming, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	_add_bounded(run_incoming, source_id, applied_damage, MAX_DAMAGE_SOURCES)
	last_incoming_source = source_id
	last_incoming_damage = applied_damage


func record_defeat(
	archetype_id: StringName,
	family_id: StringName = &"",
	family_trait: StringName = &""
) -> void:
	if archetype_id == &"":
		archetype_id = &"other"
	_add_bounded(stage_defeats, archetype_id, 1, MAX_ARCHETYPES)
	_add_bounded(run_defeats, archetype_id, 1, MAX_ARCHETYPES)
	if not family_id.is_empty():
		_add_bounded(stage_family_defeats, family_id, 1, 8)
		_add_bounded(run_family_defeats, family_id, 1, 8)
	if family_trait != &"":
		var archetype_trait_key := StringName(
			"%s:%s" % [String(archetype_id), String(family_trait)]
		)
		var family_trait_key := StringName(
			"%s:%s" % [String(family_id), String(family_trait)]
		)
		_add_bounded(stage_traits, archetype_trait_key, 1, MAX_ARCHETYPES)
		_add_bounded(stage_family_traits, family_trait_key, 1, MAX_ARCHETYPES)
		_add_bounded(run_traits, family_trait_key, 1, MAX_ARCHETYPES)


func record_attack_commit(family_id: StringName) -> void:
	if family_id.is_empty():
		family_id = &"unknown"
	_add_bounded(stage_attack_commits, family_id, 1, 8)
	_add_bounded(run_attack_commits, family_id, 1, 8)


func record_experience(collected: int, level: int) -> void:
	if collected > 0:
		stage_progression["xp_collected"] = int(
			stage_progression.get("xp_collected", 0)
		) + collected
		run_progression["xp_collected"] = int(
			run_progression.get("xp_collected", 0)
		) + collected
	stage_progression["level_reached"] = maxi(
		int(stage_progression.get("level_reached", 1)), level
	)
	run_progression["level_reached"] = maxi(
		int(run_progression.get("level_reached", 1)), level
	)


func record_upgrade_opened(run_seconds: float) -> void:
	stage_progression["modal_opens"] = int(
		stage_progression.get("modal_opens", 0)
	) + 1
	run_progression["modal_opens"] = int(
		run_progression.get("modal_opens", 0)
	) + 1
	_upgrade_opened_at = maxf(0.0, run_seconds)


func record_upgrade_confirmed(run_seconds: float) -> void:
	stage_progression["upgrades_confirmed"] = int(
		stage_progression.get("upgrades_confirmed", 0)
	) + 1
	run_progression["upgrades_confirmed"] = int(
		run_progression.get("upgrades_confirmed", 0)
	) + 1
	if _upgrade_opened_at < 0.0:
		return
	var duration := maxf(0.0, run_seconds - _upgrade_opened_at)
	stage_progression["modal_seconds"] = float(
		stage_progression.get("modal_seconds", 0.0)
	) + duration
	run_progression["modal_seconds"] = float(
		run_progression.get("modal_seconds", 0.0)
	) + duration
	stage_progression["last_confirmation_seconds"] = duration
	run_progression["last_confirmation_seconds"] = duration
	_upgrade_opened_at = -1.0


func record_tactic_event(tactic_id: StringName, phase: StringName) -> void:
	if tactic_id.is_empty() or phase.is_empty():
		return
	var key := StringName("%s:%s" % [String(tactic_id), String(phase)])
	_add_bounded(stage_tactics, key, 1, MAX_TACTIC_EVENTS)
	_add_bounded(run_tactics, key, 1, MAX_TACTIC_EVENTS)


func record_boss_lifecycle(
	boss_id: StringName,
	cleanup_started: bool = false,
	cleanup_completed: bool = false,
	owned_count: int = 0,
	cleanup_seconds: float = 0.0
) -> void:
	if boss_id.is_empty():
		return
	boss_actor["id"] = boss_id
	boss_actor["cleanup_started"] = bool(boss_actor.get("cleanup_started", false)) or cleanup_started
	boss_actor["cleanup_completed"] = bool(boss_actor.get("cleanup_completed", false)) or cleanup_completed
	boss_actor["owned_count"] = maxi(int(boss_actor.get("owned_count", 0)), owned_count)
	if cleanup_seconds > 0.0:
		boss_actor["cleanup_seconds"] = cleanup_seconds


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
		"family_defeats":run_family_defeats.duplicate(),
		"traits":run_traits.duplicate(),
		"tactics":run_tactics.duplicate(),
		"attack_commits":run_attack_commits.duplicate(),
		"progression":run_progression.duplicate(true),
	}


func _stage_snapshot() -> Dictionary:
	return {
		"outgoing":stage_outgoing.duplicate(),
		"attributes":stage_attributes.duplicate(),
		"status_applications":stage_status_applications.duplicate(),
		"incoming":stage_incoming.duplicate(),
		"defeats":stage_defeats.duplicate(),
		"family_defeats":stage_family_defeats.duplicate(),
		"traits":stage_traits.duplicate(),
		"family_traits":stage_family_traits.duplicate(),
		"tactics":stage_tactics.duplicate(),
		"attack_commits":stage_attack_commits.duplicate(),
		"progression":stage_progression.duplicate(true),
		"boss":boss_actor.duplicate(),
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
