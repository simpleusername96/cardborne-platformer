class_name ProductionStageBackdrop
extends Node2D

var _world_bounds := Rect2(0.0, 0.0, 2400.0, 720.0)
var _stage_id: StringName = &"ruin_approach"


func _ready() -> void:
	z_index = -20
	queue_redraw()


func configure(world_bounds: Rect2, stage_id: StringName = &"ruin_approach") -> void:
	if world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0:
		_world_bounds = world_bounds.grow(240.0)
	_stage_id = stage_id
	queue_redraw()


func _draw() -> void:
	var left := _world_bounds.position.x
	var top := _world_bounds.position.y
	var right := _world_bounds.end.x
	var bottom := _world_bounds.end.y
	var width := _world_bounds.size.x
	var ridge_y := top + _world_bounds.size.y * 0.48
	var background := Color("11191a") if _stage_id == &"flooded_works" else Color("12171a")
	var distant := Color("173033") if _stage_id == &"flooded_works" else Color("182225")
	var structure := Color("26383a") if _stage_id == &"flooded_works" else Color("222d31")
	var trim := Color("4d817b") if _stage_id == &"flooded_works" else Color("314038")
	draw_rect(_world_bounds, background)
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
	]), distant)

	var pillar_x := left + 160.0
	while pillar_x < right:
		draw_rect(Rect2(pillar_x, top + 170.0, 44.0, 350.0), structure)
		draw_rect(Rect2(pillar_x - 14.0, top + 170.0, 72.0, 16.0), trim)
		pillar_x += 420.0
	draw_rect(Rect2(left, ridge_y + 40.0, width, 8.0), Color("253034"))
	if _stage_id == &"flooded_works":
		var water_y := bottom - 150.0
		draw_rect(Rect2(left, water_y, width, 150.0), Color("17434a", 0.62))
		draw_rect(Rect2(left, water_y, width, 5.0), Color("67b7b2", 0.78))
		var pipe_x := left + 300.0
		while pipe_x < right:
			draw_rect(Rect2(pipe_x, top + 90.0, 120.0, 20.0), Color("664f3f"))
			draw_rect(Rect2(pipe_x + 100.0, top + 90.0, 20.0, 105.0), Color("664f3f"))
			pipe_x += 760.0
