extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	var valid_masks := 0
	for nw in 6:
		for ne in 6:
			for sw in 6:
				for se in 6:
					var ids := Generator.cover_ids_for_mask([nw, ne, sw, se])
					var errors := Generator.validate_cover_ids(ids)
					if errors.is_empty():
						valid_masks += 1
					else:
						_expect(false, "cover mask %s is invalid: %s" % [[nw, ne, sw, se], "; ".join(errors)])
	_expect(valid_masks == 1296, "all 1296 modular cover masks satisfy the field invariants")

	var fixed := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS)
	var replay := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS)
	_expect(fixed != null and replay != null, "fixed seed generates a complete layout")
	if fixed != null and replay != null:
		_expect(fixed.fingerprint == replay.fingerprint, "same seed reproduces one canonical layout")
		_expect(fixed.cover_rects.size() == 8, "layout selects exactly eight covers")
		_expect(fixed.ordinary_spawn_anchors.size() >= 16, "layout retains at least sixteen ordinary anchors")
		_expect(fixed.boss_arrival_anchors.size() == 8, "layout retains all eight boss anchors")
		for stage_id in Catalog.STAGE_IDS:
			_expect(fixed.stationary_blueprint(stage_id).size() == 4, "%s has four seeded stationary threats" % stage_id)
			_expect(fixed.pickup_blueprint(stage_id).size() == 3, "%s has three seeded pickups" % stage_id)
			_expect(fixed.crate_blueprint(stage_id).size() == 5, "%s has five seeded crates" % stage_id)
			_validate_stage_objects(fixed, stage_id)

	var varied := 0
	var previous_fingerprint := -1
	for seed_offset in 256:
		var layout := Generator.generate(FIXED_SEED + seed_offset, Catalog.STAGE_IDS)
		_expect(layout != null, "seed fixture %d generates without deleting required content" % seed_offset)
		if layout == null:
			continue
		if previous_fingerprint >= 0 and layout.fingerprint != previous_fingerprint:
			varied += 1
		previous_fingerprint = layout.fingerprint
	_expect(varied >= 230, "at least 90 percent of adjacent seed fixtures vary")
	_finish()


func _validate_stage_objects(layout: VehicleFieldLayout, stage_id: StringName) -> void:
	var positions: Array[Vector2] = []
	for spec in layout.pickup_blueprint(stage_id):
		positions.append(Vector2(spec["pos"]))
	for spec in layout.crate_blueprint(stage_id):
		positions.append(Vector2(spec["pos"]))
	for first in positions.size():
		for second in range(first + 1, positions.size()):
			_expect(positions[first].distance_to(positions[second]) >= 200.0, "%s item sockets keep pair clearance" % stage_id)
	var recall_positions: Array[Vector2] = []
	for spec in layout.pickup_blueprint(stage_id):
		if StringName(spec["kind"]) == &"experience_recall":
			recall_positions.append(Vector2(spec["pos"]))
	for spec in layout.crate_blueprint(stage_id):
		if StringName(spec["drop"]) == &"experience_recall":
			recall_positions.append(Vector2(spec["pos"]))
	_expect(
		recall_positions.size() == 2 and recall_positions[0].distance_to(recall_positions[1]) >= 1200.0,
		"%s recall sources are spatially separated" % stage_id
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 32:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_FIELD_LAYOUT_GENERATION_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
