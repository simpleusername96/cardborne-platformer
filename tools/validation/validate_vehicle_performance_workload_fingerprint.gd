extends SceneTree

const Scenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")


class ReplayContract:
	extends Node

	var current_stage_id: StringName = StageCatalog.STAGE_IDS[-1]
	var selected_run_difficulty: StringName = RunDifficulty.HARD
	var selected_primary: StringName = &"pulse_cannon"


var failures: Array[String] = []


func _initialize() -> void:
	var scenario := Scenario.new()
	var run := ReplayContract.new()
	var population := {
		"authored_population":StageCatalog.authored_population(StageCatalog.STAGE_IDS[-1]),
		"materialized_cap":48,
		"active_cap":48,
	}
	var first := int(scenario.call("_production_workload_fingerprint", run, population))
	var repeated := int(scenario.call("_production_workload_fingerprint", run, population))
	_expect(first != 0 and first == repeated, "production workload fingerprint is stable and nonzero")
	var changed_population := population.duplicate()
	changed_population["active_cap"] = 64
	_expect(
		first != int(scenario.call("_production_workload_fingerprint", run, changed_population)),
		"actor-cap changes produce a distinct workload fingerprint"
	)
	run.selected_primary = &"rail_lance"
	_expect(
		first != int(scenario.call("_production_workload_fingerprint", run, population)),
		"loadout changes produce a distinct workload fingerprint"
	)
	run.free()
	if failures.is_empty():
		print("VEHICLE_PERFORMANCE_WORKLOAD_FINGERPRINT_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
