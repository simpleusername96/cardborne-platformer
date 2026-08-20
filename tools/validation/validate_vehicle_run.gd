extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyTargetingPolicy = preload(
	"res://scripts/enemies/vehicle_enemy_targeting_policy.gd"
)
const EnemyUpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"
const RUN_SOURCE := "res://scripts/vehicle/vehicle_run.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_SOURCE)
	_expect(
		run_source.contains('tr("NOTIFY_BOSS_INBOUND"), 1.5')
			and run_source.contains('tr("NOTIFY_BARRIER_DEPLETED"),'),
		"live boss-inbound and barrier-depleted danger messages interrupt lower-priority text"
	)
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
		_expect(
			run._manual_performance_request.is_empty()
				and run._manual_performance_trace == null,
			"normal play does not allocate or activate manual performance tracing"
		)
		var pressure_probe := {}
		run.encounter_runtime.fill_current_pressure(pressure_probe)
		_expect(
			pressure_probe.has("ordinary_authored_pressure_cap")
				and pressure_probe.has("ordinary_materialized_cap")
				and pressure_probe.has("ordinary_virtual_reserve")
				and pressure_probe.has("ordinary_reserved_arrival_slots")
				and pressure_probe.has("ordinary_materialized")
				and pressure_probe.has("ordinary_center_in_viewport")
				and int(pressure_probe["ordinary_offscreen_active"])
					== maxi(
						0,
						int(pressure_probe["ordinary_materialized"])
							- int(pressure_probe["ordinary_center_in_viewport"])
					),
			"manual diagnostics expose a scan-free authored/materialized/reserve pressure split"
		)
		_expect(run.current_stage_id == &"stage_1" and run.player_position == Vector2(3600,2160), "run begins at shared center")
		_expect(run.PLAYER_BASE_SPEED == 280.0, "player base speed remains 280 px/s")
		_expect(
			is_equal_approx(StageDifficulty.ORDINARY_HEALTH_MULTIPLIER, 2.60),
			"all non-boss enemy health receives the requested doubled final multiplier"
		)
		_expect(
			is_equal_approx(SpecialistRuntime.REPAIR_PER_SECOND, 8.0)
				and is_equal_approx(SpecialistRuntime.FIXED_SUPPORT_HEAL_PER_TICK, 8.0),
			"Support Ordinary Enemy Lv.1 and generator healing are doubled"
		)
		_expect(run.PICKUP_BODY_RADIUS == 42.0, "pickup body radius is 42 px")
		_expect(run.MINIMAP_COLS == 20 and run.MINIMAP_ROWS == 12, "run uses 20x12 explored minimap")
		_expect(run.ORDINARY_DECISION_BUCKET_COUNT == 6, "ordinary high-cost decisions are distributed at 10 Hz")
		_expect(run._camera.zoom == Rules.GAMEPLAY_CAMERA_ZOOM, "gameplay camera uses the shared half-scale world zoom")
		var visible_rect: Rect2 = run.call("_visible_world_rect", 0.0)
		_expect(
			float(run.call("_primary_projectile_range"))
				>= visible_rect.size.length() + run.PRIMARY_VISIBLE_RANGE_MARGIN,
			"primary range covers the full visible field diagonal with margin"
		)
		_check_upgrade_transaction_contract(run)
		_check_upgrade_stage_transition_collision(run)
		_check_progression_completion_contract(run)
		_check_primary_action_identity(run)
		_check_active_recharge_integration(run)
		run.call("_reset_run", false)
		_check_lifesteal_contract(run)
		_check_status_damage_feedback(run)
		run.call("_reset_run", false)
		_check_visual_collision_separation(run)
		_check_critical_enemy_attack_progression(run)
		_check_ordinary_predicted_commitment(run)
		var boss_arrival: Vector2 = run.call("_choose_boss_arrival_anchor")
		_expect(
			run.player_position.distance_to(boss_arrival)
				>= run.BOSS_ARRIVAL_MIN_DISTANCE,
			"boss arrival uses a reachable anchor beyond the documented minimum"
		)
		var initial_fingerprint := int(run.field_layout.fingerprint)
		run.run_build.apply(&"chassis_speed")
		run.visited_cells[Vector2i(2,2)] = true
		run.current_stage_index = 1
		run.current_stage_id = Catalog.STAGE_IDS[1]
		run.call("_reset_run", false, true, true)
		_expect(int(run.field_layout.fingerprint) == initial_fingerprint, "stage reset preserves run-scoped field geometry")
		_expect(run.run_build.has(&"chassis_speed") and run.visited_cells.has(Vector2i(2,2)), "stage reset preserves build and exploration")
		_expect(run.player_position == Vector2(3600,2160), "stage reset starts at the shared center")
		var hud: Dictionary = run.call("_build_hud_snapshot")
		_expect(hud["minimap"]["cols"] == 20 and hud["guidebook"].has("categories"), "HUD exposes minimap and guide snapshots")
		_check_nearby_radar_contacts(run)
		run.call("_reset_run", false, true, true)
		var ui = run.get_node_or_null("VehicleStageUI")
		var ui_contract: Dictionary = ui.debug_ui_contract() if ui != null else {}
		var component_owners := Dictionary(ui_contract.get("component_owners", {}))
		_expect(
			ui == run._ui
				and String(component_owners.get("guidebook", ""))
					== "res://scripts/ui/vehicle_guidebook_panel.gd",
			"guidebook modal is connected through the shared Stage UI owner"
		)
		run.call("_present_deployment")
		var deployment_guide := Dictionary(
			run._ui._latest_guidebook_snapshot
		)
		_expect(
			Array(deployment_guide.get("category_order", [])).size() == 4
				and Dictionary(deployment_guide.get("categories", {})).has(&"ship"),
			"deployment publishes a complete Guidebook before gameplay HUD updates"
		)
		_check_simulation_lod_contract(run)
		_check_boss_progression_gate(run)
		_check_boss_damage_and_guidance(run, ui)
		run.call("_reset_run", false, true, true)
		_check_boss_autonomous_shapes(run)
		_check_boss_emitted_cross(run)
		run.call("_reset_run", false, true, true)
		_check_boss_committed_recovery(run)
		run.call("_reset_run", false, true, true)
		_check_enemy_expansion(run)
		run.call("_reset_run", false, true, true)
		_check_combat_presentation_frame(run)
		_check_primary_collision_at_horde_capacity(run)
		_check_hot_path_guards(run)
		_check_effect_store(run)
	root.queue_free()
	await process_frame
	_finish()


