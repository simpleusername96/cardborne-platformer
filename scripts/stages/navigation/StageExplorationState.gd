class_name StageExplorationState
extends RefCounted

const ROOM_BOUNDARY_HYSTERESIS := 24.0
const PLAYER_POSITION_STEP := 24.0

var _base: Dictionary = {}
var _room_rows: Dictionary = {}
var _visited_rooms: Dictionary = {}
var _discovered_markers: Dictionary = {}
var _marker_states: Dictionary = {}
var _current_room_id: String = ""
var _player_position := Vector2.ZERO
var _has_player_position := false
var _revision := 0
var _snapshot: Dictionary = {}


func configure(base_snapshot: Dictionary, persisted_knowledge: Dictionary = {}) -> void:
	_base = base_snapshot.duplicate(true)
	_room_rows.clear()
	_visited_rooms.clear()
	_discovered_markers.clear()
	_marker_states.clear()
	_current_room_id = ""
	_has_player_position = false
	_revision = 0

	for room_value in _base.get("rooms", []):
		var room := (room_value as Dictionary).duplicate(true)
		_room_rows[String(room.get("id", ""))] = room
	for room_id in persisted_knowledge.get("visited_room_ids", []):
		if _room_rows.has(String(room_id)):
			_visited_rooms[String(room_id)] = true
	for marker_id in persisted_knowledge.get("discovered_marker_ids", []):
		_discovered_markers[String(marker_id)] = true
	for marker_value in _base.get("markers", []):
		var marker := marker_value as Dictionary
		_marker_states[String(marker.get("id", ""))] = String(
			marker.get("state", "unknown")
		)
	_rebuild_snapshot()


func update_player(world_position: Vector2) -> bool:
	if _base.is_empty():
		return false
	var changed := false
	var next_room_id := _resolve_current_room(world_position)
	if not next_room_id.is_empty() and next_room_id != _current_room_id:
		_current_room_id = next_room_id
		changed = true
	if not _current_room_id.is_empty() and not _visited_rooms.has(_current_room_id):
		_visited_rooms[_current_room_id] = true
		changed = true
	changed = _discover_current_room_markers() or changed

	var projected_position := Vector2(
		snappedf(world_position.x, PLAYER_POSITION_STEP),
		snappedf(world_position.y, PLAYER_POSITION_STEP)
	)
	if not _has_player_position or not projected_position.is_equal_approx(_player_position):
		_player_position = projected_position
		_has_player_position = true
		changed = true
	if changed:
		_rebuild_snapshot()
	return changed


func set_marker_state(marker_id: String, state: String, discover: bool = false) -> bool:
	if marker_id.is_empty() or not _marker_states.has(marker_id):
		return false
	var changed := false
	if String(_marker_states[marker_id]) != state:
		_marker_states[marker_id] = state
		changed = true
	if discover and not _discovered_markers.has(marker_id):
		_discovered_markers[marker_id] = true
		changed = true
	if changed:
		_rebuild_snapshot()
	return changed


func set_active_checkpoint(
	checkpoint_id: String,
	world_position: Vector2,
	room_id: String
) -> bool:
	var marker_id := "checkpoint:%s" % checkpoint_id
	var markers: Array = _base.get("markers", [])
	var changed := false
	for marker_value in markers:
		var marker := marker_value as Dictionary
		if String(marker.get("type", "")) != "checkpoint":
			continue
		var candidate_id := String(marker.get("id", ""))
		var next_state := "active" if candidate_id == marker_id else "inactive"
		if String(_marker_states.get(candidate_id, "")) != next_state:
			_marker_states[candidate_id] = next_state
			changed = true
		if candidate_id == marker_id:
			if not (marker.get("position", Vector2.ZERO) as Vector2).is_equal_approx(
				world_position
			):
				marker["position"] = world_position
				changed = true
			if not room_id.is_empty() and String(marker.get("room_id", "")) != room_id:
				marker["room_id"] = room_id
				changed = true
			if not _discovered_markers.has(candidate_id):
				_discovered_markers[candidate_id] = true
				changed = true
	if changed:
		_base["markers"] = markers
		_rebuild_snapshot()
	return changed


func get_current_room_id() -> StringName:
	return StringName(_current_room_id)


func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func get_knowledge_snapshot() -> Dictionary:
	var visited: Array[String] = []
	for room_id in _visited_rooms:
		visited.append(String(room_id))
	visited.sort()
	var discovered: Array[String] = []
	for marker_id in _discovered_markers:
		discovered.append(String(marker_id))
	discovered.sort()
	return {
		"visited_room_ids": visited,
		"discovered_marker_ids": discovered,
	}


func _resolve_current_room(world_position: Vector2) -> String:
	if not _current_room_id.is_empty():
		var current := _room_rows.get(_current_room_id, {}) as Dictionary
		var current_bounds := current.get("bounds", Rect2()) as Rect2
		if current_bounds.grow(ROOM_BOUNDARY_HYSTERESIS).has_point(world_position):
			return _current_room_id
	var candidate_ids := _room_rows.keys()
	candidate_ids.sort()
	for room_value in candidate_ids:
		var room_id := String(room_value)
		var room := _room_rows[room_value] as Dictionary
		if (room.get("bounds", Rect2()) as Rect2).has_point(world_position):
			return room_id
	return _current_room_id


func _discover_current_room_markers() -> bool:
	if _current_room_id.is_empty():
		return false
	var changed := false
	for marker_value in _base.get("markers", []):
		var marker := marker_value as Dictionary
		if String(marker.get("room_id", "")) != _current_room_id:
			continue
		var marker_type := String(marker.get("type", ""))
		if marker_type not in ["reward", "gate", "shortcut", "checkpoint"]:
			continue
		var marker_id := String(marker.get("id", ""))
		if not _discovered_markers.has(marker_id):
			_discovered_markers[marker_id] = true
			changed = true
	return changed


func _rebuild_snapshot() -> void:
	_revision += 1
	var rooms: Array[Dictionary] = []
	for room_value in _base.get("rooms", []):
		var room := (room_value as Dictionary).duplicate(true)
		var room_id := String(room.get("id", ""))
		var visited := _visited_rooms.has(room_id)
		var current := room_id == _current_room_id
		room["visited"] = visited
		room["current"] = current
		room["state"] = "current" if current else ("visited" if visited else "unvisited")
		rooms.append(room)

	var markers: Array[Dictionary] = []
	for marker_value in _base.get("markers", []):
		var marker := (marker_value as Dictionary).duplicate(true)
		var marker_id := String(marker.get("id", ""))
		var always_visible := bool(marker.get("always_visible", false))
		var discovered := always_visible or _discovered_markers.has(marker_id)
		var marker_state := String(_marker_states.get(
			marker_id,
			marker.get("state", "unknown")
		))
		marker["discovered"] = discovered
		marker["visible"] = (
			discovered
			and not (
				String(marker.get("type", "")) == "checkpoint"
				and marker_state != "active"
			)
		)
		marker["state"] = marker_state
		markers.append(marker)

	_snapshot = _base.duplicate(true)
	_snapshot["revision"] = _revision
	_snapshot["rooms"] = rooms
	_snapshot["markers"] = markers
	_snapshot["current_room_id"] = _current_room_id
	_snapshot["player_position"] = _player_position
	_snapshot["has_player_position"] = _has_player_position
