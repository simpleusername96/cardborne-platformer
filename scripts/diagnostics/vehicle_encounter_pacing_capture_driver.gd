class_name VehicleEncounterPacingCaptureDriver
extends RefCounted

## Diagnostic-only deterministic fixture. It drives existing VehicleRun owners
## and writes one pacing bundle; normal play never creates this object.

const Capture = preload("res://scripts/diagnostics/vehicle_encounter_pacing_capture.gd")
const BuildIdentity = preload("res://scripts/diagnostics/vehicle_build_identity.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")

const OUTPUT_DIRECTORY := "res://build/performance/"
const RESULT_PREFIX := "ENCOUNTER_PACING_CAPTURE_WRITTEN "

var _output_path := ""
var _capture := Capture.new()
var _time_index := 0
var _boss_fixture_started := false
var _boss_defeated := false
var _boss_defeat_elapsed := -1.0
var _succeeded := false


static func is_safe_output_path(path: String) -> bool:
	if not path.begins_with(OUTPUT_DIRECTORY):
		return false
	var file_name := path.trim_prefix(OUTPUT_DIRECTORY)
	return (
		not file_name.is_empty()
		and not file_name.contains("/")
		and not file_name.contains("\\")
		and file_name.ends_with(".json")
	)


static func identity_matches_expected(
	identity: Dictionary,
	expected_commit: String,
	expected_fingerprint: String
) -> bool:
	return (
		BuildIdentity.is_complete(identity)
		and expected_commit.length() == 40
		and expected_commit.is_valid_hex_number()
		and expected_fingerprint.length() == 64
		and expected_fingerprint.is_valid_hex_number()
		and String(identity.get("commit", "")).to_lower() == expected_commit.to_lower()
		and String(identity.get("content_fingerprint", "")).to_lower()
			== expected_fingerprint.to_lower()
	)


func configure(
	output_path: String,
	evidence_id: String,
	expected_commit: String,
	expected_fingerprint: String
) -> bool:
	if not is_safe_output_path(output_path) or FileAccess.file_exists(ProjectSettings.globalize_path(output_path)):
		return false
	var identity := BuildIdentity.evidence_identity()
	if not identity_matches_expected(identity, expected_commit, expected_fingerprint):
		return false
	if not _capture.begin(evidence_id, identity):
		return false
	_output_path = output_path
	return true


func start(run: Node) -> void:
	run.call("_reset_run", false)
	run.mode = run.RunMode.PLAYING
	run.player_invulnerable = 999.0
	run.encounter_runtime.set_pressure_observation_enabled(true)
	_capture_checkpoint(run, &"t_0", 0.0)


func after_physics(run: Node) -> bool:
	_record_lifecycle(run)
	var elapsed := float(run.active_run_elapsed_seconds)
	while _time_index < Capture.REQUIRED_TIME_CHECKPOINTS.size():
		var checkpoint_id: StringName = Capture.REQUIRED_TIME_CHECKPOINTS.keys()[_time_index]
		var target := float(Capture.REQUIRED_TIME_CHECKPOINTS[checkpoint_id])
		if elapsed + 0.0001 < target:
			break
		if checkpoint_id != &"t_0":
			_capture_checkpoint(run, checkpoint_id, target)
		_time_index += 1
	if not _boss_fixture_started and _time_index >= Capture.REQUIRED_TIME_CHECKPOINTS.size():
		_start_boss_overlap_fixture(run, elapsed)
		return false
	if _boss_fixture_started and not _boss_defeated:
		if run.stage_flow.state == StageFlow.State.BOSS_ACTIVE and run.boss_started:
			_capture_checkpoint(run, &"boss_active", elapsed)
			_defeat_fixture_boss(run)
			# Stage continuation reconfigures the encounter runtime and correctly
			# disables diagnostic scans by default. Re-enable them for this explicit
			# capture so the post-boss checkpoint observes the new stage.
			run.encounter_runtime.set_pressure_observation_enabled(true)
			_boss_defeated = true
			_boss_defeat_elapsed = elapsed
			_capture_checkpoint(run, &"boss_defeat", elapsed)
		return false
	if _boss_defeated and elapsed + 0.0001 >= _boss_defeat_elapsed + 3.0:
		_capture_checkpoint(run, &"post_boss_3", _boss_defeat_elapsed + 3.0)
		return _finish()
	return false


