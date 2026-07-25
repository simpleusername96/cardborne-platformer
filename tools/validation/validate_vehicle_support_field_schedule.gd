extends SceneTree

const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var sockets: Array[Vector2] = []
	for row in 3:
		for column in 4:
			sockets.append(Vector2(600.0 + column * 720.0, 600.0 + row * 720.0))
	var runtime := TerrainRuntime.new()
	runtime.configure([], {}, false, sockets, 445566, &"stage_3")
	var opening: Array = runtime.snapshot()["support_fields"]
	_expect(opening.size() == 4, "exactly four scheduled support slots exist")
	var expected := [
		[&"repair_a", &"warning", 1.5],
		[&"repair_b", &"initial_delay", 12.0],
		[&"overdrive_a", &"initial_delay", 5.0],
		[&"overdrive_b", &"initial_delay", 19.0],
	]
	for index in expected.size():
		_expect(StringName(opening[index]["slot_id"]) == expected[index][0], "slot order is stable")
		_expect(StringName(opening[index]["state"]) == expected[index][1], "slot initial state is exact")
		_expect(is_equal_approx(float(opening[index]["remaining_seconds"]), expected[index][2]), "slot initial offset is exact")

	var grants: Array[float] = []
	var previous_indices := {}
	for slot in opening:
		previous_indices[StringName(slot["slot_id"])] = int(slot["relocation_index"])
	var elapsed := 0.0
	for _step in 900:
		runtime.advance(0.1, Vector2(-2000.0, -2000.0), 120.0, 120.0)
		elapsed += 0.1
		for slot in Array(runtime.snapshot()["support_fields"]):
			var slot_id := StringName(slot["slot_id"])
			var relocation_index := int(slot["relocation_index"])
			if relocation_index > int(previous_indices[slot_id]):
				grants.append(elapsed)
				previous_indices[slot_id] = relocation_index
	for index in range(1, grants.size()):
		_expect(grants[index] - grants[index - 1] >= 2.99, "relocation grants remain at least three seconds apart")
	_expect(grants.size() >= 4, "all support families relocate during the schedule fixture")

	var before_pause := var_to_str(runtime.snapshot())
	var after_pause := var_to_str(runtime.snapshot())
	_expect(before_pause == after_pause, "support timers freeze when gameplay does not advance")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SUPPORT_FIELD_SCHEDULE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
