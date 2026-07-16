extends Node

# Owns mutable facts and atomic commands for one run; UI consumes copy-safe snapshots.

const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const PROGRESSION_CATALOG_PATH := "res://data/progression/run_progression_catalog.tres"
const CARD_CATALOG_PATH := "res://data/cards/card_catalog.tres"
const NORMAL_STAGE_COUNT := RunPhase.NORMAL_STAGE_COUNT
const CARD_REROLL_COST := 12
const MAX_CONSUMABLE_CHARGES := 1

const RUN_CURRENCIES: PackedStringArray = ["xp", "coin", "salvage"]
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
]

var reward_catalog: RewardCatalog
var progression_catalog: RunProgressionCatalog
var card_catalog: CardCatalog
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
var _run_salvage: int = 0
var _unsettled_materials: Dictionary = {}
var _micro_upgrade_stacks: Dictionary = {}
var _card_stacks: Dictionary = {}
var _applied_reward_ids: Dictionary = {}
var _applied_field_pickup_ids: Dictionary = {}
var _applied_merchant_transaction_ids: Dictionary = {}
var _pending_level_choices: int = 0
var _pending_level_offer: Array[StringName] = []
var _level_offer_sequence: int = 0
var _card_reward_pending: bool = false
var _pending_card_offer: Array[StringName] = []
var _card_offer_sequence: int = 0
var _card_reroll_used: bool = false
var _card_reward_stage_index: int = -1
var _committed_card_id: StringName
var current_consumable_id: StringName = &"small_potion"
var consumable_charges: int = 1
var _catalogs_valid: bool = false
var _settlement_service := RunSettlementService.new()
var _merchant_transaction_service := MerchantTransactionService.new()
var _run_started_at_msec: int = 0
var _stage_attempt_snapshot: StageAttemptSnapshot
var _stage_exploration_knowledge: Dictionary = {}


func _ready() -> void:
	_load_run_catalogs()
	start_new_run()


func start_new_run(_profile_index: int = -1, requested_seed: int = -1) -> bool:
	if not _catalogs_valid or _profile_index not in [-1, 0]:
		return false

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
	if not _is_build_valid(HERO_CARD_PROFILE_ID, candidate_build):
		return false
	_apply_hero_build(candidate_build, candidate_hero)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	run_seed = requested_seed if requested_seed >= 0 else _create_run_seed()
	current_stage_index = 0
	run_level = 1
	current_xp = 0
	coins = 0
	_run_salvage = 0
	_unsettled_materials.clear()
	_micro_upgrade_stacks.clear()
	_card_stacks.clear()
	_applied_reward_ids.clear()
	_applied_field_pickup_ids.clear()
	_applied_merchant_transaction_ids.clear()
	_pending_level_choices = 0
	_pending_level_offer.clear()
	_level_offer_sequence = 0
	_card_reward_pending = false
	_pending_card_offer.clear()
	_card_offer_sequence = 0
	_card_reroll_used = false
	_card_reward_stage_index = -1
	_committed_card_id = &""
	var profile_loadout: Dictionary = candidate_hero["loadout"]
	current_consumable_id = StringName(profile_loadout.get("consumable", "small_potion"))
	consumable_charges = 1
	_run_started_at_msec = Time.get_ticks_msec()
	_stage_attempt_snapshot = null
	_stage_exploration_knowledge.clear()
	_settlement_service.reset(ProfileState)
	_publish_state()
	SignalBus.run_started.emit()
	return true


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


