extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Registry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in Registry.FIELD_IDS:
		_validate_field(field_id)
	_validate_seeded_fallback_variation()
	_finish()


func _validate_field(field_id: StringName) -> void:
	var definition := Registry.definition(field_id)
	_expect(Rect2(definition["world_rect"]) == Rect2(0,0,7200,4320), "%s uses shared world bounds" % field_id)
	_expect(Vector2(definition["player_start"]) == Vector2(3600,2160), "%s uses shared center" % field_id)
	_expect(float(definition["start_clearance"]) == 560.0, "%s uses center clearance" % field_id)
	_expect(Array(definition["walkable_regions"]).size() >= 20, "%s has twenty broad regions" % field_id)
	_expect(Array(definition["ordinary_spawn_anchors"]).size() == 32, "%s has 32 ordinary anchors" % field_id)
	_expect(Array(definition["boss_arrival_anchors"]).size() == 12, "%s has 12 boss anchors" % field_id)
	_expect(Array(definition["item_socket_candidates"]).size() >= 32, "%s has at least 32 item sockets" % field_id)
	_expect(
		Generator.validate_feature_contract(definition).is_empty(),
		"%s functional terrain has valid disjoint footprints" % field_id
	)

	var fixed := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
	var replay := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
	_expect(fixed != null and replay != null, "%s fixed seed generates a complete layout" % field_id)
	if fixed == null or replay == null:
		return
	_expect(fixed.field_id == field_id, "%s layout retains field id" % field_id)
	_expect(fixed.fingerprint == replay.fingerprint, "%s same seed reproduces layout" % field_id)
	_validate_no_feature_overlaps(fixed, fixed.field_definition)
	var fixed_features := fixed.run_feature_blueprint()
	_expect(fixed_features.filter(func(feature: Dictionary) -> bool: return StringName(feature["kind"]) == &"hazard_zone").size() == 4, "%s fixes four hazard zones" % field_id)
	var wall_groups := {}
	for feature in fixed_features:
		if StringName(feature["kind"]) == &"structural_wall": wall_groups[int(feature.get("group", -1))] = true
	_expect(wall_groups.size() == 5, "%s fixes five inner-wall groups" % field_id)
	for stage_id in Catalog.STAGE_IDS:
		var tactical := fixed.tactical_layout(stage_id)
		_expect(tactical != null, "%s/%s has a tactical layout" % [field_id, stage_id])
		if tactical == null:
			continue
		_expect(tactical.cover_rects.is_empty(), "%s/%s retires dedicated cover" % [field_id, stage_id])
		_expect(tactical.ordinary_spawn_anchors.size() >= 20, "%s/%s retains at least 20 ordinary anchors" % [field_id, stage_id])
		_expect(tactical.boss_arrival_anchors.size() >= 8, "%s/%s retains at least eight boss anchors" % [field_id, stage_id])
		_expect(fixed.mystery_device_blueprint(stage_id).size() == 3, "%s/%s has three mystery devices" % [field_id, stage_id])
		_expect(fixed.pickup_blueprint(stage_id).size() == 6, "%s/%s has six loose pickups" % [field_id, stage_id])
		_expect(fixed.crate_blueprint(stage_id).size() == 8, "%s/%s has eight crates" % [field_id, stage_id])
		_validate_stage_objects(fixed, stage_id)
		_validate_stage_spacing(fixed, stage_id)

	var varied := 0
	var previous_fingerprint := fixed.fingerprint
	for seed_offset in 48:
		var layout := Generator.generate(FIXED_SEED + seed_offset, Catalog.STAGE_IDS, field_id)
		_expect(layout != null, "%s seed fixture %d generates" % [field_id, seed_offset])
		if layout == null:
			continue
		_validate_no_feature_overlaps(layout, layout.field_definition)
		if layout.fingerprint != previous_fingerprint:
			varied += 1
		previous_fingerprint = layout.fingerprint
	_expect(varied >= 42, "%s adjacent seed fixtures vary" % field_id)


