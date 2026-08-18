extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS)
	_expect(layout != null, "fixed layout exists for allocation validation")
	if layout == null:
		_finish()
		return
	for stage_id in Catalog.STAGE_IDS:
		var tactical = layout.tactical_layout(stage_id)
		var packets := Catalog.packets(stage_id)
		var packet: Dictionary = packets[1]
		var player_position: Vector2 = tactical.geometry_snapshot.player_start
		var visible_world := Rect2(player_position - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
		var direct_allocator := Allocator.new()
		direct_allocator.configure(
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			tactical.geometry_snapshot
		)
		var allocator := Allocator.new()
		allocator.configure(
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			tactical.geometry_snapshot
		)
		allocator.prewarm_for_packets(packets)
		var allocations: Array[Dictionary] = []
		for packet_index in packets.size():
			var comparison_packet: Dictionary = packets[packet_index]
			var direct := direct_allocator.allocate(
				comparison_packet,
				player_position,
				visible_world
			)
			var prewarmed := allocator.allocate(
				comparison_packet,
				player_position,
				visible_world
			)
			_expect(
				var_to_str(prewarmed) == var_to_str(direct),
				"%s packet %d prewarmed allocation matches direct geometry truth"
				% [stage_id, packet_index]
			)
			if packet_index == 1:
				allocations = prewarmed
		_validate_unit_allocation(allocations, packet, tactical.geometry_snapshot, player_position, visible_world, String(stage_id))
		_validate_role_multiset(allocations, packet, String(stage_id))
		_validate_role_distances(allocations, player_position, String(stage_id))
	_finish()


func _validate_unit_allocation(
	allocations: Array[Dictionary],
	packet: Dictionary,
	geometry,
	player_position: Vector2,
	visible_world: Rect2,
	context: String
) -> void:
	_expect(allocations.size() == 12, "%s allocates all twelve logical squads" % context)
	var all_positions: Array[Vector2] = []
	var positions_by_window := {}
	var sectors_by_window := {}
	var first_sectors_by_window := {}
	for allocation in allocations:
		_expect(not allocation.has("pack_index"), "%s retires pack ownership" % context)
		var roles: Array = allocation.get("roles", [])
		var positions: Array = allocation.get("unit_positions", [])
		var sectors: Array = allocation.get("unit_sectors", [])
		_expect(positions.size() == roles.size(), "%s gives every role an independent birth position" % context)
		_expect(sectors.size() == roles.size(), "%s records every unit birth sector" % context)
		var window := int(allocation.get("arrival_window", -1))
		if not sectors_by_window.has(window):
			sectors_by_window[window] = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
			first_sectors_by_window[window] = {}
			positions_by_window[window] = []
		var histogram: PackedInt32Array = sectors_by_window[window]
		if not sectors.is_empty():
			first_sectors_by_window[window][int(sectors[0])] = true
		for index in positions.size():
			var position := Vector2(positions[index])
			var distance := position.distance_to(player_position)
			_expect(distance >= Allocator.MIN_PLAYER_DISTANCE - 0.001, "%s keeps birth outside 900px" % context)
			_expect(distance <= Allocator.RELAXED_MAX_PLAYER_DISTANCE + 0.001, "%s keeps birth inside T3 maximum" % context)
			_expect(not visible_world.grow(Allocator.OFFSCREEN_MARGIN).has_point(position), "%s keeps birth outside the warning margin" % context)
			var role := StringName(roles[index])
			var radius := float(EnemyArchetypes.definition(role)["radius"])
			_expect(geometry.is_spawnable_disc(position, radius), "%s uses walkable birth geometry" % context)
			histogram[int(sectors[index])] += 1
			for previous in positions_by_window[window]:
				_expect(position.distance_to(previous) >= 320.0 - 0.001, "%s preserves the 320px hard floor" % context)
			positions_by_window[window].append(position)
			all_positions.append(position)
	for window in sectors_by_window:
		var histogram: PackedInt32Array = sectors_by_window[window]
		var minimum := 0x7fffffff
		var maximum := 0
		var used := 0
		for count in histogram:
			minimum = mini(minimum, count)
			maximum = maxi(maximum, count)
			if count > 0:
				used += 1
		_expect(used == mini(8, Array(positions_by_window[window]).size()), "%s window %d maximizes canonical sector coverage" % [context, window])
		_expect(maximum - minimum <= 1, "%s window %d balances sector population" % [context, window])
		_expect(
			Dictionary(first_sectors_by_window[window]).size()
				== mini(int(packet.get("squads_per_window", 4)), Array(positions_by_window[window]).size()),
			"%s window %d spreads its cue births" % [context, window]
		)
	var packet_sectors := {}
	for histogram_value in sectors_by_window.values():
		var histogram: PackedInt32Array = histogram_value
		for sector_index in histogram.size():
			if histogram[sector_index] > 0:
				packet_sectors[sector_index] = true
	_expect(packet_sectors.size() == 8, "%s packet uses all eight canonical sectors" % context)
	var authored_units := 0
	for squad in packet["squads"]:
		authored_units += Array(squad).size()
	_expect(all_positions.size() == authored_units, "%s allocates the complete authored population" % context)


func _validate_role_multiset(allocations: Array[Dictionary], packet: Dictionary, context: String) -> void:
	var authored: Array[StringName] = []
	var allocated: Array[StringName] = []
	for squad in packet["squads"]:
		for role in squad:
			authored.append(StringName(role))
	for allocation in allocations:
		for role in allocation.get("roles", []):
			allocated.append(StringName(role))
	authored.sort()
	allocated.sort()
	_expect(authored == allocated, "%s preserves the authored role multiset" % context)


func _validate_role_distances(allocations: Array[Dictionary], player_position: Vector2, context: String) -> void:
	for allocation in allocations:
		var roles: Array = allocation.get("roles", [])
		var lanes: Array = allocation.get("unit_distance_lanes", [])
		_expect(lanes.size() == roles.size(), "%s records every role-aware distance lane" % context)
		for index in roles.size():
			var behavior := StringName(EnemyArchetypes.definition(StringName(roles[index]))["behavior"])
			if behavior in [&"ordinary_edge_01", &"ordinary_pull_01", &"ordinary_fixed_area_01"]:
				_expect(int(lanes[index]) in [1, 2], "%s pursuit selects 1650/2100 role lanes" % context)
			elif behavior in [&"ordinary_lane_01", &"ordinary_gap_01", &"ordinary_growth_01"]:
				_expect(int(lanes[index]) in [0, 1], "%s standoff selects 1200/1650 role lanes" % context)
			elif behavior in [&"ordinary_support_02", &"ordinary_support_01", &"ordinary_support_03"]:
				_expect(int(lanes[index]) == 0, "%s standoff/support selects 1200 role lane" % context)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SPAWN_ALLOCATION_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
