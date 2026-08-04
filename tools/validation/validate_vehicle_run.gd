extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyUpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish(); return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run != null:
		run.call("_reset_run", false)
		_expect(run.current_stage_id == &"stage_1" and run.player_position == Vector2(3600,2160), "run begins at shared center")
		_expect(run.PLAYER_BASE_SPEED == 280.0, "player base speed remains 280 px/s")
		_expect(run.PICKUP_BODY_RADIUS == 42.0, "pickup body radius is 42 px")
		_expect(run.MINIMAP_COLS == 20 and run.MINIMAP_ROWS == 12, "run uses 20x12 explored minimap")
		_expect(run.ORDINARY_DECISION_BUCKET_COUNT == 6, "ordinary high-cost decisions are distributed at 10 Hz")
		_expect(run._camera.zoom == Vector2.ONE, "gameplay camera keeps zoom 1")
		var visible_rect: Rect2 = run.call("_visible_world_rect", 0.0)
		_expect(
			float(run.call("_primary_projectile_range"))
				>= visible_rect.size.length() + run.PRIMARY_VISIBLE_RANGE_MARGIN,
			"primary range covers the full visible field diagonal with margin"
		)
		_check_visual_collision_separation(run)
		var boss_arrival: Vector2 = run.call("_choose_boss_arrival_anchor")
		_expect(
			run.player_position.distance_to(boss_arrival)
				>= run.BOSS_ARRIVAL_MIN_DISTANCE,
			"boss arrival uses a reachable anchor beyond the documented minimum"
		)
		var initial_fingerprint := int(run.field_layout.fingerprint)
		run.run_build.apply(&"tuned_thrusters")
		run.visited_cells[Vector2i(2,2)] = true
		run.current_stage_index = 1
		run.current_stage_id = Catalog.STAGE_IDS[1]
		run.call("_reset_run", false, true, true)
		_expect(int(run.field_layout.fingerprint) == initial_fingerprint, "stage transition preserves run-scoped field geometry")
		_expect(run.run_build.has(&"tuned_thrusters") and run.visited_cells.has(Vector2i(2,2)), "stage transition preserves build and exploration")
		_expect(run.player_position == Vector2(3600,2160), "stage transition respawns at center")
		var hud: Dictionary = run.call("_build_hud_snapshot")
		_expect(hud["minimap"]["cols"] == 20 and hud["guidebook"].has("categories"), "HUD exposes minimap and guide snapshots")
		var ui = run.get_node_or_null("VehicleStageUI")
		var ui_contract: Dictionary = ui.debug_ui_contract() if ui != null else {}
		var component_owners := Dictionary(ui_contract.get("component_owners", {}))
		_expect(
			ui == run._ui
				and String(component_owners.get("guidebook", ""))
					== "res://scripts/ui/vehicle_guidebook_panel.gd",
			"guidebook modal is connected through the shared Stage UI owner"
		)
		_check_simulation_lod_contract(run)
		_check_boss_progression_gate(run)
		_check_boss_damage_and_guidance(run, ui)
		run.call("_reset_run", false, true, true)
		_check_boss_committed_recovery(run)
		run.call("_reset_run", false, true, true)
		_check_enemy_expansion(run)
		run.call("_reset_run", false, true, true)
		_check_primary_collision_at_horde_capacity(run)
	root.queue_free()
	await process_frame
	_finish()


func _check_visual_collision_separation(run) -> void:
	for fixture in [
		[&"chaser", 18.0, 44.0],
		[&"turret", 30.0, 62.0],
		[&"stage_boss", 76.0, 146.0],
	]:
		var enemy = run.call("_make_enemy", {
			"id":"visual_probe_%s" % String(fixture[0]),
			"role":fixture[0],
			"pos":run.player_position + Vector2(800.0, 0.0),
			"active":false,
		})
		_expect(
			enemy != null
				and is_equal_approx(enemy.radius, float(fixture[1]))
				and is_equal_approx(enemy.projectile_hit_radius, float(fixture[2]))
				and is_equal_approx(enemy.visual_radius, float(fixture[2])),
			"%s keeps movement compact while its projectile hit radius matches the art" % fixture[0]
		)
		run.enemy_store.release_untracked(enemy)


