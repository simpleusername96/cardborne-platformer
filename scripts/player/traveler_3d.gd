class_name Traveler3D
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal potion_changed(charges: int)
signal action_traced(label: String)

const MOVE_SPEED := 6.0
const ACCELERATION := 28.0
const BRAKING := 34.0
const DASH_SPEED := 14.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.55
const MELEE_DURATION := 0.38
const MELEE_HIT_TIME := 0.10
const RANGED_COOLDOWN := 0.45
const RANGED_ACTION_DURATION := 0.32
const RANGED_RELEASE_TIME := 0.10
const GUARD_MOVE_MULTIPLIER := 0.45
const GUARD_DAMAGE_MULTIPLIER := 0.35

@export var max_health := 100

var health := 100
var potion_charges := 3
var move_direction := Vector3.ZERO
var combat_facing := Vector3.FORWARD
var resolved_attack_direction := Vector3.FORWARD
var spawn_position := Vector3.ZERO
var dash_remaining := 0.0
var dash_cooldown_remaining := 0.0
var dash_direction := Vector3.ZERO
var melee_remaining := 0.0
var melee_hit_fired := false
var ranged_cooldown_remaining := 0.0
var ranged_action_remaining := 0.0
var ranged_release_fired := false
var ranged_direction := Vector3.FORWARD
var guarding := false

@onready var camera: Camera3D = get_node("../CameraRig/Camera3D")
@onready var facing_feedback: Node3D = $FacingFeedback
@onready var targeting_assist: TargetingAssist3D = $TargetingAssist
@onready var sprite_presenter: TravelerSpritePresenter3D = $ActorSprite


func _ready() -> void:
	spawn_position = global_position
	health = max_health
	health_changed.emit(health, max_health)
	potion_changed.emit(potion_charges)
	sprite_presenter.reset_presentation()


func _physics_process(delta: float) -> void:
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	ranged_cooldown_remaining = maxf(0.0, ranged_cooldown_remaining - delta)
	_tick_melee(delta)
	_tick_ranged(delta)

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_direction = _camera_relative_direction(input_vector)
	if move_direction.length_squared() > 0.0001:
		combat_facing = move_direction

	_resolve_action_requests()

	if dash_remaining > 0.0:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		velocity = dash_direction * DASH_SPEED
	else:
		var move_speed := MOVE_SPEED * GUARD_MOVE_MULTIPLIER if guarding else MOVE_SPEED
		var desired := move_direction * move_speed if melee_remaining <= 0.0 else Vector3.ZERO
		var rate := ACCELERATION if desired.length_squared() > 0.0 else BRAKING
		velocity.x = move_toward(velocity.x, desired.x, rate * delta)
		velocity.z = move_toward(velocity.z, desired.z, rate * delta)
		velocity.y = 0.0
	if Input.is_action_just_pressed("potion"):
		_use_potion()

	var position_before_move := global_position
	move_and_slide()
	var frame_displacement := global_position - position_before_move
	var traveled_distance := Vector2(frame_displacement.x, frame_displacement.z).length()
	var facing_yaw := atan2(-combat_facing.x, -combat_facing.z)
	facing_feedback.rotation.y = facing_yaw
	_update_sprite_presentation(delta, traveled_distance)


func receive_damage(amount: int, source_id: StringName) -> bool:
	if dash_remaining > DASH_DURATION - 0.10:
		action_traced.emit("Dodged %s" % source_id)
		return false
	var applied_amount := amount
	if guarding:
		applied_amount = maxi(1, ceili(float(amount) * GUARD_DAMAGE_MULTIPLIER))
		action_traced.emit("Guarded · -%d" % applied_amount)
	health = maxi(0, health - applied_amount)
	health_changed.emit(health, max_health)
	if not guarding:
		action_traced.emit("-%d · %s" % [applied_amount, source_id])
	if health <= 0:
		reset_training()
	return true


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func reset_training() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	health = max_health
	potion_charges = 3
	dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	melee_remaining = 0.0
	ranged_cooldown_remaining = 0.0
	ranged_action_remaining = 0.0
	ranged_release_fired = false
	ranged_direction = Vector3.FORWARD
	move_direction = Vector3.ZERO
	combat_facing = Vector3.FORWARD
	resolved_attack_direction = Vector3.FORWARD
	targeting_assist.reset_assist()
	_set_guarding(false)
	sprite_presenter.reset_presentation()
	health_changed.emit(health, max_health)
	potion_changed.emit(potion_charges)
	action_traced.emit("Training reset")


