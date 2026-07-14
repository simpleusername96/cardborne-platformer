extends Node

# Owns profile facts and commands; storage details remain behind ProfileSaveService.
const RuntimeResolver = preload(
	"res://scripts/progression/EquipmentRuntimeResolver.gd"
)
const ProgressionService = preload(
	"res://scripts/progression/EquipmentProgressionService.gd"
)
const HeroLoadoutResolver = preload(
	"res://scripts/player/HeroCombatLoadoutResolver.gd"
)
const HERO_DEFINITION := preload("res://data/hero/traveler.tres")

signal profile_changed(section: StringName)
signal setting_changed(setting_id: StringName, value: Variant)
signal persistence_failed(message: String)

const EQUIPMENT_CATALOG_PATH := "res://data/equipment/equipment_catalog.tres"
const MASTERY_CATALOG_PATH := "res://data/mastery/mastery_catalog.tres"
const PROGRESSION_CATALOG_PATH := \
	"res://data/equipment/equipment_progression_catalog.tres"

var equipment_catalog: EquipmentCatalog
var mastery_catalog: MasteryCatalog
var progression_catalog: EquipmentProgressionCatalog

var _data: ProfileData
var _commands: ProfileCommandService
var _save_service: ProfileSaveService


func _ready() -> void:
	load_or_create_profile()


func load_or_create_profile(profile_path: String = ProfileSaveService.DEFAULT_PRIMARY_PATH) -> bool:
	if not _load_catalogs():
		return false
	_save_service = ProfileSaveService.new(
		equipment_catalog,
		mastery_catalog,
		profile_path,
		progression_catalog
	)
	_commands = ProfileCommandService.new(
		equipment_catalog,
		mastery_catalog,
		progression_catalog
	)
	var result := _save_service.load_or_create()
	if not bool(result.get("ok", false)) or not result.get("data") is ProfileData:
		push_error("Unable to initialize persistent profile state.")
		return false
	_data = result["data"]
	if not bool(result.get("persisted", true)):
		persistence_failed.emit("Profile is active in memory but could not be saved.")
	profile_changed.emit(&"all")
	return true


func initialize_for_tests(
	items: EquipmentCatalog,
	masteries: MasteryCatalog,
	profile_path: String = "",
	load_existing: bool = false,
	progression: EquipmentProgressionCatalog = null
) -> void:
	equipment_catalog = items
	mastery_catalog = masteries
	progression_catalog = progression
	_commands = ProfileCommandService.new(
		equipment_catalog,
		mastery_catalog,
		progression_catalog
	)
	_data = ProfileData.new()
	_save_service = null
	if not profile_path.is_empty():
		_save_service = ProfileSaveService.new(
			equipment_catalog,
			mastery_catalog,
			profile_path,
			progression_catalog
		)
		if load_existing:
			var result := _save_service.load_or_create()
			if bool(result.get("ok", false)) and result.get("data") is ProfileData:
				_data = result["data"]


func save_profile() -> Dictionary:
	_ensure_initialized()
	if _save_service == null:
		return {"ok": true, "message": "Profile is in-memory only."}
	var result := _save_service.save(_data)
	if not bool(result.get("ok", false)):
		var message := String(result.get("message", "Profile save failed."))
		persistence_failed.emit(message)
		push_warning(message)
	return result


func reset_to_defaults() -> void:
	_ensure_initialized()
	var candidate := ProfileData.new()
	if not _persist_candidate(candidate):
		persistence_failed.emit("Default profile could not be persisted.")
		return
	_data = candidate
	profile_changed.emit(&"all")


func get_profile_snapshot() -> Dictionary:
	_ensure_initialized()
	return _data.to_dictionary()


func get_materials() -> Dictionary:
	_ensure_initialized()
	return _data.materials.duplicate(true)


func get_material_count(material_id: String) -> int:
	_ensure_initialized()
	return int(_data.materials.get(material_id, 0))


func grant_material(material_id: String, amount: int) -> bool:
	return bool(grant_material_command(material_id, amount).get("ok", false))


func grant_material_command(material_id: String, amount: int) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.grant_material(candidate, material_id, amount),
		&"materials"
	)


func spend_material(material_id: String, amount: int) -> bool:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return bool(_commit_candidate(
		candidate,
		_commands.spend_material(candidate, material_id, amount),
		&"materials"
	).get("ok", false))


