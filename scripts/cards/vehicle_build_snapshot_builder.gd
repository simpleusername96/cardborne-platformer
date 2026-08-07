class_name VehicleBuildSnapshotBuilder
extends RefCounted

## Freezes gameplay-owned values for every read-only build summary surface.


static func build(
	run_build: VehicleRunBuild,
	catalog: VehicleUpgradeCatalog,
	effective_stats: Array[Dictionary],
	secondaries: Array[Dictionary],
	run_state: Dictionary
) -> Dictionary:
	var upgrades: Array[Dictionary] = []
	var upgrade_ids: Array = run_build.levels.keys()
	upgrade_ids.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			var a_definition := catalog.get_definition(StringName(a))
			var b_definition := catalog.get_definition(StringName(b))
			var a_category := (
				catalog.CATEGORIES.find(a_definition.category)
				if a_definition != null else catalog.CATEGORIES.size()
			)
			var b_category := (
				catalog.CATEGORIES.find(b_definition.category)
				if b_definition != null else catalog.CATEGORIES.size()
			)
			return (
				a_category < b_category
				or (a_category == b_category and String(a) < String(b))
			)
	)
	for upgrade_value in upgrade_ids:
		var upgrade_id := StringName(upgrade_value)
		var definition := catalog.get_definition(upgrade_id)
		if definition == null:
			continue
		upgrades.append({
			"id":upgrade_id,
			"title_key":definition.title_key,
			"description_key":definition.description_key,
			"category":definition.category,
			"artwork_asset_id":definition.artwork_asset_id,
			"level":run_build.level_of(upgrade_id),
			"max_level":definition.max_level,
		})
	return {
		"active":true,
		"stats":effective_stats.duplicate(true),
		"secondaries":secondaries.duplicate(true),
		"upgrades":upgrades,
		"run_state":run_state.duplicate(true),
	}
