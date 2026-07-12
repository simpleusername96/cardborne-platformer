class_name TreasureChoiceService
extends RefCounted

const NORMAL_CHOICE_ID := &"normal_reward"
const REPLACEMENT_CHOICE_ID := &"treasure_replacement"
const SUPPORTED_POOL := &"compatible_equipment_or_forge"


static func build_choice(
	normal_transaction: RewardTransaction,
	context: Dictionary,
	card: CardDefinition,
	effect: CardEffectDefinition,
	equipment_catalog: EquipmentCatalog,
	forge_catalog: ForgeCatalog,
	loadout: Dictionary,
	temporary_affixes: Dictionary,
	run_seed: int,
	stage_index: int
) -> Dictionary:
	if normal_transaction == null or normal_transaction.id == &"":
		return _failure("The chest reward transaction is unavailable.")
	if (
		card == null
		or card.trigger != &"optional_route_chest_claimed"
		or effect == null
		or effect.effect_type != &"request_reward_preview_replacement"
		or effect.reward_pool != SUPPORTED_POOL
		or effect.choice_count != 1
	):
		return _failure("Treasure Instinct has an invalid replacement contract.")
	if not bool(context.get("optional_route", false)):
		return _failure("Treasure Instinct requires an optional-route chest.")

	var replacement := _equipment_replacement(
		normal_transaction,
		context,
		equipment_catalog,
		run_seed,
		stage_index
	)
	if replacement.is_empty():
		replacement = _forge_replacement(
			normal_transaction,
			equipment_catalog,
			forge_catalog,
			loadout,
			temporary_affixes,
			run_seed,
			stage_index
		)
	if replacement.is_empty():
		return _failure("No compatible equipment or forge replacement is available.")

	# Both options keep the chest transaction ID, so the reward ledger can commit only one.
	var request_id := StringName(context.get("request_id", normal_transaction.id))
	var snapshot := {
		"request_id": request_id,
		"card_id": card.id,
		"title": card.display_name,
		"instruction": "Choose one reward. The other is discarded.",
		"options": [
			{
				"id": NORMAL_CHOICE_ID,
				"label": "KEEP CACHE",
				"title": "Resolved Chest Reward",
				"description": _normal_description(
					normal_transaction,
					equipment_catalog,
					context
				),
				"kind": &"normal",
			},
			replacement["option"],
		],
	}
	return {
		"ok": true,
		"request_id": request_id,
		"normal_transaction": normal_transaction,
		"replacement_transaction": replacement["transaction"],
		"replacement_kind": replacement["kind"],
		"replacement_payload": replacement["payload"],
		"snapshot": snapshot,
	}


static func _equipment_replacement(
	normal_transaction: RewardTransaction,
	context: Dictionary,
	equipment_catalog: EquipmentCatalog,
	run_seed: int,
	stage_index: int
) -> Dictionary:
	if equipment_catalog == null:
		return {}
	var excluded: Dictionary = {}
	for item_id in normal_transaction.get_equipment_discoveries():
		excluded[String(item_id)] = true
	var owned: Dictionary = {}
	for item_id in context.get("owned_equipment", []):
		owned[String(item_id)] = true
	var profile_id := StringName(context.get("profile_id", &""))
	var candidates: Array[EquipmentDefinition] = []
	for item in EquipmentDiscoveryService.eligible_items(
		equipment_catalog,
		RewardTable.EQUIPMENT_POOL_STAGE_CACHE,
		profile_id,
		stage_index
	):
		if not owned.has(String(item.id)) and not excluded.has(String(item.id)):
			candidates.append(item)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(left: EquipmentDefinition, right: EquipmentDefinition) -> bool:
		return String(left.id) < String(right.id)
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = RewardService.stable_seed(
		run_seed,
		"treasure:%d:%s:equipment" % [stage_index, normal_transaction.id]
	)
	var item := candidates[rng.randi_range(0, candidates.size() - 1)]
	var description := item.mechanical_description
	if not item.tradeoff_description.strip_edges().is_empty():
		description += "\n%s" % item.tradeoff_description
	return {
		"kind": &"equipment",
		"payload": {"item_id": item.id},
		"transaction": RewardTransaction.new(
			normal_transaction.id,
			normal_transaction.source_id,
			{},
			[item.id]
		),
		"option": {
			"id": REPLACEMENT_CHOICE_ID,
			"label": "TAKE EQUIPMENT",
			"title": item.display_name,
			"description": description,
			"kind": &"equipment",
		},
	}


