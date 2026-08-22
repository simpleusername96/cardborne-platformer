extends SceneTree

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const Runtime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_catalog()
	_validate_shield_owners()
	_validate_source_boundaries()
	_finish()


func _validate_catalog() -> void:
	_expect(Catalog.validate_contract().is_empty(), "twelve boss phase definitions satisfy the authored contract")
	var variants := {}
	for stage_id in CombatStages.STAGE_IDS:
		var variant := Catalog.variant(stage_id)
		_expect(not variant.is_empty(), "%s owns a boss variant" % stage_id)
		_expect(not variants.has(variant), "%s boss variant is unique" % stage_id)
		variants[variant] = true
		for phase in [1, 2, 3]:
			var roles := Catalog.squad_roles(stage_id, phase)
			_expect(
				not roles.is_empty() and roles.size() <= Catalog.MAX_LIVE_ADDS,
				"%s phase %d periodic squad stays bounded" % [stage_id, phase]
			)
	_expect(variants.size() == 12, "all twelve cycles own distinct boss identities")
	_expect(
		Catalog.BOSS_ENTRY_SLOT_RESERVE == 1 + Catalog.MAX_LIVE_ADDS,
		"boss entry reserves only the boss body and bounded add budget"
	)


func _validate_shield_owners() -> void:
	for stage_index in CombatStages.STAGE_IDS.size():
		var stage_id := CombatStages.STAGE_IDS[stage_index]
		var runtime := Runtime.new()
		runtime.configure(stage_id)
		var payload := runtime.begin_phase(1)
		var uses_shield := Catalog.uses_shield(stage_id)
		_expect(
			runtime.state() == (&"shield_up" if uses_shield else &"none"),
			"%s exposes shield state only when its defense is authored" % stage_id
		)
		if not uses_shield:
			_expect(
				is_equal_approx(runtime.boss_damage_multiplier(), 1.0),
				"%s has no defensive stall window" % stage_id
			)
			continue
		_expect(
			is_equal_approx(runtime.boss_damage_multiplier(), 1.0)
				and not payload.has("modules"),
			"%s starts with boss-attached directional defense while non-directional damage bypasses it" % stage_id
		)
		if stage_id == &"stage_3":
			_validate_segmented_shield_direction(runtime)
	var shield_owners := CombatStages.STAGE_IDS.filter(Catalog.uses_shield)
	_expect(shield_owners == [&"stage_3"], "only Stage 3 boss owns a restrained directional defense")


func _validate_segmented_shield_direction(runtime) -> void:
	var facing := Vector2.RIGHT
	var gap_direction := Vector2.RIGHT.rotated(Runtime.SHIELD_GAP_ARC * 0.5)
	var segment_direction := Vector2.RIGHT.rotated(
		Runtime.SHIELD_GAP_ARC + Runtime.SHIELD_SEGMENT_ARC * 0.5
	)
	_expect(
		is_equal_approx(runtime.boss_damage_multiplier(gap_direction, facing, 100.0), 1.0)
			and is_equal_approx(runtime.boss_damage_multiplier(segment_direction, facing, 100.0), Runtime.BLOCKED_DAMAGE_MULTIPLIER),
		"stage 3 boss exposes each authored gap and reduces segment hits to fifteen percent"
	)
	runtime.advance(Runtime.SHIELD_UP_SECONDS)
	_expect(
		runtime.state() == &"shield_down"
			and is_equal_approx(runtime.boss_damage_multiplier(segment_direction, facing, 10.0), 1.0),
		"stage 3 boss becomes fully exposed after eight protected seconds"
	)
	runtime.advance(Runtime.SHIELD_DOWN_SECONDS)
	_expect(runtime.state() == &"shield_up", "stage 3 boss restores its segmented shield after two exposed seconds")
	_expect(runtime.consume_counterburst_multiplier() > 1.0, "Stage 3 boss blocked damage charges its next counterburst")
	_expect(StringName(runtime.presentation_snapshot()["shield_kind"]) == &"frontal_intercept", "Stage 3 boss publishes its exact renderer-facing defense kind")


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
	_expect(not runtime_source.contains("for enemy in enemies"), "boss shield runtime never scans the enemy store")
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("boss_shield_runtime.boss_damage_multiplier")
			and run_source.contains("_spawn_boss_phase_adds")
			and run_source.contains("boss_runtime.advance_squad")
			and not run_source.contains("var payload := boss_shield_runtime.begin_phase")
			and not run_source.contains("boss_pylon")
			and not run_source.contains("boss_objective"),
		"production boss flow consumes one boss-attached defense and periodic squads without phase-spawn objectives"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_SHIELDS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
