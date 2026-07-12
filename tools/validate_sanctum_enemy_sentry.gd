extends SceneTree

const SENTRY_SCENE := "res://scenes/enemies/SentrySanctum.tscn"
const MAX_WAIT_FRAMES := 180

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var fixture := await _create_fixture()
	var world := fixture.get("world") as Node2D
	var player := fixture.get("player") as Node2D
	var sentry: Variant = fixture.get("sentry")
	_expect(world != null and player != null and sentry != null, "Sentry fixture should instantiate")
	if world != null and player != null and sentry != null:
		await _validate_locked_warning_and_recovery(world, player, sentry)
		await _validate_projectile_cap(sentry)
		await _validate_inactivity(player, sentry)
		await _validate_defeat_cleanup(world, player, sentry)
		world.queue_free()
		await process_frame
	_finish()


func _create_fixture() -> Dictionary:
	var packed := load(SENTRY_SCENE) as PackedScene
	_expect(packed != null, "Sentry production scene should load")
	if packed == null:
		return {}
	var world := Node2D.new()
	world.name = "SentryFixture"
	root.add_child(world)
	_add_floor(world)
	var player := Node2D.new()
	player.name = "PlayerMarker"
	player.add_to_group("player")
	player.position = Vector2(360.0, 300.0)
	world.add_child(player)
	var sentry: Variant = packed.instantiate()
	sentry.enemy_catalog = _build_catalog()
	sentry.position = Vector2(640.0, 300.0)
	sentry.encounter_bounds = Rect2(-1400.0, 0.0, 4200.0, 720.0)
	world.add_child(sentry)
	await physics_frame
	await process_frame
	return {"world": world, "player": player, "sentry": sentry}


func _build_catalog() -> EnemyCatalog:
	var catalog := EnemyCatalog.new()
	catalog.id = &"sentry_runtime_fixture"
	catalog.display_name = "Sentry Runtime Fixture"
	catalog.tags = [&"enemy_catalog", &"fixture"]
	var archetypes: Array[EnemyArchetypeDefinition] = [
		load("res://data/enemies/sentry_archetype.tres") as EnemyArchetypeDefinition,
	]
	var tunings: Array[EnemyTuningProfile] = [
		load("res://data/enemies/tuning_broken_sanctum.tres") as EnemyTuningProfile,
	]
	var variants: Array[EnemyVariantDefinition] = [
		load("res://data/enemies/sentry_sanctum.tres") as EnemyVariantDefinition,
	]
	catalog.archetypes = archetypes
	catalog.tuning_profiles = tunings
	catalog.variants = variants
	return catalog


func _validate_locked_warning_and_recovery(world: Node2D, player: Node2D, sentry: Variant) -> void:
	_expect(sentry.resolved_spec != null, "Sentry should resolve its Sanctum spec")
	_expect(sentry.get_node_or_null("ContactHitbox") == null, "Sentry should have no contact hitbox")
	var warning_frame := -1
	var locked_direction := Vector2.ZERO
	var locked_facing := 0
	for frame in MAX_WAIT_FRAMES:
		await physics_frame
		var snapshot: Dictionary = sentry.get_combat_snapshot()
		if bool(snapshot["warning"]):
			warning_frame = frame
			locked_direction = snapshot["locked_aim_direction"]
			locked_facing = sentry.direction
			var line := sentry.get_node_or_null("AimWarning") as Line2D
			_expect(line != null and line.visible, "Sentry warning should show the locked aim line")
			break
	_expect(warning_frame >= 0, "On-screen Sentry should enter warning")
	if warning_frame < 0:
		return

	player.position = Vector2(840.0, 300.0)
	for _frame in 6:
		await physics_frame
	var during_warning: Dictionary = sentry.get_combat_snapshot()
	_expect(bool(during_warning["warning"]), "Sentry warning should remain active while target stays in range")
	_expect(sentry.direction == locked_facing, "Sentry must not turn during warning")
	_expect((during_warning["locked_aim_direction"] as Vector2).is_equal_approx(locked_direction), "Sentry aim vector must remain locked during warning")

	var recovery_frame := -1
	var idle_frame := -1
	for frame in MAX_WAIT_FRAMES:
		await physics_frame
		var snapshot: Dictionary = sentry.get_combat_snapshot()
		if recovery_frame < 0 and bool(snapshot["recovery"]):
			recovery_frame = frame
			var projectiles := _projectiles_in(world)
			_expect(projectiles.size() == 1, "Sentry should fire exactly one projectile after warning")
			if not projectiles.is_empty():
				var projectile: Variant = projectiles[0]
				_expect(is_equal_approx(projectile.velocity.length(), 300.0), "Sentry projectile speed should be exact")
				_expect(is_equal_approx(projectile.lifetime, 3.0), "Sentry projectile range should resolve to a 3 s lifetime")
				_expect(projectile.velocity.normalized().is_equal_approx(locked_direction), "Sentry projectile should use the locked aim")
		elif recovery_frame >= 0 and not bool(snapshot["recovery"]):
			idle_frame = frame
			break
	_expect(recovery_frame >= 0, "Sentry should enter explicit recovery after firing")
	_expect(idle_frame - recovery_frame >= 25, "Sentry recovery should preserve the 0.45 s floor")


