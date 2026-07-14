class_name ProfileCommandService
extends RefCounted

const ProgressionService = preload(
	"res://scripts/progression/EquipmentProgressionService.gd"
)

var equipment_catalog: EquipmentCatalog
var mastery_catalog: MasteryCatalog
var progression_catalog: EquipmentProgressionCatalog


func _init(
	items: EquipmentCatalog = null,
	masteries: MasteryCatalog = null,
	progression: EquipmentProgressionCatalog = null
) -> void:
	equipment_catalog = items
	mastery_catalog = masteries
	progression_catalog = progression


func grant_material(data: ProfileData, material_id: String, amount: int) -> ProfileCommandResult:
	if data == null or not ProfileData.MATERIAL_IDS.has(material_id) or amount <= 0:
		return _rejected(&"invalid_material", "Material grant is invalid.")
	data.materials[material_id] = int(data.materials.get(material_id, 0)) + amount
	return _accepted(&"material_granted", "Material added.", {material_id: amount})


func spend_material(data: ProfileData, material_id: String, amount: int) -> ProfileCommandResult:
	if data == null or not ProfileData.MATERIAL_IDS.has(material_id) or amount <= 0:
		return _rejected(&"invalid_material", "Material spend is invalid.")
	if int(data.materials.get(material_id, 0)) < amount:
		return _rejected(&"insufficient_material", "Not enough %s." % _display_id(material_id))
	_spend_cost(data, {material_id: amount})
	return _accepted(&"material_spent", "Material spent.", {material_id: amount})


func unlock_blueprint(
	data: ProfileData,
	model_id: StringName,
	transaction_id: StringName
) -> ProfileCommandResult:
	if data == null or transaction_id == &"":
		return _rejected(&"invalid_transaction", "Blueprint unlock needs a transaction ID.")
	if _transaction_applied(data, transaction_id):
		return _duplicate(&"duplicate_transaction", "Blueprint reward was already settled.")
	var blueprint := (
		progression_catalog.get_blueprint_for_model(model_id)
		if progression_catalog != null
		else null
	)
	if blueprint == null:
		return _rejected(&"unknown_blueprint", "Blueprint is unavailable.")
	var model_key := String(model_id)
	var already_unlocked := data.unlocked_blueprints.has(model_key)
	if not already_unlocked:
		data.unlocked_blueprints.append(model_key)
		data.unlocked_blueprints.sort()
	_record_transaction(data, transaction_id)
	return ProfileCommandResult.new(
		true,
		true,
		&"blueprint_owned" if already_unlocked else &"blueprint_unlocked",
		"Blueprint already owned." if already_unlocked else "Blueprint unlocked.",
		{"model_id": model_key, "blueprint_id": String(blueprint.id)},
		already_unlocked
	)


func unlock_spirit_stone(
	data: ProfileData,
	stone_id: StringName,
	transaction_id: StringName
) -> ProfileCommandResult:
	if data == null or transaction_id == &"":
		return _rejected(&"invalid_transaction", "Spirit Stone unlock needs a transaction ID.")
	if _transaction_applied(data, transaction_id):
		return _duplicate(&"duplicate_transaction", "Spirit Stone reward was already settled.")
	var stone := (
		progression_catalog.get_spirit_stone(stone_id)
		if progression_catalog != null
		else null
	)
	if stone == null:
		return _rejected(&"unknown_spirit_stone", "Spirit Stone is unavailable.")
	var stone_key := String(stone_id)
	var already_unlocked := data.unlocked_spirit_stones.has(stone_key)
	if not already_unlocked:
		data.unlocked_spirit_stones.append(stone_key)
		data.unlocked_spirit_stones.sort()
	_record_transaction(data, transaction_id)
	return ProfileCommandResult.new(
		true,
		true,
		&"spirit_stone_owned" if already_unlocked else &"spirit_stone_unlocked",
		"Spirit Stone already owned." if already_unlocked else "Spirit Stone unlocked.",
		{"stone_id": stone_key},
		already_unlocked
	)


