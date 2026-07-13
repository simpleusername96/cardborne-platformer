extends Control

var _accent: Color = Color.WHITE
var _kind: StringName = &"card"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(56.0, 56.0)
	queue_redraw()


func configure(kind: StringName, accent: Color) -> void:
	_kind = kind
	_accent = accent
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var unit := minf(size.x, size.y) / 56.0
	draw_circle(center, 24.0 * unit, Color(_accent, 0.10))
	draw_arc(center, 22.0 * unit, 0.0, TAU, 48, Color(_accent, 0.34), 1.5 * unit, true)
	match _kind:
		&"offense":
			_draw_offense(center, unit)
		&"survival":
			_draw_shield(center, unit)
		&"mobility":
			_draw_mobility(center, unit)
		&"tempo":
			_draw_tempo(center, unit)
		&"recovery":
			_draw_recovery(center, unit)
		&"cache":
			_draw_cache(center, unit)
		&"equipment":
			_draw_equipment(center, unit)
		&"forge":
			_draw_forge(center, unit)
		_:
			_draw_card(center, unit)


func _draw_offense(center: Vector2, unit: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-14.0, 7.0) * unit,
		center + Vector2(-3.0, -13.0) * unit,
		center + Vector2(2.0, -3.0) * unit,
		center + Vector2(13.0, -10.0) * unit,
		center + Vector2(5.0, 13.0) * unit,
	])
	draw_colored_polygon(points, Color(_accent, 0.82))
	draw_polyline(points + PackedVector2Array([points[0]]), _accent, 1.5 * unit, true)


func _draw_shield(center: Vector2, unit: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -15.0) * unit,
		center + Vector2(13.0, -9.0) * unit,
		center + Vector2(10.0, 8.0) * unit,
		center + Vector2(0.0, 16.0) * unit,
		center + Vector2(-10.0, 8.0) * unit,
		center + Vector2(-13.0, -9.0) * unit,
	])
	draw_colored_polygon(points, Color(_accent, 0.24))
	draw_polyline(points + PackedVector2Array([points[0]]), _accent, 2.0 * unit, true)


func _draw_mobility(center: Vector2, unit: float) -> void:
	var color := Color(_accent, 0.92)
	draw_line(center + Vector2(-16.0, 5.0) * unit, center + Vector2(10.0, 5.0) * unit, color, 3.0 * unit, true)
	draw_line(center + Vector2(10.0, 5.0) * unit, center + Vector2(3.0, -3.0) * unit, color, 3.0 * unit, true)
	draw_line(center + Vector2(10.0, 5.0) * unit, center + Vector2(3.0, 13.0) * unit, color, 3.0 * unit, true)
	draw_line(center + Vector2(-11.0, -7.0) * unit, center + Vector2(3.0, -7.0) * unit, Color(_accent, 0.55), 2.0 * unit, true)


func _draw_tempo(center: Vector2, unit: float) -> void:
	draw_arc(center, 14.0 * unit, 0.0, TAU, 32, _accent, 2.0 * unit, true)
	draw_line(center, center + Vector2(0.0, -9.0) * unit, _accent, 2.0 * unit, true)
	draw_line(center, center + Vector2(8.0, 4.0) * unit, _accent, 2.0 * unit, true)
	draw_circle(center, 2.2 * unit, _accent)


func _draw_recovery(center: Vector2, unit: float) -> void:
	var color := Color(_accent, 0.94)
	draw_rect(Rect2(center + Vector2(-4.0, -15.0) * unit, Vector2(8.0, 30.0) * unit), color)
	draw_rect(Rect2(center + Vector2(-15.0, -4.0) * unit, Vector2(30.0, 8.0) * unit), color)


func _draw_card(center: Vector2, unit: float) -> void:
	var back := Rect2(center + Vector2(-14.0, -11.0) * unit, Vector2(22.0, 28.0) * unit)
	var front := Rect2(center + Vector2(-8.0, -16.0) * unit, Vector2(22.0, 28.0) * unit)
	draw_rect(back, Color(_accent, 0.22), true)
	draw_rect(back, Color(_accent, 0.65), false, 1.5 * unit)
	draw_rect(front, Color(_accent, 0.16), true)
	draw_rect(front, _accent, false, 2.0 * unit)
	draw_line(front.position + Vector2(5.0, 8.0) * unit, front.position + Vector2(17.0, 8.0) * unit, _accent, 1.5 * unit, true)


func _draw_cache(center: Vector2, unit: float) -> void:
	var box := Rect2(center + Vector2(-15.0, -7.0) * unit, Vector2(30.0, 20.0) * unit)
	draw_rect(box, Color(_accent, 0.20), true)
	draw_rect(box, _accent, false, 2.0 * unit)
	draw_line(center + Vector2(-15.0, -7.0) * unit, center + Vector2(-9.0, -14.0) * unit, _accent, 2.0 * unit, true)
	draw_line(center + Vector2(-9.0, -14.0) * unit, center + Vector2(9.0, -14.0) * unit, _accent, 2.0 * unit, true)
	draw_line(center + Vector2(9.0, -14.0) * unit, center + Vector2(15.0, -7.0) * unit, _accent, 2.0 * unit, true)
	draw_rect(Rect2(center + Vector2(-3.0, -2.0) * unit, Vector2(6.0, 8.0) * unit), _accent)


func _draw_equipment(center: Vector2, unit: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -17.0) * unit,
		center + Vector2(14.0, 0.0) * unit,
		center + Vector2(0.0, 17.0) * unit,
		center + Vector2(-14.0, 0.0) * unit,
	])
	draw_colored_polygon(points, Color(_accent, 0.18))
	draw_polyline(points + PackedVector2Array([points[0]]), _accent, 2.0 * unit, true)
	draw_circle(center, 5.0 * unit, Color(_accent, 0.80))


func _draw_forge(center: Vector2, unit: float) -> void:
	draw_line(center + Vector2(-10.0, 13.0) * unit, center + Vector2(8.0, -9.0) * unit, _accent, 5.0 * unit, true)
	draw_rect(Rect2(center + Vector2(-2.0, -15.0) * unit, Vector2(20.0, 9.0) * unit), Color(_accent, 0.88))
	draw_line(center + Vector2(-15.0, 16.0) * unit, center + Vector2(15.0, 16.0) * unit, Color(_accent, 0.60), 2.0 * unit, true)