func _check_upgrade_transaction_contract(run) -> void:
	for visible_count in [1, 2]:
		run.capture_set_mode(&"playing")
		run.call("_open_upgrade_reward", &"level_up")
		_expect(
			run.current_card_offer.size() == 3
				and run.upgrade_offer_error.is_empty(),
			"fresh runtime reward freezes three legal cards"
		)
		if run.current_card_offer.size() != 3:
			return
		run.current_card_offer = run.current_card_offer.slice(0, visible_count)
		var tail_id := StringName(run.current_card_offer[0]["id"])
		_expect(
			run.apply_upgrade(tail_id),
			"runtime applies one legal card from a %d-card tail offer" % visible_count
		)
		run.call("_resolve_reward_transaction")
	run.capture_set_mode(&"playing")
	run.call("_open_upgrade_reward", &"level_up")
	if run.current_card_offer.is_empty():
		return
	var offered_id := StringName(run.current_card_offer[0]["id"])
	var unoffered_id := &""
	for definition in run.upgrade_catalog.all_definitions():
		if not run.call("_current_offer_contains", definition.id):
			unoffered_id = definition.id
			break
	var levels_before: int = int(run.run_build.total_levels())
	run.upgrade_offer_error = {"reason":"validation"}
	_expect(
		not run.apply_upgrade(offered_id)
			and run.run_build.total_levels() == levels_before,
		"runtime rejects selection while offer construction has an error"
	)
	run.upgrade_offer_error.clear()
	_expect(
		not run.apply_upgrade(unoffered_id)
			and run.run_build.total_levels() == levels_before,
		"runtime rejects a legal but unoffered upgrade without mutation"
	)
	_expect(
		run.apply_upgrade(offered_id)
			and run.run_build.total_levels() == levels_before + 1,
		"runtime applies one card from the exact frozen offer"
	)
	_expect(
		not run.apply_upgrade(offered_id)
			and run.run_build.total_levels() == levels_before + 1,
		"runtime rejects a double submit in the same transaction"
	)
	run.call("_resolve_reward_transaction")
	run.capture_set_mode(&"playing")
	_expect(
		not run.apply_upgrade(offered_id)
			and run.run_build.total_levels() == levels_before + 1,
		"runtime rejects a stale selection after the transaction closes"
	)


func _check_upgrade_stage_transition_collision(run) -> void:
	var transition = run.stage_transition_runtime
	transition.reset()
	run.set("_physics_serial", 200)
	_expect(
		bool(transition.begin(0, Catalog.STAGE_IDS.size(), &"after_boss", 200)["accepted"]),
		"stage transition collision fixture starts a continuation"
	)
	for serial in range(201, 205):
		transition.advance(serial)
	run.set("_physics_serial", 205)
	run.experience_runtime.pending_level_ups = 1
	run.capture_set_mode(&"playing")
	run.call("_open_upgrade_reward", &"level_up")
	var offer_id := (
		StringName(run.current_card_offer[0]["id"])
		if not run.current_card_offer.is_empty()
		else &""
	)
	var transition_before := Dictionary(transition.debug_snapshot())
	run.call("_advance_stage_transition")
	var transition_after := Dictionary(transition.debug_snapshot())
	_expect(
		not offer_id.is_empty()
			and StringName(run.reward_runtime.current_source()) == &"level_up"
			and transition_after == transition_before,
		"an upgrade modal parks a same-frame stage transition without losing its transaction"
	)
	run.call("_on_upgrade_selected", offer_id)
	_expect(
		run.experience_runtime.pending_level_ups == 0
			and run.reward_runtime.is_idle()
			and run.current_card_offer.is_empty()
			and transition.active(),
		"the level-up reward resolves before the parked transition can resume"
	)
	transition.reset()


func _check_progression_completion_contract(run) -> void:
	while true:
		var compatible: Array = run.upgrade_catalog.compatible_definitions(run.run_build)
		if compatible.is_empty():
			break
		var definition = compatible[0]
		_expect(
			bool(run.run_build.apply(definition.id).get("applied", false)),
			"catalog exhaustion fixture applies every reachable level"
		)
	run.experience_runtime.pending_level_ups = 2
	run.experience_runtime.spawn_shard(run.player_position, 40)
	run.capture_set_mode(&"playing")
	run.call("_open_upgrade_reward", &"level_up")
	_expect(
		not run.experience_runtime.progression_complete
			and run.experience_runtime.pending_level_ups == 2
			and run.current_card_offer.size() == 3
			and run.current_card_offer.all(func(card): return StringName(card["id"]) in run.run_build.FALLBACK_IDS),
		"zero compatible cards open the three fallback progression choices"
	)
	var selected_fallback := StringName(run.current_card_offer[0]["id"])
	run.call("_on_upgrade_selected", selected_fallback)
	_expect(
		run.experience_runtime.pending_level_ups == 1
			and run.current_card_offer.size() == 3,
		"the next pending XP level opens another fallback choice"
	)
	run.call("_on_upgrade_selected", StringName(run.current_card_offer[0]["id"]))
	for fallback_id in run.run_build.FALLBACK_IDS:
		while bool(run.run_build.fallback_preview(fallback_id).get("valid", false)):
			run.run_build.apply_fallback(fallback_id)
	run.experience_runtime.pending_level_ups = 1
	run.capture_set_mode(&"playing")
	run.call("_open_upgrade_reward", &"level_up")
	var notification := Dictionary(run._ui.debug_notification_contract())
	var fast_snapshot := Dictionary(run.call("_build_fast_hud_snapshot"))
	_expect(
		run.experience_runtime.progression_complete
			and run.experience_runtime.pending_level_ups == 0
			and run.experience_runtime.shards.is_empty()
			and run.reward_runtime.is_idle()
			and run.current_card_offer.is_empty()
			and run.upgrade_offer_error.is_empty(),
		"maxed cards and fallback ranks resolve through explicit progression completion"
	)
	_expect(
		String(notification["active_message"]) == tr("NOTIFY_ALL_UPGRADES_COMPLETE")
			and bool(fast_snapshot["experience_complete"]),
		"completion receipt is visible and the fast HUD publishes EXP MAX"
	)
	run.experience_runtime.spawn_shard(run.player_position, 99)
	_expect(
		run.experience_runtime.shards.is_empty(),
		"future enemy rewards cannot create hidden XP after MAX"
	)


func _check_lifesteal_contract(run) -> void:
	run.run_build.reset()
	run.call("_reset_run", false, true, true)
	run.player_health = 50.0
	var baseline_target: EnemyState = run.call("_make_enemy", {
		"id":"lifesteal_baseline_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(380.0, 0.0),
		"active":true,
	})
	baseline_target.health = 100.0
	baseline_target.max_health = 100.0
	run.call(
		"_damage_enemy",
		baseline_target,
		100.0,
		"player_primary",
		&"kinetic",
		true
	)
	_expect(
		is_equal_approx(float(run.player_health), 50.5),
		"player-owned damage restores the baseline half percent without the card"
	)
	run.enemy_store.release_untracked(baseline_target)

	_expect(
		bool(run.run_build.apply(&"lifesteal").get("applied", false)),
		"Lifesteal level one applies to the run build"
	)
	run.call("_reset_run", false, true, true)
	run.player_health = 50.0
	var overkill_target: EnemyState = run.call("_make_enemy", {
		"id":"lifesteal_overkill_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(420.0, 0.0),
		"active":true,
	})
	overkill_target.health = 50.0
	overkill_target.max_health = 50.0
	run.call(
		"_damage_enemy",
		overkill_target,
		100.0,
		"player_primary",
		&"kinetic",
		true
	)
	_expect(
		is_equal_approx(float(run.player_health), 50.75),
		"Lifesteal uses actual applied damage after enemy overkill clamping"
	)
	run.enemy_store.release_untracked(overkill_target)

	var excluded_health := float(run.player_health)
	var excluded_target: EnemyState = run.call("_make_enemy", {
		"id":"lifesteal_excluded_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(460.0, 0.0),
		"active":true,
	})
	run.call(
		"_damage_enemy",
		excluded_target,
		20.0,
		"enemy_probe",
		&"kinetic",
		false
	)
	run.call(
		"_damage_enemy",
		excluded_target,
		20.0,
		"validation",
		&"kinetic",
		true
	)
	_expect(
		is_equal_approx(float(run.player_health), excluded_health),
		"hostile and validation damage receipts never restore player Hull"
	)
	run.enemy_store.release_untracked(excluded_target)

	_expect(
		bool(run.run_build.apply(&"lifesteal").get("applied", false)),
		"Lifesteal level two applies to the run build"
	)
	run.lifesteal_runtime.reset(
		run.run_build.stat(&"lifesteal_percent", 0.0)
	)
	var level_two_target: EnemyState = run.call("_make_enemy", {
		"id":"lifesteal_level_two_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(500.0, 0.0),
		"active":true,
	})
	level_two_target.health = 200.0
	level_two_target.max_health = 200.0
	run.call(
		"_damage_enemy",
		level_two_target,
		200.0,
		"player_primary",
		&"kinetic",
		true
	)
	_expect(
		is_equal_approx(float(run.player_health), excluded_health + 4.4),
		"Lifesteal level two applies its gradual 2.2-percent recovery"
	)
	run.enemy_store.release_untracked(level_two_target)

	run.lifesteal_runtime.reset(
		run.run_build.stat(&"lifesteal_percent", 0.0)
	)
	run.player_health = run.call("_player_max_health") - 1.0
	var hull_limit_target: EnemyState = run.call("_make_enemy", {
		"id":"lifesteal_hull_limit_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(540.0, 0.0),
		"active":true,
	})
	run.call(
		"_damage_enemy",
		hull_limit_target,
		100.0,
		"player_primary",
		&"kinetic",
		true
	)
	_expect(
		is_equal_approx(
			float(run.player_health),
			float(run.call("_player_max_health"))
		),
		"Lifesteal never restores beyond maximum Hull"
	)
	run.enemy_store.release_untracked(hull_limit_target)


