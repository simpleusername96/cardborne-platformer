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
		var packet: Dictionary = Catalog.packets(stage_id)[1]
		_expect(not packet.has("anchor"), "%s keeps spatial allocation out of stage content" % stage_id)
		var allocator := Allocator.new()
		allocator.configure(layout.encounter_seed(stage_id), layout.ordinary_spawn_anchors)
		var allocations := allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		var second_allocations := allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		var replay_allocator := Allocator.new()
		replay_allocator.configure(layout.encounter_seed(stage_id), layout.ordinary_spawn_anchors)
		var replay := replay_allocator.allocate(packet, Catalog.player_start(), VISIBLE_WORLD)
		_expect(var_to_str(allocations) == var_to_str(replay), "%s allocation replays from the same seed" % stage_id)
		_expect(allocations.size() == 8, "%s allocates all eight surge squads" % stage_id)
		var unique_anchors := {}
		var original_roles: Array[StringName] = []
		var allocated_roles: Array[StringName] = []
		for squad in packet["squads"]:
			for role in squad:
				original_roles.append(StringName(role))
		for allocation in allocations:
			var anchor := Vector2(allocation["anchor"])
			unique_anchors[anchor] = true
			_expect(float(allocation["player_distance"]) >= 960.0, "%s keeps surge arrivals away from the player" % stage_id)
			_expect(bool(allocation["outside_visible_margin"]), "%s prefers arrivals beyond the visible margin" % stage_id)
			var roles: Array = allocation["roles"]
			_expect(roles.size() <= 5, "%s keeps one cue at five units or fewer" % stage_id)
			_expect(
				roles.any(func(role: StringName) -> bool: return role in Allocator.PURSUIT_ROLES),
				"%s gives every squad a mobile pressure role" % stage_id
			)
			_expect(
				roles.filter(func(role: StringName) -> bool: return role in Allocator.PROJECTILE_FIRING_ARCHETYPES).size() <= 2,
				"%s limits direct projectile roles per squad" % stage_id
			)
			for role in roles:
				allocated_roles.append(StringName(role))
		_expect(unique_anchors.size() == 8, "%s uses eight distinct anchors when the pool permits" % stage_id)
		var two_wave_anchors := unique_anchors.duplicate()
		for allocation in second_allocations:
			two_wave_anchors[Vector2(allocation["anchor"])] = true
		_expect(
			two_wave_anchors.size() >= 14,
			"%s distributes consecutive arrivals across the enlarged field" % stage_id
		)
		original_roles.sort()
		allocated_roles.sort()
		_expect(original_roles == allocated_roles, "%s preserves the authored role multiset" % stage_id)
		_validate_group_arcs(allocations, Catalog.player_start(), stage_id)
	_finish()


func _validate_group_arcs(
	allocations: Array[Dictionary],
	player_position: Vector2,
	stage_id: StringName
) -> void:
	var groups := {}
	for allocation in allocations:
		var group_index := int(allocation["group_index"])
		if not groups.has(group_index):
			groups[group_index] = []
		groups[group_index].append(Vector2(allocation["anchor"]))
	for group in groups.values():
		_expect(Array(group).size() <= 2, "%s early surge groups use at most two sectors" % stage_id)
		if Array(group).size() == 2:
			var first_angle := (Vector2(group[0]) - player_position).angle()
			var second_angle := (Vector2(group[1]) - player_position).angle()
			_expect(
				absf(angle_difference(first_angle, second_angle)) <= deg_to_rad(135.0) + 0.001,
				"%s early surge group remains inside a 135-degree arc" % stage_id
			)


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
