class_name ProfileData
extends Resource

const CURRENT_SCHEMA_VERSION := 1
const CHARACTER_IDS: Array[String] = ["warrior", "archer", "assassin"]
const PERSISTENT_SLOTS: Array[String] = ["weapon", "armor", "charm", "relic"]
const ALL_SLOTS: Array[String] = ["weapon", "armor", "charm", "relic", "consumable"]
const MATERIAL_IDS: Array[String] = [
	"rusted_scrap", "sky_thread", "slime_residue", "boss_core",
]
const CONSUMABLE_IDS: Array[String] = ["small_potion", "dash_tonic", "salvage_kit"]
const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"screen_shake": true,
	"damage_flash": true,
}
const DEFAULT_OWNED_EQUIPMENT: Array[String] = [
	"iron_cleaver", "field_bow", "rust_knives", "traveler_jacket",
]
const DEFAULT_LOADOUTS: Dictionary = {
	"warrior": {
		"weapon": "iron_cleaver", "armor": "traveler_jacket", "charm": "",
		"relic": "", "consumable": "small_potion",
	},
	"archer": {
		"weapon": "field_bow", "armor": "traveler_jacket", "charm": "",
		"relic": "", "consumable": "small_potion",
	},
	"assassin": {
		"weapon": "rust_knives", "armor": "traveler_jacket", "charm": "",
		"relic": "", "consumable": "small_potion",
	},
}

var schema_version: int = CURRENT_SCHEMA_VERSION
var materials: Dictionary = {}
var owned_equipment: Array[String] = []
var loadouts: Dictionary = {}
var mastery_unlocks: Dictionary = {}
var durable_unlocks: Array[String] = []
var settings: Dictionary = {}
var applied_profile_transactions: Array[String] = []


func _init() -> void:
	reset_to_defaults()


func reset_to_defaults() -> void:
	schema_version = CURRENT_SCHEMA_VERSION
	materials = {}
	owned_equipment = DEFAULT_OWNED_EQUIPMENT.duplicate()
	loadouts = DEFAULT_LOADOUTS.duplicate(true)
	mastery_unlocks = {}
	for character_id in CHARACTER_IDS:
		mastery_unlocks[character_id] = []
	durable_unlocks = []
	settings = DEFAULT_SETTINGS.duplicate(true)
	applied_profile_transactions = []


func duplicate_data() -> ProfileData:
	return from_dictionary(to_dictionary())


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"materials": materials.duplicate(true),
		"owned_equipment": owned_equipment.duplicate(),
		"loadouts": loadouts.duplicate(true),
		"mastery_unlocks": mastery_unlocks.duplicate(true),
		"durable_unlocks": durable_unlocks.duplicate(),
		"settings": settings.duplicate(true),
		"applied_profile_transactions": applied_profile_transactions.duplicate(),
	}


static func from_dictionary(payload: Dictionary) -> ProfileData:
	var data := ProfileData.new()
	data.schema_version = int(payload.get("schema_version", CURRENT_SCHEMA_VERSION))
	var raw_materials: Variant = payload.get("materials", {})
	data.materials = {}
	if raw_materials is Dictionary:
		for material_id in raw_materials:
			var amount: Variant = raw_materials[material_id]
			if (
				(amount is int or amount is float)
				and is_finite(float(amount))
				and is_equal_approx(float(amount), round(float(amount)))
			):
				data.materials[String(material_id)] = int(amount)
			else:
				data.materials[String(material_id)] = amount
	data.owned_equipment = _to_string_array(payload.get("owned_equipment", []))
	var raw_loadouts: Variant = payload.get("loadouts", {})
	data.loadouts = raw_loadouts.duplicate(true) if raw_loadouts is Dictionary else {}
	var raw_mastery: Variant = payload.get("mastery_unlocks", {})
	data.mastery_unlocks = raw_mastery.duplicate(true) if raw_mastery is Dictionary else {}
	data.durable_unlocks = _to_string_array(payload.get("durable_unlocks", []))
	var raw_settings: Variant = payload.get("settings", {})
	data.settings = raw_settings.duplicate(true) if raw_settings is Dictionary else {}
	data.applied_profile_transactions = _to_string_array(
		payload.get("applied_profile_transactions", [])
	)
	return data


func validate_data(
	equipment_catalog: EquipmentCatalog,
	mastery_catalog: MasteryCatalog
) -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != CURRENT_SCHEMA_VERSION:
		errors.append("Profile schema version %d is unsupported." % schema_version)
	_validate_materials(errors)
	_validate_owned_equipment(equipment_catalog, errors)
	_validate_loadouts(equipment_catalog, errors)
	_validate_mastery(mastery_catalog, errors)
	_validate_string_set("durable unlock", durable_unlocks, errors)
	_validate_string_set("profile transaction", applied_profile_transactions, errors)
	_validate_settings(errors)
	return errors


