class_name VehiclePressureFixture
extends RefCounted

## Builds deterministic pressure descriptors from production spawn anchors.
## This owns test workload geometry only; combat policy stays in production owners.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const SpawnAllocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")

const FIXED_SEED := 12886704
const PEAK_ORDINARY_COUNT := 276
const CAPACITY_ORDINARY_COUNT := 320
const BOSS_ORDINARY_COUNT := 76
const INNER_COUNT := 124
const NEAR_COUNT := 100
const INNER_SECTOR_WEIGHTS := [22, 9, 9, 22, 22, 9, 9, 22]

const INNER_RADII := [
	210.0, 250.0, 290.0, 330.0, 370.0,
	410.0, 450.0, 490.0, 530.0, 570.0,
]
const NEAR_RADII := [660.0, 760.0, 850.0]
const FAR_RADII := [1040.0, 1160.0, 1280.0]


static func build(
	load_class: StringName,
	stage_id: StringName,
	player_position: Vector2,
	visible_world: Rect2,
	spawn_anchors: Array[Vector2],
	production_roles: Array[StringName],
	ordinary_count_override: int = -1
) -> Dictionary:
	var ordinary_count := PEAK_ORDINARY_COUNT
	var include_boss := false
	match load_class:
		&"peak":
			pass
		&"capacity", &"lifecycle":
			ordinary_count = CAPACITY_ORDINARY_COUNT
		&"boss":
			ordinary_count = BOSS_ORDINARY_COUNT
			include_boss = true
		_:
			push_error("Unknown pressure fixture load class: %s" % String(load_class))
			return {}
	if ordinary_count_override > 0:
		ordinary_count = clampi(
			ordinary_count_override, 1, CAPACITY_ORDINARY_COUNT
		)
	if production_roles.is_empty():
		push_error("Pressure fixture requires a production role sequence")
		return {}

	var allocator := SpawnAllocator.new()
	allocator.configure(FIXED_SEED, spawn_anchors)
	var directions := _allocator_sector_directions(
		allocator, player_position, visible_world, spawn_anchors
	)
	var positions := _distributed_positions(
		stage_id, player_position, visible_world, directions, ordinary_count
	)
	var descriptors: Array[Dictionary] = []
	for index in ordinary_count:
		descriptors.append({
			"id":"pressure_%s_enemy_%03d" % [String(load_class), index],
			"role":production_roles[index % production_roles.size()],
			"pos":positions[index],
			"active":true,
			"counts_active_cap":index >= 4,
			"fixture_kind":&"ordinary",
		})
	if include_boss:
		descriptors.append({
			"id":"performance_boss",
			"role":&"stage_boss",
			"pos":positions[-1],
			"active":true,
			"counts_active_cap":false,
			"fixture_kind":&"boss",
		})
	return {
		"load_class":load_class,
		"seed":FIXED_SEED,
		"descriptors":descriptors,
		"ordinary_count":ordinary_count,
		"auxiliary_count":0,
		"boss_count":1 if include_boss else 0,
		"fingerprint":_fingerprint(descriptors),
	}


static func qualification(
	descriptors: Array,
	player_position: Vector2,
	visible_world: Rect2
) -> Dictionary:
	var visible := 0
	var near_600 := 0
	var near_900 := 0
	var sectors := PackedInt32Array()
	sectors.resize(8)
	for descriptor_variant in descriptors:
		var descriptor := Dictionary(descriptor_variant)
		if StringName(descriptor.get("fixture_kind", &"ordinary")) != &"ordinary":
			continue
		var position := Vector2(descriptor["pos"])
		var offset := position - player_position
		var distance_squared := offset.length_squared()
		if visible_world.has_point(position):
			visible += 1
		if distance_squared <= 600.0 * 600.0:
			near_600 += 1
		if distance_squared <= 900.0 * 900.0:
			near_900 += 1
		sectors[_sector_for_offset(offset)] += 1
	var all_sectors := true
	var sector_range_valid := true
	var active := 0
	for count in sectors:
		active += count
		all_sectors = all_sectors and count > 0
		sector_range_valid = sector_range_valid and count >= 24 and count <= 45
	return {
		"active":active,
		"visible":visible,
		"near_600":near_600,
		"near_900":near_900,
		"sector_histogram":sectors,
		"all_sectors":all_sectors,
		"sector_range_valid":sector_range_valid,
	}


static func peak_qualification_passes(snapshot: Dictionary) -> bool:
	return (
		int(snapshot.get("active", 0)) == PEAK_ORDINARY_COUNT
		and int(snapshot.get("visible", 0)) >= 180
		and int(snapshot.get("visible", 0)) <= 260
		and int(snapshot.get("near_600", 0)) <= 160
		and int(snapshot.get("near_900", 0)) >= 200
		and int(snapshot.get("near_900", 0)) <= 240
		and bool(snapshot.get("all_sectors", false))
		and bool(snapshot.get("sector_range_valid", false))
	)


