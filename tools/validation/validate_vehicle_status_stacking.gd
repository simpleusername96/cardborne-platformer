extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StatusProfile = preload("res://scripts/combat/vehicle_status_profile.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	for root_id in [&"thermal_burn", &"bio_toxin", &"cryo_slow"]:
		_expect(bool(build.apply(root_id).get("applied", false)), "%s can coexist with other elemental roots" % root_id)
	_expect(build.has(&"thermal_burn") and build.has(&"bio_toxin") and build.has(&"cryo_slow"), "one run owns all three elemental roots")
	var profile := StatusProfile.from_build(build)
	_expect(
		profile.burn_enabled and profile.poison_enabled and profile.chill_enabled,
		"one immutable profile carries all owned roots"
	)
	_expect(is_equal_approx(profile.burn_dps_per_stack, 2.0) and is_equal_approx(profile.burn_duration, 3.0), "Thermal Burn uses the exact level-one package")
	_expect(is_equal_approx(profile.poison_dps_per_stack, 2.0) and profile.poison_max_stacks == 3, "Bio Toxin uses the exact level-one package")
	_expect(is_equal_approx(profile.chill_magnitude_per_stack, 0.06) and is_equal_approx(profile.chill_duration, 2.0), "Cryo Slow uses the exact level-one package")
	_validate_level_progression(catalog)

	var projectile := ProjectileState.new()
	projectile.configure({"status_profile":profile}, &"player", 1)
	var later_build := RunBuild.new(catalog)
	later_build.apply(&"thermal_burn")
	var later_profile := StatusProfile.from_build(later_build)
	_expect(projectile.status_profile == profile and projectile.status_profile != later_profile, "an in-flight projectile retains its fired build profile")

	var enemy := EnemyState.new()
	enemy.role = &"chaser"
	for _hit in 3:
		StatusRuntime.apply(enemy, profile)
	_expect(StatusRuntime.stack_count(enemy, &"burn") == 3, "burn stacks independently to three")
	_expect(StatusRuntime.stack_count(enemy, &"poison") == 3, "poison stacks independently without erasing burn")
	_expect(StatusRuntime.stack_count(enemy, &"chill") == 3, "chill stacks independently without erasing other elements")
	_expect(is_equal_approx(StatusRuntime.speed_multiplier(enemy), 0.82), "three chill stacks produce the exact bounded slow")
	var dot := StatusRuntime.tick(enemy, 0.25)
	_expect(is_equal_approx(float(dot["burn"]), 1.5), "burn DOT remains an independent thermal amount")
	_expect(is_equal_approx(float(dot["poison"]), 1.5), "poison DOT remains an independent toxin amount")
	_expect(
		enemy.statuses.has(&"burn")
		and enemy.statuses.has(&"chill")
		and enemy.statuses.has(&"poison"),
		"ordinary primary hits and status ticks never consume another element"
	)
	var boss := EnemyState.new()
	boss.role = &"stage_boss"
	StatusRuntime.apply(boss, profile)
	var boss_chill: Dictionary = boss.statuses[&"chill"]
	_expect(is_equal_approx(float(boss_chill["magnitude_per_stack"]), 0.03), "boss chill magnitude is halved")
	_expect(is_equal_approx(float(boss_chill["time"]), 1.0), "boss chill duration is halved")
	_finish()


func _validate_level_progression(catalog: Catalog) -> void:
	var burn_dps := [2.0, 3.0, 4.0]
	var burn_duration := [3.0, 4.0, 5.0]
	var poison_dps := [2.0, 3.0, 4.0]
	var poison_duration := [5.0, 6.0, 7.0]
	var chill_magnitude := [0.06, 0.08, 0.10]
	var chill_duration := [2.0, 2.5, 3.0]
	for level_index in 3:
		var build := RunBuild.new(catalog)
		for _level in level_index + 1:
			build.apply(&"thermal_burn")
			build.apply(&"bio_toxin")
			build.apply(&"cryo_slow")
		var profile := StatusProfile.from_build(build)
		_expect(
			is_equal_approx(profile.burn_dps_per_stack, burn_dps[level_index])
				and is_equal_approx(profile.burn_duration, burn_duration[level_index]),
			"Thermal Burn level %d has exact DPS and duration" % (level_index + 1)
		)
		_expect(
			is_equal_approx(profile.poison_dps_per_stack, poison_dps[level_index])
				and is_equal_approx(profile.poison_duration, poison_duration[level_index]),
			"Bio Toxin level %d has exact DPS and duration" % (level_index + 1)
		)
		_expect(
			is_equal_approx(profile.chill_magnitude_per_stack, chill_magnitude[level_index])
				and is_equal_approx(profile.chill_duration, chill_duration[level_index]),
			"Cryo Slow level %d has exact slow and duration" % (level_index + 1)
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STATUS_STACKING_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
