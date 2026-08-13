class_name VehicleManualPerformanceTrace
extends RefCounted

## Bounded, diagnostic-only frame correlation for user-controlled native play.
## It never owns gameplay state, release thresholds, synthetic fixtures, or input.

const OUTPUT_DIRECTORY := "res://build/performance/manual/"
const DETAIL_SAMPLE_STRIDE_DEFAULT := 7
const BUCKET_TARGET_SECONDS := 1.0
const MAX_BUCKETS := 3600
const SLOW_FRAME_CAP := 64
const SLOW_FRAME_MIN_MS := 20.0

const PRESSURE_FIELDS := [
	"enemy_live",
	"ordinary_authored_pressure_cap",
	"ordinary_materialized_cap",
	"ordinary_virtual_reserve",
	"ordinary_quota_canceled_reserve",
	"ordinary_reserved_arrival_slots",
	"ordinary_materialized",
	"ordinary_center_in_viewport",
	"ordinary_offscreen_active",
	"ordinary_near_600",
	"ordinary_near_900",
	"ranged_commits",
	"denial_commits",
	"player_projectiles",
	"hostile_projectiles",
	"experience_shards",
	"effects",
	"denied_zones",
]

## These names deliberately distinguish logical encounter pressure from exact
## instantiated actors. This trace is diagnostic evidence, never a release gate.
const PRESSURE_FIELD_DEFINITIONS := {
	"enemy_live":"All currently instantiated enemy-store actors, including non-ordinary actors.",
	"ordinary_authored_pressure_cap":"The stage's logical authored ordinary-pressure target; it is not an instantiated-actor count.",
	"ordinary_materialized_cap":"The maximum concurrently instantiated ordinary actors for the current stage.",
	"ordinary_virtual_reserve":"Scheduled authored ordinary units that are not instantiated and therefore have no combat state.",
	"ordinary_quota_canceled_reserve":"Authored ordinary units canceled when the defeat quota sealed new admissions.",
	"ordinary_reserved_arrival_slots":"Materialized-cap slots held by already-cued arrivals that have not instantiated yet.",
	"ordinary_materialized":"Currently instantiated ordinary actors with exact simulation and combat state.",
	"ordinary_center_in_viewport":"Materialized ordinary actors whose center is inside the visible world rectangle.",
	"ordinary_offscreen_active":"ordinary_materialized minus ordinary_center_in_viewport.",
}

var output_path := ""

var _configured := false
var _recording := false
var _finished := false
var _detail_sample_stride := DETAIL_SAMPLE_STRIDE_DEFAULT
var _session_metadata: Dictionary = {}
var _finished_result: Dictionary = {}
var _engagement_telemetry: Dictionary = {}
var _viewport: Viewport

var _started_unix_time := 0.0
var _initial_static_memory := 0.0
var _active_seconds := 0.0
var _frame_serial := 0
var _frame_count := 0
var _frame_ms_total := 0.0
var _frame_ms_max := 0.0
var _physics_ms_total := 0.0
var _physics_ms_max := 0.0
var _physics_tick_total := 0
var _physics_tick_max := 0
var _multi_physics_tick_frames := 0
var _presentation_ms_total := 0.0
var _presentation_ms_max := 0.0
var _hud_ms_total := 0.0
var _hud_ms_max := 0.0
var _engine_process_ms_total := 0.0
var _engine_process_ms_max := 0.0
var _engine_physics_ms_total := 0.0
var _engine_physics_ms_max := 0.0
var _render_cpu_ms_total := 0.0
var _render_cpu_ms_max := 0.0
var _render_cpu_samples := 0
var _render_gpu_ms_total := 0.0
var _render_gpu_ms_max := 0.0
var _render_gpu_samples := 0
var _wait_ms_total := 0.0
var _wait_ms_max := 0.0
var _frames_over_20_ms := 0
var _frames_over_25_ms := 0
var _frames_over_33_3_ms := 0
var _frames_over_50_ms := 0
var _consecutive_over_33_3_ms := 0
var _max_consecutive_over_33_3_ms := 0
var _focus_samples := 0
var _unfocused_samples := 0
var _detail_sample_frames := 0

var _pending_physics_ms := 0.0
var _pending_physics_ticks := 0
var _pending_detail_ticks := 0
var _pending_subsystems: Dictionary = {}

