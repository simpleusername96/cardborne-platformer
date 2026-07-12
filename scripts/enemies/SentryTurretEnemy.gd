class_name SentryTurretEnemy
extends EnemyBase

const STATE_IDLE := &"idle"
const STATE_WARNING := &"warning"
const STATE_RECOVERY := &"recovery"
const INITIAL_WARNING_DELAY := 0.2
const TARGET_RETRY_DELAY := 0.1
const MAX_PROJECTILE_LIFETIME := 5.0
const VIEWPORT_MARGIN := 48.0

@export var activation_range: float = 900.0
@export var deactivation_range: float = 1020.0
@export var warning_time: float = 0.45
@export var fire_interval: float = 1.4
@export var recovery_time: float = 0.45
@export var projectile_speed: float = 300.0
@export var max_active_projectiles: int = 2
@export var body_color: Color = Color(0.42, 0.67, 0.78, 1.0)
@export var warning_color: Color = Color(1.0, 0.88, 0.28, 1.0)
@export var recovery_color: Color = Color(0.36, 0.42, 0.54, 1.0)
@export var projectile_color: Color = Color(1.0, 0.68, 0.18, 1.0)

var direction: int = -1
var _state: StringName = STATE_IDLE
var _state_timer: float = INITIAL_WARNING_DELAY
var _locked_aim_direction: Vector2 = Vector2.LEFT
var _active_projectiles: Array[EnemyProjectile] = []
var _shots_fired: int = 0
var _aim_warning: Line2D
var _barrel: Polygon2D


func _ready() -> void:
	super._ready()
	if resolved_spec != null:
		warning_time = resolved_spec.warning_time
		fire_interval = resolved_spec.cadence_time
		recovery_time = resolved_spec.recovery_time
		projectile_speed = resolved_spec.projectile_speed
		activation_range = resolved_spec.attack_range
		deactivation_range = maxf(deactivation_range, activation_range + 120.0)
		max_active_projectiles = resolved_spec.active_projectile_cap
	_base_visual_color = body_color
	_aim_warning = _ensure_aim_warning()
	_barrel = get_node_or_null("Barrel") as Polygon2D
	_set_state(STATE_IDLE, INITIAL_WARNING_DELAY)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_purge_projectile_list()
	if hit_stun_timer > 0.0 or is_staggered():
		if _state == STATE_WARNING:
			_set_state(STATE_RECOVERY, recovery_time)
		super._physics_process(delta)
		_update_visual()
		return

	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_state_timer -= delta
	match _state:
		STATE_IDLE:
			_face_target()
			if _state_timer <= 0.0:
				if _lock_aim_at_target():
					_set_state(STATE_WARNING, warning_time)
				else:
					_state_timer = TARGET_RETRY_DELAY
		STATE_WARNING:
			if not _can_continue_warning():
				_set_state(STATE_IDLE, TARGET_RETRY_DELAY)
			elif _state_timer <= 0.0:
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
	_set_state(STATE_IDLE, INITIAL_WARNING_DELAY)


func _defeat() -> void:
	_clear_projectiles()
	super._defeat()


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["warning"] = _state == STATE_WARNING
	snapshot["aiming"] = _state == STATE_WARNING
	snapshot["recovery"] = _state == STATE_RECOVERY
	snapshot["state_time_remaining"] = _state_timer
	snapshot["locked_aim_direction"] = _locked_aim_direction
	snapshot["active_projectiles"] = _active_projectiles.size()
	snapshot["shots_fired"] = _shots_fired
	return snapshot


func _face_target() -> void:
	var target := get_priority_target()
	if target == null or not is_target_within_encounter(target):
		return
	var offset := target.global_position.x - global_position.x
	if not is_zero_approx(offset):
		direction = int(sign(offset))


func _lock_aim_at_target() -> bool:
	var target := get_priority_target()
	if target == null or not _can_begin_warning(target):
		return false
	var origin := global_position + Vector2(0.0, -28.0)
	var offset := target.global_position - origin
	if offset.is_zero_approx():
		offset = Vector2(float(direction), 0.0)
	_locked_aim_direction = offset.normalized()
	if not is_zero_approx(_locked_aim_direction.x):
		direction = int(sign(_locked_aim_direction.x))
	_update_aim_warning_geometry()
	return true


func _can_begin_warning(target: Node2D) -> bool:
	return (
		is_target_within_encounter(target)
		and target.global_position.distance_to(global_position) <= activation_range
		and projectile_speed > 0.0
		and max_active_projectiles > 0
		and _is_on_screen()
	)


func _can_continue_warning() -> bool:
	var target := get_priority_target()
	return (
		target != null
		and is_target_within_encounter(target)
		and target.global_position.distance_to(global_position) <= deactivation_range
		and _is_on_screen()
	)


func _is_on_screen() -> bool:
	var viewport_position := get_viewport().get_canvas_transform() * global_position
	return get_viewport().get_visible_rect().grow(VIEWPORT_MARGIN).has_point(viewport_position)


func _spawn_projectile() -> void:
	_purge_projectile_list()
	if not is_player_within_encounter() or _active_projectiles.size() >= max_active_projectiles:
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
	shot.global_position = global_position + Vector2(0.0, -28.0) + _locked_aim_direction * 30.0
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
	if activation_range <= 0.0 or projectile_speed <= 0.0:
		return 0.0
	return minf(activation_range / projectile_speed, MAX_PROJECTILE_LIFETIME)


func _cooldown_time() -> float:
	return maxf(fire_interval - warning_time - recovery_time, 0.0)


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
		elif _state == STATE_WARNING:
			_visual.color = warning_color
		elif _state == STATE_RECOVERY:
			_visual.color = recovery_color
		else:
			_visual.color = _base_visual_color
	if _barrel != null:
		var aim := _locked_aim_direction if _state != STATE_IDLE else Vector2(float(direction), 0.0)
		_barrel.rotation = aim.angle()
		_barrel.color = warning_color if _state == STATE_WARNING else Color(0.72, 0.82, 0.92, 1.0)
	if _aim_warning != null:
		_aim_warning.visible = current_health > 0 and _state == STATE_WARNING


func _update_aim_warning_geometry() -> void:
	if _aim_warning == null:
		return
	_aim_warning.position = Vector2(0.0, -28.0) + _locked_aim_direction * 24.0
	_aim_warning.points = PackedVector2Array([
		Vector2.ZERO,
		_locked_aim_direction * activation_range,
	])


func _ensure_aim_warning() -> Line2D:
	var line := get_node_or_null("AimWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "AimWarning"
		line.width = 7.0
		line.default_color = warning_color
		line.antialiased = true
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line


# Sentries pressure with projectiles and never gain an untelegraphed contact hitbox.
func _ensure_contact_hitbox() -> void:
	pass