func _check_simulation_lod_contract(run) -> void:
	var moving_even := EnemyState.new()
	moving_even.alive = true
	moving_even.active = true
	moving_even.phase = &"move"
	moving_even.runtime_slot = 0
	moving_even.pos = run.player_position
	var moving_odd := EnemyState.new()
	moving_odd.alive = true
	moving_odd.active = true
	moving_odd.phase = &"move"
	moving_odd.runtime_slot = 1
	moving_odd.pos = run.player_position
	var committed_odd := EnemyState.new()
	committed_odd.alive = true
	committed_odd.active = true
	committed_odd.phase = &"startup"
	committed_odd.runtime_slot = 2
	committed_odd.pos = run.player_position + Vector2(1200.0, 0.0)
	var distant := EnemyState.new()
	distant.alive = true
	distant.active = true
	distant.phase = &"move"
	distant.runtime_slot = 3
	distant.pos = run.player_position + Vector2(1200.0, 0.0)
	var fixtures: Array[EnemyState] = [
		moving_even, moving_odd, committed_odd, distant,
	]
	var schedule := EnemyUpdateSchedule.new()
	schedule.rebuild(
		fixtures, 1.0 / 60.0, run.player_position,
		run.FAR_SIMULATION_DISTANCE_SQUARED, 0, 1, 1
	)
	_expect(
		schedule.is_critical(committed_odd)
			and is_equal_approx(schedule.motion_delta(committed_odd), 0.0),
		"attack startup is selected for the independent 60 Hz critical lane"
	)
	schedule.rebuild(
		fixtures, 1.0 / 60.0, run.player_position,
		run.FAR_SIMULATION_DISTANCE_SQUARED, 1, 0, 2
	)
	_expect(
		is_equal_approx(schedule.motion_delta(moving_even), 1.0 / 30.0),
		"ordinary locomotion integrates on its alternating 30 Hz slot"
	)
	_expect(
		is_zero_approx(schedule.motion_delta(moving_odd)),
		"the other ordinary locomotion slot waits for the next physics tick"
	)
	schedule.rebuild(
		fixtures, 1.0 / 60.0, run.player_position,
		run.FAR_SIMULATION_DISTANCE_SQUARED, 2, 1, 0
	)
	_expect(
		is_equal_approx(schedule.motion_delta(distant), 1.0 / 20.0),
		"distant non-committed locomotion integrates on its 20 Hz slot"
	)


func _check_boss_progression_gate(run) -> void:
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "stage_boss") == null, "boss cannot spawn before ordinary defeats")
	run.stage_flow.defeats = run.stage_flow.quota - 1
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "stage_boss") == null, "boss remains blocked one defeat before quota")
	_expect(run.stage_flow.record_countable_defeat(), "final ordinary defeat begins the boss warning")
	run.call("_update_stage_progression", 1.5)
	_expect(run.call("_find_enemy_by_id", "stage_boss") != null, "boss spawns only after quota and warning")


