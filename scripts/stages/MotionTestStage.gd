extends StageBase

const EXIT_PORTAL_SCENE: PackedScene = preload("res://scenes/stages/ExitPortal.tscn")
const VIEWPORT_WIDTH := 1280.0
const MAP_WIDTH := 2680.0
const MAP_HEIGHT := 2100.0
const GROUND_Y := 1860.0
const GROUND_TOP := 1840.0
const UPPER_FLOOR_Y := 790.0
const UPPER_FLOOR_TOP := 770.0
const MID_FLOOR_Y := 1220.0
const MID_FLOOR_TOP := 1200.0
const PLAYER_FOOT_OFFSET := 10.0
const MIN_GENERATED_LANDING_WIDTH := 220.0
const MIN_GENERATED_ROUTE_DISTANCE := VIEWPORT_WIDTH * 1.5
const MIN_GENERATED_BODY_GAP := 40.0
const MIN_GENERATED_HEADROOM := 72.0
const GENERATED_GAP_TOLERANCE := 28.0
const GENERATED_LEDGE_TOLERANCE := 24.0
const GENERATED_STITCH_OVERLAP := 18.0
const REQUIRED_VALIDATIONS := [
	"start",
	"timing",
	"dash",
	"climb",
	"combat",
	"destructible",
	"hazard",
	"interaction",
	"generated_start",
	"generated_exit",
]
const VALIDATION_LABELS := {
	"start": "start spawn",
	"timing": "timing lane",
	"dash": "dash gap",
	"climb": "rope climb",
	"combat": "enemy defeated",
	"destructible": "breakable destroyed",
	"hazard": "hazard damage",
	"interaction": "NPC interaction",
	"generated_start": "generated route start",
	"generated_exit": "generated route exit",
}

@export var active_seed: int = 73021
@export var generator_mode: String = "mixed_mini_run"

var world: Node2D
var test_objects: Node2D
var generated_root: Node2D
var generated_spawn: Vector2 = Vector2.ZERO
var route_bounds: Rect2 = Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT)
var route_summary: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _validations: Dictionary = {}
# Route validation reads this registry so decorative fill never counts as support.
var _route_surfaces: Array[Dictionary] = []


