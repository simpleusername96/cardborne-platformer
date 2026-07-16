extends SceneTree

const PRODUCTION_STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const FIXED_LAYOUT_VERSION := 6
const FIXED_LAYOUT_SEED_V1 := 0x43415244
const RUN_SEEDS := [1103, 73102]
const STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"catalog": "res://data/generation/lower_ruins_room_catalog.tres",
		"rooms": "lr_start_shelf,lr_rise_steps,lr_patrol_gallery,lr_shooter_overlook,lr_lower_upper_choice,lr_broken_bridge,lr_charge_lane,lr_exit_ascent,lr_destructible_cache",
		"signature": "c637d6c947eee98fa2095e5d97997b499ad234168ce910a81e6eb716d90cca85",
	},
	{
		"id": &"flooded_works",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
		"rooms": "fw_flooded_entry,fw_rope_shaft,fw_poison_timing,fw_leaper_basin,fw_lower_upper_choice,fw_pump_gallery,fw_exit_shelter,fw_sunken_cache",
		"signature": "61dfade8a9e7f56c9378c7f83088813aaff0c9f6f028b78db9e33937b97826c2",
	},
	{
		"id": &"broken_sanctum",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
		"rooms": "bs_breach_entry,bs_shield_choke,bs_gate_switch_loop,bs_volatile_nave,bs_twin_reliquary_choice,bs_fractured_gallery,bs_recovery_cloister,bs_sentry_crossfire,bs_exit_ascent,bs_material_crypt,bs_reliquary_cache",
		"signature": "a97929159621da6b87384b2827e789b1f84c41b6b93275cc357a6170eba96532",
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
			_expect(
				plan_signature == String(config["signature"]),
				"%s approved V6 plan signature mismatch: expected %s, got %s."
				% [config["id"], config["signature"], plan_signature]
			)
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
	var composition_errors := StageCompositionMetrics.validate_fixed_stage(plan, assembly)
	_expect(
		composition_errors.is_empty(),
		"%s curated composition should validate: %s"
		% [config["id"], "; ".join(composition_errors)]
	)
	if config["id"] == &"broken_sanctum":
		var crypt := assembly.get_room_hosts().get("bs_material_crypt") as RoomTemplateHost
		var nave := assembly.get_room_hosts().get("bs_volatile_nave") as RoomTemplateHost
		var reliquary := assembly.get_room_hosts().get("bs_reliquary_cache") as RoomTemplateHost
		var basin_rope := (
			crypt.get_node_or_null("Anchors/Objective/BasinReturnRope") as Climbable
			if crypt != null else null
		)
		var return_rope := (
			crypt.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable
			if crypt != null else null
		)
		var forward_hatch := (
			nave.get_node_or_null("Terrain/EntryMass") as StaticBody2D
			if nave != null else null
		)
		var sentry_drop_hatch := (
			reliquary.get_node_or_null("Terrain/EastCacheReturnMass") as StaticBody2D
			if reliquary != null else null
		)
		_expect(basin_rope != null, "Material Crypt should include its local basin rope.")
		_expect(return_rope != null, "Material Crypt should include its cross-room return rope.")
		_expect(forward_hatch != null, "Volatile Nave should include its crypt rejoin hatch.")
		_expect(sentry_drop_hatch != null, "Upper Reliquary Cache should include its sentry return hatch.")
		_expect(basin_rope != return_rope, "Local and cross-room return ropes must be separate nodes.")
		if basin_rope != null:
			var original_x := basin_rope.position.x
			basin_rope.position.x = 990.0
			var invalid_local := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
			_expect(
				_has_message(invalid_local, "local climbable 'BasinReturnRope'"),
				"Embedding the local rope in the return shelves should fail its route contract."
			)
			basin_rope.position.x = original_x
		if forward_hatch != null:
			var hatch_shape := forward_hatch.get_node_or_null("CollisionShape2D") as CollisionShape2D
			forward_hatch.set_meta("one_way", false)
			if hatch_shape != null:
				hatch_shape.one_way_collision = false
			var blocked_return := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
			_expect(
				_has_message(blocked_return, "terminates beneath solid terrain"),
				"A solid nave rejoin hatch should fail the cross-room dismount contract."
			)
			forward_hatch.set_meta("one_way", true)
			if hatch_shape != null:
				hatch_shape.one_way_collision = true
		if sentry_drop_hatch != null:
			var original_collision_layer := sentry_drop_hatch.collision_layer
			sentry_drop_hatch.collision_layer = 1
			var wrong_layer_drop := StageGeometryValidator.validate_assembly(
				plan, catalog, assembly, limits
			)
			_expect(
				_has_message(wrong_layer_drop, "drop return hatch uses the wrong collision layer"),
				"A drop hatch on the solid collision layer should fail validation."
			)
			sentry_drop_hatch.collision_layer = original_collision_layer
			sentry_drop_hatch.position.x -= 240.0
			var blocked_drop := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
			_expect(
				_has_message(blocked_drop, "drop return has no authored hatch"),
				"Moving the sentry-return hatch away should fail drop-route validation."
			)
			sentry_drop_hatch.position.x += 240.0
		var restored := StageGeometryValidator.validate_assembly(plan, catalog, assembly, limits)
		_expect(
			restored.is_empty(),
			"Broken Sanctum geometry should recover after invalid fixtures: %s"
			% "; ".join(restored)
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
