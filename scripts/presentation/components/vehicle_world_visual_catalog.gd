class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface, facility, and decoration descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const FIELD_DESCRIPTORS := {
	&"drowned_ruin_field": {"rhythm": &"central_court_orthogonal_service", "decoration_budget": 24},
	&"tidal_archive_field": {"rhythm": &"parallel_bay_lateral_rail", "decoration_budget": 24},
	&"storm_drydock_field": {"rhythm": &"basin_diagonal_docking_guide", "decoration_budget": 24},
}

const FACILITY_DESCRIPTORS := {
	&"repair_field": {
		"recipe": &"repair_field",
		"shape": &"layered_repair_pad",
		"color": &"support",
	},
	&"transit_gate": {
		"recipe": &"transit_gate",
		"shape": &"opposing_transit_chevrons",
		"color": &"system",
	},
	&"overdrive_field": {
		"recipe": &"overdrive_field",
		"shape": &"stacked_forward_chevrons",
		"color": &"player_reward",
	},
	&"arc_surge_strip": {
		"recipe": &"arc_surge_strip",
		"shape": &"broken_bolt_rail",
		"color": &"arc",
	},
	&"breakable_bulkhead": {
		"recipe": &"breakable_bulkhead",
		"shape": &"fracture_split_bulkhead",
		"color": &"raised",
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in FIELD_DESCRIPTORS:
		ids.append(StringName(value))
	for value in FACILITY_DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func facility_descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(FACILITY_DESCRIPTORS.get(visual_id, {})).duplicate(true)
