extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const RUN_SEED := 41_000

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "Broken Sanctum runtime fixture needs RunState.")
	if _run_state == null:
		_finish()
		return
	_expect(
		bool(_run_state.call("start_new_run", 0, RUN_SEED)),
		"Broken Sanctum runtime fixture should start a run."
	)
	_run_state.set("current_stage_index", 2)

	var packed := load(STAGE_PATH) as PackedScene
	var stage: Variant = packed.instantiate() if packed != null else null
	_expect(stage != null, "Broken Sanctum production stage should instantiate.")
	if stage == null:
		_finish()
		return
	root.add_child(stage)
	for _frame in 4:
		await process_frame
		await physics_frame
	_expect(stage.is_setup_complete(), "Broken Sanctum production stage should finish setup.")
	if not stage.is_setup_complete():
		stage.queue_free()
		_finish()
		return

	var runtime_case := OS.get_environment("SANCTUM_RUNTIME_CASE")
	if runtime_case == "gate":
		_set_runtime_pressure(stage, false)
		await _validate_gate_shortcut(stage)
	elif runtime_case == "route":
		_set_runtime_pressure(stage, false)
		await _validate_continuous_required_route(stage)
	elif runtime_case == "early":
		_set_runtime_pressure(stage, false)
		await _validate_early_optional_loop(stage)
	elif runtime_case == "late":
		_set_runtime_pressure(stage, false)
		await _validate_late_optional_loop(stage)
	elif runtime_case == "combat":
		await _validate_combat_terrain_roles(stage)
	else:
		_validate_composition(stage)
		_validate_topology_and_room_intent(stage)
		_validate_initial_minimap(stage)
		_set_runtime_pressure(stage, false)
		await _validate_gate_shortcut(stage)
		await _validate_continuous_required_route(stage)
		await _validate_early_optional_loop(stage)
		await _validate_late_optional_loop(stage)
		await _validate_combat_terrain_roles(stage)
		await _validate_minimap_retry_and_terminal_bypass(stage)

	_release_inputs()
	stage.queue_free()
	await process_frame
	_finish()


func _validate_composition(stage: Variant) -> void:
	var metrics: Dictionary = stage.get_composition_metrics()
	_expect(float(metrics.get("critical_route_vertical_range", 0.0)) >= 720.0, "Sanctum range should remain at least 720 px.")
	_expect(int(metrics.get("actual_enemy_count", 0)) >= 12, "Sanctum should retain at least twelve required-route enemies.")
	_expect(int(metrics.get("required_room_count", 0)) == 9, "Sanctum should retain nine required rooms.")
	_expect(int(metrics.get("forward_rejoin_count", 0)) == 2, "Both Sanctum optional routes should forward-rejoin.")
	_expect(int(metrics.get("same_hub_return_count", -1)) == 0, "Sanctum should not retain same-hub optional returns.")
	_expect(int(metrics.get("max_near_limit_chain", -1)) == 0, "Sanctum should remove repeated near-limit traversal.")
	_expect(int(metrics.get("meaningful_descent_transitions", 0)) >= 2, "Sanctum should include meaningful release descents.")
	_expect(int(metrics.get("multi_elevation_combat_room_count", 0)) >= 3, "Sanctum should retain distinct multi-height combat rooms.")


