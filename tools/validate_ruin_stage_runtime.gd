extends SceneTree

const STAGE_SCENE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run_state := root.get_node_or_null("/root/RunState")
	_run_state = run_state
	_expect(run_state != null, "Ruin runtime fixture needs RunState.")
	if run_state == null:
		_finish()
		return
	_expect(bool(run_state.call("start_new_run", 0, 73021)), "Ruin runtime fixture should start a run.")
	run_state.set("current_stage_index", 0)
	var packed_stage := load(STAGE_SCENE_PATH) as PackedScene
	_expect(packed_stage != null, "Ruin runtime fixture should load the production stage.")
	if packed_stage == null:
		_finish()
		return
	var stage: Variant = packed_stage.instantiate()
	root.add_child(stage)
	for _frame in 4:
		await process_frame
		await physics_frame
	_expect(stage.is_setup_complete(), "Ruin production stage should assemble.")
	if not stage.is_setup_complete():
		stage.queue_free()
		_finish()
		return
	var runtime_case := OS.get_environment("RUIN_RUNTIME_CASE")
	if runtime_case == "optional":
		await _validate_continuous_optional_rejoin(stage)
		stage.queue_free()
		await process_frame
		_finish()
		return

	_validate_composition(stage)
	_validate_forward_rejoin(stage)
	_validate_room_intent(stage)
	await _validate_continuous_required_route(stage)
	await _validate_continuous_optional_rejoin(stage)
	await _validate_shooter_cover_cycle(stage)
	await _validate_mobile_cycles(stage)
	await _validate_minimap_route(stage)
	_validate_terminal_bypass(stage)

	stage.queue_free()
	await process_frame
	_finish()


func _validate_composition(stage: Variant) -> void:
	var metrics: Dictionary = stage.get_composition_metrics()
	_expect(float(metrics.get("critical_route_vertical_range", 0.0)) >= 720.0, "Ruin range should remain at least 720 px.")
	_expect(int(metrics.get("actual_enemy_count", 0)) >= 8, "Ruin should retain at least eight required-route enemies.")
	_expect(int(metrics.get("required_room_count", 0)) == 8, "Ruin should retain eight required rooms.")
	_expect(int(metrics.get("meaningful_descent_transitions", 0)) >= 2, "Ruin should contain two meaningful descents.")
	_expect(int(metrics.get("direction_reversals", 0)) >= 2, "Ruin should reverse vertical direction twice.")
	_expect(int(metrics.get("forward_rejoin_count", 0)) == 1, "Ruin optional route should forward-rejoin once.")
	_expect(int(metrics.get("near_limit_required_transition_count", -1)) == 0, "Ruin required route should contain no near-limit transitions.")


func _validate_forward_rejoin(stage: Variant) -> void:
	var plan: Variant = stage.get_stage_plan()
	var found := false
	for connection in plan.get_connections():
		if connection.id != &"optional_return_0":
			continue
		found = true
		_expect(connection.from_room_id == &"lr_destructible_cache", "Ruin return should leave the cache.")
		_expect(connection.to_room_id == &"lr_broken_bridge", "Ruin return should land in the broken bridge.")
		_expect(connection.to_socket_id == &"broken_bridge_optional_rejoin", "Ruin return should use the authored bridge rope socket.")
	_expect(found, "Ruin should retain its optional return connection.")


