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
const MAX_CONSUMABLE_CHARGES := 1
const CONSUMABLES: Dictionary = {
	"small_potion": {"display_name": "Small Potion", "cost": 8, "description": "Heal 2."},
	"dash_tonic": {"display_name": "Dash Tonic", "cost": 10, "description": "Dash cooldown -0.12 s this stage."},
	"salvage_kit": {"display_name": "Salvage Kit", "cost": 10, "description": "Next material reward gains +1."},
}

const RUN_CURRENCIES: PackedStringArray = ["xp", "coin"]
const MATERIAL_CURRENCIES: PackedStringArray = [
	"rusted_scrap", "steel_fragment", "common_timber", "hardwood",
	"sky_thread", "reinforced_fabric", "slime_residue", "boss_core",
]
const HERO_CARD_PROFILE_ID := &"traveler"
const HERO_CARD_TRIGGERS: Array[StringName] = [
	&"dash_completed",
	&"first_attack_after_extra_jump",
	&"hit_target_in_recovery",
	&"required_room_encounter_cleared_without_damage",
	&"damage_left_one_health",
	&"optional_route_chest_claimed",
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
var hero_combat_loadout: Dictionary = {}

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
var _applied_field_pickup_ids: Dictionary = {}
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
var _pending_treasure_choice: Dictionary = {}
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


func start_new_run(_profile_index: int = -1, requested_seed: int = -1) -> bool:
	if profiles.is_empty():
		_load_profiles()
	if profiles.is_empty():
		return false
	if not _catalogs_valid:
		return false

	# The legacy catalog remains a migration fixture; Traveler owns production runs.
	var candidate_index := 0
	var candidate_profile := profiles[candidate_index]
	var maintenance := ProfileState.apply_stage_entry_maintenance()
	if not bool(maintenance.get("ok", false)):
		return false
	var candidate_hero := ProfileState.get_hero_combat_snapshot()
	if not bool(candidate_hero.get("ok", false)):
		push_error(String(candidate_hero.get("message", "Shared hero loadout is invalid.")))
		return false
	var candidate_build := PlayerBuild.resolve(
		candidate_hero["stats"],
		[]
	)
	if not _is_build_valid(candidate_profile, candidate_build):
		return false
	_apply_hero_build(candidate_index, candidate_profile, candidate_build, candidate_hero)
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
	_applied_field_pickup_ids.clear()
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
	_pending_treasure_choice.clear()
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
	var profile_loadout: Dictionary = candidate_hero["loadout"]
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


func get_hero_combat_loadout_snapshot() -> Dictionary:
	return hero_combat_loadout.duplicate(true)


func refresh_hero_combat_loadout() -> bool:
	var candidate := ProfileState.get_hero_combat_snapshot()
	if not bool(candidate.get("ok", false)):
		return false
	hero_combat_loadout = candidate
	return true


func get_effective_build_snapshot() -> PlayerBuildSnapshot:
	return effective_build_snapshot


func get_run_snapshot() -> RunSnapshot:
	var terminal_settlement := get_terminal_settlement_snapshot()
	return RunSnapshot.new({
		"seed": run_seed,
		"profile_id": String(hero_combat_loadout.get("hero_id", "traveler")),
		"profile_display_name": String(hero_combat_loadout.get("display_name", "Traveler")),
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
		"treasure_choice_pending": not _pending_treasure_choice.is_empty(),
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
	var blueprint_ids := transaction.get_blueprint_unlocks()
	var spirit_stone_ids := transaction.get_spirit_stone_unlocks()
	var validation_error := _validate_reward_contents(
		grants,
		equipment_ids,
		blueprint_ids,
		spirit_stone_ids
	)
	if not validation_error.is_empty():
		return RewardResult.new(
			false,
			false,
			transaction.id,
			{},
			validation_error
		)
	var consumable_salvage_eligible := _is_material_node_reward(transaction)
	var forge_salvage_remaining := _forge_salvage_remaining
	var consumable_salvage_remaining := _consumable_salvage_remaining
	for currency_id in grants:
		var amount := int(grants[currency_id])
		if (
			String(currency_id) in ["rusted_scrap", "sky_thread", "slime_residue"]
			and forge_salvage_remaining > 0
		):
			amount += _forge_salvage_value
			grants[currency_id] = amount
			forge_salvage_remaining -= 1
		if (
			String(currency_id) in ["rusted_scrap", "sky_thread", "slime_residue"]
			and consumable_salvage_remaining > 0
			and consumable_salvage_eligible
		):
			amount += 1
			grants[currency_id] = amount
			consumable_salvage_remaining -= 1

	var persistent_grants: Dictionary = {}
	for currency_id in grants:
		if MATERIAL_CURRENCIES.has(String(currency_id)):
			persistent_grants[String(currency_id)] = int(grants[currency_id])
	var progression_settlement := {
		"ok": true,
		"changed": false,
		"payload": {"blueprint_unlocks": [], "spirit_stone_unlocks": []},
	}
	if (
		not persistent_grants.is_empty()
		or not blueprint_ids.is_empty()
		or not spirit_stone_ids.is_empty()
	):
		progression_settlement = ProfileState.settle_progression_reward(
			StringName("reward:%s:progression" % transaction.id),
			persistent_grants,
			blueprint_ids,
			spirit_stone_ids
		)
		if not bool(progression_settlement.get("ok", false)):
			return RewardResult.new(
				false,
				false,
				transaction.id,
				{},
				String(progression_settlement.get("message", "Progression reward failed."))
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

	_forge_salvage_remaining = forge_salvage_remaining
	_consumable_salvage_remaining = consumable_salvage_remaining
	for currency_id in grants:
		var amount := int(grants[currency_id])
		match String(currency_id):
			"xp":
				_grant_xp_internal(amount)
			"coin":
				coins += amount
			_:
				if bool(progression_settlement.get("changed", false)):
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
		equipment_settlement["results"],
		progression_settlement.get("payload", {}).get("blueprint_unlocks", []),
		progression_settlement.get("payload", {}).get("spirit_stone_unlocks", [])
	)
	_publish_snapshot()
	SignalBus.reward_applied.emit(result.to_dictionary())
	if _pending_level_choices > 0:
		SignalBus.level_reward_pending.emit(_pending_level_choices)
	return result


func has_applied_reward(transaction_id: StringName) -> bool:
	return _applied_reward_ids.has(String(transaction_id))


func apply_field_pickup(
	pickup_id: StringName,
	definition: FieldPickupDefinition,
	player: Node = null
) -> Dictionary:
	if pickup_id == &"" or definition == null or not definition.validate_definition().is_empty():
		return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Pickup is unavailable.")
	if has_terminal_settlement() or current_health <= 0:
		return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Run is already settled.")
	var pickup_key := String(pickup_id)
	if _applied_field_pickup_ids.has(pickup_key):
		return _field_pickup_result(false, true, pickup_id, definition, 0.0, "Pickup was already collected.")

	var applied_amount := 0.0
	var result_details: Dictionary = {}
	match definition.effect_type:
		FieldPickupDefinition.EFFECT_HEAL:
			if current_health >= max_health:
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Health is already full.")
			var previous_health := current_health
			heal_player(int(definition.amount))
			applied_amount = float(current_health - previous_health)
		FieldPickupDefinition.EFFECT_REFILL_CONSUMABLE:
			if consumable_charges >= MAX_CONSUMABLE_CHARGES:
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Consumable charge is already full.")
			var previous_charges := consumable_charges
			consumable_charges = mini(
				consumable_charges + int(definition.amount),
				MAX_CONSUMABLE_CHARGES
			)
			applied_amount = float(consumable_charges - previous_charges)
			_publish_state()
		FieldPickupDefinition.EFFECT_REDUCE_SKILL_COOLDOWNS:
			if player == null or not player.has_method("apply_skill_cooldown_recovery"):
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "No skill cooldown can recover.")
			var recovery: Variant = player.call("apply_skill_cooldown_recovery", definition.amount)
			if not recovery is Dictionary or int(recovery.get("skill_count", 0)) <= 0:
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "No skill cooldown can recover.")
			applied_amount = maxf(float(recovery.get("max_seconds", 0.0)), 0.0)
			result_details = {
				"affected_skill_count": int(recovery.get("skill_count", 0)),
				"total_recovered_seconds": maxf(float(recovery.get("total_seconds", 0.0)), 0.0),
			}
		FieldPickupDefinition.EFFECT_GRANT_CURRENCY:
			var transaction_id := StringName("field:%s" % pickup_id)
			var transaction := RewardTransaction.new(
				transaction_id,
				definition.id,
				{String(definition.currency_id): int(definition.amount)}
			)
			var reward_result := apply_reward_transaction(transaction)
			if reward_result.duplicate:
				_applied_field_pickup_ids[pickup_key] = true
				return _field_pickup_result(false, true, pickup_id, definition, 0.0, "Pickup was already collected.")
			if not reward_result.applied:
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, reward_result.message)
			applied_amount = definition.amount
		FieldPickupDefinition.EFFECT_GRANT_RANGED_SUPPLY:
			var profile_state := get_node_or_null("/root/ProfileState")
			if profile_state == null or not profile_state.has_method("grant_ranged_supply"):
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Ranged supply is unavailable.")
			var supply_result: Dictionary = profile_state.call(
				"grant_ranged_supply",
				definition.supply_id,
				int(definition.amount)
			)
			if not bool(supply_result.get("ok", false)):
				return _field_pickup_result(
					false,
					false,
					pickup_id,
					definition,
					0.0,
					String(supply_result.get("message", "Ranged supply could not be stored."))
				)
			if not bool(supply_result.get("changed", false)):
				return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Ranged supply is already full.")
			var supply_payload: Dictionary = supply_result.get("payload", {})
			applied_amount = float(supply_payload.get("amount", 0))
			result_details = {
				"supply_id": String(definition.supply_id),
				"current": int(supply_payload.get("current", 0)),
				"maximum": int(supply_payload.get("maximum", 0)),
			}
		_:
			return _field_pickup_result(false, false, pickup_id, definition, 0.0, "Pickup effect is unsupported.")

	_applied_field_pickup_ids[pickup_key] = true
	return _field_pickup_result(
		true,
		false,
		pickup_id,
		definition,
		applied_amount,
		"%s collected." % definition.display_name,
		result_details
	)


