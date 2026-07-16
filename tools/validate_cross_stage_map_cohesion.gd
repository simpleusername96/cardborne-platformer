extends SceneTree

const ENEMY_CATALOG: EnemyCatalog = preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG: HazardCatalog = preload("res://data/hazards/hazard_catalog.tres")
const FIXED_LAYOUT_SEED := 0x43415244
const FIXED_LAYOUT_VERSION := 6
const STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"profile": "res://data/generation/ruin_approach_profile.tres",
		"catalog": "res://data/generation/lower_ruins_room_catalog.tres",
		"required_rooms": 8,
		"optional_rooms": 1,
		"waveform": &"broken_ascent",
	},
	{
		"id": &"flooded_works",
		"profile": "res://data/generation/flooded_works_profile.tres",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
		"required_rooms": 7,
		"optional_rooms": 1,
		"waveform": &"basin_then_pump",
	},
	{
		"id": &"broken_sanctum",
		"profile": "res://data/generation/broken_sanctum_profile.tres",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
		"required_rooms": 9,
		"optional_rooms": 2,
		"waveform": &"distributed_reversal",
	},
]
const CHARGER_SCENES := [
	"res://scenes/enemies/ChargerRuin.tscn",
	"res://scenes/enemies/ChargerFlooded.tscn",
	"res://scenes/enemies/ChargerSanctum.tscn",
]

var _failures: Array[String] = []
var _stage_rows: Array[Dictionary] = []
var _terrain_relation_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(run_state != null, "Cross-stage cohesion validation needs RunState.")
	if run_state == null:
		_finish()
		return

	for stage_index in STAGES.size():
		await _validate_stage(stage_index, STAGES[stage_index], run_state)
	await _validate_local_charger_cues()
	_validate_completion_copy_boundary()
	_validate_distinct_stage_signatures()
	_finish()


func _validate_stage(
	stage_index: int,
	config: Dictionary,
	run_state: Node
) -> void:
	var profile := load(String(config["profile"])) as StageProfile
	var catalog := load(String(config["catalog"])) as RoomCatalog
	_expect(profile != null and catalog != null, "%s data should load." % config["id"])
	if profile == null or catalog == null:
		return
	var generation := StageGenerationService.new().generate_curated(
		catalog,
		profile,
		ENEMY_CATALOG,
		HAZARD_CATALOG,
		run_state.get("reward_catalog") as RewardCatalog,
		FIXED_LAYOUT_SEED,
		FIXED_LAYOUT_VERSION,
		stage_index,
		run_state.call("get_required_route_limits") as Dictionary
	)
	_expect(generation.success and generation.plan != null, "%s should generate." % config["id"])
	if not generation.success or generation.plan == null:
		return

	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(generation.plan, catalog, rooms_root)
	_expect(assembly.success, "%s should assemble." % config["id"])
	if not assembly.success:
		rooms_root.queue_free()
		await process_frame
		return

	var metrics := StageCompositionMetrics.analyze(
		generation.plan,
		assembly,
		run_state.call("get_required_route_limits") as Dictionary
	)
	_expect(
		int(metrics.get("required_room_count", 0)) == int(config["required_rooms"]),
		"%s should retain its required-room count." % config["id"]
	)
	_expect(
		int(metrics.get("optional_branch_count", 0)) == int(config["optional_rooms"]),
		"%s should retain its optional-route count." % config["id"]
	)
	_expect(
		int(metrics.get("max_near_limit_chain", -1)) == 0,
		"%s should not regain a near-limit traversal chain." % config["id"]
	)
	_expect(
		int(metrics.get("same_hub_return_count", -1)) == 0,
		"%s should not regain a same-hub optional return." % config["id"]
	)

	var hosts := assembly.get_room_hosts()
	var active_anchor_ids: Dictionary = {}
	for encounter in generation.plan.get_encounters():
		var room_key := String(encounter.room_id)
		var room_anchors: Array = active_anchor_ids.get(room_key, [])
		if not room_anchors.has(encounter.anchor_id):
			room_anchors.append(encounter.anchor_id)
		active_anchor_ids[room_key] = room_anchors
	for planned_room in generation.plan.get_rooms():
		var host := hosts.get(String(planned_room.id)) as RoomTemplateHost
		_expect(host != null, "%s room %s should have a host." % [config["id"], planned_room.id])
		if host == null:
			continue
		_validate_room_boundary(
			config["id"],
			planned_room,
			host,
			active_anchor_ids.get(String(planned_room.id), []) as Array
		)

	_stage_rows.append({
		"id": String(config["id"]),
		"waveform": String(config["waveform"]),
		"range": float(metrics.get("critical_route_vertical_range", 0.0)),
		"ascent": float(metrics.get("cumulative_ascent", 0.0)),
		"descent": float(metrics.get("cumulative_descent", 0.0)),
		"reversals": int(metrics.get("direction_reversals", 0)),
		"optional": int(metrics.get("optional_branch_count", 0)),
	})
	rooms_root.queue_free()
	await process_frame


