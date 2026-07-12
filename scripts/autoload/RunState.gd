extends Node

# Owns mutable facts and atomic commands for one run; UI consumes copy-safe snapshots.

const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"
const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const PROGRESSION_CATALOG_PATH := "res://data/progression/run_progression_catalog.tres"
const CARD_CATALOG_PATH := "res://data/cards/card_catalog.tres"
const FORGE_CATALOG_PATH := "res://data/forge/forge_catalog.tres"
const NORMAL_STAGE_COUNT := RunPhase.NORMAL_STAGE_COUNT
const CARD_REROLL_COST := 12
const REST_HEAL_COST := 8
const REST_HEAL_AMOUNT := 2
const CONSUMABLES: Dictionary = {
	"small_potion": {"display_name": "Small Potion", "cost": 8, "description": "Heal 2."},
	"dash_tonic": {"display_name": "Dash Tonic", "cost": 10, "description": "Dash cooldown -0.12 s this stage."},
	"salvage_kit": {"display_name": "Salvage Kit", "cost": 10, "description": "Next material reward gains +1."},
}

const RUN_CURRENCIES: PackedStringArray = ["xp", "coin"]
const MATERIAL_CURRENCIES: PackedStringArray = [
	"rusted_scrap", "sky_thread", "slime_residue", "boss_core",
]

var character_catalog: CharacterCatalog
var reward_catalog: RewardCatalog
var progression_catalog: RunProgressionCatalog
var card_catalog: CardCatalog
var forge_catalog: ForgeCatalog
var profiles: Array[CharacterProfile] = []
var selected_profile_index: int = 0
var selected_profile: CharacterProfile
var effective_stats: Dictionary = {}
var effective_build_snapshot: PlayerBuildSnapshot

var current_health: int = 0
var max_health: int = 0
var run_seed: int = 0
var current_stage_index: int = 0
var run_level: int = 1
var current_xp: int = 0
var coins: int = 0
var _unsettled_materials: Dictionary = {}
var _micro_upgrade_stacks: Dictionary = {}
var _card_stacks: Dictionary = {}
var _applied_reward_ids: Dictionary = {}
var _stage_cache_discoveries: Dictionary = {}
var _pending_level_choices: int = 0
var _pending_level_offer: Array[StringName] = []
var _level_offer_sequence: int = 0
var _card_reward_pending: bool = false
var _pending_card_offer: Array[StringName] = []
var _card_offer_sequence: int = 0
var _card_reroll_used: bool = false
var _card_reward_stage_index: int = -1
var _committed_card_id: StringName
var _rest_active: bool = false
var _rest_consumable_purchased: bool = false
var _rest_forge_committed: bool = false
var _temporary_affixes: Dictionary = {}
var _forge_offer_item_id: StringName
var _forge_offer: Array[StringName] = []
var _forge_guard_remaining: int = 0
var _forge_guard_value: int = 0
var _forge_salvage_remaining: int = 0
var _forge_salvage_value: int = 0
var _dash_tonic_active: bool = false
var _consumable_salvage_remaining: int = 0
var current_consumable_id: StringName = &"small_potion"
var consumable_charges: int = 1
var _catalogs_valid: bool = false
var _settlement_service := RunSettlementService.new()
var _run_started_at_msec: int = 0


func _ready() -> void:
	_load_profiles()
	_load_run_catalogs()
	start_new_run(selected_profile_index)


func _load_profiles() -> void:
	profiles.clear()
	var loaded_catalog := load(CHARACTER_CATALOG_PATH)
	if not loaded_catalog is CharacterCatalog:
		push_error("Unable to load the production character catalog.")
		return

	character_catalog = loaded_catalog
	var catalog_errors := character_catalog.validate_catalog()
	if not catalog_errors.is_empty():
		for error in catalog_errors:
			push_error("Invalid character catalog: %s" % error)
		return

	for profile in character_catalog.profiles:
		profiles.append(profile)

	if profiles.is_empty():
		push_error("No character profiles are available for RunState.")
		return

	selected_profile_index = clampi(selected_profile_index, 0, profiles.size() - 1)
	selected_profile = profiles[selected_profile_index]


func start_new_run(profile_index: int = -1, requested_seed: int = -1) -> bool:
	if profiles.is_empty():
		_load_profiles()
	if profiles.is_empty():
		return false
	if not _catalogs_valid:
		return false

	var candidate_index := selected_profile_index
	if profile_index >= 0:
		candidate_index = wrapi(profile_index, 0, profiles.size())
	var candidate_profile := profiles[candidate_index]
	var candidate_build := PlayerBuild.resolve(
		candidate_profile.to_base_stats_dictionary(),
		ProfileState.get_build_effects(StringName(candidate_profile.id))
	)
	if not _is_build_valid(candidate_profile, candidate_build):
		return false
	_apply_profile_build(candidate_index, candidate_profile, candidate_build)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	run_seed = requested_seed if requested_seed >= 0 else _create_run_seed()
	current_stage_index = 0
	run_level = 1
	current_xp = 0
	coins = 0
	_unsettled_materials.clear()
	_micro_upgrade_stacks.clear()
	_card_stacks.clear()
	_applied_reward_ids.clear()
	_stage_cache_discoveries.clear()
	_pending_level_choices = 0
	_pending_level_offer.clear()
	_level_offer_sequence = 0
	_card_reward_pending = false
	_pending_card_offer.clear()
	_card_offer_sequence = 0
	_card_reroll_used = false
	_card_reward_stage_index = -1
	_committed_card_id = &""
	_rest_active = false
	_rest_consumable_purchased = false
	_rest_forge_committed = false
	_temporary_affixes.clear()
	_forge_offer_item_id = &""
	_forge_offer.clear()
	_forge_guard_remaining = 0
	_forge_guard_value = 0
	_forge_salvage_remaining = 0
	_forge_salvage_value = 0
	_dash_tonic_active = false
	_consumable_salvage_remaining = 0
	var profile_loadout := ProfileState.get_loadout(candidate_profile.id)
	current_consumable_id = StringName(profile_loadout.get("consumable", "small_potion"))
	consumable_charges = 1
	_run_started_at_msec = Time.get_ticks_msec()
	_settlement_service.reset(ProfileState)
	_publish_state()
	SignalBus.run_started.emit()
	return true