func _validate_topology_and_room_intent(stage: Variant) -> void:
	var expected_edges := {
		"optional_branch_0": ["bs_gate_switch_loop", "bs_material_crypt", "gate_material_branch", "material_crypt_gate_branch"],
		"optional_return_0": ["bs_material_crypt", "bs_volatile_nave", "material_crypt_nave_return", "nave_crypt_rejoin"],
		"optional_branch_1": ["bs_recovery_cloister", "bs_reliquary_cache", "cloister_reliquary_branch", "reliquary_cache_cloister_branch"],
		"optional_return_1": ["bs_reliquary_cache", "bs_sentry_crossfire", "reliquary_cache_sentry_return", "sentry_reliquary_rejoin"],
	}
	var found: Dictionary = {}
	for connection in stage.get_stage_plan().get_connections():
		var key := String(connection.id)
		if not expected_edges.has(key):
			continue
		var expected: Array = expected_edges[key]
		found[key] = true
		_expect(
			String(connection.from_room_id) == expected[0]
			and String(connection.to_room_id) == expected[1]
			and String(connection.from_socket_id) == expected[2]
			and String(connection.to_socket_id) == expected[3],
			"Sanctum edge %s should match its distributed forward route." % key
		)
	_expect(found.size() == expected_edges.size(), "Sanctum should retain both distributed optional loops.")

	var gate: Variant = stage.get_room_host(&"bs_gate_switch_loop")
	var crypt: Variant = stage.get_room_host(&"bs_material_crypt")
	var nave: Variant = stage.get_room_host(&"bs_volatile_nave")
	var transfer: Variant = stage.get_room_host(&"bs_twin_reliquary_choice")
	var fractured: Variant = stage.get_room_host(&"bs_fractured_gallery")
	var recovery: Variant = stage.get_room_host(&"bs_recovery_cloister")
	var cache: Variant = stage.get_room_host(&"bs_reliquary_cache")
	var sentry: Variant = stage.get_room_host(&"bs_sentry_crossfire")
	var exit_room: Variant = stage.get_room_host(&"bs_exit_ascent")
	_expect(
		null not in [gate, crypt, nave, transfer, fractured, recovery, cache, sentry, exit_room],
		"Sanctum authored room hosts should exist."
	)
	if null in [gate, crypt, nave, transfer, fractured, recovery, cache, sentry, exit_room]:
		return
	_expect(gate.get_node_or_null("Anchors/Objective/GateController") is SwitchGate, "Gate loop should use the shared SwitchGate.")
	_expect(gate.get_node_or_null("Anchors/Objective/MaterialBranchRead") != null, "Gate loop should reveal the early branch after the seal.")
	_expect(
		StringName(crypt.get_node("Validation").get_meta("forward_rejoin_room", &""))
			== &"bs_volatile_nave",
		"Material Crypt should forward-rejoin the Nave."
	)
	_expect(nave.get_node_or_null("Anchors/Objective/CryptRejoinRead") != null, "Volatile Nave should own the crypt rejoin landing.")
	_expect(bool(transfer.get_node("Validation").get_meta("main_route_transfer", false)), "Twin Reliquary should be a main-route transfer.")
	_expect(
		(fractured.get_node("Validation").get_meta("enemy_terrain_relations", []) as Array).size() == 3,
		"Fractured Gallery should publish one terrain relation per enemy role."
	)
	_expect(bool(recovery.get_node("Validation").get_meta("safe_room", false)), "Recovery Cloister should remain an actual safe room.")
	_expect(recovery.get_node_or_null("Anchors/Objective/ReliquaryBranchRope") is Climbable, "Recovery Cloister should own the late branch rope.")
	_expect(
		StringName(cache.get_node("Validation").get_meta("forward_rejoin_room", &""))
			== &"bs_sentry_crossfire",
		"Reliquary Cache should forward-rejoin Sentry Crossfire."
	)
	_expect(sentry.get_node_or_null("OneWay/TransferWindow") != null, "Sentry Crossfire should own a transfer window.")
	_expect(sentry.get_node_or_null("Terrain/WestCover") != null and sentry.get_node_or_null("Terrain/EastCover") != null, "Sentry Crossfire should own two solid cover bands.")
	_expect(exit_room.get_exit_portal() != null, "Sanctum exit ascent should retain its typed terminal portal.")
	for node in stage.find_children("*", "", true, false):
		_expect(
			not node.name in [&"ForgeStation", &"ShopStation"],
			"Normal Sanctum rooms must remain facility-free."
		)


