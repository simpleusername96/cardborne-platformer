class_name VehicleProjectileVisualCatalog
extends RefCounted

## One authored projectile identity shared by every non-beam projectile. Runtime
## still owns collision, damage, cadence, homing, facing, scale, and tint.

const SHARED_VISUAL_ID := &"energy_teardrop"
const SHARED_ASSET_ID := &"projectile/energy_teardrop"

const DESCRIPTORS := {
	SHARED_VISUAL_ID: {
		"asset": SHARED_ASSET_ID,
		"shape": &"energy_teardrop",
		"facing": &"right",
		"collision_centered": true,
		"tail": false,
		"runtime_tint": true,
		"runtime_scale": true,
	},
}


static func descriptor_ids() -> Array[StringName]:
	return [SHARED_VISUAL_ID]


static func descriptor(visual_id: StringName = SHARED_VISUAL_ID) -> Dictionary:
	if visual_id != SHARED_VISUAL_ID:
		return {}
	return Dictionary(DESCRIPTORS[SHARED_VISUAL_ID]).duplicate(true)
