extends SceneTree

class DamageProbe:
	extends Area2D

	var hits: Array[DamageInfo] = []

	func receive_damage(damage_info: DamageInfo) -> void:
		hits.append(damage_info)


const STAGE_PATH := "res://scenes/stages/boss/SlimeCourt.tscn"
const EPSILON := 0.0001
const INTRO_DURATION := 0.90
const PHASE_TRANSITION_DURATION := 0.75
const GROUND_Y := 640.0
const EXPECTED_TIMINGS := {
	&"jump_slam": Vector3(0.80, 0.18, 1.00),
	&"body_bump": Vector3(0.55, 0.45, 0.80),
	&"poison_bands": Vector3(0.90, 2.20, 0.80),
	&"small_slime_summon": Vector3(0.70, 0.00, 1.00),
}
const EXPECTED_WARNINGS := {
	&"jump_slam": 1,
	&"body_bump": 1,
	&"poison_bands": 2,
	&"small_slime_summon": 2,
}
const EXPECTED_ZONES := {
	&"jump_slam": 3,
	&"body_bump": 1,
	&"poison_bands": 2,
}

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile_state: Node = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and _run_state != null, "Slime King fixture needs production state autoloads")
	if profile_state == null or _run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)

	await _validate_exact_pattern_timelines()
	await _validate_phase_two_chains_and_stagger()
	await _validate_poison_chain_and_scheduler_guards()
	await _validate_defeat_cleanup_and_exactly_once_signal()
	_finish()


func _validate_exact_pattern_timelines() -> void:
	var fixture_seed := 91000
	for pattern_id in EXPECTED_TIMINGS:
		fixture_seed += 1
		var stage: Variant = await _spawn_ready_stage(fixture_seed)
		if stage == null:
			continue
		await _validate_one_pattern(stage, pattern_id)
		stage.queue_free()
		await process_frame