func _field_pickup_result(
	applied: bool,
	duplicate: bool,
	pickup_id: StringName,
	definition: FieldPickupDefinition,
	applied_amount: float,
	message: String,
	details: Dictionary = {}
) -> Dictionary:
	var result := {
		"ok": applied or duplicate,
		"applied": applied,
		"duplicate": duplicate,
		"pickup_id": String(pickup_id),
		"definition_id": String(definition.id) if definition != null else "",
		"display_name": definition.display_name if definition != null else "Pickup",
		"effect_type": String(definition.effect_type) if definition != null else "",
		"amount": applied_amount,
		"currency_id": String(definition.currency_id) if definition != null else "",
		"supply_id": String(definition.supply_id) if definition != null else "",
		"icon_id": String(definition.icon_id) if definition != null else "",
		"message": message,
	}
	result.merge(details, true)
	return result


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
	equipment_ids: Array[StringName],
	blueprint_ids: Array[StringName],
	spirit_stone_ids: Array[StringName]
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
	var seen_blueprints: Dictionary = {}
	for model_id in blueprint_ids:
		if (
			model_id == &""
			or seen_blueprints.has(model_id)
			or ProfileState.progression_catalog == null
			or ProfileState.progression_catalog.get_blueprint_for_model(model_id) == null
		):
			return "Reward transaction contains invalid blueprint unlock."
		seen_blueprints[model_id] = true
	var seen_stones: Dictionary = {}
	for stone_id in spirit_stone_ids:
		if (
			stone_id == &""
			or seen_stones.has(stone_id)
			or ProfileState.progression_catalog == null
			or ProfileState.progression_catalog.get_spirit_stone(stone_id) == null
		):
			return "Reward transaction contains invalid Spirit Stone unlock."
		seen_stones[stone_id] = true
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
		var recovery_health_after := mini(current_health + upgrade.heal_on_apply, max_health)
		return {
			"ok": true,
			"upgrade_id": String(upgrade.id),
			"changes": {},
			"heal": upgrade.heal_on_apply,
			"current_health_before": current_health,
			"current_health_after": recovery_health_after,
			"max_health_after": max_health,
		}
	var candidate_stacks := _micro_upgrade_stacks.duplicate(true)
	var next_stack := int(candidate_stacks.get(String(upgrade.id), 0)) + 1
	if next_stack > upgrade.max_stacks:
		return {"ok": false, "message": "Upgrade is already capped."}
	candidate_stacks[String(upgrade.id)] = next_stack
	var candidate := PlayerBuild.resolve(
		hero_combat_loadout.get("stats", {}),
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
	var maximum_health_after := roundi(candidate.get_stat(&"max_health"))
	var current_health_after := mini(current_health, maximum_health_after)
	current_health_after = mini(current_health_after + upgrade.heal_on_apply, maximum_health_after)
	return {
		"ok": true,
		"upgrade_id": String(upgrade.id),
		"changes": changes,
		"heal": upgrade.heal_on_apply,
		"current_health_before": current_health,
		"current_health_after": current_health_after,
		"max_health_after": maximum_health_after,
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


func begin_optional_chest_choice(
	normal_transaction: RewardTransaction,
	context: Dictionary
) -> Dictionary:
	if normal_transaction == null or not bool(context.get("optional_route", false)):
		return {"ok": false, "message": "Optional chest choice context is invalid."}
	var request_id := StringName(context.get("request_id", normal_transaction.id))
	if request_id == &"" or request_id != normal_transaction.id:
		return {"ok": false, "message": "Optional chest choice identity is invalid."}
	if int(context.get("stage_index", current_stage_index)) != current_stage_index:
		return {"ok": false, "message": "Optional chest choice belongs to another stage."}
	if has_applied_reward(normal_transaction.id):
		return {"ok": true, "pending": false, "message": "Chest reward was already applied."}
	if not _pending_treasure_choice.is_empty():
		var pending_snapshot: Dictionary = _pending_treasure_choice.get("snapshot", {})
		if StringName(pending_snapshot.get("request_id", &"")) == request_id:
			return {"ok": true, "pending": true, "snapshot": pending_snapshot.duplicate(true)}
		return {"ok": false, "message": "Resolve the current treasure choice first."}

	var card: CardDefinition
	var replacement_effect: CardEffectDefinition
	for card_context in get_card_effect_contexts(&"optional_route_chest_claimed"):
		var candidate := card_context.get("definition") as CardDefinition
		if candidate == null:
			continue
		for effect in candidate.effects:
			if effect != null and effect.effect_type == &"request_reward_preview_replacement":
				card = candidate
				replacement_effect = effect
				break
		if replacement_effect != null:
			break
	if card == null or replacement_effect == null:
		return {"ok": true, "pending": false}

	var choice := TreasureChoiceService.build_choice(
		normal_transaction,
		context,
		card,
		replacement_effect,
		ProfileState.equipment_catalog,
		forge_catalog,
		ProfileState.get_loadout(selected_profile.id),
		_temporary_affixes,
		run_seed,
		current_stage_index
	)
	if not bool(choice.get("ok", false)):
		return {
			"ok": true,
			"pending": false,
			"message": "Treasure replacement was unavailable; normal reward applied.",
		}
	choice["context"] = _treasure_claim_context(context)
	_pending_treasure_choice = choice
	var snapshot: Dictionary = choice["snapshot"]
	_publish_snapshot()
	SignalBus.reward_preview_replacement_requested.emit(snapshot.duplicate(true))
	return {"ok": true, "pending": true, "snapshot": snapshot.duplicate(true)}


func get_pending_optional_chest_choice() -> Dictionary:
	if _pending_treasure_choice.is_empty():
		return {}
	var snapshot: Dictionary = _pending_treasure_choice.get("snapshot", {})
	return snapshot.duplicate(true)


func cancel_optional_chest_choice(request_id: StringName, message: String) -> bool:
	if _pending_treasure_choice.is_empty():
		return true
	if request_id != StringName(_pending_treasure_choice.get("request_id", &"")):
		return false
	_pending_treasure_choice.clear()
	_publish_snapshot()
	SignalBus.reward_preview_replacement_committed.emit({
		"ok": false,
		"cancelled": true,
		"request_id": request_id,
		"message": message,
	})
	return true


func _treasure_claim_context(context: Dictionary) -> Dictionary:
	return {
		"request_id": StringName(context.get("request_id", &"")),
		"stage_index": int(context.get("stage_index", current_stage_index)),
		"room_id": StringName(context.get("room_id", &"")),
		"source_id": StringName(context.get("source_id", &"")),
		"optional_route": bool(context.get("optional_route", false)),
	}


func commit_optional_chest_choice(
	request_id: StringName,
	choice_id: StringName
) -> Dictionary:
	if _pending_treasure_choice.is_empty():
		return {"ok": false, "message": "No treasure choice is pending."}
	var pending_request_id := StringName(_pending_treasure_choice.get("request_id", &""))
	if request_id == &"" or request_id != pending_request_id:
		return {"ok": false, "message": "Treasure choice identity does not match."}

	var result: RewardResult
	var replacement_kind := &"normal"
	match choice_id:
		TreasureChoiceService.NORMAL_CHOICE_ID:
			result = RewardService.apply(
				_pending_treasure_choice.get("normal_transaction") as RewardTransaction,
				self
			)
		TreasureChoiceService.REPLACEMENT_CHOICE_ID:
			replacement_kind = StringName(
				_pending_treasure_choice.get("replacement_kind", &"")
			)
			var replacement := (
				_pending_treasure_choice.get("replacement_transaction") as RewardTransaction
			)
			if replacement_kind == &"forge":
				result = _apply_treasure_forge_reward(
					replacement,
					_pending_treasure_choice.get("replacement_payload", {})
				)
			else:
				result = RewardService.apply(replacement, self)
		_:
			return {"ok": false, "message": "Treasure choice is unavailable."}
	if result == null or (not result.applied and not result.duplicate):
		return {
			"ok": false,
			"message": result.message if result != null else "Treasure reward failed.",
		}

	var completion := result.to_dictionary()
	completion.merge(_pending_treasure_choice.get("context", {}), true)
	completion["ok"] = true
	completion["request_id"] = request_id
	completion["choice_id"] = choice_id
	completion["replacement_kind"] = replacement_kind
	completion["replacement_payload"] = (
		_pending_treasure_choice.get("replacement_payload", {}).duplicate(true)
		if choice_id == TreasureChoiceService.REPLACEMENT_CHOICE_ID
		else {}
	)
	_pending_treasure_choice.clear()
	_publish_snapshot()
	SignalBus.reward_preview_replacement_committed.emit(completion.duplicate(true))
	return completion


func _apply_treasure_forge_reward(
	transaction: RewardTransaction,
	payload: Dictionary
) -> RewardResult:
	if transaction == null:
		return RewardResult.new(false, false, &"", {}, "Forge reward is unavailable.")
	if has_applied_reward(transaction.id):
		return RewardService.apply(transaction, self)
	if has_terminal_settlement() or forge_catalog == null or selected_profile == null:
		return RewardResult.new(false, false, transaction.id, {}, "Forge reward is unavailable.")
	var item_id := StringName(payload.get("item_id", &""))
	var affix_id := StringName(payload.get("affix_id", &""))
	var item := ProfileState.equipment_catalog.get_item(item_id)
	var affix := forge_catalog.get_affix(affix_id)
	var loadout := ProfileState.get_loadout(selected_profile.id)
	if (
		item == null
		or affix == null
		or StringName(loadout.get(String(item.slot), &"")) != item_id
		or not affix.supports_slot(item.slot)
	):
		return RewardResult.new(false, false, transaction.id, {}, "Forge replacement is invalid.")

	var item_key := String(item_id)
	var previous_affix := StringName(_temporary_affixes.get(item_key, &""))
	# Rebuild before consuming the reward ID so any invalid affix can roll back atomically.
	_temporary_affixes[item_key] = String(affix_id)
	if not _rebuild_effective_build():
		_restore_temporary_affix(item_key, previous_affix)
		return RewardResult.new(false, false, transaction.id, {}, "Forge replacement produced an invalid build.")
	var result := RewardService.apply(transaction, self)
	if not result.applied and not result.duplicate:
		_restore_temporary_affix(item_key, previous_affix)
		return result
	if _is_stage_cache_reward(transaction):
		_stage_cache_discoveries[str(current_stage_index)] = true
	_rebuild_forge_behavior_counters()
	_publish_state()
	return result


func _restore_temporary_affix(item_key: String, previous_affix: StringName) -> void:
	if previous_affix == &"":
		_temporary_affixes.erase(item_key)
	else:
		_temporary_affixes[item_key] = String(previous_affix)
	_rebuild_effective_build()
	_rebuild_forge_behavior_counters()


func can_reroll_card_offer() -> bool:
	if not _card_reward_pending or _card_reroll_used or coins < get_card_reroll_cost():
		return false
	return CardOfferService.eligible_ids(
		card_catalog,
		HERO_CARD_PROFILE_ID,
		_card_stacks,
		[],
		HERO_CARD_TRIGGERS
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
			HERO_CARD_PROFILE_ID,
			_card_stacks,
			run_seed,
			current_stage_index,
			candidate_sequence,
			[],
			HERO_CARD_TRIGGERS
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
	return CARD_REROLL_COST


func choose_card(card_id: StringName) -> Dictionary:
	if not _card_reward_pending:
		return {"ok": false, "message": "No card reward is pending."}
	if not _pending_card_offer.has(card_id):
		return {"ok": false, "message": "Card is not in the current offer."}
	var card := get_card_definition(card_id)
	if card == null or not card.is_compatible(HERO_CARD_PROFILE_ID):
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
		var current_affix_id := StringName(_temporary_affixes.get(String(item.id), ""))
		var current_affix := forge_catalog.get_affix(current_affix_id) if forge_catalog != null else null
		item_rows.append({
			"id": String(item.id),
			"display_name": item.display_name,
			"slot": String(item.slot),
			"description": item.mechanical_description,
			"tradeoff": item.tradeoff_description,
			"base_effects": _build_effect_rows(item.build_effects),
			"affix_id": String(current_affix_id),
			"affix_name": current_affix.display_name if current_affix != null else "",
			"affix_description": current_affix.mechanical_description if current_affix != null else "",
		})
	var offer_rows: Array[Dictionary] = []
	for affix_id in _forge_offer:
		var affix := forge_catalog.get_affix(affix_id) if forge_catalog != null else null
		if affix != null:
			var preview := _preview_forge_affix(_forge_offer_item_id, affix)
			offer_rows.append({
				"id": String(affix.id),
				"display_name": affix.display_name,
				"description": affix.mechanical_description,
				"projected_stats": preview.get("projected_stats", {}),
				"stat_deltas": preview.get("stat_deltas", []),
				"validation_errors": preview.get("validation_errors", []),
				"final_coins": maxi(coins - (forge_catalog.coin_cost if forge_catalog != null else 15), 0),
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
		"effective_stats": get_effective_stats(),
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


func _apply_hero_build(
	profile_index: int,
	legacy_profile: CharacterProfile,
	build_snapshot: PlayerBuildSnapshot,
	combat_loadout: Dictionary
) -> void:
	selected_profile_index = profile_index
	selected_profile = legacy_profile
	hero_combat_loadout = combat_loadout.duplicate(true)
	effective_build_snapshot = build_snapshot
	effective_stats = build_snapshot.get_values()


func _rebuild_effective_build() -> bool:
	if selected_profile == null or hero_combat_loadout.is_empty():
		return false
	var candidate := PlayerBuild.resolve(
		hero_combat_loadout.get("stats", {}),
		_collect_all_build_effects(_micro_upgrade_stacks)
	)
	if not _is_build_valid(selected_profile, candidate):
		return false
	var previous_health := current_health
	_apply_hero_build(
		selected_profile_index,
		selected_profile,
		candidate,
		hero_combat_loadout
	)
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
	return _collect_build_effects_with_affixes(stacks, _temporary_affixes)


func _collect_build_effects_with_affixes(stacks: Dictionary, affixes: Dictionary) -> Array:
	var effects: Array = _collect_run_effects(stacks)
	if forge_catalog != null:
		var item_ids := affixes.keys()
		item_ids.sort()
		for item_id in item_ids:
			var affix := forge_catalog.get_affix(StringName(affixes[item_id]))
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


func _preview_forge_affix(
	item_id: StringName,
	affix: ForgeAffixDefinition
) -> Dictionary:
	if selected_profile == null or item_id == &"" or affix == null:
		return {"projected_stats": {}, "stat_deltas": [], "validation_errors": []}
	var candidate_affixes := _temporary_affixes.duplicate(true)
	candidate_affixes[String(item_id)] = String(affix.id)
	var candidate := PlayerBuild.resolve(
		hero_combat_loadout.get("stats", {}),
		_collect_build_effects_with_affixes(_micro_upgrade_stacks, candidate_affixes)
	)
	return {
		"projected_stats": candidate.get_values(),
		"stat_deltas": BuildComparison.stat_deltas(
			effective_build_snapshot.get_values(),
			candidate.get_values()
		),
		"validation_errors": candidate.get_validation_errors(),
	}


func _build_effect_rows(effects: Array[EffectDefinition]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for effect in effects:
		if effect == null:
			continue
		rows.append({
			"stat_id": String(effect.stat_id),
			"operation": effect.operation,
			"value": effect.value,
		})
	return rows


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
		HERO_CARD_PROFILE_ID,
		_card_stacks,
		run_seed,
		current_stage_index,
		_card_offer_sequence,
		excluded_ids,
		HERO_CARD_TRIGGERS
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
	if not hero_combat_loadout.is_empty():
		SignalBus.selected_profile_changed.emit(
			String(hero_combat_loadout.get("hero_id", "traveler")),
			String(hero_combat_loadout.get("display_name", "Traveler")),
			hero_combat_loadout.get("visual_color", Color.WHITE)
		)
	elif selected_profile != null:
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
