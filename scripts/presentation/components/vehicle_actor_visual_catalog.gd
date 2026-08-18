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
	&"ordinary_melee_01": {"role": &"swarm", "asset": &"actor/ordinary_melee_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_ranged_01": {"role": &"skirmisher", "asset": &"actor/ordinary_ranged_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_area_01": {"role": &"minelet", "asset": &"actor/ordinary_area_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_edge_01": {"role": &"melee", "asset": &"actor/ordinary_edge_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_lane_01": {"role": &"ranged", "asset": &"actor/ordinary_lane_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_gap_01": {"role": &"command", "asset": &"actor/ordinary_gap_01", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_fixed_ranged_01": {"role": &"stationary_ranged", "asset": &"actor/ordinary_fixed_ranged_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_fixed_area_01": {"role": &"stationary_area", "asset": &"actor/ordinary_fixed_area_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_fixed_support_01": {"role": &"support_structure", "asset": &"actor/ordinary_fixed_support_01", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_support_02": {"role": &"shield", "asset": &"actor/ordinary_support_02", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_growth_01": {"role": &"artillery", "asset": &"actor/ordinary_growth_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_fixed_ranged_02": {"role": &"interceptor", "asset": &"actor/ordinary_fixed_ranged_02", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_pull_01": {"role": &"ordinary_pull_01", "asset": &"actor/ordinary_pull_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_shield_01": {"role": &"guard", "asset": &"actor/ordinary_shield_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_pulse_01": {"role": &"splitter", "asset": &"actor/ordinary_pulse_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_support_01": {"role": &"repair", "asset": &"actor/ordinary_support_01", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_support_03": {"role": &"carrier", "asset": &"actor/ordinary_support_03", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_fixed_beam_01": {"role": &"beam", "asset": &"actor/ordinary_fixed_beam_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_beam_01": {"role": &"ordinary_beam_01", "asset": &"actor/ordinary_beam_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_range_01": {"role": &"ordinary_range_01", "asset": &"actor/ordinary_range_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_sweep_01": {"role": &"ordinary_sweep_01", "asset": &"actor/ordinary_sweep_01", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"ordinary_melee_02": {"role": &"ordinary_melee_02", "asset": &"actor/ordinary_melee_02", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
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
	&"ordinary_melee_01", &"ordinary_ranged_01", &"ordinary_area_01", &"ordinary_edge_01",
	&"ordinary_lane_01", &"ordinary_gap_01", &"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01", &"ordinary_fixed_support_01",
	&"ordinary_support_02", &"ordinary_growth_01", &"ordinary_fixed_ranged_02",
	&"ordinary_pull_01", &"ordinary_shield_01", &"ordinary_pulse_01", &"ordinary_support_01",
	&"ordinary_support_03", &"ordinary_fixed_beam_01", &"ordinary_beam_01", &"ordinary_range_01",
	&"ordinary_sweep_01", &"ordinary_melee_02", &"boss_actor",
]


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