func select_profile(profile_index: int) -> bool:
	if profiles.is_empty():
		return false

	var candidate_index := wrapi(profile_index, 0, profiles.size())
	var candidate_profile := profiles[candidate_index]
	var candidate_build := PlayerBuild.resolve(
		candidate_profile.to_base_stats_dictionary(),
		ProfileState.get_build_effects(StringName(candidate_profile.id))
	)
	if not _is_build_valid(candidate_profile, candidate_build):
		return false
	_apply_profile_build(candidate_index, candidate_profile, candidate_build)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	_publish_state()
	SignalBus.status_message_changed.emit("Profile: %s" % selected_profile.display_name)
	return true


func cycle_profile(step: int = 1) -> void:
	select_profile(selected_profile_index + step)


func get_effective_stat(stat_name: String, fallback: float = 0.0) -> float:
	return float(effective_stats.get(stat_name, fallback))


func get_effective_stats() -> Dictionary:
	return effective_stats.duplicate()


func get_effective_build_snapshot() -> PlayerBuildSnapshot:
	return effective_build_snapshot


func get_run_snapshot() -> RunSnapshot:
	var terminal_settlement := get_terminal_settlement_snapshot()
	return RunSnapshot.new({
		"seed": run_seed,
		"profile_id": selected_profile.id if selected_profile != null else "",
		"stage_index": current_stage_index,
		"health": current_health,
		"max_health": max_health,
		"level": run_level,
		"xp": current_xp,
		"coins": coins,
		"materials": get_unsettled_materials(),
		"cards": _card_stacks.duplicate(true),
		"micro_upgrades": _micro_upgrade_stacks.duplicate(true),
		"pending_level_choices": _pending_level_choices,
		"card_reward_pending": _card_reward_pending,
		"card_offer": _string_name_array_to_strings(_pending_card_offer),
		"card_reroll_used": _card_reroll_used,
		"temporary_affixes": _temporary_affixes.duplicate(true),
		"consumable_id": String(current_consumable_id),
		"consumable_charges": consumable_charges,
		"effective_stats": get_effective_stats(),
		"elapsed_seconds": get_run_elapsed_seconds(),
		"terminal_settlement": terminal_settlement,
	})


func get_run_elapsed_seconds() -> float:
	if _run_started_at_msec <= 0:
		return 0.0
	return maxf(float(Time.get_ticks_msec() - _run_started_at_msec) / 1000.0, 0.0)


func has_terminal_settlement() -> bool:
	return _settlement_service.has_settlement()


func get_terminal_settlement() -> RunSettlementSnapshot:
	return _settlement_service.get_snapshot()


func get_terminal_settlement_snapshot() -> Dictionary:
	var settlement := get_terminal_settlement()
	return settlement.to_dictionary() if settlement != null else {}


func settle_run_death(reason: StringName = &"player_defeated") -> Dictionary:
	var result := _settlement_service.settle_death(self, ProfileState, reason)
	_publish_terminal_settlement(result)
	return result


func settle_run_victory(
	reward_table_id: StringName = RunSettlementService.DEFAULT_BOSS_REWARD_TABLE_ID
) -> Dictionary:
	var result := _settlement_service.settle_victory(self, ProfileState, reward_table_id)
	_publish_terminal_settlement(result)
	return result


func end_run_death(reason: StringName = &"player_defeated") -> Dictionary:
	return settle_run_death(reason)


func end_run_clear(
	reward_table_id: StringName = RunSettlementService.DEFAULT_BOSS_REWARD_TABLE_ID
) -> Dictionary:
	return settle_run_victory(reward_table_id)


func get_unsettled_materials() -> Dictionary:
	return _unsettled_materials.duplicate(true)


func grant_unsettled_material(material_id: String, amount: int) -> bool:
	if not MATERIAL_CURRENCIES.has(material_id) or amount <= 0:
		return false
	_unsettled_materials[material_id] = int(_unsettled_materials.get(material_id, 0)) + amount
	return true


