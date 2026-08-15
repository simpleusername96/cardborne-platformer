extends SceneTree

const BuildIdentity = preload("res://scripts/diagnostics/vehicle_build_identity.gd")
const SignalRecorder = preload("res://scripts/diagnostics/vehicle_session_signal_recorder.gd")
const DiagnosticStore = preload("res://scripts/diagnostics/vehicle_session_diagnostic_store.gd")
const Exporter = preload("res://scripts/diagnostics/vehicle_diagnostic_exporter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var unknown := BuildIdentity.dev_unknown()
	_expect(not BuildIdentity.is_complete(unknown), "missing generated identity remains dev_unknown")
	var identity := {
		"schema_version": 1, "identity_status": "resolved", "commit": "a".repeat(40), "ref": "fixture",
		"source_cleanliness": "clean", "content_fingerprint": "b".repeat(64),
	}
	_expect(BuildIdentity.is_complete(identity), "complete commit identity is accepted")
	_expect(BuildIdentity.is_session_usable(BuildIdentity.dev_unknown()), "editor sessions retain explicit dev_unknown identity")
	var recorder := SignalRecorder.new()
	_expect(
		recorder.begin("fixture-session", identity, {
			"locale":&"ko", "viewport_class":&"standard",
			"reduced_motion":false, "renderer":&"gl_compatibility",
		}),
		"session recorder starts with complete identity and UI context"
	)
	_expect(not recorder.emit_event("localized event", {}), "dynamic event names are rejected")
	_expect(recorder.emit_event("stage_started", {"stage_id": &"stage_1", "localized_text": "ignored"}), "declared lifecycle event records semantic fields")
	for fixture_event in [
		{"kind":"first_visible", "fields":{"stage_index":0}},
		{"kind":"boss_warning", "fields":{"stage_index":0}},
		{"kind":"upgrade_focused", "fields":{"upgrade_id":&"thermal_burst"}},
		{"kind":"announcement_shown", "fields":{"semantic_id":&"boss_inbound"}},
		{"kind":"neutral_facility_destroyed", "fields":{"device_id":&"facility_a"}},
		{"kind":"result_shown", "fields":{"stage_count":8}},
	]:
		_expect(
			recorder.emit_event(
				String(fixture_event["kind"]),
				Dictionary(fixture_event["fields"])
			),
			"canonical diagnostic fixture records %s" % fixture_event["kind"]
		)
	for index in 4:
		recorder.advance_frame(
			0.3, 16.0 + index, 10 + index, true, 0, &"playing"
		)
	var bundle := recorder.finish("fixture_complete")
	_expect(Array(bundle.get("events", [])).size() == 8, "bounded lifecycle fixture retains opening, boss, Upgrade, announcement, Anomaly, and Result events")
	_expect(Array(bundle.get("one_hz", [])).size() == 1, "frame sampling produces bounded one-hertz summary")
	var second := Dictionary(Array(bundle.get("one_hz", []))[0])
	_expect(
		int(second.get("max_exact_enemy_count", 0)) == 13
			and is_equal_approx(float(second.get("visible_threat_frame_ratio", 0.0)), 1.0)
			and StringName(second.get("run_mode", &"")) == &"playing"
			and StringName(Dictionary(bundle.get("session_context", {})).get("locale", &"")) == &"ko",
		"one-hertz summary retains bounded pressure and supported UI context"
	)
	_expect(recorder.finish("second_finish").is_empty(), "completed recorder cannot leak state into a second run")
	var checkpoint_recorder := SignalRecorder.new()
	_expect(checkpoint_recorder.begin("checkpoint-session", BuildIdentity.dev_unknown()), "editor diagnostic session starts with dev_unknown identity")
	var checkpoint := checkpoint_recorder.checkpoint("settled_pause")
	_expect(not checkpoint.is_empty() and checkpoint_recorder.is_active() and not checkpoint_recorder.finish("normal_exit").is_empty(), "pause checkpoint does not finish the live recorder")
	_expect(int(checkpoint.get("started_unix", 0)) > 0 and int(checkpoint.get("saved_unix", 0)) > 0, "bundle records comparable local lifecycle timestamps")
	var redacted := Exporter.make_redacted_bundle({
		"registry_version": 1, "build_identity": identity, "completed_reason": "done",
		"session_context":{"locale":&"ko", "viewport_class":&"standard", "reduced_motion":false, "renderer":&"gl_compatibility"},
		"events": [{"session_id": "private", "kind": "stage_started", "fields": {"route": "private", "stage_id": "stage_1", "access_token": "private", "deviceId": "private", "rawPath": "private", "userAgent": "private"}}],
		"one_hz": [],
	})
	var event := Dictionary(Array(redacted.get("events", []))[0])
	var redacted_fields := Dictionary(event.get("fields", {}))
	_expect(
		not event.has("session_id")
		and not redacted_fields.has("route")
		and not redacted_fields.has("access_token")
		and not redacted_fields.has("deviceId")
		and not redacted_fields.has("rawPath")
		and not redacted_fields.has("userAgent"),
		"export redacts stable IDs, routes, paths, browser fields, and secret-like keys"
	)
	_expect(
		StringName(Dictionary(redacted.get("session_context", {})).get("locale", &"")) == &"ko",
		"explicit export preserves non-identifying comparison context"
	)
	_expect(DiagnosticStore.MAX_SESSIONS == 10 and DiagnosticStore.MAX_BYTES == 25 * 1024 * 1024 and DiagnosticStore.MAX_AGE_SECONDS == 14 * 24 * 60 * 60, "store retention contract remains newest 10 sessions / 25 MiB / 14 days")
	_validate_store_and_native_export(bundle)
	_finish()


func _validate_store_and_native_export(source_bundle: Dictionary) -> void:
	const TEST_DIRECTORY := "user://diagnostics-validation"
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	_clear_test_directory(directory)
	_expect(DirAccess.make_dir_recursive_absolute(directory) == OK, "isolated diagnostic test directory is available")
	var corrupt := FileAccess.open(directory.path_join("corrupt.json"), FileAccess.WRITE)
	_expect(corrupt != null, "corrupt fixture can be written")
	if corrupt != null:
		corrupt.store_string("not-json")
		corrupt.close()
	var saved_now := int(Time.get_unix_time_from_system())
	for index in 12:
		var retained := source_bundle.duplicate(true)
		retained["session_id"] = "store-%02d" % index
		retained["saved_unix"] = saved_now - (11 - index)
		_expect(
			DiagnosticStore.persist_completed(retained, TEST_DIRECTORY) == OK,
			"isolated store accepts retained session %d" % index
		)
	var loaded := DiagnosticStore.load_completed(TEST_DIRECTORY)
	_expect(
		loaded.size() == 10
		and String(loaded.front().get("session_id", "")) == "store-11"
		and String(loaded.back().get("session_id", "")) == "store-02",
		"store persists and loads only the newest ten sessions by saved_unix descending"
	)
	var tied := source_bundle.duplicate(true)
	tied["session_id"] = "store-zz"
	tied["saved_unix"] = saved_now
	_expect(
		DiagnosticStore.persist_completed(tied, TEST_DIRECTORY) == OK,
		"store accepts a same-timestamp session for deterministic session-id ordering"
	)
	loaded = DiagnosticStore.load_completed(TEST_DIRECTORY)
	_expect(
		String(loaded.front().get("session_id", "")) == "store-zz"
		and loaded.size() == 10,
		"same-timestamp records use session_id descending without file modification time"
	)
	_expect(
		FileAccess.file_exists(directory.path_join("corrupt.json.quarantine")),
		"corrupt store records are quarantined without blocking later sessions"
	)
	var export_path := directory.path_join("explicit-export.json")
	_expect(
		Exporter.write_native(loaded.back(), export_path) == OK
		and FileAccess.file_exists(export_path),
		"native explicit export writes a redacted JSON bundle"
	)
	_clear_test_directory(directory)


func _clear_test_directory(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(name))
	DirAccess.remove_absolute(directory)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_DIAGNOSTICS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
