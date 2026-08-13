class_name VehiclePerformanceRecorder
extends RefCounted

## Records complete rendered-frame distributions only when an explicit
## performance scenario is active. Ordinary play allocates no sample arrays.

const RESULT_PREFIX := "PERFORMANCE_RESULT "
const FRAME_THRESHOLDS: Array[float] = [20.0, 25.0, 33.3, 50.0]
const MONITOR_SAMPLE_INTERVAL := 0.1
const FRAME_ATTRIBUTION_CAP := 64

var scenario_id: StringName
var output_path := ""
var warmup_seconds := 10.0
var sample_seconds := 60.0

var _elapsed := 0.0
var _frame_ms: Array[float] = []
var _physics_ms: Array[float] = []
var _presentation_ms: Array[float] = []
var _hud_ms: Array[float] = []
var _draw_calls: Array[float] = []
var _process_ms: Array[float] = []
var _engine_physics_ms: Array[float] = []
var _subsystem_samples: Dictionary = {}
var _frame_physics_ms := 0.0
var _frame_subsystems: Dictionary = {}
var _frame_serial := 0
var _slow_frame_samples: Array[Dictionary] = []
var _max_consecutive_over_33 := 0
var _consecutive_over_33 := 0
var _initial_static_memory := 0.0
var _finished := false
var _monitor_sample_timer := 0.0
var _browser_user_agent := ""
var _native_focus_samples := 0
var _native_unfocused_samples := 0


func configure(id: StringName, path: String, warmup: float = 10.0, duration: float = 60.0) -> void:
	scenario_id = id
	output_path = path
	warmup_seconds = maxf(0.0, warmup)
	sample_seconds = maxf(0.25, duration)
	_initial_static_memory = float(Performance.get_monitor(Performance.MEMORY_STATIC))
	_prepare_web_environment_probe()


func record_physics(total_ms: float, subsystem_ms: Dictionary) -> void:
	if not _is_sampling():
		return
	_frame_physics_ms += total_ms
	_physics_ms.append(total_ms)
	for key in subsystem_ms:
		if not _subsystem_samples.has(key):
			_subsystem_samples[key] = []
		var samples: Array = _subsystem_samples[key]
		samples.append(float(subsystem_ms[key]))
		_frame_subsystems[key] = float(_frame_subsystems.get(key, 0.0)) + float(subsystem_ms[key])


func advance_frame(
	delta: float,
	presentation_ms: float,
	hud_ms: float
) -> bool:
	if _finished:
		return true
	_elapsed += delta
	if _is_sampling():
		_frame_serial += 1
		if not OS.has_feature("web"):
			_native_focus_samples += 1
			if not DisplayServer.window_is_focused():
				_native_unfocused_samples += 1
		var frame_ms := delta * 1000.0
		_frame_ms.append(frame_ms)
		_presentation_ms.append(presentation_ms)
		_hud_ms.append(hud_ms)
		_record_frame_attribution(frame_ms, presentation_ms, hud_ms)
		if frame_ms > 33.3:
			_consecutive_over_33 += 1
			_max_consecutive_over_33 = maxi(_max_consecutive_over_33, _consecutive_over_33)
		else:
			_consecutive_over_33 = 0
		_monitor_sample_timer -= delta
		if _monitor_sample_timer <= 0.0:
			_monitor_sample_timer = MONITOR_SAMPLE_INTERVAL
			_draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			_process_ms.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
			_engine_physics_ms.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	else:
		_frame_physics_ms = 0.0
		_frame_subsystems.clear()
	return _elapsed >= warmup_seconds + sample_seconds