var _subsystem_totals: Dictionary = {}
var _subsystem_maxima: Dictionary = {}
var _subsystem_samples: Dictionary = {}
var _slow_frames: Array[Dictionary] = []

var _bucket_elapsed := 0.0
var _bucket_start_seconds := 0.0
var _bucket_frame_count := 0
var _bucket_frame_ms_total := 0.0
var _bucket_frame_ms_max := 0.0
var _bucket_physics_ms_total := 0.0
var _bucket_physics_ms_max := 0.0
var _bucket_physics_tick_total := 0
var _bucket_physics_tick_max := 0
var _bucket_multi_tick_frames := 0
var _bucket_presentation_ms_total := 0.0
var _bucket_presentation_ms_max := 0.0
var _bucket_hud_ms_total := 0.0
var _bucket_hud_ms_max := 0.0
var _bucket_engine_process_ms_total := 0.0
var _bucket_engine_process_ms_max := 0.0
var _bucket_engine_physics_ms_total := 0.0
var _bucket_engine_physics_ms_max := 0.0
var _bucket_render_cpu_ms_total := 0.0
var _bucket_render_cpu_ms_max := 0.0
var _bucket_render_cpu_samples := 0
var _bucket_render_gpu_ms_total := 0.0
var _bucket_render_gpu_ms_max := 0.0
var _bucket_render_gpu_samples := 0
var _bucket_wait_ms_total := 0.0
var _bucket_wait_ms_max := 0.0
var _bucket_detail_sample_frames := 0
var _bucket_frames_over_20_ms := 0
var _bucket_frames_over_33_3_ms := 0
var _bucket_consecutive_over_33_3_ms := 0
var _bucket_max_consecutive_over_33_3_ms := 0
var _bucket_slowest_frame_ms := 0.0
var _bucket_pressure_sums := PackedFloat64Array()
var _bucket_pressure_maxima := PackedFloat64Array()
var _bucket_pressure_at_slowest: Dictionary = {}
var _bucket_context_start: Dictionary = {}
var _bucket_context_end: Dictionary = {}
var _bucket_context_at_slowest: Dictionary = {}
var _bucket_subsystem_totals: Dictionary = {}
var _bucket_subsystem_samples: Dictionary = {}
var _buckets: Array[Dictionary] = []
var _bucket_write_index := 0
var _buckets_dropped := 0


static func is_safe_output_path(path: String) -> bool:
	if not path.begins_with(OUTPUT_DIRECTORY):
		return false
	var file_name := path.trim_prefix(OUTPUT_DIRECTORY)
	if file_name.is_empty() or file_name.contains("/") or file_name.contains("\\"):
		return false
	var pattern := RegEx.new()
	if pattern.compile("^[A-Za-z0-9][A-Za-z0-9._-]*\\.json$") != OK:
		return false
	return pattern.search(file_name) != null


func configure(
	path: String,
	detail_sample_stride: int = DETAIL_SAMPLE_STRIDE_DEFAULT,
	session_metadata: Dictionary = {}
) -> bool:
	if (
		_configured
		or _recording
		or _finished
		or not is_safe_output_path(path)
		or FileAccess.file_exists(ProjectSettings.globalize_path(path))
	):
		return false
	output_path = path
	_detail_sample_stride = maxi(1, detail_sample_stride)
	_session_metadata = session_metadata.duplicate(true)
	_bucket_pressure_sums.resize(PRESSURE_FIELDS.size())
	_bucket_pressure_maxima.resize(PRESSURE_FIELDS.size())
	_configured = true
	return true


func start() -> bool:
	if not _configured or _recording or _finished:
		return false
	_recording = true
	_started_unix_time = Time.get_unix_time_from_system()
	_initial_static_memory = float(
		Performance.get_monitor(Performance.MEMORY_STATIC)
	)
	return true


func is_recording() -> bool:
	return _recording


func has_pending_physics() -> bool:
	return _pending_physics_ticks > 0


func set_engagement_telemetry(telemetry: Dictionary) -> void:
	_engagement_telemetry = telemetry.duplicate(true)


func debug_retained_counts() -> Dictionary:
	return {
		"buckets":_buckets.size(),
		"buckets_dropped":_buckets_dropped,
		"slow_frames":_slow_frames.size(),
	}