func _validate_seeded_fallback_variation() -> void:
	# Exercise the defensive path directly so a later geometry edit cannot make
	# every rejected run seed collapse onto one shared fallback structure.
	var definition := Registry.definition(Registry.FIELD_IDS[0])
	Generator.validate_feature_contract(definition)
	var first: Array[Dictionary] = Generator._fallback_run_features(FIXED_SEED)
	var replay: Array[Dictionary] = Generator._fallback_run_features(FIXED_SEED)
	var varied: Array[Dictionary] = Generator._fallback_run_features(FIXED_SEED + 1)
	_expect(not first.is_empty() and not varied.is_empty(), "seeded fallback compiles complete structures")
	_expect(var_to_bytes(first) == var_to_bytes(replay), "same seed reproduces fallback structure")
	_expect(var_to_bytes(first) != var_to_bytes(varied), "different seeds vary fallback structure")


func _validate_no_feature_overlaps(
	layout: VehicleFieldLayout,
	definition: Dictionary
) -> void:
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		if tactical == null:
			continue
		for rectangle in tactical.cover_rects:
			_expect(not Generator.feature_overlaps_rect(definition, rectangle), "%s/%s generated cover avoids functional terrain" % [layout.field_id, stage_id])
		for anchor in tactical.ordinary_spawn_anchors:
			_expect(not Generator.feature_overlaps_circle(definition, anchor, 36.0), "%s/%s ordinary spawn avoids functional terrain" % [layout.field_id, stage_id])
		for anchor in tactical.boss_arrival_anchors:
			_expect(not Generator.feature_overlaps_circle(definition, anchor, 76.0), "%s/%s boss spawn avoids functional terrain" % [layout.field_id, stage_id])
		for spec in layout.pickup_blueprint(stage_id):
			_expect(
				not Generator.feature_overlaps_circle(
					definition, Vector2(spec["pos"]), 54.0
				),
				"%s/%s pickup avoids functional terrain" % [
					layout.field_id, stage_id
				]
			)
		for spec in layout.crate_blueprint(stage_id):
			_expect(
				not Generator.feature_overlaps_circle(
					definition, Vector2(spec["pos"]), 54.0
				),
				"%s/%s crate avoids functional terrain" % [
					layout.field_id, stage_id
				]
			)


func _validate_stage_objects(layout: VehicleFieldLayout, stage_id: StringName) -> void:
	var positions: Array[Vector2] = []
	var occupied_sectors := {}
	var repair_values: Array[float] = []
	var loose_recall_count := 0
	var crate_recall_count := 0
	for spec in layout.pickup_blueprint(stage_id):
		var position := Vector2(spec["pos"])
		positions.append(position)
		occupied_sectors[
			_item_sector(position, Vector2(layout.field_definition["player_start"]))
		] = true
		if StringName(spec["kind"]) == &"experience_recall":
			loose_recall_count += 1
		else:
			repair_values.append(float(spec["heal_amount"]))
	for spec in layout.crate_blueprint(stage_id):
		var position := Vector2(spec["pos"])
		positions.append(position)
		occupied_sectors[
			_item_sector(position, Vector2(layout.field_definition["player_start"]))
		] = true
		if StringName(spec["drop"]) == &"experience_recall":
			crate_recall_count += 1
		else:
			repair_values.append(float(spec["heal_amount"]))
	for first in positions.size():
		for second in range(first + 1, positions.size()):
			_expect(positions[first].distance_to(positions[second]) >= 180.0, "%s item sockets keep pair clearance" % stage_id)
	_expect(occupied_sectors.size() >= 4, "%s items occupy at least four field sectors" % stage_id)
	_expect(loose_recall_count == 2, "%s keeps two loose recall pickups" % stage_id)
	_expect(crate_recall_count == 2, "%s keeps two crate recall drops" % stage_id)
	var twenty_five_count := repair_values.count(25.0)
	var twenty_count := repair_values.count(20.0)
	var repair_total := 0.0
	for value in repair_values:
		repair_total += value
	_expect(
		repair_values.size() == 10
			and twenty_five_count == 9
			and twenty_count == 1
			and is_equal_approx(repair_total, 245.0),
		"%s keeps ten repair events and the 245-hull budget" % stage_id
	)
	var recall_positions: Array[Vector2] = []
	for spec in layout.pickup_blueprint(stage_id):
		if StringName(spec["kind"]) == &"experience_recall":
			recall_positions.append(Vector2(spec["pos"]))
	for spec in layout.crate_blueprint(stage_id):
		if StringName(spec["drop"]) == &"experience_recall":
			recall_positions.append(Vector2(spec["pos"]))
	_expect(
		recall_positions.size() == 4 and _maximum_pair_distance(recall_positions) >= 1200.0,
		"%s four recall sources include a separated pair" % stage_id
	)


