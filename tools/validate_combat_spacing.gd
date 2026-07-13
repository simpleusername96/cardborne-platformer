extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const WALKER_SCRIPT_PATH := "res://scripts/enemies/WalkerEnemy.gd"
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")

const REPRESENTATIVE_WALKER_SPEED := 82.0
const MIN_PRE_CONTACT_MARGIN := 24.0
const EXPECTED_STEP_IN_DISTANCE := 12.0
const EXPECTED_PROJECTILE_RELEASE_OVERLAP := 2.0
const FULL_FLOOR_CENTER := Vector2(0.0, 112.0)
const FULL_FLOOR_SIZE := Vector2(1600.0, 24.0)

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _run_state: Node
var _enemy_hits: int = 0
var _health_at_first_hit: int = -1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("/root/Game")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(game != null and _run_state != null, "combat spacing fixture needs production autoloads")
	if game == null or _run_state == null:
		_finish()
		return
	game.call("ensure_input_map")

	await _validate_footprint_edges()
	await _validate_hit_before_contact()
	await _validate_assassin_step_constraints()
	await _validate_projectile_release_contract()
	await _validate_presentation_parity()
	_finish()


func _validate_footprint_edges() -> void:
	for profile_index in [0, 2]:
		var profile := CHARACTER_CATALOG.profiles[profile_index] as CharacterProfile
		var definition: AttackDefinition = profile.combat_kit.basic_attack
		for direction in [-1, 1]:
			await _create_fixture(profile_index, FULL_FLOOR_CENTER, FULL_FLOOR_SIZE)
			_player.facing = direction
			var probe: Variant = _spawn_enemy_base(Vector2(0.0, 100.0), false)
			var enemy_half_width: float = _shape_half_width(probe, "Hurtbox")
			var target_center_reach: float = (
				absf(definition.hitbox_offset.x)
				+ definition.hitbox_size.x * 0.5
				+ enemy_half_width
			)
			probe.global_position.x = float(direction) * (target_center_reach - 1.0)
			var outside: Variant = _spawn_enemy_base(
				Vector2(float(direction) * (target_center_reach + 2.0), 100.0),
				false
			)
			var center: Vector2 = _player.global_position + Vector2(
				absf(definition.hitbox_offset.x) * float(direction),
				definition.hitbox_offset.y
			)
			var targets: Array[Node] = _player.combat_controller.find_targets_in_box(
				center,
				definition.hitbox_size * 0.5,
				16
			)
			_expect(
				targets.has(probe),
				"%s facing %d should include a 1 px footprint-edge overlap"
				% [definition.id, direction]
			)
			_expect(
				not targets.has(outside),
				"%s facing %d should reject a target 2 px beyond its footprint"
				% [definition.id, direction]
			)
			await _clear_fixture()


func _validate_hit_before_contact() -> void:
	var scenarios := [
		{"profile": 0, "gap": 100.0, "hold": 0, "minimum_hits": 1},
		{"profile": 2, "gap": 95.0, "hold": 24, "minimum_hits": 2},
		{"profile": 1, "gap": 77.0, "hold": 0, "minimum_hits": 1},
	]
	for scenario in scenarios:
		var profile_index := int(scenario["profile"])
		var profile := CHARACTER_CATALOG.profiles[profile_index] as CharacterProfile
		var definition: AttackDefinition = profile.combat_kit.basic_attack
		for direction in [-1, 1]:
			await _create_fixture(profile_index, FULL_FLOOR_CENTER, FULL_FLOOR_SIZE)
			_player.facing = direction
			var enemy: Variant = _spawn_walker(
				Vector2(float(direction) * float(scenario["gap"]), 100.0),
				-direction
			)
			await _physics_steps(2)
			var initial_health: int = int(_run_state.get("current_health"))
			_print_and_validate_margin(profile, definition, enemy)
			var start_x: float = _player.global_position.x
			_enemy_hits = 0
			_health_at_first_hit = -1
			enemy.damaged.connect(_on_spacing_enemy_damaged)
			if int(scenario["hold"]) > 0:
				Input.action_press("attack")
				await _physics_steps(int(scenario["hold"]))
				Input.action_release("attack")
			else:
				await _tap_action("attack")
			await _wait_for_action_end(80)
			_expect(
				_enemy_hits >= int(scenario["minimum_hits"]),
				"%s facing %d should land before contact at %.1f px"
				% [definition.id, direction, float(scenario["gap"])]
			)
			_expect(
				_health_at_first_hit == initial_health,
				"%s facing %d should hit before enemy contact damages the player"
				% [definition.id, direction]
			)
			if definition.id == &"assassin_twin_cut":
				var step_distance: float = (_player.global_position.x - start_x) * float(direction)
				_expect(
					absf(step_distance - EXPECTED_STEP_IN_DISTANCE) <= 0.5,
					"Twin Cut facing %d should use its bounded 12 px step (%.2f)"
					% [direction, step_distance]
				)
			await _clear_fixture()


