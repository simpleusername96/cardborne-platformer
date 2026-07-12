extends Node

# Owns mutable facts and atomic commands for one run; UI consumes copy-safe snapshots.

const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"
const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const PROGRESSION_CATALOG_PATH := "res://data/progression/run_progression_catalog.tres"
const CARD_CATALOG_PATH := "res://data/cards/card_catalog.tres"
const CARD_REROLL_COST := 12

const RUN_CURRENCIES: PackedStringArray = ["xp", "coin"]
const MATERIAL_CURRENCIES: PackedStringArray = [
	"rusted_scrap", "sky_thread", "slime_residue", "boss_core",
]

var character_catalog: CharacterCatalog
var reward_catalog: RewardCatalog
var progression_catalog: RunProgressionCatalog
var card_catalog: CardCatalog
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
var _pending_level_choices: int = 0
var _pending_level_offer: Array[StringName] = []
var _level_offer_sequence: int = 0
var _card_reward_pending: bool = false
var _pending_card_offer: Array[StringName] = []
var _card_offer_sequence: int = 0
var _card_reroll_used: bool = false
var _card_reward_stage_index: int = -1
var _committed_card_id: StringName
var _catalogs_valid: bool = false


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
	var candidate_build := PlayerBuild.resolve(candidate_profile.to_base_stats_dictionary())
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
	_pending_level_choices = 0
	_pending_level_offer.clear()
	_level_offer_sequence = 0
	_card_reward_pending = false
	_pending_card_offer.clear()
	_card_offer_sequence = 0
	_card_reroll_used = false
	_card_reward_stage_index = -1
	_committed_card_id = &""
	_publish_state()
	SignalBus.run_started.emit()
	return true


func select_profile(profile_index: int) -> bool:
	if profiles.is_empty():
		return false

	var candidate_index := wrapi(profile_index, 0, profiles.size())
	var candidate_profile := profiles[candidate_index]
	var candidate_build := PlayerBuild.resolve(candidate_profile.to_base_stats_dictionary())
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
		"effective_stats": get_effective_stats(),
	})


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
			return RewardResult.new(
				false,
				false,
				transaction.id,
				{},
				"Reward transaction contains an invalid grant."
			)

	for currency_id in grants:
		var amount := int(grants[currency_id])
		match String(currency_id):
			"xp":
				_grant_xp_internal(amount)
			"coin":
				coins += amount
			_:
				grant_unsettled_material(String(currency_id), amount)
	_applied_reward_ids[transaction_key] = true
	var result := RewardResult.new(
		true,
		false,
		transaction.id,
		grants,
		"Reward applied."
	)
	_publish_snapshot()
	SignalBus.reward_applied.emit(result.to_dictionary())
	if _pending_level_choices > 0:
		SignalBus.level_reward_pending.emit(_pending_level_choices)
	return result


func has_applied_reward(transaction_id: StringName) -> bool:
	return _applied_reward_ids.has(String(transaction_id))


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
		_collect_run_effects(candidate_stacks)
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
	if not _card_reward_pending or _card_reroll_used or coins < CARD_REROLL_COST:
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
	if coins < CARD_REROLL_COST:
		return {"ok": false, "message": "Reroll needs %d coins." % CARD_REROLL_COST}
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

	coins -= CARD_REROLL_COST
	_card_offer_sequence = candidate_sequence
	_card_reroll_used = true
	_pending_card_offer = next_offer
	_publish_snapshot()
	return {
		"ok": true,
		"cost": CARD_REROLL_COST,
		"coins": coins,
		"offer": get_pending_card_offer(),
	}


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
	if _card_reward_pending or _committed_card_id == &"":
		return false
	current_stage_index += 1
	_card_reward_stage_index = -1
	_card_reroll_used = false
	_committed_card_id = &""
	_publish_snapshot()
	return true


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
	if amount <= 0 or current_health <= 0:
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
		_collect_run_effects(_micro_upgrade_stacks)
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
