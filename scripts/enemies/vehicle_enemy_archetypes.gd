class_name VehicleEnemyArchetypes
extends RefCounted

## Immutable family-tier combat data. `behavior` names an internal combat primitive;
## player-facing identity is always the archetype's family and tier.

const ORDINARY_ARCHETYPES: Array[StringName] = [
	&"ordinary_pursuer_t1", &"ordinary_pursuer_t2", &"ordinary_pursuer_t3",
	&"ordinary_charger_t1", &"ordinary_charger_t2", &"ordinary_charger_t3",
	&"ordinary_emitter_t1", &"ordinary_emitter_t2", &"ordinary_emitter_t3",
	&"ordinary_defender_t1", &"ordinary_defender_t2", &"ordinary_defender_t3",
	&"ordinary_coordinator_t1", &"ordinary_coordinator_t2", &"ordinary_coordinator_t3",
]
const PROJECTILE_FIRING_ARCHETYPES: Array[StringName] = [
	&"ordinary_emitter_t1", &"ordinary_emitter_t2", &"ordinary_emitter_t3",
	&"boss_pattern_fixed_beam_01", &"boss_actor",
]

const MOVING_PROJECTILE_TARGET_RADIUS := 48.0
const INSTALLATION_PROJECTILE_TARGET_RADIUS := 62.0
const BOSS_PROJECTILE_TARGET_RADIUS := 146.0
const INSTALLATION_ARCHETYPES: Array[StringName] = [&"boss_pattern_fixed_beam_01"]

