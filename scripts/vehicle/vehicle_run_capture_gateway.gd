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
const BossShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
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
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const UpgradeOfferPresenter = preload(
	"res://scripts/cards/vehicle_upgrade_offer_presenter.gd"
)
const GuidebookCatalog = preload(
	"res://scripts/progression/vehicle_guidebook_catalog.gd"
)
const StageTelemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const ElementProfile = preload("res://scripts/combat/vehicle_element_profile.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StageReportBuilder = preload(
	"res://scripts/combat/vehicle_stage_report_builder.gd"
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


func _init(run: Node) -> void:
	_run = run
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
			_run.player_dash_cooldown = _run._dash_cooldown_max() * 0.75
			_run.secondary_runtime.seeker_cooldown = _run.SEEKER_COOLDOWN * 0.5
			_run.player_emp_cooldown = _run._emp_cooldown_max()
			_run._ui.update_hud(_run._build_hud_snapshot(false, false))
		&"cooldowns_clear":
			_run.player_dash_cooldown = 0.0
			_run.secondary_runtime.seeker_cooldown = 0.0
			_run.player_emp_cooldown = 0.0
			_run._ui.update_hud(_run._build_hud_snapshot(false, false))


func set_world_fixture(fixture: Dictionary) -> void:
	match StringName(fixture.get("kind", &"")):
		&"capture_environment":
			_apply_capture_environment(fixture)
		&"pressure":
			await _capture_pressure_evidence()
		&"collective_tactic":
			await _capture_collective_tactic_evidence()
		&"build_state":
			await _capture_build_state_evidence()
		&"radar_minimap_roles":
			await _capture_radar_minimap_roles()
		&"field_items":
			await _capture_field_item_evidence()
		&"reinforcement_facility":
			await _capture_reinforcement_facility_evidence()
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
		&"beam_sentinel":
			await _capture_beam_sentinel_evidence()
		&"damage_feedback":
			await _capture_damage_feedback_evidence()
		&"elemental_status_feedback":
			await _capture_elemental_status_evidence()
		&"electric_field_feedback":
			await _capture_electric_field_evidence()
		&"collision_overlays":
			await _capture_collision_overlay_evidence()
		&"all_bosses":
			await _capture_all_boss_evidence()


func show_ui_fixture(fixture: Dictionary) -> void:
	match StringName(fixture.get("kind", &"")):
		&"deployment":
			_run._ui.show_deployment(
				_run.selected_primary,
				String(_run.field_layout.field_definition["name_key"])
			)
		&"settings":
			_run._ui.debug_modal_contract("settings")
		&"gameplay_settings":
			_run._ui.debug_gameplay_settings_contract()
		&"guidebook":
			_run._ui.debug_modal_contract("guidebook")
		&"guidebook_boss":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(all_known, _run._build_snapshot()),
				&"bosses",
				&"boss_stage_2"
			)
		&"guidebook_locked":
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot({}, _run._build_snapshot()),
				&"mobile",
				&"mobile_scrap_drone"
			)
		&"guidebook_counterplay":
			var all_known := GuidebookCatalog.valid_ids()
			_run._ui.debug_guide_entry(
				GuidebookCatalog.snapshot(all_known, _run._build_snapshot()),
				&"mobile",
				&"mobile_chaser"
			)
		&"boss_practice":
			_run._ui.debug_modal_contract("practice")
		&"ship_status_active":
			var active_build: Dictionary = _run._build_snapshot()
			_run._ui.update_hud({
				"build_snapshot":active_build,
				"guidebook":_run._guidebook_snapshot(active_build),
			})
			_run._ui.debug_active_settings_contract()
		&"first_contact":
			_run._ui.show_gameplay()
			_run._update_encounter(5.1)
		&"pause":
			_run.capture_set_mode(&"paused")
			_run._ui.show_pause()
		&"stage_report":
			_show_stage_report(false)
		&"failure_report":
			_show_stage_report(true)
		&"result":
			_run.capture_set_mode(&"result")
			_run._ui.show_result({
				"stage_number":1,
				"stage_title_key":_stage_title_key(0),
				"has_next_stage":true,
				"next_stage_key":_stage_title_key(1),
				"time":"4:18",
				"health_ratio":0.76,
				"upgrade":"UPGRADE_PICKUP_RADIUS_TITLE",
				"primary_hits":42,
				"dash_uses":11,
				"installations":5,
			})
		&"garage":
			_run._ui.show_garage({
				"selected_primary":_run.selected_primary,
				"clear_count":1,
				"relay_module_unlocked":true,
				"field_module_unlocked":true,
				"build_summary":_run._run_build_summary(),
				"secondaries":_run.secondary_runtime.equipped_families(
					_run.run_build
				),
			})


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
		_run._ui.show_deployment(
			_run.selected_primary,
			String(_run.field_layout.field_definition["name_key"])
		)
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
		_report_fixture.record_defeat(&"scrap_drone")
		_report_fixture.record_defeat(&"scrap_drone")
		_report_fixture.record_defeat(&"needle_drone", &"armored")
	var report_data := {
		"number":1,
		"title_key":_stage_title_key(0),
		"has_next_stage":not failed,
		"clear_time":74.8,
		"hull":0.0 if failed else 88.0,
		"max_hull":120.0,
	}
	_run._ui.show_stage_report(StageReportBuilder.build(
		_report_fixture.stage_snapshot() if failed else _report_fixture.freeze_stage(),
		report_data,
		failed
	))


