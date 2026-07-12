extends Node2D

const WORLD_WIDTH := 2400.0
const VIEW_HEIGHT := 720.0


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, WORLD_WIDTH, VIEW_HEIGHT), Color("12171a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 390.0),
		Vector2(220.0, 320.0),
		Vector2(420.0, 370.0),
		Vector2(690.0, 260.0),
		Vector2(940.0, 350.0),
		Vector2(1210.0, 245.0),
		Vector2(1510.0, 340.0),
		Vector2(1790.0, 230.0),
		Vector2(2060.0, 330.0),
		Vector2(WORLD_WIDTH, 260.0),
		Vector2(WORLD_WIDTH, VIEW_HEIGHT),
		Vector2(0.0, VIEW_HEIGHT),
	]), Color("182225"))

	for x in [120.0, 510.0, 930.0, 1370.0, 1780.0, 2180.0]:
		draw_rect(Rect2(x, 170.0, 44.0, 350.0), Color("222d31"))
		draw_rect(Rect2(x - 14.0, 170.0, 72.0, 16.0), Color("314038"))

	draw_rect(Rect2(0.0, 430.0, WORLD_WIDTH, 8.0), Color("253034"))
	draw_rect(Rect2(1640.0, 210.0, 290.0, 18.0), Color("263b39"))
	draw_rect(Rect2(1910.0, 210.0, 18.0, 210.0), Color("263b39"))