static func _allocator_sector_directions(
	allocator: SpawnAllocator,
	player_position: Vector2,
	visible_world: Rect2,
	spawn_anchors: Array[Vector2]
) -> Array[Vector2]:
	var squads: Array[Array] = []
	for _index in 8:
		squads.append([&"scrap_drone"])
	var allocations := allocator.allocate({
		"id":"performance_peak_sector_probe",
		"beat":4,
		"squads":squads,
		"zone":"field",
		"leash":Rules.world_rect(),
	}, player_position, visible_world)
	var result: Array[Vector2] = []
	result.resize(8)
	for allocation_variant in allocations:
		var allocation := Dictionary(allocation_variant)
		var direction := (Vector2(allocation["anchor"]) - player_position).normalized()
		if direction.length_squared() <= 0.001:
			continue
		var sector := _sector_for_offset(direction)
		if result[sector].length_squared() <= 0.001:
			result[sector] = direction
	for sector in 8:
		if result[sector].length_squared() > 0.001:
			continue
		var target_angle := -PI + (float(sector) + 0.5) * TAU / 8.0
		var best_direction := Vector2.RIGHT.rotated(target_angle)
		var best_error := INF
		for anchor in spawn_anchors:
			var candidate := (anchor - player_position).normalized()
			if candidate.length_squared() <= 0.001:
				continue
			var error := absf(angle_difference(candidate.angle(), target_angle))
			if error < best_error:
				best_error = error
				best_direction = candidate
		result[sector] = best_direction
	return result


static func _distributed_positions(
	stage_id: StringName,
	player_position: Vector2,
	visible_world: Rect2,
	directions: Array[Vector2],
	count: int
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var visible_targets := _weighted_sector_targets(
		mini(INNER_COUNT, count), INNER_SECTOR_WEIGHTS
	)
	var near_targets := _sector_targets(mini(NEAR_COUNT, maxi(0, count - INNER_COUNT)))
	var far_targets := _sector_targets(maxi(0, count - INNER_COUNT - NEAR_COUNT))
	for sector in 8:
		result.append_array(_positions_for_band(
			stage_id, player_position, visible_world, directions[sector],
			sector, visible_targets[sector], INNER_RADII, true
		))
		result.append_array(_positions_for_band(
			stage_id, player_position, visible_world, directions[sector],
			sector, near_targets[sector], NEAR_RADII, false
		))
		result.append_array(_positions_for_band(
			stage_id, player_position, visible_world, directions[sector],
			sector, far_targets[sector], FAR_RADII, false
		))
	return result


static func _sector_targets(total: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(8)
	for index in total:
		result[index % 8] += 1
	return result


static func _weighted_sector_targets(
	total: int,
	weights: Array
) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(weights.size())
	var weight_total := 0
	for weight in weights:
		weight_total += weight
	var assigned := 0
	for index in weights.size():
		result[index] = floori(float(total * weights[index]) / float(weight_total))
		assigned += result[index]
	var cursor := 0
	while assigned < total:
		result[cursor % result.size()] += 1
		assigned += 1
		cursor += 1
	return result


static func _positions_for_band(
	stage_id: StringName,
	player_position: Vector2,
	visible_world: Rect2,
	base_direction: Vector2,
	sector: int,
	target: int,
	radii: Array,
	require_visible: bool
) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var base_angle := base_direction.angle()
	var attempt := 0
	while result.size() < target and attempt < 512:
		var radius := float(radii[attempt % radii.size()])
		var lane := floori(float(attempt) / float(radii.size()))
		var angular_step := deg_to_rad(4.5)
		var signed_lane := (lane + 1) / 2 * (-1 if lane % 2 == 0 else 1)
		var angle := base_angle + float(signed_lane) * angular_step
		var candidate := player_position + Vector2.RIGHT.rotated(angle) * radius
		var in_sector := _sector_for_offset(candidate - player_position) == sector
		# The fixed radial workload must survive camera presentation changes.
		# Inner actors remain provably visible; outer bands keep their coordinates
		# instead of being pushed outward when the camera shows more of the field.
		var visibility_matches := (
			visible_world.grow(-42.0).has_point(candidate)
			if require_visible
			else true
		)
		if (
			in_sector
			and visibility_matches
			and Rules.is_position_walkable(candidate, 24.0, stage_id)
			and _separated(candidate, result)
		):
			result.append(candidate)
		attempt += 1
	if result.size() < target:
		push_error(
			"Pressure fixture could place only %d/%d actors in sector %d"
			% [result.size(), target, sector]
		)
		while result.size() < target:
			var fallback_radius := float(radii[result.size() % radii.size()])
			result.append(player_position + base_direction * fallback_radius)
	return result


static func _separated(candidate: Vector2, existing: Array[Vector2]) -> bool:
	for position in existing:
		if candidate.distance_squared_to(position) < 36.0 * 36.0:
			return false
	return true


static func _fingerprint(descriptors: Array[Dictionary]) -> int:
	var canonical: Array = []
	for descriptor in descriptors:
		var position := Vector2(descriptor["pos"])
		canonical.append([
			String(descriptor["id"]),
			String(descriptor["role"]),
			roundi(position.x * 10.0),
			roundi(position.y * 10.0),
			String(descriptor.get("fixture_kind", &"ordinary")),
		])
	return hash(var_to_str(canonical))


static func _sector_for_offset(offset: Vector2) -> int:
	var raw := floori((offset.angle() + PI) / (TAU / 8.0))
	return (raw % 8 + 8) % 8
