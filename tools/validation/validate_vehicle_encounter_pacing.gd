extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_arrival_contract()
	_check_packet_timeline()
	_check_presets_and_populations()
	_check_cohesion_contract()
	_check_scheduler_saturation_contract()
	_check_metrics_contract()
	if failures.is_empty():
		print("PASS: grace, sequential squads, beat caps, deterministic packets, cohesion, and bounded saturation")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _check_arrival_contract() -> void:
	var runtime := EncounterRuntime.new()
	runtime.configure(&"flooded_works", Catalog.packets(&"flooded_works"), &"standard")
	var before := runtime.tick(5.0, 0)
	_expect(before["cues"].is_empty() and before["spawns"].is_empty(), "arrival remains quiet through five seconds")
	var cue := runtime.tick(0.1, 0)
	_expect(cue["cues"].size() == 1 and cue["spawns"].is_empty(), "large arrival cue begins at 5.1 seconds")
	var almost := runtime.tick(0.8, 0)
	_expect(almost["spawns"].is_empty(), "no enemy spawns before six seconds")
	var first := runtime.tick(0.1, 0)
	_expect(first["spawns"].size() == 1, "exactly one enemy spawns at six seconds")
	if not first["spawns"].is_empty():
		_expect(StringName(first["spawns"][0]["role"]) == &"scrap_drone", "first enemy is the authored single scout")
	var snapshot := runtime.debug_snapshot()
	_expect(is_equal_approx(float(snapshot["first_cue_time"]), 5.1), "first cue metric records 5.1 seconds")
	_expect(is_equal_approx(float(snapshot["first_spawn_time"]), 6.0), "first spawn metric records 6.0 seconds")
	_expect(runtime.active_cap() == 1, "arrival beat active cap is one")


func _check_packet_timeline() -> void:
	var first := _simulate_all_stage_one_events()
	var second := _simulate_all_stage_one_events()
	_expect(first["timeline"] == second["timeline"], "fixed event schedule reproduces the same timeline")
	_expect(bool(first["one_per_tick"]), "scheduler never emits two units on one tick")
	var timeline: Array = first["timeline"]
	var west_times := _spawn_times_for_squad(timeline, "west_learning_s01")
	_expect(west_times.size() == 3, "Beat 1 first squad has three units")
	if west_times.size() == 3:
		_expect(is_equal_approx(west_times[1] - west_times[0], 0.272) and is_equal_approx(west_times[2] - west_times[1], 0.272), "Beat 1 Standard units enter at 0.272-second spacing")
	var west_next := _spawn_times_for_squad(timeline, "west_learning_s02")
	if not west_times.is_empty() and not west_next.is_empty():
		_expect(is_equal_approx(west_next[0] - west_times[0], 2.72), "Beat 1 Standard squad starts are 2.72 seconds apart")
	var calibration_times := _spawn_times_for_squad(timeline, "calibration_return_s01")
	_expect(calibration_times.size() == 4, "Beat 2 first squad has four units")
	var upper_times := _spawn_times_for_squad(timeline, "north_generator_s01")
	var relay_times := _spawn_times_for_squad(timeline, "relay_compound_s01")
	_expect(upper_times.size() == 5 and relay_times.size() == 5, "later beats use five-unit squads")


func _simulate_all_stage_one_events() -> Dictionary:
	var runtime := EncounterRuntime.new()
	runtime.configure(&"flooded_works", Catalog.packets(&"flooded_works"), &"standard")
	var one_per_tick := true
	var events := {
		7.0:&"approach_entered", 18.0:&"calibration_claimed", 34.0:&"upper_route_entered",
		50.0:&"lower_route_entered", 66.0:&"generators_complete",
	}
	for step in 2400:
		var target_time := float(step) * 0.05
		for event_time in events:
			if is_equal_approx(target_time, float(event_time)):
				runtime.signal_event(events[event_time])
		var request := runtime.tick(0.05, 0)
		one_per_tick = one_per_tick and request["spawns"].size() <= 1
	return {"timeline":runtime.debug_snapshot()["timeline"], "one_per_tick":one_per_tick}


func _spawn_times_for_squad(timeline: Array, squad_id: String) -> Array[float]:
	var result: Array[float] = []
	for entry in timeline:
		if StringName(entry.get("kind", &"")) == &"spawn" and String(entry.get("squad_id", "")) == squad_id:
			result.append(float(entry["time"]))
	return result


