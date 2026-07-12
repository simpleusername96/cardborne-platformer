extends SceneTree

const KIT := preload("res://data/characters/assassin_kit.tres")
const AFTERIMAGE := preload("res://data/cards/assassin_afterimage.tres")
const RED_SEQUENCE := preload("res://data/cards/assassin_red_sequence.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const HOOKED_BLADES := preload("res://data/equipment/items/hooked_blades.tres")
const RUST_KNIVES := preload("res://data/equipment/items/rust_knives.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_kit()
	_validate_cards()
	_validate_progression_contracts()
	_validate_snapshot_contract()
	_finish()


func _validate_kit() -> void:
	_expect(KIT.validate_definition().is_empty(), "Assassin kit should validate")
	_expect(KIT.id == &"assassin_kit", "Assassin kit ID should be canonical")
	_expect(KIT.runtime_script != null, "Assassin kit should declare its runtime")
	_expect(KIT.passive_id == &"assassin_flow", "Assassin kit should declare Flow")
	_expect(_is_timing(KIT.basic_attack, 0.07, 0.30, 0.12, 0.49), "Twin Cut should use the exact 0.49 second chain")
	_expect(KIT.basic_attack.sequence_requires_hold, "Twin Cut should require hold for step two")
	_expect(KIT.basic_attack.sequence_step_timings == [
		Vector3(0.07, 0.07, 0.08),
		Vector3(0.08, 0.07, 0.12),
	], "Twin Cut should preserve both authored substeps")
	_expect(_is_timing(KIT.heavy_attack, 0.24, 0.20, 0.34, 0.90), "Shadow Lunge should use exact timing")
	_expect(KIT.heavy_attack.base_damage == 3, "Shadow Lunge should deal 3 base damage")
	_expect(
		KIT.heavy_attack.critical_rule != null
		and KIT.heavy_attack.critical_rule.required_context_flags.has(&"target_rear_arc")
		and is_equal_approx(KIT.heavy_attack.critical_rule.multiplier, 1.5),
		"Shadow Lunge should use the earned rear-arc critical"
	)

	var smoke := KIT.get_skill_by_slot(1)
	var kunai := KIT.get_skill_by_slot(2)
	var death_mark := KIT.get_skill_by_slot(3)
	_expect(smoke != null and _is_timing(smoke, 0.08, 0.18, 0.18, 5.0), "Smoke Step should use exact timing")
	_expect(
		smoke != null
		and smoke.execution_mode == SkillDefinition.EXECUTION_DECOY_STEP
		and is_equal_approx(smoke.movement_distance, 120.0)
		and is_equal_approx(smoke.invulnerability_time, 0.18)
		and is_equal_approx(smoke.decoy_duration, 0.8),
		"Smoke Step should declare movement, invulnerability, and decoy data"
	)
	_expect(kunai != null and _is_timing(kunai, 0.18, 0.01, 0.25, 7.0), "Kunai Fan should use exact timing")
	_expect(
		kunai != null
		and kunai.projectile_count == 5
		and kunai.projectile_angles == PackedFloat32Array([-24, -12, 0, 12, 24])
		and is_equal_approx(kunai.projectile_speed, 560.0)
		and is_equal_approx(kunai.projectile_range, 360.0)
		and kunai.per_target_hit_cap == 3,
		"Kunai Fan should declare its exact five-projectile contract"
	)
	_expect(death_mark != null and _is_timing(death_mark, 0.24, 0.0, 0.28, 13.0), "Death Mark should use exact timing")
	_expect(
		death_mark != null
		and death_mark.execution_mode == SkillDefinition.EXECUTION_TARGET_MARK
		and is_equal_approx(death_mark.targeting_range, 320.0)
		and is_equal_approx(death_mark.status_duration, 5.0)
		and death_mark.required_distinct_verbs == 3,
		"Death Mark should declare range, duration, and three distinct verbs"
	)


func _validate_cards() -> void:
	for card in [AFTERIMAGE, RED_SEQUENCE]:
		_expect(card.validate_definition().is_empty(), "Assassin card '%s' should validate" % card.id)
		_expect(card.compatibility == [&"assassin"], "Assassin card '%s' should be character-specific" % card.id)
		_expect(card.max_stacks == 1, "Assassin card '%s' should cap at one" % card.id)
	_expect(AFTERIMAGE.rarity == &"rare", "Afterimage should be rare")
	_expect(AFTERIMAGE.trigger == &"assassin_shadow_lunge_completed", "Afterimage should use the clean-lunge trigger")
	_expect(
		AFTERIMAGE.effects.size() == 1
		and AFTERIMAGE.effects[0].effect_type == &"repeat_attack_path"
		and is_equal_approx(AFTERIMAGE.effects[0].damage_scale, 0.5)
		and not AFTERIMAGE.effects[0].proc_effects,
		"Afterimage should repeat path damage at 50 percent without recursion"
	)
	_expect(RED_SEQUENCE.rarity == &"legendary", "Red Sequence should be legendary")
	_expect(RED_SEQUENCE.trigger == &"assassin_flow_consumed", "Red Sequence should use the Flow-consumed trigger")
	_expect(
		RED_SEQUENCE.effects.size() == 1
		and RED_SEQUENCE.effects[0].effect_type == &"detonation_mark"
		and RED_SEQUENCE.effects[0].damage == 3
		and is_equal_approx(RED_SEQUENCE.effects[0].duration, 4.0)
		and is_equal_approx(RED_SEQUENCE.effects[0].distance, 90.0)
		and RED_SEQUENCE.effects[0].required_distinct_verbs == 1,
		"Red Sequence should declare its exact one-verb detonation mark"
	)


func _validate_progression_contracts() -> void:
	var expected_mastery := {
		&"assassin_serrated_second": &"twin_cut_second_bleed",
		&"assassin_slipstream": &"lunge_kill_refund_dash",
		&"assassin_lingering_smoke": &"smoke_duration",
		&"assassin_fan_return": &"kunai_return_count",
		&"assassin_opportunist": &"back_hit_flow_stack",
		&"assassin_perfect_exit": &"no_damage_death_mark_resets_smoke_step",
	}
	for node_id in expected_mastery:
		var node := MASTERY_CATALOG.get_node(node_id)
		_expect(node != null, "Assassin mastery '%s' should exist" % node_id)
		if node != null:
			var effect_types := PlayerProgressionEffectQuery.effect_types(node.behavior_effects)
			_expect(effect_types.has(expected_mastery[node_id]), "Assassin mastery '%s' should expose its runtime effect" % node_id)
	_expect(RUST_KNIVES.behavior_effects.is_empty(), "Rust Knives should preserve the baseline kit")
	_expect(
		PlayerProgressionEffectQuery.first(HOOKED_BLADES.behavior_effects, &"twin_cut_second_bleed") != null
		and PlayerProgressionEffectQuery.first(HOOKED_BLADES.behavior_effects, &"shadow_lunge_distance") != null,
		"Hooked Blades should expose bleed and lunge-distance behavior"
	)


func _validate_snapshot_contract() -> void:
	var runtime := KIT.runtime_script.new() as AssassinCombatRuntime
	_expect(runtime != null, "Assassin runtime should instantiate")
	if runtime == null:
		return
	var snapshot := runtime.get_state_snapshot()
	for key in [
		"flow_stacks",
		"flow_time",
		"death_mark_count",
		"red_sequence_mark_count",
		"decoy_time",
		"slipstream_cooldown",
	]:
		_expect(snapshot.has(key), "Assassin snapshot should include '%s'" % key)
		_expect(snapshot.get(key) is int or snapshot.get(key) is float, "Assassin snapshot '%s' should be numeric" % key)


func _is_timing(
	definition: AttackDefinition,
	startup: float,
	active: float,
	recovery: float,
	cooldown: float
) -> bool:
	return (
		definition != null
		and is_equal_approx(definition.startup_time, startup)
		and is_equal_approx(definition.active_time, active)
		and is_equal_approx(definition.recovery_time, recovery)
		and is_equal_approx(definition.cooldown, cooldown)
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ASSASSIN_KIT_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
