extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var fingerprint := Catalog.geometry_fingerprint(&"stage_1")
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	_expect(layout != null, "fixed validation seed produces a field layout")
	for stage_id in Catalog.STAGE_IDS:
		_expect(Catalog.geometry_fingerprint(stage_id) == fingerprint, "%s shares immutable field" % stage_id)
		_expect(Catalog.world_rect(stage_id) == Rect2(0,0,5600,3400), "%s world bounds" % stage_id)
		_expect(Catalog.player_start(stage_id) == Vector2(2800,1700), "%s center spawn" % stage_id)
		_expect(layout.stationary_blueprint(stage_id).size() == 4, "%s restocks four stationary threats" % stage_id)
		_expect(layout.pickup_blueprint(stage_id).size() == 3, "%s restocks three pickups" % stage_id)
		_expect(layout.crate_blueprint(stage_id).size() == 5, "%s restocks five crates" % stage_id)
		_expect(Catalog.packets(stage_id).all(func(packet: Dictionary) -> bool: return StringName(packet["trigger"]["kind"]) == &"time"), "%s uses only timed arrivals" % stage_id)
		var mobile_blueprint := Catalog.packet_enemy_blueprint(stage_id)
		var mobile_projectile_count := mobile_blueprint.filter(
			func(spec: Dictionary) -> bool:
				return EnemyArchetypes.fires_projectiles(StringName(spec["role"]))
		).size()
		_expect(
			float(mobile_projectile_count) / float(maxi(1, mobile_blueprint.size())) <= 0.50,
			"%s keeps projectile-firing mobile enemies at or below half" % stage_id
		)
		var stationary_blueprint := layout.stationary_blueprint(stage_id)
		var stationary_projectile_count := stationary_blueprint.filter(
			func(spec: Dictionary) -> bool:
				return EnemyArchetypes.fires_projectiles(StringName(spec["role"]))
		).size()
		_expect(
			float(stationary_projectile_count) / float(maxi(1, stationary_blueprint.size())) <= 0.50,
			"%s keeps projectile-firing stationary enemies at or below half" % stage_id
		)
	var center := Catalog.player_start()
	_expect(Rules.is_position_walkable(center, Rules.PLAYER_RADIUS, &"stage_1"), "center is walkable")
	for cover in layout.cover_rects:
		_expect(not Rules.circle_overlaps_rect(center, 480.0, cover), "center clearance contains no cover")
	for water in Catalog.water_rects():
		_expect(not Rules.circle_overlaps_rect(center, 480.0, water), "center clearance contains no water")
	for stage_id in Catalog.STAGE_IDS:
		for spec in layout.stationary_blueprint(stage_id):
			_expect(center.distance_to(Vector2(spec["pos"])) >= 480.0, "center clearance contains no stationary threat")
	_expect(Catalog.cover_rects().is_empty(), "static catalog owns no internal cover")
	_expect(layout.cover_rects.size() == 8 and Catalog.water_rects().size() == 4, "runtime blocker and border-water counts are exact")
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
