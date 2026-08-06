class_name VehicleGuidebookCatalog
extends RefCounted

## Stable guide metadata. Locked snapshots never include hidden copy.

const CATEGORIES: Array[StringName] = [&"ship", &"mobile", &"bosses", &"objects"]
const ENTRIES: Array[Dictionary] = [
	{"id":&"mobile_scrap_drone", "category":&"mobile", "name_key":"ENEMY_SCRAP_DRONE", "description_key":"GUIDE_MOBILE_SWARM_DESC", "preview":{"kind":&"enemy", "id":&"scrap_drone"}},
	{"id":&"mobile_needle_drone", "category":&"mobile", "name_key":"ENEMY_NEEDLE_DRONE", "description_key":"GUIDE_MOBILE_RANGED_DESC", "preview":{"kind":&"enemy", "id":&"needle_drone"}},
	{"id":&"mobile_spark_minelet", "category":&"mobile", "name_key":"ENEMY_SPARK_MINELET", "description_key":"GUIDE_MOBILE_MINELET_DESC", "counter_key":"TACTIC_COUNTER_FUSE_PACK", "preview":{"kind":&"enemy", "id":&"spark_minelet"}},
	{"id":&"mobile_chaser", "category":&"mobile", "name_key":"ENEMY_RIVET_CHASER", "description_key":"GUIDE_MOBILE_CHASER_DESC", "counter_key":"TACTIC_COUNTER_SPEARHEAD"},
	{"id":&"mobile_shooter", "category":&"mobile", "name_key":"ENEMY_LANE_SKIRMISHER", "description_key":"GUIDE_MOBILE_RANGED_DESC", "counter_key":"TACTIC_COUNTER_CROSSFIRE"},
	{"id":&"mobile_controller", "category":&"mobile", "name_key":"ENEMY_FLOOD_CONTROLLER", "description_key":"GUIDE_MOBILE_CONTROLLER_DESC", "counter_key":"TACTIC_COUNTER_SHEPHERD"},
	{"id":&"mobile_shield_escort", "category":&"mobile", "name_key":"ENEMY_SHIELD_ESCORT", "description_key":"GUIDE_MOBILE_SUPPORT_DESC"},
	{"id":&"mobile_artillery_spotter", "category":&"mobile", "name_key":"ENEMY_ARTILLERY_SPOTTER", "description_key":"GUIDE_MOBILE_ARTILLERY_DESC"},
	{"id":&"mobile_rammer", "category":&"mobile", "name_key":"ENEMY_RAMMER", "description_key":"GUIDE_MOBILE_RAMMER_DESC"},
	{"id":&"mobile_repair_tender", "category":&"mobile", "name_key":"ENEMY_REPAIR_TENDER", "description_key":"GUIDE_MOBILE_SUPPORT_DESC", "counter_key":"TACTIC_COUNTER_REPAIR_NETWORK"},
	{"id":&"mobile_drone_carrier", "category":&"mobile", "name_key":"ENEMY_DRONE_CARRIER", "description_key":"GUIDE_MOBILE_CARRIER_DESC"},
	{"id":&"mobile_bulkhead_guard", "category":&"mobile", "name_key":"ENEMY_BULKHEAD_GUARD", "description_key":"GUIDE_MOBILE_GUARD_DESC", "preview":{"kind":&"enemy", "id":&"bulkhead_guard"}},
	{"id":&"mobile_splitter_barge", "category":&"mobile", "name_key":"ENEMY_SPLITTER_BARGE", "description_key":"GUIDE_MOBILE_SPLITTER_DESC", "preview":{"kind":&"enemy", "id":&"splitter_barge"}},
	{"id":&"boss_stage_1", "category":&"bosses", "name_key":"ENEMY_FOUNDRY_COLOSSUS", "description_key":"GUIDE_BOSS_1_DESC", "counter_key":"BOSS_EXAM_FOUNDRY_P1", "preview":{"kind":&"boss", "id":&"colossus"}},
	{"id":&"boss_stage_2", "category":&"bosses", "name_key":"ENEMY_ARCHIVE_LEVIATHAN", "description_key":"GUIDE_BOSS_2_DESC", "counter_key":"BOSS_EXAM_LEVIATHAN_P1", "preview":{"kind":&"boss", "id":&"leviathan"}},
	{"id":&"boss_stage_3", "category":&"bosses", "name_key":"ENEMY_DRYDOCK_TITAN", "description_key":"GUIDE_BOSS_3_DESC", "counter_key":"BOSS_EXAM_TITAN_P1", "preview":{"kind":&"boss", "id":&"titan"}},
	{"id":&"boss_stage_4", "category":&"bosses", "name_key":"ENEMY_SWITCHYARD_BEHEMOTH", "description_key":"GUIDE_BOSS_4_DESC", "counter_key":"BOSS_EXAM_BEHEMOTH_P1", "preview":{"kind":&"boss", "id":&"behemoth"}},
	{"id":&"boss_stage_5", "category":&"bosses", "name_key":"ENEMY_CROWN_ENGINE", "description_key":"GUIDE_BOSS_5_DESC", "counter_key":"BOSS_EXAM_CROWN_P1", "preview":{"kind":&"boss", "id":&"crown"}},
	{"id":&"object_experience", "category":&"objects", "name_key":"GUIDE_OBJECT_EXPERIENCE_NAME", "description_key":"GUIDE_OBJECT_EXPERIENCE_DESC", "preview":{"kind":&"pickup", "id":&"experience"}},
	{"id":&"object_repair", "category":&"objects", "name_key":"GUIDE_OBJECT_REPAIR_NAME", "description_key":"GUIDE_OBJECT_REPAIR_DESC", "preview":{"kind":&"pickup", "id":&"repair"}},
	{"id":&"object_recall", "category":&"objects", "name_key":"GUIDE_OBJECT_RECALL_NAME", "description_key":"GUIDE_OBJECT_RECALL_DESC"},
	{"id":&"object_crate", "category":&"objects", "name_key":"GUIDE_OBJECT_CRATE_NAME", "description_key":"GUIDE_OBJECT_CRATE_DESC"},
	{"id":&"object_hazard_zone", "category":&"objects", "name_key":"GUIDE_TERRAIN_HAZARD_NAME", "description_key":"GUIDE_TERRAIN_HAZARD_DESC"},
	{"id":&"object_mystery_device", "category":&"objects", "name_key":"GUIDE_OBJECT_MYSTERY_DEVICE_NAME", "description_key":"GUIDE_OBJECT_MYSTERY_DEVICE_DESC"},
	{"id":&"object_transit_gate", "category":&"objects", "name_key":"GUIDE_FACILITY_GATE_NAME", "description_key":"GUIDE_FACILITY_GATE_DESC", "preview":{"kind":&"facility", "id":&"transit_gate"}},
	{"id":&"object_elite_armored", "category":&"objects", "name_key":"ELITE_ARMORED", "description_key":"GUIDE_ELITE_ARMORED_DESC", "preview":{"kind":&"elite", "id":&"armored"}},
	{"id":&"object_elite_overclocked", "category":&"objects", "name_key":"ELITE_OVERCLOCKED", "description_key":"GUIDE_ELITE_OVERCLOCKED_DESC", "preview":{"kind":&"elite", "id":&"overclocked"}},
	{"id":&"object_elite_heavy", "category":&"objects", "name_key":"ELITE_HEAVY", "description_key":"GUIDE_ELITE_HEAVY_DESC", "preview":{"kind":&"elite", "id":&"heavy"}},
]


