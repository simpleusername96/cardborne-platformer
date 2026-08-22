class_name VehicleBossPhaseCatalog
extends RefCounted

## Boss identity, squad composition, and body-attached defense metadata.
## Stage 3 guard segments and Stage 10 reflection segments share one gap-safe cycle.

const MAX_LIVE_ADDS := 12
const BOSS_ENTRY_SLOT_RESERVE := 1 + MAX_LIVE_ADDS
const PHASE_FLOORS := [0.65, 0.30, 0.0]
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PHASES := {
	&"stage_1": {"variant": &"boss_stage_01", "shield_kind": &"none", "add_roles": {2: [&"ordinary_pursuer_t1", &"ordinary_pursuer_t1", &"ordinary_charger_t1", &"ordinary_pursuer_t1"], 3: [&"ordinary_charger_t1", &"ordinary_pursuer_t1", &"ordinary_charger_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"swarm_screen", 3: &"spearhead"}},
	&"stage_2": {"variant": &"boss_stage_02", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1"], 3: [&"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_3": {"variant": &"boss_stage_03", "shield_kind": &"segmented_guard", "add_roles": {2: [&"ordinary_emitter_t1", &"ordinary_emitter_t1", &"ordinary_defender_t1", &"ordinary_emitter_t1"], 3: [&"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_4": {"variant": &"boss_stage_04", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t1", &"ordinary_pursuer_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"], 3: [&"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_defender_t1", &"ordinary_pursuer_t1"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"shielded_column"}},
	&"stage_5": {"variant": &"boss_stage_05", "shield_kind": &"none", "add_roles": {2: [&"ordinary_charger_t2", &"ordinary_pursuer_t2", &"ordinary_charger_t2", &"ordinary_pursuer_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"]}, "tactic_ids": {2: &"spearhead", 3: &"crossfire_convoy"}},
	&"stage_6": {"variant": &"boss_stage_06", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_7": {"variant": &"boss_stage_07", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t2", &"ordinary_pursuer_t2", &"ordinary_pursuer_t2", &"ordinary_defender_t2"], 3: [&"ordinary_pursuer_t2", &"ordinary_charger_t2", &"ordinary_pursuer_t2", &"ordinary_charger_t2"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"swarm_screen"}},
	&"stage_8": {"variant": &"boss_stage_08", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t2", &"ordinary_defender_t2", &"ordinary_pursuer_t2", &"ordinary_defender_t2"], 3: [&"ordinary_emitter_t2", &"ordinary_emitter_t2", &"ordinary_defender_t2", &"ordinary_emitter_t2"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"crossfire_convoy"}},
	&"stage_9": {"variant": &"boss_stage_09", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t3", &"ordinary_pursuer_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3"], 3: [&"ordinary_pursuer_t3", &"ordinary_charger_t3", &"ordinary_pursuer_t3", &"ordinary_charger_t3"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"spearhead"}},
	&"stage_10": {"variant": &"boss_stage_10", "shield_kind": &"segmented_reflection", "add_roles": {2: [&"ordinary_charger_t3", &"ordinary_defender_t3", &"ordinary_charger_t3", &"ordinary_pursuer_t3"], 3: [&"ordinary_defender_t3", &"ordinary_coordinator_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3"]}, "tactic_ids": {2: &"spearhead", 3: &"shielded_column"}},
	&"stage_11": {"variant": &"boss_stage_11", "shield_kind": &"none", "add_roles": {2: [&"ordinary_emitter_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3"], 3: [&"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3"]}, "tactic_ids": {2: &"crossfire_convoy", 3: &"shielded_column"}},
	&"stage_12": {"variant": &"boss_stage_12", "shield_kind": &"none", "add_roles": {2: [&"ordinary_coordinator_t3", &"ordinary_defender_t3", &"ordinary_pursuer_t3", &"ordinary_defender_t3"], 3: [&"ordinary_emitter_t3", &"ordinary_emitter_t3", &"ordinary_defender_t3", &"ordinary_emitter_t3"]}, "tactic_ids": {2: &"shepherd_pack", 3: &"crossfire_convoy"}},
}

const DEFENSE_PROFILES := {
	&"segmented_guard": {
		"effect": &"guard",
		"segment_count": 3,
		"segment_arc": deg_to_rad(80.0),
		"gap_arc": deg_to_rad(40.0),
		"rotation_speed": deg_to_rad(18.0),
		"active_seconds": 8.0,
		"down_seconds": 2.0,
		"cue_seconds": 0.0,
		"starts_active": true,
		"blocked_damage_multiplier": 0.15,
	},
	&"segmented_reflection": {
		"effect": &"reflect",
		"segment_count": 3,
		"segment_arc": deg_to_rad(70.0),
		"gap_arc": deg_to_rad(50.0),
		"rotation_speed": deg_to_rad(18.0),
		"active_seconds": 5.0,
		"down_seconds": 15.0,
		"cue_seconds": 1.0,
		"starts_active": false,
		"blocked_damage_multiplier": 1.0,
	},
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


static func squad_roles(stage_id: StringName, phase: int) -> Array[StringName]:
	var source_phase := clampi(phase, 1, 3)
	if source_phase == 1:
		source_phase = 2
	var result := add_roles(stage_id, source_phase)
	if phase <= 1 and result.size() > 3:
		result.resize(3)
	return result


static func squad_tactic_id(stage_id: StringName, phase: int) -> StringName:
	return tactic_id(stage_id, 2 if phase <= 1 else phase)

static func variant(stage_id: StringName) -> StringName:
	return StringName(definition(stage_id).get("variant", &""))

static func shield_kind(stage_id: StringName) -> StringName:
	return StringName(definition(stage_id).get("shield_kind", &"none"))

static func uses_shield(stage_id: StringName) -> bool:
	return shield_kind(stage_id) != &"none"


static func defense_profile(stage_id: StringName) -> Dictionary:
	return Dictionary(DEFENSE_PROFILES.get(shield_kind(stage_id), {})).duplicate(true)


static func defense_effect(stage_id: StringName) -> StringName:
	return StringName(defense_profile(stage_id).get("effect", &"none"))

static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for stage_id in CombatStages.STAGE_IDS:
		if definition(stage_id).is_empty():
			errors.append("missing boss phase definition: %s" % stage_id)
			continue
		for phase in [1, 2, 3]:
			var roles := squad_roles(stage_id, phase)
			if roles.is_empty() or roles.size() > MAX_LIVE_ADDS:
				errors.append("%s phase %d squad packet is out of bounds" % [stage_id, phase])
		if uses_shield(stage_id):
			var profile := defense_profile(stage_id)
			var segment_count := int(profile.get("segment_count", 0))
			var segment_arc := float(profile.get("segment_arc", 0.0))
			var gap_arc := float(profile.get("gap_arc", 0.0))
			if (
				segment_count <= 0
				or not is_equal_approx(float(segment_count) * (segment_arc + gap_arc), TAU)
				or float(profile.get("active_seconds", 0.0)) <= 0.0
				or float(profile.get("down_seconds", 0.0)) <= 0.0
			):
				errors.append("%s defense profile does not preserve segmented gaps and a down window" % stage_id)
	return errors
