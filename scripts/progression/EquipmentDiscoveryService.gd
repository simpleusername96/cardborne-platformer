class_name EquipmentDiscoveryService
extends RefCounted

# Cache pools stay stage-aware while room generation remains character-independent.
const STAGE_CACHE_SOURCES: Dictionary = {
	0: [&"optional_cache", &"high_route_cache", &"high_route_reward"],
	1: [&"stage_2_optional_reward", &"high_route_reward"],
	2: [&"stage_3_cache", &"high_route_reward"],
}


static func resolve(
	table: RewardTable,
	discovery_seed: int,
	context: Dictionary
) -> Array[StringName]:
	var discoveries: Array[StringName] = []
	if table == null or table.equipment_pool_id == &"":
		return discoveries
	if (
		table.equipment_pool_id == RewardTable.EQUIPMENT_POOL_STAGE_CACHE
		and bool(context.get("stage_cache_claimed", false))
	):
		return discoveries

	var catalog := context.get("equipment_catalog") as EquipmentCatalog
	var profile_id := StringName(context.get("profile_id", &""))
	if catalog == null or profile_id == &"":
		return discoveries

	var rng := RandomNumberGenerator.new()
	rng.seed = discovery_seed
	if table.equipment_pool_chance < 1.0 and rng.randf() >= table.equipment_pool_chance:
		return discoveries

	var candidates := _eligible_items(
		catalog,
		table.equipment_pool_id,
		profile_id,
		int(context.get("stage_index", -1))
	)
	if candidates.is_empty():
		return discoveries

	var owned: Array[String] = []
	var owned_value: Variant = context.get("owned_equipment", [])
	if owned_value is Array:
		for item_id in owned_value:
			owned.append(String(item_id))
	var unseen: Array[EquipmentDefinition] = []
	for item in candidates:
		if not owned.has(String(item.id)):
			unseen.append(item)
	if not unseen.is_empty():
		candidates = unseen

	candidates.sort_custom(func(left: EquipmentDefinition, right: EquipmentDefinition) -> bool:
		return String(left.id) < String(right.id)
	)
	discoveries.append(candidates[rng.randi_range(0, candidates.size() - 1)].id)
	return discoveries


static func _eligible_items(
	catalog: EquipmentCatalog,
	pool_id: StringName,
	profile_id: StringName,
	stage_index: int
) -> Array[EquipmentDefinition]:
	var source_ids: Array[StringName] = []
	if pool_id == RewardTable.EQUIPMENT_POOL_STAGE_CACHE:
		var configured_sources: Variant = STAGE_CACHE_SOURCES.get(stage_index, [])
		if configured_sources is Array:
			for source_id in configured_sources:
				source_ids.append(StringName(source_id))

	var candidates: Array[EquipmentDefinition] = []
	for item in catalog.items:
		if item == null or item.starting_item or not item.is_compatible(profile_id):
			continue
		if item.source == &"boss_core_unlock":
			continue
		if pool_id == RewardTable.EQUIPMENT_POOL_STAGE_CACHE and not source_ids.has(item.source):
			continue
		candidates.append(item)
	return candidates
