class_name ForgeCatalog
extends Resource

const EXPECTED_IDS: Array[StringName] = [
	&"forge_force", &"forge_tempo", &"forge_guard", &"forge_stride", &"forge_salvage",
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export_range(1, 999, 1) var coin_cost: int = 15
@export_range(1, 5, 1) var offer_size: int = 3
@export var affixes: Array[ForgeAffixDefinition] = []


func get_affix(affix_id: StringName) -> ForgeAffixDefinition:
	for affix in affixes:
		if affix != null and affix.id == affix_id:
			return affix
	return null


func get_eligible(slot_id: StringName) -> Array[ForgeAffixDefinition]:
	var eligible: Array[ForgeAffixDefinition] = []
	for affix in affixes:
		if affix != null and affix.supports_slot(slot_id):
			eligible.append(affix)
	eligible.sort_custom(func(left: ForgeAffixDefinition, right: ForgeAffixDefinition) -> bool:
		return String(left.id) < String(right.id)
	)
	return eligible


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Forge catalog ID", id)
	if display_name.strip_edges().is_empty() or content_version <= 0:
		errors.append("Forge catalog needs a name and positive version.")
	if coin_cost != 15 or offer_size != 3:
		errors.append("First-run forge must cost 15 coins and offer three affixes.")
	var seen: Dictionary = {}
	for affix in affixes:
		if affix == null:
			errors.append("Forge catalog contains a null affix.")
			continue
		if seen.has(affix.id):
			errors.append("Forge catalog repeats '%s'." % affix.id)
		seen[affix.id] = true
		for error in affix.validate_definition():
			errors.append(error)
	for expected_id in EXPECTED_IDS:
		if not seen.has(expected_id):
			errors.append("Forge catalog is missing '%s'." % expected_id)
	if seen.size() != EXPECTED_IDS.size():
		errors.append("Forge catalog must contain exactly five first-run affixes.")
	for slot_id in EquipmentDefinition.PERSISTENT_SLOTS:
		if get_eligible(slot_id).size() <= offer_size:
			errors.append(
				"Forge slot '%s' needs three choices after excluding its current affix."
				% slot_id
			)
	return errors