func settle_progression_reward(
	data: ProfileData,
	transaction_id: StringName,
	material_grants: Dictionary,
	blueprint_model_ids: Array[StringName],
	spirit_stone_ids: Array[StringName]
) -> ProfileCommandResult:
	if data == null or transaction_id == &"":
		return _rejected(&"invalid_transaction", "Progression reward needs a transaction ID.")
	if _transaction_applied(data, transaction_id):
		return _duplicate(&"duplicate_transaction", "Progression reward was already settled.")
	var validation_error := _validate_progression_reward(
		material_grants,
		blueprint_model_ids,
		spirit_stone_ids
	)
	if not validation_error.is_empty():
		return _rejected(&"invalid_progression_reward", validation_error)

	var blueprint_results: Array[Dictionary] = []
	for model_id in blueprint_model_ids:
		var model_key := String(model_id)
		var duplicate := data.unlocked_blueprints.has(model_key)
		if not duplicate:
			data.unlocked_blueprints.append(model_key)
		blueprint_results.append({"model_id": model_key, "duplicate": duplicate})
	data.unlocked_blueprints.sort()

	var spirit_results: Array[Dictionary] = []
	for stone_id in spirit_stone_ids:
		var stone_key := String(stone_id)
		var duplicate := data.unlocked_spirit_stones.has(stone_key)
		if not duplicate:
			data.unlocked_spirit_stones.append(stone_key)
		spirit_results.append({"stone_id": stone_key, "duplicate": duplicate})
	data.unlocked_spirit_stones.sort()
	_grant_cost(data, material_grants)
	_record_transaction(data, transaction_id)
	return _accepted(
		&"progression_reward_settled",
		"Progression reward settled.",
		{
			"materials": material_grants.duplicate(true),
			"blueprint_unlocks": blueprint_results,
			"spirit_stone_unlocks": spirit_results,
		}
	)


func craft_equipment(data: ProfileData, model_id: StringName) -> ProfileCommandResult:
	var preview := ProgressionService.preview_craft(progression_catalog, data, model_id)
	if not bool(preview.get("can_execute", false)):
		return _rejected(
			StringName(preview.get("code", &"craft_rejected")),
			String(preview.get("reason", "Equipment cannot be crafted."))
		)
	_spend_cost(data, preview["costs"])
	_store_crafted_state(data, model_id, preview["result_state"])
	return _accepted(
		&"equipment_crafted",
		"Equipment crafted.",
		_progression_payload(preview)
	)


func recraft_equipment(data: ProfileData, model_id: StringName) -> ProfileCommandResult:
	var preview := ProgressionService.preview_recraft(progression_catalog, data, model_id)
	if not bool(preview.get("can_execute", false)):
		return _rejected(
			StringName(preview.get("code", &"recraft_rejected")),
			String(preview.get("reason", "Equipment cannot be recrafted."))
		)
	_spend_cost(data, preview["costs"])
	_store_crafted_state(data, model_id, preview["result_state"])
	return _accepted(
		&"equipment_recrafted",
		"Equipment recrafted to Grade 2.",
		_progression_payload(preview)
	)


func repair_equipment(data: ProfileData, model_id: StringName) -> ProfileCommandResult:
	var preview := ProgressionService.preview_repair(progression_catalog, data, model_id)
	if not bool(preview.get("can_execute", false)):
		return _rejected(
			StringName(preview.get("code", &"repair_rejected")),
			String(preview.get("reason", "Equipment cannot be repaired."))
		)
	_spend_cost(data, preview["costs"])
	_store_crafted_state(data, model_id, preview["result_state"])
	return _accepted(
		&"equipment_repaired",
		"Equipment repaired.",
		_progression_payload(preview)
	)


func apply_stage_entry_maintenance(data: ProfileData) -> ProfileCommandResult:
	var preview := ProgressionService.preview_stage_entry_maintenance(
		progression_catalog,
		data
	)
	if not bool(preview.get("can_execute", false)):
		if preview.get("code") == ProgressionService.CODE_MAINTENANCE_NOT_REQUIRED:
			return ProfileCommandResult.new(
				true, false, &"maintenance_not_required", String(preview.get("reason", ""))
			)
		return _rejected(
			StringName(preview.get("code", &"maintenance_rejected")),
			String(preview.get("reason", "Equipment cannot be maintained."))
		)
	for raw_entry in preview.get("entries", []):
		if raw_entry is Dictionary and bool(raw_entry.get("can_execute", false)):
			_store_crafted_state(
				data,
				StringName(raw_entry.get("model_id", &"")),
				raw_entry["result_state"]
			)
	return _accepted(
		&"stage_entry_maintenance_applied",
		"Equipped melee and shield were maintained to at least 25%.",
		{"entries": preview.get("entries", []).duplicate(true)}
	)


