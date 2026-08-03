class_name VehicleActorVisualCatalog
extends RefCounted

## Actor silhouette, state, and anchor descriptors. Attack behavior, health,
## collision, animation timing, and AI remain outside this catalog.

const DESCRIPTORS := {
	&"player": {
		"role": &"player",
		"recipe": &"player_craft_body",
		"color": &"player_reward",
		"rear_anchors": [Vector2(-0.84, 0.0)],
		"components": {
			&"body": &"player_craft_body",
			&"engine_flare": &"player_engine_flare",
		},
		"states": [&"base", &"hit", &"dash"],
	},
	&"scrap_drone": {"role": &"swarm", "recipe": &"swarm_scrap_chevron", "grammar": &"solid_chevron", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"needle_drone": {"role": &"skirmisher", "recipe": &"swarm_needle_chevron", "grammar": &"solid_chevron", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"spark_minelet": {"role": &"minelet", "recipe": &"melee_minelet_split", "grammar": &"split_spear", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"chaser": {"role": &"melee", "recipe": &"melee_pursuit_split", "grammar": &"split_spear", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"shooter": {"role": &"ranged", "recipe": &"ranged_gunship_bracket", "grammar": &"open_bracket", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"controller": {"role": &"command", "recipe": &"command_twin_prong", "grammar": &"twin_prong", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"turret": {"role": &"stationary_ranged", "recipe": &"ranged_turret_bracket", "grammar": &"open_bracket", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"mine": {"role": &"stationary_mine", "recipe": &"mine_open_cradle", "grammar": &"open_cradle", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"generator": {"role": &"support_structure", "recipe": &"generator_open_cradle", "grammar": &"open_cradle", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"shield_escort": {"role": &"shield", "recipe": &"shield_forward_slab", "grammar": &"forward_slab", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"artillery_spotter": {"role": &"artillery", "recipe": &"artillery_long_rail", "grammar": &"long_rail", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"interceptor_tower": {"role": &"interceptor", "recipe": &"interceptor_twin_prong", "grammar": &"twin_prong", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"rammer": {"role": &"rammer", "recipe": &"rammer_split_spear", "grammar": &"split_spear", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"bulkhead_guard": {"role": &"guard", "recipe": &"guard_forward_slab", "grammar": &"forward_slab", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"splitter_barge": {"role": &"splitter", "recipe": &"splitter_chevron", "grammar": &"solid_chevron", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"repair_tender": {"role": &"repair", "recipe": &"repair_service_cross", "grammar": &"service_cross", "color": &"support", "states": [&"base", &"elite", &"collective"]},
	&"drone_carrier": {"role": &"carrier", "recipe": &"carrier_open_cradle", "grammar": &"open_cradle", "color": &"boss_command", "states": [&"base", &"elite", &"collective"]},
	&"beam_sentinel": {"role": &"beam", "recipe": &"beam_long_rail", "grammar": &"long_rail", "color": &"danger", "states": [&"base", &"elite", &"collective"]},
	&"boss_pylon": {"role": &"boss_module", "recipe": &"boss_pylon_anchor", "grammar": &"objective_anchor", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"forge_plate": {"role": &"boss_module", "recipe": &"objective_forge_plate", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"segment_lock": {"role": &"boss_module", "recipe": &"objective_segment_lock", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"relay_positive": {"role": &"boss_module", "recipe": &"objective_relay_positive", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"relay_negative": {"role": &"boss_module", "recipe": &"objective_relay_negative", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"route_switch": {"role": &"boss_module", "recipe": &"objective_route_switch", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"armor_car": {"role": &"boss_module", "recipe": &"objective_armor_car", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"lattice_outer": {"role": &"boss_module", "recipe": &"objective_lattice_outer", "color": &"boss_command", "states": [&"active", &"disabled"]},
	&"behemoth": {"role": &"boss", "recipe": &"boss_behemoth", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"colossus": {"role": &"boss", "recipe": &"boss_colossus", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"crown": {"role": &"boss", "recipe": &"boss_crown", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"leviathan": {"role": &"boss", "recipe": &"boss_leviathan", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
	&"titan": {"role": &"boss", "recipe": &"boss_titan", "color": &"boss_command", "module_budget": 5, "states": [&"sealed", &"vulnerable"]},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)


static func player_component_recipe(component_id: StringName) -> StringName:
	var components := Dictionary(
		Dictionary(DESCRIPTORS[&"player"]).get("components", {})
	)
	return StringName(components.get(component_id, &""))
