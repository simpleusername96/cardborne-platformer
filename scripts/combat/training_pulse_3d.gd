class_name TrainingPulse3D
extends Area3D

enum PulseState { RECOVERY, STARTUP, ACTIVE }

var state := PulseState.RECOVERY
var elapsed := 1.0

@onready var ring: MeshInstance3D = $Ring


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	monitoring = true


func _physics_process(delta: float) -> void:
	elapsed += delta
	if state == PulseState.RECOVERY and elapsed >= 2.5:
		_set_state(PulseState.STARTUP)
	elif state == PulseState.STARTUP and elapsed >= 0.8:
		_set_state(PulseState.ACTIVE)
		for body in get_overlapping_bodies():
			if body.has_method("receive_damage"):
				body.receive_damage(18, &"training_pulse")
	elif state == PulseState.ACTIVE and elapsed >= 0.18:
		_set_state(PulseState.RECOVERY)
	_update_material()


func reset_pulse() -> void:
	state = PulseState.RECOVERY
	elapsed = 1.0
	_update_material()


func _set_state(next_state: PulseState) -> void:
	state = next_state
	elapsed = 0.0


func _update_material() -> void:
	var material := ring.material_override as StandardMaterial3D
	if material == null:
		return
	if state == PulseState.RECOVERY:
		material.albedo_color = Color(0.384, 0.663, 0.71, 0.28)
		material.emission_energy_multiplier = 0.4
	elif state == PulseState.STARTUP:
		material.albedo_color = Color("d9654f")
		material.emission_energy_multiplier = 1.2
	else:
		material.albedo_color = Color("f0f1e8")
		material.emission_energy_multiplier = 2.4
