extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	Catalog.activate_field(layout.field_id)
	var fingerprints := {}
	for index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[index]
		var definition := Catalog.definition(stage_id)
		_expect(Catalog.validate_definition(definition, stage_id).is_empty(), "%s schema" % stage_id)
		_expect(Catalog.authored_population(stage_id) >= Catalog.quota(stage_id) + 32, "%s finite population exceeds quota plus active cap" % stage_id)
		fingerprints[Catalog.geometry_fingerprint(stage_id)] = true
	_expect(fingerprints.size() == 1, "all eight cycles share one geometry fingerprint")
	_expect(Catalog.world_rect() == Rect2(0, 0, 7200, 4320), "world is exactly 7200x4320")
	_expect(Catalog.player_start() == Vector2(3600, 2160), "start is exact field center")
	_expect(Catalog.walkable_regions().size() >= 20, "field has at least twenty broad regions")
	_expect(Catalog.cover_rects().is_empty(), "static field leaves internal cover to the run layout")
	_expect(Catalog.ordinary_spawn_anchors().size() == 32, "field has thirty-two ordinary candidates")
	_expect(Catalog.boss_arrival_anchors().size() == 12, "field has twelve boss anchors")
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		_expect(tactical.cover_rects.is_empty(), "%s retires dedicated tactical blockers" % stage_id)
		_expect(tactical.ordinary_spawn_anchors.size() >= 20, "%s retains twenty ordinary anchors" % stage_id)
		for anchor in tactical.ordinary_spawn_anchors:
			_expect(Rules.grid_reachable_with_extra(Catalog.player_start(), anchor, 36.0, 96.0, false, stage_id, tactical.cover_rects), "%s ordinary anchor reaches center" % stage_id)
		for anchor in tactical.boss_arrival_anchors:
			_expect(Rules.grid_reachable_with_extra(Catalog.player_start(), anchor, 76.0, 96.0, false, stage_id, tactical.cover_rects), "%s boss anchor reaches center" % stage_id)
	_check_stage_flow()
	_finish()


func _check_stage_flow() -> void:
	for index in Catalog.STAGE_IDS.size():
		var flow := StageFlow.new()
		var stage_id := Catalog.STAGE_IDS[index]
		var has_boss := Catalog.has_boss(stage_id)
		flow.configure(index, Catalog.quota(stage_id), has_boss)
		_expect(
			StringName(flow.advance(999.0)["command"]).is_empty(),
			"elapsed time alone cannot start a boss warning"
		)
		_expect(
			not bool(flow.record_boss_defeat()["accepted"]),
			"boss defeat cannot complete an ordinary encounter"
		)
		for defeat in flow.quota:
			var receipt := flow.record_countable_defeat()
			_expect(StageFlow.valid_receipt(receipt), "quota receipt shape is valid")
			_expect(
				(StringName(receipt["command"]) in [
					StageFlow.COMMAND_BEGIN_BOSS_WARNING,
					StageFlow.COMMAND_COMPLETE_WITHOUT_BOSS,
				])
					== (defeat == flow.quota - 1),
				"the stage completion command starts on exact quota"
			)
		if has_boss:
			_expect(
				StringName(flow.advance(1.5)["command"]) == StageFlow.COMMAND_ENTER_BOSS,
				"warning resolves after 1.5 seconds"
			)
			_expect(flow.boss_entry_ready(), "boss entry requires the exact defeat quota")
			_expect(
				StringName(flow.record_boss_defeat()["command"])
					== StageFlow.COMMAND_COMPLETE_AFTER_BOSS,
				"active boss defeat completes the stage"
			)
		else:
			_expect(flow.state == StageFlow.State.COMPLETE, "odd stage completes without a boss warning")
		_expect(flow.state == StageFlow.State.COMPLETE, "stage flow reaches complete without reward or transition states")


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
