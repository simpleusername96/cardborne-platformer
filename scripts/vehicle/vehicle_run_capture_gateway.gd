class_name VehicleRunCaptureGateway
extends RefCounted

## Fixed capture-only adapter over VehicleRun's existing gameplay and UI owners.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackTelegraphs = preload(
	"res://scripts/combat/vehicle_attack_telegraph_builder.gd"
)
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SpecialistRuntime = preload(
	"res://scripts/enemies/vehicle_enemy_specialist_runtime.gd"
)
const ExperienceRuntime = preload(
	"res://scripts/progression/vehicle_experience_runtime.gd"
)
const PerformanceScenario = preload(
	"res://scripts/performance/vehicle_performance_scenario.gd"
)
const PressureFixture = preload(
	"res://scripts/performance/vehicle_pressure_fixture.gd"
)
const CampaignFixtureFacade = preload(
	"res://scripts/vehicle/vehicle_campaign_fixture_facade.gd"
)
const UpgradeOfferPresenter = preload(
	"res://scripts/cards/vehicle_upgrade_offer_presenter.gd"
)
const GuidebookCatalog = preload(
	"res://scripts/progression/vehicle_guidebook_catalog.gd"
)
const StageTelemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const BuildSnapshotBuilder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const StageReportBuilder = preload(
	"res://scripts/combat/vehicle_stage_report_builder.gd"
)
const RunResultBuilder = preload(
	"res://scripts/combat/vehicle_run_result_builder.gd"
)
const VisualEventCaptureFixture = preload(
	"res://scripts/presentation/components/vehicle_visual_event_capture_fixture.gd"
)

var _run: Node
var _baseline: Dictionary
var _runtime_baseline: Dictionary = {}
var _report_fixture: VehicleStageTelemetry
var _restored := false
var _capture_text_scale := 1.0
var _campaign_fixture: RefCounted


func _init(run: Node) -> void:
	_run = run
	_campaign_fixture = CampaignFixtureFacade.new(run)
	var settings := _run.get_node_or_null("/root/SettingsStore")
	_baseline = {
		"window_size":_run.get_window().size,
		"content_scale_size":_run.get_window().content_scale_size,
		"transparent_bg":_run.get_viewport().transparent_bg,
		"reduced_motion":bool(settings.reduced_motion) if settings != null else false,
		"layout_seed_override":_run._layout_seed_override,
		"has_layout_seed_override":_run._has_layout_seed_override,
		"field_id_override":_run._field_id_override,
		"debug_collision_overlay":_run._debug_collision_overlay,
		"stage_index":_run.current_stage_index,
		"stage_id":_run.current_stage_id,
		"mode":_run.mode,
	}


func set_player_fixture(fixture: Dictionary) -> void:
	match StringName(fixture.get("kind", &"")):
		&"cooldowns":
			_run.capture_set_mode(&"paused")
			_run.player_dash_cooldown = _run._dash_cooldown_max() * 0.75
			_run.secondary_runtime.seeker_cooldown = _run.SEEKER_COOLDOWN * 0.5
			_run.active_weapon_runtime.cooldown_remaining = (
				_run.active_weapon_runtime.cooldown_max(
					_run.run_build, 1.5 if _run.persistent_relay_module else 0.0
				)
			)
			var hud_snapshot: Dictionary = _run._build_hud_snapshot(false, false)
			hud_snapshot["conditional_statuses"] = [
				{"id":&"last_stand", "value":"+35%"},
				{"id":&"overflow_barrier", "value":"2.4s"},
				{"id":&"dash_overdrive", "value":"1.8s"},
				{"id":&"braced_fire", "value":"3·1.2s"},
				{"id":&"hit_chain", "value":"×4"},
			]
			_run._ui.update_hud(hud_snapshot)
		&"cooldowns_clear":
			_run.player_dash_cooldown = 0.0
			_run.secondary_runtime.seeker_cooldown = 0.0
			_run.active_weapon_runtime.cooldown_remaining = 0.0
			_run._ui.update_hud(_run._build_hud_snapshot(false, false))


func set_world_fixture(fixture: Dictionary) -> void:
	match StringName(fixture.get("kind", &"")):
		&"capture_environment":
			_apply_capture_environment(fixture)
		&"pressure":
			await _capture_pressure_evidence()
		&"collective_tactic":
			await _capture_collective_tactic_evidence()
		&"movement_policy":
			await _capture_movement_policy_evidence()
		&"build_state":
			await _capture_build_state_evidence()
		&"radar_minimap_roles":
			await _capture_radar_minimap_roles()
		&"field_items":
			await _capture_field_item_evidence()
		&"structural_health_bars":
			await _capture_structural_health_bar_evidence()
		&"level_up":
			await _capture_level_up_evidence()
		&"boss_preview":
			await _capture_boss_preview()
		&"stage_maps":
			await _capture_stage_map_evidence()
		&"visual_events":
			await _capture_visual_event_evidence()
		&"ordinary_projectile":
			await _capture_ordinary_projectile_evidence()
		&"arc_area_telegraphs":
			await _capture_arc_area_telegraph_evidence()
		&"ordinary_fixed_beam_01":
			await _capture_ordinary_fixed_beam_01_evidence()
		&"damage_feedback":
			await _capture_damage_feedback_evidence()
		&"elemental_status_feedback":
			await _capture_elemental_status_evidence()
		&"electric_field_feedback":
			await _capture_electric_field_evidence()
		&"thermal_burst_feedback":
			await _capture_thermal_burst_evidence()
		&"drop_mine_feedback":
			await _capture_drop_mine_evidence()
		&"exact_area_effects":
			await _capture_exact_area_effect_evidence()
		&"collision_overlays":
			await _capture_collision_overlay_evidence()
		&"all_bosses":
			await _capture_all_boss_evidence()


func show_ui_fixture(fixture: Dictionary) -> void:
	match StringName(fixture.get("kind", &"")):
		&"deployment":
			_run._ui.show_deployment(_run.selected_primary)
		&"settings":
			_run._ui.debug_modal_contract("settings")
		&"gameplay_settings":
			_run._ui.debug_gameplay_settings_contract()
		&"guidebook":
			_run._ui.debug_modal_contract("guidebook")
		&"guidebook_boss":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(
					all_known,
					_run._build_snapshot(),
					{"active_stage_index":_run.current_stage_index}
				),
				&"bosses",
				&"boss_stage_1"
			)
		&"guidebook_locked":
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot({}, _run._build_snapshot()),
				&"enemies",
				&"locked_summary_enemies"
			)
		&"guidebook_enemy_stats":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(
					all_known,
					_run._build_snapshot(),
					{"active_stage_index":_run.current_stage_index}
				),
				&"enemies",
				&"enemy_ordinary_pursuer_t1"
			)
		&"guidebook_elite_stats":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(
					all_known,
					_run._build_snapshot(),
					{"active_stage_index":_run.current_stage_index}
				),
				&"enemies",
				&"object_trait_splitter"
			)
		&"guidebook_field_objects":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(all_known, _run._build_snapshot()),
				&"objects",
				&"object_mystery_device"
			)
		&"guidebook_enemy_range":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(all_known, _run._build_snapshot()),
				&"enemies",
				&"enemy_ordinary_pursuer_t1"
			)
		&"ship_status_active":
			var active_build: Dictionary = _run._build_snapshot()
			_run._ui.update_hud({
				"build_snapshot":active_build,
				"guidebook":_run._guidebook_snapshot(active_build),
			})
			_run._ui.debug_active_settings_contract()
		&"first_contact":
			_run._ui.show_gameplay()
			_run.capture_set_mode(&"playing")
			_run._update_encounter(5.1)
			_run._threat_sample_timer = 0.0
			_run._update_threat_contacts(_run.THREAT_SAMPLE_INTERVAL)
			_run._ui.update_hud(_run._build_hud_snapshot(false, false))
		&"pause":
			_run.capture_set_mode(&"paused")
			_run._ui.show_pause()
		&"stage_report":
			_show_stage_report(false)
		&"failure_report":
			_show_stage_report(true)
		&"result":
			_run.capture_set_mode(&"result")
			_run._ui.show_result(_final_result_fixture())


func snapshot(kind: StringName) -> Variant:
	match kind:
		&"viewport":
			return _run.get_viewport()
		&"tree":
			return _run.get_tree()
		&"field_ids":
			return FieldRegistry.FIELD_IDS.duplicate()
		&"stage_count":
			return StageCatalog.STAGE_IDS.size()
		&"visual_event_groups":
			return VisualEventCaptureFixture.GROUPS.duplicate(true)
		&"current_stage_slug":
			return String(_run.current_stage_id).replace("_", "-")
	return null


func refresh_capture_text_scale() -> void:
	_run._ui.debug_set_text_scale(_capture_text_scale)


func set_debug_overlay(kind: StringName, enabled: bool) -> void:
	if kind == &"collision":
		_run._debug_collision_overlay = enabled


