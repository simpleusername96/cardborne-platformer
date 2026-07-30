class_name VehicleProjectileVisualCatalog
extends RefCounted

## Projectile core/tail descriptors normalized around collision radius. Damage,
## range, cadence, hit rules, and live collision radii remain gameplay truth.

const DESCRIPTORS := {
	&"player_primary": {"owner": &"player", "core": &"disk", "tail": &"single_rail", "color": &"player_reward"},
	&"opening_breach": {"owner": &"player", "core": &"split_disk", "tail": &"double_rail", "color": &"player_reward"},
	&"kinetic": {"owner": &"hostile", "core": &"disk", "tail": &"single_rail", "color": &"danger"},
	&"thermal": {"owner": &"hostile", "core": &"ember", "tail": &"flare", "color": &"thermal"},
	&"toxin": {"owner": &"hostile", "core": &"drop", "tail": &"beads", "color": &"toxin"},
	&"cryo": {"owner": &"hostile", "core": &"shard", "tail": &"twin_rail", "color": &"cryo"},
	&"arc": {"owner": &"hostile", "core": &"bolt", "tail": &"broken_rail", "color": &"arc"},
	&"hybrid": {"owner": &"hostile", "core": &"split_diamond", "tail": &"split_rail", "color": &"text_primary"},
	&"seeker": {"owner": &"player", "core": &"forward_wedge", "tail": &"single_rail", "color": &"support"},
}


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
