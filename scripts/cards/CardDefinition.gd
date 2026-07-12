class_name CardDefinition
extends Resource

const RARITIES: Array[StringName] = [&"common", &"rare", &"legendary"]
const SUPPORTED_TRIGGERS: Array[StringName] = [
	&"heavy_hit_confirmed",
	&"dash_completed",
	&"first_attack_after_extra_jump",
	&"hit_target_in_recovery",
	&"skill_kill",
	&"heavy_ground_impact",
	&"guard_consumed",
]

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var content_version: int = 1
@export var rarity: StringName = &"common"
@export var compatibility: Array[StringName] = [&"shared"]
@export var trigger: StringName
@export var effects: Array[CardEffectDefinition] = []
@export_range(1, 99, 1) var max_stacks: int = 1
@export_range(0.0, 60.0, 0.05) var internal_cooldown: float = 0.0


func is_compatible(profile_id: StringName) -> bool:
	return compatibility.has(&"shared") or compatibility.has(profile_id)


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Card ID", id)
	if display_name.strip_edges().is_empty() or description.strip_edges().is_empty():
		errors.append("Card '%s' needs a display name and mechanical description." % id)
	if content_version <= 0 or max_stacks <= 0:
		errors.append("Card '%s' has invalid version or stack cap." % id)
	if not RARITIES.has(rarity):
		errors.append("Card '%s' has invalid rarity '%s'." % [id, rarity])
	if not SUPPORTED_TRIGGERS.has(trigger):
		errors.append("Card '%s' has unsupported trigger '%s'." % [id, trigger])
	if not is_finite(internal_cooldown) or internal_cooldown < 0.0:
		errors.append("Card '%s' has an invalid internal cooldown." % id)
	ContentId.validate_list(errors, "Card '%s' compatibility" % id, compatibility, true)
	if effects.is_empty():
		errors.append("Card '%s' needs at least one effect." % id)
	for effect_index in effects.size():
		var effect := effects[effect_index]
		if effect == null:
			errors.append("Card '%s' effect %d is null." % [id, effect_index])
			continue
		for effect_error in effect.validate_definition():
			errors.append("Card '%s': %s" % [id, effect_error])
		if effect.effect_type == &"spawn_damage_trail" and effect.damage_by_stack.size() < max_stacks:
			errors.append("Card '%s' needs dash-trail damage for every stack." % id)
		if effect.effect_type == &"area_damage" and effect.radius_by_stack.size() < max_stacks:
			errors.append("Card '%s' needs area radius for every stack." % id)
	return errors
