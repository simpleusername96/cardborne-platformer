extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

const EXPECTED_MOBILE_COUNTS := [260, 300, 340, 380, 420]
const EXPECTED_QUOTAS := [125, 166, 208, 250, 291]

var failures: Array[String] = []


func _initialize() -> void:
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		var packets := Catalog.packets(stage_id)
		_expect(Catalog.packet_enemy_blueprint(stage_id).size() == EXPECTED_MOBILE_COUNTS[stage_index], "%s authors fivefold mobile reserves" % stage_id)
		_expect(Catalog.quota(stage_id) == EXPECTED_QUOTAS[stage_index], "%s sustains the expanded defeat quota" % stage_id)
		_expect(Array(packets[1]["squads"]).size() == 8, "%s surge packets contain eight squads" % stage_id)
		var surge_units := 0
		for squad in packets[1]["squads"]:
			surge_units += Array(squad).size()
		_expect(surge_units >= 24, "%s first surge carries at least twenty-four enemies" % stage_id)
		var runtime := Runtime.new()
		runtime.configure(stage_id, Catalog.packets(stage_id), RunDifficulty.HARD)
		var before := runtime.tick(5.0, 0)
		_expect(before["cues"].is_empty() and before["spawns"].is_empty(), "%s keeps a five-second safe opening" % stage_id)
		_expect(runtime.tick(0.1, 0)["cues"].size() == 1, "%s cues first scout at 5.1 seconds" % stage_id)
		runtime.tick(0.8, 0)
		var first := runtime.tick(0.1, 0)
		_expect(first["spawns"].size() == 1 and StringName(first["spawns"][0]["role"]) == &"scrap_drone", "%s spawns one scout at six seconds" % stage_id)
		runtime.stop_spawning()
		_expect(not runtime.spawning_enabled() and runtime.debug_snapshot()["queued_spawns"] == 0, "%s quota can stop future arrivals" % stage_id)
	_expect(Director.active_cap_for(1) == 62, "Hard first surge sustains the thirty-percent density increase")
	_expect(Director.active_cap_for(4) == 92, "Hard density uses the enlarged-field ceiling")
	_expect(RunDifficulty.scaled_active_cap(92, RunDifficulty.NORMAL) == 86, "Normal density scales from the enlarged-field ceiling")
	_expect(RunDifficulty.scaled_active_cap(92, RunDifficulty.EASY) == 81, "Easy density scales from the enlarged-field ceiling")
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
