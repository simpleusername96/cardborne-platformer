class_name FixedStageBlueprintCanvas
extends Control

const BACKGROUND := Color("0b1115")
const SURFACE := Color("111a20")
const SURFACE_RAISED := Color("17232a")
const OUTLINE := Color("3a4a52")
const TEXT := Color("e5ecec")
const MUTED := Color("91a1a7")
const CRITICAL := Color("6ccfd2")
const OPTIONAL := Color("d7aa4b")
const RETURN := Color("82b98d")
const DANGER := Color("d16d63")
const SAFE := Color("8eb3c7")

const MAP_RECT := Rect2(40.0, 118.0, 1300.0, 710.0)
const INFO_RECT := Rect2(1370.0, 118.0, 430.0, 710.0)
const WAVE_RECT := Rect2(40.0, 860.0, 1760.0, 220.0)
const ROOM_SIZE := Vector2(150.0, 90.0)
const GRID_STEP := Vector2(137.0, 120.0)

var _blueprint: Dictionary = {}
var _font: Font


func configure(blueprint: Dictionary) -> void:
	_blueprint = blueprint.duplicate(true)
	_font = ThemeDB.fallback_font
	queue_redraw()


func _draw() -> void:
	if _blueprint.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	_draw_header()
	_draw_panel(MAP_RECT)
	_draw_panel(INFO_RECT)
	_draw_panel(WAVE_RECT)
	_draw_connections()
	_draw_rooms()
	_draw_info()
	_draw_waveform()
	_draw_legend()


func _draw_header() -> void:
	_text(
		Vector2(42.0, 46.0),
		String(_blueprint.get("title", "Fixed Stage Blueprint")),
		30,
		TEXT
	)
	_text(
		Vector2(42.0, 78.0),
		String(_blueprint.get("thesis", "")),
		16,
		MUTED
	)
	var policy := "TERMINAL POLICY · %s" % String(
		_blueprint.get("terminal_policy", "unspecified")
	).to_upper()
	var policy_width := _font.get_string_size(policy, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
	var badge := Rect2(size.x - policy_width - 52.0, 30.0, policy_width + 22.0, 34.0)
	draw_rect(badge, Color(CRITICAL, 0.12))
	draw_rect(badge, CRITICAL, false, 1.5)
	_text(badge.position + Vector2(11.0, 22.0), policy, 14, CRITICAL)


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, SURFACE)
	draw_rect(rect, OUTLINE, false, 1.5)


func _draw_connections() -> void:
	var room_map := _room_map()
	for connection_value in _blueprint.get("connections", []):
		var connection := connection_value as Dictionary
		var from_room := room_map.get(String(connection.get("from", "")), {}) as Dictionary
		var to_room := room_map.get(String(connection.get("to", "")), {}) as Dictionary
		if from_room.is_empty() or to_room.is_empty():
			continue
		var from_rect := _room_rect(from_room)
		var to_rect := _room_rect(to_room)
		var from_point := from_rect.get_center()
		var to_point := to_rect.get_center()
		var role := StringName(connection.get("role", &"critical"))
		var color := _connection_color(role)
		if role in [&"optional", &"return", &"shortcut"]:
			draw_dashed_line(from_point, to_point, color, 3.0, 8.0, true)
		else:
			draw_line(from_point, to_point, color, 4.0, true)
		_draw_arrow_head(from_point, to_point, color)


func _draw_arrow_head(from_point: Vector2, to_point: Vector2, color: Color) -> void:
	var direction := (to_point - from_point).normalized()
	if direction == Vector2.ZERO:
		return
	var normal := Vector2(-direction.y, direction.x)
	var tip := to_point - direction * (ROOM_SIZE.x * 0.42)
	var points := PackedVector2Array([
		tip,
		tip - direction * 13.0 + normal * 7.0,
		tip - direction * 13.0 - normal * 7.0,
	])
	draw_colored_polygon(points, color)


func _draw_rooms() -> void:
	for room_value in _blueprint.get("rooms", []):
		var room := room_value as Dictionary
		var rect := _room_rect(room)
		var required := bool(room.get("required", true))
		var role := StringName(room.get("role", &"traversal"))
		var border := CRITICAL if required else OPTIONAL
		var fill := _role_fill(role)
		draw_rect(rect, fill)
		draw_rect(rect, border, false, 2.5 if required else 2.0)
		_text(rect.position + Vector2(10.0, 22.0), String(room.get("id", "")), 13, TEXT)
		_text(
			rect.position + Vector2(10.0, 42.0),
			String(room.get("rhythm", role)).to_upper(),
			11,
			MUTED
		)
		_draw_beats(rect, room.get("beats", []), required)
		_draw_room_marker(rect, role)


func _draw_beats(rect: Rect2, beats_value: Variant, required: bool) -> void:
	var beats: Array = beats_value if beats_value is Array else []
	if beats.is_empty():
		return
	var gap := 4.0
	var width := (rect.size.x - 20.0 - gap * float(beats.size() - 1)) / float(beats.size())
	for index in beats.size():
		var beat_rect := Rect2(
			rect.position + Vector2(10.0 + float(index) * (width + gap), 58.0),
			Vector2(width, 20.0)
		)
		draw_rect(beat_rect, Color(CRITICAL if required else OPTIONAL, 0.12))
		draw_rect(beat_rect, OUTLINE, false, 1.0)
		var label := String(beats[index]).left(1).to_upper()
		var label_width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10).x
		_text(
			beat_rect.position + Vector2((beat_rect.size.x - label_width) * 0.5, 14.0),
			label,
			10,
			TEXT
		)