func _validate_initial_minimap(stage: Variant) -> void:
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(not snapshot.is_empty(), "Sanctum should publish a minimap snapshot.")
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		var marker_type := String(marker.get("type", ""))
		if marker_type == "reward":
			_expect(not bool(marker.get("visible", false)), "Undiscovered Sanctum rewards should remain hidden.")
		if marker_type == "gate":
			_expect(not bool(marker.get("visible", false)), "Undiscovered Sanctum gate should remain hidden.")
		_expect(marker_type not in ["enemy", "hazard"], "Sanctum minimap must not become an enemy radar.")


func _validate_gate_shortcut(stage: Variant) -> void:
	_release_inputs()
	var host: Variant = stage.get_room_host(&"bs_gate_switch_loop")
	var player: Variant = stage.get("player")
	var gate := host.get_node_or_null("Anchors/Objective/GateController") as SwitchGate
	var switch := gate.get_node_or_null("Switch") as SwitchInteractable if gate != null else null
	_expect(gate != null and switch != null, "Gate shortcut fixture needs its gate and switch.")
	if gate == null or switch == null:
		return
	gate.reset_gate()
	player.respawn_at(host.global_position + Vector2(700.0, 492.0), 999.0)
	for _frame in 5:
		await physics_frame
	Input.action_press("move_right")
	for _frame in 42:
		await physics_frame
	Input.action_release("move_right")
	var closed_x: float = player.global_position.x
	_expect(not gate.is_open and closed_x < host.global_position.x + 790.0, "Closed gate should stop the direct ground route.")

	player.respawn_at(host.global_position + Vector2(620.0, 492.0), 999.0)
	for _frame in 3:
		await physics_frame
	switch.interact(player)
	await create_timer(gate.open_delay + 0.08).timeout
	await physics_frame
	_expect(gate.is_open, "Interacting with the authored switch should open the shortcut.")
	var gate_body := gate.get_node_or_null("GateBody") as StaticBody2D
	_expect(gate_body != null and gate_body.collision_layer == 0, "Opened shortcut should remove its solid collision.")
	var passed := await _walk_right_to(
		player,
		host.global_position.x + 1080.0,
		host.global_position.y + 620.0,
		260
	)
	_expect(passed and player.global_position.x > closed_x + 220.0, "Opened gate should materially shorten traversal to the east side.")
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(_marker_state(snapshot, "gate") == "open", "Sanctum minimap gate marker should update to open.")


func _validate_continuous_required_route(stage: Variant) -> void:
	_release_inputs()
	var gate_host: Variant = stage.get_room_host(&"bs_gate_switch_loop")
	var gate := gate_host.get_node_or_null("Anchors/Objective/GateController") as SwitchGate
	if gate != null and not gate.is_open:
		gate.open_delay = 0.0
		gate.open_gate()
		await process_frame
	var player: Variant = stage.get("player")
	var surfaces: Array = stage.get_critical_surface_contract()
	_expect(surfaces.size() >= 2, "Sanctum continuous traversal needs critical supports.")
	if surfaces.size() < 2:
		return
	player.invulnerability_timer = 999.0
	var first := surfaces[0] as Dictionary
	player.respawn_at(
		Vector2(float(first["x"]) + minf(float(first["width"]) * 0.35, 92.0), float(first["top"])),
		999.0
	)
	for _frame in 4:
		await physics_frame
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
		Input.action_press("move_right")
		var frame_limit := ceili(maxf(target_x - player.global_position.x, 0.0) / 2.4) + 260
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
				jump_cooldown = 48
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
			if (
				player.global_position.x >= target_x
				and absf(player.global_position.y - target_top) <= 14.0
			):
				reached = true
				break
		Input.action_release("move_right")
		Input.action_release("jump")
		if not reached:
			completed = false
			_expect(
				false,
				"Sanctum continuous route should reach %s (position=%s target=(%.1f, %.1f))."
				% [target.get("id", index), player.global_position, target_x, target_top]
			)
			break
	_expect(completed, "Sanctum required route should clear continuously with baseline input.")


