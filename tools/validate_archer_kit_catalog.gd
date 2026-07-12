extends SceneTree

const KIT := preload("res://data/characters/archer_kit.tres")
const SPLIT_SHAFT := preload("res://data/cards/archer_split_shaft.tres")
const STORM_MARK := preload("res://data/cards/archer_storm_mark.tres")
const FIELD_BOW := preload("res://data/equipment/items/field_bow.tres")
const TWINSTRING_BOW := preload("res://data/equipment/items/twinstring_bow.tres")

const MASTERY_PATHS := {
	&"post_dash_quick_shot_startup_scale": "res://data/mastery/nodes/archer_quick_nock.tres",
	&"full_charge_extra_pierce": "res://data/mastery/nodes/archer_piercing_draw.tres",
	&"transfer_consumed_mark": "res://data/mastery/nodes/archer_shared_mark.tres",
	&"vault_air_control_restore": "res://data/mastery/nodes/archer_airborne_hunter.tres",
	&"rain_final_arrow_bonus": "res://data/mastery/nodes/archer_storm_pattern.tres",
	&"mark_consume_reduce_longest_skill": "res://data/mastery/nodes/archer_clean_release.tres",
}

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_kit()
	_validate_cards()
	_validate_progression_resources()
	_finish()


func _validate_kit() -> void:
	_expect(KIT is CharacterKit, "Archer kit should load as CharacterKit")
	if not KIT is CharacterKit:
		return
	var kit := KIT as CharacterKit
	_expect(kit.validate_definition().is_empty(), "Archer kit should pass typed validation")
	_expect(kit.id == &"archer_kit", "Archer kit ID should be canonical")
	_expect(kit.profile_id == &"archer", "Archer kit should target the Archer profile")
	_expect(kit.passive_id == &"archer_hunters_mark", "Archer passive ID should be canonical")
	_expect(kit.runtime_script.new() is ArcherCombatRuntime, "Archer kit should own ArcherCombatRuntime")

	var quick := kit.basic_attack
	_expect(quick.id == &"archer_quick_shot", "Quick Shot should be the basic attack")
	_expect(_timing_is(quick, 0.09, 0.0, 0.21, 0.30), "Quick Shot timing should be 0.09/projectile/0.21")
	_expect(quick.base_damage == 1, "Quick Shot should deal 1 base damage")
	_expect(is_equal_approx(quick.projectile_speed, 640.0), "Quick Shot speed should be 640")
	_expect(is_equal_approx(quick.projectile_range, 800.0), "Quick Shot range should be 800")

	var power := kit.heavy_attack
	_expect(power.id == &"archer_power_shot", "Power Shot should be the heavy attack")
	_expect(_timing_is(power, 0.28, 0.01, 0.32, 1.10), "Power Shot should use the authored release cycle")
	_expect(power.charge_time_range.is_equal_approx(Vector2(0.28, 0.80)), "Power Shot charge should be 0.28-0.80")
	_expect(power.base_damage == 2 and power.maximum_charge_damage == 4, "Power Shot should interpolate from 2 to 4 damage")
	_expect(power.cooldown_from_release, "Power Shot cooldown should start on release")
	_expect(power.projectile_target_cap == 2, "Power Shot should pierce two targets by default")
	_expect(power.critical_rule != null, "Power Shot should declare its earned critical")
	if power.critical_rule != null:
		_expect(
			power.critical_rule.required_context_flags == [&"full_charge", &"target_hunters_mark"],
			"Power Shot critical should require full charge and Hunter's Mark"
		)
		_expect(is_equal_approx(power.critical_rule.multiplier, 1.5), "Power Shot critical should use 1.5x")

	var vault := kit.get_skill_by_slot(1)
	_expect(vault != null and vault.id == &"archer_vault_shot", "Skill 1 should be Vault Shot")
	if vault != null:
		_expect(_timing_is(vault, 0.12, 0.30, 0.20, 5.0), "Vault Shot timing should match the design")
		_expect(is_equal_approx(vault.movement_distance, 120.0), "Vault Shot hop should be 120 pixels")
		_expect(vault.projectile_count == 3, "Vault Shot should fire three arrows")
		_expect(vault.projectile_angles == PackedFloat32Array([-10.0, 0.0, 10.0]), "Vault Shot fan should be -10/0/+10 degrees")
		_expect(is_equal_approx(vault.projectile_speed, 620.0), "Vault arrows should travel at 620")
		_expect(is_equal_approx(vault.projectile_range, 420.0), "Vault arrows should travel 420 pixels")

	var rain := kit.get_skill_by_slot(2)
	_expect(rain != null and rain.id == &"archer_rain_field", "Skill 2 should be Rain Field")
	if rain != null:
		_expect(_timing_is(rain, 0.30, 1.20, 0.30, 9.0), "Rain Field timing should match the design")
		_expect(rain.projectile_count == 6, "Rain Field should schedule six strikes")
		_expect(is_equal_approx(rain.warning_time, 0.45), "Rain Field warning should last 0.45 seconds")
		_expect(is_equal_approx(rain.effect_radius, 110.0), "Rain Field diameter should be 220 pixels")
		_expect(rain.per_target_hit_cap == 3, "Rain Field should cap each target at three hits")

	var threadline := kit.get_skill_by_slot(3)
	_expect(threadline != null and threadline.id == &"archer_threadline", "Skill 3 should be Threadline")
	if threadline != null:
		_expect(_timing_is(threadline, 0.22, 0.35, 0.34, 12.0), "Threadline timing should match the design")
		_expect(is_equal_approx(threadline.targeting_range, 420.0), "Threadline range should be 420 pixels")
		_expect(is_equal_approx(threadline.pull_distance, 160.0), "Threadline pull should be 160 pixels")