func record_physics(
	total_ms: float,
	subsystem_ms: Dictionary = {}
) -> void:
	if not _recording:
		return
	_pending_physics_ms += maxf(0.0, total_ms)
	_pending_physics_ticks += 1
	if subsystem_ms.is_empty():
		return
	_pending_detail_ticks += 1
	for key in subsystem_ms:
		_pending_subsystems[key] = (
			float(_pending_subsystems.get(key, 0.0))
			+ maxf(0.0, float(subsystem_ms[key]))
		)


func advance_frame(
	delta: float,
	presentation_ms: float,
	hud_ms: float,
	viewport: Viewport,
	pressure: Dictionary = {},
	context: Dictionary = {},
	active_simulation: bool = true
) -> void:
	if not _recording:
		return
	if is_instance_valid(viewport):
		_viewport = viewport
	if not active_simulation:
		_clear_pending_frame()
		return
	var safe_delta := maxf(0.0, delta)
	if safe_delta <= 0.0:
		_clear_pending_frame()
		return
	var frame_ms := safe_delta * 1000.0
	var safe_presentation_ms := maxf(0.0, presentation_ms)
	var safe_hud_ms := maxf(0.0, hud_ms)
	var engine_process_ms := (
		float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	)
	var engine_physics_ms := (
		float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	)
	var render_cpu_ms: Variant = _optional_viewport_time(viewport, true)
	var render_gpu_ms: Variant = _optional_viewport_time(viewport, false)
	var wait_ms := maxf(
		0.0,
		frame_ms - _pending_physics_ms - safe_presentation_ms - safe_hud_ms
	)

	_frame_serial += 1
	_active_seconds += safe_delta
	_frame_count += 1
	_frame_ms_total += frame_ms
	_frame_ms_max = maxf(_frame_ms_max, frame_ms)
	_physics_ms_total += _pending_physics_ms
	_physics_ms_max = maxf(_physics_ms_max, _pending_physics_ms)
	_physics_tick_total += _pending_physics_ticks
	_physics_tick_max = maxi(_physics_tick_max, _pending_physics_ticks)
	if _pending_physics_ticks > 1:
		_multi_physics_tick_frames += 1
	_presentation_ms_total += safe_presentation_ms
	_presentation_ms_max = maxf(_presentation_ms_max, safe_presentation_ms)
	_hud_ms_total += safe_hud_ms
	_hud_ms_max = maxf(_hud_ms_max, safe_hud_ms)
	_engine_process_ms_total += engine_process_ms
	_engine_process_ms_max = maxf(_engine_process_ms_max, engine_process_ms)
	_engine_physics_ms_total += engine_physics_ms
	_engine_physics_ms_max = maxf(_engine_physics_ms_max, engine_physics_ms)
	_wait_ms_total += wait_ms
	_wait_ms_max = maxf(_wait_ms_max, wait_ms)
	_accumulate_optional_render(render_cpu_ms, render_gpu_ms)
	_record_frame_thresholds(frame_ms)
	_accumulate_subsystem_totals()
	_accumulate_bucket(
		safe_delta,
		frame_ms,
		safe_presentation_ms,
		safe_hud_ms,
		engine_process_ms,
		engine_physics_ms,
		render_cpu_ms,
		render_gpu_ms,
		wait_ms,
		pressure,
		context
	)
	_record_slow_frame(
		frame_ms,
		safe_presentation_ms,
		safe_hud_ms,
		engine_process_ms,
		engine_physics_ms,
		render_cpu_ms,
		render_gpu_ms,
		wait_ms,
		pressure,
		context
	)
	_clear_pending_frame()
	if _bucket_elapsed >= BUCKET_TARGET_SECONDS:
		_flush_bucket()