func _validate_early_optional_loop(stage: Variant) -> void:
	_release_inputs()
	var gate: Variant = stage.get_room_host(&"bs_gate_switch_loop")
	var crypt: Variant = stage.get_room_host(&"bs_material_crypt")
	var nave: Variant = stage.get_room_host(&"bs_volatile_nave")
	var player: Variant = stage.get("player")
	player.respawn_at(gate.global_position + Vector2(840.0, 536.0), 999.0)
	for _frame in 30:
		await physics_frame
		if player.is_on_floor():
			break
	var drop_started := await _drop_through_one_way(player)
	var landing_top: float = crypt.global_position.y + 392.0
	var landed := await _wait_for_landing(player, landing_top, 220)
	_expect(
		drop_started and landed,
		"Material Crypt branch should drop onto its authored gate-entry shelf (position=%s target=%.1f)."
		% [player.global_position, landing_top]
	)
	if not landed:
		return
	var rope := crypt.get_node_or_null("Anchors/Objective/ReturnRope") as Climbable
	_expect(rope != null, "Material Crypt should own its Nave return rope.")
	if rope == null:
		return
	var rope_x: float = rope.global_position.x
	var rope_bottom: float = rope.global_position.y + rope.climbable_size.y * 0.5
	var rope_approach_x := rope_x - 40.0
	var reached_rope := await _walk_right_to(player, rope_approach_x, rope_bottom, 520)
	_expect(
		reached_rope,
		"Material Crypt should reach its Nave return rope (position=%s target=(%.1f, %.1f))."
		% [player.global_position, rope_approach_x, rope_bottom]
	)
	if not reached_rope:
		return
	Input.action_press("climb_up")
	var entered_climb := false
	var nave_top: float = nave.global_position.y + 620.0
	for _frame in 520:
		await physics_frame
		entered_climb = entered_climb or bool(player.is_climbing)
		if player.global_position.y <= nave_top + 10.0:
			break
	Input.action_release("climb_up")
	_expect(
		entered_climb and player.global_position.y <= nave_top + 14.0,
		"Material Crypt rope should reach Volatile Nave (entered=%s position=%s target_y=%.1f)."
		% [entered_climb, player.global_position, nave_top]
	)
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(String(snapshot.get("current_room_id", "")) == "bs_volatile_nave", "Early optional loop should update the minimap at its forward rejoin.")
	_expect(_reward_marker_visible(snapshot, "bs_material_crypt"), "Visited Material Crypt reward should appear on the minimap.")


