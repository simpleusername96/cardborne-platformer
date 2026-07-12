class_name ProductionBackdrop
extends Control


func _init() -> void:
	name = "Backdrop"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	draw_rect(Rect2(Vector2.ZERO, size), ProductionUIStyles.BACKGROUND)

	var distant := Color("1a2426")
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, height * 0.35),
		Vector2(width * 0.13, height * 0.31),
		Vector2(width * 0.21, height * 0.39),
		Vector2(width * 0.34, height * 0.25),
		Vector2(width * 0.48, height * 0.36),
		Vector2(width * 0.62, height * 0.23),
		Vector2(width * 0.75, height * 0.37),
		Vector2(width, height * 0.28),
		Vector2(width, height),
		Vector2(0.0, height),
	]), distant)

	for column in [0.08, 0.27, 0.55, 0.79, 0.92]:
		var x := width * float(column)
		var column_height := height * (0.30 + fmod(float(column) * 7.0, 0.18))
		draw_rect(
			Rect2(Vector2(x, height * 0.30), Vector2(maxf(18.0, width * 0.022), column_height)),
			Color("253034")
		)

	var foreground := Color("202b2f")
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, height * 0.76),
		Vector2(width * 0.18, height * 0.76),
		Vector2(width * 0.18, height * 0.68),
		Vector2(width * 0.36, height * 0.68),
		Vector2(width * 0.36, height * 0.73),
		Vector2(width * 0.60, height * 0.73),
		Vector2(width * 0.60, height * 0.61),
		Vector2(width * 0.82, height * 0.61),
		Vector2(width * 0.82, height * 0.70),
		Vector2(width, height * 0.70),
		Vector2(width, height),
		Vector2(0.0, height),
	]), foreground)
	draw_rect(Rect2(Vector2(0.0, height * 0.76), Vector2(width * 0.18, 5.0)), ProductionUIStyles.MOSS)
	draw_rect(Rect2(Vector2(width * 0.60, height * 0.61), Vector2(width * 0.22, 5.0)), ProductionUIStyles.CYAN)
	draw_rect(Rect2(Vector2(width * 0.88, height * 0.49), Vector2(width * 0.035, height * 0.21)), ProductionUIStyles.AMBER)