func finish(reason: String = "manual_stop") -> Dictionary:
	if _finished:
		return _finished_result
	if not _recording:
		return {}
	_recording = false
	_finished = true
	if _bucket_frame_count > 0:
		_flush_bucket()
	var final_static_memory := float(
		Performance.get_monitor(Performance.MEMORY_STATIC)
	)
	var result := {
		"schema":2,
		"kind":"manual_play_trace",
		"diagnostic_only":true,
		"authoritative":false,
		"completed_reason":reason,
		"started_unix_time":_started_unix_time,
		"finished_unix_time":Time.get_unix_time_from_system(),
		"duration_seconds":_active_seconds,
		"sampling":{
			"bucket_target_seconds":BUCKET_TARGET_SECONDS,
			"bucket_cap":MAX_BUCKETS,
			"buckets_retained":_buckets.size(),
			"buckets_dropped":_buckets_dropped,
			"slow_frame_min_ms":SLOW_FRAME_MIN_MS,
			"slow_frame_cap":SLOW_FRAME_CAP,
			"slow_frames_retained":_slow_frames.size(),
			"detail_sample_stride":_detail_sample_stride,
			"render_measurement_samples_collected":(
				_render_cpu_samples > 0 or _render_gpu_samples > 0
			),
			"file_io_during_recording":false,
		},
		"session":_session_metadata.duplicate(true),
		"pressure_field_definitions":PRESSURE_FIELD_DEFINITIONS.duplicate(true),
		"environment":_environment_metadata(),
		"viewport":_viewport_metadata(),
		"git":{
			"commit":OS.get_environment("PERFORMANCE_COMMIT"),
			"dirty":OS.get_environment("PERFORMANCE_DIRTY") == "1",
		},
		"summary":_summary(),
		"subsystems":_subsystem_summary(),
		"engagement_telemetry":_engagement_telemetry.duplicate(true),
		"frame_buckets":_ordered_buckets(),
		"slow_frames":_slow_frames.duplicate(true),
		"memory":{
			"initial_static_bytes":_initial_static_memory,
			"final_static_bytes":final_static_memory,
			"growth_bytes":final_static_memory - _initial_static_memory,
			"object_count":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"node_count":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		},
	}
	_finished_result = result
	_write_result(result)
	return _finished_result


func _record_frame_thresholds(frame_ms: float) -> void:
	if frame_ms >= 20.0:
		_frames_over_20_ms += 1
	if frame_ms >= 25.0:
		_frames_over_25_ms += 1
	if frame_ms > 33.3:
		_frames_over_33_3_ms += 1
		_consecutive_over_33_3_ms += 1
		_max_consecutive_over_33_3_ms = maxi(
			_max_consecutive_over_33_3_ms,
			_consecutive_over_33_3_ms
		)
	else:
		_consecutive_over_33_3_ms = 0
	if frame_ms >= 50.0:
		_frames_over_50_ms += 1
	if DisplayServer.get_name() != "headless":
		_focus_samples += 1
		if not DisplayServer.window_is_focused():
			_unfocused_samples += 1


func _accumulate_optional_render(cpu_ms: Variant, gpu_ms: Variant) -> void:
	if cpu_ms != null:
		_render_cpu_samples += 1
		_render_cpu_ms_total += maxf(0.0, float(cpu_ms))
		_render_cpu_ms_max = maxf(_render_cpu_ms_max, float(cpu_ms))
	if gpu_ms != null:
		_render_gpu_samples += 1
		_render_gpu_ms_total += maxf(0.0, float(gpu_ms))
		_render_gpu_ms_max = maxf(_render_gpu_ms_max, float(gpu_ms))


func _accumulate_subsystem_totals() -> void:
	if _pending_detail_ticks <= 0:
		return
	_detail_sample_frames += 1
	for key in _pending_subsystems:
		var value := float(_pending_subsystems[key])
		_subsystem_totals[key] = float(_subsystem_totals.get(key, 0.0)) + value
		_subsystem_maxima[key] = maxf(
			float(_subsystem_maxima.get(key, 0.0)), value
		)
		_subsystem_samples[key] = int(_subsystem_samples.get(key, 0)) + 1


