class_name VehicleSpawnAllocator
extends RefCounted

## Deterministically assigns validated arrival anchors while preserving authored
## squads and role totals. Unmarked packets remain spatially distributed.

const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

const MIN_PLAYER_DISTANCE := 900.0
const MAX_PLAYER_DISTANCE := 2400.0
const OFFSCREEN_MARGIN := 220.0
const RECENT_ANCHOR_LIMIT := 16
const TARGET_DISTANCES := [1200.0, 1650.0, 2100.0]
const ARRIVAL_DISTRIBUTED := &"distributed"
const ARRIVAL_HORDE_FRONT := &"horde_front"
const HORDE_FRONT_SQUADS := 4
const HORDE_FRONT_MIN_SEPARATION := PI * 0.5
const PURSUIT_ROLES: Array[StringName] = [
	&"scrap_drone", &"chaser", &"rammer", &"spark_minelet",
	&"controller", &"shield_escort", &"artillery_spotter",
	&"repair_tender", &"drone_carrier",
]
const PROJECTILE_FIRING_ARCHETYPES: Array[StringName] = EnemyArchetypes.PROJECTILE_FIRING_ARCHETYPES

var _seed := 0
var _anchors: Array[Vector2] = []
var _recent_anchors: Array[Vector2] = []


func configure(seed: int, anchors: Array[Vector2]) -> void:
	_seed = seed
	_anchors = anchors.duplicate()
	_recent_anchors.clear()


func allocate(packet: Dictionary, player_position: Vector2, visible_world: Rect2) -> Array[Dictionary]:
	var squads: Array = packet["squads"]
	var reordered := _reorder_roles(squads, String(packet["id"]))
	var arrival_mode := StringName(packet.get("arrival_mode", ARRIVAL_DISTRIBUTED))
	if arrival_mode == ARRIVAL_HORDE_FRONT:
		return _allocate_horde_fronts(packet, squads, reordered, player_position, visible_world)
	return _allocate_distributed(packet, squads, reordered, player_position, visible_world)


func _allocate_distributed(
	packet: Dictionary,
	squads: Array,
	reordered: Array[Array],
	player_position: Vector2,
	visible_world: Rect2
) -> Array[Dictionary]:
	var beat := int(packet["beat"])
	var group_size := 2 if beat <= 1 else 3
	var maximum_arc := deg_to_rad(135.0 if beat <= 1 else 180.0)
	var used: Array[Vector2] = []
	var result: Array[Dictionary] = []
	for squad_index in squads.size():
		var group_index := floori(float(squad_index) / float(group_size))
		var first_in_group := group_index * group_size
		var group_direction := INF
		if first_in_group < result.size():
			group_direction = (
				Vector2(result[first_in_group]["anchor"]) - player_position
			).angle()
		var anchor := _choose_anchor(
			player_position, visible_world, used, group_direction, maximum_arc,
			String(packet["id"]), squad_index
		)
		used.append(anchor)
		_remember(anchor)
		result.append({
			"anchor":anchor,
			"roles":reordered[squad_index],
			"group_index":group_index,
			"player_distance":anchor.distance_to(player_position),
			"outside_visible_margin":not visible_world.grow(OFFSCREEN_MARGIN).has_point(anchor),
			"sector":_sector_for(anchor - player_position),
		})
	return result


func _allocate_horde_fronts(
	packet: Dictionary,
	squads: Array,
	reordered: Array[Array],
	player_position: Vector2,
	visible_world: Rect2
) -> Array[Dictionary]:
	var used_front_anchors: Array[Vector2] = []
	var result: Array[Dictionary] = []
	for squad_index in squads.size():
		var front_index := floori(float(squad_index) / float(HORDE_FRONT_SQUADS))
		var first_squad_index := front_index * HORDE_FRONT_SQUADS
		var anchor := Vector2.ZERO
		if first_squad_index < result.size():
			anchor = Vector2(result[first_squad_index]["anchor"])
		else:
			anchor = _choose_horde_front_anchor(
				player_position,
				visible_world,
				used_front_anchors,
				String(packet["id"]),
				front_index
			)
			used_front_anchors.append(anchor)
			_remember(anchor)
		result.append({
			"anchor":anchor,
			"roles":reordered[squad_index],
			"group_index":front_index,
			"player_distance":anchor.distance_to(player_position),
			"outside_visible_margin":not visible_world.grow(OFFSCREEN_MARGIN).has_point(anchor),
			"sector":_sector_for(anchor - player_position),
		})
	return result