func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() <= 0.0001:
		return Vector3.ZERO
	var camera_right := camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var camera_forward := -camera.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	return (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()


func _update_sprite_presentation(delta: float, traveled_distance: float) -> void:
	var melee_progress := -1.0
	if melee_remaining > 0.0:
		melee_progress = 1.0 - melee_remaining / MELEE_DURATION
	var ranged_progress := -1.0
	if ranged_action_remaining > 0.0:
		ranged_progress = 1.0 - ranged_action_remaining / RANGED_ACTION_DURATION
	sprite_presenter.present_state(
		combat_facing,
		camera,
		traveled_distance,
		melee_progress,
		ranged_progress,
		guarding,
		delta,
	)


func _start_dash(requested_direction: Vector3) -> void:
	dash_direction = requested_direction if requested_direction.length_squared() > 0.0001 else combat_facing
	dash_remaining = DASH_DURATION
	dash_cooldown_remaining = DASH_COOLDOWN
	action_traced.emit("Dash")


func _resolve_action_requests() -> void:
	var can_guard := (
		dash_remaining <= 0.0
		and melee_remaining <= 0.0
		and ranged_action_remaining <= 0.0
	)
	if Input.is_action_pressed("guard") and can_guard:
		_set_guarding(true)
		return
	_set_guarding(false)

	if (
		Input.is_action_just_pressed("dash")
		and dash_cooldown_remaining <= 0.0
		and melee_remaining <= 0.0
		and ranged_action_remaining <= 0.0
	):
		_start_dash(move_direction)
		return
	if (
		Input.is_action_just_pressed("melee")
		and melee_remaining <= 0.0
		and ranged_action_remaining <= 0.0
		and dash_remaining <= 0.0
	):
		_start_melee()
		return
	if (
		Input.is_action_just_pressed("ranged")
		and ranged_cooldown_remaining <= 0.0
		and melee_remaining <= 0.0
		and dash_remaining <= 0.0
	):
		_start_ranged()


func _set_guarding(next_guarding: bool) -> void:
	if guarding == next_guarding:
		return
	guarding = next_guarding
	if guarding:
		action_traced.emit("Guard")


func _start_melee() -> void:
	resolved_attack_direction = _resolve_attack_direction(
		&"melee",
		global_position + Vector3.UP * 0.75,
	)
	melee_remaining = MELEE_DURATION
	melee_hit_fired = false
	action_traced.emit("Sword")


func _tick_melee(delta: float) -> void:
	if melee_remaining <= 0.0:
		return
	melee_remaining = maxf(0.0, melee_remaining - delta)
	var progress := 1.0 - melee_remaining / MELEE_DURATION
	if not melee_hit_fired and progress >= MELEE_HIT_TIME / MELEE_DURATION:
		melee_hit_fired = true
		_apply_melee_hit()


func _apply_melee_hit() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 1.15
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(
		Basis.IDENTITY,
		global_position + resolved_attack_direction * 1.35 + Vector3.UP * 0.6,
	)
	query.collision_mask = 1 << 2
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var collider: Object = hit["collider"]
		if collider.has_method("receive_hit"):
			collider.receive_hit(20, 20, &"sword")


func _start_ranged() -> void:
	resolved_attack_direction = _resolve_attack_direction(
		&"ranged",
		global_position + Vector3.UP * 0.75,
	)
	ranged_direction = resolved_attack_direction
	ranged_action_remaining = RANGED_ACTION_DURATION
	ranged_release_fired = false
	ranged_cooldown_remaining = RANGED_COOLDOWN
	action_traced.emit("Ranged draw")


func _tick_ranged(delta: float) -> void:
	if ranged_action_remaining <= 0.0:
		return
	ranged_action_remaining = maxf(0.0, ranged_action_remaining - delta)
	var elapsed := RANGED_ACTION_DURATION - ranged_action_remaining
	if not ranged_release_fired and elapsed >= RANGED_RELEASE_TIME:
		ranged_release_fired = true
		_spawn_ranged_projectile()


func _spawn_ranged_projectile() -> void:
	var projectile := ProofProjectile3D.new()
	get_parent().add_child(projectile)
	projectile.configure(
		global_position + ranged_direction * 0.8 + Vector3.UP * 0.75,
		ranged_direction,
	)
	action_traced.emit("Ranged shot")


func _resolve_attack_direction(kind: StringName, origin: Vector3) -> Vector3:
	var result := targeting_assist.resolve_attack(kind, origin, combat_facing)
	if result.assisted:
		combat_facing = result.direction
	return result.direction


func _use_potion() -> void:
	if potion_charges <= 0 or health >= max_health:
		action_traced.emit("Potion unavailable")
		return
	potion_charges -= 1
	heal(35)
	potion_changed.emit(potion_charges)
	action_traced.emit("Potion restored health")
