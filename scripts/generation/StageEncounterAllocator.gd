class_name StageEncounterAllocator
extends RefCounted

# MVP caps keep exact-budget backtracking finite while admitting the 8+2 Stage 3 graph.
const MAX_STAGE_ROOMS := 12
const MAX_ENCOUNTERS_PER_ROOM := 4
const MAX_CANDIDATES_PER_ROOM := 32
const MAX_SEARCH_STATES_PER_ROOM := 512

var _last_errors := PackedStringArray()

var last_errors: PackedStringArray:
	get:
		return _last_errors.duplicate()


# Returns a copied plan only after every room's encounter budget is filled exactly.
func allocate(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> StagePlan:
	_last_errors.clear()
	_validate_inputs(plan, room_catalog, profile, enemy_catalog)
	if not _last_errors.is_empty():
		return null

	var stream_seeds := plan.get_rng_stream_seeds()
	var encounter_rng := RandomNumberGenerator.new()
	encounter_rng.seed = int(stream_seeds[String(&"encounter")])
	var variant_rng := RandomNumberGenerator.new()
	variant_rng.seed = int(stream_seeds[String(&"enemy_variant")])

	var planned_encounters: Array[PlannedEncounter] = []
	for room in plan.get_rooms():
		var template := room_catalog.get_room_by_id(room.template_id)
		var allocation := _allocate_room(
			room,
			template,
			profile,
			enemy_catalog,
			encounter_rng,
			variant_rng
		)
		if not bool(allocation.get("ok", false)):
			return null
		for encounter in allocation.get("encounters", []):
			planned_encounters.append(encounter)

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
		planned_encounters,
		plan.schema_version,
		plan.generation_attempt,
		plan.get_hazards(),
		plan.get_rewards()
	)