func synchronize_hero_profile() -> Dictionary:
	var candidate := ProfileState.get_hero_combat_snapshot()
	if not bool(candidate.get("ok", false)):
		return {
			"ok": false,
			"message": candidate.get("message", "Traveler equipment is invalid."),
		}
	var candidate_build := PlayerBuild.resolve(
		candidate.get("stats", {}),
		_collect_all_build_effects(_micro_upgrade_stacks)
	)
	if not _is_build_valid(HERO_CARD_PROFILE_ID, candidate_build):
		return {"ok": false, "message": "Traveler equipment produced an invalid build."}
	var previous_health := current_health
	_apply_hero_build(candidate_build, candidate)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = clampi(previous_health, 0, max_health)
	_publish_state()
	return {"ok": true, "message": "Traveler equipment synchronized."}


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
		"run_salvage": _run_salvage,
		"applied_merchant_transaction_ids": get_applied_merchant_transaction_ids(),
		"materials": get_unsettled_materials(),
		"cards": _card_stacks.duplicate(true),
		"micro_upgrades": _micro_upgrade_stacks.duplicate(true),
		"pending_level_choices": _pending_level_choices,
		"card_reward_pending": _card_reward_pending,
		"card_offer": _string_name_array_to_strings(_pending_card_offer),
		"card_reroll_used": _card_reroll_used,
		"consumable_id": String(current_consumable_id),
		"consumable_charges": consumable_charges,
		"effective_stats": get_effective_stats(),
		"elapsed_seconds": get_run_elapsed_seconds(),
		"terminal_settlement": terminal_settlement,
	})


func capture_stage_attempt(stage_path: String, boss_attempt: bool) -> Dictionary:
	if has_terminal_settlement() or current_health <= 0:
		return _stage_attempt_failure("An active, unsettled run is required.")
	var profile_resources := _capture_stage_attempt_profile_resources()
	if profile_resources.is_empty():
		return _stage_attempt_failure("Stage attempt profile resources are unavailable.")
	var candidate := StageAttemptSnapshot.new({
		"version": StageAttemptSnapshot.VERSION,
		"run_seed": run_seed,
		"stage_index": current_stage_index,
		"stage_path": stage_path,
		"boss_attempt": boss_attempt,
		"run_state": {
			"run_seed": run_seed,
			"stage_index": current_stage_index,
			"current_health": current_health,
			"max_health": max_health,
			"run_level": run_level,
			"current_xp": current_xp,
			"coins": coins,
			"run_salvage": _run_salvage,
			"unsettled_materials": _unsettled_materials.duplicate(true),
			"micro_upgrade_stacks": _micro_upgrade_stacks.duplicate(true),
			"card_stacks": _card_stacks.duplicate(true),
			"applied_reward_ids": _applied_reward_ids.duplicate(true),
			"applied_field_pickup_ids": _applied_field_pickup_ids.duplicate(true),
			"applied_merchant_transaction_ids": (
				_applied_merchant_transaction_ids.duplicate(true)
			),
			"pending_level_choices": _pending_level_choices,
			"pending_level_offer": _string_name_array_to_strings(_pending_level_offer),
			"level_offer_sequence": _level_offer_sequence,
			"card_reward_pending": _card_reward_pending,
			"pending_card_offer": _string_name_array_to_strings(_pending_card_offer),
			"card_offer_sequence": _card_offer_sequence,
			"card_reroll_used": _card_reroll_used,
			"card_reward_stage_index": _card_reward_stage_index,
			"committed_card_id": String(_committed_card_id),
			"current_consumable_id": String(current_consumable_id),
			"consumable_charges": consumable_charges,
			"hero_combat_loadout": hero_combat_loadout.duplicate(true),
		},
		"profile_resources": profile_resources,
	})
	if not candidate.is_valid():
		return _stage_attempt_failure(
			"Stage attempt capture is incomplete: %s"
			% "; ".join(candidate.get_validation_errors())
		)
	_stage_attempt_snapshot = candidate
	return {
		"ok": true,
		"message": "Stage attempt captured.",
		"snapshot": candidate.to_dictionary(),
	}


func has_stage_attempt_snapshot() -> bool:
	return _stage_attempt_snapshot != null and _stage_attempt_snapshot.is_valid()


func get_stage_attempt_snapshot() -> StageAttemptSnapshot:
	return _stage_attempt_snapshot


func get_stage_attempt_snapshot_data() -> Dictionary:
	return (
		_stage_attempt_snapshot.to_dictionary()
		if _stage_attempt_snapshot != null
		else {}
	)


func begin_stage_exploration(content_signature: String) -> Dictionary:
	if content_signature.is_empty():
		return {}
	if not _stage_exploration_knowledge.has(content_signature):
		_stage_exploration_knowledge[content_signature] = {
			"visited_room_ids": [],
			"discovered_marker_ids": [],
		}
	return get_stage_exploration_knowledge(content_signature)


