class_name VehicleCombatStages
extends RefCounted

## Stage pressure data. Geometry is supplied by the run-selected field.

const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const TacticCatalog = preload(
	"res://scripts/encounters/vehicle_collective_tactic_catalog.gd"
)

const STAGE_IDS: Array[StringName] = [
	&"stage_1", &"stage_2", &"stage_3", &"stage_4", &"stage_5",
	&"stage_6", &"stage_7", &"stage_8", &"stage_9", &"stage_10",
]
const QUOTAS := [24, 24, 32, 32, 40, 40, 48, 48, 56, 56]
const AUTHORED_COUNTS := [260, 260, 330, 330, 408, 408, 513, 513, 630, 630]
const ARRIVAL_WINDOWS := 3
const SQUADS_PER_WINDOW := 4
const SURGE_SQUADS := ARRIVAL_WINDOWS * SQUADS_PER_WINDOW
const MIN_SQUAD_SIZE := 4
const MAX_SQUAD_SIZE := 8
const MAX_SURGE_UNITS := SURGE_SQUADS * MAX_SQUAD_SIZE
# Standard-to-total pursuit ratios preserve the pre-density quota-path XP
# cadence without spending the new body count on ranged or support roles.
const PURSUIT_STANDARD_RATIOS := [
	Vector2i(27, 53),
	Vector2i(27, 53),
	Vector2i(77, 127),
	Vector2i(77, 127),
	Vector2i(119, 188),
	Vector2i(119, 188),
	Vector2i(85, 96),
	Vector2i(85, 96),
	Vector2i(149, 195),
	Vector2i(149, 195),
]
const TITLE_KEYS_BY_FIELD := {
	&"drowned_ruin_field":[
		"STAGE_DROWNED_RUINS_1", "STAGE_DROWNED_RUINS_2", "STAGE_DROWNED_RUINS_3",
		"STAGE_DROWNED_RUINS_4", "STAGE_DROWNED_RUINS_5", "STAGE_DROWNED_RUINS_6", "STAGE_DROWNED_RUINS_7", "STAGE_DROWNED_RUINS_8", "STAGE_DROWNED_RUINS_9", "STAGE_DROWNED_RUINS_10",
	],
	&"tidal_archive_field":[
		"STAGE_TIDAL_ARCHIVE_1", "STAGE_TIDAL_ARCHIVE_2", "STAGE_TIDAL_ARCHIVE_3",
		"STAGE_TIDAL_ARCHIVE_4", "STAGE_TIDAL_ARCHIVE_5", "STAGE_TIDAL_ARCHIVE_6", "STAGE_TIDAL_ARCHIVE_7", "STAGE_TIDAL_ARCHIVE_8", "STAGE_TIDAL_ARCHIVE_9", "STAGE_TIDAL_ARCHIVE_10",
	],
	&"storm_drydock_field":[
		"STAGE_STORM_DRYDOCK_1", "STAGE_STORM_DRYDOCK_2", "STAGE_STORM_DRYDOCK_3",
		"STAGE_STORM_DRYDOCK_4", "STAGE_STORM_DRYDOCK_5", "STAGE_STORM_DRYDOCK_6", "STAGE_STORM_DRYDOCK_7", "STAGE_STORM_DRYDOCK_8", "STAGE_STORM_DRYDOCK_9", "STAGE_STORM_DRYDOCK_10",
	],
}
const BOSS_PROFILE_IDS: Array[StringName] = [
	&"", &"stage_1", &"", &"stage_2", &"", &"stage_3", &"", &"stage_4", &"", &"stage_5",
]
const BOSS_NAME_KEYS := [
	"", "ENEMY_FOUNDRY_COLOSSUS", "", "ENEMY_ARCHIVE_LEVIATHAN", "", "ENEMY_DRYDOCK_TITAN", "", "ENEMY_SWITCHYARD_BEHEMOTH", "", "ENEMY_CROWN_ENGINE",
]
const MOBILE_ROLES := [
	[&"scrap_drone", &"needle_drone", &"chaser", &"shooter"],
	[&"scrap_drone", &"needle_drone", &"chaser", &"shooter"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"shield_escort", &"shooter", &"chaser"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"shield_escort", &"shooter", &"chaser"],
	[&"spark_minelet", &"chaser", &"artillery_spotter", &"rammer", &"bulkhead_guard", &"scrap_drone"],
	[&"spark_minelet", &"chaser", &"artillery_spotter", &"rammer", &"bulkhead_guard", &"scrap_drone"],
	[&"chaser", &"rammer", &"bulkhead_guard", &"repair_tender", &"spark_minelet", &"needle_drone"],
	[&"chaser", &"rammer", &"bulkhead_guard", &"repair_tender", &"spark_minelet", &"needle_drone"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender", &"needle_drone"],
	[&"scrap_drone", &"spark_minelet", &"controller", &"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender", &"needle_drone"],
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


static func profile(stage_id: StringName, field_id: StringName = &"drowned_ruin_field") -> Dictionary:
	var index := index_of(stage_id)
	if index < 0:
		return {}
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
		"has_boss": not BOSS_PROFILE_IDS[index].is_empty(),
		"boss_profile_id": BOSS_PROFILE_IDS[index],
		"quota": QUOTAS[index],
		"authored_count": AUTHORED_COUNTS[index],
		"mobile_roles": MOBILE_ROLES[index].duplicate(),
	}


static func definition(
	stage_id: StringName,
	field_definition: Dictionary = FieldRegistry.definition(&"drowned_ruin_field")
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
	var sequence := _role_sequence(stage_index, target_count)
	var opening_roles: Array[StringName] = sequence.slice(0, 6)
	result.append({
		"id":"stage_%d_packet_01" % [stage_index + 1],
		"beat":0,
		"trigger":{"kind":&"time", "at":0.0},
		"squads":[opening_roles],
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
	var cursor := opening_roles.size()
	for surge_index in surge_count:
		var surge_size := base_surge_size + (1 if surge_index < extra_surges else 0)
		var beat := mini(4, 1 + floori(4.0 * float(surge_index) / float(surge_count)))
		var squads := _surge_squads(sequence, cursor, surge_size)
		result.append({
			"id":"stage_%d_packet_%02d" % [stage_index + 1, surge_index + 2],
			"beat":beat,
			"trigger":{"kind":&"time", "at":4.0 + float(surge_index) * 2.4},
			"squads":squads,
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
		cursor += surge_size
	return result


static func _role_sequence(stage_index: int, target_count: int) -> Array[StringName]:
	var pair_start := stage_index - posmod(stage_index, 2)
	var pair_total: int = AUTHORED_COUNTS[pair_start] + AUTHORED_COUNTS[pair_start + 1]
	var pair_sequence := _role_sequence_for_arc(pair_start, pair_total)
	var quota_half: int = QUOTAS[pair_start]
	var remaining := pair_sequence.slice(quota_half * 2)
	var result: Array[StringName] = []
	if stage_index == pair_start:
		result.assign(pair_sequence.slice(0, quota_half))
	else:
		result.assign(pair_sequence.slice(quota_half, quota_half * 2))
	var remainder_lane := 0 if stage_index == pair_start else 1
	for remaining_index in remaining.size():
		if remaining_index % 2 == remainder_lane:
			result.append(remaining[remaining_index])
	if result.size() != target_count:
		push_error("Paired stage role partition produced an invalid authored count")
		return []
	return result


static func _role_sequence_for_arc(stage_index: int, target_count: int) -> Array[StringName]:
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
		var ordinal := int(counters[family])
		var selected_role := (
			_pursuit_role(roles, stage_index, ordinal)
			if family == &"pursuit"
			else StringName(roles[ordinal % roles.size()])
		)
		result.append(selected_role)
		counters[family] = int(counters[family]) + 1
	result[0] = &"scrap_drone"
	return result


static func _pursuit_role(
	roles: Array,
	stage_index: int,
	ordinal: int
) -> StringName:
	var standard: Array[StringName] = []
	var swarm: Array[StringName] = []
	for role_variant in roles:
		var role := StringName(role_variant)
		if StringName(EnemyArchetypes.definition(role)["health_class"]) == &"swarm":
			swarm.append(role)
		else:
			standard.append(role)
	if standard.is_empty() or swarm.is_empty():
		return StringName(roles[ordinal % roles.size()])
	var ratio: Vector2i = PURSUIT_STANDARD_RATIOS[stage_index]
	var standard_before := floori(
		float(ordinal * ratio.x) / float(ratio.y)
	)
	var standard_after := floori(
		float((ordinal + 1) * ratio.x) / float(ratio.y)
	)
	if standard_after > standard_before:
		return standard[standard_before % standard.size()]
	var swarm_before := ordinal - standard_before
	return swarm[swarm_before % swarm.size()]


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
