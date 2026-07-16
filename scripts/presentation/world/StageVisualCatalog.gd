class_name StageVisualCatalog
extends Resource

@export var definitions: Array[StageVisualDefinition] = []


func get_definition(stage_id: StringName) -> StageVisualDefinition:
	for definition in definitions:
		if definition != null and definition.id == stage_id:
			return definition
	return null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for definition in definitions:
		if definition == null:
			errors.append("Stage visual catalog contains a null definition.")
			continue
		if ids.has(String(definition.id)):
			errors.append("Duplicate stage visual id %s." % definition.id)
		ids[String(definition.id)] = true
		errors.append_array(definition.validation_errors())
	return errors
