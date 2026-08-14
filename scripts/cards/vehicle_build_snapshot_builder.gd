class_name VehicleBuildSnapshotBuilder
extends RefCounted

## Freezes gameplay-owned values for every read-only build summary surface.

const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")


static func build(
	run_build: VehicleRunBuild,
	catalog: VehicleUpgradeCatalog,
	effective_stats: Array[Dictionary],
	secondaries: Array[Dictionary],
	run_state: Dictionary
) -> Dictionary:
	var records_by_slot := {}
	var upgrade_ids: Array[StringName] = []
	for upgrade_id in run_build.acquisition_order:
		if run_build.has(upgrade_id) and not upgrade_ids.has(upgrade_id):
			upgrade_ids.append(upgrade_id)
	# This fallback keeps snapshots readable if an older saved run has levels but
	# predates acquisition-order tracking. New runs always use the run-owned order.
	var legacy_ids: Array[StringName] = []
	for upgrade_value in run_build.levels.keys():
		var legacy_id := StringName(upgrade_value)
		if not upgrade_ids.has(legacy_id):
			legacy_ids.append(legacy_id)
	legacy_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	upgrade_ids.append_array(legacy_ids)
	for upgrade_value in upgrade_ids:
		var upgrade_id := StringName(upgrade_value)
		var definition := catalog.get_definition(upgrade_id)
		if definition == null:
			continue
		var level := run_build.level_of(upgrade_id)
		var acquisition_offer := OfferPresenter.snapshot(definition, maxi(0, level - 1))
		var current_effect_rows: Array[Dictionary] = []
		for effect_row_variant in Array(acquisition_offer["effect_rows"]):
			var effect_row := Dictionary(effect_row_variant).duplicate(true)
			# A build cell reports the effect already owned, never the next offer.
			effect_row["current"] = effect_row.get("next", effect_row.get("current", 0.0))
			effect_row["next"] = effect_row["current"]
			effect_row["show_current"] = true
			current_effect_rows.append(effect_row)
		var record := {
			"id":upgrade_id,
			"title_key":definition.title_key,
			"description_key":acquisition_offer["description_key"],
			"category":definition.category,
			"artwork_asset_id":definition.artwork_asset_id,
			"level":level,
			"max_level":definition.max_level,
			"effect_rows":current_effect_rows,
		}
		var slot_key := catalog.category_slot_key(definition, run_build)
		if not slot_key.is_empty():
			records_by_slot["%s/%s" % [definition.category, slot_key]] = record
	var categories: Array[Dictionary] = []
	var upgrades: Array[Dictionary] = []
	for descriptor in catalog.category_descriptors():
		var category_id := StringName(descriptor["id"])
		var slots: Array[Dictionary] = []
		for slot_key_variant in Array(descriptor["slot_keys"]):
			var slot_key := StringName(slot_key_variant)
			var record := Dictionary(records_by_slot.get("%s/%s" % [category_id, slot_key], {})).duplicate(true)
			slots.append({"slot_key":slot_key, "record":record})
			if not record.is_empty():
				upgrades.append(record.duplicate(true))
		categories.append({
			"id":category_id,
			"heading_key":String(descriptor["heading_key"]),
			"description_key":String(descriptor["description_key"]),
			"capacity":int(descriptor["capacity"]),
			"slots":slots,
		})
	return {
		"active":true,
		"stats":effective_stats.duplicate(true),
		"secondaries":secondaries.duplicate(true),
		"upgrades":upgrades,
		"categories":categories,
		"run_state":run_state.duplicate(true),
	}
