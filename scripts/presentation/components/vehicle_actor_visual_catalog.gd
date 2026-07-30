class_name VehicleActorVisualCatalog
extends RefCounted

## Actor silhouette, state, and anchor descriptors. Attack behavior, health,
## collision, animation timing, and AI remain outside this catalog.

const SOURCE_FAMILIES: Array[StringName] = [
	&"player_chassis",
	&"player_engine_flame",
	&"player_engine_modules",
	&"mobile_enemy_set",
	&"stationary_enemy_set",
	&"boss_set",
	&"secondary_escort_drone",
]

const DESCRIPTORS := {
	&"player": {
		"role": &"player",
		"shape": &"player_interceptor",
		"color": &"player_reward",
		"rear_sockets": [Vector2(-0.58, -0.43), Vector2(-0.58, 0.43)],
		"aim_socket": Vector2(0.04, 0.0),
	},
	&"scrap_drone": {"role": &"swarm", "shape": &"scrap_hook", "color": &"danger"},
	&"needle_drone": {"role": &"skirmisher", "shape": &"needle_kite", "color": &"danger"},
	&"spark_minelet": {"role": &"minelet", "shape": &"spark_star", "color": &"danger"},
	&"chaser": {"role": &"melee", "shape": &"pursuit_claw", "color": &"danger"},
	&"shooter": {"role": &"ranged", "shape": &"gunship_slab", "color": &"danger"},
	&"controller": {"role": &"command", "shape": &"command_gear", "color": &"boss_command"},
	&"turret": {"role": &"stationary_ranged", "shape": &"gun_platform", "color": &"danger"},
	&"mine": {"role": &"stationary_mine", "shape": &"mine_star", "color": &"danger"},
	&"generator": {"role": &"support_structure", "shape": &"generator_octagon", "color": &"support"},
	&"shield_escort": {"role": &"shield", "shape": &"escort_shield", "color": &"support"},
	&"artillery_spotter": {"role": &"artillery", "shape": &"spotter_hex", "color": &"danger"},
	&"interceptor_tower": {"role": &"interceptor", "shape": &"split_interceptor", "color": &"danger"},
	&"rammer": {"role": &"rammer", "shape": &"ram_wedge", "color": &"danger"},
	&"bulkhead_guard": {"role": &"guard", "shape": &"guard_bulwark", "color": &"danger"},
	&"splitter_barge": {"role": &"splitter", "shape": &"split_barge", "color": &"danger"},
	&"repair_tender": {"role": &"repair", "shape": &"repair_cross", "color": &"support"},
	&"drone_carrier": {"role": &"carrier", "shape": &"carrier_barge", "color": &"boss_command"},
	&"beam_sentinel": {"role": &"beam", "shape": &"beam_lance", "color": &"danger"},
	&"boss_pylon": {"role": &"boss_module", "shape": &"diamond", "color": &"boss_command"},
	&"escort_drone": {"role": &"player_secondary", "shape": &"solid_chevron", "color": &"support"},
	&"behemoth": {"role": &"boss", "shape": &"slab", "color": &"boss_command", "module_budget": 5},
	&"colossus": {"role": &"boss", "shape": &"forward_wedge", "color": &"boss_command", "module_budget": 5},
	&"crown": {"role": &"boss", "shape": &"solid_chevron", "color": &"boss_command", "module_budget": 5},
	&"leviathan": {"role": &"boss", "shape": &"split_spear", "color": &"boss_command", "module_budget": 5},
	&"titan": {"role": &"boss", "shape": &"diamond", "color": &"boss_command", "module_budget": 5},
}


static func source_family_ids() -> Array[StringName]:
	return SOURCE_FAMILIES.duplicate()


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
