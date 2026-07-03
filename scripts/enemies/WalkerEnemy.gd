class_name WalkerEnemy
extends EnemyBase

@export var patrol_half_width: float = 110.0
@export var move_speed: float = 70.0

var direction: int = -1
var left_limit: float
var right_limit: float


func _ready() -> void:
	super._ready()
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	if _visual != null:
		_visual.color = Color(0.92, 0.38, 0.26, 1.0)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer <= 0.0:
		velocity.x = float(direction) * move_speed
	super._physics_process(delta)

	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1

	if _visual != null:
		_visual.scale.x = float(direction)
