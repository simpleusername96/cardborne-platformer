class_name VehicleGuidebookCatalog
extends RefCounted

## Stable guide metadata. Locked snapshots never include hidden copy.

const CATEGORIES: Array[StringName] = [&"ship", &"mobile", &"stationary", &"bosses", &"objects"]
const ENTRIES: Array[Dictionary] = [
	{"id":&"mobile_scrap_drone", "category":&"mobile", "name_key":"ENEMY_SCRAP_DRONE", "description_key":"GUIDE_MOBILE_SWARM_DESC"},
	{"id":&"mobile_needle_drone", "category":&"mobile", "name_key":"ENEMY_NEEDLE_DRONE", "description_key":"GUIDE_MOBILE_RANGED_DESC"},
	{"id":&"mobile_spark_minelet", "category":&"mobile", "name_key":"ENEMY_SPARK_MINELET", "description_key":"GUIDE_MOBILE_MINELET_DESC"},
	{"id":&"mobile_chaser", "category":&"mobile", "name_key":"ENEMY_RIVET_CHASER", "description_key":"GUIDE_MOBILE_CHASER_DESC"},
	{"id":&"mobile_shooter", "category":&"mobile", "name_key":"ENEMY_LANE_SKIRMISHER", "description_key":"GUIDE_MOBILE_RANGED_DESC"},
	{"id":&"mobile_controller", "category":&"mobile", "name_key":"ENEMY_FLOOD_CONTROLLER", "description_key":"GUIDE_MOBILE_CONTROLLER_DESC"},
	{"id":&"mobile_shield_escort", "category":&"mobile", "name_key":"ENEMY_SHIELD_ESCORT", "description_key":"GUIDE_MOBILE_SUPPORT_DESC"},
	{"id":&"mobile_artillery_spotter", "category":&"mobile", "name_key":"ENEMY_ARTILLERY_SPOTTER", "description_key":"GUIDE_MOBILE_ARTILLERY_DESC"},
	{"id":&"mobile_rammer", "category":&"mobile", "name_key":"ENEMY_RAMMER", "description_key":"GUIDE_MOBILE_RAMMER_DESC"},
	{"id":&"mobile_repair_tender", "category":&"mobile", "name_key":"ENEMY_REPAIR_TENDER", "description_key":"GUIDE_MOBILE_SUPPORT_DESC"},
	{"id":&"mobile_drone_carrier", "category":&"mobile", "name_key":"ENEMY_DRONE_CARRIER", "description_key":"GUIDE_MOBILE_CARRIER_DESC"},
	{"id":&"stationary_turret", "category":&"stationary", "name_key":"ENEMY_FOUNDRY_TURRET", "description_key":"GUIDE_STATIONARY_TURRET_DESC"},
	{"id":&"stationary_mine", "category":&"stationary", "name_key":"ENEMY_ARC_MINE", "description_key":"GUIDE_STATIONARY_MINE_DESC"},
	{"id":&"stationary_interceptor_tower", "category":&"stationary", "name_key":"ENEMY_INTERCEPTOR_TOWER", "description_key":"GUIDE_STATIONARY_INTERCEPTOR_DESC"},
	{"id":&"stationary_beam_sentinel", "category":&"stationary", "name_key":"ENEMY_BEAM_SENTINEL", "description_key":"GUIDE_STATIONARY_BEAM_DESC"},
	{"id":&"stationary_generator", "category":&"stationary", "name_key":"ENEMY_BARRIER_GENERATOR", "description_key":"GUIDE_STATIONARY_GENERATOR_DESC"},
	{"id":&"stationary_boss_pylon", "category":&"stationary", "name_key":"ENEMY_COLOSSUS_PYLON", "description_key":"GUIDE_STATIONARY_PYLON_DESC"},
	{"id":&"boss_stage_1", "category":&"bosses", "name_key":"ENEMY_FOUNDRY_COLOSSUS", "description_key":"GUIDE_BOSS_1_DESC"},
	{"id":&"boss_stage_2", "category":&"bosses", "name_key":"ENEMY_ARCHIVE_LEVIATHAN", "description_key":"GUIDE_BOSS_2_DESC"},
	{"id":&"boss_stage_3", "category":&"bosses", "name_key":"ENEMY_DRYDOCK_TITAN", "description_key":"GUIDE_BOSS_3_DESC"},
	{"id":&"boss_stage_4", "category":&"bosses", "name_key":"ENEMY_SWITCHYARD_BEHEMOTH", "description_key":"GUIDE_BOSS_4_DESC"},
	{"id":&"boss_stage_5", "category":&"bosses", "name_key":"ENEMY_CROWN_ENGINE", "description_key":"GUIDE_BOSS_5_DESC"},
	{"id":&"object_experience", "category":&"objects", "name_key":"GUIDE_OBJECT_EXPERIENCE_NAME", "description_key":"GUIDE_OBJECT_EXPERIENCE_DESC"},
	{"id":&"object_repair", "category":&"objects", "name_key":"GUIDE_OBJECT_REPAIR_NAME", "description_key":"GUIDE_OBJECT_REPAIR_DESC"},
	{"id":&"object_recall", "category":&"objects", "name_key":"GUIDE_OBJECT_RECALL_NAME", "description_key":"GUIDE_OBJECT_RECALL_DESC"},
	{"id":&"object_crate", "category":&"objects", "name_key":"GUIDE_OBJECT_CRATE_NAME", "description_key":"GUIDE_OBJECT_CRATE_DESC"},
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
	var stationary := archetype in stationary_archetypes
	return StringName("%s_%s" % ["stationary" if stationary else "mobile", String(behavior if stationary else archetype)])


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
			})
		else:
			categories[StringName(entry["category"])].append({"id":entry_id, "locked":true, "name":"???", "description":""})
	return {"categories":categories, "category_order":CATEGORIES.duplicate()}
