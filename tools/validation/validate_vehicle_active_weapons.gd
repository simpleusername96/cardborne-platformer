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
			and is_equal_approx(runtime.damage, 62.0)
			and is_equal_approx(runtime.size, 285.0)
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
		{"card":&"gravity_collapse", "id":&"black_hole", "damage":[60.0, 97.75, 149.5, 225.0], "size":[150.0, 175.0, 200.0, 225.0], "startup":0.35, "cooldown":[12.0, 10.8, 9.84, 9.0]},
		{"card":&"kinetic_shockwave", "id":&"shockwave", "damage":[45.0, 74.75, 117.0, 180.0], "size":[180.0, 210.0, 240.0, 270.0], "startup":0.20, "cooldown":[9.0, 8.1, 7.38, 6.75]},
		{"card":&"piercing_lance", "id":&"cross_beam", "damage":[80.0, 126.5, 188.5, 277.5], "size":[24.0, 32.0, 40.0, 48.0], "startup":0.30, "cooldown":[10.5, 9.45, 8.61, 7.875]},
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
				is_equal_approx(definition.damage(level_index + 1), float(case["damage"][level_index]))
					and is_equal_approx(definition.size(level_index + 1), float(case["size"][level_index]))
					and is_equal_approx(definition.cooldown(level_index + 1), float(case["cooldown"][level_index])),
				"%s level %d owns its exact damage and size" % [case["id"], level_index + 1]
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
			and is_equal_approx(runtime.damage, 93.0)
			and is_equal_approx(runtime.cooldown_remaining, 9.75),
		"EMP Level 4 owns the former fully upgraded endpoint"
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
