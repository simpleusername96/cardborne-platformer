class_name VehicleVisualEventCaptureFixture
extends RefCounted

## Reviewed grouping for full runtime effect capture. HUD-only events are
## intentionally absent because they do not create a world-space visual.

const VisualEventCatalog = preload(
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)

const GROUPS := [
	{
		"id": &"player",
		"events": [
			&"player_primary_muzzle",
			&"player_dash_start",
			&"player_dash_afterimage",
			&"player_hull_hit",
			&"player_barrier_hit",
			&"player_barrier_activate",
			&"player_emp_charge",
			&"player_emp_release",
			&"player_emp_aftershock",
			&"player_ram_pulse",
			&"player_phase_shear_hit",
			&"player_ram_impact",
		],
	},
	{
		"id": &"secondary",
		"events": [
			&"secondary_seeker_impact",
			&"secondary_seeker_burst",
			&"secondary_escort_impact",
			&"secondary_orbit_blade_impact",
			&"secondary_wake_mine_detonation",
			&"enemy_mine_detonation",
		],
	},
	{
		"id": &"projectile_hostile",
		"events": [
			&"hostile_projectile_impact",
			&"projectile_cover_impact",
			&"projectile_damage_impact",
			&"projectile_reflected",
			&"projectile_intercepted",
			&"enemy_barrier_hit",
			&"hostile_arrival",
			&"hostile_summon_arrival",
		],
	},
	{
		"id": &"destroy_boss",
		"events": [
			&"enemy_destroy_light",
			&"enemy_destroy_heavy",
			&"boss_core_reduced_hit",
			&"boss_module_resolved",
			&"bulkhead_destroy",
			&"crate_destroy",
			&"transit_complete",
		],
	},
	{
		"id": &"pickup_support",
		"events": [
			&"pickup_experience",
			&"pickup_repair",
			&"pickup_reward",
			&"support_heal",
			&"lifesteal_transfer",
		],
	},
]


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var captured := {}
	for group in GROUPS:
		for event_variant in Array(group["events"]):
			var event_id := StringName(event_variant)
			if captured.has(event_id):
				errors.append("duplicate capture event: %s" % event_id)
			captured[event_id] = true
			if not VisualEventCatalog.has_event(event_id):
				errors.append("capture fixture event is unmapped: %s" % event_id)
	for event_id in VisualEventCatalog.event_ids():
		var mode := StringName(
			VisualEventCatalog.descriptor(event_id).get(
				"mode",
				&"animation"
			)
		)
		if mode == &"hud_only":
			continue
		if not captured.has(event_id):
			errors.append("world event has no capture fixture: %s" % event_id)
	return errors
