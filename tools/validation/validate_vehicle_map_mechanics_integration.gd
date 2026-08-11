extends SceneTree

## Focused live-run coverage for the map mechanics that only VehicleRun owns.

const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")

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
		run.call("_reset_run", false)
		run.mode = run.RunMode.PLAYING
		_validate_device_collision_and_damage_authority(run)
		_validate_projectile_purge_scope(run)
		_validate_effect_targeting(run)
	game_root.queue_free()
	await process_frame
	_finish()


func _configure_devices(run, outcomes: Array[StringName]) -> Array:
	var blueprint: Array = []
	for index in outcomes.size():
		blueprint.append({
			"id": StringName("validation_device_%d" % index),
			"pos": Vector2(1200.0 + index * 900.0, 1200.0),
			"outcome": outcomes[index],
		})
	run.mystery_device_runtime.configure(blueprint, 99, &"stage_1")
	return Array(run.mystery_device_runtime.snapshot()["devices"])


func _validate_device_collision_and_damage_authority(run) -> void:
	var devices := _configure_devices(run, [&"gravity_pull", &"cryo_lock", &"projectile_purge"])
	_expect(devices.size() == 3, "live run configures three mystery devices")
	var outcomes: Dictionary = {}
	for device in devices:
		outcomes[StringName(device.get("revealed_outcome", &""))] = true
		_expect(StringName(device["state"]) == &"intact" and not device.has("revealed_outcome"), "intact device keeps its outcome hidden")
	_expect(outcomes.size() == 1 and outcomes.has(&""), "all intact outcomes remain hidden in the live snapshot")
	var position := Vector2(devices[0]["position"])
	_expect(not bool(run.call("_position_clear_of_stage_objects", position, 24.0)), "intact device blocks live actor collision")
	var blocked := Vector2(run.call("_move_actor", position - Vector2(160.0, 0.0), Vector2(160.0, 0.0), 24.0, false))
	_expect(blocked != position, "live actor movement cannot enter an intact device")
	run.call("_clear_projectiles")
	run.projectile_store.add_hostile({"pos":position - Vector2(120.0, 0.0), "velocity":Vector2.RIGHT * 600.0, "radius":4.0, "damage":1.0, "life":2.0, "wall_piercing":true})
	run.call("_update_projectiles", 0.25)
	_expect(run.projectile_store.hostile_count() == 1, "hostile projectiles pass through intact mystery devices")
	var quota_before := int(run.stage_flow.defeats)
	var experience_before := int(run.experience_runtime.experience)
	_expect(not bool(run.call("_damage_mystery_device", StringName(devices[0]["id"]), 90.0, &"contact", position, Color.WHITE, Vector2.RIGHT)), "contact damage cannot break a device")
	_expect(bool(run.call("_damage_mystery_device", StringName(devices[0]["id"]), 45.0, &"direct", position, Color.WHITE, Vector2.RIGHT)), "the first player hit is accepted")
	var revealed_devices := Array(run.mystery_device_runtime.snapshot()["devices"])
	_expect(
		StringName(revealed_devices[0]["state"]) == &"intact"
		and StringName(revealed_devices[0]["revealed_outcome"]) == &"gravity_pull",
		"the first player hit reveals the device outcome before break"
	)
	_expect(bool(run.call("_damage_mystery_device", StringName(devices[0]["id"]), 45.0, &"direct", position, Color.WHITE, Vector2.RIGHT)), "the second player hit breaks the device")
	_expect(int(run.stage_flow.defeats) == quota_before and int(run.experience_runtime.experience) == experience_before, "device break changes neither quota nor XP")
	_expect(bool(run.mystery_device_runtime.is_position_clear(position, 0.0)), "resolved device no longer blocks actor collision")


func _validate_projectile_purge_scope(run) -> void:
	var devices := _configure_devices(run, [&"projectile_purge", &"gravity_pull", &"cryo_lock"])
	var center := Vector2(devices[0]["position"])
	run.call("_clear_projectiles")
	run.projectile_store.add_player({"pos":center, "velocity":Vector2.RIGHT, "radius":4.0, "damage":1.0, "life":2.0})
	run.projectile_store.add_hostile({"pos":center + Vector2(100.0, 0.0), "velocity":Vector2.RIGHT, "radius":4.0, "damage":1.0, "life":2.0})
	run.projectile_store.add_hostile({"pos":center + Vector2(500.0, 0.0), "velocity":Vector2.RIGHT, "radius":4.0, "damage":1.0, "life":2.0})
	run.call("_damage_mystery_device", StringName(devices[0]["id"]), 90.0, &"area", center, Color.WHITE, Vector2.RIGHT)
	_expect(run.projectile_store.player_count() == 1 and run.projectile_store.hostile_count() == 1, "projectile purge clears only hostile projectiles inside its radius")
	_expect(
		StringName(run._mystery_device_result_receipt["effect_id"])
			== &"projectile_purge"
		and int(run._mystery_device_result_receipt["affected_count"]) == 1,
		"Mystery result receipt reports the one cleared hostile projectile"
	)
	_expect(
		run.effect_store.count_kind(EffectStore.MYSTERY_PURGE_PULSE_KIND) == 1,
		"projectile purge publishes one short System pulse after the clear"
	)


