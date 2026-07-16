extends SceneTree

const ENEMY_CATALOG: EnemyCatalog = preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG: HazardCatalog = preload("res://data/hazards/hazard_catalog.tres")
const VISUAL_CATALOG: StageVisualCatalog = preload(
	"res://data/presentation/stage_visual_catalog.tres"
)
const MAXIMUM_VIEWPORT := Vector2i(1920, 1080)
const FIXED_LAYOUT_SEED := 0x43415244
const FIXED_LAYOUT_VERSION := 6
const REPORT_PATH := "res://.codex-runtime/reports/stage_visual_coverage.json"
const GENERATED_STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"profile": "res://data/generation/ruin_approach_profile.tres",
		"catalog": "res://data/generation/lower_ruins_room_catalog.tres",
	},
	{
		"id": &"flooded_works",
		"profile": "res://data/generation/flooded_works_profile.tres",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
	},
	{
		"id": &"broken_sanctum",
		"profile": "res://data/generation/broken_sanctum_profile.tres",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
	},
]
const FIXED_STAGES: Array[Dictionary] = [
	{
		"id": &"arsenal_trial",
		"scene": "res://scenes/stages/trial/ArsenalTrial.tscn",
		"bounds_method": &"get_layout_bounds",
	},
	{
		"id": &"safe_intermission",
		"scene": "res://scenes/stages/intermission/SafeIntermission.tscn",
		"bounds_method": &"get_world_bounds",
	},
	{
		"id": &"slime_court",
		"scene": "res://scenes/stages/boss/SlimeCourt.tscn",
		"bounds_method": &"get_world_bounds",
	},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var report := {
		"schema_version": 1,
		"viewport_envelope": _vector2i_data(MAXIMUM_VIEWPORT),
		"stages": [],
		"total_initial_panel_count": 0,
		"total_initial_rgba_bytes": 0,
		"loading_policy": "current_location_only",
	}
	for error in VISUAL_CATALOG.validation_errors():
		_failures.append(error)

	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null:
		_failures.append("RunState autoload is required to measure curated stage bounds.")
	else:
		for stage_index in GENERATED_STAGES.size():
			var config := GENERATED_STAGES[stage_index]
			var bounds := _measure_generated_bounds(stage_index, config, run_state)
			_append_stage_measurement(report, config["id"], bounds, "curated_runtime_assembly")

	for config in FIXED_STAGES:
		var bounds := _measure_fixed_bounds(config)
		_append_stage_measurement(report, config["id"], bounds, "authored_scene_contract")

	var stages: Array = report["stages"]
	for stage_data in stages:
		report["total_initial_panel_count"] += int(stage_data["minimum_panel_count"])
		report["total_initial_rgba_bytes"] += int(stage_data["estimated_rgba_bytes"])
	report["total_initial_rgba_mib"] = _bytes_to_mib(report["total_initial_rgba_bytes"])

	if int(report["total_initial_panel_count"]) != 11:
		_failures.append(
			"Measured initial manifest should contain 11 panels, got %d."
			% int(report["total_initial_panel_count"])
		)
	_write_report(report)
	print("STAGE_VISUAL_COVERAGE %s" % JSON.stringify(report))
	_finish()


func _measure_generated_bounds(stage_index: int, config: Dictionary, run_state: Node) -> Rect2:
	var profile := load(String(config["profile"])) as StageProfile
	var catalog := load(String(config["catalog"])) as RoomCatalog
	if profile == null or catalog == null:
		_failures.append("%s generation data did not load." % config["id"])
		return Rect2()
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
	if not generation.success or generation.plan == null:
		_failures.append("%s curated plan did not generate." % config["id"])
		return Rect2()
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(generation.plan, catalog, rooms_root)
	var bounds := assembly.world_bounds if assembly.success else Rect2()
	if not assembly.success:
		_failures.append("%s curated plan did not assemble." % config["id"])
	rooms_root.queue_free()
	return bounds


func _measure_fixed_bounds(config: Dictionary) -> Rect2:
	var packed := load(String(config["scene"])) as PackedScene
	if packed == null:
		_failures.append("%s fixed scene did not load." % config["id"])
		return Rect2()
	var instance := packed.instantiate()
	var method_name := StringName(config["bounds_method"])
	var bounds := Rect2()
	if not instance.has_method(method_name):
		_failures.append("%s has no %s bounds method." % [config["id"], method_name])
	else:
		bounds = instance.call(method_name) as Rect2
	instance.free()
	return bounds


func _append_stage_measurement(
	report: Dictionary,
	stage_id: StringName,
	world_bounds: Rect2,
	bounds_source: String
) -> void:
	var definition := VISUAL_CATALOG.get_definition(stage_id)
	if definition == null:
		_failures.append("No stage visual definition exists for %s." % stage_id)
		return
	if world_bounds.size.x <= 0.0 or world_bounds.size.y <= 0.0:
		_failures.append("%s produced invalid world bounds %s." % [stage_id, world_bounds])
		return
	var panel_count := definition.minimum_panel_count(world_bounds, MAXIMUM_VIEWPORT)
	if panel_count <= 0:
		_failures.append("%s panel contract cannot cover the measured stage." % stage_id)
		return
	var required := definition.required_coverage(world_bounds, MAXIMUM_VIEWPORT)
	var composite := definition.composite_size(panel_count)
	if composite.x < ceili(required.x) or composite.y < ceili(required.y):
		_failures.append("%s composite does not satisfy measured coverage." % stage_id)
	var stage_data := {
		"id": String(stage_id),
		"bounds_source": bounds_source,
		"world_bounds": _rect2_data(world_bounds),
		"mode": String(definition.mode),
		"panel_size": _vector2i_data(definition.panel_size),
		"panel_ratio": snappedf(
			float(definition.panel_size.x) / float(definition.panel_size.y), 0.0001
		),
		"panel_overlap": definition.panel_overlap,
		"scroll_scale": _vector2_data(definition.scroll_scale),
		"overscan": _vector2i_data(definition.overscan),
		"required_composite_size": _vector2_data(required),
		"minimum_panel_count": panel_count,
		"composite_size": _vector2i_data(composite),
		"estimated_rgba_bytes": definition.estimated_rgba_bytes(panel_count),
		"estimated_rgba_mib": _bytes_to_mib(definition.estimated_rgba_bytes(panel_count)),
		"authored_panel_count": definition.panel_paths.size(),
		"procedural_fallback": definition.procedural_fallback,
		"proof_room_id": String(definition.proof_room_id),
		"proof_status": String(definition.proof_status),
	}
	(report["stages"] as Array).append(stage_data)


func _write_report(report: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("Could not write %s." % REPORT_PATH)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")


func _rect2_data(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}


func _vector2_data(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _vector2i_data(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _bytes_to_mib(value: int) -> float:
	return snappedf(float(value) / 1048576.0, 0.01)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_VISUAL_COVERAGE_OK stages=6 panels=11")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
