class_name VehicleEnemyArchetypes
extends RefCounted

## Immutable combat/presentation values for vehicle-stage enemy roles.
## The stage owns instances; this catalog prevents role tuning from spreading.

const DEFINITIONS := {
	&"scrap_drone": {"behavior": &"chaser", "health": 18.0, "speed": 225.0, "radius": 12.0, "visual_radius": 18.0, "name_key": "ENEMY_SCRAP_DRONE", "health_class": &"swarm", "threat_cost": 0.25, "threat_kind": &"melee", "active_cap": true},
	&"needle_drone": {"behavior": &"shooter", "health": 14.0, "speed": 170.0, "radius": 11.0, "visual_radius": 17.0, "name_key": "ENEMY_NEEDLE_DRONE", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"ranged", "active_cap": true},
	&"spark_minelet": {"behavior": &"mine", "health": 12.0, "speed": 90.0, "radius": 10.0, "visual_radius": 16.0, "name_key": "ENEMY_SPARK_MINELET", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"melee", "active_cap": true},
	&"chaser": {"behavior": &"chaser", "health": 48.0, "speed": 205.0, "radius": 18.0, "visual_radius": 26.0, "name_key": "ENEMY_RIVET_CHASER", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"melee", "active_cap": true},
	&"shooter": {"behavior": &"shooter", "health": 40.0, "speed": 155.0, "radius": 17.0, "visual_radius": 24.0, "name_key": "ENEMY_LANE_SKIRMISHER", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"ranged", "active_cap": true},
	&"controller": {"behavior": &"controller", "health": 60.0, "speed": 135.0, "radius": 21.0, "visual_radius": 30.0, "name_key": "ENEMY_FLOOD_CONTROLLER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"shield_escort": {"behavior": &"shield_escort", "health": 68.0, "speed": 165.0, "radius": 20.0, "visual_radius": 28.0, "name_key": "ENEMY_SHIELD_ESCORT", "health_class": &"standard", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"artillery_spotter": {"behavior": &"artillery_spotter", "health": 62.0, "speed": 115.0, "radius": 21.0, "visual_radius": 30.0, "name_key": "ENEMY_ARTILLERY_SPOTTER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"turret": {"behavior": &"turret", "health": 110.0, "speed": 0.0, "radius": 30.0, "visual_radius": 46.0, "name_key": "ENEMY_FOUNDRY_TURRET", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"mine": {"behavior": &"mine", "health": 65.0, "speed": 0.0, "radius": 27.0, "visual_radius": 42.0, "name_key": "ENEMY_ARC_MINE", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"melee", "active_cap": false},
	&"interceptor_tower": {"behavior": &"interceptor_tower", "health": 125.0, "speed": 0.0, "radius": 34.0, "visual_radius": 50.0, "name_key": "ENEMY_INTERCEPTOR_TOWER", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"rammer": {"behavior": &"rammer", "health": 82.0, "speed": 185.0, "radius": 23.0, "visual_radius": 33.0, "name_key": "ENEMY_RAMMER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"repair_tender": {"behavior": &"repair_tender", "health": 74.0, "speed": 145.0, "radius": 22.0, "visual_radius": 32.0, "name_key": "ENEMY_REPAIR_TENDER", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"drone_carrier": {"behavior": &"drone_carrier", "health": 126.0, "speed": 105.0, "radius": 30.0, "visual_radius": 44.0, "name_key": "ENEMY_DRONE_CARRIER", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"support", "active_cap": true},
	&"beam_sentinel": {"behavior": &"beam_sentinel", "health": 138.0, "speed": 0.0, "radius": 34.0, "visual_radius": 50.0, "name_key": "ENEMY_BEAM_SENTINEL", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": false},
	&"generator": {"behavior": &"generator", "health": 155.0, "speed": 0.0, "radius": 36.0, "visual_radius": 52.0, "name_key": "ENEMY_BARRIER_GENERATOR", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": false},
	&"boss_pylon": {"behavior": &"boss_pylon", "health": 120.0, "speed": 0.0, "radius": 33.0, "visual_radius": 48.0, "name_key": "ENEMY_COLOSSUS_PYLON", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": false},
	&"stage_boss": {"behavior": &"stage_boss", "health": 1450.0, "speed": 150.0, "radius": 76.0, "visual_radius": 112.0, "name_key": "ENEMY_FOUNDRY_COLOSSUS", "health_class": &"boss", "threat_cost": 0.0, "threat_kind": &"boss", "active_cap": false},
}


static func definition(archetype: StringName) -> Dictionary:
	return Dictionary(DEFINITIONS.get(archetype, DEFINITIONS[&"chaser"])).duplicate(true)


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for required in [&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser", &"shooter", &"controller", &"rammer", &"repair_tender", &"drone_carrier", &"beam_sentinel", &"generator", &"stage_boss"]:
		if not DEFINITIONS.has(required):
			errors.append("missing vehicle enemy archetype: %s" % required)
	for archetype in DEFINITIONS:
		var data: Dictionary = DEFINITIONS[archetype]
		if float(data["health"]) <= 0.0 or float(data["radius"]) <= 0.0 or float(data["visual_radius"]) < float(data["radius"]):
			errors.append("invalid enemy dimensions: %s" % archetype)
	return errors
