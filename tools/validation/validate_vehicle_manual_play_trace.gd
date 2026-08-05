extends SceneTree

const Trace = preload(
	"res://scripts/performance/vehicle_manual_performance_trace.gd"
)
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")
const RunHarness = preload(
	"res://tools/validation/fixtures/vehicle_manual_trace_run_harness.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_path := (
		"res://build/performance/manual/validation-%d-%d.json"
		% [OS.get_process_id(), Time.get_ticks_usec()]
	)
	var absolute_path := ProjectSettings.globalize_path(test_path)
	_expect(
		not FileAccess.file_exists(absolute_path),
		"validator begins with a uniquely owned output path"
	)

	_expect(Trace.is_safe_output_path(test_path), "the canonical manual trace path is safe")
	var parsed_request := VehicleRun._manual_performance_request_from_arguments([
		"--manual-performance-output=%s" % test_path,
	])
	_expect(
		String(parsed_request.get("output", "")) == test_path,
		"VehicleRun parses the explicit manual trace CLI boundary"
	)
	_expect(
		not Trace.is_safe_output_path(
			"res://build/performance/manual/../escaped.json"
		),
		"manual traces reject traversal"
	)
	_expect(
		not Trace.is_safe_output_path(
			"res://build/performance/manual/nested/trace.json"
		),
		"manual traces reject nested output paths"
	)
	_expect(
		not Trace.is_safe_output_path("res://build/performance/manual/trace.txt"),
		"manual traces require JSON output"
	)

	var bounded := Trace.new()
	for index in Trace.MAX_BUCKETS + 2:
		bounded.call("_retain_bucket", {"index":index})
	var bounded_counts := bounded.debug_retained_counts()
	_expect(
		int(bounded_counts["buckets"]) == Trace.MAX_BUCKETS
			and int(bounded_counts["buckets_dropped"]) == 2,
		"one-second bucket storage is a bounded ring"
	)

	var trace := Trace.new()
	_expect(
		trace.configure(
			test_path,
			7,
			{"gameplay_path":"validation", "pressure_source":"fixture"}
		),
		"manual trace accepts one safe explicit output"
	)
	_expect(trace.start(), "configured manual trace starts explicitly")
	trace.record_physics(3.0, {"discarded_fixture":2.0})
	trace.advance_frame(
		0.5, 0.0, 0.0, get_root(), {}, {}, false
	)
	_expect(
		not trace.has_pending_physics(),
		"inactive menu or pause time cannot leak pending physics into gameplay"
	)

	for frame_index in 70:
		trace.record_physics(1.0, {"enemy_update":0.5})
		if frame_index == 69:
			trace.record_physics(1.5, {"enemy_update":0.75})
		var active := 100 + frame_index
		var visible := 30 + frame_index % 10
		var pressure := {
			"enemy_live":active + 4,
			"ordinary_active":active,
			"ordinary_active_cap":276,
			"ordinary_center_in_viewport":visible,
			"ordinary_offscreen_active":active - visible,
			"ordinary_near_600":20,
			"ordinary_near_900":40,
			"ranged_commits":2,
			"denial_commits":1,
			"player_projectiles":12,
			"hostile_projectiles":8,
			"experience_shards":6,
			"effects":5,
			"denied_zones":2,
			"damaging_trails":1,
		}
		trace.advance_frame(
			(21.0 + float(frame_index)) / 1000.0,
			0.4,
			0.2,
			get_root(),
			pressure,
			{
				"stage_id":"stage_3",
				"run_time_seconds":float(frame_index),
				"run_mode":"playing",
			},
			true
		)

	_expect(
		not FileAccess.file_exists(absolute_path),
		"manual trace performs no file I/O while gameplay is recording"
	)
	var result := trace.finish("validation_complete")
	_expect(
		String(result.get("kind", "")) == "manual_play_trace"
			and bool(result.get("diagnostic_only", false))
			and not bool(result.get("authoritative", true))
			and not result.has("thresholds"),
		"manual output cannot impersonate release qualification"
	)
	var sampling := Dictionary(result.get("sampling", {}))
	_expect(
		int(sampling.get("slow_frames_retained", 0)) == Trace.SLOW_FRAME_CAP
			and int(sampling.get("buckets_retained", 0)) <= Trace.MAX_BUCKETS
			and not bool(sampling.get("file_io_during_recording", true)),
		"manual output reports its bounded retention contract"
	)
	var buckets := Array(result.get("frame_buckets", []))
	var first_bucket := Dictionary(buckets[0]) if not buckets.is_empty() else {}
	var bucket_hitches := Dictionary(first_bucket.get("hitches", {}))
	_expect(
		float(sampling.get("bucket_target_seconds", 0.0)) == 1.0
			and int(bucket_hitches.get("frames_over_20_ms", 0)) > 0
			and int(bucket_hitches.get("max_consecutive_over_33_3_ms", 0)) > 0,
		"approximately one-second buckets expose continuous-versus-intermittent hitch counts"
	)
	var summary := Dictionary(result.get("summary", {}))
	var physics_ticks := Dictionary(summary.get("physics_ticks", {}))
	_expect(
		int(summary.get("frame_count", 0)) == 70
			and int(physics_ticks.get("max_per_frame", 0)) == 2
			and int(physics_ticks.get("multi_tick_frames", 0)) == 1,
		"rendered frames retain physics catch-up evidence"
	)
	var slow_frames := Array(result.get("slow_frames", []))
	var slowest := Dictionary(slow_frames[0]) if not slow_frames.is_empty() else {}
	var slowest_pressure := Dictionary(slowest.get("pressure", {}))
	_expect(
		int(slowest.get("physics_ticks", 0)) == 2
			and int(slowest_pressure.get("ordinary_active", 0)) == 169
			and int(slowest_pressure.get("ordinary_center_in_viewport", 0)) == 39
			and int(slowest_pressure.get("ordinary_offscreen_active", 0)) == 130,
		"the slowest frame retains the caller-provided active/visible/offscreen split"
	)
	_expect(
		slowest.get("render_cpu_ms") == null
			and slowest.get("render_gpu_ms") == null,
		"unavailable headless render measurements remain null instead of fake zeroes"
	)

	var encoded := FileAccess.get_file_as_string(absolute_path)
	var parsed: Variant = JSON.parse_string(encoded)
	_expect(
		parsed is Dictionary
			and String(Dictionary(parsed).get("completed_reason", ""))
				== "validation_complete",
		"finished JSON is flushed and immediately readable"
	)
	var second_result := trace.finish("must_not_rewrite")
	var encoded_after_second_finish := FileAccess.get_file_as_string(absolute_path)
	_expect(
		second_result == result and encoded_after_second_finish == encoded,
		"finish is idempotent and never rewrites the first result"
	)
	var overwrite_probe := Trace.new()
	_expect(
		not overwrite_probe.configure(test_path),
		"the recorder itself refuses to overwrite an existing trace"
	)
	DirAccess.remove_absolute(absolute_path)
	_expect(
		not FileAccess.file_exists(absolute_path),
		"validator removes only its exact ignored trace artifact"
	)

	var integration_path := (
		"res://build/performance/manual/integration-%d-%d.json"
		% [OS.get_process_id(), Time.get_ticks_usec()]
	)
	var integration_absolute := ProjectSettings.globalize_path(integration_path)
	_expect(
		not FileAccess.file_exists(integration_absolute),
		"integration begins with a uniquely owned output path"
	)
	var harness = RunHarness.new()
	get_root().add_child(harness)
	await process_frame
	_expect(
		harness._manual_performance_request.is_empty()
			and harness._manual_performance_trace == null,
		"ordinary Run construction leaves manual tracing inactive"
	)
	harness._manual_performance_request = {"output":integration_path}
	harness.call("_prepare_manual_performance_trace")
	_expect(
		harness._manual_performance_trace != null
			and not harness._manual_performance_trace.is_recording(),
		"explicit manual mode configures without starting before deployment"
	)
	harness.call("_start_manual_performance_trace")
	_expect(
		harness._manual_performance_trace.is_recording(),
		"the deployment hook starts the prepared recorder"
	)
	harness._manual_performance_trace.record_physics(1.0, {"integration":0.5})
	harness._manual_performance_trace.advance_frame(
		0.025,
		0.2,
		0.1,
		get_root(),
		{"ordinary_active":3, "ordinary_center_in_viewport":2},
		{"stage_id":"stage_1", "run_mode":"playing"},
		true
	)
	harness.queue_free()
	await process_frame
	var integration_parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(integration_absolute)
	)
	_expect(
		integration_parsed is Dictionary
			and String(Dictionary(integration_parsed).get("completed_reason", ""))
				== "normal_exit",
		"Run exit flushes the manual trace exactly through its lifecycle hook"
	)
	DirAccess.remove_absolute(integration_absolute)
	_expect(
		not FileAccess.file_exists(integration_absolute),
		"integration validator removes only its uniquely owned trace"
	)
	var conflict_path := (
		"res://build/performance/manual/conflict-%d-%d.json"
		% [OS.get_process_id(), Time.get_ticks_usec()]
	)
	var conflict_absolute := ProjectSettings.globalize_path(conflict_path)
	_expect(
		not FileAccess.file_exists(conflict_absolute),
		"mode-conflict check begins with a uniquely owned output path"
	)
	var conflict_harness = RunHarness.new()
	get_root().add_child(conflict_harness)
	await process_frame
	conflict_harness._performance_request = {"scenario":"peak_horde"}
	conflict_harness._manual_performance_request = {"output":conflict_path}
	conflict_harness.call("_prepare_manual_performance_trace")
	_expect(
		conflict_harness._manual_performance_request.is_empty()
			and conflict_harness._manual_performance_trace == null,
		"manual tracing cannot mix with a synthetic performance scenario"
	)
	conflict_harness.queue_free()
	await process_frame
	_expect(
		not FileAccess.file_exists(conflict_absolute),
		"a rejected mixed mode never creates output"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_MANUAL_PLAY_TRACE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
