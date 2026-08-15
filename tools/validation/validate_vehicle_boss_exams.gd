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
				not runtime.lower_after_direct_attack()
					and is_equal_approx(runtime.boss_damage_multiplier(), 1.0),
				"%s has no defensive stall window" % stage_id
			)
			continue
		_expect(
			runtime.boss_damage_multiplier()
				== StageDifficulty.boss_shielded_damage_multiplier(stage_index)
				and not payload.has("modules"),
			"%s starts with its boss-attached defense and no external objective" % stage_id
		)
		_expect(runtime.lower_after_direct_attack(), "%s direct attack lowers the shield" % stage_id)
		_expect(
			runtime.state() == &"shield_down"
				and is_equal_approx(runtime.shield_down_remaining, Runtime.SHIELD_DOWN_SECONDS),
			"%s opens one bounded focus-fire window" % stage_id
		)
		runtime.advance(Runtime.SHIELD_DOWN_SECONDS + 0.01)
		_expect(runtime.state() == &"shield_up", "%s shield returns after its bounded window" % stage_id)
	var shield_owners := CombatStages.STAGE_IDS.filter(Catalog.uses_shield)
	_expect(shield_owners == [&"stage_3", &"stage_5"], "only Drydock and Crown own defenses")


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