func update_stage_exploration(
	content_signature: String,
	knowledge: Dictionary
) -> bool:
	if content_signature.is_empty():
		return false
	var normalized := _normalize_stage_exploration_knowledge(knowledge)
	var previous := _stage_exploration_knowledge.get(content_signature, {}) as Dictionary
	if previous == normalized:
		return false
	_stage_exploration_knowledge[content_signature] = normalized
	return true


func get_stage_exploration_knowledge(content_signature: String) -> Dictionary:
	if content_signature.is_empty():
		return {}
	var value := _stage_exploration_knowledge.get(content_signature, {}) as Dictionary
	return value.duplicate(true)


func get_all_stage_exploration_knowledge() -> Dictionary:
	return _stage_exploration_knowledge.duplicate(true)


func restore_stage_attempt() -> Dictionary:
	if has_terminal_settlement():
		return _stage_attempt_failure("A settled run cannot restore an attempt.")
	if _stage_attempt_snapshot == null or not _stage_attempt_snapshot.is_valid():
		return _stage_attempt_failure("No complete stage attempt snapshot is available.")
	if (
		run_seed != _stage_attempt_snapshot.get_run_seed()
		or current_stage_index != _stage_attempt_snapshot.get_stage_index()
	):
		return _stage_attempt_failure("Stage attempt identity no longer matches the active run.")

	var run_data := _stage_attempt_snapshot.get_run_state()
	var candidate_loadout: Dictionary = run_data.get("hero_combat_loadout", {}).duplicate(true)
	var candidate_micro_upgrades: Dictionary = run_data.get("micro_upgrade_stacks", {}).duplicate(true)
	var candidate_build := PlayerBuild.resolve(
		candidate_loadout.get("stats", {}),
		_collect_all_build_effects(candidate_micro_upgrades)
	)
	if not _is_build_valid(HERO_CARD_PROFILE_ID, candidate_build):
		return _stage_attempt_failure("Stage attempt build is invalid.")
	var candidate_max_health := int(candidate_build.get_values().get("max_health", 0))
	if candidate_max_health != int(run_data.get("max_health", -1)):
		return _stage_attempt_failure("Stage attempt maximum health is inconsistent.")

	# Profile persistence is committed only after the complete run candidate validates.
	var profile_restore: Dictionary = ProfileState.restore_stage_attempt_resources(
		_stage_attempt_snapshot.get_profile_resources()
	)
	if not bool(profile_restore.get("ok", false)):
		return _stage_attempt_failure(
			"Stage attempt profile restore failed: %s"
			% profile_restore.get("message", "Unknown error.")
		)

	run_seed = int(run_data["run_seed"])
	current_stage_index = int(run_data["stage_index"])
	run_level = int(run_data["run_level"])
	current_xp = int(run_data["current_xp"])
	coins = int(run_data["coins"])
	_run_salvage = int(run_data["run_salvage"])
	_unsettled_materials = (run_data["unsettled_materials"] as Dictionary).duplicate(true)
	_micro_upgrade_stacks = candidate_micro_upgrades
	_card_stacks = (run_data["card_stacks"] as Dictionary).duplicate(true)
	_applied_reward_ids = (run_data["applied_reward_ids"] as Dictionary).duplicate(true)
	_applied_field_pickup_ids = (run_data["applied_field_pickup_ids"] as Dictionary).duplicate(true)
	_applied_merchant_transaction_ids = (
		(run_data["applied_merchant_transaction_ids"] as Dictionary).duplicate(true)
	)
	_pending_level_choices = int(run_data["pending_level_choices"])
	_pending_level_offer = _strings_to_string_name_array(run_data["pending_level_offer"] as Array)
	_level_offer_sequence = int(run_data["level_offer_sequence"])
	_card_reward_pending = bool(run_data["card_reward_pending"])
	_pending_card_offer = _strings_to_string_name_array(run_data["pending_card_offer"] as Array)
	_card_offer_sequence = int(run_data["card_offer_sequence"])
	_card_reroll_used = bool(run_data["card_reroll_used"])
	_card_reward_stage_index = int(run_data["card_reward_stage_index"])
	_committed_card_id = StringName(run_data["committed_card_id"])
	current_consumable_id = StringName(run_data["current_consumable_id"])
	consumable_charges = int(run_data["consumable_charges"])
	_apply_hero_build(candidate_build, candidate_loadout)
	max_health = candidate_max_health
	current_health = int(run_data["current_health"])
	_publish_state()
	return {
		"ok": true,
		"message": "Stage attempt restored.",
		"snapshot": get_run_snapshot().to_dictionary(),
	}


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