func _validate_assassin_step_constraints() -> void:
	await _create_fixture(2, FULL_FLOOR_CENTER, FULL_FLOOR_SIZE)
	_player.facing = 1
	_add_static_rect(Vector2(28.0, 45.0), Vector2(20.0, 110.0), "StepWall")
	await _physics_steps(2)
	var wall_start: float = _player.global_position.x
	await _tap_action("attack")
	await _physics_steps(8)
	var wall_step: float = _player.global_position.x - wall_start
	_expect(wall_step >= -0.05 and wall_step <= 4.5, "Twin Cut step should stop before a wall")
	await _clear_fixture()

	# The player's center is supported, but a full left step would leave the shelf.
	await _create_fixture(2, Vector2(100.0, 112.0), Vector2(212.0, 24.0))
	_player.facing = -1
	await _physics_steps(2)
	_expect(_player.is_on_floor(), "ledge step fixture should begin supported")
	var ledge_start: float = _player.global_position.x
	await _tap_action("attack")
	await _physics_steps(8)
	var ledge_step: float = absf(_player.global_position.x - ledge_start)
	_expect(ledge_step <= 0.5, "Twin Cut step should cancel before an unsupported ledge")
	await _clear_fixture()


func _validate_projectile_release_contract() -> void:
	var profile := CHARACTER_CATALOG.profiles[1] as CharacterProfile
	var definition: AttackDefinition = profile.combat_kit.basic_attack
	_expect(is_equal_approx(definition.projectile_range, 800.0), "Quick Shot max range must remain 800 px")
	for direction in [-1, 1]:
		await _create_fixture(1, FULL_FLOOR_CENTER, FULL_FLOOR_SIZE)
		_player.facing = direction
		var projectile: PlayerAttackProjectile = _player.combat_controller.spawn_projectile(
			definition,
			direction
		)
		_expect(projectile != null, "Quick Shot release fixture should spawn a projectile")
		if projectile != null:
			var release_distance: float = (
				projectile.global_position.x - _player.global_position.x
			) * float(direction)
			var player_half_width: float = _shape_half_width(_player, "Hurtbox")
			var expected_release: float = maxf(
				absf(definition.hitbox_offset.x),
				player_half_width
				+ projectile.projectile_size.x * 0.5
				- EXPECTED_PROJECTILE_RELEASE_OVERLAP
			)
			_expect(
				is_equal_approx(release_distance, expected_release),
				"Quick Shot facing %d release should overlap the player front by 2 px"
				% direction
			)
			_expect(
				is_equal_approx(projectile.max_distance, definition.projectile_range),
				"Quick Shot release tuning must not increase max range"
			)
			var collision := _first_rectangle_collision(projectile)
			var visual := projectile.get_node_or_null("Visual") as Polygon2D
			var actual_size := Vector2.ZERO
			if collision != null and collision.shape is RectangleShape2D:
				actual_size = (collision.shape as RectangleShape2D).size
			_expect(
				actual_size.is_equal_approx(projectile.projectile_size),
				"Quick Shot projectile collision %s should equal declared size %s"
				% [actual_size, projectile.projectile_size]
			)
			if visual != null:
				var collision_bounds := Rect2(
					-projectile.projectile_size * 0.5,
					projectile.projectile_size
				)
				_expect(
					_rect_contains(collision_bounds, _polygon_bounds(visual.polygon)),
					"Quick Shot projectile visual should stay inside collision"
				)
		await _clear_fixture()


