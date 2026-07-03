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


func _ready() -> void:
	_reset_validations()
	_ensure_runtime_roots()
	_clear_children(world)
	_clear_children(test_objects)
	_clear_children(generated_root)
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

	_add_platform(world, "EntranceFloor", Vector2(420.0, GROUND_Y), Vector2(760.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_platform(world, "LowerCorridorFloor", Vector2(900.0, GROUND_Y), Vector2(520.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_platform(world, "FirstStep", Vector2(760.0, 1788.0), Vector2(240.0, 28.0), Color(0.32, 0.36, 0.42, 1.0))
	_add_walker(test_objects, "IntroWalker", Vector2(520.0, GROUND_TOP), 95.0)
	_add_label(world, "LOWER CORRIDOR\nMovement plus first Walker in real room scale.", Vector2(750.0, 1670.0), 360.0)

	_add_platform(world, "CoyoteLedge", Vector2(1060.0, 1724.0), Vector2(250.0, 26.0), Color(0.29, 0.39, 0.49, 1.0))
	_add_platform(world, "JumpBufferOneWay", Vector2(1260.0, 1658.0), Vector2(280.0, 22.0), Color(0.22, 0.48, 0.56, 1.0), true)
	_add_platform(world, "TimingRecovery", Vector2(1335.0, GROUND_Y), Vector2(530.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_checkpoint(test_objects, "CheckpointTiming", Vector2(1335.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "timing")
	_add_label(world, "TIMING CHAMBER\nCoyote ledge, buffered jump, one-way drop.", Vector2(1035.0, 1560.0), 430.0)

	_add_platform(world, "DashPrep", Vector2(1300.0, 1818.0), Vector2(300.0, 28.0), Color(0.32, 0.36, 0.42, 1.0))
	_add_platform(world, "DashLanding", Vector2(1740.0, 1782.0), Vector2(330.0, 28.0), Color(0.37, 0.38, 0.48, 1.0))
	_add_checkpoint(test_objects, "CheckpointDashPrep", Vector2(1300.0, 1794.0), "dash_prep")
	_add_checkpoint(test_objects, "CheckpointDashClear", Vector2(1740.0, 1758.0), "dash")
	_add_label(world, "BROKEN BRIDGE\nRequired jump + dash gap folded into lower ruins.", Vector2(1370.0, 1692.0), 480.0)

	_add_platform(world, "ShaftLower", Vector2(1760.0, GROUND_Y), Vector2(520.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_climbable(test_objects, "RopeClimb", Vector2(1660.0, 1300.0), Vector2(44.0, 1050.0))
	_add_platform(world, "ShaftL1OneWay", Vector2(1500.0, 1635.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_platform(world, "ShaftL2", Vector2(1820.0, 1455.0), Vector2(260.0, 28.0), Color(0.32, 0.36, 0.42, 1.0))
	_add_platform(world, "ShaftL3OneWay", Vector2(1500.0, 1245.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_platform(world, "ShaftL4", Vector2(1810.0, 1035.0), Vector2(260.0, 28.0), Color(0.32, 0.36, 0.42, 1.0))
	_add_platform(world, "ClimbUpper", Vector2(1610.0, UPPER_FLOOR_Y), Vector2(420.0, 28.0), Color(0.32, 0.36, 0.42, 1.0))
	_add_platform(world, "UpperGallery", Vector2(1970.0, UPPER_FLOOR_Y), Vector2(650.0, 28.0), Color(0.31, 0.36, 0.42, 1.0))
	_add_checkpoint(test_objects, "CheckpointClimbPrep", Vector2(1660.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "climb_prep")
	_add_checkpoint(test_objects, "CheckpointClimbClear", Vector2(1610.0, UPPER_FLOOR_TOP - PLAYER_FOOT_OFFSET), "climb")
	_add_label(world, "CENTRAL SHAFT\nRope climb, one-way recovery, upper exit.", Vector2(1410.0, 910.0), 430.0)

	_add_platform(world, "HighCacheBranch", Vector2(1080.0, 560.0), Vector2(330.0, 26.0), Color(0.43, 0.35, 0.52, 1.0))
	_add_platform(world, "HighCacheRejoin", Vector2(1280.0, 690.0), Vector2(220.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_label(world, "OPTIONAL HIGH CACHE\nAssassin double jump / later upgrade branch.", Vector2(900.0, 455.0), 400.0)
	_add_label(world, "WALL TRAVERSAL\nDeferred: not required for this route.", Vector2(1090.0, 705.0), 360.0)

	_add_platform(world, "CombatHallFloor", Vector2(2200.0, UPPER_FLOOR_Y), Vector2(850.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_platform(world, "ShooterLedge", Vector2(2250.0, 635.0), Vector2(260.0, 28.0), Color(0.34, 0.36, 0.43, 1.0))
	_add_label(world, "UPPER COMBAT HALL\nWalker, Charger, Shooter, breakable gate.", Vector2(1960.0, 540.0), 500.0)
	_add_checkpoint(test_objects, "CheckpointCombatPrep", Vector2(1840.0, UPPER_FLOOR_TOP - PLAYER_FOOT_OFFSET), "combat_prep")
	_add_walker(test_objects, "AuthoredWalker", Vector2(2020.0, UPPER_FLOOR_TOP), 115.0)
	_add_charger(test_objects, "AuthoredCharger", Vector2(2200.0, UPPER_FLOOR_TOP), 125.0)
	_add_shooter(test_objects, "AuthoredShooter", Vector2(2250.0, 621.0))
	_add_destructible(test_objects, "BreakableGate", Vector2(2460.0, UPPER_FLOOR_TOP), 3)

	_add_platform(world, "DescentOneWay", Vector2(2420.0, 1010.0), Vector2(260.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_platform(world, "MiddleConnectorFloor", Vector2(2200.0, MID_FLOOR_Y), Vector2(760.0, 40.0), Color(0.23, 0.27, 0.32, 1.0))
	_add_hazard(test_objects, "SpikeTrench", Vector2(2310.0, MID_FLOOR_TOP - 8.0), Vector2(165.0, 22.0), Vector2(-240.0, -220.0))
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
			{"id": "entrance", "role": "entrance", "bounds": Rect2(60.0, 1320.0, 900.0, 740.0), "color": Color(0.13, 0.15, 0.18, 0.92)},
			{"id": "timing_traversal", "role": "timing_traversal", "bounds": Rect2(760.0, 1440.0, 760.0, 620.0), "color": Color(0.12, 0.16, 0.19, 0.92)},
			{"id": "dash_gap", "role": "dash_gap", "bounds": Rect2(1220.0, 1510.0, 650.0, 520.0), "color": Color(0.14, 0.14, 0.18, 0.92)},
			{"id": "central_shaft", "role": "vertical_shaft", "bounds": Rect2(1280.0, 500.0, 760.0, 1430.0), "color": Color(0.12, 0.15, 0.18, 0.92)},
			{"id": "optional_high_cache", "role": "optional_reward", "bounds": Rect2(820.0, 360.0, 620.0, 420.0), "color": Color(0.15, 0.12, 0.18, 0.92)},
			{"id": "upper_combat", "role": "combat_mixed", "bounds": Rect2(1760.0, 420.0, 860.0, 560.0), "color": Color(0.15, 0.13, 0.16, 0.92)},
			{"id": "mid_connector", "role": "hazard_interaction", "bounds": Rect2(1830.0, 960.0, 790.0, 520.0), "color": Color(0.13, 0.14, 0.17, 0.92)},
			{"id": "generated_pocket", "role": "generated_pocket", "bounds": Rect2(1040.0, 1180.0, 1540.0, 820.0), "color": Color(0.11, 0.15, 0.16, 0.92)},
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
	_reset_generated_validations()
	_rng.seed = seed

	var segments: Array[Dictionary] = [
		{"id": "jump", "center": Vector2(1800.0, 1295.0), "width": 360.0, "jitter": Vector2(20.0, 8.0)},
		{"id": "hazard", "center": Vector2(1360.0, 1435.0), "width": 360.0, "jitter": Vector2(18.0, 8.0)},
		{"id": "combat", "center": Vector2(1740.0, 1568.0), "width": 380.0, "jitter": Vector2(22.0, 8.0)},
		{"id": "destructible", "center": Vector2(2200.0, 1710.0), "width": 320.0, "jitter": Vector2(24.0, 10.0)},
		{"id": "interaction", "center": Vector2(1750.0, 1840.0), "width": 340.0, "jitter": Vector2(26.0, 0.0)},
	]
	var segment_log: Array[String] = []
	var enemy_count := 0
	var hazard_count := 0
	var interactable_count := 0
	var destructible_count := 0
	var start_center := Vector2(2260.0, MID_FLOOR_Y)
	var previous_center := start_center
	var route_distance := 0.0

	generated_spawn = Vector2(start_center.x - 120.0, MID_FLOOR_TOP - PLAYER_FOOT_OFFSET)
	_add_checkpoint(generated_root, "CheckpointGeneratedStart", generated_spawn, "generated_start")
	_add_label(
		generated_root,
		"SEED POCKET\nSeed %d | R random | T replay same seed" % seed,
		Vector2(start_center.x - 290.0, 1085.0),
		520.0
	)
	_add_platform(generated_root, "GeneratedStart", start_center, Vector2(340.0, 40.0), Color(0.21, 0.31, 0.34, 1.0))
	_add_climbable(generated_root, "GeneratedPocketRope", Vector2(1580.0, 1570.0), Vector2(52.0, 520.0))
	_add_platform(generated_root, "GeneratedPocketRecoveryA", Vector2(1570.0, 1505.0), Vector2(220.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_platform(generated_root, "GeneratedPocketRecoveryB", Vector2(1585.0, 1378.0), Vector2(220.0, 22.0), Color(0.23, 0.48, 0.56, 1.0), true)
	_add_label(generated_root, "RECOVERY ROPE\nClimb back if you drop into the lower pocket.", Vector2(1460.0, 1295.0), 360.0)

	for segment in segments:
		var segment_id := str(segment.get("id", "segment"))
		var anchor: Vector2 = segment.get("center", start_center)
		var jitter: Vector2 = segment.get("jitter", Vector2.ZERO)
		var center := anchor + Vector2(_rng.randf_range(-jitter.x, jitter.x), _rng.randf_range(-jitter.y, jitter.y))
		var width := float(segment.get("width", 320.0)) + _rng.randf_range(-22.0, 22.0)
		var platform_size := Vector2(width, 36.0)
		var platform_top := center.y - platform_size.y * 0.5
		route_distance += previous_center.distance_to(center)
		previous_center = center

		_add_platform(generated_root, "Generated_%s_%d" % [segment_id, segment_log.size()], center, platform_size, Color(0.25, 0.32, 0.36, 1.0))
		_add_label(generated_root, segment_id.to_upper(), Vector2(center.x - width * 0.5, center.y - 105.0), 220.0)
		segment_log.append(segment_id)

		if segment_id == "hazard":
			_add_hazard(generated_root, "GeneratedHazard", Vector2(center.x, platform_top - 8.0), Vector2(minf(180.0, width - 80.0), 22.0), Vector2(-220.0, -210.0))
			hazard_count += 1
		elif segment_id == "combat":
			_add_walker(generated_root, "GeneratedWalker", Vector2(center.x, platform_top), 100.0)
			enemy_count += 1
		elif segment_id == "destructible":
			_add_destructible(generated_root, "GeneratedBreakable", Vector2(center.x + width * 0.18, platform_top), 2)
			destructible_count += 1
		elif segment_id == "interaction":
			_add_npc(generated_root, "GeneratedNPC", Vector2(center.x, platform_top), "Generated NPC: seed interaction checked")
			interactable_count += 1

	var exit_bridge_center := Vector2(2180.0, GROUND_Y)
	var exit_center := Vector2(2480.0, GROUND_Y)
	route_distance += previous_center.distance_to(exit_bridge_center)
	route_distance += exit_bridge_center.distance_to(exit_center)
	_add_platform(generated_root, "GeneratedExitBridge", exit_bridge_center, Vector2(300.0, 40.0), Color(0.21, 0.31, 0.34, 1.0))
	_add_platform(generated_root, "GeneratedExitPlatform", exit_center, Vector2(320.0, 40.0), Color(0.21, 0.31, 0.34, 1.0))
	_add_exit(generated_root, Vector2(exit_center.x + 50.0, GROUND_TOP), "Clear generated seed")
	_add_label(generated_root, "EXIT ROOM\nClear requires generated route completion.", Vector2(exit_center.x - 250.0, 1710.0), 360.0)

	var valid := route_distance > VIEWPORT_WIDTH * 2.0
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
		"failure_reason": "" if valid else "generated route travel is too short",
	}
	route_bounds = Rect2(0.0, 0.0, MAP_WIDTH, MAP_HEIGHT)
	_rebuild_dungeon_framing()
	_rebuild_fall_reset_zone()
	_configure_spawned_player()
	SignalBus.testbed_route_status_changed.emit(_route_status_text("ready" if valid else "invalid"))

	if move_player_to_generated_start:
		set_checkpoint("generated_start", generated_spawn, false)
		respawn_player("generated seed")
		SignalBus.status_message_changed.emit("Generated seed %d ready" % seed)


func _publish_testbed_context(objective: String) -> void:
	SignalBus.testbed_objective_changed.emit(objective)
	SignalBus.testbed_flags_changed.emit(RunState.get_testbed_ability_flags())
	SignalBus.testbed_metrics_changed.emit(RunState.get_testbed_metrics_snapshot())
	SignalBus.testbed_route_status_changed.emit(_route_status_text("ready"))


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
	SignalBus.testbed_route_status_changed.emit(_route_status_text("ready"))


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


func _add_platform(parent: Node, platform_name: String, center: Vector2, size: Vector2, color: Color, one_way: bool = false) -> StaticBody2D:
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
