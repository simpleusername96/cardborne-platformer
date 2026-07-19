class_name RoomGate3D
extends Area3D

signal transition_requested(target_room_id: StringName, target_socket_id: StringName)

@export var socket_id: StringName
@export var target_room_id: StringName
@export var target_socket_id: StringName
@export var facing: StringName

var _traveler_inside := false
var locked := false


func _ready() -> void:
	add_to_group(&"room_gates")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _traveler_inside and event.is_action_pressed("interact") and not event.is_echo():
		if locked:
			var traveler := _traveler_in_gate()
			if traveler != null:
				traveler.action_traced.emit("Gate sealed · objective incomplete")
		else:
			transition_requested.emit(target_room_id, target_socket_id)
		get_viewport().set_input_as_handled()


func set_locked(value: bool) -> void:
	locked = value
	for child in get_children():
		var visual := child as MeshInstance3D
		if visual == null:
			continue
		if locked:
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.55, 0.20, 0.17)
			material.emission_enabled = true
			material.emission = Color(0.85, 0.42, 0.32)
			material.emission_energy_multiplier = 0.35
			visual.material_override = material
		else:
			visual.material_override = null


func _traveler_in_gate() -> Traveler3D:
	for body in get_overlapping_bodies():
		if body is Traveler3D:
			return body
	return null


func _on_body_entered(body: Node3D) -> void:
	if body is Traveler3D:
		_traveler_inside = true
		body.action_traced.emit("V · Enter gate")


func _on_body_exited(body: Node3D) -> void:
	if body is Traveler3D:
		_traveler_inside = false