func _accumulate_bucket(
	delta: float,
	frame_ms: float,
	presentation_ms: float,
	hud_ms: float,
	engine_process_ms: float,
	engine_physics_ms: float,
	render_cpu_ms: Variant,
	render_gpu_ms: Variant,
	wait_ms: float,
	pressure: Dictionary,
	context: Dictionary
) -> void:
	if _bucket_frame_count == 0:
		_bucket_start_seconds = _active_seconds - delta
		_bucket_context_start.clear()
		_bucket_context_start.merge(context, true)
	_bucket_elapsed += delta
	_bucket_frame_count += 1
	_bucket_frame_ms_total += frame_ms
	_bucket_frame_ms_max = maxf(_bucket_frame_ms_max, frame_ms)
	_bucket_physics_ms_total += _pending_physics_ms
	_bucket_physics_ms_max = maxf(_bucket_physics_ms_max, _pending_physics_ms)
	_bucket_physics_tick_total += _pending_physics_ticks
	_bucket_physics_tick_max = maxi(
		_bucket_physics_tick_max, _pending_physics_ticks
	)
	if _pending_physics_ticks > 1:
		_bucket_multi_tick_frames += 1
	_bucket_presentation_ms_total += presentation_ms
	_bucket_presentation_ms_max = maxf(
		_bucket_presentation_ms_max, presentation_ms
	)
	_bucket_hud_ms_total += hud_ms
	_bucket_hud_ms_max = maxf(_bucket_hud_ms_max, hud_ms)
	_bucket_engine_process_ms_total += engine_process_ms
	_bucket_engine_process_ms_max = maxf(
		_bucket_engine_process_ms_max, engine_process_ms
	)
	_bucket_engine_physics_ms_total += engine_physics_ms
	_bucket_engine_physics_ms_max = maxf(
		_bucket_engine_physics_ms_max, engine_physics_ms
	)
	_bucket_wait_ms_total += wait_ms
	_bucket_wait_ms_max = maxf(_bucket_wait_ms_max, wait_ms)
	if frame_ms >= 20.0:
		_bucket_frames_over_20_ms += 1
	if frame_ms > 33.3:
		_bucket_frames_over_33_3_ms += 1
		_bucket_consecutive_over_33_3_ms += 1
		_bucket_max_consecutive_over_33_3_ms = maxi(
			_bucket_max_consecutive_over_33_3_ms,
			_bucket_consecutive_over_33_3_ms
		)
	else:
		_bucket_consecutive_over_33_3_ms = 0
	if render_cpu_ms != null:
		_bucket_render_cpu_samples += 1
		_bucket_render_cpu_ms_total += maxf(0.0, float(render_cpu_ms))
		_bucket_render_cpu_ms_max = maxf(
			_bucket_render_cpu_ms_max, float(render_cpu_ms)
		)
	if render_gpu_ms != null:
		_bucket_render_gpu_samples += 1
		_bucket_render_gpu_ms_total += maxf(0.0, float(render_gpu_ms))
		_bucket_render_gpu_ms_max = maxf(
			_bucket_render_gpu_ms_max, float(render_gpu_ms)
		)
	if _pending_detail_ticks > 0:
		_bucket_detail_sample_frames += 1
		for key in _pending_subsystems:
			_bucket_subsystem_totals[key] = (
				float(_bucket_subsystem_totals.get(key, 0.0))
				+ float(_pending_subsystems[key])
			)
			_bucket_subsystem_samples[key] = (
				int(_bucket_subsystem_samples.get(key, 0)) + 1
			)
	for index in PRESSURE_FIELDS.size():
		var value := maxf(0.0, float(pressure.get(PRESSURE_FIELDS[index], 0.0)))
		_bucket_pressure_sums[index] += value
		_bucket_pressure_maxima[index] = maxf(
			_bucket_pressure_maxima[index], value
		)
	_bucket_context_end.clear()
	_bucket_context_end.merge(context, true)
	if frame_ms >= _bucket_slowest_frame_ms:
		_bucket_slowest_frame_ms = frame_ms
		_bucket_pressure_at_slowest.clear()
		_bucket_pressure_at_slowest.merge(pressure, true)
		_bucket_context_at_slowest.clear()
		_bucket_context_at_slowest.merge(context, true)


