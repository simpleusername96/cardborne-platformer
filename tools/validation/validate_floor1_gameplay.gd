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
	_validate_damage_contract(runtime.traveler)
	await _validate_foundry(runtime)
	await _validate_pump(runtime)
	await _validate_pressure(runtime)
	await _validate_boss(runtime)
	pivot.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: damage, three enemy roles, Foundry clear, Pump activation, Pressure survival, and Slime King contracts")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _validate_damage_contract(traveler: Traveler3D) -> void:
	traveler.health = 100
	traveler.max_health = 100
	traveler._set_guarding(true)
	var blocked := traveler.apply_damage(DamageRequest3D.new(20, 0, DamageRequest3D.Team.ENEMY, &"blocked"))
	_expect(blocked.damage_applied == 7 and traveler.health == 93, "blockable damage did not retain 65% guard reduction")
	var pressure := traveler.apply_damage(DamageRequest3D.new(20, 0, DamageRequest3D.Team.ENVIRONMENT, &"pressure", false))
	_expect(pressure.damage_applied == 20 and traveler.health == 73, "non-blockable pressure did not bypass guard")
	traveler._set_guarding(false)
	traveler.max_health = 10000
	traveler.health = 10000


func _validate_foundry(runtime: FloorRuntime3D) -> void:
	await runtime._on_transition_requested(&"foundry_approach", &"foundry_south")
	await create_timer(0.35).timeout
	var encounter := runtime.current_room.get_node("FoundryEncounter3D") as FoundryEncounter3D
	_expect(encounter.active_enemies.size() == 2, "Foundry wave 1 is not exactly two Pursuers")
	for enemy in encounter.active_enemies.duplicate():
		enemy.apply_damage(DamageRequest3D.new(999, 0, DamageRequest3D.Team.PLAYER, &"validator"))
	await create_timer(1.05).timeout
	_expect(encounter.active_enemies.size() == 3, "Foundry wave 2 is not exactly three enemies")
	var roles: Dictionary = {}
	for enemy in encounter.active_enemies:
		roles[enemy.role] = true
	_expect(roles.has("pursuer") and roles.has("shooter") and roles.has("controller"), "Foundry mixed roster is incomplete")
	for enemy in encounter.active_enemies.duplicate():
		enemy.apply_damage(DamageRequest3D.new(999, 0, DamageRequest3D.Team.PLAYER, &"validator"))
	await create_timer(0.35).timeout
	_expect(encounter.encounter_completed, "Foundry did not complete after its fixed arena clear")
	_expect(not _gate_to(runtime.current_room, &"pump_gallery").locked, "Foundry exit remained locked")


func _validate_pump(runtime: FloorRuntime3D) -> void:
	await runtime._on_transition_requested(&"pump_gallery", &"pump_south")
	await create_timer(0.35).timeout
	var encounter := runtime.current_room.get_node("PumpGalleryEncounter3D") as PumpGalleryEncounter3D
	_expect(encounter.pumps.size() == 2, "Pump Gallery does not own exactly two pumps")
	_expect(encounter.enemies.size() == 3, "Pump Gallery pressure roster is not three enemies")
	var crates := runtime.current_room.find_children("*", "WaterloggedCrate3D", true, false)
	_expect(crates.size() == 2, "Pump Gallery does not own two waterlogged crates")
	if crates.size() == 2:
		var first := crates[0] as WaterloggedCrate3D
		first.apply_damage(DamageRequest3D.new(10, 0, DamageRequest3D.Team.PLAYER, &"ranged"))
		first.apply_damage(DamageRequest3D.new(10, 0, DamageRequest3D.Team.PLAYER, &"ranged"))
		_expect(first.is_broken, "two ranged hits did not break the crate")
		var second := crates[1] as WaterloggedCrate3D
		second.apply_damage(DamageRequest3D.new(20, 0, DamageRequest3D.Team.PLAYER, &"melee"))
		_expect(second.is_broken, "one standard melee did not break the crate")
	for pump in encounter.pumps:
		pump.restore_active(true)
	encounter._update_objective()
	_expect(bool(encounter.state.get("completed", false)), "two pumps did not complete the activation objective")
	_expect(not _gate_to(runtime.current_room, &"pressure_vault").locked, "Pump exit remained kill-gated")
	_expect(encounter.enemies.any(func(enemy: EnemyActor3D) -> bool: return is_instance_valid(enemy) and enemy.is_targetable()), "Pump objective removed every living enemy")
	_expect(encounter.enemies.all(func(enemy: EnemyActor3D) -> bool: return enemy.combat_suspended), "Pump completion did not stop new attacks")


