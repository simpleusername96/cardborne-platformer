class_name VehicleBossPhaseCatalog
extends RefCounted

## Boss identity metadata. Drydock alone uses a restrained directional defense
## that directly feeds a counterattack instead of stalling combat.

const MAX_LIVE_ADDS := 12
const BOSS_ENTRY_SLOT_RESERVE := 1 + MAX_LIVE_ADDS
const PHASE_FLOORS := [0.65, 0.30, 0.0]
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PHASES := {
	&"stage_1": {"variant": &"colossus", "shield_kind": &"none", "add_roles": {2: [&"chaser", &"scrap_drone", &"scrap_drone"], 3: [&"chaser", &"shooter", &"scrap_drone", &"scrap_drone"]}, "tactic_ids": {2: &"spearhead", 3: &"swarm_screen"}},
	&"stage_2": {"variant": &"leviathan", "shield_kind": &"none", "add_roles": {2: [&"controller", &"chaser", &"scrap_drone"], 3: [&"chaser", &"shield_escort", &"scrap_drone"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"shielded_column"}},
	&"stage_3": {"variant": &"titan", "shield_kind": &"frontal_intercept", "add_roles": {2: [&"spark_minelet", &"chaser", &"scrap_drone"], 3: [&"bulkhead_guard", &"spark_minelet", &"scrap_drone"]}, "tactic_ids": {2: &"fuse_pack", 3: &"bulwark_fuse"}},
	&"stage_4": {"variant": &"behemoth", "shield_kind": &"none", "add_roles": {2: [&"repair_tender", &"chaser", &"scrap_drone"], 3: [&"shooter", &"chaser", &"scrap_drone"]}, "tactic_ids": {2: &"repair_network", 3: &"crossfire_convoy"}},
	&"stage_5": {"variant": &"crown", "shield_kind": &"none", "add_roles": {2: [&"controller", &"chaser", &"scrap_drone"], 3: [&"drone_carrier", &"chaser", &"scrap_drone"]}, "tactic_ids": {2: &"learned_remix", 3: &"learned_remix"}},
	&"stage_6": {"variant": &"battery", "shield_kind": &"none", "add_roles": {2: [&"artillery_spotter", &"chaser", &"scrap_drone"], 3: [&"shooter", &"rammer", &"scrap_drone"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"spearhead"}},
	&"stage_7": {"variant": &"loom", "shield_kind": &"none", "add_roles": {2: [&"controller", &"rammer", &"scrap_drone"], 3: [&"bulkhead_guard", &"chaser", &"scrap_drone"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"bulwark_fuse"}},
	&"stage_8": {"variant": &"pulse_core", "shield_kind": &"none", "add_roles": {2: [&"splitter_barge", &"rammer", &"scrap_drone"], 3: [&"drone_carrier", &"controller", &"scrap_drone"]}, "tactic_ids": {2: &"learned_remix", 3: &"crossfire_convoy"}},
}

static func definition(stage_id: StringName) -> Dictionary:
	return Dictionary(PHASES.get(CombatStages.boss_profile_id(stage_id), {})).duplicate(true)

static func phase_floor(phase: int) -> float:
	return float(PHASE_FLOORS[clampi(phase - 1, 0, PHASE_FLOORS.size() - 1)])

static func add_roles(stage_id: StringName, phase: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for role in Array(Dictionary(definition(stage_id).get("add_roles", {})).get(phase, [])):
		result.append(StringName(role))
	return result

static func tactic_id(stage_id: StringName, phase: int) -> StringName:
	return StringName(Dictionary(definition(stage_id).get("tactic_ids", {})).get(phase, &""))

static func variant(stage_id: StringName) -> StringName:
	return StringName(definition(stage_id).get("variant", &""))

static func shield_kind(stage_id: StringName) -> StringName:
	return StringName(definition(stage_id).get("shield_kind", &"none"))

static func uses_shield(stage_id: StringName) -> bool:
	return shield_kind(stage_id) != &"none"

static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for stage_id in CombatStages.STAGE_IDS:
		if definition(stage_id).is_empty():
			errors.append("missing boss phase definition: %s" % stage_id)
			continue
		for phase in [2, 3]:
			var roles := add_roles(stage_id, phase)
			if roles.is_empty() or roles.size() > MAX_LIVE_ADDS:
				errors.append("%s phase %d add packet is out of bounds" % [stage_id, phase])
	return errors
