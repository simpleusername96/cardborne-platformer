class_name VehicleBossExamCatalog
extends RefCounted

## Authored semantic objective contract for the connected five-stage boss run.
## Pattern timing remains in VehicleBossPatterns; this catalog owns what the
## player must manipulate before each boss-health segment can be damaged.

const MODULE_HEALTH_RATIO := 0.09
const VULNERABILITY_SECONDS := 5.0
const MAX_LIVE_ADDS := 12
# Boss entry waits for enough room to keep the boss, its two objective modules,
# and the complete finite add budget addressable without evicting live enemies.
const BOSS_ENTRY_SLOT_RESERVE := 1 + 2 + MAX_LIVE_ADDS
const PHASE_FLOORS := [0.65, 0.30, 0.0]

const EXAMS := {
	&"stage_1":{
		"variant":&"colossus",
		"objective":&"forge_plate",
		"resolution_mode":&"parallel",
		"module_kinds":[&"forge_plate", &"forge_plate"],
		"module_offsets":[Vector2(-150.0, -160.0), Vector2(-150.0, 160.0)],
		"cue_keys":[
			"BOSS_EXAM_FOUNDRY_P1",
			"BOSS_EXAM_FOUNDRY_P2",
			"BOSS_EXAM_FOUNDRY_P3",
		],
		"add_roles":{
			2:[&"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"chaser", &"chaser", &"shooter", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"spearhead", 3:&"swarm_screen"},
	},
	&"stage_2":{
		"variant":&"leviathan",
		"objective":&"segment_lock",
		"resolution_mode":&"sequential",
		"module_kinds":[&"segment_lock", &"segment_lock"],
		"module_offsets":[Vector2(0.0, -190.0), Vector2(0.0, 190.0)],
		"cue_keys":[
			"BOSS_EXAM_LEVIATHAN_P1",
			"BOSS_EXAM_LEVIATHAN_P2",
			"BOSS_EXAM_LEVIATHAN_P3",
		],
		"add_roles":{
			2:[&"controller", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"shield_escort", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"shepherd_pack", 3:&"shielded_column"},
	},
	&"stage_3":{
		"variant":&"titan",
		"objective":&"relay_polarity",
		"resolution_mode":&"polarity",
		"module_kinds":[&"relay_positive", &"relay_negative"],
		"module_offsets":[Vector2(-180.0, -110.0), Vector2(180.0, 110.0)],
		"cue_keys":[
			"BOSS_EXAM_TITAN_P1",
			"BOSS_EXAM_TITAN_P2",
			"BOSS_EXAM_TITAN_P3",
		],
		"add_roles":{
			2:[&"spark_minelet", &"spark_minelet", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"bulkhead_guard", &"spark_minelet", &"spark_minelet", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"fuse_pack", 3:&"bulwark_fuse"},
	},
	&"stage_4":{
		"variant":&"behemoth",
		"objective":&"route_switch",
		"resolution_mode":&"sequential",
		"module_kinds":[&"route_switch", &"armor_car"],
		"module_offsets":[Vector2(-190.0, 0.0), Vector2(190.0, 0.0)],
		"cue_keys":[
			"BOSS_EXAM_BEHEMOTH_P1",
			"BOSS_EXAM_BEHEMOTH_P2",
			"BOSS_EXAM_BEHEMOTH_P3",
		],
		"add_roles":{
			2:[&"repair_tender", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"shooter", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"repair_network", 3:&"crossfire_convoy"},
	},
	&"stage_5":{
		"variant":&"crown",
		"objective":&"lattice_command",
		"resolution_mode":&"sequential",
		"module_kinds":[&"lattice_outer", &"lattice_outer"],
		"module_offsets":[Vector2(0.0, -190.0), Vector2(0.0, 190.0)],
		"cue_keys":[
			"BOSS_EXAM_CROWN_P1",
			"BOSS_EXAM_CROWN_P2",
			"BOSS_EXAM_CROWN_P3",
		],
		"add_roles":{
			2:[&"controller", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"drone_carrier", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"learned_remix", 3:&"learned_remix"},
	},
}


static func exam(stage_id: StringName) -> Dictionary:
	return Dictionary(EXAMS.get(stage_id, {})).duplicate(true)


static func phase_floor(phase: int) -> float:
	return float(PHASE_FLOORS[clampi(phase - 1, 0, PHASE_FLOORS.size() - 1)])


static func cue_key(stage_id: StringName, phase: int) -> String:
	var definition := exam(stage_id)
	var keys := Array(definition.get("cue_keys", []))
	if keys.is_empty():
		return ""
	return String(keys[clampi(phase - 1, 0, keys.size() - 1)])


static func add_roles(stage_id: StringName, phase: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var by_phase := Dictionary(exam(stage_id).get("add_roles", {}))
	for role in Array(by_phase.get(phase, [])):
		result.append(StringName(role))
	return result


static func tactic_id(stage_id: StringName, phase: int) -> StringName:
	return StringName(Dictionary(exam(stage_id).get("tactic_ids", {})).get(phase, &""))


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		var definition := exam(stage_id)
		if definition.is_empty():
			errors.append("missing boss exam: %s" % stage_id)
			continue
		if Array(definition.get("module_kinds", [])).size() != 2:
			errors.append("%s must own exactly two objective modules" % stage_id)
		if Array(definition.get("module_offsets", [])).size() != 2:
			errors.append("%s must own exactly two module offsets" % stage_id)
		if Array(definition.get("cue_keys", [])).size() != 3:
			errors.append("%s must own three semantic phase cues" % stage_id)
		for phase in [2, 3]:
			var roles := add_roles(stage_id, phase)
			if roles.is_empty() or roles.size() > MAX_LIVE_ADDS:
				errors.append("%s phase %d add packet is out of bounds" % [stage_id, phase])
	return errors
