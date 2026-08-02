extends SceneTree

const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(RunDifficulty.IDS == [&"easy", &"normal", &"hard"], "difficulty exposes exactly Easy, Normal, and Hard")
	_expect(RunDifficulty.normalize(&"unknown") == RunDifficulty.HARD, "invalid difficulty restores Hard")
	_expect(is_equal_approx(RunDifficulty.simultaneous_pressure(RunDifficulty.HARD), 1.0), "Hard preserves the current ordinary baseline")
	_expect(_near(RunDifficulty.simultaneous_pressure(RunDifficulty.NORMAL), 0.85, 0.01), "Normal ordinary pressure is approximately fifteen percent lower")
	_expect(_near(RunDifficulty.simultaneous_pressure(RunDifficulty.EASY), 0.72, 0.01), "Easy ordinary pressure applies the reduction a second time")
	_expect(_near(RunDifficulty.simultaneous_pressure(RunDifficulty.NORMAL, true), 0.85, 0.01), "Normal boss pressure is approximately fifteen percent lower")
	_expect(_near(RunDifficulty.simultaneous_pressure(RunDifficulty.EASY, true), 0.72, 0.01), "Easy boss pressure applies the reduction a second time")
	_expect(RunDifficulty.scaled_quota(125, RunDifficulty.HARD) == 125, "Hard preserves the enlarged stage-one quota")
	_expect(RunDifficulty.scaled_quota(125, RunDifficulty.NORMAL) == 113, "Normal scales the enlarged stage-one quota")
	_expect(RunDifficulty.scaled_quota(125, RunDifficulty.EASY) == 101, "Easy scales the enlarged stage-one quota")
	var previous_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for key in [
			"DEPLOY_DIFFICULTY_LABEL",
			"DIFFICULTY_EASY",
			"DIFFICULTY_NORMAL",
			"DIFFICULTY_HARD",
			"DEPLOY_DIFFICULTY_EASY_DETAIL",
			"DEPLOY_DIFFICULTY_NORMAL_DETAIL",
			"DEPLOY_DIFFICULTY_HARD_DETAIL",
			"SETTINGS_DIFFICULTY_LOCKED",
		]:
			_expect(tr(key) != key, "%s translation exists for %s" % [locale, key])
	TranslationServer.set_locale(previous_locale)

	var settings := get_root().get_node("SettingsStore") as SettingsStoreService
	var previous_difficulty := settings.run_difficulty
	settings.set_run_difficulty(RunDifficulty.HARD)
	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	var stage_ui = stage.get("_ui")
	stage_ui.call("show_deployment", &"pulse_cannon", RunDifficulty.HARD)
	stage_ui.call("debug_submit_deployment", RunDifficulty.NORMAL)
	_expect(stage.selected_run_difficulty == RunDifficulty.NORMAL, "deployment snapshots Normal on the active run")
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.NORMAL, "encounter runtime receives the deployed difficulty")
	_expect(stage.stage_flow.quota == RunDifficulty.scaled_quota(StageCatalog.quota(&"stage_1"), RunDifficulty.NORMAL), "active stage quota uses the deployed difficulty")
	stage.selected_run_difficulty = RunDifficulty.HARD
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
	stage.selected_run_difficulty = RunDifficulty.NORMAL
	var normal_enemy = stage.call("_make_enemy", {"id":"normal_probe", "role":&"chaser", "pos":Vector2.ZERO})
	var normal_boss = stage.call("_make_enemy", {"id":"normal_boss_probe", "role":&"stage_boss", "pos":Vector2.ZERO})
	_expect(_near(normal_enemy.health / hard_enemy.health, 0.96, 0.001), "Normal applies ordinary health once")
	_expect(_near(normal_enemy.speed / hard_enemy.speed, 0.98, 0.001), "Normal applies movement speed once")
	_expect(_near(normal_boss.health / hard_boss.health, 0.90, 0.001), "Normal applies boss health once")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true)) / hard_damage, 0.96, 0.001), "Normal applies ordinary damage once")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true, true)) / hard_final_damage, 0.96, 0.001), "Normal applies authored boss damage once")
	settings.set_run_difficulty(RunDifficulty.EASY)
	_expect(stage.selected_run_difficulty == RunDifficulty.NORMAL, "changing the next-run preference cannot mutate the active run")
	stage.call("_start_deployed_run", &"pulse_cannon", RunDifficulty.NORMAL)
	_expect(settings.run_difficulty == RunDifficulty.EASY, "non-player performance setup cannot overwrite the next-run preference")
	stage.call("_reset_run", false, true, true)
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.NORMAL, "stage restart preserves the deployed difficulty")
	stage.queue_free()
	await process_frame
	settings.set_run_difficulty(previous_difficulty)
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