func apply_reward_transaction(transaction: RewardTransaction) -> RewardResult:
	if transaction == null or transaction.id == &"":
		return RewardResult.new(false, false, &"", {}, "Reward transaction ID is missing.")
	if has_terminal_settlement():
		return RewardResult.new(
			false,
			false,
			transaction.id,
			{},
			"Run is already settled."
		)
	var transaction_key := String(transaction.id)
	if _applied_reward_ids.has(transaction_key):
		return RewardResult.new(
			false,
			true,
			transaction.id,
			{},
			"Reward transaction was already applied."
		)
	var grants := transaction.get_grants()
	var equipment_ids := transaction.get_equipment_discoveries()
	var validation_error := _validate_reward_contents(grants, equipment_ids)
	if not validation_error.is_empty():
		return RewardResult.new(
			false,
			false,
			transaction.id,
			{},
			validation_error
		)
	var equipment_settlement := _settle_equipment_discoveries(transaction.id, equipment_ids)
	if not bool(equipment_settlement.get("ok", false)):
		return RewardResult.new(
			false,
			false,
			transaction.id,
			{},
			String(equipment_settlement.get("message", "Equipment discovery failed."))
		)
	var consumable_salvage_eligible := _is_material_node_reward(transaction)
	for currency_id in grants:
		var amount := int(grants[currency_id])
		if (
			String(currency_id) in ["rusted_scrap", "sky_thread", "slime_residue"]
			and _forge_salvage_remaining > 0
		):
			amount += _forge_salvage_value
			grants[currency_id] = amount
			_forge_salvage_remaining -= 1
		if (
			String(currency_id) in ["rusted_scrap", "sky_thread", "slime_residue"]
			and _consumable_salvage_remaining > 0
			and consumable_salvage_eligible
		):
			amount += 1
			grants[currency_id] = amount
			_consumable_salvage_remaining -= 1
		match String(currency_id):
			"xp":
				_grant_xp_internal(amount)
			"coin":
				coins += amount
			_:
				if not ProfileState.grant_material(String(currency_id), amount):
					return RewardResult.new(
						false,
						false,
						transaction.id,
						{},
						"Persistent material grant failed."
					)
				grant_unsettled_material(String(currency_id), amount)
	if not equipment_ids.is_empty() and _is_stage_cache_reward(transaction):
		_stage_cache_discoveries[str(current_stage_index)] = true
	_applied_reward_ids[transaction_key] = true
	var result := RewardResult.new(
		true,
		false,
		transaction.id,
		grants,
		"Reward applied.",
		equipment_settlement["results"]
	)
	_publish_snapshot()
	SignalBus.reward_applied.emit(result.to_dictionary())
	if _pending_level_choices > 0:
		SignalBus.level_reward_pending.emit(_pending_level_choices)
	return result


func has_applied_reward(transaction_id: StringName) -> bool:
	return _applied_reward_ids.has(String(transaction_id))


func get_reward_resolution_context() -> Dictionary:
	return {
		"profile_id": selected_profile.id if selected_profile != null else &"",
		"stage_index": current_stage_index,
		"equipment_catalog": ProfileState.equipment_catalog,
		"owned_equipment": ProfileState.get_owned_equipment(),
		"stage_cache_claimed": _stage_cache_discoveries.has(str(current_stage_index)),
	}


func _validate_reward_contents(
	grants: Dictionary,
	equipment_ids: Array[StringName]
) -> String:
	for currency_id in grants:
		var amount_value: Variant = grants[currency_id]
		if (
			not (amount_value is int or amount_value is float)
			or not is_equal_approx(float(amount_value), round(float(amount_value)))
			or int(amount_value) <= 0
			or (
				not RUN_CURRENCIES.has(String(currency_id))
				and not MATERIAL_CURRENCIES.has(String(currency_id))
			)
		):
			return "Reward transaction contains an invalid grant."
	var seen_equipment: Dictionary = {}
	for item_id in equipment_ids:
		if item_id == &"" or seen_equipment.has(item_id) or not ProfileState.has_equipment_definition(item_id):
			return "Reward transaction contains invalid equipment discovery."
		seen_equipment[item_id] = true
	return ""


func _settle_equipment_discoveries(
	transaction_id: StringName,
	equipment_ids: Array[StringName]
) -> Dictionary:
	var results: Array[Dictionary] = []
	for index in equipment_ids.size():
		var item_id := equipment_ids[index]
		var profile_transaction_id := StringName(
			"reward:%s:equipment:%02d:%s" % [transaction_id, index, item_id]
		)
		var discovery: Dictionary = ProfileState.discover_equipment(
			item_id,
			profile_transaction_id
		)
		if not bool(discovery.get("ok", false)):
			return {
				"ok": false,
				"message": discovery.get("message", "Equipment discovery failed."),
			}
		results.append({
			"item_id": String(item_id),
			"profile_transaction_id": String(profile_transaction_id),
			"duplicate": bool(discovery.get("duplicate", false)),
			"persisted": bool(discovery.get("persisted", true)),
			"payload": discovery.get("payload", {}).duplicate(true),
		})
	return {"ok": true, "results": results}


func get_pending_level_choice_count() -> int:
	return _pending_level_choices


func get_pending_level_offer() -> Array[StringName]:
	if _pending_level_choices <= 0 or progression_catalog == null:
		return []
	if _pending_level_offer.is_empty():
		_pending_level_offer = ProgressionOfferService.build_offer(
			progression_catalog,
			_micro_upgrade_stacks,
			run_seed,
			_level_offer_sequence
		)
		_level_offer_sequence += 1
	return _pending_level_offer.duplicate()


