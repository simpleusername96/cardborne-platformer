extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for stage_id in Catalog.STAGE_IDS:
		var data := Catalog.definition(stage_id)
		_expect(not data.is_empty(), "%s definition loads" % stage_id)
		_expect(Catalog.validate_definition(data, stage_id).is_empty(), "%s definition satisfies the shared schema" % stage_id)
		var errors := Rules.validate_blueprint(stage_id)
		_expect(errors.is_empty(), "%s geometry, content anchors, and routes agree" % stage_id)
		for error in errors:
			failures.append("%s: %s" % [stage_id, error])
		_expect(Catalog.walkable_regions(stage_id).size() == Rules.get_floor_regions(stage_id).size(), "%s renders every walkable region from shared data" % stage_id)
		_expect(Rules.is_position_walkable(Catalog.player_start(stage_id), Rules.PLAYER_RADIUS, stage_id), "%s start is walkable" % stage_id)

	var stage_id := &"flooded_works"
	var world := Catalog.world_rect(stage_id)
	var start := Catalog.player_start(stage_id)
	_expect(world == Rect2(0,0,4400,2800), "Flooded Works uses the locked 4400x2800 world")
	_expect(start == world.get_center() and start == Vector2(2200,1400), "Flooded Works starts at the exact map center")
	for cover in Catalog.cover_rects(stage_id):
		_expect(not Rules.circle_overlaps_rect(start, 360.0, cover), "Flooded Works start clearance contains no cover")
	for water in Catalog.water_rects(stage_id):
		_expect(not Rules.circle_overlaps_rect(start, 360.0, water), "Flooded Works start clearance contains no water")
	for enemy in Catalog.enemy_blueprint(stage_id):
		_expect(start.distance_to(Vector2(enemy["pos"])) >= 360.0, "Flooded Works start clearance contains no enemy spawn")
	var landmarks := Catalog.landmarks(stage_id)
	for landmark_id in ["open_entry", "upper_route", "lower_route", "generator_a", "generator_b", "field_boss", "chest", "boss_gate", "boss"]:
		_expect(Rules.grid_reachable(start, landmarks[landmark_id], Rules.PLAYER_RADIUS, 56.0, false, stage_id), "Flooded Works reaches %s" % landmark_id)
	_expect(not Rules.is_position_walkable(Vector2(2800,1400), Rules.PLAYER_RADIUS, stage_id), "cobalt center channel is non-walkable")
	var first_cover := Catalog.cover_rects(stage_id)[0]
	_expect(not Rules.is_position_walkable(first_cover.get_center(), Rules.PLAYER_RADIUS, stage_id), "ceramic cover is non-walkable")
	_expect(Rules.move_circle(start, Vector2(0,-240), Rules.PLAYER_RADIUS, false, stage_id) != start, "central plaza permits movement")

	if failures.is_empty():
		print("PASS: per-stage schema, shared walkability, central Flooded Works start, clearance, and route reachability")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