func _validate_pressure(runtime: FloorRuntime3D) -> void:
	await runtime._on_transition_requested(&"pressure_vault", &"pressure_south")
	await create_timer(0.35).timeout
	var encounter := runtime.current_room.get_node("PressureVaultEncounter3D") as PressureVaultEncounter3D
	_expect(encounter.vents.size() == 4, "Pressure Vault does not own four vents")
	encounter.elapsed = 44.9
	await create_timer(0.2).timeout
	_expect(encounter.encounter_completed, "Pressure objective did not complete at 45 seconds")
	_expect(not _gate_to(runtime.current_room, &"slime_king_reservoir").locked, "Pressure exit remained kill-gated")
	_expect(encounter.enemies.any(func(enemy: EnemyActor3D) -> bool: return is_instance_valid(enemy)), "Pressure completion required extermination")
	_expect(encounter.vents.all(func(vent: PressureVent3D) -> bool: return vent.state == PressureVent3D.State.INERT), "vents did not become inert on completion")


func _validate_boss(runtime: FloorRuntime3D) -> void:
	await runtime._on_transition_requested(&"slime_king_reservoir", &"reservoir_south")
	await create_timer(0.35).timeout
	var encounter := runtime.current_room.get_node("SlimeKingEncounter3D") as SlimeKingEncounter3D
	_expect(encounter.boss != null and encounter.boss.health == SlimeKing3D.MAX_HEALTH, "Slime King did not spawn at 600 HP")
	var boss_health_bar := encounter.boss.get_node_or_null("HealthBar") as EnemyHealthBar3D
	_expect(boss_health_bar != null and boss_health_bar.visible, "Slime King has no visible health bar")
	var first_boss_id := encounter.boss.get_instance_id()
	runtime.traveler.defeated.emit()
	await create_timer(0.65).timeout
	_expect(encounter.boss != null and encounter.boss.get_instance_id() != first_boss_id, "boss retry kept stale boss state")
	var patterns: Array[StringName] = []
	encounter.boss.pattern_started.connect(func(pattern_id: StringName) -> void: patterns.append(pattern_id))
	var deadline := Time.get_ticks_msec() + 18000
	while patterns.size() < 4 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	_expect(patterns.size() == 4 and patterns.duplicate().all(func(id: StringName) -> bool: return patterns.count(id) == 1), "boss scheduler did not expose four non-repeating patterns")
	var previous_fill := boss_health_bar.fill.scale.x if boss_health_bar != null else 0.0
	encounter.boss.apply_damage(DamageRequest3D.new(100, 0, DamageRequest3D.Team.PLAYER, &"validator"))
	if boss_health_bar != null:
		_expect(boss_health_bar.fill.scale.x < previous_fill, "Slime King health bar did not reflect damage")
	encounter.boss.apply_damage(DamageRequest3D.new(999, 0, DamageRequest3D.Team.PLAYER, &"validator"))
	await process_frame
	_expect(encounter.encounter_completed and encounter.result_emitted, "boss defeat result hook did not fire exactly once")
	_expect(get_nodes_in_group(&"combat_effects").filter(func(node: Node) -> bool: return runtime.current_room.is_ancestor_of(node)).is_empty(), "boss defeat left stale hazards")


func _gate_to(room: FloodedWorksRoom3D, target_room_id: StringName) -> RoomGate3D:
	for gate in room.get_gates():
		if gate.target_room_id == target_room_id:
			return gate
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
