class_name EncounterCompositionRules
extends RefCounted

const HIGH_ATTENTION_ROLES: Array[StringName] = [
	&"burst", &"ranged", &"guard", &"vertical", &"zone", &"summoner",
]
const MAX_HIGH_ATTENTION_ENEMIES := 2
const FINAL_GALLERY_HIGH_ATTENTION_ENEMIES := 3
const THREE_THREAT_COMBINE_GROUPS: Array[StringName] = [
	&"flooded_final_gallery",
	&"sanctum_fractured_gallery",
]
const MAX_SAME_ARCHETYPE := 2


static func permits_candidate(
	template: RoomTemplateData,
	selected: Array,
	candidate: Dictionary
) -> bool:
	var pressure_role := StringName(candidate.get("pressure_role", ""))
	var archetype_id := StringName(candidate.get("archetype_id", ""))
	if is_forbidden(template, pressure_role, archetype_id):
		return false
	var high_attention_count := 1 if HIGH_ATTENTION_ROLES.has(pressure_role) else 0
	var same_archetype_count := 1
	for choice in selected:
		if HIGH_ATTENTION_ROLES.has(StringName(choice.get("pressure_role", ""))):
			high_attention_count += 1
		if StringName(choice.get("archetype_id", "")) == archetype_id:
			same_archetype_count += 1
	var high_attention_limit := (
		FINAL_GALLERY_HIGH_ATTENTION_ENEMIES
		if template != null and THREE_THREAT_COMBINE_GROUPS.has(template.variant_group)
		else MAX_HIGH_ATTENTION_ENEMIES
	)
	return (
		high_attention_count <= high_attention_limit
		and same_archetype_count <= MAX_SAME_ARCHETYPE
	)


static func is_forbidden(
	template: RoomTemplateData,
	pressure_role: StringName,
	archetype_id: StringName
) -> bool:
	return (
		template != null
		and (
			template.forbidden_pairs.has(pressure_role)
			or template.forbidden_pairs.has(archetype_id)
		)
	)


static func validate_room(
	template: RoomTemplateData,
	encounters: Array[PlannedEncounter]
) -> PackedStringArray:
	var errors := PackedStringArray()
	var selected: Array[Dictionary] = []
	for encounter in encounters:
		var candidate := {
			"pressure_role": encounter.pressure_role,
			"archetype_id": encounter.archetype_id,
		}
		if not permits_candidate(template, selected, candidate):
			errors.append(
				"Encounter '%s' violates room exclusion or composition limits."
				% encounter.id
			)
		selected.append(candidate)
	return errors
