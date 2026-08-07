class_name VehicleBossPhaseCatalog
extends RefCounted

## Owns five-stage boss identity, health floors, and bounded phase add packets.
## Shield timing and damage response belong to VehicleBossShieldRuntime.

const MAX_LIVE_ADDS := 12
const BOSS_ENTRY_SLOT_RESERVE := 1 + MAX_LIVE_ADDS
const PHASE_FLOORS := [0.65, 0.30, 0.0]

const PHASES := {
	&"stage_1":{
		"variant":&"colossus",
		"add_roles":{
			2:[&"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"chaser", &"chaser", &"shooter", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"spearhead", 3:&"swarm_screen"},
	},
	&"stage_2":{
		"variant":&"leviathan",
		"add_roles":{
			2:[&"controller", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"shield_escort", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"shepherd_pack", 3:&"shielded_column"},
	},
	&"stage_3":{
		"variant":&"titan",
		"add_roles":{
			2:[&"spark_minelet", &"spark_minelet", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"bulkhead_guard", &"spark_minelet", &"spark_minelet", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"fuse_pack", 3:&"bulwark_fuse"},
	},
	&"stage_4":{
		"variant":&"behemoth",
		"add_roles":{
			2:[&"repair_tender", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"shooter", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"repair_network", 3:&"crossfire_convoy"},
	},
	&"stage_5":{
		"variant":&"crown",
		"add_roles":{
			2:[&"controller", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
			3:[&"drone_carrier", &"chaser", &"chaser", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone", &"scrap_drone"],
		},
		"tactic_ids":{2:&"learned_remix", 3:&"learned_remix"},
	},
}


static func definition(stage_id: StringName) -> Dictionary:
	return Dictionary(PHASES.get(stage_id, {})).duplicate(true)


static func phase_floor(phase: int) -> float:
	return float(PHASE_FLOORS[clampi(phase - 1, 0, PHASE_FLOORS.size() - 1)])


static func add_roles(stage_id: StringName, phase: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var by_phase := Dictionary(definition(stage_id).get("add_roles", {}))
	for role in Array(by_phase.get(phase, [])):
		result.append(StringName(role))
	return result


static func tactic_id(stage_id: StringName, phase: int) -> StringName:
	return StringName(Dictionary(definition(stage_id).get("tactic_ids", {})).get(phase, &""))


static func variant(stage_id: StringName) -> StringName:
	return StringName(definition(stage_id).get("variant", &"colossus"))


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		if definition(stage_id).is_empty():
			errors.append("missing boss phase definition: %s" % stage_id)
			continue
		for phase in [2, 3]:
			var roles := add_roles(stage_id, phase)
			if roles.is_empty() or roles.size() > MAX_LIVE_ADDS:
				errors.append("%s phase %d add packet is out of bounds" % [stage_id, phase])
	return errors
