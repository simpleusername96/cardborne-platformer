class_name EquipmentDefinition
extends Resource

const PERSISTENT_SLOTS: Array[StringName] = [&"weapon", &"armor", &"charm", &"relic"]
const COMPATIBILITY_IDS: Array[StringName] = [&"warrior", &"archer", &"assassin", &"shared"]
const MATERIAL_IDS: Array[StringName] = [&"rusted_scrap", &"sky_thread", &"slime_residue", &"boss_core"]
const BUILD_STAT_IDS: Array[StringName] = [
	&"max_health",
	&"move_speed",
	&"dash_cooldown",
	&"damage_knockback_x",
	&"damage_knockback_y",
]

@export var id: StringName
@export var display_name: String
@export_multiline var mechanical_description: String
@export_multiline var tradeoff_description: String
@export var content_version: int = 1
@export var slot: StringName
@export var compatibility: Array[StringName] = []
@export var source: StringName
@export var build_effects: Array[EffectDefinition] = []
@export var behavior_effects: Array[ProgressionBehaviorEffect] = []
@export var salvage_materials: Dictionary = {}
@export var unlock_costs: Dictionary = {}
@export var starting_item: bool = false


func is_compatible(character_id: StringName) -> bool:
	return compatibility.has(&"shared") or compatibility.has(character_id)


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Equipment ID", id)
	if display_name.strip_edges().is_empty() or mechanical_description.strip_edges().is_empty():
		errors.append("Equipment '%s' needs a display name and mechanical description." % id)
	if content_version <= 0:
		errors.append("Equipment '%s' needs a positive content version." % id)
	if not PERSISTENT_SLOTS.has(slot):
		errors.append("Equipment '%s' has invalid persistent slot '%s'." % [id, slot])
	ContentId.validate_list(errors, "Equipment '%s' compatibility" % id, compatibility, true)
	for compatibility_id in compatibility:
		if not COMPATIBILITY_IDS.has(compatibility_id):
			errors.append("Equipment '%s' has unsupported compatibility '%s'." % [id, compatibility_id])
	if compatibility.has(&"shared") and compatibility.size() != 1:
		errors.append("Equipment '%s' cannot combine shared and character compatibility." % id)
	ContentId.validate(errors, "Equipment '%s' source" % id, source)
	_validate_material_map(errors, salvage_materials, "salvage", true)
	_validate_material_map(errors, unlock_costs, "unlock", false)
	if starting_item and not unlock_costs.is_empty():
		errors.append("Starting equipment '%s' must have zero unlock cost." % id)
	if not starting_item and unlock_costs.is_empty():
		errors.append("Unlockable equipment '%s' needs an explicit unlock cost." % id)
	if not starting_item and tradeoff_description.strip_edges().is_empty():
		errors.append("Unlockable equipment '%s' needs a stated tradeoff or limit." % id)
	if not starting_item and build_effects.is_empty() and behavior_effects.is_empty():
		errors.append("Unlockable equipment '%s' needs a build or behavior effect." % id)

	var build_signatures: Dictionary = {}
	for effect_index in build_effects.size():
		var effect := build_effects[effect_index]
		if effect == null:
			errors.append("Equipment '%s' build effect %d is null." % [id, effect_index])
			continue
		_validate_build_effect(errors, effect)
		var signature := "%s:%s" % [effect.stat_id, effect.operation]
		if build_signatures.has(signature):
			errors.append("Equipment '%s' repeats build effect '%s'." % [id, signature])
		build_signatures[signature] = true

	var behavior_types: Dictionary = {}
	for effect_index in behavior_effects.size():
		var effect := behavior_effects[effect_index]
		if effect == null:
			errors.append("Equipment '%s' behavior effect %d is null." % [id, effect_index])
			continue
		for effect_error in effect.validate_definition():
			errors.append("Equipment '%s': %s" % [id, effect_error])
		if effect.source_id != id or effect.source_scope != ProgressionBehaviorEffect.SOURCE_SCOPE_EQUIPMENT:
			errors.append("Equipment '%s' behavior effects must use their owner ID and equipment scope." % id)
		if behavior_types.has(effect.effect_type):
			errors.append("Equipment '%s' repeats behavior effect '%s'." % [id, effect.effect_type])
		behavior_types[effect.effect_type] = true
	return errors


func _validate_build_effect(errors: PackedStringArray, effect: EffectDefinition) -> void:
	ContentId.validate(errors, "Equipment '%s' build stat" % id, effect.stat_id)
	ContentId.validate(errors, "Equipment '%s' build source" % id, effect.source_id)
	if not BUILD_STAT_IDS.has(effect.stat_id):
		errors.append("Equipment '%s' uses unsupported build stat '%s'." % [id, effect.stat_id])
	if effect.operation not in [EffectDefinition.OPERATION_ADD, EffectDefinition.OPERATION_MULTIPLY, EffectDefinition.OPERATION_OVERRIDE]:
		errors.append("Equipment '%s' has invalid build operation '%s'." % [id, effect.operation])
	if not is_finite(effect.value) or is_zero_approx(effect.value):
		errors.append("Equipment '%s' build effects need finite, non-zero values." % id)
	if effect.operation == EffectDefinition.OPERATION_MULTIPLY and effect.value <= 0.0:
		errors.append("Equipment '%s' multipliers must be positive." % id)
	if effect.source_id != id or effect.source_scope != EffectDefinition.SOURCE_SCOPE_EQUIPMENT:
		errors.append("Equipment '%s' build effects must use their owner ID and equipment scope." % id)
	if effect.stacking not in [EffectDefinition.STACKING_STACK, EffectDefinition.STACKING_UNIQUE, EffectDefinition.STACKING_REPLACE, EffectDefinition.STACKING_HIGHEST]:
		errors.append("Equipment '%s' has invalid build stacking '%s'." % [id, effect.stacking])
	if effect.stacking != EffectDefinition.STACKING_STACK:
		ContentId.validate(errors, "Equipment '%s' build stack key" % id, effect.stack_key)


func _validate_material_map(
	errors: PackedStringArray,
	material_map: Dictionary,
	label: String,
	require_value: bool
) -> void:
	if require_value and material_map.is_empty():
		errors.append("Equipment '%s' needs salvage materials." % id)
	for raw_material_id in material_map:
		var material_id := StringName(raw_material_id)
		ContentId.validate(errors, "Equipment '%s' %s material" % [id, label], material_id)
		if not MATERIAL_IDS.has(material_id):
			errors.append("Equipment '%s' has unsupported %s material '%s'." % [id, label, material_id])
		var amount: Variant = material_map[raw_material_id]
		if not amount is int or int(amount) <= 0:
			errors.append("Equipment '%s' %s material '%s' needs a positive integer amount." % [id, label, material_id])