func _check_status_damage_feedback(run) -> void:
	var enemy: EnemyState = run.call("_make_enemy", {
		"id":"status_feedback_enemy",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(180.0, 0.0),
		"active":true,
	})
	_expect(enemy != null, "status feedback fixture creates an ordinary enemy")
	if enemy == null:
		return
	var direct_damage := float(run.call(
		"_damage_enemy", enemy, 1.0, "validation", &"kinetic", false
	))
	_expect(
		direct_damage > 0.0 and is_equal_approx(enemy.flash, 0.11),
		"direct damage retains the generic enemy hit flash"
	)
	enemy.flash = 0.0
	var status_damage := float(run.call(
		"_damage_enemy",
		enemy,
		1.0,
		"status",
		&"toxin",
		false,
		false,
		false
	))
	_expect(
		status_damage > 0.0 and is_zero_approx(enemy.flash),
		"Toxin DOT changes health without restarting the generic hit flash"
	)
	run.enemy_store.release_untracked(enemy)


func _check_visual_collision_separation(run) -> void:
	for fixture in [
		[&"ordinary_pursuer_t1", 18.0, 48.0, 56.0],
		[&"ordinary_pursuer_t2", 18.0, 48.0, 70.0],
		[&"ordinary_pursuer_t3", 18.0, 48.0, 84.0],
		[&"boss_pattern_fixed_beam_01", 34.0, 62.0, 62.0],
		[&"boss_actor", 76.0, 146.0, 146.0],
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
				and is_equal_approx(enemy.visual_radius, float(fixture[3])),
			"%s keeps compact movement plus explicit visual and projectile target radii" % fixture[0]
		)
		run.enemy_store.release_untracked(enemy)
	var ordering_enemy := EnemyState.new()
	ordering_enemy.id = "structure_limit_probe"
	ordering_enemy.role = &"ordinary_edge_01"
	ordering_enemy.archetype = &"ordinary_edge_01"
	ordering_enemy.alive = true
	ordering_enemy.active = true
	ordering_enemy.pos = Vector2(70.0, 0.0)
	ordering_enemy.radius = 10.0
	ordering_enemy.projectile_hit_radius = 10.0
	var ordering_projectile := ProjectileState.new()
	ordering_projectile.radius = 2.0
	var ordering_candidates: Array[EnemyState] = [ordering_enemy]
	_expect(
		run.call(
			"_player_projectile_contact",
			ordering_projectile,
			Vector2.ZERO,
			Vector2(100.0, 0.0),
			2.0,
			ordering_candidates,
			PackedInt32Array(),
			PackedFloat32Array(),
			0.40
		) == null,
		"a nearer structure limit excludes enemies behind it from direct contact"
	)
	_expect(
		run.call(
			"_player_projectile_contact",
			ordering_projectile,
			Vector2.ZERO,
			Vector2(100.0, 0.0),
			2.0,
			ordering_candidates,
			PackedInt32Array(),
			PackedFloat32Array(),
			0.80
		) == ordering_enemy,
		"an enemy before the structure limit remains the first direct contact"
	)


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


func _check_critical_enemy_attack_progression(run) -> void:
	var projectile_store: RefCounted = run.get("projectile_store")
	projectile_store.call("clear")
	var gunner: EnemyState = run.call("_make_enemy", {
		"id":"critical_attack_progression",
		"role":&"ordinary_gunner_t1",
		"pos":run.player_position + Vector2(-320.0, 0.0),
		"active":true,
	})
	gunner.phase = &"startup"
	gunner.phase_time = 0.0
	gunner.committed_dir = Vector2.RIGHT
	gunner.committed_target = run.player_position
	var phase_time_before := gunner.phase_time
	run.call("_update_scheduled_ordinary_enemy", gunner, 1.0 / 60.0)
	_expect(
		gunner.phase_time < phase_time_before
			or gunner.phase in [&"recovery", &"active"],
		"critical ordinary startup advances on the 60 Hz path"
	)
	_expect(
		gunner.phase == &"recovery" and projectile_store.call("hostile_count") == 1,
		"critical Gunner reaches its real fire path instead of freezing"
	)
	projectile_store.call("clear")
	run.enemy_store.release_untracked(gunner)


func _check_ordinary_predicted_commitment(run) -> void:
	var pressure_focus: Vector2 = run.player_position
	var origin := pressure_focus + Vector2(-500.0, 0.0)
	var found_clear_focus_line := false
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var candidate: Vector2 = pressure_focus + Vector2(direction) * 500.0
		if bool(run.call(
			"_runtime_has_line_of_sight", candidate, pressure_focus, 7.0
		)):
			origin = candidate
			found_clear_focus_line = true
			break
	_expect(found_clear_focus_line, "ordinary attack fixture finds a clear focus line")
	var ordinary_lane_01: EnemyState = run.call("_make_enemy", {
		"id":"ordinary_predicted_commitment",
		"role":&"ordinary_lane_01",
		"pos":origin,
		"active":true,
	})
	var original_velocity: Vector2 = run.player_velocity
	run.player_velocity = Vector2(0.0, 220.0)
	var attack := AttackContract.ordinary_attack(&"ordinary_lane_01")
	var predicted := EnemyTargetingPolicy.attack_target(
		&"ordinary_lane_01",
		origin,
		pressure_focus,
		run.player_velocity,
		float(attack["startup"]),
		Director.effective_hostile_projectile_speed(float(attack["speed"]))
	)
	var expected := predicted
	if not bool(run.call("_runtime_has_line_of_sight", origin, predicted, 7.0)):
		expected = pressure_focus
	run.call("_start_enemy_attack", ordinary_lane_01)
	var committed := ordinary_lane_01.committed_target
	_expect(
		committed.is_equal_approx(expected)
			and committed.distance_to(pressure_focus) <= 260.001,
		"ordinary projectile startup uses bounded prediction with geometry fallback"
	)
	run.player_position += Vector2(0.0, 90.0)
	_expect(
		ordinary_lane_01.committed_target == committed,
		"ordinary predicted aim remains frozen after startup commitment"
	)
	run.player_position = pressure_focus
	run.player_velocity = original_velocity
	run.enemy_store.release_untracked(ordinary_lane_01)


