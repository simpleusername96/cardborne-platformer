class_name VehicleCombatStages
extends RefCounted

## Stage pressure data. Geometry is owned exclusively by DrownedRuinField.

const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")

const STAGE_IDS: Array[StringName] = [&"stage_1", &"stage_2", &"stage_3", &"stage_4", &"stage_5"]
const QUOTAS := [20, 28, 36, 44, 52]
const AUTHORED_COUNTS := [260, 300, 340, 380, 420]
const SURGE_SQUADS := 5
const TITLE_KEYS := [
	"STAGE_DROWNED_RUINS_1", "STAGE_DROWNED_RUINS_2", "STAGE_DROWNED_RUINS_3",
	"STAGE_DROWNED_RUINS_4", "STAGE_DROWNED_RUINS_5",
]
const BOSS_NAME_KEYS := [
	"ENEMY_FOUNDRY_COLOSSUS", "ENEMY_ARCHIVE_LEVIATHAN", "ENEMY_DRYDOCK_TITAN",
	"ENEMY_SWITCHYARD_BEHEMOTH", "ENEMY_CROWN_ENGINE",
]
const MOBILE_ROLES := [
	[&"scrap_drone", &"needle_drone", &"chaser", &"shooter"],
	[&"scrap_drone", &"needle_drone", &"controller", &"shield_escort", &"shooter"],
	[&"needle_drone", &"chaser", &"artillery_spotter", &"rammer", &"shooter"],
	[&"chaser", &"rammer", &"repair_tender", &"drone_carrier", &"needle_drone"],
	[&"scrap_drone", &"needle_drone", &"controller", &"rammer", &"repair_tender", &"drone_carrier", &"artillery_spotter"],
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


static func profile(stage_id: StringName) -> Dictionary:
	var index := index_of(stage_id)
	return {
		"id": STAGE_IDS[index],
		"field_id": Field.FIELD_ID,
		"number": index + 1,
		"title_key": TITLE_KEYS[index],
		"boss_name_key": BOSS_NAME_KEYS[index],
		"quota": QUOTAS[index],
		"authored_count": AUTHORED_COUNTS[index],
		"mobile_roles": MOBILE_ROLES[index].duplicate(),
		"stationary_roles": STATIONARY_ROLES[index].duplicate(),
	}


static func definition(stage_id: StringName) -> Dictionary:
	var result := Field.definition().duplicate(true)
	var stage := profile(stage_id)
	result["id"] = stage["id"]
	result["field_id"] = stage["field_id"]
	result["number"] = stage["number"]
	result["title_key"] = stage["title_key"]
	result["boss_name_key"] = stage["boss_name_key"]
	result["quota"] = stage["quota"]
	result["static_enemies"] = _static_enemies(index_of(stage_id))
	result["packets"] = _packets(index_of(stage_id))
	return result


static func _static_enemies(stage_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in Field.STATIONARY_ANCHORS.size():
		result.append({
			"id":"stage_%d_stationary_%02d" % [stage_index + 1, index + 1],
			"role":STATIONARY_ROLES[stage_index][index],
			"pos":Field.STATIONARY_ANCHORS[index],
			"zone":"field",
			"active":true,
		})
	return result


static func _packets(stage_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var roles: Array = MOBILE_ROLES[stage_index]
	var target_count: int = int(AUTHORED_COUNTS[stage_index])
	var authored := 0
	var packet_index := 0
	while authored < target_count:
		var squads: Array[Array] = []
		var squads_in_packet := 1 if packet_index == 0 else SURGE_SQUADS
		for squad_index in squads_in_packet:
			if authored >= target_count:
				break
			var squad_size := 1 if packet_index == 0 else mini(5, 3 + floori(float(packet_index + squad_index) / 6.0))
			squad_size = mini(squad_size, target_count - authored)
			var squad: Array[StringName] = []
			for unit_index in squad_size:
				squad.append(roles[(packet_index + squad_index + unit_index) % roles.size()])
			if packet_index == 0:
				squad[0] = &"scrap_drone"
			squads.append(squad)
			authored += squad_size
		var anchor := Field.ORDINARY_SPAWN_ANCHORS[(packet_index + stage_index * 3) % Field.ORDINARY_SPAWN_ANCHORS.size()]
		var at_time := 5.1 if packet_index == 0 else 8.0 + float(packet_index - 1) * 3.2
		result.append({
			"id":"stage_%d_packet_%02d" % [stage_index + 1, packet_index + 1],
			"beat":0 if packet_index == 0 else mini(4, 1 + floori(float(packet_index - 1) / 2.0)),
			"trigger":{"kind":&"time", "at":at_time},
			"anchor":anchor,
			"squads":squads,
			"unit_spacing":0.22,
			"squad_gap":0.95,
			"cue_lead":0.9,
			"zone":"field",
			"leash":Field.WORLD_RECT,
		})
		packet_index += 1
	return result