func _validate_late_optional_loop(stage: Variant) -> void:
	_release_inputs()
	var recovery: Variant = stage.get_room_host(&"bs_recovery_cloister")
	var cache: Variant = stage.get_room_host(&"bs_reliquary_cache")
	var sentry: Variant = stage.get_room_host(&"bs_sentry_crossfire")
	var player: Variant = stage.get("player")
	var checkpoint := recovery.get_node_or_null("Anchors/Objective/SanctumCheckpoint") as StageCheckpoint
	_expect(checkpoint != null, "Late optional loop needs the recovery checkpoint.")
	if checkpoint != null:
		player.respawn_at(checkpoint.global_position, 999.0)
		for _frame in 5:
			await physics_frame
			await process_frame
	var rope := recovery.get_node_or_null("Anchors/Objective/ReliquaryBranchRope") as Climbable
	_expect(rope != null, "Recovery Cloister should expose the Reliquary rope.")
	if rope == null:
		return
	var bottom_y := rope.global_position.y + rope.climbable_size.y * 0.5
	player.respawn_at(Vector2(rope.global_position.x, bottom_y - 14.0), 999.0)
	for _frame in 3:
		await physics_frame
	Input.action_press("climb_up")
	var entered_climb := false
	var cache_top: float = cache.global_position.y + 620.0
	for _frame in 620:
		await physics_frame
		entered_climb = entered_climb or bool(player.is_climbing)
		if entered_climb and not player.is_climbing and player.global_position.y <= cache_top + 10.0:
			break
	Input.action_release("climb_up")
	var settled_on_cache := await _wait_for_landing(player, cache_top, 120)
	_expect(
		entered_climb
		and not player.is_climbing
		and settled_on_cache,
		"Recovery rope should enter and naturally dismount in the upper Reliquary."
	)
	var hatch := cache.get_node_or_null("Anchors/Objective/SentryDropReturn") as Marker2D
	_expect(hatch != null, "Reliquary Cache should own its Sentry drop marker.")
	if hatch == null:
		return
	var reached_hatch := await _walk_right_to(
		player,
		hatch.global_position.x,
		cache.global_position.y + 620.0,
		420
	)
	_expect(reached_hatch, "Reliquary Cache should reach its Sentry drop hatch.")
	if not reached_hatch:
		return
	var drop_started := await _drop_through_one_way(player)
	var sentry_top: float = sentry.global_position.y + 620.0
	var landed := await _wait_for_landing(player, sentry_top, 260)
	_expect(drop_started and landed, "Reliquary return should land in Sentry Crossfire.")
	for _frame in 4:
		await physics_frame
		await process_frame
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(
		String(snapshot.get("current_room_id", "")) == "bs_sentry_crossfire",
		"Late optional loop should update the minimap at Sentry Crossfire (current=%s position=%s)."
		% [snapshot.get("current_room_id", ""), player.global_position]
	)
	_expect(_reward_marker_visible(snapshot, "bs_reliquary_cache"), "Visited Reliquary reward should appear on the minimap.")
	_expect(
		_marker_visible(snapshot, "checkpoint"),
		"Activated Cloister checkpoint should remain visible (checkpoint=%s)."
		% stage.get("current_checkpoint_position")
	)
	if not _marker_visible(snapshot, "checkpoint"):
		print("SANCTUM_CHECKPOINT_MARKERS ", snapshot.get("markers", []))


func _validate_combat_terrain_roles(stage: Variant) -> void:
	for enemy in stage.get_all_enemies():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await _validate_fractured_combat(stage)
	await _validate_sentry_cover(stage)
	for enemy in stage.get_all_enemies():
		enemy.process_mode = Node.PROCESS_MODE_INHERIT


