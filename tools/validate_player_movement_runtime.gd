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
	await _validate_dash()
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
	if _failures.is_empty():
		print("PLAYER_MOVEMENT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
