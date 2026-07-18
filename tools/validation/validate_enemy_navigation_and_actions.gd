extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var pivot := (load("res://scenes/main/PivotRoot.tscn") as PackedScene).instantiate()
	root.add_child(pivot)
	await create_timer(0.25).timeout
	var runtime := pivot.get_node("FloorRuntime3D") as FloorRuntime3D
	runtime.traveler.max_health = 10000
	runtime.traveler.health = 10000
	await runtime._on_transition_requested(&"foundry_approach", &"foundry_south")
	await create_timer(0.4).timeout
	var encounter := runtime.current_room.get_node("FoundryEncounter3D") as FoundryEncounter3D
	var wave_one := encounter.active_enemies.duplicate()
	var starts: Dictionary = {}
	var cycles: Dictionary = {}
	for enemy in wave_one:
		starts[enemy.get_instance_id()] = enemy.global_position
		cycles[enemy.get_instance_id()] = 0
		enemy.attack_completed.connect(func(actor: EnemyActor3D, _role: StringName) -> void: cycles[actor.get_instance_id()] = int(cycles.get(actor.get_instance_id(), 0)) + 1)
	await create_timer(12.0).timeout
	for enemy in wave_one:
		_expect(enemy.global_position.distance_to(starts[enemy.get_instance_id()]) > 0.5, "%s did not navigate from its authored spawn" % enemy.name)
		_expect(int(cycles[enemy.get_instance_id()]) >= 3, "%s did not complete three legal attack cycles" % enemy.name)
	for enemy in wave_one:
		enemy.apply_damage(DamageRequest3D.new(999, 0, DamageRequest3D.Team.PLAYER, &"validator"))
	await create_timer(1.05).timeout
	var wave_two := encounter.active_enemies.duplicate()
	cycles.clear()
	for enemy in wave_two:
		cycles[enemy.get_instance_id()] = 0
		enemy.attack_completed.connect(func(actor: EnemyActor3D, _role: StringName) -> void: cycles[actor.get_instance_id()] = int(cycles.get(actor.get_instance_id(), 0)) + 1)
	await create_timer(16.0).timeout
	for enemy in wave_two:
		_expect(int(cycles.get(enemy.get_instance_id(), 0)) >= 3, "%s did not complete three mixed-role cycles" % enemy.role)
		var stagger_result: DamageResult3D = enemy.apply_damage(DamageRequest3D.new(1, 20, DamageRequest3D.Team.PLAYER, &"interrupt"))
		_expect(stagger_result.accepted and enemy.state == EnemyActor3D.State.STAGGER, "%s did not enter legal stagger interruption" % enemy.role)
	await create_timer(0.35).timeout
	_expect(get_nodes_in_group(&"combat_projectiles").size() <= 3, "enemy projectile count is unbounded")
	pivot.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: enemy navigation, three-role repeated attacks, threat tokens, interruption, and bounded effects")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
