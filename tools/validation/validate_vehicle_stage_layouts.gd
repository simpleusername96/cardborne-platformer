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
	Catalog.activate_field(layout.field_id)
	fingerprint = Catalog.geometry_fingerprint(&"stage_1")
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		_expect(Catalog.geometry_fingerprint(stage_id) == fingerprint, "%s shares immutable field" % stage_id)
		_expect(Catalog.world_rect(stage_id) == Rect2(0,0,7200,4320), "%s world bounds" % stage_id)
		_expect(Catalog.player_start(stage_id) == Vector2(3600,2160), "%s center spawn" % stage_id)
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
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		for cover in tactical.cover_rects:
			_expect(not Rules.circle_overlaps_rect(center, 560.0, cover), "%s center clearance contains no cover" % stage_id)
	for water in Catalog.water_rects():
		_expect(not Rules.circle_overlaps_rect(center, 560.0, water), "center clearance contains no water")
	for stage_id in Catalog.STAGE_IDS:
		for spec in layout.stationary_blueprint(stage_id):
			_expect(center.distance_to(Vector2(spec["pos"])) >= 560.0, "center clearance contains no stationary threat")
	_expect(Catalog.cover_rects().is_empty(), "static catalog owns no internal cover")
	for stage_id in Catalog.STAGE_IDS:
		_expect(layout.tactical_layout(stage_id).cover_rects.size() == 8, "%s runtime blocker count is exact" % stage_id)
	_expect(7200.0 / 1280.0 > 5.0 and 4320.0 / 720.0 >= 6.0, "field cannot fit in one gameplay viewport")
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