func _validate_one_pattern(stage: Variant, pattern_id: StringName) -> void:
	var boss: Variant = stage.get_boss()
	var runtime: Variant = boss.pattern_runtime
	var timing: Vector3 = EXPECTED_TIMINGS[pattern_id]
	boss.set_scheduler_enabled(false)
	if pattern_id == &"body_bump":
		stage.player.global_position.x = boss.global_position.x - 300.0
	elif pattern_id == &"jump_slam":
		stage.player.global_position.x = 520.0
	elif pattern_id == &"small_slime_summon":
		stage.player.global_position.x = 400.0
	_expect(boss.execute_pattern(pattern_id, 2), "%s should begin from the real actor" % pattern_id)
	var startup := _pattern_snapshot(boss)
	_expect(startup["state"] == &"startup", "%s should begin in startup" % pattern_id)
	_expect(_near(float(startup["state_duration"]), timing.x), "%s startup should be exact" % pattern_id)
	_expect(not bool(startup["damage_enabled"]), "%s startup should be non-damaging" % pattern_id)
	_expect(startup["active_zone_count"] == 0, "%s startup should expose no active hit areas" % pattern_id)
	_expect(startup["warning_count"] == EXPECTED_WARNINGS[pattern_id], "%s should expose its authored warning geometry" % pattern_id)

	var probe := DamageProbe.new()
	probe.name = "%sProbe" % String(pattern_id).to_pascal_case()
	stage.add_child(probe)
	_expect(not runtime.try_damage_contact(probe, &"not_active"), "%s startup should reject contact" % pattern_id)

	stage.advance_runtime(timing.x * 0.5)
	var mid_startup := _pattern_snapshot(boss)
	_expect(mid_startup["state"] == &"startup", "%s should retain its full startup" % pattern_id)
	if pattern_id == &"jump_slam":
		_expect(boss.global_position.y < GROUND_Y - 40.0, "Jump Slam should visibly ascend over its shadow")
		_expect(_near((mid_startup["locked_target"] as Vector2).x, 520.0), "Jump Slam shadow should lock the warned landing position")
	elif pattern_id == &"body_bump":
		var locked_direction := int(mid_startup["locked_direction"])
		stage.player.global_position.x = boss.global_position.x + 300.0
		_expect(locked_direction == -1, "Body Bump should lock its warned lane direction")
		var pose_rotation: float = boss.visual.rotation
		var pose_scale: Vector2 = boss.visual.scale
		var pose_color: Color = boss.body_visual.color
		boss.receive_damage(DamageInfo.new(0, stage.player, Vector2.ZERO, ["player_attack"], &"flash_pose_fixture"))
		_expect(_near(boss.visual.rotation, pose_rotation) and boss.visual.scale.is_equal_approx(pose_scale), "hit flash should not erase the active pattern transform")
		_expect(boss.body_visual.color == pose_color, "hit flash should not replace the active pattern color")
		await create_timer(0.08).timeout
		_expect(_near(boss.visual.rotation, pose_rotation) and boss.visual.scale.is_equal_approx(pose_scale), "hit flash expiry should preserve the active pattern pose")
		_expect(boss.body_visual.color == pose_color, "hit flash expiry should preserve the active pattern color")
	elif pattern_id == &"small_slime_summon":
		var marker_positions: PackedVector2Array = mid_startup["spawn_marker_positions"]
		_expect(marker_positions.size() == 2, "Summon should warn with exactly two markers")
		for marker_position in marker_positions:
			_expect(marker_position.distance_to(stage.player.global_position) + EPSILON >= 150.0, "Summon markers should never target the current player position")

	stage.advance_runtime(timing.x * 0.5)
	var after_startup := _pattern_snapshot(boss)
	if pattern_id == &"small_slime_summon":
		_validate_summon_activation(stage, boss, after_startup, timing)
		probe.queue_free()
		return

	_expect(after_startup["state"] == &"active", "%s should enter active at the exact startup boundary" % pattern_id)
	_expect(_near(float(after_startup["state_duration"]), timing.y), "%s active duration should be exact" % pattern_id)
	_expect(bool(after_startup["damage_enabled"]), "%s should enable damage only while active" % pattern_id)
	_expect(after_startup["active_zone_count"] == EXPECTED_ZONES[pattern_id], "%s should expose the authored active geometry" % pattern_id)
	if pattern_id == &"jump_slam":
		var jump_zones: Array = after_startup["active_zone_ids"]
		_expect(jump_zones.has(&"jump_landing") and jump_zones.has(&"shockwave_left") and jump_zones.has(&"shockwave_right"), "Jump Slam should activate one landing and two readable shockwaves")
		_expect(_near(boss.global_position.y, GROUND_Y), "Jump Slam should land at active start")
	elif pattern_id == &"body_bump":
		_expect(int(after_startup["locked_direction"]) == -1, "Body Bump direction should remain locked after the player crosses behind")
	elif pattern_id == &"poison_bands":
		var poison_zones: Array = after_startup["active_zone_ids"]
		_expect(poison_zones.has(&"poison_band_0") and poison_zones.has(&"poison_band_2"), "Poison should activate alternating floor bands")
		_expect(float(after_startup["safe_floor_or_platform_fraction"]) + EPSILON >= 0.35, "Poison should preserve at least 35 percent safe floor/platform area")
		_expect(_near(float(after_startup["safe_floor_fraction"]), 0.50), "authored Poison layout should preserve 50 percent floor before platform safety")

	var active_zone_ids: Array = after_startup["active_zone_ids"]
	var first_zone := StringName(active_zone_ids[0])
	_expect(runtime.try_damage_contact(probe, first_zone), "%s first active contact should deal damage" % pattern_id)
	_expect(not runtime.try_damage_contact(probe, first_zone), "%s should not repeat damage within one active contact" % pattern_id)
	if active_zone_ids.size() > 1:
		_expect(not runtime.try_damage_contact(probe, StringName(active_zone_ids[1])), "%s sibling hit areas should share one active-window hit policy" % pattern_id)
	_expect(probe.hits.size() == 1, "%s should deal exactly one hit in its active window" % pattern_id)
	if probe.hits.size() == 1:
		_expect(probe.hits[0].amount == 1, "%s active contact should deal exactly one damage" % pattern_id)
		_expect(probe.hits[0].attack_id == pattern_id, "%s damage should retain its pattern ID" % pattern_id)

	var active_start_x: float = boss.global_position.x
	stage.advance_runtime(timing.y - 0.01)
	var late_active := _pattern_snapshot(boss)
	_expect(late_active["state"] == &"active", "%s should remain active until its exact boundary" % pattern_id)
	if pattern_id == &"body_bump":
		_expect(boss.global_position.x < active_start_x - 100.0, "Body Bump should move in its locked direction during the 0.45 s contact window")
	stage.advance_runtime(0.01)
	var recovery := _pattern_snapshot(boss)
	_expect(recovery["state"] == &"recovery", "%s should enter recovery at the exact active boundary" % pattern_id)
	_expect(_near(float(recovery["state_duration"]), timing.z), "%s recovery should be exact" % pattern_id)
	_expect(not bool(recovery["damage_enabled"]) and recovery["active_zone_count"] == 0, "%s recovery should disable and clear all damage" % pattern_id)
	_expect(not runtime.try_damage_contact(probe, first_zone), "%s recovery should reject contact" % pattern_id)
	_expect(probe.hits.size() == 1, "%s recovery should not add damage" % pattern_id)
	stage.advance_runtime(timing.z - 0.01)
	_expect(_pattern_snapshot(boss)["state"] == &"recovery", "%s should retain its full recovery" % pattern_id)
	stage.advance_runtime(0.01)
	var finished := _pattern_snapshot(boss)
	_expect(finished["state"] == &"idle", "%s should finish only after exact recovery" % pattern_id)
	_expect(not bool(finished["damage_enabled"]), "%s idle state should remain non-damaging" % pattern_id)
	probe.queue_free()


