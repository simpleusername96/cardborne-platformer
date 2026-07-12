extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const ENEMY_CATALOG := preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG := preload("res://data/hazards/hazard_catalog.tres")
const REWARD_CATALOG := preload("res://data/rewards/reward_catalog.tres")
const RUIN_PROFILE := preload("res://data/generation/ruin_approach_profile.tres")
const RUIN_ROOMS := preload("res://data/generation/lower_ruins_room_catalog.tres")
const FLOODED_PROFILE := preload("res://data/generation/flooded_works_profile.tres")
const FLOODED_ROOMS := preload("res://data/generation/flooded_works_room_catalog.tres")
const SANCTUM_PROFILE := preload("res://data/generation/broken_sanctum_profile.tres")
const SANCTUM_ROOMS := preload("res://data/generation/broken_sanctum_room_catalog.tres")

const SEEDS: Array[int] = [1103, 2207, 29017, 41000, 73021, 93117]
const STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"profile": RUIN_PROFILE,
		"rooms": RUIN_ROOMS,
		"clear": &"stage_clear_ruin_approach",
	},
	{
		"id": &"flooded_works",
		"profile": FLOODED_PROFILE,
		"rooms": FLOODED_ROOMS,
		"clear": &"stage_clear_flooded_works",
	},
	{
		"id": &"broken_sanctum",
		"profile": SANCTUM_PROFILE,
		"rooms": SANCTUM_ROOMS,
		"clear": &"stage_clear_broken_sanctum",
	},
]

var _failures: Array[String] = []
var _run_state: Node
var _profile_state: Node
var _checkpoint_values := {
	"critical": [[], [], []],
	"engaged": [[], [], []],
	"explorer": [[], [], []],
}
var _final_spends := {"critical": [], "engaged": [], "explorer": []}
var _xp_checkpoints := {
	"critical": [[], [], []],
	"engaged": [[], [], []],
	"explorer": [[], [], []],
}
var _final_xp := {"critical": [], "engaged": [], "explorer": []}
var _final_levels := {"critical": [], "engaged": [], "explorer": []}
var _build_signatures: Dictionary = {}
var _explorer_mastery_ready := 0
var _explorer_equipment_ready := 0
var _mastery_ready_by_profile: Dictionary = {}
var _equipment_ready_by_profile: Dictionary = {}
var _level_six_by_profile: Dictionary = {}
var _scenario_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_expect(_run_state != null and _profile_state != null, "balance matrix needs production state")
	if _run_state == null or _profile_state == null:
		_finish()
		return

	for profile_index in _run_state.profiles.size():
		var profile: CharacterProfile = _run_state.profiles[profile_index]
		var profile_key := String(profile.id)
		_build_signatures[profile_key] = {}
		_mastery_ready_by_profile[profile_key] = 0
		_equipment_ready_by_profile[profile_key] = 0
		_level_six_by_profile[profile_key] = 0
		for seed in SEEDS:
			_simulate(profile_index, seed, "critical")
			_simulate(profile_index, seed, "engaged")
			_simulate(profile_index, seed, "explorer")

	for profile_id in _build_signatures:
		_expect(
			(_build_signatures[profile_id] as Dictionary).size() >= 3,
			"%s should produce at least three distinct three-card builds" % profile_id
		)
		_expect(
			int(_level_six_by_profile[profile_id]) > 0,
			"%s should have at least one normal-participation seed reaching level 6"
			% profile_id
		)
		_expect(
			int(_mastery_ready_by_profile[profile_id]) == SEEDS.size(),
			"every explorer %s victory should afford a matching root mastery" % profile_id
		)
		_expect(
			int(_equipment_ready_by_profile[profile_id]) == SEEDS.size(),
			"every explorer %s victory should expose alternate equipment" % profile_id
		)
	_expect(
		_average(_checkpoint_values["engaged"][0]) >= 18.0
		and _average(_checkpoint_values["engaged"][0]) <= 28.0,
		"normal Stage 1 average should stay inside the 18-28 coin target"
	)
	_expect(
		_average(_checkpoint_values["engaged"][1]) >= 38.0
		and _average(_checkpoint_values["engaged"][1]) <= 58.0,
		"normal Stage 2 average should stay inside the 38-58 coin target"
	)
	_expect(
		_average(_checkpoint_values["engaged"][2]) >= 65.0
		and _average(_checkpoint_values["engaged"][2]) <= 95.0,
		"normal Stage 3 average should stay inside the 65-95 coin target"
	)
	_expect(
		_maximum(_checkpoint_values["explorer"][2]) <= 105,
		"complete exploration should not create runaway final coins"
	)
	_expect(
		_explorer_mastery_ready >= 12,
		"at least two thirds of explorer runs should afford a matching root mastery"
	)
	_expect(
		_explorer_equipment_ready >= 12,
		"at least two thirds of explorer runs should afford or discover alternate equipment"
	)
	_finish()


