extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var fingerprint := Catalog.geometry_fingerprint(&"stage_1")
	for stage_id in Catalog.STAGE_IDS:
		_expect(Catalog.geometry_fingerprint(stage_id) == fingerprint, "%s shares immutable field" % stage_id)
		_expect(Catalog.world_rect(stage_id) == Rect2(0,0,5600,3400), "%s world bounds" % stage_id)
		_expect(Catalog.player_start(stage_id) == Vector2(2800,1700), "%s center spawn" % stage_id)
		_expect(Catalog.static_enemy_blueprint(stage_id).size() == 4, "%s restocks four stationary threats" % stage_id)
		_expect(Catalog.pickup_blueprint(stage_id).size() == 3, "%s restocks three pickups" % stage_id)
		_expect(Catalog.crate_blueprint(stage_id).size() == 5, "%s restocks five crates" % stage_id)
		_expect(Catalog.packets(stage_id).all(func(packet: Dictionary) -> bool: return StringName(packet["trigger"]["kind"]) == &"time"), "%s uses only timed arrivals" % stage_id)
	var center := Catalog.player_start()
	_expect(Rules.is_position_walkable(center, Rules.PLAYER_RADIUS, &"stage_1"), "center is walkable")
	for cover in Catalog.cover_rects():
		_expect(not Rules.circle_overlaps_rect(center, 480.0, cover), "center clearance contains no cover")
	for water in Catalog.water_rects():
		_expect(not Rules.circle_overlaps_rect(center, 480.0, water), "center clearance contains no water")
	for anchor in Catalog.stationary_anchors():
		_expect(center.distance_to(anchor) >= 480.0, "center clearance contains no stationary threat")
	_expect(Catalog.cover_rects().size() == 13 and Catalog.water_rects().size() == 4, "blocker and border-water counts are exact")
	_expect(5600.0 / 1280.0 > 4.0 and 3400.0 / 720.0 > 4.0, "field cannot fit in one gameplay viewport")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_LAYOUTS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
