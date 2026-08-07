class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface and facility descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const FIELD_DESCRIPTORS := {
	&"drowned_ruin_field": {"rhythm": &"central_court", "decoration_budget": 0},
	&"tidal_archive_field": {"rhythm": &"parallel_bays", "decoration_budget": 0},
	&"storm_drydock_field": {"rhythm": &"basin_modules", "decoration_budget": 0},
}

const WORLD_OBJECT_DESCRIPTORS := {
	&"transit_gate": {
		"asset": &"world/facility_transit_gate",
		"kind": &"transit_gate",
		"shape": &"round_portal",
		"color": &"system",
	},
	&"hazard_toxic_bog": {
		"asset": &"world/hazard_toxic_bog",
		"kind": &"hazard_zone",
		"variant": &"toxic_bog",
		"shape": &"broad_ground",
		"color": &"toxin",
	},
	&"hazard_lava_pool": {
		"asset": &"world/hazard_lava_pool",
		"kind": &"hazard_zone",
		"variant": &"lava_pool",
		"shape": &"broad_ground",
		"color": &"thermal",
	},
	&"mystery_device_intact": {
		"asset": &"world/mystery_device_intact",
		"kind": &"mystery_device",
		"state": &"intact",
		"shape": &"neutral_mechanical_body",
		"color": &"system",
	},
	&"mystery_device_resolved": {
		"asset": &"world/mystery_device_resolved",
		"kind": &"mystery_device",
		"state": &"resolved",
		"shape": &"resolved_wreck",
		"color": &"raised",
	},
	&"reinforcement_fabricator": {
		"asset": &"world/facility_reinforcement_fabricator",
		"kind": &"reinforcement_facility",
		"shape": &"wide_static_fabricator",
		"color": &"danger",
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in FIELD_DESCRIPTORS:
		ids.append(StringName(value))
	for value in WORLD_OBJECT_DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func world_object_descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(WORLD_OBJECT_DESCRIPTORS.get(visual_id, {})).duplicate(true)
