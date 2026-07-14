extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const ENEMY_SCENE := "res://scenes/enemies/WalkerRuin.tscn"

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile_state := root.get_node_or_null("/root/ProfileState")
	if profile_state == null:
		_failures.append("ProfileState autoload is unavailable.")
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null or not bool(run_state.start_new_run(0, 1701)):
		_failures.append("Shared hero run could not start.")
		_finish()
		return
	var combat_loadout: Dictionary = run_state.get_hero_combat_loadout_snapshot()
	# Runtime selection is the subject here; profile command tests own supply mutation.
	(combat_loadout["ranged"]["intent_policy"] as Dictionary)["resource_cost"] = 0
	await _validate_attack(combat_loadout, 62.0, &"melee", &"traveler_sword_slash")
	await _validate_attack(combat_loadout, 280.0, &"ranged", &"hunting_bow_shot")
	_finish()


func _validate_attack(
	combat_loadout: Dictionary,
	target_distance: float,
	expected_mode: StringName,
	expected_attack_id: StringName
) -> void:
	var world := Node2D.new()
	world.name = "SharedHeroCombatValidationWorld"
	root.add_child(world)
	var player_scene := load(PLAYER_SCENE) as PackedScene
	var enemy_scene := load(ENEMY_SCENE) as PackedScene
	if player_scene == null or enemy_scene == null:
		_failures.append("Combat validation scenes could not be loaded.")
		world.queue_free()
		await process_frame
		return
	var player := player_scene.instantiate() as CharacterBody2D
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	world.add_child(player)
	world.add_child(enemy)
	player.global_position = Vector2(240.0, 320.0)
	enemy.global_position = player.global_position + Vector2(target_distance, 0.0)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.make_current()
		camera.reset_smoothing()
	await process_frame
	var combat: Variant = player.get_node("CombatController")
	combat.configure_shared_hero(combat_loadout, root.get_node("/root/RunState").get_effective_stats())
	player.facing = 1
	var target_snapshot: Dictionary = combat.call("_build_context_target_snapshot")
	_expect(
		not (target_snapshot.get("targets", []) as Array).is_empty(),
		"Live target snapshot was empty at distance %.1f (enemy hp %s, screen %s)." % [
			target_distance,
			enemy.get("current_health"),
			combat.call("_is_world_point_on_screen", enemy.global_position),
		]
	)

	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	await physics_frame
	var snapshot: Dictionary = combat.get_state_snapshot()
	var intent: Dictionary = snapshot.get("committed_intent", {})
	_expect(
		StringName(intent.get("mode", &"")) == expected_mode,
		"Context attack chose the wrong mode: %s targets=%s" % [
			intent,
			{
				"target_snapshot": combat.call("_build_context_target_snapshot"),
				"viewport": player.get_viewport_rect(),
				"camera_center": camera.get_screen_center_position() if camera != null else Vector2.ZERO,
			},
		]
	)
	_expect(combat.current_attack != null, "Context attack did not start.")
	if combat.current_attack != null:
		_expect(combat.current_attack.id == expected_attack_id, "Context attack chose the wrong definition.")
	player.facing = -1
	# Selection is now committed; remove the target so this validator cannot mutate condition.
	enemy.queue_free()

	var activated: bool = await _wait_for_activation(world, combat, expected_mode)
	_expect(activated, "Context attack did not activate before its timing deadline.")
	var hitbox: Variant = player.get_node("AttackHitbox")
	var presenter: Variant = player.get_node("AttackPresenter")
	if expected_mode == &"melee":
		_expect(hitbox.active, "Melee intent did not activate the shared hitbox.")
		_expect(hitbox.position.x > 0.0, "Melee hitbox changed direction after intent commit.")
		if combat.current_attack != null:
			var contract: Dictionary = presenter.get_visual_contract()
			var expected_bounds: Rect2 = Rect2(
				-combat.current_attack.hitbox_size * 0.5,
				combat.current_attack.hitbox_size
			)
			_expect(_rect_approx(contract["contact_bounds"], expected_bounds), "Melee preview differs from hitbox data.")
	else:
		var projectile: Variant = _first_projectile(world)
		_expect(projectile != null, "Ranged intent did not spawn a projectile.")
		if projectile != null:
			var intent_direction: Vector2 = intent.get("direction", Vector2.RIGHT)
			_expect(
				projectile.velocity.normalized().dot(intent_direction.normalized()) >= 0.999,
				"Projectile direction differs from committed intent."
			)
			var presentation: Dictionary = presenter.get_visual_contract()
			var presented_direction: Vector2 = presentation.get(
				"aim_direction", Vector2.ZERO
			)
			_expect(
				presented_direction.dot(intent_direction.normalized()) >= 0.999,
				"Ranged presentation differs from committed intent."
			)
			var presentation_origin: Vector2 = presentation.get("origin", Vector2.ZERO)
			var expected_position := (
				intent_direction.normalized() * absf(presentation_origin.x)
				+ Vector2(0.0, presentation_origin.y)
			)
			_expect(
				(presentation.get("motion_position", Vector2.ZERO) as Vector2).is_equal_approx(
					expected_position
				),
				"Ranged presentation origin differs from committed intent."
			)

	Input.action_release("attack")
	world.queue_free()
	await process_frame


func _wait_for_activation(
	world: Node,
	combat: Variant,
	mode: StringName
) -> bool:
	var elapsed := 0.0
	while elapsed <= 0.5:
		if mode == &"melee" and bool(combat.attack_hitbox.active):
			return true
		if mode == &"ranged" and _first_projectile(world) != null:
			return true
		await physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
	return false


func _first_projectile(node: Node) -> Variant:
	if node.get_script() != null and node.get_script().resource_path.ends_with("PlayerAttackProjectile.gd"):
		return node
	for child in node.get_children():
		var result: Variant = _first_projectile(child)
		if result != null:
			return result
	return null


func _rect_approx(actual: Rect2, expected: Rect2, tolerance: float = 0.01) -> bool:
	return (
		actual.position.distance_to(expected.position) <= tolerance
		and actual.size.distance_to(expected.size) <= tolerance
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SHARED_HERO_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
