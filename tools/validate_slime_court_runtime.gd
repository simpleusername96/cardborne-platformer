extends SceneTree

const STAGE_PATH := "res://scenes/stages/boss/SlimeCourt.tscn"
const EPSILON := 0.0001
const INTRO_DURATION := 0.90

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile_state: Node = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and _run_state != null, "Slime Court fixture needs production state autoloads")
	if profile_state == null or _run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)

	var stage: Variant = await _spawn_stage(88031)
	if stage == null:
		_finish()
		return
	_validate_setup_and_geometry(stage)
	await _validate_camera_framing(stage)
	await _validate_intro_and_entrance(stage)
	await _validate_player_death_cleanup(stage)
	stage.queue_free()
	await process_frame

	await _validate_scene_exit_cleanup()
	_finish()


func _spawn_stage(seed: int) -> Variant:
	_expect(_run_state.start_new_run(0, seed), "Slime Court fixture run should start")
	_run_state.set("current_stage_index", 3)
	var packed := load(STAGE_PATH) as PackedScene
	_expect(packed != null, "Slime Court scene should load")
	if packed == null:
		return null
	var stage: Variant = packed.instantiate()
	_expect(stage != null, "Slime Court scene should instantiate as SlimeCourt")
	if stage == null:
		return null
	root.add_child(stage)
	stage.set_manual_simulation(true)
	await process_frame
	return stage


func _validate_setup_and_geometry(stage: Variant) -> void:
	_expect(stage.is_setup_complete(), "Slime Court should complete authored setup")
	var arena: Dictionary = stage.get_arena_snapshot()
	var bounds: Rect2 = arena.get("bounds", Rect2())
	var ground: Rect2 = arena.get("ground_surface", Rect2())
	var platforms: Array = arena.get("platform_surfaces", [])
	_expect(bounds == Rect2(0.0, 0.0, 1280.0, 720.0), "arena should author an exact 1280x720 frame")
	_expect(_near(float(arena.get("usable_ground_width", 0.0)), 1080.0), "arena should expose exactly 1080 px usable ground")
	_expect(_near(ground.size.x, 1080.0) and _near(ground.end.y, 640.0), "ground contract should match visible floor support")
	_expect(platforms.size() == 2, "arena should expose exactly two side platforms")
	if platforms.size() == 2:
		var low := platforms[0] as Rect2
		var high := platforms[1] as Rect2
		_expect(not _near(low.position.y, high.position.y), "side platforms should use different heights")
		_expect(low.end.x < bounds.get_center().x and high.position.x > bounds.get_center().x, "side platforms should occupy opposite sides")
	for platform_path in ["OneWay/LowPlatform", "OneWay/HighPlatform"]:
		var platform := stage.get_node(platform_path) as StaticBody2D
		var shape := platform.get_node("CollisionShape2D") as CollisionShape2D
		_expect(platform.collision_layer == 2 and shape.one_way_collision, "%s should be a one-way platform" % platform_path)
	_expect(stage.player != null and stage.player.global_position.is_equal_approx(Vector2(170.0, 640.0)), "arena should spawn the player on stable ground")
	_expect(stage.get_boss() != null and stage.get_boss().global_position.is_equal_approx(Vector2(950.0, 640.0)), "arena should place the Slime King on stable ground")
	_expect(arena.get("camera_limits", Rect2()) == bounds, "player camera limits should remain fixed to the authored frame")
	_expect(stage.player.camera != null and not stage.player.camera.position_smoothing_enabled, "arena camera should remain stable during the fight")
	_expect(stage.find_children("*", "Label", true, false).is_empty(), "arena should contain no debug narration labels")
	var terrain_color := (stage.get_node("Terrain/Ground/Visual") as Polygon2D).color
	var platform_color := (stage.get_node("OneWay/LowPlatform/Visual") as Polygon2D).color
	_expect(terrain_color != Color(1.0, 0.88, 0.30, 0.96), "terrain should be visually distinct from startup warnings")
	_expect(platform_color != Color(0.94, 0.20, 0.25, 0.72), "platforms should be visually distinct from active hit areas")
	_expect(stage.get_boss().is_runtime_ready(), "SlimeKingActor should validate its model, scheduler, and pattern runtime")
	_expect(stage.get_boss().get_runtime_snapshot()["stagger_capacity"] == 100, "reviewed Slime King stagger capacity should be 100")
	_expect(stage.get_boss().hurtbox.receiver == stage.get_boss(), "boss Hurtbox should forward existing DamageInfo attacks to SlimeKingActor")


