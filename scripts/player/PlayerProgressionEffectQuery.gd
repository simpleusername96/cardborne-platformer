class_name PlayerProgressionEffectQuery
extends RefCounted


static func matching(
	effects: Array,
	effect_type: StringName,
	target_id: StringName = &""
) -> Array[ProgressionBehaviorEffect]:
	var matches: Array[ProgressionBehaviorEffect] = []
	for value in effects:
		var effect := value as ProgressionBehaviorEffect
		if effect == null or effect.effect_type != effect_type:
			continue
		if not target_id.is_empty() and effect.target_id != target_id:
			continue
		matches.append(effect)
	return matches


static func first(
	effects: Array,
	effect_type: StringName,
	target_id: StringName = &""
) -> ProgressionBehaviorEffect:
	var matches := matching(effects, effect_type, target_id)
	return matches[0] if not matches.is_empty() else null


static func has(effects: Array, effect_type: StringName) -> bool:
	return first(effects, effect_type) != null


static func attack_modifiers(effects: Array, attack_id: StringName) -> Dictionary:
	var modifiers: Dictionary = {}
	for effect in matching(effects, &"modify_attack", attack_id):
		_add(modifiers, "direct_damage_additive", effect.damage)
		_add(modifiers, "stagger_additive", effect.stagger)
		_add(modifiers, "recovery_time_additive", effect.recovery)
	return modifiers


static func first_card_reroll_discount(effects: Array) -> int:
	var total := 0.0
	for effect in matching(effects, &"reduce_first_card_reroll_cost"):
		total += effect.value
	return maxi(int(floor(total + 0.5)), 0)


static func first_post_double_jump_stagger(effects: Array) -> int:
	var total := 0
	for effect in matching(effects, &"first_post_double_jump_attack_stagger"):
		total += effect.stagger
	return maxi(total, 0)


static func effect_types(effects: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in effects:
		var effect := value as ProgressionBehaviorEffect
		if effect != null and not result.has(effect.effect_type):
			result.append(effect.effect_type)
	return result


static func _add(destination: Dictionary, key: String, amount: float) -> void:
	destination[key] = float(destination.get(key, 0.0)) + amount