func equip_hero_item(
	data: ProfileData,
	slot_id: StringName,
	item_id: StringName
) -> ProfileCommandResult:
	var slot_key := String(slot_id)
	var item_key := String(item_id)
	if data == null or not ProfileData.HERO_LOADOUT_SLOTS.has(slot_key):
		return _rejected(&"invalid_slot", "Hero equipment slot is unavailable.")
	if item_key.is_empty():
		return _rejected(&"required_slot", "Hero equipment slots cannot be empty.")
	if slot_key == "spirit_stone":
		if not data.unlocked_spirit_stones.has(item_key):
			return _rejected(&"spirit_stone_locked", "Spirit Stone is not unlocked.")
	elif slot_key == "consumable":
		if not ProfileData.CONSUMABLE_IDS.has(item_key):
			return _rejected(&"unknown_consumable", "Consumable is unavailable.")
	else:
		var model := (
			progression_catalog.get_model(item_id)
			if progression_catalog != null
			else null
		)
		if model == null:
			return _rejected(&"unknown_equipment", "Equipment model is unavailable.")
		if String(model.slot) != slot_key:
			return _rejected(&"incompatible_equipment", "Equipment does not fit this slot.")
		if not data.crafted_equipment.has(item_key):
			return _rejected(&"equipment_uncrafted", "Equipment has not been crafted.")
	if String(data.hero_loadout.get(slot_key, "")) == item_key:
		return ProfileCommandResult.new(true, false, &"already_equipped", "Hero loadout is unchanged.")
	data.hero_loadout[slot_key] = item_key
	return _accepted(
		&"hero_item_equipped",
		"Hero loadout updated.",
		{"slot": slot_key, "item_id": item_key}
	)


func grant_ranged_supply(
	data: ProfileData,
	supply_id: StringName,
	amount: int
) -> ProfileCommandResult:
	var supply_key := String(supply_id)
	if data == null or not ProfileData.RANGED_SUPPLY_LIMITS.has(supply_key) or amount <= 0:
		return _rejected(&"invalid_supply", "Ranged supply grant is invalid.")
	var current := int(data.ranged_supplies.get(supply_key, 0))
	var maximum := int(ProfileData.RANGED_SUPPLY_LIMITS[supply_key])
	var result := mini(current + amount, maximum)
	if result == current:
		return ProfileCommandResult.new(true, false, &"supply_full", "Ranged supply is already full.")
	data.ranged_supplies[supply_key] = result
	return _accepted(
		&"ranged_supply_granted",
		"Ranged supply added.",
		{"supply_id": supply_key, "amount": result - current, "current": result, "maximum": maximum}
	)


func spend_ranged_supply(
	data: ProfileData,
	supply_id: StringName,
	amount: int
) -> ProfileCommandResult:
	var supply_key := String(supply_id)
	if data == null or not ProfileData.RANGED_SUPPLY_LIMITS.has(supply_key) or amount <= 0:
		return _rejected(&"invalid_supply", "Ranged supply spend is invalid.")
	var current := int(data.ranged_supplies.get(supply_key, 0))
	if current < amount:
		return _rejected(&"insufficient_supply", "Not enough ranged supply.")
	data.ranged_supplies[supply_key] = current - amount
	return _accepted(
		&"ranged_supply_spent",
		"Ranged supply spent.",
		{"supply_id": supply_key, "amount": amount, "current": current - amount}
	)


