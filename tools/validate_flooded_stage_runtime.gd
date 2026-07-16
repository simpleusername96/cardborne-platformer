extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const RUN_SEED := 2207

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "Flooded runtime fixture needs RunState.")
	if _run_state == null:
		_finish()
		return
	_expect(bool(_run_state.call("start_new_run", 0, RUN_SEED)), "Flooded runtime fixture should start a run.")
	_run_state.set("current_stage_index", 1)

	var packed := load(STAGE_PATH) as PackedScene
	var stage: Variant = packed.instantiate() if packed != null else null
	_expect(stage != null, "Flooded production stage should instantiate.")
	if stage == null:
		_finish()
		return
	root.add_child(stage)
	for _frame in 4:
		await process_frame
		await physics_frame
	_expect(stage.is_setup_complete(), "Flooded production stage should finish runtime setup.")
	if not stage.is_setup_complete():
		stage.queue_free()
		_finish()
		return

	var runtime_case := OS.get_environment("FLOODED_RUNTIME_CASE")
	if runtime_case == "rope":
		await _validate_bidirectional_rope(stage)
	elif runtime_case == "optional":
		await _validate_optional_forward_rejoin(stage)
	elif runtime_case == "combat":
		await _validate_pump_combat_cycles(stage)
	elif runtime_case == "route":
		_set_runtime_pressure(stage, false)
		await _validate_continuous_required_route(stage)
	else:
		_validate_composition(stage)
		_validate_forward_rejoin(stage)
		_validate_room_intent(stage)
		_set_runtime_pressure(stage, false)
		await _validate_continuous_required_route(stage)
		await _validate_bidirectional_rope(stage)
		await _validate_optional_forward_rejoin(stage)
		await _validate_real_hazard_reset(stage)
		_set_runtime_pressure(stage, true)
		await _validate_pump_combat_cycles(stage)
		await _validate_minimap_and_terminal_bypass(stage)

	_release_inputs()
	stage.queue_free()
	await process_frame
	_finish()


func _validate_composition(stage: Variant) -> void:
	var metrics: Dictionary = stage.get_composition_metrics()
	_expect(not stage.is_exit_enabled(), "Flooded shelter exit should start locked before arrival.")
	_expect(float(metrics.get("critical_route_vertical_range", 0.0)) >= 720.0, "Flooded range should remain at least 720 px.")
	_expect(int(metrics.get("actual_enemy_count", 0)) >= 10, "Flooded should retain at least ten required-route enemies.")
	_expect(int(metrics.get("required_room_count", 0)) == 7, "Flooded should retain seven required rooms.")
	_expect(int(metrics.get("meaningful_descent_transitions", 0)) >= 3, "Flooded should descend meaningfully at least three times.")
	_expect(int(metrics.get("meaningful_ascent_transitions", 0)) >= 3, "Flooded should ascend meaningfully at least three times.")
	_expect(int(metrics.get("forward_rejoin_count", 0)) == 1, "Flooded optional route should forward-rejoin once.")
	_expect(int(metrics.get("same_hub_return_count", -1)) == 0, "Flooded should not retain a same-hub optional return.")
	_expect(int(metrics.get("max_near_limit_chain", -1)) <= 1, "Flooded should not chain near-limit jumps.")


func _validate_forward_rejoin(stage: Variant) -> void:
	var found := false
	for connection in stage.get_stage_plan().get_connections():
		if connection.id != &"optional_return_0":
			continue
		found = true
		_expect(connection.from_room_id == &"fw_sunken_cache", "Flooded return should leave the Sunken Cache.")
		_expect(connection.to_room_id == &"fw_pump_gallery", "Flooded return should land in Pump Gallery.")
		_expect(connection.to_socket_id == &"pump_optional_rejoin", "Flooded return should use the pump rope socket.")
	_expect(found, "Flooded should retain its optional return connection.")


