class_name VehicleCombatStages
extends RefCounted

## Stage pressure data. Geometry is supplied by the run-selected field.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload(
	"res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd"
)
const TacticCatalog = preload(
	"res://scripts/encounters/vehicle_collective_tactic_catalog.gd"
)

const STAGE_IDS: Array[StringName] = [
	&"stage_1", &"stage_2", &"stage_3", &"stage_4",
	&"stage_5", &"stage_6", &"stage_7", &"stage_8",
	&"stage_9", &"stage_10", &"stage_11", &"stage_12",
]
# A stage ID is now an internal cycle key. Every cycle has a quota and boss.
const QUOTAS := [90, 99, 108, 117, 126, 135, 144, 153, 162, 171, 180, 189]
const AUTHORED_COUNTS := [260, 300, 340, 390, 440, 500, 560, 630, 700, 770, 840, 910]
const ARRIVAL_WINDOWS := 3
const SQUADS_PER_WINDOW := 4
const SURGE_SQUADS := ARRIVAL_WINDOWS * SQUADS_PER_WINDOW
const MIN_SQUAD_SIZE := 4
const MAX_SQUAD_SIZE := 8
const MAX_SURGE_UNITS := SURGE_SQUADS * MAX_SQUAD_SIZE
const TITLE_KEYS_BY_FIELD := {
	&"field_01":[
		"STAGE_FIELD_01_01", "STAGE_FIELD_01_02", "STAGE_FIELD_01_03", "STAGE_FIELD_01_04",
		"STAGE_FIELD_01_05", "STAGE_FIELD_01_06", "STAGE_FIELD_01_07", "STAGE_FIELD_01_08",
		"STAGE_FIELD_01_09", "STAGE_FIELD_01_10", "STAGE_FIELD_01_11", "STAGE_FIELD_01_12",
	],
	&"field_02":[
		"STAGE_FIELD_02_01", "STAGE_FIELD_02_02", "STAGE_FIELD_02_03", "STAGE_FIELD_02_04",
		"STAGE_FIELD_02_05", "STAGE_FIELD_02_06", "STAGE_FIELD_02_07", "STAGE_FIELD_02_08",
		"STAGE_FIELD_02_09", "STAGE_FIELD_02_10", "STAGE_FIELD_02_11", "STAGE_FIELD_02_12",
	],
	&"field_03":[
		"STAGE_FIELD_03_01", "STAGE_FIELD_03_02", "STAGE_FIELD_03_03", "STAGE_FIELD_03_04",
		"STAGE_FIELD_03_05", "STAGE_FIELD_03_06", "STAGE_FIELD_03_07", "STAGE_FIELD_03_08",
		"STAGE_FIELD_03_09", "STAGE_FIELD_03_10", "STAGE_FIELD_03_11", "STAGE_FIELD_03_12",
	],
}
const BOSS_PROFILE_IDS: Array[StringName] = [
	&"stage_1", &"stage_2", &"stage_3", &"stage_4",
	&"stage_5", &"stage_6", &"stage_7", &"stage_8",
	&"stage_9", &"stage_10", &"stage_11", &"stage_12",
]
const BOSS_NAME_KEYS := [
	"BOSS_STAGE_01", "BOSS_STAGE_02", "BOSS_STAGE_03", "BOSS_STAGE_04",
	"BOSS_STAGE_05", "BOSS_STAGE_06", "BOSS_STAGE_07", "BOSS_STAGE_08",
	"BOSS_STAGE_09", "BOSS_STAGE_10", "BOSS_STAGE_11", "BOSS_STAGE_12",
]
const MOBILE_ROLES := [
	[&"ordinary_pursuer_t1", &"ordinary_charger_t1", &"ordinary_gunner_t1"],
	[&"ordinary_charger_t1", &"ordinary_gunner_t1", &"ordinary_defender_t1"],
	[&"ordinary_gunner_t1", &"ordinary_defender_t1", &"ordinary_coordinator_t1"],
	[&"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_pursuer_t1"],
	[&"ordinary_pursuer_t2", &"ordinary_charger_t2", &"ordinary_gunner_t2"],
	[&"ordinary_charger_t2", &"ordinary_gunner_t2", &"ordinary_defender_t2"],
	[&"ordinary_gunner_t2", &"ordinary_defender_t2", &"ordinary_coordinator_t2"],
	[&"ordinary_defender_t2", &"ordinary_coordinator_t2", &"ordinary_pursuer_t2"],
	[&"ordinary_pursuer_t3", &"ordinary_charger_t3", &"ordinary_gunner_t3"],
	[&"ordinary_charger_t3", &"ordinary_gunner_t3", &"ordinary_defender_t3"],
	[&"ordinary_gunner_t3", &"ordinary_defender_t3", &"ordinary_coordinator_t3"],
	[&"ordinary_defender_t3", &"ordinary_coordinator_t3", &"ordinary_pursuer_t3"],
]
const BOSS_TUTOR_ROLES := [
	&"ordinary_gunner_t1", &"ordinary_defender_t1", &"ordinary_coordinator_t1", &"ordinary_pursuer_t1",
	&"ordinary_gunner_t2", &"ordinary_defender_t2", &"ordinary_coordinator_t2", &"ordinary_pursuer_t2",
	&"ordinary_gunner_t3", &"ordinary_defender_t3", &"ordinary_coordinator_t3", &"ordinary_pursuer_t3",
]

