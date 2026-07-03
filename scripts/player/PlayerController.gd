class_name PlayerController
extends CharacterBody2D

@export var attack_active_time: float = 0.12
@export var crouch_speed_multiplier: float = 0.55
@export var one_way_drop_time: float = 0.18
@export var climb_speed: float = 165.0

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_visual: Polygon2D = $AttackHitbox/AttackVisual
@onready var camera: Camera2D = get_node_or_null("Camera2D")

var stats: Dictionary = {}
var facing: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_charges_left: int = 1
var attack_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var invulnerability_timer: float = 0.0
var one_way_drop_timer: float = 0.0
var is_dashing: bool = false
var is_climbing: bool = false
var climbable_count: int = 0
var extra_jumps_left: int = 0


func _ready() -> void:
	add_to_group("player")
	_apply_run_state()
	attack_hitbox.set_active(false)
	attack_hitbox.visible = false
	attack_hitbox.target_hit.connect(_on_attack_hit_confirmed)
	SignalBus.selected_profile_changed.connect(_on_selected_profile_changed)
	SignalBus.player_stats_changed.connect(_on_player_stats_changed)
	SignalBus.testbed_flags_changed.connect(_on_testbed_flags_changed)


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if Input.is_action_just_pressed("open_build_panel"):
		RunState.cycle_profile(1)

	var input_axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(input_axis):
		facing = int(sign(input_axis))

	_update_jump_buffer()
	_update_climb_state(input_axis, delta)
	if is_climbing:
		move_and_slide()
		return

	_update_dash(input_axis, delta)
	if is_dashing:
		move_and_slide()
		return

	_update_gravity(delta)
	_update_horizontal_motion(input_axis, delta)
	_try_jump()
	_update_attack()
	_update_visual_state(delta)

	move_and_slide()


func receive_damage(damage_info: DamageInfo) -> void:
	if invulnerability_timer > 0.0 or RunState.current_health <= 0:
		return

	RunState.damage_player(damage_info.amount)
	invulnerability_timer = float(stats.get("post_hit_invulnerability", 1.0))
	var knockback := damage_info.knockback
	if knockback == Vector2.ZERO:
		knockback = Vector2(
			-float(facing) * float(stats.get("damage_knockback_x", 220.0)),
			float(stats.get("damage_knockback_y", -220.0))
		)
	velocity = knockback


func _update_timers(delta: float) -> void:
	coyote_timer = float(stats.get("coyote_time", 0.1)) if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)

	if one_way_drop_timer > 0.0:
		one_way_drop_timer = maxf(one_way_drop_timer - delta, 0.0)
		if one_way_drop_timer <= 0.0:
			set_collision_mask_value(2, true)

	if is_on_floor():
		dash_charges_left = _max_dash_charges()
		extra_jumps_left = _max_extra_jumps()

	if attack_timer <= 0.0:
		attack_hitbox.set_active(false, false)
		attack_hitbox.visible = false

	visual.modulate.a = 0.45 if invulnerability_timer > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0


func _update_jump_buffer() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if Input.is_action_pressed("crouch") and is_on_floor():
		one_way_drop_timer = one_way_drop_time
		set_collision_mask_value(2, false)
		return

	jump_buffer_timer = float(stats.get("jump_buffer_time", 0.12))