func _check_boss_damage_and_guidance(run, ui) -> void:
	var boss: EnemyState = run.call("_find_enemy_by_id", "stage_boss")
	_expect(boss != null, "boss guidance fixture has a live boss")
	if boss == null:
		return
	var health_before := boss.health
	var applied := float(
		run.call(
			"_damage_enemy",
			boss,
			100.0,
			"validation",
			&"kinetic",
			false
		)
	)
	_expect(
		is_equal_approx(applied, 20.0)
			and is_equal_approx(health_before - boss.health, 20.0),
		"sealed boss damage is reduced to twenty percent instead of cancelled"
	)
	_expect(
		not run.effects.is_empty()
			and String(run.effects[-1]["kind"]) == "boss_core_reduced_hit"
			and is_equal_approx(float(run.effects[-1]["value"]), 20.0),
		"sealed hit feedback exposes the actual applied damage"
	)
	var hud := Dictionary(run.call("_build_hud_snapshot"))
	var objective := Dictionary(Dictionary(hud["boss"])["objective"])
	var active_modules := Array(objective["active_modules"])
	_expect(
		objective["state"] == &"sealed"
			and is_equal_approx(float(objective["damage_multiplier"]), 0.20)
			and not active_modules.is_empty(),
		"boss strip consumes the sealed state and active module health snapshot"
	)
	var active := Dictionary(active_modules[0])
	var minimap_markers := Array(hud["minimap"]["markers"])
	var active_module_markers := minimap_markers.filter(
		func(marker_variant) -> bool:
			var marker := Dictionary(marker_variant)
			return (
				StringName(marker.get("kind", &"")) == &"enemy"
				and Vector2(marker.get("position", Vector2.ZERO)).is_equal_approx(
					Vector2(active["position"])
				)
			)
	)
	var only_shared_minimap_roles := true
	for marker_variant in minimap_markers:
		if StringName(Dictionary(marker_variant).get("kind", &"")) not in [
			&"item", &"enemy", &"boss",
		]:
			only_shared_minimap_roles = false
			break
	_expect(
		not active_module_markers.is_empty()
			and only_shared_minimap_roles,
		"minimap folds objective modules into the shared enemy role"
	)
	var all_modules := Array(objective["modules"])
	var locked_modules := all_modules.filter(
		func(module_variant) -> bool:
			return StringName(Dictionary(module_variant)["state"]) == &"locked"
	)
	if not locked_modules.is_empty():
		var locked := Dictionary(locked_modules[0])
		var locked_enemy: EnemyState = run.call(
			"_find_enemy_by_id",
			String(locked["id"])
		)
		var probe := ProjectileState.new()
		probe.radius = 6.0
		var locked_candidates: Array[EnemyState] = [locked_enemy]
		var contact = run.call(
			"_player_projectile_contact",
			probe,
			locked_enemy.pos - Vector2(120.0, 0.0),
			locked_enemy.pos + Vector2(120.0, 0.0),
			probe.radius,
			locked_candidates
		)
		_expect(
			contact == null,
			"inactive sequential objective modules are projectile-pass-through"
		)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", 0.11)
	var objective_contacts: Array = run._threat_contact_cache.filter(
		func(contact_variant) -> bool:
			var contact := Dictionary(contact_variant)
			return (
				bool(contact.get("objective", false))
				and String(contact.get("objective_id", "")) == String(active["id"])
				and StringName(contact.get("objective_state", &"")) == &"active"
				and is_equal_approx(
					float(contact.get("health", -1.0)),
					float(active["health"])
				)
			)
	)
	_expect(
		not objective_contacts.is_empty(),
		"off-screen radar consumes the same active objective id, state, and health"
	)
	ui.update_hud(hud)
	_expect(
		ui._hud._boss_cluster.visible
			and ui._hud._objective_panel.visible,
		"boss strip and objective panel remain visible together"
	)