func restore_baseline() -> void:
	if _restored or not is_instance_valid(_run):
		return
	_restored = true
	var settings := _run.get_node_or_null("/root/SettingsStore")
	if settings != null:
		settings.reduced_motion = bool(_baseline["reduced_motion"])
	_run.get_viewport().transparent_bg = bool(_baseline["transparent_bg"])
	_run.get_window().content_scale_size = Vector2i(_baseline["content_scale_size"])
	_run.get_window().size = Vector2i(_baseline["window_size"])
	_run._layout_seed_override = int(_baseline["layout_seed_override"])
	_run._has_layout_seed_override = bool(_baseline["has_layout_seed_override"])
	_run._field_id_override = StringName(_baseline["field_id_override"])
	_run._debug_collision_overlay = bool(_baseline["debug_collision_overlay"])
	_run.field_layout = null
	_run._reset_run(false)
	_run.current_stage_index = int(_baseline["stage_index"])
	_run.current_stage_id = StringName(_baseline["stage_id"])
	_run.mode = int(_baseline["mode"])
	if is_instance_valid(_run._camera) and not _runtime_baseline.is_empty():
		_run._camera.zoom = Vector2(_runtime_baseline["camera_zoom"])
		_run._camera.position = Vector2(_runtime_baseline["camera_position"])
		_run._camera.position_smoothing_enabled = bool(
			_runtime_baseline["camera_smoothing"]
		)
	if is_instance_valid(_run._ui):
		_run._ui.debug_set_text_scale(1.0)
		_run._present_deployment()
	_run._release_tree_pause()


func _apply_capture_environment(fixture: Dictionary) -> void:
	if _runtime_baseline.is_empty():
		_runtime_baseline = {
			"camera_zoom":_run._camera.zoom,
			"camera_position":_run._camera.position,
			"camera_smoothing":_run._camera.position_smoothing_enabled,
		}
	_run.get_viewport().transparent_bg = false
	var viewport_size := Vector2i(fixture.get("viewport_size", Vector2i.ZERO))
	if viewport_size.x > 0 and viewport_size.y > 0:
		_run.get_window().content_scale_size = viewport_size
		_run.get_window().size = viewport_size
	_run._camera.position_smoothing_enabled = false
	_capture_text_scale = float(fixture.get("text_scale", 1.0))
	refresh_capture_text_scale()


func _show_stage_report(failed: bool) -> void:
	if _report_fixture == null:
		_report_fixture = StageTelemetry.new()
		_report_fixture.record_outgoing(&"primary", &"kinetic", 418.0)
		_report_fixture.record_outgoing(&"seeker", &"kinetic", 126.0)
		_report_fixture.record_outgoing(&"thermal_burst", &"thermal", 44.0)
		_report_fixture.record_status_application(&"chill")
		_report_fixture.record_incoming(&"projectile", 32.0)
		_report_fixture.record_incoming(&"contact", 18.0)
		_report_fixture.record_defeat(&"ordinary_pursuer_t1")
		_report_fixture.record_defeat(&"ordinary_pursuer_t1")
		_report_fixture.record_defeat(&"ordinary_emitter_t1", &"slow")
	var report_data := {
		"number":1,
		"title_key":_stage_title_key(0),
		"has_next_stage":not failed,
		"run_time_seconds":74.8,
		"hull":0.0 if failed else 88.0,
		"max_hull":120.0,
	}
	_run._ui.show_stage_report(StageReportBuilder.build(
		_report_fixture.stage_snapshot() if failed else _report_fixture.freeze_stage(),
		report_data,
		failed
	))


func _final_result_fixture() -> Dictionary:
	var stage_records: Array = []
	for stage_index in StageCatalog.STAGE_IDS.size():
		var telemetry := StageTelemetry.new()
		telemetry.record_outgoing(&"primary", &"kinetic", 180.0 + stage_index * 30.0)
		telemetry.record_outgoing(&"seeker", &"kinetic", 72.0 + stage_index * 12.0)
		telemetry.record_outgoing(&"thermal_burst", &"thermal", 24.0 + stage_index * 6.0)
		telemetry.record_status_application(&"chill")
		telemetry.record_defeat(&"ordinary_pursuer_t1")
		telemetry.record_defeat(&"ordinary_pursuer_t1")
		telemetry.record_defeat(&"ordinary_emitter_t1", &"slow" if stage_index % 2 == 0 else &"")
		stage_records.append(StageReportBuilder.build(telemetry.freeze_stage(), {
			"number":stage_index + 1,
			"title_key":_stage_title_key(stage_index),
			"has_boss":StageCatalog.has_boss(StageCatalog.STAGE_IDS[stage_index]),
			"has_next_stage":stage_index < StageCatalog.STAGE_IDS.size() - 1,
			"run_time_seconds":64.0 * (stage_index + 1),
			"hull":120.0 - stage_index * 9.0,
			"max_hull":120.0,
		}))
	var fixture_build := RunBuild.new(UpgradeCatalog.new())
	fixture_build.apply(&"pickup_radius")
	fixture_build.apply(&"thermal_burst")
	fixture_build.apply(&"homing_missiles")
	fixture_build.apply(&"homing_missiles")
	return RunResultBuilder.build(stage_records, {
		"active_run_elapsed_seconds":320.0,
		"hull":84.0,
		"max_hull":120.0,
		"health_ratio":0.7,
		"primary_hits":184,
		"dash_uses":24,
		"installations":11,
		"build_snapshot":BuildSnapshotBuilder.build(fixture_build, fixture_build.catalog, [], [], {}),
		"loadout":{
			"primary_title_key":"PRIMARY_PULSE_CANNON",
			"secondary_title_keys":["UPGRADE_HOMING_MISSILES_TITLE"],
			"active_title_key":"ACTIVE_WEAPON_EMP_NAME",
		},
	})


func prepare_stage(stage_index: int, preserve_upgrades: bool = false) -> void:
	if not _campaign_fixture.prepare_stage(stage_index, preserve_upgrades):
		push_error("Capture requested an invalid campaign stage: %d" % stage_index)


func _capture_pressure_evidence() -> void:
	prepare_stage(StageCatalog.STAGE_IDS.size() - 1)
	_run._clear_enemies()
	var scenario := PerformanceScenario.new()
	var production_roles: Array[StringName] = scenario._production_pressure_roles(
		PressureFixture.CAPACITY_ORDINARY_COUNT
	)
	# The pressure scenario is canonical gameplay evidence, not a function of
	# the UI matrix viewport. A fixed world window keeps its sectors feasible.
	var pressure_visible_world := Rect2(
		_run.player_position - Vector2(640.0, 360.0),
		Vector2(1280.0, 720.0)
	)
	var fixture := PressureFixture.build(
		&"peak",
		_run.current_stage_id,
		_run.player_position,
		pressure_visible_world,
		_run._active_tactical_layout.ordinary_spawn_anchors,
		production_roles
	)
	for descriptor_variant in Array(fixture["descriptors"]):
		var descriptor := Dictionary(descriptor_variant)
		var enemy: VehicleEnemyState = _run._make_enemy(descriptor)
		if enemy == null:
			break
		enemy.active = true
		enemy.counts_active_cap = bool(descriptor["counts_active_cap"])
		var enemy_index: int = _run.enemies.size()
		enemy.health_visible_timer = 99.0 if enemy_index < 12 else 0.0
		enemy.committed_dir = (_run.player_position - enemy.pos).normalized()
		if enemy_index < 3:
			enemy.phase = "startup"
			enemy.committed_target = _run.player_position
			AttackTelegraphs.refresh_ordinary(
				enemy,
				_run._runtime_attack_path_callable,
				_run._runtime_charge_path_callable
			)
		_run._append_enemy(enemy)
	_run.experience_runtime.clear_shards()
	for index in ExperienceRuntime.MAX_SHARDS:
		var angle := TAU * float(index % 24) / 24.0
		var radius := 145.0 + float(index % 5) * 58.0
		var shard_position: Vector2 = (
			_run.player_position + Vector2.RIGHT.rotated(angle) * radius
		)
		if index >= 72:
			shard_position = Vector2(580.0 + float(index % 20) * 34.0, 520.0 + float((index - 72) / 20) * 36.0)
		_run.experience_runtime.spawn_shard(shard_position, 1 + int(index % 11 == 0) * 3)
	_run._update_threat_contacts(0.2)
	var qualification := PressureFixture.qualification(
		Array(fixture["descriptors"]), _run.player_position, pressure_visible_world
	)
	print(JSON.stringify({
		"capture":"03-peak-horde.png",
		"fixture_fingerprint":fixture["fingerprint"],
		"qualification":qualification,
	}))
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03-peak-horde.png")


