class_name ProfileCommandService
extends RefCounted

var equipment_catalog: EquipmentCatalog
var mastery_catalog: MasteryCatalog


func _init(
	items: EquipmentCatalog = null,
	masteries: MasteryCatalog = null
) -> void:
	equipment_catalog = items
	mastery_catalog = masteries


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