func _validate_room_boundary(
	stage_id: StringName,
	planned_room: PlannedRoom,
	host: RoomTemplateHost,
	active_anchor_ids: Array
) -> void:
	_expect(
		host.find_children("*", "ForgeStationInteractable", true, false).is_empty(),
		"%s/%s must remain Forge-free." % [stage_id, planned_room.id]
	)
	_expect(
		host.find_children("*", "MerchantInteractable", true, false).is_empty(),
		"%s/%s must remain Merchant-free." % [stage_id, planned_room.id]
	)
	for node in host.find_children("*", "", true, false):
		_expect(
			not node.has_meta("camera_id"),
			"%s/%s should use proven default-camera geometry, not dead camera metadata."
			% [stage_id, planned_room.id]
		)

	var enemy_anchors: Array[RoomAnchor] = []
	for anchor_id in active_anchor_ids:
		var anchor := host.get_anchor_by_id(&"Enemy", StringName(anchor_id))
		if anchor != null:
			enemy_anchors.append(anchor)
	if enemy_anchors.is_empty():
		return
	var recoveries := host.get_typed_anchors(&"Recovery")
	_expect(
		not recoveries.is_empty(),
		"%s/%s combat needs an authored recovery anchor." % [stage_id, planned_room.id]
	)
	var entry_recovery := false
	for recovery in recoveries:
		entry_recovery = entry_recovery or recovery.position.x <= 240.0
	_expect(
		entry_recovery,
		"%s/%s combat needs a recovery point inside its 240 px entry buffer."
		% [stage_id, planned_room.id]
	)
	for anchor in enemy_anchors:
		var relation := StringName(anchor.get_meta("terrain_relation", &""))
		_expect(
			not String(relation).is_empty(),
			"%s/%s enemy anchor %s needs a terrain relation."
			% [stage_id, planned_room.id, anchor.anchor_id]
		)
		_expect(
			anchor.position.x >= 240.0,
			"%s/%s enemy anchor %s violates the entry threat buffer."
			% [stage_id, planned_room.id, anchor.anchor_id]
		)
		if not String(relation).is_empty():
			_terrain_relation_count += 1


func _validate_local_charger_cues() -> void:
	for scene_path in CHARGER_SCENES:
		var packed := load(scene_path) as PackedScene
		var charger: Variant = packed.instantiate() if packed != null else null
		_expect(charger != null, "%s should instantiate." % scene_path)
		if charger == null:
			continue
		root.add_child(charger)
		await process_frame
		var warning := charger.get_node_or_null("LaneWarning") as Line2D
		_expect(
			warning != null
			and warning.points.size() == 2
			and warning.points[1].length() <= 128.0 + 0.1,
			"%s should use a local Charger direction cue." % scene_path
		)
		charger.queue_free()
		await process_frame


func _validate_completion_copy_boundary() -> void:
	var hud_source := FileAccess.get_file_as_string(
		"res://scripts/ui/production/ProductionHUD.gd"
	)
	_expect(not hud_source.is_empty(), "ProductionHUD source should load.")
	_expect(
		not hud_source.contains("get_remaining_enemy_count"),
		"ProductionHUD must not regain the global required-enemy tally."
	)
	_expect(
		not hud_source.contains("Defeat %") and not hud_source.contains("remaining enemies"),
		"ProductionHUD must not regain global kill-gate copy."
	)


func _validate_distinct_stage_signatures() -> void:
	_expect(_stage_rows.size() == STAGES.size(), "All three stage signatures should resolve.")
	if _stage_rows.size() != STAGES.size():
		return
	var signature_keys: Dictionary = {}
	for row in _stage_rows:
		var key := "%s:%d:%d:%d" % [
			row["waveform"],
			roundi(float(row["range"])),
			int(row["reversals"]),
			int(row["optional"]),
		]
		signature_keys[key] = true
		match String(row["id"]):
			"ruin_approach":
				_expect(
					float(row["ascent"]) > float(row["descent"]),
					"Ruin should retain an ascent-led broken waveform."
				)
			"flooded_works":
				_expect(
					float(row["descent"]) > float(row["ascent"]),
					"Flooded should retain a basin-first waveform."
				)
			"broken_sanctum":
				_expect(
					int(row["reversals"]) >= 4 and int(row["optional"]) == 2,
					"Sanctum should retain distributed reversals and two optional routes."
				)
	_expect(
		signature_keys.size() == STAGES.size(),
		"The three fixed stages should keep distinct silhouette signatures."
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"CROSS_STAGE_MAP_COHESION_OK stages=3 terrain_relations=%d local_warnings=true facilities=separated"
			% _terrain_relation_count
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
