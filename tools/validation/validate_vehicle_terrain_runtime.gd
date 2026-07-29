extends SceneTree

const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var _failures: Array[String] = []


func _init() -> void:
	var persistent := {}
	var sockets: Array[Vector2] = []
	for row in 3:
		for column in 4:
			sockets.append(Vector2(column * 720.0, row * 720.0))
	var runtime := TerrainRuntime.new()
	runtime.configure([
		{"id":&"arc", "kind":&"arc_surge", "rect":Rect2(500, 0, 400, 400)},
		{"id":&"wall", "kind":&"breakable_bulkhead", "rect":Rect2(1000, 0, 120, 400)},
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(0, 800)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(3200, 800)},
	], persistent, false, sockets, 9981, &"stage_1")

	_expect(runtime.support_fields.size() == 4, "four independent support slots exist")
	var opening: Array = runtime.snapshot()["support_fields"]
	_expect(StringName(opening[0]["state"]) == &"warning", "repair A starts with warning")
	_expect(StringName(opening[1]["state"]) == &"initial_delay", "repair B keeps its initial offset")
	_expect(StringName(opening[2]["state"]) == &"initial_delay", "overdrive A keeps its initial offset")
	_expect(StringName(opening[3]["state"]) == &"initial_delay", "overdrive B keeps its initial offset")

	runtime.advance(4.5, Vector2(4000, 4000), 100.0, 100.0)
	var first_arc := runtime.surge_damage_for("enemy", Vector2(600, 100), &"enemy")
	var repeated_arc := runtime.surge_damage_for("enemy", Vector2(600, 100), &"enemy")
	_expect(first_arc == 18.0 and repeated_arc == 0.0, "arc surge hits once per active window")

	for hit_index in 4:
		_expect(
			runtime.damage_bulkhead(&"wall", 18.0) == (hit_index == 3),
			"four uniform primary hits break a full-health bulkhead"
		)
	_expect(runtime.live_bulkhead_rects().is_empty(), "broken bulkhead leaves blocker snapshot")
	var next_stage := TerrainRuntime.new()
	next_stage.configure([], persistent, true, sockets, 9981, &"stage_2")
	_expect(float(persistent.get(&"wall", -1.0)) == 0.0, "bulkhead health persists across stages")

	var transit_events: Array[Dictionary] = []
	for _step in 4:
		transit_events.append_array(runtime.advance(0.1, Vector2(0, 800), 100.0, 100.0))
	_expect(
		transit_events.any(func(event: Dictionary) -> bool: return event.get("kind") == &"transit"),
		"transit fires after dwell"
	)

	var repair_position := Vector2(runtime.support_fields[0]["position"])
	var healed := 0.0
	for _step in 20:
		for event in runtime.advance(0.1, repair_position, 50.0 + healed, 100.0):
			if event.get("kind") == &"heal":
				healed += float(event["amount"])
	_expect(healed > 0.0 and healed <= TerrainRuntime.REPAIR_BUDGET, "active repair is dwell-gated and budgeted")

	var overdrive_position := Vector2(runtime.support_fields[2]["position"])
	for _step in 30:
		runtime.advance(0.1, overdrive_position, 100.0, 100.0)
	_expect(runtime.overdrive_active, "active overdrive uses exact player membership")

	var before_pause := var_to_str(runtime.snapshot()["support_fields"])
	var after_pause := var_to_str(runtime.snapshot()["support_fields"])
	_expect(before_pause == after_pause, "support state is stable when gameplay does not advance")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_TERRAIN_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
