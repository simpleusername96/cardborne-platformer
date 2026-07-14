class_name HUDGlyph
extends Control

var icon_id: StringName = &"basic"
var tone: Color = Color.WHITE
var muted: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(18.0, 18.0)
	queue_redraw()


func configure(next_icon_id: StringName, next_tone: Color, is_muted: bool = false) -> void:
	icon_id = next_icon_id
	tone = next_tone
	muted = is_muted
	queue_redraw()


func _draw() -> void:
	var draw_tone := Color(tone, 0.42 if muted else tone.a)
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var width := maxf(radius * 0.15, 1.5)
	match icon_id:
		&"basic", &"attack", &"melee":
			_draw_blade(center, radius, draw_tone, width)
		&"heavy":
			_draw_hammer(center, radius, draw_tone, width)
		&"skill_1", &"guard", &"armor":
			_draw_shield(center, radius, draw_tone, width)
		&"skill_2":
			_draw_split(center, radius, draw_tone, width)
		&"skill_3":
			_draw_banner(center, radius, draw_tone, width)
		&"consumable", &"potion":
			_draw_bottle(center, radius, draw_tone, width)
		&"warrior":
			_draw_shield(center, radius, draw_tone, width)
		&"assassin":
			_draw_twin_blades(center, radius, draw_tone, width)
		&"archer", &"ranged":
			_draw_bow(center, radius, draw_tone, width)
		&"coin":
			draw_circle(center, radius * 0.82, draw_tone)
			draw_arc(center, radius * 0.48, 0.0, TAU, 20, draw_tone.darkened(0.3), width)
		&"rusted_scrap":
			_draw_polygon_outline(_hexagon(center, radius * 0.88), draw_tone, width)
			draw_line(center + Vector2(-radius * 0.38, 0.0), center + Vector2(radius * 0.38, 0.0), draw_tone, width)
		&"sky_thread":
			_draw_diamond(center, radius, draw_tone, width, true)
		&"slime_residue":
			var drop := PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius * 0.72, radius * 0.22),
				center + Vector2(radius * 0.45, radius * 0.82),
				center + Vector2(-radius * 0.45, radius * 0.82),
				center + Vector2(-radius * 0.72, radius * 0.22),
			])
			draw_colored_polygon(drop, Color(draw_tone, draw_tone.a * 0.76))
			_draw_polygon_outline(drop, draw_tone, width)
		&"boss_core":
			var core := _hexagon(center, radius)
			draw_colored_polygon(core, Color(draw_tone, draw_tone.a * 0.36))
			_draw_polygon_outline(core, draw_tone, width)
			draw_circle(center, radius * 0.28, draw_tone)
		_:
			_draw_diamond(center, radius, draw_tone, width, false)


func _draw_blade(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_line(
		center + Vector2(-radius * 0.72, radius * 0.72),
		center + Vector2(radius * 0.72, -radius * 0.72),
		color,
		width * 1.35,
		true
	)
	draw_line(
		center + Vector2(-radius * 0.62, radius * 0.18),
		center + Vector2(-radius * 0.12, radius * 0.68),
		color,
		width,
		true
	)


func _draw_hammer(center: Vector2, radius: float, color: Color, width: float) -> void:
	var head := Rect2(
		center + Vector2(-radius * 0.76, -radius * 0.62),
		Vector2(radius * 1.52, radius * 0.62)
	)
	draw_rect(head, color, false, width)
	draw_line(center + Vector2(0.0, -radius * 0.02), center + Vector2(0.0, radius * 0.88), color, width * 1.25)


func _draw_shield(center: Vector2, radius: float, color: Color, width: float) -> void:
	var shield := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.78, -radius * 0.48),
		center + Vector2(radius * 0.62, radius * 0.42),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.62, radius * 0.42),
		center + Vector2(-radius * 0.78, -radius * 0.48),
	])
	draw_colored_polygon(shield, Color(color, color.a * 0.22))
	_draw_polygon_outline(shield, color, width)


func _draw_split(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_line(center + Vector2(0.0, radius), center + Vector2(0.0, -radius * 0.18), color, width)
	draw_line(center + Vector2(0.0, -radius * 0.18), center + Vector2(-radius * 0.68, -radius * 0.82), color, width)
	draw_line(center + Vector2(0.0, -radius * 0.18), center + Vector2(radius * 0.68, -radius * 0.82), color, width)
	draw_circle(center + Vector2(-radius * 0.68, -radius * 0.82), width * 0.85, color)
	draw_circle(center + Vector2(radius * 0.68, -radius * 0.82), width * 0.85, color)


func _draw_banner(center: Vector2, radius: float, color: Color, width: float) -> void:
	var pole_x := center.x - radius * 0.48
	draw_line(Vector2(pole_x, center.y - radius), Vector2(pole_x, center.y + radius), color, width)
	var banner := PackedVector2Array([
		Vector2(pole_x, center.y - radius * 0.82),
		center + Vector2(radius * 0.72, -radius * 0.62),
		center + Vector2(radius * 0.34, -radius * 0.08),
		Vector2(pole_x, center.y - radius * 0.18),
	])
	draw_colored_polygon(banner, Color(color, color.a * 0.62))
	_draw_polygon_outline(banner, color, width)


func _draw_bottle(center: Vector2, radius: float, color: Color, width: float) -> void:
	var neck := Rect2(
		center + Vector2(-radius * 0.24, -radius),
		Vector2(radius * 0.48, radius * 0.42)
	)
	draw_rect(neck, color, false, width)
	var body := PackedVector2Array([
		center + Vector2(-radius * 0.48, -radius * 0.54),
		center + Vector2(radius * 0.48, -radius * 0.54),
		center + Vector2(radius * 0.72, radius * 0.62),
		center + Vector2(radius * 0.42, radius),
		center + Vector2(-radius * 0.42, radius),
		center + Vector2(-radius * 0.72, radius * 0.62),
	])
	draw_colored_polygon(body, Color(color, color.a * 0.28))
	_draw_polygon_outline(body, color, width)


func _draw_twin_blades(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_line(center + Vector2(-radius, radius * 0.68), center + Vector2(radius * 0.55, -radius), color, width, true)
	draw_line(center + Vector2(radius, radius * 0.68), center + Vector2(-radius * 0.55, -radius), color, width, true)


func _draw_bow(center: Vector2, radius: float, color: Color, width: float) -> void:
	draw_arc(center + Vector2(-radius * 0.08, 0.0), radius * 0.92, -PI * 0.55, PI * 0.55, 16, color, width)
	draw_line(center + Vector2(-radius * 0.12, -radius * 0.92), center + Vector2(-radius * 0.12, radius * 0.92), color, width)
	draw_line(center + Vector2(-radius * 0.5, 0.0), center + Vector2(radius, 0.0), color, width)
	draw_line(center + Vector2(radius, 0.0), center + Vector2(radius * 0.62, -radius * 0.24), color, width)
	draw_line(center + Vector2(radius, 0.0), center + Vector2(radius * 0.62, radius * 0.24), color, width)


func _draw_diamond(
	center: Vector2,
	radius: float,
	color: Color,
	width: float,
	filled: bool
) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.72, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.72, 0.0),
	])
	if filled:
		draw_colored_polygon(points, Color(color, color.a * 0.42))
	_draw_polygon_outline(points, color, width)


func _hexagon(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 6:
		points.append(center + Vector2.RIGHT.rotated(PI / 6.0 + TAU * float(index) / 6.0) * radius)
	return points


func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.is_empty():
		return
	for index in points.size():
		draw_line(points[index], points[(index + 1) % points.size()], color, width, true)
