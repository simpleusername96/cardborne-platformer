class_name PlayerController
extends CharacterBody2D

@export var attack_active_time: float = 0.12
@export var crouch_speed_multiplier: float = 0.55
@export var one_way_drop_time: float = 0.18

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var attack_hitbox: Hitbox = $AttackHitbox

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


func _ready() -> void:
	add_to_group("player")
	_apply_run_state()
	attack_hitbox.set_active(false)
	SignalBus.selected_profile_changed.connect(_on_selected_profile_changed)
	SignalBus.player_stats_changed.connect(_on_player_stats_changed)


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if Input.is_action_just_pressed("open_build_panel"):
		RunState.cycle_profile(1)

	var input_axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(input_axis):
		facing = int(sign(input_axis))

	_update_jump_buffer()
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
		dash_charges_left = int(stats.get("dash_charges", 1))

	if attack_timer <= 0.0:
		attack_hitbox.set_active(false, false)

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
	if jump_buffer_timer <= 0.0 or coyote_timer <= 0.0:
		return

	velocity.y = float(stats.get("jump_velocity", -420.0))
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func _update_attack() -> void:
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		attack_cooldown_timer = float(stats.get("attack_cooldown", 0.35))
		attack_timer = attack_active_time
		attack_hitbox.position = Vector2(30.0 * float(facing), -26.0)
		attack_hitbox.damage_amount = int(stats.get("attack_damage", 1))
		attack_hitbox.knockback = Vector2(160.0 * float(facing), -80.0)
		attack_hitbox.set_active(true)


func _update_visual_state(delta: float) -> void:
	var crouch_scale := 0.72 if Input.is_action_pressed("crouch") and is_on_floor() else 1.0
	visual.scale.x = float(facing)
	visual.scale.y = move_toward(visual.scale.y, crouch_scale, delta * 12.0)


func _apply_run_state() -> void:
	stats = RunState.get_effective_stats()
	var profile := RunState.selected_profile
	if profile != null:
		body_polygon.color = profile.visual_color
	dash_charges_left = int(stats.get("dash_charges", 1))


func _on_selected_profile_changed(_profile_id: String, _display_name: String, color: Color) -> void:
	body_polygon.color = color


func _on_player_stats_changed(new_stats: Dictionary) -> void:
	stats = new_stats.duplicate()
	dash_charges_left = int(stats.get("dash_charges", 1))
