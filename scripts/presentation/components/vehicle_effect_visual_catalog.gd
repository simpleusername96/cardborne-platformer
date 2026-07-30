class_name VehicleEffectVisualCatalog
extends RefCounted

## Transient semantic effect descriptors. Timers, damage, protection sources,
## stack rules, and state transitions remain outside this catalog.

const SOURCE_FAMILIES: Array[StringName] = [
	&"player_dash_effect",
	&"player_status_overlays",
	&"elite_trait_overlays",
	&"enemy_condition_overlays",
	&"player_projectile_modifier_overlays",
	&"secondary_ion_field",
	&"secondary_orbit_blades",
	&"secondary_wake_mines",
	&"telegraph_shape_system",
	&"impact_effects",
]

const DESCRIPTORS := {
	&"dash_afterimage": {"shape": &"elongated_hull", "color": &"system", "radial": false},
	&"dash_engine_flare": {"shape": &"rear_flare", "color": &"system", "radial": false},
	&"barrier": {"shape": &"open_ring", "color": &"support", "radial": true},
	&"arrival": {"shape": &"corner_brackets", "color": &"system", "radial": false},
	&"transit": {"shape": &"opposing_chevrons", "color": &"system", "radial": false},
	&"hull_hit": {"shape": &"hull_flash", "color": &"danger", "radial": false},
	&"telegraph": {"shape": &"live_footprint", "color": &"danger", "radial": false},
	&"impact": {"shape": &"short_sparks", "color": &"text_primary", "radial": false},
	&"condition_burn": {"shape": &"broken_arc", "color": &"thermal", "radial": true},
	&"condition_poison": {"shape": &"dotted_arc", "color": &"toxin", "radial": true},
	&"condition_chill": {"shape": &"split_arc", "color": &"cryo", "radial": true},
}


static func source_family_ids() -> Array[StringName]:
	return SOURCE_FAMILIES.duplicate()


static func descriptor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in DESCRIPTORS:
		ids.append(StringName(value))
	ids.sort()
	return ids


static func descriptor(visual_id: StringName) -> Dictionary:
	return Dictionary(DESCRIPTORS.get(visual_id, {})).duplicate(true)
