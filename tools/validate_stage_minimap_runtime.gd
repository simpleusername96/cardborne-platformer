extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exploration := StageExplorationState.new()
	exploration.configure(_base_snapshot())
	_expect(exploration.update_player(Vector2(100.0, 100.0)), "initial player update should publish")
	var first := exploration.get_snapshot()
	_expect(first["current_room_id"] == "room_a", "start position should select room A")
	_expect(_room_state(first, "room_a") == "current", "room A should be current")
	_expect(_room_state(first, "room_b") == "unvisited", "room B should start dark")
	_expect(_marker_visible(first, "start:room_a"), "start marker should always be visible")
	_expect(_marker_visible(first, "exit:room_b"), "exit marker should always be visible")
	_expect(not _marker_visible(first, "reward:cache"), "undiscovered reward should stay hidden")

	exploration.update_player(Vector2(205.0, 100.0))
	_expect(
		exploration.get_current_room_id() == &"room_a",
		"socket-boundary hysteresis should keep the previous room"
	)
	exploration.update_player(Vector2(232.0, 100.0))
	var crossed := exploration.get_snapshot()
	_expect(crossed["current_room_id"] == "room_b", "moving beyond hysteresis should enter room B")
	_expect(_room_state(crossed, "room_a") == "visited", "previous room should remain visited")
	_expect(_marker_visible(crossed, "reward:cache"), "reward should reveal after room discovery")
	_expect(_marker_visible(crossed, "gate:loop"), "gate should reveal after room discovery")
	_expect(not _marker_visible(crossed, "checkpoint:terminal"), "inactive checkpoint should stay hidden")

	exploration.set_marker_state("reward:cache", "claimed", true)
	exploration.set_marker_state("gate:loop", "open", true)
	exploration.set_marker_state("exit:room_b", "ready", true)
	exploration.set_active_checkpoint("terminal", Vector2(330.0, 120.0), "room_b")
	var resolved := exploration.get_snapshot()
	_expect(_marker_state(resolved, "reward:cache") == "claimed", "reward claim should update once")
	_expect(_marker_state(resolved, "gate:loop") == "open", "gate open state should update")
	_expect(_marker_state(resolved, "exit:room_b") == "ready", "exit ready state should update")
	_expect(_marker_visible(resolved, "checkpoint:terminal"), "active checkpoint should be visible")

	var mutable_copy := exploration.get_snapshot()
	(mutable_copy["rooms"][0] as Dictionary)["state"] = "corrupted"
	_expect(
		_room_state(exploration.get_snapshot(), "room_a") == "visited",
		"map snapshots should be copy-safe"
	)
	var knowledge := exploration.get_knowledge_snapshot()
	var restored := StageExplorationState.new()
	restored.configure(_base_snapshot(), knowledge)
	restored.update_player(Vector2(100.0, 100.0))
	_expect(
		_room_state(restored.get_snapshot(), "room_b") == "visited",
		"persisted knowledge should retain prior rooms without retaining current room"
	)
	_finish()


func _base_snapshot() -> Dictionary:
	return {
		"stage_id": "fixture",
		"stage_index": 0,
		"content_signature": "fixture:1",
		"world_bounds": Rect2(0.0, 0.0, 400.0, 200.0),
		"rooms": [
			{
				"id": "room_a",
				"role": "start",
				"required_route": true,
				"route_index": 0,
				"bounds": Rect2(0.0, 0.0, 200.0, 200.0),
				"start": true,
				"exit": false,
			},
			{
				"id": "room_b",
				"role": "exit",
				"required_route": true,
				"route_index": 1,
				"bounds": Rect2(200.0, 0.0, 200.0, 200.0),
				"start": false,
				"exit": true,
			},
		],
		"connections": [
			{
				"id": "critical_0",
				"from_room_id": "room_a",
				"to_room_id": "room_b",
				"route_role": "critical",
			},
		],
		"markers": [
			{"id": "start:room_a", "type": "start", "room_id": "room_a", "position": Vector2(40.0, 100.0), "state": "known", "always_visible": true},
			{"id": "exit:room_b", "type": "exit", "room_id": "room_b", "position": Vector2(360.0, 100.0), "state": "locked", "always_visible": true},
			{"id": "reward:cache", "type": "reward", "room_id": "room_b", "position": Vector2(280.0, 120.0), "state": "available", "always_visible": false},
			{"id": "gate:loop", "type": "gate", "room_id": "room_b", "position": Vector2(300.0, 90.0), "state": "closed", "always_visible": false},
			{"id": "checkpoint:terminal", "type": "checkpoint", "room_id": "room_b", "position": Vector2(330.0, 120.0), "state": "inactive", "always_visible": false},
		],
	}


func _room_state(snapshot: Dictionary, room_id: String) -> String:
	for room_value in snapshot.get("rooms", []):
		var room := room_value as Dictionary
		if String(room.get("id", "")) == room_id:
			return String(room.get("state", ""))
	return ""


func _marker_visible(snapshot: Dictionary, marker_id: String) -> bool:
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if String(marker.get("id", "")) == marker_id:
			return bool(marker.get("visible", false))
	return false


func _marker_state(snapshot: Dictionary, marker_id: String) -> String:
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if String(marker.get("id", "")) == marker_id:
			return String(marker.get("state", ""))
	return ""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_MINIMAP_RUNTIME_VALIDATION_OK fog=hysteresis markers=stateful")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
