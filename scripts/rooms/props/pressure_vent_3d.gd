class_name PressureVent3D
extends Area3D

enum State { WARNING, ACTIVE, RECOVERY, INERT }

const WARNING_SECONDS := 0.8
const ACTIVE_SECONDS := 0.18
const RECOVERY_SECONDS := 2.5

var state := State.RECOVERY
var elapsed := 1.0
var hit_this_activation := false

@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	add_to_group(&"combat_effects")
	collision_layer = 0
	collision_mask = 1 << 1


func _physics_process(delta: float) -> void:
	if state == State.INERT:
		return
	elapsed += delta
	if state == State.RECOVERY and elapsed >= RECOVERY_SECONDS:
		_set_state(State.WARNING)
	elif state == State.WARNING and elapsed >= WARNING_SECONDS:
		_set_state(State.ACTIVE)
		_apply_once()
	elif state == State.ACTIVE and elapsed >= ACTIVE_SECONDS:
		_set_state(State.RECOVERY)


func make_inert() -> void:
	_set_state(State.INERT)


func _apply_once() -> void:
	if hit_this_activation:
		return
	hit_this_activation = true
	for body in get_overlapping_bodies():
		if body.has_method("apply_damage"):
			body.apply_damage(DamageRequest3D.new(16, 0, DamageRequest3D.Team.ENVIRONMENT, &"pressure_vent", false))


func _set_state(next_state: State) -> void:
	state = next_state
	elapsed = 0.0
	if state == State.WARNING:
		hit_this_activation = false
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	match state:
		State.WARNING:
			material.albedo_color = Color(0.65, 0.30, 0.24, 0.75)
		State.ACTIVE:
			material.albedo_color = Color(0.95, 0.82, 0.48, 0.9)
		State.INERT:
			material.albedo_color = Color(0.18, 0.28, 0.29, 0.45)
		_:
			material.albedo_color = Color(0.25, 0.45, 0.45, 0.25)
