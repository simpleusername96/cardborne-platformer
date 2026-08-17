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
	_expect(Catalog.validate_contract().is_empty(), "eight boss phase definitions satisfy the authored contract")
	var variants := {}
	for stage_id in CombatStages.STAGE_IDS:
		var variant := Catalog.variant(stage_id)
		_expect(not variant.is_empty(), "%s owns a boss variant" % stage_id)
		_expect(not variants.has(variant), "%s boss variant is unique" % stage_id)
		variants[variant] = true
		for phase in [2, 3]:
			_expect(
				Catalog.add_roles(stage_id, phase).size() <= Catalog.MAX_LIVE_ADDS,
				"%s phase %d add packet stays at or below twelve" % [stage_id, phase]
			)
	_expect(variants.size() == 8, "all eight cycles own distinct boss identities")
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
			_validate_drydock_direction(runtime)
	var shield_owners := CombatStages.STAGE_IDS.filter(Catalog.uses_shield)
	_expect(shield_owners == [&"stage_3"], "only Drydock owns a restrained directional defense")


func _validate_drydock_direction(runtime) -> void:
	var facing := Vector2.RIGHT
	_expect(
		is_equal_approx(runtime.boss_damage_multiplier(Vector2.RIGHT, facing, 100.0), Runtime.BLOCKED_DAMAGE_MULTIPLIER)
			and is_equal_approx(runtime.boss_damage_multiplier(Vector2.LEFT, facing, 100.0), 1.0),
		"Drydock intercepts only its body-facing frontal arc"
	)
	var edge := Vector2.RIGHT.rotated(Runtime.DRYDOCK_FRONTAL_HALF_ANGLE)
	var outside := Vector2.RIGHT.rotated(Runtime.DRYDOCK_FRONTAL_HALF_ANGLE + 0.01)
	_expect(
		is_equal_approx(runtime.boss_damage_multiplier(edge, facing, 10.0), Runtime.BLOCKED_DAMAGE_MULTIPLIER)
			and is_equal_approx(runtime.boss_damage_multiplier(outside, facing, 10.0), 1.0),
		"Drydock frontal edge is inclusive and the rear side stays exposed"
	)
	_expect(runtime.consume_counterburst_multiplier() > 1.0, "Drydock blocked damage charges its next counterburst")
	_expect(StringName(runtime.presentation_snapshot()["shield_kind"]) == &"frontal_intercept", "Drydock publishes its exact renderer-facing defense kind")


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
	_expect(not runtime_source.contains("for enemy in enemies"), "boss shield runtime never scans the enemy store")
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("boss_shield_runtime.boss_damage_multiplier")
			and run_source.contains("_spawn_boss_phase_adds")
			and not run_source.contains("boss_pylon")
			and not run_source.contains("boss_objective"),
		"production boss flow consumes one boss-attached defense without objective actors"
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
