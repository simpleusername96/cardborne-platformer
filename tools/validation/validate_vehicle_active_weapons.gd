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
	_validate_empty_start_and_emp(catalog)
	_validate_replacement_values(catalog)
	_validate_weapon_owned_endpoints()
	_validate_black_hole_phases()
	_finish()


func _validate_empty_start_and_emp(catalog: ActiveCatalog) -> void:
	var definition = catalog.get_definition(&"emp")
	var build := RunBuild.new(UpgradeCatalog.new())
	var runtime := ActiveRuntime.new()
	var event := runtime.try_start(
		Vector2(400.0, 300.0), Vector2.RIGHT, Rect2(0.0, 0.0, 1000.0, 800.0), build
	)
	_expect(
		definition != null
			and build.active_weapon_id().is_empty()
			and not bool(event["started"])
			and not runtime.is_ready(),
		"a fresh run has no active weapon and active input is a no-op"
	)
	build.apply(&"emp")
	event = runtime.try_start(
		Vector2(400.0, 300.0), Vector2.RIGHT, Rect2(0.0, 0.0, 1000.0, 800.0), build
	)
	_expect(
		bool(event["started"])
			and is_equal_approx(runtime.size, 285.0)
			and is_equal_approx(runtime.duration, 1.4)
			and is_equal_approx(runtime.strength, 1.0)
			and is_equal_approx(runtime.cooldown_remaining, 13.0),
		"EMP Level 1 starts only after card acquisition"
	)
	var release := runtime.advance(0.42, build)
	_expect(
		bool(release["released"]) and not runtime.is_ready(),
		"EMP releases once after its exact startup and keeps cooldown"
	)


func _validate_replacement_values(catalog: ActiveCatalog) -> void:
	var cases := [
		{"card":&"gravity_collapse", "id":&"black_hole", "duration":[1.6, 2.0, 2.4, 2.8], "strength":[0.25, 0.30, 0.35, 0.40], "size":[180.0, 220.0, 260.0, 300.0], "startup":0.35, "cooldown":[12.0, 10.8, 9.6, 8.4]},
		{"card":&"kinetic_shockwave", "id":&"shockwave", "duration":[0.35, 0.50, 0.65, 0.80], "strength":[1.0, 1.0, 1.0, 1.0], "size":[200.0, 240.0, 280.0, 320.0], "startup":0.20, "cooldown":[9.0, 8.1, 7.2, 6.3]},
		{"card":&"piercing_lance", "id":&"cross_beam", "duration":[1.5, 2.0, 2.5, 3.0], "strength":[0.25, 0.30, 0.35, 0.40], "size":[28.0, 40.0, 52.0, 64.0], "startup":0.30, "cooldown":[10.5, 9.4, 8.3, 7.2]},
	]
	for case_variant in cases:
		var case := Dictionary(case_variant)
		var definition = catalog.get_definition(StringName(case["id"]))
		_expect(
			definition != null and is_equal_approx(definition.startup_seconds, float(case["startup"])),
			"%s owns its exact timing" % case["id"]
		)
		for level_index in 4:
			_expect(
				is_equal_approx(definition.duration(level_index + 1), float(case["duration"][level_index]))
					and is_equal_approx(definition.strength(level_index + 1), float(case["strength"][level_index]))
					and is_equal_approx(definition.size(level_index + 1), float(case["size"][level_index]))
					and is_equal_approx(definition.cooldown(level_index + 1), float(case["cooldown"][level_index])),
				"%s level %d owns its exact CC duration, strength, size, and cooldown" % [case["id"], level_index + 1]
			)


func _validate_weapon_owned_endpoints() -> void:
	var catalog := UpgradeCatalog.new()
	var build := RunBuild.new(catalog)
	for _level in 4:
		build.apply(&"emp")
	var runtime := ActiveRuntime.new()
	var event := runtime.try_start(
		Vector2.ZERO, Vector2.RIGHT, Rect2(-500.0, -500.0, 1000.0, 1000.0), build
	)
	_expect(
		bool(event["started"])
			and is_equal_approx(runtime.size, 405.0)
			and is_equal_approx(runtime.duration, 2.6)
			and is_equal_approx(runtime.cooldown_remaining, 9.1),
		"EMP Level 4 owns the fully upgraded control endpoint"
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
			and runtime.center == Vector2(820.0, 400.0),
		"black-hole aim distance clamps its full radius inside the map"
	)
	var opened := runtime.advance(0.35, build)
	_expect(
		not bool(opened["released"])
			and is_equal_approx(runtime.active_remaining, 1.6),
		"black hole opens after startup without publishing damage"
	)
	var pull := runtime.advance(0.1, build)
	_expect(int(pull["pull_steps"]) == 1, "black hole publishes one bounded 10 Hz pull step")
	var collapse := runtime.advance(1.5, build)
	_expect(
		bool(collapse["collapse"])
			and int(collapse["pull_steps"]) == 15
			and is_zero_approx(runtime.active_remaining),
		"black hole publishes exactly sixteen pull steps and one collapse over 1.6 seconds"
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