static func valid_ids() -> Dictionary:
	var result := {}
	for entry in ENTRIES:
		result[StringName(entry["id"])] = true
	return result


static func entry_id_for_enemy(archetype: StringName, behavior: StringName) -> StringName:
	var stationary_archetypes: Array[StringName] = [
		&"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"generator", &"boss_pylon",
	]
	if archetype in stationary_archetypes:
		return &""
	return StringName("mobile_%s" % String(archetype))


static func snapshot(known: Dictionary, ship: Dictionary) -> Dictionary:
	var categories := {}
	for category in CATEGORIES:
		categories[category] = []
	categories[&"ship"] = [{"id":&"current_ship", "locked":false, "name_key":"GUIDE_CURRENT_SHIP", "description":"", "ship":ship.duplicate(true)}]
	for entry in ENTRIES:
		var entry_id := StringName(entry["id"])
		if known.has(entry_id):
			categories[StringName(entry["category"])].append({
				"id":entry_id, "locked":false, "name_key":String(entry["name_key"]),
				"description_key":String(entry["description_key"]),
				"preview":_preview_for(entry),
				"movement_key":_row_key(entry, "movement"),
				"attack_key":_row_key(entry, "attack"),
				"counter_key":_row_key(entry, "counter"),
			})
		else:
			categories[StringName(entry["category"])].append({"id":entry_id, "locked":true, "name":"???", "description":""})
	return {"categories":categories, "category_order":CATEGORIES.duplicate()}


static func _preview_for(entry: Dictionary) -> Dictionary:
	var explicit := Dictionary(entry.get("preview", {}))
	if not explicit.is_empty():
		return explicit.duplicate(true)
	var category := StringName(entry["category"])
	var entry_id := String(entry["id"])
	if category == &"mobile":
		return {
			"kind":&"enemy",
			"id":StringName(entry_id.trim_prefix("mobile_")),
		}
	if entry_id == "object_recall":
		return {"kind":&"pickup", "id":&"experience_recall"}
	if entry_id == "object_crate":
		return {"kind":&"pickup", "id":&"reward_crate"}
	return {}


static func _row_key(entry: Dictionary, row: String) -> String:
	var explicit_key := String(entry.get("%s_key" % row, ""))
	if not explicit_key.is_empty():
		return explicit_key
	var preview := _preview_for(entry)
	if StringName(entry["category"]) == &"objects" and StringName(preview.get("kind", &"")) != &"elite":
		return {
			"movement":"GUIDE_ROW_OBJECT_MOVEMENT",
			"attack":"GUIDE_ROW_OBJECT_EFFECT",
			"counter":"GUIDE_ROW_OBJECT_COUNTER",
		}[row]
	return {
		"movement":"GUIDE_ROW_MOVEMENT_DEFAULT",
		"attack":"GUIDE_ROW_ATTACK_DEFAULT",
		"counter":"GUIDE_ROW_COUNTER_DEFAULT",
	}[row]
