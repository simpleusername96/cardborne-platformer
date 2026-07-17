extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/PivotRoot.tscn")
	var pivot := packed.instantiate()
	root.add_child(pivot)
	await _physics_frames(3)

	var sandbox: CombatSandbox3D = pivot.get_node("CombatSandbox3D")
	var traveler: Traveler3D = sandbox.get_node("Traveler")
	var dummy: DamageableDummy3D = sandbox.get_node("DamageableDummy")

	_validate_scene_contract(sandbox, traveler)
	_validate_input_contract()
	_validate_numeric_contract()
	await _validate_movement(traveler)
	await _validate_dash(traveler)
	await _validate_melee(traveler, dummy)
	await _validate_ranged(traveler, dummy)
	await _validate_projectile_cover(traveler, dummy, sandbox.get_node("TallCover"))
	await _validate_guard(traveler)
	await _validate_potion(traveler)
	await _validate_pulse(traveler, sandbox.training_pulse)
	await _validate_pause(sandbox.get_node("HUD"))

	pivot.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PASS: real key events, movement, dash, guard, combat, cover, potion, pulse, and pause contracts")
		quit(0)
	else:
		for failure in _failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _validate_scene_contract(sandbox: CombatSandbox3D, traveler: Traveler3D) -> void:
	_expect(sandbox.has_node("Architecture/RoomLarge"), "Kenney room geometry is missing")
	_expect(sandbox.has_node("Architecture/NorthGate"), "Kenney gate geometry is missing")
	_expect(sandbox.has_node("Collision/Floor"), "3D floor collision is missing")
	_expect(sandbox.has_node("TallCover"), "projectile-blocking cover is missing")
	_expect(sandbox.has_node("DamageableDummy"), "damageable dummy is missing")
	_expect(sandbox.has_node("TrainingPulse"), "timed damage pulse is missing")
	_expect(traveler is CharacterBody3D, "Traveler is not a real 3D character body")
	var camera: Camera3D = sandbox.get_node("CameraRig/Camera3D")
	_expect(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "camera is not orthographic")
	_expect(camera.current, "isometric camera is not current")
	var imported_meshes := sandbox.get_node("Architecture").find_children("*", "MeshInstance3D", true, false)
	_expect(imported_meshes.size() >= 3, "imported architecture did not instantiate as 3D meshes")


func _validate_input_contract() -> void:
	var expected_keys := {
		&"move_left": KEY_LEFT,
		&"move_right": KEY_RIGHT,
		&"move_up": KEY_UP,
		&"move_down": KEY_DOWN,
		&"melee": KEY_Z,
		&"ranged": KEY_X,
		&"dash": KEY_SPACE,
		&"guard": KEY_SHIFT,
		&"potion": KEY_C,
		&"pause": KEY_ESCAPE,
	}
	for action: StringName in expected_keys:
		_expect(InputMap.has_action(action), "InputMap action %s is missing" % action)
		_expect(_has_physical_key(action, expected_keys[action]), "%s does not use its required keyboard key" % action)
	_expect(_has_event_type(&"dash", "InputEventJoypadButton"), "dash gamepad binding is missing")
	_expect(_has_event_type(&"ranged", "InputEventJoypadMotion"), "ranged gamepad trigger is missing")


func _validate_numeric_contract() -> void:
	_expect(Traveler3D.MOVE_SPEED == 6.0, "3D movement baseline changed")
	_expect(Traveler3D.DASH_SPEED == 14.0, "3D dash speed baseline changed")
	_expect(Traveler3D.DASH_DURATION == 0.18, "3D dash duration baseline changed")
	_expect(ProofProjectile3D.SPEED == 18.0, "3D projectile speed baseline changed")


func _validate_movement(traveler: Traveler3D) -> void:
	var movement_keys: Array[Key] = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
	for keycode in movement_keys:
		traveler.reset_training()
		var start := traveler.global_position
		_key_down(keycode)
		await _physics_frames(18)
		_key_up(keycode)
		await _physics_frames(2)
		_expect(
			traveler.global_position.distance_to(start) > 0.9,
			"arrow key %s did not move the Traveler" % OS.get_keycode_string(keycode),
		)
		_expect(absf(traveler.global_position.y - start.y) < 0.05, "planar movement drifted vertically")

	traveler.reset_training()
	var cardinal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var cardinal_distance := traveler.global_position.distance_to(cardinal_start)
	traveler.reset_training()
	var diagonal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	_key_down(KEY_UP)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	_key_up(KEY_UP)
	var diagonal_distance := traveler.global_position.distance_to(diagonal_start)
	_expect(
		absf(diagonal_distance - cardinal_distance) < cardinal_distance * 0.1,
		"diagonal arrow movement is not normalized (cardinal %.3f, diagonal %.3f)"
		% [cardinal_distance, diagonal_distance],
	)


