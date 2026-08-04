class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface and facility descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const FIELD_DESCRIPTORS := {
	&"drowned_ruin_field": {"rhythm": &"central_court", "decoration_budget": 0},
	&"tidal_archive_field": {"rhythm": &"parallel_bays", "decoration_budget": 0},
	&"storm_drydock_field": {"rhythm": &"basin_modules", "decoration_budget": 0},
}

const FACILITY_DESCRIPTORS := {
	&"repair_field": {
		"asset": &"world/facility_repair_pad",
		"shape": &"round_plus_pad",
		"color": &"support",
	},
	&"transit_gate": {
		"asset": &"world/facility_transit_gate",
		"shape": &"round_portal",
		"color": &"system",
	},
	&"overdrive_field": {
		"asset": &"world/facility_overdrive_pad",
		"shape": &"round_forward_pad",
		"color": &"player_reward",
	},
	&"arc_surge_strip": {
		"asset": &"world/facility_arc_surge_strip",
		"shape": &"arc_pylon",
		"color": &"arc",
	},
	&"breakable_bulkhead": {
		"asset_family": &"world/world_bulkhead",
		"shape": &"split_bulkhead",
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