func get_hero_loadout() -> Dictionary:
	_ensure_initialized()
	return _data.hero_loadout.duplicate(true)


func get_crafted_equipment() -> Dictionary:
	_ensure_initialized()
	return _data.crafted_equipment.duplicate(true)


func get_ranged_supplies() -> Dictionary:
	_ensure_initialized()
	return _data.ranged_supplies.duplicate(true)


func get_tutorial_state() -> Dictionary:
	_ensure_initialized()
	return _data.tutorial_state.duplicate(true)


func unlock_blueprint(
	model_id: StringName,
	transaction_id: StringName
) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.unlock_blueprint(candidate, model_id, transaction_id),
		&"blueprints"
	)


func unlock_spirit_stone(
	stone_id: StringName,
	transaction_id: StringName
) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.unlock_spirit_stone(candidate, stone_id, transaction_id),
		&"spirit_stones"
	)


func settle_progression_reward(
	transaction_id: StringName,
	material_grants: Dictionary,
	blueprint_model_ids: Array[StringName],
	spirit_stone_ids: Array[StringName]
) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.settle_progression_reward(
			candidate,
			transaction_id,
			material_grants,
			blueprint_model_ids,
			spirit_stone_ids
		),
		&"progression_reward"
	)


func craft_equipment(model_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.craft_equipment(candidate, model_id),
		&"equipment"
	)


func recraft_equipment(model_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.recraft_equipment(candidate, model_id),
		&"equipment"
	)


func repair_equipment(model_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.repair_equipment(candidate, model_id),
		&"equipment"
	)


func equip_hero_item(slot_id: StringName, item_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.equip_hero_item(candidate, slot_id, item_id),
		&"hero_loadout"
	)


func apply_stage_entry_maintenance() -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.apply_stage_entry_maintenance(candidate),
		&"equipment"
	)


func grant_ranged_supply(supply_id: StringName, amount: int) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.grant_ranged_supply(candidate, supply_id, amount),
		&"ranged_supplies"
	)


func spend_ranged_supply(supply_id: StringName, amount: int = 1) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.spend_ranged_supply(candidate, supply_id, amount),
		&"ranged_supplies"
	)


func consume_equipment_condition(
	model_id: StringName,
	amount: float = 1.0
) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.consume_equipment_condition(candidate, model_id, amount),
		&"equipment"
	)


func resolve_tutorial(completed: bool, transaction_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.resolve_tutorial(candidate, completed, transaction_id),
		&"tutorial"
	)


func get_equipment_decision_snapshot(model_id: StringName) -> Dictionary:
	_ensure_initialized()
	var model := progression_catalog.get_model(model_id) if progression_catalog != null else null
	if model == null:
		return {"ok": false, "code": "missing_model", "message": "Equipment is unavailable."}
	var crafted_state: Dictionary = _data.crafted_equipment.get(String(model_id), {}).duplicate(true)
	var current_runtime := (
		RuntimeResolver.resolve(model, crafted_state)
		if not crafted_state.is_empty()
		else {}
	)
	var craft := _with_runtime_preview(
		model,
		ProgressionService.preview_craft(progression_catalog, _data, model_id),
		current_runtime
	)
	var recraft := _with_runtime_preview(
		model,
		ProgressionService.preview_recraft(progression_catalog, _data, model_id),
		current_runtime
	)
	var repair := _with_runtime_preview(
		model,
		ProgressionService.preview_repair(progression_catalog, _data, model_id),
		current_runtime
	)
	return {
		"ok": true,
		"model_id": String(model.id),
		"display_name": model.display_name,
		"slot": String(model.slot),
		"behavior": model.behavior_description,
		"weakness": model.weakness_description,
		"blueprint_unlocked": _data.unlocked_blueprints.has(String(model_id)),
		"crafted": not crafted_state.is_empty(),
		"equipped": String(_data.hero_loadout.get(String(model.slot), "")) == String(model_id),
		"runtime": current_runtime,
		"craft": craft,
		"recraft": recraft,
		"repair": repair,
	}


