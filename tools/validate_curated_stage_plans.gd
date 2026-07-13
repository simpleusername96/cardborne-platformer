extends SceneTree

const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const FIXED_LAYOUT_VERSION := 1
const FIXED_LAYOUT_SEED_V1 := 0x43415244
const RUN_SEEDS := [1103, 73102]
const STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"catalog": "res://data/generation/lower_ruins_room_catalog.tres",
		"rooms": "lr_start_shelf,lr_rise_steps,lr_patrol_gallery,lr_lower_upper_choice,lr_charge_lane,lr_exit_ascent,lr_destructible_cache",
	},
	{
		"id": &"flooded_works",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
		"rooms": "fw_flooded_entry,fw_rope_shaft,fw_poison_timing,fw_leaper_basin,fw_lower_upper_choice,fw_pump_gallery,fw_rest_forge,fw_sunken_cache",
	},
	{
		"id": &"broken_sanctum",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
		"rooms": "bs_breach_entry,bs_shield_choke,bs_gate_switch_loop,bs_volatile_nave,bs_twin_reliquary_choice,bs_recovery_cloister,bs_sentry_crossfire,bs_exit_ascent,bs_material_crypt,bs_reliquary_cache",
	},
]

var _failures: Array[String] = []
var _production_stage: PackedScene


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_production_stage = load(PRODUCTION_STAGE_PATH) as PackedScene
	_expect(_production_stage != null, "Production stage scene should load.")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(run_state != null, "RunState autoload should exist.")
	if run_state == null or _production_stage == null:
		_finish()
		return
	for stage_index in STAGES.size():
		await _validate_stage(stage_index, STAGES[stage_index], run_state)
	_finish()


func _validate_stage(stage_index: int, config: Dictionary, run_state: Node) -> void:
	var baseline_plan := ""
	var baseline_signature := ""
	for run_seed in RUN_SEEDS:
		_expect(
			bool(run_state.call("start_new_run", 0, run_seed)),
			"Run seed %d should initialize." % run_seed
		)
		run_state.set("current_stage_index", stage_index)
		var stage := _production_stage.instantiate()
		root.add_child(stage)
		await process_frame
		await process_frame
		var setup_complete := (
			stage.has_method("is_setup_complete")
			and bool(stage.call("is_setup_complete"))
		)
		_expect(
			setup_complete,
			"%s should assemble for run seed %d." % [config["id"], run_seed]
		)
		if setup_complete:
			var plan := stage.call("get_stage_plan") as StagePlan
			var report := stage.call("get_generation_report") as GenerationReport
			var details := _decision_details(report, &"accepted_curated_plan")
			_expect(plan != null and report != null, "%s should retain plan evidence." % config["id"])
			_expect(not report.fallback_used, "%s should use explicit curated mode." % config["id"])
			_expect(plan.run_seed == FIXED_LAYOUT_SEED_V1, "%s should use the fixed layout seed." % config["id"])
			_expect(
				plan.generation_attempt == CuratedStagePlanBuilder.CURATED_ATTEMPT,
				"%s should retain the curated attempt identity." % config["id"]
			)
			_expect(String(details.get("mode", "")) == "curated_fixed", "%s report mode is incorrect." % config["id"])
			_expect(int(details.get("layout_version", 0)) == FIXED_LAYOUT_VERSION, "%s layout version is incorrect." % config["id"])
			_expect(int(details.get("layout_seed", 0)) == FIXED_LAYOUT_SEED_V1, "%s report seed is incorrect." % config["id"])
			_expect(String(details.get("room_signature", "")) == String(config["rooms"]), "%s room signature changed." % config["id"])
			var plan_json := plan.to_json()
			var plan_signature := String(details.get("plan_signature", ""))
			_expect(plan_signature == plan_json.sha256_text(), "%s plan signature should cover complete map content." % config["id"])
			if baseline_plan.is_empty():
				baseline_plan = plan_json
				baseline_signature = plan_signature
				_validate_geometry_fixture(plan, config, run_state)
			else:
				_expect(plan_json == baseline_plan, "%s map content changed with run seed." % config["id"])
				_expect(plan_signature == baseline_signature, "%s signature changed with run seed." % config["id"])
		stage.queue_free()
		await process_frame
		await process_frame


func _validate_geometry_fixture(plan: StagePlan, config: Dictionary, run_state: Node) -> void:
	var catalog := load(String(config["catalog"])) as RoomCatalog
	_expect(catalog != null, "%s room catalog should load." % config["id"])
	if catalog == null:
		return
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(plan, catalog, rooms_root)
	_expect(assembly.success, "%s curated plan should assemble in isolation." % config["id"])
	if not assembly.success:
		rooms_root.queue_free()
		return
	var limits: Dictionary = run_state.call("get_required_route_limits")
	var errors := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
	_expect(errors.is_empty(), "%s curated geometry should validate: %s" % [config["id"], "; ".join(errors)])
	if config["id"] == &"broken_sanctum":
		var crypt := assembly.get_room_hosts().get("bs_material_crypt") as RoomTemplateHost
		var step := crypt.get_node_or_null("OneWay/BasinReturnStep") if crypt != null else null
		var rope := crypt.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable if crypt != null else null
		_expect(step != null, "Material Crypt should include its basin return step.")
		_expect(rope != null, "Material Crypt should include its return rope.")
		if rope != null:
			rope.position.x = 1040.0
			rope.set_meta("entry_support", &"material_crypt_return_shelf")
			rope.set_meta("exit_support", &"twin_choice_right_floor")
			var blocked := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
			_expect(
				_has_message(blocked, "terminates beneath solid terrain"),
				"The former rope shaft should fail the upper dismount contract."
			)
			rope.position.x = 240.0
			rope.set_meta("entry_support", &"material_crypt_entry_shelf")
			rope.set_meta("exit_support", &"twin_choice_lower_cover")
		if step != null:
			step.get_parent().remove_child(step)
			step.free()
			var invalid := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
			_expect(
				_has_message(invalid, "crypt_basin_recovery")
				and _has_message(invalid, "cannot reach the return rope"),
				"Removing the basin step should fail the committed-drop return contract."
			)
	rooms_root.queue_free()


func _decision_details(report: GenerationReport, code: StringName) -> Dictionary:
	if report == null:
		return {}
	for decision in report.get_decisions():
		if StringName(decision.get("code", &"")) == code:
			return (decision.get("details", {}) as Dictionary).duplicate(true)
	return {}


func _has_message(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CURATED_STAGE_PLAN_VALIDATION_OK stages=3 run_seeds=2")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
