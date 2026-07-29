extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Registry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

const FIXED_SEED := 0xC4A2B0
const SEED_FIXTURES := 16

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in Registry.FIELD_IDS:
		_validate_field(field_id)
	_finish()


func _validate_field(field_id: StringName) -> void:
	var field_definition := Registry.definition(field_id)
	var player_position := Vector2(field_definition["player_start"])
	var visible_world := Rect2(
		player_position - Vector2(640.0, 360.0),
		Vector2(1280.0, 720.0)
	)
	for seed_offset in SEED_FIXTURES:
		var layout := Generator.generate(
			FIXED_SEED + seed_offset,
			CombatStages.STAGE_IDS,
			field_id
		)
		_expect(layout != null, "%s seed %d generates a layout" % [field_id, seed_offset])
		if layout == null:
			continue
		for stage_id in CombatStages.STAGE_IDS:
			var tactical := layout.tactical_layout(stage_id)
			var packets: Array = CombatStages.definition(stage_id, field_definition)["packets"]
			for packet_index in range(1, packets.size()):
				var packet: Dictionary = packets[packet_index]
				var context := "%s %s seed %d packet %d" % [
					field_id, stage_id, seed_offset, packet_index + 1
				]
				_validate_packet(
					packet,
					tactical.encounter_seed,
					tactical.ordinary_spawn_anchors,
					player_position,
					visible_world,
					context
				)
			if seed_offset == 0:
				_validate_runtime(packets[1], tactical.ordinary_spawn_anchors, player_position, visible_world, field_id, stage_id)


func _validate_packet(
	packet: Dictionary,
	encounter_seed: int,
	anchors: Array[Vector2],
	player_position: Vector2,
	visible_world: Rect2,
	context: String
) -> void:
	_expect(
		StringName(packet.get("arrival_mode", &"")) == Allocator.ARRIVAL_MULTI_SECTOR,
		"%s uses multi-sector arrival" % context
	)
	var allocator := Allocator.new()
	allocator.configure(encounter_seed, anchors)
	var allocations := allocator.allocate(packet, player_position, visible_world)
	var replay_allocator := Allocator.new()
	replay_allocator.configure(encounter_seed, anchors)
	var replay := replay_allocator.allocate(packet, player_position, visible_world)
	_expect(var_to_str(allocations) == var_to_str(replay), "%s is deterministic" % context)
	_expect(allocations.size() == 12, "%s allocates twelve squads" % context)
	var quadrants := {}
	var sectors := {}
	var packs := {}
	var population_by_sector := PackedInt32Array()
	population_by_sector.resize(8)
	var total_population := 0
	for allocation in allocations:
		var pack := int(allocation["pack_index"])
		if not packs.has(pack):
			packs[pack] = []
		packs[pack].append(allocation)
		quadrants[int(allocation["quadrant"])] = true
		var sector := int(allocation["sector"])
		sectors[sector] = true
		var population := Array(allocation["roles"]).size()
		population_by_sector[sector] += population
		total_population += population
		_expect(bool(allocation["outside_visible_margin"]), "%s stays outside the cue margin" % context)
		_expect(
			float(allocation["player_distance"]) >= Allocator.MIN_PLAYER_DISTANCE
				and float(allocation["player_distance"]) <= Allocator.MAX_PLAYER_DISTANCE,
			"%s stays inside the fair spawn ring" % context
		)
	_expect(packs.size() == 4, "%s forms four packs" % context)
	_expect(quadrants.size() == 4, "%s covers four quadrants" % context)
	_expect(sectors.size() >= 4, "%s covers at least four sectors" % context)
	for entries in packs.values():
		var pack_entries: Array = entries
		_expect(pack_entries.size() == 3, "%s keeps three squads per pack" % context)
		var pack_anchors := {}
		for entry in pack_entries:
			pack_anchors[Vector2(entry["anchor"])] = true
		_expect(pack_anchors.size() == 1, "%s gives each pack one readable cue anchor" % context)
	for sector in 8:
		var share := float(population_by_sector[sector]) / float(maxi(1, total_population))
		var adjacent_share := float(
			population_by_sector[sector] + population_by_sector[(sector + 1) % 8]
		) / float(maxi(1, total_population))
		_expect(share <= 0.35, "%s keeps each sector at or below 35%%" % context)
		_expect(adjacent_share <= 0.55, "%s keeps adjacent sectors at or below 55%%" % context)


func _validate_runtime(
	source_packet: Dictionary,
	anchors: Array[Vector2],
	player_position: Vector2,
	visible_world: Rect2,
	field_id: StringName,
	stage_id: StringName
) -> void:
	var packet := source_packet.duplicate(true)
	packet["trigger"] = {"kind":&"time", "at":0.0}
	var runtime := Runtime.new()
	runtime.configure(stage_id, [packet], RunDifficulty.HARD, anchors, FIXED_SEED)
	var cue_count := 0
	var maximum_spawns := 0
	for _step in 48:
		var result := runtime.tick(0.1, 0, [], player_position, visible_world)
		cue_count += Array(result["cues"]).size()
		maximum_spawns = maxi(maximum_spawns, Array(result["spawns"]).size())
	var context := "%s %s runtime" % [field_id, stage_id]
	_expect(cue_count == 4, "%s coalesces one cue per pack" % context)
	_expect(maximum_spawns <= Runtime.MAX_SPAWNS_PER_TICK, "%s dequeues at most four units per tick" % context)
	_expect(float(packet["cue_lead"]) >= 0.9, "%s preserves the cue lead contract" % context)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_MULTI_SECTOR_SPAWNS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