func _ready() -> void:
	_reset_validations()
	_ensure_runtime_roots()
	_clear_children(world)
	_clear_children(test_objects)
	_clear_children(generated_root)
	_clear_route_surfaces()
	_set_player_spawn(Vector2(120.0, GROUND_TOP - PLAYER_FOOT_OFFSET))
	_build_authored_route()
	_build_generated_route(active_seed, false)
	_rebuild_fall_reset_zone()
	super._ready()
	_configure_spawned_player()
	_mark_validation("start", false)
	_publish_testbed_context("Clear required checks, then finish the generated seed route.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("regenerate_landscape"):
		get_viewport().set_input_as_handled()
		active_seed = int(Time.get_ticks_msec() % 900000) + 1000
		_build_generated_route(active_seed, true)
	elif event.is_action_pressed("replay_landscape"):
		get_viewport().set_input_as_handled()
		_build_generated_route(active_seed, true)
	elif event.is_action_pressed("reset_testbed"):
		get_viewport().set_input_as_handled()
		respawn_player("manual reset")


func set_checkpoint(checkpoint_id: String, checkpoint_position: Vector2, announce: bool = true) -> void:
	super.set_checkpoint(checkpoint_id, checkpoint_position, announce)
	var validation_id := _validation_for_checkpoint(checkpoint_id)
	if not validation_id.is_empty():
		_mark_validation(validation_id)


func complete_stage() -> void:
	if not bool(route_summary.get("valid", false)):
		SignalBus.status_message_changed.emit("Exit locked: generated route invalid (%s)" % str(route_summary.get("failure_reason", "unknown")))
		SignalBus.testbed_route_status_changed.emit(_route_status_text("invalid"))
		return

	_mark_validation("generated_exit", false)
	if not _is_final_clear_ready():
		SignalBus.status_message_changed.emit("Exit locked: finish %s" % _compact_missing_validation_text())
		SignalBus.testbed_route_status_changed.emit(_route_status_text("locked"))
		return

	super.complete_stage()
	SignalBus.status_message_changed.emit("Testbed clear: checks complete, seed %d replayable" % active_seed)
	SignalBus.testbed_route_status_changed.emit(_route_status_text("clear"))


func _ensure_runtime_roots() -> void:
	world = get_node_or_null("World") as Node2D
	if world == null:
		world = Node2D.new()
		world.name = "World"
		add_child(world)

	test_objects = get_node_or_null("TestObjects") as Node2D
	if test_objects == null:
		test_objects = Node2D.new()
		test_objects.name = "TestObjects"
		add_child(test_objects)

	generated_root = get_node_or_null("GeneratedRoot") as Node2D
	if generated_root == null:
		generated_root = Node2D.new()
		generated_root.name = "GeneratedRoot"
		add_child(generated_root)


func _clear_children(root: Node) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.free()


func _set_player_spawn(spawn_position: Vector2) -> void:
	if player_spawn == null:
		player_spawn = Marker2D.new()
		player_spawn.name = "PlayerSpawn"
		add_child(player_spawn)
	player_spawn.position = spawn_position


func _build_authored_route() -> void:
	var route_plan := _stage01_route_plan()
	route_bounds = route_plan.get("map_bounds", Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT))

	var metrics := RunState.get_testbed_metrics_snapshot()
	var active_metrics: Dictionary = metrics.get("active", {})
	var route_limits: Dictionary = metrics.get("route_limits", {})
	var least_name := str(route_limits.get("least_mobile_profile_name", "unknown"))
	var required_gap := float(route_limits.get("max_required_gap", 210.0))
	var required_ledge := float(route_limits.get("max_required_ledge", 120.0))

	_build_lower_ruins_room_shells(route_plan)

	_add_label(
		world,
		"LOWER RUINS ASCENT\nCompact Stage01 route: lower ruins, shaft, upper combat, seed pocket.",
		Vector2(86.0, 1445.0),
		460.0
	)
	_add_checkpoint(test_objects, "CheckpointStart", Vector2(120.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "start")
	_add_label(
		world,
		"Route metrics\nLeast mobile: %s\nCritical gates stay <= %.0fpx gap / %.0fpx ledge" % [least_name, required_gap, required_ledge],
		Vector2(540.0, 1495.0),
		430.0
	)

	_add_platform(world, "LeftBoundaryWall", Vector2(20.0, MAP_HEIGHT * 0.5), Vector2(40.0, MAP_HEIGHT), Color(0.08, 0.09, 0.10, 1.0))
	_add_platform(world, "RightBoundaryWall", Vector2(MAP_WIDTH - 20.0, MAP_HEIGHT * 0.5), Vector2(40.0, MAP_HEIGHT), Color(0.08, 0.09, 0.10, 1.0))

	_add_terrain_mass(world, "EntranceFloor", Vector2(340.0, GROUND_Y), Vector2(600.0, 40.0), 260.0, Color(0.22, 0.25, 0.29, 1.0), true)
	_add_terrain_mass(world, "LowerCorridorFloor", Vector2(900.0, GROUND_Y), Vector2(520.0, 40.0), 260.0, Color(0.22, 0.25, 0.29, 1.0), true)
	_add_terrain_mass(world, "FirstStep", Vector2(760.0, 1808.0), Vector2(240.0, 28.0), 78.0, Color(0.30, 0.34, 0.39, 1.0))
	_add_walker(test_objects, "IntroWalker", Vector2(520.0, GROUND_TOP), 95.0)
	_add_label(world, "LOWER CORRIDOR\nMovement plus first Walker in real room scale.", Vector2(750.0, 1670.0), 360.0)

	_add_terrain_mass(world, "CoyoteLedge", Vector2(1060.0, 1763.0), Vector2(250.0, 26.0), 92.0, Color(0.28, 0.37, 0.45, 1.0))
	_add_platform(world, "JumpBufferOneWay", Vector2(1260.0, 1717.0), Vector2(280.0, 22.0), Color(0.22, 0.48, 0.56, 1.0), true)
	_add_terrain_mass(world, "TimingRecovery", Vector2(1380.0, GROUND_Y), Vector2(440.0, 40.0), 260.0, Color(0.22, 0.25, 0.29, 1.0), true)
	_add_checkpoint(test_objects, "CheckpointTiming", Vector2(1335.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "timing")
	_add_label(world, "TIMING CHAMBER\nCoyote ledge, buffered jump, one-way drop.", Vector2(1035.0, 1560.0), 430.0)

	_add_terrain_mass(world, "DashPrep", Vector2(1300.0, 1818.0), Vector2(300.0, 28.0), 76.0, Color(0.30, 0.34, 0.39, 1.0))
	_add_terrain_mass(world, "DashLanding", Vector2(1740.0, 1782.0), Vector2(330.0, 28.0), 112.0, Color(0.35, 0.36, 0.45, 1.0))
	_add_checkpoint(test_objects, "CheckpointDashPrep", Vector2(1300.0, 1794.0), "dash_prep")
	_add_checkpoint(test_objects, "CheckpointDashClear", Vector2(1740.0, 1758.0), "dash")
	_add_label(world, "BROKEN BRIDGE\nRequired jump + dash gap folded into lower ruins.", Vector2(1370.0, 1692.0), 480.0)

	_add_terrain_mass(world, "ShaftLower", Vector2(1810.0, GROUND_Y), Vector2(420.0, 40.0), 260.0, Color(0.22, 0.25, 0.29, 1.0), true)
	_add_climbable(test_objects, "RopeClimb", Vector2(1660.0, 1300.0), Vector2(44.0, 1050.0))
	_add_platform(world, "ShaftL1OneWay", Vector2(1500.0, 1635.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_terrain_mass(world, "ShaftL2", Vector2(1820.0, 1455.0), Vector2(260.0, 28.0), 130.0, Color(0.30, 0.34, 0.39, 1.0))
	_add_platform(world, "ShaftL3OneWay", Vector2(1500.0, 1245.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_terrain_mass(world, "ShaftL4", Vector2(1810.0, 1035.0), Vector2(260.0, 28.0), 126.0, Color(0.30, 0.34, 0.39, 1.0))
	_add_terrain_mass(world, "ClimbUpper", Vector2(1610.0, UPPER_FLOOR_Y), Vector2(420.0, 28.0), 112.0, Color(0.30, 0.34, 0.39, 1.0))
	_add_terrain_mass(world, "UpperGallery", Vector2(1970.0, UPPER_FLOOR_Y), Vector2(650.0, 28.0), 112.0, Color(0.29, 0.34, 0.39, 1.0))
	_add_checkpoint(test_objects, "CheckpointClimbPrep", Vector2(1660.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "climb_prep")
	_add_checkpoint(test_objects, "CheckpointClimbClear", Vector2(1610.0, UPPER_FLOOR_TOP - PLAYER_FOOT_OFFSET), "climb")
	_add_label(world, "CENTRAL SHAFT\nRope climb, one-way recovery, upper exit.", Vector2(1410.0, 910.0), 430.0)

	_add_terrain_mass(world, "HighCacheBranch", Vector2(1080.0, 560.0), Vector2(330.0, 26.0), 118.0, Color(0.39, 0.31, 0.47, 1.0))
	_add_platform(world, "HighCacheRejoin", Vector2(1280.0, 690.0), Vector2(220.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_label(world, "OPTIONAL HIGH CACHE\nAssassin double jump / later upgrade branch.", Vector2(900.0, 455.0), 400.0)
	_add_label(world, "WALL TRAVERSAL\nDeferred: not required for this route.", Vector2(1090.0, 705.0), 360.0)

	_add_terrain_mass(world, "CombatHallFloor", Vector2(2200.0, UPPER_FLOOR_Y), Vector2(850.0, 40.0), 120.0, Color(0.22, 0.25, 0.29, 1.0))
	_add_terrain_mass(world, "ShooterLedge", Vector2(2250.0, 635.0), Vector2(260.0, 28.0), 90.0, Color(0.32, 0.34, 0.40, 1.0))
	_add_label(world, "UPPER COMBAT HALL\nWalker, Charger, Shooter, breakable gate.", Vector2(1960.0, 540.0), 500.0)
	_add_checkpoint(test_objects, "CheckpointCombatPrep", Vector2(1840.0, UPPER_FLOOR_TOP - PLAYER_FOOT_OFFSET), "combat_prep")
	_add_leaper(test_objects, "AuthoredLeaper", Vector2(1900.0, UPPER_FLOOR_TOP))
	_add_walker(test_objects, "AuthoredWalker", Vector2(2020.0, UPPER_FLOOR_TOP), 115.0)
	_add_charger(test_objects, "AuthoredCharger", Vector2(2200.0, UPPER_FLOOR_TOP), 125.0)
	_add_shooter(test_objects, "AuthoredShooter", Vector2(2250.0, 621.0))
	_add_shield_guard(test_objects, "AuthoredShieldGuard", Vector2(2380.0, UPPER_FLOOR_TOP), 80.0)
	_add_destructible(test_objects, "BreakableGate", Vector2(2460.0, UPPER_FLOOR_TOP), 3)

	_add_platform(world, "DescentOneWay", Vector2(2420.0, 1010.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_crumbling_platform(world, "OptionalCrumblingStep", Vector2(2160.0, 1010.0), Vector2(210.0, 26.0))
	_add_terrain_mass(world, "MiddleConnectorFloor", Vector2(2200.0, MID_FLOOR_Y), Vector2(760.0, 40.0), 180.0, Color(0.22, 0.25, 0.29, 1.0))
	_add_hazard(test_objects, "SpikeTrench", Vector2(2310.0, MID_FLOOR_TOP - 8.0), Vector2(165.0, 22.0), Vector2(-240.0, -220.0))
	_add_timed_poison_vent(test_objects, "TimedPoisonVent", Vector2(2425.0, MID_FLOOR_TOP - 8.0), Vector2(135.0, 22.0))
	_add_summon_node(test_objects, "SummonNode", Vector2(2180.0, MID_FLOOR_TOP))
	_add_switch_gate(test_objects, "PracticeSwitchGate", Vector2(2545.0, MID_FLOOR_TOP), Vector2(-110.0, 0.0))
	_add_npc(test_objects, "TestNPC", Vector2(2050.0, MID_FLOOR_TOP), "Lower ruins scout: interaction contract checked")
	_add_label(world, "MID CONNECTOR\nHazard recovery, scout interaction, seed gate.", Vector2(1970.0, 1085.0), 500.0)

	var reach := float(active_metrics.get("single_jump_reach", 0.0))
	_add_metric_marker(world, Vector2(280.0, GROUND_TOP - 58.0), minf(reach, 340.0), "single jump reach")


func _stage01_route_plan() -> Dictionary:
	return {
		"map_bounds": Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT),
		"aspect_ratio": MAP_WIDTH / MAP_HEIGHT,
		"target_viewport_equivalent_route": 8.0,
		"critical_path": [
			"entrance",
			"lower_corridor",
			"timing_traversal",
			"dash_gap",
			"central_shaft",
			"upper_combat",
			"mid_connector",
			"generated_pocket",
			"exit",
		],
		"rooms": [
			{"id": "entrance", "role": "entrance", "bounds": Rect2(60.0, 1320.0, 760.0, 740.0), "color": Color(0.13, 0.15, 0.18, 0.92)},
			{"id": "lower_corridor", "role": "movement_combat", "bounds": Rect2(560.0, 1500.0, 740.0, 560.0), "color": Color(0.12, 0.15, 0.18, 0.92)},
			{"id": "timing_traversal", "role": "timing_traversal", "bounds": Rect2(760.0, 1440.0, 760.0, 620.0), "color": Color(0.12, 0.16, 0.19, 0.92)},
			{"id": "dash_gap", "role": "dash_gap", "bounds": Rect2(1220.0, 1510.0, 650.0, 520.0), "color": Color(0.14, 0.14, 0.18, 0.92)},
			{"id": "central_shaft", "role": "vertical_shaft", "bounds": Rect2(1280.0, 500.0, 760.0, 1430.0), "color": Color(0.12, 0.15, 0.18, 0.92)},
			{"id": "optional_high_cache", "role": "optional_reward", "bounds": Rect2(820.0, 360.0, 620.0, 420.0), "color": Color(0.15, 0.12, 0.18, 0.92)},
			{"id": "upper_combat", "role": "combat_mixed", "bounds": Rect2(1760.0, 420.0, 860.0, 560.0), "color": Color(0.15, 0.13, 0.16, 0.92)},
			{"id": "mid_connector", "role": "hazard_interaction", "bounds": Rect2(1830.0, 960.0, 790.0, 520.0), "color": Color(0.13, 0.14, 0.17, 0.92)},
			{"id": "generated_pocket", "role": "generated_pocket", "bounds": Rect2(1040.0, 1180.0, 1540.0, 820.0), "color": Color(0.11, 0.15, 0.16, 0.92)},
			{"id": "exit", "role": "exit_room", "bounds": Rect2(2260.0, 1600.0, 360.0, 420.0), "color": Color(0.12, 0.14, 0.16, 0.92)},
		],
	}


func _build_lower_ruins_room_shells(route_plan: Dictionary) -> void:
	var rooms: Array = route_plan.get("rooms", [])
	for room in rooms:
		var room_id := str(room.get("id", "room"))
		var bounds: Rect2 = room.get("bounds", Rect2())
		var color: Color = room.get("color", Color(0.12, 0.14, 0.16, 0.92))
		_add_dungeon_room_frame(world, room_id.capitalize().replace(" ", "") + "Room", bounds.get_center(), bounds.size, color)

	_add_masonry_cluster(world, "EntranceRubble", 170.0, 1955.0, 7)
	_add_masonry_cluster(world, "ShaftLowerRubble", 1450.0, 1955.0, 8)
	_add_masonry_cluster(world, "MidConnectorRubble", 1980.0, 1320.0, 7)
	_add_masonry_cluster(world, "UpperCombatRubble", 1880.0, 900.0, 8)


func _add_dungeon_room_frame(parent: Node, room_name: String, center: Vector2, size: Vector2, color: Color) -> void:
	var accent := Color(color.r + 0.05, color.g + 0.05, color.b + 0.06, color.a)
	_add_backdrop_rect(parent, room_name + "Rear", center, size, color)
	_add_backdrop_rect(parent, room_name + "CeilingLip", center + Vector2(0.0, -size.y * 0.5 + 18.0), Vector2(size.x, 36.0), Color(0.07, 0.08, 0.10, 0.96))
	_add_backdrop_rect(parent, room_name + "LowerMass", center + Vector2(0.0, size.y * 0.5 - 22.0), Vector2(size.x, 44.0), Color(0.08, 0.09, 0.11, 0.96))
	_add_backdrop_rect(parent, room_name + "LeftPier", center + Vector2(-size.x * 0.5 + 24.0, 36.0), Vector2(48.0, size.y - 90.0), accent)
	_add_backdrop_rect(parent, room_name + "RightPier", center + Vector2(size.x * 0.5 - 24.0, 36.0), Vector2(48.0, size.y - 90.0), accent)


func _add_masonry_cluster(parent: Node, prefix: String, start_x: float, y: float, count: int) -> void:
	for index in range(count):
		var block_width := 58.0 + float(index % 3) * 16.0
		var block_height := 20.0 + float(index % 2) * 12.0
		var x := start_x + float(index) * 88.0
		var tone := 0.12 + float(index % 4) * 0.018
		_add_backdrop_rect(parent, "%sBlock%d" % [prefix, index], Vector2(x, y - block_height * 0.5), Vector2(block_width, block_height), Color(tone, tone + 0.01, tone + 0.025, 0.92))


func _build_generated_route(seed: int, move_player_to_generated_start: bool) -> void:
	_clear_children(generated_root)
	_clear_generated_route_surfaces()
	_reset_generated_validations()
	_rng.seed = seed
	var metrics := RunState.get_testbed_metrics_snapshot()
	var route_limits: Dictionary = metrics.get("route_limits", {})

	var segments: Array[Dictionary] = [
		{"id": "jump", "center": Vector2(1580.0, 1350.0), "width": 300.0, "jitter": Vector2(6.0, 5.0), "width_jitter": 10.0, "fill_depth": 82.0, "fill_jitter": 6.0},
		{"id": "drop", "center": Vector2(1150.0, 1480.0), "width": 320.0, "jitter": Vector2(6.0, 5.0), "width_jitter": 10.0, "fill_depth": 82.0, "fill_jitter": 6.0},
		{"id": "turnback", "center": Vector2(1580.0, 1605.0), "width": 320.0, "jitter": Vector2(6.0, 5.0), "width_jitter": 10.0, "fill_depth": 82.0, "fill_jitter": 6.0},
		{"id": "descent", "center": Vector2(1960.0, 1730.0), "width": 320.0, "jitter": Vector2(6.0, 5.0), "width_jitter": 10.0, "fill_depth": 82.0, "fill_jitter": 6.0},
		{"id": "exit_prep", "center": Vector2(2300.0, 1810.0), "width": 220.0, "jitter": Vector2(2.0, 3.0), "width_jitter": 0.0, "fill_depth": 44.0, "fill_jitter": 2.0},
	]
	var segment_log: Array[String] = []
	var enemy_count := 0
	var hazard_count := 0
	var interactable_count := 0
	var destructible_count := 0
	var start_center := Vector2(2260.0, MID_FLOOR_Y)
	var previous_center := start_center
	var route_distance := 0.0
	var route_surface_ids: Array[String] = ["MiddleConnectorFloor"]

	generated_spawn = Vector2(start_center.x - 120.0, MID_FLOOR_TOP - PLAYER_FOOT_OFFSET)
	_add_checkpoint(generated_root, "CheckpointGeneratedStart", generated_spawn, "generated_start")
	_add_terrain_visual_mass(generated_root, "GeneratedStartSocket", start_center, Vector2(340.0, 40.0), 126.0, Color(0.19, 0.28, 0.31, 0.92))

	for segment in segments:
		var segment_id := str(segment.get("id", "segment"))
		var anchor: Vector2 = segment.get("center", start_center)
		var jitter: Vector2 = segment.get("jitter", Vector2.ZERO)
		var center := anchor + Vector2(_rng.randf_range(-jitter.x, jitter.x), _rng.randf_range(-jitter.y, jitter.y))
		var width_jitter := float(segment.get("width_jitter", 22.0))
		var width := float(segment.get("width", 320.0)) + _rng.randf_range(-width_jitter, width_jitter)
		var platform_size := Vector2(width, 36.0)
		var fill_jitter := float(segment.get("fill_jitter", 0.0))
		var fill_depth := float(segment.get("fill_depth", 82.0)) + _rng.randf_range(-fill_jitter, fill_jitter)
		var surface_id := "Generated_%s_%d" % [segment_id, segment_log.size()]
		route_distance += previous_center.distance_to(center)
		previous_center = center

		_add_terrain_mass(generated_root, surface_id, center, platform_size, fill_depth, Color(0.23, 0.30, 0.34, 1.0), false, segment_id)
		segment_log.append(segment_id)
		route_surface_ids.append(surface_id)

	var exit_center := Vector2(2570.0, GROUND_Y)
	route_distance += previous_center.distance_to(exit_center)
	_add_terrain_mass(generated_root, "GeneratedExitPlatform", exit_center, Vector2(220.0, 40.0), 260.0, Color(0.19, 0.28, 0.31, 1.0), true, "exit")
	route_surface_ids.append("GeneratedExitPlatform")
	_add_exit(generated_root, Vector2(exit_center.x + 50.0, GROUND_TOP), "Clear generated seed")

	var validation := _validate_generated_route(route_distance, route_surface_ids, route_limits)
	var valid := bool(validation.get("valid", false))
	route_summary = {
		"seed": seed,
		"mode": generator_mode,
		"segments": segment_log,
		"span": route_distance,
		"valid": valid,
		"enemy_count": enemy_count,
		"hazard_count": hazard_count,
		"interactable_count": interactable_count,
		"destructible_count": destructible_count,
		"failure_reason": str(validation.get("failure_reason", "")),
		"validation_checks": validation.get("checks", {}),
		"route_surface_ids": route_surface_ids,
	}
	if not valid:
		_clear_children(generated_root)
		_clear_generated_route_surfaces()
	route_bounds = Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT)
	_rebuild_dungeon_framing()
	_rebuild_fall_reset_zone()
	_configure_spawned_player()
	SignalBus.testbed_route_status_changed.emit(_route_status_text("ready" if valid else "invalid"))

	if move_player_to_generated_start:
		if valid:
			set_checkpoint("generated_start", generated_spawn, false)
			respawn_player("generated seed")
			SignalBus.status_message_changed.emit("Generated seed %d ready" % seed)
		else:
			SignalBus.status_message_changed.emit("Generated seed %d invalid: %s" % [seed, route_summary.get("failure_reason", "unknown")])


func _publish_testbed_context(objective: String) -> void:
	SignalBus.testbed_objective_changed.emit(objective)
	SignalBus.testbed_flags_changed.emit(RunState.get_testbed_ability_flags())
	SignalBus.testbed_metrics_changed.emit(RunState.get_testbed_metrics_snapshot())
	SignalBus.testbed_route_status_changed.emit(_route_status_text(_route_status_state("ready")))


func _after_player_respawned() -> void:
	_configure_spawned_player()


func _configure_spawned_player() -> void:
	if player != null and is_instance_valid(player):
		player.set_camera_limits(route_bounds)


func _rebuild_fall_reset_zone() -> void:
	if test_objects == null:
		return

	var existing := test_objects.get_node_or_null("FallResetZone")
	if existing != null:
		test_objects.remove_child(existing)
		existing.free()

	var zone := FallResetZone.new()
	zone.name = "FallResetZone"
	zone.position = Vector2(route_bounds.position.x + route_bounds.size.x * 0.5, route_bounds.position.y + route_bounds.size.y + 80.0)
	zone.zone_size = Vector2(route_bounds.size.x + 800.0, 170.0)
	test_objects.add_child(zone)


func _rebuild_dungeon_framing() -> void:
	if world == null:
		return

	var existing := world.get_node_or_null("DungeonBackdrop")
	if existing != null:
		world.remove_child(existing)
		existing.free()

	var backdrop := Node2D.new()
	backdrop.name = "DungeonBackdrop"
	world.add_child(backdrop)
	world.move_child(backdrop, 0)

	var width := route_bounds.size.x + 900.0
	var height := route_bounds.size.y
	var top := route_bounds.position.y
	var left := route_bounds.position.x - 360.0
	var right := left + width
	var bottom := route_bounds.position.y + route_bounds.size.y
	_add_backdrop_rect(backdrop, "RearWall", Vector2(left + width * 0.5, top + height * 0.5), Vector2(width, height + 120.0), Color(0.11, 0.12, 0.14, 1.0))
	_add_backdrop_rect(backdrop, "CeilingMass", Vector2(left + width * 0.5, top + 54.0), Vector2(width, 108.0), Color(0.06, 0.07, 0.08, 1.0))
	_add_backdrop_rect(backdrop, "LowerMasonry", Vector2(left + width * 0.5, bottom - 46.0), Vector2(width, 190.0), Color(0.07, 0.08, 0.09, 1.0))
	_add_backdrop_rect(backdrop, "LeftBoundaryWall", Vector2(left + 38.0, top + height * 0.5), Vector2(76.0, height + 120.0), Color(0.07, 0.08, 0.09, 1.0))
	_add_backdrop_rect(backdrop, "RightBoundaryWall", Vector2(right - 38.0, top + height * 0.5), Vector2(76.0, height + 120.0), Color(0.07, 0.08, 0.09, 1.0))

	var tier_y := top + 420.0
	var tier_index := 0
	while tier_y < bottom - 260.0:
		var tier_tone := 0.09 + float(tier_index % 3) * 0.012
		_add_backdrop_rect(backdrop, "MasonryTier%d" % tier_index, Vector2(left + width * 0.5, tier_y), Vector2(width, 34.0), Color(tier_tone, tier_tone + 0.012, tier_tone + 0.025, 0.48))
		tier_y += 390.0
		tier_index += 1

	var column_x := left + 260.0
	var column_index := 0
	while column_x < right - 200.0:
		var tone := 0.15 if column_index % 2 == 0 else 0.18
		_add_backdrop_rect(backdrop, "Column%d" % column_index, Vector2(column_x, top + height * 0.54), Vector2(54.0, height - 260.0), Color(tone, tone + 0.01, tone + 0.025, 0.50))
		_add_backdrop_rect(backdrop, "ColumnCapTop%d" % column_index, Vector2(column_x, top + 170.0), Vector2(96.0, 26.0), Color(0.18, 0.19, 0.21, 0.70))
		_add_backdrop_rect(backdrop, "ColumnCapMid%d" % column_index, Vector2(column_x, MID_FLOOR_TOP + 70.0), Vector2(104.0, 24.0), Color(0.15, 0.16, 0.18, 0.58))
		_add_backdrop_rect(backdrop, "FloorBlock%d" % column_index, Vector2(column_x + 150.0, bottom - 84.0), Vector2(190.0, 34.0), Color(0.12, 0.13, 0.15, 0.95))
		column_x += 460.0
		column_index += 1


func _add_backdrop_rect(parent: Node, object_name: String, center: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.name = object_name
	visual.position = center
	visual.color = color
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	parent.add_child(visual)
	return visual


# Elevated masses keep old surface collision but render filled depth; ground masses can opt into solid fill.
func _add_terrain_mass(parent: Node, object_name: String, surface_center: Vector2, surface_size: Vector2, fill_depth: float, color: Color, solid_fill: bool = false, role: String = "") -> StaticBody2D:
	var surface_top := surface_center.y - surface_size.y * 0.5
	var visual_depth := maxf(fill_depth, surface_size.y)
	var collision_depth := visual_depth if solid_fill else surface_size.y
	var body := StaticBody2D.new()
	body.name = object_name
	body.position = Vector2(surface_center.x, surface_top + collision_depth * 0.5)
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(surface_size.x, collision_depth)
	shape.shape = rect
	body.add_child(shape)

	var visual_bounds := Rect2(Vector2(surface_center.x - surface_size.x * 0.5, surface_top), Vector2(surface_size.x, visual_depth))
	var collision_bounds := Rect2(Vector2(surface_center.x - surface_size.x * 0.5, surface_top), Vector2(surface_size.x, collision_depth))
	var support_capable := surface_size.x >= MIN_GENERATED_LANDING_WIDTH
	_register_route_surface(object_name, parent, role, visual_bounds, collision_bounds, support_capable, false, solid_fill, false)

	var visual_center := Vector2(0.0, surface_top + visual_depth * 0.5 - body.position.y)
	_add_rock_mass_visual(body, "Visual", visual_center, Vector2(surface_size.x, visual_depth), color)
	return body


func _add_terrain_visual_mass(parent: Node, object_name: String, surface_center: Vector2, surface_size: Vector2, fill_depth: float, color: Color, role: String = "") -> Node2D:
	var surface_top := surface_center.y - surface_size.y * 0.5
	var visual_depth := maxf(fill_depth, surface_size.y)
	var root := Node2D.new()
	root.name = object_name
	root.position = Vector2(surface_center.x, surface_top + visual_depth * 0.5)
	parent.add_child(root)
	var visual_bounds := Rect2(Vector2(surface_center.x - surface_size.x * 0.5, surface_top), Vector2(surface_size.x, visual_depth))
	_register_route_surface(object_name, parent, role, visual_bounds, Rect2(), false, false, false, true)
	_add_rock_mass_visual(root, "Visual", Vector2.ZERO, Vector2(surface_size.x, visual_depth), color)
	return root


func _add_rock_mass_visual(parent: Node, object_name: String, local_center: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.name = object_name
	visual.position = local_center
	visual.color = color
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y + 7.0),
		Vector2(-half.x * 0.72, -half.y + 2.0),
		Vector2(-half.x * 0.38, -half.y + 5.0),
		Vector2(0.0, -half.y + 1.0),
		Vector2(half.x * 0.42, -half.y + 4.0),
		Vector2(half.x * 0.74, -half.y + 2.0),
		Vector2(half.x, -half.y + 7.0),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	parent.add_child(visual)

	var top_color := Color(minf(color.r + 0.07, 1.0), minf(color.g + 0.07, 1.0), minf(color.b + 0.07, 1.0), color.a)
	var shadow_color := Color(maxf(color.r - 0.045, 0.0), maxf(color.g - 0.045, 0.0), maxf(color.b - 0.045, 0.0), color.a)
	_add_local_rect(parent, object_name + "TopLip", local_center + Vector2(0.0, -half.y + 11.0), Vector2(maxf(size.x - 18.0, 12.0), 10.0), top_color)
	for index in range(3):
		var line_y := -half.y + 38.0 + float(index) * maxf(34.0, size.y * 0.22)
		if line_y < half.y - 14.0:
			_add_local_rect(parent, "%sStrata%d" % [object_name, index], local_center + Vector2(float(index - 1) * 18.0, line_y), Vector2(size.x * 0.74, 5.0), shadow_color)
	return visual


func _add_local_rect(parent: Node, object_name: String, local_center: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.name = object_name
	visual.position = local_center
	visual.color = color
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	parent.add_child(visual)
	return visual


func _register_route_surface(surface_id: String, parent: Node, role: String, visual_bounds: Rect2, collision_bounds: Rect2, support_capable: bool, one_way: bool, solid_fill: bool, visual_only: bool, allow_stitch: bool = false) -> void:
	var surface_role := role if not role.is_empty() else surface_id
	var top := visual_bounds.position.y if visual_only else collision_bounds.position.y
	_route_surfaces.append({
		"id": surface_id,
		"source": _route_surface_source(parent),
		"role": surface_role,
		"visual_bounds": visual_bounds,
		"collision_bounds": collision_bounds,
		"top": top,
		"support_capable": support_capable,
		"one_way": one_way,
		"solid_fill": solid_fill,
		"visual_only": visual_only,
		"allow_stitch": allow_stitch,
	})


func _route_surface_source(parent: Node) -> String:
	if generated_root != null and (parent == generated_root or generated_root.is_ancestor_of(parent)):
		return "generated"
	return "authored"


func _clear_route_surfaces() -> void:
	_route_surfaces.clear()


func _clear_generated_route_surfaces() -> void:
	if _route_surfaces.is_empty():
		return
	for index in range(_route_surfaces.size() - 1, -1, -1):
		var surface: Dictionary = _route_surfaces[index]
		if str(surface.get("source", "")) == "generated":
			_route_surfaces.remove_at(index)


func _support_surface_for_id(surface_id: String) -> Dictionary:
	for surface in _route_surfaces:
		if str(surface.get("id", "")) == surface_id and bool(surface.get("support_capable", false)):
			return surface
	return {}


func _support_surfaces_by_source(surface_source: String) -> Array[Dictionary]:
	var support_surfaces: Array[Dictionary] = []
	for surface in _route_surfaces:
		if str(surface.get("source", "")) == surface_source and bool(surface.get("support_capable", false)):
			support_surfaces.append(surface)
	return support_surfaces


func _validate_generated_route(route_distance: float, route_surface_ids: Array[String], route_limits: Dictionary) -> Dictionary:
	var failures := PackedStringArray()
	var route_surfaces: Array[Dictionary] = []
	var checks := {
		"distance": route_distance > MIN_GENERATED_ROUTE_DISTANCE,
		"surface_count": true,
		"landing_width": true,
		"link_gaps": true,
		"ability_envelope": true,
		"headroom": true,
		"body_clearance": true,
		"duplicate_surfaces": true,
		"support_contract": true,
	}
	if not bool(checks["distance"]):
		failures.append("generated route travel is too short")

	for surface_id in route_surface_ids:
		var surface := _support_surface_for_id(surface_id)
		if surface.is_empty():
			checks["support_contract"] = false
			failures.append("%s has no support-capable collision surface" % surface_id)
		else:
			route_surfaces.append(surface)

	checks["surface_count"] = route_surfaces.size() >= 7
	if not bool(checks["surface_count"]):
		failures.append("generated route has too few support surfaces")

	var max_gap := float(route_limits.get("max_required_gap", 140.0)) + GENERATED_GAP_TOLERANCE
	var max_step_up := float(route_limits.get("max_required_ledge", 96.0)) + GENERATED_LEDGE_TOLERANCE
	for surface in route_surfaces:
		var bounds: Rect2 = surface.get("collision_bounds", Rect2())
		if bounds.size.x < MIN_GENERATED_LANDING_WIDTH:
			checks["landing_width"] = false
			failures.append("%s landing too narrow" % str(surface.get("id", "surface")))
		_validate_surface_headroom(surface, route_surfaces, checks, failures)

	for index in range(route_surfaces.size() - 1):
		var current := route_surfaces[index]
		var next := route_surfaces[index + 1]
		var current_bounds: Rect2 = current.get("collision_bounds", Rect2())
		var next_bounds: Rect2 = next.get("collision_bounds", Rect2())
		var horizontal_gap := maxf(0.0, maxf(next_bounds.position.x - current_bounds.end.x, current_bounds.position.x - next_bounds.end.x))
		var step_up := float(current.get("top", 0.0)) - float(next.get("top", 0.0))
		var visual_overlap_x := _horizontal_overlap(current.get("visual_bounds", Rect2()), next.get("visual_bounds", Rect2()))
		if horizontal_gap > max_gap:
			checks["link_gaps"] = false
			checks["ability_envelope"] = false
			failures.append("%s to %s gap %.0fpx exceeds %.0fpx ability reach" % [str(current.get("id", "surface")), str(next.get("id", "surface")), horizontal_gap, max_gap])
		if horizontal_gap > 0.0 and horizontal_gap < MIN_GENERATED_BODY_GAP:
			checks["body_clearance"] = false
			failures.append("%s to %s body gap %.0fpx is under %.0fpx" % [str(current.get("id", "surface")), str(next.get("id", "surface")), horizontal_gap, MIN_GENERATED_BODY_GAP])
		if step_up > max_step_up:
			checks["link_gaps"] = false
			checks["ability_envelope"] = false
			failures.append("%s to %s step-up %.0fpx exceeds %.0fpx ability ledge" % [str(current.get("id", "surface")), str(next.get("id", "surface")), step_up, max_step_up])
		if visual_overlap_x > GENERATED_STITCH_OVERLAP and _vertical_headroom(current, next) < MIN_GENERATED_HEADROOM:
			checks["body_clearance"] = false
			failures.append("%s to %s visual clearance is under %.0fpx" % [str(current.get("id", "surface")), str(next.get("id", "surface")), MIN_GENERATED_HEADROOM])

	_validate_duplicate_generated_supports(checks, failures)

	return {
		"valid": failures.is_empty(),
		"failure_reason": "" if failures.is_empty() else "; ".join(failures),
		"checks": checks,
	}


func _horizontal_overlap(left: Rect2, right: Rect2) -> float:
	return minf(left.end.x, right.end.x) - maxf(left.position.x, right.position.x)


func _validate_surface_headroom(surface: Dictionary, route_surfaces: Array[Dictionary], checks: Dictionary, failures: PackedStringArray) -> void:
	var bounds: Rect2 = surface.get("collision_bounds", Rect2())
	if bounds == Rect2():
		return
	for overhead in route_surfaces:
		if str(overhead.get("id", "")) == str(surface.get("id", "")):
			continue
		var overhead_bounds: Rect2 = overhead.get("visual_bounds", Rect2())
		if overhead_bounds == Rect2() or overhead_bounds.end.y > bounds.position.y:
			continue
		if _horizontal_overlap(bounds, overhead_bounds) <= GENERATED_STITCH_OVERLAP:
			continue
		var clearance := bounds.position.y - overhead_bounds.end.y
		if clearance < MIN_GENERATED_HEADROOM:
			checks["headroom"] = false
			checks["body_clearance"] = false
			failures.append("%s headroom %.0fpx is under %.0fpx full-height clearance" % [str(surface.get("id", "surface")), clearance, MIN_GENERATED_HEADROOM])


func _vertical_headroom(current: Dictionary, next: Dictionary) -> float:
	var current_visual: Rect2 = current.get("visual_bounds", Rect2())
	var next_visual: Rect2 = next.get("visual_bounds", Rect2())
	var current_top := float(current.get("top", 0.0))
	var next_top := float(next.get("top", 0.0))
	if current_top <= next_top:
		return next_top - current_visual.end.y
	return current_top - next_visual.end.y


func _validate_duplicate_generated_supports(checks: Dictionary, failures: PackedStringArray) -> void:
	var generated_supports := _support_surfaces_by_source("generated")
	var authored_supports := _support_surfaces_by_source("authored")
	for index in range(generated_supports.size()):
		var current := generated_supports[index]
		for other_index in range(index + 1, generated_supports.size()):
			_report_duplicate_support_if_needed(current, generated_supports[other_index], checks, failures)
		for authored in authored_supports:
			_report_duplicate_support_if_needed(current, authored, checks, failures)


func _report_duplicate_support_if_needed(current: Dictionary, other: Dictionary, checks: Dictionary, failures: PackedStringArray) -> void:
	if bool(current.get("allow_stitch", false)) or bool(other.get("allow_stitch", false)):
		return
	var current_bounds: Rect2 = current.get("collision_bounds", Rect2())
	var other_bounds: Rect2 = other.get("collision_bounds", Rect2())
	var overlap_x := minf(current_bounds.end.x, other_bounds.end.x) - maxf(current_bounds.position.x, other_bounds.position.x)
	var same_level := absf(float(current.get("top", 0.0)) - float(other.get("top", 0.0))) < 8.0
	if same_level and overlap_x > GENERATED_STITCH_OVERLAP:
		checks["duplicate_surfaces"] = false
		failures.append("%s overlaps %s by %.0fpx" % [str(current.get("id", "surface")), str(other.get("id", "surface")), overlap_x])


func _route_status_state(default_state: String = "ready") -> String:
	if route_summary.has("valid") and not bool(route_summary.get("valid", false)):
		return "invalid"
	return default_state


func _route_status_text(state: String) -> String:
	var route_text := "Seed %d %s | %dpx | E%d/H%d/D%d/I%d" % [
		int(route_summary.get("seed", active_seed)),
		state,
		int(route_summary.get("span", 0)),
		int(route_summary.get("enemy_count", 0)),
		int(route_summary.get("hazard_count", 0)),
		int(route_summary.get("destructible_count", 0)),
		int(route_summary.get("interactable_count", 0)),
	]
	return "%s | %s" % [route_text, _validation_status_text()]


func _reset_validations() -> void:
	_validations.clear()
	for validation_id in REQUIRED_VALIDATIONS:
		_validations[validation_id] = false


func _reset_generated_validations() -> void:
	if _validations.has("generated_start"):
		_validations["generated_start"] = false
	if _validations.has("generated_exit"):
		_validations["generated_exit"] = false


func _validation_for_checkpoint(checkpoint_id: String) -> String:
	match checkpoint_id:
		"start":
			return "start"
		"timing":
			return "timing"
		"dash":
			return "dash"
		"climb":
			return "climb"
		"generated_start":
			return "generated_start"
		_:
			return ""


func _mark_validation(validation_id: String, announce: bool = true) -> void:
	if validation_id.is_empty() or not _validations.has(validation_id):
		return
	if bool(_validations.get(validation_id, false)):
		return

	_validations[validation_id] = true
	if announce:
		SignalBus.status_message_changed.emit("Check complete: %s" % str(VALIDATION_LABELS.get(validation_id, validation_id)))
	SignalBus.testbed_route_status_changed.emit(_route_status_text(_route_status_state("ready")))


func _is_final_clear_ready() -> bool:
	return _missing_validation_labels().is_empty()


func _validation_status_text() -> String:
	var missing := _missing_validation_labels()
	var done_count := REQUIRED_VALIDATIONS.size() - missing.size()
	if missing.is_empty():
		return "Checks %d/%d ready" % [done_count, REQUIRED_VALIDATIONS.size()]
	return "Checks %d/%d missing %s" % [done_count, REQUIRED_VALIDATIONS.size(), _compact_missing_validation_text()]


func _missing_validation_labels() -> PackedStringArray:
	var missing := PackedStringArray()
	for validation_id in REQUIRED_VALIDATIONS:
		if not bool(_validations.get(validation_id, false)):
			missing.append(str(VALIDATION_LABELS.get(validation_id, validation_id)))
	return missing


func _compact_missing_validation_text(limit: int = 4) -> String:
	var missing := _missing_validation_labels()
	if missing.is_empty():
		return "none"

	var visible := PackedStringArray()
	var visible_count := mini(limit, missing.size())
	for index in range(visible_count):
		visible.append(missing[index])

	var text := ", ".join(visible)
	var remainder := missing.size() - visible_count
	if remainder > 0:
		text += " +%d" % remainder
	return text


func _add_platform(parent: Node, platform_name: String, center: Vector2, size: Vector2, color: Color, one_way: bool = false, role: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = center
	body.collision_layer = 2 if one_way else 1
	body.collision_mask = 0
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	body.add_child(shape)

	var bounds := Rect2(center - size * 0.5, size)
	var support_capable := size.x >= MIN_GENERATED_LANDING_WIDTH and size.x >= size.y
	_register_route_surface(platform_name, parent, role, bounds, bounds, support_capable, one_way, true, false)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	body.add_child(visual)
	return body


func _add_metric_marker(parent: Node, start: Vector2, width: float, label_text: String) -> void:
	var marker := Polygon2D.new()
	marker.name = "MetricMarker"
	marker.color = Color(0.88, 0.78, 0.30, 0.62)
	marker.position = start
	marker.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(width, 0.0),
		Vector2(width, 5.0),
		Vector2(0.0, 5.0),
	])
	parent.add_child(marker)
	_add_label(parent, label_text, start + Vector2(0.0, 8.0), 220.0)


func _add_label(parent: Node, text: String, label_position: Vector2, label_width: float) -> Label:
	var label := Label.new()
	label.name = "WorldLabel"
	label.position = label_position
	label.size = Vector2(label_width, 82.0)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label


func _add_climbable(parent: Node, object_name: String, center: Vector2, size: Vector2) -> Climbable:
	var climbable := Climbable.new()
	climbable.name = object_name
	climbable.position = center
	climbable.climbable_size = size
	parent.add_child(climbable)
	return climbable


func _add_checkpoint(parent: Node, object_name: String, respawn_position: Vector2, checkpoint_id: String) -> StageCheckpoint:
	var checkpoint := StageCheckpoint.new()
	checkpoint.name = object_name
	checkpoint.position = respawn_position
	checkpoint.checkpoint_id = checkpoint_id
	parent.add_child(checkpoint)
	return checkpoint


func _add_hazard(parent: Node, object_name: String, center: Vector2, size: Vector2, knockback: Vector2) -> Hazard:
	var hazard := Hazard.new()
	hazard.name = object_name
	hazard.position = center
	hazard.hazard_size = size
	hazard.damage_amount = 1
	hazard.knockback = knockback
	hazard.target_hit.connect(func(_area: Area2D, _damage_info: DamageInfo) -> void:
		_mark_validation("hazard")
	)
	parent.add_child(hazard)
	return hazard


func _add_walker(parent: Node, object_name: String, foot_position: Vector2, patrol_half_width: float) -> WalkerEnemy:
	var walker := WalkerEnemy.new()
	walker.name = object_name
	walker.position = foot_position
	walker.patrol_half_width = patrol_half_width
	walker.max_health = 3
	walker.contact_damage = 1
	walker.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(walker)
	return walker


func _add_charger(parent: Node, object_name: String, foot_position: Vector2, patrol_half_width: float) -> ChargerEnemy:
	var charger := ChargerEnemy.new()
	charger.name = object_name
	charger.position = foot_position
	charger.patrol_half_width = patrol_half_width
	charger.max_health = 3
	charger.contact_damage = 1
	charger.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(charger)
	return charger


func _add_shooter(parent: Node, object_name: String, foot_position: Vector2) -> ShooterEnemy:
	var shooter := ShooterEnemy.new()
	shooter.name = object_name
	shooter.position = foot_position
	shooter.max_health = 2
	shooter.contact_damage = 1
	shooter.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(shooter)
	return shooter


func _add_shield_guard(parent: Node, object_name: String, foot_position: Vector2, patrol_half_width: float) -> ShieldGuardEnemy:
	var guard := ShieldGuardEnemy.new()
	guard.name = object_name
	guard.position = foot_position
	guard.patrol_half_width = patrol_half_width
	guard.max_health = 4
	guard.contact_damage = 1
	guard.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(guard)
	return guard


func _add_leaper(parent: Node, object_name: String, foot_position: Vector2) -> LeaperEnemy:
	var leaper := LeaperEnemy.new()
	leaper.name = object_name
	leaper.position = foot_position
	leaper.max_health = 3
	leaper.contact_damage = 1
	leaper.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(leaper)
	return leaper


func _add_sentry_turret(parent: Node, object_name: String, foot_position: Vector2) -> SentryTurretEnemy:
	var turret := SentryTurretEnemy.new()
	turret.name = object_name
	turret.position = foot_position
	turret.max_health = 3
	turret.contact_damage = 1
	turret.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(turret)
	return turret


func _add_summon_node(parent: Node, object_name: String, foot_position: Vector2) -> SummonNodeEnemy:
	var node := SummonNodeEnemy.new()
	node.name = object_name
	node.position = foot_position
	node.max_health = 4
	node.contact_damage = 1
	node.defeated.connect(func(_enemy: EnemyBase) -> void:
		_mark_validation("combat")
	)
	parent.add_child(node)
	return node


func _add_destructible(parent: Node, object_name: String, foot_position: Vector2, health: int) -> DestructibleObstacle:
	var obstacle := DestructibleObstacle.new()
	obstacle.name = object_name
	obstacle.position = foot_position
	obstacle.max_health = health
	obstacle.destroyed.connect(func(_destroyed_obstacle: Node) -> void:
		_mark_validation("destructible")
	)
	parent.add_child(obstacle)
	return obstacle


func _add_crumbling_platform(parent: Node, object_name: String, center: Vector2, size: Vector2) -> CrumblingPlatform:
	var platform := CrumblingPlatform.new()
	platform.name = object_name
	platform.position = center
	platform.platform_size = size
	parent.add_child(platform)
	return platform


func _add_timed_poison_vent(parent: Node, object_name: String, center: Vector2, size: Vector2) -> TimedPoisonVent:
	var vent := TimedPoisonVent.new()
	vent.name = object_name
	vent.position = center
	vent.vent_size = size
	vent.target_hit.connect(func(_area: Area2D, _damage_info: DamageInfo) -> void:
		_mark_validation("hazard")
	)
	parent.add_child(vent)
	return vent


func _add_switch_gate(parent: Node, object_name: String, foot_position: Vector2, switch_offset: Vector2) -> SwitchGate:
	var gate := SwitchGate.new()
	gate.name = object_name
	gate.position = foot_position
	gate.switch_offset = switch_offset
	gate.opened.connect(func(_gate: SwitchGate) -> void:
		_mark_validation("interaction")
	)
	parent.add_child(gate)
	return gate


func _add_npc(parent: Node, object_name: String, foot_position: Vector2, message: String) -> TestbedInteractable:
	var npc := TestbedInteractable.new()
	npc.name = object_name
	npc.position = foot_position
	npc.prompt_text = "Talk"
	npc.result_message = message
	npc.interacted.connect(func(_player: Node) -> void:
		_mark_validation("interaction")
	)
	parent.add_child(npc)
	return npc


func _add_exit(parent: Node, foot_position: Vector2, prompt: String) -> Node2D:
	var portal := EXIT_PORTAL_SCENE.instantiate() as Node2D
	portal.position = foot_position
	if portal is Interactable:
		var interactable := portal as Interactable
		interactable.prompt_text = prompt
	parent.add_child(portal)
	return portal