func _validate_summon_activation(
	stage: Variant,
	boss: Variant,
	after_startup: Dictionary,
	timing: Vector3
) -> void:
	_expect(after_startup["state"] == &"recovery", "Summon activation should be instantaneous at 0.70 s")
	_expect(_near(float(after_startup["state_duration"]), timing.z), "Summon recovery should be exactly 1.00 s")
	_expect(not bool(after_startup["damage_enabled"]) and after_startup["active_zone_count"] == 0, "Summon should not create boss damage during recovery")
	_expect(after_startup["spawn_marker_count"] == 2, "Summon should retain its two resolved marker facts")
	_expect(after_startup["active_add_count"] == 2, "Summon should activate at most two Small Slime children")
	for slime in boss.pattern_runtime.get_active_adds():
		var script := slime.get_script() as Script
		_expect(script != null and script.get_global_name() == &"SmallSlimeEnemy" and slime.get_parent() == boss.pattern_runtime, "Summon children should remain boss-runtime-owned")
		var contact := slime.get_node_or_null("ContactHitbox") as Hitbox
		_expect(contact != null and contact.active and contact.damage_amount == 1, "Small Slime contact should activate for one damage only after markers")
	stage.advance_runtime(timing.z - 0.01)
	_expect(_pattern_snapshot(boss)["state"] == &"recovery", "Summon should retain its full recovery")
	stage.advance_runtime(0.01)
	_expect(_pattern_snapshot(boss)["state"] == &"idle", "Summon should finish after exact recovery")
	_expect(boss.execute_pattern(&"small_slime_summon", 2), "direct Summon replay should remain bounded")
	stage.advance_runtime(timing.x)
	_expect(_pattern_snapshot(boss)["active_add_count"] == 2, "Summon replay should never exceed the two-add cap")


func _validate_phase_two_chains_and_stagger() -> void:
	var stage: Variant = await _spawn_ready_stage(92001)
	if stage == null:
		return
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	boss.hurtbox.receive_damage(DamageInfo.new(40, stage.player, Vector2.ZERO, ["player_attack"], &"phase_fixture"))
	var transition: Dictionary = boss.get_runtime_snapshot()
	_expect(transition["phase"] == 2 and transition["health"] == 40, "40 HP should enter phase 2 exactly")
	_expect(transition["actor_state"] == &"phase_transition", "phase 2 should begin with a non-damaging transition")
	_expect(not bool((transition["pattern"] as Dictionary)["damage_enabled"]), "phase transition should disable boss damage")
	stage.advance_runtime(PHASE_TRANSITION_DURATION - 0.01)
	_expect(boss.get_runtime_snapshot()["actor_state"] == &"phase_transition", "phase transition should retain its full reviewed duration")
	stage.advance_runtime(0.01)
	_expect(boss.get_runtime_snapshot()["actor_state"] == &"active", "phase transition should return to active play")

	var body_chain := _find_reviewed_chain(boss.scheduler, &"body_bump")
	_expect(body_chain != null and body_chain.pattern_ids() == [&"body_bump", &"jump_slam"], "phase-2 scheduler should produce only the reviewed Body Bump to Jump Slam chain")
	if body_chain != null:
		_expect(_near(body_chain.neutral_between_patterns, 0.50), "Body Bump chain neutral should be exactly 0.50 s")
		_expect(body_chain.neutral_after + EPSILON >= 0.75, "reviewed chain should end with at least 0.75 s neutral")
		_expect(boss.execute_schedule(body_chain), "actor should execute the scheduler's reviewed Body chain")
		stage.advance_runtime(0.55 + 0.45 + 0.80)
		var chain_neutral := _pattern_snapshot(boss)
		_expect(chain_neutral["state"] == &"neutral", "Body chain should enter its authored neutral window")
		_expect(_near(float(chain_neutral["state_duration"]), 0.50), "Body chain runtime should honor exact 0.50 s neutral")
		_expect(not bool(chain_neutral["damage_enabled"]), "chain neutral should remain non-damaging")
		_expect((chain_neutral["queued_pattern_ids"] as Array) == [&"jump_slam"], "chain neutral should retain only Jump Slam as queued followup")
		stage.advance_runtime(0.50)
		_expect(_pattern_snapshot(boss)["pattern_id"] == &"jump_slam", "reviewed followup should begin after exact neutral")

		boss.receive_damage(DamageInfo.new(0, stage.player, Vector2.ZERO, ["player_attack"], &"stagger_fixture", 100))
		var staggered: Dictionary = boss.get_runtime_snapshot()
		var cancelled_pattern := staggered["pattern"] as Dictionary
		_expect(staggered["actor_state"] == &"staggered", "100 stagger should open the reviewed punish window")
		_expect(_near(float(staggered["stagger_time_remaining"]), 1.40), "stagger punish window should be exactly 1.40 s")
		_expect(cancelled_pattern["state"] == &"cancelled", "stagger should cancel active pattern execution")
		_expect((cancelled_pattern["queued_pattern_ids"] as Array).is_empty(), "stagger should clear the queued chain")
		_expect(not bool(cancelled_pattern["damage_enabled"]) and cancelled_pattern["active_zone_count"] == 0, "stagger should disable and clear damage immediately")
		stage.advance_runtime(1.39)
		_expect(boss.get_runtime_snapshot()["actor_state"] == &"staggered", "stagger should remain punishable before 1.40 s")
		stage.advance_runtime(0.01)
		_expect(boss.get_runtime_snapshot()["actor_state"] == &"active", "stagger should recover at exactly 1.40 s")
	stage.queue_free()
	await process_frame


