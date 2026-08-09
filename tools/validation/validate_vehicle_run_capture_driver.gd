extends SceneTree

const RUN_PATH := "res://scripts/vehicle/vehicle_run.gd"
const DRIVER_PATH := "res://scripts/vehicle/vehicle_run_capture_driver.gd"
const GATEWAY_PATH := "res://scripts/vehicle/vehicle_run_capture_gateway.gd"
const Driver = preload(DRIVER_PATH)

var _failures: Array[String] = []


func _initialize() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	var driver_source := FileAccess.get_file_as_string(DRIVER_PATH)
	var gateway_source := FileAccess.get_file_as_string(GATEWAY_PATH)
	_expect(run_source.contains("vehicle_run_capture_driver.gd"), "run composes capture driver")
	_expect(run_source.contains("vehicle_run_capture_gateway.gd"), "run composes capture gateway")
	_expect(
		run_source.contains("CaptureDriver.is_requested_from_command_line()"),
		"normal play checks request before creating capture objects"
	)
	_expect(
		not run_source.contains("func _run_capture_sequence"),
		"VehicleRun no longer owns capture sequence"
	)
	_expect(
		not run_source.contains("func _capture_"),
		"VehicleRun no longer owns capture fixture implementations"
	)
	for owned_token in [
		"--capture-all=",
		"--capture-locale=",
		"--capture-size=",
		"DirAccess.make_dir_recursive_absolute",
		"save_png(",
		"capture-manifest.json",
		"_write_manifest(gateway)",
		"FULL_CAPTURE_FILES",
		"VEHICLE_STAGE_CAPTURE_COMPLETE",
	]:
		_expect(driver_source.contains(owned_token), "capture driver owns %s" % owned_token)
		_expect(not run_source.contains(owned_token), "VehicleRun no longer owns %s" % owned_token)
	for gateway_api in [
		"prepare_stage",
		"prepare_boss",
		"lower_boss_shield",
		"set_player_fixture",
		"set_world_fixture",
		"show_ui_fixture",
		"snapshot",
		"refresh_capture_text_scale",
		"set_debug_overlay",
		"restore_baseline",
	]:
		_expect(
			gateway_source.contains("func %s(" % gateway_api),
			"capture gateway exposes %s" % gateway_api
		)
	_expect(
		gateway_source.contains("\"content_scale_size\":_run.get_window().content_scale_size"),
		"capture gateway preserves logical viewport baseline"
	)
	_expect(
		gateway_source.contains("_run.get_window().content_scale_size = viewport_size"),
		"capture gateway applies requested logical viewport"
	)
	_expect(
		driver_source.contains("Capture logical viewport mismatch"),
		"capture driver rejects incorrectly scaled evidence"
	)
	_expect(
		driver_source.contains("finish_capture(gateway, 1)"),
		"capture failures share terminal cleanup path"
	)
	_expect(
		run_source.contains("restore_on_exit(_capture_gateway)"),
		"tree exit has capture restore fallback"
	)
	_expect(
		not driver_source.contains("._capture_"),
		"driver does not access VehicleRun private capture hooks"
	)
	_expect(Driver.CORE_CAPTURE_FILES.size() == 36, "core manifest has 36 captures")
	_expect(Driver.FULL_CAPTURE_FILES.size() == 103, "full manifest has 103 captures")
	for required_capture in [
		"03d-movement-cover-approach.png",
		"03e-movement-cover-turn.png",
		"03f-movement-cover-standoff.png",
		"04-stage-4-xp-hud.png",
		"04b-stage-4-xp-collected.png",
		"04c-progression-max.png",
		"04d-ship-status-acquired-build.png",
		"04e-radar-minimap-roles.png",
		"06-thermal-first-acquisition.png",
		"06c-thermal-enhancement.png",
		"06d-two-card-tail.png",
		"05b-reinforcement-facility.png",
		"05c-structural-health-bars.png",
		"09-effects-essential-transients.png",
		"09-effects-projectile-hostile-startup.png",
		"09-effects-projectile-hostile-flight.png",
		"09-effects-projectile-hostile-hit.png",
		"09-effects-arc-mine-startup.png",
		"09-effects-beam-sentinel-startup.png",
		"09-effects-beam-sentinel-active.png",
		"09b-element-status-application.png",
		"09c-element-status-persistent.png",
		"09d-element-status-hit-flash.png",
		"09e-element-status-reduced-motion.png",
		"09f-element-status-expired.png",
		"09g-electric-field-level-1.png",
		"09h-electric-field-level-2.png",
		"09i-electric-field-level-3.png",
		"09j-thermal-burst-level-1.png",
		"09k-thermal-burst-level-2.png",
		"09l-thermal-burst-level-3.png",
		"09m-thermal-burst-saturation-emp.png",
		"30-boss-01-stage-1-arc-area-startup.png",
		"30-boss-05-stage-5-crown-beam-startup.png",
		"30-boss-05-stage-5-crown-beam-active.png",
	]:
		_expect(required_capture in Driver.FULL_CAPTURE_FILES, "full manifest includes %s" % required_capture)
	_expect(
		_unique_count(Driver.FULL_CAPTURE_FILES) == Driver.FULL_CAPTURE_FILES.size(),
		"full manifest has no duplicate filenames"
	)
	for file_name in Driver.CORE_CAPTURE_FILES:
		_expect(file_name in Driver.FULL_CAPTURE_FILES, "full manifest includes %s" % file_name)
	_finish()


func _unique_count(values: Array) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_RUN_CAPTURE_DRIVER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
