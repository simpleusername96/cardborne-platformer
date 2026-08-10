class_name VehicleUpgradeEffectPreview
extends RefCounted

## Composes frozen display rows from gameplay-owned rules and definitions.

const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")

static var _secondary_catalog: RefCounted


static func rows(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Array[Dictionary]:
	if not definition.modifiers.is_empty():
		return _modifier_rows(definition, current_level)
	match definition.id:
		&"split_muzzle":
			return [
				_row(
					"UPGRADE_EFFECT_PROJECTILES_PER_VOLLEY",
					PrimaryRules.projectiles_per_volley(current_level),
					PrimaryRules.projectiles_per_volley(current_level + 1)
				),
				_row(
					"UPGRADE_EFFECT_TOTAL_VOLLEY_DAMAGE",
					PrimaryRules.total_volley_damage_percent(current_level),
					PrimaryRules.total_volley_damage_percent(current_level + 1),
					"percent"
				),
			]
		&"piercing_rounds":
			return [_row(
				"UPGRADE_EFFECT_ADDITIONAL_PENETRATIONS",
				PrimaryRules.additional_penetrations(current_level),
				PrimaryRules.additional_penetrations(current_level + 1)
			)]
		&"homing_missiles":
			return _seeker_rows(current_level)
		&"electric_field":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DPS",
				"UPGRADE_EFFECT_RADIUS",
				false
			)
		&"orbiting_blades":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DAMAGE_PER_BLADE",
				"UPGRADE_EFFECT_BLADE_COUNT",
				true
			)
		&"drop_mines":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DAMAGE",
				"UPGRADE_EFFECT_DEPLOYMENT_INTERVAL",
				false,
				"seconds"
			)
	return []


static func _modifier_rows(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for modifier in definition.modifiers:
		result.append({
			"stat_key":"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
			"operation":modifier.operation,
			"display_unit":modifier.display_unit,
			"current":modifier.display_value_at(current_level),
			"next":modifier.display_value_at(current_level + 1),
			"show_current":current_level > 0 or definition.category != &"element",
			"absolute_value":definition.category == &"element",
		})
		if result.size() >= 2:
			break
	return result


static func _seeker_rows(current_level: int) -> Array[Dictionary]:
	var definition := _secondary_def(&"homing_missiles")
	if definition == null:
		return []
	var current_state := current_level + 1
	var next_state := current_level + 2
	return [
		_row(
			"UPGRADE_EFFECT_MISSILES_PER_VOLLEY",
			definition.cap(current_state),
			definition.cap(next_state)
		),
		_row(
			"UPGRADE_EFFECT_DAMAGE_PER_MISSILE",
			definition.value(current_state),
			definition.value(next_state)
		),
	]


static func _optional_secondary_rows(
	upgrade_id: StringName,
	current_level: int,
	value_key: String,
	auxiliary_key: String,
	auxiliary_first: bool,
	auxiliary_unit: String = "none"
) -> Array[Dictionary]:
	var definition := _secondary_def(upgrade_id)
	if definition == null:
		return []
	var current_state := maxi(1, current_level)
	var next_state := current_level + 1
	var show_current := current_level > 0
	var value_row := _row(
		value_key,
		definition.value(current_state),
		definition.value(next_state),
		"none",
		show_current
	)
	var auxiliary_row := _row(
		auxiliary_key,
		definition.cap(current_state) if auxiliary_first else definition.auxiliary(current_state),
		definition.cap(next_state) if auxiliary_first else definition.auxiliary(next_state),
		auxiliary_unit,
		show_current
	)
	return [auxiliary_row, value_row] if auxiliary_first else [value_row, auxiliary_row]


static func _secondary_def(upgrade_id: StringName) -> VehicleSecondaryDefinition:
	if _secondary_catalog == null:
		_secondary_catalog = SecondaryCatalog.new()
	return _secondary_catalog.get_by_upgrade_id(upgrade_id)


static func _row(
	stat_key: String,
	current_value: float,
	next_value: float,
	display_unit: String = "none",
	show_current: bool = true
) -> Dictionary:
	return {
		"stat_key":stat_key,
		"operation":"add",
		"display_unit":display_unit,
		"current":current_value,
		"next":next_value,
		"show_current":show_current,
		"absolute_value":true,
	}
