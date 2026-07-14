class_name EquipmentBlueprintDefinition
extends Resource

const MINIMUM_MATERIAL_GRADE := MaterialDefinition.GRADE_ONE
const MAXIMUM_MATERIAL_GRADE := MaterialDefinition.GRADE_TWO

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export var model_id: StringName
@export var starting_blueprint: bool = false
@export var minimum_material_grade: int = MINIMUM_MATERIAL_GRADE
@export var maximum_material_grade: int = MAXIMUM_MATERIAL_GRADE
@export var recipe: CraftingRecipeDefinition


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Equipment blueprint ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Equipment blueprint '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Equipment blueprint '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Equipment blueprint '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Equipment blueprint '%s' presentation key" % id, presentation_key)
	ContentId.validate(errors, "Equipment blueprint '%s' model ID" % id, model_id)
	if not tags.has(&"equipment_blueprint"):
		errors.append("Equipment blueprint '%s' needs the equipment_blueprint tag." % id)
	var expected_id := StringName("%s_blueprint" % model_id)
	if id != expected_id:
		errors.append("Equipment blueprint '%s' must use ID '%s'." % [id, expected_id])
	if (
		minimum_material_grade != MINIMUM_MATERIAL_GRADE
		or maximum_material_grade != MAXIMUM_MATERIAL_GRADE
	):
		errors.append("Equipment blueprint '%s' must support exactly material grades 1 and 2." % id)
	if recipe == null:
		errors.append("Equipment blueprint '%s' needs a typed crafting recipe." % id)
		return errors
	for recipe_error in recipe.validate_definition():
		errors.append("Equipment blueprint '%s': %s" % [id, recipe_error])
	var expected_recipe_id := StringName("%s_recipe" % model_id)
	if recipe.id != expected_recipe_id:
		errors.append(
			"Equipment blueprint '%s' recipe must use ID '%s'." % [id, expected_recipe_id]
		)
	return errors
