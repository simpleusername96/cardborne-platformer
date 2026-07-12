class_name ShieldGuardEnemy
extends EnemyBase

const STATE_GUARD := &"guard"
const STATE_WARNING := &"warning"
const STATE_ACTIVE := &"active"
const STATE_RECOVERY := &"recovery"
const TARGET_RETRY_TIME := 0.15

@export var patrol_half_width: float = 90.0
@export var move_speed: float = 45.0
@export var guard_time: float = 1.2
@export var attack_warning_time: float = 0.35
@export var attack_active_time: float = 0.18
@export var attack_recovery_time: float = 0.55
@export var attack_speed: float = 170.0
@export var detection_range: float = 260.0
@export var detection_height: float = 100.0
@export var blocked_damage_status: String = "Shield blocked"
@export var body_color: Color = Color(0.52, 0.57, 0.68, 1.0)
@export var warning_color: Color = Color(1.0, 0.80, 0.28, 1.0)
@export var active_color: Color = Color(0.92, 0.38, 0.20, 1.0)
@export var recovery_color: Color = Color(0.45, 0.95, 0.75, 1.0)

var direction: int = -1
var left_limit: float
var right_limit: float
var _state: StringName = STATE_GUARD
var _state_timer: float = 1.2
var _attack_warning: Line2D


func _ready() -> void:
	super._ready()
	if resolved_spec != null:
		guard_time = resolved_spec.active_time
		attack_warning_time = resolved_spec.warning_time
		attack_recovery_time = resolved_spec.recovery_time
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_base_visual_color = body_color
	if _visual != null:
		_visual.color = _base_visual_color
	_attack_warning = _ensure_attack_warning()
	_set_state(STATE_GUARD, guard_time)


func receive_damage(damage_info: DamageInfo) -> void:
	if (
		_state == STATE_GUARD
		and _damage_from_front(damage_info)
		and not _bypasses_guard(damage_info)
	):
		# Guard blocks health damage, but authored stagger still pressures the shield.
		if damage_info.stagger > 0:
			super.receive_damage(DamageInfo.new(
				0,
				damage_info.source,
				damage_info.knockback,
				damage_info.tags,
				damage_info.attack_id,
				damage_info.stagger,
				false,
				damage_info.secondary_hit
			))
		SignalBus.status_message_changed.emit(blocked_damage_status)
		_flash_guard()
		return

	super.receive_damage(damage_info)
	if current_health > 0 and (_state == STATE_WARNING or _state == STATE_ACTIVE):
		_set_state(STATE_RECOVERY, attack_recovery_time)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer > 0.0 or is_staggered():
		if is_staggered() and _state != STATE_RECOVERY:
			_set_state(STATE_RECOVERY, attack_recovery_time)
		super._physics_process(delta)
		_update_visual()
		return

	_state_timer -= delta
	match _state:
		STATE_GUARD:
			velocity.x = float(direction) * move_speed * get_external_speed_scale()
			_update_patrol_bounds()
			if _state_timer <= 0.0:
				if _lock_direction_to_target():
					_set_state(STATE_WARNING, attack_warning_time)
				else:
					_state_timer = TARGET_RETRY_TIME
		STATE_WARNING:
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_set_state(STATE_ACTIVE, attack_active_time)
		STATE_ACTIVE:
			velocity.x = float(direction) * attack_speed * get_external_speed_scale()
			if _state_timer <= 0.0 or is_on_wall():
				_set_state(STATE_RECOVERY, attack_recovery_time)
		STATE_RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, attack_speed * delta * 4.0)
			if _state_timer <= 0.0:
				direction *= -1
				_set_state(STATE_GUARD, guard_time)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	direction = -1
	_set_state(STATE_GUARD, guard_time)


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["guarding"] = _state == STATE_GUARD
	snapshot["warning"] = _state == STATE_WARNING
	snapshot["active"] = _state == STATE_ACTIVE
	snapshot["recovery"] = _state == STATE_RECOVERY
	snapshot["state_time_remaining"] = _state_timer
	return snapshot


func _damage_from_front(damage_info: DamageInfo) -> bool:
	if damage_info.source == null or not damage_info.source is Node2D:
		return false
	var source_node := damage_info.source as Node2D
	var source_side := int(sign(source_node.global_position.x - global_position.x))
	return source_side != 0 and source_side == direction


func _bypasses_guard(damage_info: DamageInfo) -> bool:
	return (
		damage_info.tags.has("shockwave")
		or damage_info.tags.has("area")
		or damage_info.tags.has("area_barrage")
	)


func _lock_direction_to_target() -> bool:
	var target := get_priority_target()
	if target == null or not is_target_within_encounter(target):
		return false
	var offset := target.global_position - global_position
	if absf(offset.x) > detection_range or absf(offset.y) > detection_height:
		return false
	if not is_zero_approx(offset.x):
		direction = int(sign(offset.x))
	return true


func _update_patrol_bounds() -> void:
	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0)
	_set_attack_active(_state == STATE_ACTIVE)
	_update_visual()


func _set_attack_active(enabled: bool) -> void:
	var hitbox := get_node_or_null("ContactHitbox") as Hitbox
	if hitbox != null:
		hitbox.set_active(enabled)


func _refresh_visual_color() -> void:
	_update_visual()


func _update_visual() -> void:
	if _visual != null:
		_visual.scale.x = float(direction)
		if is_staggered():
			_visual.color = Color(0.36, 0.88, 0.92, 1.0)
		elif _state == STATE_WARNING:
			_visual.color = warning_color
		elif _state == STATE_ACTIVE:
			_visual.color = active_color
		elif _state == STATE_RECOVERY:
			_visual.color = recovery_color
		else:
			_visual.color = _base_visual_color
	if _attack_warning != null:
		_attack_warning.visible = current_health > 0 and _state == STATE_WARNING
		_attack_warning.scale.x = float(direction)


func _ensure_attack_warning() -> Line2D:
	var line := get_node_or_null("AttackWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "AttackWarning"
		line.position = Vector2(0.0, -16.0)
		line.width = 8.0
		line.default_color = warning_color
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(118.0, 0.0)])
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line


func _flash_guard() -> void:
	if _visual == null:
		return
	_visual.color = Color(0.72, 0.88, 1.0, 1.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_update_visual()
