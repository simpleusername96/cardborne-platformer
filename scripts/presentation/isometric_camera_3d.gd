class_name IsometricCameraRig3D
extends Node3D

@export var target := Vector3(0.0, 0.8, 0.0)

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.look_at(target, Vector3.UP)
