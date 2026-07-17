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

@export var max_health := 100

var health := 100
var potion_charges := 3
var facing := Vector3(0, 0, -1)
var spawn_position := Vector3.ZERO
var dash_remaining := 0.0
var dash_cooldown_remaining := 0.0
var dash_direction := Vector3.ZERO
var melee_remaining := 0.0
var melee_hit_fired := false
var ranged_cooldown_remaining := 0.0

@onready var camera: Camera3D = get_node("../CameraRig/Camera3D")
@onready var visual: Node3D = $Visual
@onready var sword_pivot: Node3D = $Visual/SwordPivot


func _ready() -> void:
	spawn_position = global_position
	health = max_health
	health_changed.emit(health, max_health)
	potion_changed.emit(potion_charges)


func _physics_process(delta: float) -> void:
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	ranged_cooldown_remaining = maxf(0.0, ranged_cooldown_remaining - delta)
	_tick_melee(delta)

	if dash_remaining > 0.0:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		velocity = dash_direction * DASH_SPEED
	else:
		var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var move_direction := _camera_relative_direction(input_vector)
		if move_direction.length_squared() > 0.0001:
			facing = move_direction
		var desired := move_direction * MOVE_SPEED if melee_remaining <= 0.0 else Vector3.ZERO
		var rate := ACCELERATION if desired.length_squared() > 0.0 else BRAKING
		velocity.x = move_toward(velocity.x, desired.x, rate * delta)
		velocity.z = move_toward(velocity.z, desired.z, rate * delta)
		velocity.y = 0.0
		if Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0.0 and melee_remaining <= 0.0:
			_start_dash(move_direction)

	if Input.is_action_just_pressed("melee") and melee_remaining <= 0.0 and dash_remaining <= 0.0:
		_start_melee()
	if Input.is_action_just_pressed("ranged") and ranged_cooldown_remaining <= 0.0 and dash_remaining <= 0.0:
		_fire_ranged()
	if Input.is_action_just_pressed("interact"):
		action_traced.emit("Interact")
	if Input.is_action_just_pressed("potion"):
		_use_potion()

	move_and_slide()
	visual.rotation.y = atan2(facing.x, facing.z)


func receive_damage(amount: int, source_id: StringName) -> bool:
	if dash_remaining > DASH_DURATION - 0.10:
		action_traced.emit("Dodged %s" % source_id)
		return false
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	action_traced.emit("-%d · %s" % [amount, source_id])
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


func _start_dash(requested_direction: Vector3) -> void:
	dash_direction = requested_direction if requested_direction.length_squared() > 0.0001 else facing
	dash_remaining = DASH_DURATION
	dash_cooldown_remaining = DASH_COOLDOWN
	action_traced.emit("Dash")


func _start_melee() -> void:
	melee_remaining = MELEE_DURATION
	melee_hit_fired = false
	action_traced.emit("Sword")


func _tick_melee(delta: float) -> void:
	if melee_remaining <= 0.0:
		sword_pivot.rotation.y = lerpf(sword_pivot.rotation.y, 0.0, minf(1.0, delta * 18.0))
		return
	melee_remaining = maxf(0.0, melee_remaining - delta)
	var progress := 1.0 - melee_remaining / MELEE_DURATION
	sword_pivot.rotation.y = lerpf(-1.15, 1.2, progress)
	if not melee_hit_fired and progress >= MELEE_HIT_TIME / MELEE_DURATION:
		melee_hit_fired = true
		_apply_melee_hit()


func _apply_melee_hit() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 1.15
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position + facing * 1.35 + Vector3.UP * 0.6)
	query.collision_mask = 1 << 2
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var collider: Object = hit["collider"]
		if collider.has_method("receive_hit"):
			collider.receive_hit(20, 20, &"sword")


func _fire_ranged() -> void:
	var projectile := ProofProjectile3D.new()
	get_parent().add_child(projectile)
	projectile.configure(global_position + facing * 0.8 + Vector3.UP * 0.75, facing)
	ranged_cooldown_remaining = RANGED_COOLDOWN
	action_traced.emit("Ranged shot")


func _use_potion() -> void:
	if potion_charges <= 0 or health >= max_health:
		action_traced.emit("Potion unavailable")
		return
	potion_charges -= 1
	heal(35)
	potion_changed.emit(potion_charges)
	action_traced.emit("Potion restored health")
