class_name StageContentAllocator
extends RefCounted

const MAX_PLACEMENTS_PER_ROOM := 4
const MAX_SEARCH_STATES_PER_ROOM := 256

var _last_errors := PackedStringArray()

var last_errors: PackedStringArray:
	get:
		return _last_errors.duplicate()


func allocate(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog
) -> StagePlan:
	_last_errors.clear()
	_validate_inputs(plan, room_catalog, profile, hazard_catalog, reward_catalog)
	if not _last_errors.is_empty():
		return null

	var seeds := plan.get_rng_stream_seeds()
	var hazard_rng := RandomNumberGenerator.new()
	hazard_rng.seed = int(seeds["hazard"])
	var reward_rng := RandomNumberGenerator.new()
	reward_rng.seed = int(seeds["reward"])
	var hazards: Array[PlannedHazard] = []
	var rewards: Array[PlannedReward] = []
	for room in plan.get_rooms():
		var template := room_catalog.get_room_by_id(room.template_id)
		var room_hazards: Variant = _allocate_hazards(
			room,
			template,
			profile,
			hazard_catalog,
			hazard_rng
		)
		if room_hazards == null:
			return null
		hazards.append_array(room_hazards)
		var room_rewards: Variant = _allocate_rewards(
			room,
			template,
			reward_catalog,
			reward_rng
		)
		if room_rewards == null:
			return null
		rewards.append_array(room_rewards)

	return StagePlan.new(
		plan.run_seed,
		plan.stage_index,
		plan.profile_id,
		plan.profile_content_version,
		plan.room_catalog_id,
		plan.room_catalog_content_version,
		plan.get_rng_stream_seeds(),
		plan.get_rooms(),
		plan.get_connections(),
		plan.get_encounters(),
		plan.schema_version,
		plan.generation_attempt,
		hazards,
		rewards
	)


func _validate_inputs(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	hazard_catalog: HazardCatalog,
	reward_catalog: RewardCatalog
) -> void:
	if plan == null:
		_last_errors.append("Stage content allocation needs a StagePlan.")
	if room_catalog == null:
		_last_errors.append("Stage content allocation needs a RoomCatalog.")
	if profile == null:
		_last_errors.append("Stage content allocation needs a StageProfile.")
	if hazard_catalog == null:
		_last_errors.append("Stage content allocation needs a HazardCatalog.")
	if reward_catalog == null:
		_last_errors.append("Stage content allocation needs a RewardCatalog.")
	if (
		plan == null
		or room_catalog == null
		or profile == null
		or hazard_catalog == null
		or reward_catalog == null
	):
		return
	_append_errors(room_catalog.validate_catalog(), "Room catalog")
	_append_errors(profile.validate_definition(), "Stage profile")
	_append_errors(hazard_catalog.validate_catalog(), "Hazard catalog")
	_append_errors(reward_catalog.validate_catalog(), "Reward catalog")
	if not plan.get_hazards().is_empty() or not plan.get_rewards().is_empty():
		_last_errors.append("StagePlan already contains hazard or reward placements.")
	for stream_name in ["hazard", "reward"]:
		if not plan.get_rng_stream_seeds().has(stream_name):
			_last_errors.append("StagePlan is missing RNG stream seed '%s'." % stream_name)