const DEFINITIONS := {
	&"ordinary_pursuer_t1": {"family": &"pursuer", "tier": 1, "size_percent": 100, "behavior": &"ordinary_edge_01", "asset": &"actor/ordinary_pursuer_t1", "health": 38.0, "speed": 190.0, "radius": 18.0, "name_key": "ORDINARY_PURSUER_T1", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_pursuer_t2": {"family": &"pursuer", "tier": 2, "size_percent": 125, "behavior": &"ordinary_edge_01", "asset": &"actor/ordinary_pursuer_t2", "health": 52.0, "speed": 198.0, "radius": 18.0, "name_key": "ORDINARY_PURSUER_T2", "health_class": &"standard", "threat_cost": 1.15, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_pursuer_t3": {"family": &"pursuer", "tier": 3, "size_percent": 150, "behavior": &"ordinary_edge_01", "asset": &"actor/ordinary_pursuer_t3", "health": 70.0, "speed": 206.0, "radius": 18.0, "name_key": "ORDINARY_PURSUER_T3", "health_class": &"standard", "threat_cost": 1.3, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_charger_t1": {"family": &"charger", "tier": 1, "size_percent": 100, "behavior": &"ordinary_pull_01", "asset": &"actor/ordinary_charger_t1", "health": 58.0, "speed": 185.0, "radius": 23.0, "name_key": "ORDINARY_CHARGER_T1", "health_class": &"standard", "threat_cost": 1.25, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_charger_t2": {"family": &"charger", "tier": 2, "size_percent": 125, "behavior": &"ordinary_pull_01", "asset": &"actor/ordinary_charger_t2", "health": 78.0, "speed": 192.0, "radius": 23.0, "name_key": "ORDINARY_CHARGER_T2", "health_class": &"standard", "threat_cost": 1.45, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_charger_t3": {"family": &"charger", "tier": 3, "size_percent": 150, "behavior": &"ordinary_pull_01", "asset": &"actor/ordinary_charger_t3", "health": 104.0, "speed": 199.0, "radius": 23.0, "name_key": "ORDINARY_CHARGER_T3", "health_class": &"priority", "threat_cost": 1.65, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_emitter_t1": {"family": &"emitter", "tier": 1, "size_percent": 100, "behavior": &"ordinary_lane_01", "asset": &"actor/ordinary_emitter_t1", "health": 42.0, "speed": 166.0, "radius": 18.0, "name_key": "ORDINARY_EMITTER_T1", "health_class": &"standard", "threat_cost": 1.0, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_emitter_t2": {"family": &"emitter", "tier": 2, "size_percent": 125, "behavior": &"ordinary_lane_01", "asset": &"actor/ordinary_emitter_t2", "health": 57.0, "speed": 171.0, "radius": 18.0, "name_key": "ORDINARY_EMITTER_T2", "health_class": &"standard", "threat_cost": 1.2, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_emitter_t3": {"family": &"emitter", "tier": 3, "size_percent": 150, "behavior": &"ordinary_lane_01", "asset": &"actor/ordinary_emitter_t3", "health": 76.0, "speed": 176.0, "radius": 18.0, "name_key": "ORDINARY_EMITTER_T3", "health_class": &"priority", "threat_cost": 1.4, "threat_kind": &"ranged", "active_cap": true},
	&"ordinary_defender_t1": {"family": &"defender", "tier": 1, "size_percent": 100, "behavior": &"ordinary_shield_01", "asset": &"actor/ordinary_defender_t1", "health": 90.0, "speed": 158.0, "radius": 24.0, "name_key": "ORDINARY_DEFENDER_T1", "health_class": &"standard", "threat_cost": 1.5, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_defender_t2": {"family": &"defender", "tier": 2, "size_percent": 125, "behavior": &"ordinary_shield_01", "asset": &"actor/ordinary_defender_t2", "health": 122.0, "speed": 162.0, "radius": 24.0, "name_key": "ORDINARY_DEFENDER_T2", "health_class": &"priority", "threat_cost": 1.7, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_defender_t3": {"family": &"defender", "tier": 3, "size_percent": 150, "behavior": &"ordinary_shield_01", "asset": &"actor/ordinary_defender_t3", "health": 162.0, "speed": 166.0, "radius": 24.0, "name_key": "ORDINARY_DEFENDER_T3", "health_class": &"priority", "threat_cost": 1.9, "threat_kind": &"melee", "active_cap": true},
	&"ordinary_coordinator_t1": {"family": &"coordinator", "tier": 1, "size_percent": 100, "behavior": &"ordinary_pulse_01", "asset": &"actor/ordinary_coordinator_t1", "health": 66.0, "speed": 157.0, "radius": 22.0, "name_key": "ORDINARY_COORDINATOR_T1", "health_class": &"priority", "threat_cost": 1.0, "threat_kind": &"support", "active_cap": true},
	&"ordinary_coordinator_t2": {"family": &"coordinator", "tier": 2, "size_percent": 125, "behavior": &"ordinary_pulse_01", "asset": &"actor/ordinary_coordinator_t2", "health": 89.0, "speed": 162.0, "radius": 22.0, "name_key": "ORDINARY_COORDINATOR_T2", "health_class": &"priority", "threat_cost": 1.2, "threat_kind": &"support", "active_cap": true},
	&"ordinary_coordinator_t3": {"family": &"coordinator", "tier": 3, "size_percent": 150, "behavior": &"ordinary_pulse_01", "asset": &"actor/ordinary_coordinator_t3", "health": 118.0, "speed": 167.0, "radius": 22.0, "name_key": "ORDINARY_COORDINATOR_T3", "health_class": &"priority", "threat_cost": 1.4, "threat_kind": &"support", "active_cap": true},
	&"boss_pattern_fixed_beam_01": {"family": &"boss_pattern", "tier": 0, "size_percent": 100, "behavior": &"ordinary_fixed_beam_01", "asset": &"actor/boss_pattern_fixed_beam_01", "health": 138.0, "speed": 0.0, "radius": 34.0, "name_key": "BOSS_PATTERN_FIXED_BEAM_01", "health_class": &"priority", "threat_cost": 1.5, "threat_kind": &"ranged", "active_cap": false},
	&"boss_actor": {"family": &"boss", "tier": 0, "size_percent": 100, "behavior": &"boss", "health": 1450.0, "speed": 150.0, "radius": 76.0, "name_key": "BOSS_STAGE_01", "health_class": &"boss", "threat_cost": 0.0, "threat_kind": &"boss", "active_cap": false},
}


static func definition(archetype: StringName) -> Dictionary:
	return Dictionary(DEFINITIONS.get(archetype, DEFINITIONS[&"ordinary_pursuer_t1"])).duplicate(true)


static func fires_projectiles(archetype: StringName) -> bool:
	return archetype in PROJECTILE_FIRING_ARCHETYPES


static func is_ordinary(archetype: StringName) -> bool:
	return archetype in ORDINARY_ARCHETYPES


static func projectile_target_radius(archetype: StringName) -> float:
	if archetype == &"boss_actor":
		return BOSS_PROJECTILE_TARGET_RADIUS
	if archetype in INSTALLATION_ARCHETYPES:
		return INSTALLATION_PROJECTILE_TARGET_RADIUS
	return MOVING_PROJECTILE_TARGET_RADIUS


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if ORDINARY_ARCHETYPES.size() != 15:
		errors.append("ordinary catalog must contain exactly fifteen family-tier archetypes")
	var family_tiers := {}
	for archetype in DEFINITIONS:
		var data: Dictionary = DEFINITIONS[archetype]
		if float(data["health"]) <= 0.0 or float(data["radius"]) <= 0.0:
			errors.append("invalid enemy dimensions: %s" % archetype)
		if archetype not in ORDINARY_ARCHETYPES:
			continue
		var family := StringName(data.get("family", &""))
		var tier := int(data.get("tier", 0))
		var size_percent := int(data.get("size_percent", 0))
		family_tiers["%s:%d" % [family, tier]] = true
		if size_percent != [100, 125, 150][tier - 1]:
			errors.append("invalid tier size percent: %s" % archetype)
		if projectile_target_radius(archetype) != MOVING_PROJECTILE_TARGET_RADIUS:
			errors.append("ordinary projectile target radius must remain 48: %s" % archetype)
	for family in [&"pursuer", &"charger", &"emitter", &"defender", &"coordinator"]:
		for tier in range(1, 4):
			if not family_tiers.has("%s:%d" % [family, tier]):
				errors.append("missing family tier: %s t%d" % [family, tier])
	for archetype in PROJECTILE_FIRING_ARCHETYPES:
		if not DEFINITIONS.has(archetype):
			errors.append("unknown projectile-firing archetype: %s" % archetype)
	return errors
