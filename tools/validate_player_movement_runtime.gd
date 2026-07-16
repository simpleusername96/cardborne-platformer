extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"

var _failures: Array[String] = []
var _world: Node2D
var _player: Variant
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("/root/Game")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(game != null and _run_state != null, "movement fixture needs production autoloads")
	if game == null or _run_state == null:
		_finish()
		return
	game.ensure_input_map()
	_run_state.call("start_new_run", 0)

	_world = Node2D.new()
	_world.name = "MovementFixture"
	root.add_child(_world)
	_add_static_rect("Floor", Vector2(0.0, 112.0), Vector2(900.0, 24.0))
	var packed_player := load(PLAYER_SCENE) as PackedScene
	_expect(packed_player != null, "movement fixture should load player scene")
	if packed_player == null:
		_finish()
		return
	_player = packed_player.instantiate()
	_expect(_player != null, "player scene should instantiate for movement validation")
	if _player == null:
		_finish()
		return
	_world.add_child(_player)
	_player.position = Vector2(0.0, 100.0)
	await _physics_steps(4)

	await _validate_crouch_clearance()
	await _validate_jump_and_double_jump()
	await _validate_jump_comfort_measurements()
	await _validate_dash()
	await _validate_bidirectional_climb()
	_world.queue_free()
	await process_frame
	_finish()


func _validate_crouch_clearance() -> void:
	var body_shape := _player.get_node("CollisionShape2D") as CollisionShape2D
	var standing_height := (body_shape.shape as RectangleShape2D).size.y
	Input.action_press("crouch")
	await _physics_steps(2)
	var crouching_height := (body_shape.shape as RectangleShape2D).size.y
	_expect(_player.is_crouching, "crouch input should enter crouching state")
	_expect(crouching_height < standing_height, "crouch should shorten the collision body")

	var ceiling := _add_static_rect("LowCeiling", Vector2(0.0, 55.0), Vector2(180.0, 10.0))
	await _physics_steps(2)
	Input.action_release("crouch")
	await _physics_steps(2)
	_expect(_player.is_crouching, "player should remain crouched while standing shape is blocked")
	_expect(
		is_equal_approx((body_shape.shape as RectangleShape2D).size.y, crouching_height),
		"blocked stand attempt should preserve crouch collision"
	)

	ceiling.collision_layer = 0
	var ceiling_shape := ceiling.get_node("CollisionShape2D") as CollisionShape2D
	ceiling_shape.set_deferred("disabled", true)
	ceiling.queue_free()
	await _physics_steps(2)
	_expect(not _player.is_crouching, "player should stand after headroom becomes clear")
	_expect(
		is_equal_approx((body_shape.shape as RectangleShape2D).size.y, standing_height),
		"standing should restore collision height"
	)