func _check_boss_committed_recovery(run) -> void:
	var boss: EnemyState = run.call("_make_enemy", {
		"id":"validation_boss", "role":&"stage_boss",
		"pos":run.player_position + Vector2(760.0, 0.0), "active":true,
	})
	boss["active"] = true
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 1.0
	run.call("_append_enemy", boss)
	run.call("_damage_enemy", boss, 1.0, "validation", &"kinetic", false)
	_expect(
		String(boss["phase"]) == "boss_startup",
		"routine primary damage cannot interrupt a committed boss startup"
	)

	boss["phase"] = "boss_recovery"
	boss["vulnerable"] = 1.0
	run.call("_damage_enemy", boss, 1.0, "validation", &"kinetic", false)
	_expect(
		String(boss["phase"]) == "boss_recovery",
		"routine primary damage preserves the authored boss recovery"
	)

	run.call("_clear_projectiles")
	boss["pos"] = run.player_position + Vector2(-420.0, 0.0)
	boss["phase"] = "boss_startup"
	boss["phase_time"] = 0.8
	boss["pattern"] = "current_fan"
	boss["pattern_index"] = 1
	boss["committed_dir"] = Vector2.UP
	boss["committed_target"] = run.player_position + Vector2(0.0, -240.0)
	AttackTelegraphs.refresh_boss(
		boss,
		"current_fan",
		Callable(run, "_runtime_attack_path_end"),
		Callable(run, "_runtime_charge_path_end")
	)
	run.call("_update_stage_boss", boss, 0.0)
	var warned_position := Vector2(boss["pos"])
	var warned_direction := Vector2(boss["committed_dir"])
	var warned_target := Vector2(boss["committed_target"])
	var warned_endpoint := Vector2(boss.attack_telegraphs[0]["to"])
	var player_before_warning_test := Vector2(run.player_position)
	run.player_position += Vector2(180.0, 120.0)
	run.player_velocity = Vector2(0.0, 180.0)
	run.call("_update_stage_boss", boss, 0.1)
	_expect(
		Vector2(boss["pos"]).is_equal_approx(warned_position)
			and Vector2(boss["committed_dir"]).is_equal_approx(warned_direction)
			and Vector2(boss["committed_target"]).is_equal_approx(warned_target)
			and Vector2(boss.attack_telegraphs[0]["to"]).is_equal_approx(warned_endpoint),
		"boss attack geometry remains fixed after its warning becomes visible"
	)
	_expect(
		float(boss.attack_telegraphs[0]["readiness"]) > 0.0,
		"boss warning readiness advances without moving its footprint"
	)
	run.player_position = player_before_warning_test
	run.call("_boss_begin_active", boss)
	var committed_origin := Vector2(boss["pos"])
	run.call("_boss_update_active", boss, 0.01)
	run.call("_boss_update_active", boss, BossPatterns.volley_interval("current_fan") + 0.01)
	_expect(run.call("_count_hostile_projectiles") >= 10, "boss fires repeated committed volleys instead of one inert shot")
	_expect(
		Vector2(boss["pos"]).is_equal_approx(committed_origin),
		"damaging boss attacks do not drift away from their warned origin"
	)

	run.call("_clear_projectiles")
	var ordinary_limit := Director.HOSTILE_PROJECTILE_CAP - Director.BOSS_PROJECTILE_RESERVE
	for index in ordinary_limit + 8:
		run.call(
			"_spawn_hostile_projectile",
			boss["pos"],
			Vector2.LEFT,
			1.0,
			100.0,
			"validation_ordinary",
			AttackContract.KINETIC
		)
	_expect(run.call("_count_hostile_projectiles") == ordinary_limit, "ordinary hostile shots preserve the boss projectile reserve")
	var before_boss_shot := int(run.call("_count_hostile_projectiles"))
	run.call(
		"_spawn_hostile_projectile",
		boss["pos"],
		Vector2.LEFT,
		1.0,
		100.0,
		"validation_boss",
		AttackContract.KINETIC,
		true
	)
	_expect(run.call("_count_hostile_projectiles") == before_boss_shot + 1, "boss attacks still fire when ordinary projectile pressure is saturated")


