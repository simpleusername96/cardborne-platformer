class_name ProfileData
extends Resource

const CURRENT_SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1
const HERO_ID := "traveler"
const HERO_LOADOUT_SLOTS: Array[String] = [
	"melee", "ranged", "shield", "armor", "spirit_stone", "consumable",
]
const EQUIPMENT_MODEL_IDS: Array[String] = [
	"traveler_sword", "hunting_spear", "hunting_bow", "matchlock",
	"round_shield", "tower_shield", "traveler_coat", "reinforced_coat",
]
const MODEL_SLOTS: Dictionary = {
	"traveler_sword": "melee",
	"hunting_spear": "melee",
	"hunting_bow": "ranged",
	"matchlock": "ranged",
	"round_shield": "shield",
	"tower_shield": "shield",
	"traveler_coat": "armor",
	"reinforced_coat": "armor",
}
const CONDITION_MODEL_IDS: Array[String] = [
	"traveler_sword", "hunting_spear", "round_shield", "tower_shield",
]
const GRADE_IDS: Array[String] = ["grade_1", "grade_2"]
const ACTIVE_MATERIAL_IDS: Array[String] = [
	"rusted_scrap", "steel_fragment", "common_timber", "hardwood",
	"sky_thread", "reinforced_fabric",
]
const LEGACY_MATERIAL_IDS: Array[String] = ["slime_residue", "boss_core"]
const MATERIAL_IDS: Array[String] = [
	"rusted_scrap", "steel_fragment", "common_timber", "hardwood",
	"sky_thread", "reinforced_fabric", "slime_residue", "boss_core",
]
const SPIRIT_STONE_IDS: Array[String] = ["ember_spirit_stone", "frost_spirit_stone"]
const CONSUMABLE_IDS: Array[String] = ["small_potion"]
const RANGED_SUPPLY_LIMITS: Dictionary = {"arrows": 20, "cartridges": 8}
const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"screen_shake": true,
	"damage_flash": true,
}
const DEFAULT_BLUEPRINTS: Array[String] = [
	"traveler_sword", "hunting_bow", "round_shield", "traveler_coat",
]
const DEFAULT_CRAFTED_EQUIPMENT: Dictionary = {
	"traveler_sword": {"grade_id": "grade_1", "condition": 100.0},
	"hunting_bow": {"grade_id": "grade_1", "condition": 0.0},
	"round_shield": {"grade_id": "grade_1", "condition": 100.0},
	"traveler_coat": {"grade_id": "grade_1", "condition": 0.0},
}
const DEFAULT_HERO_LOADOUT: Dictionary = {
	"melee": "traveler_sword",
	"ranged": "hunting_bow",
	"shield": "round_shield",
	"armor": "traveler_coat",
	"spirit_stone": "ember_spirit_stone",
	"consumable": "small_potion",
}
const DEFAULT_RANGED_SUPPLIES: Dictionary = {"arrows": 12, "cartridges": 5}
const DEFAULT_TUTORIAL_STATE: Dictionary = {
	"resolved": false,
	"completed": false,
	"skipped": false,
}

# Compatibility-only v1 state remains for migration fixtures, not the Traveler flow.
const CHARACTER_IDS: Array[String] = ["warrior", "archer", "assassin"]
const PERSISTENT_SLOTS: Array[String] = ["weapon", "armor", "charm", "relic"]
const ALL_SLOTS: Array[String] = ["weapon", "armor", "charm", "relic", "consumable"]
const LEGACY_CONSUMABLE_IDS: Array[String] = ["small_potion", "dash_tonic", "salvage_kit"]
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
var hero_id: String = HERO_ID
var materials: Dictionary = {}
var unlocked_blueprints: Array[String] = []
var crafted_equipment: Dictionary = {}
var unlocked_spirit_stones: Array[String] = []
var hero_loadout: Dictionary = {}
var ranged_supplies: Dictionary = {}
var tutorial_state: Dictionary = {}
var settings: Dictionary = {}
var applied_profile_transactions: Array[String] = []
var durable_unlocks: Array[String] = []

