extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Geometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const COVER_LIMITS := {&"flooded_works":9, &"tidal_archive":10, &"storm_drydock":9, &"coral_switchyard":9, &"abyssal_observatory":8}
var failures := PackedStringArray()


func _initialize() -> void:
	_expect(Art.BLOCKER_FILL == Color("#07564C"), "blocker fill is the accepted ceramic green")
	for stage_id in Catalog.STAGE_IDS:
		_validate_stage(stage_id)
	if failures.is_empty():
		print("VEHICLE_NAVIGATION_CLEARANCE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _validate_stage(stage_id: StringName) -> void:
	var definition := Catalog.definition(stage_id)
	var polygons := Catalog.cover_polygons(stage_id)
	_expect(polygons.size() <= int(COVER_LIMITS[stage_id]), "%s respects its static-cover budget" % stage_id)
	_expect(polygons.size() == Catalog.cover_rects(stage_id).size(), "%s derives one collision polygon per rendered blocker" % stage_id)
	for index in polygons.size():
		_expect(Geometry.polygon_bounds(polygons[index]).is_equal_approx(Catalog.cover_rects(stage_id)[index]), "%s blocker %d shares exact draw and collision bounds" % [stage_id, index])
	_validate_blocker_gaps(stage_id, Catalog.cover_rects(stage_id))

	var start := Catalog.player_start(stage_id)
	var clearance := float(definition["start_clearance"])
	for polygon in polygons:
		_expect(not Geometry.circle_overlaps_polygon(start, clearance, polygon), "%s start clearance excludes static cover" % stage_id)
	for crate in Catalog.crate_blueprint(stage_id):
		_expect(start.distance_to(Vector2(crate["pos"])) >= clearance + 31.0, "%s start clearance excludes crates" % stage_id)
	for enemy in Catalog.static_enemy_blueprint(stage_id):
		_expect(start.distance_to(Vector2(enemy["pos"])) >= clearance + 28.0, "%s start clearance excludes static enemies" % stage_id)

	var landmarks := Catalog.landmarks(stage_id)
	for landmark_id in ["open_entry", "installation_entry", "upper_route", "lower_route", "generator_a", "generator_b", "chest", "boss_gate"]:
		_expect(Rules.grid_reachable(start, Vector2(landmarks[landmark_id]), Rules.PLAYER_RADIUS, 56.0, false, stage_id), "%s keeps a player-clear route to %s" % [stage_id, landmark_id])
	for landmark_id in ["open_entry", "installation_entry", "upper_route", "lower_route", "boss_gate"]:
		_expect(_reachable_near_with_clearance(start, Vector2(landmarks[landmark_id]), 160.0, 84.0, stage_id), "%s presents at least 168 pixels of route clearance to %s" % [stage_id, landmark_id])
	_expect(Rules.grid_reachable(start, Vector2(landmarks["open_entry"]), 160.0, 56.0, false, stage_id), "%s keeps its arrival lane at least 320 pixels wide" % stage_id)
	_expect(_reachable_near_with_clearance(start, Vector2(landmarks["upper_route"]), 190.0, 120.0, stage_id) or _reachable_near_with_clearance(start, Vector2(landmarks["lower_route"]), 190.0, 120.0, stage_id), "%s preserves a 240-pixel turning route" % stage_id)
	for pickup in Catalog.pickup_blueprint(stage_id):
		_expect(_reachable_near(start, Vector2(pickup["pos"]), 48.0, stage_id), "%s pickup %s remains reachable" % [stage_id, pickup["id"]])
	for crate in Catalog.crate_blueprint(stage_id):
		_expect(_reachable_near(start, Vector2(crate["pos"]), 120.0, stage_id), "%s crate %s remains attackable from a reachable position" % [stage_id, crate["id"]])
	_validate_live_obstacles(stage_id, start, landmarks)
	_validate_dynamic_states(stage_id, start, landmarks)


func _validate_blocker_gaps(stage_id: StringName, rects: Array[Rect2]) -> void:
	for first_index in rects.size():
		for second_index in range(first_index + 1, rects.size()):
			var first := rects[first_index]
			var second := rects[second_index]
			var vertical_overlap := minf(first.end.y, second.end.y) - maxf(first.position.y, second.position.y)
			var horizontal_gap := maxf(second.position.x - first.end.x, first.position.x - second.end.x)
			if vertical_overlap > 48.0 and horizontal_gap > 0.0:
				_expect(horizontal_gap >= 168.0, "%s does not present a false horizontal opening" % stage_id)
			var horizontal_overlap := minf(first.end.x, second.end.x) - maxf(first.position.x, second.position.x)
			var vertical_gap := maxf(second.position.y - first.end.y, first.position.y - second.end.y)
			if horizontal_overlap > 48.0 and vertical_gap > 0.0:
				_expect(vertical_gap >= 168.0, "%s does not present a false vertical opening" % stage_id)


func _reachable_near(start: Vector2, target: Vector2, approach_radius: float, stage_id: StringName) -> bool:
	if Rules.grid_reachable(start, target, Rules.PLAYER_RADIUS, 42.0, false, stage_id):
		return true
	for index in 8:
		var approach := target + Vector2.RIGHT.rotated(TAU * float(index) / 8.0) * approach_radius
		if Rules.is_position_walkable(approach, Rules.PLAYER_RADIUS, stage_id) and Rules.grid_reachable(start, approach, Rules.PLAYER_RADIUS, 42.0, false, stage_id):
			return true
	return false


func _reachable_near_with_clearance(start: Vector2, target: Vector2, approach_radius: float, clearance_radius: float, stage_id: StringName) -> bool:
	if Rules.is_position_walkable(target, clearance_radius, stage_id) and Rules.grid_reachable(start, target, clearance_radius, 42.0, false, stage_id):
		return true
	for index in 16:
		var approach := target + Vector2.RIGHT.rotated(TAU * float(index) / 16.0) * approach_radius
		if Rules.is_position_walkable(approach, clearance_radius, stage_id) and Rules.grid_reachable(start, approach, clearance_radius, 42.0, false, stage_id):
			return true
	return false


func _validate_live_obstacles(stage_id: StringName, start: Vector2, landmarks: Dictionary) -> void:
	var obstacle_rects: Array[Rect2] = []
	for crate in Catalog.crate_blueprint(stage_id):
		obstacle_rects.append(Rect2(Vector2(crate["pos"]) - Vector2(31.0, 31.0), Vector2(62.0, 62.0)))
	for enemy in Catalog.static_enemy_blueprint(stage_id):
		if StringName(enemy["role"]) in [&"generator", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel"]:
			obstacle_rects.append(Rect2(Vector2(enemy["pos"]) - Vector2(38.0, 38.0), Vector2(76.0, 76.0)))
	for landmark_id in ["open_entry", "installation_entry", "upper_route", "lower_route", "boss_gate"]:
		_expect(Rules.grid_reachable_with_extra(start, Vector2(landmarks[landmark_id]), Rules.PLAYER_RADIUS, 42.0, false, stage_id, obstacle_rects), "%s live crates and installations preserve the route to %s" % [stage_id, landmark_id])


func _validate_dynamic_states(stage_id: StringName, start: Vector2, landmarks: Dictionary) -> void:
	var zones := Catalog.environment_zones(stage_id)
	if stage_id == &"coral_switchyard":
		for state in 2:
			var gates: Array[Rect2] = []
			for zone in zones:
				if StringName(zone.get("kind", &"")) == &"switch_gate":
					gates.append(Rect2(zone["positions"][state]))
			_expect(Rules.grid_reachable_with_extra(start, Vector2(landmarks["boss_gate"]), Rules.PLAYER_RADIUS, 42.0, false, stage_id, gates), "coral_switchyard switch state %d preserves one route to the boss gate" % state)
	elif stage_id == &"abyssal_observatory":
		var reflectors: Array[Rect2] = []
		var closed: Array[Rect2] = []
		for zone in zones:
			match StringName(zone.get("kind", &"")):
				&"reflector":
					reflectors.append(Rect2(zone["rect"]))
				&"vault_gate":
					closed.append(Rect2(zone["rect"]))
		closed.append_array(reflectors)
		_expect(Rules.grid_reachable_with_extra(start, Vector2(landmarks["boss_gate"]), Rules.PLAYER_RADIUS, 42.0, false, stage_id, closed), "abyssal_observatory closed vault preserves the required route")
		_expect(Rules.grid_reachable_with_extra(start, Vector2(landmarks["field_boss"]), Rules.PLAYER_RADIUS, 42.0, false, stage_id, reflectors), "abyssal_observatory aligned vault exposes the optional boss route")


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
