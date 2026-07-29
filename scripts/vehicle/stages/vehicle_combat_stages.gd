class_name VehicleCombatStages
extends RefCounted

## Stage pressure data. Geometry is supplied by the run-selected field.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

const STAGE_IDS: Array[StringName] = [&"stage_1", &"stage_2", &"stage_3", &"stage_4", &"stage_5"]
const QUOTAS := [125, 166, 208, 250, 291]
const AUTHORED_COUNTS := [520, 660, 816, 1026, 1260]
const SURGE_PACKS := 4
const SQUADS_PER_PACK := 3
const SURGE_SQUADS := SURGE_PACKS * SQUADS_PER_PACK
const MIN_SQUAD_SIZE := 4
const MAX_SQUAD_SIZE := 8
const MAX_SURGE_UNITS := SURGE_SQUADS * MAX_SQUAD_SIZE
const TITLE_KEYS_BY_FIELD := {
	&"drowned_ruin_field":[
		"STAGE_DROWNED_RUINS_1", "STAGE_DROWNED_RUINS_2", "STAGE_DROWNED_RUINS_3",
		"STAGE_DROWNED_RUINS_4", "STAGE_DROWNED_RUINS_5",
	],
	&"tidal_archive_field":[
		"STAGE_TIDAL_ARCHIVE_1", "STAGE_TIDAL_ARCHIVE_2", "STAGE_TIDAL_ARCHIVE_3",
		"STAGE_TIDAL_ARCHIVE_4", "STAGE_TIDAL_ARCHIVE_5",
	],
	&"storm_drydock_field":[
		"STAGE_STORM_DRYDOCK_1", "STAGE_STORM_DRYDOCK_2", "STAGE_STORM_DRYDOCK_3",
		"STAGE_STORM_DRYDOCK_4", "STAGE_STORM_DRYDOCK_5",
	],
}
const BOSS_NAME_KEYS := [
	"ENEMY_FOUNDRY_COLOSSUS", "ENEMY_ARCHIVE_LEVIATHAN", "ENEMY_DRYDOCK_TITAN",
	"ENEMY_SWITCHYARD_BEHEMOTH", "ENEMY_CROWN_ENGINE",
]
const MOBILE_ROLES := [
	[&"scrap_drone", &"needle_drone", &"chaser", &"shooter"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"shield_escort", &"shooter", &"chaser"],
	[&"spark_minelet", &"chaser", &"artillery_spotter", &"rammer", &"bulkhead_guard", &"scrap_drone"],
	[&"chaser", &"rammer", &"bulkhead_guard", &"repair_tender", &"spark_minelet", &"needle_drone"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender", &"needle_drone"],
]
const STATIONARY_ROLES := [
	[&"turret", &"mine", &"turret", &"mine"],
	[&"interceptor_tower", &"generator", &"turret", &"mine"],
	[&"beam_sentinel", &"turret", &"interceptor_tower", &"mine"],
	[&"generator", &"beam_sentinel", &"interceptor_tower", &"turret"],
	[&"beam_sentinel", &"generator", &"interceptor_tower", &"turret"],
]


static func normalized_id(stage_id: StringName) -> StringName:
	return stage_id if stage_id in STAGE_IDS else STAGE_IDS[0]


static func index_of(stage_id: StringName) -> int:
	return maxi(0, STAGE_IDS.find(normalized_id(stage_id)))


static func profile(stage_id: StringName, field_id: StringName = &"drowned_ruin_field") -> Dictionary:
	var index := index_of(stage_id)
	var normalized_field := FieldRegistry.normalized_id(field_id)
	var title_keys: Array = TITLE_KEYS_BY_FIELD.get(
		normalized_field,
		TITLE_KEYS_BY_FIELD[&"drowned_ruin_field"]
	)
	return {
		"id": STAGE_IDS[index],
		"field_id": normalized_field,
		"number": index + 1,
		"title_key": title_keys[index],
		"boss_name_key": BOSS_NAME_KEYS[index],
		"quota": QUOTAS[index],
		"authored_count": AUTHORED_COUNTS[index],
		"mobile_roles": MOBILE_ROLES[index].duplicate(),
		"stationary_roles": STATIONARY_ROLES[index].duplicate(),
	}


static func definition(
	stage_id: StringName,
	field_definition: Dictionary = FieldRegistry.definition(&"drowned_ruin_field")
) -> Dictionary:
	var result := field_definition.duplicate(true)
	var stage := profile(stage_id, StringName(field_definition["id"]))
	result["id"] = stage["id"]
	result["field_id"] = stage["field_id"]
	result["number"] = stage["number"]
	result["title_key"] = stage["title_key"]
	result["boss_name_key"] = stage["boss_name_key"]
	result["quota"] = stage["quota"]
	result["static_enemies"] = _static_enemies(index_of(stage_id), field_definition)
	result["packets"] = _packets(index_of(stage_id), field_definition)
	return result


static func _static_enemies(stage_index: int, field_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var sectors: Array[StringName] = [&"nw", &"n", &"ne", &"sw"]
	var candidate_groups: Dictionary = field_definition["stationary_candidates"]
	for index in sectors.size():
		result.append({
			"id":"stage_%d_stationary_%02d" % [stage_index + 1, index + 1],
			"role":STATIONARY_ROLES[stage_index][index],
			"pos":Vector2(candidate_groups[sectors[index]][0]),
			"zone":"field",
			"active":true,
		})
	return result


static func _packets(stage_index: int, field_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var target_count: int = int(AUTHORED_COUNTS[stage_index])
	var sequence := _role_sequence(stage_index, target_count)
	result.append({
		"id":"stage_%d_packet_01" % [stage_index + 1],
		"beat":0,
		"trigger":{"kind":&"time", "at":5.1},
		"squads":[[&"scrap_drone"]],
		"unit_spacing":0.16,
		"cue_lead":0.9,
		"zone":"field",
		"leash":Rect2(field_definition["world_rect"]),
	})
	var remaining := target_count - 1
	var surge_count := ceili(float(remaining) / float(MAX_SURGE_UNITS))
	var base_surge_size := remaining / surge_count
	var extra_surges := remaining % surge_count
	var cursor := 1
	for surge_index in surge_count:
		var surge_size := base_surge_size + (1 if surge_index < extra_surges else 0)
		var beat := mini(4, 1 + floori(4.0 * float(surge_index) / float(surge_count)))
		result.append({
			"id":"stage_%d_packet_%02d" % [stage_index + 1, surge_index + 2],
			"beat":beat,
			"trigger":{"kind":&"time", "at":8.0 + float(surge_index) * 2.4},
			"squads":_surge_squads(sequence, cursor, surge_size),
			"pack_count":SURGE_PACKS,
			"squads_per_pack":SQUADS_PER_PACK,
			"arrival_mode":&"multi_sector",
			"unit_spacing":0.10,
			"cue_lead":0.9,
			"zone":"field",
			"leash":Rect2(field_definition["world_rect"]),
		})
		cursor += surge_size
	return result


static func _role_sequence(stage_index: int, target_count: int) -> Array[StringName]:
	var families := {
		&"pursuit":[],
		&"ranged":[],
		&"denial":[],
		&"support":[],
	}
	for role_variant in MOBILE_ROLES[stage_index]:
		var role := StringName(role_variant)
		var definition := EnemyArchetypes.definition(role)
		var family := StringName(definition["threat_kind"])
		if EnemyArchetypes.fires_projectiles(role):
			family = &"ranged"
		if not families.has(family):
			family = &"pursuit"
		families[family].append(role)
	var counters := {&"pursuit":0, &"ranged":0, &"denial":0, &"support":0}
	var result: Array[StringName] = []
	for index in target_count:
		var roll := index % 100
		var family := &"pursuit"
		if roll >= 88:
			family = &"support"
		elif roll >= 80:
			family = &"denial"
		elif roll >= 65:
			family = &"ranged"
		var roles: Array = families[family]
		if roles.is_empty():
			family = &"pursuit"
			roles = families[family]
		var role_index := int(counters[family]) % roles.size()
		result.append(StringName(roles[role_index]))
		counters[family] = int(counters[family]) + 1
	result[0] = &"scrap_drone"
	return result


static func _surge_squads(
	sequence: Array[StringName],
	start_index: int,
	unit_count: int
) -> Array[Array]:
	var result: Array[Array] = []
	var base_size := unit_count / SURGE_SQUADS
	var extra := unit_count % SURGE_SQUADS
	var cursor := start_index
	for squad_index in SURGE_SQUADS:
		var squad_size := base_size + (1 if squad_index < extra else 0)
		var squad: Array[StringName] = []
		for _unit_index in squad_size:
			squad.append(sequence[cursor])
			cursor += 1
		result.append(squad)
	return result
