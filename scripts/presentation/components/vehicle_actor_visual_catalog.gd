class_name VehicleActorVisualCatalog
extends RefCounted

## Actor silhouette, state, and anchor descriptors. Attack behavior, health,
## collision, animation timing, and AI remain outside this catalog.

const DESCRIPTORS := {
	&"player": {
		"role": &"player",
		"asset": &"attachment/player_craft_body",
		"color": &"player_reward",
		"rear_anchors": [Vector2(-0.84, 0.0)],
		"states": [&"base", &"hit", &"dash"],
	},
	&"ordinary_pursuer_t1": {"role": &"pursuer", "asset": &"actor/ordinary_pursuer_t1", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_pursuer_t2": {"role": &"pursuer", "asset": &"actor/ordinary_pursuer_t2", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_pursuer_t3": {"role": &"pursuer", "asset": &"actor/ordinary_pursuer_t3", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_charger_t1": {"role": &"charger", "asset": &"actor/ordinary_charger_t1", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_charger_t2": {"role": &"charger", "asset": &"actor/ordinary_charger_t2", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_charger_t3": {"role": &"charger", "asset": &"actor/ordinary_charger_t3", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_gunner_t1": {"role": &"gunner", "asset": &"actor/ordinary_gunner_t1", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_gunner_t2": {"role": &"gunner", "asset": &"actor/ordinary_gunner_t2", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_gunner_t3": {"role": &"gunner", "asset": &"actor/ordinary_gunner_t3", "color": &"danger", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_defender_t1": {"role": &"defender", "asset": &"actor/ordinary_defender_t1", "color": &"support", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_defender_t2": {"role": &"defender", "asset": &"actor/ordinary_defender_t2", "color": &"support", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_defender_t3": {"role": &"defender", "asset": &"actor/ordinary_defender_t3", "color": &"support", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_coordinator_t1": {"role": &"coordinator", "asset": &"actor/ordinary_coordinator_t1", "color": &"boss_command", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_coordinator_t2": {"role": &"coordinator", "asset": &"actor/ordinary_coordinator_t2", "color": &"boss_command", "states": [&"base", &"trait", &"collective"]},
	&"ordinary_coordinator_t3": {"role": &"coordinator", "asset": &"actor/ordinary_coordinator_t3", "color": &"boss_command", "states": [&"base", &"trait", &"collective"]},
	&"boss_pattern_fixed_beam_01": {"role": &"boss_pattern", "asset": &"actor/boss_pattern_fixed_beam_01", "color": &"danger", "states": [&"base", &"active"]},
	&"boss_stage_01": {"role": &"boss", "asset": &"boss/stage_01", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_02": {"role": &"boss", "asset": &"boss/stage_02", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_03": {"role": &"boss", "asset": &"boss/stage_03", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_04": {"role": &"boss", "asset": &"boss/stage_04", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_05": {"role": &"boss", "asset": &"boss/stage_05", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_06": {"role": &"boss", "asset": &"boss/stage_06", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_07": {"role": &"boss", "asset": &"boss/stage_07", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_08": {"role": &"boss", "asset": &"boss/stage_08", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_09": {"role": &"boss", "asset": &"boss/stage_09", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_10": {"role": &"boss", "asset": &"boss/stage_10", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_11": {"role": &"boss", "asset": &"boss/stage_11", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
	&"boss_stage_12": {"role": &"boss", "asset": &"boss/stage_12", "color": &"boss_command", "states": [&"shield_up", &"shield_down"]},
}

const ENEMY_ARCHETYPES: Array[StringName] = [
	&"ordinary_pursuer_t1", &"ordinary_pursuer_t2", &"ordinary_pursuer_t3",
	&"ordinary_charger_t1", &"ordinary_charger_t2", &"ordinary_charger_t3",
	&"ordinary_gunner_t1", &"ordinary_gunner_t2", &"ordinary_gunner_t3",
	&"ordinary_defender_t1", &"ordinary_defender_t2", &"ordinary_defender_t3",
	&"ordinary_coordinator_t1", &"ordinary_coordinator_t2", &"ordinary_coordinator_t3",
	&"boss_pattern_fixed_beam_01", &"boss_actor",
]


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)


static func asset_id_for_enemy(
	archetype: StringName,
	family_trait: StringName = &""
) -> StringName:
	var actor := descriptor(archetype)
	var base_asset := StringName(actor.get("asset", &""))
	if family_trait.is_empty() or base_asset.is_empty():
		return base_asset
	var family := StringName(actor.get("role", &""))
	var tier_text := String(archetype).get_slice("_t", 1)
	if family.is_empty() or tier_text.is_empty():
		return base_asset
	return StringName(
		"actor/ordinary_%s_%s_t%s" % [family, family_trait, tier_text]
	)