func _validate_fractured_combat(stage: Variant) -> void:
	var host: Variant = stage.get_room_host(&"bs_fractured_gallery")
	var player: Variant = stage.get("player")
	var charger: Variant = _find_enemy(stage, &"bs_fractured_gallery", &"charger")
	var leaper: Variant = _find_enemy(stage, &"bs_fractured_gallery", &"leaper")
	var shooter: Variant = _find_enemy(stage, &"bs_fractured_gallery", &"shooter")
	_expect(
		charger != null and leaper != null and shooter != null,
		"Fractured Gallery should spawn Charger, Leaper, and Shooter terrain roles."
	)
	if charger == null or leaper == null or shooter == null:
		var enemy_rows: Array[String] = []
		for enemy in stage.get_all_enemies():
			enemy_rows.append(
				"%s:%s"
				% [
					enemy.get_meta("planned_room_id", ""),
					enemy.archetype_id,
				]
			)
		print("SANCTUM_ENEMY_ROWS ", enemy_rows)
		return

	charger.process_mode = Node.PROCESS_MODE_INHERIT
	charger.reset_enemy()
	player.respawn_at(host.global_position + Vector2(180.0, 620.0), 999.0)
	var warning_seen := false
	var charge_seen := false
	var recovery_seen := false
	for _frame in 320:
		await physics_frame
		var snapshot: Dictionary = charger.get_combat_snapshot()
		var warning := charger.get_node_or_null("LaneWarning") as Line2D
		if warning != null and warning.visible:
			_expect(
				warning.points.size() == 2
				and warning.points[1].length() <= 128.0 + 0.1,
				"Fractured Charger warning should remain local."
			)
		warning_seen = warning_seen or (warning != null and warning.visible)
		charge_seen = charge_seen or absf(charger.velocity.x) >= 240.0
		recovery_seen = recovery_seen or bool(snapshot.get("recovery", false))
		if warning_seen and charge_seen and recovery_seen:
			break
	_expect(warning_seen and charge_seen and recovery_seen, "Fractured Charger should complete warning, lane pressure, and recovery.")
	charger.process_mode = Node.PROCESS_MODE_DISABLED

	leaper.process_mode = Node.PROCESS_MODE_INHERIT
	var destinations: Array[Vector2] = []
	for target in [
		host.global_position + Vector2(420.0, 492.0),
		host.global_position + Vector2(820.0, 556.0),
	]:
		leaper.reset_enemy()
		player.respawn_at(target, 999.0)
		for _frame in 3:
			await physics_frame
		var landing := Vector2.INF
		for _frame in 180:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if bool(snapshot.get("warning", false)):
				landing = snapshot.get("landing_target", Vector2.INF)
				break
		_expect(
			landing != Vector2.INF,
			"Fractured Leaper should select a reachable destination for target %s."
			% target
		)
		if landing != Vector2.INF:
			destinations.append(landing)
		for _frame in 240:
			await physics_frame
			var snapshot: Dictionary = leaper.get_combat_snapshot()
			if bool(snapshot.get("recovery", false)) and leaper.is_on_floor():
				break
	var unique_destinations: Array[int] = []
	for destination in destinations:
		var key := roundi(destination.x / 24.0)
		if not unique_destinations.has(key):
			unique_destinations.append(key)
	_expect(unique_destinations.size() >= 2, "Fractured Leaper should use more than one landing destination.")
	leaper.process_mode = Node.PROCESS_MODE_DISABLED

	var cover := host.get_node_or_null("Terrain/LineBreakCover") as StaticBody2D
	var origin: Vector2 = shooter.global_position + Vector2(0.0, -28.0)
	var target_position: Vector2 = host.global_position + Vector2(640.0, 556.0)
	var ray := PhysicsRayQueryParameters2D.create(origin, target_position, 1)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit: Dictionary = host.get_world_2d().direct_space_state.intersect_ray(ray)
	_expect(
		cover != null and not hit.is_empty() and hit.get("collider") == cover,
		"Fractured Shooter should relate to its solid line-break cover."
	)


func _validate_sentry_cover(stage: Variant) -> void:
	var host: Variant = stage.get_room_host(&"bs_sentry_crossfire")
	var player: Variant = stage.get("player")
	var sentries: Array = []
	for enemy in stage.get_all_enemies():
		if (
			StringName(enemy.get_meta("planned_room_id", &"")) == &"bs_sentry_crossfire"
			and enemy.archetype_id == &"sentry"
		):
			sentries.append(enemy)
	_expect(sentries.size() == 2, "Sentry Crossfire should spawn two staggered Sentries.")
	if sentries.is_empty():
		return
	sentries.sort_custom(
		func(left: Variant, right: Variant) -> bool:
			return left.global_position.x < right.global_position.x
	)
	var sentry: Variant = sentries[0]
	sentry.process_mode = Node.PROCESS_MODE_INHERIT
	sentry.reset_enemy()
	_run_state.call("revive_player")
	player.respawn_at(host.global_position + Vector2(250.0, 620.0), 0.0)
	if player.camera != null:
		player.camera.reset_smoothing()
	for _frame in 12:
		await physics_frame
		await process_frame
	var cover := host.get_node_or_null("Terrain/WestCover") as StaticBody2D
	var origin: Vector2 = sentry.global_position + Vector2(0.0, -28.0)
	var ray := PhysicsRayQueryParameters2D.create(origin, player.global_position, 1)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit: Dictionary = host.get_world_2d().direct_space_state.intersect_ray(ray)
	_expect(
		cover != null and not hit.is_empty() and hit.get("collider") == cover,
		"Crossfire entry should be protected by the authored solid cover."
	)
	var health_before := int(_run_state.get("current_health"))
	var warning_seen := false
	var shot_seen := false
	for _frame in 300:
		await physics_frame
		var snapshot: Dictionary = sentry.get_combat_snapshot()
		var warning := sentry.get_node_or_null("AimWarning") as Line2D
		if warning != null and warning.visible:
			_expect(
				warning.points.size() == 2
				and warning.points[1].length() <= 96.0 + 0.1,
				"Sentry startup should use a local direction cue."
			)
		warning_seen = warning_seen or bool(snapshot.get("warning", false))
		shot_seen = shot_seen or int(snapshot.get("shots_fired", 0)) >= 1
		if warning_seen and shot_seen:
			break
	for _frame in 120:
		await physics_frame
	_expect(warning_seen and shot_seen, "Sentry should show a local startup warning and fire.")
	_expect(int(_run_state.get("current_health")) == health_before, "Sentry cover should prevent projectile damage.")
	sentry.process_mode = Node.PROCESS_MODE_DISABLED


