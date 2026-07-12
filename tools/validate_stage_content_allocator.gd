extends SceneTree

const ROOM_CATALOG_PATH := "res://data/generation/lower_ruins_room_catalog.tres"
const STAGE_PROFILE_PATH := "res://data/generation/ruin_approach_profile.tres"
const ENEMY_CATALOG_PATH := "res://data/enemies/enemy_catalog.tres"
const HAZARD_CATALOG_PATH := "res://data/hazards/hazard_catalog.tres"
const REWARD_CATALOG_PATH := "res://data/rewards/reward_catalog.tres"
const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"

var _failures: Array[String] = []


func _initialize() -> void:
	var rooms := load(ROOM_CATALOG_PATH) as RoomCatalog
	var profile := load(STAGE_PROFILE_PATH) as StageProfile
	var enemies := load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var hazards := load(HAZARD_CATALOG_PATH) as HazardCatalog
	var rewards := load(REWARD_CATALOG_PATH) as RewardCatalog
	var characters := load(CHARACTER_CATALOG_PATH) as CharacterCatalog
	for loaded in [rooms, profile, enemies, hazards, rewards, characters]:
		_expect(loaded != null, "all shipped generation catalogs should load")
	if null in [rooms, profile, enemies, hazards, rewards, characters]:
		_finish()
		return

	var limits := MovementMetrics.route_limits_for_profiles(characters.profiles)
	limits["minimum_headroom"] = 100.0
	limits["allowed_required_abilities"] = [
		"baseline", "double_jump", "dash", "crouch", "climb",
	]
	var saw_spikes := false
	var saw_safe_rise := false
	for seed in range(1200, 1208):
		var topology := StagePlanner.new().build_plan(rooms, profile, seed, 0, limits)
		_expect(topology != null, "seed %d topology should build" % seed)
		if topology == null:
			continue
		var encounter_allocator := StageEncounterAllocator.new()
		var combat_plan := encounter_allocator.allocate(topology, rooms, profile, enemies)
		_expect(
			combat_plan != null,
			"seed %d encounters should allocate: %s"
			% [seed, "; ".join(encounter_allocator.last_errors)]
		)
		if combat_plan == null:
			continue
		var allocator := StageContentAllocator.new()
		var plan := allocator.allocate(combat_plan, rooms, profile, hazards, rewards)
		_expect(
			plan != null,
			"seed %d content should allocate: %s" % [seed, "; ".join(allocator.last_errors)]
		)
		if plan == null:
			continue
		var repeated := StageContentAllocator.new().allocate(
			combat_plan,
			rooms,
			profile,
			hazards,
			rewards
		)
		_expect(repeated != null and repeated.to_json() == plan.to_json(), "seed %d content should reproduce" % seed)
		var validation_errors := StagePlanValidator.validate_complete(
			plan,
			rooms,
			profile,
			limits,
			enemies,
			hazards,
			rewards
		)
		_expect(
			validation_errors.is_empty(),
			"seed %d complete plan should validate: %s" % [seed, "; ".join(validation_errors)]
		)
		_validate_content_contracts(plan, rooms, hazards, rewards)
		var reproduced := StagePlan.from_json(plan.to_json())
		_expect(reproduced != null and reproduced.to_json() == plan.to_json(), "seed %d complete plan should round-trip" % seed)
		var rise := plan.get_room(&"lr_rise_steps")
		if rise != null and rise.hazard_budget == 1:
			saw_spikes = true
		elif rise != null:
			saw_safe_rise = true

	_expect(saw_spikes, "seed sweep should include a Rise Steps spike-row decision")
	_expect(saw_safe_rise, "seed sweep should include a hazard-free Rise Steps decision")
	_finish()


func _validate_content_contracts(
	plan: StagePlan,
	rooms: RoomCatalog,
	hazards: HazardCatalog,
	rewards: RewardCatalog
) -> void:
	var hazard_spend: Dictionary = {}
	var reward_spend: Dictionary = {}
	for room in plan.get_rooms():
		hazard_spend[String(room.id)] = 0
		reward_spend[String(room.id)] = 0
	for placement in plan.get_hazards():
		var room := plan.get_room(placement.room_id)
		var template := rooms.get_room_by_id(room.template_id)
		var anchor := template.get_hazard_anchor_by_id(placement.anchor_id)
		var definition := hazards.get_hazard(placement.hazard_id)
		_expect(anchor != null and anchor.allowed_hazard_ids.has(placement.hazard_id), "planned hazard should fit its anchor")
		_expect(definition != null and definition.budget_cost == placement.budget_cost, "planned hazard should preserve exact definition")
		hazard_spend[String(room.id)] = int(hazard_spend[String(room.id)]) + placement.budget_cost
	for placement in plan.get_rewards():
		var room := plan.get_room(placement.room_id)
		var template := rooms.get_room_by_id(room.template_id)
		var anchor := template.get_reward_anchor_by_id(placement.anchor_id)
		var table := rewards.get_table(placement.reward_table_id)
		_expect(anchor != null and anchor.eligible_table_ids.has(placement.reward_table_id), "planned reward should fit its anchor")
		_expect(table != null and table.content_version == placement.content_version, "planned reward should preserve its table")
		reward_spend[String(room.id)] = int(reward_spend[String(room.id)]) + placement.budget_cost
	for room in plan.get_rooms():
		_expect(int(hazard_spend[String(room.id)]) == room.hazard_budget, "room hazard budget should be exact")
		_expect(int(reward_spend[String(room.id)]) == room.reward_budget, "room reward budget should be exact")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_CONTENT_ALLOCATOR_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