var owned_equipment: Array[String] = []
var loadouts: Dictionary = {}
var mastery_unlocks: Dictionary = {}


func _init() -> void:
	reset_to_defaults()


func reset_to_defaults() -> void:
	schema_version = CURRENT_SCHEMA_VERSION
	hero_id = HERO_ID
	materials = {}
	unlocked_blueprints = DEFAULT_BLUEPRINTS.duplicate()
	crafted_equipment = DEFAULT_CRAFTED_EQUIPMENT.duplicate(true)
	unlocked_spirit_stones = ["ember_spirit_stone"]
	hero_loadout = DEFAULT_HERO_LOADOUT.duplicate(true)
	ranged_supplies = DEFAULT_RANGED_SUPPLIES.duplicate(true)
	tutorial_state = DEFAULT_TUTORIAL_STATE.duplicate(true)
	settings = DEFAULT_SETTINGS.duplicate(true)
	applied_profile_transactions = []
	durable_unlocks = []

	owned_equipment = DEFAULT_OWNED_EQUIPMENT.duplicate()
	loadouts = DEFAULT_LOADOUTS.duplicate(true)
	mastery_unlocks = {}
	for character_id in CHARACTER_IDS:
		mastery_unlocks[character_id] = []


func duplicate_data() -> ProfileData:
	return from_dictionary(to_dictionary())


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"hero_id": hero_id,
		"materials": materials.duplicate(true),
		"unlocked_blueprints": unlocked_blueprints.duplicate(),
		"crafted_equipment": crafted_equipment.duplicate(true),
		"unlocked_spirit_stones": unlocked_spirit_stones.duplicate(),
		"hero_loadout": hero_loadout.duplicate(true),
		"ranged_supplies": ranged_supplies.duplicate(true),
		"tutorial_state": tutorial_state.duplicate(true),
		"settings": settings.duplicate(true),
		"applied_profile_transactions": applied_profile_transactions.duplicate(),
		"durable_unlocks": durable_unlocks.duplicate(),
		"owned_equipment": owned_equipment.duplicate(),
		"loadouts": loadouts.duplicate(true),
		"mastery_unlocks": mastery_unlocks.duplicate(true),
	}


static func from_dictionary(payload: Dictionary) -> ProfileData:
	var data := ProfileData.new()
	data.schema_version = int(payload.get("schema_version", CURRENT_SCHEMA_VERSION))
	data.hero_id = String(payload.get("hero_id", HERO_ID))
	data.materials = _material_dictionary(payload.get("materials", {}))
	data.unlocked_blueprints = _to_string_array(
		payload.get("unlocked_blueprints", DEFAULT_BLUEPRINTS)
	)
	data.crafted_equipment = _dictionary_or_default(
		payload.get("crafted_equipment", DEFAULT_CRAFTED_EQUIPMENT),
		DEFAULT_CRAFTED_EQUIPMENT
	)
	data.unlocked_spirit_stones = _to_string_array(
		payload.get("unlocked_spirit_stones", ["ember_spirit_stone"])
	)
	data.hero_loadout = _dictionary_or_default(
		payload.get("hero_loadout", DEFAULT_HERO_LOADOUT),
		DEFAULT_HERO_LOADOUT
	)
	data.ranged_supplies = _integer_dictionary_or_default(
		payload.get("ranged_supplies", DEFAULT_RANGED_SUPPLIES),
		DEFAULT_RANGED_SUPPLIES
	)
	data.tutorial_state = _dictionary_or_default(
		payload.get("tutorial_state", DEFAULT_TUTORIAL_STATE),
		DEFAULT_TUTORIAL_STATE
	)
	data.settings = _dictionary_or_default(
		payload.get("settings", DEFAULT_SETTINGS),
		DEFAULT_SETTINGS
	)
	data.applied_profile_transactions = _to_string_array(
		payload.get("applied_profile_transactions", [])
	)
	data.durable_unlocks = _to_string_array(payload.get("durable_unlocks", []))

	data.owned_equipment = _to_string_array(
		payload.get("owned_equipment", DEFAULT_OWNED_EQUIPMENT)
	)
	data.loadouts = _dictionary_or_default(payload.get("loadouts", DEFAULT_LOADOUTS), DEFAULT_LOADOUTS)
	data.mastery_unlocks = _dictionary_or_default(payload.get("mastery_unlocks", {}), {})
	return data


