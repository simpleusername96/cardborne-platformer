class_name LeaperEnemy
extends EnemyBase

@export var activation_range: float = 360.0
@export var deactivation_range: float = 520.0
@export var windup_time: float = 0.35
@export var leap_time: float = 0.52
@export var recovery_time: float = 0.50
@export var leap_speed_x: float = 260.0
@export var leap_velocity_y: float = -430.0

var direction: int = -1
var _state: String = "idle"
var _state_timer: float = 0.0
var _target_x: float = 0.0


func _ready() -> void:
	super._ready()
	_base_visual_color = Color(0.74, 0.42, 0.92, 1.0)
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
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_try_start_windup()
		"windup":
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_start_leap()
		"leap":
			if _state_timer <= 0.0 or is_on_floor():
				_set_state("recovery", recovery_time)
		"recovery":
			velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
			if _state_timer <= 0.0:
				_set_state("idle", 0.0)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	_set_state("idle", 0.0)


func _try_start_windup() -> void:
	if not is_on_floor():
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return
	var distance := target.global_position.distance_to(global_position)
	if distance > activation_range or distance < 48.0:
		return
	_target_x = target.global_position.x
	direction = int(sign(_target_x - global_position.x))
	if direction == 0:
		direction = -1
	_set_state("windup", windup_time)


func _start_leap() -> void:
	var delta_x := clampf(_target_x - global_position.x, -leap_speed_x * leap_time, leap_speed_x * leap_time)
	direction = int(sign(delta_x)) if not is_zero_approx(delta_x) else direction
	velocity = Vector2(float(direction) * leap_speed_x, leap_velocity_y)
	_set_state("leap", leap_time)


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if _state == "windup":
		_visual.color = Color(1.0, 0.82, 0.24, 1.0)
	elif _state == "leap":
		_visual.color = Color(1.0, 0.38, 0.70, 1.0)
	elif _state == "recovery":
		_visual.color = Color(0.55, 0.48, 0.70, 1.0)
	else:
		_visual.color = _base_visual_color
