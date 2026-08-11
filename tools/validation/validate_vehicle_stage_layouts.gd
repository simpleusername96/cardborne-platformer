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
		_expect(layout.mystery_device_blueprint(stage_id).size() == 3, "%s scatters three mystery devices" % stage_id)
		_expect(layout.pickup_blueprint(stage_id).size() == 14, "%s restocks fourteen direct pickups" % stage_id)
		_expect(Catalog.packets(stage_id).all(func(packet: Dictionary) -> bool: return StringName(packet["trigger"]["kind"]) == &"time"), "%s uses only timed arrivals" % stage_id)
		var mobile_blueprint := Catalog.packet_enemy_blueprint(stage_id)
		var mobile_projectile_count := mobile_blueprint.filter(
			func(spec: Dictionary) -> bool:
				return EnemyArchetypes.fires_projectiles(StringName(spec["role"]))
		).size()
		_expect(
			float(mobile_projectile_count) / float(maxi(1, mobile_blueprint.size())) <= 0.15,
			"%s keeps projectile-firing mobile enemies at or below fifteen percent" % stage_id
		)
	var center := Catalog.player_start()
	_expect(Rules.is_position_walkable(center, Rules.PLAYER_RADIUS, &"stage_1"), "center is walkable")
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		for cover in tactical.cover_rects:
			_expect(not Rules.circle_overlaps_rect(center, 560.0, cover), "%s center clearance contains no cover" % stage_id)
	for void_rect in Catalog.void_rects():
		_expect(not Rules.circle_overlaps_rect(center, 560.0, void_rect), "center clearance contains no void")
	for feature in layout.run_feature_blueprint():
		if Dictionary(feature).has("rect"):
			_expect(not Rules.circle_overlaps_rect(center, 560.0, Rect2(feature["rect"])), "center clearance contains no fixed field feature")
	_expect(Catalog.cover_rects().is_empty(), "static catalog owns no internal cover")
	var walls := layout.run_feature_blueprint().filter(func(feature: Dictionary) -> bool: return StringName(feature["kind"]) == &"structural_wall")
	var groups := {}
	for wall in walls:
		groups[int(wall.get("group", -1))] = true
	_expect(groups.size() == 5, "run fixes exactly five inner-wall groups")
	var templates := {}
	for wall in walls: templates[StringName(wall.get("template", &""))] = true
	_expect(templates.size() == 5, "wall groups use five unique templates")
	for stage_id in Catalog.STAGE_IDS:
		for device in layout.mystery_device_blueprint(stage_id):
			_expect(not device.has("effect"), "%s device blueprint hides outcome" % stage_id)
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
