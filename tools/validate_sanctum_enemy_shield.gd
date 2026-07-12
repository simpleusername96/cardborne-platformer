extends SceneTree

const SHIELD_SCENE := "res://scenes/enemies/ShieldGuardSanctum.tscn"
const MAX_SEQUENCE_FRAMES := 220

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var fixture := await _create_fixture()
	var world := fixture.get("world") as Node2D
	var player := fixture.get("player") as Node2D
	var rear_source := fixture.get("rear_source") as Node2D
	var shield: Variant = fixture.get("shield")
	_expect(world != null and player != null and rear_source != null and shield != null, "Shield fixture should instantiate")
	if world != null and shield != null:
		_validate_damage_responses(shield, player, rear_source)
		shield.reset_enemy()
		await physics_frame
		await _validate_state_sequence(shield)
		world.queue_free()
		await process_frame
	_finish()


func _create_fixture() -> Dictionary:
	var packed := load(SHIELD_SCENE) as PackedScene
	_expect(packed != null, "Shield production scene should load")
	if packed == null:
		return {}
	var world := Node2D.new()
	world.name = "ShieldFixture"
	root.add_child(world)
	_add_floor(world)
	var player := Node2D.new()
	player.name = "PlayerMarker"
	player.add_to_group("player")
	player.position = Vector2(500.0, 300.0)
	world.add_child(player)
	var rear_source := Node2D.new()
	rear_source.name = "RearSource"
	rear_source.position = Vector2(780.0, 300.0)
	world.add_child(rear_source)
	var shield: Variant = packed.instantiate()
	shield.enemy_catalog = _build_catalog()
	shield.position = Vector2(640.0, 300.0)
	shield.encounter_bounds = Rect2(0.0, 0.0, 1280.0, 720.0)
	world.add_child(shield)
	await physics_frame
	await process_frame
	return {"world": world, "player": player, "rear_source": rear_source, "shield": shield}


func _build_catalog() -> EnemyCatalog:
	var catalog := EnemyCatalog.new()
	catalog.id = &"shield_runtime_fixture"
	catalog.display_name = "Shield Runtime Fixture"
	catalog.tags = [&"enemy_catalog", &"fixture"]
	var archetypes: Array[EnemyArchetypeDefinition] = [
		load("res://data/enemies/shield_guard_archetype.tres") as EnemyArchetypeDefinition,
	]
	var tunings: Array[EnemyTuningProfile] = [
		load("res://data/enemies/tuning_broken_sanctum.tres") as EnemyTuningProfile,
	]
	var variants: Array[EnemyVariantDefinition] = [
		load("res://data/enemies/shield_guard_sanctum.tres") as EnemyVariantDefinition,
	]
	catalog.archetypes = archetypes
	catalog.tuning_profiles = tunings
	catalog.variants = variants
	return catalog


func _validate_damage_responses(shield: Variant, front: Node2D, rear: Node2D) -> void:
	_expect(shield.resolved_spec != null, "Shield should resolve its Sanctum spec")
	_expect(shield.current_health == 7, "Shield should start at exact HP 7")
	shield.direction = -1
	shield.receive_damage(DamageInfo.new(
		2, front, Vector2.ZERO, ["player_attack", "basic"], &"fixture_basic"
	))
	_expect(shield.current_health == 7, "Frontal guard should block health damage")
	shield.receive_damage(DamageInfo.new(
		2, rear, Vector2.ZERO, ["player_attack", "basic"], &"fixture_flank"
	))
	_expect(shield.current_health == 5, "Rear attack should bypass guard")

	shield.reset_enemy()
	shield.direction = -1
	shield.receive_damage(DamageInfo.new(
		3, front, Vector2.ZERO, ["player_attack", "skill", "shockwave"], &"fixture_area"
	))
	_expect(shield.current_health == 4, "Authored area attack should bypass the frontal shield")

	shield.reset_enemy()
	shield.direction = -1
	for hit_index in 2:
		shield.receive_damage(DamageInfo.new(
			4,
			front,
			Vector2.ZERO,
			["player_attack", "heavy"],
			StringName("fixture_heavy_%d" % hit_index),
			60
		))
	_expect(shield.current_health == 7, "Frontal Heavy should not leak health damage through guard")
	_expect(shield.is_staggered(), "Repeated Heavy stagger should break Shield Guard posture")


func _validate_state_sequence(shield: Variant) -> void:
	var warning_frame := -1
	var active_frame := -1
	var recovery_frame := -1
	var guard_return_frame := -1
	for frame in MAX_SEQUENCE_FRAMES:
		await physics_frame
		var snapshot: Dictionary = shield.get_combat_snapshot()
		var contact := shield.get_node_or_null("ContactHitbox") as Hitbox
		if warning_frame < 0 and bool(snapshot["warning"]):
			warning_frame = frame
			var warning := shield.get_node_or_null("AttackWarning") as Line2D
			_expect(warning != null and warning.visible, "Shield attack warning should be visible")
			_expect(contact != null and not contact.active, "Shield warning must be non-damaging")
		if active_frame < 0 and bool(snapshot["active"]):
			active_frame = frame
			_expect(contact != null and contact.active, "Shield active shove should enable contact damage")
		if active_frame >= 0 and recovery_frame < 0 and bool(snapshot["recovery"]):
			recovery_frame = frame
			_expect(contact != null and not contact.active, "Shield recovery must disable contact damage")
		if recovery_frame >= 0 and bool(snapshot["guarding"]):
			guard_return_frame = frame
			break
	_expect(warning_frame >= 0, "Shield should enter warning near a valid target")
	_expect(active_frame > warning_frame, "Shield active shove should follow warning")
	_expect(recovery_frame > active_frame, "Shield recovery should follow active shove")
	_expect(guard_return_frame > recovery_frame, "Shield should return to guard after recovery")
	_expect(active_frame - warning_frame >= 19, "Shield warning should preserve the 0.35 s floor")
	_expect(recovery_frame - active_frame >= 9, "Shield should expose a real active attack window")
	_expect(guard_return_frame - recovery_frame >= 31, "Shield recovery should preserve the 0.55 s floor")


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(640.0, 312.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1280.0, 24.0)
	collision.shape = shape
	floor.add_child(collision)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SANCTUM_ENEMY_SHIELD_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