func _validate_materials(errors: PackedStringArray) -> void:
	for raw_material_id in materials:
		var material_id := String(raw_material_id)
		var value: Variant = materials[raw_material_id]
		if not MATERIAL_IDS.has(material_id):
			errors.append("Profile contains unknown material '%s'." % material_id)
		elif not value is int or int(value) < 0:
			errors.append("Profile material '%s' must be a non-negative integer." % material_id)


func _validate_owned_equipment(
	equipment_catalog: EquipmentCatalog,
	errors: PackedStringArray
) -> void:
	_validate_string_set("owned equipment", owned_equipment, errors)
	for item_id in owned_equipment:
		if equipment_catalog == null or equipment_catalog.get_item(StringName(item_id)) == null:
			errors.append("Profile owns unknown equipment '%s'." % item_id)


func _validate_loadouts(
	equipment_catalog: EquipmentCatalog,
	errors: PackedStringArray
) -> void:
	for character_id in CHARACTER_IDS:
		var raw_loadout: Variant = loadouts.get(character_id, null)
		if not raw_loadout is Dictionary:
			errors.append("Profile is missing the '%s' loadout." % character_id)
			continue
		var loadout: Dictionary = raw_loadout
		for slot_id in ALL_SLOTS:
			if not loadout.has(slot_id):
				errors.append("Loadout '%s' is missing slot '%s'." % [character_id, slot_id])
				continue
			var item_id := String(loadout[slot_id])
			if item_id.is_empty():
				if slot_id in ["weapon", "armor"]:
					errors.append("Loadout '%s' requires a %s." % [character_id, slot_id])
				continue
			if slot_id == "consumable":
				if not CONSUMABLE_IDS.has(item_id):
					errors.append("Loadout '%s' has unknown consumable '%s'." % [character_id, item_id])
				continue
			var item := equipment_catalog.get_item(StringName(item_id)) if equipment_catalog != null else null
			if item == null:
				errors.append("Loadout '%s' references unknown item '%s'." % [character_id, item_id])
			elif not owned_equipment.has(item_id):
				errors.append("Loadout '%s' equips unowned item '%s'." % [character_id, item_id])
			elif String(item.slot) != slot_id or not item.is_compatible(StringName(character_id)):
				errors.append("Item '%s' is incompatible with %s %s." % [item_id, character_id, slot_id])


func _validate_mastery(
	mastery_catalog: MasteryCatalog,
	errors: PackedStringArray
) -> void:
	for character_id in CHARACTER_IDS:
		var raw_nodes: Variant = mastery_unlocks.get(character_id, null)
		if not raw_nodes is Array:
			errors.append("Profile is missing '%s' mastery state." % character_id)
			continue
		var node_ids := _to_string_array(raw_nodes)
		_validate_string_set("%s mastery" % character_id, node_ids, errors)
		for node_id in node_ids:
			var node := mastery_catalog.get_node(StringName(node_id)) if mastery_catalog != null else null
			if node == null or String(node.character_id) != character_id:
				errors.append("Profile has invalid %s mastery '%s'." % [character_id, node_id])
				continue
			for required_id in node.requires_all:
				if not node_ids.has(String(required_id)):
					errors.append("Mastery '%s' is missing prerequisite '%s'." % [node_id, required_id])
			if not node.requires_any.is_empty():
				var has_any := false
				for required_id in node.requires_any:
					has_any = has_any or node_ids.has(String(required_id))
				if not has_any:
					errors.append("Mastery '%s' is missing an alternate prerequisite." % node_id)


func _validate_settings(errors: PackedStringArray) -> void:
	for setting_id in DEFAULT_SETTINGS:
		if not settings.has(setting_id):
			errors.append("Profile is missing setting '%s'." % setting_id)
			continue
		var value: Variant = settings[setting_id]
		if String(setting_id).ends_with("_volume"):
			if not (value is int or value is float):
				errors.append("Setting '%s' must be numeric." % setting_id)
				continue
			var volume := float(value)
			if not is_finite(volume) or volume < 0.0 or volume > 1.0:
				errors.append("Setting '%s' must be between zero and one." % setting_id)
		elif not value is bool:
			errors.append("Setting '%s' must be boolean." % setting_id)
	for setting_id in settings:
		if not DEFAULT_SETTINGS.has(setting_id):
			errors.append("Profile contains unknown setting '%s'." % setting_id)


static func _validate_string_set(
	label: String,
	values: Array[String],
	errors: PackedStringArray
) -> void:
	var seen: Dictionary = {}
	for value in values:
		if value.strip_edges().is_empty():
			errors.append("Profile %s contains a blank ID." % label)
		elif seen.has(value):
			errors.append("Profile %s repeats '%s'." % [label, value])
		seen[value] = true


static func _to_string_array(raw_values: Variant) -> Array[String]:
	var values: Array[String] = []
	if raw_values is Array:
		for value in raw_values:
			values.append(String(value))
	return values