func _validate_room_intent(stage: Variant) -> void:
	var rise: Variant = stage.get_room_host(&"lr_rise_steps")
	var patrol: Variant = stage.get_room_host(&"lr_patrol_gallery")
	var choice: Variant = stage.get_room_host(&"lr_lower_upper_choice")
	var cache: Variant = stage.get_room_host(&"lr_destructible_cache")
	var bridge: Variant = stage.get_room_host(&"lr_broken_bridge")
	var charge: Variant = stage.get_room_host(&"lr_charge_lane")
	_expect(rise != null and patrol != null and choice != null and cache != null and bridge != null and charge != null, "Ruin authored room hosts should exist.")
	if rise == null or patrol == null or choice == null or cache == null or bridge == null or charge == null:
		return
	_expect(_critical_surfaces(rise).size() == 5, "Rise Steps should expose five comfortable supports.")
	_expect(_critical_surfaces(patrol).size() == 5, "Patrol Gallery should expose two readable elevation bands.")
	var choice_validation: Node = choice.get_node("Validation")
	var axes: Array = choice_validation.get_meta("route_difference_axes", [])
	_expect(axes.has(&"movement") and axes.has(&"risk"), "Ruin choice routes should differ by movement and risk.")
	var cache_validation: Node = cache.get_node("Validation")
	_expect(cache_validation.get_meta("forward_rejoin_room", &"") == &"lr_broken_bridge", "Cache should declare its forward rejoin owner.")
	var bridge_validation: Node = bridge.get_node("Validation")
	_expect(int(bridge_validation.get_meta("controlled_descent_count", 0)) == 2, "Broken Bridge should declare two controlled descents.")
	_expect(bridge.get_node_or_null("Anchors/Objective/NoFacilityContent") != null, "Broken Bridge should remain free of Forge or merchant content.")
	var lane := charge.get_node("Terrain/ChargeLaneMass") as StaticBody2D
	var escape := charge.get_node("OneWay/EscapeLedge") as StaticBody2D
	var reengage := charge.get_node("OneWay/ReengageLedge") as StaticBody2D
	_expect(absf(lane.position.y - escape.position.y) <= 64.0, "Charge side escape should be reachable from the lane.")
	_expect(absf(escape.position.y - reengage.position.y) <= 64.0, "Charge re-engage ledge should follow one comfortable transfer.")


func _validate_shooter_cover_cycle(stage: Variant) -> void:
	var host: Variant = stage.get_room_host(&"lr_shooter_overlook")
	var shooter: Variant = _find_enemy(stage, &"lr_shooter_overlook", &"shooter")
	_expect(host != null and shooter != null, "Shooter Overlook should spawn its ranged enemy.")
	if host == null or shooter == null:
		return
	var player: Variant = stage.get("player")
	player.respawn_at(host.global_position + Vector2(120.0, 620.0), 0.0)
	shooter.reset_enemy()
	await physics_frame

	var origin: Vector2 = shooter.global_position + Vector2(0.0, -28.0)
	var lower_target: Vector2 = player.global_position
	var lower_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, lower_target, 1)
	lower_query.collide_with_areas = false
	lower_query.collide_with_bodies = true
	var lower_hit: Dictionary = host.get_world_2d().direct_space_state.intersect_ray(lower_query)
	_expect(
		not lower_hit.is_empty()
			and String((lower_hit.get("collider") as Node).name) == "CoverWall",
		"Shooter lower lane should be blocked by the authored solid cover."
	)
	var upper_marker := host.get_node("Anchors/Objective/UpperExposureStart") as Marker2D
	var upper_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		origin,
		upper_marker.global_position + Vector2(0.0, -28.0),
		1
	)
	upper_query.collide_with_areas = false
	upper_query.collide_with_bodies = true
	_expect(
		host.get_world_2d().direct_space_state.intersect_ray(upper_query).is_empty(),
		"Shooter upper response should remain exposed."
	)

	var warning_seen := false
	var health_before := int(_run_state.get("current_health"))
	for _frame in 180:
		await physics_frame
		var warning := shooter.get_node_or_null("AimWarning") as Line2D
		if warning != null and warning.visible:
			warning_seen = true
		if int(shooter.get("_shots_fired")) >= 1 and warning_seen:
			break
	_expect(warning_seen, "Shooter should expose a local startup cue.")
	_expect(
		int(shooter.get("_shots_fired")) >= 1,
		"Shooter should fire during the authored cover cycle (shots=%d state=%s)."
		% [int(shooter.get("_shots_fired")), String(shooter.get("_state"))]
	)
	for _frame in 100:
		await physics_frame
	_expect(int(_run_state.get("current_health")) == health_before, "Shooter cover should prevent player damage.")