func _validate_cards() -> void:
	_expect(SPLIT_SHAFT.validate_definition().is_empty(), "Split Shaft should pass typed validation")
	_expect(SPLIT_SHAFT.id == &"archer_split_shaft", "Split Shaft ID should be canonical")
	_expect(SPLIT_SHAFT.rarity == &"rare" and SPLIT_SHAFT.max_stacks == 1, "Split Shaft should be a one-stack rare")
	_expect(SPLIT_SHAFT.trigger == &"archer_power_shot_terminated", "Split Shaft should use the Power Shot termination trigger")
	var split := SPLIT_SHAFT.effects[0]
	_expect(split.effect_type == &"split_projectile", "Split Shaft should use the typed split effect")
	_expect(split.damage == 1 and split.projectile_count == 2, "Split Shaft should create two 1-damage arrows")
	_expect(is_equal_approx(split.angle_degrees, 18.0) and not split.proc_effects, "Split arrows should be +/-18 degrees and nonrecursive")

	_expect(STORM_MARK.validate_definition().is_empty(), "Storm Mark should pass typed validation")
	_expect(STORM_MARK.id == &"archer_storm_mark", "Storm Mark ID should be canonical")
	_expect(STORM_MARK.rarity == &"legendary" and STORM_MARK.max_stacks == 1, "Storm Mark should be a one-stack legendary")
	_expect(STORM_MARK.trigger == &"archer_mark_consumed", "Storm Mark should use the mark-consumed trigger")
	var delayed := STORM_MARK.effects[0]
	_expect(delayed.effect_type == &"delayed_target_strike", "Storm Mark should use the typed delayed-strike effect")
	_expect(delayed.damage == 2 and is_equal_approx(delayed.delay, 0.35), "Storm Mark should deal 2 damage after 0.35 seconds")
	_expect(not delayed.proc_effects, "Storm Mark should be nonrecursive")


func _validate_progression_resources() -> void:
	for effect_type in MASTERY_PATHS:
		var node := load(MASTERY_PATHS[effect_type]) as MasteryNodeDefinition
		_expect(node != null, "Archer mastery for %s should load" % effect_type)
		if node == null:
			continue
		_expect(node.validate_definition().is_empty(), "Archer mastery '%s' should validate" % node.id)
		_expect(node.behavior_effects.size() == 1, "Archer mastery '%s' should own one behavior" % node.id)
		if not node.behavior_effects.is_empty():
			_expect(node.behavior_effects[0].effect_type == effect_type, "Archer mastery '%s' should expose %s" % [node.id, effect_type])

	_expect(FIELD_BOW.validate_definition().is_empty(), "Field Bow should remain a valid baseline weapon")
	_expect(FIELD_BOW.behavior_effects.is_empty(), "Field Bow should not alter the baseline Archer kit")
	_expect(TWINSTRING_BOW.validate_definition().is_empty(), "Twinstring Bow should pass typed validation")
	_expect(TWINSTRING_BOW.behavior_effects.size() == 2, "Twinstring Bow should own repeat and maximum-damage behaviors")
	if TWINSTRING_BOW.behavior_effects.size() == 2:
		var repeat := TWINSTRING_BOW.behavior_effects[0]
		var penalty := TWINSTRING_BOW.behavior_effects[1]
		_expect(repeat.effect_type == &"quick_shot_repeat", "Twinstring should repeat Quick Shot")
		_expect(is_equal_approx(repeat.delay, 0.16) and is_equal_approx(repeat.damage_scale, 0.5), "Twinstring repeat should be delayed 0.16 seconds at 50 percent")
		_expect(penalty.effect_type == &"power_shot_max_damage" and penalty.damage_delta == -1, "Twinstring should reduce maximum Power Shot damage by one")


func _timing_is(
	definition: AttackDefinition,
	startup: float,
	active: float,
	recovery: float,
	cooldown: float
) -> bool:
	return (
		is_equal_approx(definition.startup_time, startup)
		and is_equal_approx(definition.active_time, active)
		and is_equal_approx(definition.recovery_time, recovery)
		and is_equal_approx(definition.cooldown, cooldown)
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ARCHER_KIT_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