func get_micro_upgrade(upgrade_id: StringName) -> MicroUpgradeDefinition:
	return progression_catalog.get_upgrade(upgrade_id) if progression_catalog != null else null


func preview_micro_upgrade(upgrade_id: StringName) -> Dictionary:
	var upgrade := get_micro_upgrade(upgrade_id)
	if upgrade == null:
		return {"ok": false, "message": "Upgrade definition is unavailable."}
	if upgrade.recovery_choice:
		return {
			"ok": true,
			"upgrade_id": String(upgrade.id),
			"changes": {},
			"heal": upgrade.heal_on_apply,
		}
	var candidate_stacks := _micro_upgrade_stacks.duplicate(true)
	var next_stack := int(candidate_stacks.get(String(upgrade.id), 0)) + 1
	if next_stack > upgrade.max_stacks:
		return {"ok": false, "message": "Upgrade is already capped."}
	candidate_stacks[String(upgrade.id)] = next_stack
	var candidate := PlayerBuild.resolve(
		selected_profile.to_base_stats_dictionary(),
		_collect_all_build_effects(candidate_stacks)
	)
	if not candidate.is_valid():
		return {"ok": false, "message": "Upgrade preview produced an invalid build."}
	var changes: Dictionary = {}
	for stat_id in candidate.get_values():
		var before := float(effective_stats.get(stat_id, candidate.get_stat(stat_id)))
		var after := candidate.get_stat(stat_id)
		if not is_equal_approx(before, after):
			changes[String(stat_id)] = {"before": before, "after": after}
	return {
		"ok": true,
		"upgrade_id": String(upgrade.id),
		"changes": changes,
		"heal": upgrade.heal_on_apply,
	}


func choose_micro_upgrade(upgrade_id: StringName) -> Dictionary:
	if _pending_level_choices <= 0:
		return {"ok": false, "message": "No level reward is pending."}
	var offer := get_pending_level_offer()
	if not offer.has(upgrade_id):
		return {"ok": false, "message": "Upgrade is not in the current offer."}
	var upgrade := get_micro_upgrade(upgrade_id)
	if upgrade == null:
		return {"ok": false, "message": "Upgrade definition is unavailable."}
	var previous_stack := int(_micro_upgrade_stacks.get(String(upgrade.id), 0))
	if not upgrade.recovery_choice:
		if previous_stack >= upgrade.max_stacks:
			return {"ok": false, "message": "Upgrade is already capped."}
		_micro_upgrade_stacks[String(upgrade.id)] = previous_stack + 1
	if not _rebuild_effective_build():
		if not upgrade.recovery_choice:
			if previous_stack <= 0:
				_micro_upgrade_stacks.erase(String(upgrade.id))
			else:
				_micro_upgrade_stacks[String(upgrade.id)] = previous_stack
		return {"ok": false, "message": "Upgrade produced an invalid build."}
	if upgrade.heal_on_apply > 0:
		current_health = mini(current_health + upgrade.heal_on_apply, max_health)
	_pending_level_choices -= 1
	_pending_level_offer.clear()
	var result := {
		"ok": true,
		"upgrade_id": String(upgrade.id),
		"display_name": upgrade.display_name,
		"pending_count": _pending_level_choices,
		"snapshot": get_run_snapshot().to_dictionary(),
	}
	_publish_state()
	SignalBus.level_choice_committed.emit(result.duplicate(true))
	return result


func spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	_publish_snapshot()
	return true


func begin_stage_card_reward() -> Dictionary:
	if (
		has_terminal_settlement()
		or current_stage_index < 0
		or current_stage_index >= NORMAL_STAGE_COUNT
	):
		return {"ok": false, "message": "No normal-stage card reward is available."}
	if card_catalog == null:
		return {"ok": false, "message": "Card catalog is unavailable."}
	if _card_reward_stage_index == current_stage_index:
		if _card_reward_pending:
			return {
				"ok": true,
				"pending": true,
				"offer": get_pending_card_offer(),
				"message": "Card reward is already active for this stage.",
			}
		return {"ok": false, "message": "This stage card reward is already committed."}
	_card_reward_stage_index = current_stage_index
	_card_reward_pending = true
	_card_reroll_used = false
	_committed_card_id = &""
	_pending_card_offer = _build_card_offer([])
	if _pending_card_offer.size() != CardOfferService.CHOICE_COUNT:
		_clear_card_reward_state()
		return {"ok": false, "message": "No complete compatible card offer is available."}
	_publish_snapshot()
	return {"ok": true, "pending": true, "offer": get_pending_card_offer()}


func get_pending_card_offer() -> Array[StringName]:
	return _pending_card_offer.duplicate() if _card_reward_pending else []


func get_card_definition(card_id: StringName) -> CardDefinition:
	return card_catalog.get_card(card_id) if card_catalog != null else null


func get_card_stack(card_id: StringName) -> int:
	return int(_card_stacks.get(String(card_id), 0))


func get_card_stacks() -> Dictionary:
	return _card_stacks.duplicate(true)


func get_card_effect_contexts(trigger: StringName) -> Array[Dictionary]:
	var contexts: Array[Dictionary] = []
	if card_catalog == null:
		return contexts
	var card_ids := _card_stacks.keys()
	card_ids.sort()
	for card_id in card_ids:
		var card := card_catalog.get_card(StringName(card_id))
		var stack := int(_card_stacks[card_id])
		if card != null and card.trigger == trigger and stack > 0:
			contexts.append({"definition": card, "stack": stack})
	return contexts