func _validate_projectile_cap(sentry: Variant) -> void:
	var maximum_seen := 0
	for _frame in 260:
		await physics_frame
		var snapshot: Dictionary = sentry.get_combat_snapshot()
		maximum_seen = maxi(maximum_seen, int(snapshot["active_projectiles"]))
		_expect(int(snapshot["active_projectiles"]) <= 2, "Sentry must never exceed two active projectiles")
	_expect(maximum_seen == 2, "Sentry cap fixture should reach two simultaneous projectiles")
	sentry.reset_enemy()
	await process_frame
	_expect(int(sentry.get_combat_snapshot()["active_projectiles"]) == 0, "Sentry reset should clear all projectiles")


func _validate_inactivity(player: Node2D, sentry: Variant) -> void:
	sentry.global_position = Vector2(-700.0, 300.0)
	player.global_position = Vector2(-500.0, 300.0)
	for _frame in 100:
		await physics_frame
	var offscreen: Dictionary = sentry.get_combat_snapshot()
	_expect(not bool(offscreen["warning"]), "Off-screen Sentry must not aim")
	_expect(int(offscreen["shots_fired"]) == 0, "Off-screen Sentry must not fire")

	sentry.reset_enemy()
	player.global_position = Vector2(360.0, 300.0)
	sentry.encounter_bounds = Rect2(700.0, 0.0, 400.0, 720.0)
	for _frame in 100:
		await physics_frame
	var outside_encounter: Dictionary = sentry.get_combat_snapshot()
	_expect(not bool(outside_encounter["warning"]), "Sentry must ignore targets outside encounter bounds")
	_expect(int(outside_encounter["shots_fired"]) == 0, "Sentry must not fire outside its encounter")


func _validate_defeat_cleanup(world: Node2D, player: Node2D, sentry: Variant) -> void:
	sentry.encounter_bounds = Rect2(-1400.0, 0.0, 4200.0, 720.0)
	player.global_position = Vector2(360.0, 300.0)
	sentry.reset_enemy()
	var shot_seen := false
	for _frame in MAX_WAIT_FRAMES:
		await physics_frame
		if int(sentry.get_combat_snapshot()["active_projectiles"]) > 0:
			shot_seen = true
			break
	_expect(shot_seen, "Defeat fixture should produce one live projectile")
	sentry.receive_damage(DamageInfo.new(99))
	await process_frame
	await process_frame
	_expect(int(sentry.get_combat_snapshot()["active_projectiles"]) == 0, "Sentry defeat should clear its projectile registry")
	_expect(_projectiles_in(world).is_empty(), "Sentry defeat should remove every live projectile node")


func _projectiles_in(world: Node2D) -> Array:
	var projectiles: Array = []
	for child in world.get_children():
		if child is Area2D and child.has_method("set_active") and String(child.name).contains("Projectile"):
			projectiles.append(child)
	return projectiles


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(640.0, 312.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000.0, 24.0)
	collision.shape = shape
	floor.add_child(collision)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SANCTUM_ENEMY_SENTRY_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
