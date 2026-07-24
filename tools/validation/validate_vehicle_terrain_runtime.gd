extends SceneTree

const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var _failures: Array[String] = []


func _init() -> void:
	var persistent := {}
	var runtime := TerrainRuntime.new()
	runtime.configure([
		{"id":&"flow", "kind":&"flow_channel", "rect":Rect2(0, 0, 400, 400), "vector":Vector2(72, 0)},
		{"id":&"arc", "kind":&"arc_surge", "rect":Rect2(500, 0, 400, 400)},
		{"id":&"wall", "kind":&"breakable_bulkhead", "rect":Rect2(1000, 0, 120, 400)},
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(0, 800)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(3200, 800)},
		{"id":&"repair", "kind":&"repair_basin", "pos":Vector2(0, 1400)},
		{"id":&"overdrive", "kind":&"overdrive_field", "pos":Vector2(800, 1400)},
	], persistent, false)
	_expect(runtime.flow_vector_at(Vector2(100, 100)) == Vector2(72, 0), "flow applies to mobile actors")
	_expect(runtime.flow_vector_at(Vector2(100, 100), true) == Vector2(36, 0), "flow halves for bosses")
	_expect(runtime.flow_vector_at(Vector2(100, 100), false, true) == Vector2.ZERO, "flow excludes stationary actors")

	runtime.advance(4.5, Vector2.ZERO, 100.0, 100.0)
	var first_arc := runtime.surge_damage_for("enemy", Vector2(600, 100), &"enemy")
	var repeated_arc := runtime.surge_damage_for("enemy", Vector2(600, 100), &"enemy")
	_expect(first_arc == 18.0 and repeated_arc == 0.0, "arc surge hits once per active window")

	_expect(runtime.damage_bulkhead(&"wall", 72.0), "one full Breach breaks a bulkhead")
	_expect(runtime.live_bulkhead_rects().is_empty(), "broken bulkhead leaves blocker snapshot")
	var next_stage := TerrainRuntime.new()
	next_stage.configure([], persistent, true)
	_expect(float(persistent.get(&"wall", -1.0)) == 0.0, "bulkhead health persists across stages")

	var transit_events: Array[Dictionary] = []
	for _step in 4:
		transit_events.append_array(runtime.advance(0.1, Vector2(0, 800), 100.0, 100.0))
	_expect(
		transit_events.any(func(event: Dictionary) -> bool: return event.get("kind") == &"transit"),
		"transit fires after dwell"
	)

	var healed := 0.0
	for _step in 20:
		for event in runtime.advance(0.1, Vector2(0, 1400), 50.0 + healed, 100.0):
			if event.get("kind") == &"heal":
				healed += float(event["amount"])
	_expect(healed > 0.0 and healed <= TerrainRuntime.REPAIR_BUDGET, "repair is dwell-gated and budgeted")
	runtime.advance(0.1, Vector2(800, 1400), 100.0, 100.0)
	_expect(runtime.overdrive_active, "overdrive uses exact player membership")
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