func _record_slow_frame(
	frame_ms: float,
	presentation_ms: float,
	hud_ms: float,
	engine_process_ms: float,
	engine_physics_ms: float,
	render_cpu_ms: Variant,
	render_gpu_ms: Variant,
	wait_ms: float,
	pressure: Dictionary,
	context: Dictionary
) -> void:
	if frame_ms < SLOW_FRAME_MIN_MS:
		return
	var should_retain := _slow_frames.size() < SLOW_FRAME_CAP
	if not should_retain and not _slow_frames.is_empty():
		should_retain = frame_ms > float(_slow_frames[-1]["frame_ms"])
	if not should_retain:
		return
	var sample := {
		"frame_serial":_frame_serial,
		"active_seconds":_active_seconds,
		"frame_ms":frame_ms,
		"physics_ticks":_pending_physics_ticks,
		"physics_ms":_pending_physics_ms,
		"presentation_ms":presentation_ms,
		"hud_ms":hud_ms,
		"engine_process_ms":engine_process_ms,
		"engine_physics_ms":engine_physics_ms,
		"render_cpu_ms":render_cpu_ms,
		"render_gpu_ms":render_gpu_ms,
		"wait_or_unattributed_ms":wait_ms,
		"detail_sampled":_pending_detail_ticks > 0,
		"detail_physics_ticks":_pending_detail_ticks,
		"subsystems":_pending_subsystems.duplicate(true),
		"pressure":pressure.duplicate(true),
		"context":context.duplicate(true),
	}
	if _slow_frames.size() < SLOW_FRAME_CAP:
		_slow_frames.append(sample)
	else:
		_slow_frames[-1] = sample
	_slow_frames.sort_custom(_sort_slow_frames)


static func _sort_slow_frames(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("frame_ms", 0.0)) > float(b.get("frame_ms", 0.0))


func _flush_bucket() -> void:
	if _bucket_frame_count <= 0:
		return
	var bucket := {
		"start_active_seconds":_bucket_start_seconds,
		"end_active_seconds":_active_seconds,
		"duration_seconds":_bucket_elapsed,
		"frame_count":_bucket_frame_count,
		"frame_ms":_metric_summary(
			_bucket_frame_ms_total, _bucket_frame_ms_max, _bucket_frame_count
		),
		"physics_ms":_metric_summary(
			_bucket_physics_ms_total,
			_bucket_physics_ms_max,
			_bucket_frame_count
		),
		"physics_ticks":{
			"average":_safe_average(
				float(_bucket_physics_tick_total), _bucket_frame_count
			),
			"max_per_frame":_bucket_physics_tick_max,
			"multi_tick_frames":_bucket_multi_tick_frames,
		},
		"presentation_ms":_metric_summary(
			_bucket_presentation_ms_total,
			_bucket_presentation_ms_max,
			_bucket_frame_count
		),
		"hud_ms":_metric_summary(
			_bucket_hud_ms_total, _bucket_hud_ms_max, _bucket_frame_count
		),
		"engine_process_ms":_metric_summary(
			_bucket_engine_process_ms_total,
			_bucket_engine_process_ms_max,
			_bucket_frame_count
		),
		"engine_physics_ms":_metric_summary(
			_bucket_engine_physics_ms_total,
			_bucket_engine_physics_ms_max,
			_bucket_frame_count
		),
		"render_cpu_ms":_optional_metric_summary(
			_bucket_render_cpu_ms_total,
			_bucket_render_cpu_ms_max,
			_bucket_render_cpu_samples
		),
		"render_gpu_ms":_optional_metric_summary(
			_bucket_render_gpu_ms_total,
			_bucket_render_gpu_ms_max,
			_bucket_render_gpu_samples
		),
		"wait_or_unattributed_ms":_metric_summary(
			_bucket_wait_ms_total, _bucket_wait_ms_max, _bucket_frame_count
		),
		"hitches":{
			"frames_over_20_ms":_bucket_frames_over_20_ms,
			"frames_over_33_3_ms":_bucket_frames_over_33_3_ms,
			"max_consecutive_over_33_3_ms":(
				_bucket_max_consecutive_over_33_3_ms
			),
		},
		"detail_sample_frames":_bucket_detail_sample_frames,
		"subsystems":_bucket_subsystem_summary(),
		"pressure_average":_pressure_summary(
			_bucket_pressure_sums, _bucket_frame_count
		),
		"pressure_max":_pressure_summary(_bucket_pressure_maxima, 1),
		"pressure_at_slowest_frame":_bucket_pressure_at_slowest.duplicate(true),
		"context_start":_bucket_context_start.duplicate(true),
		"context_end":_bucket_context_end.duplicate(true),
		"context_at_slowest_frame":_bucket_context_at_slowest.duplicate(true),
	}
	_retain_bucket(bucket)
	_reset_bucket()


