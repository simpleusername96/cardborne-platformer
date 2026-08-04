class_name VehicleEffectVisualCatalog
extends RefCounted

## Geometry recipe lookup for the retained dash afterimage batch. Visual event
## feedback, including the authored EMP, is owned by VehicleVisualEventCatalog.

const DESCRIPTORS := {
	&"dash_afterimage": {
		"asset": &"attachment/player_craft_body",
		"media": &"authored_actor_reuse",
		"shape": &"elongated_hull",
		"color": &"system",
		"radial": false,
		"recipe": &"dash_player_hull_afterimage",
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