func allocate_encounters(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> StagePlan:
	return allocate(plan, room_catalog, profile, enemy_catalog)


func _validate_inputs(
	plan: StagePlan,
	room_catalog: RoomCatalog,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog
) -> void:
	if plan == null:
		_last_errors.append("Encounter allocation needs a StagePlan.")
	if room_catalog == null:
		_last_errors.append("Encounter allocation needs a RoomCatalog.")
	if profile == null:
		_last_errors.append("Encounter allocation needs a StageProfile.")
	if enemy_catalog == null:
		_last_errors.append("Encounter allocation needs an EnemyCatalog.")
	if plan == null or room_catalog == null or profile == null or enemy_catalog == null:
		return

	_append_errors(room_catalog.validate_catalog(), "Room catalog")
	_append_errors(profile.validate_definition(), "Stage profile")
	_append_errors(enemy_catalog.validate_catalog(), "Enemy catalog")
	if not plan.get_encounters().is_empty():
		_last_errors.append("StagePlan already contains encounters; allocation will not overwrite them.")
	if plan.get_rooms().size() > MAX_STAGE_ROOMS:
		_last_errors.append(
			"StagePlan has %d rooms, exceeding the normal-stage allocator bound of %d."
			% [plan.get_rooms().size(), MAX_STAGE_ROOMS]
		)
	if plan.profile_id != profile.id or plan.profile_content_version != profile.content_version:
		_last_errors.append("StagePlan profile identity or content version does not match StageProfile.")
	if (
		plan.room_catalog_id != room_catalog.id
		or plan.room_catalog_content_version != room_catalog.content_version
	):
		_last_errors.append("StagePlan room catalog identity or content version does not match RoomCatalog.")

	var stream_seeds := plan.get_rng_stream_seeds()
	for stream_name in [&"encounter", &"enemy_variant"]:
		if not stream_seeds.has(String(stream_name)):
			_last_errors.append("StagePlan is missing RNG stream seed '%s'." % stream_name)

	var seen_room_ids: Dictionary = {}
	for room in plan.get_rooms():
		ContentId.validate(_last_errors, "Planned room ID", room.id)
		if seen_room_ids.has(room.id):
			_last_errors.append("StagePlan repeats planned room ID '%s'." % room.id)
		seen_room_ids[room.id] = true
		var template := room_catalog.get_room_by_id(room.template_id)
		if template == null:
			_last_errors.append(
				"Planned room '%s' references missing template '%s'." % [room.id, room.template_id]
			)
			continue
		if room.template_content_version != template.content_version:
			_last_errors.append("Planned room '%s' has a stale template version." % room.id)
		if room.role != template.role or room.required_route != template.required_route:
			_last_errors.append("Planned room '%s' does not match its template contract." % room.id)
		if (
			room.encounter_budget < template.encounter_budget.x
			or room.encounter_budget > template.encounter_budget.y
		):
			_last_errors.append(
				"Planned room '%s' encounter budget %d is outside template range %s."
				% [room.id, room.encounter_budget, template.encounter_budget]
			)
		if (
			room.role == &"combat"
			and (
				room.encounter_budget < profile.encounter_budget_per_combat_room.x
				or room.encounter_budget > profile.encounter_budget_per_combat_room.y
			)
		):
			_last_errors.append(
				"Combat room '%s' encounter budget %d is outside StageProfile range %s."
				% [room.id, room.encounter_budget, profile.encounter_budget_per_combat_room]
			)


func _allocate_room(
	room: PlannedRoom,
	template: RoomTemplateData,
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	encounter_rng: RandomNumberGenerator,
	variant_rng: RandomNumberGenerator
) -> Dictionary:
	if room.encounter_budget == 0:
		return {"ok": true, "encounters": []}
	if template.enemy_anchors.is_empty():
		_last_errors.append(
			"Room '%s' needs encounter budget %d but has no enemy anchors."
			% [room.id, room.encounter_budget]
		)
		return {"ok": false}
	if template.allowed_enemy_tags.is_empty():
		_last_errors.append(
			"Room '%s' needs encounter budget %d but allows no pressure roles."
			% [room.id, room.encounter_budget]
		)
		return {"ok": false}
	if template.enemy_anchors.size() > MAX_ENCOUNTERS_PER_ROOM:
		_last_errors.append(
			"Room '%s' has %d enemy anchors, exceeding the normal-stage bound of %d."
			% [room.id, template.enemy_anchors.size(), MAX_ENCOUNTERS_PER_ROOM]
		)
		return {"ok": false}

	var anchors: Array[RoomEnemyAnchorData] = template.enemy_anchors.duplicate()
	_shuffle(anchors, encounter_rng)
	var candidate_result := _build_candidates(
		room,
		anchors,
		profile,
		enemy_catalog,
		encounter_rng
	)
	if not bool(candidate_result.get("ok", false)):
		return {"ok": false}
	var candidates_by_anchor: Array = candidate_result["candidates_by_anchor"]
	if candidates_by_anchor.is_empty():
		_last_errors.append(
			"Room '%s' has no eligible pressure role, archetype, and stage variant chain."
			% room.id
		)
		return {"ok": false}

	var search_state := {"visited": 0, "exhausted": false}
	var search_result := _search_exact_budget(
		candidates_by_anchor,
		0,
		room.encounter_budget,
		search_state
	)
	if not bool(search_result.get("found", false)):
		if bool(search_state["exhausted"]):
			_last_errors.append(
				"Room '%s' exact-budget search exceeded %d states."
				% [room.id, MAX_SEARCH_STATES_PER_ROOM]
			)
		else:
			_last_errors.append(
				"Room '%s' cannot exactly fill encounter budget %d with %d eligible anchors."
				% [room.id, room.encounter_budget, template.enemy_anchors.size()]
			)
		return {"ok": false}

	var choices: Array = search_result["choices"]
	var encounters: Array[PlannedEncounter] = []
	for choice_index in choices.size():
		var choice: Dictionary = choices[choice_index]
		var variants: Array = choice["variants"].duplicate()
		_shuffle(variants, variant_rng)
		var resolved := variants[0] as ResolvedEnemySpec
		encounters.append(
			PlannedEncounter.new(
				StringName("encounter_%s_%02d" % [room.id, choice_index]),
				room.id,
				choice["anchor_id"],
				choice["pressure_role"],
				choice["archetype_id"],
				resolved.variant_id,
				resolved.variant_content_version,
				int(choice["budget_cost"])
			)
		)
	return {"ok": true, "encounters": encounters}


func _build_candidates(
	room: PlannedRoom,
	anchors: Array[RoomEnemyAnchorData],
	profile: StageProfile,
	enemy_catalog: EnemyCatalog,
	encounter_rng: RandomNumberGenerator
) -> Dictionary:
	var candidates_by_anchor: Array = []
	var candidate_count := 0
	for anchor in anchors:
		var anchor_candidates: Array[Dictionary] = []
		var pressure_roles: Array[StringName] = anchor.allowed_pressure_roles.duplicate()
		_shuffle(pressure_roles, encounter_rng)
		for pressure_role in pressure_roles:
			var archetypes: Array[EnemyArchetypeDefinition] = []
			for archetype_id in profile.eligible_enemy_archetypes:
				var archetype := enemy_catalog.get_archetype_by_id(archetype_id)
				if anchor.supports(archetype, pressure_role):
					archetypes.append(archetype)
			_shuffle(archetypes, encounter_rng)
			for archetype in archetypes:
				var variants_by_cost: Dictionary = {}
				for variant in enemy_catalog.variants:
					if (
						variant == null
						or variant.archetype_id != archetype.id
						or variant.stage_id != profile.id
					):
						continue
					var resolved := enemy_catalog.resolve(archetype.id, variant.id, profile.id)
					if resolved == null:
						continue
					var cost := resolved.budget_cost
					var cost_variants: Array = variants_by_cost.get(cost, [])
					cost_variants.append(resolved)
					variants_by_cost[cost] = cost_variants
				var costs: Array = variants_by_cost.keys()
				costs.sort()
				for cost in costs:
					anchor_candidates.append({
						"anchor_id": anchor.id,
						"pressure_role": pressure_role,
						"archetype_id": archetype.id,
						"budget_cost": int(cost),
						"variants": variants_by_cost[cost],
					})
					candidate_count += 1
					if candidate_count > MAX_CANDIDATES_PER_ROOM:
						_last_errors.append(
							"Room '%s' has more than %d eligible encounter candidates."
							% [room.id, MAX_CANDIDATES_PER_ROOM]
						)
						return {"ok": false}
		candidates_by_anchor.append(anchor_candidates)
	return {"ok": true, "candidates_by_anchor": candidates_by_anchor}


func _search_exact_budget(
	candidates_by_anchor: Array,
	anchor_index: int,
	remaining_budget: int,
	state: Dictionary
) -> Dictionary:
	state["visited"] = int(state["visited"]) + 1
	if int(state["visited"]) > MAX_SEARCH_STATES_PER_ROOM:
		state["exhausted"] = true
		return {"found": false}
	if remaining_budget == 0:
		return {"found": true, "choices": []}
	if anchor_index >= candidates_by_anchor.size():
		return {"found": false}

	for candidate in candidates_by_anchor[anchor_index]:
		var cost := int(candidate["budget_cost"])
		if cost <= 0 or cost > remaining_budget:
			continue
		var suffix := _search_exact_budget(
			candidates_by_anchor,
			anchor_index + 1,
			remaining_budget - cost,
			state
		)
		if bool(suffix.get("found", false)):
			var choices: Array = [candidate]
			choices.append_array(suffix["choices"])
			return {"found": true, "choices": choices}
		if bool(state["exhausted"]):
			return {"found": false}
	return _search_exact_budget(
		candidates_by_anchor,
		anchor_index + 1,
		remaining_budget,
		state
	)


func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


func _append_errors(source: PackedStringArray, label: String) -> void:
	for error in source:
		_last_errors.append("%s: %s" % [label, error])
