extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const ElementProfile = preload("res://scripts/combat/vehicle_element_profile.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	_expect(bool(build.apply(&"thermal_burst").get("applied", false)), "one elemental root can be selected")
	_expect(
		not bool(build.apply(&"bio_toxin").get("applied", false))
			and not bool(build.apply(&"cryo_slow").get("applied", false)),
		"the first elemental root excludes the other two"
	)
	_expect(build.active_element_id() == &"thermal_burst", "the build exposes its selected element")
	var profile := ElementProfile.from_build(build)
	_expect(
		profile.thermal_enabled and not profile.poison_enabled and not profile.chill_enabled,
		"one immutable profile carries only the selected root"
	)
	_expect(
		profile.thermal_burst_radius == 72.0
			and profile.thermal_burst_damage == 4.0
			and not profile.has_persistent_status(),
		"Thermal Burst uses the exact level-one immediate package"
	)
	_expect(
		profile.can_trigger_thermal_burst("player_primary", false)
			and not profile.can_trigger_thermal_burst("seeker", false)
			and not profile.can_trigger_thermal_burst("player_primary", true),
		"only non-reflected primary contacts can trigger Thermal Burst"
	)
	_validate_level_progression(catalog)

	var projectile := ProjectileState.new()
	projectile.configure({"element_profile":profile}, &"player", 1)
	var later_build := RunBuild.new(catalog)
	later_build.apply(&"thermal_burst")
	var later_profile := ElementProfile.from_build(later_build)
	_expect(
		projectile.element_profile == profile
			and projectile.element_profile != later_profile,
		"an in-flight projectile retains its fired build profile"
	)

	var toxin_build := RunBuild.new(catalog)
	toxin_build.apply(&"bio_toxin")
	var toxin_profile := ElementProfile.from_build(toxin_build)
	var enemy := EnemyState.new()
	enemy.role = &"chaser"
	for _hit in 3:
		StatusRuntime.apply(enemy, toxin_profile)
	_expect(StatusRuntime.stack_count(enemy, &"poison") == 3, "selected toxin stacks to three")
	_expect(StatusRuntime.stack_count(enemy, &"chill") == 0, "unselected chill is absent")
	_expect(
		is_equal_approx(enemy.toxin_stack_ratio, 1.0)
			and is_equal_approx(enemy.toxin_application_pulse, 1.0),
		"toxin publishes a bounded full-stack ratio and one application receipt"
	)
	var dot := StatusRuntime.tick(enemy, 0.25)
	_expect(is_equal_approx(float(dot["poison"]), 1.5), "toxin DOT remains independent")
	_expect(
		enemy.statuses.has(&"poison") and enemy.statuses.size() == 1,
		"ordinary primary hits retain one selected persistent condition"
	)
	var chill_build := RunBuild.new(catalog)
	chill_build.apply(&"cryo_slow")
	var chill_profile := ElementProfile.from_build(chill_build)
	var boss := EnemyState.new()
	boss.role = &"stage_boss"
	StatusRuntime.apply(boss, chill_profile)
	var boss_chill: Dictionary = boss.statuses[&"chill"]
	_expect(is_equal_approx(float(boss_chill["magnitude_per_stack"]), 0.03), "boss chill magnitude is halved")
	_expect(is_equal_approx(float(boss_chill["time"]), 1.0), "boss chill duration is halved")
	_expect(
		is_equal_approx(boss.cryo_stack_ratio, 1.0 / 3.0)
			and is_equal_approx(boss.cryo_application_pulse, 1.0),
		"boss Chill keeps gameplay halving separate from its one-stack presentation receipt"
	)
	var pulse_enemy := EnemyState.new()
	StatusRuntime.apply(pulse_enemy, chill_profile)
	StatusRuntime.tick(pulse_enemy, 0.08)
	_expect(
		is_equal_approx(pulse_enemy.cryo_application_pulse, 0.5),
		"the normalized application receipt reaches half strength after 0.08 seconds"
	)
	StatusRuntime.tick(pulse_enemy, 0.08)
	_expect(
		is_zero_approx(pulse_enemy.cryo_application_pulse),
		"the application receipt ends exactly after 0.16 seconds"
	)
	boss.reset_runtime_collections()
	_expect(
		boss.statuses.is_empty()
			and is_zero_approx(boss.cryo_stack_ratio)
			and is_zero_approx(boss.cryo_application_pulse),
		"pooled enemy reset clears every status presentation scalar"
	)
	_finish()


func _validate_level_progression(catalog: Catalog) -> void:
	var thermal_radius := [72.0, 84.0, 96.0]
	var thermal_damage := [4.0, 6.0, 8.0]
	var poison_dps := [2.0, 3.0, 4.0]
	var poison_duration := [5.0, 6.0, 7.0]
	var chill_magnitude := [0.06, 0.08, 0.10]
	var chill_duration := [2.0, 2.5, 3.0]
	for level_index in 3:
		var thermal_build := RunBuild.new(catalog)
		var toxin_build := RunBuild.new(catalog)
		var cryo_build := RunBuild.new(catalog)
		for _level in level_index + 1:
			thermal_build.apply(&"thermal_burst")
			toxin_build.apply(&"bio_toxin")
			cryo_build.apply(&"cryo_slow")
		var thermal_profile := ElementProfile.from_build(thermal_build)
		var toxin_profile := ElementProfile.from_build(toxin_build)
		var cryo_profile := ElementProfile.from_build(cryo_build)
		_expect(
			thermal_profile.thermal_burst_radius == thermal_radius[level_index]
				and thermal_profile.thermal_burst_damage == thermal_damage[level_index],
			"Thermal Burst level %d has exact radius and damage" % (level_index + 1)
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
		return
	for failure in failures:
		push_error(failure)
	quit(1)
