class_name VehicleEnemyArchetypes
extends RefCounted

## Immutable combat/presentation values for vehicle-stage enemy roles.
## The stage owns instances; this catalog prevents role tuning from spreading.

const PROJECTILE_FIRING_ARCHETYPES: Array[StringName] = [
	&"needle_drone", &"shooter", &"controller", &"turret",
	&"artillery_spotter", &"interceptor_tower", &"stage_boss",
]

const MOVING_PROJECTILE_TARGET_RADIUS := 48.0
const INSTALLATION_PROJECTILE_TARGET_RADIUS := 62.0
const BOSS_PROJECTILE_TARGET_RADIUS := 146.0
const INSTALLATION_ARCHETYPES: Array[StringName] = [
	&"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"generator",
]

const DEFINITIONS := {
	&"scrap_drone": {"behavior": &"chaser", "health": 18.0, "speed": 190.0, "radius": 12.0, "name_key": "ENEMY_SCRAP_DRONE", "health_class": &"swarm", "threat_cost": 0.25, "threat_kind": &"melee", "active_cap": true},
	&"needle_drone": {"behavior": &"shooter", "health": 14.0, "speed": 176.0, "radius": 11.0, "name_key": "ENEMY_NEEDLE_DRONE", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"ranged", "active_cap": true},
	&"spark_minelet": {"behavior": &"mine", "health": 12.0, "speed": 100.0, "radius": 10.0, "name_key": "ENEMY_SPARK_MINELET", "health_class": &"swarm", "threat_cost": 0.5, "threat_kind": &"melee", "active_cap": true},
	&"chaser": {"behavior": &"chaser", "health": 48.0, "speed": 190.0, "radius": 18.0, "name_key": "ENEMY_RIVET_CHASER", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"melee", "active_cap": true},
	&"shooter": {"behavior": &"shooter", "health": 40.0, "speed": 166.0, "radius": 17.0, "name_key": "ENEMY_LANE_SKIRMISHER", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"ranged", "active_cap": true},
	&"controller": {"behavior": &"controller", "health": 60.0, "speed": 150.0, "radius": 21.0, "name_key": "ENEMY_FLOOD_CONTROLLER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"shield_escort": {"behavior": &"shield_escort", "health": 68.0, "speed": 170.0, "radius": 20.0, "name_key": "ENEMY_SHIELD_ESCORT", "health_class": &"standard", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"artillery_spotter": {"behavior": &"artillery_spotter", "health": 62.0, "speed": 140.0, "radius": 21.0, "name_key": "ENEMY_ARTILLERY_SPOTTER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"denial", "active_cap": true},
	&"turret": {"behavior": &"turret", "health": 110.0, "speed": 0.0, "radius": 30.0, "name_key": "ENEMY_FOUNDRY_TURRET", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"mine": {"behavior": &"mine", "health": 65.0, "speed": 0.0, "radius": 27.0, "name_key": "ENEMY_ARC_MINE", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"melee", "active_cap": false},
	&"interceptor_tower": {"behavior": &"interceptor_tower", "health": 125.0, "speed": 0.0, "radius": 34.0, "name_key": "ENEMY_INTERCEPTOR_TOWER", "health_class": &"priority", "threat_cost": 1.25, "threat_kind": &"ranged", "active_cap": false},
	&"rammer": {"behavior": &"rammer", "health": 82.0, "speed": 190.0, "radius": 23.0, "name_key": "ENEMY_RAMMER", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"bulkhead_guard": {"behavior": &"bulkhead_guard", "health": 90.0, "speed": 164.0, "radius": 24.0, "name_key": "ENEMY_BULKHEAD_GUARD", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"splitter_barge": {"behavior": &"splitter_barge", "health": 96.0, "speed": 157.0, "radius": 26.0, "name_key": "ENEMY_SPLITTER_BARGE", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"repair_tender": {"behavior": &"repair_tender", "health": 74.0, "speed": 159.0, "radius": 22.0, "name_key": "ENEMY_REPAIR_TENDER", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": true},
	&"drone_carrier": {"behavior": &"drone_carrier", "health": 126.0, "speed": 136.0, "radius": 30.0, "name_key": "ENEMY_DRONE_CARRIER", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"support", "active_cap": true},
	&"beam_sentinel": {"behavior": &"beam_sentinel", "health": 138.0, "speed": 0.0, "radius": 34.0, "name_key": "ENEMY_BEAM_SENTINEL", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": false},
	&"generator": {"behavior": &"generator", "health": 155.0, "speed": 0.0, "radius": 36.0, "name_key": "ENEMY_BARRIER_GENERATOR", "health_class": &"priority", "threat_cost": 0.0, "threat_kind": &"support", "active_cap": false},
	&"stage_boss": {"behavior": &"stage_boss", "health": 1450.0, "speed": 150.0, "radius": 76.0, "name_key": "ENEMY_FOUNDRY_COLOSSUS", "health_class": &"boss", "threat_cost": 0.0, "threat_kind": &"boss", "active_cap": false},
}


static func definition(archetype: StringName) -> Dictionary:
	return Dictionary(DEFINITIONS.get(archetype, DEFINITIONS[&"chaser"])).duplicate(true)


static func fires_projectiles(archetype: StringName) -> bool:
	return archetype in PROJECTILE_FIRING_ARCHETYPES


static func projectile_target_radius(archetype: StringName) -> float:
	if archetype == &"stage_boss":
		return BOSS_PROJECTILE_TARGET_RADIUS
	if archetype in INSTALLATION_ARCHETYPES:
		return INSTALLATION_PROJECTILE_TARGET_RADIUS
	return MOVING_PROJECTILE_TARGET_RADIUS


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for archetype in PROJECTILE_FIRING_ARCHETYPES:
		if not DEFINITIONS.has(archetype):
			errors.append("unknown projectile-firing archetype: %s" % archetype)
	for required in [&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser", &"shooter", &"controller", &"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender", &"drone_carrier", &"beam_sentinel", &"generator", &"stage_boss"]:
		if not DEFINITIONS.has(required):
			errors.append("missing vehicle enemy archetype: %s" % required)
	for archetype in DEFINITIONS:
		var data: Dictionary = DEFINITIONS[archetype]
		if float(data["health"]) <= 0.0 or float(data["radius"]) <= 0.0:
			errors.append("invalid enemy dimensions: %s" % archetype)
	return errors
