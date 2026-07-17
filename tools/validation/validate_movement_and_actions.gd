extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/PivotRoot.tscn")
	var pivot := packed.instantiate()
	root.add_child(pivot)
	await physics_frame
	await physics_frame

	var sandbox: CombatSandbox = pivot.get_node("CombatSandbox")
	var traveler: Traveler = sandbox.get_node("Traveler")
	var dummy: DamageableDummy = sandbox.get_node("DamageableDummy")

	_validate_scene_contract(sandbox, traveler)
	_validate_input_contract()
	_validate_numeric_contract()
	await _validate_movement(traveler)
	await _validate_dash(traveler)
	await _validate_melee(traveler, dummy)
	await _validate_ranged(traveler, dummy)
	await _validate_projectile_cover(traveler, dummy, sandbox.get_node("CoverWest"))
	await _validate_potion(traveler)

	pivot.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PASS: movement, map, action, damage, and reset contracts")
		quit(0)
	else:
		for failure in _failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _validate_scene_contract(sandbox: CombatSandbox, traveler: Traveler) -> void:
	_expect(sandbox.has_node("Boundary/Top"), "room top boundary is missing")
	_expect(sandbox.has_node("Boundary/Bottom"), "room bottom boundary is missing")
	_expect(sandbox.has_node("CoverWest"), "first cover block is missing")
	_expect(sandbox.has_node("CoverSouth"), "second cover block is missing")
	_expect(sandbox.has_node("DamageableDummy"), "damageable dummy is missing")
	_expect(sandbox.has_node("TrainingPulse"), "timed damage pulse is missing")
	_expect(traveler.has_node("Camera2D"), "bounded player camera is missing")
	var camera: Camera2D = traveler.get_node("Camera2D")
	_expect(camera.limit_left == 0 and camera.limit_right == 1600, "camera horizontal limits changed")
	_expect(camera.limit_top == 0 and camera.limit_bottom == 900, "camera vertical limits changed")


func _validate_input_contract() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down", &"melee", &"ranged", &"dash", &"interact", &"potion", &"pause"]:
		_expect(InputMap.has_action(action), "InputMap action %s is missing" % action)
		_expect(not InputMap.action_get_events(action).is_empty(), "InputMap action %s has no binding" % action)
	_expect(_has_event_type(&"melee", "InputEventMouseButton"), "melee mouse binding is missing")
	_expect(_has_event_type(&"melee", "InputEventJoypadButton"), "melee gamepad binding is missing")
	_expect(_has_event_type(&"ranged", "InputEventMouseButton"), "ranged mouse binding is missing")
	_expect(_has_event_type(&"ranged", "InputEventJoypadMotion"), "ranged trigger binding is missing")


func _validate_numeric_contract() -> void:
	var motor := PlayerMotor.new()
	var diagonal := motor.normalized_velocity(Vector2.ONE)
	_expect(is_equal_approx(diagonal.length(), PlayerMotor.MAX_SPEED), "diagonal movement is not normalized")
	_expect(PlayerMotor.MAX_SPEED == 220.0, "ground speed baseline changed")
	_expect(PlayerMotor.DASH_SPEED == 520.0, "dash speed baseline changed")
	_expect(PlayerMotor.DASH_DURATION == 0.18, "dash duration baseline changed")
	_expect(PlayerMotor.DASH_INVULNERABILITY == 0.10, "dash invulnerability baseline changed")
	var sword_one: AttackDefinition = load("res://data/attacks/proof/sword_hit_1.tres")
	var sword_two: AttackDefinition = load("res://data/attacks/proof/sword_hit_2.tres")
	var ranged: AttackDefinition = load("res://data/attacks/proof/ranged_shot.tres")
	_expect(sword_one.damage == 20 and sword_two.damage == 28, "sword damage baselines changed")
	_expect(ranged.damage == 16 and ranged.projectile_speed == 720.0, "ranged baseline changed")