func get_run_salvage() -> int:
	return _run_salvage


func get_applied_merchant_transaction_ids() -> Array[String]:
	var result: Array[String] = []
	for transaction_id in _applied_merchant_transaction_ids:
		result.append(String(transaction_id))
	result.sort()
	return result


func get_merchant_snapshot() -> Dictionary:
	var run_facts := _merchant_run_facts()
	var buy_preview := _merchant_transaction_service.preview(
		MerchantTransactionService.BUY_POTION,
		run_facts
	)
	var sell_preview := _merchant_transaction_service.preview(
		MerchantTransactionService.SELL_ALL_SALVAGE,
		run_facts
	)
	return {
		"coins": coins,
		"run_salvage": _run_salvage,
		"consumable_id": String(current_consumable_id),
		"consumable_charges": consumable_charges,
		"max_consumable_charges": MAX_CONSUMABLE_CHARGES,
		"buy_potion": buy_preview,
		"sell_run_salvage": sell_preview.duplicate(true),
		"sell_all_salvage": sell_preview,
		"applied_transaction_ids": get_applied_merchant_transaction_ids(),
	}


func buy_merchant_potion(transaction_id: StringName) -> Dictionary:
	return _merchant_result(
		apply_merchant_transaction(transaction_id, MerchantTransactionService.BUY_POTION)
	)


func sell_run_salvage(transaction_id: StringName) -> Dictionary:
	return _merchant_result(
		apply_merchant_transaction(transaction_id, MerchantTransactionService.SELL_ALL_SALVAGE)
	)


func preview_merchant_transaction(kind: StringName) -> Dictionary:
	return _merchant_transaction_service.preview(kind, _merchant_run_facts())


func apply_merchant_transaction(
	transaction_id: StringName,
	kind: StringName
) -> MerchantTransactionReceipt:
	var receipt := _merchant_transaction_service.execute(
		transaction_id,
		kind,
		_merchant_run_facts(),
		_applied_merchant_transaction_ids
	)
	if receipt.is_applied():
		var after: Dictionary = receipt.get_value(&"after", {})
		coins = int(after["coins"])
		_run_salvage = int(after["run_salvage"])
		consumable_charges = int(after["consumable_charges"])
		_applied_merchant_transaction_ids[String(transaction_id)] = true
		_publish_state()
	return receipt


func _merchant_result(receipt: MerchantTransactionReceipt) -> Dictionary:
	return {
		"ok": receipt.is_applied(),
		"duplicate": receipt.is_duplicate(),
		"message": receipt.get_message(),
		"receipt": receipt.to_dictionary(),
		"snapshot": get_run_snapshot().to_dictionary(),
	}


func _merchant_run_facts() -> Dictionary:
	return {
		"active": not has_terminal_settlement() and current_health > 0,
		"coins": coins,
		"run_salvage": _run_salvage,
		"consumable_charges": consumable_charges,
		"max_consumable_charges": MAX_CONSUMABLE_CHARGES,
	}


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

	for currency_id in grants:
		var amount := int(grants[currency_id])
		match String(currency_id):
			"xp":
				_grant_xp_internal(amount)
			"coin":
				coins += amount
			"salvage":
				_run_salvage += amount
			_:
				if bool(progression_settlement.get("changed", false)):
					grant_unsettled_material(String(currency_id), amount)
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
	_player: Node = null
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
	return {}


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
	current_stage_index += 1
	_card_reward_stage_index = -1
	_card_reroll_used = false
	_committed_card_id = &""
	_publish_snapshot()
	return true


