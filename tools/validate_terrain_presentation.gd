extends SceneTree

const STAGE_SCENE := "res://scenes/stages/production/ProductionStageHost.tscn"
const STAGE_IDS := [&"ruin_approach", &"flooded_works", &"broken_sanctum"]

var _failures: Array[String] = []
var _rock_colors: Array[Color] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	_expect(run_state != null and profile_state != null, "terrain presentation needs production state")
	if run_state == null or profile_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	var packed := load(STAGE_SCENE) as PackedScene
	for stage_index in STAGE_IDS.size():
		run_state.start_new_run(0, 96200 + stage_index)
		run_state.set("current_stage_index", stage_index)
		var stage := packed.instantiate()
		root.add_child(stage)
		await process_frame
		_validate_stage(stage, STAGE_IDS[stage_index])
		stage.queue_free()
		await process_frame
	_expect(_rock_colors.size() == 3, "all three regional rock palettes should resolve")
	if _rock_colors.size() == 3:
		_expect(
			_rock_colors[0] != _rock_colors[1]
			and _rock_colors[1] != _rock_colors[2]
			and _rock_colors[0] != _rock_colors[2],
			"each region should have a distinct rock material color"
		)
	_finish()


func _validate_stage(stage: Node, expected_stage_id: StringName) -> void:
	_expect(stage.is_setup_complete(), "%s should assemble before styling" % expected_stage_id)
	var snapshot: Dictionary = stage.get_terrain_presentation_snapshot()
	_expect(snapshot.get("stage_id") == String(expected_stage_id), "%s should retain palette ownership" % expected_stage_id)
	_expect(int(snapshot.get("styled_total", 0)) >= 20, "%s should style the assembled terrain family" % expected_stage_id)
	var counts: Dictionary = snapshot.get("counts", {})
	_expect(int(counts.get("rock", 0)) > 0, "%s should style filled rock masses" % expected_stage_id)
	_expect(int(counts.get("cap", 0)) > 0, "%s should style readable support caps" % expected_stage_id)
	var palette: Dictionary = snapshot.get("palette", {})
	var rock_color: Color = palette.get("rock", Color.TRANSPARENT)
	_rock_colors.append(rock_color)
	var found_rock := false
	for room_id in stage.get_room_ids():
		var room: Node = stage.get_room_host(room_id)
		for node in room.find_children("RockVisual", "Polygon2D", true, false):
			found_rock = true
			_expect((node as Polygon2D).color == rock_color, "%s rock masses should consume the regional palette" % expected_stage_id)
			break
		if found_rock:
			break
	_expect(found_rock, "%s should expose at least one rock visual" % expected_stage_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TERRAIN_PRESENTATION_VALIDATION_OK stages=3 distinct_palettes=3")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
