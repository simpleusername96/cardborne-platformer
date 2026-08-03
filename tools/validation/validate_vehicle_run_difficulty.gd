extends SceneTree

const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")

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
			205.0 * EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER,
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
	var hard_damage := float(stage.call("_scaled_incoming_damage", 10.0, true))
	var hard_final_damage := float(stage.call("_scaled_incoming_damage", 10.0, true, true))
	stage.selected_run_difficulty = &"easy"
	var compatibility_enemy = stage.call("_make_enemy", {"id":"compatibility_probe", "role":&"chaser", "pos":Vector2.ZERO})
	var compatibility_boss = stage.call("_make_enemy", {"id":"compatibility_boss_probe", "role":&"stage_boss", "pos":Vector2.ZERO})
	_expect(_near(compatibility_enemy.health, hard_enemy.health, 0.001), "retired identifiers cannot alter ordinary health")
	_expect(_near(compatibility_enemy.speed, hard_enemy.speed, 0.001), "retired identifiers cannot alter movement speed")
	_expect(_near(compatibility_boss.health, hard_boss.health, 0.001), "retired identifiers cannot alter boss health")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true)), hard_damage, 0.001), "retired identifiers cannot alter ordinary damage")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true, true)), hard_final_damage, 0.001), "retired identifiers cannot alter authored boss damage")
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