func prepare_stage(stage_index: int, preserve_upgrades: bool = false) -> void:
	_run.current_stage_index = clampi(stage_index, 0, StageCatalog.STAGE_IDS.size() - 1)
	_run.current_stage_id = StageCatalog.STAGE_IDS[_run.current_stage_index]
	_run._reset_run(false, true, preserve_upgrades)
	_run.capture_set_mode(&"playing")
	_run.player_position = Rules.player_start(_run.current_stage_id)
	_run.player_invulnerable = 99.0
	_run._camera.zoom = Vector2.ONE
	_run._ui.show_gameplay()


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
	prepare_stage(0)
	_run._clear_enemies()
	var direction := Vector2.LEFT
	for index in 6:
		var row := floori((float(index) + 1.0) * 0.5)
		var sign_value := -1.0 if index % 2 == 0 else 1.0
		var position: Vector2 = (
			_run.player_position
			+ Vector2(330.0 + float(row) * 48.0, sign_value * float(row) * 42.0)
		)
		var enemy: VehicleEnemyState = _run._make_enemy({
			"id":"capture_tactic_%02d" % index,
			"role":&"rammer" if index == 0 else &"chaser",
			"pos":position,
			"active":true,
			"squad_id":"capture_tactic",
			"group_id":"capture_tactic",
			"squad_leader":index == 0,
			"formation_slot":index,
			"formation_size":6,
			"collective_tactic_id":&"spearhead",
			"collective_beat_kind":&"teach",
		})
		if enemy == null:
			break
		enemy.collective_phase = &"lock"
		enemy.collective_mode = &"charge"
		enemy.collective_direction = direction
		enemy.collective_target = position
		enemy.health_visible_timer = 99.0 if index == 0 else 0.0
		_run._append_enemy(enemy)
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03b-collective-lock.png")
	for enemy in _run.enemies:
		if enemy.squad_id != "capture_tactic":
			continue
		enemy.collective_phase = &"break"
		enemy.vulnerable = 1.0
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("03c-collective-break.png")