func _allocate_hazards(
	room: PlannedRoom,
	template: RoomTemplateData,
	profile: StageProfile,
	catalog: HazardCatalog,
	rng: RandomNumberGenerator
) -> Variant:
	if room.hazard_budget == 0:
		var empty: Array[PlannedHazard] = []
		return empty
	if template.hazard_anchors.is_empty():
		_last_errors.append("Room '%s' has hazard budget but no hazard anchors." % room.id)
		return null
	if template.hazard_anchors.size() > MAX_PLACEMENTS_PER_ROOM:
		_last_errors.append("Room '%s' exceeds the hazard placement cap." % room.id)
		return null
	var groups: Array = []
	var anchors := template.hazard_anchors.duplicate()
	_shuffle(anchors, rng)
	for anchor in anchors:
		var candidates: Array[Dictionary] = []
		var hazard_ids: Array[StringName] = anchor.allowed_hazard_ids.duplicate()
		_shuffle(hazard_ids, rng)
		for hazard_id in hazard_ids:
			if not profile.eligible_hazards.has(hazard_id):
				continue
			var definition := catalog.get_hazard(hazard_id)
			if definition == null or definition.budget_cost <= 0:
				continue
			candidates.append({"anchor": anchor, "definition": definition, "cost": definition.budget_cost})
		groups.append(candidates)
	var choices: Variant = _find_exact(groups, room.hazard_budget)
	if choices == null:
		_last_errors.append(
			"Room '%s' cannot exactly fill hazard budget %d." % [room.id, room.hazard_budget]
		)
		return null
	var placements: Array[PlannedHazard] = []
	for index in choices.size():
		var choice: Dictionary = choices[index]
		var anchor := choice["anchor"] as RoomHazardAnchorData
		var definition := choice["definition"] as HazardDefinition
		placements.append(
			PlannedHazard.new(
				StringName("hazard_%s_%02d" % [room.id, index]),
				room.id,
				anchor.id,
				definition.id,
				definition.content_version,
				definition.budget_cost
			)
		)
	return placements


func _allocate_rewards(
	room: PlannedRoom,
	template: RoomTemplateData,
	catalog: RewardCatalog,
	rng: RandomNumberGenerator
) -> Variant:
	if room.reward_budget == 0:
		var empty: Array[PlannedReward] = []
		return empty
	if template.reward_anchors.is_empty():
		_last_errors.append("Room '%s' has reward budget but no reward anchors." % room.id)
		return null
	if template.reward_anchors.size() > MAX_PLACEMENTS_PER_ROOM:
		_last_errors.append("Room '%s' exceeds the reward placement cap." % room.id)
		return null
	var groups: Array = []
	var anchors := template.reward_anchors.duplicate()
	_shuffle(anchors, rng)
	for anchor in anchors:
		var candidates: Array[Dictionary] = []
		var table_ids: Array[StringName] = anchor.eligible_table_ids.duplicate()
		_shuffle(table_ids, rng)
		for table_id in table_ids:
			var table := catalog.get_table(table_id)
			if table != null:
				candidates.append({"anchor": anchor, "table": table, "cost": anchor.budget_cost})
		groups.append(candidates)
	var choices: Variant = _find_exact(groups, room.reward_budget)
	if choices == null:
		_last_errors.append(
			"Room '%s' cannot exactly fill reward budget %d." % [room.id, room.reward_budget]
		)
		return null
	var placements: Array[PlannedReward] = []
	for index in choices.size():
		var choice: Dictionary = choices[index]
		var anchor := choice["anchor"] as RoomRewardAnchorData
		var table := choice["table"] as RewardTable
		placements.append(
			PlannedReward.new(
				StringName("reward_%s_%02d" % [room.id, index]),
				room.id,
				anchor.id,
				table.id,
				table.content_version,
				anchor.budget_cost
			)
		)
	return placements


func _find_exact(groups: Array, budget: int) -> Variant:
	var state := {"visited": 0}
	return _search_exact(groups, 0, budget, state)


func _search_exact(groups: Array, group_index: int, remaining: int, state: Dictionary) -> Variant:
	state["visited"] = int(state["visited"]) + 1
	if int(state["visited"]) > MAX_SEARCH_STATES_PER_ROOM:
		return null
	if remaining == 0:
		return []
	if group_index >= groups.size():
		return null
	for candidate in groups[group_index]:
		var cost := int(candidate["cost"])
		if cost <= 0 or cost > remaining:
			continue
		var suffix: Variant = _search_exact(groups, group_index + 1, remaining - cost, state)
		if suffix != null:
			var choices: Array = [candidate]
			choices.append_array(suffix)
			return choices
	return _search_exact(groups, group_index + 1, remaining, state)


func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


func _append_errors(source: PackedStringArray, label: String) -> void:
	for error in source:
		_last_errors.append("%s: %s" % [label, error])