func _capture_collective_tactic_evidence() -> void:
	prepare_stage(2)
	_run._clear_enemies()
	var direction := Vector2.LEFT
	var formation_targets: Array[Vector2] = []
	for index in 6:
		var centered := float(index) - 2.5
		var target: Vector2 = (
			_run.player_position
			+ Vector2(420.0 - centered * 54.0, 0.0)
		)
		formation_targets.append(target)
		var position: Vector2 = _run.player_position + Vector2(
			290.0 + float(index % 3) * 155.0,
			-170.0 + float(index / 3) * 340.0 + float(index % 2) * 46.0
		)
		var enemy: VehicleEnemyState = _run._make_enemy({
			"id":"capture_tactic_%02d" % index,
			"role":&"ordinary_charger_t1" if index == 0 else &"ordinary_pursuer_t1",
			"pos":position,
			"active":true,
			"squad_id":"capture_tactic",
			"group_id":"capture_tactic",
			"squad_leader":index == 0,
			"formation_slot":index,
			"formation_size":6,
			"collective_tactic_id":&"shielded_column",
			"collective_beat_kind":&"combine",
		})
		if enemy == null:
			break
		enemy.collective_phase = &"dormant"
		enemy.collective_mode = &"shield"
		enemy.collective_direction = direction
		enemy.collective_target = target
		enemy.health_visible_timer = 99.0 if index == 0 else 0.0
		_run._append_enemy(enemy)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03a-collective-dormant.png")
	for enemy_variant in _run.enemies:
		var enemy: VehicleEnemyState = enemy_variant
		if enemy.squad_id != "capture_tactic":
			continue
		enemy.collective_phase = &"gather"
		var gather_target := Vector2(formation_targets[enemy.formation_slot])
		enemy.pos = enemy.pos.lerp(gather_target, 0.55)
		_run._update_collective_enemy(enemy, 0.0)
		_run._apply_enemy_shield(enemy, {})
	await _settle_capture()
	_save_capture("03aa-collective-gather.png")
	for enemy_variant in _run.enemies:
		var enemy: VehicleEnemyState = enemy_variant
		if enemy.squad_id != "capture_tactic":
			continue
		enemy.collective_phase = &"lock"
		enemy.pos = formation_targets[enemy.formation_slot]
		_run._update_collective_enemy(enemy, 0.0)
		_run._apply_enemy_shield(enemy, {})
	await _settle_capture()
	_save_capture("03b-collective-lock.png")
	for enemy_variant in _run.enemies:
		var enemy: VehicleEnemyState = enemy_variant
		if enemy.squad_id != "capture_tactic":
			continue
		enemy.collective_phase = &"break"
		enemy.vulnerable = 1.0
		_run._apply_enemy_shield(enemy, {})
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03c-collective-break.png")
	print(JSON.stringify({
		"capture":"collective_tactic_transition",
		"states":["dormant", "gather", "lock", "break"],
		"dormant_shield_source":"none",
		"gather_shield_source":"none",
		"lock_shield_source":"collective_tactic",
	}))


func _capture_movement_policy_evidence() -> void:
	## Exercise the real scheduler, pursuit field, collision recovery, and retained
	## actor renderer while one pursuit and one ranged role follow a moving player.
	prepare_stage(0, true)
	# Beat zero intentionally permits one first-contact enemy. This fixture needs
	# the normal encounter cap so both movement families remain active together.
	_run.encounter_runtime.current_beat = 1
	_run._clear_enemies()
	_run._clear_projectiles()
	var fixture := _movement_capture_fixture()
	if fixture.is_empty():
		push_error("movement capture fixture could not find one clear authored cover")
		return
	var player_start := Vector2(fixture["player_start"])
	var player_turn := Vector2(fixture["player_turn"])
	var player_end := Vector2(fixture["player_end"])
	_run.player_position = player_start
	_run.player_invulnerable = 99.0
	var ordinary_edge_01: VehicleEnemyState = _run._make_enemy({
		"id":"capture_movement_ordinary_edge_01",
		"role":&"ordinary_pursuer_t1",
		"pos":Vector2(fixture["ordinary_edge_01_start"]),
		"active":true,
	})
	var ordinary_lane_01: VehicleEnemyState = _run._make_enemy({
		"id":"capture_movement_ordinary_lane_01",
		"role":&"ordinary_emitter_t1",
		"pos":Vector2(fixture["ordinary_lane_01_start"]),
		"active":true,
	})
	if ordinary_edge_01 == null or ordinary_lane_01 == null:
		push_error("movement capture fixture could not acquire both enemies")
		return
	for enemy in [ordinary_edge_01, ordinary_lane_01]:
		enemy.attack_cooldown = 99.0
		enemy.decision_elapsed = 0.10
		enemy.motion_elapsed = 1.0 / 30.0
	ordinary_edge_01.strafe_sign = -1.0
	ordinary_lane_01.strafe_sign = 1.0
	var ordinary_edge_01_added: bool = _run._append_enemy(ordinary_edge_01)
	var ordinary_lane_01_added: bool = _run._append_enemy(ordinary_lane_01)
	if not ordinary_edge_01_added or not ordinary_lane_01_added:
		push_error("movement capture fixture could not register both enemies")
		return
	var metrics := {
		"initial_ordinary_edge_01_distance":ordinary_edge_01.pos.distance_to(player_start),
		"ordinary_edge_01_travel":0.0,
		"ordinary_lane_01_travel":0.0,
		"ordinary_lane_01_max_desired_speed":0.0,
		"ordinary_lane_01_max_velocity":0.0,
		"ordinary_lane_01_min_distance":ordinary_lane_01.pos.distance_to(player_start),
		"ordinary_lane_01_max_distance":ordinary_lane_01.pos.distance_to(player_start),
		"ordinary_edge_01_intercept_samples":0,
		"ordinary_lane_01_runtime_slot":ordinary_lane_01.runtime_slot,
		"ordinary_lane_01_decision_bucket":ordinary_lane_01.decision_bucket,
	}
	_run.player_aim_direction = (ordinary_lane_01.pos - _run.player_position).normalized()
	_run.set_physics_process(false)
	_focus_movement_capture(ordinary_lane_01)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03d-movement-cover-approach.png")
	_advance_movement_capture_segment(
		player_start, player_turn, 1.25, ordinary_edge_01, ordinary_lane_01, metrics
	)
	_focus_movement_capture(ordinary_lane_01)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03e-movement-cover-turn.png")
	_advance_movement_capture_segment(
		player_turn, player_end, 1.25, ordinary_edge_01, ordinary_lane_01, metrics
	)
	_focus_movement_capture(ordinary_lane_01)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03f-movement-cover-standoff.png")
	_run.set_physics_process(true)
	metrics["final_ordinary_edge_01_distance"] = ordinary_edge_01.pos.distance_to(player_end)
	metrics["final_ordinary_lane_01_distance"] = ordinary_lane_01.pos.distance_to(player_end)
	metrics["final_ordinary_lane_01_active"] = ordinary_lane_01.active
	metrics["final_ordinary_lane_01_alive"] = ordinary_lane_01.alive
	metrics["final_ordinary_lane_01_phase"] = String(ordinary_lane_01.phase)
	var passed := (
		float(metrics["ordinary_edge_01_travel"]) >= 120.0
		and float(metrics["ordinary_lane_01_travel"]) >= 60.0
		and float(metrics["final_ordinary_edge_01_distance"])
			< float(metrics["initial_ordinary_edge_01_distance"]) - 80.0
		and float(metrics["ordinary_lane_01_min_distance"]) >= 250.0
		and float(metrics["ordinary_lane_01_max_distance"]) <= 650.0
	)
	metrics["passed"] = passed
	print(JSON.stringify({"capture":"movement_policy", "metrics":metrics}))
	if not passed:
		_run._capture_driver.failed = true
		push_error("movement capture fixture violated pursuit/standoff bounds")


func _movement_capture_fixture() -> Dictionary:
	var geometry = _run._active_tactical_layout.geometry_snapshot
	for cover in _run._runtime_cover_rects():
		var rectangle := Rect2(cover)
		var center := rectangle.get_center()
		var major := Vector2.DOWN if rectangle.size.y >= rectangle.size.x else Vector2.RIGHT
		var half_length := maxf(rectangle.size.x, rectangle.size.y) * 0.5
		var tangent := major.rotated(PI * 0.5)
		for endpoint_sign in [-1.0, 1.0]:
			var outward: Vector2 = major * float(endpoint_sign)
			var endpoint: Vector2 = center + outward * half_length
			var player_start: Vector2 = endpoint + outward * 120.0 - tangent * 220.0
			var player_turn: Vector2 = endpoint + outward * 220.0
			var player_end: Vector2 = endpoint + outward * 120.0 + tangent * 220.0
			var ordinary_lane_01_start: Vector2 = endpoint + outward * 620.0
			var points := [player_start, player_turn, player_end, ordinary_lane_01_start]
			var clear := true
			for point in points:
				if not geometry.is_spawnable_disc(Vector2(point), 48.0):
					clear = false
					break
			if not clear:
				continue
			return {
				"player_start":player_start,
				"player_turn":player_turn,
				"player_end":player_end,
				"ordinary_edge_01_start":player_end,
				"ordinary_lane_01_start":ordinary_lane_01_start,
			}
	return {}


func _focus_movement_capture(ordinary_lane_01: VehicleEnemyState) -> void:
	_run._camera.position = (_run.player_position + ordinary_lane_01.pos) * 0.5
	_run._camera.zoom = Vector2.ONE * 0.75