func _validate_room_intent(stage: Variant) -> void:
	var entry: Variant = stage.get_room_host(&"fw_flooded_entry")
	var rope: Variant = stage.get_room_host(&"fw_rope_shaft")
	var poison: Variant = stage.get_room_host(&"fw_poison_timing")
	var basin: Variant = stage.get_room_host(&"fw_leaper_basin")
	var choice: Variant = stage.get_room_host(&"fw_lower_upper_choice")
	var cache: Variant = stage.get_room_host(&"fw_sunken_cache")
	var pump: Variant = stage.get_room_host(&"fw_pump_gallery")
	var shelter: Variant = stage.get_room_host(&"fw_exit_shelter")
	_expect(
		entry != null and rope != null and poison != null and basin != null
			and choice != null and cache != null and pump != null and shelter != null,
		"Flooded authored room hosts should exist."
	)
	if (
		entry == null or rope == null or poison == null or basin == null
		or choice == null or cache == null or pump == null or shelter == null
	):
		return
	_expect(entry.get_node_or_null("Anchors/Objective/PumpPreview") != null, "Flooded entry should preview the final pump.")
	_expect(
		bool(rope.get_node("Validation").get_meta("required_bidirectional", false)),
		"Rope Shaft should declare bidirectional traversal."
	)
	_expect(poison.get_node_or_null("Anchors/Objective/WaitPad") != null, "Poison timing should own a wait pad.")
	_expect(poison.get_node_or_null("Anchors/Objective/NextSafeDestination") != null, "Poison timing should preview its destination.")
	var basin_validation: Node = basin.get_node("Validation")
	_expect(bool(basin_validation.get_meta("previewed_commitment", false)), "Leaper basin should preview its drop.")
	_expect(
		(basin_validation.get_meta("reachable_destination_ids", []) as Array).size() >= 2,
		"Leaper basin should publish multiple destinations."
	)
	_expect(
		(choice.get_node("Validation").get_meta("route_difference_axes", []) as Array).size() >= 2,
		"Flooded choice routes should differ on at least two axes."
	)
	_expect(
		cache.get_node("Validation").get_meta("forward_rejoin_room", &"") == &"fw_pump_gallery",
		"Sunken Cache should declare its forward rejoin."
	)
	_expect(pump.get_node_or_null("Terrain/CoverWall") != null, "Pump Gallery should own solid shooter cover.")
	_expect(pump.get_node_or_null("Anchors/Recovery/GalleryMidRecovery") != null, "Pump Gallery should own a mid-climb recovery.")
	_expect(shelter.get_node("Validation").get_meta("terminal_policy", &"") == &"arrival", "Shelter should use arrival release.")
	_expect(
		shelter.get_node_or_null("Anchors/Objective/ForgeStation") == null
			and shelter.get_node_or_null("Anchors/Objective/ShopStation") == null,
		"Shelter should remain facility-free."
	)
	for node in stage.find_children("*", "", true, false):
		_expect(not node is MovingPlatform, "Flooded required route should not add moving platforms.")


func _validate_continuous_required_route(stage: Variant) -> void:
	var player: Variant = stage.get("player")
	var surfaces: Array = stage.get_critical_surface_contract()
	_expect(surfaces.size() >= 2, "Flooded continuous traversal needs critical supports.")
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
		var target_x := target_start + minf(float(target["width"]) * 0.35, 92.0)
		var rise := float(previous["top"]) - target_top
		var gap := maxf(target_start - previous_end, 0.0)
		var jump_needed := rise > 8.0 or gap > 16.0
		var jump_hold := 0
		var jump_cooldown := 0
		var stalled_frames := 0
		var last_x: float = player.global_position.x
		var reached := false
		var braking_for_landing := false
		Input.action_press("move_right")
		var frame_limit := ceili(maxf(target_x - player.global_position.x, 0.0) / 2.4) + 240
		for _frame in frame_limit:
			if jump_cooldown > 0:
				jump_cooldown -= 1
			var near_takeoff: bool = player.global_position.x >= previous_end - 30.0
			if (
				player.is_on_floor()
				and jump_hold == 0
				and jump_cooldown == 0
				and ((jump_needed and near_takeoff) or stalled_frames >= 12)
			):
				Input.action_press("jump")
				jump_hold = 24
				jump_cooldown = 54
				stalled_frames = 0
			if jump_hold > 0:
				jump_hold -= 1
				if jump_hold == 0:
					Input.action_release("jump")
			await physics_frame
			if absf(player.global_position.x - last_x) < 0.25 and player.is_on_floor():
				stalled_frames += 1
			else:
				stalled_frames = 0
			last_x = player.global_position.x
			if not jump_needed and player.global_position.x >= target_x and not braking_for_landing:
				Input.action_release("move_right")
				braking_for_landing = true
			if (
				player.global_position.x >= target_x
				and player.is_on_floor()
				and absf(player.global_position.y - target_top) <= 12.0
			):
				reached = true
				break
			if braking_for_landing and player.is_on_floor() and player.global_position.x < target_x:
				Input.action_press("move_right")
				braking_for_landing = false
		Input.action_release("jump")
		if not reached:
			_expect(
				false,
				"Flooded input traversal missed %s from %s at %s (target_x=%.1f target_top=%.1f mask=%d climbing=%s)."
				% [
					target.get("id", index),
					previous.get("id", index - 1),
					player.global_position,
					target_x,
					target_top,
					player.collision_mask,
					player.is_climbing,
				]
			)
			completed = false
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	_expect(completed, "Flooded required route should clear continuously with baseline input.")


