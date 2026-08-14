extends SceneTree

const Scenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const Recorder = preload("res://scripts/performance/vehicle_performance_recorder.gd")
const PressureFixture = preload("res://scripts/performance/vehicle_pressure_fixture.gd")
const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
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
		_expect(
			scenario.after_physics_is_diagnostic_only()
				== (scenario_id == &"production_replay"),
			"%s declares whether after-physics work is diagnostic-only"
			% String(scenario_id)
		)
		scenario.activate(run)
		if scenario_id == &"production_replay":
			run.encounter_runtime.set_pressure_observation_enabled(true)
		print("Activated performance scenario: %s" % String(scenario_id))
		if scenario_id == &"production_replay":
			var performance_state := {}
			run.encounter_runtime.fill_performance_state(performance_state)
			_expect(
				performance_state.has("materialized_spawned")
					and performance_state.has("pressure_active")
					and not performance_state.has("timeline")
					and not performance_state.has("allocations"),
				"production replay uses the bounded scheduler sample instead of full debug history"
			)
			var stable_population := true
			var stabilized_count := 0
			for enemy in run.enemies:
				if not enemy.alive or not enemy.active or not enemy.counts_active_cap:
					continue
				stabilized_count += 1
				stable_population = (
					stable_population
					and enemy.health >= Scenario.PERFORMANCE_ENEMY_HEALTH
					and enemy.max_health >= Scenario.PERFORMANCE_ENEMY_HEALTH
				)
			_expect(
				stable_population
					and stabilized_count
						>= floori(
							float(run.encounter_runtime.active_cap())
							* Scenario.PRODUCTION_REPLAY_MIN_ACTIVE_RATIO
						),
				"production replay stabilizes its timed peak without disabling attacks"
			)
			# This is a scheduler contract replay, not a frame benchmark. Ten-Hz
			# steps preserve the production decision cadence. Packet fences can defer
			# a later authored beat while the preceding population enters in windows,
			# so the replay runs until the peak beat is actually active and then keeps
			# one full ten-second qualification window. The bound is derived from the
			# authored trigger plus a bounded packet-drain allowance rather than a
			# wall-clock benchmark duration.
			var final_trigger := _final_authored_trigger_time(run.current_stage_id)
			var replay_limit := ceili((final_trigger + 240.0) / 0.10)
			var peak_window_steps := -1
			for _step in replay_limit:
				scenario.before_physics(run, 0.10)
				run.call("_update_encounter", 0.10)
				scenario.after_physics(run)
				if peak_window_steps < 0 and run.encounter_runtime.current_beat >= 4:
					peak_window_steps = 0
				elif peak_window_steps >= 0:
					peak_window_steps += 1
					if peak_window_steps >= 120:
						break
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
		var effect_store_snapshot := Dictionary(snapshot["effect_store"])
		_expect(
			bool(effect_store_snapshot["valid"])
				and int(effect_store_snapshot["capacity"]) == 96
				and int(effect_store_snapshot["state_instances_created"]) == 96
				and int(effect_store_snapshot["live"]) == int(snapshot["effects"])
				and int(effect_store_snapshot["live"])
					+ int(effect_store_snapshot["pool"]) == 96,
			"%s runtime qualification proves fixed effect-store ownership and accounting"
			% String(scenario_id)
		)
		if scenario_id in [&"capacity_pressure", &"lifecycle_pressure"]:
			_expect(
				int(snapshot["effects"]) == 96
					and int(effect_store_snapshot["live"]) == 96
					and int(effect_store_snapshot["pool"]) == 0,
				"%s qualifies the fully saturated 96-state effect workload"
				% String(scenario_id)
			)
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
			int(snapshot["health_overlay_capacity"]) == 26,
			"%s keeps the fixed world-health overlay capacity" % String(scenario_id)
		)
		_expect(
			StringName(snapshot["scenario_origin"]) == (
				&"production_scheduler" if scenario_id == &"production_replay" else &"fixture"
			),
			"%s reports its workload origin" % String(scenario_id)
		)
		if scenario_id == &"production_replay":
			var final_authored_population := StageCatalog.authored_population(
				StageCatalog.STAGE_IDS[-1]
			)
			_expect(bool(snapshot["scheduler_spawn_seen"]), "production replay creates actors through the real scheduler")
			_expect(
				int(snapshot["workload_fingerprint"]) != 0
					and int(snapshot["fixture_fingerprint"])
						== int(snapshot["workload_fingerprint"]),
				"production replay publishes a nonzero authored workload fingerprint"
			)
			var qualification := Dictionary(snapshot["production_qualification"])
			var population := Dictionary(snapshot.get("population", {}))
			_expect(
				int(qualification["sample_count"]) == 10,
				"production replay retains a rolling ten-second peak window"
			)
			var production_samples: Array = qualification["samples"]
			_expect(
				not production_samples.is_empty()
				and int(Dictionary(production_samples[0]).get("authored_population", -1))
					== final_authored_population,
				"production replay reports the final Stage 10 authored population"
			)
			_expect(
				int(population.get("authored_population", -1)) == final_authored_population
				and int(population.get("materialized_spawned", -1)) >= 0
				and int(population.get("virtual_reserve", -1)) >= 0
				and int(population.get("materialized_cap", -1)) > 0
				and int(population.get("active_cap", -1)) > 0,
				"production replay publishes authored, materialized, reserve, and cap populations"
			)
			_expect(
				int(population["authored_population"])
					== int(population["materialized_spawned"])
						+ int(population["virtual_reserve"]),
				"production replay population accounting balances authored and remaining reserve"
			)
			var scheduler_queues := Dictionary(population.get("scheduler_queues", {}))
			_expect(
				int(scheduler_queues.get("windows", -1)) >= 0
				and int(scheduler_queues.get("spawned", -1)) >= 0
				and int(scheduler_queues.get("reserved_arrival_slots", -1)) >= 0,
				"production replay includes scheduler queue accounting with population evidence"
			)
			_expect(
				int(qualification["median_active"])
					>= int(qualification["minimum_active"]),
				"production replay sustains the discrete ninety-percent Hard peak floor"
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
			run.experience_runtime.spawn_shard(Vector2.ZERO, 1)
			scenario.after_physics(run)
			snapshot = scenario.validation_snapshot(run)
			_expect(
				int(snapshot["experience"]) == int(snapshot["experience_target"]),
				"measured after-physics maintenance trims excess shard pressure"
			)
		_expect(
			PackedInt32Array(snapshot["pressure"]["sector_histogram"]).size() == 8,
			"%s publishes an eight-sector pressure histogram" % String(scenario_id)
		)
		if scenario_id != &"production_replay":
			_expect(
				int(snapshot["experience"]) == int(snapshot["experience_target"]),
				"%s sustains its exact experience-shard workload" % String(scenario_id)
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
			var effect_target := int(snapshot["effect_target"])
			run.effect_store.remove_at_swap(run.effects.size() - 1)
			var depleted_effect_count: int = run.effects.size()
			snapshot = scenario.validation_snapshot(run)
			_expect(
				depleted_effect_count == effect_target - 1
					and int(snapshot["effects"]) == depleted_effect_count
					and run.effects.size() == depleted_effect_count,
				"terminal effect qualification observes depletion without repairing it"
			)
			_expect(
				not bool(snapshot["valid"]),
				"terminal effect depletion invalidates the declared exact workload"
			)
			scenario.after_physics(run)
			snapshot = scenario.validation_snapshot(run)
			_expect(
				int(snapshot["effects"]) == effect_target and bool(snapshot["valid"]),
				"measured after-physics maintenance restores exact effect pressure"
			)
			run.experience_runtime.call(
				"_swap_remove", run.experience_runtime.shards.size() - 1
			)
			snapshot = scenario.validation_snapshot(run)
			_expect(
				int(snapshot["experience"]) == int(snapshot["experience_target"]) - 1
				and not bool(snapshot["valid"]),
				"terminal shard depletion invalidates the declared exact workload"
			)
			scenario.after_physics(run)
			snapshot = scenario.validation_snapshot(run)
			_expect(
				int(snapshot["experience"]) == int(snapshot["experience_target"])
				and bool(snapshot["valid"]),
				"measured after-physics maintenance restores exact shard pressure"
			)
			run.denied_zones.append({
				"source":"authored_fixture_probe",
				"pos":Vector2.ZERO,
				"duration":1.0,
			})
			scenario.after_physics(run)
			_expect(
				run.denied_zones.size() == 16,
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
				run.denied_zones.size() == 16,
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
		if scenario_id == &"production_replay":
			run.encounter_runtime.set_pressure_observation_enabled(false)
	for target in Scenario.DIAGNOSTIC_EXACT_CAPS:
		var scaling := Scenario.new()
		_expect(
			scaling.configure(&"capacity_pressure", target),
			"capacity diagnostics accept exact %d-enemy target" % target
		)
		scaling.activate(run)
		scaling.after_physics(run)
		var scaling_snapshot := scaling.validation_snapshot(run)
		_expect(
			bool(scaling_snapshot["valid"])
				and bool(scaling_snapshot["diagnostic_only"])
				and bool(scaling_snapshot["exact_target_matched"])
				and int(scaling_snapshot["expected_enemies"]) == target
				and int(scaling_snapshot["ordinary_enemies"]) == target
				and int(scaling_snapshot["exact_ordinary_count"]) == target
				and int(scaling_snapshot["diagnostic_enemy_count"]) == target
				and int(scaling_snapshot["authored_reserve"]) >= 0
				and int(scaling_snapshot["role_mix_fingerprint"]) != 0,
			"%d-enemy diagnostic labels its exact count, reserve, role mix, and combat workload"
			% target
		)
		scaling.deactivate()
	_expect(
		not Scenario.new().configure(&"peak_horde", 64)
			and not Scenario.new().configure(&"capacity_pressure", 63)
			and not Scenario.new().configure(&"capacity_pressure", 321),
		"enemy-count overrides remain diagnostic-only and limited to the declared staircase"
	)
	_expect(peak_fingerprint != 0, "peak workload has a stable nonzero fingerprint")
	_validate_threshold_contract()
	run.queue_free()
	await process_frame
	_finish()


func _final_authored_trigger_time(stage_id: StringName) -> float:
	var final_beat := 0
	var trigger_time := 0.0
	for packet in StageCatalog.packets(stage_id):
		var beat := int(packet.get("beat", 0))
		var trigger := Dictionary(packet.get("trigger", {}))
		if StringName(trigger.get("kind", &"")) != &"time":
			continue
		var at := float(trigger.get("at", 0.0))
		if beat > final_beat:
			final_beat = beat
			trigger_time = at
		elif beat == final_beat:
			trigger_time = minf(trigger_time, at)
	return trigger_time


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

	recorder.scenario_id = &"production_replay"
	recorder._max_consecutive_over_33 = 1
	var production_replay := _threshold_fixture("native", Vector2i(1280, 720))
	_expect(
		bool(recorder._threshold_result(production_replay)["passed"]),
		"production replay applies the same exact 6/8 ms capacity limits"
	)
	production_replay["physics"]["p99"] = 8.01
	_expect(
		not bool(recorder._threshold_result(production_replay)["passed"]),
		"production replay p99 above 8 ms fails the shipping capacity contract"
	)

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
