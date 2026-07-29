extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")

const FIXED_SEED := 0xC4A2B0
const VISIBLE_WORLD := Rect2(2160, 1340, 1280, 720)

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS)
	_expect(layout != null, "fixed layout exists for allocation validation")
	if layout == null:
		_finish()
		return
	for stage_id in Catalog.STAGE_IDS:
		var tactical := layout.tactical_layout(stage_id)
		var packet: Dictionary = Catalog.packets(stage_id)[1]
		_expect(not packet.has("anchor"), "%s keeps spatial allocation out of stage content" % stage_id)
		var allocator := Allocator.new()
		allocator.configure(tactical.encounter_seed, tactical.ordinary_spawn_anchors)
		var allocations := allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		var second := allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		var replay_allocator := Allocator.new()
		replay_allocator.configure(tactical.encounter_seed, tactical.ordinary_spawn_anchors)
		var replay := replay_allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		_expect(var_to_str(allocations) == var_to_str(replay), "%s allocation replays from the same seed" % stage_id)
		_validate_four_pack_allocation(allocations, packet, stage_id)
		_validate_role_multiset(allocations, packet, stage_id)
		_validate_rotation(allocations, second, stage_id)
	_finish()


func _validate_four_pack_allocation(
	allocations: Array[Dictionary],
	packet: Dictionary,
	stage_id: StringName
) -> void:
	_expect(allocations.size() == 12, "%s allocates all twelve surge squads" % stage_id)
	var packs := {}
	var quadrants := {}
	var sectors := {}
	var sector_population := PackedInt32Array()
	sector_population.resize(8)
	var total_population := 0
	for allocation in allocations:
		var pack_index := int(allocation["pack_index"])
		if not packs.has(pack_index):
			packs[pack_index] = []
		packs[pack_index].append(allocation)
		quadrants[int(allocation["quadrant"])] = true
		var sector := int(allocation["sector"])
		sectors[sector] = true
		var roles: Array = allocation["roles"]
		sector_population[sector] += roles.size()
		total_population += roles.size()
		_expect(float(allocation["player_distance"]) >= Allocator.MIN_PLAYER_DISTANCE, "%s keeps packs outside the inner ring" % stage_id)
		_expect(bool(allocation["outside_visible_margin"]), "%s prefers packs beyond the visible margin" % stage_id)
		_expect(roles.size() >= 4 and roles.size() <= 8, "%s preserves squad size bounds" % stage_id)
		_expect(
			roles.any(func(role: StringName) -> bool: return role in Allocator.PURSUIT_ROLES),
			"%s gives every squad a pursuit-capable role" % stage_id
		)
		_expect(
			roles.filter(func(role: StringName) -> bool: return role in Allocator.PROJECTILE_FIRING_ARCHETYPES).size() <= 2,
			"%s limits direct projectile roles per squad" % stage_id
		)
	_expect(packs.size() == 4, "%s allocates exactly four packs" % stage_id)
	_expect(quadrants.size() == 4, "%s occupies all four quadrants" % stage_id)
	_expect(sectors.size() >= 4, "%s occupies at least four of eight sectors" % stage_id)
	for entries in packs.values():
		var pack_entries: Array = entries
		_expect(pack_entries.size() == 3, "%s assigns three squads to each pack" % stage_id)
		var anchors := {}
		for entry in pack_entries:
			anchors[Vector2(entry["anchor"])] = true
		_expect(anchors.size() == 1, "%s pack squads share one arrival anchor" % stage_id)
	for population in sector_population:
		_expect(float(population) / float(maxi(1, total_population)) <= 0.35, "%s limits one-sector population to 35%%" % stage_id)
	for sector in 8:
		var adjacent := sector_population[sector] + sector_population[(sector + 1) % 8]
		_expect(float(adjacent) / float(maxi(1, total_population)) <= 0.55, "%s limits adjacent-sector population to 55%%" % stage_id)


func _validate_role_multiset(
	allocations: Array[Dictionary],
	packet: Dictionary,
	stage_id: StringName
) -> void:
	var authored: Array[StringName] = []
	var allocated: Array[StringName] = []
	for squad in packet["squads"]:
		for role in squad:
			authored.append(StringName(role))
	for allocation in allocations:
		for role in allocation["roles"]:
			allocated.append(StringName(role))
	authored.sort()
	allocated.sort()
	_expect(authored == allocated, "%s allocation preserves the authored role multiset" % stage_id)


func _validate_rotation(
	first: Array[Dictionary],
	second: Array[Dictionary],
	stage_id: StringName
) -> void:
	var first_largest_quadrant := _largest_pack_quadrant(first)
	var second_first_quadrant := int(second[0]["quadrant"]) if not second.is_empty() else -1
	_expect(
		first_largest_quadrant != second_first_quadrant,
		"%s rotates the next leading pack away from the previous largest quadrant" % stage_id
	)


func _largest_pack_quadrant(allocations: Array[Dictionary]) -> int:
	var populations := {}
	var quadrant_by_pack := {}
	for allocation in allocations:
		var pack := int(allocation["pack_index"])
		populations[pack] = int(populations.get(pack, 0)) + Array(allocation["roles"]).size()
		quadrant_by_pack[pack] = int(allocation["quadrant"])
	var largest_pack := 0
	for pack in populations:
		if int(populations[pack]) > int(populations.get(largest_pack, -1)):
			largest_pack = int(pack)
	return int(quadrant_by_pack.get(largest_pack, -1))


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
