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
	&"scrap_drone": {"role": &"swarm", "asset": &"actor/scrap_drone", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"needle_drone": {"role": &"skirmisher", "asset": &"actor/needle_drone", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"spark_minelet": {"role": &"minelet", "asset": &"actor/spark_minelet", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"chaser": {"role": &"melee", "asset": &"actor/chaser", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"shooter": {"role": &"ranged", "asset": &"actor/shooter", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"controller": {"role": &"command", "asset": &"actor/controller", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"turret": {"role": &"stationary_ranged", "asset": &"actor/turret", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"mine": {"role": &"stationary_mine", "asset": &"actor/mine", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"generator": {"role": &"support_structure", "asset": &"actor/generator", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"shield_escort": {"role": &"shield", "asset": &"actor/shield_escort", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"artillery_spotter": {"role": &"artillery", "asset": &"actor/artillery_spotter", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"interceptor_tower": {"role": &"interceptor", "asset": &"actor/interceptor_tower", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"rammer": {"role": &"rammer", "asset": &"actor/rammer", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"bulkhead_guard": {"role": &"guard", "asset": &"actor/bulkhead_guard", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"splitter_barge": {"role": &"splitter", "asset": &"actor/splitter_barge", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"repair_tender": {"role": &"repair", "asset": &"actor/repair_tender", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"drone_carrier": {"role": &"carrier", "asset": &"actor/drone_carrier", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"beam_sentinel": {"role": &"beam", "asset": &"actor/beam_sentinel", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"boss_pylon": {"role": &"boss_module", "asset": &"actor/boss_pylon", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"forge_plate": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"segment_lock": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"relay_positive": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"relay_negative": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"route_switch": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"armor_car": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"lattice_outer": {"role": &"boss_module", "asset_family": &"boss/node", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"behemoth": {"role": &"boss", "asset": &"boss/behemoth", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"colossus": {"role": &"boss", "asset": &"boss/colossus", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"crown": {"role": &"boss", "asset": &"boss/crown", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"leviathan": {"role": &"boss", "asset": &"boss/leviathan", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"titan": {"role": &"boss", "asset": &"boss/titan", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
}

const ENEMY_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser",
	&"shooter", &"controller", &"turret", &"mine", &"generator",
	&"shield_escort", &"artillery_spotter", &"interceptor_tower",
	&"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender",
	&"drone_carrier", &"beam_sentinel", &"boss_pylon", &"stage_boss",
]


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
