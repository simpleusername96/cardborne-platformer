extends SceneTree

const EffectDefinitionScript = preload("res://scripts/player/EffectDefinition.gd")
const PlayerBuildScript = preload("res://scripts/player/PlayerBuild.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_operation_order()
	_validate_stack_selection()
	_validate_build_limits()
	_validate_unsupported_effects()
	_validate_source_breakdown()
	_validate_determinism()
	_validate_input_immutability()

	if _failures.is_empty():
		print("PLAYER_BUILD_VALIDATION_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_operation_order() -> void:
	var base_stats := {"attack_damage": 10}
	var add_effect := _effect("attack_damage", "add", 5.0, "mastery.blade_training")
	var multiply_effect := _effect("attack_damage", "multiply", 2.0, "equipment.iron_blade")
	var ordered_snapshot = PlayerBuildScript.resolve(base_stats, [multiply_effect, add_effect])
	_expect_close(ordered_snapshot.get_stat(&"attack_damage"), 30.0, "operations within one source scope must use canonical order")

	var mastery_multiplier := _effect(
		"attack_damage", "multiply", 2.0, "mastery.force", "stack", "", 0, "mastery"
	)
	var equipment_bonus := _effect(
		"attack_damage", "add", 5.0, "equipment.tempered_blade", "stack", "", 0, "equipment"
	)
	var source_order_snapshot = PlayerBuildScript.resolve(
		base_stats,
		[equipment_bonus, mastery_multiplier]
	)
	_expect_close(
		source_order_snapshot.get_stat(&"attack_damage"),
		25.0,
		"mastery must resolve before equipment regardless of operation"
	)

	var low_override := _effect("attack_damage", "override", 35.0, "card.old_form", "stack", "", 10)
	var high_override := _effect("attack_damage", "override", 42.0, "temporary.boss_blessing", "stack", "", 20)
	var override_snapshot = PlayerBuildScript.resolve(
		base_stats,
		[high_override, multiply_effect, low_override, add_effect]
	)
	_expect_close(override_snapshot.get_stat(&"attack_damage"), 42.0, "highest-priority override must apply last")


func _validate_stack_selection() -> void:
	var old_boots := _effect("move_speed", "add", 10.0, "equipment.old_boots", "replace", "boots_speed", 10)
	var forged_boots := _effect("move_speed", "add", 25.0, "temporary.forged_boots", "replace", "boots_speed", 20)
	var replacement_snapshot = PlayerBuildScript.resolve(
		{"move_speed": 100.0},
		[forged_boots, old_boots]
	)
	_expect_close(replacement_snapshot.get_stat(&"move_speed"), 125.0, "replacement stack must keep the highest-priority effect")
	_expect(
		replacement_snapshot.get_source_effects(&"equipment.old_boots").is_empty(),
		"replaced build source must not appear as applied"
	)

	var vitality := _effect("max_health", "add", 2.0, "card.vitality", "unique", "vitality")
	var duplicate_snapshot = PlayerBuildScript.resolve({"max_health": 5}, [vitality, vitality])
	_expect_close(duplicate_snapshot.get_stat(&"max_health"), 7.0, "unique stack must deduplicate repeated source effects")

	var stronger_vitality := _effect(
		"max_health", "add", 3.0, "temporary.vitality", "unique", "vitality", 1, "temporary"
	)
	var distinct_source_snapshot = PlayerBuildScript.resolve(
		{"max_health": 5},
		[vitality, stronger_vitality]
	)
	_expect_close(
		distinct_source_snapshot.get_stat(&"max_health"),
		8.0,
		"unique stack key must remain unique across different sources"
	)

	var conflicting_policy := _effect(
		"move_speed", "add", 20.0, "card.conflict", "highest", "boots_speed"
	)
	var conflict_snapshot = PlayerBuildScript.resolve(
		{"move_speed": 100.0},
		[old_boots, conflicting_policy]
	)
	_expect(
		_validation_error_codes(conflict_snapshot.get_validation_errors()).has("conflicting_effect_stack_policy"),
		"mixed policies for one stack key must fail validation"
	)
	_expect_close(conflict_snapshot.get_stat(&"move_speed"), 100.0, "conflicting stack group must not apply")


func _validate_build_limits() -> void:
	var snapshot = PlayerBuildScript.resolve(
		{"max_health": 5, "attack_cooldown": 0.3, "move_speed": 100.0},
		[
			_effect("max_health", "override", 5000.0, "temporary.unbounded_health"),
			_effect("attack_cooldown", "multiply", 0.0, "card.instant_attack"),
			_effect("move_speed", "add", -1000.0, "equipment.rooted_armor"),
		]
	)
	_expect_close(snapshot.get_stat(&"max_health"), 999.0, "max health must respect its build limit")
	_expect_close(snapshot.get_stat(&"attack_cooldown"), 0.05, "attack cooldown must respect its build limit")
	_expect_close(snapshot.get_stat(&"move_speed"), 1.0, "move speed must respect its build limit")
	_expect(not snapshot.get_source_effects(&"build_limits").is_empty(), "build limit adjustments must be visible in source breakdown")


func _validate_unsupported_effects() -> void:
	var unsupported_stat := _effect("critical_chance", "add", 1.0, "card.unsupported_stat")
	var unsupported_operation := _effect("attack_damage", "subtract", 1.0, "card.unsupported_operation")
	var non_finite := _effect("attack_damage", "add", INF, "card.non_finite")
	var unsupported_scope := _effect(
		"attack_damage", "add", 1.0, "card.unsupported_scope", "stack", "", 0, "unknown"
	)
	var snapshot = PlayerBuildScript.resolve(
		{"attack_damage": 10},
		[non_finite, unsupported_operation, unsupported_scope, unsupported_stat]
	)
	var codes := _validation_error_codes(snapshot.get_validation_errors())
	_expect(not snapshot.is_valid(), "unsupported effects must invalidate the player build snapshot")
	_expect(codes.has("unsupported_effect_player_stat"), "unsupported player stat error must be reported")
	_expect(codes.has("unsupported_effect_operation"), "unsupported operation error must be reported")
	_expect(codes.has("non_finite_effect_value"), "non-finite effect value error must be reported")
	_expect(codes.has("unsupported_effect_source_scope"), "unsupported source scope error must be reported")
	_expect_close(snapshot.get_stat(&"attack_damage"), 10.0, "invalid effects must not change resolved stats")


func _validate_source_breakdown() -> void:
	var snapshot = PlayerBuildScript.resolve(
		{"attack_damage": 10},
		[_effect("attack_damage", "add", 2.0, "card.sharpened_edge")]
	)
	var effects := snapshot.get_source_effects(&"card.sharpened_edge")
	_expect(effects.size() == 1, "applied effect source must have one breakdown record")
	if effects.size() == 1:
		_expect(effects[0]["stat_id"] == "attack_damage", "source breakdown must name the player stat")
		_expect_close(float(effects[0]["before"]), 10.0, "source breakdown must record the prior value")
		_expect_close(float(effects[0]["after"]), 12.0, "source breakdown must record the resolved value")
	_expect(snapshot.get_source_breakdown().has("base_character"), "source breakdown must include base character stats")


func _validate_determinism() -> void:
	var effects := [
		_effect("attack_damage", "multiply", 1.5, "card.force"),
		_effect("attack_damage", "add", 3.0, "mastery.weapon_training"),
		_effect("move_speed", "add", 20.0, "equipment.trail_boots"),
		_effect("move_speed", "add", 10.0, "temporary.old_boots", "replace", "boots_speed", 1),
		_effect("move_speed", "add", 30.0, "temporary.new_boots", "replace", "boots_speed", 2),
	]
	var reversed_effects := effects.duplicate()
	reversed_effects.reverse()
	var first = PlayerBuildScript.resolve({"attack_damage": 8, "move_speed": 200.0}, effects)
	var second = PlayerBuildScript.resolve({"move_speed": 200.0, "attack_damage": 8}, reversed_effects)
	_expect(first.get_values() == second.get_values(), "effect and base dictionary order must not change resolved values")
	_expect(first.get_source_breakdown() == second.get_source_breakdown(), "effect order must not change source breakdown")
	_expect(first.get_validation_errors() == second.get_validation_errors(), "effect order must not change validation errors")


func _validate_input_immutability() -> void:
	var base_stats := {"attack_damage": 10, "move_speed": 200.0}
	var effect := _effect("attack_damage", "add", 4.0, "card.immutable_input")
	var effects := [effect]
	var base_before := base_stats.duplicate(true)
	var effect_before := {
		"stat_id": effect.stat_id,
		"operation": effect.operation,
		"value": effect.value,
		"stacking": effect.stacking,
		"stack_key": effect.stack_key,
		"source_id": effect.source_id,
		"source_scope": effect.source_scope,
		"priority": effect.priority,
	}
	var snapshot = PlayerBuildScript.resolve(base_stats, effects)
	_expect(base_stats == base_before, "player build resolver must not mutate base stats")
	_expect(effects.size() == 1 and effects[0] == effect, "player build resolver must not mutate the effects array")
	_expect(_effect_fields(effect) == effect_before, "player build resolver must not mutate effect resources")

	var values_copy := snapshot.get_values()
	values_copy["attack_damage"] = 999.0
	_expect_close(snapshot.get_stat(&"attack_damage"), 14.0, "snapshot values must be isolated from callers")
	var breakdown_copy := snapshot.get_source_breakdown()
	breakdown_copy.clear()
	_expect(not snapshot.get_source_breakdown().is_empty(), "snapshot source breakdown must be isolated from callers")


func _effect(
	stat_id: String,
	operation: String,
	value: float,
	source_id: String,
	stacking: String = "stack",
	stack_key: String = "",
	priority: int = 0,
	source_scope: String = "card"
) -> EffectDefinition:
	var effect := EffectDefinitionScript.new()
	effect.stat_id = StringName(stat_id)
	effect.operation = operation
	effect.value = value
	effect.stacking = stacking
	effect.stack_key = StringName(stack_key)
	effect.source_id = StringName(source_id)
	effect.source_scope = source_scope
	effect.priority = priority
	return effect


func _effect_fields(effect: EffectDefinition) -> Dictionary:
	return {
		"stat_id": effect.stat_id,
		"operation": effect.operation,
		"value": effect.value,
		"stacking": effect.stacking,
		"stack_key": effect.stack_key,
		"source_id": effect.source_id,
		"source_scope": effect.source_scope,
		"priority": effect.priority,
	}


func _validation_error_codes(errors: Array) -> Array[String]:
	var codes: Array[String] = []
	for error in errors:
		codes.append(str(error.get("code", "")))
	return codes


func _expect_close(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures.append("%s; expected %s, got %s." % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
