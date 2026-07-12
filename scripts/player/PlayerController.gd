class_name PlayerController
extends CharacterBody2D

signal extra_jump_performed
signal dash_completed(start_position: Vector2, end_position: Vector2)

@export var crouch_speed_multiplier: float = 0.55
@export var crouch_height: float = 34.0
@export var one_way_drop_time: float = 0.18
@export var climb_speed: float = 165.0

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var combat_controller: PlayerCombatController = $CombatController
@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var visual_overlay: PlayerVisualOverlay = $Visual/PlayerVisualOverlay

var stats: Dictionary = {}
var facing: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_charges_left: int = 1
var invulnerability_timer: float = 0.0
var one_way_drop_timer: float = 0.0
var is_dashing: bool = false
var is_climbing: bool = false
var is_crouching: bool = false
var climbable_count: int = 0
var extra_jumps_left: int = 0

var _standing_body_size: Vector2
var _standing_hurtbox_size: Vector2
var _dash_start_position: Vector2


func _ready() -> void:
	add_to_group("player")
	_prepare_collision_shapes()
	_apply_run_state()
	SignalBus.selected_profile_changed.connect(_on_selected_profile_changed)
	SignalBus.player_stats_changed.connect(_on_player_stats_changed)


func _exit_tree() -> void:
	if SignalBus.selected_profile_changed.is_connected(_on_selected_profile_changed):
		SignalBus.selected_profile_changed.disconnect(_on_selected_profile_changed)
	if SignalBus.player_stats_changed.is_connected(_on_player_stats_changed):
		SignalBus.player_stats_changed.disconnect(_on_player_stats_changed)


func _prepare_collision_shapes() -> void:
	if body_collision.shape is RectangleShape2D:
		body_collision.shape = body_collision.shape.duplicate()
		_standing_body_size = (body_collision.shape as RectangleShape2D).size
	if hurtbox_collision.shape is RectangleShape2D:
		hurtbox_collision.shape = hurtbox_collision.shape.duplicate()
		_standing_hurtbox_size = (hurtbox_collision.shape as RectangleShape2D).size


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	combat_controller.update_combat(delta)
	_try_use_consumable()

	var input_axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(input_axis) and not combat_controller.is_movement_locked():
		facing = int(sign(input_axis))

	_update_jump_buffer()
	_update_crouch_state()
	if not combat_controller.is_action_committed():
		_update_climb_state(input_axis, delta)
	if is_climbing:
		move_and_slide()
		return

	if not combat_controller.is_action_committed():
		_update_dash(input_axis, delta)
	if is_dashing:
		move_and_slide()
		return

	combat_controller.try_start_input()
	_update_gravity(delta)
	if combat_controller.is_movement_locked():
		combat_controller.apply_movement(delta)
	else:
		_update_horizontal_motion(input_axis, delta)
		_try_jump()
	_update_visual_state(delta)

	move_and_slide()
	if is_on_wall():
		combat_controller.notify_wall_collision()


func receive_damage(damage_info: DamageInfo) -> void:
	if invulnerability_timer > 0.0 or RunState.current_health <= 0:
		return
	if combat_controller.blocks_incoming_damage(damage_info):
		return

	var defense := combat_controller.resolve_incoming_damage(damage_info.amount)
	var resolved_damage := int(defense.get("damage", damage_info.amount))
	resolved_damage = RunState.reduce_damage_with_forge_guard(resolved_damage)
	var previous_health: int = RunState.current_health
	RunState.damage_player(resolved_damage)
	combat_controller.notify_health_changed(previous_health, RunState.current_health)
	combat_controller.notify_player_damaged(resolved_damage)
	invulnerability_timer = float(stats.get("post_hit_invulnerability", 1.0))
	var committed_damage := maxi(previous_health - RunState.current_health, 0)
	if committed_damage > 0:
		combat_controller.notify_player_health_damage({
			"amount": committed_damage,
			"previous_health": previous_health,
			"current_health": RunState.current_health,
			"attack_id": damage_info.attack_id,
			"tags": damage_info.tags.duplicate(),
		})
	var knockback := damage_info.knockback
	if knockback == Vector2.ZERO:
		knockback = Vector2(
			-float(facing) * float(stats.get("damage_knockback_x", 220.0)),
			float(stats.get("damage_knockback_y", -220.0))
		)
	velocity = knockback * float(defense.get("knockback_scale", 1.0))


func heal_player(amount: int) -> int:
	if amount <= 0:
		return 0
	var previous_health := RunState.current_health
	RunState.heal_player(amount)
	return maxi(RunState.current_health - previous_health, 0)


func _try_use_consumable() -> void:
	if not Input.is_action_just_pressed("use_consumable"):
		return
	var result: Dictionary = RunState.use_consumable()
	SignalBus.status_message_changed.emit(str(result.get("message", "Consumable unavailable.")))


