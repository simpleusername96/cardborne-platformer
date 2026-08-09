class_name VehicleUpgradeOfferPresenter
extends RefCounted

## Builds immutable UI snapshots from upgrade definitions. Gameplay owns levels
## and application; UI and validators share this presentation boundary.

static func artwork_asset_id(definition: VehicleUpgradeDefinition) -> StringName:
	return definition.artwork_asset_id


static func snapshot(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Dictionary:
	var effect_rows: Array[Dictionary] = []
	for modifier in definition.modifiers:
		effect_rows.append({
			"stat_key":"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
			"operation":modifier.operation,
			"display_unit":modifier.display_unit,
			"current":modifier.display_value_at(current_level),
			"next":modifier.display_value_at(current_level + 1),
			"show_current":current_level > 0 or definition.category != &"element",
			"absolute_value":definition.category == &"element",
		})
		if effect_rows.size() >= 2:
			break
	var change_kind := (
		(&"unlock" if current_level == 0 else &"enhance")
		if definition.category == &"element" or definition.modifiers.is_empty()
		else &"stats"
	)
	var change_label_key := ""
	if change_kind == &"unlock":
		change_label_key = "UPGRADE_CHANGE_UNLOCK"
	elif change_kind == &"enhance":
		change_label_key = "UPGRADE_CHANGE_ENHANCE"
	return {
		"id":definition.id,
		"title_key":definition.title_key,
		"description_key":definition.description_key,
		"category_key":"UPGRADE_CATEGORY_%s" % String(definition.category).to_upper(),
		"category":definition.category,
		"current_level":current_level,
		"next_level":current_level + 1,
		"max_level":definition.max_level,
		"change_kind":change_kind,
		"change_label_key":change_label_key,
		"effect_rows":effect_rows,
		"artwork_asset_id":artwork_asset_id(definition),
	}