func can_reroll_card_offer() -> bool:
	if not _card_reward_pending or _card_reroll_used or coins < get_card_reroll_cost():
		return false
	return CardOfferService.eligible_ids(
		card_catalog,
		selected_profile.id,
		_card_stacks,
		[],
		CardOfferService.supported_triggers_for_profile(selected_profile)
	).size() > CardOfferService.CHOICE_COUNT


func reroll_card_offer() -> Dictionary:
	if not _card_reward_pending:
		return {"ok": false, "message": "No card reward is pending."}
	if _card_reroll_used:
		return {"ok": false, "message": "The stage card reroll was already used."}
	var reroll_cost := get_card_reroll_cost()
	if coins < reroll_cost:
		return {"ok": false, "message": "Reroll needs %d coins." % reroll_cost}
	if not can_reroll_card_offer():
		return {"ok": false, "message": "No different card choices are available."}

	var previous_offer := _pending_card_offer.duplicate()
	var next_offer: Array[StringName] = []
	var candidate_sequence := _card_offer_sequence
	# Find a visibly different deterministic offer before committing state or cost.
	for _attempt in 16:
		next_offer = CardOfferService.build_offer(
			card_catalog,
			selected_profile.id,
			_card_stacks,
			run_seed,
			current_stage_index,
			candidate_sequence,
			[],
			CardOfferService.supported_triggers_for_profile(selected_profile)
		)
		candidate_sequence += 1
		if (
			next_offer.size() == CardOfferService.CHOICE_COUNT
			and not _same_card_choice_set(next_offer, previous_offer)
		):
			break
	if (
		next_offer.size() != CardOfferService.CHOICE_COUNT
		or _same_card_choice_set(next_offer, previous_offer)
	):
		return {"ok": false, "message": "No different complete card offer is available."}

	coins -= reroll_cost
	_card_offer_sequence = candidate_sequence
	_card_reroll_used = true
	_pending_card_offer = next_offer
	_publish_snapshot()
	return {
		"ok": true,
		"cost": reroll_cost,
		"coins": coins,
		"offer": get_pending_card_offer(),
	}


func get_card_reroll_cost() -> int:
	var discount := PlayerProgressionEffectQuery.first_card_reroll_discount(
		ProfileState.get_behavior_effects(StringName(selected_profile.id))
	)
	return maxi(CARD_REROLL_COST - discount, 0)


func choose_card(card_id: StringName) -> Dictionary:
	if not _card_reward_pending:
		return {"ok": false, "message": "No card reward is pending."}
	if not _pending_card_offer.has(card_id):
		return {"ok": false, "message": "Card is not in the current offer."}
	var card := get_card_definition(card_id)
	if card == null or not card.is_compatible(selected_profile.id):
		return {"ok": false, "message": "Card is unavailable for this character."}
	var next_stack := get_card_stack(card_id) + 1
	if next_stack > card.max_stacks:
		return {"ok": false, "message": "Card is already at maximum stacks."}

	_card_stacks[String(card_id)] = next_stack
	_card_reward_pending = false
	_pending_card_offer.clear()
	_committed_card_id = card_id
	_publish_snapshot()
	return {
		"ok": true,
		"card_id": String(card_id),
		"display_name": card.display_name,
		"stack": next_stack,
		"snapshot": get_run_snapshot().to_dictionary(),
	}


func advance_stage_after_card_reward() -> bool:
	if (
		has_terminal_settlement()
		or current_stage_index < 0
		or current_stage_index >= NORMAL_STAGE_COUNT
		or _card_reward_pending
		or _committed_card_id == &""
	):
		return false
	if _dash_tonic_active:
		_dash_tonic_active = false
		if not _rebuild_effective_build():
			_dash_tonic_active = true
			_rebuild_effective_build()
			return false
	current_stage_index += 1
	_card_reward_stage_index = -1
	_card_reroll_used = false
	_committed_card_id = &""
	_publish_snapshot()
	return true


func begin_rest_forge() -> Dictionary:
	if _rest_active:
		return {"ok": true, "snapshot": get_rest_forge_snapshot()}
	_rest_active = true
	_rest_consumable_purchased = false
	_rest_forge_committed = false
	_forge_offer_item_id = &""
	_forge_offer.clear()
	_publish_snapshot()
	return {"ok": true, "snapshot": get_rest_forge_snapshot()}


