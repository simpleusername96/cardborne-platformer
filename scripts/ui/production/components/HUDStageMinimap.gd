class_name HUDStageMinimap
extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

const PANEL := Color("11181c")
const PANEL_EDGE := Color("526068")
const UNVISITED_FILL := Color("172025")
const UNVISITED_EDGE := Color("354148")
const VISITED_FILL := Color("334349")
const VISITED_EDGE := Color("84969a")
const CURRENT_FILL := Color("31565b")
const CURRENT_EDGE := Color("62bdc7")
const OPTIONAL_EDGE := Color("d4a33f")
const PLAYER := Color("f0f1e8")
const READY := Color("6fd5a0")
const LOCKED := Color("d9654f")

var _snapshot: Dictionary = {}
var _world_bounds := Rect2()
var _map_rect := Rect2()
var _scale := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_world_bounds = _snapshot.get("world_bounds", Rect2()) as Rect2
	queue_redraw()


func clear() -> void:
	_snapshot.clear()
	queue_redraw()


func get_display_snapshot() -> Dictionary:
	var visible_rooms := 0
	var visited_rooms := 0
	var current_rooms := 0
	for room_value in _snapshot.get("rooms", []):
		var room := room_value as Dictionary
		visible_rooms += 1
		if bool(room.get("visited", false)):
			visited_rooms += 1
		if bool(room.get("current", false)):
			current_rooms += 1
	var visible_markers: Array[String] = []
	var marker_states := {}
	for marker_value in _snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if not bool(marker.get("visible", false)):
			continue
		var marker_id := String(marker.get("id", ""))
		visible_markers.append(marker_id)
		marker_states[marker_id] = String(marker.get("state", ""))
	visible_markers.sort()
	return {
		"stage_id": String(_snapshot.get("stage_id", "")),
		"revision": int(_snapshot.get("revision", 0)),
		"room_count": visible_rooms,
		"visited_room_count": visited_rooms,
		"current_room_count": current_rooms,
		"current_room_id": String(_snapshot.get("current_room_id", "")),
		"visible_marker_ids": visible_markers,
		"marker_states": marker_states,
	}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	draw_rect(Rect2(Vector2.ZERO, size), PANEL_EDGE, false, 1.0)
	_draw_title()
	if _snapshot.is_empty() or _world_bounds.size.x <= 0.0 or _world_bounds.size.y <= 0.0:
		return
	_prepare_projection()
	_draw_connections()
	_draw_rooms()
	_draw_markers()
	_draw_player()


func _draw_title() -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(9.0, 17.0),
		"MAP",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		12,
		Styles.TEXT_MUTED
	)
	draw_line(Vector2(9.0, 21.0), Vector2(size.x - 9.0, 21.0), PANEL_EDGE, 1.0)


func _prepare_projection() -> void:
	_map_rect = Rect2(9.0, 27.0, maxf(size.x - 18.0, 1.0), maxf(size.y - 35.0, 1.0))
	_scale = minf(
		_map_rect.size.x / _world_bounds.size.x,
		_map_rect.size.y / _world_bounds.size.y
	)
	var projected_size := _world_bounds.size * _scale
	_origin = _map_rect.position + (_map_rect.size - projected_size) * 0.5


func _draw_connections() -> void:
	var room_centers := {}
	var room_states := {}
	for room_value in _snapshot.get("rooms", []):
		var room := room_value as Dictionary
		var room_id := String(room.get("id", ""))
		room_centers[room_id] = _project_rect(room.get("bounds", Rect2()) as Rect2).get_center()
		room_states[room_id] = String(room.get("state", "unvisited"))
	for connection_value in _snapshot.get("connections", []):
		var connection := connection_value as Dictionary
		var from_id := String(connection.get("from_room_id", ""))
		var to_id := String(connection.get("to_room_id", ""))
		if not room_centers.has(from_id) or not room_centers.has(to_id):
			continue
		var discovered := (
			String(room_states.get(from_id, "unvisited")) != "unvisited"
			and String(room_states.get(to_id, "unvisited")) != "unvisited"
		)
		var role := String(connection.get("route_role", "critical"))
		var color := (
			OPTIONAL_EDGE
			if discovered and role in ["optional", "return"]
			else (VISITED_EDGE if discovered else UNVISITED_EDGE)
		)
		if role in ["optional", "return"]:
			draw_dashed_line(
				room_centers[from_id],
				room_centers[to_id],
				color,
				1.5,
				4.0,
				true
			)
		else:
			draw_line(room_centers[from_id], room_centers[to_id], color, 1.5, true)