func consume_equipment_condition(
	data: ProfileData,
	model_id: StringName,
	amount: float
) -> ProfileCommandResult:
	var model := (
		progression_catalog.get_model(model_id)
		if progression_catalog != null
		else null
	)
	if data == null or model == null or not model.has_condition or not is_finite(amount) or amount <= 0.0:
		return _rejected(&"invalid_condition_change", "Equipment condition change is invalid.")
	var model_key := String(model_id)
	var raw_state: Variant = data.crafted_equipment.get(model_key, null)
	if not raw_state is Dictionary:
		return _rejected(&"equipment_uncrafted", "Equipment has not been crafted.")
	var state: Dictionary = raw_state.duplicate(true)
	var current := float(state.get("condition", 0.0))
	var result := maxf(current - amount, 0.0)
	if is_equal_approx(result, current):
		return ProfileCommandResult.new(true, false, &"condition_depleted", "Equipment is already worn.")
	state["condition"] = result
	data.crafted_equipment[model_key] = state
	return _accepted(
		&"equipment_condition_consumed",
		"Equipment condition reduced.",
		{"model_id": model_key, "before": current, "after": result}
	)


func resolve_tutorial(
	data: ProfileData,
	completed: bool,
	transaction_id: StringName
) -> ProfileCommandResult:
	if data == null or transaction_id == &"":
		return _rejected(&"invalid_transaction", "Tutorial resolution needs a transaction ID.")
	if _transaction_applied(data, transaction_id):
		return _duplicate(&"duplicate_transaction", "Tutorial result was already settled.")
	if bool(data.tutorial_state.get("resolved", false)):
		return _rejected(&"tutorial_resolved", "Tutorial choice is already resolved.")
	data.tutorial_state = {
		"resolved": true,
		"completed": completed,
		"skipped": not completed,
	}
	_record_transaction(data, transaction_id)
	return _accepted(
		&"tutorial_completed" if completed else &"tutorial_skipped",
		"Tutorial completed." if completed else "Tutorial skipped.",
		{"completed": completed}
	)


func discover_equipment(
	data: ProfileData,
	item_id: StringName,
	transaction_id: StringName
) -> ProfileCommandResult:
	if data == null or transaction_id == &"":
		return _rejected(&"invalid_transaction", "Equipment discovery needs a transaction ID.")
	if data.applied_profile_transactions.has(String(transaction_id)):
		return ProfileCommandResult.new(
			true, false, &"duplicate_transaction", "Discovery was already settled.", {}, true
		)
	var item := equipment_catalog.get_item(item_id) if equipment_catalog != null else null
	if item == null:
		return _rejected(&"unknown_equipment", "Equipment is unavailable.")

	var payload := {"item_id": String(item_id), "salvage": {}}
	if data.owned_equipment.has(String(item_id)):
		var salvage: Dictionary = item.salvage_materials.duplicate(true)
		_grant_cost(data, salvage)
		payload["salvage"] = salvage
	else:
		data.owned_equipment.append(String(item_id))
		data.owned_equipment.sort()
	data.applied_profile_transactions.append(String(transaction_id))
	data.applied_profile_transactions.sort()
	return _accepted(&"equipment_discovered", "Equipment discovery settled.", payload)


func purchase_equipment(data: ProfileData, item_id: StringName) -> ProfileCommandResult:
	var item := equipment_catalog.get_item(item_id) if equipment_catalog != null else null
	if data == null or item == null:
		return _rejected(&"unknown_equipment", "Equipment is unavailable.")
	if data.owned_equipment.has(String(item_id)):
		return _rejected(&"already_owned", "Equipment is already owned.")
	var costs: Dictionary = item.unlock_costs
	if costs.is_empty():
		return _rejected(&"not_purchasable", "This equipment is found during a run.")
	var shortage := _first_shortage(data, costs)
	if not shortage.is_empty():
		return _rejected(&"insufficient_material", shortage)
	_spend_cost(data, costs)
	data.owned_equipment.append(String(item_id))
	data.owned_equipment.sort()
	return _accepted(
		&"equipment_unlocked",
		"Equipment unlocked.",
		{"item_id": String(item_id), "costs": costs.duplicate(true)}
	)


