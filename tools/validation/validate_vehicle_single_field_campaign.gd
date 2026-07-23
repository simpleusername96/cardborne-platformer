extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	var fingerprints := {}
	for index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[index]
		var definition := Catalog.definition(stage_id)
		_expect(Catalog.validate_definition(definition, stage_id).is_empty(), "%s schema" % stage_id)
		_expect(Catalog.authored_population(stage_id) >= Catalog.quota(stage_id) + 32, "%s finite population exceeds quota plus active cap" % stage_id)
		fingerprints[Catalog.geometry_fingerprint(stage_id)] = true
	_expect(fingerprints.size() == 1, "all five stages share one geometry fingerprint")
	_expect(Catalog.world_rect() == Rect2(0, 0, 5600, 3400), "world is exactly 5600x3400")
	_expect(Catalog.player_start() == Vector2(2800, 1700), "start is exact field center")
	_expect(Catalog.walkable_regions().size() == 16, "translated core and six extensions are present")
	_expect(Catalog.cover_rects().is_empty(), "static field leaves internal cover to the run layout")
	_expect(layout.cover_rects.size() == 8, "run layout has eight modular blockers")
	_expect(Catalog.water_rects().size() == 4, "field has four border-water regions")
	_expect(Catalog.motifs().size() == 4, "field has four macro motifs")
	_expect(Catalog.ordinary_spawn_anchors().size() == 24, "field has twenty-four ordinary candidates")
	_expect(layout.ordinary_spawn_anchors.size() >= 16, "run layout retains at least sixteen ordinary anchors")
	_expect(Catalog.boss_arrival_anchors().size() == 8, "field has eight boss anchors")
	for anchor in layout.ordinary_spawn_anchors:
		_expect(Rules.grid_reachable_with_extra(Catalog.player_start(), anchor, 36.0, 96.0, false, &"stage_1", layout.cover_rects), "ordinary anchor reaches center")
	for anchor in layout.boss_arrival_anchors:
		_expect(Rules.grid_reachable_with_extra(Catalog.player_start(), anchor, 76.0, 96.0, false, &"stage_1", layout.cover_rects), "boss anchor reaches center")
	_check_stage_flow()
	_finish()


func _check_stage_flow() -> void:
	for index in Catalog.STAGE_IDS.size():
		var flow := StageFlow.new()
		flow.configure(index, Catalog.quota(Catalog.STAGE_IDS[index]))
		_expect(not flow.tick(999.0), "elapsed time alone cannot start a boss warning")
		_expect(not flow.record_boss_defeat(), "boss defeat cannot complete an ordinary encounter")
		for defeat in flow.quota:
			var triggered := flow.record_countable_defeat()
			_expect(triggered == (defeat == flow.quota - 1), "boss warning starts on exact quota")
		_expect(flow.stop_ordinary_spawning(), "quota stops ordinary spawning")
		_expect(flow.tick(1.5), "warning resolves after 1.5 seconds")
		_expect(flow.boss_entry_ready(), "boss entry requires the exact defeat quota")
		_expect(flow.record_boss_defeat(), "active boss defeat begins rewards")
		flow.record_rewards_complete()
		_expect(flow.state == StageFlow.State.COMPLETE, "stage flow reaches complete without a map trigger")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SINGLE_FIELD_CAMPAIGN_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
