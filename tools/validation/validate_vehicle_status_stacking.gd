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
	for root_id in [&"incendiary_core", &"toxin_core", &"cryo_core"]:
		_expect(bool(build.apply(root_id).get("applied", false)), "%s can coexist with other elemental roots" % root_id)
	_expect(build.has(&"incendiary_core") and build.has(&"toxin_core") and build.has(&"cryo_core"), "one run owns all three elemental roots")
	for upgrade_id in [
		&"thermal_compound", &"thermal_compound", &"flashover",
		&"concentrated_toxin", &"concentrated_toxin", &"contagion",
		&"deep_freeze", &"deep_freeze", &"shatter",
	]:
		_expect(bool(build.apply(upgrade_id).get("applied", false)), "%s follows its prerequisite chain" % upgrade_id)
	var profile := StatusProfile.from_build(build)
	_expect(
		profile.burn_enabled and profile.poison_enabled and profile.chill_enabled,
		"one immutable profile carries all owned roots"
	)
	_expect(is_equal_approx(profile.burn_dps_per_stack, 3.5) and is_equal_approx(profile.burn_duration, 4.0), "Thermal Compound uses the exact burn progression")
	_expect(is_equal_approx(profile.poison_dps_per_stack, 4.0) and profile.poison_max_stacks == 5, "Concentrated Toxin uses the exact poison progression")
	_expect(is_equal_approx(profile.chill_magnitude_per_stack, 0.10) and is_equal_approx(profile.chill_duration, 3.0), "Deep Freeze uses the exact chill progression")

	var projectile := ProjectileState.new()
	projectile.configure({"status_profile":profile}, &"player", 1)
	var later_build := RunBuild.new(catalog)
	later_build.apply(&"incendiary_core")
	var later_profile := StatusProfile.from_build(later_build)
	_expect(projectile.status_profile == profile and projectile.status_profile != later_profile, "an in-flight projectile retains its fired build profile")

	var enemy := EnemyState.new()
	enemy.role = &"chaser"
	for _hit in 3:
		StatusRuntime.apply(enemy, profile)
	_expect(StatusRuntime.stack_count(enemy, &"burn") == 3, "burn stacks independently to three")
	_expect(StatusRuntime.stack_count(enemy, &"poison") == 3, "poison stacks independently without erasing burn")
	_expect(StatusRuntime.stack_count(enemy, &"chill") == 3, "chill stacks independently without erasing other elements")
	_expect(is_equal_approx(StatusRuntime.speed_multiplier(enemy), 0.70), "three upgraded chill stacks produce the bounded slow")
	_expect(is_equal_approx(StatusRuntime.tick(enemy, 0.25), 5.625), "burn and poison DOT add together on the shared tick")

	var opening := StatusRuntime.resolve_opening(enemy, profile, 20.0)
	_expect(is_equal_approx(float(opening["splash_damage"]), 49.21875), "Flashover consumes remaining burn stacks using exact time")
	_expect(is_equal_approx(float(opening["bonus_damage"]), 57.21875), "one opening shot resolves Flashover and Shatter together")
	_expect(bool(opening["flashover"]) and bool(opening["shatter"]), "coexisting capstones both trigger")
	_expect(
		not enemy.statuses.has(&"burn")
		and not enemy.statuses.has(&"chill")
		and enemy.statuses.has(&"poison"),
		"opening capstones consume only their own statuses"
	)

	var boss := EnemyState.new()
	boss.role = &"stage_boss"
	StatusRuntime.apply(boss, profile)
	var boss_chill: Dictionary = boss.statuses[&"chill"]
	_expect(is_equal_approx(float(boss_chill["magnitude_per_stack"]), 0.05), "boss chill magnitude is halved")
	_expect(is_equal_approx(float(boss_chill["time"]), 1.5), "boss chill duration is halved")

	var spread_target := EnemyState.new()
	spread_target.role = &"chaser"
	StatusRuntime.spread_poison(enemy, spread_target)
	_expect(StatusRuntime.stack_count(spread_target, &"poison") == 1, "Contagion transfers exactly one poison stack per target")
	_finish()


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