func _validate_minimap_retry_and_terminal_bypass(stage: Variant) -> void:
	var player: Variant = stage.get("player")
	for room_id in [
		&"bs_gate_switch_loop",
		&"bs_material_crypt",
		&"bs_volatile_nave",
		&"bs_recovery_cloister",
		&"bs_reliquary_cache",
		&"bs_sentry_crossfire",
		&"bs_exit_ascent",
	]:
		var host: Variant = stage.get_room_host(room_id)
		player.respawn_at(host.global_position + Vector2(560.0, 520.0), 999.0)
		for _frame in 3:
			await physics_frame
			await process_frame
	var snapshot: Dictionary = stage.get_stage_map_snapshot()
	_expect(_room_state(snapshot, "bs_material_crypt") == "visited", "Material Crypt should remain visited.")
	_expect(_room_state(snapshot, "bs_reliquary_cache") == "visited", "Reliquary Cache should remain visited.")
	_expect(_room_state(snapshot, "bs_exit_ascent") == "current", "Exit Ascent should be current.")
	_expect(_marker_state(snapshot, "gate") == "open", "Opened Sanctum gate state should not become stale.")
	_expect(_reward_marker_visible(snapshot, "bs_material_crypt"), "Material reward should remain discovered.")
	_expect(_reward_marker_visible(snapshot, "bs_reliquary_cache"), "Reliquary reward should remain discovered.")
	_expect(not stage.is_exit_enabled(), "Sanctum terminal exit should remain locked before its local encounter clears.")

	var nonterminal_alive := 0
	for enemy in stage.get_all_enemies():
		if StringName(enemy.get_meta("planned_room_id", &"")) == &"bs_exit_ascent":
			_defeat(enemy, player)
		elif enemy.current_health > 0:
			nonterminal_alive += 1
	await process_frame
	_expect(nonterminal_alive > 0, "Sanctum terminal fixture should leave Shield, Gallery, and Crossfire enemies alive.")
	_expect(stage.get_remaining_enemy_count() > 0, "Sanctum should retain bypassed non-terminal combat.")
	_expect(stage.is_exit_enabled(), "Clearing only Exit Ascent should enable the Sanctum exit.")
	_expect(_marker_state(stage.get_stage_map_snapshot(), "exit") == "ready", "Sanctum minimap exit should become ready.")

	var checkpoint: Vector2 = stage.get("current_checkpoint_position")
	var bounds: Rect2 = stage.get_world_bounds()
	player.global_position = Vector2(checkpoint.x, bounds.end.y + 420.0)
	for _frame in 4:
		await physics_frame
	_expect(player.global_position.distance_to(checkpoint) <= 2.0, "Sanctum fall should recover at the active checkpoint.")
	_expect(
		_room_state(stage.get_stage_map_snapshot(), "bs_reliquary_cache") == "visited",
		"Sanctum retry should preserve optional exploration knowledge."
	)