func _capture_build_state_evidence() -> void:
	prepare_stage(3)
	_run._clear_enemies()
	for index in 4:
		var angle := -0.75 + float(index) * 0.5
		var position: Vector2 = (
			_run.player_position
			+ Vector2.RIGHT.rotated(angle) * (260.0 + float(index) * 35.0)
		)
		var role: StringName = &"controller" if index == 0 else &"chaser"
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
	_run._threat_contact_cache = threat_contacts
	_run.experience_runtime.run_level = 12
	_run.experience_runtime.experience = 73
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	await _settle_capture()
	_save_capture("04-stage-4-xp-hud.png")
	_run.experience_runtime.experience += 7
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	await _settle_capture()
	_save_capture("04b-stage-4-xp-collected.png")
	_run.experience_runtime.complete_progression()
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	_run._ui.notify_immediate(
		tr("NOTIFY_ALL_UPGRADES_COMPLETE"), 2.4, Art.SYSTEM
	)
	await _settle_capture()
	_save_capture("04c-progression-max.png")
	prepare_stage(3)
	for upgrade_id in [&"thermal_burst", &"chassis_speed", &"homing_missiles"]:
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
		{"kind":&"reward_crate", "position":world_size * Vector2(0.27, 0.25), "discovered":true},
		{"kind":&"mystery_device", "position":world_size * Vector2(0.42, 0.24), "discovered":true},
		{"kind":&"mobile_enemy", "position":world_size * Vector2(0.61, 0.25), "discovered":true},
		{"kind":&"priority_enemy", "position":world_size * Vector2(0.74, 0.25), "discovered":true},
		{"kind":&"boss", "position":world_size * Vector2(0.88, 0.25), "discovered":true},
		{"kind":&"reinforcement_facility", "position":world_size * Vector2(0.78, 0.72), "discovered":true},
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
	_run._ui.update_hud({
		"minimap":minimap,
		"threat_radar":{
			"visible":true,
			"center":_run.get_viewport_rect().size * 0.5,
			"max_distance":_run.THREAT_SCAN_DISTANCE,
			"contacts":contacts,
		},
	})
	await _run.get_tree().process_frame
	_save_capture("04e-radar-minimap-roles.png")