func _retain_bucket(bucket: Dictionary) -> void:
	if _buckets.size() < MAX_BUCKETS:
		_buckets.append(bucket)
		return
	_buckets[_bucket_write_index] = bucket
	_bucket_write_index = (_bucket_write_index + 1) % MAX_BUCKETS
	_buckets_dropped += 1


func _reset_bucket() -> void:
	_bucket_elapsed = 0.0
	_bucket_start_seconds = _active_seconds
	_bucket_frame_count = 0
	_bucket_frame_ms_total = 0.0
	_bucket_frame_ms_max = 0.0
	_bucket_physics_ms_total = 0.0
	_bucket_physics_ms_max = 0.0
	_bucket_physics_tick_total = 0
	_bucket_physics_tick_max = 0
	_bucket_multi_tick_frames = 0
	_bucket_presentation_ms_total = 0.0
	_bucket_presentation_ms_max = 0.0
	_bucket_hud_ms_total = 0.0
	_bucket_hud_ms_max = 0.0
	_bucket_engine_process_ms_total = 0.0
	_bucket_engine_process_ms_max = 0.0
	_bucket_engine_physics_ms_total = 0.0
	_bucket_engine_physics_ms_max = 0.0
	_bucket_render_cpu_ms_total = 0.0
	_bucket_render_cpu_ms_max = 0.0
	_bucket_render_cpu_samples = 0
	_bucket_render_gpu_ms_total = 0.0
	_bucket_render_gpu_ms_max = 0.0
	_bucket_render_gpu_samples = 0
	_bucket_wait_ms_total = 0.0
	_bucket_wait_ms_max = 0.0
	_bucket_detail_sample_frames = 0
	_bucket_frames_over_20_ms = 0
	_bucket_frames_over_33_3_ms = 0
	_bucket_consecutive_over_33_3_ms = 0
	_bucket_max_consecutive_over_33_3_ms = 0
	_bucket_slowest_frame_ms = 0.0
	_bucket_pressure_sums.fill(0.0)
	_bucket_pressure_maxima.fill(0.0)
	_bucket_pressure_at_slowest.clear()
	_bucket_context_start.clear()
	_bucket_context_end.clear()
	_bucket_context_at_slowest.clear()
	_bucket_subsystem_totals.clear()
	_bucket_subsystem_samples.clear()


func _clear_pending_frame() -> void:
	_pending_physics_ms = 0.0
	_pending_physics_ticks = 0
	_pending_detail_ticks = 0
	_pending_subsystems.clear()


func _summary() -> Dictionary:
	return {
		"frame_count":_frame_count,
		"average_fps":(
			float(_frame_count) / _active_seconds
			if _active_seconds > 0.0
			else 0.0
		),
		"frame_ms":_metric_summary(
			_frame_ms_total, _frame_ms_max, _frame_count
		),
		"physics_ms":_metric_summary(
			_physics_ms_total, _physics_ms_max, _frame_count
		),
		"physics_ticks":{
			"total":_physics_tick_total,
			"average":_safe_average(float(_physics_tick_total), _frame_count),
			"max_per_frame":_physics_tick_max,
			"multi_tick_frames":_multi_physics_tick_frames,
		},
		"presentation_ms":_metric_summary(
			_presentation_ms_total, _presentation_ms_max, _frame_count
		),
		"hud_ms":_metric_summary(_hud_ms_total, _hud_ms_max, _frame_count),
		"engine_process_ms":_metric_summary(
			_engine_process_ms_total, _engine_process_ms_max, _frame_count
		),
		"engine_physics_ms":_metric_summary(
			_engine_physics_ms_total, _engine_physics_ms_max, _frame_count
		),
		"render_cpu_ms":_optional_metric_summary(
			_render_cpu_ms_total, _render_cpu_ms_max, _render_cpu_samples
		),
		"render_gpu_ms":_optional_metric_summary(
			_render_gpu_ms_total, _render_gpu_ms_max, _render_gpu_samples
		),
		"wait_or_unattributed_ms":_metric_summary(
			_wait_ms_total, _wait_ms_max, _frame_count
		),
		"frames_over_ms":{
			"20":_frames_over_20_ms,
			"25":_frames_over_25_ms,
			"33_3":_frames_over_33_3_ms,
			"50":_frames_over_50_ms,
		},
		"max_consecutive_frames_over_33_3_ms":(
			_max_consecutive_over_33_3_ms
		),
		"detail_sample_frames":_detail_sample_frames,
	}