func _drop_through_one_way(player: Variant) -> bool:
	Input.action_press("crouch")
	for _frame in 2:
		await physics_frame
	Input.action_press("jump")
	for _frame in 2:
		await physics_frame
	var started := float(player.one_way_drop_timer) > 0.0
	Input.action_release("jump")
	for _frame in 14:
		await physics_frame
	Input.action_release("crouch")
	return started


func _wait_for_landing(player: Variant, target_top: float, frame_limit: int) -> bool:
	for _frame in frame_limit:
		await physics_frame
		if player.is_on_floor() and absf(player.global_position.y - target_top) <= 14.0:
			return true
	return false


func _walk_right_to(
	player: Variant,
	target_x: float,
	target_top: float,
	frame_limit: int
) -> bool:
	Input.action_press("move_right")
	var jump_hold := 0
	var jump_cooldown := 0
	var stalled := 0
	var last_x: float = player.global_position.x
	var furthest_position: Vector2 = player.global_position
	var nearest_target_position: Vector2 = player.global_position
	var nearest_target_distance := absf(player.global_position.x - target_x)
	for _frame in frame_limit:
		if jump_cooldown > 0:
			jump_cooldown -= 1
		var target_is_higher: bool = target_top < player.global_position.y - 8.0
		if (
			player.is_on_floor()
			and jump_hold == 0
			and jump_cooldown == 0
			and (stalled >= 10 or target_is_higher)
		):
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
		if player.global_position.x > furthest_position.x:
			furthest_position = player.global_position
		var target_distance := absf(player.global_position.x - target_x)
		if target_distance < nearest_target_distance:
			nearest_target_distance = target_distance
			nearest_target_position = player.global_position
		if (
			player.global_position.x >= target_x
			and absf(player.global_position.y - target_top) <= 14.0
		):
			Input.action_release("move_right")
			Input.action_release("jump")
			return true
	Input.action_release("move_right")
	Input.action_release("jump")
	print(
		"WALK_RIGHT_FAILED target=(%.1f, %.1f) nearest=%s furthest=%s final=%s"
		% [
			target_x,
			target_top,
			nearest_target_position,
			furthest_position,
			player.global_position,
		]
	)
	return false


func _set_runtime_pressure(stage: Variant, enabled: bool) -> void:
	for enemy in stage.get_all_enemies():
		enemy.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if enabled
			else Node.PROCESS_MODE_DISABLED
		)
	for hazard in stage.get_spawned_hazards():
		hazard.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if enabled
			else Node.PROCESS_MODE_DISABLED
		)


func _find_enemy(
	stage: Variant,
	room_id: StringName,
	archetype_id: StringName
) -> Variant:
	for enemy in stage.get_all_enemies():
		if (
			StringName(enemy.get_meta("planned_room_id", &"")) == room_id
			and enemy.archetype_id == archetype_id
		):
			return enemy
	return null


func _defeat(enemy: Variant, source: Node) -> void:
	enemy.receive_damage(DamageInfo.new(
		int(enemy.current_health),
		source,
		Vector2.ZERO,
		["area"],
		&"sanctum_terminal_validation"
	))


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
		if String(marker.get("type", "")) == marker_type:
			return bool(marker.get("visible", false))
	return false


func _marker_state(snapshot: Dictionary, marker_type: String) -> String:
	for marker_value in snapshot.get("markers", []):
		var marker := marker_value as Dictionary
		if String(marker.get("type", "")) == marker_type:
			return String(marker.get("state", ""))
	return ""


func _release_inputs() -> void:
	for action in [
		"move_left",
		"move_right",
		"jump",
		"crouch",
		"climb_up",
		"climb_down",
	]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BROKEN_SANCTUM_RUNTIME_VALIDATION_OK range=736 branches=2 enemies=12")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
