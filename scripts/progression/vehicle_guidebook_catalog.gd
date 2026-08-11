class_name VehicleGuidebookCatalog
extends RefCounted

## Stable Guidebook identity and discovery metadata. Combat statistics are
## projected by VehicleGuidebookStatAdapter from gameplay-owned values.

const StatAdapter = preload(
	"res://scripts/progression/vehicle_guidebook_stat_adapter.gd"
)

const CATEGORIES: Array[StringName] = [&"ship", &"enemies", &"bosses", &"objects"]
const ENEMY_ENTRY_IDS := {
	&"scrap_drone":&"mobile_scrap_drone",
	&"needle_drone":&"mobile_needle_drone",
	&"spark_minelet":&"mobile_spark_minelet",
	&"chaser":&"mobile_chaser",
	&"shooter":&"mobile_shooter",
	&"controller":&"mobile_controller",
	&"shield_escort":&"mobile_shield_escort",
	&"artillery_spotter":&"mobile_artillery_spotter",
	&"rammer":&"mobile_rammer",
	&"repair_tender":&"mobile_repair_tender",
	&"drone_carrier":&"mobile_drone_carrier",
	&"bulkhead_guard":&"mobile_bulkhead_guard",
	&"splitter_barge":&"mobile_splitter_barge",
	&"turret":&"mobile_turret",
	&"mine":&"mobile_mine",
	&"interceptor_tower":&"mobile_interceptor_tower",
	&"beam_sentinel":&"mobile_beam_sentinel",
	&"generator":&"mobile_generator",
}
const ENTRIES: Array[Dictionary] = [
	{"id":&"mobile_scrap_drone", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"scrap_drone", "name_key":"ENEMY_SCRAP_DRONE"},
	{"id":&"mobile_needle_drone", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"needle_drone", "name_key":"ENEMY_NEEDLE_DRONE"},
	{"id":&"mobile_spark_minelet", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"spark_minelet", "name_key":"ENEMY_SPARK_MINELET"},
	{"id":&"mobile_chaser", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"chaser", "name_key":"ENEMY_RIVET_CHASER"},
	{"id":&"mobile_shooter", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"shooter", "name_key":"ENEMY_LANE_SKIRMISHER"},
	{"id":&"mobile_controller", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"controller", "name_key":"ENEMY_FLOOD_CONTROLLER"},
	{"id":&"mobile_shield_escort", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"shield_escort", "name_key":"ENEMY_SHIELD_ESCORT"},
	{"id":&"mobile_artillery_spotter", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"artillery_spotter", "name_key":"ENEMY_ARTILLERY_SPOTTER"},
	{"id":&"mobile_rammer", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"rammer", "name_key":"ENEMY_RAMMER"},
	{"id":&"mobile_repair_tender", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"repair_tender", "name_key":"ENEMY_REPAIR_TENDER"},
	{"id":&"mobile_drone_carrier", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"drone_carrier", "name_key":"ENEMY_DRONE_CARRIER"},
	{"id":&"mobile_bulkhead_guard", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"bulkhead_guard", "name_key":"ENEMY_BULKHEAD_GUARD"},
	{"id":&"mobile_splitter_barge", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"splitter_barge", "name_key":"ENEMY_SPLITTER_BARGE"},
	{"id":&"mobile_turret", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"turret", "name_key":"ENEMY_FOUNDRY_TURRET"},
	{"id":&"mobile_mine", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"mine", "name_key":"ENEMY_ARC_MINE"},
	{"id":&"mobile_interceptor_tower", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"interceptor_tower", "name_key":"ENEMY_INTERCEPTOR_TOWER"},
	{"id":&"mobile_beam_sentinel", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"beam_sentinel", "name_key":"ENEMY_BEAM_SENTINEL"},
	{"id":&"mobile_generator", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"generator", "name_key":"ENEMY_BARRIER_GENERATOR"},
	{"id":&"object_elite_armored", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"armored", "name_key":"ELITE_ARMORED", "preview":{"kind":&"elite", "id":&"armored"}},
	{"id":&"object_elite_overclocked", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"overclocked", "name_key":"ELITE_OVERCLOCKED", "preview":{"kind":&"elite", "id":&"overclocked"}},
	{"id":&"object_elite_heavy", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"heavy", "name_key":"ELITE_HEAVY", "preview":{"kind":&"elite", "id":&"heavy"}},
	{"id":&"boss_stage_1", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":0, "name_key":"ENEMY_FOUNDRY_COLOSSUS", "preview":{"kind":&"boss", "id":&"colossus"}},
	{"id":&"boss_stage_2", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":1, "name_key":"ENEMY_ARCHIVE_LEVIATHAN", "preview":{"kind":&"boss", "id":&"leviathan"}},
	{"id":&"boss_stage_3", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":2, "name_key":"ENEMY_DRYDOCK_TITAN", "preview":{"kind":&"boss", "id":&"titan"}},
	{"id":&"boss_stage_4", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":3, "name_key":"ENEMY_SWITCHYARD_BEHEMOTH", "preview":{"kind":&"boss", "id":&"behemoth"}},
	{"id":&"boss_stage_5", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":4, "name_key":"ENEMY_CROWN_ENGINE", "preview":{"kind":&"boss", "id":&"crown"}},
	{"id":&"object_experience", "category":&"objects", "entry_kind":&"object", "object_kind":&"experience", "name_key":"GUIDE_OBJECT_EXPERIENCE_NAME", "preview":{"kind":&"pickup", "id":&"experience"}},
	{"id":&"object_repair", "category":&"objects", "entry_kind":&"object", "object_kind":&"repair", "name_key":"GUIDE_OBJECT_REPAIR_NAME", "preview":{"kind":&"pickup", "id":&"repair"}},
	{"id":&"object_recall", "category":&"objects", "entry_kind":&"object", "object_kind":&"recall", "name_key":"GUIDE_OBJECT_RECALL_NAME", "preview":{"kind":&"pickup", "id":&"experience_recall"}},
	{"id":&"object_crate", "category":&"objects", "entry_kind":&"object", "object_kind":&"crate", "name_key":"GUIDE_OBJECT_CRATE_NAME", "preview":{"kind":&"pickup", "id":&"reward_crate"}},
	{"id":&"object_mystery_device", "category":&"objects", "entry_kind":&"object", "object_kind":&"mystery_device", "name_key":"GUIDE_OBJECT_MYSTERY_DEVICE_NAME", "preview":{"kind":&"mystery_device"}},
	{"id":&"object_transit_gate", "category":&"objects", "entry_kind":&"object", "object_kind":&"transit_gate", "name_key":"GUIDE_FACILITY_GATE_NAME", "preview":{"kind":&"facility", "id":&"transit_gate"}},
]


static func valid_ids() -> Dictionary:
	var result := {}
	for entry in ENTRIES:
		result[StringName(entry["id"])] = true
	return result


static func entry_id_for_enemy(
	archetype: StringName,
	_behavior: StringName
) -> StringName:
	return StringName(ENEMY_ENTRY_IDS.get(archetype, &""))


static func snapshot(
	known: Dictionary,
	ship: Dictionary,
	context: Dictionary = {}
) -> Dictionary:
	var categories := {}
	var locked_counts := {}
	for category in CATEGORIES:
		categories[category] = []
		locked_counts[category] = 0
	categories[&"ship"] = [{
		"id":&"current_ship",
		"locked":false,
		"name_key":"GUIDE_CURRENT_SHIP",
		"ship":ship.duplicate(true),
	}]
	for entry in ENTRIES:
		var entry_id := StringName(entry["id"])
		var category := StringName(entry["category"])
		if not known.has(entry_id):
			locked_counts[category] = int(locked_counts[category]) + 1
			continue
		categories[category].append({
			"id":entry_id,
			"locked":false,
			"name_key":String(entry["name_key"]),
			"preview":_preview_for(entry),
			"stat_rows":StatAdapter.rows_for(entry, context),
		})
	for category in CATEGORIES:
		if category == &"ship" or int(locked_counts[category]) <= 0:
			continue
		categories[category].append({
			"id":StringName("locked_summary_%s" % String(category)),
			"locked_summary":true,
			"locked_count":int(locked_counts[category]),
		})
	return {
		"categories":categories,
		"category_order":CATEGORIES.duplicate(),
		"stage_context":context.duplicate(),
	}


static func _preview_for(entry: Dictionary) -> Dictionary:
	var explicit := Dictionary(entry.get("preview", {}))
	if not explicit.is_empty():
		return explicit.duplicate(true)
	if StringName(entry["entry_kind"]) == &"enemy":
		return {"kind":&"enemy", "id":StringName(entry["archetype"])}
	return {}