func _with_runtime_preview(
	model: EquipmentModelDefinition,
	preview: Dictionary,
	current_runtime: Dictionary
) -> Dictionary:
	var result := preview.duplicate(true)
	result["current_runtime"] = current_runtime.duplicate(true)
	var result_state: Variant = result.get("result_state", {})
	result["result_runtime"] = (
		RuntimeResolver.resolve(model, result_state)
		if result_state is Dictionary and bool(result_state.get("owned", false))
		else {}
	)
	return result


func get_preparation_snapshot() -> Dictionary:
	_ensure_initialized()
	var slots: Array[Dictionary] = []
	for slot_id in ["melee", "ranged", "shield", "armor"]:
		var options: Array[Dictionary] = []
		for model in progression_catalog.models:
			if model != null and String(model.slot) == slot_id:
				options.append(get_equipment_decision_snapshot(model.id))
		slots.append({
			"slot": slot_id,
			"equipped_id": String(_data.hero_loadout.get(slot_id, "")),
			"options": options,
		})
	var stones: Array[Dictionary] = []
	for stone in progression_catalog.spirit_stones:
		if stone != null:
			stones.append({
				"id": String(stone.id),
				"display_name": stone.display_name,
				"description": stone.passive_description,
				"weakness": stone.weakness_description,
				"unlocked": _data.unlocked_spirit_stones.has(String(stone.id)),
				"equipped": String(_data.hero_loadout.get("spirit_stone", "")) == String(stone.id),
			})
	return {
		"hero_id": _data.hero_id,
		"materials": _data.materials.duplicate(true),
		"ranged_supplies": _data.ranged_supplies.duplicate(true),
		"tutorial": _data.tutorial_state.duplicate(true),
		"loadout": _data.hero_loadout.duplicate(true),
		"slots": slots,
		"spirit_stones": stones,
	}


func get_hero_combat_snapshot() -> Dictionary:
	_ensure_initialized()
	return HeroLoadoutResolver.resolve(
		HERO_DEFINITION,
		_data,
		progression_catalog
	)


# Compatibility facade for v1 migration fixtures; production uses the Traveler APIs above.
func get_owned_equipment() -> Array[String]:
	_ensure_initialized()
	return _data.owned_equipment.duplicate()


func owns_equipment(item_id: String) -> bool:
	_ensure_initialized()
	return _data.owned_equipment.has(item_id)


func has_equipment_definition(item_id: StringName) -> bool:
	_ensure_initialized()
	return equipment_catalog != null and equipment_catalog.has_item(item_id)


func discover_equipment(item_id: StringName, transaction_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.discover_equipment(candidate, item_id, transaction_id),
		&"equipment"
	)


func purchase_equipment(item_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.purchase_equipment(candidate, item_id),
		&"equipment"
	)


func grant_equipment(item_id: String) -> bool:
	var transaction_id := StringName("manual_equipment:%s" % item_id)
	var result := discover_equipment(StringName(item_id), transaction_id)
	return bool(result.get("ok", false)) and not bool(result.get("duplicate", false))


func get_loadout(character_id: String = "warrior") -> Dictionary:
	_ensure_initialized()
	var raw_loadout: Variant = _data.loadouts.get(character_id, {})
	return raw_loadout.duplicate(true) if raw_loadout is Dictionary else {}


func equip_item(
	character_id: StringName,
	slot_id: StringName,
	item_id: StringName
) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.equip_item(candidate, character_id, slot_id, item_id),
		&"loadout"
	)


func set_loadout_item(slot_id: String, item_id: String, character_id: String = "warrior") -> bool:
	return bool(equip_item(
		StringName(character_id), StringName(slot_id), StringName(item_id)
	).get("ok", false))


func purchase_mastery(character_id: StringName, node_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.purchase_mastery(candidate, character_id, node_id),
		&"mastery"
	)


func respec_character(character_id: StringName) -> Dictionary:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return _commit_candidate(
		candidate,
		_commands.respec_character(candidate, character_id),
		&"mastery"
	)


func has_mastery(character_id: String, node_id: String) -> bool:
	return get_mastery_unlocks(character_id).has(node_id)


func get_mastery_unlocks(character_id: String) -> Array[String]:
	_ensure_initialized()
	var values: Array[String] = []
	var raw_values: Variant = _data.mastery_unlocks.get(character_id, [])
	if raw_values is Array:
		for value in raw_values:
			values.append(String(value))
	values.sort()
	return values