func _subsystem_summary() -> Dictionary:
	var result := {}
	for key in _subsystem_totals:
		var sample_count := int(_subsystem_samples.get(key, 0))
		result[key] = {
			"samples":sample_count,
			"average_ms":_safe_average(
				float(_subsystem_totals[key]), sample_count
			),
			"max_ms":float(_subsystem_maxima.get(key, 0.0)),
		}
	return result


func _bucket_subsystem_summary() -> Dictionary:
	var result := {}
	for key in _bucket_subsystem_totals:
		var sample_count := int(_bucket_subsystem_samples.get(key, 0))
		result[key] = {
			"samples":sample_count,
			"average_ms":_safe_average(
				float(_bucket_subsystem_totals[key]), sample_count
			),
		}
	return result


func _pressure_summary(values: PackedFloat64Array, divisor: int) -> Dictionary:
	var result := {}
	for index in PRESSURE_FIELDS.size():
		result[PRESSURE_FIELDS[index]] = _safe_average(values[index], divisor)
	return result


func _ordered_buckets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _buckets.size() < MAX_BUCKETS:
		for bucket in _buckets:
			result.append(bucket.duplicate(true))
		return result
	for offset in _buckets.size():
		var index := (_bucket_write_index + offset) % _buckets.size()
		result.append(_buckets[index].duplicate(true))
	return result


func _environment_metadata() -> Dictionary:
	var renderer := {
		"method":RenderingServer.get_current_rendering_method(),
		"driver":RenderingServer.get_current_rendering_driver_name(),
	}
	if RenderingServer.has_method("get_video_adapter_name"):
		renderer["adapter"] = RenderingServer.get_video_adapter_name()
	if RenderingServer.has_method("get_video_adapter_vendor"):
		renderer["vendor"] = RenderingServer.get_video_adapter_vendor()
	return {
		"platform":OS.get_name(),
		"display_server":DisplayServer.get_name(),
		"godot":Engine.get_version_info(),
		"renderer":renderer,
		"focus_samples":_focus_samples,
		"unfocused_samples":_unfocused_samples,
		"was_unfocused":_unfocused_samples > 0,
	}


func _viewport_metadata() -> Dictionary:
	if not is_instance_valid(_viewport):
		return {"logical":[0, 0], "window":[0, 0]}
	var visible_size := _viewport.get_visible_rect().size
	var window := _viewport.get_window()
	var window_size := window.size if window != null else Vector2i.ZERO
	return {
		"logical":[roundi(visible_size.x), roundi(visible_size.y)],
		"window":[window_size.x, window_size.y],
	}


func _optional_viewport_time(viewport: Viewport, cpu: bool) -> Variant:
	if not is_instance_valid(viewport) or DisplayServer.get_name() == "headless":
		return null
	var viewport_rid := viewport.get_viewport_rid()
	if cpu and RenderingServer.has_method("viewport_get_measured_render_time_cpu"):
		return RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
	if not cpu and RenderingServer.has_method("viewport_get_measured_render_time_gpu"):
		return RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	return null


func _write_result(result: Dictionary) -> void:
	var absolute_path := ProjectSettings.globalize_path(output_path)
	if FileAccess.file_exists(absolute_path):
		push_error("Refusing to overwrite manual performance trace: %s" % absolute_path)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(
		absolute_path.get_base_dir()
	)
	if directory_error != OK:
		push_error(
			"Could not create manual performance directory: %s"
			% error_string(directory_error)
		)
		return
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write manual performance trace: %s" % absolute_path)
		return
	file.store_string(JSON.stringify(result, "\t", false) + "\n")
	file.flush()
	file = null
	print("MANUAL_PERFORMANCE_TRACE_WRITTEN " + output_path)


static func _metric_summary(total: float, maximum: float, count: int) -> Dictionary:
	return {"average":_safe_average(total, count), "max":maximum}


static func _optional_metric_summary(
	total: float,
	maximum: float,
	count: int
) -> Dictionary:
	return {
		"samples":count,
		"average":_safe_average(total, count) if count > 0 else null,
		"max":maximum if count > 0 else null,
	}


static func _safe_average(total: float, count: int) -> float:
	return total / float(count) if count > 0 else 0.0