func get_rest_forge_snapshot() -> Dictionary:
	var item_rows: Array[Dictionary] = []
	var loadout := ProfileState.get_loadout(selected_profile.id)
	for slot_id in ProfileData.PERSISTENT_SLOTS:
		var item_id := StringName(loadout.get(slot_id, ""))
		if item_id == &"":
			continue
		var item := ProfileState.equipment_catalog.get_item(item_id)
		if item == null:
			continue
		item_rows.append({
			"id": String(item.id),
			"display_name": item.display_name,
			"slot": String(item.slot),
			"affix_id": String(_temporary_affixes.get(String(item.id), "")),
		})
	var offer_rows: Array[Dictionary] = []
	for affix_id in _forge_offer:
		var affix := forge_catalog.get_affix(affix_id) if forge_catalog != null else null
		if affix != null:
			offer_rows.append({
				"id": String(affix.id),
				"display_name": affix.display_name,
				"description": affix.mechanical_description,
			})
	var consumable_rows: Array[Dictionary] = []
	for consumable_id in CONSUMABLES:
		var definition: Dictionary = CONSUMABLES[consumable_id]
		consumable_rows.append({
			"id": consumable_id,
			"display_name": definition["display_name"],
			"description": definition["description"],
			"cost": definition["cost"],
		})
	consumable_rows.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left["id"]) < String(right["id"])
	)
	return {
		"active": _rest_active,
		"health": current_health,
		"max_health": max_health,
		"coins": coins,
		"heal_cost": REST_HEAL_COST,
		"heal_amount": REST_HEAL_AMOUNT,
		"can_heal": _rest_active and current_health < max_health and coins >= REST_HEAL_COST,
		"consumables": consumable_rows,
		"consumable_purchased": _rest_consumable_purchased,
		"current_consumable_id": String(current_consumable_id),
		"items": item_rows,
		"forge_cost": forge_catalog.coin_cost if forge_catalog != null else 15,
		"forge_committed": _rest_forge_committed,
		"forge_item_id": String(_forge_offer_item_id),
		"forge_offer": offer_rows,
		"temporary_affixes": _temporary_affixes.duplicate(true),
	}


func buy_rest_heal() -> Dictionary:
	if not _rest_active:
		return {"ok": false, "message": "Rest is not active."}
	if current_health >= max_health:
		return {"ok": false, "message": "Health is already full."}
	if not spend_coins(REST_HEAL_COST):
		return {"ok": false, "message": "Heal needs %d coins." % REST_HEAL_COST}
	heal_player(REST_HEAL_AMOUNT)
	return {"ok": true, "message": "Recovered %d health." % REST_HEAL_AMOUNT, "snapshot": get_rest_forge_snapshot()}


func buy_rest_consumable(consumable_id: StringName) -> Dictionary:
	var key := String(consumable_id)
	if not _rest_active or not CONSUMABLES.has(key):
		return {"ok": false, "message": "Consumable is unavailable."}
	if _rest_consumable_purchased:
		return {"ok": false, "message": "A consumable was already bought here."}
	var definition: Dictionary = CONSUMABLES[key]
	var cost := int(definition["cost"])
	if not spend_coins(cost):
		return {"ok": false, "message": "%s needs %d coins." % [definition["display_name"], cost]}
	current_consumable_id = consumable_id
	consumable_charges = 1
	_rest_consumable_purchased = true
	_publish_snapshot()
	return {"ok": true, "message": "%s equipped." % definition["display_name"], "snapshot": get_rest_forge_snapshot()}


func begin_forge_offer(item_id: StringName) -> Dictionary:
	if not _rest_active or _rest_forge_committed or forge_catalog == null:
		return {"ok": false, "message": "Forge is unavailable."}
	var item := ProfileState.equipment_catalog.get_item(item_id)
	var loadout := ProfileState.get_loadout(selected_profile.id)
	if item == null or String(loadout.get(String(item.slot), "")) != String(item_id):
		return {"ok": false, "message": "Choose an equipped item."}
	if _forge_offer_item_id == item_id and _forge_offer.size() == forge_catalog.offer_size:
		return {"ok": true, "snapshot": get_rest_forge_snapshot()}
	var current_affix := StringName(_temporary_affixes.get(String(item_id), ""))
	_forge_offer = ForgeOfferService.build_offer(
		forge_catalog,
		item.slot,
		run_seed,
		current_stage_index,
		item_id,
		0,
		current_affix
	)
	if _forge_offer.size() != forge_catalog.offer_size:
		_forge_offer_item_id = &""
		return {"ok": false, "message": "No complete forge offer is available."}
	_forge_offer_item_id = item_id
	return {"ok": true, "message": "Choose one affix.", "snapshot": get_rest_forge_snapshot()}


func commit_forge_affix(
	item_id: StringName,
	affix_id: StringName,
	confirm_replace: bool = false
) -> Dictionary:
	if not _rest_active or _rest_forge_committed:
		return {"ok": false, "message": "Forge was already used here."}
	if item_id != _forge_offer_item_id or not _forge_offer.has(affix_id):
		return {"ok": false, "message": "Affix is not in the current offer."}
	if coins < forge_catalog.coin_cost:
		return {"ok": false, "message": "Forge needs %d coins." % forge_catalog.coin_cost}
	var previous_affix := StringName(_temporary_affixes.get(String(item_id), ""))
	if previous_affix != &"" and not confirm_replace:
		return {
			"ok": false,
			"requires_confirmation": true,
			"message": "Replace the current affix?",
			"item_id": String(item_id),
			"affix_id": String(affix_id),
		}
	_temporary_affixes[String(item_id)] = String(affix_id)
	if not _rebuild_effective_build():
		if previous_affix == &"":
			_temporary_affixes.erase(String(item_id))
		else:
			_temporary_affixes[String(item_id)] = String(previous_affix)
		_rebuild_effective_build()
		return {"ok": false, "message": "Affix produced an invalid build."}
	coins -= forge_catalog.coin_cost
	_rest_forge_committed = true
	_forge_offer_item_id = &""
	_forge_offer.clear()
	_rebuild_forge_behavior_counters()
	_publish_state()
	return {
		"ok": true,
		"message": "%s forged." % ProfileState.equipment_catalog.get_item(item_id).display_name,
		"snapshot": get_rest_forge_snapshot(),
	}