func unlock_content(content_id: String) -> bool:
	_ensure_initialized()
	var candidate := _data.duplicate_data()
	return bool(_commit_candidate(
		candidate,
		_commands.unlock_content(candidate, StringName(content_id)),
		&"unlocks"
	).get("ok", false))


func has_content_unlock(content_id: String) -> bool:
	_ensure_initialized()
	return _data.durable_unlocks.has(content_id)


func get_durable_unlocks() -> Array[String]:
	_ensure_initialized()
	return _data.durable_unlocks.duplicate()


func get_build_effects(character_id: StringName) -> Array:
	_ensure_initialized()
	return _get_build_effects_for_loadout(
		character_id,
		get_loadout(String(character_id))
	)


func _get_build_effects_for_loadout(character_id: StringName, loadout: Dictionary) -> Array:
	var effects: Array = []
	for slot_id in ProfileData.PERSISTENT_SLOTS:
		var item_id := StringName(loadout.get(slot_id, ""))
		var item := equipment_catalog.get_item(item_id) if equipment_catalog != null else null
		if (
			item == null
			or not item.is_compatible(character_id)
			or item.slot != StringName(slot_id)
		):
			continue
		for effect in item.build_effects:
			effects.append(effect)
	return effects


func get_behavior_effects(character_id: StringName) -> Array[ProgressionBehaviorEffect]:
	_ensure_initialized()
	var effects: Array[ProgressionBehaviorEffect] = []
	var loadout := get_loadout(String(character_id))
	for slot_id in ProfileData.PERSISTENT_SLOTS:
		var item := equipment_catalog.get_item(StringName(loadout.get(slot_id, "")))
		if item != null:
			for effect in item.behavior_effects:
				effects.append(effect)
	for node_id in get_mastery_unlocks(String(character_id)):
		var node := mastery_catalog.get_node(StringName(node_id)) if mastery_catalog != null else null
		if node != null:
			for effect in node.behavior_effects:
				effects.append(effect)
	return effects


func preview_build(profile: CharacterProfile) -> PlayerBuildSnapshot:
	if profile == null:
		return PlayerBuildSnapshot.new({}, {}, [{"code": "missing_profile", "message": "Profile is missing."}])
	return PlayerBuild.resolve(profile.to_base_stats_dictionary(), get_build_effects(StringName(profile.id)))


func get_character_loadout_snapshot(profile: CharacterProfile) -> Dictionary:
	_ensure_initialized()
	if profile == null:
		return {"ok": false, "message": "Character is unavailable."}
	var character_id := StringName(profile.id)
	var loadout := get_loadout(profile.id)
	var build := preview_build(profile)
	var current_values := build.get_values()
	var slot_rows: Array[Dictionary] = []
	for slot_id in ProfileData.PERSISTENT_SLOTS:
		var options: Array[Dictionary] = []
		for item in equipment_catalog.get_compatible(character_id):
			if String(item.slot) != slot_id:
				continue
			var candidate_loadout := loadout.duplicate(true)
			candidate_loadout[slot_id] = String(item.id)
			var candidate_build := PlayerBuild.resolve(
				profile.to_base_stats_dictionary(),
				_get_build_effects_for_loadout(character_id, candidate_loadout)
			)
			options.append({
				"id": String(item.id),
				"display_name": item.display_name,
				"description": item.mechanical_description,
				"tradeoff": item.tradeoff_description,
				"owned": owns_equipment(String(item.id)),
				"equipped": String(loadout.get(slot_id, "")) == String(item.id),
				"unlock_costs": item.unlock_costs.duplicate(true),
				"projected_stats": candidate_build.get_values(),
				"stat_deltas": BuildComparison.stat_deltas(
					current_values,
					candidate_build.get_values()
				),
				"validation_errors": candidate_build.get_validation_errors(),
			})
		slot_rows.append({
			"slot": slot_id,
			"equipped_id": String(loadout.get(slot_id, "")),
			"options": options,
		})

	var mastery_rows: Array[Dictionary] = []
	var unlocked := get_mastery_unlocks(profile.id)
	for node in mastery_catalog.get_for_character(character_id):
		mastery_rows.append({
			"id": String(node.id),
			"display_name": node.display_name,
			"description": node.mechanical_description,
			"depth": String(node.depth),
			"requires_all": _names_to_strings(node.requires_all),
			"requires_any": _names_to_strings(node.requires_any),
			"costs": node.costs.duplicate(true),
			"purchased": unlocked.has(String(node.id)),
			"affordable": _can_afford(node.costs),
		})
	return {
		"ok": build.is_valid(),
		"character_id": profile.id,
		"materials": get_materials(),
		"loadout": loadout,
		"base_stats": profile.to_base_stats_dictionary(),
		"slots": slot_rows,
		"mastery": mastery_rows,
		"effective_stats": build.get_values(),
		"source_breakdown": build.get_source_breakdown(),
		"validation_errors": build.get_validation_errors(),
	}


