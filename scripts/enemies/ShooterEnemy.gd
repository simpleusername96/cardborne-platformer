class_name ShooterEnemy
extends EnemyBase

const STATE_IDLE := &"idle"
const STATE_AIMING := &"aiming"
const STATE_RECOVERY := &"recovery"
const INITIAL_AIM_DELAY := 0.2
const TARGET_RETRY_DELAY := 0.1
const MAX_PROJECTILE_LIFETIME := 5.0
const VIEWPORT_MARGIN := 48.0

@export var shoot_interval: float = 1.8
@export var warning_time: float = 0.38
@export var recovery_time: float = 0.45
@export var projectile_speed: float = 280.0
@export var projectile_range: float = 760.0
@export var max_active_projectiles: int = 2
@export var body_color: Color = Color(0.34, 0.62, 0.92, 1.0)
@export var recovery_color: Color = Color(0.42, 0.40, 0.58, 1.0)
@export var warning_color: Color = Color(1.0, 0.88, 0.24, 1.0)
@export var weapon_color: Color = Color(0.72, 0.84, 0.96, 1.0)
@export var projectile_color: Color = Color(1.0, 0.78, 0.18, 1.0)
@export var weapon_length: float = 28.0

var direction: int = -1
var _state: StringName = STATE_IDLE
var _state_timer: float = INITIAL_AIM_DELAY
var _locked_aim_direction: Vector2 = Vector2.LEFT
var _active_projectiles: Array[EnemyProjectile] = []
var _shots_fired: int = 0
var _aim_warning: Line2D
var _weapon_visual: Polygon2D


func _ready() -> void:
	super._ready()
	if resolved_spec != null:
		warning_time = resolved_spec.warning_time
		recovery_time = resolved_spec.recovery_time
		shoot_interval = resolved_spec.cadence_time
		projectile_speed = resolved_spec.projectile_speed
		projectile_range = resolved_spec.attack_range
		max_active_projectiles = resolved_spec.active_projectile_cap
	_base_visual_color = body_color
	_aim_warning = _ensure_aim_warning()
	_weapon_visual = _ensure_weapon_visual()
	_set_state(STATE_IDLE, INITIAL_AIM_DELAY)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_purge_projectile_list()
	if hit_stun_timer > 0.0 or is_staggered():
		if _state == STATE_AIMING:
			_set_state(STATE_RECOVERY, recovery_time)
		super._physics_process(delta)
		_update_visual()
		return

	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	_state_timer -= delta
	match _state:
		STATE_IDLE:
			_face_player()
			if _state_timer <= 0.0:
				if _lock_aim_at_player():
					_set_state(STATE_AIMING, warning_time)
				else:
					_state_timer = TARGET_RETRY_DELAY
		STATE_AIMING:
			if _state_timer <= 0.0:
				_spawn_projectile()
				_set_state(STATE_RECOVERY, recovery_time)
		STATE_RECOVERY:
			if _state_timer <= 0.0:
				_set_state(STATE_IDLE, _cooldown_time())

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	_clear_projectiles()
	super.reset_enemy()
	direction = -1
	_locked_aim_direction = Vector2.LEFT
	_shots_fired = 0
	_set_state(STATE_IDLE, INITIAL_AIM_DELAY)


func _defeat() -> void:
	_clear_projectiles()
	super._defeat()


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["aiming"] = _state == STATE_AIMING
	snapshot["recovery"] = _state == STATE_RECOVERY
	return snapshot


func _face_player() -> void:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null or not is_target_within_encounter(target):
		return
	var offset := target.global_position.x - global_position.x
	if not is_zero_approx(offset):
		direction = int(sign(offset))


func _lock_aim_at_player() -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null or not _can_begin_aim(target):
		return false
	var offset := target.global_position - (global_position + Vector2(0.0, -28.0))
	if offset.is_zero_approx():
		offset = Vector2(float(direction), 0.0)
	_locked_aim_direction = offset.normalized()
	if not is_zero_approx(_locked_aim_direction.x):
		direction = int(sign(_locked_aim_direction.x))
	_update_aim_warning_geometry()
	return true


