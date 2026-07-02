extends StageBase

const EXIT_PORTAL_SCENE: PackedScene = preload("res://scenes/stages/ExitPortal.tscn")
const VIEWPORT_WIDTH := 1280.0
const GROUND_Y := 680.0
const GROUND_TOP := 660.0
const PLAYER_FOOT_OFFSET := 10.0

@export var active_seed: int = 73021
@export var generator_mode: String = "mixed_mini_run"

var world: Node2D
var test_objects: Node2D
var generated_root: Node2D
var generated_spawn: Vector2 = Vector2.ZERO
var route_bounds: Rect2 = Rect2(0.0, 0.0, 7600.0, 780.0)
var route_summary: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
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
	_publish_testbed_context("Clear authored lanes, then finish the generated seed route.")


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


func complete_stage() -> void:
	super.complete_stage()
	SignalBus.status_message_changed.emit("Testbed clear: seed %d replayable" % active_seed)
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
	var metrics := RunState.get_testbed_metrics_snapshot()
	var active_metrics: Dictionary = metrics.get("active", {})
	var route_limits: Dictionary = metrics.get("route_limits", {})
	var least_name := str(route_limits.get("least_mobile_profile_name", "unknown"))
	var required_gap := float(route_limits.get("max_required_gap", 210.0))
	var required_ledge := float(route_limits.get("max_required_ledge", 120.0))

	_add_label(
		world,
		"START\nMove right. Camera follows.",
		Vector2(70.0, 545.0),
		300.0
	)
	_add_checkpoint(test_objects, "CheckpointStart", Vector2(120.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "start")
	_add_label(
		world,
		"Metrics\nLeast mobile: %s\nRequired gate: %.0fpx gap / %.0fpx ledge" % [least_name, required_gap, required_ledge],
		Vector2(520.0, 545.0),
		400.0
	)

	_add_platform(world, "StartFlat", Vector2(420.0, GROUND_Y), Vector2(760.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))
	_add_platform(world, "JumpLanding", Vector2(1040.0, 638.0), Vector2(260.0, 28.0), Color(0.31, 0.36, 0.42, 1.0))
	_add_label(world, "JUMP\nForgiving gap + ledge.", Vector2(900.0, 535.0), 260.0)

	_add_platform(world, "CoyoteLedge", Vector2(1320.0, 592.0), Vector2(230.0, 26.0), Color(0.28, 0.38, 0.50, 1.0))
	_add_platform(world, "JumpBufferOneWay", Vector2(1600.0, 528.0), Vector2(250.0, 22.0), Color(0.25, 0.48, 0.58, 1.0), true)
	_add_platform(world, "DropRecovery", Vector2(1720.0, GROUND_Y), Vector2(430.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))
	_add_checkpoint(test_objects, "CheckpointTiming", Vector2(1750.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "timing")
	_add_label(world, "TIMING\nCoyote ledge, jump buffer, one-way drop to recovery.", Vector2(1380.0, 465.0), 420.0)

	_add_platform(world, "DashPrep", Vector2(2180.0, 622.0), Vector2(300.0, 28.0), Color(0.31, 0.36, 0.42, 1.0))
	_add_platform(world, "DashLanding", Vector2(2580.0, 582.0), Vector2(280.0, 28.0), Color(0.36, 0.38, 0.48, 1.0))
	_add_checkpoint(test_objects, "CheckpointDash", Vector2(2180.0, 602.0), "dash")
	_add_label(world, "DASH GAP\nUse jump + dash. Sized from shared metrics.", Vector2(2080.0, 505.0), 430.0)

	_add_platform(world, "ClimbLower", Vector2(2920.0, GROUND_Y), Vector2(420.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))
	_add_climbable(test_objects, "RopeClimb", Vector2(3060.0, 526.0), Vector2(44.0, 270.0))
	_add_platform(world, "ClimbUpper", Vector2(3240.0, 400.0), Vector2(330.0, 28.0), Color(0.31, 0.36, 0.42, 1.0))
	_add_checkpoint(test_objects, "CheckpointClimb", Vector2(2920.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "climb")
	_add_label(world, "ROPE / LADDER\nW/S or Up/Down to climb. Space dismount.", Vector2(2850.0, 355.0), 420.0)

	_add_platform(world, "DoubleJumpBranch", Vector2(3580.0, 318.0), Vector2(260.0, 26.0), Color(0.42, 0.35, 0.52, 1.0))
	_add_platform(world, "BranchRecovery", Vector2(3600.0, GROUND_Y), Vector2(600.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))
	_add_label(world, "DEBUG DOUBLE JUMP\nFlag is ON for optional route calibration.", Vector2(3430.0, 230.0), 360.0)
	_add_label(world, "WALL TRAVERSAL\nDeferred: wall climb/slide/jump are visible flags, not required lanes.", Vector2(3800.0, 500.0), 420.0)

	_add_platform(world, "CombatGround", Vector2(4170.0, GROUND_Y), Vector2(940.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))
	_add_label(world, "COMBAT CONTRACTS\nWalker enemy, hazard, destructible, NPC interaction.", Vector2(3820.0, 545.0), 500.0)
	_add_checkpoint(test_objects, "CheckpointCombat", Vector2(3740.0, GROUND_TOP - PLAYER_FOOT_OFFSET), "combat")
	_add_walker(test_objects, "AuthoredWalker", Vector2(3840.0, GROUND_TOP), 115.0)
	_add_destructible(test_objects, "BreakableGate", Vector2(4230.0, GROUND_TOP), 3)
	_add_hazard(test_objects, "SpikeStrip", Vector2(4445.0, GROUND_TOP - 8.0), Vector2(160.0, 22.0), Vector2(-240.0, -220.0))
	_add_npc(test_objects, "TestNPC", Vector2(4650.0, GROUND_TOP), "NPC: interaction contract checked")
	_add_platform(world, "GeneratedBridge", Vector2(4810.0, GROUND_Y), Vector2(310.0, 40.0), Color(0.24, 0.28, 0.33, 1.0))

	var reach := float(active_metrics.get("single_jump_reach", 0.0))
	_add_metric_marker(world, Vector2(520.0, 628.0), minf(reach, 340.0), "single jump reach")


func _build_generated_route(seed: int, move_player_to_generated_start: bool) -> void:
	_clear_children(generated_root)
	_rng.seed = seed

	var segments: Array[String] = ["jump", "hazard", "combat", "destructible", "interaction"]
	var segment_log: Array[String] = []
	var enemy_count := 0
	var hazard_count := 0
	var interactable_count := 0
	var destructible_count := 0
	var start_x := 5080.0
	var x := start_x
	var y := GROUND_Y

	generated_spawn = Vector2(start_x - 145.0, GROUND_TOP - PLAYER_FOOT_OFFSET)
	_add_checkpoint(generated_root, "CheckpointGeneratedStart", generated_spawn, "generated_start")
	_add_label(
		generated_root,
		"GENERATED MINI ROUTE\nSeed %d | R random | T replay same seed" % seed,
		Vector2(start_x - 220.0, 545.0),
		520.0
	)
	_add_platform(generated_root, "GeneratedStart", Vector2(start_x, y), Vector2(330.0, 40.0), Color(0.21, 0.31, 0.34, 1.0))

	for segment_id in segments:
		var width := _rng.randf_range(280.0, 430.0)
		var gap := _rng.randf_range(85.0, 165.0)
		if segment_id == "jump":
			gap = _rng.randf_range(120.0, 185.0)
		x += width * 0.5 + gap + 180.0
		y = clampf(y + float(_rng.randi_range(-1, 1)) * 28.0, 560.0, GROUND_Y)
		_add_platform(generated_root, "Generated_%s_%d" % [segment_id, segment_log.size()], Vector2(x, y), Vector2(width, 36.0), Color(0.25, 0.32, 0.36, 1.0))
		_add_label(generated_root, segment_id.to_upper(), Vector2(x - width * 0.5, y - 105.0), 220.0)
		segment_log.append(segment_id)

		if segment_id == "hazard":
			_add_hazard(generated_root, "GeneratedHazard", Vector2(x, y - 29.0), Vector2(minf(180.0, width - 80.0), 22.0), Vector2(-220.0, -210.0))
			hazard_count += 1
		elif segment_id == "combat":
			_add_walker(generated_root, "GeneratedWalker", Vector2(x, y - 20.0), 100.0)
			enemy_count += 1
		elif segment_id == "destructible":
			_add_destructible(generated_root, "GeneratedBreakable", Vector2(x + width * 0.18, y - 20.0), 2)
			destructible_count += 1
		elif segment_id == "interaction":
			_add_npc(generated_root, "GeneratedNPC", Vector2(x, y - 20.0), "Generated NPC: seed interaction checked")
			interactable_count += 1

	x += 380.0
	_add_platform(generated_root, "GeneratedExitPlatform", Vector2(x, GROUND_Y), Vector2(360.0, 40.0), Color(0.21, 0.31, 0.34, 1.0))
	_add_exit(generated_root, Vector2(x + 80.0, GROUND_TOP), "Clear generated seed")
	_add_label(generated_root, "EXIT\nClear requires generated route completion.", Vector2(x - 100.0, 555.0), 360.0)

	var span := (x + 260.0) - (start_x - 260.0)
	var valid := span > VIEWPORT_WIDTH
	route_summary = {
		"seed": seed,
		"mode": generator_mode,
		"segments": segment_log,
		"span": span,
		"valid": valid,
		"enemy_count": enemy_count,
		"hazard_count": hazard_count,
		"interactable_count": interactable_count,
		"destructible_count": destructible_count,
		"failure_reason": "" if valid else "route fits inside one viewport",
	}
	route_bounds = Rect2(0.0, 0.0, maxf(x + 700.0, 7200.0), 780.0)
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


func _route_status_text(state: String) -> String:
	return "Seed %d %s | %dpx | E%d/H%d/D%d/I%d" % [
		int(route_summary.get("seed", active_seed)),
		state,
		int(route_summary.get("span", 0)),
		int(route_summary.get("enemy_count", 0)),
		int(route_summary.get("hazard_count", 0)),
		int(route_summary.get("destructible_count", 0)),
		int(route_summary.get("interactable_count", 0)),
	]


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
	parent.add_child(hazard)
	return hazard


func _add_walker(parent: Node, object_name: String, foot_position: Vector2, patrol_half_width: float) -> WalkerEnemy:
	var walker := WalkerEnemy.new()
	walker.name = object_name
	walker.position = foot_position
	walker.patrol_half_width = patrol_half_width
	walker.max_health = 3
	walker.contact_damage = 1
	parent.add_child(walker)
	return walker


func _add_destructible(parent: Node, object_name: String, foot_position: Vector2, health: int) -> DestructibleObstacle:
	var obstacle := DestructibleObstacle.new()
	obstacle.name = object_name
	obstacle.position = foot_position
	obstacle.max_health = health
	parent.add_child(obstacle)
	return obstacle


func _add_npc(parent: Node, object_name: String, foot_position: Vector2, message: String) -> TestbedInteractable:
	var npc := TestbedInteractable.new()
	npc.name = object_name
	npc.position = foot_position
	npc.prompt_text = "Talk"
	npc.result_message = message
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
