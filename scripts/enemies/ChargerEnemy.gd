class_name ChargerEnemy
extends EnemyBase

@export var patrol_half_width: float = 130.0
@export var patrol_speed: float = 55.0
@export var warning_time: float = 0.48
@export var charge_speed: float = 360.0
@export var charge_time: float = 0.52
@export var recovery_time: float = 0.42

var direction: int = -1
var left_limit: float
var right_limit: float
var _state: String = "patrol"
var _state_timer: float = 1.0


func _ready() -> void:
	super._ready()
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_base_visual_color = Color(0.94, 0.55, 0.22, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer > 0.0:
		super._physics_process(delta)
		return

	_state_timer -= delta
	match _state:
		"patrol":
			_update_patrol(delta)
		"warning":
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_set_state("charge", charge_time)
		"charge":
			velocity.x = float(direction) * charge_speed
			if _state_timer <= 0.0:
				_set_state("recovery", recovery_time)
		"recovery":
			velocity.x = move_toward(velocity.x, 0.0, charge_speed * delta * 3.0)
			if _state_timer <= 0.0:
				direction *= -1
				_set_state("patrol", 1.25)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	direction = -1
	_set_state("patrol", 1.0)


func _update_patrol(_delta: float) -> void:
	velocity.x = float(direction) * patrol_speed
	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1
	if _state_timer <= 0.0:
		_set_state("warning", warning_time)


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if _state == "warning":
		_visual.color = Color(1.0, 0.86, 0.26, 1.0)
	elif _state == "charge":
		_visual.color = Color(1.0, 0.22, 0.16, 1.0)
	else:
		_visual.color = _base_visual_color
