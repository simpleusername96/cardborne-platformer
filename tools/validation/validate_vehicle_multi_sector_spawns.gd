extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Registry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")

const FIXED_SEED := 0xC4A2B0
const SEED_FIXTURES := 16

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in Registry.FIELD_IDS:
		_validate_field(field_id)
	_finish()


func _validate_field(field_id: StringName) -> void:
	var definition := Registry.definition(field_id)
	var canonical_player := Vector2(definition["player_start"])
	var visible := Rect2(canonical_player - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
	for seed_offset in SEED_FIXTURES:
		var layout := Generator.generate(FIXED_SEED + seed_offset, CombatStages.STAGE_IDS, field_id)
		_expect(layout != null, "%s seed %d generates a layout" % [field_id, seed_offset])
		if layout == null:
			continue
		for stage_id in CombatStages.STAGE_IDS:
			var tactical = layout.tactical_layout(stage_id)
			var packet: Dictionary = CombatStages.definition(stage_id, definition)["packets"][1]
			var context := "%s %s seed %d" % [field_id, stage_id, seed_offset]
			_validate_packet(packet, tactical, canonical_player, visible, context)
			_validate_patterns(CombatStages.definition(stage_id, definition)["packets"], String(stage_id))
			if seed_offset == 0:
				_validate_field_edges(packet, tactical, context)


func _validate_patterns(packets: Array, context: String) -> void:
	_expect(StringName(packets[0].get("engagement_pattern", &"")) == &"none", "%s opening singleton has no gate pattern" % context)
	for packet in packets.slice(1):
		_expect(StringName(packet.get("engagement_pattern", &"")) == &"broad_crescent", "%s multi-window packet declares its first pattern" % context)
		var expected_patterns: Array[StringName] = []
		for window_index in int(packet.get("arrival_windows", 3)):
			expected_patterns.append(
				&"two_offset_streams" if window_index % 3 == 1 else &"broad_crescent"
			)
		_expect(Array(packet.get("engagement_patterns", [])) == expected_patterns, "%s keeps the locked window pattern sequence" % context)


func _validate_packet(packet: Dictionary, tactical, player_position: Vector2, visible_world: Rect2, context: String) -> void:
	var allocator := Allocator.new()
	allocator.configure(tactical.encounter_seed, tactical.ordinary_spawn_anchors, tactical.geometry_snapshot)
	var allocations := allocator.allocate(packet, player_position, visible_world)
	var replay_allocator := Allocator.new()
	replay_allocator.configure(tactical.encounter_seed, tactical.ordinary_spawn_anchors, tactical.geometry_snapshot)
	var replay := replay_allocator.allocate(packet, player_position, visible_world)
	_expect(var_to_str(allocations) == var_to_str(replay), "%s is deterministic" % context)
	_expect(allocations.size() == 12, "%s allocates twelve logical squads" % context)
	var moving_allocator := Allocator.new()
	moving_allocator.configure(
		tactical.encounter_seed,
		tactical.ordinary_spawn_anchors,
		tactical.geometry_snapshot
	)
	var moving := moving_allocator.allocate_window(
		packet,
		0,
		player_position,
		visible_world,
		[],
		[],
		Vector2(240.0, 0.0)
	)
	_expect(
		not moving.is_empty()
			and int(Array(moving[0]["unit_sectors"])[0]) == 4,
		"%s starts moving-right arrivals in the forward sector" % context
	)
	if moving.size() >= 2:
		var second_sector := int(Array(moving[1]["unit_sectors"])[0])
		var second_offset := posmod(second_sector - 4, 8)
		var second_distance := mini(second_offset, 8 - second_offset)
		var moving_sectors := {}
		for allocation in moving:
			for sector in Array(allocation["unit_sectors"]):
				moving_sectors[int(sector)] = true
		_expect(
			second_distance in [1, 2]
				and second_sector != 0
				and moving_sectors.has(0),
			"%s gives one extra request to a forward/lateral sector before retaining later rear pressure"
			% context
		)
	var positions_by_window := {}
	var histograms := {}
	var packet_histogram := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
	for allocation in allocations:
		var window := int(allocation["arrival_window"])
		if not positions_by_window.has(window):
			positions_by_window[window] = []
			histograms[window] = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
		var histogram: PackedInt32Array = histograms[window]
		var positions: Array = allocation["unit_positions"]
		var sectors: Array = allocation["unit_sectors"]
		for index in positions.size():
			var position := Vector2(positions[index])
			for previous in positions_by_window[window]:
				_expect(position.distance_to(previous) >= 320.0 - 0.001, "%s keeps the window hard floor" % context)
			positions_by_window[window].append(position)
			histogram[int(sectors[index])] += 1
			packet_histogram[int(sectors[index])] += 1
	for window in histograms:
		var histogram: PackedInt32Array = histograms[window]
		var minimum := 0x7fffffff
		var maximum := 0
		var used := 0
		for count in histogram:
			minimum = mini(minimum, count)
			maximum = maxi(maximum, count)
			if count > 0:
				used += 1
		_expect(used == mini(8, Array(positions_by_window[window]).size()), "%s window %d maximizes canonical sector coverage" % [context, window])
		_expect(maximum - minimum <= 1, "%s window %d balances sector counts" % [context, window])
	var packet_used := 0
	for count in packet_histogram:
		if count > 0:
			packet_used += 1
	_expect(packet_used == 8, "%s packet covers all canonical sectors" % context)


func _validate_field_edges(packet: Dictionary, tactical, context: String) -> void:
	var world_rect: Rect2 = tactical.geometry_snapshot.world_rect
	var inset := Vector2(220.0, 220.0)
	var points: Array[Vector2] = [
		world_rect.position + inset,
		Vector2(world_rect.end.x - inset.x, world_rect.position.y + inset.y),
		Vector2(world_rect.position.x + inset.x, world_rect.end.y - inset.y),
		world_rect.end - inset,
	]
	for point_index in points.size():
		var player_position := points[point_index]
		var visible := Rect2(player_position - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
		var allocator := Allocator.new()
		allocator.configure(tactical.encounter_seed, tactical.ordinary_spawn_anchors, tactical.geometry_snapshot)
		var allocations := allocator.allocate_window(packet, 0, player_position, visible)
		if allocations.is_empty():
			continue
		var sectors := {}
		var positions: Array[Vector2] = []
		for allocation in allocations:
			for index in Array(allocation["unit_positions"]).size():
				var position := Vector2(allocation["unit_positions"][index])
				sectors[int(allocation["unit_sectors"][index])] = true
				_expect(position.distance_to(player_position) >= 900.0 - 0.001, "%s edge %d preserves player distance" % [context, point_index])
				_expect(not visible.grow(220.0).has_point(position), "%s edge %d stays offscreen" % [context, point_index])
				for previous in positions:
					_expect(position.distance_to(previous) >= 320.0 - 0.001, "%s edge %d preserves hard floor" % [context, point_index])
				positions.append(position)
		_expect(sectors.size() >= 2, "%s edge %d uses at least two safe sectors" % [context, point_index])


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_MULTI_SECTOR_SPAWNS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
