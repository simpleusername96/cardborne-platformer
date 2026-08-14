extends SceneTree

const PacingCapture = preload(
	"res://scripts/diagnostics/vehicle_encounter_pacing_capture.gd"
)
const CaptureDriver = preload(
	"res://scripts/diagnostics/vehicle_encounter_pacing_capture_driver.gd"
)
const RUN_PATH := "res://scripts/vehicle/vehicle_run.gd"

var failures: Array[String] = []


func _initialize() -> void:
	var capture := PacingCapture.new()
	var identity := {
		"schema_version": 1, "identity_status": "resolved", "commit": "a".repeat(40),
		"ref": "fixture", "source_cleanliness": "clean", "content_fingerprint": "b".repeat(64),
	}
	_expect(capture.begin("evidence-fixture-001", identity), "capture starts from one evidence ID")
	_expect(not capture.record_lifecycle(&"unknown", 0.0), "undeclared lifecycle is rejected")
	_expect(capture.record_lifecycle(&"cue", 0.0), "cue lifecycle is retained")
	_expect(capture.record_lifecycle(&"birth", 0.9), "birth lifecycle is retained")
	_expect(capture.record_lifecycle(&"first_visible", 3.5), "first-visible lifecycle is retained")
	_expect(capture.record_lifecycle(&"first_commit_or_damage", 8.0), "commit lifecycle is retained")
	for checkpoint_id in PacingCapture.REQUIRED_TIME_CHECKPOINTS:
		_expect(
			capture.record_checkpoint(
				checkpoint_id,
				float(PacingCapture.REQUIRED_TIME_CHECKPOINTS[checkpoint_id]),
				_snapshot(checkpoint_id)
			),
			"required time checkpoint %s is retained" % checkpoint_id
		)
	for checkpoint_id in PacingCapture.REQUIRED_TRANSITION_CHECKPOINTS:
		var elapsed_seconds := (
			33.0 if checkpoint_id == &"post_boss_3" else 30.0
		)
		_expect(
			capture.record_checkpoint(checkpoint_id, elapsed_seconds, _snapshot(checkpoint_id)),
			"transition checkpoint %s is retained" % checkpoint_id
		)
	var bundle := capture.bundle()
	_expect(not bundle.is_empty(), "complete pacing capture emits one bounded bundle")
	_expect(String(bundle.get("evidence_id", "")) == "evidence-fixture-001", "bundle preserves evidence ID")
	var provenance := Dictionary(bundle.get("provenance", {}))
	_expect(
		int(bundle.get("registry_version", 0)) == 1
			and String(Dictionary(bundle.get("build_identity", {})).get("commit", "")) == "a".repeat(40)
			and String(provenance.get("artifact_kind", "")) == "encounter_pacing_capture"
			and String(provenance.get("scenario", "")) == "opening_boss_overlap"
			and int(provenance.get("seed", -1)) == 0xC4A2B0
			and not String(provenance.get("utc_started", "")).is_empty(),
		"bundle uses the shared build identity and diagnostic provenance envelope"
	)
	_expect(Array(bundle.get("checkpoints", [])).size() == 13, "bundle retains eight time and five transition checkpoints")
	var first := Dictionary(Array(bundle.get("checkpoints", []))[0])
	_expect(
		StringName(first.get("checkpoint_id", &"")) == &"t_0"
			and first.has("exact_count")
			and first.has("active_count")
			and first.has("visible_gap_active")
			and first.has("reserve_count")
			and first.has("queued_spawns")
			and first.has("boss_slot_margin")
			and Dictionary(first.get("scan_counts", {})).has(&"pressure"),
		"checkpoint records the required bounded pacing fields"
	)
	var incomplete := PacingCapture.new()
	_expect(incomplete.begin("incomplete"), "incomplete fixture starts")
	_expect(incomplete.bundle().is_empty(), "partial capture never emits a misleading bundle")
	var invalid_time := PacingCapture.new()
	_expect(invalid_time.begin("invalid-time"), "invalid-time fixture starts")
	_expect(not invalid_time.record_checkpoint(&"t_1", 1.1, _snapshot(&"t_1")), "fixed checkpoints reject timing drift")
	_expect(
		not invalid_time.record_checkpoint(&"post_boss_3", 3.0, _snapshot(&"post_boss_3")),
		"post-boss checkpoint requires the boss-defeat anchor"
	)
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	_expect(
		run_source.contains("--encounter-pacing-output=")
			and run_source.contains("--encounter-pacing-evidence-id=")
			and run_source.contains("--encounter-pacing-expected-commit=")
			and run_source.contains("--encounter-pacing-expected-fingerprint=")
			and run_source.contains("_start_encounter_pacing_capture"),
		"explicit diagnostic request owns the bounded versioned capture entry path"
)
	_expect(
		CaptureDriver.identity_matches_expected(
			identity, "a".repeat(40), "b".repeat(64)
		)
			and not CaptureDriver.identity_matches_expected(
				identity, "c".repeat(40), "b".repeat(64)
			),
		"capture refuses a stale generated build identity"
	)
	_expect(
		CaptureDriver.is_safe_output_path("res://build/performance/pacing.json")
			and not CaptureDriver.is_safe_output_path("user://unsafe.json")
			and run_source.contains("_encounter_pacing_capture_driver.succeeded()"),
		"diagnostic path bounds output and reports incomplete capture failure"
	)
	_expect(
		run_source.contains("retain_pacing_capture_flags")
			and run_source.contains("not _session_diagnostics.is_active() and not retain_pacing_capture_flags"),
		"pacing capture retains visibility and commit flags without starting a synthetic session"
	)
	_finish()


func _snapshot(checkpoint_id: StringName) -> Dictionary:
	return {
		"exact_count": 8 if checkpoint_id == &"boss_active" else 6,
		"active_count": 6,
		"visible_ordinary_count": 3,
		"visible_gap_active": checkpoint_id == &"t_0",
		"reserve_count": 42,
		"queued_windows": 0,
		"queued_spawns": 0,
		"reserved_arrival_slots": 0,
		"boss_slot_margin": 1,
		"scan_counts": {&"pressure": 1, &"contact": 1, &"anomaly": 0},
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENCOUNTER_PACING_CAPTURE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
