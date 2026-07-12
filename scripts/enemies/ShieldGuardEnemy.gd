class_name ShieldGuardEnemy
extends EnemyBase

@export var patrol_half_width: float = 90.0
@export var move_speed: float = 45.0
@export var guard_time: float = 1.2
@export var attack_warning_time: float = 0.35
@export var attack_recovery_time: float = 0.55
@export var blocked_damage_status: String = "Shield blocked"

var direction: int = -1
var left_limit: float
var right_limit: float
var _state: String = "guard"
var _state_timer: float = 1.2


func _ready() -> void:
	super._ready()
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_base_visual_color = Color(0.58, 0.62, 0.72, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func receive_damage(damage_info: DamageInfo) -> void:
	if _state == "guard" and _damage_from_front(damage_info):
		SignalBus.status_message_changed.emit(blocked_damage_status)
		_flash_guard()
		return

	super.receive_damage(damage_info)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer > 0.0:
		super._physics_process(delta)
		return

	_state_timer -= delta
	match _state:
		"guard":
			velocity.x = float(direction) * move_speed * get_external_speed_scale()
			if _state_timer <= 0.0:
				_set_state("warning", attack_warning_time)
		"warning":
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_set_state("recovery", attack_recovery_time)
		"recovery":
			velocity.x = 0.0
			if _state_timer <= 0.0:
				direction *= -1
				_set_state("guard", guard_time)

	super._physics_process(delta)
	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	direction = -1
	_set_state("guard", guard_time)


func _damage_from_front(damage_info: DamageInfo) -> bool:
	if damage_info.source == null or not damage_info.source is Node2D:
		return false
	var source_node := damage_info.source as Node2D
	var source_side := int(sign(source_node.global_position.x - global_position.x))
	return int(source_side) == direction


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if _state == "warning":
		_visual.color = Color(1.0, 0.80, 0.28, 1.0)
	elif _state == "recovery":
		_visual.color = Color(0.45, 0.95, 0.75, 1.0)
	else:
		_visual.color = _base_visual_color


func _flash_guard() -> void:
	if _visual == null:
		return
	_visual.color = Color(0.72, 0.88, 1.0, 1.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_update_visual()
