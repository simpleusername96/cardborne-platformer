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
		"target_ready": true,
	},
	{
		"id": &"flooded_works",
		"profile": "res://data/generation/flooded_works_profile.tres",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
		"target_ready": true,
	},
	{
		"id": &"broken_sanctum",
		"profile": "res://data/generation/broken_sanctum_profile.tres",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
	},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(run_state != null, "RunState autoload should exist.")
	if run_state == null:
		_finish()
		return
	for stage_index in STAGES.size():
		_validate_stage(stage_index, STAGES[stage_index], run_state)
	_finish()


func _validate_stage(stage_index: int, config: Dictionary, run_state: Node) -> void:
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
	_expect(generation.success and generation.plan != null, "%s plan should generate." % config["id"])
	if not generation.success or generation.plan == null:
		if generation.report != null:
			for failure in generation.report.get_failures() + generation.report.get_attempt_failures():
				_failures.append("%s: %s" % [config["id"], failure.get("message", failure)])
		return
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(generation.plan, catalog, rooms_root)
	_expect(assembly.success, "%s plan should assemble." % config["id"])
	if assembly.success:
		var geometry_errors := StageGeometryValidator.validate_assembly(
			generation.plan,
			catalog,
			assembly,
			run_state.call("get_required_route_limits") as Dictionary
		)
		_expect(
			geometry_errors.is_empty(),
			"%s geometry should validate: %s" % [config["id"], "; ".join(geometry_errors)]
		)
		var metrics := StageCompositionMetrics.analyze(
			generation.plan,
			assembly,
			run_state.call("get_required_route_limits") as Dictionary
		)
		print("STAGE_COMPOSITION_METRICS %s %s" % [config["id"], JSON.stringify(metrics)])
		for error in StageCompositionMetrics.validate_fixed_stage(generation.plan, assembly):
			_failures.append(error)
		if bool(config.get("target_ready", false)):
			for error in StageCompositionMetrics.validate_target_structure(
				generation.plan,
				assembly
			):
				_failures.append(error)
	rooms_root.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_COMPOSITION_VALIDATION_OK stages=3")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