func _check_enemy_expansion(run) -> void:
	var mine: EnemyState = run.call("_make_enemy", {
		"id":"validation_mine", "role":&"mine",
		"pos":run.player_position + Vector2(229.0, 0.0), "active":true,
	})
	run.call("_append_enemy", mine)
	var health_before := float(run.player_health)
	run.call("_update_mine", mine, 0.0, 0.0, true)
	_expect(
		mine.phase == &"mine_armed"
			and is_equal_approx(mine.phase_time, 1.25)
			and is_equal_approx(float(run.player_health), health_before),
		"stationary mine arms outside its separate damage ring"
	)
	run.player_position += Vector2(800.0, 0.0)
	run.call("_update_mine", mine, 1.26, 0.0, true)
	_expect(not mine.alive, "stationary mine retires after one explosion")

	var guard: EnemyState = run.call("_make_enemy", {
		"id":"validation_guard", "role":&"bulkhead_guard",
		"pos":run.player_position + Vector2(300.0, 0.0), "active":true,
	})
	var primary_round := ProjectileState.new()
	primary_round.velocity = Vector2.RIGHT
	primary_round.structure_damage = 18.0
	for expected_structure in [54.0, 36.0, 18.0, 0.0]:
		_expect(
			bool(run.call("_try_absorb_protective_structure", guard, primary_round))
				and is_equal_approx(guard.guard_plate_structure, expected_structure),
			"sustained primary fire chips the Guard plate by one uniform hit"
		)
	run.enemy_store.release_untracked(guard)

	var splitter: EnemyState = run.call("_make_enemy", {
		"id":"validation_splitter", "role":&"splitter_barge",
		"pos":run.player_position + Vector2(-300.0, 0.0), "active":true,
	})
	run.encounter_runtime.current_beat = 4
	run.call("_append_enemy", splitter)
	run.call("_defeat_enemy", splitter, "player_primary")
	var children := 0
	for enemy in run.enemies:
		if enemy.alive and enemy.carrier_id == "splitter:validation_splitter":
			children += 1
	_expect(children == 2, "Splitter Barge emits exactly two summon-only children when capacity permits")


func _check_primary_collision_at_horde_capacity(run) -> void:
	run.call("_clear_enemies")
	run.call("_clear_projectiles")
	for index in EnemyStore.MAX_LIVE_HOSTILES - 2:
		var filler: EnemyState = run.call("_make_enemy", {
			"id":"collision_filler_%d" % index,
			"role":&"chaser",
			"pos":run.player_position + Vector2(-500.0, 400.0),
			"active":true,
		})
		_expect(
			filler != null and bool(run.call("_append_enemy", filler)),
			"collision fixture fills every non-target enemy slot"
		)
	var first_target: EnemyState = run.call("_make_enemy", {
		"id":"collision_first_target",
		"role":&"chaser",
		"pos":run.player_position + Vector2(240.0, 38.0),
		"active":true,
	})
	var rear_target: EnemyState = run.call("_make_enemy", {
		"id":"collision_rear_target",
		"role":&"chaser",
		"pos":run.player_position + Vector2(310.0, 0.0),
		"active":true,
	})
	if first_target == null or rear_target == null:
		_expect(false, "collision fixture acquires both maximum-capacity targets")
		return
	_expect(
		bool(run.call("_append_enemy", first_target))
			and bool(run.call("_append_enemy", rear_target))
			and rear_target.runtime_slot == EnemyStore.MAX_LIVE_HOSTILES - 1,
		"collision targets occupy the final two horde-capacity slots"
	)
	run.call("_rebuild_enemy_runtime_indexes")
	var first_health := first_target.health
	var rear_health := rear_target.health
	_expect(
		run.projectile_store.add_player({
			"pos":run.player_position,
			"velocity":Vector2.RIGHT * run.PRIMARY_PROJECTILE_SPEED,
			"radius":run.PRIMARY_PROJECTILE_RADIUS,
			"damage":18.0,
			"structure_damage":18.0,
			"life":1.0,
			"owner":"player_primary",
		}),
		"primary collision fixture accepts one uniform round"
	)
	run.call("_update_projectiles", 0.30)
	_expect(
		first_target.health < first_health,
		"uniform primary fire damages an enemy in a maximum-capacity slot"
	)
	_expect(
		is_equal_approx(rear_target.health, rear_health)
			and run.projectile_store.player_count() == 0,
		"a non-piercing primary round stops at the first enemy"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUN_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
