extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Registry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

const FIXED_SEED := 0xC4A2B0
const SEED_FIXTURES := 48
const STAGE_IDS: Array[StringName] = [&"stage_1"]
const EXPECTED_BASE_SIZES := [3, 3, 3, 3, 3, 4, 4, 4]
const EXPECTED_CONTINGENCY_SIZES := [5, 4, 4, 5, 4, 5, 5, 4]
const CONTINGENCY_ADDITIONS := [2, 1, 1, 2, 1, 1, 1, 0]

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in Registry.FIELD_IDS:
		_validate_field(field_id)
	_finish()


func _validate_field(field_id: StringName) -> void:
	var field_definition := Registry.definition(field_id)
	var production_packet: Dictionary = CombatStages.definition(
		&"stage_1", field_definition
	)["packets"][1]
	_expect(
		StringName(production_packet.get("arrival_mode", &"")) == Allocator.ARRIVAL_HORDE_FRONT,
		"%s Stage 1 production packet selects horde-front allocation" % field_id
	)
	_expect(
		_squad_sizes(production_packet) == EXPECTED_BASE_SIZES,
		"%s production B keeps the 3,3,3,3,3,4,4,4 squad sizes" % field_id
	)
	var baseline_packet := production_packet.duplicate(true)
	baseline_packet.erase("arrival_mode")
	var contingency_packet := _contingency_packet(production_packet)
	for seed_offset in SEED_FIXTURES:
		var layout := Generator.generate(
			FIXED_SEED + seed_offset, STAGE_IDS, field_id
		)
		_expect(
			layout != null,
			"%s seed fixture %d generates a Stage 1 layout" % [field_id, seed_offset]
		)
		if layout == null:
			continue
		var tactical := layout.tactical_layout(&"stage_1")
		var player_position := Vector2(field_definition["player_start"])
		var visible_world := Rect2(
			player_position - Vector2(640.0, 360.0),
			Vector2(1280.0, 720.0)
		)
		var context := "%s seed %d" % [field_id, seed_offset]
		var baseline := _allocate(
			baseline_packet,
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			player_position,
			visible_world
		)
		var production := _allocate(
			production_packet,
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			player_position,
			visible_world
		)
		var replay := _allocate(
			production_packet,
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			player_position,
			visible_world
		)
		var contingency := _allocate(
			contingency_packet,
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			player_position,
			visible_world
		)
		var contingency_replay := _allocate(
			contingency_packet,
			tactical.encounter_seed,
			tactical.ordinary_spawn_anchors,
			player_position,
			visible_world
		)
		_validate_a(baseline_packet, baseline, context)
		_validate_b(production_packet, production, replay, player_position, context)
		_validate_c(
			production_packet,
			contingency_packet,
			contingency,
			contingency_replay,
			player_position,
			context
		)
		if seed_offset == 0:
			var baseline_trace := _runtime_trace(
				baseline_packet,
				tactical.encounter_seed,
				tactical.ordinary_spawn_anchors,
				player_position,
				visible_world
			)
			var production_trace := _runtime_trace(
				production_packet,
				tactical.encounter_seed,
				tactical.ordinary_spawn_anchors,
				player_position,
				visible_world
			)
			var contingency_trace := _runtime_trace(
				contingency_packet,
				tactical.encounter_seed,
				tactical.ordinary_spawn_anchors,
				player_position,
				visible_world
			)
			_expect(
				Array(baseline_trace["cues"]).size() == 8,
				"%s A emits eight distributed squad cues" % context
			)
			_expect(
				Array(production_trace["cues"]).size() == 2,
				"%s B emits two horde-front cues" % context
			)
			_expect(
				Array(contingency_trace["cues"]).size() == 2,
				"%s C emits two horde-front cues" % context
			)
			_validate_spawn_fan(production_trace, 27, "%s B" % context)
			_validate_spawn_fan(contingency_trace, 36, "%s C" % context)