func _simulate(profile_index: int, seed: int, mode: String) -> void:
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_expect(
		_run_state.start_new_run(profile_index, seed),
		"profile %d seed %d should start" % [profile_index, seed]
	)
	if _run_state.selected_profile == null:
		return
	var profile_id := StringName(_run_state.selected_profile.id)
	var gross_coins := 0
	var spent_coins := 0

	for stage_index in STAGES.size():
		var stage: Dictionary = STAGES[stage_index]
		var generation := StageGenerationService.new().generate(
			stage["rooms"],
			stage["profile"],
			ENEMY_CATALOG,
			HAZARD_CATALOG,
			REWARD_CATALOG,
			seed,
			stage_index,
			_run_state.get_required_route_limits()
		)
		_expect(
			generation.success and generation.plan != null,
			"%s seed %d stage %d should generate" % [profile_id, seed, stage_index + 1]
		)
		if generation.plan == null:
			return
		gross_coins += _settle_stage_plan(
			generation.plan,
			stage,
			seed,
			stage_index,
			mode
		)
		(_checkpoint_values[mode][stage_index] as Array).append(gross_coins)
		(_xp_checkpoints[mode][stage_index] as Array).append(int(_run_state.current_xp))
		_settle_level_choices(seed, stage_index)

		var begin_card: Dictionary = _run_state.begin_stage_card_reward()
		_expect(bool(begin_card.get("ok", false)), "stage card offer should open")
		if mode == "explorer" and stage_index == 0 and _run_state.can_reroll_card_offer():
			var reroll: Dictionary = _run_state.reroll_card_offer()
			_expect(bool(reroll.get("ok", false)), "explorer Stage 1 reroll should commit")
			if bool(reroll.get("ok", false)):
				spent_coins += int(reroll.get("cost", 0))
		var offer: Array[StringName] = _run_state.get_pending_card_offer()
		_expect(offer.size() == CardOfferService.CHOICE_COUNT, "card offer should stay complete")
		if offer.is_empty():
			return
		var card_index := posmod(seed + stage_index * 7 + profile_index * 3, offer.size())
		var card_id := offer[card_index]
		var card: CardDefinition = _run_state.get_card_definition(card_id)
		_expect(
			card != null and card.is_compatible(profile_id),
			"offered card should remain compatible with %s" % profile_id
		)
		_expect(
			bool(_run_state.choose_card(card_id).get("ok", false)),
			"offered card should commit"
		)
		_expect(_run_state.advance_stage_after_card_reward(), "card choice should advance stage")

		if stage_index == 1:
			spent_coins += _exercise_rest_and_forge()

	_expect(_run_state.current_stage_index == 3, "three cards should reach the boss boundary")
	(_final_xp[mode] as Array).append(int(_run_state.current_xp))
	(_final_levels[mode] as Array).append(int(_run_state.run_level))
	if mode == "engaged" and int(_run_state.run_level) == 6:
		_level_six_by_profile[String(profile_id)] = int(
			_level_six_by_profile[String(profile_id)]
		) + 1
	_expect(_run_state.get_card_stacks().size() >= 1, "run should retain selected cards")
	_expect(_total_card_stacks(_run_state.get_card_stacks()) == 3, "run should retain exactly three card picks")
	_expect(
		spent_coins >= 16 and spent_coins <= 45,
		"%s seed %d spend %d should stay inside the intended final range"
		% [mode, seed, spent_coins]
	)
	_expect(_run_state.coins == gross_coins - spent_coins, "gross coin accounting should reconcile")
	(_final_spends[mode] as Array).append(spent_coins)

	if mode == "explorer":
		(_build_signatures[String(profile_id)] as Dictionary)[_card_signature()] = true

	var settlement: Dictionary = _run_state.settle_run_victory()
	_expect(bool(settlement.get("ok", false)), "boss victory settlement should commit")
	var snapshot := settlement.get("settlement") as RunSettlementSnapshot
	_expect(snapshot != null and snapshot.is_victory(), "complete-run settlement should be victorious")
	if snapshot != null:
		var result := snapshot.to_dictionary()
		_expect(
			int((result.get("persistent_material_delta", {}) as Dictionary).get("boss_core", 0)) == 1,
			"victory should grant exactly one Boss Core"
		)
	if mode == "explorer":
		if _affordable_root_count(profile_id) > 0:
			_explorer_mastery_ready += 1
			_mastery_ready_by_profile[String(profile_id)] = int(
				_mastery_ready_by_profile[String(profile_id)]
			) + 1
		if _alternate_equipment_ready(profile_id):
			_explorer_equipment_ready += 1
			_equipment_ready_by_profile[String(profile_id)] = int(
				_equipment_ready_by_profile[String(profile_id)]
			) + 1
	_scenario_count += 1


