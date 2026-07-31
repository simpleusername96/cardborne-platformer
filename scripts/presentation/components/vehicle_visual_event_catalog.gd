class_name VehicleVisualEventCatalog
extends RefCounted

## Presentation-only contract between gameplay events and semantic-v2 assets.
## Gameplay owners emit exact event IDs; this catalog decides how they render.

const EVENTS := {
	&"player_primary_muzzle": {
		"animation": &"muzzle_player_primary",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_dash_start": {
		"animation": &"dash_start",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_dash_afterimage": {
		"mode": &"hull_afterimage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_hull_hit": {
		"animation": &"hull_hit",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_barrier_hit": {
		"animation": &"barrier_contact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_barrier_activate": {
		"animation": &"barrier_contact",
		"tint": &"event",
	},
	&"player_emp_charge": {
		"mode": &"live_emp_radius",
		"tint": &"event",
	},
	&"player_emp_release": {
		"animation": &"emp_release",
		"tint": &"event",
	},
	&"player_emp_aftershock": {
		"animation": &"emp_release",
		"tint": &"event",
	},
	&"player_ram_pulse": {
		"animation": &"emp_release",
		"tint": &"event",
	},
	&"player_phase_shear_hit": {
		"animation": &"impact_damage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"player_ram_impact": {
		"animation": &"impact_damage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"secondary_seeker_impact": {
		"animation": &"seeker_impact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"secondary_seeker_burst": {
		"animation": &"seeker_impact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"secondary_escort_impact": {
		"animation": &"escort_drone_impact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"secondary_orbit_blade_impact": {
		"animation": &"orbit_blade_impact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"secondary_wake_mine_detonation": {
		"animation": &"wake_mine_detonation",
		"tint": &"event",
	},
	&"enemy_mine_detonation": {
		"animation": &"wake_mine_detonation",
		"tint": &"event",
	},
	&"hostile_projectile_impact": {
		"animation": &"impact_damage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"projectile_cover_impact": {
		"animation": &"impact_damage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"projectile_damage_impact": {
		"animation": &"impact_damage",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"projectile_reflected": {
		"animation": &"reflect_deflection",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"projectile_intercepted": {
		"animation": &"reflect_deflection",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"enemy_barrier_hit": {
		"animation": &"barrier_contact",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"hostile_arrival": {
		"animation": &"hostile_summon_arrival",
		"tint": &"event",
	},
	&"hostile_summon_arrival": {
		"animation": &"hostile_summon_arrival",
		"tint": &"event",
	},
	&"enemy_destroy_light": {
		"animation": &"enemy_destroy_light",
		"tint": &"event",
	},
	&"enemy_destroy_heavy": {
		"animation": &"enemy_destroy_heavy",
		"tint": &"event",
	},
	&"boss_core_reduced_hit": {
		"animation": &"boss_reduced_hit",
		"rotation": &"direction",
		"tint": &"event",
		"floating_damage": true,
	},
	&"boss_module_resolved": {
		"animation": &"boss_module_disabled",
		"tint": &"event",
	},
	&"pickup_experience": {
		"animation": &"pickup_intake",
		"mode": &"pickup_intake",
		"tint": &"event",
	},
	&"pickup_repair": {
		"animation": &"pickup_intake",
		"mode": &"pickup_intake",
		"tint": &"event",
	},
	&"pickup_reward": {
		"animation": &"pickup_intake",
		"mode": &"pickup_intake",
		"tint": &"event",
	},
	&"support_heal": {
		"animation": &"support_heal",
		"tint": &"event",
	},
	&"lifesteal_transfer": {
		"animation": &"lifesteal_pulse",
		"mode": &"directed_transfer",
		"rotation": &"target",
		"tint": &"event",
	},
	&"transit_complete": {
		"animation": &"transit_shift",
		"rotation": &"direction",
		"tint": &"event",
	},
	&"bulkhead_destroy": {
		"animation": &"bulkhead_destroy",
		"tint": &"event",
	},
	&"crate_destroy": {
		"animation": &"crate_destroy",
		"tint": &"event",
	},
	&"group_clear": {
		"mode": &"hud_only",
	},
}


static func has_event(event_id: StringName) -> bool:
	return EVENTS.has(event_id)


static func descriptor(event_id: StringName) -> Dictionary:
	return Dictionary(EVENTS.get(event_id, {}))


static func event_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for event_id in EVENTS:
		ids.append(StringName(event_id))
	ids.sort()
	return ids
