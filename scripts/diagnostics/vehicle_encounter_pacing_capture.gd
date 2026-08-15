class_name VehicleEncounterPacingCapture
extends RefCounted

## Bounded semantic pacing evidence for one deterministic run. The caller owns
## simulation and persistence; this collector only normalizes its observations.

const SCHEMA_VERSION := 1
const REGISTRY_VERSION := 1
const BuildIdentity = preload("res://scripts/diagnostics/vehicle_build_identity.gd")
const REQUIRED_TIME_CHECKPOINTS := {
	&"t_0": 0.0,
	&"t_1": 1.0,
	&"t_3_5": 3.5,
	&"t_5": 5.0,
	&"t_6": 6.0,
	&"t_8": 8.0,
	&"t_15": 15.0,
	&"t_30": 30.0,
}
const REQUIRED_TRANSITION_CHECKPOINTS := [
	&"quota", &"boss_warning", &"boss_active", &"boss_defeat",
	&"boss_cleanup_complete", &"post_boss_3",
]
const REQUIRED_LIFECYCLE_EVENTS := [
	&"cue", &"birth", &"first_visible", &"first_attack_preparation",
]
const MAX_SCAN_OWNERS := 16
const GAP_REASONS: Array[StringName] = [
	&"none", &"awaiting_birth", &"allocator_retry", &"arrival_capacity",
	&"awaiting_cue", &"authored_reserve_exhausted", &"maintenance_low_watermark",
	&"maintenance_interval", &"packet_fence", &"spawning_stopped",
	&"awaiting_packet_trigger",
]

var _evidence_id := ""
var _build_identity: Dictionary = {}
var _started_utc := ""
var _checkpoints: Dictionary = {}
var _lifecycle: Dictionary = {}


func begin(evidence_id: String, build_identity: Dictionary = {}) -> bool:
	reset()
	if evidence_id.is_empty():
		return false
	_evidence_id = evidence_id
	_build_identity = (
		build_identity.duplicate(true)
		if not build_identity.is_empty()
		else BuildIdentity.evidence_identity()
	)
	if not BuildIdentity.is_session_usable(_build_identity):
		reset()
		return false
	_started_utc = Time.get_datetime_string_from_system(true, true)
	return true


func reset() -> void:
	_evidence_id = ""
	_build_identity.clear()
	_started_utc = ""
	_checkpoints.clear()
	_lifecycle.clear()


func record_lifecycle(kind: StringName, elapsed_seconds: float) -> bool:
	if _evidence_id.is_empty() or kind not in REQUIRED_LIFECYCLE_EVENTS:
		return false
	if _lifecycle.has(kind):
		return true
	_lifecycle[kind] = maxf(0.0, elapsed_seconds)
	return true


func record_checkpoint(
	checkpoint_id: StringName,
	elapsed_seconds: float,
	snapshot: Dictionary
) -> bool:
	if _evidence_id.is_empty() or not _is_known_checkpoint(checkpoint_id):
		return false
	if _checkpoints.has(checkpoint_id) or not _matches_required_time(checkpoint_id, elapsed_seconds):
		return false
	if (
		checkpoint_id == &"post_boss_3"
		and (
			not _checkpoints.has(&"boss_cleanup_complete")
			or not is_equal_approx(
				elapsed_seconds,
				float(_checkpoints[&"boss_cleanup_complete"]["elapsed_seconds"]) + 3.0
			)
		)
	):
		return false
	var normalized := _normalize_snapshot(snapshot)
	if normalized.is_empty():
		return false
	_checkpoints[checkpoint_id] = {
		"elapsed_seconds": maxf(0.0, elapsed_seconds),
		"exact_count": int(normalized["exact_count"]),
		"active_count": int(normalized["active_count"]),
		"visible_ordinary_count": int(normalized["visible_ordinary_count"]),
		"visible_gap_active": bool(normalized["visible_gap_active"]),
		"reserve_count": int(normalized["reserve_count"]),
		"queued_windows": int(normalized["queued_windows"]),
		"queued_spawns": int(normalized["queued_spawns"]),
		"reserved_arrival_slots": int(normalized["reserved_arrival_slots"]),
		"boss_slot_margin": int(normalized["boss_slot_margin"]),
		"scheduler_gap_reason": StringName(normalized["scheduler_gap_reason"]),
		"scheduler_gap_seconds": float(normalized["scheduler_gap_seconds"]),
		"scan_counts": Dictionary(normalized["scan_counts"]),
	}
	return true


func is_complete() -> bool:
	if _evidence_id.is_empty():
		return false
	for checkpoint_id in REQUIRED_TIME_CHECKPOINTS:
		if not _checkpoints.has(checkpoint_id):
			return false
	for checkpoint_id in REQUIRED_TRANSITION_CHECKPOINTS:
		if not _checkpoints.has(checkpoint_id):
			return false
	for kind in REQUIRED_LIFECYCLE_EVENTS:
		if not _lifecycle.has(kind):
			return false
	return true