func _settle_stage_plan(
	plan: StagePlan,
	stage: Dictionary,
	seed: int,
	stage_index: int,
	mode: String
) -> int:
	var earned := 0
	var optional_rooms: Array[PlannedRoom] = []
	for planned_room in plan.get_rooms():
		if not planned_room.required_route:
			optional_rooms.append(planned_room)
	optional_rooms.sort_custom(func(left: PlannedRoom, right: PlannedRoom) -> bool:
		return String(left.id) < String(right.id)
	)
	var engaged_room_id: StringName = &""
	if not optional_rooms.is_empty():
		engaged_room_id = optional_rooms[posmod(seed + stage_index, optional_rooms.size())].id
	for encounter in plan.get_encounters():
		var room := plan.get_room(encounter.room_id)
		var include_encounter := (
			room != null
			and (
				room.required_route
				or mode == "explorer"
				or (mode == "engaged" and room.id == engaged_room_id)
			)
		)
		if not include_encounter:
			continue
		var variant := ENEMY_CATALOG.get_variant_by_id(encounter.variant_id)
		_expect(variant != null, "planned encounter should resolve its enemy variant")
		if variant == null:
			continue
		earned += _apply_reward_table(
			variant.drop_source_id,
			StringName("%d:%d:%s" % [seed, stage_index, encounter.id]),
			seed
		)

	if mode != "critical":
		for reward in plan.get_rewards():
			var reward_room := plan.get_room(reward.room_id)
			if (
				mode == "engaged"
				and reward_room != null
				and not reward_room.required_route
				and reward_room.id != engaged_room_id
			):
				continue
			earned += _apply_reward_table(
				reward.reward_table_id,
				StringName("%d:%d:%s" % [seed, stage_index, reward.id]),
				seed
			)

	earned += _apply_reward_table(
		stage["clear"],
		StringName("%d:%d:%s:stage_clear:0" % [seed, stage_index, stage["id"]]),
		seed
	)
	return earned


func _apply_reward_table(table_id: StringName, transaction_id: StringName, seed: int) -> int:
	var table := REWARD_CATALOG.get_table(table_id)
	_expect(table != null, "reward table %s should exist" % table_id)
	if table == null:
		return 0
	var transaction := RewardService.resolve_with_context(
		table,
		transaction_id,
		seed,
		_run_state.get_reward_resolution_context()
	)
	var result := RewardService.apply(transaction, _run_state)
	_expect(result.applied and not result.duplicate, "reward %s should apply once" % transaction_id)
	return int(result.grants.get("coin", 0)) if result.applied else 0


func _settle_level_choices(seed: int, stage_index: int) -> void:
	while _run_state.get_pending_level_choice_count() > 0:
		var offer: Array[StringName] = _run_state.get_pending_level_offer()
		_expect(offer.size() == ProgressionOfferService.CHOICE_COUNT, "level offer should stay complete")
		if offer.is_empty():
			return
		var index := posmod(seed + stage_index * 5 + _run_state.get_pending_level_choice_count(), offer.size())
		_expect(
			bool(_run_state.choose_micro_upgrade(offer[index]).get("ok", false)),
			"offered level upgrade should commit"
		)


func _exercise_rest_and_forge() -> int:
	var spent := 0
	_run_state.damage_player(2)
	_expect(bool(_run_state.begin_rest_forge().get("ok", false)), "rest/forge should open")
	var heal: Dictionary = _run_state.buy_rest_heal()
	_expect(bool(heal.get("ok", false)), "normal injury should permit the eight-coin heal")
	if bool(heal.get("ok", false)):
		spent += _run_state.REST_HEAL_COST

	var snapshot: Dictionary = _run_state.get_rest_forge_snapshot()
	var items: Array = snapshot.get("items", [])
	_expect(not items.is_empty(), "rest/forge should list equipped items")
	if not items.is_empty():
		var item_id := StringName(items[0].get("id", ""))
		var begin_forge: Dictionary = _run_state.begin_forge_offer(item_id)
		_expect(bool(begin_forge.get("ok", false)), "equipped item should produce a forge offer")
		var offer_rows: Array = _run_state.get_rest_forge_snapshot().get("forge_offer", [])
		_expect(offer_rows.size() == 3, "forge should present three exact choices")
		if not offer_rows.is_empty():
			var affix_id := StringName(offer_rows[0].get("id", ""))
			var committed: Dictionary = _run_state.commit_forge_affix(item_id, affix_id)
			_expect(bool(committed.get("ok", false)), "forge choice should commit")
			if bool(committed.get("ok", false)):
				spent += int(snapshot.get("forge_cost", 15))
	_expect(_run_state.end_rest_forge(), "rest/forge should close")
	return spent


