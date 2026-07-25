class_name VehicleUpgradeOfferPresenter
extends RefCounted

## Builds immutable UI snapshots from upgrade definitions. Gameplay owns levels
## and application; UI and validators share this presentation boundary.


static func snapshot(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Dictionary:
	var value_previews: Array[Dictionary] = []
	for modifier in definition.modifiers:
		value_previews.append({
			"stat_key":"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
			"operation":modifier.operation,
			"current":modifier.value_at(current_level),
			"next":modifier.value_at(current_level + 1),
		})
	return {
		"id":definition.id,
		"title_key":definition.title_key,
		"description_key":definition.description_key,
		"family_key":"UPGRADE_FAMILY_%s" % String(definition.family).to_upper(),
		"current_level":current_level,
		"next_level":current_level + 1,
		"max_level":definition.max_level,
		"value_previews":value_previews,
	}