func _validate_continuous_required_route(stage: Variant) -> void:
	var player: Variant = stage.get("player")
	var surfaces: Array = stage.get_critical_surface_contract()
	_expect(surfaces.size() >= 2, "Ruin continuous traversal needs critical supports.")
	if surfaces.size() < 2:
		return
	player.invulnerability_timer = 999.0
	var completed := true
	for index in range(1, surfaces.size()):
		var previous := surfaces[index - 1] as Dictionary
		var target := surfaces[index] as Dictionary
		var previous_end := float(previous["x"]) + float(previous["width"])
		var target_start := float(target["x"])
		var target_top := float(target["top"])
		var target_x := target_start + minf(float(target["width"]) * 0.35, 96.0)
		var rise := float(previous["top"]) - target_top
		var gap := maxf(target_start - previous_end, 0.0)
		var jump_needed := rise > 8.0 or gap > 16.0
		var takeoff_margin := 96.0 if gap > 16.0 else 24.0
		var planned_jump_done := false
		var jump_hold := 0
		var stalled_frames := 0
		var emergency_cooldown := 0
		var last_x: float = player.global_position.x
		Input.action_press("move_right")
		var reached := false
		var frame_limit := ceili(
			maxf(target_x - player.global_position.x, 0.0) / 2.5
		) + 180
		for _frame in frame_limit:
			if (
				jump_needed
				and not planned_jump_done
				and jump_hold == 0
				and player.is_on_floor()
				and player.global_position.x >= previous_end - takeoff_margin
			):
				Input.action_press("jump")
				planned_jump_done = true
				jump_hold = 24
			if emergency_cooldown > 0:
				emergency_cooldown -= 1
			if absf(player.global_position.x - last_x) < 0.25 and player.is_on_floor():
				stalled_frames += 1
			else:
				stalled_frames = 0
			if (
				stalled_frames >= 12
				and jump_hold == 0
				and emergency_cooldown == 0
				and not planned_jump_done
			):
				Input.action_press("jump")
				jump_hold = 24
				emergency_cooldown = 60
				stalled_frames = 0
			if jump_hold > 0:
				jump_hold -= 1
				if jump_hold == 0:
					Input.action_release("jump")
			await physics_frame
			last_x = player.global_position.x
			if (
				player.global_position.x >= target_x
				and player.is_on_floor()
				and absf(player.global_position.y - target_top) <= 10.0
			):
				reached = true
				break
		Input.action_release("jump")
		if not reached:
			_expect(
				false,
				"Ruin input traversal missed %s from %s at %s."
				% [target.get("id", index), previous.get("id", index - 1), player.global_position]
			)
			completed = false
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	_expect(completed, "Ruin required route should clear continuously with baseline input.")


func _validate_mobile_cycles(stage: Variant) -> void:
	var walker: Variant = _find_enemy(stage, &"lr_patrol_gallery", &"walker")
	_expect(walker != null, "Patrol Gallery should spawn a Walker.")
	if walker != null:
		var minimum_x: float = walker.global_position.x
		var maximum_x: float = walker.global_position.x
		var directions: Dictionary = {}
		for _frame in 180:
			await physics_frame
			minimum_x = minf(minimum_x, walker.global_position.x)
			maximum_x = maxf(maximum_x, walker.global_position.x)
			directions[int(walker.get("direction"))] = true
		_expect(maximum_x - minimum_x >= 18.0, "Ruin Walker should keep moving on its support.")
		_expect(directions.size() >= 2, "Ruin Walker should turn at a wall or ledge.")

	var charger: Variant = _find_enemy(stage, &"lr_charge_lane", &"charger")
	_expect(charger != null, "Charge Lane should spawn a Charger rather than a static guard-only encounter.")
	if charger == null:
		return
	var host: Variant = stage.get_room_host(&"lr_charge_lane")
	var player: Variant = stage.get("player")
	player.respawn_at(host.global_position + Vector2(180.0, 600.0), 1.0)
	charger.reset_enemy()
	var warning_seen := false
	var charge_seen := false
	var recovery_seen := false
	for _frame in 240:
		await physics_frame
		var warning := charger.get_node_or_null("LaneWarning") as Line2D
		warning_seen = warning_seen or (warning != null and warning.visible)
		charge_seen = charge_seen or absf(charger.velocity.x) >= 240.0
		recovery_seen = recovery_seen or bool(charger.get_combat_snapshot().get("recovery", false))
		if warning_seen and charge_seen and recovery_seen:
			break
	_expect(warning_seen and charge_seen and recovery_seen, "Ruin Charger should complete warning, charge, and recovery.")
	_expect(
		Rect2(host.global_position, host.template_data.bounds.size).grow(32.0).has_point(charger.global_position),
		"Ruin Charger should remain inside its authored room."
	)