func end_rest_forge() -> bool:
	if not _rest_active:
		return false
	_rest_active = false
	_forge_offer_item_id = &""
	_forge_offer.clear()
	_publish_snapshot()
	return true


func use_consumable() -> Dictionary:
	if consumable_charges <= 0:
		return {"ok": false, "message": "No consumable charge remains."}
	match current_consumable_id:
		&"small_potion":
			if current_health >= max_health:
				return {"ok": false, "message": "Health is already full."}
			heal_player(2)
		&"dash_tonic":
			_dash_tonic_active = true
			_rebuild_effective_build()
		&"salvage_kit":
			_consumable_salvage_remaining = 1
		_:
			return {"ok": false, "message": "Consumable is unavailable."}
	consumable_charges -= 1
	_publish_state()
	return {"ok": true, "message": "Consumable used.", "snapshot": get_run_snapshot().to_dictionary()}


func reduce_damage_with_forge_guard(amount: int) -> int:
	if amount <= 0 or _forge_guard_remaining <= 0:
		return amount
	_forge_guard_remaining -= 1
	SignalBus.status_message_changed.emit("Forge Guard reduced damage")
	return maxi(amount - _forge_guard_value, 0)


func _is_material_node_reward(transaction: RewardTransaction) -> bool:
	if reward_catalog == null or transaction == null:
		return false
	var table := reward_catalog.get_table(transaction.source_id)
	return table != null and table.tags.has(&"material_node")


func _is_stage_cache_reward(transaction: RewardTransaction) -> bool:
	if reward_catalog == null or transaction == null:
		return false
	var table := reward_catalog.get_table(transaction.source_id)
	return (
		table != null
		and table.equipment_pool_id == RewardTable.EQUIPMENT_POOL_STAGE_CACHE
	)


func get_movement_metrics() -> Dictionary:
	return MovementMetrics.calculate_for_profile(selected_profile)


func get_required_route_limits() -> Dictionary:
	return MovementMetrics.route_limits_for_profiles(profiles)


func _grant_xp_internal(amount: int) -> void:
	if amount <= 0 or progression_catalog == null:
		return
	current_xp += amount
	var resolved_level := progression_catalog.get_level_for_xp(current_xp)
	if resolved_level > run_level:
		_pending_level_choices += resolved_level - run_level
		run_level = resolved_level


func damage_player(amount: int) -> void:
	if has_terminal_settlement() or amount <= 0 or current_health <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	SignalBus.player_health_changed.emit(current_health, max_health)
	_publish_snapshot()
	if current_health <= 0:
		SignalBus.player_died.emit()


