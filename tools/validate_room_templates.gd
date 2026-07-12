extends SceneTree

const ROOM_DATA_DIR := "res://data/rooms/lower_ruins"
const MIN_CRITICAL_LANDING_WIDTH := 220.0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var files := DirAccess.get_files_at(ROOM_DATA_DIR)
	var room_count := 0
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var data := load("%s/%s" % [ROOM_DATA_DIR, file_name]) as RoomTemplateData
		_expect(data != null, "%s should load as RoomTemplateData" % file_name)
		if data == null:
			continue
		room_count += 1
		await _validate_room(data)
	_expect(room_count >= 2, "lower ruins should retain at least the landed room templates")
	_finish()


func _validate_room(data: RoomTemplateData) -> void:
	for error in data.validate_definition():
		_failures.append("%s: %s" % [data.id, error])
	if data.scene == null:
		return
	var room := data.scene.instantiate() as RoomTemplateHost
	_expect(room != null, "%s scene should instantiate as RoomTemplateHost" % data.id)
	if room == null:
		return
	root.add_child(room)
	for error in room.configure(data):
		_failures.append("%s: %s" % [data.id, error])
	var surfaces := room.get_support_surfaces()
	if data.required_route:
		_expect(not surfaces.is_empty(), "%s required route needs support surfaces" % data.id)
	for surface in surfaces:
		_expect(
			float(surface.get("width", 0.0)) >= MIN_CRITICAL_LANDING_WIDTH,
			"%s surface %s is narrower than a critical landing"
			% [data.id, surface.get("id", "unknown")]
		)
		_expect(is_finite(float(surface.get("top", INF))), "%s has non-finite support" % data.id)
	for group_name in [&"Enemy", &"Recovery"]:
		for anchor in room.get_typed_anchors(group_name):
			_expect(
				_anchor_has_support(anchor, surfaces),
				"%s anchor %s must sit on authored support" % [data.id, anchor.anchor_id]
			)
	if data.role == &"exit" and not room.get_typed_anchors(&"Enemy").is_empty():
		var checkpoint := room.get_anchor(&"Objective", &"Checkpoint")
		var enemy_anchor := room.get_typed_anchors(&"Enemy")[0]
		var original_position := enemy_anchor.position
		enemy_anchor.position = checkpoint.position
		_expect(
			_has_error(room.configure(data), "patrol enters safe objective"),
			"%s should reject enemy patrol inside its terminal checkpoint" % data.id
		)
		enemy_anchor.position = original_position
	room.queue_free()
	await process_frame


func _anchor_has_support(anchor: RoomAnchor, surfaces: Array) -> bool:
	for surface in surfaces:
		var start := float(surface["x"])
		var end := start + float(surface["width"])
		if anchor.position.x < start or anchor.position.x > end:
			continue
		if absf(anchor.position.y - float(surface["top"])) <= 1.0:
			return true
	return false


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ROOM_TEMPLATE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