func _validate_stage_spacing(layout: VehicleFieldLayout, stage_id: StringName) -> void:
	var devices := layout.mystery_device_blueprint(stage_id)
	var crates := layout.crate_blueprint(stage_id)
	var pickups := layout.pickup_blueprint(stage_id)
	var hazards: Array = layout.run_feature_blueprint().filter(
		func(feature: Dictionary) -> bool: return StringName(feature["kind"]) == &"hazard_zone"
	)
	var gates: Array = layout.run_feature_blueprint().filter(
		func(feature: Dictionary) -> bool: return StringName(feature["kind"]) == &"transit_gate"
	)
	for first in devices.size():
		var device_pos := Vector2(devices[first]["pos"])
		for second in range(first + 1, devices.size()):
			_expect(device_pos.distance_to(Vector2(devices[second]["pos"])) >= 960.0, "%s devices keep 960 spacing" % stage_id)
		for hazard in hazards:
			_expect(_point_to_rect_distance(device_pos, Rect2(hazard["rect"])) >= 576.0, "%s device avoids hazard" % stage_id)
		for gate in gates:
			_expect(device_pos.distance_to(Vector2(gate["pos"])) >= 576.0, "%s device avoids gate" % stage_id)
	for first in crates.size():
		var crate_pos := Vector2(crates[first]["pos"])
		for second in range(first + 1, crates.size()):
			_expect(crate_pos.distance_to(Vector2(crates[second]["pos"])) >= 672.0, "%s crates keep 672 spacing" % stage_id)
		for device in devices:
			_expect(crate_pos.distance_to(Vector2(device["pos"])) >= 576.0, "%s crate avoids device" % stage_id)
		for hazard in hazards:
			_expect(_point_to_rect_distance(crate_pos, Rect2(hazard["rect"])) >= 384.0, "%s crate avoids hazard" % stage_id)
	for first in pickups.size():
		var pickup_pos := Vector2(pickups[first]["pos"])
		for second in range(first + 1, pickups.size()):
			_expect(pickup_pos.distance_to(Vector2(pickups[second]["pos"])) >= 384.0, "%s pickups keep 384 spacing" % stage_id)
		for crate in crates:
			_expect(pickup_pos.distance_to(Vector2(crate["pos"])) >= 384.0, "%s pickup avoids crate" % stage_id)
		for device in devices:
			_expect(pickup_pos.distance_to(Vector2(device["pos"])) >= 480.0, "%s pickup avoids device" % stage_id)
		for hazard in hazards:
			_expect(_point_to_rect_distance(pickup_pos, Rect2(hazard["rect"])) >= 384.0, "%s pickup avoids hazard" % stage_id)


func _point_to_rect_distance(point: Vector2, rectangle: Rect2) -> float:
	var nearest := Vector2(
		clampf(point.x, rectangle.position.x, rectangle.end.x),
		clampf(point.y, rectangle.position.y, rectangle.end.y)
	)
	return point.distance_to(nearest)


func _item_sector(position: Vector2, center: Vector2) -> int:
	var raw := floori(((position - center).angle() + PI) / (TAU / 8.0))
	return (raw % 8 + 8) % 8


func _maximum_pair_distance(points: Array[Vector2]) -> float:
	var result := 0.0
	for first in points.size():
		for second in range(first + 1, points.size()):
			result = maxf(result, points[first].distance_to(points[second]))
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_FIELD_LAYOUT_GENERATION_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
