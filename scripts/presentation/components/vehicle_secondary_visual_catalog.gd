class_name VehicleSecondaryVisualCatalog
extends RefCounted

## Presentation identities for player secondaries. Cadence, targeting, damage,
## orbit motion, mine triggers, and drone behavior stay in secondary runtime.

const DESCRIPTORS := {
	&"seeker": {
		"asset": &"secondary/seeker",
		"projectile_asset": &"projectile/player_seeker",
		"silhouette": &"guided_forward_wedge",
		"motion": &"homing",
	},
	&"escort_drone": {
		"asset": &"secondary/escort_drone",
		"silhouette": &"twin_fin_support_drone",
		"motion": &"escort",
	},
	&"orbit_blade": {
		"asset": &"secondary/orbit_blade",
		"silhouette": &"long_split_blade",
		"motion": &"orbit",
	},
	&"wake_mine": {
		"asset": &"secondary/wake_mine",
		"silhouette": &"four_point_anchor",
		"motion": &"stationary",
	},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for visual_id in DESCRIPTORS:
		ids.append(StringName(visual_id))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