func _validate_intro_and_entrance(stage: Variant) -> void:
	var boss: Variant = stage.get_boss()
	var opening_health := int(_run_state.get("current_health"))
	var opening: Dictionary = boss.get_runtime_snapshot()
	_expect(not stage.is_intro_complete() and not stage.is_entrance_locked(), "entrance should stay open during the intro")
	_expect(opening["actor_state"] == &"dormant", "boss should remain dormant during intro")
	_expect(not bool((opening["pattern"] as Dictionary)["damage_enabled"]), "intro should expose no boss damage")

	stage.advance_runtime(0.45)
	var halfway: Dictionary = boss.get_runtime_snapshot()
	_expect(not stage.is_intro_complete(), "half the intro should remain non-active")
	_expect(halfway["actor_state"] == &"dormant", "boss should stay dormant at half intro")
	_expect(int(_run_state.get("current_health")) == opening_health, "intro should not damage the player")

	stage.advance_runtime(INTRO_DURATION - 0.45 - 0.01)
	_expect(not stage.is_intro_complete(), "intro should not end before exact authored duration")
	stage.advance_runtime(0.01)
	await process_frame
	var active: Dictionary = boss.get_runtime_snapshot()
	_expect(stage.is_intro_complete() and stage.is_entrance_locked(), "entrance should lock when the 0.90 s intro completes")
	_expect(active["actor_state"] == &"active", "boss should activate after intro")
	_expect((active["pattern"] as Dictionary)["state"] == &"startup", "scheduler should begin with a visible startup")
	_expect(not bool((active["pattern"] as Dictionary)["damage_enabled"]), "first pattern startup should remain non-damaging")
	var gate_shape := stage.get_node("Terrain/EntranceLock/CollisionShape2D") as CollisionShape2D
	_expect(not gate_shape.disabled, "entrance collision should enable after intro")
	_expect(int(_run_state.get("current_health")) == opening_health, "intro completion should preserve player health")


func _validate_camera_framing(stage: Variant) -> void:
	var fixtures: Array[Dictionary] = [
		{"size": Vector2i(1280, 720), "zoom": 1.0},
		{"size": Vector2i(960, 540), "zoom": 0.75},
		{"size": Vector2i(1920, 1080), "zoom": 1.5},
	]
	for index in fixtures.size():
		var fixture := fixtures[index]
		root.size = fixture["size"] as Vector2i
		stage.player.global_position.x = 170.0 if index % 2 == 0 else 1110.0
		await process_frame
		var arena: Dictionary = stage.get_arena_snapshot()
		var zoom: Vector2 = arena["camera_zoom"]
		var visible_world: Vector2 = arena["camera_visible_world_size"]
		_expect((arena["camera_center"] as Vector2).is_equal_approx(Vector2(640.0, 360.0)), "%s camera should stay centered on the authored court" % fixture["size"])
		_expect(zoom.is_equal_approx(Vector2.ONE * float(fixture["zoom"])), "%s camera should use fit-to-arena zoom" % fixture["size"])
		_expect(visible_world.is_equal_approx(Vector2(1280.0, 720.0)), "%s should keep the full 1280x720 court visible" % fixture["size"])
	root.size = Vector2i(1280, 720)
	await process_frame


func _validate_player_death_cleanup(stage: Variant) -> void:
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	_expect(boss.call("_execute_pattern_for_validation", &"small_slime_summon", 2), "death fixture should start Summon")
	stage.advance_runtime(0.70)
	var summoned: Dictionary = boss.get_runtime_snapshot()
	_expect((summoned["pattern"] as Dictionary)["active_add_count"] == 2, "death fixture should own two active adds")
	var bus: Node = root.get_node_or_null("/root/SignalBus")
	bus.player_died.emit()
	var cancelled: Dictionary = boss.get_runtime_snapshot()
	var pattern := cancelled["pattern"] as Dictionary
	_expect(cancelled["actor_state"] == &"cancelled", "player death should cancel the boss actor")
	_expect(not bool(pattern["damage_enabled"]), "player death should disable boss damage immediately")
	_expect((pattern["queued_pattern_ids"] as Array).is_empty(), "player death should clear queued patterns")
	_expect(pattern["active_zone_count"] == 0 and pattern["active_add_count"] == 0, "player death should clear hazards and adds")


func _validate_scene_exit_cleanup() -> void:
	var stage: Variant = await _spawn_stage(88032)
	if stage == null:
		return
	stage.advance_runtime(INTRO_DURATION)
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	_expect(boss.call("_execute_pattern_for_validation", &"small_slime_summon", 2), "exit fixture should start Summon")
	stage.advance_runtime(0.70)
	stage.advance_runtime(1.00)
	_expect(boss.call("_execute_pattern_for_validation", &"jump_slam"), "exit fixture should start Jump Slam")
	stage.advance_runtime(0.80)
	var runtime: Variant = boss.pattern_runtime
	var actor_refs: Array[WeakRef] = []
	for slime in runtime.get_active_adds():
		actor_refs.append(weakref(slime))
	for child in runtime.get_children():
		if child.has_method("is_zone_active"):
			actor_refs.append(weakref(child))
	_expect(actor_refs.size() >= 5, "exit fixture should own two adds and three Jump Slam damage zones")
	stage.queue_free()
	await process_frame
	await process_frame
	for actor_ref in actor_refs:
		_expect(actor_ref.get_ref() == null, "scene exit should free every boss-owned runtime actor")


func _near(left: float, right: float) -> bool:
	return absf(left - right) <= EPSILON


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SLIME_COURT_RUNTIME_VALIDATION_OK geometry=1080 platforms=2 camera=1280+960+1920 intro=0.90 cleanup=player_death+scene_exit")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
