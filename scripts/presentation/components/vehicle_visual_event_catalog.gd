class_name VehicleVisualEventCatalog
extends RefCounted

## Presentation-only contract between gameplay events and visual feedback.
## Minor cosmetic events stay mapped but intentionally render no raster frames.

const EVENTS := {
	&"player_primary_muzzle": {"mode": &"direct_feedback"},
	&"player_dash_start": {"mode": &"direct_feedback"},
	&"player_dash_afterimage": {
		"mode": &"hull_afterimage",
		"rotation": &"direction",
	},
	&"player_hull_hit": {"mode": &"direct_feedback"},
	&"player_barrier_hit": {"mode": &"direct_feedback"},
	&"player_barrier_activate": {"mode": &"direct_feedback"},
	&"player_emp_charge": {"mode": &"live_emp_radius"},
	&"player_emp_release": {
		"mode": &"authored_emp",
		"asset": &"effect/emp_release",
	},
	&"player_emp_aftershock": {"mode": &"suppressed"},
	&"player_ram_pulse": {"mode": &"suppressed"},
	&"player_phase_shear_hit": {"mode": &"suppressed"},
	&"player_ram_impact": {"mode": &"suppressed"},
	&"secondary_seeker_impact": {"mode": &"suppressed"},
	&"secondary_seeker_burst": {"mode": &"suppressed"},
	&"secondary_escort_impact": {"mode": &"suppressed"},
	&"secondary_orbit_blade_impact": {"mode": &"suppressed"},
	&"secondary_wake_mine_detonation": {"mode": &"direct_feedback"},
	&"enemy_mine_detonation": {"mode": &"direct_feedback"},
	&"hostile_projectile_impact": {"mode": &"suppressed"},
	&"projectile_cover_impact": {"mode": &"suppressed"},
	&"projectile_damage_impact": {"mode": &"suppressed"},
	&"projectile_reflected": {"mode": &"direct_feedback"},
	&"projectile_intercepted": {"mode": &"direct_feedback"},
	&"enemy_barrier_hit": {"mode": &"direct_feedback"},
	&"hostile_arrival": {"mode": &"direct_feedback"},
	&"hostile_summon_arrival": {"mode": &"direct_feedback"},
	&"enemy_destroy_light": {"mode": &"suppressed"},
	&"enemy_destroy_heavy": {"mode": &"suppressed"},
	&"boss_core_reduced_hit": {
		"mode": &"floating_damage",
		"floating_damage": true,
	},
	&"boss_module_resolved": {"mode": &"direct_feedback"},
	&"pickup_experience": {"mode": &"suppressed"},
	&"pickup_repair": {"mode": &"suppressed"},
	&"pickup_reward": {"mode": &"suppressed"},
	&"support_heal": {"mode": &"direct_feedback"},
	&"lifesteal_transfer": {
		"mode": &"directed_transfer",
		"rotation": &"target",
	},
	&"transit_complete": {"mode": &"direct_feedback"},
	&"bulkhead_destroy": {"mode": &"direct_feedback"},
	&"crate_destroy": {"mode": &"direct_feedback"},
	&"group_clear": {"mode": &"hud_only"},
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