func _validate_a(packet: Dictionary, allocations: Array[Dictionary], context: String) -> void:
	_expect(_unit_count(packet) == 27, "%s A keeps 27 authored units" % context)
	_expect(allocations.size() == 8, "%s A allocates eight squads" % context)
	_expect(_unique_anchor_count(allocations) == 8, "%s A uses eight distinct anchors" % context)
	var groups := _grouped_allocations(allocations)
	_expect(groups.size() == 4, "%s A has four distributed groups" % context)
	for group in groups.values():
		_expect(Array(group).size() == 2, "%s A assigns two squads per group" % context)
	_expect(
		_sorted_roles(packet) == _sorted_allocated_roles(allocations),
		"%s A preserves the authored role multiset" % context
	)


func _validate_b(
	packet: Dictionary,
	allocations: Array[Dictionary],
	replay: Array[Dictionary],
	player_position: Vector2,
	context: String
) -> void:
	_expect(_unit_count(packet) == 27, "%s B keeps 27 authored units" % context)
	_validate_horde_contract(
		packet, allocations, replay, player_position, [12, 15], context, "B"
	)


func _validate_horde_contract(
	packet: Dictionary,
	allocations: Array[Dictionary],
	replay: Array[Dictionary],
	player_position: Vector2,
	expected_populations: Array,
	context: String,
	label: String
) -> void:
	_expect(
		allocations.size() == 8,
		"%s %s allocates eight authored squads" % [context, label]
	)
	_expect(
		var_to_str(allocations) == var_to_str(replay),
		"%s %s replays deterministically" % [context, label]
	)
	_expect(
		_unique_anchor_count(allocations) == 2,
		"%s %s uses two front anchors" % [context, label]
	)
	var fronts := _grouped_allocations(allocations)
	_expect(
		fronts.size() == 2,
		"%s %s has exactly two fronts" % [context, label]
	)
	var populations: Array[int] = []
	var front_anchors: Array[Vector2] = []
	for front in fronts.values():
		var entries: Array = front
		_expect(
			entries.size() == 4,
			"%s %s assigns four squads per front" % [context, label]
		)
		var anchors := {}
		var population := 0
		for allocation in entries:
			var anchor := Vector2(allocation["anchor"])
			anchors[anchor] = true
			population += Array(allocation["roles"]).size()
			_expect(
				bool(allocation["outside_visible_margin"]),
				"%s %s keeps every front outside the visible margin" % [context, label]
			)
			_expect(
				float(allocation["player_distance"]) >= Allocator.MIN_PLAYER_DISTANCE
				and float(allocation["player_distance"]) <= Allocator.MAX_PLAYER_DISTANCE,
				"%s %s prefers the validated player-distance ring" % [context, label]
			)
		_expect(
			anchors.size() == 1,
			"%s %s front squads share one anchor" % [context, label]
		)
		if anchors.size() == 1:
			front_anchors.append(Vector2(anchors.keys()[0]))
		populations.append(population)
	populations.sort()
	_expect(
		populations == expected_populations,
		"%s %s presents the expected front populations" % [context, label]
	)
	if front_anchors.size() == 2:
		var first_direction := (front_anchors[0] - player_position).angle()
		var second_direction := (front_anchors[1] - player_position).angle()
		_expect(
			absf(angle_difference(first_direction, second_direction))
			>= Allocator.HORDE_FRONT_MIN_SEPARATION - 0.001,
			"%s %s prefers fronts separated by at least 90 degrees" % [context, label]
		)
	_expect(
		_sorted_roles(packet) == _sorted_allocated_roles(allocations),
		"%s %s preserves the authored role multiset" % [context, label]
	)