func _advance_movement_capture_segment(
	from: Vector2,
	to: Vector2,
	duration: float,
	ordinary_edge_01: VehicleEnemyState,
	ordinary_lane_01: VehicleEnemyState,
	metrics: Dictionary
) -> void:
	const DELTA := 1.0 / 60.0
	var steps := maxi(1, roundi(duration / DELTA))
	_run.player_velocity = (to - from) / maxf(duration, DELTA)
	_run.capture_set_mode(&"playing")
	for step in steps:
		var previous_ordinary_edge_01 := ordinary_edge_01.pos
		var previous_ordinary_lane_01 := ordinary_lane_01.pos
		_run.player_position = from.lerp(to, float(step + 1) / float(steps))
		_run.player_aim_direction = (
			ordinary_lane_01.pos - _run.player_position
		).normalized()
		_run.pursuit_field.update(DELTA, _run.player_position)
		_run._simulation_lod_bucket = 1 - _run._simulation_lod_bucket
		_run._far_enemy_simulation_bucket = (
			(_run._far_enemy_simulation_bucket + 1)
			% _run.FAR_ENEMY_SIMULATION_BUCKET_COUNT
		)
		_run._update_enemies(DELTA, _run.player_position)
		metrics["ordinary_edge_01_travel"] = (
			float(metrics["ordinary_edge_01_travel"])
			+ previous_ordinary_edge_01.distance_to(ordinary_edge_01.pos)
		)
		metrics["ordinary_lane_01_travel"] = (
			float(metrics["ordinary_lane_01_travel"])
			+ previous_ordinary_lane_01.distance_to(ordinary_lane_01.pos)
		)
		metrics["ordinary_lane_01_max_desired_speed"] = maxf(
			float(metrics["ordinary_lane_01_max_desired_speed"]),
			ordinary_lane_01.desired_velocity.length()
		)
		metrics["ordinary_lane_01_max_velocity"] = maxf(
			float(metrics["ordinary_lane_01_max_velocity"]), ordinary_lane_01.velocity.length()
		)
		var direct_ordinary_edge_01_direction: Vector2 = (
			_run.player_position - ordinary_edge_01.pos
		).normalized()
		if (
			not ordinary_edge_01.desired_velocity.is_zero_approx()
			and ordinary_edge_01.desired_velocity.normalized().dot(direct_ordinary_edge_01_direction)
				< 0.995
			and ordinary_edge_01.desired_velocity.dot(_run.player_velocity) > 0.0
		):
			metrics["ordinary_edge_01_intercept_samples"] = (
				int(metrics["ordinary_edge_01_intercept_samples"]) + 1
			)
		var ordinary_lane_01_distance := ordinary_lane_01.pos.distance_to(_run.player_position)
		metrics["ordinary_lane_01_min_distance"] = minf(
			float(metrics["ordinary_lane_01_min_distance"]), ordinary_lane_01_distance
		)
		metrics["ordinary_lane_01_max_distance"] = maxf(
			float(metrics["ordinary_lane_01_max_distance"]), ordinary_lane_01_distance
		)
	_run.player_velocity = Vector2.ZERO


func _capture_build_state_evidence() -> void:
	prepare_stage(3)
	_run.run_build.apply(&"emp")
	_run._clear_enemies()
	for index in 4:
		var angle := -0.75 + float(index) * 0.5
		var position: Vector2 = (
			_run.player_position
			+ Vector2.RIGHT.rotated(angle) * (260.0 + float(index) * 35.0)
		)
		var role: StringName = &"ordinary_gap_01" if index == 0 else &"ordinary_edge_01"
		var enemy: VehicleEnemyState = _run._make_enemy({
			"id":"capture_build_state_%d" % index,
			"role":role,
			"pos":position,
			"active":true,
		})
		if enemy == null:
			break
		enemy.active = true
		enemy.health_visible_timer = 99.0
		_run._append_enemy(enemy)
	_run._aim_target_id = "capture_build_state_0"
	var threat_contacts: Array[Dictionary] = [
		{
			"offset":Vector2(-760.0, -180.0),
			"kind":&"incoming_attack",
			"readiness":0.35,
		},
		{
			"offset":Vector2(820.0, 120.0),
			"kind":&"boss_arrival",
			"readiness":1.0,
		},
	]
	_publish_threat_fixture(threat_contacts)
	_run.experience_runtime.run_level = 12
	_run.experience_runtime.experience = 37
	var hud_snapshot: Dictionary = _run._build_hud_snapshot(false, false)
	hud_snapshot["threat_radar"] = _run._runtime_threat_radar_snapshot()
	_run._ui.update_hud(hud_snapshot)
	await _settle_capture()
	_save_capture("04-stage-4-xp-hud.png")
	_run.experience_runtime.experience += 7
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	await _settle_capture()
	_save_capture("04b-stage-4-xp-collected.png")
	_run.experience_runtime.complete_progression()
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	_run._ui.notify_immediate(
		tr("NOTIFY_ALL_UPGRADES_COMPLETE"),
		2.4,
		Art.SYSTEM,
		&"all_upgrades_complete"
	)
	await _settle_capture()
	_save_capture("04c-progression-max.png")
	prepare_stage(3)
	for upgrade_id in [&"emp", &"thermal_burst", &"chassis_speed", &"homing_missiles"]:
		_run.run_build.apply(upgrade_id)
	_run.run_build.apply(&"thermal_burst")
	var build_snapshot: Dictionary = _run._build_snapshot()
	_run._ui.update_hud({"build_snapshot":build_snapshot})
	_run._ui.debug_active_settings_contract()
	await _settle_capture()
	_save_capture("04d-ship-status-acquired-build.png")


func _capture_radar_minimap_roles() -> void:
	prepare_stage(2)
	_run._clear_enemies()
	var world_size: Vector2 = Rules.world_rect(_run.current_stage_id).size
	var minimap: Dictionary = _run._minimap_snapshot(true)
	minimap["visited"] = []
	for row in _run.MINIMAP_ROWS:
		for column in _run.MINIMAP_COLS:
			minimap["visited"].append(Vector2i(column, row))
	minimap["player"] = world_size * Vector2(0.50, 0.56)
	minimap["player_facing"] = Vector2.RIGHT
	minimap["markers"] = [
		{"kind":&"field_pickup", "position":world_size * Vector2(0.12, 0.24), "discovered":true},
		{"kind":&"mystery_device", "position":world_size * Vector2(0.42, 0.24), "discovered":true},
		{"kind":&"mobile_enemy", "position":world_size * Vector2(0.61, 0.25), "discovered":true},
		{"kind":&"priority_enemy", "position":world_size * Vector2(0.74, 0.25), "discovered":true},
		{"kind":&"boss", "position":world_size * Vector2(0.88, 0.25), "discovered":true},
	]
	var contacts: Array[Dictionary] = [
		{"offset":Vector2(-940.0, -220.0), "kind":&"nearby_enemy", "readiness":0.0},
		{"offset":Vector2(-890.0, -175.0), "kind":&"nearby_enemy", "readiness":0.0},
		{"offset":Vector2(-820.0, -135.0), "kind":&"nearby_enemy", "readiness":0.0},
		{"offset":Vector2(900.0, -150.0), "kind":&"incoming_attack", "readiness":0.72},
		{"offset":Vector2(240.0, 980.0), "kind":&"boss_arrival", "readiness":1.0},
	]
	# Settle the normal world publication first so the deterministic evidence
	# snapshot remains the last HUD write before the forced capture draw.
	await _settle_capture()
	var sampled_player_position: Vector2 = _run.player_position
	_publish_threat_fixture(contacts, sampled_player_position)
	_run._ui.update_hud({
		"minimap":minimap,
		"threat_radar":_run._runtime_threat_radar_snapshot(),
	})
	await _run.get_tree().process_frame
	_save_capture("04e-radar-minimap-roles.png")
	var dash_distances := [0.0, 122.0, 244.0]
	var dash_files := [
		"04f-radar-dash-begin.png",
		"04g-radar-dash-mid.png",
		"04h-radar-dash-end.png",
	]
	for index in dash_distances.size():
		_run.player_position = (
			sampled_player_position + Vector2.RIGHT * float(dash_distances[index])
		)
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_publish_threat_fixture(contacts, sampled_player_position)
		_run._ui.update_threat_anchor(
			_run.player_position,
			_run.get_canvas_transform() * _run.player_position,
			true
		)
		_run._ui.update_hud({
			"threat_radar":_run._runtime_threat_radar_snapshot(),
		})
		await _run.get_tree().process_frame
		_save_capture(String(dash_files[index]))
	_run.player_position = sampled_player_position + Vector2.RIGHT * 122.0
	_refresh_combat_capture()
	await _run.get_tree().process_frame
	_publish_threat_fixture(contacts, sampled_player_position)
	_run._ui.update_threat_anchor(
		_run.player_position,
		_run.get_canvas_transform() * _run.player_position,
		true
	)
	_run._ui.update_hud({
		"reduced_motion":true,
		"threat_radar":_run._runtime_threat_radar_snapshot(),
	})
	await _run.get_tree().process_frame
	_save_capture("04i-radar-dash-mid-reduced.png")


