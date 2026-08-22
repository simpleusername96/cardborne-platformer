extends SceneTree

## Focused live-run coverage for transit-gate and hostile upgrade-device integration.

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
		await _validate_upgrade_device_authority(run)
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


func _validate_upgrade_device_authority(run) -> void:
	var blueprint: Array[Dictionary] = [
		{"id":&"validation_a", "pos":Vector2(900.0, 1080.0)},
		{"id":&"validation_b", "pos":Vector2(2700.0, 1080.0)},
		{"id":&"validation_c", "pos":Vector2(4500.0, 1080.0)},
		{"id":&"validation_d", "pos":Vector2(6300.0, 1080.0)},
		{"id":&"validation_e", "pos":Vector2(1800.0, 3240.0)},
		{"id":&"validation_f", "pos":Vector2(5400.0, 3240.0)},
	]
	run.mystery_device_runtime.configure(blueprint, 99, &"stage_1")
	run.mystery_device_runtime.refresh_publication(Rect2(), Vector2.ZERO)
	_expect(
		_active_devices(run).is_empty(),
		"the tutorial cycle publishes no enemy upgrade device"
	)
	run.mystery_device_runtime.configure(blueprint, 99, &"stage_2")
	run.mystery_device_runtime.refresh_publication(Rect2(), Vector2.ZERO)
	var devices := _active_devices(run)
	_expect(devices.size() == 4, "a non-tutorial cycle publishes four enemy upgrade devices")
	if devices.is_empty():
		return
	var first := Dictionary(devices[0])
	var position := Vector2(first["position"])
	_expect(
		not bool(run.call("_position_clear_of_stage_objects", position, 24.0)),
		"every published enemy upgrade device blocks actor movement"
	)
	var minimap := Dictionary(run.call("_minimap_snapshot", false))
	var marker_count := 0
	for marker_variant in Array(minimap["markers"]):
		if StringName(Dictionary(marker_variant)["kind"]) == &"mystery_device":
			marker_count += 1
	_expect(marker_count == 4, "the live minimap publishes all four device markers")

	run.player_position = Vector2(3600.0, 2160.0)
	run.call("_clear_projectiles")
	run.projectile_store.add_hostile({
		"pos":position - Vector2(120.0, 0.0),
		"velocity":Vector2.RIGHT * 600.0,
		"radius":4.0,
		"damage":10.0,
		"life":2.0,
		"wall_piercing":true,
	})
	run.call("_update_projectiles", 0.25)
	_expect(run.projectile_store.hostile_count() == 1, "hostile projectiles pass through devices")
	var quota_before := int(run.stage_flow.defeats)
	var experience_before := int(run.experience_runtime.experience)
	_expect(
		not bool(run.call(
			"_damage_mystery_device", StringName(first["id"]), 120.0,
			&"area", position, Color.WHITE, Vector2.RIGHT, &"hostile"
		)),
		"hostile attacks cannot damage enemy upgrade devices"
	)
	_expect(
		bool(run.call(
			"_damage_mystery_device", StringName(first["id"]), 99999.0,
			&"projectile", position, Color.WHITE, Vector2.RIGHT, &"player"
		)),
		"player attacks destroy enemy upgrade devices"
	)
	await process_frame
	_expect(
		int(run.stage_flow.defeats) == quota_before
			and int(run.experience_runtime.experience) == experience_before,
		"device destruction grants neither quota nor XP"
	)
	_expect(
		bool(run.mystery_device_runtime.is_position_clear(position, 0.0)),
		"resolved devices stop blocking movement in the same simulation state"
	)
	_expect(
		String(run._ui.debug_notification_contract()["active_message"])
			== tr("NOTIFY_ENEMY_UPGRADE_DEVICE_COUNTS") % [0, 1],
		"player destruction publishes the counted localized device outcome"
	)
	_expect(
		_active_devices(run).size() == 3,
		"a destroyed device disappears while the other three remain"
	)
	run._ui.clear_notifications()

	var participant = run.call("_make_enemy", {
		"id":"map_device_participant",
		"role":&"ordinary_pursuer_t1",
		"pos":Vector2(devices[1]["position"]),
		"active":true,
		"leash_rect":Rect2(0.0, 0.0, 7200.0, 4320.0),
	})
	run.call("_append_enemy", participant)
	var prior_max_health := float(participant.max_health)
	run.call("_handle_mystery_device_event", {
		"kind":&"enemy_upgrade_device_activated",
		"device_id":StringName(devices[1]["id"]),
		"participant_ids":[participant.id],
	})
	await process_frame
	_expect(
		is_equal_approx(float(participant.max_health), prior_max_health + 30.0),
		"a verified activation immediately augments its living participant"
	)
	_expect(
		String(run._ui.debug_notification_contract()["active_message"])
			== tr("NOTIFY_ENEMY_UPGRADE_DEVICE_COUNTS") % [1, 1],
		"enemy activation publishes current-cycle activation and destruction counts"
	)


func _active_devices(run) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	run.mystery_device_runtime.fill_device_snapshot(result)
	return result


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