func _choose_horde_front_anchor(
	player_position: Vector2,
	visible_world: Rect2,
	used_front_anchors: Array[Vector2],
	packet_id: String,
	front_index: int
) -> Vector2:
	# Spatial fairness tiers remain stronger than the preferred opposite front.
	var tiers: Array[Dictionary] = [
		{"ring":true, "offscreen":true, "avoid_recent":true},
		{"ring":true, "offscreen":true, "avoid_recent":false},
		{"ring":false, "offscreen":true, "avoid_recent":true},
		{"ring":false, "offscreen":true, "avoid_recent":false},
	]
	for tier in tiers:
		for require_separation in [true, false]:
			var candidates := _horde_front_candidates(
				player_position,
				visible_world,
				used_front_anchors,
				bool(tier["ring"]),
				bool(tier["offscreen"]),
				bool(tier["avoid_recent"]),
				require_separation
			)
			if candidates.is_empty():
				continue
			candidates.sort_custom(
				func(a: Vector2, b: Vector2) -> bool:
					return _anchor_score(
						a, player_position, packet_id, front_index * HORDE_FRONT_SQUADS
					) < _anchor_score(
						b, player_position, packet_id, front_index * HORDE_FRONT_SQUADS
					)
			)
			return candidates[0]
	for require_separation in [true, false]:
		var fallback := _horde_front_candidates(
			player_position,
			visible_world,
			used_front_anchors,
			false,
			false,
			false,
			require_separation
		)
		if fallback.is_empty():
			continue
		fallback.sort_custom(
			func(a: Vector2, b: Vector2) -> bool:
				return _anchor_score(
					a, player_position, packet_id, front_index * HORDE_FRONT_SQUADS
				) < _anchor_score(
					b, player_position, packet_id, front_index * HORDE_FRONT_SQUADS
				)
		)
		return fallback[0]
	return _anchors[0] if not _anchors.is_empty() else player_position


func _horde_front_candidates(
	player_position: Vector2,
	visible_world: Rect2,
	used_front_anchors: Array[Vector2],
	require_ring: bool,
	require_offscreen: bool,
	avoid_recent: bool,
	require_separation: bool
) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for anchor in _anchors:
		if anchor in used_front_anchors and used_front_anchors.size() < _anchors.size():
			continue
		var distance := anchor.distance_to(player_position)
		if require_ring and (distance < MIN_PLAYER_DISTANCE or distance > MAX_PLAYER_DISTANCE):
			continue
		if require_offscreen and visible_world.grow(OFFSCREEN_MARGIN).has_point(anchor):
			continue
		if avoid_recent and anchor in _recent_anchors:
			continue
		if require_separation and not used_front_anchors.is_empty():
			var first_direction := (used_front_anchors[0] - player_position).angle()
			var candidate_direction := (anchor - player_position).angle()
			if absf(angle_difference(candidate_direction, first_direction)) < HORDE_FRONT_MIN_SEPARATION:
				continue
		candidates.append(anchor)
	return candidates


func _choose_anchor(
	player_position: Vector2,
	visible_world: Rect2,
	used: Array[Vector2],
	group_direction: float,
	maximum_arc: float,
	packet_id: String,
	squad_index: int
) -> Vector2:
	var tiers: Array[Dictionary] = [
		{"ring":true, "offscreen":true, "recent":true, "arc":true},
		{"ring":false, "offscreen":true, "recent":true, "arc":true},
		{"ring":true, "offscreen":true, "recent":false, "arc":true},
		{"ring":false, "offscreen":true, "recent":false, "arc":true},
		{"distance":false, "offscreen":false, "recent":false, "arc":false},
	]
	for tier in tiers:
		var candidates: Array[Vector2] = []
		for anchor in _anchors:
			if anchor in used and used.size() < _anchors.size():
				continue
			if bool(tier.get("ring", false)):
				var distance := anchor.distance_to(player_position)
				if distance < MIN_PLAYER_DISTANCE or distance > MAX_PLAYER_DISTANCE:
					continue
			if bool(tier["offscreen"]) and visible_world.grow(OFFSCREEN_MARGIN).has_point(anchor):
				continue
			if bool(tier["recent"]) and anchor in _recent_anchors:
				continue
			if (
				bool(tier["arc"])
				and group_direction != INF
				and absf(angle_difference((anchor - player_position).angle(), group_direction)) > maximum_arc * 0.5
			):
				continue
			candidates.append(anchor)
		if candidates.is_empty():
			continue
		candidates.sort_custom(
			func(a: Vector2, b: Vector2) -> bool:
				return _anchor_score(a, player_position, packet_id, squad_index) < _anchor_score(
					b, player_position, packet_id, squad_index
				)
		)
		return candidates[0]
	return _anchors[0] if not _anchors.is_empty() else player_position


func _anchor_score(
	anchor: Vector2,
	player_position: Vector2,
	packet_id: String,
	squad_index: int
) -> float:
	var tie_break := absf(float(hash(
		"%d:%s:%d:%d:%d" % [_seed, packet_id, squad_index, roundi(anchor.x), roundi(anchor.y)]
	) % 10000)) / 10000.0
	var distance_lane := wrapi(
		hash("%d:%s:%d:distance" % [_seed, packet_id, squad_index]),
		0,
		TARGET_DISTANCES.size()
	)
	var target_distance := float(TARGET_DISTANCES[distance_lane])
	return absf(anchor.distance_to(player_position) - target_distance) + tie_break


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


func _remember(anchor: Vector2) -> void:
	_recent_anchors.append(anchor)
	while _recent_anchors.size() > RECENT_ANCHOR_LIMIT:
		_recent_anchors.pop_front()


func _sector_for(offset: Vector2) -> int:
	var raw := floori((offset.angle() + PI) / (TAU / 8.0))
	return (raw % 8 + 8) % 8
