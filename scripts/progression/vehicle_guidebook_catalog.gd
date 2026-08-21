class_name VehicleGuidebookCatalog
extends RefCounted

## Stable Guidebook identity and discovery metadata. Combat statistics are
## projected by VehicleGuidebookStatAdapter from gameplay-owned values.

const StatAdapter = preload(
	"res://scripts/progression/vehicle_guidebook_stat_adapter.gd"
)

const CATEGORIES: Array[StringName] = [&"ship", &"enemies", &"bosses", &"objects"]
const ENEMY_ENTRY_IDS := {
	&"ordinary_pursuer_t1":&"enemy_ordinary_pursuer_t1",
	&"ordinary_pursuer_t2":&"enemy_ordinary_pursuer_t2",
	&"ordinary_pursuer_t3":&"enemy_ordinary_pursuer_t3",
	&"ordinary_charger_t1":&"enemy_ordinary_charger_t1",
	&"ordinary_charger_t2":&"enemy_ordinary_charger_t2",
	&"ordinary_charger_t3":&"enemy_ordinary_charger_t3",
	&"ordinary_emitter_t1":&"enemy_ordinary_emitter_t1",
	&"ordinary_emitter_t2":&"enemy_ordinary_emitter_t2",
	&"ordinary_emitter_t3":&"enemy_ordinary_emitter_t3",
	&"ordinary_defender_t1":&"enemy_ordinary_defender_t1",
	&"ordinary_defender_t2":&"enemy_ordinary_defender_t2",
	&"ordinary_defender_t3":&"enemy_ordinary_defender_t3",
	&"ordinary_coordinator_t1":&"enemy_ordinary_coordinator_t1",
	&"ordinary_coordinator_t2":&"enemy_ordinary_coordinator_t2",
	&"ordinary_coordinator_t3":&"enemy_ordinary_coordinator_t3",
}
const ENTRIES: Array[Dictionary] = [
	{"id":&"enemy_ordinary_pursuer_t1", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_pursuer_t1", "name_key":"ORDINARY_PURSUER_T1"},
	{"id":&"enemy_ordinary_pursuer_t2", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_pursuer_t2", "name_key":"ORDINARY_PURSUER_T2"},
	{"id":&"enemy_ordinary_pursuer_t3", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_pursuer_t3", "name_key":"ORDINARY_PURSUER_T3"},
	{"id":&"enemy_ordinary_charger_t1", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_charger_t1", "name_key":"ORDINARY_CHARGER_T1"},
	{"id":&"enemy_ordinary_charger_t2", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_charger_t2", "name_key":"ORDINARY_CHARGER_T2"},
	{"id":&"enemy_ordinary_charger_t3", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_charger_t3", "name_key":"ORDINARY_CHARGER_T3"},
	{"id":&"enemy_ordinary_emitter_t1", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_emitter_t1", "name_key":"ORDINARY_EMITTER_T1"},
	{"id":&"enemy_ordinary_emitter_t2", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_emitter_t2", "name_key":"ORDINARY_EMITTER_T2"},
	{"id":&"enemy_ordinary_emitter_t3", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_emitter_t3", "name_key":"ORDINARY_EMITTER_T3"},
	{"id":&"enemy_ordinary_defender_t1", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_defender_t1", "name_key":"ORDINARY_DEFENDER_T1"},
	{"id":&"enemy_ordinary_defender_t2", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_defender_t2", "name_key":"ORDINARY_DEFENDER_T2"},
	{"id":&"enemy_ordinary_defender_t3", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_defender_t3", "name_key":"ORDINARY_DEFENDER_T3"},
	{"id":&"enemy_ordinary_coordinator_t1", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_coordinator_t1", "name_key":"ORDINARY_COORDINATOR_T1"},
	{"id":&"enemy_ordinary_coordinator_t2", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_coordinator_t2", "name_key":"ORDINARY_COORDINATOR_T2"},
	{"id":&"enemy_ordinary_coordinator_t3", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_coordinator_t3", "name_key":"ORDINARY_COORDINATOR_T3"},
	{"id":&"object_trait_splitter", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"splitter", "name_key":"TRAIT_SPLITTER", "preview":{"kind":&"enemy", "id":&"ordinary_pursuer_t1"}},
	{"id":&"object_trait_frenzy", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"frenzy", "name_key":"TRAIT_FRENZY", "preview":{"kind":&"enemy", "id":&"ordinary_pursuer_t1"}},
	{"id":&"object_trait_double", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"double", "name_key":"TRAIT_DOUBLE", "preview":{"kind":&"enemy", "id":&"ordinary_charger_t1"}},
	{"id":&"object_trait_self_destruct", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"self_destruct", "name_key":"TRAIT_SELF_DESTRUCT", "preview":{"kind":&"enemy", "id":&"ordinary_charger_t1"}},
	{"id":&"object_trait_artillery", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"artillery", "name_key":"TRAIT_ARTILLERY", "preview":{"kind":&"enemy", "id":&"ordinary_emitter_t1"}},
	{"id":&"object_trait_slow", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"slow", "name_key":"TRAIT_SLOW", "preview":{"kind":&"enemy", "id":&"ordinary_emitter_t1"}},
	{"id":&"object_trait_bulwark", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"bulwark", "name_key":"TRAIT_BULWARK", "preview":{"kind":&"enemy", "id":&"ordinary_defender_t1"}},
	{"id":&"object_trait_reflector", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"reflector", "name_key":"TRAIT_REFLECTOR", "preview":{"kind":&"enemy", "id":&"ordinary_defender_t1"}},
	{"id":&"object_trait_blink", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"blink", "name_key":"TRAIT_BLINK", "preview":{"kind":&"enemy", "id":&"ordinary_coordinator_t1"}},
	{"id":&"object_trait_pack_feed", "category":&"enemies", "entry_kind":&"trait", "family_trait":&"pack_feed", "name_key":"TRAIT_PACK_FEED", "preview":{"kind":&"enemy", "id":&"ordinary_coordinator_t1"}},
	{"id":&"boss_stage_01", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":0, "name_key":"BOSS_STAGE_01", "preview":{"kind":&"boss", "id":&"boss_stage_01"}},
	{"id":&"boss_stage_02", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":1, "name_key":"BOSS_STAGE_02", "preview":{"kind":&"boss", "id":&"boss_stage_02"}},
	{"id":&"boss_stage_03", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":2, "name_key":"BOSS_STAGE_03", "preview":{"kind":&"boss", "id":&"boss_stage_03"}},
	{"id":&"boss_stage_04", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":3, "name_key":"BOSS_STAGE_04", "preview":{"kind":&"boss", "id":&"boss_stage_04"}},
	{"id":&"boss_stage_05", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":4, "name_key":"BOSS_STAGE_05", "preview":{"kind":&"boss", "id":&"boss_stage_05"}},
	{"id":&"boss_stage_06", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":5, "name_key":"BOSS_STAGE_06", "preview":{"kind":&"boss", "id":&"boss_stage_06"}},
	{"id":&"boss_stage_07", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":6, "name_key":"BOSS_STAGE_07", "preview":{"kind":&"boss", "id":&"boss_stage_07"}},
	{"id":&"boss_stage_08", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":7, "name_key":"BOSS_STAGE_08", "preview":{"kind":&"boss", "id":&"boss_stage_08"}},
	{"id":&"boss_stage_09", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":8, "name_key":"BOSS_STAGE_09", "preview":{"kind":&"boss", "id":&"boss_stage_09"}},
	{"id":&"boss_stage_10", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":9, "name_key":"BOSS_STAGE_10", "preview":{"kind":&"boss", "id":&"boss_stage_10"}},
	{"id":&"boss_stage_11", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":10, "name_key":"BOSS_STAGE_11", "preview":{"kind":&"boss", "id":&"boss_stage_11"}},
	{"id":&"boss_stage_12", "category":&"bosses", "entry_kind":&"boss", "boss_stage_index":11, "name_key":"BOSS_STAGE_12", "preview":{"kind":&"boss", "id":&"boss_stage_12"}},
	{"id":&"object_experience", "category":&"objects", "entry_kind":&"object", "object_kind":&"experience", "name_key":"GUIDE_OBJECT_EXPERIENCE_NAME", "preview":{"kind":&"pickup", "id":&"experience"}},
	{"id":&"object_recall", "category":&"objects", "entry_kind":&"object", "object_kind":&"recall", "name_key":"GUIDE_OBJECT_RECALL_NAME", "preview":{"kind":&"pickup", "id":&"experience_recall"}},
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
	if entry.has("preview"):
		return Dictionary(entry["preview"]).duplicate(true)
	if StringName(entry["entry_kind"]) == &"enemy":
		return {"kind":&"enemy", "id":StringName(entry["archetype"])}
	return {}
