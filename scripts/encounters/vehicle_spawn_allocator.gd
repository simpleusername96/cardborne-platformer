class_name VehicleSpawnAllocator
extends RefCounted

## Deterministically assigns independent offscreen birth positions. Authored
## squads keep role/tactic meaning but never own a shared spatial anchor.

const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

const MIN_PLAYER_DISTANCE := 900.0
## Reserve arrivals may use the nearest valid point just beyond the camera margin.
## They still remain outside the visible world; this only avoids a long empty
## approach after an opening, quota seal, or stage continuation.
const NEAREST_SAFE_MIN_PLAYER_DISTANCE := 0.0
const MAX_PLAYER_DISTANCE := 2400.0
const RELAXED_MAX_PLAYER_DISTANCE := 2800.0
const OFFSCREEN_MARGIN := 220.0
const CANDIDATE_PREFILTER_RADIUS := 32.0
const TARGET_DISTANCES := [1200.0, 1650.0, 2100.0]
const ARRIVAL_WINDOWS := 3
const SQUADS_PER_WINDOW := 4
const SECTOR_COUNT := 8
const MIN_SAFE_SECTORS := 2
const FORWARD_ARRIVAL_SPEED_THRESHOLD := 80.0
const RELAXATION_TIERS: Array[Dictionary] = [
	{"id":&"T0", "maximum":MAX_PLAYER_DISTANCE, "clearance":480.0},
	{"id":&"T1", "maximum":MAX_PLAYER_DISTANCE, "clearance":400.0},
	{"id":&"T2", "maximum":MAX_PLAYER_DISTANCE, "clearance":320.0},
	{"id":&"T3", "maximum":RELAXED_MAX_PLAYER_DISTANCE, "clearance":320.0},
]
const PURSUIT_ROLES: Array[StringName] = [
	&"ordinary_melee_01", &"ordinary_edge_01", &"ordinary_pull_01", &"ordinary_area_01",
	&"ordinary_gap_01", &"ordinary_support_02", &"ordinary_growth_01",
	&"ordinary_support_01", &"ordinary_support_03",
]
const PROJECTILE_FIRING_ARCHETYPES: Array[StringName] = EnemyArchetypes.PROJECTILE_FIRING_ARCHETYPES

var _seed := 0
var _candidate_points: Array[Vector2] = []
var _geometry_snapshot: Variant
var _geometry_truth_by_radius: Dictionary = {}


func configure(seed: int, authored_anchors: Array[Vector2], geometry_snapshot: Variant = null) -> void:
	_seed = seed
	_geometry_snapshot = geometry_snapshot
	_candidate_points.clear()
	_geometry_truth_by_radius.clear()
	var seen := {}
	if _geometry_snapshot != null and _geometry_snapshot.has_method("spawn_candidate_points"):
		for point in _geometry_snapshot.spawn_candidate_points():
			_append_candidate(Vector2(point), seen)
	for point in authored_anchors:
		_append_candidate(point, seen)


func prewarm_for_packets(packets: Array[Dictionary]) -> void:
	## Geometry is immutable for a configured stage, so exact per-radius truth
	## can be compiled before play instead of recomputed inside an arrival frame.
	if _geometry_snapshot == null or not _geometry_snapshot.has_method("is_spawnable_disc"):
		return
	var radii: Array[float] = [CANDIDATE_PREFILTER_RADIUS]
	var roles := {}
	for packet in packets:
		for squad in Array(packet.get("squads", [])):
			for role_value in Array(squad):
				roles[StringName(role_value)] = true
	for role in roles:
		var radius := float(EnemyArchetypes.definition(StringName(role))["radius"])
		if radius not in radii:
			radii.append(radius)
	radii.sort()
	for radius in radii:
		_cache_geometry_truth(radius)