func _draw_rooms() -> void:
	for room_value in _snapshot.get("rooms", []):
		var room := room_value as Dictionary
		var rect := _project_rect(room.get("bounds", Rect2()) as Rect2)
		rect.size.x = maxf(rect.size.x, 4.0)
		rect.size.y = maxf(rect.size.y, 3.0)
		var state := String(room.get("state", "unvisited"))
		var fill := UNVISITED_FILL
		var edge := UNVISITED_EDGE
		if state == "visited":
			fill = VISITED_FILL
			edge = VISITED_EDGE
		elif state == "current":
			fill = CURRENT_FILL
			edge = CURRENT_EDGE
		draw_rect(rect, fill)
		if state == "unvisited":
			_draw_dashed_rect(rect, edge)
		else:
			draw_rect(rect, edge, false, 1.5)
		if state == "current":
			draw_rect(rect.grow(2.0), CURRENT_EDGE, false, 1.0)
		elif not bool(room.get("required_route", true)):
			draw_line(rect.position, rect.position + Vector2(minf(rect.size.x, 10.0), 0.0), OPTIONAL_EDGE, 2.0)


func _draw_markers() -> void:
	for marker_value in _snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if not bool(marker.get("visible", false)):
			continue
		var position := _project_point(marker.get("position", Vector2.ZERO) as Vector2)
		var marker_type := String(marker.get("type", ""))
		var state := String(marker.get("state", ""))
		match marker_type:
			"start":
				_draw_triangle(position, Styles.CYAN)
			"exit":
				_draw_exit(position, state)
			"checkpoint":
				_draw_checkpoint(position)
			"reward":
				_draw_reward(position, state)
			"gate", "shortcut":
				_draw_gate(position, state)


func _draw_player() -> void:
	if not bool(_snapshot.get("has_player_position", false)):
		return
	var position := _project_point(
		_snapshot.get("player_position", Vector2.ZERO) as Vector2
	)
	var diamond := PackedVector2Array([
		position + Vector2(0.0, -5.0),
		position + Vector2(5.0, 0.0),
		position + Vector2(0.0, 5.0),
		position + Vector2(-5.0, 0.0),
	])
	draw_colored_polygon(diamond, PLAYER)
	draw_polyline(diamond, CURRENT_EDGE, 1.0, true)


func _draw_triangle(position: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(0.0, -4.0),
		position + Vector2(4.0, 4.0),
		position + Vector2(-4.0, 4.0),
	]), color)


func _draw_exit(position: Vector2, state: String) -> void:
	var color := READY if state == "ready" else LOCKED
	draw_rect(Rect2(position - Vector2(4.0, 5.0), Vector2(8.0, 10.0)), color, false, 1.5)
	if state == "ready":
		draw_circle(position + Vector2(2.0, 0.0), 1.0, color)
	else:
		draw_line(position + Vector2(-3.0, -3.0), position + Vector2(3.0, 3.0), color, 1.5)
		draw_line(position + Vector2(3.0, -3.0), position + Vector2(-3.0, 3.0), color, 1.5)


func _draw_checkpoint(position: Vector2) -> void:
	draw_line(position + Vector2(-5.0, 0.0), position + Vector2(5.0, 0.0), READY, 2.0)
	draw_line(position + Vector2(0.0, -5.0), position + Vector2(0.0, 5.0), READY, 2.0)


func _draw_reward(position: Vector2, state: String) -> void:
	var points := PackedVector2Array([
		position + Vector2(0.0, -4.0),
		position + Vector2(4.0, 0.0),
		position + Vector2(0.0, 4.0),
		position + Vector2(-4.0, 0.0),
		position + Vector2(0.0, -4.0),
	])
	if state == "claimed":
		draw_polyline(points, Color(OPTIONAL_EDGE, 0.45), 1.0, true)
	else:
		draw_colored_polygon(PackedVector2Array(points.slice(0, 4)), OPTIONAL_EDGE)


func _draw_gate(position: Vector2, state: String) -> void:
	var color := READY if state == "open" else LOCKED
	if state == "open":
		draw_line(position + Vector2(-5.0, -5.0), position + Vector2(-5.0, 5.0), color, 1.5)
		draw_line(position + Vector2(5.0, -5.0), position + Vector2(5.0, 5.0), color, 1.5)
	else:
		draw_line(position + Vector2(-3.0, -5.0), position + Vector2(-3.0, 5.0), color, 2.0)
		draw_line(position + Vector2(3.0, -5.0), position + Vector2(3.0, 5.0), color, 2.0)
		draw_line(position + Vector2(-3.0, 0.0), position + Vector2(3.0, 0.0), color, 1.5)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), color, 1.0, 3.0)
	draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, color, 1.0, 3.0)
	draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), color, 1.0, 3.0)
	draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, color, 1.0, 3.0)


func _project_rect(world_rect: Rect2) -> Rect2:
	return Rect2(
		_project_point(world_rect.position),
		world_rect.size * _scale
	)


func _project_point(world_position: Vector2) -> Vector2:
	return _origin + (world_position - _world_bounds.position) * _scale
