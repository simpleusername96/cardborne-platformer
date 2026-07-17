class_name TrainingPulse
extends Area2D

enum PulseState { RECOVERY, STARTUP, ACTIVE }

const STARTUP_TIME := 0.75
const ACTIVE_TIME := 0.16
const RECOVERY_TIME := 2.6

var state := PulseState.RECOVERY
var elapsed := 1.2
var _hit_this_activation := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	monitoring = true
	queue_redraw()


func _physics_process(delta: float) -> void:
	elapsed += delta
	if state == PulseState.RECOVERY and elapsed >= RECOVERY_TIME:
		_set_state(PulseState.STARTUP)
	elif state == PulseState.STARTUP and elapsed >= STARTUP_TIME:
		_set_state(PulseState.ACTIVE)
		_apply_pulse()
	elif state == PulseState.ACTIVE and elapsed >= ACTIVE_TIME:
		_set_state(PulseState.RECOVERY)
	queue_redraw()


func reset_pulse() -> void:
	state = PulseState.RECOVERY
	elapsed = 1.2
	_hit_this_activation = false
	queue_redraw()


func _set_state(next_state: PulseState) -> void:
	state = next_state
	elapsed = 0.0
	_hit_this_activation = false


func _apply_pulse() -> void:
	if _hit_this_activation:
		return
	_hit_this_activation = true
	for body in get_overlapping_bodies():
		if body.has_method("receive_damage"):
			body.receive_damage(18, &"training_pulse")


func _draw() -> void:
	var color := Color(0.384, 0.663, 0.71, 0.16)
	var width := 3.0
	if state == PulseState.STARTUP:
		color = Color(0.85, 0.396, 0.31, 0.64)
		width = 7.0
	elif state == PulseState.ACTIVE:
		color = Color(0.85, 0.396, 0.31, 0.92)
		width = 13.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.52))
	draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 64, color, width, true)
	draw_circle(Vector2.ZERO, 18.0, Color("d4a33f"))
