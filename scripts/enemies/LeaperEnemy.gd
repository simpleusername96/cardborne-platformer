class_name LeaperEnemy
extends EnemyBase

const STATE_IDLE := &"idle"
const STATE_WARNING := &"warning"
const STATE_ACTIVE := &"active"
const STATE_RECOVERY := &"recovery"
const TARGET_RETRY_TIME := 0.12

@export var activation_range: float = 420.0
@export var warning_time: float = 0.35
@export var leap_time: float = 0.52
@export var recovery_time: float = 0.50
@export var maximum_leap_speed_x: float = 620.0
@export var leap_velocity_y: float = -430.0
@export var arc_clearance: float = 180.0
@export var body_color: Color = Color(0.32, 0.68, 0.76, 1.0)
@export var warning_color: Color = Color(1.0, 0.84, 0.24, 1.0)
@export var active_color: Color = Color(0.30, 0.96, 0.72, 1.0)
@export var recovery_color: Color = Color(0.28, 0.46, 0.52, 1.0)

var direction: int = -1
var _state: StringName = STATE_IDLE
var _state_timer: float = TARGET_RETRY_TIME
var _locked_target_x: float = 0.0
var _landing_warning: Line2D


func _ready() -> void:
	super._ready()
	if resolved_spec != null:
		warning_time = resolved_spec.warning_time
		leap_time = resolved_spec.active_time
		recovery_time = resolved_spec.recovery_time
		arc_clearance = float(resolved_spec.room_requirements.get("minimum_arc_clearance", arc_clearance))
	_base_visual_color = body_color
	_landing_warning = _ensure_landing_warning()
	_set_state(STATE_IDLE, TARGET_RETRY_TIME)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return
	if hit_stun_timer > 0.0 or is_staggered():
		if _state == STATE_WARNING or _state == STATE_ACTIVE:
			_set_state(STATE_RECOVERY, recovery_time)
		else:
			_set_attack_active(false)
		super._physics_process(delta)
		_update_visual()
		return

	_state_timer -= delta
	match _state:
		STATE_IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _state_timer <= 0.0:
				_try_start_warning()
		STATE_WARNING:
			velocity.x = 0.0
			if _state_timer <= 0.0:
				_start_leap()
		STATE_ACTIVE:
			if _state_timer <= 0.0 or (is_on_floor() and velocity.y >= 0.0):
				_set_state(STATE_RECOVERY, recovery_time)
		STATE_RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
			if _state_timer <= 0.0 and is_on_floor():
				_set_state(STATE_IDLE, TARGET_RETRY_TIME)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	direction = -1
	_locked_target_x = global_position.x
	_set_state(STATE_IDLE, TARGET_RETRY_TIME)


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["warning"] = _state == STATE_WARNING
	snapshot["active"] = _state == STATE_ACTIVE
	snapshot["recovery"] = _state == STATE_RECOVERY
	snapshot["state_time_remaining"] = _state_timer
	return snapshot


func _try_start_warning() -> void:
	if not is_on_floor():
		_state_timer = TARGET_RETRY_TIME
		return
	var target := get_priority_target()
	if target == null or not is_target_within_encounter(target):
		_state_timer = TARGET_RETRY_TIME
		return
	var distance := target.global_position.distance_to(global_position)
	if distance > activation_range or distance < 48.0:
		_state_timer = TARGET_RETRY_TIME
		return
	_locked_target_x = target.global_position.x
	direction = _direction_to(_locked_target_x)
	_update_landing_warning_geometry()
	_set_state(STATE_WARNING, warning_time)


func _start_leap() -> void:
	var horizontal_delta := _locked_target_x - global_position.x
	var horizontal_speed := clampf(
		horizontal_delta / maxf(leap_time, 0.001),
		-maximum_leap_speed_x,
		maximum_leap_speed_x
	)
	direction = _direction_to(global_position.x + horizontal_speed)
	velocity = Vector2(horizontal_speed * get_external_speed_scale(), leap_velocity_y)
	_set_state(STATE_ACTIVE, leap_time)


func _direction_to(target_x: float) -> int:
	var offset := target_x - global_position.x
	return int(sign(offset)) if not is_zero_approx(offset) else direction


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0)
	_set_attack_active(_state == STATE_ACTIVE)
	_update_visual()


func _set_attack_active(enabled: bool) -> void:
	var hitbox := get_node_or_null("ContactHitbox") as Hitbox
	if hitbox != null:
		hitbox.set_active(enabled)


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
	if _landing_warning != null:
		_landing_warning.visible = current_health > 0 and _state == STATE_WARNING


func _update_landing_warning_geometry() -> void:
	if _landing_warning == null:
		return
	var landing_x := _locked_target_x - global_position.x
	_landing_warning.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(landing_x * 0.5, -arc_clearance),
		Vector2(landing_x, 0.0),
	])


func _ensure_landing_warning() -> Line2D:
	var line := get_node_or_null("LandingWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "LandingWarning"
		line.position = Vector2(0.0, -4.0)
		line.width = 10.0
		line.default_color = warning_color
		line.antialiased = true
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line
