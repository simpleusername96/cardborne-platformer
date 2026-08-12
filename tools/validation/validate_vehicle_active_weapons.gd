extends SceneTree

const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const ActiveCatalog = preload("res://scripts/player/vehicle_active_weapon_catalog.gd")
const ActiveRuntime = preload("res://scripts/player/vehicle_active_weapon_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := ActiveCatalog.new()
	for error in catalog.validate_contract():
		failures.append(error)
	_expect(catalog.definitions.size() == 4, "four active weapon definitions load")
	_validate_default_emp(catalog)
	_validate_replacement_values(catalog)
	_validate_shared_enhancements()
	_validate_black_hole_phases()
	_finish()


func _validate_default_emp(catalog: ActiveCatalog) -> void:
	var definition = catalog.get_definition(&"emp")
	var build := RunBuild.new(UpgradeCatalog.new())
	var runtime := ActiveRuntime.new()
	var event := runtime.try_start(
		Vector2(400.0, 300.0), Vector2.RIGHT, Rect2(0.0, 0.0, 1000.0, 800.0), build
	)
	_expect(
		definition != null
			and build.active_weapon_id() == &"emp"
			and bool(event["started"])
			and is_equal_approx(runtime.damage, 62.0)
			and is_equal_approx(runtime.size, 285.0)
			and is_equal_approx(runtime.cooldown_remaining, 13.0),
		"EMP remains the exact default active weapon"
	)
	var release := runtime.advance(0.42, build)
	_expect(
		bool(release["released"]) and not runtime.is_ready(),
		"EMP releases once after its exact startup and keeps cooldown"
	)


func _validate_replacement_values(catalog: ActiveCatalog) -> void:
	var cases := [
		{"card":&"gravity_collapse", "id":&"black_hole", "damage":[60.0, 85.0, 115.0, 150.0], "size":[150.0, 175.0, 200.0, 225.0], "startup":0.35, "cooldown":12.0},
		{"card":&"kinetic_shockwave", "id":&"shockwave", "damage":[45.0, 65.0, 90.0, 120.0], "size":[180.0, 210.0, 240.0, 270.0], "startup":0.20, "cooldown":9.0},
		{"card":&"piercing_lance", "id":&"cross_beam", "damage":[70.0, 95.0, 125.0, 160.0], "size":[14.0, 18.0, 22.0, 26.0], "startup":0.35, "cooldown":12.0},
	]
	for case_variant in cases:
		var case := Dictionary(case_variant)
		var definition = catalog.get_definition(StringName(case["id"]))
		_expect(
			definition != null
				and is_equal_approx(definition.startup_seconds, float(case["startup"]))
				and is_equal_approx(definition.cooldown_seconds, float(case["cooldown"])),
			"%s owns its exact timing" % case["id"]
		)
		for level_index in 4:
			_expect(
				is_equal_approx(definition.damage(level_index + 1), float(case["damage"][level_index]))
					and is_equal_approx(definition.size(level_index + 1), float(case["size"][level_index])),
				"%s level %d owns its exact damage and size" % [case["id"], level_index + 1]
			)


func _validate_shared_enhancements() -> void:
	var catalog := UpgradeCatalog.new()
	var build := RunBuild.new(catalog)
	for _level in 3:
		build.apply(&"active_coolant")
		build.apply(&"active_amplifier")
	_expect(
		is_equal_approx(build.stat(&"active_cooldown_multiplier", 1.0), 0.75)
			and is_equal_approx(build.stat(&"active_damage_multiplier", 1.0), 1.5),
		"active weapon shared enhancements reach their approved final multipliers"
	)
	var runtime := ActiveRuntime.new()
	var event := runtime.try_start(
		Vector2.ZERO, Vector2.RIGHT, Rect2(-500.0, -500.0, 1000.0, 1000.0), build
	)
	_expect(
		bool(event["started"])
			and is_equal_approx(runtime.damage, 93.0)
			and is_equal_approx(runtime.cooldown_remaining, 9.75),
		"shared active upgrades modify the default EMP through the common runtime"
	)


func _validate_black_hole_phases() -> void:
	var build := RunBuild.new(UpgradeCatalog.new())
	build.apply(&"gravity_collapse")
	var runtime := ActiveRuntime.new()
	var bounds := Rect2(0.0, 0.0, 1000.0, 800.0)
	var event := runtime.try_start(Vector2(900.0, 400.0), Vector2.RIGHT, bounds, build)
	_expect(
		bool(event["started"])
			and runtime.equipped_id == &"black_hole"
			and runtime.center == Vector2(850.0, 400.0),
		"black-hole aim distance clamps its full radius inside the map"
	)
	var opened := runtime.advance(0.35, build)
	_expect(
		not bool(opened["released"])
			and is_equal_approx(runtime.active_remaining, 1.2),
		"black hole opens after startup without applying collapse damage"
	)
	var pull := runtime.advance(0.1, build)
	_expect(int(pull["pull_steps"]) == 1, "black hole publishes one bounded 10 Hz pull step")
	var collapse := runtime.advance(1.1, build)
	_expect(
		bool(collapse["collapse"])
			and int(collapse["pull_steps"]) == 11
			and is_zero_approx(runtime.active_remaining),
		"black hole publishes exactly twelve pull steps and one collapse over 1.2 seconds"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ACTIVE_WEAPONS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
