class_name MaterialDefinition
extends Resource

const FAMILY_METAL := &"metal"
const FAMILY_TIMBER := &"timber"
const FAMILY_TEXTILE := &"textile"
const FAMILIES: Array[StringName] = [FAMILY_METAL, FAMILY_TIMBER, FAMILY_TEXTILE]
const GRADE_ONE := 1
const GRADE_TWO := 2
const GRADES: Array[int] = [GRADE_ONE, GRADE_TWO]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var presentation_key: StringName
@export var family: StringName
@export var grade: int = GRADE_ONE


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Material ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Material '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Material '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Material '%s' tag" % id, tags, true)
	ContentId.validate(errors, "Material '%s' presentation key" % id, presentation_key)
	if family not in FAMILIES:
		errors.append("Material '%s' has unsupported family '%s'." % [id, family])
	if grade not in GRADES:
		errors.append("Material '%s' grade must be 1 or 2." % id)
	if not tags.has(&"material"):
		errors.append("Material '%s' needs the material tag." % id)
	if family in FAMILIES and not tags.has(family):
		errors.append("Material '%s' needs its family tag '%s'." % [id, family])
	if grade in GRADES and not tags.has(grade_tag()):
		errors.append("Material '%s' needs its grade tag '%s'." % [id, grade_tag()])
	return errors


func grade_tag() -> StringName:
	return &"grade_one" if grade == GRADE_ONE else &"grade_two"