func _validate_bidirectional_rope(stage: Variant) -> void:
	_release_inputs()
	var host: Variant = stage.get_room_host(&"fw_rope_shaft")
	var rope: Variant = host.get_node_or_null("Anchors/Objective/RopeClimb") if host != null else null
	var player: Variant = stage.get("player")
	_expect(rope != null, "Flooded Rope Shaft should instantiate its climbable.")
	if rope == null:
		return
	var half_height: float = rope.climbable_size.y * 0.5
	var top_y: float = rope.global_position.y - half_height
	var bottom_y: float = rope.global_position.y + half_height

	player.respawn_at(Vector2(rope.global_position.x, bottom_y - 16.0), 999.0)
	for _frame in 3:
		await physics_frame
	Input.action_press("climb_up")
	var climbed_up := false
	for _frame in 260:
		await physics_frame
		climbed_up = climbed_up or bool(player.is_climbing)
		if player.global_position.y <= top_y + 14.0:
			break
	Input.action_release("climb_up")
	_expect(climbed_up and player.global_position.y <= top_y + 16.0, "Flooded rope should climb from bottom to top.")
	Input.action_press("move_left")
	Input.action_press("jump")
	for _frame in 2:
		await physics_frame
	Input.action_release("jump")
	for _frame in 18:
		await physics_frame
	Input.action_release("move_left")
	_expect(not player.is_climbing and player.global_position.x < rope.global_position.x - 8.0, "Rope top should allow a lateral dismount.")

	player.respawn_at(Vector2(rope.global_position.x, top_y + 20.0), 999.0)
	for _frame in 3:
		await physics_frame
	Input.action_press("climb_down")
	var climbed_down := false
	for _frame in 260:
		await physics_frame
		climbed_down = climbed_down or bool(player.is_climbing)
		if player.global_position.y >= bottom_y - 14.0:
			break
	Input.action_release("climb_down")
	_expect(climbed_down and player.global_position.y >= bottom_y - 18.0, "Flooded rope should descend from top to bottom.")
	Input.action_press("move_right")
	Input.action_press("jump")
	for _frame in 2:
		await physics_frame
	Input.action_release("jump")
	for _frame in 16:
		await physics_frame
	Input.action_release("move_right")
	_expect(not player.is_climbing, "Rope bottom should allow a clean dismount.")


