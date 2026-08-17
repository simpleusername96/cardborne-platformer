extends SceneTree

## Focused live-run coverage for persistent symmetric neutral facilities.

const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "GameRoot scene loads")
	if packed == null:
		_finish()
		return
	var game_root := packed.instantiate()
	get_root().add_child(game_root)
	await process_frame
	await process_frame
	var run = game_root.get_node_or_null("VehicleRun")
	_expect(run != null, "GameRoot provides VehicleRun")
	if run != null:
		run.set_process(false)
		run.set_physics_process(false)
		run.set("_layout_seed_override", 0xC4A2B0)
		run.set("_has_layout_seed_override", true)
		run.call("_reset_run", false)
		run.mode = run.RunMode.PLAYING
		_validate_transit_gate_visual(run)
		_validate_facility_authority(run)
	game_root.queue_free()
	await process_frame
	_finish()


func _validate_transit_gate_visual(run) -> void:
	var contract := Dictionary(run.call("debug_transit_gate_visual_contract"))
	_expect(
		StringName(contract.get("asset_id", &"")) == &"world/facility_transit_gate"
			and is_equal_approx(float(contract.get("asset_radius", 0.0)), 96.0)
			and not bool(contract.get("legacy_ring", true)),
		"Transit Gate keeps the approved authored visual without the legacy ring"
	)


func _validate_facility_authority(run) -> void:
	var blueprint := [
		{"id":&"validation_a", "pos":Vector2(1200.0, 1200.0)},
		{"id":&"validation_b", "pos":Vector2(2100.0, 1200.0)},
		{"id":&"validation_c", "pos":Vector2(3000.0, 1200.0)},
	]
	run.mystery_device_runtime.configure(blueprint, 99, &"stage_1")
	var devices: Array = run.mystery_device_runtime.snapshot()["devices"]
	_expect(devices.size() == 3, "live run configures three dormant facilities")
	var first := Dictionary(devices[0])
	var position := Vector2(first["position"])
	_expect(not bool(run.call("_position_clear_of_stage_objects", position, 24.0)), "a dormant facility blocks actor movement")
	run.call("_clear_projectiles")
	run.projectile_store.add_hostile({"pos":position - Vector2(120.0, 0.0), "velocity":Vector2.RIGHT * 600.0, "radius":4.0, "damage":10.0, "life":2.0, "wall_piercing":true})
	run.call("_update_projectiles", 0.25)
	_expect(run.projectile_store.hostile_count() == 1, "hostile projectiles continue through facilities")
	var quota_before := int(run.stage_flow.defeats)
	var experience_before := int(run.experience_runtime.experience)
	_expect(bool(run.call("_damage_mystery_device", StringName(first["id"]), 120.0, &"area", position, Color.WHITE, Vector2.RIGHT, &"hostile")), "hostile attacks damage facilities")
	_expect(bool(run.call("_damage_mystery_device", StringName(first["id"]), 300.0, &"projectile", position, Color.WHITE, Vector2.RIGHT, &"player")), "player attacks destroy facilities")
	_expect(int(run.stage_flow.defeats) == quota_before and int(run.experience_runtime.experience) == experience_before, "facility destruction grants neither quota nor XP")
	_expect(bool(run.mystery_device_runtime.is_position_clear(position, 0.0)), "activated facilities stop blocking movement")
	var notification := Dictionary(run._ui.debug_notification_contract())
	var outcome := StringName(first["outcome"])
	var activation_key := String(run.call("_facility_notification_key", &"facility_activated", outcome))
	_expect(
		String(notification["active_message"]) == tr(activation_key),
		"a verified activation event publishes its role-specific auxiliary-AI message"
	)
	run._ui.clear_notifications()
	var facility_events: Array[Dictionary] = []
	run.mystery_device_runtime.advance(9.0, facility_events)
	for event in facility_events:
		run.call("_handle_mystery_device_event", event)
	var outcome_name := tr(String(run.call("_facility_outcome_name_key", outcome)))
	notification = Dictionary(run._ui.debug_notification_contract())
	_expect(
		String(notification["active_message"])
			== tr("NOTIFY_FACILITY_EXPIRY_WARNING") % outcome_name,
		"the verified three-second event publishes an auxiliary-AI expiry warning"
	)
	run._ui.clear_notifications()
	run.mystery_device_runtime.advance(3.0, facility_events)
	for event in facility_events:
		run.call("_handle_mystery_device_event", event)
	notification = Dictionary(run._ui.debug_notification_contract())
	_expect(
		String(notification["active_message"])
			== tr("NOTIFY_FACILITY_SHUTDOWN") % outcome_name,
		"the verified expiry event publishes an auxiliary-AI shutdown message"
	)
	run._ui.clear_notifications()
	run.call("_publish_facility_notification", {
		"kind":&"facility_shutdown", "outcome":&"unknown",
	})
	_expect(
		not bool(run._ui.debug_notification_contract()["active"]),
		"unknown facility events fail closed instead of naming the wrong outcome"
	)

	# A live-run enemy receives the same role-specific modifier returned for a player position.
	run.mystery_device_runtime.configure(blueprint, 99, &"stage_1")
	devices = run.mystery_device_runtime.snapshot()["devices"]
	var modifier_device := Dictionary(devices[0])
	run.mystery_device_runtime.devices[0]["outcome"] = &"gravity"
	run.mystery_device_runtime.devices[0]["state"] = &"active"
	run.mystery_device_runtime.devices[0]["active_remaining"] = run.mystery_device_runtime.ACTIVE_DURATION_SECONDS
	run.player_position = Vector2(modifier_device["position"])
	_expect(
		is_equal_approx(float(run.call("_player_facility_movement_multiplier")), 0.70)
			and is_equal_approx(float(run.call("_player_facility_acceleration_multiplier")), 0.70),
		"gravity applies the same max-speed and acceleration multipliers to the player"
	)
	var enemy = run.call("_make_enemy", {"role":&"chaser", "id":"facility_target", "pos":Vector2(modifier_device["position"]), "active":true})
	run.call("_append_enemy", enemy)
	run.call("_apply_enemy_facility_modifiers", enemy, 0.5)
	var profile := Dictionary(run.mystery_device_runtime.modifiers_at(enemy.pos)[0]["profile"])
	_expect(
		is_equal_approx(enemy.facility_movement_multiplier, float(profile.get("movement_multiplier", profile.get("max_speed_multiplier", 1.0))))
			and is_equal_approx(enemy.facility_acceleration_multiplier, float(profile.get("acceleration_multiplier", 1.0)))
			and is_equal_approx(enemy.facility_cadence_multiplier, float(profile.get("attack_cadence_multiplier", 1.0)))
			and is_equal_approx(enemy.facility_received_damage_multiplier, float(profile.get("received_damage_multiplier", 1.0))),
		"VehicleRun applies the same active facility profile to enemies"
	)
	run.mystery_device_runtime.devices[0]["outcome"] = &"cryo"
	_expect(
		is_equal_approx(float(run.call("_player_facility_attack_cadence_multiplier")), 0.82),
		"cryo slows player primary and active cooldown cadence through the live-run multiplier"
	)
	run.call("_apply_enemy_facility_modifiers", enemy, 0.0)
	_expect(is_equal_approx(enemy.facility_cadence_multiplier, 0.82), "cryo slows enemy attack cadence through the same facility")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_MAP_MECHANICS_INTEGRATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
