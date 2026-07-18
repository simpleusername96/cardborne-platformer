class_name SlimeKing3D
extends CharacterBody3D

signal defeated
signal pattern_started(pattern_id: StringName)

enum State { NEUTRAL, STARTUP, ACTIVE, RECOVERY, DEFEATED }

const MAX_HEALTH := 600
const PATTERNS: Array[StringName] = [&"lane_charge", &"landing_slam", &"poison_bands", &"pressure_nodes"]

var health := MAX_HEALTH
var state := State.NEUTRAL
var state_remaining := 1.0
var pattern_index := -1
var current_pattern: StringName
var target: Traveler3D
var charge_direction := Vector3.FORWARD
var charge_hit := false


func configure(next_target: Traveler3D) -> void:
	target = next_target


func _ready() -> void:
	add_to_group(&"attack_targets")
	add_to_group(&"floor_enemies")
	collision_layer = 1 << 2
	collision_mask = 1 << 0


func _physics_process(delta: float) -> void:
	if target == null or state == State.DEFEATED:
		return
	state_remaining = maxf(0.0, state_remaining - delta)
	if state == State.NEUTRAL and state_remaining <= 0.0:
		_start_next_pattern()
	elif state == State.STARTUP and state_remaining <= 0.0:
		state = State.ACTIVE
		state_remaining = _active_duration(current_pattern)
		_activate_pattern()
	elif state == State.ACTIVE:
		_tick_active(delta)
		if state_remaining <= 0.0:
			state = State.RECOVERY
			state_remaining = 0.9
	elif state == State.RECOVERY and state_remaining <= 0.0:
		state = State.NEUTRAL
		state_remaining = 1.0


func apply_damage(request: DamageRequest3D) -> DamageResult3D:
	if state == State.DEFEATED or request.team != DamageRequest3D.Team.PLAYER:
		return DamageResult3D.rejected()
	health = maxi(0, health - request.damage)
	if health <= 0:
		state = State.DEFEATED
		collision_layer = 0
		_cleanup_hazards()
		defeated.emit()
		return DamageResult3D.applied(request.damage, request.stagger, true)
	return DamageResult3D.applied(request.damage, request.stagger, false)


func receive_hit(damage: int, stagger: int, source_id: StringName) -> void:
	apply_damage(DamageRequest3D.new(damage, stagger, DamageRequest3D.Team.PLAYER, source_id))


func is_targetable() -> bool:
	return state != State.DEFEATED


func _start_next_pattern() -> void:
	pattern_index = (pattern_index + 1) % PATTERNS.size()
	current_pattern = PATTERNS[pattern_index]
	state = State.STARTUP
	state_remaining = _startup_duration(current_pattern)
	pattern_started.emit(current_pattern)
	if current_pattern == &"lane_charge":
		charge_direction = target.global_position - global_position
		charge_direction.y = 0.0
		charge_direction = charge_direction.normalized()
		charge_hit = false
		_spawn_hazard(global_position + charge_direction * 4.0, Vector2(3.0, 9.0), 0.75, 0.1, 0, true, atan2(-charge_direction.x, -charge_direction.z))
	elif current_pattern == &"landing_slam":
		_spawn_hazard(target.global_position, Vector2(4.2, 4.2), 0.9, 0.18, 26, false)


func _activate_pattern() -> void:
	if current_pattern == &"poison_bands":
		_spawn_hazard(Vector3(-5.5, 0, 0), Vector2(5.0, 18.0), 0.1, 1.2, 18, false)
		_spawn_hazard(Vector3(5.5, 0, 0), Vector2(5.0, 18.0), 0.1, 1.2, 18, false)
	elif current_pattern == &"pressure_nodes":
		for position in [Vector3(-5, 0, -3), Vector3(5, 0, 3), Vector3(0, 0, 5)]:
			_spawn_hazard(position, Vector2(3.0, 3.0), 0.2, 0.22, 20, false)


func _tick_active(delta: float) -> void:
	if current_pattern != &"lane_charge":
		return
	velocity = charge_direction * 9.0
	move_and_slide()
	if not charge_hit and global_position.distance_to(target.global_position) <= 1.9:
		charge_hit = true
		target.apply_damage(DamageRequest3D.new(24, 30, DamageRequest3D.Team.ENEMY, &"slime_charge"))
	if state_remaining <= delta:
		velocity = Vector3.ZERO


func _spawn_hazard(position: Vector3, size: Vector2, startup: float, active: float, damage: int, blockable: bool, yaw: float = 0.0) -> void:
	var hazard := BossHazardZone3D.new()
	get_parent().add_child(hazard)
	hazard.configure(size, startup, active, damage, blockable)
	hazard.global_position = Vector3(position.x, 0.0, position.z)
	hazard.rotation.y = yaw


func _cleanup_hazards() -> void:
	for node in get_tree().get_nodes_in_group(&"combat_effects"):
		if get_parent().is_ancestor_of(node):
			node.queue_free()


func _startup_duration(pattern: StringName) -> float:
	match pattern:
		&"lane_charge": return 0.75
		&"landing_slam": return 0.9
		&"poison_bands": return 0.8
		_: return 0.85


func _active_duration(pattern: StringName) -> float:
	return 0.85 if pattern == &"lane_charge" else 1.2 if pattern == &"poison_bands" else 0.22
