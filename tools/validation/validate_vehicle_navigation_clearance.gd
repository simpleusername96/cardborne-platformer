extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Pursuit = preload("res://scripts/enemies/vehicle_pursuit_field.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	var pursuit := Pursuit.new()
	pursuit.reset(&"stage_1", layout.cover_rects)
	pursuit.update(0.2, Catalog.player_start())
	for anchor in layout.ordinary_spawn_anchors:
		_expect(pursuit.path_cost(anchor, 36.0) >= 0, "ordinary pursuit reaches a spawn anchor")
	for anchor in layout.boss_arrival_anchors:
		_expect(pursuit.path_cost(anchor, 76.0) >= 0, "boss pursuit reaches an arrival anchor")
	for cover in layout.cover_rects:
		_expect(
			Rules.move_circle_with_extra(
				cover.get_center() - Vector2(200.0, 0.0), Vector2(200.0, 0.0),
				24.0, false, &"stage_1", layout.cover_rects
			) != cover.get_center(),
			"visible runtime cover rejects movement"
		)
	var snapshot := pursuit.debug_snapshot()
	_expect(is_equal_approx(float(snapshot["cell_size"]), 96.0) and is_equal_approx(float(snapshot["rebuild_interval"]), 0.2), "shared pursuit uses 96px cells at max 5Hz")
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