func get_settings() -> Dictionary:
	_ensure_initialized()
	return _data.settings.duplicate(true)


func get_setting(setting_id: String, fallback: Variant = null) -> Variant:
	_ensure_initialized()
	return _data.settings.get(setting_id, fallback)


func set_setting(setting_id: String, value: Variant) -> bool:
	_ensure_initialized()
	if not _data.settings.has(setting_id) or not _is_valid_setting_value(setting_id, value):
		return false
	var normalized_value: Variant = float(value) if setting_id.ends_with("_volume") else value
	if _data.settings[setting_id] == normalized_value:
		return true
	var candidate := _data.duplicate_data()
	candidate.settings[setting_id] = normalized_value
	if not _persist_candidate(candidate):
		return false
	_data = candidate
	setting_changed.emit(StringName(setting_id), normalized_value)
	profile_changed.emit(&"settings")
	return true


func _commit_candidate(
	candidate: ProfileData,
	result: ProfileCommandResult,
	section: StringName
) -> Dictionary:
	var response := result.to_dictionary()
	if not result.ok:
		response["snapshot"] = get_profile_snapshot()
		response["persisted"] = true
		return response
	if result.changed:
		if not _persist_candidate(candidate):
			response["ok"] = false
			response["changed"] = false
			response["code"] = "persistence_failed"
			response["message"] = "Profile change could not be saved."
			response["persisted"] = false
			response["snapshot"] = get_profile_snapshot()
			return response
		_data = candidate
		profile_changed.emit(section)
	response["persisted"] = true
	response["snapshot"] = get_profile_snapshot()
	return response


func _persist_candidate(candidate: ProfileData) -> bool:
	if _save_service == null:
		return true
	var result := _save_service.save(candidate)
	if bool(result.get("ok", false)):
		return true
	var message := String(result.get("message", "Profile save failed."))
	persistence_failed.emit(message)
	push_warning(message)
	return false


func _load_catalogs() -> bool:
	var loaded_items := load(EQUIPMENT_CATALOG_PATH)
	var loaded_masteries := load(MASTERY_CATALOG_PATH)
	var loaded_progression := load(PROGRESSION_CATALOG_PATH)
	if (
		not loaded_items is EquipmentCatalog
		or not loaded_masteries is MasteryCatalog
		or not loaded_progression is EquipmentProgressionCatalog
	):
		push_error("Unable to load profile progression catalogs.")
		return false
	equipment_catalog = loaded_items
	mastery_catalog = loaded_masteries
	progression_catalog = loaded_progression
	var errors := PackedStringArray()
	errors.append_array(equipment_catalog.validate_catalog())
	errors.append_array(mastery_catalog.validate_catalog())
	errors.append_array(progression_catalog.validate_catalog())
	for error in errors:
		push_error("Invalid profile progression catalog: %s" % error)
	return errors.is_empty()


func _ensure_initialized() -> void:
	if _data != null and _commands != null:
		return
	if equipment_catalog == null or mastery_catalog == null:
		_load_catalogs()
	_data = ProfileData.new()
	_commands = ProfileCommandService.new(
		equipment_catalog,
		mastery_catalog,
		progression_catalog
	)


func _can_afford(costs: Dictionary) -> bool:
	for material_id in costs:
		if get_material_count(String(material_id)) < int(costs[material_id]):
			return false
	return true


func _names_to_strings(values: Array[StringName]) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(String(value))
	return strings


func _is_valid_setting_value(setting_id: String, value: Variant) -> bool:
	if setting_id.ends_with("_volume"):
		if not (value is float or value is int):
			return false
		var numeric_value := float(value)
		return is_finite(numeric_value) and numeric_value >= 0.0 and numeric_value <= 1.0
	return value is bool
