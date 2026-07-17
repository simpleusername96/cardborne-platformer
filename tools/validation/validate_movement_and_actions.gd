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
	await _validate_potion(traveler)
	await _validate_pulse(traveler, sandbox.training_pulse)

	pivot.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PASS: 3D map, keyboard, movement, dash, combat, cover, potion, and pulse contracts")
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
		&"melee": KEY_SPACE,
		&"ranged": KEY_Z,
		&"dash": KEY_SHIFT,
		&"interact": KEY_X,
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
	traveler.reset_training()
	var start := traveler.global_position
	Input.action_press("move_right")
	await _physics_frames(18)
	Input.action_release("move_right")
	await _physics_frames(2)
	_expect(traveler.global_position.distance_to(start) > 0.9, "arrow-key movement did not move the Traveler")
	_expect(absf(traveler.global_position.y - start.y) < 0.05, "planar movement drifted vertically")


func _validate_dash(traveler: Traveler3D) -> void:
	traveler.reset_training()
	traveler.facing = Vector3.RIGHT
	var start := traveler.global_position
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
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
	Input.action_press("melee")
	await physics_frame
	Input.action_release("melee")
	await _physics_frames(10)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH - 20, "Space melee did not hit exactly once")


func _validate_ranged(traveler: Traveler3D, dummy: DamageableDummy3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = Vector3.ZERO
	traveler.facing = Vector3.FORWARD
	dummy.global_position = Vector3(0, 0, -4.0)
	await _physics_frames(2)
	Input.action_press("ranged")
	await physics_frame
	Input.action_release("ranged")
	await _physics_frames(24)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH - 16, "Z ranged projectile did not hit exactly once")


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
	Input.action_press("ranged")
	await physics_frame
	Input.action_release("ranged")
	await _physics_frames(30)
	_expect(dummy.health == DamageableDummy3D.MAX_HEALTH, "ordinary ranged projectile pierced solid 3D cover")
	dummy.global_position = dummy_home


func _validate_potion(traveler: Traveler3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	traveler.receive_damage(50, &"validator")
	Input.action_press("potion")
	await physics_frame
	Input.action_release("potion")
	await _physics_frames(2)
	_expect(traveler.health == 85, "C potion did not restore 35 health")
	_expect(traveler.potion_charges == 2, "potion charge was not consumed exactly once")


func _validate_pulse(traveler: Traveler3D, pulse: TrainingPulse3D) -> void:
	traveler.reset_training()
	traveler.global_position = pulse.global_position - Vector3(0, pulse.global_position.y, 0)
	await _physics_frames(2)
	pulse.state = TrainingPulse3D.PulseState.STARTUP
	pulse.elapsed = 0.79
	await _physics_frames(3)
	_expect(traveler.health == traveler.max_health - 18, "active pulse did not damage the overlapping player")


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


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