func equip_item(
	data: ProfileData,
	character_id: StringName,
	slot_id: StringName,
	item_id: StringName
) -> ProfileCommandResult:
	var character_key := String(character_id)
	var slot_key := String(slot_id)
	var item_key := String(item_id)
	if data == null or not ProfileData.CHARACTER_IDS.has(character_key):
		return _rejected(&"invalid_character", "Character is unavailable.")
	if not ProfileData.ALL_SLOTS.has(slot_key):
		return _rejected(&"invalid_slot", "Loadout slot is unavailable.")
	if item_key.is_empty():
		if slot_key in ["weapon", "armor"]:
			return _rejected(&"required_slot", "%s cannot be empty." % slot_key.capitalize())
	else:
		if slot_key == "consumable":
			if not ProfileData.CONSUMABLE_IDS.has(item_key):
				return _rejected(&"unknown_consumable", "Consumable is unavailable.")
		else:
			var item := equipment_catalog.get_item(item_id) if equipment_catalog != null else null
			if item == null:
				return _rejected(&"unknown_equipment", "Equipment is unavailable.")
			if not data.owned_equipment.has(item_key):
				return _rejected(&"equipment_locked", "Equipment is not owned.")
			if String(item.slot) != slot_key or not item.is_compatible(character_id):
				return _rejected(&"incompatible_equipment", "Equipment does not fit this loadout.")

	var loadout: Dictionary = data.loadouts.get(character_key, {}).duplicate(true)
	if String(loadout.get(slot_key, "")) == item_key:
		return ProfileCommandResult.new(true, false, &"already_equipped", "Loadout is unchanged.")
	loadout[slot_key] = item_key
	data.loadouts[character_key] = loadout
	return _accepted(
		&"item_equipped",
		"Loadout updated.",
		{"character_id": character_key, "slot": slot_key, "item_id": item_key}
	)


func purchase_mastery(
	data: ProfileData,
	character_id: StringName,
	node_id: StringName
) -> ProfileCommandResult:
	var character_key := String(character_id)
	var node := mastery_catalog.get_node(node_id) if mastery_catalog != null else null
	if data == null or node == null or String(node.character_id) != character_key:
		return _rejected(&"invalid_mastery", "Mastery node is unavailable.")
	var unlocked := _mastery_ids(data, character_key)
	if unlocked.has(String(node_id)):
		return _rejected(&"mastery_owned", "Mastery is already purchased.")
	for required_id in node.requires_all:
		if not unlocked.has(String(required_id)):
			return _rejected(&"missing_prerequisite", "A required mastery is missing.")
	if not node.requires_any.is_empty():
		var has_any := false
		for required_id in node.requires_any:
			has_any = has_any or unlocked.has(String(required_id))
		if not has_any:
			return _rejected(&"missing_prerequisite", "A branch prerequisite is missing.")
	var costs: Dictionary = node.costs
	var shortage := _first_shortage(data, costs)
	if not shortage.is_empty():
		return _rejected(&"insufficient_material", shortage)
	_spend_cost(data, costs)
	unlocked.append(String(node_id))
	unlocked.sort()
	data.mastery_unlocks[character_key] = unlocked
	return _accepted(
		&"mastery_purchased",
		"Mastery purchased.",
		{"character_id": character_key, "node_id": String(node_id), "costs": costs.duplicate(true)}
	)


func respec_character(data: ProfileData, character_id: StringName) -> ProfileCommandResult:
	var character_key := String(character_id)
	if data == null or not ProfileData.CHARACTER_IDS.has(character_key):
		return _rejected(&"invalid_character", "Character is unavailable.")
	var unlocked := _mastery_ids(data, character_key)
	if unlocked.is_empty():
		return ProfileCommandResult.new(true, false, &"nothing_to_respec", "No mastery is purchased.")
	var refunds: Dictionary = {}
	for node_id in unlocked:
		var node := mastery_catalog.get_node(StringName(node_id)) if mastery_catalog != null else null
		if node == null:
			return _rejected(&"invalid_mastery_state", "Mastery state cannot be refunded safely.")
		for material_id in node.costs:
			refunds[material_id] = int(refunds.get(material_id, 0)) + int(node.costs[material_id])
	_grant_cost(data, refunds)
	data.mastery_unlocks[character_key] = []
	return _accepted(
		&"mastery_respec",
		"Mastery reset.",
		{"character_id": character_key, "refunds": refunds}
	)


func unlock_content(data: ProfileData, content_id: StringName) -> ProfileCommandResult:
	var content_key := String(content_id)
	if data == null or content_key.is_empty():
		return _rejected(&"invalid_content", "Content unlock is invalid.")
	if data.durable_unlocks.has(content_key):
		return ProfileCommandResult.new(true, false, &"content_owned", "Content is already unlocked.")
	data.durable_unlocks.append(content_key)
	data.durable_unlocks.sort()
	return _accepted(&"content_unlocked", "Content unlocked.", {"content_id": content_key})


