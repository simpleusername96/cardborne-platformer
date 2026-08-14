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
	var records_by_category := {}
	var acquired_records_by_category := {}
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
		var acquired_records: Array = acquired_records_by_category.get(
			definition.category, []
		)
		acquired_records.append(record)
		acquired_records_by_category[definition.category] = acquired_records
		if definition.category == &"activated" and definition.active_slot_kind == &"kind":
			# The equipped action glyph replaces this card only in the grouped rail.
			# The flat acquired-upgrade projection still retains the actual card.
			continue
		var category_records: Array = records_by_category.get(definition.category, [])
		category_records.append(record)
		records_by_category[definition.category] = category_records
	var categories: Array[Dictionary] = []
	var upgrades: Array[Dictionary] = []
	for descriptor in catalog.category_descriptors():
		var category_id := StringName(descriptor["id"])
		for acquired_record in Array(acquired_records_by_category.get(category_id, [])):
			upgrades.append(Dictionary(acquired_record).duplicate(true))
		var category_records: Array = records_by_category.get(category_id, [])
		if category_id == &"activated":
			category_records.push_front(_equipped_active_record(run_build))
		var slots: Array[Dictionary] = []
		for slot_index in int(descriptor["capacity"]):
			var record := (
				Dictionary(category_records[slot_index]).duplicate(true)
				if slot_index < category_records.size() else {}
			)
			slots.append({"slot_key":StringName("slot_%d" % slot_index), "record":record})
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


static func _equipped_active_record(run_build: VehicleRunBuild) -> Dictionary:
	var active_weapon_id := run_build.active_weapon_id()
	var title_key := &"UPGRADE_ACTIVE_EMP_TITLE"
	var description_key := &"UPGRADE_ACTIVE_EMP_DESC"
	var level := 1
	var max_level := 1
	var active_card_id := run_build.active_weapon_card_id()
	if not active_card_id.is_empty():
		var definition := run_build.catalog.get_definition(active_card_id)
		if definition != null:
			title_key = definition.title_key
			description_key = definition.description_key
			level = run_build.level_of(active_card_id)
			max_level = definition.max_level
	return {
		"id":active_weapon_id,
		"title_key":title_key,
		"description_key":description_key,
		"category":&"activated",
		"action_glyph_id":active_weapon_id,
		"display_only":true,
		"level":level,
		"max_level":max_level,
		"effect_rows":[],
	}
