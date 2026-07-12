class_name ProductionPortrait
extends Control

var profile_id: String = "warrior"
var profile_color: Color = ProductionUIStyles.CYAN


func configure(p_profile_id: String, p_profile_color: Color) -> void:
	profile_id = p_profile_id
	profile_color = p_profile_color
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.48)
	draw_rect(Rect2(center + Vector2(-24.0, -12.0), Vector2(48.0, 66.0)), profile_color)
	draw_circle(center + Vector2(0.0, -30.0), 18.0, ProductionUIStyles.TEXT)
	match profile_id:
		"warrior":
			draw_rect(Rect2(center + Vector2(-48.0, 2.0), Vector2(18.0, 48.0)), ProductionUIStyles.MOSS)
			draw_rect(Rect2(center + Vector2(34.0, -4.0), Vector2(6.0, 74.0)), ProductionUIStyles.AMBER)
		"archer":
			draw_arc(center + Vector2(32.0, 10.0), 34.0, -1.4, 1.4, 24, ProductionUIStyles.AMBER, 4.0)
			draw_line(center + Vector2(38.0, -24.0), center + Vector2(38.0, 44.0), ProductionUIStyles.TEXT_MUTED, 2.0)
		"assassin":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-42.0, 8.0),
				center + Vector2(-8.0, 18.0),
				center + Vector2(-36.0, 30.0),
			]), ProductionUIStyles.CORAL)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(42.0, 8.0),
				center + Vector2(8.0, 18.0),
				center + Vector2(36.0, 30.0),
			]), ProductionUIStyles.CORAL)