func _can_begin_aim(target: Node2D) -> bool:
	if not is_target_within_encounter(target):
		return false
	if projectile_range <= 0.0 or projectile_speed <= 0.0:
		return false
	if target.global_position.distance_to(global_position) > projectile_range:
		return false
	var viewport_position := get_viewport().get_canvas_transform() * global_position
	return get_viewport().get_visible_rect().grow(VIEWPORT_MARGIN).has_point(viewport_position)


func _spawn_projectile() -> void:
	_purge_projectile_list()
	if not is_player_within_encounter():
		return
	if _active_projectiles.size() >= max_active_projectiles:
		return
	var lifetime := _projectile_lifetime()
	var parent_node := get_parent()
	if parent_node == null or lifetime <= 0.0:
		return

	_shots_fired += 1
	var shot := EnemyProjectile.new()
	shot.name = "%sProjectile%d" % [name, _shots_fired]
	shot.damage_amount = contact_damage
	shot.knockback = Vector2(float(direction) * 220.0, -120.0)
	shot.lifetime = lifetime
	shot.velocity = _locked_aim_direction * projectile_speed
	shot.projectile_size = Vector2(30.0, 12.0)
	shot.projectile_color = projectile_color
	shot.target_hit.connect(_on_projectile_target_hit.bind(shot))
	parent_node.add_child(shot)
	shot.global_position = (
		global_position + Vector2(0.0, -28.0) + _locked_aim_direction * 28.0
	)
	shot.rotation = _locked_aim_direction.angle()
	_active_projectiles.append(shot)


func _on_projectile_target_hit(
	_area: Area2D,
	_damage_info: DamageInfo,
	projectile: EnemyProjectile
) -> void:
	if projectile != null and is_instance_valid(projectile):
		projectile.set_active(false)
		projectile.queue_free()


func _projectile_lifetime() -> float:
	if projectile_range <= 0.0 or projectile_speed <= 0.0:
		return 0.0
	return minf(projectile_range / projectile_speed, MAX_PROJECTILE_LIFETIME)


func _cooldown_time() -> float:
	return maxf(shoot_interval - warning_time - recovery_time, 0.0)


func _purge_projectile_list() -> void:
	var live_projectiles: Array[EnemyProjectile] = []
	for projectile in _active_projectiles:
		if (
			projectile != null
			and is_instance_valid(projectile)
			and not projectile.is_queued_for_deletion()
		):
			live_projectiles.append(projectile)
	_active_projectiles = live_projectiles


func _clear_projectiles() -> void:
	for projectile in _active_projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.set_active(false)
			projectile.queue_free()
	_active_projectiles.clear()


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0)
	_update_visual()


func _refresh_visual_color() -> void:
	_update_visual()


func _update_visual() -> void:
	if _visual != null:
		_visual.scale.x = float(direction)
		if is_staggered():
			_visual.color = Color(0.36, 0.88, 0.92, 1.0)
		elif _state == STATE_AIMING:
			_visual.color = warning_color
		elif _state == STATE_RECOVERY:
			_visual.color = recovery_color
		else:
			_visual.color = _base_visual_color
	if _weapon_visual != null:
		_weapon_visual.position = Vector2(float(direction) * 8.0, -28.0)
		_weapon_visual.scale.x = float(direction)
		_weapon_visual.color = (
			warning_color
			if _state == STATE_AIMING
			else weapon_color
		)
	if _aim_warning != null:
		_aim_warning.visible = current_health > 0 and _state == STATE_AIMING


func _update_aim_warning_geometry() -> void:
	if _aim_warning == null:
		return
	_aim_warning.position = Vector2(0.0, -28.0) + _locked_aim_direction * 24.0
	_aim_warning.points = PackedVector2Array([
		Vector2.ZERO,
		_locked_aim_direction * projectile_range,
	])


func _ensure_aim_warning() -> Line2D:
	var line := get_node_or_null("AimWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "AimWarning"
		line.width = 8.0
		line.default_color = warning_color
		line.antialiased = true
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line


func _ensure_weapon_visual() -> Polygon2D:
	var weapon := get_node_or_null("Weapon") as Polygon2D
	if weapon == null:
		weapon = Polygon2D.new()
		weapon.name = "Weapon"
		weapon.polygon = PackedVector2Array([
			Vector2(0.0, -5.0),
			Vector2(weapon_length, -5.0),
			Vector2(weapon_length, 5.0),
			Vector2(0.0, 5.0),
		])
		weapon.z_index = 1
		add_child(weapon)
	return weapon
