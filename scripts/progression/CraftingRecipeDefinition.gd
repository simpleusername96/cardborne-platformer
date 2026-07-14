class_name CraftingRecipeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export var family_costs: Dictionary = {}
@export var same_grade_only: bool = true


func get_cost(family_id: StringName) -> int:
	if family_costs.has(family_id):
		return int(family_costs[family_id])
	return int(family_costs.get(String(family_id), 0))


func normalized_costs() -> Dictionary:
	var costs: Dictionary = {}
	for raw_family in family_costs:
		costs[StringName(raw_family)] = family_costs[raw_family]
	return costs


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Crafting recipe ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Crafting recipe '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Crafting recipe '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Crafting recipe '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Crafting recipe '%s' presentation key" % id, presentation_key)
	if not tags.has(&"crafting_recipe"):
		errors.append("Crafting recipe '%s' needs the crafting_recipe tag." % id)
	if not same_grade_only:
		errors.append("Crafting recipe '%s' must consume the selected material grade only." % id)
	if family_costs.is_empty():
		errors.append("Crafting recipe '%s' needs at least one material-family cost." % id)

	var seen_families: Dictionary = {}
	for raw_family in family_costs:
		var family_id := StringName(raw_family)
		var family_text := String(family_id)
		ContentId.validate(errors, "Crafting recipe '%s' material family" % id, family_id)
		if seen_families.has(family_text):
			errors.append("Crafting recipe '%s' repeats material family '%s'." % [id, family_id])
		seen_families[family_text] = true
		if family_id not in MaterialDefinition.FAMILIES:
			errors.append("Crafting recipe '%s' uses unsupported material family '%s'." % [id, family_id])
		var amount: Variant = family_costs[raw_family]
		if not amount is int or int(amount) <= 0:
			errors.append(
				"Crafting recipe '%s' material family '%s' needs a positive integer amount."
				% [id, family_id]
			)
	return errors
