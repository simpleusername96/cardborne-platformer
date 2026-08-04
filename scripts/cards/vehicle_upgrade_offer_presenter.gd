class_name VehicleUpgradeOfferPresenter
extends RefCounted

## Builds immutable UI snapshots from upgrade definitions. Gameplay owns levels
## and application; UI and validators share this presentation boundary.

const ARTWORK_BY_UPGRADE := {
	&"ion_field": &"upgrade/ion_field",
	&"orbit_blades": &"secondary/orbit_blade",
	&"wake_mines": &"secondary/wake_mine",
	&"escort_drone": &"secondary/escort_drone",
	&"incendiary_core": &"upgrade/element_thermal",
	&"thermal_compound": &"upgrade/element_thermal",
	&"toxin_core": &"upgrade/element_toxin",
	&"concentrated_toxin": &"upgrade/element_toxin",
	&"contagion": &"upgrade/element_toxin",
	&"cryo_core": &"upgrade/element_cryo",
	&"deep_freeze": &"upgrade/element_cryo",
	&"tuned_thrusters": &"upgrade/mobility_thruster",
	&"dash_capacitor": &"upgrade/mobility_thruster",
	&"coolant_wake": &"upgrade/dash_wake",
	&"ion_wake": &"upgrade/dash_wake",
	&"phase_shear": &"upgrade/dash_wake",
	&"ram_pulse": &"upgrade/dash_wake",
	&"aegis_cycle": &"upgrade/defense_matrix",
	&"siphon_matrix": &"upgrade/defense_matrix",
	&"static_aegis": &"upgrade/defense_matrix",
	&"relay_overload": &"upgrade/system_relay",
	&"pickup_magnet": &"upgrade/pickup_magnet",
	&"reinforced_hull": &"upgrade/hull_reinforcement",
}

static func artwork_asset_id(definition: VehicleUpgradeDefinition) -> StringName:
	if definition.artwork_asset_id != &"":
		return definition.artwork_asset_id
	if ARTWORK_BY_UPGRADE.has(definition.id):
		return StringName(ARTWORK_BY_UPGRADE[definition.id])
	if definition.family == &"primary":
		return &"projectile/energy_teardrop"
	if definition.family == &"secondary":
		if definition.secondary_slot_kind == &"built_in":
			return &"secondary/seeker"
		return StringName("secondary/%s" % String(definition.id).replace("_", "-"))
	if definition.family == &"skill":
		return &"effect/emp_release"
	return &"upgrade/system_relay"


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
		"artwork_asset_id":artwork_asset_id(definition),
	}
