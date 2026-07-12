extends SceneTree

const WARRIOR_KIT_PATH := "res://data/characters/warrior_kit.tres"

var _failures: Array[String] = []


func _initialize() -> void:
	var kit := load(WARRIOR_KIT_PATH) as CharacterKit
	_expect(kit != null, "warrior combat kit should load")
	if kit != null:
		_validate_kit(kit)
		_validate_damage_resolution(kit)
	_validate_context_critical(&"archer_fixture", ["full_charge", "target_hunters_mark"])
	_validate_context_critical(&"assassin_fixture", ["target_rear_arc"])
	_finish()


func _validate_kit(kit: CharacterKit) -> void:
	_expect(kit.validate_definition().is_empty(), "warrior combat kit should validate")
	var cleave := kit.basic_attack
	var breaker := kit.heavy_attack
	var shield_rush := kit.get_skill_by_slot(1)
	_expect(cleave != null and cleave.id == &"warrior_cleave", "warrior basic should be cleave")
	_expect(breaker != null and breaker.id == &"warrior_breaker", "warrior heavy should be breaker")
	_expect(shield_rush != null and shield_rush.id == &"warrior_shield_rush", "warrior skill 1 should be shield rush")
	if shield_rush != null:
		_expect(shield_rush.frontal_guard_during_active, "shield rush should guard its front")
		_expect(is_equal_approx(shield_rush.movement_distance, 180.0), "shield rush should travel 180 px")


func _validate_damage_resolution(kit: CharacterKit) -> void:
	var cleave_result := DamageResolver.resolve_attack(kit.basic_attack)
	_expect(cleave_result.is_valid(), "cleave result should be valid")
	_expect(cleave_result.final_damage == 2, "cleave should deal 2 damage")
	_expect(cleave_result.stagger == 20, "cleave should deal 20 stagger")
	_expect(not cleave_result.critical, "cleave should not critical")

	var normal_breaker := DamageResolver.resolve_attack(kit.heavy_attack, {"staggered": false})
	var critical_breaker := DamageResolver.resolve_attack(kit.heavy_attack, {"staggered": true})
	var repeat_breaker := DamageResolver.resolve_attack(kit.heavy_attack, {"staggered": true})
	_expect(normal_breaker.final_damage == 4, "breaker should deal 4 normal damage")
	_expect(not normal_breaker.critical, "breaker should need stagger for critical")
	_expect(critical_breaker.final_damage == 6, "staggered breaker should deal 6 damage")
	_expect(critical_breaker.critical, "staggered breaker should be critical")
	_expect(
		_result_fingerprint(critical_breaker) == _result_fingerprint(repeat_breaker),
		"identical critical contexts should resolve identically"
	)

	var secondary_breaker := DamageResolver.resolve_attack(
		kit.heavy_attack,
		{"staggered": true},
		{"secondary_hit": true}
	)
	_expect(not secondary_breaker.critical, "secondary hits should not critical by default")
	_expect(secondary_breaker.final_damage == 4, "secondary breaker should retain base damage")


func _validate_context_critical(rule_id: StringName, required_flags: Array[String]) -> void:
	var rule := CriticalRule.new()
	rule.id = rule_id
	for flag in required_flags:
		rule.required_context_flags.append(StringName(flag))
	var attack := AttackDefinition.new()
	attack.id = StringName("%s_attack" % rule_id)
	attack.display_name = "Critical fixture"
	attack.tags = [&"player_attack"]
	attack.base_damage = 4
	attack.critical_rule = rule
	var context: Dictionary = {}
	for flag in required_flags:
		context[flag] = true
	var result := DamageResolver.resolve_attack(attack, {}, context)
	_expect(result.critical and result.final_damage == 6, "%s should earn its critical" % rule_id)
	var secondary := DamageResolver.resolve_attack(attack, {}, context.merged({"secondary_hit": true}, true))
	_expect(not secondary.critical, "%s secondary hit should not critical" % rule_id)


func _result_fingerprint(result: HitResult) -> PackedByteArray:
	return var_to_bytes({
		"damage": result.final_damage,
		"critical": result.critical,
		"stagger": result.stagger,
		"knockback": result.knockback,
		"tags": result.tags,
		"errors": result.validation_errors,
	})


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("COMBAT_FOUNDATION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