func _affordable_root_count(profile_id: StringName) -> int:
	var materials: Dictionary = _profile_state.get_materials()
	var count := 0
	for node in MASTERY_CATALOG.get_for_character(profile_id):
		if node.depth == &"root" and _can_afford(node.costs, materials):
			count += 1
	return count


func _alternate_equipment_ready(profile_id: StringName) -> bool:
	var owned: Array[String] = _profile_state.get_owned_equipment()
	var materials: Dictionary = _profile_state.get_materials()
	for item in EQUIPMENT_CATALOG.get_compatible(profile_id):
		if item.starting_item:
			continue
		if owned.has(String(item.id)) or _can_afford(item.unlock_costs, materials):
			return true
	return false


func _can_afford(costs: Dictionary, wallet: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for material_id in costs:
		if int(wallet.get(String(material_id), 0)) < int(costs[material_id]):
			return false
	return true


func _card_signature() -> String:
	var stacks: Dictionary = _run_state.get_card_stacks()
	var ids := stacks.keys()
	ids.sort()
	var parts: Array[String] = []
	for card_id in ids:
		parts.append("%s:%d" % [card_id, int(stacks[card_id])])
	return "|".join(parts)


func _total_card_stacks(stacks: Dictionary) -> int:
	var total := 0
	for card_id in stacks:
		total += int(stacks[card_id])
	return total


func _range_text(values: Array) -> String:
	if values.is_empty():
		return "missing"
	var minimum := int(values[0])
	var maximum := minimum
	for value in values:
		minimum = mini(minimum, int(value))
		maximum = maxi(maximum, int(value))
	return "%d-%d" % [minimum, maximum]


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _maximum(values: Array) -> int:
	var maximum := 0
	for value in values:
		maximum = maxi(maximum, int(value))
	return maximum


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 80:
		_failures.append(message)


func _finish() -> void:
	var summary := (
		"scenarios=%d coins_critical=%s/%s/%s coins_engaged=%s/%s/%s "
		+ "coins_explorer=%s/%s/%s spend=%s/%s/%s xp_steps=%s/%s/%s|%s/%s/%s|%s/%s/%s "
		+ "xp_final=%s/%s/%s levels=%s/%s/%s "
		+ "averages=%.1f/%.1f/%.1f mastery_ready=%d:%s equipment_ready=%d:%s level6=%s"
	) % [
		_scenario_count,
		_range_text(_checkpoint_values["critical"][0]),
		_range_text(_checkpoint_values["critical"][1]),
		_range_text(_checkpoint_values["critical"][2]),
		_range_text(_checkpoint_values["engaged"][0]),
		_range_text(_checkpoint_values["engaged"][1]),
		_range_text(_checkpoint_values["engaged"][2]),
		_range_text(_checkpoint_values["explorer"][0]),
		_range_text(_checkpoint_values["explorer"][1]),
		_range_text(_checkpoint_values["explorer"][2]),
		_range_text(_final_spends["critical"]),
		_range_text(_final_spends["engaged"]),
		_range_text(_final_spends["explorer"]),
		_range_text(_xp_checkpoints["critical"][0]),
		_range_text(_xp_checkpoints["critical"][1]),
		_range_text(_xp_checkpoints["critical"][2]),
		_range_text(_xp_checkpoints["engaged"][0]),
		_range_text(_xp_checkpoints["engaged"][1]),
		_range_text(_xp_checkpoints["engaged"][2]),
		_range_text(_xp_checkpoints["explorer"][0]),
		_range_text(_xp_checkpoints["explorer"][1]),
		_range_text(_xp_checkpoints["explorer"][2]),
		_range_text(_final_xp["critical"]),
		_range_text(_final_xp["engaged"]),
		_range_text(_final_xp["explorer"]),
		_range_text(_final_levels["critical"]),
		_range_text(_final_levels["engaged"]),
		_range_text(_final_levels["explorer"]),
		_average(_checkpoint_values["engaged"][0]),
		_average(_checkpoint_values["engaged"][1]),
		_average(_checkpoint_values["engaged"][2]),
		_explorer_mastery_ready,
		str(_mastery_ready_by_profile),
		_explorer_equipment_ready,
		str(_equipment_ready_by_profile),
		str(_level_six_by_profile),
	]
	if _failures.is_empty():
		print("COMPLETE_RUN_BALANCE_VALIDATION_OK %s" % summary)
		quit(0)
		return
	print("COMPLETE_RUN_BALANCE_DIAGNOSTIC %s" % summary)
	for failure in _failures:
		push_error(failure)
	quit(1)