func _publish_threat_fixture(
	contacts: Array[Dictionary],
	sample_origin: Vector2 = Vector2.INF
) -> void:
	var origin: Vector2 = (
		_run.player_position if sample_origin == Vector2.INF else sample_origin
	)
	_run._threat_sample_timer = 999.0
	_run._threat_radar_feed.begin_sample(origin)
	for contact in contacts:
		_run._threat_radar_feed.append_offset(
			Vector2(contact.get("offset", Vector2.ZERO)),
			StringName(contact.get("kind", &"nearby_enemy")),
			float(contact.get("readiness", 0.0))
		)
	_run._threat_radar_feed.commit_sample()
	_run._ui.update_threat_anchor(
		_run.player_position,
		_run.get_canvas_transform() * _run.player_position,
		true
	)


func _capture_field_item_evidence() -> void:
	prepare_stage(0)
	_run._clear_enemies()
	var facility_positions := [
		_run.player_position + Vector2(-310.0, -120.0),
		_run.player_position + Vector2(0.0, 210.0),
		_run.player_position + Vector2(330.0, -80.0),
	]
	_run.mystery_device_runtime.configure([
		{"id":&"capture_facility_repair", "pos":facility_positions[0]},
		{"id":&"capture_facility_cryo", "pos":facility_positions[1]},
		{"id":&"capture_facility_lava", "pos":facility_positions[2]},
	], 1701, _run.current_stage_id)
	var facility_outcomes := [&"repair", &"cryo", &"lava"]
	for index in _run.mystery_device_runtime.devices.size():
		_run.mystery_device_runtime.devices[index]["outcome"] = facility_outcomes[index]
		if index > 0:
			_run.mystery_device_runtime.devices[index]["state"] = &"active"
			_run.mystery_device_runtime.devices[index]["health"] = 0.0
			_run.mystery_device_runtime.devices[index]["active_remaining"] = (
				_run.mystery_device_runtime.ACTIVE_DURATION_SECONDS
				* (0.67 if index == 1 else 0.33)
			)
	_run.pickups.clear()
	_run.pickups.append({"id":"capture_recall", "kind":&"experience_recall", "pos":_run.player_position + Vector2(-150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":0.0})
	_run.experience_runtime.clear_shards()
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(245.0, -90.0), 1)
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(300.0, 35.0), 4)
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(245.0, 150.0), 18)
	await _settle_capture()
	_save_capture("05-two-field-items.png")


func _capture_structural_health_bar_evidence() -> void:
	prepare_stage(2)
	_run._clear_enemies()
	_run.pickups.clear()
	var mobile: VehicleEnemyState = _run._make_enemy({
		"id":"capture_mobile_without_health_bar",
		"role":&"ordinary_pursuer_t1",
		"pos":_run.player_position + Vector2(-280.0, 90.0),
		"active":true,
	})
	if mobile != null:
		mobile.health = mobile.max_health * 0.5
		mobile.health_visible_timer = 99.0
		_run._append_enemy(mobile)
	var repairer: VehicleEnemyState = _run._make_enemy({
		"id":"capture_repair_link",
		"role":&"ordinary_defender_t1",
		"pos":_run.player_position + Vector2(-440.0, 90.0),
		"active":true,
	})
	if repairer != null and mobile != null:
		repairer.repair_target_id = mobile.id
		_run._append_enemy(repairer)
	var installation: VehicleEnemyState = _run._make_enemy({
		"id":"capture_structural_health_bar",
		"role":&"boss_pattern_fixed_beam_01",
		"pos":_run.player_position + Vector2(290.0, -70.0),
		"active":true,
	})
	if installation != null:
		installation.health = installation.max_health * 0.5
		_run._append_enemy(installation)
	var boss: VehicleEnemyState = _run._make_enemy({
		"id":"capture_boss_health_bar",
		"role":&"boss_actor",
		"pos":_run.player_position + Vector2(-300.0, -245.0),
		"active":true,
		"boss_variant":&"boss_stage_03",
		"boss_shield_state":&"shield_down",
	})
	if boss != null:
		boss.health = boss.max_health * 0.5
		_run._append_enemy(boss)
	_run.capture_set_mode(&"paused")
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	await _settle_capture()
	_save_capture("05c-structural-health-bars.png")


func _capture_level_up_evidence() -> void:
	prepare_stage(0)
	var first_acquisition := _upgrade_offer_fixture([
		[&"emp", 0],
		[&"homing_missiles", 0],
		[&"split_muzzle", 0],
	])
	_run._ui.show_upgrade(first_acquisition, _run._build_snapshot())
	await _settle_capture()
	_save_capture("06-first-weapon-acquisition.png")
	_run._ui.debug_select_upgrade(0)
	await _settle_capture()
	_save_capture("06b-first-weapon-selected.png")
	_run.run_build.apply(&"emp")
	var enhancement := _upgrade_offer_fixture([
		[&"emp", 1],
		[&"homing_missiles", 0],
		[&"drop_mines", 0],
	])
	_run._ui.show_upgrade(enhancement, _run._build_snapshot())
	_run._ui.debug_select_upgrade(0)
	await _settle_capture()
	_save_capture("06c-weapon-enhancement.png")
	_run._ui.show_upgrade(enhancement.slice(0, 2), _run._build_snapshot())
	await _settle_capture()
	_save_capture("06d-two-card-tail.png")
	for upgrade_id in [&"pickup_radius", &"homing_missiles"]:
		_run.run_build.apply(upgrade_id)
	_run.run_build.apply(&"homing_missiles")
	_run._ui.show_upgrade(enhancement, _run._build_snapshot())
	await _settle_capture()
	_run._ui.debug_open_first_build_preview()
	await _settle_capture()
	_save_capture("06e-partial-build-popover.png")