func validate_data(
	equipment_catalog: EquipmentCatalog = null,
	mastery_catalog: MasteryCatalog = null,
	progression_catalog: Resource = null
) -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != CURRENT_SCHEMA_VERSION:
		errors.append("Profile schema version %d is unsupported." % schema_version)
	if hero_id != HERO_ID:
		errors.append("Profile hero '%s' is unsupported." % hero_id)
	_validate_materials(errors)
	_validate_blueprints(progression_catalog, errors)
	_validate_crafted_equipment(progression_catalog, errors)
	_validate_spirit_stones(progression_catalog, errors)
	_validate_hero_loadout(errors)
	_validate_ranged_supplies(errors)
	_validate_tutorial_state(errors)
	_validate_string_set("durable unlock", durable_unlocks, errors)
	_validate_string_set("profile transaction", applied_profile_transactions, errors)
	_validate_settings(errors)
	_validate_legacy_state(equipment_catalog, mastery_catalog, errors)
	return errors


func _validate_materials(errors: PackedStringArray) -> void:
	for raw_material_id in materials:
		var material_id := String(raw_material_id)
		var value: Variant = materials[raw_material_id]
		if not MATERIAL_IDS.has(material_id):
			errors.append("Profile contains unknown material '%s'." % material_id)
		elif not value is int or int(value) < 0:
			errors.append("Profile material '%s' must be a non-negative integer." % material_id)


func _validate_blueprints(catalog: Resource, errors: PackedStringArray) -> void:
	_validate_string_set("blueprint", unlocked_blueprints, errors)
	for model_id in unlocked_blueprints:
		if not EQUIPMENT_MODEL_IDS.has(model_id):
			errors.append("Profile has unknown blueprint '%s'." % model_id)
		elif catalog != null and catalog.has_method("get_blueprint_for_model"):
			if catalog.call("get_blueprint_for_model", StringName(model_id)) == null:
				errors.append("Profile blueprint '%s' is absent from the catalog." % model_id)


func _validate_crafted_equipment(catalog: Resource, errors: PackedStringArray) -> void:
	for raw_model_id in crafted_equipment:
		var model_id := String(raw_model_id)
		if not EQUIPMENT_MODEL_IDS.has(model_id):
			errors.append("Profile has unknown crafted equipment '%s'." % model_id)
			continue
		if not unlocked_blueprints.has(model_id):
			errors.append("Crafted equipment '%s' requires its blueprint." % model_id)
		var raw_state: Variant = crafted_equipment[raw_model_id]
		if not raw_state is Dictionary:
			errors.append("Crafted equipment '%s' state must be a dictionary." % model_id)
			continue
		var state: Dictionary = raw_state
		var grade_id := String(state.get("grade_id", ""))
		if not GRADE_IDS.has(grade_id):
			errors.append("Crafted equipment '%s' has invalid grade '%s'." % [model_id, grade_id])
		var condition: Variant = state.get("condition", null)
		if not (condition is int or condition is float) or not is_finite(float(condition)):
			errors.append("Crafted equipment '%s' condition must be finite and numeric." % model_id)
		else:
			var maximum := 120.0 if grade_id == "grade_2" else 100.0
			if float(condition) < 0.0 or float(condition) > maximum:
				errors.append("Crafted equipment '%s' condition is outside 0-%d." % [model_id, int(maximum)])
			if not CONDITION_MODEL_IDS.has(model_id) and not is_zero_approx(float(condition)):
				errors.append("Equipment '%s' does not own condition." % model_id)
		if catalog != null and catalog.has_method("get_model"):
			if catalog.call("get_model", StringName(model_id)) == null:
				errors.append("Crafted equipment '%s' is absent from the catalog." % model_id)