func _capture_field_item_evidence() -> void:
	prepare_stage(0)
	_run._clear_enemies()
	_run.crates.clear()
	_run.pickups.clear()
	_run.player_health = 64.0
	_run.pickups.append({"id":"capture_repair", "kind":&"repair", "pos":_run.player_position + Vector2(-150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":70.0})
	_run.pickups.append({"id":"capture_recall", "kind":&"experience_recall", "pos":_run.player_position + Vector2(150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":0.0})
	_run.experience_runtime.clear_shards()
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(245.0, -90.0), 1)
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(300.0, 35.0), 4)
	_run.experience_runtime.spawn_shard(_run.player_position + Vector2(245.0, 150.0), 18)
	await _settle_capture()
	_save_capture("05-two-field-items.png")


func _capture_reinforcement_facility_evidence() -> void:
	prepare_stage(0)
	_run._clear_enemies()
	_run.crates.clear()
	_run.pickups.clear()
	_run.reinforcement_facility_runtime.configure(
		0, _run.player_position + Vector2(360.0, 0.0)
	)
	_run.reinforcement_facility_runtime.activate_if_ready(35, 100)
	_run.reinforcement_facility_runtime.receive_damage(72.0, &"player", &"direct")
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	_run._ui.notify(tr("NOTIFY_REINFORCEMENT_FACILITY"), 2.4, Art.DANGER)
	await _settle_capture()
	_save_capture("05b-reinforcement-facility.png")


func _capture_structural_health_bar_evidence() -> void:
	prepare_stage(2)
	_run._clear_enemies()
	_run.pickups.clear()
	_run.crates.clear()
	var mobile: VehicleEnemyState = _run._make_enemy({
		"id":"capture_mobile_without_health_bar",
		"role":&"chaser",
		"pos":_run.player_position + Vector2(-280.0, 90.0),
		"active":true,
	})
	if mobile != null:
		mobile.health = mobile.max_health * 0.5
		mobile.health_visible_timer = 99.0
		_run._append_enemy(mobile)
	var installation: VehicleEnemyState = _run._make_enemy({
		"id":"capture_structural_health_bar",
		"role":&"beam_sentinel",
		"pos":_run.player_position + Vector2(290.0, -70.0),
		"active":true,
	})
	if installation != null:
		installation.health = installation.max_health * 0.5
		_run._append_enemy(installation)
	_run.reinforcement_facility_runtime.configure(
		2, _run.player_position + Vector2(20.0, 250.0)
	)
	_run.reinforcement_facility_runtime.activate_if_ready(70, 100)
	_run.reinforcement_facility_runtime.receive_damage(72.0, &"player", &"direct")
	_run.capture_set_mode(&"paused")
	_run._ui.update_hud(_run._build_hud_snapshot(false, false))
	await _settle_capture()
	_save_capture("05c-structural-health-bars.png")


func _capture_level_up_evidence() -> void:
	prepare_stage(0)
	var first_acquisition := _upgrade_offer_fixture([
		[&"thermal_burst", 0],
		[&"pickup_radius", 0],
		[&"homing_missiles", 0],
	])
	_run._ui.show_upgrade(first_acquisition)
	await _settle_capture()
	_save_capture("06-thermal-first-acquisition.png")
	_run._ui.debug_select_upgrade(0)
	await _settle_capture()
	_save_capture("06b-thermal-first-selected.png")
	var enhancement := _upgrade_offer_fixture([
		[&"thermal_burst", 1],
		[&"pickup_radius", 1],
		[&"homing_missiles", 1],
	])
	_run._ui.show_upgrade(enhancement)
	_run._ui.debug_select_upgrade(0)
	await _settle_capture()
	_save_capture("06c-thermal-enhancement.png")
	_run._ui.show_upgrade(enhancement.slice(0, 2))
	await _settle_capture()
	_save_capture("06d-two-card-tail.png")


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
		_save_capture("10-field-%s.png" % String(field_id).replace("_", "-"))
	_run._camera.zoom = Vector2.ONE
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
	var toxin_profile := ElementProfile.from_build(toxin_build)
	var cryo_profile := ElementProfile.from_build(cryo_build)
	var status_enemies: Array[EnemyState] = []
	for row in 2:
		for stack_index in 3:
			var enemy: EnemyState = _run._make_enemy({
				"id":"capture_status_%d_%d" % [row, stack_index],
				"role":&"chaser",
				"pos":_run.player_position + Vector2(
					165.0 + float(stack_index) * 105.0,
					-105.0 if row == 0 else 105.0
				),
				"active":true,
			})
			if enemy == null:
				continue
			for _stack in stack_index + 1:
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
	_save_capture("09b-element-status-application.png")
	for enemy in status_enemies:
		enemy.toxin_application_pulse = 0.0
		enemy.cryo_application_pulse = 0.0
	await _settle_capture()
	_save_capture("09c-element-status-persistent.png")
	if status_enemies.size() >= 3:
		status_enemies[2].flash = 0.11
	await _settle_capture()
	_save_capture("09d-element-status-hit-flash.png")
	if status_enemies.size() >= 3:
		status_enemies[2].flash = 0.0
	for enemy in status_enemies:
		enemy.toxin_application_pulse = 1.0
		enemy.cryo_application_pulse = 1.0
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
			"role":&"chaser",
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
			_run._add_effect(
				StringName(event_ids[index]),
				position,
				colors[index % colors.size()],
				1.0,
				54.0,
				direction,
				18.0,
				0.20
			)
			_run.effects[-1].time = 0.52
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
	## Drive an ordinary shooter through its authored startup, fire, flight,
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
	var shooter: VehicleEnemyState = _run._make_enemy({
		"id":"capture_ordinary_shooter",
		"role":&"shooter",
		"pos":_run.player_position + Vector2(-260.0, 0.0),
		"active":true,
	})
	if shooter == null:
		push_error("ordinary projectile capture fixture could not create shooter")
		return
	_run._append_enemy(shooter)
	_run._start_enemy_attack(shooter)
	if shooter.phase != &"startup":
		push_error("ordinary projectile capture fixture did not enter startup")
	_run.capture_set_mode(&"paused")
	await _settle_capture()
	_save_capture("09-effects-projectile-hostile-startup.png")
	_run.capture_set_mode(&"playing")
	shooter.phase_time = 0.0
	_run._update_scheduled_ordinary_enemy(shooter, 1.0 / 60.0)
	if shooter.phase != &"recovery" or _run.projectile_store.hostile_count() != 1:
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


func _capture_beam_sentinel_evidence() -> void:
	prepare_stage(2, true)
	_run._clear_enemies()
	_run._clear_projectiles()
	var sentinel: VehicleEnemyState = _run._make_enemy({
		"id":"capture_beam_sentinel",
		"role":&"beam_sentinel",
		"pos":_run.player_position + Vector2(-360.0, 0.0),
		"active":true,
	})
	if sentinel == null:
		push_error("beam sentinel capture fixture could not create the installation")
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
		"role":&"mine",
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
	boss.pattern = &"furnace_ring"
	boss.phase_time = BossPatterns.startup_seconds("furnace_ring")
	boss.committed_target = _run.player_position
	boss.committed_dir = (_run.player_position - boss.pos).normalized()
	AttackTelegraphs.refresh_boss(
		boss,
		"furnace_ring",
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
	_run._camera.zoom = Vector2.ONE


func _capture_all_boss_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		var boss := prepare_boss(stage_index)
		if boss == null:
			continue
		var stage_slug := String(_run.current_stage_id).replace("_", "-")
		if stage_index == 0:
			_run._damage_enemy(
				boss,
				100.0,
				"validation",
				&"kinetic",
				true
			)
			_run.capture_set_mode(&"paused")
			await _settle_capture()
			_save_capture("30-boss-01-stage-1-shield-up-hit.png")
			_run.call("_clear_effects")
		_run._boss_select_pattern(boss)
		_run.capture_set_mode(&"paused")
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-startup.png" % [stage_index + 1, stage_slug])

		boss.phase_time = BossPatterns.startup_seconds(String(boss.pattern)) * 0.12
		AttackTelegraphs.update_boss_readiness(boss, String(boss.pattern))
		await _settle_capture()
		_save_capture(
			"30-boss-%02d-%s-startup-imminent.png"
			% [stage_index + 1, stage_slug]
		)

		boss.phase_time = 0.0
		AttackTelegraphs.update_boss_readiness(boss, String(boss.pattern))
		_run._boss_begin_active(boss)
		_run._boss_update_active(boss, 0.05)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-active.png" % [stage_index + 1, stage_slug])

		_run._clear_projectiles()
		_run.denied_zones.clear()
		lower_boss_shield()
		_run.call("_clear_effects")
		boss.phase = "boss_recovery"
		boss.phase_time = BossPatterns.recovery_seconds(String(boss.pattern))
		boss.vulnerable = 1.55
		boss.last_pattern = boss.pattern
		boss.pattern = "recovery_window"
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-recovery.png" % [stage_index + 1, stage_slug])
		_run.boss_shield_runtime.advance(BossShieldRuntime.SHIELD_DOWN_SECONDS + 0.1)
		boss.boss_shield_state = _run.boss_shield_runtime.state()
		await _settle_capture()
		_save_capture(
			"30-boss-%02d-%s-shield-restored.png" % [stage_index + 1, stage_slug]
		)

		boss.health = float(boss.max_health) * 0.48
		_run._ui.clear_notifications()
		_run._begin_boss_shield_phase(boss, 2)
		_run._boss_select_pattern(boss)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-phase-two.png" % [stage_index + 1, stage_slug])
		if stage_index == 0:
			boss.pos = _run.player_position + Vector2(920.0, 0.0)
			boss.phase = &"boss_startup"
			boss.phase_time = BossPatterns.startup_seconds("furnace_ring")
			boss.pattern = "furnace_ring"
			boss.committed_target = _run.player_position
			boss.committed_dir = (_run.player_position - Vector2(boss.pos)).normalized()
			AttackTelegraphs.refresh_boss(
				boss,
				"furnace_ring",
				_run._runtime_attack_path_callable,
				_run._runtime_charge_path_callable
			)
			_run._camera.position = _run.player_position
			await _settle_capture()
			_save_capture("30-boss-01-stage-1-offscreen-furnace.png")
			boss.phase_time = BossPatterns.startup_seconds("furnace_ring") * 0.12
			AttackTelegraphs.update_boss_readiness(boss, "furnace_ring")
			await _settle_capture()
			_save_capture(
				"30-boss-01-stage-1-offscreen-furnace-imminent.png"
			)
			boss.phase_time = 0.0
			AttackTelegraphs.update_boss_readiness(boss, "furnace_ring")
			_run._boss_begin_active(boss)
			_run._boss_update_active(boss, 0.05)
			await _settle_capture()
			_save_capture(
				"30-boss-01-stage-1-offscreen-furnace-active.png"
			)
		elif stage_index == 4:
			boss.pos = _run.player_position + Vector2(420.0, 0.0)
			boss.phase = &"boss_startup"
			boss.phase_time = BossPatterns.startup_seconds("crown_beam") * 0.5
			boss.pattern = "crown_beam"
			boss.committed_target = _run.player_position
			boss.committed_dir = (_run.player_position - Vector2(boss.pos)).normalized()
			AttackTelegraphs.refresh_boss(
				boss,
				"crown_beam",
				_run._runtime_attack_path_callable,
				_run._runtime_charge_path_callable
			)
			_run._camera.position = _run.player_position
			await _settle_capture()
			_save_capture("30-boss-05-stage-5-crown-beam-startup.png")
			boss.phase_time = 0.0
			AttackTelegraphs.update_boss_readiness(boss, "crown_beam")
			_run._boss_begin_active(boss)
			_run._boss_update_active(boss, 0.05)
			await _settle_capture()
			_save_capture("30-boss-05-stage-5-crown-beam-active.png")


func prepare_boss(stage_index: int) -> EnemyState:
	prepare_stage(stage_index, true)
	_run._clear_enemies()
	_run._clear_projectiles()
	_run.denied_zones.clear()
	_run.player_position = Rules.player_start(_run.current_stage_id)
	_run.boss_arrival_position = (
		_run._active_tactical_layout.boss_arrival_anchors[0]
		if _run.field_layout != null
		else StageCatalog.boss_arrival_anchors(_run.current_stage_id)[0]
	)
	_run.stage_flow.defeats = _run.stage_flow.quota
	_run.stage_flow.state = StageFlow.State.BOSS_ACTIVE
	_run._start_stage_boss()
	var boss: VehicleEnemyState = _run._find_enemy_by_id("stage_boss")
	if boss == null:
		return null
	boss.pos = _run.player_position + Vector2(360.0, 0.0)
	_run.player_aim_direction = (Vector2(boss.pos) - _run.player_position).normalized()
	return boss


func lower_boss_shield() -> void:
	var boss: VehicleEnemyState = _run._find_enemy_by_id("stage_boss")
	if boss != null:
		_run._on_boss_direct_attack_complete(boss)


func _fit_camera_to_stage(bounds: Rect2) -> void:
	var viewport_size := _run.get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y) * 0.86
	_run._camera.zoom = Vector2.ONE * fit
	_run._camera.position = bounds.get_center()


func _settle_capture() -> void:
	for frame in 4:
		await _run.get_tree().process_frame


func _save_capture(file_name: String) -> void:
	_run._capture_driver.save_viewport(_run.get_viewport(), file_name)


func _stage_title_key(stage_index: int) -> String:
	return String(StageCatalog.profile(StageCatalog.STAGE_IDS[stage_index])["title_key"])
