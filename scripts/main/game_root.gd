class_name GameRoot
extends Node

## Registers the vehicle controls before the run enters the tree.

const InputProfile = preload("res://scripts/input/vehicle_input_profile.gd")


func _enter_tree() -> void:
	_register_input_map()
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_signal("controls_changed"):
		settings.controls_changed.connect(_on_controls_changed)


func _register_input_map() -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	var bindings := InputProfile.default_descriptors()
	if settings != null:
		bindings = settings.control_bindings
	InputProfile.apply_input_map(bindings)


func _on_controls_changed(_action: StringName) -> void:
	_register_input_map()