func _draw_room_marker(rect: Rect2, role: StringName) -> void:
	var center := rect.position + Vector2(rect.size.x - 16.0, 16.0)
	match role:
		&"start":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0.0, -7.0),
					center + Vector2(7.0, 6.0),
					center + Vector2(-7.0, 6.0),
				]),
				SAFE
			)
		&"exit":
			draw_rect(Rect2(center - Vector2(6.0, 7.0), Vector2(12.0, 14.0)), OPTIONAL, false, 2.0)
			draw_circle(center + Vector2(3.0, 0.0), 1.5, OPTIONAL)
		&"optional":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0.0, -7.0),
					center + Vector2(7.0, 0.0),
					center + Vector2(0.0, 7.0),
					center + Vector2(-7.0, 0.0),
				]),
				OPTIONAL
			)
		&"objective":
			draw_circle(center, 7.0, DANGER, false, 2.0)
			draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), DANGER, 2.0)
		&"safe":
			draw_line(center + Vector2(-6.0, 0.0), center + Vector2(6.0, 0.0), SAFE, 2.0)
			draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 6.0), SAFE, 2.0)


func _draw_info() -> void:
	var cursor := INFO_RECT.position + Vector2(20.0, 30.0)
	_text(cursor, "IMPLEMENTATION CONTRACT", 15, CRITICAL)
	cursor.y += 30.0
	for line_value in _blueprint.get("contract", []):
		_text(cursor, "• %s" % String(line_value), 13, TEXT)
		cursor.y += 24.0
	cursor.y += 10.0
	_text(cursor, "LANDMARKS", 15, OPTIONAL)
	cursor.y += 30.0
	for line_value in _blueprint.get("landmarks", []):
		_text(cursor, "• %s" % String(line_value), 13, TEXT)
		cursor.y += 24.0
	cursor.y += 10.0
	_text(cursor, "MINIMAP LAYER", 15, SAFE)
	cursor.y += 30.0
	for line_value in _blueprint.get("minimap", []):
		_text(cursor, "• %s" % String(line_value), 13, TEXT)
		cursor.y += 24.0
	cursor.y += 10.0
	_text(cursor, "TARGET TIME", 15, DANGER)
	cursor.y += 30.0
	_text(cursor, String(_blueprint.get("target_time", "")), 14, TEXT)


func _draw_waveform() -> void:
	_text(WAVE_RECT.position + Vector2(18.0, 27.0), "TARGET HEIGHT WAVEFORM", 14, MUTED)
	var critical_rooms: Array[Dictionary] = []
	for room_value in _blueprint.get("rooms", []):
		var room := room_value as Dictionary
		if bool(room.get("required", true)):
			critical_rooms.append(room)
	critical_rooms.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("route_index", 0)) < int(right.get("route_index", 0))
	)
	if critical_rooms.size() < 2:
		return
	var left := WAVE_RECT.position.x + 36.0
	var right := WAVE_RECT.end.x - 36.0
	var top := WAVE_RECT.position.y + 48.0
	var bottom := WAVE_RECT.end.y - 24.0
	var points := PackedVector2Array()
	for index in critical_rooms.size():
		var room := critical_rooms[index]
		var grid := room.get("grid", Vector2.ZERO) as Vector2
		var x := lerpf(left, right, float(index) / float(critical_rooms.size() - 1))
		var y := remap(grid.y, 0.0, 4.5, top, bottom)
		points.append(Vector2(x, y))
		draw_circle(Vector2(x, y), 5.0, CRITICAL)
		var short_id := String(room.get("id", "")).trim_prefix("lr_").trim_prefix("fw_").trim_prefix("bs_")
		_text(Vector2(x - 24.0, bottom + 16.0), short_id.left(10), 9, MUTED)
	for index in range(1, points.size()):
		draw_line(points[index - 1], points[index], CRITICAL, 3.0, true)


func _draw_legend() -> void:
	var origin := MAP_RECT.position + Vector2(18.0, MAP_RECT.size.y - 24.0)
	var entries := [
		["critical", CRITICAL],
		["optional / return", OPTIONAL],
		["safe / checkpoint", SAFE],
		["terminal blocker", DANGER],
	]
	for entry in entries:
		draw_rect(Rect2(origin, Vector2(16.0, 5.0)), entry[1])
		_text(origin + Vector2(22.0, 6.0), entry[0], 11, MUTED)
		origin.x += 180.0


func _room_map() -> Dictionary:
	var result := {}
	for room_value in _blueprint.get("rooms", []):
		var room := room_value as Dictionary
		result[String(room.get("id", ""))] = room
	return result


func _room_rect(room: Dictionary) -> Rect2:
	var grid := room.get("grid", Vector2.ZERO) as Vector2
	return Rect2(
		MAP_RECT.position + Vector2(26.0, 24.0) + grid * GRID_STEP,
		ROOM_SIZE
	)


func _role_fill(role: StringName) -> Color:
	match role:
		&"start":
			return Color(SAFE, 0.13)
		&"combat":
			return Color(DANGER, 0.13)
		&"hazard":
			return Color(OPTIONAL, 0.10)
		&"choice":
			return Color(CRITICAL, 0.12)
		&"objective":
			return Color(DANGER, 0.16)
		&"safe":
			return Color(SAFE, 0.16)
		&"exit":
			return Color(OPTIONAL, 0.15)
		&"optional":
			return Color(OPTIONAL, 0.12)
		_:
			return SURFACE_RAISED


func _connection_color(role: StringName) -> Color:
	match role:
		&"optional":
			return OPTIONAL
		&"return":
			return RETURN
		&"shortcut":
			return SAFE
		_:
			return CRITICAL


func _text(position: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(
		_font,
		position,
		value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