func bundle() -> Dictionary:
	if not is_complete():
		return {}
	var ordered_checkpoints: Array[Dictionary] = []
	for checkpoint_id in REQUIRED_TIME_CHECKPOINTS:
		ordered_checkpoints.append(_checkpoint_entry(checkpoint_id))
	for checkpoint_id in REQUIRED_TRANSITION_CHECKPOINTS:
		ordered_checkpoints.append(_checkpoint_entry(checkpoint_id))
	var lifecycle: Dictionary = {}
	for kind in REQUIRED_LIFECYCLE_EVENTS:
		lifecycle[kind] = float(_lifecycle[kind])
	return {
		"schema_version": SCHEMA_VERSION,
		"registry_version": REGISTRY_VERSION,
		"kind": "encounter_pacing_capture",
		"evidence_id": _evidence_id,
		"build_identity": _build_identity.duplicate(true),
		"provenance": {
			"schema_version": 1,
			"artifact_kind": "encounter_pacing_capture",
			"scenario": "opening_boss_overlap",
			"seed": 0xC4A2B0,
			"utc_started": _started_utc,
			"utc_finished": Time.get_datetime_string_from_system(true, true),
			"status": "diagnostic",
		},
		"lifecycle": lifecycle,
		"checkpoints": ordered_checkpoints,
		"acceptance": acceptance(),
	}


func acceptance() -> Dictionary:
	if not is_complete():
		return {"passed":false, "checks":{}}
	var boss_active: Dictionary = _checkpoints[&"boss_active"]
	var post_boss: Dictionary = _checkpoints[&"post_boss_3"]
	var checks := {
		"first_visible_by_4s":float(_lifecycle[&"first_visible"]) <= 4.0,
		"first_attack_preparation_by_8s":float(_lifecycle[&"first_attack_preparation"]) <= 8.0,
		"boss_slot_margin_nonnegative":int(boss_active["boss_slot_margin"]) >= 0,
		"post_cleanup_visible_by_3s":int(post_boss["visible_ordinary_count"]) >= 1,
	}
	var passed := true
	for value in checks.values():
		passed = passed and bool(value)
	return {"passed":passed, "checks":checks}


func _checkpoint_entry(checkpoint_id: StringName) -> Dictionary:
	var entry: Dictionary = _checkpoints[checkpoint_id]
	return {
		"checkpoint_id": checkpoint_id,
		"elapsed_seconds": float(entry["elapsed_seconds"]),
		"exact_count": int(entry["exact_count"]),
		"active_count": int(entry["active_count"]),
		"visible_ordinary_count": int(entry["visible_ordinary_count"]),
		"visible_gap_active": bool(entry["visible_gap_active"]),
		"reserve_count": int(entry["reserve_count"]),
		"queued_windows": int(entry["queued_windows"]),
		"queued_spawns": int(entry["queued_spawns"]),
		"reserved_arrival_slots": int(entry["reserved_arrival_slots"]),
		"boss_slot_margin": int(entry["boss_slot_margin"]),
		"scheduler_gap_reason": StringName(entry["scheduler_gap_reason"]),
		"scheduler_gap_seconds": float(entry["scheduler_gap_seconds"]),
		"scan_counts": Dictionary(entry["scan_counts"]).duplicate(),
	}


func _is_known_checkpoint(checkpoint_id: StringName) -> bool:
	return (
		REQUIRED_TIME_CHECKPOINTS.has(checkpoint_id)
		or checkpoint_id in REQUIRED_TRANSITION_CHECKPOINTS
	)


func _matches_required_time(checkpoint_id: StringName, elapsed_seconds: float) -> bool:
	if not REQUIRED_TIME_CHECKPOINTS.has(checkpoint_id):
		return elapsed_seconds >= 0.0
	return is_equal_approx(
		elapsed_seconds, float(REQUIRED_TIME_CHECKPOINTS[checkpoint_id])
	)


func _normalize_snapshot(snapshot: Dictionary) -> Dictionary:
	for field in [
		"exact_count", "active_count", "visible_ordinary_count", "reserve_count",
		"queued_windows", "queued_spawns", "reserved_arrival_slots", "boss_slot_margin",
	]:
		if not snapshot.has(field) or int(snapshot[field]) < 0:
			return {}
	if (
		not snapshot.has("visible_gap_active")
		or not snapshot.has("scan_counts")
		or not snapshot.has("scheduler_gap_reason")
		or not snapshot.has("scheduler_gap_seconds")
	):
		return {}
	var gap_reason := StringName(snapshot["scheduler_gap_reason"])
	if gap_reason not in GAP_REASONS or float(snapshot["scheduler_gap_seconds"]) < 0.0:
		return {}
	var scan_counts := Dictionary(snapshot["scan_counts"])
	if scan_counts.size() > MAX_SCAN_OWNERS:
		return {}
	var normalized_scans := {}
	for owner in scan_counts:
		var owner_id := StringName(owner)
		if owner_id.is_empty() or int(scan_counts[owner]) < 0:
			return {}
		normalized_scans[owner_id] = int(scan_counts[owner])
	return {
		"exact_count": int(snapshot["exact_count"]),
		"active_count": int(snapshot["active_count"]),
		"visible_ordinary_count": int(snapshot["visible_ordinary_count"]),
		"visible_gap_active": bool(snapshot["visible_gap_active"]),
		"reserve_count": int(snapshot["reserve_count"]),
		"queued_windows": int(snapshot["queued_windows"]),
		"queued_spawns": int(snapshot["queued_spawns"]),
		"reserved_arrival_slots": int(snapshot["reserved_arrival_slots"]),
		"boss_slot_margin": int(snapshot["boss_slot_margin"]),
		"scheduler_gap_reason": gap_reason,
		"scheduler_gap_seconds": float(snapshot["scheduler_gap_seconds"]),
		"scan_counts": normalized_scans,
	}
