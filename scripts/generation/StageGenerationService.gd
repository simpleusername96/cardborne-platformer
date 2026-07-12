class_name StageGenerationService
extends RefCounted

const MAX_RANDOM_ATTEMPTS := 3


func generate(
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog,
	run_seed: int,
	stage_index: int,
	movement_limits: Dictionary,
	random_attempt_limit: int = MAX_RANDOM_ATTEMPTS
) -> StageGenerationResult:
	var preflight_errors := _preflight(
		room_catalog,
		profile,
		enemy_catalog,
		hazard_catalog,
		reward_catalog,
		movement_limits,
		random_attempt_limit
	)
	if not preflight_errors.is_empty():
		var failed_report := _new_report(
			room_catalog,
			profile,
			run_seed,
			stage_index,
			0
		)
		failed_report.record_validation_errors(preflight_errors)
		return StageGenerationResult.new(false, null, failed_report)

	var attempt_failures: Array[Dictionary] = []
	for attempt in random_attempt_limit:
		var planner := StagePlanner.new()
		var topology := planner.build_plan(
			room_catalog,
			profile,
			run_seed,
			stage_index,
			movement_limits,
			attempt
		)
		if topology == null:
			_append_planner_failures(attempt_failures, attempt, planner.last_report)
			continue
		var completed := _allocate_and_validate(
			topology,
			room_catalog,
			profile,
			enemy_catalog,
			hazard_catalog,
			reward_catalog,
			movement_limits,
			attempt_failures
		)
		if completed == null:
			continue
		var report := _new_report(
			room_catalog,
			profile,
			run_seed,
			stage_index,
			attempt
		)
		_copy_attempt_failures(report, attempt_failures)
		_copy_planner_decisions(report, planner.last_report)
		report.record_decision(&"accepted_plan", {
			"attempt": attempt,
			"room_count": completed.get_rooms().size(),
			"encounter_count": completed.get_encounters().size(),
			"hazard_count": completed.get_hazards().size(),
			"reward_count": completed.get_rewards().size(),
		})
		return StageGenerationResult.new(true, completed, report)

	var fallback_builder := CuratedStagePlanBuilder.new()
	var fallback_topology := fallback_builder.build_ruin_approach(
		room_catalog,
		profile,
		run_seed,
		stage_index,
		movement_limits
	)
	var fallback_attempt := CuratedStagePlanBuilder.FALLBACK_ATTEMPT
	if fallback_topology == null:
		for error in fallback_builder.last_errors:
			attempt_failures.append({
				"attempt": fallback_attempt,
				"code": "fallback_topology",
				"message": error,
			})
	else:
		var fallback_plan := _allocate_and_validate(
			fallback_topology,
			room_catalog,
			profile,
			enemy_catalog,
			hazard_catalog,
			reward_catalog,
			movement_limits,
			attempt_failures
		)
		if fallback_plan != null:
			var fallback_report := _new_report(
				room_catalog,
				profile,
				run_seed,
				stage_index,
				fallback_attempt
			)
			_copy_attempt_failures(fallback_report, attempt_failures)
			fallback_report.mark_fallback(profile.fallback_id)
			fallback_report.record_decision(&"accepted_fallback", {
				"fallback_id": String(profile.fallback_id),
				"room_count": fallback_plan.get_rooms().size(),
			})
			return StageGenerationResult.new(true, fallback_plan, fallback_report)

	var report := _new_report(
		room_catalog,
		profile,
		run_seed,
		stage_index,
		fallback_attempt
	)
	_copy_attempt_failures(report, attempt_failures)
	report.record_failure(&"generation_exhausted", "Random attempts and curated fallback failed.")
	return StageGenerationResult.new(false, null, report)


func _allocate_and_validate(
	topology: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog,
	movement_limits: Dictionary,
	attempt_failures: Array[Dictionary]
) -> StagePlan:
	var attempt := topology.generation_attempt
	var encounter_allocator := StageEncounterAllocator.new()
	var combat_plan := encounter_allocator.allocate(
		topology,
		room_catalog,
		profile,
		enemy_catalog
	)
	if combat_plan == null:
		_append_errors(attempt_failures, attempt, &"encounter_allocation", encounter_allocator.last_errors)
		return null
	var content_allocator := StageContentAllocator.new()
	var complete_plan := content_allocator.allocate(
		combat_plan,
		room_catalog,
		profile,
		hazard_catalog,
		reward_catalog
	)
	if complete_plan == null:
		_append_errors(attempt_failures, attempt, &"content_allocation", content_allocator.last_errors)
		return null
	var validation_errors := StagePlanValidator.validate_complete(
		complete_plan,
		room_catalog,
		profile,
		movement_limits,
		enemy_catalog,
		hazard_catalog,
		reward_catalog
	)
	if not validation_errors.is_empty():
		_append_errors(attempt_failures, attempt, &"complete_validation", validation_errors)
		return null
	return complete_plan


func _preflight(
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog,
	movement_limits: Dictionary,
	random_attempt_limit: int
) -> PackedStringArray:
	var errors := PackedStringArray()
	if room_catalog == null or profile == null or enemy_catalog == null:
		errors.append("Stage generation needs room, profile, and enemy catalogs.")
	if hazard_catalog == null or reward_catalog == null:
		errors.append("Stage generation needs hazard and reward catalogs.")
	if random_attempt_limit < 0 or random_attempt_limit > MAX_RANDOM_ATTEMPTS:
		errors.append("Random attempt limit must be between 0 and %d." % MAX_RANDOM_ATTEMPTS)
	for error in RoomSocketCompatibility.validate_movement_limits(movement_limits):
		errors.append("Movement limits: %s" % error)
	return errors


func _new_report(
	room_catalog: RoomCatalog,
	profile: StageProfile,
	run_seed: int,
	stage_index: int,
	attempt: int
) -> GenerationReport:
	var catalog_version := room_catalog.content_version if room_catalog != null else 0
	var profile_version := profile.content_version if profile != null else 0
	var streams := NamedRngStreams.new(
		run_seed,
		stage_index,
		catalog_version,
		profile_version,
		attempt
	)
	return GenerationReport.new(
		run_seed,
		stage_index,
		profile.id if profile != null else &"",
		profile_version,
		room_catalog.id if room_catalog != null else &"",
		catalog_version,
		streams.get_stream_seeds(),
		attempt
	)


func _append_planner_failures(
	target: Array[Dictionary],
	attempt: int,
	report: GenerationReport
) -> void:
	if report == null:
		target.append({"attempt": attempt, "code": "planner", "message": "Planner returned no report."})
		return
	for failure in report.get_failures():
		target.append({
			"attempt": attempt,
			"code": str(failure.get("code", "planner")),
			"message": str(failure.get("message", "Planner failed.")),
		})


func _append_errors(
	target: Array[Dictionary],
	attempt: int,
	code: StringName,
	errors: PackedStringArray
) -> void:
	for error in errors:
		target.append({"attempt": attempt, "code": String(code), "message": error})


func _copy_attempt_failures(report: GenerationReport, failures: Array[Dictionary]) -> void:
	for failure in failures:
		report.record_attempt_failure(
			int(failure["attempt"]),
			StringName(failure["code"]),
			str(failure["message"])
		)


func _copy_planner_decisions(report: GenerationReport, planner_report: GenerationReport) -> void:
	if planner_report == null:
		return
	for decision in planner_report.get_decisions():
		report.record_decision(
			StringName("planner_%s" % decision.get("code", "decision")),
			decision.get("details", {})
		)