func _validate_poison_chain_and_scheduler_guards() -> void:
	var stage: Variant = await _spawn_ready_stage(92002)
	if stage == null:
		return
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	boss.receive_damage(DamageInfo.new(40, stage.player))
	stage.advance_runtime(PHASE_TRANSITION_DURATION)
	var poison_chain := _find_reviewed_chain(boss.scheduler, &"poison_bands")
	_expect(poison_chain != null and poison_chain.pattern_ids() == [&"poison_bands", &"small_slime_summon"], "phase-2 scheduler should produce only the reviewed Poison to Summon chain")
	if poison_chain != null:
		_expect(is_zero_approx(poison_chain.neutral_between_patterns), "Poison chain should use zero inter-pattern neutral after cleanup")
		_expect(boss.execute_schedule(poison_chain), "actor should execute the scheduler's reviewed Poison chain")
		stage.advance_runtime(0.90 + 2.20 + 0.80)
		var summon_startup := _pattern_snapshot(boss)
		_expect(summon_startup["pattern_id"] == &"small_slime_summon" and summon_startup["state"] == &"startup", "Summon should begin immediately after Poison cleanup")
		_expect(summon_startup["active_zone_count"] == 0 and not bool(summon_startup["damage_enabled"]), "Poison zones should be gone before Summon markers begin")
		stage.advance_runtime(0.70)
		_expect(_pattern_snapshot(boss)["active_add_count"] == 2, "reviewed Poison chain should honor the two-add cap")
		stage.advance_runtime(1.00)
		var final_neutral := _pattern_snapshot(boss)
		_expect(final_neutral["state"] == &"neutral", "reviewed Poison chain should end in neutral")
		_expect(float(final_neutral["state_duration"]) + EPSILON >= 0.75, "reviewed Poison chain runtime should honor at least 0.75 s final neutral")
		stage.advance_runtime(float(final_neutral["state_duration"]))
		_expect(_pattern_snapshot(boss)["state"] == &"idle", "reviewed chain should finish after final neutral")

	var capped_context := BossPatternContext.new(2, 2, 2, 1.0, true, false, false, false, true, false)
	for seed in 32:
		boss.scheduler.reset(seed)
		var capped_schedule: BossPatternSchedule = boss.scheduler.choose_next(capped_context)
		if capped_schedule == null:
			continue
		_expect(not capped_schedule.pattern_ids().has(&"small_slime_summon"), "scheduler should skip Summon at active-add cap")
		_expect(not capped_schedule.pattern_ids().has(&"body_bump"), "scheduler should block Body Bump when two adds close both sides")
	var overlap_context := BossPatternContext.new(2, 0, 2, 1.0, true, false, true, true, true, true)
	for seed in 32:
		boss.scheduler.reset(seed)
		var overlap_schedule: BossPatternSchedule = boss.scheduler.choose_next(overlap_context)
		if overlap_schedule != null:
			_expect(overlap_schedule.pattern_ids() != [&"poison_bands", &"small_slime_summon"], "scheduler should block Poison-to-Summon overlap")
	stage.queue_free()
	await process_frame