func succeeded() -> bool:
	return _succeeded


func _record_lifecycle(run: Node) -> void:
	var scheduler: Dictionary = run.encounter_runtime.debug_snapshot()
	var cue_time := float(scheduler.get("first_cue_time", -1.0))
	if cue_time >= 0.0:
		_capture.record_lifecycle(&"cue", cue_time)
	var birth_time := float(scheduler.get("first_spawn_time", -1.0))
	if birth_time >= 0.0:
		_capture.record_lifecycle(&"birth", birth_time)
	if bool(run.get("_diagnostic_first_visible")):
		_capture.record_lifecycle(&"first_visible", float(run.active_run_elapsed_seconds))
	if bool(run.get("_diagnostic_first_commit")):
		_capture.record_lifecycle(&"first_commit_or_damage", float(run.active_run_elapsed_seconds))


func _start_boss_overlap_fixture(run: Node, elapsed: float) -> void:
	_boss_fixture_started = true
	run.call("_clear_enemies")
	for index in 8:
		var enemy = run.call("_make_enemy", {
			"id":"pacing_overlap_%02d" % index,
			"role":&"chaser",
			"pos":run.player_position + Vector2(300.0 + float(index) * 12.0, 0.0),
			"active":true,
		})
		if enemy != null:
			run.call("_append_enemy", enemy)
	run.stage_flow.defeats = run.stage_flow.quota - 1
	for enemy in run.enemies:
		if enemy.alive and bool(run.call("_is_countable_stage_enemy", enemy)):
			run.call(
				"_damage_enemy", enemy, enemy.max_health + 1.0,
				"pacing_capture", &"kinetic", true, true, false
			)
			break
	_capture_checkpoint(run, &"quota", elapsed)
	_capture_checkpoint(run, &"boss_warning", elapsed)
	run.call("_update_stage_progression", 1.5)


func _defeat_fixture_boss(run: Node) -> void:
	for enemy in run.enemies:
		if enemy.alive and enemy.role == &"stage_boss":
			run.call(
				"_damage_enemy", enemy, enemy.max_health + 1.0,
				"pacing_capture", &"kinetic", true, true, false
			)
			return


func _capture_checkpoint(run: Node, checkpoint_id: StringName, elapsed: float) -> void:
	var scheduler: Dictionary = run.encounter_runtime.debug_snapshot()
	_capture.record_checkpoint(checkpoint_id, elapsed, {
		"exact_count":run.enemy_store.live_count(),
		"active_count":run.call("_active_mobile_count"),
		"visible_ordinary_count":run.encounter_runtime.pressure_visible_count(),
		"visible_gap_active":bool(run.get("_diagnostic_visible_gap_active")),
		"reserve_count":int(scheduler.get("virtual_reserve", 0)),
		"queued_windows":int(scheduler.get("queued_windows", 0)),
		"queued_spawns":int(scheduler.get("queued_spawns", 0)),
		"reserved_arrival_slots":int(scheduler.get("reserved_arrival_slots", 0)),
		# Free live-store entries remaining after the boss and its reserved add
		# capacity. This is not the materialized ordinary cap.
		"boss_slot_margin":maxi(
			0,
			EnemyStore.MAX_LIVE_HOSTILES
			- run.enemy_store.live_count()
			- BossPhaseCatalog.BOSS_ENTRY_SLOT_RESERVE
		),
		"scan_counts":{
			&"pressure":1 if run.encounter_runtime.pressure_scan_happened() else 0,
			&"threat_contacts":1,
		},
	})


func _finish() -> bool:
	var bundle := _capture.bundle()
	if bundle.is_empty():
		push_error("Encounter pacing capture did not reach every required checkpoint.")
		return true
	if not bool(Dictionary(bundle.get("acceptance", {})).get("passed", false)):
		push_error("Encounter pacing capture failed one or more gameplay gates.")
		return true
	var absolute_path := ProjectSettings.globalize_path(_output_path)
	if DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir()) != OK:
		push_error("Could not create encounter pacing output directory.")
		return true
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write encounter pacing capture: %s" % _output_path)
		return true
	file.store_string(JSON.stringify(bundle, "\t") + "\n")
	file.flush()
	_succeeded = true
	print(RESULT_PREFIX + _output_path)
	return true
