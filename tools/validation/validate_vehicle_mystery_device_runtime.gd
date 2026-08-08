extends SceneTree

const Runtime = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	_validate_configure_and_hidden_outcomes()
	_validate_damage_authority_and_break_event()
	_validate_effect_retirement_and_stage_reset()
	_validate_hot_path_queries_and_reused_output()
	if failures.is_empty():
		print("VEHICLE_MYSTERY_DEVICE_RUNTIME_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_configure_and_hidden_outcomes() -> void:
	var first := Runtime.new()
	var second := Runtime.new()
	var blueprint := _blueprint()
	first.configure(blueprint, 771, &"stage_2")
	second.configure(blueprint, 771, &"stage_2")
	var snapshot := first.snapshot()
	_expect(Array(snapshot["devices"]).size() == 3, "configure keeps exactly three devices")
	for device in Array(snapshot["devices"]):
		_expect(is_equal_approx(float(device["health"]), 90.0), "intact device has 90 health")
		_expect(is_equal_approx(float(device["max_health"]), 90.0), "device snapshot publishes max health")
		_expect(is_zero_approx(float(device["health_visible_timer"])), "undamaged device hides its health bar")
		_expect(is_equal_approx(float(device["radius"]), 84.0), "intact device has radius 84")
		_expect(StringName(device["state"]) == &"intact" and bool(device["visible"]), "intact device is visible")
		_expect(not Dictionary(device).has("revealed_outcome"), "intact snapshot hides the outcome")
	_expect(
		var_to_str(first.snapshot()) == var_to_str(second.snapshot()),
		"same seed and stage assign outcomes deterministically"
	)
	var explicit := Runtime.new()
	explicit.configure([
		{"id":&"a", "position":Vector2.ZERO, "outcome":&"decoy_signal"},
		{"id":&"b", "position":Vector2(1.0, 0.0), "outcome":&"decoy_signal"},
		{"id":&"c", "position":Vector2(2.0, 0.0)},
	], 1, &"stage_1")
	var outcome_ids: Dictionary = {}
	for device in explicit.devices:
		outcome_ids[StringName(device["outcome"])] = true
	_expect(outcome_ids.size() == 3, "stage outcomes stay unique when blueprint requests a duplicate")


func _validate_damage_authority_and_break_event() -> void:
	var runtime := Runtime.new()
	runtime.configure(_blueprint(), 771, &"stage_2")
	_expect(not Runtime.accepts_damage(&"hostile", &"direct"), "hostile attacks are ignored")
	_expect(not Runtime.accepts_damage(&"player", &"contact"), "player contact is ignored")
	_expect(Runtime.accepts_damage(&"player", &"area"), "player area attacks are accepted")
	var ignored := runtime.receive_damage(&"a", 90.0, &"hostile", &"direct")
	_expect(not bool(ignored["accepted"]), "hostile damage receipt is rejected")
	var partial := runtime.receive_damage(&"a", 45.0, &"player", &"direct")
	_expect(bool(partial["accepted"]) and not bool(partial["broken"]), "authorized direct damage reduces health")
	var damaged: Dictionary = Dictionary(Array(runtime.snapshot()["devices"])[0])
	_expect(
		is_equal_approx(float(damaged["health_visible_timer"]), 1.5),
		"authorized damage opens the device health bar for one and a half seconds"
	)
	runtime.advance(0.5)
	damaged = Dictionary(Array(runtime.snapshot()["devices"])[0])
	_expect(
		is_equal_approx(float(damaged["health_visible_timer"]), 1.0),
		"device health-bar visibility counts down with the reused runtime advance"
	)
	var broken := runtime.receive_damage(&"a", 45.0, &"player", &"area")
	var event := Dictionary(broken["break_event"])
	_expect(bool(broken["broken"]) and not event.is_empty(), "lethal authorized damage returns one break event")
	_expect(
		StringName(event["effect_id"]) == &"gravity_pull"
		and Vector2(event["position"]) == Vector2(100.0, 200.0)
		and is_equal_approx(float(event["radius"]), 480.0)
		and is_equal_approx(float(event["duration"]), 1.2),
		"break event carries exact effect id, position, radius, and duration"
	)
	_expect(
		not bool(event["device_counts_for_quota"])
		and not bool(event["grants_experience"])
		and StringName(event["drop"]) == &"",
		"break event explicitly grants no quota, XP, or drop"
	)
	var revealed: Dictionary = Dictionary(Array(runtime.snapshot()["devices"])[0])
	_expect(StringName(revealed["revealed_outcome"]) == &"gravity_pull", "outcome appears only after break")
	_expect(StringName(revealed["state"]) == &"resolved" and bool(revealed["visible"]), "broken device stays resolved while effect is active")
	_expect(not runtime.is_intact(&"a") and runtime.intact_devices_snapshot().size() == 2, "broken device is no longer intact or damageable")


func _validate_effect_retirement_and_stage_reset() -> void:
	var runtime := Runtime.new()
	runtime.configure(_blueprint(), 3, &"stage_1")
	runtime.receive_damage(&"a", 90.0, &"player", &"direct")
	_expect(runtime.advance(1.19).is_empty(), "effect remains active before its duration ends")
	var retired := runtime.advance(0.02)
	_expect(retired.size() == 1 and StringName(retired[0]["effect_id"]) == &"gravity_pull", "effect retires at its duration")
	var retired_device: Dictionary = Dictionary(Array(runtime.snapshot()["devices"])[0])
	_expect(StringName(retired_device["state"]) == &"retired" and not bool(retired_device["visible"]), "resolved device retires and becomes invisible with its effect")
	runtime.configure(_blueprint(), 3, &"stage_1")
	var purge := runtime.receive_damage(&"b", 90.0, &"player", &"area")
	var purge_event: Dictionary = Dictionary(purge["break_event"])
	_expect(StringName(purge_event["effect_id"]) == &"projectile_purge" and is_zero_approx(float(purge_event["duration"])), "projectile purge is an immediate exact event")
	_expect(Array(runtime.snapshot()["active_effects"]).is_empty(), "immediate projectile purge never enters active effects")
	var purge_device: Dictionary = Dictionary(Array(runtime.snapshot()["devices"])[1])
	_expect(StringName(purge_device["state"]) == &"retired" and not bool(purge_device["visible"]), "immediate effect retires its device immediately")
	runtime.configure(_blueprint(), 3, &"stage_2")
	_expect(Array(runtime.snapshot()["active_effects"]).is_empty(), "stage configure clears active effects")


func _validate_hot_path_queries_and_reused_output() -> void:
	var runtime := Runtime.new()
	runtime.configure([
		{"id":&"near", "pos":Vector2(200.0, 0.0), "outcome":&"gravity_pull"},
		{"id":&"far", "pos":Vector2(400.0, 0.0), "outcome":&"decoy_signal"},
		{"id":&"side", "pos":Vector2(400.0, 400.0), "outcome":&"cryo_lock"},
	], 9, &"stage_3")
	_expect(not runtime.is_position_clear(Vector2(116.0, 0.0), 0.0), "actor position collision detects intact device")
	_expect(runtime.is_position_clear(Vector2(115.9, 0.0), 0.0), "clear actor position stays outside intact radius")
	var hit_receipt := {"stale":true}
	_expect(runtime.first_intact_segment_hit(Vector2.ZERO, Vector2(600.0, 0.0), 0.0, hit_receipt), "segment hit detects intact device")
	_expect(
		StringName(hit_receipt["device_id"]) == &"near"
		and is_equal_approx(float(hit_receipt["t"]), 116.0 / 600.0)
		and Vector2(hit_receipt["position"]) == Vector2(116.0, 0.0)
		and not hit_receipt.has("outcome"),
		"segment receipt returns nearest intersection without leaking outcome"
	)
	var device_output: Array[Dictionary] = []
	var filled_devices := runtime.fill_device_snapshot(device_output)
	var first_device_record: Dictionary = device_output[0]
	_expect(is_same(filled_devices, runtime.fill_device_snapshot(device_output)) and is_same(first_device_record, device_output[0]), "device snapshot reuses caller-owned array and records")
	runtime.receive_damage(&"near", 90.0, &"player", &"direct")
	_expect(runtime.is_position_clear(Vector2(200.0, 0.0), 0.0), "resolved device no longer blocks actor collision")
	hit_receipt["stale"] = true
	_expect(runtime.first_intact_segment_hit(Vector2.ZERO, Vector2(600.0, 0.0), 0.0, hit_receipt) and StringName(hit_receipt["device_id"]) == &"far", "broken device is ignored by segment hit")
	var effect_output: Array[Dictionary] = []
	var filled_effects := runtime.fill_active_effect_snapshot(effect_output)
	var first_effect_record: Dictionary = effect_output[0]
	_expect(is_same(filled_effects, runtime.fill_active_effect_snapshot(effect_output)) and is_same(first_effect_record, effect_output[0]), "active-effect snapshot reuses caller-owned array and records")
	runtime.advance(1.2)
	_expect(runtime.is_position_clear(Vector2(200.0, 0.0), 0.0), "retired device remains ignored by collision")


func _blueprint() -> Array:
	return [
		{"id":&"a", "pos":Vector2(100.0, 200.0), "outcome":&"gravity_pull"},
		{"id":&"b", "pos":Vector2(300.0, 400.0), "outcome":&"projectile_purge"},
		{"id":&"c", "position":Vector2(500.0, 600.0), "outcome":&"cryo_lock"},
	]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