func _check_presets_and_populations() -> void:
	var expected_standard := [1,15,22,28,32]
	var expected_onslaught := [1,22,33,44,52]
	for beat in 5:
		_expect(Director.active_cap_for(beat, &"standard") == expected_standard[beat], "Standard beat %d cap matches" % beat)
		_expect(Director.active_cap_for(beat, &"onslaught") == expected_onslaught[beat], "Onslaught beat %d cap matches" % beat)
	var expected_health := [1.0, 1.04, 1.08, 1.12, 1.16]
	var expected_damage := [1.0, 1.03, 1.06, 1.09, 1.12]
	var expected_speed := [1.0, 1.01, 1.02, 1.03, 1.04]
	for stage_index in 5:
		var multipliers := Difficulty.multipliers(stage_index)
		_expect(is_equal_approx(float(multipliers["health"]), expected_health[stage_index]), "stage %d uses the bounded health curve" % (stage_index + 1))
		_expect(is_equal_approx(float(multipliers["damage"]), expected_damage[stage_index]), "stage %d uses the bounded damage curve" % (stage_index + 1))
		_expect(is_equal_approx(float(multipliers["speed"]), expected_speed[stage_index]), "stage %d uses the bounded speed curve" % (stage_index + 1))
	_expect(Director.STANDARD_THREAT_BUDGETS == [1.0,3.0,4.5,5.25,6.25], "Standard threat budgets use the locked bounded curve")
	for stage_id in Catalog.STAGE_IDS:
		var population := Catalog.authored_population(stage_id)
		var band := Director.population_band(stage_id)
		_expect(population >= band.x and population <= band.y, "%s authored population stays inside %d-%d" % [stage_id, band.x, band.y])
	_expect(is_equal_approx(Director.spawn_pace_multiplier(0, &"standard"), 1.0), "arrival scout pacing remains unchanged")
	_expect(is_equal_approx(Director.spawn_pace_multiplier(1, &"standard"), 0.34), "Standard post-arrival pacing is 0.34x")
	_expect(is_equal_approx(Director.spawn_pace_multiplier(1, &"onslaught"), 0.28), "Onslaught post-arrival pacing is 0.28x")


func _check_cohesion_contract() -> void:
	var members: Array[Dictionary] = [
		{"alive":true,"active":true,"squad_id":"probe","pos":Vector2(0,0)},
		{"alive":true,"active":true,"squad_id":"probe","pos":Vector2(100,0)},
		{"alive":true,"active":true,"squad_id":"probe","pos":Vector2(0,100)},
	]
	var enemy := members[1]
	enemy["phase"] = "move"
	enemy["formation_offset"] = Vector2.ZERO
	var role_velocity := Vector2(0,100)
	var snapshot := Director.squad_motion_snapshot(members)
	var blended := Director.cohesion_velocity(enemy, snapshot, role_velocity)
	var centroid := Vector2(100.0/3.0,100.0/3.0)
	_expect(blended.dot(centroid - Vector2(enemy["pos"])) > 0.0, "non-committed movement receives inward cohesion steering")
	enemy["phase"] = "startup"
	_expect(Director.cohesion_velocity(enemy, snapshot, role_velocity) == role_velocity, "committed startup is never bent by formation steering")


func _check_scheduler_saturation_contract() -> void:
	var runtime := EncounterRuntime.new()
	runtime.configure(&"flooded_works", Catalog.packets(&"flooded_works"), &"standard")
	runtime.tick(5.1, 0)
	for _blocked_tick in 180:
		runtime.tick(1.0 / 60.0, 999)
	var delayed_snapshot := runtime.debug_snapshot()
	_expect(float(delayed_snapshot["schedule_delay"]) >= 2.0, "a saturated cap accumulates scheduler delay without dropping requests")
	var activation_time := float(delayed_snapshot["elapsed"])
	runtime.signal_event(&"approach_entered")
	runtime.tick(0.0, 999)
	var west_cue_time := -1.0
	for entry in runtime.debug_snapshot()["timeline"]:
		if StringName(entry.get("kind", &"")) == &"cue" and String(entry.get("id", "")) == "west_learning_s01":
			west_cue_time = float(entry["time"])
			break
	_expect(is_equal_approx(west_cue_time, activation_time), "a newly activated packet does not inherit earlier cap delay")

	var metrics_runtime := EncounterRuntime.new()
	metrics_runtime.configure(&"flooded_works", Catalog.packets(&"flooded_works"), &"standard")
	for _sample in 5000:
		metrics_runtime.tick(0.1, 0)
	_expect(int(metrics_runtime.debug_snapshot()["active_count_samples"]) == 4096, "long-session metric history remains bounded")


func _check_metrics_contract() -> void:
	var runtime := EncounterRuntime.new()
	runtime.configure(&"flooded_works", Catalog.packets(&"flooded_works"), &"standard")
	for second in 60:
		var count := mini(second / 4, runtime.active_cap())
		runtime.tick(1.0, count, [&"melee", &"ranged"])
	runtime.record_player_damage(&"projectile")
	runtime.record_reward()
	var snapshot := runtime.debug_snapshot()
	_expect(int(snapshot["active_count_p90"]) > 0, "local metrics retain an active-count percentile")
	_expect(int(snapshot["max_attack_family_overlap"]) == 2, "local metrics retain attack-family overlap")
	_expect(int(snapshot["damage_source_families"].get(&"projectile", 0)) == 1, "local metrics retain damage-source families")
	_expect(float(snapshot["first_reward_time"]) >= 45.0 and float(snapshot["first_reward_time"]) <= 75.0, "critical-route reward window is represented in first-clear metrics")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
