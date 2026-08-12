class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface and world-object descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const FIELD_DESCRIPTORS := {
	&"drowned_ruin_field": {"rhythm": &"central_court", "decoration_budget": 192},
	&"tidal_archive_field": {"rhythm": &"parallel_bays", "decoration_budget": 192},
	&"storm_drydock_field": {"rhythm": &"basin_modules", "decoration_budget": 192},
}

const WORLD_OBJECT_DESCRIPTORS := {
	&"transit_gate": {
		"asset": &"world/facility_transit_gate",
		"kind": &"transit_gate",
		"shape": &"round_portal",
		"color": &"system",
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
}

const SURFACE_DETAIL_DESCRIPTORS := {
	&"surface_detail_crack": {
		"asset": &"world/surface_detail_crack",
		"family": &"crack",
		"canvas": Vector2i(96, 96),
	},
	&"surface_detail_stain": {
		"asset": &"world/surface_detail_stain",
		"family": &"stain",
		"canvas": Vector2i(128, 96),
	},
	&"surface_detail_embedded_chip": {
		"asset": &"world/surface_detail_embedded_chip",
		"family": &"embedded_chip",
		"canvas": Vector2i(64, 64),
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in FIELD_DESCRIPTORS:
		ids.append(StringName(value))
	for value in WORLD_OBJECT_DESCRIPTORS:
		ids.append(StringName(value))
	for value in SURFACE_DETAIL_DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func world_object_descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(WORLD_OBJECT_DESCRIPTORS.get(visual_id, {})).duplicate(true)
