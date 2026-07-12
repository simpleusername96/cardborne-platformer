class_name MasteryNodeDefinition
extends Resource

const CHARACTER_IDS: Array[StringName] = [&"warrior", &"archer", &"assassin"]
const DEPTHS: Array[StringName] = [&"root", &"middle", &"capstone"]
const MATERIAL_IDS: Array[StringName] = [&"rusted_scrap", &"sky_thread", &"slime_residue", &"boss_core"]

@export var id: StringName
@export var display_name: String
@export_multiline var mechanical_description: String
@export var content_version: int = 1
@export var character_id: StringName
@export var depth: StringName
@export var requires_all: Array[StringName] = []
@export var requires_any: Array[StringName] = []
@export var costs: Dictionary = {}
@export var behavior_effects: Array[ProgressionBehaviorEffect] = []


func get_prerequisite_ids() -> Array[StringName]:
	var prerequisite_ids := requires_all.duplicate()
	for prerequisite_id in requires_any:
		if not prerequisite_ids.has(prerequisite_id):
			prerequisite_ids.append(prerequisite_id)
	return prerequisite_ids


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Mastery node ID", id)
	if display_name.strip_edges().is_empty() or mechanical_description.strip_edges().is_empty():
		errors.append("Mastery node '%s' needs a display name and mechanical description." % id)
	if content_version <= 0:
		errors.append("Mastery node '%s' needs a positive content version." % id)
	if not CHARACTER_IDS.has(character_id):
		errors.append("Mastery node '%s' has invalid character '%s'." % [id, character_id])
	if not DEPTHS.has(depth):
		errors.append("Mastery node '%s' has invalid depth '%s'." % [id, depth])
	ContentId.validate_list(errors, "Mastery node '%s' required node" % id, requires_all, false)
	ContentId.validate_list(errors, "Mastery node '%s' alternative node" % id, requires_any, false)
	if not requires_all.is_empty() and not requires_any.is_empty():
		errors.append("Mastery node '%s' cannot combine all-of and any-of prerequisites." % id)
	if requires_all.has(id) or requires_any.has(id):
		errors.append("Mastery node '%s' cannot require itself." % id)
	for required_id in requires_all:
		if requires_any.has(required_id):
			errors.append("Mastery node '%s' repeats prerequisite '%s'." % [id, required_id])
	_validate_costs(errors)
	if behavior_effects.is_empty():
		errors.append("Mastery node '%s' needs at least one behavior effect." % id)
	var seen_effect_types: Dictionary = {}
	for effect_index in behavior_effects.size():
		var effect := behavior_effects[effect_index]
		if effect == null:
			errors.append("Mastery node '%s' behavior effect %d is null." % [id, effect_index])
			continue
		for effect_error in effect.validate_definition():
			errors.append("Mastery node '%s': %s" % [id, effect_error])
		if effect.source_id != id or effect.source_scope != ProgressionBehaviorEffect.SOURCE_SCOPE_MASTERY:
			errors.append("Mastery node '%s' effects must use their owner ID and mastery scope." % id)
		if seen_effect_types.has(effect.effect_type):
			errors.append("Mastery node '%s' repeats behavior effect '%s'." % [id, effect.effect_type])
		seen_effect_types[effect.effect_type] = true
	return errors


func _validate_costs(errors: PackedStringArray) -> void:
	if costs.is_empty():
		errors.append("Mastery node '%s' needs an explicit material cost." % id)
	for raw_material_id in costs:
		var material_id := StringName(raw_material_id)
		ContentId.validate(errors, "Mastery node '%s' cost material" % id, material_id)
		if not MATERIAL_IDS.has(material_id):
			errors.append("Mastery node '%s' has unsupported cost material '%s'." % [id, material_id])
		var amount: Variant = costs[raw_material_id]
		if not amount is int or int(amount) <= 0:
			errors.append("Mastery node '%s' cost '%s' needs a positive integer amount." % [id, material_id])