func _validate_spirit_stones(catalog: Resource, errors: PackedStringArray) -> void:
	_validate_string_set("Spirit Stone", unlocked_spirit_stones, errors)
	for stone_id in unlocked_spirit_stones:
		if not SPIRIT_STONE_IDS.has(stone_id):
			errors.append("Profile has unknown Spirit Stone '%s'." % stone_id)
		elif catalog != null and catalog.has_method("get_spirit_stone"):
			if catalog.call("get_spirit_stone", StringName(stone_id)) == null:
				errors.append("Spirit Stone '%s' is absent from the catalog." % stone_id)


func _validate_hero_loadout(errors: PackedStringArray) -> void:
	for slot_id in HERO_LOADOUT_SLOTS:
		if not hero_loadout.has(slot_id):
			errors.append("Hero loadout is missing slot '%s'." % slot_id)
			continue
		var item_id := String(hero_loadout[slot_id])
		if item_id.is_empty():
			errors.append("Hero loadout slot '%s' cannot be empty." % slot_id)
			continue
		if slot_id == "spirit_stone":
			if not unlocked_spirit_stones.has(item_id):
				errors.append("Hero equips locked Spirit Stone '%s'." % item_id)
		elif slot_id == "consumable":
			if not CONSUMABLE_IDS.has(item_id):
				errors.append("Hero equips unknown consumable '%s'." % item_id)
		else:
			if MODEL_SLOTS.get(item_id, "") != slot_id:
				errors.append("Equipment '%s' does not fit hero slot '%s'." % [item_id, slot_id])
			elif not crafted_equipment.has(item_id):
				errors.append("Hero equips uncrafted equipment '%s'." % item_id)
	for slot_id in hero_loadout:
		if not HERO_LOADOUT_SLOTS.has(String(slot_id)):
			errors.append("Hero loadout has unsupported slot '%s'." % slot_id)


func _validate_ranged_supplies(errors: PackedStringArray) -> void:
	for supply_id in RANGED_SUPPLY_LIMITS:
		if not ranged_supplies.has(supply_id):
			errors.append("Profile is missing ranged supply '%s'." % supply_id)
			continue
		var amount: Variant = ranged_supplies[supply_id]
		if not amount is int or int(amount) < 0 or int(amount) > int(RANGED_SUPPLY_LIMITS[supply_id]):
			errors.append("Ranged supply '%s' must be within 0-%d." % [supply_id, RANGED_SUPPLY_LIMITS[supply_id]])
	for supply_id in ranged_supplies:
		if not RANGED_SUPPLY_LIMITS.has(supply_id):
			errors.append("Profile contains unknown ranged supply '%s'." % supply_id)


func _validate_tutorial_state(errors: PackedStringArray) -> void:
	for state_id in DEFAULT_TUTORIAL_STATE:
		if not tutorial_state.has(state_id) or not tutorial_state[state_id] is bool:
			errors.append("Tutorial state '%s' must be boolean." % state_id)
	for state_id in tutorial_state:
		if not DEFAULT_TUTORIAL_STATE.has(state_id):
			errors.append("Profile contains unknown tutorial state '%s'." % state_id)
	var completed := bool(tutorial_state.get("completed", false))
	var skipped := bool(tutorial_state.get("skipped", false))
	var resolved := bool(tutorial_state.get("resolved", false))
	if completed and skipped:
		errors.append("Tutorial cannot be both completed and skipped.")
	if (completed or skipped) and not resolved:
		errors.append("Completed or skipped tutorial state must be resolved.")


