class_name VehicleEnemyArchetypes
extends RefCounted

## Immutable combat/presentation values for vehicle-stage enemy roles.
## The stage owns instances; this catalog prevents role tuning from spreading.

const PROJECTILE_FIRING_ARCHETYPES: Array[StringName] = [
	&"ordinary_ranged_01", &"ordinary_lane_01", &"ordinary_growth_01",
	&"ordinary_gap_01", &"ordinary_beam_01", &"ordinary_range_01",
	&"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02",
	&"ordinary_fixed_beam_01", &"boss_actor",
]

const MOVING_PROJECTILE_TARGET_RADIUS := 48.0
const INSTALLATION_PROJECTILE_TARGET_RADIUS := 62.0
const BOSS_PROJECTILE_TARGET_RADIUS := 146.0
const INSTALLATION_ARCHETYPES: Array[StringName] = [
	&"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01",
	&"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01",
	&"ordinary_fixed_support_01",
]

const DEFINITIONS := {
	&"ordinary_melee_01": {"behavior": &"ordinary_edge_01", "health": 18.0, "speed": 190.0, "radius": 12.0, "name_key": "ORDINARY_MELEE_01", "health_class": &"swarm", "threat_cost": 0.25, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_ranged_01": {"behavior": &"ordinary_lane_01", "health": 14.0, "speed": 176.0, "radius": 11.0, "name_key": "ORDINARY_RANGED_01", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_area_01": {"behavior": &"ordinary_fixed_area_01", "health": 12.0, "speed": 100.0, "radius": 10.0, "name_key": "ORDINARY_AREA_01", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"denial", "active_cap": true},
	&"ordinary_lane_01": {"behavior": &"ordinary_lane_01", "health": 40.0, "speed": 166.0, "radius": 17.0, "name_key": "ORDINARY_LANE_01", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_shield_01": {"behavior": &"ordinary_shield_01", "health": 90.0, "speed": 164.0, "radius": 24.0, "name_key": "ORDINARY_SHIELD_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_sweep_01": {"behavior": &"ordinary_sweep_01", "health": 66.0, "speed": 238.0, "radius": 20.0, "name_key": "ORDINARY_SWEEP_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"ordinary_beam_01": {"behavior": &"ordinary_beam_01", "health": 72.0, "speed": 148.0, "radius": 20.0, "name_key": "ORDINARY_BEAM_01", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_growth_01": {"behavior": &"ordinary_growth_01", "health": 62.0, "speed": 140.0, "radius": 21.0, "name_key": "ORDINARY_GROWTH_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"ordinary_gap_01": {"behavior": &"ordinary_gap_01", "health": 60.0, "speed": 150.0, "radius": 21.0, "name_key": "ORDINARY_GAP_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"ordinary_pulse_01": {"behavior": &"ordinary_pulse_01", "health": 96.0, "speed": 157.0, "radius": 26.0, "name_key": "ORDINARY_PULSE_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_edge_01": {"behavior": &"ordinary_edge_01", "health": 48.0, "speed": 190.0, "radius": 18.0, "name_key": "ORDINARY_EDGE_01", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_pull_01": {"behavior": &"ordinary_pull_01", "health": 82.0, "speed": 190.0, "radius": 23.0, "name_key": "ORDINARY_PULL_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_range_01": {"behavior": &"ordinary_range_01", "health": 56.0, "speed": 172.0, "radius": 18.0, "name_key": "ORDINARY_RANGE_01", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_support_01": {"behavior": &"ordinary_support_01", "health": 74.0, "speed": 159.0, "radius": 22.0, "name_key": "ORDINARY_SUPPORT_01", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"ordinary_support_02": {"behavior": &"ordinary_support_02", "health": 86.0, "speed": 165.0, "radius": 23.0, "name_key": "ORDINARY_SUPPORT_02", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"ordinary_support_03": {"behavior": &"ordinary_support_03", "health": 104.0, "speed": 150.0, "radius": 26.0, "name_key": "ORDINARY_SUPPORT_03", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"ordinary_melee_02": {"behavior": &"ordinary_melee_02", "health": 80.0, "speed": 184.0, "radius": 22.0, "name_key": "ORDINARY_MELEE_02", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_fixed_ranged_01": {"behavior": &"ordinary_fixed_ranged_01", "health": 110.0, "speed": 0.0, "radius": 30.0, "name_key": "ORDINARY_FIXED_RANGED_01", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"ordinary_fixed_area_01": {"behavior": &"ordinary_fixed_area_01", "health": 65.0, "speed": 0.0, "radius": 27.0, "name_key": "ORDINARY_FIXED_AREA_01", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"melee", "active_cap": false},
	&"ordinary_fixed_ranged_02": {"behavior": &"ordinary_fixed_ranged_02", "health": 125.0, "speed": 0.0, "radius": 34.0, "name_key": "ORDINARY_FIXED_RANGED_02", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"ordinary_fixed_beam_01": {"behavior": &"ordinary_fixed_beam_01", "health": 138.0, "speed": 0.0, "radius": 34.0, "name_key": "ORDINARY_FIXED_BEAM_01", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": false},
	&"ordinary_fixed_support_01": {"behavior": &"ordinary_fixed_support_01", "health": 155.0, "speed": 0.0, "radius": 36.0, "name_key": "ORDINARY_FIXED_SUPPORT_01", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": false},
	&"boss_actor": {"behavior": &"boss", "health": 1450.0, "speed": 150.0, "radius": 76.0, "name_key": "BOSS_STAGE_01", "health_class": &"boss", "threat_cost": 0.0, "threat_kind": &"boss", "active_cap": false},
}


static func definition(archetype: StringName) -> Dictionary:
	return Dictionary(DEFINITIONS.get(archetype, DEFINITIONS[&"ordinary_melee_01"])).duplicate(true)


static func fires_projectiles(archetype: StringName) -> bool:
	return archetype in PROJECTILE_FIRING_ARCHETYPES


static func projectile_target_radius(archetype: StringName) -> float:
	if archetype == &"boss_actor":
		return BOSS_PROJECTILE_TARGET_RADIUS
	if archetype in INSTALLATION_ARCHETYPES:
		return INSTALLATION_PROJECTILE_TARGET_RADIUS
	return MOVING_PROJECTILE_TARGET_RADIUS


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for archetype in PROJECTILE_FIRING_ARCHETYPES:
		if not DEFINITIONS.has(archetype):
			errors.append("unknown projectile-firing archetype: %s" % archetype)
	for required in DEFINITIONS:
		if not DEFINITIONS.has(required):
			errors.append("missing vehicle enemy archetype: %s" % required)
	for archetype in DEFINITIONS:
		var data: Dictionary = DEFINITIONS[archetype]
		if float(data["health"]) <= 0.0 or float(data["radius"]) <= 0.0:
			errors.append("invalid enemy dimensions: %s" % archetype)
	return errors
