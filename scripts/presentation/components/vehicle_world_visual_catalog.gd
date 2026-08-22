class_name VehicleWorldVisualCatalog
extends RefCounted

## Field surface and world-object descriptors. Geometry, collision,
## navigation, placement, schedules, and deterministic layout stay authoritative.

const FIELD_DESCRIPTORS := {
	&"field_01": {"rhythm": &"central_court", "decoration_budget": 192},
	&"field_02": {"rhythm": &"parallel_bays", "decoration_budget": 192},
	&"field_03": {"rhythm": &"basin_modules", "decoration_budget": 192},
}

const WORLD_OBJECT_DESCRIPTORS := {
	&"transit_gate": {
		"asset": &"world/facility_transit_gate",
		"kind": &"transit_gate",
		"shape": &"round_portal",
		"color": &"system",
	},
	&"repair_beacon": {
		"asset": &"world/facility_repair_beacon",
		"kind": &"neutral_facility",
		"shape": &"service_cross",
		"color": &"support",
	},
	&"mystery_device_cryo": {
		"asset": &"world/mystery_device_cryo", "kind": &"mystery_device_symbol", "shape": &"broad_snowflake",
	},
	&"mystery_device_weakpoint": {
		"asset": &"world/mystery_device_weakpoint", "kind": &"mystery_device_symbol", "shape": &"opened_armor",
	},
	&"mystery_device_lava": {
		"asset": &"world/mystery_device_lava", "kind": &"mystery_device_symbol", "shape": &"thermal_vent",
	},
	&"enemy_upgrade_device": {
		"asset": &"world/enemy_upgrade_device",
		"kind": &"enemy_upgrade_device",
		"shape": &"triad_forge",
		"color": &"danger",
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