static func normalized_id(stage_id: StringName) -> StringName:
	return stage_id if stage_id in STAGE_IDS else &""


static func index_of(stage_id: StringName) -> int:
	return STAGE_IDS.find(normalized_id(stage_id))


static func has_boss(stage_id: StringName) -> bool:
	var index := index_of(stage_id)
	return index >= 0 and not BOSS_PROFILE_IDS[index].is_empty()


static func boss_profile_id(stage_id: StringName) -> StringName:
	var index := index_of(stage_id)
	return BOSS_PROFILE_IDS[index] if index >= 0 else &""


static func profile(stage_id: StringName, field_id: StringName = &"field_01") -> Dictionary:
	var index := index_of(stage_id)
	if index < 0:
		return {}
	var normalized_field := FieldRegistry.normalized_id(field_id)
	var title_keys: Array = TITLE_KEYS_BY_FIELD.get(
		normalized_field,
		TITLE_KEYS_BY_FIELD[&"field_01"]
	)
	return {
		"id": STAGE_IDS[index],
		"field_id": normalized_field,
		"number": index + 1,
		"title_key": title_keys[index],
		"boss_name_key": BOSS_NAME_KEYS[index],
		"has_boss": not BOSS_PROFILE_IDS[index].is_empty(),
		"boss_profile_id": BOSS_PROFILE_IDS[index],
		"quota": QUOTAS[index],
		"authored_count": AUTHORED_COUNTS[index],
		"mobile_roles": MOBILE_ROLES[index].duplicate(),
	}


static func definition(
	stage_id: StringName,
	field_definition: Dictionary = FieldRegistry.definition(&"field_01")
) -> Dictionary:
	var result := field_definition.duplicate(true)
	var stage := profile(stage_id, StringName(field_definition["id"]))
	if stage.is_empty():
		return {}
	result["id"] = stage["id"]
	result["field_id"] = stage["field_id"]
	result["number"] = stage["number"]
	result["title_key"] = stage["title_key"]
	result["boss_name_key"] = stage["boss_name_key"]
	result["has_boss"] = stage["has_boss"]
	result["boss_profile_id"] = stage["boss_profile_id"]
	result["quota"] = stage["quota"]
	result["packets"] = _packets(index_of(stage_id), field_definition)
	return result


