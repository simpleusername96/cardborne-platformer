class_name ThreatCoordinator3D
extends RefCounted

var close_holder: EnemyActor3D
var pressure_holder: EnemyActor3D


func request_token(actor: EnemyActor3D, kind: StringName) -> bool:
	if kind == &"close":
		if close_holder == null or not is_instance_valid(close_holder) or close_holder == actor:
			close_holder = actor
			return true
		return false
	if pressure_holder == null or not is_instance_valid(pressure_holder) or pressure_holder == actor:
		pressure_holder = actor
		return true
	return false


func release(actor: EnemyActor3D) -> void:
	if close_holder == actor:
		close_holder = null
	if pressure_holder == actor:
		pressure_holder = null