func _validate_defeat_cleanup_and_exactly_once_signal() -> void:
	var stage: Variant = await _spawn_ready_stage(93001)
	if stage == null:
		return
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	_expect(boss.execute_pattern(&"small_slime_summon", 2), "defeat fixture should spawn adds")
	stage.advance_runtime(0.70)
	stage.advance_runtime(1.00)
	_expect(boss.execute_pattern(&"jump_slam"), "defeat fixture should open an active damage window")
	stage.advance_runtime(0.80)
	var before := _pattern_snapshot(boss)
	_expect(before["active_add_count"] == 2 and before["active_zone_count"] == 3, "defeat fixture should own adds and shockwaves before cleanup")

	var signal_result: Dictionary = {"count": 0, "reward_id": &""}
	var bus: Node = root.get_node_or_null("/root/SignalBus")
	var callback: Callable = func(reward_table_id: StringName) -> void:
		signal_result["count"] = int(signal_result["count"]) + 1
		signal_result["reward_id"] = reward_table_id
	bus.boss_defeated.connect(callback)
	boss.receive_damage(DamageInfo.new(80, stage.player, Vector2.ZERO, ["player_attack"], &"defeat_fixture"))
	var defeated: Dictionary = boss.get_runtime_snapshot()
	var cleared := defeated["pattern"] as Dictionary
	_expect(defeated["actor_state"] == &"defeated" and defeated["health"] == 0, "zero health should defeat the real SlimeKingActor")
	_expect(not bool(cleared["damage_enabled"]), "defeat should disable all boss damage immediately")
	_expect(cleared["active_zone_count"] == 0, "defeat should clear landing and shockwave actors")
	_expect(cleared["active_add_count"] == 0, "defeat should clear every Small Slime add")
	_expect((cleared["queued_pattern_ids"] as Array).is_empty(), "defeat should clear queued pattern execution")
	_expect(signal_result["count"] == 1, "boss defeat should emit exactly one SignalBus fact")
	_expect(signal_result["reward_id"] == &"boss_clear_slime_king", "boss defeat should emit the exact settlement reward table ID")
	boss.receive_damage(DamageInfo.new(80, stage.player))
	_expect(signal_result["count"] == 1, "repeated defeat hits should not emit a second SignalBus fact")
	if bus.boss_defeated.is_connected(callback):
		bus.boss_defeated.disconnect(callback)
	stage.queue_free()
	await process_frame


func _find_reviewed_chain(
	scheduler: BossPatternScheduler,
	first_pattern_id: StringName
) -> BossPatternSchedule:
	var context: BossPatternContext = BossPatternContext.new(2, 0, 2, 1.0, true, false, true, true, true, false)
	for seed in 256:
		scheduler.reset(seed)
		var schedule: BossPatternSchedule = scheduler.choose_next(context)
		if schedule != null and schedule.is_chain() and schedule.patterns[0].id == first_pattern_id:
			return schedule
	return null


func _spawn_ready_stage(seed: int) -> Variant:
	_expect(_run_state.start_new_run(0, seed), "boss pattern fixture run should start")
	_run_state.set("current_stage_index", 3)
	var packed := load(STAGE_PATH) as PackedScene
	_expect(packed != null, "Slime Court scene should load for pattern validation")
	if packed == null:
		return null
	var stage: Variant = packed.instantiate()
	_expect(stage != null, "Slime Court should instantiate for pattern validation")
	if stage == null:
		return null
	root.add_child(stage)
	stage.set_manual_simulation(true)
	await process_frame
	_expect(stage.is_setup_complete(), "pattern fixture stage should complete setup")
	stage.advance_runtime(INTRO_DURATION)
	_expect(stage.is_intro_complete(), "pattern fixture should step the exact intro deterministically")
	return stage


func _pattern_snapshot(boss: Variant) -> Dictionary:
	return (boss.get_runtime_snapshot()["pattern"] as Dictionary).duplicate(true)


func _near(left: float, right: float) -> bool:
	return absf(left - right) <= EPSILON


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 100:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SLIME_KING_PATTERNS_RUNTIME_VALIDATION_OK patterns=4 stagger=100/1.40 chains=2 defeat_signal=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
