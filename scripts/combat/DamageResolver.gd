class_name DamageResolver
extends RefCounted

const DEFAULT_CRITICAL_MULTIPLIER := 1.5
const MAXIMUM_CRITICAL_MULTIPLIER := 2.0


static func resolve_attack(
	attack: AttackDefinition,
	target_state: Dictionary = {},
	hit_context: Dictionary = {},
	source_modifiers: Dictionary = {}
) -> HitResult:
	var errors := PackedStringArray()
	if attack == null:
		errors.append("Damage resolution needs an attack definition.")
		return HitResult.new(0, false, 0, Vector2.ZERO, [], errors)

	var base_damage := float(attack.base_damage)
	var additive := float(source_modifiers.get("direct_damage_additive", 0.0))
	var multiplier := float(source_modifiers.get("direct_damage_multiplier", 1.0))
	var mitigation := float(target_state.get("mitigation", 0.0))
	if not is_finite(base_damage + additive + multiplier + mitigation) or multiplier < 0.0:
		errors.append("Damage resolution received invalid numeric modifiers.")
		return HitResult.new(0, false, 0, attack.knockback, _string_tags(attack.tags), errors)

	var critical := false
	var critical_multiplier := 1.0
	var critical_eligible := (
		attack.tags.has(&"player_attack")
		and not bool(hit_context.get("secondary_hit", false))
		and not bool(hit_context.get("source_is_enemy", false))
		and not bool(hit_context.get("source_is_hazard", false))
	)
	if (
		critical_eligible
		and attack.critical_rule != null
		and attack.critical_rule.is_satisfied(target_state, hit_context)
	):
		critical = true
		critical_multiplier = clampf(
			attack.critical_rule.multiplier,
			DEFAULT_CRITICAL_MULTIPLIER,
			MAXIMUM_CRITICAL_MULTIPLIER
		)

	var resolved := maxf((base_damage + additive) * multiplier, 0.0)
	resolved *= critical_multiplier
	resolved = maxf(resolved - mitigation, 0.0)
	var final_damage := maxi(int(floor(resolved + 0.5)), 0)
	var tags := _string_tags(attack.tags)
	if critical and not tags.has("critical"):
		tags.append("critical")
	return HitResult.new(final_damage, critical, attack.stagger, attack.knockback, tags, errors)


static func _string_tags(source: Array[StringName]) -> Array[String]:
	var tags: Array[String] = []
	for tag in source:
		tags.append(String(tag))
	return tags