func _validate_c(
	base_packet: Dictionary,
	packet: Dictionary,
	allocations: Array[Dictionary],
	replay: Array[Dictionary],
	player_position: Vector2,
	context: String
) -> void:
	_expect(_unit_count(packet) == 36, "%s C reaches 36 test-only units" % context)
	_expect(
		_squad_sizes(packet) == EXPECTED_CONTINGENCY_SIZES,
		"%s C uses the bounded 5,4,4,5,4,5,5,4 squad sizes" % context
	)
	_validate_horde_contract(
		packet, allocations, replay, player_position, [18, 18], context, "C"
	)
	var base_roles := _sorted_roles(base_packet)
	var contingency_roles := _sorted_roles(packet)
	for role in base_roles:
		contingency_roles.erase(role)
	_expect(contingency_roles.size() == 9, "%s C adds exactly nine roles" % context)
	for role in contingency_roles:
		_expect(StringName(role) == &"scrap_drone", "%s C only adds scrap drones" % context)
		_expect(
			float(EnemyArchetypes.definition(StringName(role))["health"]) <= 18.0,
			"%s C additions remain low-health swarm units" % context
		)


func _contingency_packet(base_packet: Dictionary) -> Dictionary:
	var result := base_packet.duplicate(true)
	for squad_index in CONTINGENCY_ADDITIONS.size():
		for _addition in CONTINGENCY_ADDITIONS[squad_index]:
			result["squads"][squad_index].append(&"scrap_drone")
	result["id"] = "%s_test_only_36" % String(base_packet["id"])
	return result


func _allocate(
	packet: Dictionary,
	seed: int,
	anchors: Array[Vector2],
	player_position: Vector2,
	visible_world: Rect2
) -> Array[Dictionary]:
	var allocator := Allocator.new()
	allocator.configure(seed, anchors)
	return allocator.allocate(packet, player_position, visible_world)


func _runtime_trace(
	packet: Dictionary,
	seed: int,
	anchors: Array[Vector2],
	player_position: Vector2,
	visible_world: Rect2
) -> Dictionary:
	var fixture := packet.duplicate(true)
	fixture["trigger"] = {"kind":&"time", "at":0.0}
	var runtime := Runtime.new()
	runtime.configure(&"stage_1", [fixture], RunDifficulty.HARD, anchors, seed)
	var cues: Array[Dictionary] = []
	var spawns: Array[Dictionary] = []
	for step in 400:
		var delta := 0.0 if step == 0 else 0.02
		var result := runtime.tick(delta, 0, [], player_position, visible_world)
		cues.append_array(result["cues"])
		spawns.append_array(result["spawns"])
		if spawns.size() == _unit_count(fixture) and runtime.debug_snapshot()["queued_spawns"] == 0:
			break
	return {"cues":cues, "spawns":spawns}


func _validate_spawn_fan(trace: Dictionary, expected_count: int, context: String) -> void:
	var spawns: Array = trace["spawns"]
	_expect(spawns.size() == expected_count, "%s schedules every runtime spawn" % context)
	var positions := {}
	for spec in spawns:
		positions[Vector2(spec["pos"])] = true
	_expect(
		positions.size() == expected_count,
		"%s gives every shared-anchor unit a distinct initial fan position" % context
	)


func _grouped_allocations(allocations: Array[Dictionary]) -> Dictionary:
	var groups := {}
	for allocation in allocations:
		var group_index := int(allocation["group_index"])
		if not groups.has(group_index):
			groups[group_index] = []
		groups[group_index].append(allocation)
	return groups


func _unique_anchor_count(allocations: Array[Dictionary]) -> int:
	var anchors := {}
	for allocation in allocations:
		anchors[Vector2(allocation["anchor"])] = true
	return anchors.size()


func _unit_count(packet: Dictionary) -> int:
	var result := 0
	for squad in packet["squads"]:
		result += Array(squad).size()
	return result


func _squad_sizes(packet: Dictionary) -> Array:
	var result := []
	for squad in packet["squads"]:
		result.append(Array(squad).size())
	return result


func _sorted_roles(packet: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for squad in packet["squads"]:
		for role in squad:
			result.append(StringName(role))
	result.sort()
	return result


func _sorted_allocated_roles(allocations: Array[Dictionary]) -> Array[StringName]:
	var result: Array[StringName] = []
	for allocation in allocations:
		for role in allocation["roles"]:
			result.append(StringName(role))
	result.sort()
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_HORDE_FRONTS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