func _validate_movement(traveler: Traveler) -> void:
	traveler.reset_training()
	var start := traveler.global_position
	Input.action_press("move_right")
	await _physics_frames(18)
	Input.action_release("move_right")
	_expect(traveler.global_position.x > start.x + 35.0, "move-right input did not move the Traveler")
	_expect(absf(traveler.global_position.y - start.y) < 2.0, "cardinal movement drifted vertically")
	traveler.global_position = Vector2(500, 192)
	traveler.velocity = Vector2.ZERO
	Input.action_press("move_up")
	Input.action_press("move_right")
	await _physics_frames(18)
	Input.action_release("move_up")
	Input.action_release("move_right")
	_expect(traveler.global_position.x > 530.0, "wall-slide input did not preserve tangential movement")
	_expect(traveler.global_position.y >= 187.0, "Traveler crossed the top boundary during wall slide")


func _validate_dash(traveler: Traveler) -> void:
	traveler.reset_training()
	traveler.set_validation_aim(Vector2.RIGHT)
	var start := traveler.global_position
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame
	var health_before_pulse := traveler.health
	var damage_applied := traveler.receive_damage(20, &"dash_validator")
	_expect(not damage_applied and traveler.health == health_before_pulse, "dash invulnerability did not reject damage")
	await _physics_frames(14)
	var distance := traveler.global_position.distance_to(start)
	_expect(distance >= 78.0 and distance <= 110.0, "dash distance %.2f is outside the proof range" % distance)


func _validate_melee(traveler: Traveler, dummy: DamageableDummy) -> void:
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = dummy.global_position - Vector2(92, 0)
	traveler.set_validation_aim(Vector2.RIGHT)
	Input.action_press("melee")
	await physics_frame
	Input.action_release("melee")
	await _physics_frames(12)
	_expect(dummy.health == DamageableDummy.MAX_HEALTH - 20, "first sword activation did not hit exactly once")
	await _physics_frames(18)
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = dummy.global_position - Vector2(92, 0)
	traveler.set_validation_aim(Vector2.RIGHT)
	Input.action_press("melee")
	await physics_frame
	Input.action_release("melee")
	await _physics_frames(14)
	Input.action_press("melee")
	await physics_frame
	Input.action_release("melee")
	await _physics_frames(38)
	_expect(dummy.health == DamageableDummy.MAX_HEALTH - 48, "buffered sword chain did not apply exactly two activations")


func _validate_ranged(traveler: Traveler, dummy: DamageableDummy) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	dummy.reset_dummy()
	traveler.global_position = dummy.global_position - Vector2(250, 0)
	traveler.set_validation_aim(Vector2.RIGHT)
	Input.action_press("ranged")
	await physics_frame
	Input.action_release("ranged")
	await _physics_frames(28)
	_expect(dummy.health == DamageableDummy.MAX_HEALTH - 16, "ranged projectile did not hit exactly once")


func _validate_projectile_cover(traveler: Traveler, dummy: DamageableDummy, cover: Node2D) -> void:
	await _physics_frames(12)
	traveler.reset_training()
	dummy.reset_dummy()
	var dummy_home := dummy.global_position
	dummy.global_position = cover.global_position + Vector2(180, 0)
	traveler.global_position = cover.global_position - Vector2(240, 0)
	traveler.set_validation_aim(Vector2.RIGHT)
	Input.action_press("ranged")
	await physics_frame
	Input.action_release("ranged")
	await _physics_frames(34)
	_expect(dummy.health == DamageableDummy.MAX_HEALTH, "ordinary ranged projectile pierced solid cover")
	dummy.global_position = dummy_home


func _validate_potion(traveler: Traveler) -> void:
	await _physics_frames(12)
	traveler.reset_training()
	traveler.receive_damage(50, &"validator")
	Input.action_press("potion")
	await physics_frame
	Input.action_release("potion")
	await _physics_frames(10)
	traveler.receive_damage(5, &"interrupt_validator")
	await _physics_frames(24)
	_expect(traveler.health == 45, "damage did not cancel the committed potion before healing")
	_expect(traveler.actions.potion_charges == 3, "interrupted potion consumed a charge")
	traveler.reset_training()
	traveler.receive_damage(50, &"validator")
	Input.action_press("potion")
	await physics_frame
	Input.action_release("potion")
	await _physics_frames(32)
	_expect(traveler.health == 85, "potion did not restore 35 percent health")
	_expect(traveler.actions.potion_charges == 2, "potion charge was not consumed exactly once")
	traveler.reset_training()
	_expect(traveler.health == 100 and traveler.actions.potion_charges == 3, "training reset did not restore the fixture")


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


func _has_event_type(action: StringName, expected_class: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event.get_class() == expected_class:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
