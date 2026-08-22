extends SceneTree

const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
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
	_expect(is_equal_approx(EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER, 1.48), "ordinary movement multiplier is locked to 1.48")
	_expect(
		is_equal_approx(EncounterDirector.ordinary_recovery_scale(&"pursuer"), 0.90)
			and is_equal_approx(EncounterDirector.ordinary_recovery_scale(&"emitter"), 0.765),
		"ordinary recovery is 10 percent shorter and emitter recovery is 23.5 percent shorter"
	)
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
	stage_ui.call("show_deployment", &"pulse_cannon")
	stage_ui.call("debug_submit_deployment")
	_expect(stage.selected_run_difficulty == RunDifficulty.HARD, "deployment starts the fixed Hard run")
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.HARD, "encounter runtime starts at fixed Hard")
	_expect(stage.stage_flow.quota == StageCatalog.quota(&"stage_1"), "active stage quota preserves the previous Hard value")
	var hard_enemy = stage.call("_make_enemy", {"id":"hard_probe", "role":&"ordinary_pursuer_t1", "pos":Vector2.ZERO})
	var hard_boss = stage.call("_make_enemy", {"id":"hard_boss_probe", "role":&"boss_actor", "pos":Vector2.ZERO})
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
			BossProfiles.move_speed(0),
			0.001
		),
		"boss movement uses the cycle-owned base speed"
	)
	var health_curve := [1.00, 1.10, 1.20, 1.35, 1.50, 1.65, 1.82, 2.00, 2.00, 2.00, 2.00, 2.00]
	var speed_curve := [1.00, 1.04, 1.08, 1.12, 1.17, 1.21, 1.26, 1.30, 1.30, 1.30, 1.30, 1.30]
	var health_pressure := [1.00, 1.00, 1.00, 1.06, 1.12, 1.19, 1.25, 1.31, 1.38, 1.44, 1.47, 1.50]
	_expect(
		BossProfiles.PROFILES.map(func(profile): return float(profile["move_speed"]))
			== [405.0, 420.0, 435.0, 450.0, 465.0, 480.0, 500.0, 515.0, 525.0, 535.0, 540.0, 555.0],
		"boss movement uses twelve independently authored speeds"
	)
	_expect(StageDifficulty.HEALTH == health_curve, "ordinary base health stays near baseline early and reaches exactly 2.00x")
	_expect(StageDifficulty.SPEED == speed_curve, "ordinary movement stays bounded by the exact 1.30x cycle curve")
	_expect(
		StageDifficulty.ORDINARY_HEALTH_PRESSURE == health_pressure,
		"ordinary late health pressure starts at cycle 4 and reaches 1.50x"
	)
	_expect(
		is_equal_approx(StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER, 1.20),
		"all non-boss hostiles use one final 20 percent durability policy"
	)
	_expect(health_curve[2] <= 1.20 and health_curve[-1] == 2.00, "early ordinary health stays within 20 percent and the late run reaches 200 percent base health")
	for stage_index in health_curve.size():
		stage.current_stage_index = stage_index
		var standard_enemy = stage.call("_make_enemy", {
			"id":"standard_health_%d" % stage_index,
			"role":&"ordinary_pursuer_t1",
			"pos":Vector2.ZERO,
		})
		var priority_enemy = stage.call("_make_enemy", {
			"id":"priority_health_%d" % stage_index,
			"role":&"ordinary_coordinator_t1",
			"pos":Vector2.ZERO,
		})
		var boss_actor = stage.call("_make_enemy", {
			"id":"boss_health_%d" % stage_index,
			"role":&"boss_actor",
			"pos":Vector2.ZERO,
		})
		_expect(
			_near(
				standard_enemy.health,
				38.0 * EncounterDirector.ENEMY_HEALTH_MULTIPLIER
					* health_curve[stage_index]
					* health_pressure[stage_index]
					* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER
					* StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER,
				0.001
			),
			"Stage %d applies class and stage factors to standard health"
				% (stage_index + 1)
		)
		_expect(
			_near(
				priority_enemy.health,
				66.0 * health_curve[stage_index]
					* health_pressure[stage_index]
					* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER
					* StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER,
				0.001
			),
			"Stage %d applies only the stage factor to priority health"
				% (stage_index + 1)
		)
		_expect(
			_near(
				boss_actor.health,
				BossProfiles.health(stage_index),
				0.001
			),
			"Stage %d reads the exact independent boss-health profile"
				% (stage_index + 1)
		)
	var damage_curve := [1.00, 1.03, 1.06, 1.09, 1.12, 1.15, 1.18, 1.21, 1.24, 1.27, 1.30, 1.33]
	var damage_pressure := [0.98, 1.08, 1.18, 1.28, 1.38, 1.48, 1.57, 1.66, 1.72, 1.78, 1.84, 1.90]
	_expect(
		StageDifficulty.ORDINARY_DAMAGE_PRESSURE == damage_pressure,
		"ordinary damage applies the twelve-cycle pressure curve"
	)
	for stage_index in damage_curve.size():
		stage.current_stage_index = stage_index
		var expected_damage: float = (
			10.0 * EncounterDirector.ENEMY_DAMAGE_MULTIPLIER
			* damage_curve[stage_index] * damage_pressure[stage_index]
		)
		_expect(
			_near(
				float(stage.call("_scaled_incoming_damage", 10.0, true)),
				expected_damage,
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
	var compatibility_enemy = stage.call("_make_enemy", {"id":"compatibility_probe", "role":&"ordinary_pursuer_t1", "pos":Vector2.ZERO})
	var compatibility_boss = stage.call("_make_enemy", {"id":"compatibility_boss_probe", "role":&"boss_actor", "pos":Vector2.ZERO})
	_expect(_near(compatibility_enemy.health, hard_enemy.health, 0.001), "retired identifiers cannot alter ordinary health")
	_expect(_near(compatibility_enemy.speed, hard_enemy.speed, 0.001), "retired identifiers cannot alter movement speed")
	_expect(_near(compatibility_boss.health, hard_boss.health, 0.001), "retired identifiers cannot alter boss health")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true)), hard_damage, 0.001), "retired identifiers cannot alter ordinary damage")
	_expect(_near(float(stage.call("_scaled_incoming_damage", 10.0, true, true)), hard_final_damage, 0.001), "retired identifiers cannot alter authored boss damage")
	var tuned_mobile_bases := {
		&"ordinary_pursuer_t1":190.0,
		&"ordinary_pursuer_t2":198.0,
		&"ordinary_pursuer_t3":206.0,
		&"ordinary_charger_t1":185.0,
		&"ordinary_charger_t2":192.0,
		&"ordinary_charger_t3":199.0,
		&"ordinary_emitter_t1":166.0,
		&"ordinary_emitter_t2":171.0,
		&"ordinary_emitter_t3":176.0,
		&"ordinary_defender_t1":158.0,
		&"ordinary_defender_t2":162.0,
		&"ordinary_defender_t3":166.0,
		&"ordinary_coordinator_t1":157.0,
		&"ordinary_coordinator_t2":162.0,
		&"ordinary_coordinator_t3":167.0,
	}
	for archetype in tuned_mobile_bases:
		var base_speed := float(
			EnemyArchetypes.definition(StringName(archetype))["speed"]
		)
		var final_cycle_speed := (
			base_speed
			* EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
			* float(StageDifficulty.SPEED[11])
		)
		_expect(
			_near(base_speed, float(tuned_mobile_bases[archetype]), 0.001)
			and _near(
				final_cycle_speed,
				base_speed * EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER * 1.30,
				0.001
			),
			"%s keeps its tuned base and uses the exact late-run speed ceiling"
			% String(archetype)
		)
	stage.call("_reset_run", false, true, true)
	_expect(stage.encounter_runtime.difficulty == RunDifficulty.HARD, "encounters ignore retired compatibility identifiers")
	_expect(stage.stage_flow.quota == StageCatalog.quota(&"stage_1"), "retired identifiers cannot alter stage quota")
	stage.call("_start_deployed_run", &"pulse_cannon")
	_expect(stage.selected_run_difficulty == RunDifficulty.HARD, "new runs restore the fixed Hard telemetry field")
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