static func _packets(stage_index: int, field_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var target_count: int = int(AUTHORED_COUNTS[stage_index])
	var opening_pack := _pack_blueprint(stage_index, 0, 6)
	var opening_roles: Array[StringName] = []
	for role in Array(opening_pack["roles"]):
		opening_roles.append(StringName(role))
	result.append({
		"id":"stage_%d_packet_01" % [stage_index + 1],
		"beat":0,
		"trigger":{"kind":&"time", "at":0.0},
		"squads":[opening_roles],
		"packs":[opening_pack],
		"unit_spacing":0.16,
		"cue_lead":0.9,
		"nearest_safe_offscreen":true,
		"engagement_pattern":&"none",
		"engagement_patterns":[&"none"],
		"zone":"field",
		"leash":Rect2(field_definition["world_rect"]),
	})
	var remaining := target_count - opening_roles.size()
	var stage_one_surge := stage_index == 0
	var maximum_surge_units := 72 if stage_one_surge else MAX_SURGE_UNITS
	var arrival_windows := 12 if stage_one_surge else ARRIVAL_WINDOWS
	var squads_per_window := 1 if stage_one_surge else SQUADS_PER_WINDOW
	var engagement_patterns: Array[StringName] = []
	for window_index in arrival_windows:
		engagement_patterns.append(
			&"two_offset_streams" if window_index % 3 == 1 else &"broad_crescent"
		)
	var surge_count := ceili(float(remaining) / float(maximum_surge_units))
	var base_surge_size := remaining / surge_count
	var extra_surges := remaining % surge_count
	var pack_ordinal := 1
	for surge_index in surge_count:
		var surge_size := base_surge_size + (1 if surge_index < extra_surges else 0)
		var beat := mini(4, 1 + floori(4.0 * float(surge_index) / float(surge_count)))
		var packs := _surge_packs(stage_index, pack_ordinal, surge_size)
		var squads: Array[Array] = []
		for pack in packs:
			squads.append(Array(Dictionary(pack)["roles"]).duplicate())
		result.append({
			"id":"stage_%d_packet_%02d" % [stage_index + 1, surge_index + 2],
			"beat":beat,
			"trigger":{"kind":&"time", "at":4.0 + float(surge_index) * 2.4},
			"squads":squads,
			"packs":packs,
			"collective_tactic":TacticCatalog.assignment_for(
				stage_index,
				surge_index,
				surge_count,
				squads.size()
			),
			"arrival_windows":arrival_windows,
			"squads_per_window":squads_per_window,
			"window_gap":1.20,
			"unit_spacing":0.16,
			"cue_lead":0.9,
			"engagement_pattern":&"broad_crescent",
			"engagement_patterns":engagement_patterns,
			"zone":"field",
			"leash":Rect2(field_definition["world_rect"]),
		})
		pack_ordinal += packs.size()
	return result


static func _surge_packs(
	stage_index: int,
	start_pack_ordinal: int,
	unit_count: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var base_size := unit_count / SURGE_SQUADS
	var extra := unit_count % SURGE_SQUADS
	for squad_index in SURGE_SQUADS:
		var squad_size := base_size + (1 if squad_index < extra else 0)
		result.append(_pack_blueprint(stage_index, start_pack_ordinal + squad_index, squad_size))
	return result


static func _pack_blueprint(stage_index: int, pack_ordinal: int, pack_size: int) -> Dictionary:
	var tier := FamilyTraits.tier_for_stage(stage_index)
	var primary_archetype := StringName(MOBILE_ROLES[stage_index][pack_ordinal % 3])
	var family := StringName(EnemyArchetypes.definition(primary_archetype)["family"])
	var roles: Array[StringName] = []
	var defender_count := 0
	if family == &"gunner":
		defender_count = 2 if pack_size >= 6 else 1
	for _index in pack_size - defender_count:
		roles.append(FamilyTraits.archetype(family, tier))
	for _index in defender_count:
		roles.append(FamilyTraits.archetype(&"defender", tier))
	return {
		"family":family,
		"tier":tier,
		"trait":FamilyTraits.trait_for_pack(family, stage_index, pack_ordinal),
		"tactic_id":FamilyTraits.tactic_for_family(family),
		"roles":roles,
	}