func _update_dash(input_axis: float, delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer = maxf(dash_timer - delta, 0.0)
		velocity = Vector2(float(facing) * float(stats.get("dash_speed", 520.0)), 0.0)
		is_dashing = dash_timer > 0.0
		return

	if not Input.is_action_just_pressed("dash"):
		is_dashing = false
		return

	if dash_cooldown_timer > 0.0 or dash_charges_left <= 0:
		return

	if not is_zero_approx(input_axis):
		facing = int(sign(input_axis))
	dash_charges_left -= 1
	dash_timer = float(stats.get("dash_duration", 0.13))
	dash_cooldown_timer = float(stats.get("dash_cooldown", 0.45))
	is_dashing = true
	velocity = Vector2(float(facing) * float(stats.get("dash_speed", 520.0)), 0.0)


func _update_gravity(delta: float) -> void:
	if is_climbing:
		return

	if is_on_floor():
		return

	var gravity := float(stats.get("gravity", 1200.0))
	if Input.is_action_pressed("crouch"):
		gravity *= 1.6
	velocity.y = minf(velocity.y + gravity * delta, float(stats.get("max_fall_speed", 700.0)))

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= float(stats.get("jump_cut_multiplier", 0.45))


func _update_horizontal_motion(input_axis: float, delta: float) -> void:
	var move_speed := float(stats.get("move_speed", 220.0))
	if Input.is_action_pressed("crouch") and is_on_floor():
		move_speed *= crouch_speed_multiplier

	var target_speed := input_axis * move_speed
	var acceleration := float(stats.get("air_acceleration", 1200.0))
	if is_on_floor():
		acceleration = float(stats.get("acceleration", 1800.0)) if not is_zero_approx(input_axis) else float(stats.get("deceleration", 2200.0))
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _try_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return

	if coyote_timer > 0.0:
		_perform_jump()
		return

	if extra_jumps_left > 0:
		extra_jumps_left -= 1
		_perform_jump()


func _update_attack() -> void:
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		attack_cooldown_timer = float(stats.get("attack_cooldown", 0.35))
		attack_timer = float(stats.get("attack_active_time", attack_active_time))
		attack_hitbox.position = Vector2(
			float(stats.get("attack_offset_x", 30.0)) * float(facing),
			float(stats.get("attack_offset_y", -26.0))
		)
		_configure_attack_geometry(
			float(stats.get("attack_range", 38.0)),
			float(stats.get("attack_height", 30.0))
		)
		attack_hitbox.damage_amount = int(stats.get("attack_damage", 1))
		attack_hitbox.knockback = Vector2(
			float(stats.get("attack_knockback_x", 160.0)) * float(facing),
			float(stats.get("attack_knockback_y", -80.0))
		)
		attack_hitbox.set_active(true)
		attack_hitbox.visible = true
		SignalBus.status_message_changed.emit("%s active" % str(stats.get("attack_label", "Attack")))


func _update_visual_state(delta: float) -> void:
	var crouch_scale := 0.72 if Input.is_action_pressed("crouch") and is_on_floor() else 1.0
	visual.scale.x = float(facing)
	visual.scale.y = move_toward(visual.scale.y, crouch_scale, delta * 12.0)


func _update_climb_state(input_axis: float, _delta: float) -> void:
	if is_climbing:
		if climbable_count <= 0 or Input.is_action_just_pressed("climb_cancel") or Input.is_action_just_pressed("dash"):
			_set_climbing(false)
			return
		if Input.is_action_just_pressed("jump"):
			_set_climbing(false)
			jump_buffer_timer = float(stats.get("jump_buffer_time", 0.12))
			_perform_jump()
			return

		var vertical_axis := Input.get_axis("climb_up", "climb_down")
		velocity = Vector2(input_axis * float(stats.get("move_speed", 220.0)) * 0.35, vertical_axis * climb_speed)
		coyote_timer = 0.0
		dash_charges_left = _max_dash_charges()
		extra_jumps_left = _max_extra_jumps()
		return

	if climbable_count <= 0:
		return

	if Input.is_action_pressed("climb_up") or Input.is_action_pressed("climb_down"):
		_set_climbing(true)


func _set_climbing(enabled: bool) -> void:
	is_climbing = enabled and RunState.is_testbed_ability_enabled("rope_climb_enabled")
	if is_climbing:
		velocity = Vector2.ZERO
		is_dashing = false
		dash_timer = 0.0
		SignalBus.status_message_changed.emit("Climb mode")


func _perform_jump() -> void:
	velocity.y = float(stats.get("jump_velocity", -420.0))
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	is_climbing = false


func _configure_attack_geometry(range: float, height: float) -> void:
	var safe_range := maxf(range, 12.0)
	var safe_height := maxf(height, 12.0)
	if attack_shape != null and attack_shape.shape is RectangleShape2D:
		var rect := attack_shape.shape as RectangleShape2D
		rect.size = Vector2(safe_range, safe_height)

	if attack_visual == null:
		return

	var half := Vector2(safe_range, safe_height) * 0.5
	attack_visual.scale.x = float(facing)
	attack_visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x + 6.0, 0.0),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _max_dash_charges() -> int:
	var charges := int(stats.get("dash_charges", 1))
	if RunState.is_testbed_ability_enabled("extra_dash_enabled"):
		charges += 1
	return charges


func _max_extra_jumps() -> int:
	return 1 if RunState.is_testbed_ability_enabled("double_jump_enabled") else 0


func enter_climbable(_climbable: Area2D) -> void:
	climbable_count += 1
	SignalBus.status_message_changed.emit("Climbable: W/S or Up/Down, Space dismount")


func exit_climbable(_climbable: Area2D) -> void:
	climbable_count = maxi(climbable_count - 1, 0)
	if climbable_count <= 0:
		_set_climbing(false)


func set_camera_limits(bounds: Rect2) -> void:
	if camera == null:
		return

	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.position.x + bounds.size.x)
	camera.limit_bottom = int(bounds.position.y + bounds.size.y)
	camera.make_current()


func respawn_at(respawn_position: Vector2, invulnerability_time: float) -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	attack_cooldown_timer = 0.0
	attack_timer = 0.0
	one_way_drop_timer = 0.0
	is_dashing = false
	is_climbing = false
	climbable_count = 0
	invulnerability_timer = invulnerability_time
	set_collision_mask_value(2, true)
	attack_hitbox.set_active(false, false)
	attack_hitbox.visible = false
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _apply_run_state() -> void:
	stats = RunState.get_effective_stats()
	var profile := RunState.selected_profile
	if profile != null:
		body_polygon.color = profile.visual_color
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _on_selected_profile_changed(_profile_id: String, _display_name: String, color: Color) -> void:
	body_polygon.color = color


func _on_player_stats_changed(new_stats: Dictionary) -> void:
	stats = new_stats.duplicate()
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _on_testbed_flags_changed(_flags: Dictionary) -> void:
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _on_attack_hit_confirmed(_area: Area2D, _damage_info: DamageInfo) -> void:
	SignalBus.status_message_changed.emit("Hit confirmed")