func _validate_presentation_parity() -> void:
	for profile_index in [0, 2]:
		await _create_fixture(profile_index, FULL_FLOOR_CENTER, FULL_FLOOR_SIZE)
		var profile := CHARACTER_CATALOG.profiles[profile_index] as CharacterProfile
		var definition: AttackDefinition = profile.combat_kit.basic_attack
		var presenter := _player.get_node("AttackPresenter") as PlayerAttackPresenter
		for direction in [-1, 1]:
			presenter.begin(definition, direction, definition.hitbox_offset)
			if definition.id == &"assassin_twin_cut":
				presenter.show_runtime_pulse(2)
			for progress in [0.0, 0.25, 0.5, 0.75, 1.0]:
				presenter.update(
					definition,
					&"active",
					definition.active_time * (1.0 - float(progress)),
					definition.active_time,
					direction
				)
				var contract := presenter.get_visual_contract()
				var contact_bounds := Rect2(-definition.hitbox_size * 0.5, definition.hitbox_size)
				_expect(
					_rect_approx(contract["contact_bounds"], contact_bounds),
					"%s contact visual should equal collision in facing %d"
					% [definition.id, direction]
				)
				_expect(
					_rect_contains(contact_bounds, contract["transformed_motion_bounds"]),
					"%s motion should stay inside collision in facing %d at %.2f"
					% [definition.id, direction, float(progress)]
				)
		await _clear_fixture()


func _print_and_validate_margin(
	profile: CharacterProfile,
	definition: AttackDefinition,
	enemy: Variant
) -> void:
	var player_half_width := _shape_half_width(_player, "Hurtbox")
	var enemy_hurt_half_width := _shape_half_width(enemy, "Hurtbox")
	var enemy_contact_half_width := _shape_half_width(enemy, "ContactHitbox")
	var contact_gap := player_half_width + enemy_contact_half_width
	var startup_approach := REPRESENTATIVE_WALKER_SPEED * definition.startup_time
	var target_center_reach: float
	var step_distance := 0.0
	if definition.projectile_speed > 0.0:
		var projectile_size: Vector2 = profile.attack_projectile_size
		var release_distance := maxf(
			absf(definition.hitbox_offset.x),
			player_half_width
			+ projectile_size.x * 0.5
			- EXPECTED_PROJECTILE_RELEASE_OVERLAP
		)
		target_center_reach = release_distance + projectile_size.x * 0.5 + enemy_hurt_half_width
	else:
		target_center_reach = (
			absf(definition.hitbox_offset.x)
			+ definition.hitbox_size.x * 0.5
			+ enemy_hurt_half_width
		)
		step_distance = EXPECTED_STEP_IN_DISTANCE if definition.tags.has(&"step_in") else 0.0
	var static_margin := target_center_reach - startup_approach - contact_gap
	var effective_margin := static_margin + step_distance
	print(
		(
			"COMBAT_SPACING_METRIC id=%s reach=%.2f startup_approach=%.2f "
			+ "contact_gap=%.2f static_margin=%.2f step=%.2f effective_margin=%.2f"
		) % [
			definition.id,
			target_center_reach,
			startup_approach,
			contact_gap,
			static_margin,
			step_distance,
			effective_margin,
		]
	)
	_expect(
		static_margin >= MIN_PRE_CONTACT_MARGIN,
		"%s needs at least %.1f px pre-contact margin, got %.2f"
		% [definition.id, MIN_PRE_CONTACT_MARGIN, static_margin]
	)


