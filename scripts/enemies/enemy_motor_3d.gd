class_name EnemyMotor3D
extends RefCounted

const TARGET_REFRESH := 0.20
const STUCK_LIMIT := 1.5

var actor: EnemyActor3D
var agent: NavigationAgent3D
var refresh_remaining := 0.0
var stationary_remaining := 0.0
var last_position := Vector3.ZERO


func _init(owner_actor: EnemyActor3D, navigation_agent: NavigationAgent3D) -> void:
	actor = owner_actor
	agent = navigation_agent
	last_position = actor.global_position


func stop() -> void:
	actor.velocity = Vector3.ZERO


func move_toward(target: Vector3, speed: float, delta: float) -> void:
	refresh_remaining -= delta
	if refresh_remaining <= 0.0:
		agent.target_position = Vector3(target.x, actor.global_position.y, target.z)
		refresh_remaining = TARGET_REFRESH
	var next_point := agent.get_next_path_position()
	var direction := next_point - actor.global_position
	direction.y = 0.0
	if agent.is_navigation_finished() or direction.length_squared() <= 0.0025:
		actor.velocity = actor.velocity.move_toward(Vector3.ZERO, speed * 6.0 * delta)
	else:
		direction = direction.normalized()
		actor.velocity = actor.velocity.move_toward(direction * speed, speed * 8.0 * delta)
	actor.velocity.y = 0.0
	actor.move_and_slide()
	_track_stuck(delta)


func _track_stuck(delta: float) -> void:
	var displacement := Vector2(
		actor.global_position.x - last_position.x,
		actor.global_position.z - last_position.z
	).length()
	stationary_remaining = stationary_remaining + delta if displacement < 0.015 else 0.0
	if stationary_remaining >= STUCK_LIMIT:
		agent.target_position += Vector3(-agent.target_position.z, 0.0, agent.target_position.x).normalized() * 1.25
		refresh_remaining = TARGET_REFRESH
		stationary_remaining = 0.0
	last_position = actor.global_position
