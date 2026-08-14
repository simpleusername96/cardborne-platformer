class_name VehicleUpgradeOfferPresenter
extends RefCounted

const EffectPreview = preload("res://scripts/cards/vehicle_upgrade_effect_preview.gd")

## Builds immutable UI snapshots from upgrade definitions. Gameplay owns levels
## and application; UI and validators share this presentation boundary.

static func artwork_asset_id(definition: VehicleUpgradeDefinition) -> StringName:
	return definition.artwork_asset_id


static func snapshot(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Dictionary:
	var effect_rows: Array = EffectPreview.rows(definition, current_level)
	var change_kind := _change_kind(definition, current_level)
	var change_label_key := ""
	if change_kind == &"unlock":
		change_label_key = "UPGRADE_CHANGE_UNLOCK"
	elif change_kind == &"enhance":
		change_label_key = "UPGRADE_CHANGE_ENHANCE"
	var description_key := definition.description_key
	if current_level > 0 and not definition.enhance_description_key.is_empty():
		description_key = definition.enhance_description_key
	return {
		"id":definition.id,
		"title_key":definition.title_key,
		"description_key":description_key,
		"category_key":"UPGRADE_CATEGORY_%s" % String(definition.category).to_upper(),
		"category":definition.category,
		"current_level":current_level,
		"next_level":current_level + 1,
		"max_level":definition.max_level,
		"change_kind":change_kind,
		"change_label_key":change_label_key,
		"activation_mode":(
			&"manual" if definition.category == &"activated" else (
				&"automatic" if definition.category == &"secondary" else &""
			)
		),
		"effect_rows":effect_rows,
		"artwork_asset_id":artwork_asset_id(definition),
	}


static func _change_kind(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> StringName:
	if not definition.modifiers.is_empty() and definition.category != &"element":
		return &"stats"
	return &"unlock" if current_level == 0 else &"enhance"