func _validate_optional_forward_rejoin(stage: Variant) -> void:
	_release_inputs()
	var choice: Variant = stage.get_room_host(&"fw_lower_upper_choice")
	var cache: Variant = stage.get_room_host(&"fw_sunken_cache")
	var pump: Variant = stage.get_room_host(&"fw_pump_gallery")
	var player: Variant = stage.get("player")
	player.respawn_at(choice.global_position + Vector2(320.0, 560.0), 999.0)
	for _frame in 40:
		await physics_frame
		if player.is_on_floor():
			break
	Input.action_press("crouch")
	for _frame in 2:
		await physics_frame
	Input.action_press("jump")
	for _frame in 2:
		await physics_frame
	var drop_started := float(player.one_way_drop_timer) > 0.0
	Input.action_release("jump")
	for _frame in 14:
		await physics_frame
	Input.action_release("crouch")
	var cache_entry_top: float = cache.global_position.y + 220.0
	var landed := false
	for _frame in 180:
		await physics_frame
		if player.is_on_floor() and absf(player.global_position.y - cache_entry_top) <= 12.0:
			landed = true
			break
	_expect(
		drop_started and landed,
		"Flooded optional branch should drop onto the previewed cache shelf (drop=%s position=%s target=%.1f)."
		% [drop_started, player.global_position, cache_entry_top]
	)
	if not landed:
		return

	var rope_x: float = cache.global_position.x + 1280.0
	var exit_top: float = cache.global_position.y + 284.0
	var reached_rope := await _walk_right_to(player, rope_x - 18.0, exit_top, 720)
	_expect(reached_rope, "Sunken Cache should reach its forward return rope.")
	if not reached_rope:
		return
	Input.action_press("climb_up")
	var entered_climb := false
	var pump_top: float = pump.global_position.y + 620.0
	for _frame in 520:
		await physics_frame
		entered_climb = entered_climb or bool(player.is_climbing)
		if player.global_position.y <= pump_top + 8.0:
			break
	Input.action_release("climb_up")
	_expect(entered_climb and player.global_position.y <= pump_top + 12.0, "Sunken Cache rope should reach Pump Gallery.")
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(
		String(snapshot.get("current_room_id", "")) == "fw_pump_gallery",
		"Forward climb should update the minimap to Pump Gallery."
	)


func _validate_real_hazard_reset(stage: Variant) -> void:
	var vent: Variant
	for hazard in stage.get_spawned_hazards():
		if hazard is TimedPoisonVent:
			vent = hazard
			break
	_expect(vent != null, "Flooded runtime should spawn the real poison vent.")
	if vent == null:
		return
	vent.set_physics_process(false)
	vent.reset_hazard()
	vent.advance_time(0.70)
	_expect(vent.get_runtime_snapshot()["state"] == &"active", "Real poison vent should enter its active state.")
	stage.respawn_player("flooded_hazard_retry")
	await process_frame
	await physics_frame
	var reset_snapshot: Dictionary = vent.get_runtime_snapshot()
	_expect(reset_snapshot["state"] == &"warning", "Checkpoint retry should reset poison to warning.")
	_expect(not reset_snapshot["damage_active"], "Checkpoint retry should restore a non-damaging poison state.")
	vent.advance_time(0.70)
	stage.reset_runtime_hazards()
	var explicit_reset: Dictionary = vent.get_runtime_snapshot()
	_expect(explicit_reset["state"] == &"warning", "Explicit stage hazard reset should be deterministic.")
	vent.set_physics_process(true)


