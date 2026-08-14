class_name VehicleSessionSignalRecorder
extends RefCounted

## Lifecycle-only diagnostic accumulator. It owns no files and frame sampling only
## mutates fixed counters; callers decide which safe boundary persists a completed run.

const SCHEMA_VERSION := 1
const REGISTRY_VERSION := 1
const MAX_EVENTS := 256
const MAX_SECOND_BUCKETS := 1800
const EVENT_KINDS := {
	"run_started": true, "stage_started": true, "stage_ended": true,
	"arrival_cued": true, "arrival_began": true, "first_visible": true,
	"first_commit": true, "visible_gap_closed": true,
	"boss_warning": true, "boss_started": true, "boss_ended": true,
	"upgrade_opened": true, "upgrade_focused": true, "upgrade_confirmed": true,
	"announcement_queued": true, "announcement_shown": true,
	"announcement_interrupted": true, "announcement_dropped": true,
	"anomaly_revealed": true, "anomaly_activated": true, "anomaly_retired": true,
	"layout_fault": true, "result_shown": true, "run_completed": true,
	"run_failed": true,
}

var _session_id := ""
var _build_identity: Dictionary = {}
var _session_context: Dictionary = {}
var _started_unix := 0
var _sequence := 0
var _elapsed_seconds := 0.0
var _events: Array[Dictionary] = []
var _event_dropped := 0
var _seconds: Array[Dictionary] = []
var _second_elapsed := 0.0
var _second_frames := 0
var _second_frame_ms := 0.0
var _second_max_frame_ms := 0.0
var _second_exact_enemy_total := 0
var _second_exact_enemy_max := 0
var _second_visible_frames := 0
var _second_stage_index := 0
var _second_run_mode: StringName = &"unknown"
var _active := false


func begin(
	session_id: String,
	build_identity: Dictionary,
	session_context: Dictionary = {}
) -> bool:
	reset()
	if session_id.is_empty() or not VehicleBuildIdentity.is_session_usable(build_identity):
		return false
	_session_id = session_id
	_build_identity = build_identity.duplicate(true)
	_session_context = session_context.duplicate(true)
	_started_unix = int(Time.get_unix_time_from_system())
	_active = true
	emit_event("run_started", {})
	return true


func reset() -> void:
	_session_id = ""
	_build_identity.clear()
	_session_context.clear()
	_started_unix = 0
	_sequence = 0
	_elapsed_seconds = 0.0
	_events.clear()
	_event_dropped = 0
	_seconds.clear()
	_second_elapsed = 0.0
	_second_frames = 0
	_second_frame_ms = 0.0
	_second_max_frame_ms = 0.0
	_reset_second_context()
	_active = false


func emit_event(kind: String, fields: Dictionary) -> bool:
	if not _active or not EVENT_KINDS.has(kind):
		return false
	_sequence += 1
	if _events.size() >= MAX_EVENTS:
		_event_dropped += 1
		return false
	_events.append({
		"schema_version": SCHEMA_VERSION,
		"registry_version": REGISTRY_VERSION,
		"sequence": _sequence,
		"monotonic_seconds": _elapsed_seconds,
		"kind": kind,
		"fields": _semantic_fields(fields),
	})
	return true


func advance_frame(
	delta: float,
	frame_ms: float,
	exact_enemy_count: int = 0,
	visible_threat: bool = false,
	stage_index: int = 0,
	run_mode: StringName = &"unknown"
) -> void:
	if not _active:
		return
	_elapsed_seconds += maxf(0.0, delta)
	_second_elapsed += maxf(0.0, delta)
	_second_frames += 1
	_second_frame_ms += maxf(0.0, frame_ms)
	_second_max_frame_ms = maxf(_second_max_frame_ms, frame_ms)
	_second_exact_enemy_total += maxi(0, exact_enemy_count)
	_second_exact_enemy_max = maxi(
		_second_exact_enemy_max, maxi(0, exact_enemy_count)
	)
	if visible_threat:
		_second_visible_frames += 1
	_second_stage_index = maxi(0, stage_index)
	_second_run_mode = run_mode
	if _second_elapsed >= 1.0:
		_retain_second({
			"end_monotonic_seconds": _elapsed_seconds,
			"frames": _second_frames,
			"average_frame_ms": _second_frame_ms / float(maxi(1, _second_frames)),
			"max_frame_ms": _second_max_frame_ms,
			"average_exact_enemy_count":(
				float(_second_exact_enemy_total) / float(maxi(1, _second_frames))
			),
			"max_exact_enemy_count":_second_exact_enemy_max,
			"visible_threat_frame_ratio":(
				float(_second_visible_frames) / float(maxi(1, _second_frames))
			),
			"stage_index":_second_stage_index,
			"run_mode":_second_run_mode,
		})
		_second_elapsed = 0.0
		_second_frames = 0
		_second_frame_ms = 0.0
		_second_max_frame_ms = 0.0
		_reset_second_context()


func finish(reason: String) -> Dictionary:
	if not _active:
		return {}
	if _second_frames > 0:
		_retain_second({"end_monotonic_seconds": _elapsed_seconds, "frames": _second_frames,
			"average_frame_ms": _second_frame_ms / float(maxi(1, _second_frames)),
			"max_frame_ms": _second_max_frame_ms,
			"average_exact_enemy_count":float(_second_exact_enemy_total) / float(maxi(1, _second_frames)),
			"max_exact_enemy_count":_second_exact_enemy_max,
			"visible_threat_frame_ratio":float(_second_visible_frames) / float(maxi(1, _second_frames)),
			"stage_index":_second_stage_index, "run_mode":_second_run_mode})
	_active = false
	return _bundle(reason)


func checkpoint(reason: String) -> Dictionary:
	if not _active:
		return {}
	return _bundle(reason)


func is_active() -> bool:
	return _active


func _bundle(reason: String) -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "kind": "session_diagnostic",
		"registry_version": REGISTRY_VERSION, "session_id": _session_id,
		"started_unix": _started_unix,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"build_identity": _build_identity.duplicate(true),
		"session_context":_session_context.duplicate(true),
		"completed_reason": reason,
		"events": _events.duplicate(true), "one_hz": _seconds.duplicate(true),
		"retention": {"event_cap": MAX_EVENTS, "event_dropped": _event_dropped,
			"one_hz_cap": MAX_SECOND_BUCKETS}}


func _retain_second(second: Dictionary) -> void:
	if _seconds.size() < MAX_SECOND_BUCKETS:
		_seconds.append(second)


func _reset_second_context() -> void:
	_second_exact_enemy_total = 0
	_second_exact_enemy_max = 0
	_second_visible_frames = 0
	_second_stage_index = 0
	_second_run_mode = &"unknown"


func _semantic_fields(fields: Dictionary) -> Dictionary:
	var safe := {}
	for key in fields:
		var name := String(key)
		var value: Variant = fields[key]
		if name.is_valid_identifier() and (value is StringName or value is int or value is float or value is bool):
			safe[name] = value
	return safe
