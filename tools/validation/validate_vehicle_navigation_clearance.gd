extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Pursuit = preload("res://scripts/enemies/vehicle_pursuit_field.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	Catalog.activate_field(layout.field_id)
	var pursuit := Pursuit.new()
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		var tactical_snapshot := tactical.debug_snapshot()
		_expect(
			is_equal_approx(float(tactical_snapshot["fast_motion_cell_size"]), 80.0)
				and is_equal_approx(float(tactical_snapshot["fast_motion_radius"]), 36.0)
				and int(tactical_snapshot["fast_motion_safe_cell_count"]) > 0,
			"%s compiles a non-empty combined tactical fast-motion mask" % stage_id
		)
		var start := Vector2(tactical.geometry_snapshot.player_start)
		_expect(
			tactical.is_fast_motion_clear(start, start + Vector2(12.0, 0.0), 36.0)
			and Catalog.is_fast_motion_clear(
				stage_id, start, start + Vector2(12.0, 0.0), 36.0
			),
			"%s keeps the clear center on the certified fast path" % stage_id
		)
		_expect(
			not tactical.is_fast_motion_clear(start, start + Vector2(80.0, 0.0), 36.0),
			"%s sends cross-cell motion to the exact solver" % stage_id
		)
		_expect(
			not tactical.is_fast_motion_clear(start, start + Vector2(12.0, 0.0), 76.0),
			"%s keeps boss-radius motion off the fast path" % stage_id
		)
		var outside := Rect2(layout.field_definition["world_rect"]).position - Vector2(8.0, 8.0)
		_expect(
			not tactical.is_fast_motion_clear(outside, outside + Vector2(4.0, 0.0), 24.0)
			and not Catalog.is_fast_motion_clear(
				stage_id, outside, outside + Vector2(4.0, 0.0), 24.0
			),
			"%s keeps out-of-bounds motion off the fast path" % stage_id
		)
		for cover in tactical.cover_rects:
			var cover_center := cover.get_center()
			_expect(
				not tactical.is_fast_motion_clear(
					cover_center, cover_center + Vector2(1.0, 0.0), 24.0
				),
				"%s selected cover cells remain uncertified" % stage_id
			)
		for feature_value in Array(layout.field_definition.get("features", [])):
			var feature := Dictionary(feature_value)
			if StringName(feature.get("kind", &"")) not in [
				&"structural_wall", &"breakable_bulkhead",
			]:
				continue
			var feature_center := Rect2(feature["rect"]).get_center()
			_expect(
				not tactical.is_fast_motion_clear(
					feature_center, feature_center + Vector2(1.0, 0.0), 24.0
				),
				"%s static wall and bulkhead cells remain uncertified" % stage_id
			)
		pursuit.reset(stage_id, tactical.cover_rects)
		for _step in 8:
			pursuit.update(0.2, Catalog.player_start())
		for anchor in tactical.ordinary_spawn_anchors:
			_expect(pursuit.path_cost(anchor, 36.0) >= 0, "%s ordinary pursuit reaches a spawn anchor" % stage_id)
		if not tactical.boss_arrival_anchors.is_empty():
			pursuit.path_cost(tactical.boss_arrival_anchors[0], 76.0)
		for _step in 8:
			pursuit.update(0.2, Catalog.player_start())
		for anchor in tactical.boss_arrival_anchors:
			_expect(pursuit.path_cost(anchor, 76.0) >= 0, "%s boss pursuit reaches an arrival anchor" % stage_id)
		for cover in tactical.cover_rects:
			_expect(
				Rules.move_circle_with_extra(
					cover.get_center() - Vector2(200.0, 0.0), Vector2(200.0, 0.0),
					24.0, false, stage_id, tactical.cover_rects
				) != cover.get_center(),
				"%s visible runtime cover rejects movement" % stage_id
			)
	var snapshot := pursuit.debug_snapshot()
	_expect(
		is_equal_approx(float(snapshot["cell_size"]), 96.0)
		and Vector2i(snapshot["grid_size"]) == Vector2i(75,45)
		and int(snapshot["max_rebuild_cells_per_tick"]) == 512
		and is_equal_approx(float(snapshot["rebuild_interval"]), 0.2),
		"shared pursuit uses a bounded packed 75x45 field"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_NAVIGATION_CLEARANCE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
