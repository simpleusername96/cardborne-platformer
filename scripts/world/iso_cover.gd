class_name IsoCover
extends StaticBody2D

@export var cover_size := Vector2(210, 84)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var half := cover_size * 0.5
	var lift := 32.0
	var top := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	var front := PackedVector2Array([
		Vector2(-half.x, half.y), Vector2(half.x, half.y),
		Vector2(half.x, half.y + lift), Vector2(-half.x, half.y + lift),
	])
	var side := PackedVector2Array([
		Vector2(half.x, -half.y), Vector2(half.x, half.y),
		Vector2(half.x, half.y + lift), Vector2(half.x, -half.y + lift),
	])
	draw_polygon(front, PackedColorArray([Color("12171a")]))
	draw_polygon(side, PackedColorArray([Color("1c2428")]))
	draw_polygon(top, PackedColorArray([Color("344348")]))
	draw_rect(Rect2(-half.x + 14, -half.y + 12, cover_size.x - 28, 8), Color("6f8f62"))
