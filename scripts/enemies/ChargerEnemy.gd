class_name ChargerEnemy
extends EnemyBase

@export var patrol_half_width: float = 130.0
@export var patrol_speed: float = 55.0
@export var warning_time: float = 0.48
@export var charge_speed: float = 360.0
@export var charge_time: float = 0.52
@export var recovery_time: float = 0.42
@export var detection_range: float = 680.0
@export var detection_height: float = 96.0

var direction: int = -1
var left_limit: float
var right_limit: float
var _state: String = "patrol"
var _state_timer: float = 1.0
var _lane_warning: Line2D


func _ready() -> void:
	super._ready()
	if resolved_spec != null:
		warning_time = resolved_spec.warning_time
		charge_speed = resolved_spec.charge_speed
		charge_time = resolved_spec.active_time
		recovery_time = resolved_spec.recovery_time
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_base_visual_color = Color(0.94, 0.55, 0.22, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color
	_lane_warning = _ensure_lane_warning()


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer > 0.0 or is_staggered():
		super._physics_process(delta)
		_update_visual()
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
			if _state_timer <= 0.0 or is_on_wall():
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
		if _can_start_charge():
			_lock_direction_to_player()
			_set_state("warning", warning_time)
		else:
			_state_timer = 0.25


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if is_staggered():
		_visual.color = Color(0.36, 0.88, 0.92, 1.0)
	elif _state == "warning":
		_visual.color = Color(1.0, 0.86, 0.26, 1.0)
	elif _state == "charge":
		_visual.color = Color(1.0, 0.22, 0.16, 1.0)
	else:
		_visual.color = _base_visual_color
	if _lane_warning != null:
		_lane_warning.visible = _state == "warning"
		_lane_warning.scale.x = float(direction)


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["recovery"] = _state == "recovery"
	return snapshot


func _can_start_charge() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset := player.global_position - global_position
	return absf(offset.x) <= detection_range and absf(offset.y) <= detection_height


func _lock_direction_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or is_zero_approx(player.global_position.x - global_position.x):
		return
	direction = int(sign(player.global_position.x - global_position.x))


func _ensure_lane_warning() -> Line2D:
	var line := get_node_or_null("LaneWarning") as Line2D
	if line != null:
		return line
	line = Line2D.new()
	line.name = "LaneWarning"
	line.position = Vector2(0.0, -14.0)
	line.width = 6.0
	line.default_color = Color(1.0, 0.72, 0.18, 0.72)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(520.0, 0.0)])
	line.visible = false
	line.z_index = -1
	add_child(line)
	return line