func _validate_jump_and_double_jump() -> void:
	_player.position = Vector2(0.0, 100.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(3)
	Input.action_press("jump")
	await _physics_steps(2)
	Input.action_release("jump")
	_expect(_player.velocity.y < 0.0, "ground jump should apply upward velocity")
	var jumps_before: int = int(_player.extra_jumps_left)
	Input.action_press("jump")
	await _physics_steps(2)
	Input.action_release("jump")
	_expect(_player.extra_jumps_left == jumps_before - 1, "air jump should consume one extra jump")
	_expect(_player.velocity.y < 0.0, "double jump should restore upward velocity")


func _validate_dash() -> void:
	_player.position = Vector2(0.0, 100.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(3)
	Input.action_press("dash")
	await _physics_steps(2)
	Input.action_release("dash")
	_expect(_player.is_dashing, "dash input should enter dash state")
	_expect(
		absf(_player.velocity.x)
		>= float(_run_state.call("get_effective_stat", "dash_speed", 500.0)) * 0.95,
		"dash should use the resolved build speed"
	)


func _validate_jump_comfort_measurements() -> void:
	var short_jump := await _measure_single_jump("short", 4, 0)
	var full_jump := await _measure_single_jump("full", 32, 0)
	var late_approach := await _measure_single_jump("late_approach", 32, 10)
	_expect(
		float(full_jump["distance"]) > float(short_jump["distance"]) + 20.0,
		"held jump should preserve meaningful reach over early release"
	)
	_expect(
		float(late_approach["distance"]) >= float(full_jump["distance"]),
		"an imperfect late takeoff should remain measurable without exceeding fixture bounds"
	)
	print(
		"PLAYER_JUMP_COMFORT short=%.1fx%.1f full=%.1fx%.1f late=%.1fx%.1f margin=%.1f"
		% [
			short_jump["distance"],
			short_jump["height"],
			full_jump["distance"],
			full_jump["height"],
			late_approach["distance"],
			late_approach["height"],
			float(full_jump["distance"]) - float(short_jump["distance"]),
		]
	)


func _measure_single_jump(
	label: String,
	release_frame: int,
	approach_frames: int
) -> Dictionary:
	_player.respawn_at(Vector2(-300.0, 100.0), 0.0)
	await _physics_steps(3)
	Input.action_press("move_right")
	await _physics_steps(approach_frames)
	var takeoff_x: float = _player.global_position.x
	var takeoff_y: float = _player.global_position.y
	Input.action_press("jump")
	var airborne := false
	var landing_frame := -1
	var minimum_y: float = _player.global_position.y
	for frame in 150:
		if frame == release_frame:
			Input.action_release("jump")
		await physics_frame
		await process_frame
		minimum_y = minf(minimum_y, _player.global_position.y)
		if not _player.is_on_floor():
			airborne = true
		elif airborne:
			landing_frame = frame
			break
	Input.action_release("jump")
	Input.action_release("move_right")
	_expect(airborne and landing_frame > 0, "%s jump measurement should land" % label)
	return {
		"label": label,
		"distance": _player.global_position.x - takeoff_x,
		"height": takeoff_y - minimum_y,
		"landing_frame": landing_frame,
	}


func _validate_bidirectional_climb() -> void:
	var platform := _add_one_way_rect(
		"RopeTop",
		Vector2(600.0, 100.0),
		Vector2(220.0, 12.0)
	)
	_add_static_rect("RopeFloor", Vector2(600.0, 240.0), Vector2(260.0, 20.0))
	var rope := Climbable.new()
	rope.name = "BidirectionalRope"
	rope.position = Vector2(600.0, 160.0)
	rope.climbable_size = Vector2(42.0, 180.0)
	_world.add_child(rope)
	_player.respawn_at(Vector2(618.0, 230.0), 0.0)
	await _physics_steps(4)
	Input.action_press("climb_up")
	await _physics_steps(8)
	_expect(_player.is_climbing, "lower rope input should enter climb mode")
	_expect(
		absf(_player.global_position.x - rope.global_position.x) <= 3.0,
		"climb mode should center the player on the rope axis"
	)
	_expect(
		not _player.get_collision_mask_value(2),
		"climbing should temporarily ignore one-way platform collision"
	)
	await _physics_steps(52)
	Input.action_release("climb_up")
	await _physics_steps(8)
	_expect(
		_player.global_position.y <= 98.0,
		"upward climb should cross the one-way top and reach its landing"
	)
	_expect(
		_player.get_collision_mask_value(2),
		"upper dismount should restore the one-way collision mask"
	)

	_player.position = Vector2(600.0, 94.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(4)
	Input.action_press("climb_down")
	await _physics_steps(8)
	_expect(_player.is_climbing, "top rope input should enter downward climb")
	_expect(
		not _player.get_collision_mask_value(2),
		"downward climb should pass through the one-way top"
	)
	await _physics_steps(28)
	_expect(
		_player.global_position.y > 112.0,
		"downward climb should move below the one-way platform"
	)
	Input.action_release("climb_down")
	Input.action_press("jump")
	await _physics_steps(2)
	Input.action_release("jump")
	await _physics_steps(2)
	_expect(not _player.is_climbing, "jump should dismount the rope")
	_expect(
		_player.get_collision_mask_value(2),
		"jump dismount should restore the one-way collision mask"
	)
	_player.respawn_at(Vector2(720.0, 230.0), 0.0)
	await _physics_steps(3)
	_player.global_position = Vector2(600.0, 180.0)
	_player.velocity = Vector2.ZERO
	await _physics_steps(4)
	Input.action_press("climb_down")
	await _physics_steps(4)
	Input.action_release("climb_down")
	_expect(_player.is_climbing, "dash fixture should begin on the rope")
	Input.action_press("dash")
	await _physics_steps(2)
	Input.action_release("dash")
	_expect(not _player.is_climbing, "dash should dismount the rope")
	_expect(
		_player.get_collision_mask_value(2),
		"dash dismount should restore the one-way collision mask"
	)
	_player.respawn_at(Vector2(600.0, 230.0), 0.0)
	_expect(
		_player.get_collision_mask_value(2),
		"respawn should restore the one-way collision mask"
	)
	platform.queue_free()


func _add_static_rect(node_name: String, center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)
	return body


func _add_one_way_rect(
	node_name: String,
	center: Vector2,
	size: Vector2
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 2
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.one_way_collision = true
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)
	return body


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	Input.action_release("crouch")
	Input.action_release("jump")
	Input.action_release("dash")
	Input.action_release("climb_up")
	Input.action_release("climb_down")
	Input.action_release("move_right")
	if _failures.is_empty():
		print("PLAYER_MOVEMENT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
