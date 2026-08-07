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
	_expect(bool(build.apply(&"thermal_burn").get("applied", false)), "one elemental root can be selected")
	_expect(
		not bool(build.apply(&"bio_toxin").get("applied", false))
			and not bool(build.apply(&"cryo_slow").get("applied", false)),
		"the first elemental root excludes the other two"
	)
	_expect(build.active_element_id() == &"thermal_burn", "the build exposes its selected element")
	var profile := StatusProfile.from_build(build)
	_expect(
		profile.burn_enabled and not profile.poison_enabled and not profile.chill_enabled,
		"one immutable profile carries only the selected root"
	)
	_expect(is_equal_approx(profile.burn_dps_per_stack, 2.0) and is_equal_approx(profile.burn_duration, 3.0), "Thermal Burn uses the exact level-one package")
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
	_expect(StatusRuntime.stack_count(enemy, &"burn") == 3, "selected burn stacks to three")
	_expect(StatusRuntime.stack_count(enemy, &"poison") == 0, "unselected poison is absent")
	_expect(StatusRuntime.stack_count(enemy, &"chill") == 0, "unselected chill is absent")
	var dot := StatusRuntime.tick(enemy, 0.25)
	_expect(is_equal_approx(float(dot["burn"]), 1.5), "burn DOT remains an independent thermal amount")
	_expect(
		enemy.statuses.has(&"burn") and enemy.statuses.size() == 1,
		"ordinary primary hits retain one selected condition"
	)
	var chill_build := RunBuild.new(catalog)
	chill_build.apply(&"cryo_slow")
	var chill_profile := StatusProfile.from_build(chill_build)
	var boss := EnemyState.new()
	boss.role = &"stage_boss"
	StatusRuntime.apply(boss, chill_profile)
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
		var thermal_build := RunBuild.new(catalog)
		var toxin_build := RunBuild.new(catalog)
		var cryo_build := RunBuild.new(catalog)
		for _level in level_index + 1:
			thermal_build.apply(&"thermal_burn")
			toxin_build.apply(&"bio_toxin")
			cryo_build.apply(&"cryo_slow")
		var thermal_profile := StatusProfile.from_build(thermal_build)
		var toxin_profile := StatusProfile.from_build(toxin_build)
		var cryo_profile := StatusProfile.from_build(cryo_build)
		_expect(
			is_equal_approx(thermal_profile.burn_dps_per_stack, burn_dps[level_index])
				and is_equal_approx(thermal_profile.burn_duration, burn_duration[level_index]),
			"Thermal Burn level %d has exact DPS and duration" % (level_index + 1)
		)
		_expect(
			is_equal_approx(toxin_profile.poison_dps_per_stack, poison_dps[level_index])
				and is_equal_approx(toxin_profile.poison_duration, poison_duration[level_index]),
			"Bio Toxin level %d has exact DPS and duration" % (level_index + 1)
		)
		_expect(
			is_equal_approx(cryo_profile.chill_magnitude_per_stack, chill_magnitude[level_index])
				and is_equal_approx(cryo_profile.chill_duration, chill_duration[level_index]),
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