func use_consumable() -> Dictionary:
	if consumable_charges <= 0:
		return {"ok": false, "message": "No consumable charge remains."}
	if current_consumable_id != &"small_potion":
		return {"ok": false, "message": "Consumable is unavailable."}
	if current_health >= max_health:
		return {"ok": false, "message": "Health is already full."}
	heal_player(2)
	consumable_charges -= 1
	_publish_state()
	return {"ok": true, "message": "Healing Potion used.", "snapshot": get_run_snapshot().to_dictionary()}


func get_movement_metrics() -> Dictionary:
	return MovementMetrics.calculate(effective_stats)


func get_required_route_limits() -> Dictionary:
	return MovementMetrics.route_limits_for_stats(
		effective_stats,
		HERO_CARD_PROFILE_ID,
		String(hero_combat_loadout.get("display_name", "Traveler"))
	)


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


func _is_build_valid(owner_id: StringName, build_snapshot: PlayerBuildSnapshot) -> bool:
	if build_snapshot.is_valid():
		return true
	for error in build_snapshot.get_validation_errors():
		push_error(
			"Invalid player build for '%s': %s"
			% [owner_id, error.get("message", "Unknown error.")]
		)
	return false


func _apply_hero_build(
	build_snapshot: PlayerBuildSnapshot,
	combat_loadout: Dictionary
) -> void:
	hero_combat_loadout = combat_loadout.duplicate(true)
	effective_build_snapshot = build_snapshot
	effective_stats = build_snapshot.get_values()


func _rebuild_effective_build() -> bool:
	if hero_combat_loadout.is_empty():
		return false
	var candidate := PlayerBuild.resolve(
		hero_combat_loadout.get("stats", {}),
		_collect_all_build_effects(_micro_upgrade_stacks)
	)
	if not _is_build_valid(HERO_CARD_PROFILE_ID, candidate):
		return false
	var previous_health := current_health
	_apply_hero_build(candidate, hero_combat_loadout)
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
	return _collect_run_effects(stacks)


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


func _strings_to_string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		if value is String or value is StringName:
			result.append(StringName(value))
	return result


func _capture_stage_attempt_profile_resources() -> Dictionary:
	if (
		ProfileState == null
		or not ProfileState.has_method("get_crafted_equipment")
		or not ProfileState.has_method("get_ranged_supplies")
	):
		return {}
	var crafted: Dictionary = ProfileState.get_crafted_equipment()
	var equipment_conditions: Dictionary = {}
	for raw_model_id in crafted:
		var model_id := String(raw_model_id)
		if not ProfileData.CONDITION_MODEL_IDS.has(model_id):
			continue
		var raw_state: Variant = crafted[raw_model_id]
		if not raw_state is Dictionary:
			return {}
		var condition: Variant = (raw_state as Dictionary).get("condition", null)
		if not (condition is int or condition is float) or not is_finite(float(condition)):
			return {}
		equipment_conditions[model_id] = float(condition)
	return {
		"equipment_conditions": equipment_conditions,
		"ranged_supplies": ProfileState.get_ranged_supplies(),
	}


func _stage_attempt_failure(message: String) -> Dictionary:
	return {
		"ok": false,
		"message": message,
		"snapshot": {},
	}


func _normalize_stage_exploration_knowledge(knowledge: Dictionary) -> Dictionary:
	var visited: Array[String] = []
	for room_id in knowledge.get("visited_room_ids", []):
		var normalized := String(room_id)
		if not normalized.is_empty() and not visited.has(normalized):
			visited.append(normalized)
	visited.sort()
	var discovered: Array[String] = []
	for marker_id in knowledge.get("discovered_marker_ids", []):
		var normalized := String(marker_id)
		if not normalized.is_empty() and not discovered.has(normalized):
			discovered.append(normalized)
	discovered.sort()
	return {
		"visited_room_ids": visited,
		"discovered_marker_ids": discovered,
	}


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
		SignalBus.hero_changed.emit(
			String(hero_combat_loadout.get("hero_id", "traveler")),
			String(hero_combat_loadout.get("display_name", "Traveler")),
			hero_combat_loadout.get("visual_color", Color.WHITE)
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
