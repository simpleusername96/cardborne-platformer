class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface, facility, and decoration descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const SOURCE_FAMILIES: Array[StringName] = [
	&"world_floor_void_tiles",
	&"wall_cover_tiles",
	&"water_void_edge_tiles",
	&"arc_surge_strip",
	&"breakable_bulkhead",
	&"transit_gate",
	&"repair_field",
	&"overdrive_field",
]

const SOURCE_STAMPS: Array[StringName] = [
	&"frame_h", &"frame_v", &"corner_nw", &"corner_ne", &"corner_se", &"corner_sw",
	&"rail_h", &"rail_v", &"service_bay_h", &"service_bay_v",
	&"cover_small", &"cover_wide", &"bulkhead_h", &"bulkhead_v",
	&"inner_cap_h", &"inner_cap_v", &"hatch_round", &"vent_round",
	&"console_small", &"console_wide", &"cargo_small", &"cargo_wide",
	&"machinery_small", &"machinery_tall", &"warning_plate", &"pipe_cluster",
	&"cable_coil", &"terminal", &"wear_scrape_a", &"wear_scrape_b",
	&"wear_chip_a", &"wear_chip_b",
]

const FIELD_DESCRIPTORS := {
	&"drowned_ruin_field": {"rhythm": &"central_court_orthogonal_service", "decoration_budget": 24},
	&"tidal_archive_field": {"rhythm": &"parallel_bay_lateral_rail", "decoration_budget": 24},
	&"storm_drydock_field": {"rhythm": &"basin_diagonal_docking_guide", "decoration_budget": 24},
}

const FACILITY_DESCRIPTORS := {
	&"repair_field": {"shape": &"plus_cut", "color": &"support"},
	&"transit_gate": {"shape": &"opposing_chevrons", "color": &"system"},
	&"overdrive_field": {"shape": &"stacked_forward_chevrons", "color": &"player_reward"},
	&"arc_surge_strip": {"shape": &"broken_bolt_rail", "color": &"arc"},
	&"breakable_bulkhead": {"shape": &"split_slab", "color": &"raised"},
}


static func source_family_ids() -> Array[StringName]:
	return SOURCE_FAMILIES.duplicate()


static func source_stamp_ids() -> Array[StringName]:
	return SOURCE_STAMPS.duplicate()


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in FIELD_DESCRIPTORS:
		ids.append(StringName(value))
	for value in FACILITY_DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids
