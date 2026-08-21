class_name VehicleBossPhaseCatalog
extends RefCounted

## Boss identity metadata. Stage 3 alone uses a restrained directional defense
## that directly feeds a counterattack instead of stalling combat.

const MAX_LIVE_ADDS := 12
const BOSS_ENTRY_SLOT_RESERVE := 1 + MAX_LIVE_ADDS
const PHASE_FLOORS := [0.65, 0.30, 0.0]
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PHASES := {
	&"stage_1": {"variant": &"boss_stage_01", "shield_kind": &"none", "add_roles": {2: [&"ordinary_pursuer_t1", &"ordinary_pursuer_t1", &"ordinary_charger_t1", &"ordinary_pursuer_t1"], 3: [&"ordinary_charger_t1", &"ordinary_pursuer_t1", &"ordinary_charger_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"swarm_screen", 3: &"spearhead"}},
	&"stage_2": {"variant": &"boss_stage_02", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1"], 3: [&"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_3": {"variant": &"boss_stage_03", "shield_kind": &"frontal_intercept", "add_roles": {2: [&"ordinary_emitter_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1"], 3: [&"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_4": {"variant": &"boss_stage_04", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t1", &"ordinary_pursuer_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"], 3: [&"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"shielded_column"}},
	&"stage_5": {"variant": &"boss_stage_05", "shield_kind": &"none", "add_roles": {2: [&"ordinary_charger_t2", &"ordinary_pursuer_t2", &"ordinary_charger_t2", &"ordinary_pursuer_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"]}, "tactic_ids": {2: &"spearhead", 3: &"crossfire_convoy"}},
	&"stage_6": {"variant": &"boss_stage_06", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_7": {"variant": &"boss_stage_07", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t2", &"ordinary_pursuer_t2", &"ordinary_pursuer_t2", &"ordinary_defender_t2"], 3: [&"ordinary_pursuer_t2", &"ordinary_charger_t2", &"ordinary_pursuer_t2", &"ordinary_charger_t2"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"swarm_screen"}},
	&"stage_8": {"variant": &"boss_stage_08", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t2", &"ordinary_defender_t2", &"ordinary_pursuer_t2", &"ordinary_defender_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"crossfire_convoy"}},
	&"stage_9": {"variant": &"boss_stage_09", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t3", &"ordinary_pursuer_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3"], 3: [&"ordinary_pursuer_t3", &"ordinary_charger_t3", &"ordinary_pursuer_t3", &"ordinary_charger_t3"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"spearhead"}},
	&"stage_10": {"variant": &"boss_stage_10", "shield_kind": &"none", "add_roles": {2: [&"ordinary_charger_t3", &"ordinary_defender_t3", &"ordinary_charger_t3", &"ordinary_pursuer_t3"], 3: [&"ordinary_defender_t3", &"ordinary_coordinator_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3"]}, "tactic_ids": {2: &"spearhead", 3: &"shielded_column"}},
	&"stage_11": {"variant": &"boss_stage_11", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3"], 3: [&"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_12": {"variant": &"boss_stage_12", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3", &"ordinary_defender_t3"], 3: [&"ordinary_emitter_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"crossfire_convoy"}},
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
