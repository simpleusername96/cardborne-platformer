class_name PlayerActionController
extends Node

signal action_started(label: String)
signal potion_consumed(charges_remaining: int)

enum ActionState { IDLE, MELEE, RANGED, POTION }

const SWORD_ONE: AttackDefinition = preload("res://data/attacks/proof/sword_hit_1.tres")
const SWORD_TWO: AttackDefinition = preload("res://data/attacks/proof/sword_hit_2.tres")
const RANGED_SHOT: AttackDefinition = preload("res://data/attacks/proof/ranged_shot.tres")
const POTION_COMMIT := 0.45

var state := ActionState.IDLE
var elapsed := 0.0
var combo_step := 0
var buffered_melee := false
var activation_fired := false
var aim := Vector2.RIGHT
var potion_charges := 3
var _traveler: Traveler


func setup(traveler: Traveler) -> void:
	_traveler = traveler


func tick(frame: PlayerCommandFrame, delta: float, motor_can_act: bool) -> void:
	if state == ActionState.IDLE:
		if frame.dash_pressed or not motor_can_act:
			return
		if frame.melee_pressed:
			_start_melee(1, frame.aim)
		elif frame.ranged_pressed:
			_start_ranged(frame.aim)
		elif frame.potion_pressed and potion_charges > 0 and _traveler.health < _traveler.max_health:
			_start_potion()
		return

	elapsed += delta
	if state == ActionState.MELEE:
		_tick_melee(frame)
	elif state == ActionState.RANGED:
		_tick_ranged()
	elif state == ActionState.POTION:
		_tick_potion()


func actions_lock_movement() -> bool:
	return state != ActionState.IDLE


func cancel_committed_action_on_damage() -> void:
	if state == ActionState.POTION and not activation_fired:
		action_started.emit("Potion interrupted")
		_finish_action()


func reset() -> void:
	state = ActionState.IDLE
	elapsed = 0.0
	combo_step = 0
	buffered_melee = false
	activation_fired = false
	potion_charges = 3
	potion_consumed.emit(potion_charges)


func _start_melee(step: int, requested_aim: Vector2) -> void:
	state = ActionState.MELEE
	elapsed = 0.0
	combo_step = step
	buffered_melee = false
	activation_fired = false
	aim = requested_aim.normalized()
	action_started.emit("Sword %d" % step)


func _tick_melee(frame: PlayerCommandFrame) -> void:
	var definition := SWORD_ONE if combo_step == 1 else SWORD_TWO
	if not activation_fired and elapsed >= definition.startup:
		activation_fired = true
		_perform_melee_hit(definition)
	var total := definition.startup + definition.active + definition.recovery
	if combo_step == 1 and frame.melee_pressed and elapsed >= total - 0.15:
		buffered_melee = true
	if elapsed < total:
		return
	if combo_step == 1 and buffered_melee:
		_start_melee(2, frame.aim)
	else:
		_finish_action()


func _start_ranged(requested_aim: Vector2) -> void:
	state = ActionState.RANGED
	elapsed = 0.0
	activation_fired = false
	aim = requested_aim.normalized()
	action_started.emit("Ranged shot")


func _tick_ranged() -> void:
	if not activation_fired and elapsed >= RANGED_SHOT.startup:
		activation_fired = true
		var projectile := ProofProjectile.new()
		_traveler.get_parent().add_child(projectile)
		projectile.configure(_traveler.global_position + aim * 34.0, aim, RANGED_SHOT)
	if elapsed >= RANGED_SHOT.startup + RANGED_SHOT.recovery:
		_finish_action()


func _start_potion() -> void:
	state = ActionState.POTION
	elapsed = 0.0
	activation_fired = false
	action_started.emit("Using potion")


func _tick_potion() -> void:
	if elapsed < POTION_COMMIT or activation_fired:
		return
	activation_fired = true
	potion_charges -= 1
	_traveler.heal(roundi(_traveler.max_health * 0.35))
	potion_consumed.emit(potion_charges)
	action_started.emit("Potion restored health")
	_finish_action()


func _perform_melee_hit(definition: AttackDefinition) -> void:
	var shape := CircleShape2D.new()
	shape.radius = definition.radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, _traveler.global_position + aim * definition.reach)
	query.collision_mask = 1 << 2
	query.exclude = [_traveler.get_rid()]
	var hits := _traveler.get_world_2d().direct_space_state.intersect_shape(query, 16)
	var struck: Dictionary = {}
	for hit in hits:
		var collider: Object = hit["collider"]
		if struck.has(collider):
			continue
		struck[collider] = true
		if collider.has_method("receive_hit"):
			collider.receive_hit(definition.damage, definition.stagger, definition.attack_id)


func _finish_action() -> void:
	state = ActionState.IDLE
	elapsed = 0.0
	combo_step = 0
	buffered_melee = false
	activation_fired = false