func _mastery_ids(data: ProfileData, character_id: String) -> Array[String]:
	var ids: Array[String] = []
	var raw_ids: Variant = data.mastery_unlocks.get(character_id, [])
	if raw_ids is Array:
		for node_id in raw_ids:
			ids.append(String(node_id))
	return ids


func _validate_progression_reward(
	material_grants: Dictionary,
	blueprint_model_ids: Array[StringName],
	spirit_stone_ids: Array[StringName]
) -> String:
	for raw_material_id in material_grants:
		var material_id := String(raw_material_id)
		var amount: Variant = material_grants[raw_material_id]
		if (
			not ProfileData.MATERIAL_IDS.has(material_id)
			or not amount is int
			or int(amount) <= 0
		):
			return "Progression reward contains an invalid material grant."
	var seen_blueprints: Dictionary = {}
	for model_id in blueprint_model_ids:
		if (
			model_id == &""
			or seen_blueprints.has(model_id)
			or progression_catalog == null
			or progression_catalog.get_blueprint_for_model(model_id) == null
		):
			return "Progression reward contains an invalid blueprint unlock."
		seen_blueprints[model_id] = true
	var seen_stones: Dictionary = {}
	for stone_id in spirit_stone_ids:
		if (
			stone_id == &""
			or seen_stones.has(stone_id)
			or progression_catalog == null
			or progression_catalog.get_spirit_stone(stone_id) == null
		):
			return "Progression reward contains an invalid Spirit Stone unlock."
		seen_stones[stone_id] = true
	return ""


func _first_shortage(data: ProfileData, costs: Dictionary) -> String:
	var material_ids := costs.keys()
	material_ids.sort()
	for material_id in material_ids:
		var required := int(costs[material_id])
		var available := int(data.materials.get(String(material_id), 0))
		if available < required:
			return "Need %d more %s." % [required - available, _display_id(String(material_id))]
	return ""


func _spend_cost(data: ProfileData, costs: Dictionary) -> void:
	for material_id in costs:
		var remaining := int(data.materials.get(String(material_id), 0)) - int(costs[material_id])
		if remaining <= 0:
			data.materials.erase(String(material_id))
		else:
			data.materials[String(material_id)] = remaining


func _grant_cost(data: ProfileData, grants: Dictionary) -> void:
	for material_id in grants:
		data.materials[String(material_id)] = (
			int(data.materials.get(String(material_id), 0)) + int(grants[material_id])
		)


func _store_crafted_state(
	data: ProfileData,
	model_id: StringName,
	resolved_state: Dictionary
) -> void:
	data.crafted_equipment[String(model_id)] = {
		"grade_id": String(resolved_state.get("grade_id", "grade_1")),
		"condition": float(resolved_state.get("condition", 0.0)),
	}


func _progression_payload(preview: Dictionary) -> Dictionary:
	return {
		"action": String(preview.get("action", "")),
		"model_id": String(preview.get("model_id", "")),
		"costs": preview.get("costs", {}).duplicate(true),
		"current_state": preview.get("current_state", {}).duplicate(true),
		"result_state": preview.get("result_state", {}).duplicate(true),
	}


func _transaction_applied(data: ProfileData, transaction_id: StringName) -> bool:
	return data.applied_profile_transactions.has(String(transaction_id))


func _record_transaction(data: ProfileData, transaction_id: StringName) -> void:
	var transaction_key := String(transaction_id)
	if not data.applied_profile_transactions.has(transaction_key):
		data.applied_profile_transactions.append(transaction_key)
		data.applied_profile_transactions.sort()


func _display_id(value: String) -> String:
	return value.replace("_", " ")


func _accepted(
	code: StringName,
	message: String,
	payload: Dictionary = {}
) -> ProfileCommandResult:
	return ProfileCommandResult.new(true, true, code, message, payload)


func _rejected(code: StringName, message: String) -> ProfileCommandResult:
	return ProfileCommandResult.new(false, false, code, message)


func _duplicate(code: StringName, message: String) -> ProfileCommandResult:
	return ProfileCommandResult.new(true, false, code, message, {}, true)
