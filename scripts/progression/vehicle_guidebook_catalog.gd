class_name VehicleGuidebookCatalog
extends RefCounted

## Stable Guidebook identity and discovery metadata. Combat statistics are
## projected by VehicleGuidebookStatAdapter from gameplay-owned values.

const StatAdapter = preload(
	"res://scripts/progression/vehicle_guidebook_stat_adapter.gd"
)

const CATEGORIES: Array[StringName] = [&"ship", &"enemies", &"bosses", &"objects"]
const ENEMY_ENTRY_IDS := {
	&"ordinary_melee_01":&"enemy_ordinary_melee_01", &"ordinary_ranged_01":&"enemy_ordinary_ranged_01",
	&"ordinary_area_01":&"enemy_ordinary_area_01", &"ordinary_edge_01":&"enemy_ordinary_edge_01",
	&"ordinary_lane_01":&"enemy_ordinary_lane_01", &"ordinary_gap_01":&"enemy_ordinary_gap_01",
	&"ordinary_support_02":&"enemy_ordinary_support_02", &"ordinary_growth_01":&"enemy_ordinary_growth_01",
	&"ordinary_pull_01":&"enemy_ordinary_pull_01", &"ordinary_support_01":&"enemy_ordinary_support_01",
	&"ordinary_support_03":&"enemy_ordinary_support_03", &"ordinary_shield_01":&"enemy_ordinary_shield_01",
	&"ordinary_pulse_01":&"enemy_ordinary_pulse_01", &"ordinary_fixed_ranged_01":&"enemy_ordinary_fixed_ranged_01",
	&"ordinary_fixed_area_01":&"enemy_ordinary_fixed_area_01", &"ordinary_fixed_ranged_02":&"enemy_ordinary_fixed_ranged_02",
	&"ordinary_fixed_beam_01":&"enemy_ordinary_fixed_beam_01", &"ordinary_fixed_support_01":&"enemy_ordinary_fixed_support_01",
	&"ordinary_beam_01":&"enemy_ordinary_beam_01", &"ordinary_range_01":&"enemy_ordinary_range_01",
	&"ordinary_sweep_01":&"enemy_ordinary_sweep_01", &"ordinary_melee_02":&"enemy_ordinary_melee_02",
}
const ENTRIES: Array[Dictionary] = [
	{"id":&"enemy_ordinary_melee_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_melee_01", "name_key":"ORDINARY_MELEE_01"},
	{"id":&"enemy_ordinary_ranged_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_ranged_01", "name_key":"ORDINARY_RANGED_01"},
	{"id":&"enemy_ordinary_area_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_area_01", "name_key":"ORDINARY_AREA_01"},
	{"id":&"enemy_ordinary_edge_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_edge_01", "name_key":"ORDINARY_EDGE_01"},
	{"id":&"enemy_ordinary_lane_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_lane_01", "name_key":"ORDINARY_LANE_01"},
	{"id":&"enemy_ordinary_gap_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_gap_01", "name_key":"ORDINARY_GAP_01"},
	{"id":&"enemy_ordinary_support_02", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_support_02", "name_key":"ORDINARY_SUPPORT_02"},
	{"id":&"enemy_ordinary_growth_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_growth_01", "name_key":"ORDINARY_GROWTH_01"},
	{"id":&"enemy_ordinary_pull_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_pull_01", "name_key":"ORDINARY_PULL_01"},
	{"id":&"enemy_ordinary_support_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_support_01", "name_key":"ORDINARY_SUPPORT_01"},
	{"id":&"enemy_ordinary_support_03", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_support_03", "name_key":"ORDINARY_SUPPORT_03"},
	{"id":&"enemy_ordinary_shield_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_shield_01", "name_key":"ORDINARY_SHIELD_01"},
	{"id":&"enemy_ordinary_pulse_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_pulse_01", "name_key":"ORDINARY_PULSE_01"},
	{"id":&"enemy_ordinary_fixed_ranged_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_fixed_ranged_01", "name_key":"ORDINARY_FIXED_RANGED_01"},
	{"id":&"enemy_ordinary_fixed_area_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_fixed_area_01", "name_key":"ORDINARY_FIXED_AREA_01"},
	{"id":&"enemy_ordinary_fixed_ranged_02", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_fixed_ranged_02", "name_key":"ORDINARY_FIXED_RANGED_02"},
	{"id":&"enemy_ordinary_fixed_beam_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_fixed_beam_01", "name_key":"ORDINARY_FIXED_BEAM_01"},
	{"id":&"enemy_ordinary_fixed_support_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_fixed_support_01", "name_key":"ORDINARY_FIXED_SUPPORT_01"},
	{"id":&"enemy_ordinary_beam_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_beam_01", "name_key":"ORDINARY_BEAM_01"},
	{"id":&"enemy_ordinary_range_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_range_01", "name_key":"ORDINARY_RANGE_01"},
	{"id":&"enemy_ordinary_sweep_01", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_sweep_01", "name_key":"ORDINARY_SWEEP_01"},
	{"id":&"enemy_ordinary_melee_02", "category":&"enemies", "entry_kind":&"enemy", "archetype":&"ordinary_melee_02", "name_key":"ORDINARY_MELEE_02"},
	{"id":&"object_elite_armored", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"armored", "name_key":"ELITE_ARMORED", "preview":{"kind":&"elite", "id":&"armored"}},
	{"id":&"object_elite_overclocked", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"overclocked", "name_key":"ELITE_OVERCLOCKED", "preview":{"kind":&"elite", "id":&"overclocked"}},
	{"id":&"object_elite_heavy", "category":&"enemies", "entry_kind":&"elite", "elite_trait":&"heavy", "name_key":"ELITE_HEAVY", "preview":{"kind":&"elite", "id":&"heavy"}},
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