func _validate_legacy_state(
	equipment_catalog: EquipmentCatalog,
	mastery_catalog: MasteryCatalog,
	errors: PackedStringArray
) -> void:
	if equipment_catalog == null or mastery_catalog == null:
		return
	_validate_string_set("owned equipment", owned_equipment, errors)
	for item_id in owned_equipment:
		if equipment_catalog.get_item(StringName(item_id)) == null:
			errors.append("Legacy profile owns unknown equipment '%s'." % item_id)
	_validate_legacy_loadouts(equipment_catalog, errors)
	_validate_legacy_mastery(mastery_catalog, errors)


func _validate_legacy_loadouts(catalog: EquipmentCatalog, errors: PackedStringArray) -> void:
	for character_id in CHARACTER_IDS:
		var raw_loadout: Variant = loadouts.get(character_id, null)
		if not raw_loadout is Dictionary:
			errors.append("Legacy profile is missing the '%s' loadout." % character_id)
			continue
		var loadout: Dictionary = raw_loadout
		for slot_id in ALL_SLOTS:
			if not loadout.has(slot_id):
				errors.append("Legacy loadout '%s' is missing slot '%s'." % [character_id, slot_id])
				continue
			var item_id := String(loadout[slot_id])
			if item_id.is_empty():
				if slot_id in ["weapon", "armor"]:
					errors.append("Legacy loadout '%s' requires a %s." % [character_id, slot_id])
				continue
			if slot_id == "consumable":
				if not LEGACY_CONSUMABLE_IDS.has(item_id):
					errors.append("Legacy loadout '%s' has unknown consumable '%s'." % [character_id, item_id])
				continue
			var item := catalog.get_item(StringName(item_id))
			if item == null:
				errors.append("Legacy loadout '%s' references unknown item '%s'." % [character_id, item_id])
			elif not owned_equipment.has(item_id):
				errors.append("Legacy loadout '%s' equips unowned item '%s'." % [character_id, item_id])
			elif String(item.slot) != slot_id or not item.is_compatible(StringName(character_id)):
				errors.append("Legacy item '%s' is incompatible with %s %s." % [item_id, character_id, slot_id])


func _validate_legacy_mastery(catalog: MasteryCatalog, errors: PackedStringArray) -> void:
	for character_id in CHARACTER_IDS:
		var raw_nodes: Variant = mastery_unlocks.get(character_id, null)
		if not raw_nodes is Array:
			errors.append("Legacy profile is missing '%s' mastery state." % character_id)
			continue
		var node_ids := _to_string_array(raw_nodes)
		_validate_string_set("%s mastery" % character_id, node_ids, errors)
		for node_id in node_ids:
			var node := catalog.get_node(StringName(node_id))
			if node == null or String(node.character_id) != character_id:
				errors.append("Legacy profile has invalid %s mastery '%s'." % [character_id, node_id])
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


static func _dictionary_or_default(value: Variant, fallback: Dictionary) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else fallback.duplicate(true)


static func _integer_dictionary_or_default(value: Variant, fallback: Dictionary) -> Dictionary:
	if not value is Dictionary:
		return fallback.duplicate(true)
	var result: Dictionary = {}
	for key in value:
		var number: Variant = value[key]
		if (
			(number is int or number is float)
			and is_finite(float(number))
			and is_equal_approx(float(number), round(float(number)))
		):
			result[String(key)] = int(number)
		else:
			result[String(key)] = number
	return result


static func _material_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for material_id in value:
		var amount: Variant = value[material_id]
		if (
			(amount is int or amount is float)
			and is_finite(float(amount))
			and is_equal_approx(float(amount), round(float(amount)))
		):
			result[String(material_id)] = int(amount)
		else:
			result[String(material_id)] = amount
	return result