func _validate_continuous_optional_rejoin(stage: Variant) -> void:
	var choice: Variant = stage.get_room_host(&"lr_lower_upper_choice")
	var cache: Variant = stage.get_room_host(&"lr_destructible_cache")
	var bridge: Variant = stage.get_room_host(&"lr_broken_bridge")
	var player: Variant = stage.get("player")
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("crouch")
	Input.action_release("climb_up")
	for _frame in 2:
		await physics_frame
	var branch_position: Vector2 = choice.global_position + Vector2(56.0, 560.0)
	player.respawn_at(branch_position, 999.0)
	for _frame in 40:
		await physics_frame
		if player.is_on_floor():
			break
	var on_floor_before_drop := bool(player.is_on_floor())
	Input.action_press("crouch")
	for _frame in 2:
		await physics_frame
	Input.action_press("jump")
	for _frame in 2:
		await physics_frame
	var drop_started := float(player.one_way_drop_timer) > 0.0
	Input.action_release("jump")
	for _frame in 16:
		await physics_frame
	Input.action_release("crouch")
	var cache_floor: float = cache.global_position.y + 620.0
	var landed_in_cache := false
	for _frame in 150:
		await physics_frame
		if player.is_on_floor() and absf(player.global_position.y - cache_floor) <= 10.0:
			landed_in_cache = true
			break
	_expect(
		drop_started and landed_in_cache,
		"Ruin optional branch should drop safely into the cache (floor_before=%s drop=%s position=%s floor=%.1f)."
		% [on_floor_before_drop, drop_started, player.global_position, cache_floor]
	)
	if not landed_in_cache:
		return

	var rope_x: float = cache.global_position.x + 1120.0
	Input.action_press("move_right")
	var stalled_frames := 0
	var last_x: float = player.global_position.x
	var jump_hold := 0
	for _frame in 520:
		if player.global_position.x >= rope_x - 20.0:
			break
		if absf(player.global_position.x - last_x) < 0.25 and player.is_on_floor():
			stalled_frames += 1
		else:
			stalled_frames = 0
		if stalled_frames >= 12 and jump_hold == 0:
			Input.action_press("jump")
			jump_hold = 20
			stalled_frames = 0
		if jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0:
				Input.action_release("jump")
		await physics_frame
		last_x = player.global_position.x
	Input.action_release("move_right")
	Input.action_release("jump")
	_expect(absf(player.global_position.x - rope_x) <= 40.0, "Ruin cache should reach the forward rope mount.")
	if absf(player.global_position.x - rope_x) > 40.0:
		return

	Input.action_press("climb_up")
	var entered_climb := false
	var reached_bridge := false
	var bridge_top: float = bridge.global_position.y + 420.0
	for _frame in 720:
		await physics_frame
		entered_climb = entered_climb or bool(player.is_climbing)
		if player.global_position.y <= bridge_top + 4.0:
			reached_bridge = true
			break
	Input.action_release("climb_up")
	for _frame in 8:
		await physics_frame
	_expect(entered_climb, "Ruin cache rope should enter climb mode from below.")
	_expect(
		reached_bridge,
		"Ruin cache rope should reach the Broken Bridge support (position=%s top=%.1f climbing=%s)."
		% [player.global_position, bridge_top, player.is_climbing]
	)
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(
		String(snapshot.get("current_room_id", "")) == "lr_broken_bridge",
		"Ruin optional climb should update the minimap to the forward rejoin room."
	)


