class_name EnemyHealthBar3D
extends Node3D

const BAR_WIDTH := 1.2

@onready var fill: MeshInstance3D = $Fill


func set_health(current: int, maximum: int) -> void:
	var ratio := clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)
	fill.scale.x = ratio
	fill.position.x = -BAR_WIDTH * (1.0 - ratio) * 0.5
	visible = current > 0
