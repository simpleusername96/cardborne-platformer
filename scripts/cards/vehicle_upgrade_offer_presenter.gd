class_name VehicleUpgradeOfferPresenter
extends RefCounted

## Builds immutable UI snapshots from upgrade definitions. Gameplay owns levels
## and application; UI and validators share this presentation boundary.


static func snapshot(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Dictionary:
	var effect_rows: Array[Dictionary] = []
	for modifier in definition.modifiers:
		effect_rows.append({
			"stat_key":"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
			"operation":modifier.operation,
			"current":modifier.value_at(current_level),
			"next":modifier.value_at(current_level + 1),
		})
		if effect_rows.size() >= 2:
			break
	var summary_key := definition.summary_key_at(current_level + 1)
	var behavior_change_key := ""
	if (
		not definition.behavior_ids.is_empty()
		and definition.description_key != summary_key
	):
		behavior_change_key = definition.description_key
	return {
		"id":definition.id,
		"title_key":definition.title_key,
		"summary_key":summary_key,
		"family_key":"UPGRADE_FAMILY_%s" % String(definition.family).to_upper(),
		"family":definition.family,
		"current_level":current_level,
		"next_level":current_level + 1,
		"max_level":definition.max_level,
		"effect_rows":effect_rows,
		"behavior_change_key":behavior_change_key,
	}
