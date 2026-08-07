class_name VehicleProjectileVisualCatalog
extends RefCounted

## Separate authored identities for player primary, player seeker, and hostile
## non-beam projectiles. Runtime still owns collision, damage, homing, scale, and tint.

const PLAYER_PRIMARY := &"player_primary"
const PLAYER_SEEKER := &"player_seeker"
const HOSTILE := &"hostile"

const DESCRIPTORS := {
	PLAYER_PRIMARY: {
		"asset": &"projectile/energy_teardrop",
		"shape": &"energy_teardrop",
		"facing": &"right",
		"collision_centered": true,
	},
	PLAYER_SEEKER: {
		"asset": &"secondary/seeker",
		"shape": &"guided_forward_wedge",
		"facing": &"right",
		"collision_centered": true,
	},
	HOSTILE: {
		"asset": &"projectile/hostile_barbed_bolt",
		"shape": &"barbed_spearhead",
		"facing": &"right",
		"collision_centered": true,
	},
}


static func descriptor_ids() -> Array[StringName]:
	return [PLAYER_PRIMARY, PLAYER_SEEKER, HOSTILE]


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)


static func asset_id(visual_id: StringName) -> StringName:
	return StringName(descriptor(visual_id).get("asset", &""))
