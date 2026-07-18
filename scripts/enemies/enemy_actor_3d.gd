class_name EnemyActor3D
extends CharacterBody3D

signal defeated(actor: EnemyActor3D)
signal attack_completed(actor: EnemyActor3D, role: StringName)

enum State { REPOSITION, STARTUP, ACTIVE, RECOVERY, STAGGER, DEFEATED }

@export_enum("pursuer", "shooter", "controller") var role := "pursuer"

var state := State.REPOSITION
var state_remaining := 0.0
var health := 60
var max_health := 60
var move_speed := 3.4
var preferred_range := 1.6
var target: Traveler3D
var coordinator: ThreatCoordinator3D
var token_kind: StringName = &"close"
var motor: EnemyMotor3D
var attack_node: Node
var combat_suspended := false

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	add_to_group(&"attack_targets")
	add_to_group(&"floor_enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 0
	agent.path_height_offset = 0.0
	agent.radius = 0.42
	# The baked walk surface sits one 0.25 m voxel above actor origin; this tolerance
	# lets the agent consume that first vertical-only point without moving on Y.
	agent.path_desired_distance = 0.55
	agent.target_desired_distance = 0.75
	motor = EnemyMotor3D.new(self, agent)
	_apply_role_profile()


func configure(next_target: Traveler3D, next_coordinator: ThreatCoordinator3D) -> void:
	target = next_target
	coordinator = next_coordinator


func _physics_process(delta: float) -> void:
	if target == null or state == State.DEFEATED or combat_suspended:
		return
	state_remaining = maxf(0.0, state_remaining - delta)
	match state:
		State.REPOSITION:
			_tick_reposition(delta)
		State.STARTUP:
			motor.stop()
			_face_target()
			if state_remaining <= 0.0:
				_set_state(State.ACTIVE, 0.12)
				_execute_attack()
		State.ACTIVE:
			motor.stop()
			if state_remaining <= 0.0:
				_set_state(State.RECOVERY, _recovery_duration())
		State.RECOVERY:
			motor.stop()
			if state_remaining <= 0.0:
				coordinator.release(self)
				attack_completed.emit(self, StringName(role))
				_set_state(State.REPOSITION, 0.0)
		State.STAGGER:
			motor.stop()
			if state_remaining <= 0.0:
				_set_state(State.REPOSITION, 0.0)


func apply_damage(request: DamageRequest3D) -> DamageResult3D:
	if state == State.DEFEATED or request.team != DamageRequest3D.Team.PLAYER:
		return DamageResult3D.rejected()
	health = maxi(0, health - request.damage)
	if health <= 0:
		_defeat()
		return DamageResult3D.applied(request.damage, request.stagger, true)
	if request.stagger >= 20:
		_interrupt_to_stagger()
	return DamageResult3D.applied(request.damage, request.stagger, false)


func receive_hit(damage: int, stagger: int, source_id: StringName) -> void:
	apply_damage(DamageRequest3D.new(damage, stagger, DamageRequest3D.Team.PLAYER, source_id))


func is_targetable() -> bool:
	return state != State.DEFEATED


func suspend_combat() -> void:
	combat_suspended = true
	coordinator.release(self)
	motor.stop()
	if attack_node != null and is_instance_valid(attack_node):
		attack_node.queue_free()
	attack_node = null
	_set_state(State.REPOSITION, 0.0)


func get_target_point() -> Vector3:
	return global_position + Vector3.UP * 0.75


func _tick_reposition(delta: float) -> void:
	var distance := global_position.distance_to(target.global_position)
	var destination := target.global_position
	if role != "pursuer" and distance < preferred_range - 1.0:
		var away := global_position - target.global_position
		away.y = 0.0
		destination = global_position + away.normalized() * 3.0
	if distance > preferred_range or role != "pursuer" and distance < preferred_range - 1.0:
		motor.move_toward(destination, move_speed, delta)
	else:
		motor.stop()
		_face_target()
		if coordinator.request_token(self, token_kind):
			_set_state(State.STARTUP, _startup_duration())


func _execute_attack() -> void:
	if role == "pursuer":
		if global_position.distance_to(target.global_position) <= 2.0:
			target.apply_damage(DamageRequest3D.new(16, 16, DamageRequest3D.Team.ENEMY, &"pursuer_swing"))
	elif role == "shooter":
		var projectile := EnemyProjectile3D.new()
		get_parent().add_child(projectile)
		projectile.configure(global_position + Vector3.UP * 0.7, target.global_position + Vector3.UP * 0.7)
		_add_projectile_visual(projectile)
		attack_node = projectile
	else:
		var zone := EnemyPressureZone3D.new()
		get_parent().add_child(zone)
		zone.global_position = target.global_position
		attack_node = zone


func _add_projectile_visual(projectile: EnemyProjectile3D) -> void:
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	shape_node.shape = shape
	projectile.add_child(shape_node)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c7d6cf")
	material.emission_enabled = true
	material.emission = Color("6ca1a0")
	mesh.material = material
	mesh_instance.mesh = mesh
	projectile.add_child(mesh_instance)


func _interrupt_to_stagger() -> void:
	coordinator.release(self)
	if attack_node != null and is_instance_valid(attack_node):
		attack_node.queue_free()
	attack_node = null
	_set_state(State.STAGGER, 0.28)


func _defeat() -> void:
	state = State.DEFEATED
	coordinator.release(self)
	if attack_node != null and is_instance_valid(attack_node):
		attack_node.queue_free()
	attack_node = null
	collision_layer = 0
	visual.scale.y = 0.35
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.25)
	tween.tween_callback(queue_free)


func _apply_role_profile() -> void:
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	match role:
		"shooter":
			max_health = 45
			move_speed = 2.8
			preferred_range = 6.0
			token_kind = &"pressure"
			material.albedo_color = Color("38585a")
			visual.scale = Vector3(0.78, 1.18, 0.78)
		"controller":
			max_health = 70
			move_speed = 2.4
			preferred_range = 5.0
			token_kind = &"pressure"
			material.albedo_color = Color("466564")
			visual.scale = Vector3(1.18, 0.82, 1.18)
		_:
			max_health = 60
			move_speed = 3.4
			preferred_range = 1.6
			token_kind = &"close"
			material.albedo_color = Color("304b4e")
			visual.scale = Vector3(0.88, 0.78, 1.12)
	health = max_health
	visual.material_override = material


func _startup_duration() -> float:
	return 0.42 if role == "pursuer" else 0.62 if role == "shooter" else 0.78


func _recovery_duration() -> float:
	return 0.62 if role == "pursuer" else 0.92 if role == "shooter" else 1.05


func _set_state(next_state: State, duration: float) -> void:
	state = next_state
	state_remaining = duration
	var material := visual.material_override as StandardMaterial3D
	if next_state == State.STARTUP:
		material.emission_enabled = true
		material.emission = Color("d4a33f")
		material.emission_energy_multiplier = 0.55
	else:
		material.emission_enabled = false


func _face_target() -> void:
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)
