extends SceneTree

const Runtime = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_expect(
		Runtime.OUTCOME_IDS == [&"repair", &"barrier", &"gravity", &"cryo", &"weakpoint"],
		"neutral facilities expose the five approved persistent roles"
	)
	_expect(
		is_equal_approx(float(Runtime.OUTCOME_PROFILE[&"repair"]["radius"]), 420.0)
			and is_equal_approx(float(Runtime.OUTCOME_PROFILE[&"barrier"]["shield_cap_max_hull_ratio"]), 1.0)
			and is_equal_approx(float(Runtime.OUTCOME_PROFILE[&"gravity"]["max_speed_multiplier"]), 0.55)
			and is_equal_approx(float(Runtime.OUTCOME_PROFILE[&"cryo"]["attack_cadence_multiplier"]), 0.70)
			and is_equal_approx(float(Runtime.OUTCOME_PROFILE[&"weakpoint"]["received_damage_multiplier"]), 1.25),
		"facility profiles preserve the approved radii and symmetric modifiers"
	)
	var blueprint := [
		{"id":&"a", "pos":Vector2.ZERO},
		{"id":&"b", "pos":Vector2(900.0, 0.0)},
		{"id":&"c", "pos":Vector2(1800.0, 0.0)},
	]
	var seen := {}
	for cycle_index in 8:
		var runtime := Runtime.new()
		runtime.configure(blueprint, 7100, StringName("stage_%d" % (cycle_index + 1)))
		var devices: Array = runtime.snapshot()["devices"]
		_expect(devices.size() == 3, "cycle %d configures three facilities" % (cycle_index + 1))
		var cycle_roles := {}
		for device in devices:
			cycle_roles[StringName(device["outcome"])] = true
			seen[StringName(device["outcome"])] = true
		_expect(cycle_roles.size() == 3, "cycle %d facilities have distinct roles" % (cycle_index + 1))
	_expect(seen.size() == 5, "the deterministic eight-cycle fixture covers every facility role")

	var runtime := Runtime.new()
	runtime.configure(blueprint, 77, &"stage_1")
	var first := Dictionary(runtime.snapshot()["devices"][0])
	var device_id := StringName(first["id"])
	var inside := runtime.modifiers_at(Vector2(first["position"]))
	_expect(inside.size() == 1 and StringName(inside[0]["applies_to"]) == &"all_actors", "an intact facility affects either faction inside its radius")
	_expect(runtime.modifiers_at(Vector2(first["position"]) + Vector2(0.0, 600.0)).is_empty(), "facility effects stop outside their radius")
	var hit := {}
	_expect(not runtime.first_intact_segment_hit(Vector2(-100.0, 0.0), Vector2(100.0, 0.0), 0.0, hit), "facilities never block projectiles")
	_expect(runtime.first_damageable_segment_hit(Vector2(-100.0, 0.0), Vector2(100.0, 0.0), 0.0, hit), "passing projectiles still acquire a facility damage target")
	_expect(bool(runtime.receive_damage(device_id, 120.0, &"hostile", &"area")["accepted"]), "hostile area damage affects facilities")
	var broken := runtime.receive_damage(device_id, Runtime.DEVICE_HEALTH, &"player", &"projectile")
	_expect(bool(broken["broken"]) and not bool(Dictionary(broken["break_event"])["grants_experience"]), "player damage destroys a facility without rewards")
	_expect(runtime.modifiers_at(Vector2(first["position"])).is_empty(), "destroyed facilities stop their effects immediately")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_MYSTERY_DEVICE_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
