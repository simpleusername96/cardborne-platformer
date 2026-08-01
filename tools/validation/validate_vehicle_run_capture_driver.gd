extends SceneTree

const RUN_PATH := "res://scripts/vehicle/vehicle_run.gd"
const DRIVER_PATH := "res://scripts/vehicle/vehicle_run_capture_driver.gd"

var _failures: Array[String] = []


func _initialize() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	var driver_source := FileAccess.get_file_as_string(DRIVER_PATH)
	_expect(run_source.contains("vehicle_run_capture_driver.gd"), "run composes capture driver")
	for owned_token in [
		"--capture-all=", "--capture-locale=", "--capture-size=",
		"DirAccess.make_dir_recursive_absolute", "save_png("
	]:
		_expect(
			driver_source.contains(owned_token),
			"capture driver owns %s" % owned_token
		)
		_expect(
			not run_source.contains(owned_token),
			"VehicleRun no longer owns %s" % owned_token
		)
	_finish()


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
