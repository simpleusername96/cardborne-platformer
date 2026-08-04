class_name VehicleEffectVisualCatalog
extends RefCounted

## Presentation recipes only. Gameplay timers, damage, protection, and status
## truth remain with their existing owners; EMP is the sole authored effect.

const DESCRIPTORS := {
	&"emp_release": {
		"asset": &"effect/emp_release",
		"media": &"authored_raster",
		"shape": &"live_radius_pulse",
		"color": &"system",
	},
	&"dash_afterimage": {
		"asset": &"attachment/player_craft_body",
		"media": &"authored_actor_reuse",
		"shape": &"elongated_hull",
		"color": &"system",
		"radial": false,
		"recipe": &"dash_player_hull_afterimage",
	},
	&"dash_engine_flare": {
		"media": &"code_native",
		"shape": &"rear_flare",
		"color": &"system",
		"radial": false,
	},
	&"barrier": {
		"media": &"code_native",
		"shape": &"support_ring",
		"color": &"support",
		"radial": true,
	},
	&"hull_hit": {
		"media": &"code_native",
		"shape": &"actor_tint",
		"color": &"danger",
		"radial": false,
	},
	&"telegraph": {
		"media": &"code_native",
		"shape": &"live_footprint",
		"color": &"danger",
		"radial": false,
	},
	&"minor_event": {
		"media": &"suppressed",
		"shape": &"none",
		"radial": false,
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