func _check_primary_action_identity(run) -> void:
	run.call("_clear_projectiles")
	for _level in 3:
		run.run_build.apply(&"split_muzzle")
	run.call("_fire_primary")
	var projectiles: Array = run.projectile_store.player_live
	var shared_serial: int = (
		projectiles[0].combat_action_serial if not projectiles.is_empty() else 0
	)
	_expect(
		projectiles.size() == 3
			and shared_serial > 0
			and projectiles.all(
				func(projectile) -> bool: return (
					projectile.combat_action_family == &"primary"
					and projectile.combat_action_serial == shared_serial
				)
			),
		"one Split Muzzle volley shares one primary combat-action identity"
	)


func _check_active_recharge_integration(run) -> void:
	run.active_recharge_runtime.reset()
	run.active_weapon_runtime.cooldown_remaining = 5.0
	var first: EnemyState = run.call("_make_enemy", {
		"id":"recharge_direct_first",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(300.0, 0.0),
		"active":true,
	})
	var second: EnemyState = run.call("_make_enemy", {
		"id":"recharge_direct_second",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(340.0, 0.0),
		"active":true,
	})
	run.call(
		"_damage_enemy", first, 1.0, "player_primary", &"kinetic", true,
		false, true, OutgoingDamagePolicy.DAMAGE_DIRECT, 901, &"primary"
	)
	run.call(
		"_damage_enemy", second, 1.0, "player_primary", &"kinetic", true,
		false, true, OutgoingDamagePolicy.DAMAGE_DIRECT, 901, &"primary"
	)
	var after_direct: float = run.active_weapon_runtime.cooldown_remaining
	run.call(
		"_damage_enemy", second, 1.0, "thermal_burst", &"thermal", true,
		false, false, 0, 902
	)
	_expect(
		is_equal_approx(after_direct, 4.9)
			and is_equal_approx(run.active_weapon_runtime.cooldown_remaining, 4.9),
		"Run credits one direct action once and excludes derived damage without an action family"
	)
	run.enemy_store.release_untracked(first)
	run.enemy_store.release_untracked(second)


func _check_boss_progression_gate(run) -> void:
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "boss_actor") == null, "boss cannot spawn before ordinary defeats")
	run.stage_flow.defeats = run.stage_flow.quota - 1
	run.call("_start_stage_boss")
	_expect(run.call("_find_enemy_by_id", "boss_actor") == null, "boss remains blocked one defeat before quota")
	var quota_enemy: EnemyState = run.call("_make_enemy", {
		"id":"quota_transition_probe",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(600.0, 0.0),
		"active":true,
	})
	_expect(
		quota_enemy != null and run.call("_append_enemy", quota_enemy),
		"quota transition fixture materializes one countable ordinary enemy"
	)
	run.call("_defeat_enemy", quota_enemy, "validation")
	run.enemy_store.flush_defeated()
	_expect(
		run.stage_flow.state == StageFlow.State.BOSS_WARNING
			and run.encounter_runtime.quota_sealed()
			and run.encounter_runtime.spawning_enabled(),
		"the exact final countable defeat seals quota progression but keeps boss maintenance available"
	)
	var blocked_live_count := (
		EnemyStore.MAX_LIVE_HOSTILES
		- BossPhaseCatalog.BOSS_ENTRY_SLOT_RESERVE
		+ 1
	)
	var filler_ids := PackedStringArray()
	while run.enemy_store.live_count() < blocked_live_count:
		var filler_id := "boss_capacity_filler_%03d" % filler_ids.size()
		var filler: EnemyState = run.call("_make_enemy", {
			"id":filler_id,
			"role":&"ordinary_melee_01",
			"pos":run.player_position + Vector2(float(filler_ids.size()), 500.0),
			"active":true,
		})
		if filler == null or not run.call("_append_enemy", filler):
			break
		filler_ids.append(filler_id)
	run.call("_update_stage_progression", 1.5)
	_expect(
		run.stage_flow.boss_entry_ready()
			and run.call("_find_enemy_by_id", "boss_actor") == null
			and run.enemy_store.live_count() == blocked_live_count,
		"boss entry remains pending when the reserved capacity is unavailable"
	)
	var released_filler_id := String(filler_ids[0])
	var released_filler: EnemyState = run.call(
		"_find_enemy_by_id", released_filler_id
	)
	released_filler.alive = false
	run.enemy_store.queue_defeat(released_filler)
	run.enemy_store.flush_defeated()
	run.call("_update_stage_progression", 0.0)
	_expect(
		run.call("_find_enemy_by_id", "boss_actor") != null
			and run.enemy_store.live_count() <= EnemyStore.MAX_LIVE_HOSTILES,
		"pending boss entry retries after one slot clears and never exceeds capacity"
	)
	for filler_id in filler_ids:
		var filler_enemy: EnemyState = run.call("_find_enemy_by_id", String(filler_id))
		if filler_enemy == null:
			continue
		filler_enemy.alive = false
		run.enemy_store.queue_defeat(filler_enemy)
	run.enemy_store.flush_defeated()
	_expect(
		run.encounter_runtime.quota_sealed()
			and run.encounter_runtime.spawning_enabled(),
		"boss maintenance keeps ordinary admission available without reopening quota progression"
	)


func _check_boss_damage_and_guidance(run, ui) -> void:
	var boss: EnemyState = run.call("_find_enemy_by_id", "boss_actor")
	_expect(boss != null, "boss guidance fixture has a live boss")
	if boss == null:
		return
	var health_before := boss.health
	var effect_count_before: int = run.effects.size()
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
	var expected_damage := 100.0
	_expect(
		is_equal_approx(applied, expected_damage)
			and is_equal_approx(health_before - boss.health, expected_damage),
		"the unshielded first boss receives full damage"
	)
	_expect(
		run.effects.size() == effect_count_before,
		"shielded boss damage does not create floating damage feedback"
	)
	var hud := Dictionary(run.call("_build_hud_snapshot"))
	_expect(
		not hud.has("boss")
			and not hud.has("target")
			and int(hud["stage_number"]) == run.current_stage_index + 1
			and int(hud["stage_total"]) == Catalog.STAGE_IDS.size()
			and int(hud["stage_quota_remaining"]) >= 0
			and int(hud["cumulative_defeated"]) == run.stats_enemies_defeated
			and not hud.has("defeated")
			and not hud.has("quota"),
		"HUD publishes stage progress, remaining quota, and cumulative defeats without edge health"
	)
	var minimap_markers := Array(hud["minimap"]["markers"])
	var boss_markers := minimap_markers.filter(
		func(marker_variant) -> bool:
			var marker := Dictionary(marker_variant)
			return StringName(marker.get("kind", &"")) == &"boss"
	)
	var only_shared_minimap_roles := true
	for marker_variant in minimap_markers:
		if StringName(Dictionary(marker_variant).get("kind", &"")) not in [
			&"field_pickup", &"mystery_device",
			&"mobile_enemy", &"priority_enemy", &"boss",
		]:
			only_shared_minimap_roles = false
			break
	_expect(
		boss_markers.size() == 1 and only_shared_minimap_roles,
		"minimap exposes one dedicated boss marker without objective actors"
	)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", 0.11)
	var objective_contacts: Array = Array(
		run._threat_radar_feed.snapshot()["sectors"]
	).filter(
		func(contact_variant) -> bool:
			var contact := Dictionary(contact_variant)
			return bool(contact.get("active", false)) and StringName(
				contact.get("kind", &"")
			) == &"boss_objective"
	)
	_expect(
		objective_contacts.is_empty(),
		"off-screen radar has no removed boss-objective contact"
	)
	ui.update_hud(hud)
	_expect(
		ui._hud._status_cluster.visible
			and ui._hud._status_item(&"stage")._value_label.text == tr("HUD_BOSS_PROGRESS_VALUE") % [
				run.current_stage_index + 1,
				Catalog.STAGE_IDS.size(),
				int(hud["stage_quota_remaining"]),
			],
		"panel-free semantic stage item remains visible during the boss encounter"
	)


