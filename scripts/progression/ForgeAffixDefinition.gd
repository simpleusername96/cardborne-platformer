class_name ForgeAffixDefinition
extends Resource

const BEHAVIOR_NONE := &""
const BEHAVIOR_GUARD := &"reduce_first_damage"
const BEHAVIOR_SALVAGE := &"bonus_material_drops"
const SUPPORTED_BEHAVIORS: Array[StringName] = [
	BEHAVIOR_NONE, BEHAVIOR_GUARD, BEHAVIOR_SALVAGE,
]

@export var id: StringName
@export var display_name: String
@export_multiline var mechanical_description: String
@export var content_version: int = 1
@export var eligible_slots: Array[StringName] = []
@export var build_effects: Array[EffectDefinition] = []
@export var behavior_type: StringName
@export_range(0, 99, 1) var behavior_value: int = 0
@export_range(0, 99, 1) var trigger_count: int = 0


func supports_slot(slot_id: StringName) -> bool:
	return eligible_slots.has(slot_id)


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Forge affix ID", id)
	if display_name.strip_edges().is_empty() or mechanical_description.strip_edges().is_empty():
		errors.append("Forge affix '%s' needs a name and mechanical description." % id)
	if content_version <= 0 or eligible_slots.is_empty():
		errors.append("Forge affix '%s' needs a version and eligible slot." % id)
	ContentId.validate_list(errors, "Forge affix '%s' slots" % id, eligible_slots, true)
	for slot_id in eligible_slots:
		if not EquipmentDefinition.PERSISTENT_SLOTS.has(slot_id):
			errors.append("Forge affix '%s' has unsupported slot '%s'." % [id, slot_id])
	if not SUPPORTED_BEHAVIORS.has(behavior_type):
		errors.append("Forge affix '%s' has unsupported behavior '%s'." % [id, behavior_type])
	if build_effects.is_empty() == behavior_type.is_empty():
		errors.append("Forge affix '%s' must own build effects or one behavior." % id)
	for effect_index in build_effects.size():
		var effect := build_effects[effect_index]
		if effect == null:
			errors.append("Forge affix '%s' build effect %d is null." % [id, effect_index])
			continue
		if not PlayerBuild.STAT_RULES.has(String(effect.stat_id)):
			errors.append("Forge affix '%s' targets unsupported stat '%s'." % [id, effect.stat_id])
		if effect.source_id != id or effect.source_scope != EffectDefinition.SOURCE_SCOPE_TEMPORARY:
			errors.append("Forge affix '%s' build effects need temporary owner scope." % id)
		if not is_finite(effect.value) or is_zero_approx(effect.value):
			errors.append("Forge affix '%s' build values must be finite and non-zero." % id)
	if behavior_type.is_empty():
		if behavior_value != 0 or trigger_count != 0:
			errors.append("Stat forge affix '%s' cannot declare behavior counters." % id)
	elif behavior_value <= 0 or trigger_count <= 0:
		errors.append("Behavior forge affix '%s' needs positive value and trigger count." % id)
	return errors