func _validate_pump_combat_cycles(stage: Variant) -> void:
	var host: Variant = stage.get_room_host(&"fw_pump_gallery")
	var player: Variant = stage.get("player")
	var walker: Variant = _find_enemy(stage, &"fw_pump_gallery", &"walker")
	var charger: Variant = _find_enemy(stage, &"fw_pump_gallery", &"charger")
	var leaper: Variant = _find_enemy(stage, &"fw_pump_gallery", &"leaper")
	var shooter: Variant = _find_enemy(stage, &"fw_pump_gallery", &"shooter")
	_expect(
		host != null and walker != null and charger != null and leaper != null and shooter != null,
		"Pump Gallery should spawn walker, charger, leaper, and shooter."
	)
	if host == null or walker == null or charger == null or leaper == null or shooter == null:
		return
	for enemy in stage.get_all_enemies():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	shooter.process_mode = Node.PROCESS_MODE_INHERIT
	shooter.reset_enemy()
	_run_state.call("revive_player")
	player.respawn_at(host.global_position + Vector2(240.0, 620.0), 0.0)
	var origin: Vector2 = shooter.global_position + Vector2(0.0, -28.0)
	var ray := PhysicsRayQueryParameters2D.create(origin, player.global_position, 1)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit: Dictionary = host.get_world_2d().direct_space_state.intersect_ray(ray)
	_expect(
		not hit.is_empty() and String((hit.get("collider") as Node).name) == "CoverWall",
		"Pump lower lane should be blocked by the authored solid cover."
	)
	var health_before := int(_run_state.get("current_health"))
	var warning_seen := false
	for _frame in 260:
		await physics_frame
		var warning := shooter.get_node_or_null("AimWarning") as Line2D
		warning_seen = warning_seen or (warning != null and warning.visible)
		if warning_seen and int(shooter.get("_shots_fired")) >= 1:
			break
	for _frame in 100:
		await physics_frame
	_expect(warning_seen and int(shooter.get("_shots_fired")) >= 1, "Pump Shooter should warn and fire into cover.")
	_expect(int(_run_state.get("current_health")) == health_before, "Pump cover should prevent projectile damage.")
	shooter.process_mode = Node.PROCESS_MODE_DISABLED

	walker.process_mode = Node.PROCESS_MODE_INHERIT
	walker.reset_enemy()
	var min_x: float = walker.global_position.x
	var max_x: float = walker.global_position.x
	var directions: Dictionary = {}
	for _frame in 220:
		await physics_frame
		min_x = minf(min_x, walker.global_position.x)
		max_x = maxf(max_x, walker.global_position.x)
		directions[int(walker.get("direction"))] = true
	_expect(max_x - min_x >= 24.0 and directions.size() >= 2, "Pump Walker should patrol and reverse without getting stuck.")
	walker.process_mode = Node.PROCESS_MODE_DISABLED

	charger.process_mode = Node.PROCESS_MODE_INHERIT
	charger.reset_enemy()
	player.respawn_at(host.global_position + Vector2(180.0, 620.0), 999.0)
	var charge_warning := false
	var charge_active := false
	var charge_recovery := false
	for _frame in 300:
		await physics_frame
		var warning := charger.get_node_or_null("LaneWarning") as Line2D
		if warning != null and warning.visible:
			_expect(
				warning.points.size() == 2
				and warning.points[1].length() <= 128.0 + 0.1,
				"Pump Charger warning should remain local."
			)
		charge_warning = charge_warning or (warning != null and warning.visible)
		charge_active = charge_active or absf(charger.velocity.x) >= 240.0
		charge_recovery = charge_recovery or bool(charger.get_combat_snapshot().get("recovery", false))
		if charge_warning and charge_active and charge_recovery:
			break
	_expect(charge_warning and charge_active and charge_recovery, "Pump Charger should complete warning, charge, and recovery.")
	charger.process_mode = Node.PROCESS_MODE_DISABLED

	leaper.process_mode = Node.PROCESS_MODE_INHERIT
	leaper.reset_enemy()
	var destinations: Array[Vector2] = []
	var player_targets := [
		host.global_position + Vector2(280.0, 620.0),
		host.global_position + Vector2(920.0, 492.0),
		host.global_position + Vector2(280.0, 620.0),
	]
	for cycle in player_targets.size():
		leaper.reset_enemy()
		player.respawn_at(player_targets[cycle], 999.0)
		for _frame in 2:
			await physics_frame
		var warning_target := Vector2.INF
		for _frame in 180:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if bool(snapshot.get("warning", false)):
				warning_target = snapshot.get("landing_target", Vector2.INF)
				break
		_expect(warning_target != Vector2.INF, "Pump Leaper cycle %d should choose a destination." % cycle)
		if warning_target == Vector2.INF:
			break
		destinations.append(warning_target)
		var recovered := false
		for _frame in 220:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if bool(snapshot.get("recovery", false)) and leaper.is_on_floor():
				recovered = true
				break
		_expect(recovered, "Pump Leaper cycle %d should land and recover." % cycle)
		for _frame in 90:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if (
				not bool(snapshot.get("warning", false))
				and not bool(snapshot.get("active", false))
				and not bool(snapshot.get("recovery", false))
			):
				break
	var unique_xs: Array[int] = []
	for destination in destinations:
		var key := roundi(destination.x / 24.0)
		if not unique_xs.has(key):
			unique_xs.append(key)
	_expect(unique_xs.size() >= 2, "Pump Leaper should alternate between reachable destinations.")
	_expect(
		Rect2(host.global_position, host.template_data.bounds.size).grow(48.0).has_point(leaper.global_position),
		"Pump Leaper should remain inside its authored encounter."
	)
	for enemy in stage.get_all_enemies():
		enemy.process_mode = Node.PROCESS_MODE_INHERIT