static func _forge_replacement(
	normal_transaction: RewardTransaction,
	equipment_catalog: EquipmentCatalog,
	forge_catalog: ForgeCatalog,
	loadout: Dictionary,
	temporary_affixes: Dictionary,
	run_seed: int,
	stage_index: int
) -> Dictionary:
	if equipment_catalog == null or forge_catalog == null:
		return {}
	var candidates: Array[Dictionary] = []
	for slot_id in EquipmentDefinition.PERSISTENT_SLOTS:
		var item_id := StringName(loadout.get(String(slot_id), &""))
		var item := equipment_catalog.get_item(item_id)
		if item == null:
			continue
		var current_affix_id := StringName(temporary_affixes.get(String(item.id), &""))
		for affix in forge_catalog.get_eligible(item.slot):
			if affix.id != current_affix_id:
				candidates.append({
					"item": item,
					"affix": affix,
					"current_affix_id": current_affix_id,
				})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_key := "%s:%s" % [left["item"].id, left["affix"].id]
		var right_key := "%s:%s" % [right["item"].id, right["affix"].id]
		return left_key < right_key
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = RewardService.stable_seed(
		run_seed,
		"treasure:%d:%s:forge" % [stage_index, normal_transaction.id]
	)
	var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var item := selected["item"] as EquipmentDefinition
	var affix := selected["affix"] as ForgeAffixDefinition
	var current_affix_id := selected["current_affix_id"] as StringName
	var description := affix.mechanical_description
	if current_affix_id != &"":
		var current_affix := forge_catalog.get_affix(current_affix_id)
		if current_affix != null:
			description += "\nReplaces %s." % current_affix.display_name
	return {
		"kind": &"forge",
		"payload": {
			"item_id": item.id,
			"affix_id": affix.id,
			"previous_affix_id": current_affix_id,
		},
		"transaction": RewardTransaction.new(
			normal_transaction.id,
			normal_transaction.source_id
		),
		"option": {
			"id": REPLACEMENT_CHOICE_ID,
			"label": "TAKE FREE FORGE",
			"title": "%s - %s" % [item.display_name, affix.display_name],
			"description": description,
			"kind": &"forge",
		},
	}


static func _normal_description(
	transaction: RewardTransaction,
	equipment_catalog: EquipmentCatalog,
	context: Dictionary
) -> String:
	var lines: Array[String] = []
	var grant_ids := transaction.get_grants().keys()
	grant_ids.sort()
	var grants := transaction.get_grants()
	for grant_id in grant_ids:
		lines.append("+%d %s" % [int(grants[grant_id]), _grant_label(String(grant_id))])
	var owned: Dictionary = {}
	for item_id in context.get("owned_equipment", []):
		owned[String(item_id)] = true
	for item_id in transaction.get_equipment_discoveries():
		var item := equipment_catalog.get_item(item_id) if equipment_catalog != null else null
		var item_name := item.display_name if item != null else String(item_id)
		if item != null and owned.has(String(item_id)):
			lines.append("Duplicate %s salvages to %s" % [
				item_name,
				_format_materials(item.salvage_materials),
			])
		else:
			lines.append("Discover %s" % item_name)
	return "\n".join(lines) if not lines.is_empty() else "Claim the resolved cache reward."


static func _format_materials(materials: Dictionary) -> String:
	var parts: Array[String] = []
	var material_ids := materials.keys()
	material_ids.sort()
	for material_id in material_ids:
		parts.append("%d %s" % [
			int(materials[material_id]),
			_grant_label(String(material_id)),
		])
	return ", ".join(parts) if not parts.is_empty() else "materials"


static func _grant_label(grant_id: String) -> String:
	return {
		"coin": "Coins",
		"xp": "XP",
		"rusted_scrap": "Rusted Scrap",
		"sky_thread": "Sky Thread",
		"slime_residue": "Slime Residue",
		"boss_core": "Boss Core",
	}.get(grant_id, grant_id.capitalize())


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