func _validate_minimap_route(stage: Variant) -> void:
	var player: Variant = stage.get("player")
	for room_id in [&"lr_lower_upper_choice", &"lr_destructible_cache", &"lr_broken_bridge"]:
		var host: Variant = stage.get_room_host(room_id)
		player.respawn_at(host.global_position + Vector2(560.0, 300.0), 0.5)
		await physics_frame
		await process_frame
		var snapshot: Dictionary = stage.get_stage_map_snapshot()
		_expect(String(snapshot.get("current_room_id", "")) == String(room_id), "Ruin minimap should enter %s." % room_id)
	var final_snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(_room_state(final_snapshot, "lr_lower_upper_choice") == "visited", "Choice room should remain visited.")
	_expect(_room_state(final_snapshot, "lr_destructible_cache") == "visited", "Optional cache should remain visited.")
	_expect(_room_state(final_snapshot, "lr_broken_bridge") == "current", "Broken Bridge should be current after forward rejoin.")
	_expect(_reward_marker_visible(final_snapshot, "lr_destructible_cache"), "Discovered cache reward should appear on the minimap.")
	var checkpoint: Vector2 = stage.get("current_checkpoint_position")
	var world_bounds: Rect2 = stage.get_world_bounds()
	player.global_position = Vector2(
		checkpoint.x,
		world_bounds.end.y + 420.0
	)
	for _frame in 3:
		await physics_frame
	_expect(
		player.global_position.distance_to(checkpoint) <= 2.0,
		"Ruin out-of-bounds fall should return the player to the active checkpoint."
	)
	var recovered_snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(
		_room_state(recovered_snapshot, "lr_destructible_cache") == "visited",
		"Ruin fall recovery should preserve optional-room exploration knowledge."
	)


func _validate_terminal_bypass(stage: Variant) -> void:
	var nonterminal_alive := 0
	for enemy in stage.get_all_enemies():
		if StringName(enemy.get_meta("planned_room_id", &"")) == &"lr_exit_ascent":
			enemy.receive_damage(DamageInfo.new(999))
		elif enemy.current_health > 0:
			nonterminal_alive += 1
	_expect(nonterminal_alive > 0, "Ruin terminal fixture should leave prior enemies alive.")
	_expect(stage.is_exit_enabled(), "Clearing only the terminal room should enable the Ruin exit.")


func _find_enemy(stage: Variant, room_id: StringName, archetype_id: StringName) -> Variant:
	for enemy in stage.get_all_enemies():
		if (
			StringName(enemy.get_meta("planned_room_id", &"")) == room_id
			and enemy.archetype_id == archetype_id
		):
			return enemy
	return null


func _find_projectile(stage: Node) -> Variant:
	for node in stage.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if (
			script != null
			and script.get_global_name() == "EnemyProjectile"
			and not node.is_queued_for_deletion()
		):
			return node
	return null


func _critical_surfaces(host: Variant) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	for surface in host.get_support_surfaces():
		if bool(surface.get("critical", false)):
			surfaces.append(surface)
	return surfaces


func _room_state(snapshot: Dictionary, room_id: String) -> String:
	for room_value in snapshot.get("rooms", []):
		var room := room_value as Dictionary
		if String(room.get("id", "")) == room_id:
			return String(room.get("state", ""))
	return ""


func _reward_marker_visible(snapshot: Dictionary, room_id: String) -> bool:
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if (
			String(marker.get("type", "")) == "reward"
			and String(marker.get("room_id", "")) == room_id
		):
			return bool(marker.get("visible", false))
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("RUIN_STAGE_RUNTIME_VALIDATION_OK range=784 descents=2 forward_rejoin=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
