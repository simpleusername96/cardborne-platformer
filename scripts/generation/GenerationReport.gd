class_name GenerationReport
extends RefCounted

var _run_seed: int
var _stage_index: int
var _profile_id: StringName
var _profile_content_version: int
var _room_catalog_id: StringName
var _room_catalog_content_version: int
var _attempt: int
var _fallback_used: bool
var _fallback_id: StringName
var _rng_stream_seeds: Dictionary
var _decisions: Array[Dictionary] = []
var _failures: Array[Dictionary] = []
var _attempt_failures: Array[Dictionary] = []

var run_seed: int:
	get:
		return _run_seed
var stage_index: int:
	get:
		return _stage_index
var profile_id: StringName:
	get:
		return _profile_id
var attempt: int:
	get:
		return _attempt
var fallback_used: bool:
	get:
		return _fallback_used


func _init(
	report_run_seed: int = 0,
	report_stage_index: int = 0,
	stage_profile_id: StringName = &"",
	stage_profile_content_version: int = 0,
	catalog_id: StringName = &"",
	catalog_content_version: int = 0,
	stream_seeds: Dictionary = {},
	report_attempt: int = 0
) -> void:
	_run_seed = report_run_seed
	_stage_index = report_stage_index
	_profile_id = stage_profile_id
	_profile_content_version = stage_profile_content_version
	_room_catalog_id = catalog_id
	_room_catalog_content_version = catalog_content_version
	_rng_stream_seeds = stream_seeds.duplicate(true)
	_attempt = report_attempt


func record_decision(code: StringName, details: Dictionary = {}) -> void:
	_decisions.append({"code": String(code), "details": details.duplicate(true)})


func record_failure(code: StringName, message: String) -> void:
	_failures.append({"code": String(code), "message": message})


func record_validation_errors(errors: PackedStringArray) -> void:
	for error in errors:
		record_failure(&"validation", error)


func record_attempt_failure(attempt: int, code: StringName, message: String) -> void:
	_attempt_failures.append({
		"attempt": attempt,
		"code": String(code),
		"message": message,
	})


func mark_fallback(fallback_id: StringName) -> void:
	_fallback_used = true
	_fallback_id = fallback_id


func is_successful() -> bool:
	return _failures.is_empty()


func get_rng_stream_seeds() -> Dictionary:
	return _rng_stream_seeds.duplicate(true)


func get_decisions() -> Array[Dictionary]:
	return _decisions.duplicate(true)


func get_failures() -> Array[Dictionary]:
	return _failures.duplicate(true)


func get_attempt_failures() -> Array[Dictionary]:
	return _attempt_failures.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"run_seed": _run_seed,
		"stage_index": _stage_index,
		"profile_id": String(_profile_id),
		"profile_content_version": _profile_content_version,
		"room_catalog_id": String(_room_catalog_id),
		"room_catalog_content_version": _room_catalog_content_version,
		"attempt": _attempt,
		"fallback_used": _fallback_used,
		"fallback_id": String(_fallback_id),
		"rng_stream_seeds": _rng_stream_seeds.duplicate(true),
		"decisions": get_decisions(),
		"attempt_failures": get_attempt_failures(),
		"failures": get_failures(),
	}
