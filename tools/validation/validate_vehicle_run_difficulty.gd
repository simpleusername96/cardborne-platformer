extends SceneTree

const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(RunDifficulty.IDS == [&"hard"], "difficulty exposes exactly one fixed Hard identifier")
	_expect(RunDifficulty.DEFAULT == RunDifficulty.HARD, "fixed difficulty defaults to Hard")
	_expect(RunDifficulty.is_valid(&"hard"), "Hard is the only valid difficulty identifier")
	_expect(not RunDifficulty.is_valid(&"normal") and not RunDifficulty.is_valid(&"easy"), "retired identifiers are not valid choices")
	_expect(RunDifficulty.normalize(&"unknown") == RunDifficulty.HARD, "unknown identifiers collapse to Hard")
	_expect(RunDifficulty.normalize(&"normal") == RunDifficulty.HARD, "retired Normal collapses to Hard")
	_expect(RunDifficulty.normalize(&"easy") == RunDifficulty.HARD, "retired Easy collapses to Hard")
	_expect(is_equal_approx(EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER, 1.40), "ordinary movement multiplier is locked to 1.40")
	_expect(is_equal_approx(EncounterDirector.ENEMY_DAMAGE_MULTIPLIER, 1.755), "ordinary outgoing-damage multiplier is locked to 1.755")
	for axis in ["quota", "active_cap", "health", "boss_health", "damage", "speed"]:
		_expect(is_equal_approx(RunDifficulty.factor(RunDifficulty.HARD, axis), 1.0), "Hard %s factor preserves the previous baseline" % axis)
		_expect(is_equal_approx(RunDifficulty.factor(&"easy", axis), 1.0), "retired identifiers cannot alter the %s factor" % axis)
	_expect(is_equal_approx(RunDifficulty.simultaneous_pressure(RunDifficulty.HARD), 1.0), "Hard preserves ordinary pressure")
	_expect(is_equal_approx(RunDifficulty.simultaneous_pressure(RunDifficulty.HARD, true), 1.0), "Hard preserves boss pressure")
	_expect(RunDifficulty.scaled_quota(125, RunDifficulty.HARD) == 125, "Hard preserves the enlarged stage-one quota")
	_expect(RunDifficulty.scaled_quota(125, &"normal") == 125, "retired identifiers cannot scale quota")
	_expect(RunDifficulty.scaled_active_cap(9, &"easy") == 9, "retired identifiers cannot scale active cap")

	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	var stage_ui = stage.get("_ui")
	stage_ui.call("show_deployment", &"pulse_cannon", "FIELD_DROWNED_RUIN")
	stage_ui.call("debug_submit_deployment")
	_expect(stage.selected_run_difficulty == RunDifficulty.HARD, "deployment starts the fixed Hard run")
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.HARD, "encounter runtime starts at fixed Hard")
	_expect(stage.stage_flow.quota == StageCatalog.quota(&"stage_1"), "active stage quota preserves the previous Hard value")
	var hard_enemy = stage.call("_make_enemy", {"id":"hard_probe", "role":&"chaser", "pos":Vector2.ZERO})
	var hard_boss = stage.call("_make_enemy", {"id":"hard_boss_probe", "role":&"stage_boss", "pos":Vector2.ZERO})
	_expect(
		_near(
			hard_enemy.speed,
			190.0 * EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER,
			0.001
		),
		"ordinary movement uses its dedicated multiplier"
	)
	_expect(
		_near(
			hard_boss.speed,
			150.0 * EncounterDirector.ENEMY_SPEED_MULTIPLIER,
			0.001
		),
		"boss movement preserves the committed-attack multiplier"
	)
	var health_curve := [0.85, 1.00, 1.15, 1.30, 1.45]
	var health_pressure := [1.15, 1.55, 1.70, 1.85, 2.00]
	var previous_health_pressure := [1.35, 1.45, 1.55, 1.65, 1.75]
	var boss_bases := [1250.0, 1350.0, 1450.0, 1550.0, 1650.0]
	var boss_health_multipliers := [4.20, 4.30, 4.40, 4.50, 4.60]
	_expect(StageDifficulty.HEALTH == health_curve, "ordinary health uses the locked five-stage curve")
	_expect(
		StageDifficulty.ORDINARY_HEALTH_PRESSURE == health_pressure,
		"ordinary health applies the revised five-stage pressure curve"
	)
	_expect(
		_near(health_pressure[0] / previous_health_pressure[0], 0.85, 0.01),
		"Stage 1 ordinary health pressure is approximately 15 percent lower"
	)
	for stage_index in range(1, health_pressure.size()):
		_expect(
			health_pressure[stage_index] > previous_health_pressure[stage_index],
			"Stage %d ordinary health pressure is higher than the previous curve"
				% (stage_index + 1)
		)
	for stage_index in health_curve.size():
		stage.current_stage_index = stage_index
		var standard_enemy = stage.call("_make_enemy", {
			"id":"standard_health_%d" % stage_index,
			"role":&"chaser",
			"pos":Vector2.ZERO,
		})
		var priority_enemy = stage.call("_make_enemy", {
			"id":"priority_health_%d" % stage_index,
			"role":&"repair_tender",
			"pos":Vector2.ZERO,
		})
		var stage_boss = stage.call("_make_enemy", {
			"id":"boss_health_%d" % stage_index,
			"role":&"stage_boss",
			"pos":Vector2.ZERO,
		})
		_expect(
			_near(
				standard_enemy.health,
				48.0 * EncounterDirector.ENEMY_HEALTH_MULTIPLIER
					* health_curve[stage_index]
					* health_pressure[stage_index]
					* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER,
				0.001
			),
			"Stage %d applies class and stage factors to standard health"
				% (stage_index + 1)
		)
		_expect(
			_near(
				priority_enemy.health,
				74.0 * health_curve[stage_index]
					* health_pressure[stage_index]
					* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER,
				0.001
			),
			"Stage %d applies only the stage factor to priority health"
				% (stage_index + 1)
		)
		_expect(
			_near(
				stage_boss.health,
				boss_bases[stage_index]
					* boss_health_multipliers[stage_index],
				0.001
			),
			"Stage %d applies the exact monotonic boss-health profile"
				% (stage_index + 1)
		)
	var damage_curve := [1.00, 1.03, 1.06, 1.09, 1.12]
	var damage_pressure := [0.98, 1.30, 1.42, 1.54, 1.66]
	var previous_damage_pressure := [1.15, 1.24, 1.33, 1.42, 1.50]
	var expected_damage := [17.199, 23.49945, 26.41626, 29.45943, 32.62896]
	_expect(
		StageDifficulty.ORDINARY_DAMAGE_PRESSURE == damage_pressure,
		"ordinary damage applies the revised five-stage pressure curve"
	)
	_expect(
		_near(damage_pressure[0] / previous_damage_pressure[0], 0.85, 0.01),
		"Stage 1 ordinary damage pressure is approximately 15 percent lower"
	)
	for stage_index in range(1, damage_pressure.size()):
		_expect(
			damage_pressure[stage_index] > previous_damage_pressure[stage_index],
			"Stage %d ordinary damage pressure is higher than the previous curve"
				% (stage_index + 1)
		)
	for stage_index in damage_curve.size():
		stage.current_stage_index = stage_index
		_expect(
			_near(
				float(stage.call("_scaled_incoming_damage", 10.0, true)),
				expected_damage[stage_index],
				0.001
			),
			"Stage %d applies the exact ordinary outgoing-damage curve"
				% (stage_index + 1)
		)
	stage.current_stage_index = 0
	var hard_damage := float(stage.call("_scaled_incoming_damage", 10.0, true))
	var hard_final_damage := float(stage.call("_scaled_incoming_damage", 10.0, true, true))
	var environmental_damage := float(stage.call("_scaled_incoming_damage", 10.0, false))
	_expect(_near(hard_final_damage, 10.0, 0.001), "final-effective boss damage bypass remains unchanged")
	_expect(_near(environmental_damage, 10.0, 0.001), "friendly and environmental damage bypass remains unchanged")
	stage.selected_run_difficulty = &"easy"
	var compatibility_enemy = stage.call("_make_enemy", {"id":"compatibility_probe", "role":&"chaser", "pos":Vector2.ZERO})
	var compatibility_boss = stage.call("_make_enemy", {"id":"compatibility_boss_probe", "role":&"stage_boss", "pos":Vector2.ZERO})
	_expect(_near(compatibility_enemy.health, hard_enemy.health, 0.001), "retired identifiers cannot alter ordinary health")
	_expect(_near(compatibility_enemy.speed, hard_enemy.speed, 0.001), "retired identifiers cannot alter movement speed")
	_expect(_near(compatibility_boss.health, hard_boss.health, 0.001), "retired identifiers cannot alter boss health")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true)), hard_damage, 0.001), "retired identifiers cannot alter ordinary damage")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true, true)), hard_final_damage, 0.001), "retired identifiers cannot alter authored boss damage")
	var tuned_mobile_bases := {
		&"scrap_drone":190.0,
		&"needle_drone":176.0,
		&"spark_minelet":100.0,
		&"chaser":190.0,
		&"shooter":166.0,
		&"controller":150.0,
		&"shield_escort":170.0,
		&"artillery_spotter":140.0,
		&"rammer":190.0,
		&"bulkhead_guard":164.0,
		&"splitter_barge":157.0,
		&"repair_tender":159.0,
		&"drone_carrier":136.0,
	}
	for archetype in tuned_mobile_bases:
		var base_speed := float(
			EnemyArchetypes.definition(StringName(archetype))["speed"]
		)
		var stage_five_speed := (
			base_speed
			* EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
			* float(StageDifficulty.SPEED[4])
		)
		_expect(
			_near(base_speed, float(tuned_mobile_bases[archetype]), 0.001)
				and stage_five_speed < 280.0,
			"%s keeps its tuned base and stays below player speed at Stage 5"
			% String(archetype)
		)
	stage.call("_reset_run", false, true, true)
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.HARD, "encounters ignore retired compatibility identifiers")
	_expect(stage.stage_flow.quota == StageCatalog.quota(&"stage_1"), "retired identifiers cannot alter stage quota")
	stage.call("_start_deployed_run", &"pulse_cannon")
	_expect(stage.selected_run_difficulty == RunDifficulty.HARD, "new runs restore the fixed Hard telemetry field")
	stage.call("_reset_run", false, true, true)
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.HARD, "stage restart preserves fixed Hard")
	_expect(stage.stage_flow.quota == StageCatalog.quota(&"stage_1"), "stage restart preserves the previous Hard quota")
	stage.queue_free()
	await process_frame
	_finish()


func _near(value: float, target: float, tolerance: float) -> bool:
	return absf(value - target) <= tolerance


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUN_DIFFICULTY_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
