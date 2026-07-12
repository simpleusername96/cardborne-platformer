class_name ProductionStageBackdrop
extends Node2D

var _world_bounds := Rect2(0.0, 0.0, 2400.0, 720.0)


func _ready() -> void:
	z_index = -20
	queue_redraw()


func configure(world_bounds: Rect2) -> void:
	if world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0:
		_world_bounds = world_bounds.grow(240.0)
	queue_redraw()


func _draw() -> void:
	var left := _world_bounds.position.x
	var top := _world_bounds.position.y
	var right := _world_bounds.end.x
	var bottom := _world_bounds.end.y
	var width := _world_bounds.size.x
	var ridge_y := top + _world_bounds.size.y * 0.48
	draw_rect(_world_bounds, Color("12171a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, ridge_y),
		Vector2(left + width * 0.12, ridge_y - 70.0),
		Vector2(left + width * 0.25, ridge_y + 10.0),
		Vector2(left + width * 0.40, ridge_y - 95.0),
		Vector2(left + width * 0.55, ridge_y - 20.0),
		Vector2(left + width * 0.72, ridge_y - 110.0),
		Vector2(left + width * 0.88, ridge_y - 35.0),
		Vector2(right, ridge_y - 90.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	]), Color("182225"))

	var pillar_x := left + 160.0
	while pillar_x < right:
		draw_rect(Rect2(pillar_x, top + 170.0, 44.0, 350.0), Color("222d31"))
		draw_rect(Rect2(pillar_x - 14.0, top + 170.0, 72.0, 16.0), Color("314038"))
		pillar_x += 420.0
	draw_rect(Rect2(left, ridge_y + 40.0, width, 8.0), Color("253034"))