func finish(
	viewport: Viewport,
	validation: Dictionary = {},
	counts: Dictionary = {},
	renderer: Dictionary = {},
	grid: Dictionary = {},
	engagement_telemetry: Dictionary = {}
) -> Dictionary:
	if _finished:
		return {}
	_finished = true
	var subsystem_stats := {}
	for key in _subsystem_samples:
		subsystem_stats[key] = _distribution(_typed_float_array(_subsystem_samples[key]))
	var frame_stats := _distribution(_frame_ms)
	var physics_stats := _distribution(_physics_ms)
	var presentation_stats := _distribution(_presentation_ms)
	var hud_stats := _distribution(_hud_ms)
	var execution_environment := _execution_environment()
	_classify_frame_scheduler(
		execution_environment,
		frame_stats,
		physics_stats,
		presentation_stats,
		hud_stats
	)
	var authoritative := (
		warmup_seconds >= 10.0
		and sample_seconds >= 60.0
		and bool(execution_environment["authority_eligible"])
	)
	var result := {
		"schema": 1,
		"scenario": String(scenario_id),
		"authoritative": authoritative,
		"warmup_seconds": warmup_seconds,
		"sample_seconds": sample_seconds,
		"seed": 0xC4A2B0,
		"platform": OS.get_name(),
		"execution_environment": execution_environment,
		"godot": Engine.get_version_info(),
		"renderer": _renderer_metadata(),
		"viewport": {
			"logical": [roundi(viewport.get_visible_rect().size.x), roundi(viewport.get_visible_rect().size.y)],
			"window": [get_window_size(viewport).x, get_window_size(viewport).y],
			"cpu_render_ms": _optional_viewport_time(viewport, true),
			"gpu_render_ms": _optional_viewport_time(viewport, false),
		},
		"git": {
			"commit": OS.get_environment("PERFORMANCE_COMMIT"),
			"dirty": OS.get_environment("PERFORMANCE_DIRTY") == "1",
		},
		"frames": frame_stats,
		"physics": physics_stats,
		"presentation": presentation_stats,
		"hud": hud_stats,
		"engine_process": _distribution(_process_ms),
		"engine_physics": _distribution(_engine_physics_ms),
		"draw_calls": _distribution(_draw_calls),
		"frame_attribution": {
			"sample_count": _slow_frame_samples.size(),
			"slow_frame_samples": _slow_frame_samples.duplicate(true),
			"p99_hitch": _p99_attribution(),
		},
		"subsystems": subsystem_stats,
		"max_consecutive_frames_over_33_3_ms": _max_consecutive_over_33,
		"counts": counts.duplicate(true),
		"combat_renderer": renderer.duplicate(true),
		"spatial_grid": grid.duplicate(true),
		"engagement_telemetry": engagement_telemetry.duplicate(true),
		"memory": {
			"initial_static_bytes": _initial_static_memory,
			"final_static_bytes": float(Performance.get_monitor(Performance.MEMORY_STATIC)),
			"growth_bytes": float(Performance.get_monitor(Performance.MEMORY_STATIC)) - _initial_static_memory,
			"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		},
		"scenario_validation": validation,
	}
	result["thresholds"] = _threshold_result(result)
	var encoded := JSON.stringify(result)
	if OS.has_feature("web"):
		_publish_web_summary(result)
	print(RESULT_PREFIX + encoded)
	if not output_path.is_empty() and not OS.has_feature("web"):
		var absolute_path := ProjectSettings.globalize_path(output_path)
		DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
		var file := FileAccess.open(absolute_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write performance result: %s" % absolute_path)
		else:
			file.store_string(JSON.stringify(result, "\t"))
	return result


func _record_frame_attribution(
	frame_ms: float,
	presentation_ms: float,
	hud_ms: float
) -> void:
	var should_capture := _slow_frame_samples.size() < FRAME_ATTRIBUTION_CAP
	if not should_capture and not _slow_frame_samples.is_empty():
		should_capture = frame_ms > float(_slow_frame_samples[-1].get("frame_ms", 0.0))
	if should_capture:
		var engine_process_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		var engine_physics_ms := float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
		var attributed_ms := _frame_physics_ms + presentation_ms + hud_ms
		var sample := {
			"frame_serial": _frame_serial,
			"frame_ms": frame_ms,
			"physics_ms": _frame_physics_ms,
			"presentation_ms": presentation_ms,
			"hud_ms": hud_ms,
			"engine_process_ms": engine_process_ms,
			"engine_physics_ms": engine_physics_ms,
			"render_cpu_ms": null,
			"render_gpu_ms": null,
			"wait_or_unattributed_ms": maxf(0.0, frame_ms - attributed_ms),
			"subsystems": _frame_subsystems.duplicate(true),
		}
		if _slow_frame_samples.size() < FRAME_ATTRIBUTION_CAP:
			_slow_frame_samples.append(sample)
		else:
			_slow_frame_samples[-1] = sample
		_slow_frame_samples.sort_custom(_sort_frame_samples)
	_frame_physics_ms = 0.0
	_frame_subsystems.clear()


static func _sort_frame_samples(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("frame_ms", 0.0)) > float(b.get("frame_ms", 0.0))


func _p99_attribution() -> Dictionary:
	if _slow_frame_samples.is_empty():
		return {}
	var index := clampi(ceili(float(_frame_serial) * 0.01) - 1, 0, _slow_frame_samples.size() - 1)
	return Dictionary(_slow_frame_samples[index]).duplicate(true)


static func get_window_size(viewport: Viewport) -> Vector2i:
	var window := viewport.get_window()
	return window.size if window != null else Vector2i.ZERO


func _is_sampling() -> bool:
	return _elapsed >= warmup_seconds and _elapsed < warmup_seconds + sample_seconds


func _threshold_result(result: Dictionary) -> Dictionary:
	var frames: Dictionary = result["frames"]
	var physics: Dictionary = result["physics"]
	var draw_stats: Dictionary = result["draw_calls"]
	var renderer: Dictionary = result["combat_renderer"]
	var validation: Dictionary = result["scenario_validation"]
	var viewport: Dictionary = result["viewport"]
	var execution_environment: Dictionary = result["execution_environment"]
	var memory: Dictionary = result["memory"]
	var authoritative := bool(result["authoritative"])
	var is_web := String(execution_environment.get("kind", "")) == "web"
	var window_values: Array = viewport.get("window", [])
	var window_size := Vector2i(
		int(window_values[0]) if window_values.size() > 0 else 0,
		int(window_values[1]) if window_values.size() > 1 else 0
	)
	var standard_native := not is_web and window_size == Vector2i(1280, 720)
	var high_resolution_native := not is_web and window_size == Vector2i(2560, 1600)
	var standard_web := is_web and window_size == Vector2i(1280, 720)
	var supported_viewport := standard_native or high_resolution_native or standard_web
	var frame_p95_limit := 18.0 if standard_native else 20.0
	var frame_p99_limit := 25.0 if standard_native else 33.3
	var one_percent_low_limit := 55.0 if standard_native else 50.0
	var median_fps_limit := 59.0 if standard_native else 58.0
	var consecutive_over_33_limit: Variant = null if high_resolution_native else (2 if is_web else 1)
	var median_frame_ms := _metric_or(frames, "median", INF)
	var median_fps := 1000.0 / median_frame_ms if median_frame_ms > 0.0 and median_frame_ms < INF else 0.0
	var capacity_scenario := scenario_id in [&"capacity_pressure", &"lifecycle_pressure"]
	var lifecycle_scenario := scenario_id == &"lifecycle_pressure"
	var lifecycle_soak_complete := (
		not lifecycle_scenario
		or float(result.get("sample_seconds", 0.0)) >= 600.0
	)
	var lifecycle_memory_within_limit := (
		not lifecycle_scenario
		or float(memory.get("growth_bytes", INF)) < 8.0 * 1024.0 * 1024.0
	)
	var cpu_render: Variant = viewport.get("cpu_render_ms")
	var gpu_render: Variant = viewport.get("gpu_render_ms")
	var checks := {
		"supported_viewport": supported_viewport,
		"median_fps": median_fps >= median_fps_limit,
		"frame_p95_ms": _metric_or(frames, "p95", INF) <= frame_p95_limit,
		"frame_p99_ms": _metric_or(frames, "p99", INF) <= frame_p99_limit,
		"one_percent_low_fps": _metric_or(frames, "one_percent_low_fps", 0.0) >= one_percent_low_limit,
		"consecutive_over_33_3": (
			true
			if consecutive_over_33_limit == null
			else _max_consecutive_over_33 <= int(consecutive_over_33_limit)
		),
		"capacity_simulation_p95": (
			not capacity_scenario
			or _metric_or(physics, "p95", INF) <= 6.0
		),
		"capacity_simulation_p99": (
			not capacity_scenario
			or _metric_or(physics, "p99", INF) <= 8.0
		),
		"draw_calls_p95": _metric_or(draw_stats, "p95", INF) <= 200.0,
		"combat_batches": int(renderer.get("batches", 999)) <= 50,
		"lifecycle_soak_duration": lifecycle_soak_complete,
		"lifecycle_memory_growth": lifecycle_memory_within_limit,
		"scenario_counts": bool(validation.get("valid", false)),
	}
	var authority_eligible := authoritative and supported_viewport
	var passed := authority_eligible
	for value in checks.values():
		passed = passed and bool(value)
	return {
		"authoritative_run": authority_eligible,
		"load_class": "capacity" if capacity_scenario else "release",
		"limits": {
			"supported_window": [window_size.x, window_size.y],
			"median_fps": median_fps_limit,
			"frame_p95_ms": frame_p95_limit,
			"frame_p99_ms": frame_p99_limit,
			"one_percent_low_fps": one_percent_low_limit,
			"max_consecutive_frames_over_33_3_ms": consecutive_over_33_limit,
			"capacity_simulation_p95_ms": 6.0 if capacity_scenario else null,
			"capacity_simulation_p99_ms": 8.0 if capacity_scenario else null,
			"draw_calls_p95": 200.0,
			"combat_batches": 50,
			"lifecycle_sample_seconds": 600.0 if lifecycle_scenario else null,
			"lifecycle_memory_growth_bytes": 8.0 * 1024.0 * 1024.0 if lifecycle_scenario else null,
		},
		"observed": {
			"median_fps": median_fps,
			"render_cpu_ms": cpu_render,
			"render_gpu_ms": gpu_render,
		},
		"checks": checks,
		"passed": passed,
	}


func _metric_or(stats: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = stats.get(key)
	return fallback if value == null else float(value)


func _distribution(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {
			"samples": 0, "mean": null, "median": null, "p95": null,
			"p99": null, "maximum": null, "slowest_one_percent_mean": null,
			"one_percent_low_fps": null, "over_threshold": {},
		}
	var sorted := samples.duplicate()
	sorted.sort()
	var sum := 0.0
	for value in sorted:
		sum += value
	var slow_count := maxi(1, ceili(float(sorted.size()) * 0.01))
	var slow_sum := 0.0
	for index in range(sorted.size() - slow_count, sorted.size()):
		slow_sum += sorted[index]
	var slow_mean := slow_sum / float(slow_count)
	var over := {}
	for threshold in FRAME_THRESHOLDS:
		var count := 0
		for value in samples:
			if value > threshold:
				count += 1
		over[str(threshold)] = count
	return {
		"samples": sorted.size(),
		"mean": sum / float(sorted.size()),
		"median": _percentile(sorted, 0.50),
		"p95": _percentile(sorted, 0.95),
		"p99": _percentile(sorted, 0.99),
		"maximum": sorted[-1],
		"slowest_one_percent_mean": slow_mean,
		"one_percent_low_fps": 1000.0 / slow_mean if slow_mean > 0.0 else null,
		"over_threshold": over,
	}


func _percentile(sorted: Array[float], ratio: float) -> float:
	var index := clampi(ceili(float(sorted.size()) * ratio) - 1, 0, sorted.size() - 1)
	return sorted[index]


func _typed_float_array(values: Array) -> Array[float]:
	var typed: Array[float] = []
	for value in values:
		typed.append(float(value))
	return typed


func _renderer_metadata() -> Dictionary:
	var metadata := {
		"method": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
	}
	if RenderingServer.has_method("get_video_adapter_name"):
		metadata["adapter"] = RenderingServer.get_video_adapter_name()
	if RenderingServer.has_method("get_video_adapter_vendor"):
		metadata["vendor"] = RenderingServer.get_video_adapter_vendor()
	return metadata


func _prepare_web_environment_probe() -> void:
	if not OS.has_feature("web"):
		return
	var user_agent: Variant = JavaScriptBridge.eval("navigator.userAgent", true)
	if user_agent is String:
		_browser_user_agent = String(user_agent)
	JavaScriptBridge.eval(
		"""(function () {
			window.__cardbornePerformanceWasHidden = Boolean(document.hidden);
			if (window.__cardbornePerformanceVisibilityProbeInstalled) return;
			window.__cardbornePerformanceVisibilityProbeInstalled = true;
			document.addEventListener("visibilitychange", function () {
				if (document.hidden) window.__cardbornePerformanceWasHidden = true;
			});
		})();""",
		true
	)


func _execution_environment() -> Dictionary:
	if not OS.has_feature("web"):
		return {
			"kind": "native",
			"focus_samples": _native_focus_samples,
			"unfocused_samples": _native_unfocused_samples,
			"was_unfocused": _native_unfocused_samples > 0,
			"authority_eligible": (
				_native_focus_samples > 0
				and _native_unfocused_samples == 0
			),
		}
	var hidden_value: Variant = JavaScriptBridge.eval(
		"Boolean(window.__cardbornePerformanceWasHidden || document.hidden)",
		true
	)
	var visibility_value: Variant = JavaScriptBridge.eval("document.visibilityState", true)
	var was_hidden := bool(hidden_value)
	var headless := _browser_user_agent.contains("HeadlessChrome")
	return {
		"kind": "web",
		"user_agent": _browser_user_agent,
		"visibility_state": String(visibility_value),
		"was_hidden": was_hidden,
		"headless": headless,
		"authority_eligible": not was_hidden and not headless,
	}


func _publish_web_summary(result: Dictionary) -> void:
	var summary := {
		"scenario": result["scenario"],
		"authoritative": result["authoritative"],
		"execution_environment": result["execution_environment"],
		"frames": result["frames"],
		"physics": result["physics"],
		"presentation": result["presentation"],
		"hud": result["hud"],
		"draw_calls": result["draw_calls"],
		"subsystems": result["subsystems"],
		"counts": result["counts"],
		"combat_renderer": result["combat_renderer"],
		"engagement_telemetry": result["engagement_telemetry"],
		"scenario_validation": result["scenario_validation"],
		"thresholds": result["thresholds"],
	}
	var encoded_summary := JSON.stringify(summary)
	JavaScriptBridge.eval(
		"window.__cardbornePerformanceResultJson = %s;" % JSON.stringify(encoded_summary),
		true
	)


func _classify_frame_scheduler(
	execution_environment: Dictionary,
	frame_stats: Dictionary,
	physics_stats: Dictionary,
	presentation_stats: Dictionary,
	hud_stats: Dictionary
) -> void:
	var frame_median := float(frame_stats.get("median", 0.0))
	var measured_work_median := (
		float(physics_stats.get("median", 0.0))
		+ float(presentation_stats.get("median", 0.0))
		+ float(hud_stats.get("median", 0.0))
	)
	var unattributed_median := maxf(0.0, frame_median - measured_work_median)
	var scheduler_throttled := (
		OS.has_feature("web")
		and frame_median >= 50.0
		and unattributed_median >= frame_median * 0.5
	)
	execution_environment["frame_median_ms"] = frame_median
	execution_environment["measured_work_median_ms"] = measured_work_median
	execution_environment["unattributed_median_ms"] = unattributed_median
	execution_environment["scheduler_throttled"] = scheduler_throttled
	if scheduler_throttled:
		execution_environment["authority_eligible"] = false


func _optional_viewport_time(viewport: Viewport, cpu: bool) -> Variant:
	var viewport_rid := viewport.get_viewport_rid()
	if cpu and RenderingServer.has_method("viewport_get_measured_render_time_cpu"):
		return RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
	if not cpu and RenderingServer.has_method("viewport_get_measured_render_time_gpu"):
		return RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	return null