func _validate_minimap_and_terminal_bypass(stage: Variant) -> void:
	var player: Variant = stage.get("player")
	for room_id in [&"fw_lower_upper_choice", &"fw_sunken_cache", &"fw_pump_gallery", &"fw_exit_shelter"]:
		var host: Variant = stage.get_room_host(room_id)
		var local_position := (
			Vector2(180.0, 620.0)
			if room_id == &"fw_exit_shelter"
			else Vector2(560.0, 300.0)
		)
		player.respawn_at(host.global_position + local_position, 999.0)
		for _frame in 3:
			await physics_frame
			await process_frame
		var snapshot: Dictionary = stage.get_stage_map_snapshot()
		_expect(String(snapshot.get("current_room_id", "")) == String(room_id), "Flooded minimap should enter %s." % room_id)
	var final_snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(_room_state(final_snapshot, "fw_lower_upper_choice") == "visited", "Flooded choice should remain visited.")
	_expect(_room_state(final_snapshot, "fw_sunken_cache") == "visited", "Sunken Cache should remain visited.")
	_expect(_room_state(final_snapshot, "fw_pump_gallery") == "visited", "Pump Gallery should remain visited.")
	_expect(_room_state(final_snapshot, "fw_exit_shelter") == "current", "Exit Shelter should be current.")
	_expect(_reward_marker_visible(final_snapshot, "fw_sunken_cache"), "Discovered Sunken Cache reward should appear.")
	_expect(_marker_visible(final_snapshot, "checkpoint"), "Shelter checkpoint should appear after activation.")

	var alive_before_exit := 0
	for enemy in stage.get_all_enemies():
		if enemy.current_health > 0:
			alive_before_exit += 1
	_expect(alive_before_exit > 0, "Flooded terminal fixture should leave prior enemies alive.")
	_expect(stage.get_exit_policy_id() == &"arrival", "Flooded exit should use arrival policy.")
	_expect(stage.is_exit_enabled(), "Entering the shelter should enable the exit without global combat clear.")

	var checkpoint: Vector2 = stage.get("current_checkpoint_position")
	var bounds: Rect2 = stage.get_world_bounds()
	player.global_position = Vector2(checkpoint.x, bounds.end.y + 420.0)
	for _frame in 4:
		await physics_frame
	_expect(player.global_position.distance_to(checkpoint) <= 2.0, "Flooded fall should recover at the active shelter checkpoint.")
	_expect(
		_room_state(stage.get_stage_map_snapshot(), "fw_sunken_cache") == "visited",
		"Flooded retry should preserve optional exploration knowledge."
	)


func _walk_right_to(player: Variant, target_x: float, target_top: float, frame_limit: int) -> bool:
	Input.action_press("move_right")
	var jump_hold := 0
	var jump_cooldown := 0
	var stalled := 0
	var last_x: float = player.global_position.x
	for _frame in frame_limit:
		if jump_cooldown > 0:
			jump_cooldown -= 1
		if player.is_on_floor() and jump_hold == 0 and jump_cooldown == 0 and stalled >= 10:
			Input.action_press("jump")
			jump_hold = 24
			jump_cooldown = 48
			stalled = 0
		if jump_hold > 0:
			jump_hold -= 1
			if jump_hold == 0:
				Input.action_release("jump")
		await physics_frame
		if absf(player.global_position.x - last_x) < 0.25 and player.is_on_floor():
			stalled += 1
		else:
			stalled = 0
		last_x = player.global_position.x
		if (
			player.global_position.x >= target_x
			and absf(player.global_position.y - target_top) <= 14.0
		):
			Input.action_release("move_right")
			Input.action_release("jump")
			return true
	Input.action_release("move_right")
	Input.action_release("jump")
	return false


func _set_runtime_pressure(stage: Variant, enabled: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	for enemy in stage.get_all_enemies():
		enemy.process_mode = mode
	for hazard in stage.get_spawned_hazards():
		hazard.process_mode = mode


func _find_enemy(stage: Variant, room_id: StringName, archetype_id: StringName) -> Variant:
	for enemy in stage.get_all_enemies():
		if (
			StringName(enemy.get_meta("planned_room_id", &"")) == room_id
			and enemy.archetype_id == archetype_id
		):
			return enemy
	return null


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


func _marker_visible(snapshot: Dictionary, marker_type: String) -> bool:
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if String(marker.get("type", "")) == marker_type and bool(marker.get("visible", false)):
			return true
	return false


func _release_inputs() -> void:
	for action in ["move_left", "move_right", "jump", "crouch", "climb_up", "climb_down", "dash"]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_STAGE_RUNTIME_VALIDATION_OK range=896 descents=12 ascents=4 forward_rejoin=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