func _upgrade_offer_fixture(records: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for upgrade_record in records:
		var upgrade_id := StringName(upgrade_record[0])
		var definition: VehicleUpgradeDefinition = (
			_run.upgrade_catalog.get_definition(upgrade_id)
		)
		if definition != null:
			result.append(
				UpgradeOfferPresenter.snapshot(
					definition,
					int(upgrade_record[1])
				)
			)
	return result


func _capture_boss_preview() -> void:
	var boss := prepare_boss(0)
	if boss == null:
		return
	_run._boss_select_pattern(boss)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("07-stage-boss-startup.png")


func _capture_stage_map_evidence() -> void:
	var original_override: StringName = _run._field_id_override
	for field_id in FieldRegistry.FIELD_IDS:
		_run._field_id_override = field_id
		_run.field_layout = null
		_run._reset_run(false, false, true)
		_run.current_stage_index = 0
		_run.current_stage_id = StageCatalog.STAGE_IDS[0]
		if is_instance_valid(_run._backdrop):
			_run._backdrop.configure(_run.current_stage_id, _run._active_tactical_layout)
		_run.capture_set_mode(&"paused")
		var bounds := Rules.world_rect(_run.current_stage_id)
		_run.player_position = bounds.get_center()
		_fit_camera_to_stage(bounds)
		await _settle_capture()
		_save_capture(
			"10-field-%s.png"
			% String(field_id).trim_prefix("field_").replace("_", "-")
		)
	_run._camera.zoom = Rules.GAMEPLAY_CAMERA_ZOOM
	_run._field_id_override = original_override
	_run.field_layout = null
	_run._reset_run(false, false, true)


func _capture_damage_feedback_evidence() -> void:
	var settings: Node = _run.get_node_or_null("/root/SettingsStore")
	var original_reduced_motion := bool(settings.reduced_motion) if settings != null else false
	for reduced_motion in [false, true]:
		prepare_stage(0, true)
		_run._clear_enemies()
		if settings != null:
			settings.reduced_motion = reduced_motion
		_run.player_health = _run._player_max_health()
		_run.player_invulnerable = 0.0
		_run.player_hit_flash = 0.0
		_run.player_barrier_strength = 0.0
		_run.player_barrier_timer = 0.0
		_run.capture_set_mode(&"playing")
		_run._damage_player(34.0, "capture hull hit", false, false)
		if reduced_motion:
			_run.player_hit_flash = 0.0
			_run.player_invulnerable = 0.72
		_run.capture_set_mode(&"paused")
		await _settle_capture()
		_save_capture(
			"08-player-hit-reduced-motion.png"
			if reduced_motion
			else "08-player-hit-standard.png"
		)

	prepare_stage(0, true)
	_run._clear_enemies()
	if settings != null:
		settings.reduced_motion = false
	_run.player_health = _run._player_max_health()
	_run.player_invulnerable = 0.0
	_run.player_hit_flash = 0.0
	_run.player_barrier_strength = 100.0
	_run.player_barrier_timer = 1.0
	_run.capture_set_mode(&"playing")
	_run._damage_player(34.0, "capture barrier hit", true, false)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("08-player-barrier-only.png")
	if settings != null:
		settings.reduced_motion = original_reduced_motion


func _capture_elemental_status_evidence() -> void:
	prepare_stage(1)
	_run._clear_enemies()
	_run._clear_projectiles()
	var settings: Node = _run.get_node_or_null("/root/SettingsStore")
	var original_reduced_motion := bool(settings.reduced_motion) if settings != null else false
	if settings != null:
		settings.reduced_motion = false
	var toxin_build := RunBuild.new(_run.upgrade_catalog)
	var cryo_build := RunBuild.new(_run.upgrade_catalog)
	toxin_build.apply(&"bio_toxin")
	cryo_build.apply(&"cryo_slow")
	var toxin_profile := PrimaryPayload.from_build(toxin_build)
	var cryo_profile := PrimaryPayload.from_build(cryo_build)
	var status_enemies: Array[EnemyState] = []
	for row in 2:
		for stack_index in 3:
			var enemy: EnemyState = _run._make_enemy({
				"id":"capture_status_%d_%d" % [row, stack_index],
				"role":&"ordinary_pursuer_t1",
				"pos":_run.player_position + Vector2(
					165.0 + float(stack_index) * 105.0,
					-105.0 if row == 0 else 105.0
				),
				"active":true,
			})
			if enemy == null:
				continue
			for _stack in stack_index + 1:
				_run._damage_enemy(
					enemy,
					1.0,
					"validation",
					&"kinetic",
					false
				)
				StatusRuntime.apply(
					enemy,
					toxin_profile if row == 0 else cryo_profile
				)
			enemy.health_visible_timer = 0.0
			_run._append_enemy(enemy)
			status_enemies.append(enemy)
	_run._spawn_player_projectile(
		_run.player_position + Vector2(75.0, -105.0),
		Vector2.RIGHT, 1.0, 360.0, 0, 6.0, 1.0, 420.0, toxin_profile
	)
	_run._spawn_player_projectile(
		_run.player_position + Vector2(75.0, 105.0),
		Vector2.RIGHT, 1.0, 360.0, 0, 6.0, 1.0, 420.0, cryo_profile
	)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09d-element-status-hit-flash.png")
	for enemy in status_enemies:
		enemy.flash = 0.0
		StatusRuntime.tick(enemy, 0.11)
	await _settle_capture()
	_save_capture("09b-element-status-application.png")
	for enemy in status_enemies:
		var status_damage := StatusRuntime.tick(enemy, 0.16)
		if float(status_damage["poison"]) > 0.0:
			_run._damage_enemy(
				enemy,
				float(status_damage["poison"]),
				"status",
				&"toxin",
				true,
				false,
				false
			)
	await _settle_capture()
	_save_capture("09c-element-status-persistent.png")
	for enemy in status_enemies:
		StatusRuntime.apply(
			enemy,
			toxin_profile if enemy.toxin_stack_ratio > 0.0 else cryo_profile
		)
	if settings != null:
		settings.reduced_motion = true
	await _settle_capture()
	_save_capture("09e-element-status-reduced-motion.png")
	for enemy in status_enemies:
		enemy.statuses.clear()
		enemy.toxin_stack_ratio = 0.0
		enemy.cryo_stack_ratio = 0.0
		enemy.toxin_application_pulse = 0.0
		enemy.cryo_application_pulse = 0.0
	await _settle_capture()
	_save_capture("09f-element-status-expired.png")
	if settings != null:
		settings.reduced_motion = original_reduced_motion


func _capture_electric_field_evidence() -> void:
	prepare_stage(0)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run.run_build.reset()
	_run.player_barrier_strength = 100.0
	_run.player_barrier_timer = 99.0
	for index in 2:
		var enemy: EnemyState = _run._make_enemy({
			"id":"capture_field_target_%d" % index,
			"role":&"ordinary_pursuer_t1",
			"pos":_run.player_position + Vector2(
				130.0 if index == 0 else -145.0,
				0.0
			),
			"active":true,
		})
		if enemy == null:
			continue
		enemy.shielded = index == 0
		enemy.health_visible_timer = 0.0
		_run._append_enemy(enemy)
	_run.capture_set_mode(&"paused")
	var level_suffixes := ["g", "h", "i"]
	for level_index in 3:
		_run.run_build.apply(&"electric_field")
		await _settle_capture()
		_save_capture(
			"09%s-electric-field-level-%d.png"
			% [level_suffixes[level_index], level_index + 1]
		)


func _capture_thermal_burst_evidence() -> void:
	var file_prefixes := ["09j", "09k", "09l"]
	for level_index in 3:
		prepare_stage(1)
		_run._clear_enemies()
		_run._clear_projectiles()
		_run._clear_effects()
		_run.run_build.reset()
		for _level in level_index + 1:
			_run.run_build.apply(&"thermal_burst")
		var profile := PrimaryPayload.from_build(_run.run_build)
		var center: Vector2 = _run.player_position + Vector2(290.0, 0.0)
		var direct: EnemyState = _run._make_enemy({
			"id":"capture_thermal_direct_%d" % (level_index + 1),
			"role":&"ordinary_pursuer_t1",
			"pos":center,
			"active":true,
		})
		if direct != null:
			direct.health_visible_timer = 0.0
			_run._append_enemy(direct)
		_add_exact_area_reference_markers(
			center,
			profile.thermal_burst_radius,
			profile.thermal_burst_radius
		)
		_run.capture_set_mode(&"paused")
		await _settle_capture()
		if direct != null:
			_run._apply_thermal_burst(direct, center, profile)
			direct.flash = 0.11
		if not _run.effects.is_empty():
			_run.effects[-1].time = 0.09
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_save_capture(
			"%s-thermal-burst-level-%d.png"
			% [file_prefixes[level_index], level_index + 1]
		)

	prepare_stage(1)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run._clear_effects()
	_run.run_build.apply(&"emp")
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_run._start_active_weapon()
	_run._advance_active_weapon(0.42)
	for impact_index in EffectStore.MAX_LIVE_THERMAL_IMPACTS:
		var column := impact_index % 6
		var row := impact_index / 6
		var position: Vector2 = _run.player_position + Vector2(
			-360.0 + float(column) * 144.0,
			-216.0 + float(row) * 144.0
		)
		_run._add_effect(
			&"thermal_burst_impact", position,
			Color.WHITE, 0.18, 72.0
		)
		_run.effects[-1].time = 0.09
	for fill_index in (
		EffectStore.MAX_LIVE_EFFECTS
		- EffectStore.MAX_LIVE_THERMAL_IMPACTS
		- 2
	):
		_run._add_effect(
			&"player_dash_afterimage",
			Vector2(10000.0 + float(fill_index), 10000.0),
			Color.WHITE,
			1.0,
			30.0,
			Vector2.RIGHT
		)
	_run._add_effect(
		&"thermal_burst_impact",
		_run.player_position + Vector2(360.0, 216.0),
		Color.WHITE,
		0.18,
		72.0
	)
	_run.effects[-1].time = 0.09
	print(JSON.stringify({
		"capture_group":"thermal_burst_saturation_emp",
		"effect_store":_run.effect_store.debug_snapshot(),
		"emp_charge":_run.effect_store.count_kind(&"player_emp_charge"),
		"emp_release":_run.effect_store.count_kind(&"player_emp_release"),
	}))
	_refresh_combat_capture()
	await _run.get_tree().process_frame
	_save_capture("09m-thermal-burst-saturation-emp.png")


func _capture_drop_mine_evidence() -> void:
	var file_prefixes := ["09n", "09o", "09p"]
	var radii := [192.0, 216.0, 240.0]
	for level_index in 3:
		prepare_stage(0)
		_run._clear_enemies()
		_run._clear_projectiles()
		_run._clear_effects()
		var center: Vector2 = _run.player_position + Vector2(290.0, 0.0)
		_add_exact_area_reference_markers(
			center, radii[level_index], radii[level_index]
		)
		_run.capture_set_mode(&"paused")
		await _settle_capture()
		_run._add_effect(
			EffectStore.DROP_MINE_DETONATION_KIND,
			center,
			Color.WHITE,
			0.18,
			radii[level_index]
		)
		_run.effects[-1].time = 0.09
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_save_capture(
			"%s-drop-mine-level-%d.png"
			% [file_prefixes[level_index], level_index + 1]
		)

	var settings := _run.get_node_or_null("/root/SettingsStore")
	var original_reduced_motion := (
		bool(settings.reduced_motion) if settings != null else false
	)
	if settings != null:
		settings.reduced_motion = true
	prepare_stage(0)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run._clear_effects()
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_run._add_effect(
		EffectStore.DROP_MINE_DETONATION_KIND,
		_run.player_position + Vector2(290.0, 0.0),
		Color.WHITE,
		0.18,
		120.0
	)
	_run.effects[-1].time = 0.18
	_refresh_combat_capture()
	await _run.get_tree().process_frame
	_save_capture("09q-drop-mine-reduced-motion.png")
	if settings != null:
		settings.reduced_motion = original_reduced_motion


func _capture_exact_area_effect_evidence() -> void:
	var settings := _run.get_node_or_null("/root/SettingsStore")
	var original_reduced_motion := (
		bool(settings.reduced_motion) if settings != null else false
	)
	for reduced_motion in [false, true]:
		if settings != null:
			settings.reduced_motion = reduced_motion
		var center := _prepare_exact_area_scene(0.90)
		_run._start_active_weapon()
		var emp_effect = _run.effects[-1]
		emp_effect.time = emp_effect.duration
		_add_exact_area_reference_markers(
			center, emp_effect.radius, emp_effect.secondary_radius
		)
		_run.capture_set_mode(&"paused")
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_save_capture(
			"09%s-emp-charge-%s.png"
			% ["s" if reduced_motion else "r", "reduced" if reduced_motion else "standard"]
		)

		center = _prepare_exact_area_scene(0.90)
		_run._start_active_weapon()
		_run._clear_effects()
		_run._advance_active_weapon(0.42)
		emp_effect = _run.effects[-1]
		emp_effect.time = emp_effect.duration
		_add_exact_area_reference_markers(
			center, emp_effect.radius, emp_effect.secondary_radius
		)
		_run.capture_set_mode(&"paused")
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_save_capture(
			"09%s-emp-release-%s.png"
			% ["u" if reduced_motion else "t", "reduced" if reduced_motion else "standard"]
		)

	if settings != null:
		settings.reduced_motion = false
	var seeker_center := _prepare_exact_area_scene(1.0)
	_run._add_effect(
		EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND,
		seeker_center,
		Art.MUSTARD,
		0.18,
		95.0
	)
	_run.effects[-1].time = _run.effects[-1].duration
	_add_exact_area_reference_markers(seeker_center, 95.0, 95.0)
	_run.capture_set_mode(&"paused")
	_refresh_combat_capture()
	await _run.get_tree().process_frame
	_save_capture("09z-explosive-seeker-impact.png")

	var mystery_profiles := [
		[&"lava", 0.40, "09v-facility-lava.png"],
		[&"cryo", 0.50, "09w-facility-cryo.png"],
		[&"weakpoint", 0.35, "09y-facility-weakpoint.png"],
	]
	if settings != null:
		settings.reduced_motion = false
	var ready_center := _prepare_exact_area_scene(1.0)
	_run.player_position = ready_center + Vector2(0.0, -130.0)
	_run.mystery_device_runtime.configure(
		[{"id":&"capture_mystery_ready", "pos":ready_center}],
		1701,
		_run.current_stage_id
	)
	_run.capture_set_mode(&"paused")
	_refresh_combat_capture()
	await _run.get_tree().process_frame
	_save_capture("09x-mystery-device-ready.png")
	for profile_variant in mystery_profiles:
		var profile := Array(profile_variant)
		var outcome := StringName(profile[0])
		var center := _prepare_exact_area_scene(float(profile[1]))
		# Keep the player visible but off the device center so the reviewed outcome
		# symbol remains inspectable in deterministic capture evidence.
		_run.player_position = center + Vector2(0.0, -130.0)
		_run.mystery_device_runtime.configure(
			[{"id":&"capture_mystery", "pos":center}],
			1701,
			_run.current_stage_id
		)
		_run.mystery_device_runtime.devices[0]["outcome"] = outcome
		_run.mystery_device_runtime.devices[0]["state"] = &"active"
		_run.mystery_device_runtime.devices[0]["health"] = 0.0
		_run.mystery_device_runtime.devices[0]["active_remaining"] = (
			_run.mystery_device_runtime.ACTIVE_DURATION_SECONDS * 0.65
		)
		var radius := float(
			_run.mystery_device_runtime.OUTCOME_PROFILE[outcome]["radius"]
		)
		_add_exact_area_reference_markers(center, radius, radius)
		_run.capture_set_mode(&"paused")
		_refresh_combat_capture()
		await _run.get_tree().process_frame
		_save_capture(String(profile[2]))
	if settings != null:
		settings.reduced_motion = original_reduced_motion
	_run._camera.zoom = Rules.GAMEPLAY_CAMERA_ZOOM


func _prepare_exact_area_scene(camera_zoom: float) -> Vector2:
	prepare_stage(0, true)
	if not _run.run_build.has(&"emp"):
		_run.run_build.apply(&"emp")
	_run._clear_enemies()
	_run._clear_projectiles()
	_run._clear_effects()
	_run.mystery_device_runtime.devices.clear()
	var center: Vector2 = Rules.world_rect(_run.current_stage_id).get_center()
	_run.player_position = center
	_run._camera.position = center
	_run._camera.zoom = Vector2.ONE * camera_zoom
	return center


func _add_exact_area_reference_markers(
	center: Vector2,
	actor_radius: float,
	projectile_radius: float
) -> void:
	var actor_distances := [actor_radius * 0.48, actor_radius, actor_radius + 42.0]
	for index in actor_distances.size():
		var enemy: EnemyState = _run._make_enemy({
			"id":"exact_area_actor_%d" % index,
			"role":&"ordinary_pursuer_t1",
			"pos":center + Vector2.LEFT.rotated(float(index) * 0.48)
				* float(actor_distances[index]),
			"active":true,
		})
		if enemy != null:
			enemy.health_visible_timer = 0.0
			_run._append_enemy(enemy)
	var projectile_distances := [
		projectile_radius * 0.58,
		projectile_radius,
		projectile_radius + 28.0,
	]
	for index in projectile_distances.size():
		var direction := Vector2.RIGHT.rotated(-0.68 + float(index) * 0.52)
		_run._spawn_hostile_projectile(
			center + direction * float(projectile_distances[index]),
			direction.rotated(PI * 0.5),
			6.0,
			500.0,
			"exact area reference"
		)
	_run._rebuild_enemy_runtime_indexes()


func _capture_visual_event_evidence() -> void:
	var colors := [Art.SYSTEM, Art.MUSTARD, Art.CORAL, Art.MINT]
	for group_variant in VisualEventCaptureFixture.GROUPS:
		var group := Dictionary(group_variant)
		var event_ids := Array(group["events"])
		prepare_stage(0, true)
		_run._clear_enemies()
		_run._clear_projectiles()
		_run.call("_clear_effects")
		for index in event_ids.size():
			var column := index % 4
			var row := index / 4
			var position: Vector2 = _run.player_position + Vector2(
				-330.0 + float(column) * 220.0,
				-180.0 + float(row) * 180.0
			)
			var direction := Vector2.RIGHT.rotated(
				float(index) * TAU / maxf(1.0, float(event_ids.size()))
			)
			var event_id := StringName(event_ids[index])
			var instant_impact := event_id in [
				&"thermal_burst_impact", EffectStore.DROP_MINE_DETONATION_KIND,
				EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND,
			]
			var radius := 54.0
			var secondary_radius := 0.0
			var duration := 1.0
			match event_id:
				EffectStore.EMP_CHARGE_KIND:
					radius = 285.0
					secondary_radius = 325.0
					duration = 0.42
				EffectStore.EMP_RELEASE_KIND:
					radius = 285.0
					secondary_radius = 325.0
					duration = 0.55
				EffectStore.THERMAL_BURST_IMPACT_KIND:
					radius = 84.0
					duration = 0.18
				EffectStore.DROP_MINE_DETONATION_KIND:
					radius = 108.0
					duration = 0.18
				EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND:
					radius = 95.0
					duration = 0.18
			_run._add_effect(
				event_id,
				position,
				Art.MUSTARD if instant_impact
				else colors[index % colors.size()],
				duration,
				radius,
				direction,
				18.0,
				0.20,
				secondary_radius
			)
			_run.effects[-1].time = duration * 0.65
		_run.capture_set_mode(&"paused")
		print(JSON.stringify({
			"capture_group":String(group["id"]),
			"events":event_ids,
		}))
		await _settle_capture()
		_save_capture(
			"09-effects-%s.png" % String(group["id"]).replace("_", "-")
		)


func _capture_ordinary_projectile_evidence() -> void:
	## Drive an ordinary ordinary_lane_01 through its authored startup, fire, flight,
	## and collision path. This fixture must never call the spawn helper
	## directly: the scheduling regression is what the capture is proving.
	prepare_stage(0, true)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run.player_health = _run._player_max_health()
	_run.player_invulnerable = 0.0
	_run.player_hit_flash = 0.0
	_run.player_barrier_strength = 0.0
	_run.player_barrier_timer = 0.0
	var ordinary_lane_01: VehicleEnemyState = _run._make_enemy({
		"id":"capture_ordinary_ordinary_lane_01",
		"role":&"ordinary_emitter_t1",
		"pos":_run.player_position + Vector2(-260.0, 0.0),
		"active":true,
	})
	if ordinary_lane_01 == null:
		push_error("ordinary projectile capture fixture could not create ordinary_lane_01")
		return
	_run._append_enemy(ordinary_lane_01)
	_run._start_enemy_attack(ordinary_lane_01)
	if ordinary_lane_01.phase != &"startup":
		push_error("ordinary projectile capture fixture did not enter startup")
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-projectile-hostile-startup.png")
	_run.capture_set_mode(&"playing")
	ordinary_lane_01.phase_time = 0.0
	_run._update_scheduled_ordinary_enemy(ordinary_lane_01, 1.0 / 60.0)
	if ordinary_lane_01.phase != &"recovery" or _run.projectile_store.hostile_count() != 1:
		push_error("ordinary projectile capture fixture did not produce a scheduled hostile shot")
	_run._update_projectiles(0.10)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-projectile-hostile-flight.png")
	_run.capture_set_mode(&"playing")
	var hull_before_hit: float = float(_run.player_health)
	_run._update_projectiles(0.50)
	if _run.player_health >= hull_before_hit:
		push_error("ordinary projectile capture fixture did not deliver hull damage")
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-projectile-hostile-hit.png")


func _capture_ordinary_fixed_beam_01_evidence() -> void:
	prepare_stage(2, true)
	_run._clear_enemies()
	_run._clear_projectiles()
	var sentinel: VehicleEnemyState = _run._make_enemy({
		"id":"capture_ordinary_fixed_beam_01",
		"role":&"boss_pattern_fixed_beam_01",
		"pos":_run.player_position + Vector2(-360.0, 0.0),
		"active":true,
	})
	if sentinel == null:
		push_error("Fixed Beam Ordinary Enemy Lv.1 capture fixture could not create the installation")
		return
	_run._append_enemy(sentinel)
	_run._start_enemy_attack(sentinel)
	sentinel.phase_time = SpecialistRuntime.BEAM_STARTUP * 0.5
	AttackTelegraphs.refresh_ordinary(
		sentinel,
		_run._runtime_attack_path_callable,
		_run._runtime_charge_path_callable
	)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-beam-sentinel-startup.png")
	_run._begin_enemy_active(sentinel)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-beam-sentinel-active.png")


func _capture_arc_area_telegraph_evidence() -> void:
	prepare_stage(0, true)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run.denied_zones.clear()
	var mine: VehicleEnemyState = _run._make_enemy({
		"id":"capture_arc_mine",
		"role":&"ordinary_charger_t1",
		"family_trait":&"self_destruct",
		"pos":_run.player_position + Vector2(250.0, 0.0),
		"active":true,
	})
	if mine != null:
		_run._append_enemy(mine)
		_run._start_enemy_attack(mine)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-arc-mine-startup.png")
	var boss := prepare_boss(0)
	if boss == null:
		push_error("arc area telegraph capture fixture could not create stage boss")
		return
	boss.phase = &"boss_startup"
	boss.pattern = &"thermal_ring"
	boss.phase_time = BossPatterns.startup_seconds("thermal_ring")
	boss.committed_target = _run.player_position
	boss.committed_dir = (_run.player_position - boss.pos).normalized()
	AttackTelegraphs.refresh_boss(
		boss,
		"thermal_ring",
		_run._runtime_attack_path_callable,
		_run._runtime_charge_path_callable
	)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("30-boss-01-stage-1-arc-area-startup.png")


func _capture_collision_overlay_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		prepare_stage(stage_index, true)
		_run.capture_set_mode(&"paused")
		var bounds := Rules.world_rect(_run.current_stage_id)
		_run.player_position = bounds.get_center()
		_fit_camera_to_stage(bounds)
		_run._debug_collision_overlay = true
		await _settle_capture()
		var stage_slug := String(_run.current_stage_id).replace("_", "-")
		_save_capture("20-collision-%02d-%s-default.png" % [stage_index + 1, stage_slug])
		_run._debug_collision_overlay = false
	_run._camera.zoom = Rules.GAMEPLAY_CAMERA_ZOOM


func _capture_all_boss_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		var boss := prepare_boss(stage_index)
		if boss == null:
			continue
		var stage_slug := String(_run.current_stage_id).replace("_", "-")
		var boss_number := stage_index + 1
		if stage_index == 2:
			_run._damage_enemy(
				boss,
				100.0,
				"validation",
				&"kinetic",
				true
			)
			_run.capture_set_mode(&"paused")
			await _settle_capture()
			_save_capture("30-boss-03-stage-3-shield-up-hit.png")
			_run.call("_clear_effects")
		_run._boss_select_pattern(boss)
		_run.capture_set_mode(&"paused")
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-startup.png" % [boss_number, stage_slug])

		boss.phase_time = BossPatterns.startup_seconds(String(boss.pattern)) * 0.12
		AttackTelegraphs.update_boss_readiness(boss, String(boss.pattern))
		await _settle_capture()
		_save_capture(
			"30-boss-%02d-%s-startup-imminent.png"
			% [boss_number, stage_slug]
		)

		boss.phase_time = 0.0
		AttackTelegraphs.update_boss_readiness(boss, String(boss.pattern))
		_run._boss_begin_active(boss)
		_run._boss_update_active(boss, 0.05)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-active.png" % [boss_number, stage_slug])

		_run._clear_projectiles()
		_run.denied_zones.clear()
		_run.call("_clear_effects")
		boss.phase = "boss_recovery"
		boss.phase_time = BossPatterns.recovery_seconds(String(boss.pattern))
		boss.vulnerable = 1.55
		boss.last_pattern = boss.pattern
		boss.pattern = "recovery_window"
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-recovery.png" % [boss_number, stage_slug])

		boss.health = float(boss.max_health) * 0.48
		_run._ui.clear_notifications()
		_run._begin_boss_shield_phase(boss, 2)
		_run._boss_select_pattern(boss)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-phase-two.png" % [boss_number, stage_slug])
		if stage_index == 0:
			boss.pos = _run.player_position + Vector2(920.0, 0.0)
			boss.phase = &"boss_startup"
			boss.phase_time = BossPatterns.startup_seconds("thermal_ring")
			boss.pattern = "thermal_ring"
			boss.committed_target = _run.player_position
			boss.committed_dir = (_run.player_position - Vector2(boss.pos)).normalized()
			AttackTelegraphs.refresh_boss(
				boss,
				"thermal_ring",
				_run._runtime_attack_path_callable,
				_run._runtime_charge_path_callable
			)
			_run._camera.position = _run.player_position
			await _settle_capture()
			_save_capture("30-boss-01-stage-1-offscreen-furnace.png")
			boss.phase_time = BossPatterns.startup_seconds("thermal_ring") * 0.12
			AttackTelegraphs.update_boss_readiness(boss, "thermal_ring")
			await _settle_capture()
			_save_capture(
				"30-boss-01-stage-1-offscreen-furnace-imminent.png"
			)
			boss.phase_time = 0.0
			AttackTelegraphs.update_boss_readiness(boss, "thermal_ring")
			_run._boss_begin_active(boss)
			_run._boss_update_active(boss, 0.05)
			await _settle_capture()
			_save_capture(
				"30-boss-01-stage-1-offscreen-furnace-active.png"
			)
		elif stage_index == 4:
			boss.pos = _run.player_position + Vector2(420.0, 0.0)
			boss.phase = &"boss_startup"
			boss.phase_time = BossPatterns.startup_seconds("focused_beam") * 0.5
			boss.pattern = "focused_beam"
			boss.committed_target = _run.player_position
			boss.committed_dir = (_run.player_position - Vector2(boss.pos)).normalized()
			AttackTelegraphs.refresh_boss(
				boss,
				"focused_beam",
				_run._runtime_attack_path_callable,
				_run._runtime_charge_path_callable
			)
			_run._camera.position = _run.player_position
			await _settle_capture()
			_save_capture("30-boss-05-radial-beam-startup.png")
			boss.phase_time = 0.0
			AttackTelegraphs.update_boss_readiness(boss, "focused_beam")
			_run._boss_begin_active(boss)
			_run._boss_update_active(boss, 0.05)
			await _settle_capture()
			_save_capture("30-boss-05-radial-beam-active.png")


func prepare_boss(stage_index: int) -> EnemyState:
	var boss: VehicleEnemyState = _campaign_fixture.prepare_boss_entry(stage_index)
	if boss == null:
		return null
	boss.pos = _run.player_position + Vector2(360.0, 0.0)
	_run.player_aim_direction = (Vector2(boss.pos) - _run.player_position).normalized()
	return boss


func _fit_camera_to_stage(bounds: Rect2) -> void:
	var viewport_size := _run.get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y) * 0.86
	_run._camera.zoom = Vector2.ONE * fit
	_run._camera.position = bounds.get_center()


func _settle_capture() -> void:
	for frame in 4:
		await _run.get_tree().process_frame


func _refresh_combat_capture() -> void:
	## Transient evidence is staged after the world settles so its exact short
	## mid-frame state is not consumed by capture-only wait frames.
	_run._combat_renderer.sync(
		_run.enemies,
		_run.player_projectiles,
		_run.hostile_projectiles,
		_run.experience_runtime.shards,
		_run.effects,
		_run._visible_world_rect(0.0),
		_run.player_position,
		_run.active_run_elapsed_seconds,
		true,
		_run._aim_target_id,
		_run._runtime_combat_presentation_snapshot()
	)


func _save_capture(file_name: String) -> void:
	_run._capture_driver.save_viewport(_run.get_viewport(), file_name)


func _stage_title_key(stage_index: int) -> String:
	return String(StageCatalog.profile(StageCatalog.STAGE_IDS[stage_index])["title_key"])