func allocate(
	packet: Dictionary,
	player_position: Vector2,
	visible_world: Rect2,
	recent_birth_positions: Array[Vector2] = [],
	player_velocity: Vector2 = Vector2.ZERO
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var window_count := _window_count(packet)
	for arrival_window in window_count:
		var allocations := allocate_window(
			packet,
			arrival_window,
			player_position,
			visible_world,
			[],
			recent_birth_positions,
			player_velocity
		)
		if allocations.is_empty():
			return []
		for allocation in allocations:
			result.append(allocation)
	return result


func allocate_window(
	packet: Dictionary,
	arrival_window: int,
	player_position: Vector2,
	visible_world: Rect2,
	reserved_positions: Array[Vector2] = [],
	recent_birth_positions: Array[Vector2] = [],
	player_velocity: Vector2 = Vector2.ZERO
) -> Array[Dictionary]:
	var squads: Array = packet["squads"]
	var reordered := _reorder_roles(squads, String(packet["id"]))
	var squads_per_window := int(packet.get("squads_per_window", SQUADS_PER_WINDOW))
	var first_squad := arrival_window * squads_per_window
	if first_squad >= squads.size():
		return []
	var last_squad := mini(squads.size(), first_squad + squads_per_window)
	var requests: Array[Dictionary] = []
	var maximum_size := 0
	for squad_index in range(first_squad, last_squad):
		maximum_size = maxi(maximum_size, reordered[squad_index].size())
	for unit_index in maximum_size:
		for squad_index in range(first_squad, last_squad):
			if unit_index >= reordered[squad_index].size():
				continue
			requests.append({
				"squad_index":squad_index,
				"window_slot":squad_index - first_squad,
				"unit_index":unit_index,
				"role":StringName(reordered[squad_index][unit_index]),
				"nearest_safe_offscreen":bool(packet.get("nearest_safe_offscreen", false)),
			})
	var separation_truth := reserved_positions.duplicate()
	for position in recent_birth_positions:
		if position not in separation_truth:
			separation_truth.append(position)
	for tier_index in RELAXATION_TIERS.size():
		var tier: Dictionary = RELAXATION_TIERS[tier_index]
		var positions := _try_allocate_requests(
			requests,
			player_position,
			visible_world,
			separation_truth,
			tier,
			String(packet["id"]),
			arrival_window,
			player_velocity
		)
		if positions.is_empty():
			continue
		return _build_window_allocations(
			reordered,
			requests,
			positions,
			first_squad,
			last_squad,
			arrival_window,
			player_position,
			visible_world,
			tier,
			tier_index
		)
	return []


func _try_allocate_requests(
	requests: Array[Dictionary],
	player_position: Vector2,
	visible_world: Rect2,
	existing_positions: Array[Vector2],
	tier: Dictionary,
	packet_id: String,
	arrival_window: int,
	player_velocity: Vector2
) -> Array[Dictionary]:
	var candidates_by_sector := _candidates_by_sector(
		player_position,
		visible_world,
		tier,
		bool(requests[0].get("nearest_safe_offscreen", false))
	)
	var available_sectors := _available_sectors(candidates_by_sector)
	if available_sectors.size() < MIN_SAFE_SECTORS:
		return []
	var sector_order := _maximally_spaced_sector_order(
		available_sectors,
		packet_id,
		arrival_window,
		player_velocity
	)
	var selected := existing_positions.duplicate()
	var result: Array[Dictionary] = []
	for request_index in requests.size():
		var request: Dictionary = requests[request_index]
		var desired_sector := int(sector_order[request_index % sector_order.size()])
		var role := StringName(request["role"])
		var radius := float(EnemyArchetypes.definition(role)["radius"])
		var score_identity := _candidate_score_identity(
			packet_id,
			arrival_window,
			request
		)
		var distance_lane := _role_distance_lane(score_identity, role)
		var best := Vector2.INF
		var best_score := INF
		var best_clearance := INF
		for candidate_index_value in candidates_by_sector[desired_sector]:
			var candidate_index := int(candidate_index_value)
			var candidate := _candidate_points[candidate_index]
			if not _geometry_allows(
				candidate_index,
				candidate,
				radius
			):
				continue
			var clearance := _minimum_clearance(candidate, selected)
			if clearance + 0.001 < float(tier["clearance"]):
				continue
			var score := _candidate_score(
				candidate,
				player_position,
				score_identity,
				distance_lane,
				bool(request.get("nearest_safe_offscreen", false))
			)
			if score < best_score:
				best = candidate
				best_score = score
				best_clearance = clearance
		if not best.is_finite():
			return []
		selected.append(best)
		result.append({
			"position":best,
			"clearance":best_clearance,
			"sector":desired_sector,
			"distance_lane":distance_lane,
		})
	return result


func _build_window_allocations(
	reordered: Array[Array],
	requests: Array[Dictionary],
	positions: Array[Dictionary],
	first_squad: int,
	last_squad: int,
	arrival_window: int,
	player_position: Vector2,
	visible_world: Rect2,
	tier: Dictionary,
	tier_index: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for squad_index in range(first_squad, last_squad):
		result.append({
			"roles":reordered[squad_index].duplicate(),
			"arrival_window":arrival_window,
			"window_slot":squad_index - first_squad,
			"unit_positions":[],
			"unit_clearances":[],
			"unit_sectors":[],
			"unit_distance_lanes":[],
			"relaxation_tier":StringName(tier["id"]),
			"relaxation_tier_index":tier_index,
		})
	for request_index in requests.size():
		var request: Dictionary = requests[request_index]
		var target: Dictionary = result[int(request["squad_index"]) - first_squad]
		var selected: Dictionary = positions[request_index]
		target["unit_positions"].append(Vector2(selected["position"]))
		target["unit_clearances"].append(float(selected["clearance"]))
		target["unit_sectors"].append(int(selected["sector"]))
		target["unit_distance_lanes"].append(int(selected["distance_lane"]))
	for allocation in result:
		var birth_position := Vector2(allocation["unit_positions"][0])
		allocation["anchor"] = birth_position
		allocation["birth_position"] = birth_position
		allocation["birth_clearance"] = _minimum_value(Array(allocation["unit_clearances"]))
		allocation["birth_sector"] = int(allocation["unit_sectors"][0])
		allocation["player_distance"] = birth_position.distance_to(player_position)
		allocation["outside_visible_margin"] = not visible_world.grow(OFFSCREEN_MARGIN).has_point(birth_position)
	return result


func _candidates_by_sector(
	player_position: Vector2,
	visible_world: Rect2,
	tier: Dictionary,
	nearest_safe_offscreen: bool = false
) -> Array[Array]:
	var result: Array[Array] = []
	for _sector in SECTOR_COUNT:
		result.append([])
	for candidate_index in _candidate_points.size():
		var candidate := _candidate_points[candidate_index]
		if not _candidate_allowed(
			candidate_index,
			candidate,
			CANDIDATE_PREFILTER_RADIUS,
			player_position,
			visible_world,
			tier,
			nearest_safe_offscreen
		):
			continue
		result[_sector_for(candidate - player_position)].append(candidate_index)
	return result


func _available_sectors(candidates_by_sector: Array[Array]) -> PackedInt32Array:
	var result := PackedInt32Array()
	for sector in SECTOR_COUNT:
		if not candidates_by_sector[sector].is_empty():
			result.append(sector)
	return result


func _maximally_spaced_sector_order(
	available: PackedInt32Array,
	packet_id: String,
	arrival_window: int,
	player_velocity: Vector2 = Vector2.ZERO
) -> PackedInt32Array:
	var remaining: Array[int] = []
	for sector in available:
		remaining.append(sector)
	remaining.sort()
	var result := PackedInt32Array()
	var start_index := wrapi(
		hash("%d:%s:%d:sector" % [_seed, packet_id, arrival_window]),
		0,
		remaining.size()
	)
	if player_velocity.length() >= FORWARD_ARRIVAL_SPEED_THRESHOLD:
		var forward_sector := _sector_for(player_velocity)
		var closest_distance := SECTOR_COUNT
		var closest_tie := 0x7fffffff
		for index in remaining.size():
			var sector := remaining[index]
			var difference := absi(sector - forward_sector)
			var circular_distance := mini(
				difference, SECTOR_COUNT - difference
			)
			var tie := absi(hash(
				"%d:%s:%d:%d:forward"
				% [_seed, packet_id, arrival_window, sector]
			))
			if (
				circular_distance < closest_distance
				or (
					circular_distance == closest_distance
					and tie < closest_tie
				)
			):
				start_index = index
				closest_distance = circular_distance
				closest_tie = tie
	result.append(remaining.pop_at(start_index))
	if (
		player_velocity.length() >= FORWARD_ARRIVAL_SPEED_THRESHOLD
		and not remaining.is_empty()
	):
		var forward_sector := _sector_for(player_velocity)
		var lateral_index := -1
		var lateral_distance := -1
		var lateral_tie := 0x7fffffff
		for index in remaining.size():
			var sector := remaining[index]
			var difference := absi(sector - forward_sector)
			var circular_distance := mini(
				difference, SECTOR_COUNT - difference
			)
			if circular_distance < 1 or circular_distance > 2:
				continue
			var tie := absi(hash(
				"%d:%s:%d:%d:lateral"
				% [_seed, packet_id, arrival_window, sector]
			))
			if (
				circular_distance > lateral_distance
				or (
					circular_distance == lateral_distance
					and tie < lateral_tie
				)
			):
				lateral_index = index
				lateral_distance = circular_distance
				lateral_tie = tie
		if lateral_index >= 0:
			result.append(remaining.pop_at(lateral_index))
	while not remaining.is_empty():
		var best_index := 0
		var best_distance := -1
		var best_tie := 0x7fffffff
		for index in remaining.size():
			var sector := remaining[index]
			var minimum_distance := SECTOR_COUNT
			for selected in result:
				var difference := absi(sector - selected)
				minimum_distance = mini(minimum_distance, mini(difference, SECTOR_COUNT - difference))
			var tie := absi(hash("%d:%s:%d:%d" % [_seed, packet_id, arrival_window, sector]))
			if minimum_distance > best_distance or (minimum_distance == best_distance and tie < best_tie):
				best_index = index
				best_distance = minimum_distance
				best_tie = tie
		result.append(remaining.pop_at(best_index))
	return result


func _candidate_allowed(
	candidate_index: int,
	candidate: Vector2,
	radius: float,
	player_position: Vector2,
	visible_world: Rect2,
	tier: Dictionary,
	nearest_safe_offscreen: bool = false
) -> bool:
	var distance := candidate.distance_to(player_position)
	var minimum_distance := (
		NEAREST_SAFE_MIN_PLAYER_DISTANCE
		if nearest_safe_offscreen
		else MIN_PLAYER_DISTANCE
	)
	if distance < minimum_distance or distance > float(tier["maximum"]):
		return false
	if visible_world.grow(OFFSCREEN_MARGIN).has_point(candidate):
		return false
	return _geometry_allows(candidate_index, candidate, radius)


func _geometry_allows(candidate_index: int, candidate: Vector2, radius: float) -> bool:
	if _geometry_snapshot != null and _geometry_snapshot.has_method("is_spawnable_disc"):
		var truth: PackedByteArray = _geometry_truth_by_radius.get(radius, PackedByteArray())
		if truth.size() == _candidate_points.size():
			return (
				candidate_index >= 0
				and candidate_index < truth.size()
				and truth[candidate_index] != 0
			)
		return bool(_geometry_snapshot.is_spawnable_disc(candidate, radius))
	return true


func _cache_geometry_truth(radius: float) -> void:
	if _geometry_truth_by_radius.has(radius):
		return
	var truth := PackedByteArray()
	truth.resize(_candidate_points.size())
	for candidate_index in _candidate_points.size():
		if bool(_geometry_snapshot.is_spawnable_disc(_candidate_points[candidate_index], radius)):
			truth[candidate_index] = 1
	_geometry_truth_by_radius[radius] = truth


func _candidate_score(
	candidate: Vector2,
	player_position: Vector2,
	identity: String,
	distance_lane: int,
	nearest_safe_offscreen: bool = false
) -> float:
	var candidate_identity := identity + ":%d:%d" % [
		roundi(candidate.x),
		roundi(candidate.y),
	]
	var tie_break := float(absi(hash(candidate_identity)) % 10000) / 10000.0
	if nearest_safe_offscreen:
		return candidate.distance_to(player_position) + tie_break
	return absf(candidate.distance_to(player_position) - TARGET_DISTANCES[distance_lane]) + tie_break


func _candidate_score_identity(
	packet_id: String,
	arrival_window: int,
	request: Dictionary
) -> String:
	return "%d:%s:%d:%d:%d" % [
		_seed,
		packet_id,
		arrival_window,
		int(request["window_slot"]),
		int(request["unit_index"]),
	]


func _role_distance_lane(score_identity: String, role: StringName) -> int:
	## Allocation chooses only an existing role-appropriate distance lane; the
	## runtime remains the sole owner of effective speed scaling.
	var definition := EnemyArchetypes.definition(role)
	var behavior := StringName(definition.get("behavior", &""))
	if role in [&"ordinary_melee_01", &"ordinary_edge_01", &"ordinary_pull_01", &"ordinary_shield_01", &"ordinary_pulse_01", &"ordinary_area_01"]:
		return 1 + posmod(hash(score_identity + ":pursuit-distance"), 2)
	if behavior in [&"ordinary_lane_01", &"ordinary_gap_01", &"ordinary_growth_01"]:
		return posmod(hash(score_identity + ":standoff-distance"), 2)
	if behavior in [&"ordinary_support_02", &"ordinary_support_01", &"ordinary_support_03"]:
		return 0 # escort/support prefers 1200px.
	# Stationary and specialist births retain the previous all-lane choice.
	return posmod(hash(score_identity + ":distance"), TARGET_DISTANCES.size())


func _minimum_clearance(candidate: Vector2, positions: Array[Vector2]) -> float:
	var result := INF
	for position in positions:
		result = minf(result, candidate.distance_to(position))
	return result


func _minimum_value(values: Array) -> float:
	var result := INF
	for value in values:
		result = minf(result, float(value))
	return result


func _window_count(packet: Dictionary) -> int:
	var squads: Array = packet["squads"]
	if squads.size() <= 1:
		return 1
	return ceili(float(squads.size()) / float(int(packet.get("squads_per_window", SQUADS_PER_WINDOW))))


func _append_candidate(point: Vector2, seen: Dictionary) -> void:
	var key := Vector2i(roundi(point.x), roundi(point.y))
	if seen.has(key):
		return
	seen[key] = true
	_candidate_points.append(point)


func _reorder_roles(squads: Array, packet_id: String) -> Array[Array]:
	if squads.size() == 1 and Array(squads[0]).size() == 1:
		return [[StringName(squads[0][0])]]
	var sizes: Array[int] = []
	var bag: Array[StringName] = []
	var result: Array[Array] = []
	for squad in squads:
		sizes.append(Array(squad).size())
		result.append([])
		for role in squad:
			bag.append(StringName(role))
	_seeded_sort_roles(bag, packet_id)
	for squad_index in sizes.size():
		var pursuit_index := _find_role_index(bag, PURSUIT_ROLES)
		if pursuit_index >= 0:
			result[squad_index].append(bag.pop_at(pursuit_index))
	var direct_index := _find_role_index(bag, PROJECTILE_FIRING_ARCHETYPES)
	var direct_cursor := 0
	while direct_index >= 0:
		var squad_index := _next_available_squad(result, sizes, direct_cursor, true)
		if squad_index < 0:
			break
		result[squad_index].append(bag.pop_at(direct_index))
		direct_cursor = squad_index + 1
		direct_index = _find_role_index(bag, PROJECTILE_FIRING_ARCHETYPES)
	var fill_cursor := 0
	while not bag.is_empty():
		var squad_index := _next_available_squad(result, sizes, fill_cursor, false)
		if squad_index < 0:
			break
		result[squad_index].append(bag.pop_front())
		fill_cursor = squad_index + 1
	return result


func _next_available_squad(
	squads: Array[Array],
	sizes: Array[int],
	cursor: int,
	direct_role: bool
) -> int:
	for offset in squads.size():
		var index := (cursor + offset) % squads.size()
		if squads[index].size() >= sizes[index]:
			continue
		if direct_role and squads[index].filter(
			func(role: StringName) -> bool: return role in PROJECTILE_FIRING_ARCHETYPES
		).size() >= 2:
			continue
		return index
	return -1


func _find_role_index(bag: Array[StringName], accepted: Array[StringName]) -> int:
	for index in bag.size():
		if bag[index] in accepted:
			return index
	return -1


func _seeded_sort_roles(roles: Array[StringName], packet_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:roles" % [_seed, packet_id])
	for index in range(roles.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := roles[index]
		roles[index] = roles[swap_index]
		roles[swap_index] = held


func _sector_for(offset: Vector2) -> int:
	var raw := floori((offset.angle() + PI) / (TAU / float(SECTOR_COUNT)))
	return (raw % SECTOR_COUNT + SECTOR_COUNT) % SECTOR_COUNT
