extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for stage_id in Catalog.STAGE_IDS:
		var runtime := Runtime.new()
		runtime.configure(stage_id, Catalog.packets(stage_id), &"standard")
		var before := runtime.tick(5.0, 0)
		_expect(before["cues"].is_empty() and before["spawns"].is_empty(), "%s keeps a five-second safe opening" % stage_id)
		_expect(runtime.tick(0.1, 0)["cues"].size() == 1, "%s cues first scout at 5.1 seconds" % stage_id)
		runtime.tick(0.8, 0)
		var first := runtime.tick(0.1, 0)
		_expect(first["spawns"].size() == 1 and StringName(first["spawns"][0]["role"]) == &"scrap_drone", "%s spawns one scout at six seconds" % stage_id)
		runtime.stop_spawning()
		_expect(not runtime.spawning_enabled() and runtime.debug_snapshot()["queued_spawns"] == 0, "%s quota can stop future arrivals" % stage_id)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENCOUNTER_PACING_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
