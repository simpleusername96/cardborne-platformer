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
var _locked_landing_position := Vector2.ZERO
var _last_landing_x: float = INF
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
			if is_on_floor() and velocity.y >= 0.0:
				if absf(global_position.x - _locked_landing_position.x) <= 72.0:
					global_position.x = _locked_landing_position.x
				velocity = Vector2.ZERO
				_set_state(STATE_RECOVERY, recovery_time)
			elif _state_timer <= 0.0:
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
	_locked_landing_position = global_position
	_last_landing_x = INF
	_set_state(STATE_IDLE, TARGET_RETRY_TIME)


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["warning"] = _state == STATE_WARNING
	snapshot["active"] = _state == STATE_ACTIVE
	snapshot["recovery"] = _state == STATE_RECOVERY
	snapshot["state_time_remaining"] = _state_timer
	snapshot["landing_target"] = _locked_landing_position
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
	var landing: Variant = _select_landing_destination(target)
	if landing == null:
		_state_timer = TARGET_RETRY_TIME
		return
	_locked_landing_position = landing as Vector2
	direction = _direction_to(_locked_landing_position.x)
	_update_landing_warning_geometry()
	_set_state(STATE_WARNING, warning_time)


func _start_leap() -> void:
	var flight_time := _flight_time_to(_locked_landing_position.y)
	if flight_time <= 0.0:
		_set_state(STATE_RECOVERY, recovery_time)
		return
	var horizontal_delta := _locked_landing_position.x - global_position.x
	var horizontal_speed := clampf(
		horizontal_delta / flight_time,
		-maximum_leap_speed_x,
		maximum_leap_speed_x
	)
	direction = _direction_to(global_position.x + horizontal_speed)
	velocity = Vector2(horizontal_speed * get_external_speed_scale(), leap_velocity_y)
	_last_landing_x = _locked_landing_position.x
	_set_state(STATE_ACTIVE, maxf(leap_time, flight_time + 0.12))


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
	var landing := _locked_landing_position - global_position
	_landing_warning.points = PackedVector2Array([
		landing + Vector2(-24.0, 0.0),
		landing + Vector2(24.0, 0.0),
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


func _select_landing_destination(target: Node2D) -> Variant:
	var bounds := encounter_bounds
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(global_position - Vector2(520.0, 260.0), Vector2(1040.0, 520.0))
	var nominal_flight := _flight_time_to(global_position.y)
	var maximum_reach := maximum_leap_speed_x * maxf(nominal_flight, leap_time)
	var candidates: Array[Vector2] = []
	var sample_xs: Array[float] = [
		clampf(target.global_position.x, bounds.position.x + 24.0, bounds.end.x - 24.0),
		global_position.x - maximum_reach * 0.72,
		global_position.x + maximum_reach * 0.72,
		lerpf(bounds.position.x, bounds.end.x, 0.25),
		lerpf(bounds.position.x, bounds.end.x, 0.50),
		lerpf(bounds.position.x, bounds.end.x, 0.75),
	]
	for sample_x in sample_xs:
		var landing: Variant = _support_at_x(clampf(
			sample_x,
			bounds.position.x + 20.0,
			bounds.end.x - 20.0
		), bounds)
		if landing == null:
			continue
		var candidate := landing as Vector2
		var horizontal_delta := absf(candidate.x - global_position.x)
		if horizontal_delta < 64.0 or horizontal_delta > maximum_reach + 1.0:
			continue
		if _flight_time_to(candidate.y) <= 0.0:
			continue
		if not _contains_near(candidates, candidate):
			candidates.append(candidate)
	if candidates.is_empty():
		return null
	candidates.sort_custom(
		func(left: Vector2, right: Vector2) -> bool:
			return (
				_landing_score(left, target.global_position)
				< _landing_score(right, target.global_position)
			)
	)
	return candidates[0]


func _support_at_x(x: float, bounds: Rect2) -> Variant:
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(x, bounds.position.y - 64.0),
		Vector2(x, bounds.end.y + 96.0),
		1,
		[get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.get("position", null)


func _flight_time_to(landing_y: float) -> float:
	var vertical_delta := landing_y - global_position.y
	var discriminant := leap_velocity_y * leap_velocity_y + 2.0 * gravity * vertical_delta
	if discriminant < 0.0 or gravity <= 0.0:
		return -1.0
	return (-leap_velocity_y + sqrt(discriminant)) / gravity


func _landing_score(candidate: Vector2, target_position: Vector2) -> float:
	var repeat_penalty := (
		260.0
		if is_finite(_last_landing_x) and absf(candidate.x - _last_landing_x) < 48.0
		else 0.0
	)
	return absf(candidate.x - target_position.x) + repeat_penalty


func _contains_near(candidates: Array[Vector2], candidate: Vector2) -> bool:
	for existing in candidates:
		if existing.distance_to(candidate) < 24.0:
			return true
	return false