func _append_enemy(run, archetype: StringName, id: String, position: Vector2):
	var enemy = run.call("_make_enemy", {"role":archetype, "id":id, "pos":position, "active":true})
	if enemy != null:
		run.call("_append_enemy", enemy)
	return enemy


func _validate_effect_targeting(run) -> void:
	run.call("_clear_enemies")
	var devices := _configure_devices(run, [&"cryo_lock", &"gravity_pull", &"decoy_signal"])
	var center := Vector2(devices[0]["position"])
	var movable = _append_enemy(run, &"chaser", "validation_cryo_movable", center + Vector2(120.0, 0.0))
	var startup = _append_enemy(run, &"chaser", "validation_cryo_startup", center + Vector2(160.0, 0.0))
	startup.phase = &"startup"
	startup.velocity = Vector2(10.0, 0.0)
	run.call("_damage_mystery_device", StringName(devices[0]["id"]), 90.0, &"direct", center, Color.WHITE, Vector2.RIGHT)
	_expect(
		StringName(run._mystery_device_result_receipt["effect_id"]) == &"cryo_lock"
		and int(run._mystery_device_result_receipt["affected_count"]) == 2,
		"Mystery result receipt reports both Cryo-affected ordinary enemies"
	)
	run.call("_prepare_mystery_device_effects", 0.1)
	_expect(
		movable.stun > 0.0
		and movable.velocity == Vector2.ZERO
		and movable.mystery_cryo_remaining > 0.0,
		"cryo blocks fresh movement and publishes the shared blue body-overlay state"
	)
	_expect(startup.stun == 0.0 and startup.velocity == Vector2(10.0, 0.0), "cryo preserves warned startup attacks")

	run.call("_clear_enemies")
	devices = _configure_devices(run, [&"gravity_pull", &"decoy_signal", &"cryo_lock"])
	center = Vector2(devices[0]["position"])
	var ordinary = _append_enemy(run, &"chaser", "validation_gravity_ordinary", center + Vector2(300.0, 0.0))
	var boss = _append_enemy(run, &"stage_boss", "validation_gravity_boss", center + Vector2(300.0, 80.0))
	var structure = _append_enemy(run, &"generator", "validation_gravity_structure", center + Vector2(300.0, -80.0))
	var boss_before: Vector2 = boss.pos
	var structure_before: Vector2 = structure.pos
	run.call("_damage_mystery_device", StringName(devices[0]["id"]), 90.0, &"direct", center, Color.WHITE, Vector2.RIGHT)
	run.call("_prepare_mystery_device_effects", 0.1)
	run.call("_apply_mystery_device_forced_motion", 0.1)
	_expect(ordinary.pos.distance_to(center) < 300.0, "gravity pull moves ordinary enemies toward its anchor")
	_expect(boss.pos == boss_before and structure.pos == structure_before, "gravity pull ignores bosses and structures")

	run.call("_clear_enemies")
	devices = _configure_devices(run, [&"decoy_signal", &"gravity_pull", &"cryo_lock"])
	center = Vector2(devices[0]["position"])
	ordinary = _append_enemy(run, &"chaser", "validation_decoy_ordinary", center + Vector2(300.0, 0.0))
	boss = _append_enemy(run, &"stage_boss", "validation_decoy_boss", center + Vector2(300.0, 80.0))
	structure = _append_enemy(run, &"generator", "validation_decoy_structure", center + Vector2(300.0, -80.0))
	boss_before = boss.pos
	structure_before = structure.pos
	run.call("_damage_mystery_device", StringName(devices[0]["id"]), 90.0, &"direct", center, Color.WHITE, Vector2.RIGHT)
	run.call("_prepare_mystery_device_effects", 0.1)
	run.call("_refresh_enemy_presentation_facing", ordinary)
	_expect(
		ordinary.presentation_facing.normalized().is_equal_approx(
			(center - ordinary.pos).normalized()
		),
		"decoy signal publishes its redirected target through enemy facing"
	)
	var ordinary_before: Vector2 = ordinary.pos
	run.call("_move_enemy_role", ordinary, 0.1, false, true)
	_expect(
		ordinary.pos.distance_to(center) < ordinary_before.distance_to(center),
		"decoy signal steers ordinary enemies toward its anchor"
	)
	run.call("_start_enemy_attack", ordinary)
	_expect(
		ordinary.committed_target == center,
		"decoy signal redirects a fresh enemy attack toward its anchor"
	)
	_expect(boss.pos == boss_before and structure.pos == structure_before, "decoy signal ignores bosses and structures")


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