func _create_fixture(profile_index: int, floor_center: Vector2, floor_size: Vector2) -> void:
	_expect(_run_state.call("start_new_run", profile_index, 93000 + profile_index), "fixture run should start")
	_world = Node2D.new()
	_world.name = "CombatSpacingFixture"
	root.add_child(_world)
	_add_static_rect(floor_center, floor_size, "Floor")
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(packed_player != null, "combat spacing fixture should load Player.tscn")
	if packed_player == null:
		return
	_player = packed_player.instantiate()
	_expect(_player != null, "combat spacing fixture should instantiate Player")
	if _player == null:
		return
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(3)
	var profile := CHARACTER_CATALOG.profiles[profile_index] as CharacterProfile
	_player.combat_controller.configure(profile, profile.to_stats_dictionary(), [])
	_player.velocity = Vector2.ZERO


func _spawn_enemy_base(position: Vector2, contact_active: bool) -> Variant:
	var enemy_script := load(ENEMY_SCRIPT_PATH) as Script
	_expect(enemy_script != null, "combat spacing fixture should load EnemyBase")
	if enemy_script == null:
		return null
	var enemy: Variant = enemy_script.new()
	enemy.position = position
	enemy.max_health = 20
	enemy.stagger_capacity = 999
	enemy.hit_knockback_multiplier = 0.0
	enemy.auto_reset_on_defeat = false
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
	if contact != null:
		contact.set_active(contact_active)
	return enemy


func _spawn_walker(position: Vector2, direction: int) -> Variant:
	var walker_script := load(WALKER_SCRIPT_PATH) as Script
	_expect(walker_script != null, "combat spacing fixture should load WalkerEnemy")
	if walker_script == null:
		return null
	var enemy: Variant = walker_script.new()
	enemy.position = position
	enemy.direction = direction
	enemy.move_speed = REPRESENTATIVE_WALKER_SPEED
	enemy.patrol_half_width = 400.0
	enemy.max_health = 20
	enemy.stagger_capacity = 999
	enemy.hit_knockback_multiplier = 0.0
	enemy.auto_reset_on_defeat = false
	_world.add_child(enemy)
	return enemy


func _shape_half_width(owner: Node, container_path: String) -> float:
	var container := owner.get_node_or_null(container_path)
	var collision := _first_rectangle_collision(container)
	if collision == null:
		return 0.0
	return (collision.shape as RectangleShape2D).size.x * 0.5


func _first_rectangle_collision(owner: Node) -> CollisionShape2D:
	if owner == null:
		return null
	for child in owner.find_children("*", "CollisionShape2D", true, false):
		var collision := child as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			return collision
	return null


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await physics_frame
	await process_frame
	Input.action_release(action_name)


func _wait_for_action_end(max_steps: int) -> void:
	for _step in max_steps:
		if _player.combat_controller.current_attack == null:
			return
		await physics_frame
		await process_frame
	_failures.append("combat action did not finish within %d physics steps" % max_steps)


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _add_static_rect(center: Vector2, size: Vector2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)


func _on_spacing_enemy_damaged(_enemy: Variant, _damage_info: DamageInfo) -> void:
	_enemy_hits += 1
	if _health_at_first_hit < 0:
		_health_at_first_hit = int(_run_state.get("current_health"))


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for index in range(1, points.size()):
		bounds = bounds.expand(points[index])
	return bounds


func _rect_approx(actual: Rect2, expected: Rect2, tolerance: float = 0.01) -> bool:
	return (
		actual.position.distance_to(expected.position) <= tolerance
		and actual.size.distance_to(expected.size) <= tolerance
	)


func _rect_contains(outer: Rect2, inner: Rect2, tolerance: float = 0.05) -> bool:
	return (
		inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance
	)


func _clear_fixture() -> void:
	Input.action_release("attack")
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	await process_frame
	_world = null
	_player = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	Input.action_release("attack")
	if _failures.is_empty():
		print("COMBAT_SPACING_VALIDATION_OK scenarios=6 facings=2 constraints=2")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