func _update_timers(delta: float) -> void:
	coyote_timer = float(stats.get("coyote_time", 0.1)) if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)

	if one_way_drop_timer > 0.0:
		one_way_drop_timer = maxf(one_way_drop_timer - delta, 0.0)
		if one_way_drop_timer <= 0.0:
			set_collision_mask_value(2, true)

	if is_on_floor():
		dash_charges_left = _max_dash_charges()
		extra_jumps_left = _max_extra_jumps()

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
		var was_dashing := is_dashing
		dash_timer = maxf(dash_timer - delta, 0.0)
		velocity = Vector2(float(facing) * float(stats.get("dash_speed", 520.0)), 0.0)
		is_dashing = dash_timer > 0.0
		if was_dashing and not is_dashing:
			dash_completed.emit(_dash_start_position, global_position)
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
	_dash_start_position = global_position
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
	if is_crouching:
		move_speed *= crouch_speed_multiplier

	var target_speed := input_axis * move_speed
	var acceleration := float(stats.get("air_acceleration", 1200.0))
	if is_on_floor():
		acceleration = float(stats.get("acceleration", 1800.0)) if not is_zero_approx(input_axis) else float(stats.get("deceleration", 2200.0))
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _try_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return
	if is_crouching:
		if not _can_stand():
			return
		_set_crouching(false)

	if coyote_timer > 0.0:
		_perform_jump()
		return

	if extra_jumps_left > 0:
		extra_jumps_left -= 1
		_perform_jump()
		extra_jump_performed.emit()


func _update_visual_state(delta: float) -> void:
	var crouch_scale := 0.72 if is_crouching else 1.0
	visual.scale.x = float(facing)
	visual.scale.y = move_toward(visual.scale.y, crouch_scale, delta * 12.0)


func _update_crouch_state() -> void:
	var wants_crouch := Input.is_action_pressed("crouch") and is_on_floor()
	if wants_crouch:
		_set_crouching(true)
	elif is_crouching and _can_stand():
		_set_crouching(false)


func _can_stand() -> bool:
	if _standing_body_size.y <= 0.0:
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	var standing_shape := RectangleShape2D.new()
	standing_shape.size = _standing_body_size
	query.shape = standing_shape
	query.transform = Transform2D(
		0.0,
		global_position + Vector2(0.0, -_standing_body_size.y * 0.5 - 0.5)
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _set_crouching(enabled: bool) -> void:
	if is_crouching == enabled:
		return
	is_crouching = enabled
	var body_height := crouch_height if enabled else _standing_body_size.y
	var hurtbox_height := crouch_height + 2.0 if enabled else _standing_hurtbox_size.y
	if body_collision.shape is RectangleShape2D:
		(body_collision.shape as RectangleShape2D).size.y = body_height
		body_collision.position.y = -body_height * 0.5
	if hurtbox_collision.shape is RectangleShape2D:
		(hurtbox_collision.shape as RectangleShape2D).size.y = hurtbox_height
		hurtbox_collision.position.y = -hurtbox_height * 0.5


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
	is_climbing = enabled
	if is_climbing:
		_set_crouching(false)
		velocity = Vector2.ZERO
		is_dashing = false
		dash_timer = 0.0
		SignalBus.status_message_changed.emit("Climb mode")


func _perform_jump() -> void:
	_set_crouching(false)
	velocity.y = float(stats.get("jump_velocity", -420.0))
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	is_climbing = false


func _max_dash_charges() -> int:
	return int(stats.get("dash_charges", 1))


func _max_extra_jumps() -> int:
	return int(stats.get("extra_jumps", 1))


func refund_dash_charge(amount: int = 1) -> int:
	var previous := dash_charges_left
	dash_charges_left = mini(dash_charges_left + maxi(amount, 0), _max_dash_charges())
	return dash_charges_left - previous


func grant_invulnerability(duration: float) -> void:
	invulnerability_timer = maxf(invulnerability_timer, maxf(duration, 0.0))


func restore_air_control(fraction: float, direction: int) -> void:
	if is_on_floor() or fraction <= 0.0:
		return
	var move_speed := float(stats.get("move_speed", 220.0))
	var target := clampf(
		velocity.x + float(direction) * move_speed * fraction,
		-move_speed,
		move_speed
	)
	velocity.x = target


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
	one_way_drop_timer = 0.0
	is_dashing = false
	_dash_start_position = respawn_position
	is_climbing = false
	_set_crouching(false)
	climbable_count = 0
	invulnerability_timer = invulnerability_time
	set_collision_mask_value(2, true)
	combat_controller.reset_combat_state()
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _apply_run_state() -> void:
	stats = RunState.get_effective_stats()
	var profile := RunState.selected_profile
	if profile != null:
		body_polygon.color = profile.visual_color
		visual_overlay.configure(StringName(profile.id), profile.visual_color)
	combat_controller.configure(
		profile,
		stats,
		ProfileState.get_behavior_effects(StringName(profile.id))
	)
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()


func _on_selected_profile_changed(_profile_id: String, _display_name: String, color: Color) -> void:
	body_polygon.color = color
	visual_overlay.configure(StringName(_profile_id), color)
	combat_controller.configure(
		RunState.selected_profile,
		stats,
		ProfileState.get_behavior_effects(StringName(RunState.selected_profile.id))
	)


func _on_player_stats_changed(new_stats: Dictionary) -> void:
	stats = new_stats.duplicate()
	combat_controller.update_stats(stats)
	dash_charges_left = _max_dash_charges()
	extra_jumps_left = _max_extra_jumps()