func _check_boss_committed_recovery(run) -> void:
	var boss: EnemyState = run.call("_make_enemy", {
		"id":"validation_boss", "role":&"boss_actor",
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


func _check_boss_autonomous_shapes(run) -> void:
	for boss_index in 8:
		var stage_index := boss_index
		var stage_id := StringName("stage_%d" % (stage_index + 1))
		for pattern_name in BossPatterns.autonomous_sequence(stage_id):
			var pattern := String(pattern_name)
			var kind := BossPatterns.kind(pattern)
			run.denied_zones.clear()
			var enemies_before: int = run.enemy_store.live.size()
			var projectiles_before: int = run.projectile_store.hostile_count()
			run.call("_execute_boss_autonomous", {
				"id":"validation_%d_%s" % [stage_index, pattern],
				"pattern":pattern,
				"kind":kind,
				"origin":run.player_position + Vector2(-480.0, 0.0),
				"target":run.player_position + Vector2(240.0, 0.0),
				"startup":BossPatterns.startup_seconds(pattern),
				"duration":BossPatterns.active_seconds(pattern),
				"damage":BossPatterns.damage(pattern, stage_index),
				"radius":BossPatterns.radius(pattern, stage_index),
				"width":BossPatterns.width(pattern, stage_index),
				"lane_spacing":BossPatterns.lane_spacing(stage_index),
				"affinity":BossPatterns.affinity(pattern),
			})
			if kind == &"area":
				_expect(
					run.denied_zones.size() == 1
						and StringName(run.denied_zones[0]["shape"]) == &"area"
						and is_equal_approx(
							float(run.denied_zones[0]["radius"]),
							BossPatterns.radius(pattern, stage_index)
						),
					"%s executes as its exact scaled circular area" % pattern
				)
			elif kind == &"lanes":
				_expect(
					run.denied_zones.size() == 2
						and _all_corridors_match(
							run.denied_zones,
							BossPatterns.width(pattern, stage_index)
						)
						and run.denied_zones.all(func(zone): return (
							is_equal_approx(
								float(zone["beam_growth_seconds"]),
								AttackContract.EMITTED_BEAM_GROWTH_SECONDS
							)
							and StringName(zone["beam_emission_mode"])
								== AttackContract.EMITTED_BEAM_FORWARD
						)),
					"%s executes as two forward-emitted growing beams" % pattern
				)
			elif kind == &"beam":
				_expect(
					run.denied_zones.size() == 2
						and run.denied_zones.all(func(zone): return (
							StringName(zone["shape"]) == &"corridor"
							and is_equal_approx(float(zone["width"]), BossPatterns.width(pattern, stage_index))
							and is_equal_approx(float(zone["beam_growth_seconds"]), AttackContract.EMITTED_BEAM_GROWTH_SECONDS)
							and is_equal_approx(float(zone["duration_total"]), maxf(0.62, BossPatterns.active_seconds(pattern)))
							and StringName(zone["beam_emission_mode"]) == AttackContract.EMITTED_BEAM_FORWARD
							and StringName(zone["beam_topology"]) == AttackContract.BEAM_TOPOLOGY_PARALLEL
						)),
					"%s executes as two collision-owned forward-emitted beams" % pattern
				)
			elif kind == &"summon":
				_expect(
					run.enemy_store.live.size() == enemies_before + 1,
					"%s executes through the bounded sentinel summon path" % pattern
				)
			elif kind == &"long_banks":
				_expect(
					run.projectile_store.hostile_count() > projectiles_before,
					"%s emits its bounded projectile formation" % pattern
				)
			elif kind == &"crossing_weave":
				_expect(
					run.denied_zones.size() == 8
						and run.denied_zones.all(func(zone): return StringName(zone["shape"]) == &"corridor" and Vector2(zone["motion"]).length() > 0.0 and is_equal_approx(float(zone["safe_gap"]), 200.0) and not zone.has("beam_emission_mode")),
					"%s creates crossing translating walls with collision-true gaps" % pattern
				)
			elif kind == &"alternating_pulse":
				_expect(
					run.denied_zones.size() == 2
						and StringName(run.denied_zones[0]["shape"]) == &"wedge_ring"
						and StringName(run.denied_zones[1]["shape"]) == &"wedge_ring"
						and is_equal_approx(
							float(run.denied_zones[1]["radius"]),
							BossPatterns.radius(pattern, stage_index)
						)
						and StringName(run.denied_zones[1]["activation_kind"]) == &"radial_volley",
					"%s creates alternating warned safe sectors and one bounded volley" % pattern
				)
			else:
				_expect(false, "%s has an unsupported autonomous kind" % pattern)


func _all_corridors_match(zones: Array, expected_width: float) -> bool:
	for zone_variant in zones:
		var zone: Dictionary = zone_variant
		if (
			StringName(zone["shape"]) != &"corridor"
			or not is_equal_approx(float(zone["width"]), expected_width)
		):
			return false
	return true


func _check_boss_emitted_cross(run) -> void:
	run.denied_zones.clear()
	var boss: EnemyState = run.call("_make_enemy", {
		"id":"validation_cross_boss",
		"role":&"boss_actor",
		"pos":run.player_position + Vector2(-480.0, 0.0),
		"active":true,
	})
	boss.committed_dir = Vector2.RIGHT
	boss.attack_telegraphs = [{"delivery":&"beam"}]
	run.call(
		"_append_boss_cross_corridors",
		boss,
		"cross_beam",
		BossPatterns.damage("cross_beam", run.current_stage_index)
	)
	_expect(
		run.denied_zones.size() == 2
			and run.denied_zones.all(func(zone): return (
				StringName(zone["shape"]) == &"corridor"
				and StringName(zone["beam_emission_mode"])
					== AttackContract.EMITTED_BEAM_BIDIRECTIONAL
				and Vector2(zone["beam_emitter"]).is_equal_approx(boss.pos)
				and is_equal_approx(
					float(zone["beam_growth_seconds"]),
					AttackContract.EMITTED_BEAM_GROWTH_SECONDS
				)
			))
			and boss.attack_telegraphs.is_empty(),
		"Cross Beam transfers two bidirectional emitted-beam axes to collision zones"
	)
	run.denied_zones.clear()
	run.enemy_store.release_untracked(boss)


func _check_enemy_expansion(run) -> void:
	var guard: EnemyState = run.call("_make_enemy", {
		"id":"validation_guard", "role":&"ordinary_defender_t1",
		"pos":run.player_position + Vector2(300.0, 0.0), "active":true,
	})
	var primary_round := ProjectileState.new()
	primary_round.velocity = Vector2.RIGHT
	primary_round.structure_damage = 18.0
	for expected_structure in [54.0, 36.0, 18.0, 0.0]:
		_expect(
			bool(run.call("_try_absorb_protective_structure", guard, primary_round))
				and is_equal_approx(guard.guard_plate_structure, expected_structure),
			"sustained primary fire chips the Defender plate by one uniform hit"
		)
	run.enemy_store.release_untracked(guard)

	var splitter: EnemyState = run.call("_make_enemy", {
		"id":"validation_splitter", "role":&"ordinary_pursuer_t1",
		"pack_family":&"pursuer", "pack_trait":&"splitter",
		"pos":run.player_position + Vector2(-300.0, 0.0), "active":true,
	})
	run.encounter_runtime.current_beat = 4
	run.call("_append_enemy", splitter)
	run.call("_defeat_enemy", splitter, "player_primary")
	var children := 0
	for enemy in run.enemies:
		if enemy.alive and enemy.carrier_id == "splitter:validation_splitter":
			children += 1
	_expect(children == 2, "Splitter emits exactly two bounded traitless T1 children when capacity permits")


func _check_primary_collision_at_horde_capacity(run) -> void:
	run.call("_clear_enemies")
	run.call("_clear_projectiles")
	for index in EnemyStore.MAX_LIVE_HOSTILES - 2:
		var filler: EnemyState = run.call("_make_enemy", {
			"id":"collision_filler_%d" % index,
			"role":&"ordinary_edge_01",
			"pos":run.player_position + Vector2(-500.0, 400.0),
			"active":true,
		})
		_expect(
			filler != null and bool(run.call("_append_enemy", filler)),
			"collision fixture fills every non-target enemy slot"
		)
	var first_target: EnemyState = run.call("_make_enemy", {
		"id":"collision_first_target",
		"role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(240.0, 38.0),
		"active":true,
	})
	var rear_target: EnemyState = run.call("_make_enemy", {
		"id":"collision_rear_target",
		"role":&"ordinary_edge_01",
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
	_check_runtime_minimap_at_horde_capacity(run)
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


func _check_combat_presentation_frame(run) -> void:
	var original_protection: Dictionary = (
		run.player_protection_sources.duplicate()
	)
	var original_mines: Array = run.secondary_runtime.mines.duplicate(true)
	var original_orbit_angle := float(run.secondary_runtime.orbit_angle)
	run.player_protection_sources.clear()
	run.player_protection_sources[&"emp"] = 0.40
	run.secondary_runtime.mines.clear()
	run.secondary_runtime.mines.append({
		"pos":run.player_position + Vector2(48.0, 0.0),
		"life":3.25,
	})
	run.secondary_runtime.orbit_angle = 0.37
	var oracle: Dictionary = run.call("_combat_presentation_snapshot")
	var first: Dictionary = run.call("_runtime_combat_presentation_snapshot")
	var secondary: Dictionary = first["secondary"]
	_expect(
		_presentation_snapshots_match(oracle, first),
		"borrowed combat presentation matches every renderer-visible cold-oracle field"
	)
	_expect(
		is_same(first["zones"], run.denied_zones)
			and is_same(first["protection_sources"], run.player_protection_sources)
			and is_same(secondary, run._runtime_secondary_presentation_frame)
			and is_same(secondary["mines"], run.secondary_runtime.mines)
			and is_same(first["mystery_devices"], run._mystery_device_snapshot_buffer),
		"combat presentation borrows synchronous live collections without duplication"
	)
	_expect(
		secondary.size() == 15
			and is_equal_approx(float(secondary["storm_radius"]), 280.0)
			and not secondary.has("equipped")
			and not secondary.has("seeker_cooldown")
			and not secondary.has("storm_cooldown"),
		"runtime secondary state exposes only renderer-owned bounded presentation fields"
	)
	_expect(
			not is_same(oracle["protection_sources"], run.player_protection_sources)
			and not is_same(oracle["secondary"]["mines"], run.secondary_runtime.mines)
			and not is_same(oracle["mystery_devices"], run._mystery_device_snapshot_buffer),
		"cold combat snapshot remains independently owned for validators and capture"
	)
	var identities_stable := true
	for _sync_index in 128:
		var repeated: Dictionary = run.call(
			"_runtime_combat_presentation_snapshot"
		)
		identities_stable = identities_stable and (
			is_same(first, repeated)
			and is_same(secondary, repeated["secondary"])
			and is_same(first["mystery_devices"], repeated["mystery_devices"])
		)
	_expect(
		identities_stable,
		"128 synchronous combat snapshots reuse top-level and nested bounded buffers"
	)
	run.player_protection_sources[&"emp"] = 0.20
	run.secondary_runtime.orbit_angle = 0.81
	run.secondary_runtime.mines[0]["life"] = 1.75
	var changed: Dictionary = run.call("_runtime_combat_presentation_snapshot")
	_expect(
		is_same(first, changed)
			and float(changed["protection_sources"][&"emp"]) == 0.20
			and float(changed["secondary"]["orbit_angle"]) == 0.81
			and float(changed["secondary"]["mines"][0]["life"]) == 1.75,
		"reused combat presentation reflects current protection, orbit, and mine state"
	)
	var original_dash_timer := float(run.player_dash_timer)
	var original_dash_direction := Vector2(run.player_dash_direction)
	var original_hull_direction := Vector2(run.player_hull_direction)
	run.player_dash_timer = 0.10
	run.player_dash_direction = Vector2.LEFT
	run.player_hull_direction = Vector2.DOWN
	var dash_snapshot: Dictionary = run.call(
		"_runtime_combat_presentation_snapshot"
	)
	_expect(
		bool(dash_snapshot["dash_active"])
		and Vector2(dash_snapshot["hull_direction"]) == Vector2.LEFT
		and Vector2(dash_snapshot["dash_direction"]) == Vector2.LEFT,
		"dash freezes the craft and every hull-attached directional cue to its committed direction"
	)
	run.player_dash_timer = original_dash_timer
	run.player_dash_direction = original_dash_direction
	run.player_hull_direction = original_hull_direction
	run.player_protection_sources.clear()
	run.player_protection_sources.merge(original_protection)
	run.secondary_runtime.mines.clear()
	run.secondary_runtime.mines.append_array(original_mines)
	run.secondary_runtime.orbit_angle = original_orbit_angle


func _presentation_snapshots_match(
	expected: Dictionary,
	actual: Dictionary
) -> bool:
	for key in [
		"zones", "player_position", "hull_direction",
		"aim_direction", "player_speed", "dash_active", "dash_progress",
		"dash_direction", "player_hit", "player_hit_remaining",
		"player_barrier_hit_remaining", "player_invulnerable_remaining",
		"protection_sources", "muzzle_flash",
		"barrier_strength", "reduced_motion", "run_time",
		"secondary_visual_tier",
		"orbiting_blade_level", "cursor_position",
	]:
		if expected.get(key) != actual.get(key):
			return false
	if expected.get("mystery_devices") != actual.get("mystery_devices"):
		return false
	var expected_secondary := Dictionary(expected.get("secondary", {}))
	var actual_secondary := Dictionary(actual.get("secondary", {}))
	for key in ["orbit_angle", "mines", "electric_field_radius"]:
		if expected_secondary.get(key) != actual_secondary.get(key):
			return false
	return true


func _check_runtime_minimap_at_horde_capacity(run) -> void:
	var oracle: Dictionary = run.call("_minimap_snapshot", false)
	var first: Dictionary = run.call("_runtime_minimap_snapshot", false)
	var first_markers: Array = first["markers"]
	var first_visited: Array = first["visited"]
	_expect(
		_minimap_snapshots_match(oracle, first),
		"runtime minimap preserves cold-oracle marker count, order, roles, and values at 320 enemies"
	)
	_expect(
		first_markers.size() >= EnemyStore.MAX_LIVE_HOSTILES
			and first_markers.size() <= run.MINIMAP_MARKER_CAPACITY,
		"runtime minimap publishes all 320 enemies within its fixed marker capacity"
	)
	_expect(
		run._runtime_minimap_marker_pool.size()
			== run.MINIMAP_FRAME_COUNT * run.MINIMAP_MARKER_CAPACITY,
		"runtime minimap owns exactly two fixed-capacity marker pools"
	)
	var threat_feed_contract: Dictionary = run._threat_radar_feed.debug_contract()
	_expect(
		int(threat_feed_contract["frame_count"]) == 2
			and int(threat_feed_contract["sector_count"]) == 12,
		"threat radar owns two fixed twelve-sector sample frames"
	)
	var retained_player := Vector2(first["player"])
	var retained_marker_position := Vector2(first_markers[0]["position"])
	var retained_visited := first_visited.duplicate()
	var original_player := Vector2(run.player_position)
	var original_enemy_position := Vector2(run.enemies[0].pos)
	run.player_position += Vector2(5.0, 0.0)
	run.enemies[0].pos += Vector2(7.0, 0.0)
	var second: Dictionary = run.call("_runtime_minimap_snapshot", false)
	var second_markers: Array = second["markers"]
	_expect(
		not is_same(first, second)
			and not is_same(first_markers, second_markers)
			and not is_same(first_visited, second["visited"])
			and not is_same(first_markers[0], second_markers[0]),
		"alternating minimap frames do not alias retained dictionaries, arrays, or marker records"
	)
	_expect(
		Vector2(first["player"]) == retained_player
			and Vector2(first_markers[0]["position"]) == retained_marker_position
			and first_visited == retained_visited,
		"the next minimap publication does not mutate the immediately retained frame"
	)
	var third: Dictionary = run.call("_runtime_minimap_snapshot", false)
	_expect(
		is_same(first, third)
			and is_same(first_markers, third["markers"])
			and is_same(first_visited, third["visited"]),
		"runtime minimap alternates back to the first preallocated frame"
	)
	run.player_position = original_player
	run.enemies[0].pos = original_enemy_position
	var threat_first: Dictionary = run.call("_runtime_threat_radar_snapshot")
	var threat_second: Dictionary = run.call("_runtime_threat_radar_snapshot")
	_expect(
		is_same(threat_first, threat_second)
			and threat_first.has("generation")
			and threat_first.has("sample_origin")
			and Array(threat_first["sectors"]).size() == 12,
		"threat radar reuses one wrapper around a coherent fixed-sector generation"
	)


func _check_nearby_radar_contacts(run) -> void:
	run.call("_clear_enemies")
	run.call("_clear_ordinary_arrival_cues")
	run.call("_refresh_visible_world_runtime_ranges")
	var visible_world: Rect2 = run.call("_visible_world_rect", 0.0)
	var nearby_offset: float = maxf(
		850.0,
		visible_world.end.x - run.player_position.x + 80.0
	)
	nearby_offset = minf(nearby_offset, run._runtime_threat_scan_distance - 80.0)
	var distant_offset: float = run._runtime_threat_scan_distance + 200.0
	var visible_enemy: EnemyState = run.call("_make_enemy", {
		"id":"radar_visible", "role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(200.0, 0.0), "active":true,
	})
	var nearby_enemy: EnemyState = run.call("_make_enemy", {
		"id":"radar_nearby", "role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(nearby_offset, 0.0), "active":true,
	})
	var distant_enemy: EnemyState = run.call("_make_enemy", {
		"id":"radar_distant", "role":&"ordinary_edge_01",
		"pos":run.player_position + Vector2(distant_offset, 0.0), "active":true,
	})
	for enemy in [visible_enemy, nearby_enemy, distant_enemy]:
		if enemy != null:
			enemy.active = true
			run.call("_append_enemy", enemy)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", run.THREAT_SAMPLE_INTERVAL)
	var nearby_contacts := _active_threat_sectors(run, &"nearby_enemy")
	_expect(
		nearby_contacts.size() == 1
			and (
				Vector2(nearby_contacts[0]["world_position"])
				- run.player_position
			).is_equal_approx(Vector2(nearby_offset, 0.0)),
		"five-hertz radar includes only off-screen targetable enemies inside the runtime band"
	)
	var retained_frame: Dictionary = run._threat_radar_feed.snapshot()
	var retained_position := (
		Vector2(nearby_contacts[0]["world_position"])
		if not nearby_contacts.is_empty()
		else Vector2.ZERO
	)
	if nearby_enemy != null:
		nearby_enemy.pos += Vector2(20.0, 0.0)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", run.THREAT_SAMPLE_INTERVAL)
	var moved_contacts := _active_threat_sectors(run, &"nearby_enemy")
	_expect(
		not nearby_contacts.is_empty()
			and not is_same(retained_frame, run._threat_radar_feed.snapshot())
			and Vector2(nearby_contacts[0]["world_position"]) == retained_position
			and moved_contacts.size() == 1
			and (
				Vector2(moved_contacts[0]["world_position"])
				- run.player_position
			).is_equal_approx(Vector2(nearby_offset + 20.0, 0.0)),
		"radar swaps coherent frames without mutating the immediately retained sample"
	)
	run.call("_clear_enemies")
	run.call("_clear_ordinary_arrival_cues")
	var cue_position: Vector2 = run.player_position + Vector2(2200.0, 220.0)
	run.call("_record_ordinary_arrival_cue", {
		"birth_position":cue_position,
		"visual_duration":0.90,
	})
	var held_player_position := Vector2(run.player_position)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", run.THREAT_SAMPLE_INTERVAL)
	var arrival_contacts := _active_threat_sectors(run, &"nearby_enemy")
	var arrival_offset := (
		Vector2(arrival_contacts[0]["world_position"]) - held_player_position
		if not arrival_contacts.is_empty()
		else Vector2.ZERO
	)
	_expect(
		run.player_position == held_player_position
			and run._ordinary_arrival_cue_count == 1
			and arrival_contacts.size() == 1
			and arrival_offset.length() < run._runtime_threat_scan_distance
			and arrival_offset.normalized().is_equal_approx(
				(cue_position - held_player_position).normalized()
			),
		"a stationary player receives a direction-only nearby arc for a distant timed arrival cue"
	)
	run.call("_advance_ordinary_arrival_cues", 2.01)
	run._threat_sample_timer = 0.0
	run.call("_update_threat_contacts", run.THREAT_SAMPLE_INTERVAL)
	_expect(
		run._ordinary_arrival_cue_count == 0
			and _active_threat_sectors(run, &"nearby_enemy").is_empty(),
		"ordinary arrival radar receipt expires after cue lead plus the bounded post-birth hold"
	)


func _active_threat_sectors(run, kind: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for sector_variant in Array(run._threat_radar_feed.snapshot()["sectors"]):
		var sector := Dictionary(sector_variant)
		if bool(sector.get("active", false)) and StringName(
			sector.get("kind", &"")
		) == kind:
			result.append(sector)
	return result


func _minimap_snapshots_match(expected: Dictionary, actual: Dictionary) -> bool:
	for key in ["cols", "rows", "visited", "player", "player_facing", "world_size"]:
		if expected.get(key) != actual.get(key):
			return false
	var expected_markers: Array = expected.get("markers", [])
	var actual_markers: Array = actual.get("markers", [])
	if expected_markers.size() != actual_markers.size():
		return false
	for index in expected_markers.size():
		var expected_marker := Dictionary(expected_markers[index])
		var actual_marker := Dictionary(actual_markers[index])
		if (
			expected_marker.get("kind") != actual_marker.get("kind")
			or expected_marker.get("position") != actual_marker.get("position")
			or expected_marker.get("discovered") != actual_marker.get("discovered")
		):
			return false
	return true


func _check_hot_path_guards(run) -> void:
	var open_from: Vector2 = run.player_position
	var open_motion := Vector2(1.0, 0.0)
	var open_cover: Array = run.call(
		"_runtime_motion_cover_rects",
		open_from,
		open_from + open_motion,
		12.0
	)
	_expect(open_cover.is_empty(), "open-space motion has no runtime cover candidate")
	_expect(
		bool(run._motion_cover_static_safe)
		and bool(run._motion_cover_static_cover_clear),
		"combined same-cell certificate returns before static blocker scanning"
	)
	var open_result: Vector2 = Rules.move_circle_with_extra(
		open_from,
		open_motion,
		12.0,
		false,
		run.current_stage_id,
		open_cover
	)
	_expect(open_result == open_from + open_motion, "open-space motion takes the safe fast path")
	var open_known_result: Vector2 = Rules.move_circle_with_extra_safe(
		open_from,
		open_motion,
		12.0,
		StringName(run.current_stage_id),
		open_cover,
		bool(run._motion_cover_static_safe)
	)
	_expect(
		open_known_result == open_result,
		"cached safe-cell motion preserves the exact open-space result"
	)
	var open_cover_cached_result: Vector2 = Rules.move_circle_with_extra_safe(
		open_from,
		open_motion,
		12.0,
		StringName(run.current_stage_id),
		[],
		false,
		true
	)
	_expect(
		open_cover_cached_result == open_result,
		"cached empty static-cover broadphase preserves floor/void motion"
	)
	var cross_from: Vector2 = Vector2(run.player_position) + Vector2(1.0, 1.0)
	var cross_to: Vector2 = cross_from + Vector2(80.0, 0.0)
	run.call("_runtime_motion_cover_rects", cross_from, cross_to, 24.0)
	_expect(
		not bool(run._motion_cover_static_safe),
		"cross-cell motion remains on the exact solver"
	)
	run.call(
		"_runtime_motion_cover_rects",
		run.player_position,
		run.player_position + Vector2(8.0, 0.0),
		76.0
	)
	_expect(
		not bool(run._motion_cover_static_safe),
		"radius-over-36 motion remains on the exact solver"
	)
	var outside := Catalog.world_rect(run.current_stage_id).position - Vector2(40.0, 40.0)
	run.call("_runtime_motion_cover_rects", outside, outside + Vector2(4.0, 0.0), 24.0)
	_expect(
		not bool(run._motion_cover_static_safe),
		"out-of-bounds motion remains on the exact solver"
	)
	_expect(
		run._active_tactical_layout.cover_rects.is_empty(),
		"dedicated cover is retired in favor of inner walls"
	)
	if not run._runtime_structural_walls.is_empty():
		var wall := Rect2(run._runtime_structural_walls[0])
		var wall_from := wall.get_center() - Vector2(wall.size.x * 0.5 + 80.0, 0.0)
		var wall_to := wall.get_center() + Vector2(wall.size.x * 0.5 + 80.0, 0.0)
		var wall_cover: Array = run.call(
			"_runtime_motion_cover_rects", wall_from, wall_to, 24.0
		)
		_expect(
			wall in wall_cover and not bool(run._motion_cover_static_safe),
			"structural-wall motion retains exact blocker scanning"
		)
	else:
		_expect(false, "stage fixture exposes a structural wall")
	run.mystery_device_runtime.refresh_publication(
		run.call("_visible_world_rect", 240.0), run.player_position
	)
	var device_rows: Array = run.mystery_device_runtime.snapshot()["devices"]
	var published_devices := device_rows.filter(func(device): return bool(device["published"]))
	var hidden_devices := device_rows.filter(func(device): return not bool(device["published"]))
	_expect(
		device_rows.size() == 6
		and published_devices.size() == 1
		and hidden_devices.size() == 5
		and not bool(run.call(
			"_position_clear_of_stage_objects",
			Vector2(published_devices[0]["position"]),
			24.0
		))
		and bool(run.call(
			"_position_clear_of_stage_objects",
			Vector2(hidden_devices[0]["position"]),
			24.0
		)),
		"one published mystery device participates in collision while five stay dormant"
	)
	run.call("_clear_enemies")
	run.call("_clear_projectiles")
	var piercing_path_start := cover_hit_start(run)
	_expect(
		run.projectile_store.add_player({
			"pos":piercing_path_start,
			"velocity":Vector2.RIGHT * 500.0,
			"radius":run.PRIMARY_PROJECTILE_RADIUS,
			"damage":18.0,
			"structure_damage":18.0,
			"life":1.0,
			"owner":"validation_wall_piercing",
			"wall_piercing":true,
		}),
		"wall-piercing fixture accepts a projectile"
	)
	run.call("_update_projectiles", 0.30)
	_expect(
		run.projectile_store.player_count() == 1,
		"wall-piercing projectile bypasses cover collision while retaining its life"
	)


func _check_effect_store(run) -> void:
	run.call("_clear_effects")
	if not run.run_build.has(&"emp"):
		run.run_build.apply(&"emp")
	run.active_weapon_runtime.reset(run.player_position)
	run.active_weapon_runtime.configure(run.run_build)
	run.call("_start_active_weapon")
	run.call("_clear_effects")
	run.call("_advance_active_weapon", 0.42)
	_expect(
		run.effect_store.count_kind(&"player_emp_release") == 1,
		"acquired EMP emits one release visual"
	)
	run.call("_update_effects", 0.56)
	_expect(
		run.effect_store.count_kind(&"player_emp_release") == 0,
		"acquired EMP release visual retires after its bounded lifetime"
	)
	_expect(
		run.effect_store.validate_capacity()
		and run.effects.size() <= run.effect_store.MAX_LIVE_EFFECTS
		and int(run.effect_store.debug_snapshot()["state_instances_created"])
			== run.effect_store.MAX_LIVE_EFFECTS,
		"run effect boundary preserves exact pool accounting and cap"
	)
	run.call("_clear_effects")
	run.call("_update_effects", 1.0)
	_expect(
		run.effects.is_empty(),
		"effect reset returns every visual state"
	)


func cover_hit_start(run) -> Vector2:
	if run._active_tactical_layout.cover_rects.is_empty():
		return run.player_position
	var cover := Rect2(run._active_tactical_layout.cover_rects[0])
	return cover.get_center() - Vector2(cover.size.x * 0.5 + 120.0, 0.0)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_RUN_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
