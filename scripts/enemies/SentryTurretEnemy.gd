class_name SentryTurretEnemy
extends EnemyBase

@export var activation_range: float = 560.0
@export var deactivation_range: float = 720.0
@export var warning_time: float = 0.45
@export var fire_interval: float = 1.4
@export var projectile_speed: float = 300.0
@export var projectile_lifetime: float = 2.2
@export var max_active_projectiles: int = 2

var direction: int = -1
var _state: String = "idle"
var _state_timer: float = 0.6
var _active_projectiles: Array[EnemyProjectile] = []


func _ready() -> void:
	super._ready()
	_base_visual_color = Color(0.44, 0.76, 0.86, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_purge_projectile_list()
	if hit_stun_timer > 0.0:
		super._physics_process(delta)
		return

	velocity.x = 0.0
	_face_player_if_in_range()
	_state_timer -= delta
	match _state:
		"idle":
			if _player_in_range(activation_range) and _state_timer <= 0.0:
				_set_state("warning", warning_time)
		"warning":
			if not _player_in_range(deactivation_range):
				_set_state("idle", fire_interval)
			elif _state_timer <= 0.0:
				_fire_if_allowed()
				_set_state("idle", fire_interval)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	_clear_projectiles()
	super.reset_enemy()
	_set_state("idle", fire_interval)


func _face_player_if_in_range() -> void:
	var target := get_priority_target()
	if target == null or target.global_position.distance_to(global_position) > deactivation_range:
		return
	var offset := target.global_position.x - global_position.x
	if not is_zero_approx(offset):
		direction = int(sign(offset))


func _player_in_range(range_px: float) -> bool:
	var target := get_priority_target()
	return target != null and target.global_position.distance_to(global_position) <= range_px


func _fire_if_allowed() -> void:
	_purge_projectile_list()
	if _active_projectiles.size() >= max_active_projectiles:
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	var shot := EnemyProjectile.new()
	shot.name = "%sShot%d" % [name, Time.get_ticks_msec()]
	shot.damage_amount = contact_damage
	shot.knockback = Vector2(float(direction) * 220.0, -120.0)
	shot.lifetime = projectile_lifetime
	shot.velocity = Vector2(float(direction) * projectile_speed, 0.0)
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(float(direction) * 34.0, -28.0)
	_active_projectiles.append(shot)


func _purge_projectile_list() -> void:
	var live_projectiles: Array[EnemyProjectile] = []
	for projectile in _active_projectiles:
		if projectile != null and is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			live_projectiles.append(projectile)
	_active_projectiles = live_projectiles


func _clear_projectiles() -> void:
	for projectile in _active_projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()
	_active_projectiles.clear()


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if _state == "warning":
		_visual.color = Color(1.0, 0.88, 0.28, 1.0)
	else:
		_visual.color = _base_visual_color
