class_name VehicleCombatMeshIcon
extends Control

## Small retained combat silhouette used by reports and other dense UI rows.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")

var _instance: MeshInstance2D


func _ready() -> void:
	custom_minimum_size = Vector2(40.0, 40.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)


func set_enemy(archetype: StringName) -> void:
	if not is_instance_valid(_instance):
		_instance = MeshInstance2D.new()
		add_child(_instance)
	_instance.mesh = Visuals.enemy_mesh(archetype)
	_instance.modulate = Visuals.enemy_color(archetype)
	_instance.scale = Vector2(15.0, 15.0)
	_layout()


func _layout() -> void:
	if is_instance_valid(_instance):
		_instance.position = size * 0.5