func _validate_dash(traveler: Traveler3D) -> void:
	traveler.reset_training()
	traveler.facing = Vector3.RIGHT
	var start := traveler.global_position
	_key_down(KEY_SPACE)
	await physics_frame
	_key_up(KEY_SPACE)
	await physics_frame
	var health_before := traveler.health
	var damage_applied := traveler.receive_damage(20, &"dash_validator")
	_expect(not damage_applied and traveler.health == health_before, "dash startup did not reject damage")
	await _physics_frames(12)
	_expect(traveler.global_position.distance_to(start) > 1.5, "dash displacement is too short")


func _validate_melee(traveler: Traveler3D, dummy: DamageableDummy3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = Vector3.ZERO
	traveler.facing = Vector3.FORWARD
	dummy.global_position = Vector3(0, 0, -1.65)
	await _physics_frames(2)
	_key_down(KEY_Z)
	await physics_frame
	_key_up(KEY_Z)
	await _physics_frames(10)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH - 20, "Z melee did not hit exactly once")


func _validate_ranged(traveler: Traveler3D, dummy: DamageableDummy3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = Vector3.ZERO
	traveler.facing = Vector3.FORWARD
	dummy.global_position = Vector3(0, 0, -4.0)
	await _physics_frames(2)
	_key_down(KEY_X)
	await physics_frame
	_key_up(KEY_X)
	await _physics_frames(24)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH - 16, "X ranged projectile did not hit exactly once")


func _validate_projectile_cover(
	traveler: Traveler3D,
	dummy: DamageableDummy3D,
	cover: StaticBody3D,
) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	dummy.reset_dummy()
	var dummy_home := dummy.global_position
	traveler.global_position = cover.global_position + Vector3(-3.2, -0.9, 0)
	traveler.facing = Vector3.RIGHT
	dummy.global_position = cover.global_position + Vector3(3.2, -0.9, 0)
	await _physics_frames(2)
	_key_down(KEY_X)
	await physics_frame
	_key_up(KEY_X)
	await _physics_frames(30)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH, "ordinary ranged projectile pierced solid 3D cover")
	dummy.global_position = dummy_home


func _validate_potion(traveler: Traveler3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	traveler.receive_damage(50, &"validator")
	_key_down(KEY_C)
	await physics_frame
	_key_up(KEY_C)
	await _physics_frames(2)
	_expect(traveler.health == 85, "C potion did not restore 35 health")
	_expect(traveler.potion_charges == 2, "potion charge was not consumed exactly once")


func _validate_guard(traveler: Traveler3D) -> void:
	traveler.reset_training()
	_key_down(KEY_SHIFT)
	await _physics_frames(2)
	_expect(traveler.guarding and traveler.shield.visible, "Shift did not enter the visible guard state")
	_key_down(KEY_Z)
	_key_down(KEY_X)
	_key_down(KEY_SPACE)
	await physics_frame
	_key_up(KEY_Z)
	_key_up(KEY_X)
	_key_up(KEY_SPACE)
	_expect(
		traveler.melee_remaining <= 0.0
		and traveler.ranged_cooldown_remaining <= 0.0
		and traveler.dash_remaining <= 0.0,
		"guard did not block melee, ranged, and dash actions",
	)
	traveler.receive_damage(20, &"guard_validator")
	_expect(traveler.health == 93, "guard did not reduce 20 damage to 7")
	var guarded_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var guarded_distance := traveler.global_position.distance_to(guarded_start)
	_key_up(KEY_SHIFT)
	await _physics_frames(2)
	_expect(not traveler.guarding and not traveler.shield.visible, "guard state remained active after Shift release")
	traveler.reset_training()
	var normal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var normal_distance := traveler.global_position.distance_to(normal_start)
	_expect(guarded_distance < normal_distance * 0.7, "guard did not apply its movement-speed penalty")


func _validate_pulse(traveler: Traveler3D, pulse: TrainingPulse3D) -> void:
	traveler.reset_training()
	traveler.global_position = pulse.global_position - Vector3(0, pulse.global_position.y, 0)
	await _physics_frames(2)
	pulse.state = TrainingPulse3D.PulseState.STARTUP
	pulse.elapsed = 0.79
	await _physics_frames(3)
	_expect(traveler.health == traveler.max_health - 18, "active pulse did not damage the overlapping player")


func _validate_pause(hud: CombatSandboxHud3D) -> void:
	_key_down(KEY_ESCAPE)
	await process_frame
	_key_up(KEY_ESCAPE)
	await process_frame
	_expect(paused and hud.pause_overlay.visible, "Esc did not pause the scene and reveal the pause overlay")
	var paused_position := hud.traveler.global_position
	_key_down(KEY_RIGHT)
	for _index in 4:
		await process_frame
	_key_up(KEY_RIGHT)
	_expect(
		hud.traveler.global_position.is_equal_approx(paused_position),
		"Traveler continued moving while the scene was paused",
	)
	_key_down(KEY_ESCAPE)
	await process_frame
	_key_up(KEY_ESCAPE)
	await process_frame
	_expect(not paused and not hud.pause_overlay.visible, "second Esc did not resume the scene")


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


func _key_down(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, true))


func _key_up(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, false))


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _has_physical_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _has_event_type(action: StringName, expected_class: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event.get_class() == expected_class:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
