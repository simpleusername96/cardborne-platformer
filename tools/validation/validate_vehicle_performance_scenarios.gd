extends SceneTree

const Scenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const Recorder = preload("res://scripts/performance/vehicle_performance_recorder.gd")
const PressureFixture = preload("res://scripts/performance/vehicle_pressure_fixture.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RUN_SCENE := "res://scenes/run/VehicleRun.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	InputProfile.apply_input_map(InputProfile.default_descriptors())
	var packed := load(RUN_SCENE) as PackedScene
	_expect(packed != null, "vehicle run scene loads")
	if packed == null:
		_finish()
		return
	var run = packed.instantiate()
	root.add_child(run)
	await process_frame
	run.set_process(false)
	run.set_physics_process(false)
	_expect(
		not Scenario.new().configure(&"current_pressure"),
		"retired current_pressure scenario is rejected rather than aliased"
	)
	var peak_fingerprint := 0
	for scenario_id in Scenario.VALID_SCENARIOS:
		print("Validating performance scenario: %s" % String(scenario_id))
		var scenario := Scenario.new()
		_expect(scenario.configure(scenario_id), "%s configures" % String(scenario_id))
		scenario.activate(run)
		print("Activated performance scenario: %s" % String(scenario_id))
		if scenario_id == &"production_replay":
			# This is a scheduler contract replay, not a frame benchmark. Ten-Hz
			# steps preserve the production decision cadence and enough simulated
			# time to reach the fenced peak beat plus its ten-second rolling window
			# without spending test time on redundant per-frame telemetry.
			for _step in 740:
				scenario.before_physics(run, 0.10)
				run.call("_update_encounter", 0.10)
				scenario.after_physics(run)
		scenario.after_physics(run)
		var snapshot := scenario.validation_snapshot(run)
		if scenario_id == &"production_replay" and not bool(snapshot["valid"]):
			print(
				"PRODUCTION_REPLAY_DIAGNOSTIC ",
				JSON.stringify({
					"scheduler":snapshot.get("scheduler", {}),
					"qualification":snapshot.get("production_qualification", {}),
					"enemies":snapshot.get("enemies", {}),
					"projectiles":snapshot.get("projectiles", {}),
				})
			)
		_expect(bool(snapshot["valid"]), "%s reaches every declared workload count" % String(scenario_id))
		var expected_by_scenario := {
			&"production_replay":-1,
			&"peak_horde":Scenario.PEAK_HORDE_TARGET,
			&"capacity_pressure":Scenario.CAPACITY_PRESSURE_TARGET,
			&"lifecycle_pressure":Scenario.CAPACITY_PRESSURE_TARGET,
			&"boss_pressure":Scenario.BOSS_PRESSURE_TARGET,
		}
		_expect(
			int(snapshot["expected_enemies"]) == int(expected_by_scenario[scenario_id]),
			"%s uses its locked actor load" % String(scenario_id)
		)
		_expect(
			StringName(snapshot["scenario_origin"]) == (
				&"production_scheduler" if scenario_id == &"production_replay" else &"fixture"
			),
			"%s reports its workload origin" % String(scenario_id)
		)
		if scenario_id == &"production_replay":
			_expect(bool(snapshot["scheduler_spawn_seen"]), "production replay creates actors through the real scheduler")
			var qualification := Dictionary(snapshot["production_qualification"])
			_expect(
				int(qualification["sample_count"]) == 10,
				"production replay retains a rolling ten-second peak window"
			)
			var production_samples: Array = qualification["samples"]
			_expect(
				not production_samples.is_empty()
				and int(Dictionary(production_samples[0]).get("authored_reserve", -1)) == 1260,
				"production replay reports the Stage 5 ordinary authored reserve"
			)
			_expect(
				int(qualification["median_active"])
					>= int(qualification["minimum_active"]),
				"production replay sustains at least ninety percent of the Hard peak cap"
			)
			_expect(
				bool(qualification["allocations"]["valid"]),
				"production replay allocation covers four quadrants without one-sided concentration"
			)
			_expect(
				int(qualification["maximum_ranged_commits"])
					<= EncounterDirector.MAX_RANGED_COMMITS
					and int(qualification["maximum_denial_commits"])
					<= EncounterDirector.MAX_DENIAL_COMMITS,
				"production replay peak window preserves commit caps"
			)
		else:
			_expect(int(snapshot["fixture_fingerprint"]) != 0, "%s publishes a fixture fingerprint" % String(scenario_id))
		if scenario_id == &"peak_horde":
			peak_fingerprint = int(snapshot["fixture_fingerprint"])
			_expect(
				PressureFixture.peak_qualification_passes(snapshot["fixture_qualification"]),
				"peak fixture passes locked focus and sector qualification"
			)
			var one_sided := Dictionary(snapshot["fixture_qualification"]).duplicate(true)
			one_sided["sector_histogram"] = PackedInt32Array([0, 0, 0, 0, 69, 69, 69, 69])
			one_sided["all_sectors"] = false
			one_sided["sector_range_valid"] = false
			_expect(
				not PressureFixture.peak_qualification_passes(one_sided),
				"one-sided peak placement fails qualification"
			)
		_expect(
			PackedInt32Array(snapshot["pressure"]["sector_histogram"]).size() == 8,
			"%s publishes an eight-sector pressure histogram" % String(scenario_id)
		)
		if scenario_id != &"production_replay":
			_expect(
				int(snapshot["pressure"]["hostile_projectiles"]) == int(snapshot["expected_hostile_projectiles"]),
				"%s pressure snapshot exposes hostile projectile occupancy" % String(scenario_id)
			)
		if scenario_id == &"capacity_pressure":
			run.projectile_store.remove_hostile_at_swap(
				run.projectile_store.hostile_count() - 1
			)
			snapshot = scenario.validation_snapshot(run)
			_expect(
				int(snapshot["projectiles"]["hostile"])
					== int(snapshot["expected_hostile_projectiles"]),
				"terminal capacity qualification refills a just-retired projectile"
			)
			_expect(
				bool(snapshot["valid"]),
				"terminal projectile retirement does not invalidate capacity load"
			)
			run.denied_zones.append({
				"source":"authored_fixture_probe",
				"pos":Vector2.ZERO,
				"duration":1.0,
			})
			scenario.after_physics(run)
			_expect(
				run.denied_zones.size() + run.damaging_trails.size() == 16,
				"real attack zones retire artificial fixture zones without lowering pressure"
			)
			var authored_probe_preserved := false
			for zone in run.denied_zones:
				if String(zone.get("source", "")) == "authored_fixture_probe":
					authored_probe_preserved = true
					break
			_expect(
				authored_probe_preserved,
				"fixture pressure maintenance preserves real attack zones"
			)
			for index in range(run.denied_zones.size() - 1, -1, -1):
				if String(run.denied_zones[index].get("source", "")) == "authored_fixture_probe":
					run.denied_zones.remove_at(index)
					break
			scenario.after_physics(run)
			_expect(
				run.denied_zones.size() + run.damaging_trails.size() == 16,
				"expired real zones are backfilled to the declared fixture pressure"
			)
		if scenario_id == &"lifecycle_pressure":
			_expect(int(snapshot["lifecycle_cycles"]) == 300, "lifecycle scenario retires 300 actors before capacity load")
			for _step in 20:
				scenario.before_physics(run, 0.25)
			snapshot = scenario.validation_snapshot(run)
			_expect(int(snapshot["lifecycle_cycles"]) >= 305, "lifecycle scenario keeps retiring and replacing actors during sampling")
			_expect(bool(snapshot["valid"]), "lifecycle churn preserves the declared live composition")
		scenario.deactivate()
	_expect(peak_fingerprint != 0, "peak workload has a stable nonzero fingerprint")
	_validate_threshold_contract()
	run.queue_free()
	await process_frame
	_finish()


func _validate_threshold_contract() -> void:
	var recorder := Recorder.new()
	recorder.scenario_id = &"peak_horde"
	recorder._max_consecutive_over_33 = 1
	var native_standard := _threshold_fixture("native", Vector2i(1280, 720))
	var thresholds: Dictionary = recorder._threshold_result(native_standard)
	_expect(bool(thresholds["passed"]), "native 1280 threshold boundary accepts the locked contract")
	_expect(float(thresholds["limits"]["draw_calls_p95"]) == 200.0, "draw-call gate remains locked at 200")
	_expect(int(thresholds["limits"]["combat_batches"]) == 50, "combat batch gate retains the canonical ceiling")
	_expect(float(thresholds["limits"]["frame_p95_ms"]) == 18.0, "native 1280 p95 gate remains locked at 18 ms")
	native_standard["draw_calls"]["p95"] = 201.0
	_expect(not bool(recorder._threshold_result(native_standard)["passed"]), "draw-call overflow fails release")
	native_standard["draw_calls"]["p95"] = 200.0
	native_standard["combat_renderer"]["batches"] = 52
	_expect(not bool(recorder._threshold_result(native_standard)["passed"]), "combat batch overflow fails release")

	recorder.scenario_id = &"capacity_pressure"
	recorder._max_consecutive_over_33 = 1
	var capacity := _threshold_fixture("native", Vector2i(1280, 720))
	_expect(bool(recorder._threshold_result(capacity)["passed"]), "capacity simulation accepts exact 6/8 ms bounds")
	capacity["physics"]["p95"] = 6.01
	_expect(not bool(recorder._threshold_result(capacity)["passed"]), "capacity simulation p95 above 6 ms fails")

	recorder.scenario_id = &"lifecycle_pressure"
	var lifecycle := _threshold_fixture("native", Vector2i(1280, 720))
	_expect(not bool(recorder._threshold_result(lifecycle)["passed"]), "60-second lifecycle sample cannot impersonate the soak")
	lifecycle["sample_seconds"] = 600.0
	_expect(bool(recorder._threshold_result(lifecycle)["passed"]), "ten-minute bounded lifecycle fixture can pass")
	lifecycle["memory"]["growth_bytes"] = 8.0 * 1024.0 * 1024.0
	_expect(not bool(recorder._threshold_result(lifecycle)["passed"]), "eight MiB lifecycle growth fails the strict bound")

	recorder.scenario_id = &"peak_horde"
	recorder._max_consecutive_over_33 = 2
	var web_standard := _threshold_fixture("web", Vector2i(1280, 720))
	_expect(bool(recorder._threshold_result(web_standard)["passed"]), "Web 1280 uses the locked Web frame contract")
	recorder._max_consecutive_over_33 = 3
	_expect(not bool(recorder._threshold_result(web_standard)["passed"]), "three consecutive Web stalls fail")

	recorder._max_consecutive_over_33 = 20
	var native_high_resolution := _threshold_fixture("native", Vector2i(2560, 1600))
	_expect(bool(recorder._threshold_result(native_high_resolution)["passed"]), "native 2560 contract has no consecutive-frame gate")
	var unsupported := _threshold_fixture("native", Vector2i(1920, 1080))
	_expect(not bool(recorder._threshold_result(unsupported)["passed"]), "undeclared viewport cannot produce a passing result")


func _threshold_fixture(kind: String, window_size: Vector2i) -> Dictionary:
	return {
		"authoritative": true,
		"sample_seconds": 60.0,
		"execution_environment": {"kind": kind},
		"frames": {
			"median": 16.0,
			"p95": 18.0,
			"p99": 25.0,
			"one_percent_low_fps": 55.0,
		},
		"physics": {"p95": 6.0, "p99": 8.0},
		"draw_calls": {"p95": 200.0},
		"combat_renderer": {"batches": 50},
		"scenario_validation": {"valid": true},
		"viewport": {
			"window": [window_size.x, window_size.y],
			"cpu_render_ms": 9.0,
			"gpu_render_ms": 9.0,
		},
		"memory": {"growth_bytes": 0.0},
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PERFORMANCE_SCENARIOS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