func heal_player(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	SignalBus.player_health_changed.emit(current_health, max_health)
	_publish_snapshot()


func revive_player() -> void:
	current_health = max_health
	SignalBus.player_health_changed.emit(current_health, max_health)
	_publish_snapshot()


func set_setting(setting_name: String, value: Variant) -> void:
	if not ProfileState.set_setting(setting_name, value):
		push_warning("Rejected profile setting: %s" % setting_name)


func get_setting(setting_name: String, fallback: Variant = null) -> Variant:
	return ProfileState.get_setting(setting_name, fallback)


func _is_build_valid(profile: CharacterProfile, build_snapshot: PlayerBuildSnapshot) -> bool:
	if build_snapshot.is_valid():
		return true
	for error in build_snapshot.get_validation_errors():
		push_error(
			"Invalid player build for '%s': %s"
			% [profile.id, error.get("message", "Unknown error.")]
		)
	return false


func _apply_profile_build(
	profile_index: int,
	profile: CharacterProfile,
	build_snapshot: PlayerBuildSnapshot
) -> void:
	var resolved_stats := profile.to_stats_dictionary()
	for stat_id in profile.to_base_stats_dictionary():
		resolved_stats.erase(stat_id)
	for stat_id in build_snapshot.get_values():
		resolved_stats[stat_id] = build_snapshot.get_stat(stat_id)

	selected_profile_index = profile_index
	selected_profile = profile
	effective_build_snapshot = build_snapshot
	effective_stats = resolved_stats


func _rebuild_effective_build() -> bool:
	if selected_profile == null:
		return false
	var candidate := PlayerBuild.resolve(
		selected_profile.to_base_stats_dictionary(),
		_collect_all_build_effects(_micro_upgrade_stacks)
	)
	if not _is_build_valid(selected_profile, candidate):
		return false
	var previous_health := current_health
	_apply_profile_build(selected_profile_index, selected_profile, candidate)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = clampi(previous_health, 0, max_health)
	return true


func _collect_run_effects(stacks: Dictionary) -> Array:
	var effects: Array = []
	if progression_catalog == null:
		return effects
	var upgrade_ids := stacks.keys()
	upgrade_ids.sort()
	for upgrade_id in upgrade_ids:
		var upgrade := progression_catalog.get_upgrade(StringName(upgrade_id))
		if upgrade == null:
			continue
		for _stack in int(stacks[upgrade_id]):
			for effect in upgrade.effects:
				effects.append(effect)
	return effects


func _collect_all_build_effects(stacks: Dictionary) -> Array:
	var effects: Array = ProfileState.get_build_effects(StringName(selected_profile.id))
	effects.append_array(_collect_run_effects(stacks))
	if forge_catalog != null:
		var item_ids := _temporary_affixes.keys()
		item_ids.sort()
		for item_id in item_ids:
			var affix := forge_catalog.get_affix(StringName(_temporary_affixes[item_id]))
			if affix != null:
				for effect in affix.build_effects:
					effects.append(effect)
	if _dash_tonic_active:
		var dash_effect := EffectDefinition.new()
		dash_effect.stat_id = &"dash_cooldown"
		dash_effect.operation = EffectDefinition.OPERATION_ADD
		dash_effect.value = -0.12
		dash_effect.source_id = &"dash_tonic"
		dash_effect.source_scope = EffectDefinition.SOURCE_SCOPE_TEMPORARY
		effects.append(dash_effect)
	return effects


func _rebuild_forge_behavior_counters() -> void:
	_forge_guard_remaining = 0
	_forge_guard_value = 0
	_forge_salvage_remaining = 0
	_forge_salvage_value = 0
	if forge_catalog == null:
		return
	for item_id in _temporary_affixes:
		var affix := forge_catalog.get_affix(StringName(_temporary_affixes[item_id]))
		if affix == null:
			continue
		match affix.behavior_type:
			ForgeAffixDefinition.BEHAVIOR_GUARD:
				_forge_guard_remaining += affix.trigger_count
				_forge_guard_value = maxi(_forge_guard_value, affix.behavior_value)
			ForgeAffixDefinition.BEHAVIOR_SALVAGE:
				_forge_salvage_remaining += affix.trigger_count
				_forge_salvage_value = maxi(_forge_salvage_value, affix.behavior_value)


func _load_run_catalogs() -> void:
	_catalogs_valid = true
	var loaded_rewards := load(REWARD_CATALOG_PATH)
	if loaded_rewards is RewardCatalog:
		reward_catalog = loaded_rewards
		var errors := reward_catalog.validate_catalog()
		_catalogs_valid = _catalogs_valid and errors.is_empty()
		for error in errors:
			push_error("Invalid reward catalog: %s" % error)
	else:
		_catalogs_valid = false
		push_error("Unable to load the reward catalog.")
	var loaded_progression := load(PROGRESSION_CATALOG_PATH)
	if loaded_progression is RunProgressionCatalog:
		progression_catalog = loaded_progression
		var errors := progression_catalog.validate_catalog()
		_catalogs_valid = _catalogs_valid and errors.is_empty()
		for error in errors:
			push_error("Invalid run progression catalog: %s" % error)
	else:
		_catalogs_valid = false
		push_error("Unable to load the run progression catalog.")
	var loaded_cards := load(CARD_CATALOG_PATH)
	if loaded_cards is CardCatalog:
		card_catalog = loaded_cards
		var errors := card_catalog.validate_catalog()
		_catalogs_valid = _catalogs_valid and errors.is_empty()
		for error in errors:
			push_error("Invalid card catalog: %s" % error)
	else:
		_catalogs_valid = false
		push_error("Unable to load the card catalog.")
	var loaded_forge := load(FORGE_CATALOG_PATH)
	if loaded_forge is ForgeCatalog:
		forge_catalog = loaded_forge
		var errors := forge_catalog.validate_catalog()
		_catalogs_valid = _catalogs_valid and errors.is_empty()
		for error in errors:
			push_error("Invalid forge catalog: %s" % error)
	else:
		_catalogs_valid = false
		push_error("Unable to load the forge catalog.")


func _build_card_offer(excluded_ids: Array[StringName]) -> Array[StringName]:
	var offer := CardOfferService.build_offer(
		card_catalog,
		selected_profile.id,
		_card_stacks,
		run_seed,
		current_stage_index,
		_card_offer_sequence,
		excluded_ids,
		CardOfferService.supported_triggers_for_profile(selected_profile)
	)
	_card_offer_sequence += 1
	return offer


func _clear_card_reward_state() -> void:
	_card_reward_pending = false
	_pending_card_offer.clear()
	_card_reward_stage_index = -1
	_card_reroll_used = false
	_committed_card_id = &""


func _string_name_array_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _same_card_choice_set(first: Array[StringName], second: Array[StringName]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _create_run_seed() -> int:
	return int((Time.get_unix_time_from_system() * 1000.0 + Time.get_ticks_usec()) as int) & 0x7fffffff


func _publish_state() -> void:
	if selected_profile != null:
		SignalBus.selected_profile_changed.emit(
			selected_profile.id,
			selected_profile.display_name,
			selected_profile.visual_color
		)
	SignalBus.player_stats_changed.emit(get_effective_stats())
	SignalBus.player_health_changed.emit(current_health, max_health)
	_publish_snapshot()


func _publish_snapshot() -> void:
	SignalBus.run_state_changed.emit(get_run_snapshot().to_dictionary())


func _publish_terminal_settlement(result: Dictionary) -> void:
	if not bool(result.get("ok", false)) or bool(result.get("duplicate", false)):
		return
	var settlement := result.get("settlement") as RunSettlementSnapshot
	if settlement == null:
		return
	_publish_snapshot()
	SignalBus.run_settled.emit(settlement.to_dictionary())
