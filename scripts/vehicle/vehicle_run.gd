class_name VehicleRun
extends Node2D

## Runs the connected authored vehicle campaign and its combat state.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const HudPresenter = preload("res://scripts/ui/vehicle_hud_presenter.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EliteTraits = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const CollectiveTacticRuntime = preload(
	"res://scripts/encounters/vehicle_collective_tactic_runtime.gd"
)
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const StatusProfile = preload("res://scripts/combat/vehicle_status_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const SpatialGrid = preload("res://scripts/combat/vehicle_spatial_grid.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const CombatRenderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const StageBackdrop = preload("res://scripts/vehicle/vehicle_stage_backdrop.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossExamCatalog = preload("res://scripts/bosses/vehicle_boss_exam_catalog.gd")
const BossExamRuntime = preload("res://scripts/bosses/vehicle_boss_exam_runtime.gd")
const UpgradeOfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPracticeSession = preload("res://scripts/bosses/vehicle_boss_practice_session.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const RewardRuntime = preload("res://scripts/rewards/vehicle_reward_runtime.gd")
const PickupContact = preload("res://scripts/rewards/vehicle_pickup_contact.gd")
const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const CycleRuntime = preload("res://scripts/cards/vehicle_cycle_runtime.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const PursuitField = preload("res://scripts/enemies/vehicle_pursuit_field.gd")
const SecondaryRuntime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const GuidebookCatalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyUpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")
const EnemyLocalSteering = preload("res://scripts/enemies/vehicle_enemy_local_steering.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const PerformanceRecorder = preload("res://scripts/performance/vehicle_performance_recorder.gd")
const PerformanceScenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const FieldLayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const StageTacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")
const DamageSourceCatalog = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const StageTelemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const BuildSnapshotBuilder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")
const StageReportBuilder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const CaptureDriver = preload("res://scripts/vehicle/vehicle_run_capture_driver.gd")
const CaptureGateway = preload("res://scripts/vehicle/vehicle_run_capture_gateway.gd")

enum RunMode {
	DEPLOYMENT,
	PLAYING,
	STAGE_TRANSITION,
	UPGRADE,
	PAUSED,
	STAGE_REPORT,
	FAILURE_REPORT,
	RESULT,
	GARAGE,
}

const SAVE_PATH := "user://vehicle-run.cfg"
const PLAYER_MAX_HEALTH := 120.0
const PLAYER_BASE_SPEED := 280.0
const PRIMARY_RANGE := 1600.0
const PRIMARY_VISIBLE_RANGE_MARGIN := 80.0
const PRIMARY_PROJECTILE_SPEED := 1120.0
const PRIMARY_PROJECTILE_RADIUS := 7.0
const DASH_DURATION := 0.20
const DASH_SPEED := 1220.0
const DASH_COOLDOWN := 1.25
const MAX_DASH_AFTERIMAGES := 5
const SEEKER_RANGE := 560.0
const SEEKER_COOLDOWN := 1.35
const EMP_COOLDOWN := 13.0
const EMP_STARTUP := 0.42
const EMP_RADIUS := 285.0
const MINIMAP_COLS := 20
const MINIMAP_ROWS := 12
const THREAT_SCAN_DISTANCE := 1200.0
const BOSS_ARRIVAL_MIN_DISTANCE := 1200.0
const BOSS_ARRIVAL_PREFERRED_MAX_DISTANCE := 1500.0
# Threat contacts feed the radar/world-marker channel, whose observable refresh
# cadence is five hertz. Keep the cache on that same boundary so peak hordes do
# not pay a duplicate full-enemy scan between HUD world updates.
const THREAT_SAMPLE_INTERVAL := 0.20
const LOW_COUNT_OVERLAY_INTERVAL := 0.05
const ORDINARY_DECISION_BUCKET_COUNT := 6
const FAR_SIMULATION_DISTANCE := 820.0
const FAR_SIMULATION_DISTANCE_SQUARED := FAR_SIMULATION_DISTANCE * FAR_SIMULATION_DISTANCE
const FAR_ENEMY_SIMULATION_BUCKET_COUNT := 3
const PICKUP_BODY_RADIUS := Art.PICKUP_PLINTH_RADIUS
const CRATE_COLLISION_RADIUS := 31.0
const CRATE_COLLISION_CELL_SIZE := 320.0
const CHARGE_PATH_SAMPLE_STEP := 8.0
const CHARGE_PATH_BINARY_STEPS := 8
# Prime relative to the six-way enemy decision buckets so profiling eventually
# observes every scheduling phase without timing every physics tick.
const PERFORMANCE_DETAIL_SAMPLE_STRIDE := 7
const PLAYER_HIT_FLASH_DURATION := 0.20
const PLAYER_HIT_INVULNERABILITY := 1.0
const STAGE_TRANSITION_SECONDS := 1.6
const STAGE_TRANSITION_INVULNERABILITY := 1.2
const STAGE_TRANSITION_CUE_AT := 0.35
const STAGE_TRANSITION_FIRST_SPAWN_AT := 1.35
const FIXED_LAYOUT_SEED := 0xC4A2B0

var mode := RunMode.DEPLOYMENT
var mode_before_pause := RunMode.PLAYING
var _tree_pause_owned := false
var _ui: Variant
var _hud_presenter := HudPresenter.new()
var _camera: Camera2D
var _backdrop
var _combat_renderer: VehicleCombatRenderer
var _rng := RandomNumberGenerator.new()
var _layout_session_rng := RandomNumberGenerator.new()
var _layout_session_seed := 0
var _layout_seed_override := 0
var _has_layout_seed_override := false
var _field_id_override: StringName = &""
var field_layout: VehicleFieldLayout
var _active_tactical_layout: StageTacticalLayout
var encounter_runtime := EncounterRuntime.new()
var collective_tactics := CollectiveTacticRuntime.new()
var stage_flow := StageFlow.new()
var pursuit_field := PursuitField.new()
var secondary_runtime := SecondaryRuntime.new()
var terrain_runtime := TerrainRuntime.new()
var stage_telemetry := StageTelemetry.new()
var boss_runtime := BossRuntime.new()
var boss_exam_runtime := BossExamRuntime.new()
var boss_practice := BossPracticeSession.new()
var _runtime_blockers: Array[Rect2] = []
var _runtime_bulkheads: Array[Rect2] = []
var _runtime_structural_walls: Array[Rect2] = []

var player_position := Vector2.ZERO
var player_velocity := Vector2.ZERO
var player_hull_direction := Vector2.RIGHT
var player_aim_direction := Vector2.RIGHT
var player_health := PLAYER_MAX_HEALTH
var player_invulnerable := 0.0
var player_protection_sources: Dictionary = {}
var player_hit_flash := 0.0
var player_primary_weapon := PrimaryWeapon.new()
var _primary_shot_serial := 0
var player_muzzle_flash := 0.0
var player_dash_cooldown := 0.0
var player_dash_timer := 0.0
var player_dash_direction := Vector2.RIGHT
var player_dash_trail_timer := 0.0
var player_emp_cooldown := 0.0
var player_emp_startup := 0.0
var player_barrier_strength := 0.0
var player_barrier_timer := 0.0
var coolant_surge_timer := 0.0
var _aim_target_id := ""
var _marked_enemy_id := ""
var _sheared_enemy_id := ""
var _last_damage_source := ""

var selected_primary := &"pulse_cannon"
var selected_run_difficulty: StringName = RunDifficulty.DEFAULT
var selected_upgrade_title_key := "UPGRADE_NONE"
var upgrade_catalog := UpgradeCatalog.new()
var run_build := RunBuild.new(upgrade_catalog)
var _status_profile: VehicleStatusProfile = StatusProfile.from_build(run_build)
var experience_runtime := ExperienceRuntime.new()
var cycle_runtime := CycleRuntime.new()
var applied_upgrades: Dictionary = run_build.levels
var current_card_offer: Array[Dictionary] = []
var reward_runtime := RewardRuntime.new()
var completed_group_rewards: Dictionary = {}
var pending_stage_completion := false
var experience_recall_timer := 0.0
var stage_transition_remaining := 0.0
var completed_stage_reports: Array[Dictionary] = []
var lifesteal_budget := 6.0

var enemy_store := EnemyStore.new()
var _enemy_update_schedule := EnemyUpdateSchedule.new()
var enemy_grid := SpatialGrid.new()
var enemies: Array[EnemyState] = enemy_store.live
var _enemy_query_buffer: Array[EnemyState] = []
var _enemy_query_group_ends := PackedInt32Array()
var _enemy_query_group_exit_t := PackedFloat32Array()
var _support_query_buffer: Array[EnemyState] = []
var projectile_store := ProjectileStore.new()
var player_projectiles: Array[ProjectileState] = projectile_store.player_live
var hostile_projectiles: Array[ProjectileState] = projectile_store.hostile_live
var pickups: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var _crate_collision_cells: Dictionary = {}
var denied_zones: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var resolved_boss_module_visuals: Array[Dictionary] = []
var damaging_trails: Array[Dictionary] = []
var _empty_cover_rects: Array[Rect2] = []
var _projectile_cover_query: Array[Rect2] = []
var _motion_cover_query: Array[Rect2] = []
var _cover_hit_receipt: Dictionary = {"hit":false, "t":2.0}
var _cover_hit_candidate: Dictionary = {"hit":false, "t":2.0}
var _crate_hit_receipt: Dictionary = {"crate":null, "t":INF}
var _build_fast_hud_snapshot_callable: Callable
var _minimap_snapshot_callable: Callable
var _threat_radar_snapshot_callable: Callable
var _guidebook_snapshot_callable: Callable
var _runtime_line_of_sight_callable: Callable
var _query_enemy_radius_callable: Callable
var _enemy_find_callable: Callable
var _runtime_attack_path_callable: Callable
var _runtime_charge_path_callable: Callable
var _elite_pending := 0
var _elite_spawned := 0
var _elite_threshold_cursor := 0

var tutorial_move := false
var tutorial_aim := false
var tutorial_fire := false
var tutorial_dash := false
var tutorial_announced := false
var boss_started := false
var boss_phase_two_announced := false
var boss_arrival_position := Vector2.ZERO
var stage_complete := false
var run_time := 0.0
var stage_started_at := 0.0
var run_index := 0
var current_stage_index := 0
var current_stage_id: StringName = StageCatalog.STAGE_IDS[0]

var visited_cells: Dictionary = {}
var discovered_markers: Dictionary = {}
var _threat_contact_cache: Array[Dictionary] = []
var _threat_sample_timer := 0.0
var _enemy_local_steering := EnemyLocalSteering.new()
var _shielded_enemy_ids: Dictionary = {}
var _pending_shielded_enemy_ids: Dictionary = {}
var _shield_supports: Array[EnemyState] = []
var _enemy_decision_bucket := 0
var _simulation_lod_bucket := 0
var _far_enemy_simulation_bucket := 0
var _enemy_coordination_initialized := false
var _low_count_overlay_timer := 0.0
var _physics_serial := 0
var _presented_physics_serial := -1
var _last_presentation_active := false
var camera_shake := 0.0
var _camera_offset := Vector2.ZERO

var stats_primary_hits := 0
var stats_dash_uses := 0
var stats_installations := 0
var stats_damage_taken := 0.0
var stats_enemies_defeated := 0

var persistent_clear_count := 0
var persistent_relay_module := false
var persistent_field_module := false

var _audio: VehicleAudioDirector

var _capture_mode := false
var _capture_driver: VehicleRunCaptureDriver
var _capture_gateway: RefCounted
var _debug_collision_overlay := false
var _performance_request: Dictionary = {}
var _performance_recorder: VehiclePerformanceRecorder
var _performance_scenario: VehiclePerformanceScenario
var _performance_finishing := false
var _performance_enemy_sections: Dictionary = {}
var _performance_detail_sample_active := false
var _practice_request: Dictionary = {}
var _practice_request_invalid := false
var _pending_stage_report: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_fast_hud_snapshot_callable = Callable(
		self, "_build_fast_hud_snapshot"
	)
	_minimap_snapshot_callable = Callable(self, "_minimap_snapshot")
	_threat_radar_snapshot_callable = Callable(self, "_threat_radar_snapshot")
	_guidebook_snapshot_callable = Callable(self, "_guidebook_snapshot")
	_runtime_line_of_sight_callable = Callable(
		self, "_runtime_has_line_of_sight"
	)
	_query_enemy_radius_callable = Callable(self, "_query_enemy_radius_into")
	_enemy_find_callable = Callable(enemy_store, "find")
	_runtime_attack_path_callable = Callable(self, "_runtime_attack_path_end")
	_runtime_charge_path_callable = Callable(self, "_runtime_charge_path_end")
	_rng.seed = 0xC4A2B0
	_layout_session_rng.randomize()
	_layout_session_seed = _layout_session_rng.seed
	_capture_mode = CaptureDriver.is_requested_from_command_line()
	if _capture_mode:
		_capture_gateway = CaptureGateway.new(self)
		_capture_driver = CaptureDriver.from_command_line()
		_capture_driver.apply_locale()
		if _capture_driver.layout_seed_override != null:
			_layout_seed_override = int(_capture_driver.layout_seed_override)
			_has_layout_seed_override = true
		if _capture_driver.field_id_override != &"":
			_field_id_override = _capture_driver.field_id_override
	_performance_request = _parse_performance_request()
	_practice_request = _parse_boss_practice_request()
	if _practice_request_invalid and DisplayServer.get_name() == "headless":
		get_tree().quit(2)
		return
	if (
		_capture_mode
		or not _performance_request.is_empty()
		or not _practice_request.is_empty()
	) and not _has_layout_seed_override:
		_layout_seed_override = FIXED_LAYOUT_SEED
		_has_layout_seed_override = true
	_build_backdrop()
	_build_combat_renderer()
	_build_camera()
	_build_ui()
	_build_audio()
	if _practice_request.is_empty():
		_load_persistence()
	selected_run_difficulty = RunDifficulty.HARD
	_reset_run(false)
	_ui.show_deployment(
		selected_primary,
		String(field_layout.field_definition["name_key"])
	)
	_set_mouse_for_mode()
	queue_redraw()
	if _capture_mode:
		call_deferred("_start_capture")
	elif not _practice_request.is_empty():
		call_deferred("_start_boss_practice")
	elif not _performance_request.is_empty():
		call_deferred("_start_performance_scenario")


func _exit_tree() -> void:
	if _capture_driver != null and _capture_gateway != null:
		_capture_driver.restore_on_exit(_capture_gateway)
	if is_instance_valid(_performance_scenario):
		_performance_scenario.deactivate()
	_release_tree_pause()
	if is_instance_valid(_audio):
		_audio.shutdown()


func _start_capture() -> void:
	await _capture_driver.run(_capture_gateway)


func capture_set_mode(mode_name: StringName) -> void:
	## Narrow gateway hook; capture tooling never imports or duplicates RunMode values.
	match mode_name:
		&"playing":
			mode = RunMode.PLAYING
		&"paused":
			mode = RunMode.PAUSED
		&"result":
			mode = RunMode.RESULT


func _physics_process(delta: float) -> void:
	var performance_active := is_instance_valid(_performance_recorder)
	_performance_detail_sample_active = (
		performance_active
		and _physics_serial % PERFORMANCE_DETAIL_SAMPLE_STRIDE == 0
	)
	var physics_started := Time.get_ticks_usec() if performance_active else 0
	var subsystem_ms := {}
	if _performance_detail_sample_active:
		_performance_enemy_sections.clear()
	if is_instance_valid(_performance_scenario) and mode == RunMode.PLAYING:
		_performance_scenario.before_physics(self, delta)
	if _simulation_active():
		var pickup_motion_start := player_position
		_simulation_lod_bucket = 1 - _simulation_lod_bucket
		_far_enemy_simulation_bucket = (
			(_far_enemy_simulation_bucket + 1)
			% FAR_ENEMY_SIMULATION_BUCKET_COUNT
		)
		run_time += delta
		var section_started := Time.get_ticks_usec() if _performance_detail_sample_active else 0
		_update_player(delta)
		var pickup_motion_end := player_position
		_update_terrain(delta, pickup_motion_start)
		_update_cycle_upgrades(delta)
		_update_pickups(pickup_motion_start, pickup_motion_end)
		if experience_recall_timer > 0.0:
			_update_experience(delta)
		elif _simulation_lod_bucket == 0:
			_update_experience(delta * 2.0)
		if _performance_detail_sample_active:
			subsystem_ms["player_and_rewards"] = _elapsed_ms(section_started)
			section_started = Time.get_ticks_usec()
		_update_encounter(delta)
		pursuit_field.update(delta, player_position)
		if _performance_detail_sample_active:
			subsystem_ms["encounter_and_pursuit"] = _elapsed_ms(section_started)
			section_started = Time.get_ticks_usec()
		_update_enemies(delta)
		if _performance_detail_sample_active:
			for section_name in _performance_enemy_sections:
				subsystem_ms["enemy_%s" % String(section_name)] = _performance_enemy_sections[section_name]
		_update_threat_contacts(delta)
		if _performance_detail_sample_active:
			subsystem_ms["enemies_and_grid"] = _elapsed_ms(section_started)
			section_started = Time.get_ticks_usec()
		_update_projectiles(delta)
		_update_denied_zones(delta)
		_update_trails(delta)
		if _simulation_lod_bucket == 0:
			_update_effects(delta * 2.0)
		if _performance_detail_sample_active:
			subsystem_ms["combat_and_effects"] = _elapsed_ms(section_started)
			section_started = Time.get_ticks_usec()
		_update_stage_progression(delta)
		if _flush_defeated_enemies() > 0:
			enemy_grid.sync(enemies)
		if _performance_detail_sample_active:
			subsystem_ms["progression_and_cleanup"] = _elapsed_ms(section_started)
	else:
		_update_effects(delta)
	_update_camera(delta)
	if is_instance_valid(_performance_scenario) and mode == RunMode.PLAYING:
		_performance_scenario.after_physics(self)
	if performance_active:
		_performance_recorder.record_physics(_elapsed_ms(physics_started), subsystem_ms)
	_physics_serial += 1


func _process(delta: float) -> void:
	var performance_active := is_instance_valid(_performance_recorder)
	var hud_ms := 0.0
	var presentation_ms := 0.0
	player_hit_flash = maxf(0.0, player_hit_flash - delta)
	player_muzzle_flash = maxf(0.0, player_muzzle_flash - delta)
	camera_shake = maxf(0.0, camera_shake - delta * 18.0)
	if is_instance_valid(_ui) and (_simulation_active() or _capture_mode):
		var hud_started := Time.get_ticks_usec() if performance_active else 0
		var hud_update := _hud_presenter.advance(
			delta,
			_build_fast_hud_snapshot_callable,
			_minimap_snapshot_callable,
			_threat_radar_snapshot_callable,
			_guidebook_snapshot_callable
		)
		if not hud_update.is_empty():
			_ui.update_hud(hud_update)
		if performance_active:
			hud_ms = _elapsed_ms(hud_started)
	else:
		_hud_presenter.reset()
	if is_instance_valid(_audio):
		var primary_held := (
			_simulation_active()
			and InputMap.has_action("primary_fire")
			and Input.is_action_pressed("primary_fire")
		)
		_audio.update_primary(primary_held)
	var presentation_active := _simulation_active() or _capture_mode
	if (
		is_instance_valid(_combat_renderer)
		and (
			_presented_physics_serial != _physics_serial
			or _last_presentation_active != presentation_active
		)
	):
		var presentation_started := Time.get_ticks_usec() if performance_active else 0
		_combat_renderer.sync(
			enemies,
			player_projectiles,
			hostile_projectiles,
			experience_runtime.shards,
			effects,
			_visible_world_rect(0.0),
			player_position,
			run_time,
			presentation_active,
			_aim_target_id,
			_combat_presentation_snapshot()
		)
		if performance_active:
			presentation_ms = _elapsed_ms(presentation_started)
		_presented_physics_serial = _physics_serial
		_last_presentation_active = presentation_active
	_low_count_overlay_timer -= delta
	if (
		_low_count_overlay_timer <= 0.0
		and (_simulation_active() or _capture_mode or _debug_collision_overlay)
	):
		_low_count_overlay_timer = LOW_COUNT_OVERLAY_INTERVAL
		queue_redraw()
	if (
		performance_active
		and not _performance_finishing
		and _performance_recorder.advance_frame(
			delta,
			presentation_ms,
			hud_ms
		)
	):
		_finish_performance_scenario()


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "VehicleCamera"
	_camera.enabled = true
	_camera.position = Rules.player_start(current_stage_id)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_apply_camera_stage_limits()
	add_child(_camera)


func _apply_camera_stage_limits() -> void:
	var bounds := Rules.world_rect(current_stage_id)
	_camera.limit_left = int(bounds.position.x)
	_camera.limit_top = int(bounds.position.y)
	_camera.limit_right = int(bounds.end.x)
	_camera.limit_bottom = int(bounds.end.y)


func _build_backdrop() -> void:
	_backdrop = StageBackdrop.new()
	_backdrop.name = "VehicleStageBackdrop"
	add_child(_backdrop)
	_backdrop.configure(current_stage_id, _active_tactical_layout)


func _build_combat_renderer() -> void:
	_combat_renderer = CombatRenderer.new()
	_combat_renderer.name = "VehicleCombatRenderer"
	add_child(_combat_renderer)


func _build_ui() -> void:
	_ui = StageUI.new()
	_ui.name = "VehicleStageUI"
	add_child(_ui)
	_ui.deployment_selected.connect(_on_deployment_selected)
	if _ui.has_signal("boss_practice_selected"):
		_ui.boss_practice_selected.connect(_on_boss_practice_selected)
	_ui.upgrade_selected.connect(_on_upgrade_selected)
	_ui.upgrade_previewed.connect(func(_upgrade_id: StringName) -> void: _play_sound(&"upgrade_select"))
	_ui.pause_requested.connect(_pause_run)
	_ui.resume_requested.connect(_resume_run)
	_ui.restart_requested.connect(_restart_stage)
	_ui.garage_requested.connect(_show_garage)
	_ui.replay_requested.connect(_replay_stage)
	_ui.stage_report_continued.connect(_continue_stage_report)


func _build_audio() -> void:
	_audio = AudioDirector.new()
	_audio.name = "VehicleAudioDirector"
	add_child(_audio)


func _play_sound(sound_id: StringName, pitch: float = 1.0) -> void:
	if is_instance_valid(_audio):
		_audio.play(sound_id, pitch)


func _reset_run(
	increment_index: bool = true,
	preserve_stage: bool = false,
	preserve_upgrades: bool = false,
	preserve_field_state: bool = false
) -> void:
	if increment_index:
		run_index += 1
	if not preserve_stage:
		current_stage_index = 0
		current_stage_id = StageCatalog.STAGE_IDS[0]
		_generate_field_layout()
	elif field_layout == null:
		_generate_field_layout()
	_active_tactical_layout = (
		field_layout.tactical_layout(current_stage_id)
		if field_layout != null
		else null
	)
	if _active_tactical_layout == null:
		push_error("Missing tactical layout for %s" % current_stage_id)
		return
	if is_instance_valid(_backdrop):
		_backdrop.configure(current_stage_id, _active_tactical_layout)
	if is_instance_valid(_camera):
		_apply_camera_stage_limits()
	if is_instance_valid(_ui):
		_ui.clear_notifications()
		_ui.hide_stage_transition()
	stage_transition_remaining = 0.0
	mode = RunMode.DEPLOYMENT
	player_position = Rules.player_start(current_stage_id)
	player_velocity = Vector2.ZERO
	player_hull_direction = Vector2.RIGHT
	player_aim_direction = Vector2.RIGHT
	player_health = _player_max_health()
	player_invulnerable = 0.0
	player_protection_sources.clear()
	player_hit_flash = 0.0
	player_primary_weapon.reset()
	_primary_shot_serial = 0
	player_dash_cooldown = 0.0
	player_dash_timer = 0.0
	player_emp_cooldown = 0.0
	player_emp_startup = 0.0
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	coolant_surge_timer = 0.0
	_aim_target_id = ""
	_marked_enemy_id = ""
	_sheared_enemy_id = ""
	_last_damage_source = ""
	_elite_pending = 0
	_elite_spawned = 0
	_elite_threshold_cursor = 0

	if not preserve_upgrades:
		run_build.reset()
		stage_telemetry.reset_run()
		experience_runtime.reset()
		reward_runtime.reset_run()
		completed_stage_reports.clear()
		selected_upgrade_title_key = "UPGRADE_NONE"
	else:
		stage_telemetry.reset_stage()
		experience_runtime.clear_shards()
		experience_runtime.pending_level_ups = 0
		reward_runtime.reset_stage()
	_status_profile = StatusProfile.from_build(run_build)
	cycle_runtime.reset()
	secondary_runtime.reset(player_position)
	_sync_cycle_upgrades()
	experience_recall_timer = 0.0
	lifesteal_budget = 6.0
	player_health = _player_max_health()
	current_card_offer.clear()
	_clear_enemies()
	_clear_projectiles()
	pickups.clear()
	crates.clear()
	denied_zones.clear()
	effects.clear()
	resolved_boss_module_visuals.clear()
	damaging_trails.clear()
	for spec in _active_tactical_layout.stationary_blueprint():
		_append_enemy(_make_enemy(spec))
	encounter_runtime.configure(
		current_stage_id,
		StageCatalog.packets(current_stage_id),
		selected_run_difficulty,
		_active_tactical_layout.ordinary_spawn_anchors,
		_active_tactical_layout.encounter_seed,
		_active_tactical_layout.geometry_snapshot
	)
	stage_flow.configure(
		current_stage_index,
		RunDifficulty.scaled_quota(StageCatalog.quota(current_stage_id), selected_run_difficulty)
	)
	terrain_runtime.configure(
		field_layout.field_definition.get("features", []),
		field_layout.persistent_bulkhead_health,
		preserve_field_state,
		_active_tactical_layout.support_sockets,
		field_layout.seed,
		current_stage_id,
		field_layout.persistent_wear_tile_state
	)
	_rebuild_runtime_blockers()
	pursuit_field.reset(current_stage_id, _runtime_cover_rects())
	_populate_stage_items()

	tutorial_move = false
	tutorial_aim = false
	tutorial_fire = false
	tutorial_dash = false
	tutorial_announced = false
	boss_started = false
	boss_exam_runtime.configure(current_stage_id)
	boss_phase_two_announced = false
	boss_arrival_position = Vector2.ZERO
	stage_complete = false
	pending_stage_completion = false
	completed_group_rewards.clear()
	_pending_stage_report.clear()
	if not preserve_upgrades:
		run_time = 0.0
	stage_started_at = run_time
	if not preserve_upgrades:
		visited_cells.clear()
	discovered_markers.clear()
	_threat_contact_cache.clear()
	_threat_sample_timer = 0.0
	_shielded_enemy_ids.clear()
	_pending_shielded_enemy_ids.clear()
	_shield_supports.clear()
	_enemy_decision_bucket = 0
	_simulation_lod_bucket = 0
	_far_enemy_simulation_bucket = 0
	_enemy_coordination_initialized = false
	_presented_physics_serial = -1
	_last_presentation_active = false
	_hud_presenter.reset()
	if not preserve_upgrades:
		stats_primary_hits = 0
		stats_dash_uses = 0
		stats_installations = 0
		stats_damage_taken = 0.0
		stats_enemies_defeated = 0
	_mark_visited()
	if persistent_relay_module:
		player_emp_cooldown = 0.0
	if persistent_field_module:
		secondary_runtime.seeker_cooldown = 0.0
	enemy_grid.configure(Rules.world_rect(current_stage_id), SpatialGrid.DEFAULT_CELL_SIZE)
	enemy_grid.rebuild(enemies)


func _generate_field_layout() -> void:
	var layout_seed := (
		_layout_seed_override
		if _has_layout_seed_override
		else hash("field:v1:%d:%d" % [_layout_session_seed, run_index])
	)
	field_layout = FieldLayoutGenerator.generate(
		layout_seed, StageCatalog.STAGE_IDS, _field_id_override
	)
	if field_layout == null:
		push_error("Could not generate the required run field layout")
		return
	StageCatalog.activate_field(field_layout.field_id)


func _populate_stage_items() -> void:
	pickups.clear()
	crates.clear()
	for spec in _active_tactical_layout.pickup_blueprint():
		pickups.append({
			"id": String(spec["id"]),
			"kind": StringName(spec["kind"]),
			"pos": Vector2(spec["pos"]),
			"active": true,
			"pulse": _rng.randf_range(0.0, TAU),
			"heal_amount": float(spec.get("heal_amount", 0.0)),
		})
	for spec in _active_tactical_layout.crate_blueprint():
		crates.append({
			"id": String(spec["id"]),
			"pos": Vector2(spec["pos"]),
			"drop": StringName(spec["drop"]),
			"heal_amount": float(spec.get("heal_amount", 0.0)),
			"guarded_by": StringName(spec.get("guarded_by", &"")),
			"health": 24.0,
			"max_health": 24.0,
			"alive": true,
			"flash": 0.0,
		})
	_rebuild_crate_collision_cells()


func _make_enemy(spec: Dictionary) -> EnemyState:
	var enemy: EnemyState = enemy_store.acquire()
	if enemy == null:
		return null
	var archetype := StringName(spec["role"])
	var definition := EnemyArchetypes.definition(archetype)
	var role := StringName(definition["behavior"])
	var attack_cooldown := _rng.randf_range(0.4, 1.2) / EncounterDirector.ENEMY_RECOVERY_RATE
	var health := float(definition["health"])
	var health_class := StringName(definition["health_class"])
	var stage_curve := StageDifficulty.multipliers(current_stage_index)
	var difficulty_profile := RunDifficulty.profile(selected_run_difficulty)
	if health_class in [&"swarm", &"standard"]:
		health *= EncounterDirector.ENEMY_HEALTH_MULTIPLIER
	if archetype == &"stage_boss":
		health = StageDifficulty.boss_health(current_stage_index) * float(difficulty_profile["boss_health"])
	else:
		health *= float(stage_curve["health"]) * float(difficulty_profile["health"])
	var position: Vector2 = spec["pos"]
	var movement_multiplier := (
		EncounterDirector.ENEMY_SPEED_MULTIPLIER
		if archetype == &"stage_boss"
		else EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
	)
	var speed := (
		float(definition["speed"])
		* movement_multiplier
		* float(difficulty_profile["speed"])
	)
	if archetype not in [&"stage_boss"]:
		speed *= float(stage_curve["speed"])
	enemy.id = String(spec.get("id", role))
	enemy.role = role
	enemy.archetype = archetype
	enemy.name = String(spec.get("name_key", definition["name_key"]))
	enemy.pos = position
	enemy.home = position
	enemy.velocity = Vector2.ZERO
	enemy.desired_velocity = Vector2.ZERO
	enemy.health = health
	enemy.max_health = health
	enemy.speed = speed
	enemy.radius = float(definition["radius"])
	enemy.visual_radius = Art.enemy_visual_radius(archetype)
	enemy.projectile_hit_radius = enemy.visual_radius
	enemy.health_class = health_class
	enemy.health_visible_timer = 0.0
	enemy.threat_cost = float(definition["threat_cost"])
	enemy.threat_kind = StringName(definition["threat_kind"])
	enemy.counts_active_cap = bool(definition["active_cap"])
	enemy.alive = true
	enemy.active = bool(spec.get("active", false))
	enemy.phase = &"move"
	enemy.phase_time = 0.0
	enemy.attack_cooldown = attack_cooldown
	enemy.committed_dir = Vector2.LEFT
	enemy.committed_target = position
	enemy.hit_committed = false
	enemy.burst_left = 0
	enemy.burst_timer = 0.0
	enemy.stun = 0.0
	enemy.flash = 0.0
	enemy.shielded = false
	enemy.support_tick = 0.0
	enemy.repair_target_id = ""
	enemy.intercept_charges = 3 if role == &"interceptor_tower" else 0
	enemy.intercept_recharge = 0.0
	enemy.strafe_sign = -1.0 if String(spec.get("id", "")).hash() % 2 == 0 else 1.0
	enemy.stuck_time = 0.0
	enemy.reposition_time = 0.0
	enemy.reposition_dir = Vector2.ZERO
	enemy.zone = String(spec.get("zone", ""))
	enemy.group_id = String(spec.get("group_id", ""))
	enemy.squad_id = String(spec.get("squad_id", ""))
	enemy.squad_leader = bool(spec.get("squad_leader", false))
	enemy.formation_slot = int(spec.get("formation_slot", 0))
	enemy.formation_size = int(spec.get("formation_size", 1))
	enemy.collective_tactic_id = StringName(
		spec.get("collective_tactic_id", &"")
	)
	enemy.collective_beat_kind = StringName(
		spec.get("collective_beat_kind", &"")
	)
	enemy.collective_phase = &"dormant"
	enemy.collective_mode = &""
	enemy.collective_direction = Vector2.RIGHT
	enemy.collective_target = position
	enemy.collective_slot = 0
	enemy.collective_speed_multiplier = 1.0
	enemy.packet_beat = int(spec.get("packet_beat", 0))
	enemy.carrier_id = String(spec.get("carrier_id", ""))
	enemy.summoned = bool(spec.get("summoned", false))
	enemy.child_serial = 0
	enemy.carrier_wave_released = false
	enemy.beam_end = position
	enemy.marked_time = 0.0
	enemy.shear_time = 0.0
	enemy.leash_rect = Rect2(spec.get("leash_rect", Rect2()))
	enemy.required = bool(spec.get("required", false))
	enemy.optional = bool(spec.get("optional", false))
	enemy.ram_cooldown = 0.0
	enemy.pattern_index = 0
	enemy.boss_phase = 1
	enemy.boss_variant = StringName(spec.get("boss_variant", &"colossus"))
	enemy.boss_objective_id = StringName(spec.get("boss_objective_id", &""))
	enemy.boss_module_kind = StringName(spec.get("boss_module_kind", &""))
	enemy.boss_module_index = int(spec.get("boss_module_index", -1))
	enemy.boss_module_state = StringName(spec.get("boss_module_state", &""))
	enemy.pattern = &""
	enemy.last_pattern = &""
	enemy.pattern_timer = 0.0
	enemy.pattern_tick = 0.0
	enemy.pattern_volleys = 0
	enemy.vulnerable = 0.0
	enemy.elite_trait = &""
	enemy.armor_structure = 0.0
	enemy.guard_plate_structure = 72.0 if archetype == &"bulkhead_guard" else 0.0
	enemy.mine_armed_by_player = false
	enemy.mine_fast_cue_played = false
	enemy.splitter_spawned = false
	enemy.reset_runtime_collections()
	enemy.decision_bucket = absi(enemy.id.hash()) % ORDINARY_DECISION_BUCKET_COUNT
	return enemy


func _append_enemy(enemy: EnemyState) -> bool:
	var added := enemy_store.add(enemy)
	if added:
		collective_tactics.register_enemy(enemy)
		enemy_grid.update_actor(enemy)
	return added


func _clear_enemies() -> void:
	collective_tactics.reset()
	enemy_store.clear()
	enemy_grid.rebuild(enemies)


func _flush_defeated_enemies() -> int:
	return enemy_store.flush_defeated()


func _clear_projectiles() -> void:
	projectile_store.clear()


func _rebuild_enemy_runtime_indexes() -> void:
	enemy_store.rebuild_index()
	enemy_grid.rebuild(enemies)


func _simulation_active() -> bool:
	return mode in [RunMode.PLAYING, RunMode.STAGE_TRANSITION]


func _update_encounter(delta: float) -> void:
	_refresh_elite_reservations()
	var requests := encounter_runtime.tick(
		delta,
		_active_mobile_count(),
		_active_attack_families(),
		player_position,
		_visible_world_rect(0.0),
		enemies,
		projectile_store.hostile_count()
	)
	for cue in requests["cues"]:
		_add_effect(
			&"hostile_arrival",
			Vector2(cue["anchor"]),
			Art.MUSTARD,
			float(cue.get("visual_duration", 0.9)),
			126.0
		)
		_play_sound(&"boss", 0.72)
		if int(cue["beat"]) == 0:
			_ui.notify(tr("NOTIFY_CONTACT_INBOUND"), 1.2, Art.MUSTARD)
	for spawn_spec in requests["spawns"]:
		var bounded_spec := _bounded_spawn_spec(Dictionary(spawn_spec))
		var enemy := _make_enemy(bounded_spec)
		_apply_pending_elite(enemy)
		if _append_enemy(enemy):
			_add_effect(
				&"hostile_arrival",
				Vector2(enemy.pos),
				Art.CORAL,
				0.42,
				68.0
			)


func _refresh_elite_reservations() -> void:
	var thresholds: Array = EliteTraits.thresholds(current_stage_index)
	var progress := float(stage_flow.defeats) / maxf(1.0, float(stage_flow.quota))
	while (
		_elite_threshold_cursor < thresholds.size()
		and progress >= float(thresholds[_elite_threshold_cursor])
	):
		_elite_pending += 1
		_elite_threshold_cursor += 1


func _apply_pending_elite(enemy: EnemyState) -> void:
	if (
		enemy == null
		or _elite_pending <= 0
		or not EliteTraits.eligible(enemy.archetype)
		or _live_elite_count() >= 2
	):
		return
	var elite_kind: StringName = EliteTraits.trait_for(
		current_stage_index, _elite_spawned, field_layout.seed
	)
	EliteTraits.apply(enemy, elite_kind)
	_elite_pending -= 1
	_elite_spawned += 1


func _live_elite_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.alive and not enemy.elite_trait.is_empty():
			count += 1
	return count


func _bounded_spawn_spec(spec: Dictionary) -> Dictionary:
	var archetype := StringName(spec.get("role", &"chaser"))
	var cap: int = int({
		&"spark_minelet":12,
		&"bulkhead_guard":8,
		&"splitter_barge":6,
	}.get(archetype, -1))
	if cap < 0:
		return spec
	var live_count := 0
	for enemy in enemies:
		if enemy.alive and enemy.archetype == archetype:
			live_count += 1
	if live_count < cap:
		return spec
	var substitute := spec.duplicate(true)
	substitute["role"] = &"chaser"
	return substitute


func _active_mobile_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap:
			count += 1
	return count


func _active_attack_families() -> Array[StringName]:
	var families: Array[StringName] = []
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var family := enemy.threat_kind
		if family in [&"support", &"boss"] or family in families:
			continue
		families.append(family)
	return families


func _on_deployment_selected(primary_id: StringName) -> void:
	_start_deployed_run(primary_id)


func _on_boss_practice_selected(request: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	_practice_request = request.duplicate(true)
	_start_boss_practice()


func _start_deployed_run(primary_id: StringName) -> void:
	selected_primary = primary_id
	selected_run_difficulty = RunDifficulty.HARD
	_save_persistence()
	_reset_run(false)
	selected_primary = primary_id
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_DEPLOYED"), 3.2, Rules.CYAN)
	_play_sound(&"card", 1.15)
	_set_mouse_for_mode()


func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if mode != RunMode.UPGRADE:
		return
	if not apply_upgrade(upgrade_id):
		_ui.upgrade_apply_failed(tr("UPGRADE_APPLY_FAILED"))
		return
	_resolve_reward_transaction()
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_MODULE_ONLINE") % tr(selected_upgrade_title_key), 3.0, Rules.AMBER)
	_play_sound(&"card", 1.0)
	_set_mouse_for_mode()
	_advance_reward_queue()


func _pause_run() -> void:
	if not _simulation_active():
		return
	mode_before_pause = mode
	mode = RunMode.PAUSED
	_ui.hide_stage_transition()
	var build_snapshot := _build_snapshot()
	_ui.update_hud({
		"build_snapshot":build_snapshot,
		"guidebook":_guidebook_snapshot(build_snapshot),
	})
	_ui.show_pause()
	_acquire_tree_pause()
	_set_mouse_for_mode()


func _resume_run() -> void:
	if mode != RunMode.PAUSED:
		return
	_release_tree_pause()
	mode = mode_before_pause
	_ui.show_gameplay()
	if mode == RunMode.STAGE_TRANSITION:
		_present_stage_transition_banner()
	_set_mouse_for_mode()


func _restart_stage() -> void:
	_release_tree_pause()
	var primary := selected_primary
	_reset_run(false, true, true)
	selected_primary = primary
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_STAGE_RESET"), 2.6, Rules.MUTED)
	_set_mouse_for_mode()


func _replay_stage() -> void:
	run_index += 1
	mode = RunMode.DEPLOYMENT
	_ui.show_deployment(
		selected_primary,
		String(field_layout.field_definition["name_key"])
	)
	_set_mouse_for_mode()


func _advance_stage() -> void:
	_begin_stage_transition()


func _show_garage() -> void:
	_release_tree_pause()
	mode = RunMode.GARAGE
	player_health = _player_max_health()
	_clear_projectiles()
	denied_zones.clear()
	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": persistent_clear_count,
		"relay_module_unlocked": persistent_relay_module,
		"field_module_unlocked": persistent_field_module,
		"build_summary": _run_build_summary(),
		"secondaries": secondary_runtime.equipped_families(run_build),
	})
	_set_mouse_for_mode()


func _set_mouse_for_mode() -> void:
	if _capture_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if _simulation_active() else Input.MOUSE_MODE_VISIBLE


func _acquire_tree_pause() -> void:
	var tree := get_tree()
	if tree == null:
		return
	_tree_pause_owned = true
	tree.paused = true


func _release_tree_pause() -> void:
	if not _tree_pause_owned:
		return
	var tree := get_tree()
	if tree != null:
		tree.paused = false
	_tree_pause_owned = false


func _update_player(delta: float) -> void:
	var previous_position := player_position
	lifesteal_budget = minf(6.0, lifesteal_budget + 6.0 * delta)
	player_invulnerable = maxf(0.0, player_invulnerable - delta)
	_advance_player_protection_sources(delta)
	var primary_held := Input.is_action_pressed("primary_fire")
	player_primary_weapon.tick(delta, primary_held)
	player_dash_cooldown = maxf(0.0, player_dash_cooldown - delta)
	player_emp_cooldown = maxf(0.0, player_emp_cooldown - delta)
	player_barrier_timer = maxf(0.0, player_barrier_timer - delta)
	coolant_surge_timer = maxf(0.0, coolant_surge_timer - delta)
	if player_barrier_timer <= 0.0:
		player_barrier_strength = 0.0

	if (
		is_instance_valid(_performance_scenario)
		and _performance_scenario.scenario_id == &"production_replay"
	):
		player_aim_direction = _performance_scenario.desired_aim_direction(self)
	else:
		_update_player_aim()
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length_squared() > 0.01:
		tutorial_move = true
		player_hull_direction = move_input.normalized()

	if player_dash_timer > 0.0:
		_update_dash(delta)
	else:
		var motion := move_input * _player_move_speed() * delta
		player_position = _move_actor(player_position, motion, Rules.PLAYER_RADIUS, true)
		if Input.is_action_just_pressed("dash") and player_dash_cooldown <= 0.0:
			_start_dash(move_input)

	if primary_held:
		_try_fire_primary()

	if Input.is_action_just_pressed("active_skill") and player_emp_cooldown <= 0.0 and player_emp_startup <= 0.0:
		_start_emp()

	if player_emp_startup > 0.0:
		player_emp_startup = maxf(0.0, player_emp_startup - delta)
		if player_emp_startup <= 0.0:
			_release_emp(false)

	_update_aim_target()
	_mark_visited()
	_apply_dash_collision()
	player_velocity = (player_position - previous_position) / maxf(delta, 0.0001)
	_update_secondary_weapons(delta, player_velocity)

	if tutorial_move and tutorial_aim and tutorial_fire and tutorial_dash and not tutorial_announced:
		tutorial_announced = true
		_ui.notify(tr("NOTIFY_CALIBRATION_COMPLETE"), 3.0, Rules.MOSS)


func _grant_player_protection(duration: float, source: StringName) -> void:
	var bounded_duration := maxf(0.0, duration)
	player_invulnerable = maxf(player_invulnerable, bounded_duration)
	if source != &"" and bounded_duration > 0.0:
		player_protection_sources[source] = maxf(
			float(player_protection_sources.get(source, 0.0)),
			bounded_duration
		)


func _advance_player_protection_sources(delta: float) -> void:
	for source_variant in player_protection_sources.keys():
		var source := StringName(source_variant)
		var remaining := maxf(
			0.0,
			float(player_protection_sources[source]) - maxf(0.0, delta)
		)
		if remaining <= 0.0:
			player_protection_sources.erase(source)
		else:
			player_protection_sources[source] = remaining


func _update_terrain(delta: float, previous_player_position: Vector2) -> void:
	var events := terrain_runtime.advance(
		delta, player_position, player_health, _player_max_health()
	)
	for event in events:
		match StringName(event["kind"]):
			&"heal":
				player_health = minf(
					_player_max_health(),
					player_health + float(event["amount"])
				)
			&"transit":
				player_position = Vector2(event["destination"])
				player_velocity = Vector2.ZERO
				_grant_player_protection(
					float(event["invulnerability"]),
					&"transit"
				)
				_add_effect(
					&"transit_complete",
					player_position,
					Art.MINT,
					0.34,
					96.0,
					player_hull_direction
				)
				_play_sound(&"dash", 1.18)
	var surge_damage := terrain_runtime.surge_damage_for(
		"player", player_position, &"player"
	)
	if surge_damage > 0.0:
		_damage_player(surge_damage, "Arc Surge", false, false, true)
	var wear_damage := terrain_runtime.wear_damage_for_actor(
		"player",
		previous_player_position,
		player_position,
		Rules.PLAYER_RADIUS,
		delta
	)
	if wear_damage > 0.0:
		_damage_player(wear_damage, "Wear Collapse", false, false, true)


func _update_player_aim() -> void:
	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if stick.length() > 0.32:
		player_aim_direction = stick.normalized()
		tutorial_aim = true
		return
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length() > 8.0:
		var new_direction := mouse_direction.normalized()
		if new_direction.dot(player_aim_direction) < 0.995:
			tutorial_aim = true
		player_aim_direction = new_direction


func _start_dash(move_input: Vector2) -> void:
	player_dash_direction = move_input.normalized() if move_input.length_squared() > 0.01 else player_aim_direction
	if player_dash_direction.length_squared() <= 0.01:
		player_dash_direction = player_hull_direction
	player_dash_timer = DASH_DURATION
	player_dash_cooldown = _dash_cooldown_max()
	_grant_player_protection(DASH_DURATION + 0.08, &"dash")
	player_dash_trail_timer = 0.0
	stats_dash_uses += 1
	tutorial_dash = true
	camera_shake = maxf(camera_shake, 4.0)
	_play_sound(&"dash")
	_add_effect(
		&"player_dash_start",
		player_position,
		Rules.CYAN,
		0.22,
		52.0,
		player_dash_direction
	)


func _update_dash(delta: float) -> void:
	player_dash_timer = maxf(0.0, player_dash_timer - delta)
	var before := player_position
	player_position = _move_actor(
		player_position,
		player_dash_direction * DASH_SPEED * delta,
		Rules.PLAYER_RADIUS,
		true
	)
	if run_build.has(&"phase_shear"):
		_apply_phase_shear(before, player_position)
	player_dash_trail_timer -= delta
	if player_dash_trail_timer <= 0.0:
		player_dash_trail_timer = 0.035
		if _live_effect_count(&"player_dash_afterimage") < MAX_DASH_AFTERIMAGES:
			_add_effect(
				&"player_dash_afterimage",
				before,
				Rules.CYAN,
				0.20,
				30.0,
				player_dash_direction
			)
		if applied_upgrades.has(&"ion_wake"):
			damaging_trails.append({
				"pos": before,
				"radius": 42.0,
				"time": 0.75,
				"duration": 0.75,
				"hit_ids": {},
			})
	if player_dash_timer <= 0.0:
		if run_build.has(&"coolant_wake"):
			coolant_surge_timer = 2.0
		if applied_upgrades.has(&"ram_pulse"):
			_damage_enemies_in_radius(
				player_position, 145.0, 32.0, "Ram Pulse", &"kinetic", true
			)
			_clear_hostile_projectiles(player_position, 170.0)
			_add_effect(
				&"player_ram_pulse",
				player_position,
				Rules.AMBER,
				0.38,
				170.0
			)
			_play_sound(&"emp", 1.55)


func _live_effect_count(kind: StringName) -> int:
	var count := 0
	for effect in effects:
		if StringName(effect.get("kind", &"")) == kind:
			count += 1
	return count


func _apply_phase_shear(from: Vector2, to: Vector2) -> void:
	enemy_grid.query_segment_into(from, to, Rules.PLAYER_RADIUS, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if Rules.point_segment_distance(Vector2(enemy.pos), from, to) > float(enemy.radius) + Rules.PLAYER_RADIUS:
			continue
		if not _sheared_enemy_id.is_empty():
			var previous := _find_enemy_by_id(_sheared_enemy_id)
			if previous != null:
				previous.shear_time = 0.0
		enemy.shear_time = 3.0
		_sheared_enemy_id = enemy.id
		_add_effect(
			&"player_phase_shear_hit",
			enemy.pos,
			Art.MINT,
			0.24,
			48.0,
			(to - from).normalized()
		)
		return


func _fire_primary() -> void:
	tutorial_fire = true
	player_muzzle_flash = 0.075
	_primary_shot_serial += 1
	var primary_multiplier := run_build.stat(&"primary_damage_multiplier", 1.0)
	var origin := player_position + player_aim_direction * 39.0
	var fork_level := mini(2, run_build.level_of(&"forked_muzzle"))
	var spread_step := deg_to_rad(7.0) * run_build.stat(&"primary_spread", 1.0)
	var projectile_speed := run_build.stat(&"primary_projectile_speed", PRIMARY_PROJECTILE_SPEED)
	var base_radius := run_build.stat(&"primary_radius", PRIMARY_PROJECTILE_RADIUS)
	var primary_structure := run_build.stat(&"primary_structure", 1.0)
	var projectile_range := _primary_projectile_range()
	var projectile_specs: Array[Dictionary] = [{"angle":0.0, "scale":1.0}]
	if fork_level == 1:
		var side_sign := -1.0 if _primary_shot_serial % 2 == 0 else 1.0
		projectile_specs.append({"angle":side_sign * spread_step, "scale":0.40})
	elif fork_level >= 2:
		projectile_specs.append({"angle":-spread_step, "scale":0.325})
		projectile_specs.append({"angle":spread_step, "scale":0.325})
	for spec in projectile_specs:
		var scale := float(spec["scale"])
		_spawn_player_projectile(
			origin,
			player_aim_direction.rotated(float(spec["angle"])),
			18.0 * primary_multiplier * scale,
			projectile_speed,
			run_build.level_of(&"phase_lance"),
			base_radius,
			18.0 * primary_structure * scale,
			projectile_range,
			_status_profile,
			false
		)
	_add_effect(
		&"player_primary_muzzle",
		origin,
		Art.MUSTARD,
		0.09,
		32.0,
		player_aim_direction
	)


func _try_fire_primary() -> bool:
	if not player_primary_weapon.can_fire(player_dash_timer <= 0.0):
		return false
	var interval := _primary_fire_interval()
	player_primary_weapon.consume_shot(interval)
	_fire_primary()
	return true


func _primary_fire_interval() -> float:
	var interval := maxf(PrimaryWeapon.MIN_INTERVAL, run_build.stat(&"primary_interval", PrimaryWeapon.BASE_INTERVAL))
	if coolant_surge_timer > 0.0:
		interval = maxf(PrimaryWeapon.MIN_INTERVAL, interval * 0.85)
	return interval


func _primary_projectile_range() -> float:
	var authored_range := run_build.stat(&"primary_range", PRIMARY_RANGE)
	var visible_diagonal := _visible_world_rect(0.0).size.length()
	return maxf(
		authored_range,
		visible_diagonal + PRIMARY_VISIBLE_RANGE_MARGIN
	)


func _runtime_cover_rects() -> Array[Rect2]:
	return _runtime_blockers


func _runtime_projectile_cover_rects(from: Vector2, to: Vector2, radius: float) -> Array[Rect2]:
	_projectile_cover_query.clear()
	if field_layout != null:
		_active_tactical_layout.covers_near_motion_into(
			from, to, radius, _projectile_cover_query
		)
	for wall in _runtime_structural_walls:
		_projectile_cover_query.append(wall)
	for bulkhead in _runtime_bulkheads:
		_projectile_cover_query.append(bulkhead)
	return _projectile_cover_query


func _runtime_motion_cover_rects(
	from: Vector2,
	to: Vector2,
	radius: float
) -> Array[Rect2]:
	_motion_cover_query.clear()
	if field_layout != null:
		_active_tactical_layout.covers_near_motion_into(
			from, to, radius, _motion_cover_query
		)
	var swept := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	for wall in _runtime_structural_walls:
		if swept.intersects(wall.grow(radius), true):
			_motion_cover_query.append(wall)
	for bulkhead in _runtime_bulkheads:
		if swept.intersects(bulkhead.grow(radius), true):
			_motion_cover_query.append(bulkhead)
	return _motion_cover_query


func _rebuild_runtime_blockers() -> void:
	_runtime_blockers.clear()
	if field_layout != null:
		_runtime_blockers.append_array(_active_tactical_layout.cover_rects)
	_runtime_structural_walls = terrain_runtime.structural_wall_rects()
	_runtime_blockers.append_array(_runtime_structural_walls)
	_runtime_bulkheads = terrain_runtime.live_bulkhead_rects()
	_runtime_blockers.append_array(_runtime_bulkheads)


func _runtime_first_cover_hit(from: Vector2, to: Vector2, padding: float) -> Dictionary:
	return Rules.first_cover_hit_with_extra_into(
		from,
		to,
		padding,
		current_stage_id,
		_runtime_projectile_cover_rects(from, to, padding),
		_cover_hit_receipt,
		_cover_hit_candidate
	)


func _runtime_has_line_of_sight(from: Vector2, to: Vector2, padding: float) -> bool:
	if not _runtime_cover_has_line_of_sight(from, to, padding):
		return false
	return not _segment_hits_live_crate(from, to, padding)


func _runtime_cover_has_line_of_sight(
	from: Vector2,
	to: Vector2,
	padding: float
) -> bool:
	var swept := Rect2(from, Vector2.ZERO).expand(to).grow(padding)
	for blocker in _runtime_blockers:
		if (
			swept.intersects(blocker.grow(padding), true)
			and Rules.segment_rect_intersects(from, to, blocker, padding)
		):
			return false
	return true


func _runtime_attack_path_end(
	origin: Vector2,
	direction: Vector2,
	distance: float,
	padding: float
) -> Vector2:
	var normalized := direction.normalized()
	if normalized.is_zero_approx() or distance <= 0.0:
		return origin
	var desired := origin + normalized * distance
	var cover_hit := _runtime_first_cover_hit(origin, desired, padding)
	var result := (
		Vector2(cover_hit["point"])
		if bool(cover_hit.get("hit", false))
		else desired
	)
	var crate_hit := _first_live_crate_hit(origin, result, padding)
	if crate_hit["crate"] == null:
		return result
	var hit_t := float(crate_hit["t"])
	return origin.lerp(result, hit_t) if hit_t != INF else result


func _runtime_charge_path_end(
	origin: Vector2,
	direction: Vector2,
	distance: float,
	radius: float
) -> Vector2:
	var cover_end := _runtime_attack_path_end(
		origin,
		direction,
		distance,
		radius
	)
	var path_length := origin.distance_to(cover_end)
	if path_length <= 0.001:
		return origin
	var steps := maxi(1, ceili(path_length / CHARGE_PATH_SAMPLE_STEP))
	var last_clear_t := 0.0
	for step_index in range(1, steps + 1):
		var candidate_t := float(step_index) / float(steps)
		var candidate := origin.lerp(cover_end, candidate_t)
		if Rules.is_position_walkable(candidate, radius, current_stage_id):
			last_clear_t = candidate_t
			continue
		var blocked_t := candidate_t
		for _iteration in CHARGE_PATH_BINARY_STEPS:
			var middle_t := (last_clear_t + blocked_t) * 0.5
			if Rules.is_position_walkable(
				origin.lerp(cover_end, middle_t),
				radius,
				current_stage_id
			):
				last_clear_t = middle_t
			else:
				blocked_t = middle_t
		return origin.lerp(cover_end, last_clear_t)
	return cover_end


func _spawn_player_projectile(
	origin: Vector2,
	direction: Vector2,
	damage: float,
	speed: float,
	extra_pierce: int,
	radius: float = PRIMARY_PROJECTILE_RADIUS,
	structure_damage: float = -1.0,
	projectile_range: float = PRIMARY_RANGE,
	status_profile: VehicleStatusProfile = null,
	wall_piercing: bool = false
) -> void:
	var condition_mask := AttackContract.condition_mask_for_profile(status_profile)
	var affinity := AttackContract.affinity_for_condition_mask(condition_mask)
	projectile_store.add_player({
		"pos": origin,
		"velocity": direction.normalized() * speed,
		"radius": radius,
		"damage": damage,
		"life": projectile_range / speed,
		"color": Art.attack_color(affinity, true),
		"owner": "player_primary",
		"pierce": extra_pierce,
		"bounces": 1 if run_build.has(&"ricochet_matrix") else 0,
		"homing": false,
		"target_id": "",
		"explosive": false,
		"structure_damage": damage if structure_damage < 0.0 else structure_damage,
		"reflected": false,
		"wall_piercing": wall_piercing,
		"affinity": affinity,
		"condition_mask": condition_mask,
		"reflector_lock": &"",
		"reflector_lock_time": 0.0,
		"status_profile": status_profile,
	})


func _update_secondary_weapons(delta: float, movement: Vector2) -> void:
	var secondary_result := secondary_runtime.update(
		delta,
		player_position,
		movement,
		player_hull_direction,
		run_build,
		enemies,
		_runtime_line_of_sight_callable,
		_query_enemy_radius_callable,
		_find_seeker_targets,
		player_emp_startup > 0.0,
		0.85 if persistent_field_module else 1.0
	)
	var emitted_projectiles: Array = secondary_result.get("projectiles", [])
	if not emitted_projectiles.is_empty():
		for projectile in emitted_projectiles:
			projectile_store.add_player(projectile)
		_play_sound(&"missile")
	for intent in secondary_result["damage"]:
		var target := intent.get("enemy") as EnemyState
		if target == null:
			target = _find_enemy_by_id(String(intent["enemy_id"]))
		if target != null:
			var secondary_source := String(intent["source"])
			_damage_enemy(
				target,
				float(intent["damage"]),
				secondary_source,
				&"arc" if secondary_source == "Ion Field" else &"kinetic",
				true
			)
	for effect in secondary_result["effects"]:
		var effect_position := Vector2(effect["pos"])
		var effect_target := Vector2(effect.get("target", effect_position))
		_add_effect(
			StringName(effect["event_id"]),
			effect_position,
			Art.MINT,
			0.24,
			float(effect.get("radius", 24.0)),
			(effect_target - effect_position).normalized(),
			0.0,
			1.0,
			effect_target
		)


func _find_seeker_targets(max_targets: int) -> Array[EnemyState]:
	var candidates: Array[EnemyState] = []
	enemy_grid.query_radius_into(player_position, SEEKER_RANGE, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		var distance := player_position.distance_to(enemy.pos)
		if distance > SEEKER_RANGE:
			continue
		if not _runtime_has_line_of_sight(player_position, enemy.pos, 6.0):
			continue
		var priority := 0.0
		var role := enemy.role
		if enemy.marked_time > 0.0:
			priority -= 900.0
		if applied_upgrades.has(&"hunter_firmware"):
			if role in [&"generator", &"turret", &"mine", &"boss_pylon", &"beam_sentinel", &"repair_tender", &"drone_carrier"]:
				priority -= 500.0
		elif role in [&"chaser", &"shooter", &"controller"]:
			priority -= 60.0
		enemy.target_score = priority + distance
		candidates.append(enemy)
	candidates.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		return a.target_score < b.target_score
	)
	if candidates.size() > max_targets:
		candidates.resize(max_targets)
	return candidates


func _query_enemy_radius_into(center: Vector2, radius: float, output: Array[EnemyState]) -> void:
	enemy_grid.query_radius_into(center, radius, enemies, output)
	var write_index := 0
	for enemy in output:
		if not _is_player_targetable_enemy(enemy):
			continue
		output[write_index] = enemy
		write_index += 1
	output.resize(write_index)


func _start_emp() -> void:
	player_emp_startup = EMP_STARTUP
	player_emp_cooldown = _emp_cooldown_max()
	_grant_player_protection(0.24, &"emp")
	_play_sound(&"emp_start")
	_add_effect(
		&"player_emp_charge",
		player_position,
		Art.BOSS_MAGENTA,
		EMP_STARTUP,
		_emp_radius()
	)


func _release_emp(is_aftershock: bool) -> void:
	var radius := _emp_radius() * (0.68 if is_aftershock else 1.0)
	var damage := (34.0 if is_aftershock else 62.0) * run_build.stat(&"emp_damage_multiplier", 1.0)
	_damage_enemies_in_radius(
		player_position,
		radius,
		damage,
		"EMP Aftershock" if is_aftershock else "EMP Nova",
		&"arc",
		true
	)
	_clear_hostile_projectiles(player_position, radius + 40.0)
	if not is_aftershock and run_build.has(&"static_aegis"):
		var barrier_strength := 24.0 if run_build.level_of(&"static_aegis") >= 2 else 18.0
		player_barrier_strength = maxf(player_barrier_strength, barrier_strength)
		player_barrier_timer = maxf(player_barrier_timer, 10.0)
	enemy_grid.query_radius_into(player_position, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if Vector2(enemy.pos).distance_to(player_position) <= radius:
			var stun_duration := 1.25 if is_aftershock else 2.1
			if not is_aftershock and run_build.has(&"relay_overload") and SpecialistRuntime.is_support_or_installation(StringName(enemy.role)):
				stun_duration += 2.5 * run_build.level_of(&"relay_overload")
			enemy.stun = maxf(float(enemy.stun), stun_duration)
	_add_effect(
		&"player_emp_aftershock" if is_aftershock else &"player_emp_release",
		player_position,
		Art.BOSS_MAGENTA,
		0.55,
		radius
	)
	camera_shake = maxf(camera_shake, 11.0 if not is_aftershock else 6.0)
	_play_sound(&"emp", 1.2 if is_aftershock else 1.0)
	if not is_aftershock and applied_upgrades.has(&"emp_aftershock"):
		effects.append({
			"kind": "scheduled_aftershock",
			"pos": player_position,
			"color": Art.BOSS_MAGENTA,
			"time": 0.72,
			"duration": 0.72,
			"radius": radius * 0.68,
			"dir": Vector2.ZERO,
		})


func _emp_cooldown_max() -> float:
	var base := EMP_COOLDOWN - (1.5 if persistent_relay_module else 0.0)
	return maxf(EMP_COOLDOWN * 0.70, run_build.stat(&"emp_cooldown_multiplier", base))


func _emp_radius() -> float:
	return run_build.stat(&"emp_radius_multiplier", EMP_RADIUS)


func _player_move_speed() -> float:
	return run_build.stat(&"move_speed_multiplier", PLAYER_BASE_SPEED)


func _dash_cooldown_max() -> float:
	return maxf(DASH_COOLDOWN * 0.75, run_build.stat(&"dash_cooldown_multiplier", DASH_COOLDOWN))


func _player_max_health() -> float:
	return run_build.stat(&"max_health_bonus", PLAYER_MAX_HEALTH)


func _sync_cycle_upgrades() -> void:
	for upgrade_id in cycle_runtime.sync_build(run_build).keys():
		_activate_cycle(StringName(upgrade_id))


func _update_cycle_upgrades(delta: float) -> void:
	for upgrade_id in cycle_runtime.advance(delta):
		_activate_cycle(upgrade_id)


func _activate_cycle(upgrade_id: StringName) -> void:
	if upgrade_id != &"aegis_cycle":
		return
	var level := cycle_runtime.level(upgrade_id)
	player_barrier_strength = maxf(player_barrier_strength, 28.0 if level >= 2 else 20.0)
	player_barrier_timer = maxf(player_barrier_timer, 6.0 if level >= 2 else 5.0)
	_clear_hostile_projectiles(player_position, 86.0)
	_add_effect(
		&"player_barrier_activate",
		player_position,
		Art.MINT,
		0.22,
		74.0
	)


func _update_pickups(motion_start: Vector2, motion_end: Vector2) -> void:
	for pickup in pickups:
		if not bool(pickup["active"]):
			continue
		pickup["pulse"] = float(pickup["pulse"]) + 0.06
		var pickup_position := Vector2(pickup["pos"])
		var crossed_during_motion := PickupContact.should_collect(
			true,
			motion_start,
			motion_end,
			Rules.PLAYER_RADIUS,
			pickup_position,
			PICKUP_BODY_RADIUS
		)
		var touches_current_endpoint := PickupContact.should_collect(
			true,
			player_position,
			player_position,
			Rules.PLAYER_RADIUS,
			pickup_position,
			PICKUP_BODY_RADIUS
		)
		if crossed_during_motion or touches_current_endpoint:
			_collect_pickup(pickup)


func _collect_pickup(pickup: Dictionary) -> void:
	if not bool(pickup["active"]):
		return
	pickup["active"] = false
	var kind := StringName(pickup["kind"])
	match kind:
		&"repair":
			_discover_guide(&"object_repair")
			var before := player_health
			player_health = minf(_player_max_health(), player_health + float(pickup.get("heal_amount", 35.0)))
			_ui.notify(tr("NOTIFY_REPAIR") % roundi(player_health - before), 2.0, Rules.MOSS)
		&"experience_recall":
			_discover_guide(&"object_recall")
			experience_recall_timer = 0.65
			_ui.notify(tr("NOTIFY_EXPERIENCE_RECALL"), 2.0, Rules.CYAN)
	var pickup_event := (
		&"pickup_repair"
		if kind == &"repair"
		else &"pickup_experience"
		if kind == &"experience_recall"
		else &"pickup_reward"
	)
	_add_effect(
		pickup_event,
		Vector2(pickup["pos"]),
		_pickup_color(kind),
		0.40,
		65.0,
		(player_position - Vector2(pickup["pos"])).normalized(),
		0.0,
		1.0,
		player_position
	)
	_play_sound(&"pickup")


func _pickup_color(kind: StringName) -> Color:
	match kind:
		&"repair":
			return Art.MINT
		&"experience_recall":
			return Art.COBALT_ENERGY
	return Art.IVORY_BRIGHT


func _update_experience(delta: float) -> void:
	var attraction_radius := 92.0 + run_build.stat(&"pickup_radius_bonus", 0.0)
	var result := experience_runtime.advance(
		delta,
		player_position,
		attraction_radius,
		experience_recall_timer
	)
	experience_recall_timer = maxf(0.0, experience_recall_timer - delta)
	if int(result["experience"]) > 0:
		_discover_guide(&"object_experience")
		_play_sound(&"pickup", 1.22)
	for source in result["reward_sources"]:
		reward_runtime.enqueue(StringName(source))
	if int(result["levels"]) > 0:
		_ui.notify(tr("NOTIFY_LEVEL_UP"), 1.8, Art.MUSTARD)
	_advance_reward_queue()


func _update_enemies(delta: float) -> void:
	var performance_active := _performance_detail_sample_active
	var section_started := Time.get_ticks_usec() if performance_active else 0
	var decision_bucket := _enemy_decision_bucket
	_enemy_decision_bucket = (_enemy_decision_bucket + 1) % ORDINARY_DECISION_BUCKET_COUNT
	_enemy_update_schedule.rebuild(
		enemies, delta, player_position, FAR_SIMULATION_DISTANCE_SQUARED,
		decision_bucket, _simulation_lod_bucket, _far_enemy_simulation_bucket
	)
	var active_capped := _enemy_update_schedule.active_cap_count
	if _enforce_active_enemy_cap(active_capped):
		_enemy_update_schedule.rebuild(
			enemies, 0.0, player_position, FAR_SIMULATION_DISTANCE_SQUARED,
			decision_bucket, _simulation_lod_bucket, _far_enemy_simulation_bucket
		)
		active_capped = _enemy_update_schedule.active_cap_count
	if performance_active:
		_performance_enemy_sections["budget_scan"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()

	for enemy in _enemy_update_schedule.alive:
		var flash := enemy.flash
		if flash > 0.0:
			enemy.flash = maxf(0.0, flash - delta)
		var stun := enemy.stun
		if stun > 0.0:
			enemy.stun = maxf(0.0, stun - delta)
		var ram_cooldown := enemy.ram_cooldown
		if ram_cooldown > 0.0:
			enemy.ram_cooldown = maxf(0.0, ram_cooldown - delta)
		var vulnerable := enemy.vulnerable
		if vulnerable > 0.0:
			enemy.vulnerable = maxf(0.0, vulnerable - delta)
		var marked_time := enemy.marked_time
		if marked_time > 0.0:
			enemy.marked_time = maxf(0.0, marked_time - delta)
		var shear_time := enemy.shear_time
		if shear_time > 0.0:
			enemy.shear_time = maxf(0.0, shear_time - delta)
		var health_visible_timer := enemy.health_visible_timer
		if health_visible_timer > 0.0:
			enemy.health_visible_timer = maxf(0.0, health_visible_timer - delta)
		if not enemy.active:
			var activated := _update_enemy_activation(
				enemy,
				encounter_runtime.available_active_slots(active_capped) > 0
			)
			if activated and enemy.counts_active_cap:
				active_capped += 1
			if activated:
				enemy_grid.update_actor(enemy)
	if performance_active:
		_performance_enemy_sections["status_activation"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()

	var tactic_events := collective_tactics.advance(
		delta,
		player_position,
		_visible_world_rect(0.0),
		_enemy_find_callable
	)
	_handle_collective_tactic_events(tactic_events)

	if not _enemy_coordination_initialized:
		_shielded_enemy_ids = _build_enemy_shield_assignments()
		for enemy in _enemy_update_schedule.active:
			_apply_enemy_shield(enemy, _shielded_enemy_ids)
		_pending_shielded_enemy_ids.clear()
		_append_enemy_shield_assignments(
			_pending_shielded_enemy_ids,
			decision_bucket
		)
		_enemy_coordination_initialized = true
	else:
		if decision_bucket == 0:
			_refresh_enemy_shield_supports()
			_pending_shielded_enemy_ids.clear()
		_append_enemy_shield_assignments(
			_pending_shielded_enemy_ids,
			decision_bucket
		)
		if decision_bucket == ORDINARY_DECISION_BUCKET_COUNT - 1:
			var previous_assignments := _shielded_enemy_ids
			_shielded_enemy_ids = _pending_shielded_enemy_ids
			_pending_shielded_enemy_ids = previous_assignments
			_pending_shielded_enemy_ids.clear()
			for enemy in _enemy_update_schedule.active:
				_apply_enemy_shield(enemy, _shielded_enemy_ids)
	if performance_active:
		_performance_enemy_sections["coordination"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	var arc_surge_active := terrain_runtime.has_active_arc_surge()
	for enemy in _enemy_update_schedule.active:
		if arc_surge_active:
			var terrain_damage := terrain_runtime.surge_damage_for(
				enemy.id,
				enemy.pos,
				&"boss" if enemy.role == &"stage_boss" else &"ordinary"
			)
			if terrain_damage > 0.0:
				_damage_enemy(enemy, terrain_damage, "Arc Surge", &"arc", false)
				if not enemy.alive:
					continue
		if not enemy.statuses.is_empty():
			var status_damage := StatusRuntime.tick(enemy, delta)
			if float(status_damage["burn"]) > 0.0:
				_damage_enemy(enemy, float(status_damage["burn"]), "status", &"thermal", true)
			if enemy.alive and float(status_damage["poison"]) > 0.0:
				_damage_enemy(enemy, float(status_damage["poison"]), "status", &"toxin", true)
				if not enemy.alive:
					continue
		var role := enemy.role
		if role == &"stage_boss":
			_update_stage_boss(enemy, delta)
			enemy_grid.update_actor(enemy)
			continue
		if role == &"generator":
			_update_generator(enemy, delta)
			continue
		if role == &"boss_pylon":
			continue
		if enemy.stun > 0.0:
			enemy.velocity = Vector2.ZERO
	if performance_active:
		_performance_enemy_sections["active_states"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	for enemy in _enemy_update_schedule.critical:
		_update_scheduled_ordinary_enemy(enemy, delta)
	for enemy in _enemy_update_schedule.ordinary_due:
		_update_scheduled_ordinary_enemy(enemy)
	if performance_active:
		_performance_enemy_sections["scheduled_ordinary"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	for enemy in _enemy_update_schedule.active:
		if not enemy.alive:
			continue
		var previous_position := _enemy_update_schedule.motion_start(enemy)
		if (
			previous_position == enemy.pos
			and not terrain_runtime.is_wear_actor_tracked(enemy.id)
		):
			continue
		var wear_damage := terrain_runtime.wear_damage_for_actor(
			enemy.id,
			previous_position,
			enemy.pos,
			enemy.radius,
			delta
		)
		if wear_damage > 0.0:
			_damage_enemy(enemy, wear_damage, "Wear Collapse", &"kinetic", false, true)
	if performance_active:
		_performance_enemy_sections["wear_terrain"] = _elapsed_ms(section_started)


func _update_scheduled_ordinary_enemy(
	enemy: EnemyState,
	critical_delta: float = -1.0
) -> void:
	if not enemy.alive or not enemy.active or enemy.stun > 0.0:
		return
	var motion_delta := (
		critical_delta
		if critical_delta >= 0.0
		else _enemy_update_schedule.motion_delta(enemy)
	)
	if motion_delta <= 0.0:
		return
	var previous_position := enemy.pos
	var previous_alive := enemy.alive
	var previous_active := enemy.active
	var decision_due := _enemy_update_schedule.decision_due(enemy)
	var can_commit := (
		decision_due
		and _enemy_update_schedule.can_commit(
			enemy,
			encounter_runtime.threat_budget(),
			encounter_runtime.ranged_commit_cap(),
			encounter_runtime.denial_commit_cap()
		)
	)
	if _update_ordinary_enemy(
		enemy, motion_delta, can_commit, decision_due, motion_delta
	):
		_enemy_update_schedule.note_commit(enemy)
	# The spatial grid is already correct when a scheduled tick only advances
	# timers or attack state. Re-index only after a position/occupancy change;
	# collision truth and the next exact query remain unchanged.
	if (
		enemy.pos != previous_position
		or enemy.alive != previous_alive
		or enemy.active != previous_active
	):
		enemy_grid.update_actor(enemy)


func _enforce_active_enemy_cap(known_active_count: int = -1) -> bool:
	var active_count := known_active_count
	if active_count < 0:
		active_count = 0
		for enemy in enemies:
			if enemy.alive and enemy.active and enemy.counts_active_cap:
				active_count += 1
	var cap := encounter_runtime.active_cap()
	if active_count <= cap:
		return false
	var active_mobile: Array[EnemyState] = []
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap:
			active_mobile.append(enemy)
	active_mobile.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		var a_committed := a.phase in [&"startup", &"active"]
		var b_committed := b.phase in [&"startup", &"active"]
		if a_committed != b_committed:
			return a_committed
		return player_position.distance_squared_to(a.pos) < player_position.distance_squared_to(b.pos)
	)
	for index in range(cap, active_mobile.size()):
		var enemy := active_mobile[index]
		enemy.active = false
		enemy.velocity = Vector2.ZERO
		enemy.phase = &"move"
		enemy_grid.update_actor(enemy)
	return true


func _update_enemy_activation(enemy: EnemyState, capacity_available: bool) -> bool:
	if enemy.active:
		return false
	if not capacity_available and enemy.counts_active_cap:
		return false
	enemy.active = true
	return true


func _build_enemy_shield_assignments() -> Dictionary:
	var shielded_ids := {}
	_refresh_enemy_shield_supports()
	for bucket in ORDINARY_DECISION_BUCKET_COUNT:
		_append_enemy_shield_assignments(shielded_ids, bucket)
	return shielded_ids


func _refresh_enemy_shield_supports() -> void:
	_shield_supports.clear()
	_shield_supports.assign(_enemy_update_schedule.supports)


func _append_enemy_shield_assignments(
	shielded_ids: Dictionary,
	support_bucket: int
) -> void:
	for support in _shield_supports:
		if not support.alive or not support.active:
			continue
		if posmod(
			support.runtime_slot,
			ORDINARY_DECISION_BUCKET_COUNT
		) != support_bucket:
			continue
		var support_position := support.pos
		var support_radius := 390.0 if support.role == &"generator" else 300.0
		enemy_grid.query_radius_into(
			support_position,
			support_radius,
			enemies,
			_support_query_buffer
		)
		if support.role == &"generator":
			for candidate in _support_query_buffer:
				var candidate_role := candidate.role
				if candidate != support and candidate_role not in [&"generator", &"shield_escort", &"stage_boss", &"boss_pylon"] and support_position.distance_squared_to(candidate.pos) <= 390.0 * 390.0:
					shielded_ids[candidate.id] = true
			continue
		var closest_id := ""
		var closest_distance_squared := 300.0 * 300.0
		for candidate in _support_query_buffer:
			var candidate_role := candidate.role
			if candidate == support or candidate_role in [&"generator", &"shield_escort", &"stage_boss", &"boss_pylon"]:
				continue
			var distance_squared := support_position.distance_squared_to(candidate.pos)
			if distance_squared <= closest_distance_squared:
				closest_distance_squared = distance_squared
				closest_id = candidate.id
		if not closest_id.is_empty():
			shielded_ids[closest_id] = true


func _apply_enemy_shield(enemy: EnemyState, shielded_ids: Dictionary) -> void:
	var tactic_shield := (
		enemy.collective_mode in [&"shield", &"support", &"escort"]
		and enemy.collective_phase in [&"lock", &"execute"]
	)
	var shielded := bool(shielded_ids.get(enemy.id, false)) or tactic_shield
	if enemy.shielded != shielded:
		enemy.shielded = shielded


func _update_enemy_shield(enemy: EnemyState) -> void:
	# Compatibility path for deterministic single-enemy contract checks.
	_apply_enemy_shield(enemy, _build_enemy_shield_assignments())


func _update_generator(enemy: EnemyState, delta: float) -> void:
	enemy.support_tick -= delta
	if enemy.support_tick > 0.0:
		return
	enemy.support_tick = 0.75
	enemy_grid.query_radius_into(
		enemy.pos,
		390.0,
		enemies,
		_support_query_buffer
	)
	for target in _support_query_buffer:
		if target == enemy:
			continue
		if target.pos.distance_to(enemy.pos) <= 390.0:
			target.health = minf(target.max_health, target.health + 4.0)
	_add_effect(&"support_heal", enemy.pos, Rules.CYAN, 0.28, 105.0)


func _update_repair_tender(enemy: EnemyState, delta: float, refresh_target: bool) -> void:
	if refresh_target:
		enemy_grid.query_radius_into(
			enemy.pos,
			SpecialistRuntime.REPAIR_RANGE,
			enemies,
			_support_query_buffer
		)
		enemy.repair_target_id = SpecialistRuntime.repair_target_id(
			enemy,
			_support_query_buffer,
			current_stage_id,
			false,
			_runtime_cover_rects()
		)
	var target_id := enemy.repair_target_id
	if target_id.is_empty():
		return
	var target := _find_enemy_by_id(target_id)
	if target == null:
		enemy.repair_target_id = ""
		return
	target.health = minf(target.max_health, target.health + SpecialistRuntime.REPAIR_PER_SECOND * delta)
	enemy.support_tick = maxf(0.0, enemy.support_tick - delta)
	if enemy.support_tick <= 0.0:
		enemy.support_tick = 0.32
		_add_effect(&"support_heal", target.pos, Art.MINT, 0.24, 46.0)


func _spawn_carrier_child(carrier: EnemyState) -> void:
	if (
		encounter_runtime.available_active_slots(_active_mobile_count()) <= 0
		or
		_enemy_update_schedule.carrier_child_count(carrier.id)
		>= SpecialistRuntime.CARRIER_CHILD_CAP
		or (
			carrier.role == &"stage_boss"
			and _live_boss_add_count()
				>= BossExamCatalog.MAX_LIVE_ADDS
		)
	):
		return
	carrier.child_serial += 1
	var serial := carrier.child_serial
	var offset := Vector2.RIGHT.rotated(TAU * float(serial % 6) / 6.0) * 58.0
	var spawn_position := _move_actor(carrier.pos, offset, 12.0, false)
	var child := _make_enemy({
		"id":"%s_child_%02d" % [carrier.id, serial],
		"role":&"scrap_drone",
		"pos":spawn_position,
		"active":true,
		"carrier_id":carrier.id,
		"squad_id":"%s_children" % carrier.id,
		"group_id":carrier.group_id,
		"leash_rect":carrier.leash_rect,
	})
	if _append_enemy(child):
		_enemy_update_schedule.note_carrier_child(carrier.id)
		_add_effect(
			&"hostile_summon_arrival",
			spawn_position,
			Art.CORAL,
			0.32,
			44.0
		)


func _update_ordinary_enemy(
	enemy: EnemyState,
	delta: float,
	can_commit: bool,
	decision_due: bool = true,
	motion_delta: float = -1.0
) -> bool:
	if motion_delta < 0.0:
		motion_delta = delta
	if _update_collective_enemy(enemy, motion_delta):
		return false
	var leash := enemy.leash_rect
	if leash.has_area() and not leash.has_point(player_position):
		enemy.phase = &"move"
		enemy.attack_cooldown = maxf(enemy.attack_cooldown, 0.35)
		var to_home := enemy.home - enemy.pos
		if to_home.length() <= 18.0:
			enemy.pos = enemy.home
			enemy.active = false
		else:
			_move_enemy_with_recovery(enemy, to_home.normalized() * enemy.speed, motion_delta)
		return false
	if enemy.role == &"repair_tender":
		_update_repair_tender(enemy, delta, decision_due)
		_move_enemy_role(enemy, motion_delta, false, decision_due)
		return false
	if enemy.role == &"mine":
		_update_mine(enemy, delta, motion_delta, decision_due)
		return false
	if enemy.role == &"interceptor_tower":
		enemy.intercept_recharge = maxf(0.0, enemy.intercept_recharge - delta)
		if enemy.intercept_charges < 3 and enemy.intercept_recharge <= 0.0:
			enemy.intercept_charges += 1
			enemy.intercept_recharge = 4.0
	enemy.attack_cooldown = maxf(0.0, enemy.attack_cooldown - delta * StatusRuntime.speed_multiplier(enemy))
	if enemy.role in [&"bulkhead_guard", &"splitter_barge"]:
		_move_enemy_role(enemy, motion_delta, false, decision_due)
		if (
			enemy.attack_cooldown <= 0.0
			and enemy.pos.distance_to(player_position)
				<= enemy.radius + Rules.PLAYER_RADIUS + 12.0
		):
			_damage_player(
				_enemy_contact_damage(enemy, 12.0), "Enemy hull impact", true
			)
			enemy.attack_cooldown = 0.8
		return false
	var phase := enemy.phase
	if phase == &"interrupted_recovery":
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		enemy.velocity = Vector2.ZERO
		if enemy.phase_time <= 0.0:
			enemy.phase = &"move"
			enemy.attack_cooldown = _enemy_recovery_cooldown(enemy)
		return false
	if phase == &"startup":
		if enemy.role == &"artillery_spotter" and not _runtime_has_line_of_sight(enemy.pos, player_position, 5.0):
			enemy.phase = &"recovery"
			enemy.phase_time = 0.65
			return false
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		AttackTelegraphs.update_ordinary_readiness(enemy)
		if enemy.phase_time <= 0.0:
			_begin_enemy_active(enemy)
		return false
	if phase == &"active":
		_update_enemy_active(enemy, delta)
		return false
	if phase == &"recovery":
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		_move_enemy_role(enemy, motion_delta, true, decision_due)
		if enemy.phase_time <= 0.0:
			enemy.phase = &"move"
			enemy.attack_cooldown = _enemy_recovery_cooldown(enemy)
		return false

	_move_enemy_role(enemy, motion_delta, false, decision_due)
	if not decision_due or not can_commit or enemy.attack_cooldown > 0.0:
		return false
	if _enemy_can_attack(enemy):
		_start_enemy_attack(enemy)
		return true
	return false


func _update_collective_enemy(
	enemy: EnemyState,
	delta: float
) -> bool:
	match enemy.collective_phase:
		&"gather":
			var to_slot := enemy.collective_target - enemy.pos
			if to_slot.length_squared() > 4.0:
				_move_enemy_with_recovery(
					enemy,
					to_slot.normalized() * enemy.speed,
					delta
				)
			else:
				enemy.velocity = Vector2.ZERO
			return true
		&"lock":
			enemy.velocity = Vector2.ZERO
			return true
		&"execute":
			if enemy.collective_mode in [&"charge", &"fuse"]:
				var before := enemy.pos
				var requested := (
					enemy.collective_direction
					* enemy.speed
					* enemy.collective_speed_multiplier
					* delta
				)
				var after := _runtime_charge_path_end(
					before,
					enemy.collective_direction,
					requested.length(),
					enemy.radius
				)
				enemy.pos = after
				enemy.velocity = (
					(after - before) / maxf(delta, 0.0001)
				)
				if before.distance_to(after) + 1.0 < requested.length():
					collective_tactics.break_squad(
						enemy.squad_id,
						&"cover_collision"
					)
				elif (
					not enemy.hit_committed
					and player_position.distance_to(after)
						<= enemy.radius + Rules.PLAYER_RADIUS + 10.0
				):
					enemy.hit_committed = true
					_damage_player(
						_enemy_contact_damage(enemy, 12.0),
						"Collective charge",
						true
					)
			else:
				var to_slot := enemy.collective_target - enemy.pos
				if to_slot.length_squared() > 4.0:
					_move_enemy_with_recovery(
						enemy,
						to_slot.normalized()
							* enemy.speed
							* enemy.collective_speed_multiplier,
						delta
					)
				else:
					enemy.velocity = Vector2.ZERO
			return true
	return false


func _handle_collective_tactic_events(events: Array[Dictionary]) -> void:
	for event in events:
		var kind := StringName(event.get("kind", &""))
		var tactic_id := StringName(event.get("tactic_id", &""))
		if kind == &"phase":
			var phase := StringName(event.get("phase", &""))
			stage_telemetry.record_tactic_event(tactic_id, phase)
			if phase == &"lock":
				_play_sound(&"boss", 0.62)
		elif kind == &"break":
			stage_telemetry.record_tactic_event(tactic_id, &"interrupted")
			_play_sound(&"impact", 0.86)


func _enemy_recovery_cooldown(enemy: EnemyState) -> float:
	var role := enemy.role
	var cooldown := 0.8
	match role:
		&"chaser":
			cooldown = 0.55
		&"shooter":
			cooldown = 0.78
		&"controller":
			cooldown = 1.15
		&"turret":
			cooldown = 1.05
		&"mine":
			cooldown = 1.8
		&"artillery_spotter":
			cooldown = 1.65
		&"interceptor_tower":
			cooldown = 1.25
		&"rammer":
			cooldown = SpecialistRuntime.RAMMER_RECOVERY
		&"drone_carrier":
			cooldown = SpecialistRuntime.CARRIER_RECOVERY
		&"beam_sentinel":
			cooldown = SpecialistRuntime.BEAM_RECOVERY
	var elite_scale := 0.85 if enemy.elite_trait == &"overclocked" else 1.0
	return cooldown * elite_scale / EncounterDirector.ENEMY_RECOVERY_RATE


func _enemy_can_attack(enemy: EnemyState) -> bool:
	var role := enemy.role
	var distance := enemy.pos.distance_to(player_position)
	match role:
		&"chaser":
			return distance <= 175.0
		&"shooter":
			return distance <= 620.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 7.0)
		&"controller":
			return distance <= 590.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 4.0)
		&"turret":
			return distance <= 760.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 7.0)
		&"mine":
			return distance <= 190.0
		&"artillery_spotter":
			return distance <= 880.0 and distance >= 250.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 5.0)
		&"interceptor_tower":
			return distance <= 700.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 7.0)
		&"rammer":
			return distance <= 640.0 and distance >= 130.0 and _runtime_has_line_of_sight(enemy.pos, player_position, 12.0)
		&"drone_carrier":
			return (
				distance <= 760.0
				and _enemy_update_schedule.carrier_child_count(enemy.id)
					< SpecialistRuntime.CARRIER_CHILD_CAP
			)
		&"beam_sentinel":
			return distance <= SpecialistRuntime.BEAM_RANGE and _runtime_has_line_of_sight(enemy.pos, player_position, 7.0)
	return false


func _start_enemy_attack(enemy: EnemyState) -> void:
	var role := enemy.role
	enemy.phase = &"startup"
	enemy.hit_committed = false
	enemy.committed_dir = (player_position - enemy.pos).normalized()
	enemy.committed_target = player_position
	var attack := AttackContract.ordinary_attack(role)
	if not attack.is_empty():
		enemy.phase_time = float(attack["startup"])
	elif role == &"rammer":
		enemy.phase_time = SpecialistRuntime.RAMMER_STARTUP
	elif role == &"beam_sentinel":
		enemy.phase_time = SpecialistRuntime.BEAM_STARTUP
	AttackTelegraphs.refresh_ordinary(
		enemy,
		_runtime_attack_path_callable,
		_runtime_charge_path_callable
	)


func _begin_enemy_active(enemy: EnemyState) -> void:
	var role := enemy.role
	enemy.phase = &"active"
	match role:
		&"chaser":
			enemy.phase_time = float(AttackContract.ORDINARY_ATTACKS[role]["active"])
		&"shooter":
			var shooter_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(shooter_attack["origin_offset"]),
				enemy.committed_dir,
				float(shooter_attack["damage"]),
				float(shooter_attack["speed"]),
				"Mobile shooter bolt",
				StringName(shooter_attack["affinity"]),
				false,
				false,
				AttackContract.threat_tier_for(enemy.role, enemy.elite_trait)
			)
			enemy.phase = &"recovery"
			enemy.phase_time = 0.72
		&"controller":
			var controller_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			denied_zones.append({
				"pos": enemy.committed_target,
				"radius": float(controller_attack["radius"]),
				"warning": 0.0,
				"duration": 2.15,
				"tick": 0.0,
				"damage": float(controller_attack["damage"]),
				"source": "Controller flood zone",
				"affinity": StringName(controller_attack["affinity"]),
			})
			enemy.phase = &"recovery"
			enemy.phase_time = 0.88
		&"turret":
			enemy.burst_left = 3
			enemy.burst_timer = 0.0
			enemy.phase_time = 0.55
		&"mine":
			var mine_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			enemy.phase_time = 0.15
			var mine_distance := player_position.distance_to(enemy.pos)
			var mine_damage := AttackContract.radial_damage(
				float(mine_attack["damage"]),
				mine_distance,
				float(mine_attack["radius"])
			)
			if mine_damage > 0.0:
				_damage_player(mine_damage, "Arc proximity burst", true)
			_add_effect(
				&"enemy_mine_detonation",
				enemy.pos,
				Art.attack_color(StringName(mine_attack["affinity"])),
				0.36,
				float(mine_attack["radius"])
			)
		&"artillery_spotter":
			var artillery_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			denied_zones.append({
				"pos": enemy.committed_target, "radius": float(artillery_attack["radius"]),
				"warning": 0.0,
				"duration": 1.35, "tick": 0.0,
				"damage": float(artillery_attack["damage"]),
				"source": "Artillery impact",
				"affinity": StringName(artillery_attack["affinity"]),
			})
			enemy.phase = &"recovery"
			enemy.phase_time = 1.05
		&"interceptor_tower":
			var interceptor_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(interceptor_attack["origin_offset"]),
				enemy.committed_dir,
				float(interceptor_attack["damage"]),
				float(interceptor_attack["speed"]),
				"Interceptor bolt",
				StringName(interceptor_attack["affinity"]),
				false,
				false,
				AttackContract.threat_tier_for(enemy.role, enemy.elite_trait)
			)
			enemy.phase = &"recovery"
			enemy.phase_time = 0.9
		&"rammer":
			enemy.phase_time = SpecialistRuntime.RAMMER_ACTIVE
		&"drone_carrier":
			enemy.burst_left = mini(
				3,
				SpecialistRuntime.CARRIER_CHILD_CAP
					- _enemy_update_schedule.carrier_child_count(enemy.id)
			)
			enemy.burst_timer = 0.0
			enemy.phase_time = 2.2
		&"beam_sentinel":
			enemy.phase_time = SpecialistRuntime.BEAM_ACTIVE
			enemy.hit_committed = false
			enemy.beam_end = _runtime_attack_path_end(
				enemy.pos,
				enemy.committed_dir,
				SpecialistRuntime.BEAM_RANGE,
				SpecialistRuntime.BEAM_COVER_PADDING
			)


func _update_enemy_active(enemy: EnemyState, delta: float) -> void:
	var role := enemy.role
	enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
	match role:
		&"chaser":
			var chaser_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			var before := enemy.pos
			enemy.pos = _runtime_charge_path_end(
				before,
				enemy.committed_dir,
				float(chaser_attack["speed"])
					* EncounterDirector.ENEMY_SPEED_MULTIPLIER
					* delta,
				enemy.radius
			)
			if (
				not enemy.hit_committed
				and player_position.distance_to(enemy.pos)
					<= AttackContract.contact_danger_half_width(
						enemy.radius,
						float(chaser_attack["contact_padding"])
					)
			):
				enemy.hit_committed = true
				_damage_player(
					_enemy_contact_damage(enemy, float(chaser_attack["damage"])),
					"Rivet Chaser lunge",
					true
				)
			if enemy.phase_time <= 0.0:
				enemy.phase = &"recovery"
				enemy.phase_time = 0.52
		&"turret":
			var turret_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			enemy.burst_timer -= delta
			if enemy.burst_left > 0 and enemy.burst_timer <= 0.0:
				enemy.burst_timer = 0.14
				enemy.burst_left -= 1
				var direction := enemy.committed_dir
				_spawn_hostile_projectile(
					enemy.pos + direction * float(turret_attack["origin_offset"]),
					direction,
					float(turret_attack["damage"]),
					float(turret_attack["speed"]),
					"Foundry turret burst",
					StringName(turret_attack["affinity"]),
					false,
					false,
					AttackContract.threat_tier_for(enemy.role, enemy.elite_trait)
				)
			if enemy.burst_left <= 0:
				enemy.phase = &"recovery"
				enemy.phase_time = 0.95
		&"mine":
			if enemy.phase_time <= 0.0:
				enemy.phase = &"recovery"
				enemy.phase_time = 1.2
		&"rammer":
			var before := enemy.pos
			var requested := enemy.committed_dir * SpecialistRuntime.RAMMER_SPEED * delta
			var after := _runtime_charge_path_end(
				before,
				enemy.committed_dir,
				requested.length(),
				enemy.radius
			)
			enemy.pos = after
			var struck_cover := before.distance_to(after) + 1.0 < requested.length()
			if (
				not enemy.hit_committed
				and player_position.distance_to(after)
					<= AttackContract.contact_danger_half_width(
						enemy.radius,
						SpecialistRuntime.RAMMER_CONTACT_PADDING
					)
			):
				enemy.hit_committed = true
				_damage_player(
					_enemy_contact_damage(enemy, SpecialistRuntime.RAMMER_DAMAGE),
					"Rammer charge",
					true
				)
			if struck_cover or enemy.phase_time <= 0.0:
				enemy.phase = &"recovery"
				enemy.phase_time = SpecialistRuntime.RAMMER_RECOVERY
				enemy.vulnerable = SpecialistRuntime.RAMMER_RECOVERY
		&"drone_carrier":
			enemy.burst_timer -= delta
			if enemy.burst_left > 0 and enemy.burst_timer <= 0.0:
				enemy.burst_timer = SpecialistRuntime.CARRIER_RELEASE_SPACING
				enemy.burst_left -= 1
				_spawn_carrier_child(enemy)
			if enemy.burst_left <= 0:
				enemy.phase = &"recovery"
				enemy.phase_time = SpecialistRuntime.CARRIER_RECOVERY
		&"beam_sentinel":
			var beam_end := enemy.beam_end
			if not enemy.hit_committed and Rules.point_segment_distance(player_position, enemy.pos, beam_end) <= Rules.PLAYER_RADIUS + SpecialistRuntime.BEAM_WIDTH * 0.5:
				enemy.hit_committed = true
				_damage_player(SpecialistRuntime.BEAM_DAMAGE, "Beam Sentinel sweep", true)
			if enemy.phase_time <= 0.0:
				enemy.phase = &"recovery"
				enemy.phase_time = SpecialistRuntime.BEAM_RECOVERY
		_:
			enemy.phase = &"recovery"
			enemy.phase_time = 0.6

func _move_enemy_role(enemy: EnemyState, delta: float, recovering: bool, decision_due: bool = true) -> void:
	var role := enemy.role
	if (
		role in [&"turret", &"interceptor_tower", &"beam_sentinel", &"generator", &"boss_pylon"]
		or (role == &"mine" and enemy.archetype != &"spark_minelet")
	):
		return
	if decision_due or enemy.desired_velocity.is_zero_approx():
		var refresh_overlap := (
			decision_due
			and (
				enemy.runtime_slot < 0
				or posmod(enemy.runtime_slot + _enemy_decision_bucket, 2) == 0
			)
		)
		enemy.desired_velocity = _desired_enemy_velocity(
			enemy, recovering, refresh_overlap
		)
	_move_enemy_with_recovery(enemy, enemy.desired_velocity, delta)


func _desired_enemy_velocity(
	enemy: EnemyState,
	recovering: bool,
	refresh_overlap: bool = true
) -> Vector2:
	var role := enemy.role
	var position := enemy.pos
	var to_player := player_position - position
	var distance := maxf(1.0, to_player.length())
	var direction_to_player := to_player / distance
	var desired := Vector2.ZERO
	match role:
		&"chaser":
			desired = direction_to_player
			if recovering:
				desired = -direction_to_player.rotated(enemy.strafe_sign * 0.35)
		&"shooter":
			if distance < 330.0:
				desired = -direction_to_player
			elif distance > 500.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(enemy.strafe_sign * PI * 0.5)
		&"controller":
			if distance < 390.0:
				desired = -direction_to_player
			elif distance > 540.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(enemy.strafe_sign * PI * 0.5)
		&"shield_escort":
			if distance < 300.0:
				desired = -direction_to_player
			elif distance > 470.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(enemy.strafe_sign * PI * 0.5)
		&"artillery_spotter":
			if distance < 520.0:
				desired = -direction_to_player
			elif distance > 760.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(enemy.strafe_sign * PI * 0.5)
		&"rammer":
			desired = direction_to_player if not recovering else -direction_to_player
		&"bulkhead_guard", &"splitter_barge":
			desired = direction_to_player
		&"mine":
			desired = direction_to_player
		&"repair_tender", &"drone_carrier":
			if distance < 430.0:
				desired = -direction_to_player
			elif distance > 620.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(enemy.strafe_sign * PI * 0.5)
	var route_direction := pursuit_field.direction_at(position, enemy.radius)
	if not route_direction.is_zero_approx() and (distance > 520.0 or not _runtime_has_line_of_sight(position, player_position, enemy.radius * 0.45)):
		desired = (route_direction * 0.86 + desired * 0.14).normalized()
	var role_velocity := desired.normalized() * enemy.speed * StatusRuntime.speed_multiplier(enemy)
	return _enemy_local_steering.adjusted_velocity(
		enemy, role_velocity, enemy_grid, enemies, refresh_overlap
	)


func _move_enemy_with_recovery(enemy: EnemyState, velocity: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	if enemy.reposition_time > 0.0:
		enemy.reposition_time = maxf(0.0, enemy.reposition_time - delta)
		velocity = enemy.reposition_dir * enemy.speed
	var before := enemy.pos
	var attempt := _move_actor(before, velocity * delta, enemy.radius, false)
	var moved_squared := before.distance_squared_to(attempt)
	var velocity_squared := velocity.length_squared()
	if moved_squared < 0.35 * 0.35 and velocity_squared > 1.0:
		var side_sign := enemy.strafe_sign
		var side := velocity.normalized().rotated(side_sign * PI * 0.5)
		attempt = _move_actor(before, side * enemy.speed * delta, enemy.radius, false)
		moved_squared = before.distance_squared_to(attempt)
	if moved_squared < 0.25 * 0.25 and velocity_squared > 1.0:
		enemy.stuck_time += delta
		if enemy.stuck_time > 0.55:
			enemy.stuck_time = 0.0
			enemy.strafe_sign = -enemy.strafe_sign
			enemy.reposition_time = 0.85
			enemy.reposition_dir = velocity.normalized().rotated(enemy.strafe_sign * PI * 0.5)
			if enemy.phase == &"startup":
				enemy.phase = &"move"
				enemy.attack_cooldown = 0.4
	else:
		enemy.stuck_time = 0.0
	enemy.pos = attempt
	enemy.velocity = (attempt - before) / maxf(delta, 0.0001)


func _update_mine(
	enemy: EnemyState,
	delta: float,
	motion_delta: float,
	decision_due: bool
) -> void:
	var mobile := enemy.archetype == &"spark_minelet"
	var trigger_radius := 160.0 if mobile else 230.0
	if enemy.phase != &"mine_armed":
		if mobile:
			_move_enemy_role(enemy, motion_delta, false, decision_due)
		if enemy.pos.distance_to(player_position) <= trigger_radius:
			if mobile and _armed_minelet_count() >= 6:
				return
			_arm_mine(enemy, 1.0 if mobile else 1.25, true)
		return
	enemy.velocity = Vector2.ZERO
	enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
	if not enemy.mine_fast_cue_played and enemy.phase_time <= (0.25 if mobile else 0.3125):
		enemy.mine_fast_cue_played = true
		_play_sound(&"impact", 1.16)
	if enemy.phase_time <= 0.0:
		_explode_mine(enemy)


func _armed_minelet_count() -> int:
	var count := 0
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.archetype == &"spark_minelet"
			and enemy.phase == &"mine_armed"
		):
			count += 1
	return count


func _arm_mine(enemy: EnemyState, fuse: float, player_owned: bool) -> void:
	if enemy == null or not enemy.alive:
		return
	if enemy.phase == &"mine_armed":
		enemy.phase_time = minf(enemy.phase_time, fuse)
	else:
		enemy.phase = &"mine_armed"
		enemy.phase_time = fuse
		enemy.committed_target = enemy.pos
		enemy.velocity = Vector2.ZERO
		enemy.mine_fast_cue_played = false
		_play_sound(&"boss", 0.64)
	enemy.mine_armed_by_player = enemy.mine_armed_by_player or player_owned


func _explode_mine(enemy: EnemyState) -> void:
	if enemy == null or not enemy.alive:
		return
	var mobile := enemy.archetype == &"spark_minelet"
	var radius := 100.0 if mobile else 160.0
	var center_damage := 14.0 if mobile else 26.0
	var origin := enemy.pos
	var source := "player_spark_minelet" if mobile else "player_arc_mine"
	if (
		_runtime_has_line_of_sight(origin, player_position, 2.0)
		and origin.distance_to(player_position) <= radius
	):
		var player_damage := AttackContract.radial_damage(
			center_damage, origin.distance_to(player_position), radius
		)
		if player_damage > 0.0:
			_damage_player(player_damage, "Spark Minelet" if mobile else "Arc Mine", true)
	var nearby: Array[EnemyState] = []
	enemy_grid.query_radius_into(origin, radius, enemies, nearby)
	for target in nearby:
		if (
			target == enemy
			or not target.alive
			or not target.active
			or not _runtime_has_line_of_sight(origin, target.pos, 2.0)
		):
			continue
		var damage := AttackContract.radial_damage(
			center_damage, origin.distance_to(target.pos), radius
		)
		if target.role == &"stage_boss":
			damage *= 0.25
		if damage > 0.0:
			_damage_enemy(
				target,
				damage,
				source,
				&"arc",
				enemy.mine_armed_by_player
			)
	_arm_chain_mines(enemy, origin, mobile)
	_add_effect(
		&"enemy_mine_detonation",
		origin,
		Art.ATTACK_ARC,
		0.36,
		radius
	)
	_defeat_enemy(enemy, source)


func _arm_chain_mines(source_mine: EnemyState, origin: Vector2, mobile: bool) -> void:
	var candidates: Array[EnemyState] = []
	enemy_grid.query_radius_into(origin, 320.0, enemies, candidates)
	candidates = candidates.filter(
		func(target: EnemyState) -> bool:
			return (
				target != source_mine
				and target.alive
				and target.role == &"mine"
				and target.phase != &"mine_armed"
			)
	)
	candidates.sort_custom(
		func(a: EnemyState, b: EnemyState) -> bool:
			var ad := a.pos.distance_squared_to(origin)
			var bd := b.pos.distance_squared_to(origin)
			return a.id < b.id if is_equal_approx(ad, bd) else ad < bd
	)
	for index in mini(6, candidates.size()):
		var target := candidates[index]
		_arm_mine(target, maxf(0.8, 0.9 if mobile else 1.0), true)


func _enemy_contact_damage(enemy: EnemyState, base_damage: float) -> float:
	return base_damage * (1.15 if enemy.elite_trait == &"heavy" else 1.0)


func _move_actor(position: Vector2, motion: Vector2, radius: float, is_player: bool) -> Vector2:
	var destination := position + motion
	var result := Rules.move_circle_with_extra(
		position,
		motion,
		radius,
		false,
		current_stage_id,
		_runtime_motion_cover_rects(position, destination, radius)
	)
	var clearance := radius + CRATE_COLLISION_RADIUS
	if not _position_clear_of_crates(result, clearance):
		var x_attempt := Vector2(result.x, position.y)
		var y_attempt := Vector2(position.x, result.y)
		if _position_clear_of_crates(x_attempt, clearance):
			result = x_attempt
		elif _position_clear_of_crates(y_attempt, clearance):
			result = y_attempt
		else:
			result = position
	return result


func _position_clear_of_crates(position: Vector2, clearance: float) -> bool:
	var minimum := position - Vector2.ONE * clearance
	var maximum := position + Vector2.ONE * clearance
	var min_cell := Vector2i(
		floori(minimum.x / CRATE_COLLISION_CELL_SIZE),
		floori(minimum.y / CRATE_COLLISION_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori(maximum.x / CRATE_COLLISION_CELL_SIZE),
		floori(maximum.y / CRATE_COLLISION_CELL_SIZE)
	)
	var clearance_squared := clearance * clearance
	for cell_y in range(min_cell.y, max_cell.y + 1):
		for cell_x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if not _crate_collision_cells.has(cell):
				continue
			var bucket: Array = _crate_collision_cells[cell]
			for crate in bucket:
				if (
					bool(crate["alive"])
					and position.distance_squared_to(Vector2(crate["pos"]))
						< clearance_squared
				):
					return false
	return true


func _spawn_hostile_projectile(
	origin: Vector2,
	direction: Vector2,
	damage: float,
	speed: float,
	source: String,
	affinity: StringName = AttackContract.KINETIC,
	final_damage: bool = false,
	wall_piercing: bool = false,
	threat_tier: StringName = AttackContract.THREAT_ORDINARY
) -> void:
	var normalized_affinity := AttackContract.normalize_affinity(affinity)
	projectile_store.add_hostile({
		"pos": origin,
		"velocity": direction.normalized() * EncounterDirector.effective_hostile_projectile_speed(speed),
		"radius": AttackContract.hostile_projectile_radius(damage),
		"damage": damage,
		"final_damage": final_damage,
		"life": AttackContract.HOSTILE_PROJECTILE_LIFETIME,
		"color": Art.attack_color(normalized_affinity),
		"owner": source,
		"pierce": 0,
		"bounces": 0,
		"homing": false,
		"target_id": "",
		"explosive": false,
		"reflected": false,
		"reflector_lock": &"",
		"reflector_lock_time": 0.0,
		"wall_piercing": wall_piercing,
		"affinity": normalized_affinity,
		"threat_tier": AttackContract.normalize_threat_tier(threat_tier),
		"condition_mask": 0,
	}, final_damage)


func _count_hostile_projectiles() -> int:
	return projectile_store.hostile_count()


func _update_projectiles(delta: float) -> void:
	_update_projectile_buffer(hostile_projectiles, true, delta)
	_update_projectile_buffer(player_projectiles, false, delta)


func _update_projectile_buffer(
	buffer: Array[ProjectileState],
	hostile: bool,
	delta: float
) -> void:
	var index := 0
	while index < buffer.size():
		var projectile := buffer[index]
		var from := projectile.pos
		var simulation_delta := delta
		if player_position.distance_squared_to(from) > FAR_SIMULATION_DISTANCE_SQUARED:
			if projectile.spawn_serial % 2 != _simulation_lod_bucket:
				index += 1
				continue
			simulation_delta = delta * 2.0
		projectile.life -= simulation_delta
		if projectile.life <= 0.0:
			_remove_projectile_at(hostile, index)
			continue
		if projectile.homing:
			var target := _find_enemy_by_id(projectile.target_id)
			if target != null and target.alive:
				var desired := (target.pos - projectile.pos).normalized()
				var current := projectile.velocity.normalized()
				var steered := current.lerp(desired, clampf(simulation_delta * 4.2, 0.0, 1.0)).normalized()
				projectile.velocity = steered * projectile.velocity.length()
		var to := from + projectile.velocity * simulation_delta
		var radius := projectile.radius
		if not projectile.wall_piercing:
			var cover_hit := _runtime_first_cover_hit(from, to, radius)
			if bool(cover_hit.get("hit", false)):
				if not hostile:
					var hit_rect := Rect2(cover_hit.get("rect", Rect2()))
					var bulkhead_id := terrain_runtime.bulkhead_id_for_rect(hit_rect)
					if not bulkhead_id.is_empty():
						if terrain_runtime.damage_bulkhead(
							bulkhead_id,
							projectile.structure_damage
						):
							_on_bulkhead_broken(Vector2(cover_hit["point"]))
				if projectile.bounces > 0:
					projectile.bounces -= 1
					var normal: Vector2 = cover_hit["normal"]
					projectile.velocity = projectile.velocity.bounce(normal)
					projectile.pos = Vector2(cover_hit["point"]) + normal * (radius + 2.0)
					_add_effect(
						&"projectile_reflected",
						projectile.pos,
						Rules.CYAN,
						0.15,
						18.0,
						projectile.velocity.normalized()
					)
					index += 1
					continue
				_add_effect(
					&"projectile_cover_impact",
					Vector2(cover_hit["point"]),
					projectile.color,
					0.14,
					20.0,
					projectile.velocity.normalized()
				)
				_play_sound(&"cover", _rng.randf_range(0.96, 1.04))
				_remove_projectile_at(hostile, index)
				continue
			if _projectile_hits_crate(projectile, from, to, not hostile):
				_remove_projectile_at(hostile, index)
				continue

		projectile.pos = to
		if hostile:
			if Rules.point_segment_distance(player_position, from, to) <= Rules.PLAYER_RADIUS + projectile.radius:
				_damage_player(projectile.damage, projectile.owner, true, true, projectile.final_damage)
				projectile_store.remove_hostile_at_swap(index)
				continue
		else:
			var projectile_radius := radius
			enemy_grid.query_segment_cells_into(
				from,
				to,
				projectile_radius,
				enemies,
				_enemy_query_buffer,
				_enemy_query_group_ends,
				_enemy_query_group_exit_t
			)
			var contact: Variant = _player_projectile_contact(
				projectile,
				from,
				to,
				projectile_radius,
				_enemy_query_buffer,
				_enemy_query_group_ends,
				_enemy_query_group_exit_t
			)
			if contact is bool:
				projectile_store.remove_player_at_swap(index)
				continue
			var hit_enemy := contact as EnemyState
			if hit_enemy != null:
				var hit_position := hit_enemy.pos
				if _try_absorb_protective_structure(hit_enemy, projectile):
					stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
					_add_effect(
						&"enemy_barrier_hit",
						hit_position,
						Art.IVORY_BRIGHT,
						0.20,
						hit_enemy.radius * 1.35,
						projectile.velocity.normalized()
					)
					_play_sound(&"cover", 1.06)
					if projectile.pierce > 0:
						projectile.pierce -= 1
						projectile.pos = to + projectile.velocity.normalized() * 8.0
					else:
						projectile_store.remove_player_at_swap(index)
						continue
					index += 1
					continue
				var enemy_damage := projectile.damage
				if hit_enemy.role in [&"turret", &"mine", &"generator", &"interceptor_tower", &"beam_sentinel", &"boss_pylon"]:
					enemy_damage = projectile.structure_damage
				var damage_source := "reflected_%s" % projectile.owner if projectile.reflected else projectile.owner
				var direct_attribute := (
					_telemetry_attribute_for_affinity(projectile.affinity)
					if projectile.reflected
					else &"kinetic"
				)
				_damage_enemy(
					hit_enemy,
					enemy_damage,
					damage_source,
					direct_attribute,
					true
				)
				if projectile.owner == "player_primary" and run_build.has(&"marked_salvo"):
					_mark_enemy(hit_enemy)
				StatusRuntime.apply(hit_enemy, projectile.status_profile)
				_record_status_applications(projectile.status_profile)
				stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
				var impact_event := (
					&"projectile_reflected"
					if projectile.reflected
					else &"secondary_seeker_impact"
					if projectile.owner == "seeker"
					else &"projectile_damage_impact"
				)
				_add_effect(
					impact_event,
					hit_position,
					projectile.color,
					0.18,
					24.0,
					projectile.velocity.normalized()
				)
				_play_sound(&"impact", _rng.randf_range(0.92, 1.08))
				if projectile.explosive:
					_damage_enemies_in_radius(
						hit_position, 95.0, 12.0,
						"Seeker burst", &"kinetic", true, hit_enemy.id
					)
					_add_effect(
						&"secondary_seeker_burst",
						hit_position,
						Rules.MOSS,
						0.28,
						95.0,
						projectile.velocity.normalized()
					)
				if projectile.pierce > 0:
					projectile.pierce -= 1
					projectile.pos = to + projectile.velocity.normalized() * 8.0
				else:
					projectile_store.remove_player_at_swap(index)
					continue
		index += 1


func _try_absorb_protective_structure(
	enemy: EnemyState,
	projectile: ProjectileState
) -> bool:
	if enemy.armor_structure > 0.0:
		enemy.armor_structure = maxf(0.0, enemy.armor_structure - projectile.structure_damage)
		return true
	if enemy.guard_plate_structure <= 0.0:
		return false
	var facing := (player_position - enemy.pos).normalized()
	var incoming_origin := -projectile.velocity.normalized()
	if facing.dot(incoming_origin) < 0.25:
		return false
	enemy.guard_plate_structure = maxf(
		0.0, enemy.guard_plate_structure - projectile.structure_damage
	)
	return true


func _on_bulkhead_broken(position: Vector2) -> void:
	_rebuild_runtime_blockers()
	pursuit_field.request_rebuild()
	if is_instance_valid(_backdrop):
		_backdrop.queue_redraw()
	_add_effect(&"bulkhead_destroy", position, Art.MUSTARD, 0.24, 90.0)
	_play_sound(&"destroy_priority", 0.92)


func _remove_projectile_at(hostile: bool, index: int) -> void:
	if hostile:
		projectile_store.remove_hostile_at_swap(index)
	else:
		projectile_store.remove_player_at_swap(index)


func _mark_enemy(target: EnemyState) -> void:
	if not _marked_enemy_id.is_empty():
		var previous := _find_enemy_by_id(_marked_enemy_id)
		if previous != null and previous != target:
			previous.marked_time = 0.0
	target.marked_time = 2.5
	_marked_enemy_id = target.id


func _is_player_targetable_enemy(enemy: EnemyState) -> bool:
	if enemy == null or not enemy.alive or not enemy.active:
		return false
	if (
		enemy.role == &"boss_pylon"
		and not enemy.boss_objective_id.is_empty()
	):
		return boss_exam_runtime.can_damage_module(enemy.id)
	return true


func _player_projectile_contact(
	projectile: ProjectileState,
	from: Vector2,
	to: Vector2,
	projectile_radius: float,
	candidates: Array[EnemyState],
	group_ends: PackedInt32Array = PackedInt32Array(),
	group_exit_t: PackedFloat32Array = PackedFloat32Array()
) -> Variant:
	var best: EnemyState
	var best_hit_t := INF
	var best_is_intercept := false
	var candidate_start := 0
	var group_count := group_ends.size()
	if group_count == 0 and not candidates.is_empty():
		group_count = 1
	for group_index in group_count:
		var candidate_end := (
			group_ends[group_index]
			if group_index < group_ends.size()
			else candidates.size()
		)
		for candidate_index in range(candidate_start, candidate_end):
			var enemy := candidates[candidate_index]
			if not _is_player_targetable_enemy(enemy):
				continue
			if enemy.role == &"interceptor_tower" and enemy.intercept_charges > 0:
				var intercept_t := AttackContract.segment_circle_first_t(
					from,
					to,
					enemy.pos,
					AttackContract.INTERCEPTOR_PROJECTILE_RADIUS
						+ projectile.radius
				)
				if intercept_t < best_hit_t:
					best_hit_t = intercept_t
					best = enemy
					best_is_intercept = true
				continue
			var target_radius := maxf(
				enemy.radius,
				enemy.projectile_hit_radius
			)
			var hit_t := AttackContract.segment_circle_first_t(
				from,
				to,
				enemy.pos,
				target_radius + projectile_radius
			)
			if hit_t < best_hit_t:
				best_hit_t = hit_t
				best = enemy
				best_is_intercept = false
		candidate_start = candidate_end
		var exit_t := (
			group_exit_t[group_index]
			if group_index < group_exit_t.size()
			else 1.0
		)
		if best != null and best_hit_t <= exit_t + 0.0001:
			break
	if best_is_intercept and best != null:
		best.intercept_charges -= 1
		best.intercept_recharge = 4.0
		_add_effect(
			&"projectile_intercepted",
			best.pos,
			Rules.VIOLET,
			0.24,
			112.0,
			projectile.velocity.normalized()
		)
		return true
	return best


func _segment_hits_live_crate(from: Vector2, to: Vector2, padding: float) -> bool:
	var clearance := CRATE_COLLISION_RADIUS + padding
	var minimum := (
		Vector2(minf(from.x, to.x), minf(from.y, to.y))
		- Vector2.ONE * clearance
	)
	var maximum := (
		Vector2(maxf(from.x, to.x), maxf(from.y, to.y))
		+ Vector2.ONE * clearance
	)
	var min_cell := Vector2i(
		floori(minimum.x / CRATE_COLLISION_CELL_SIZE),
		floori(minimum.y / CRATE_COLLISION_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori(maximum.x / CRATE_COLLISION_CELL_SIZE),
		floori(maximum.y / CRATE_COLLISION_CELL_SIZE)
	)
	for cell_y in range(min_cell.y, max_cell.y + 1):
		for cell_x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if not _crate_collision_cells.has(cell):
				continue
			var bucket: Array = _crate_collision_cells[cell]
			for crate in bucket:
				if (
					bool(crate["alive"])
					and AttackContract.segment_circle_first_t(
						from,
						to,
						Vector2(crate["pos"]),
						clearance
					) != INF
				):
					return true
	return false


func _first_live_crate_hit(from: Vector2, to: Vector2, padding: float) -> Dictionary:
	var clearance := CRATE_COLLISION_RADIUS + padding
	var minimum := Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2.ONE * clearance
	var maximum := Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2.ONE * clearance
	var min_cell := Vector2i(floori(minimum.x / CRATE_COLLISION_CELL_SIZE), floori(minimum.y / CRATE_COLLISION_CELL_SIZE))
	var max_cell := Vector2i(floori(maximum.x / CRATE_COLLISION_CELL_SIZE), floori(maximum.y / CRATE_COLLISION_CELL_SIZE))
	_crate_hit_receipt["crate"] = null
	_crate_hit_receipt["t"] = INF
	for cell_y in range(min_cell.y, max_cell.y + 1):
		for cell_x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if not _crate_collision_cells.has(cell):
				continue
			var bucket: Array = _crate_collision_cells[cell]
			for crate in bucket:
				if not bool(crate["alive"]):
					continue
				var crate_position := Vector2(crate["pos"])
				var hit_t := AttackContract.segment_circle_first_t(
					from,
					to,
					crate_position,
					clearance
				)
				if hit_t < float(_crate_hit_receipt["t"]):
					_crate_hit_receipt["t"] = hit_t
					_crate_hit_receipt["crate"] = crate
	return _crate_hit_receipt


func _projectile_hits_crate(
	projectile: ProjectileState,
	from: Vector2,
	to: Vector2,
	damage_crate: bool
) -> bool:
	var crate_receipt := _first_live_crate_hit(from, to, projectile.radius)
	var crate_hit: Variant = crate_receipt["crate"]
	if crate_hit == null:
		return false
	var crate_position := Vector2(crate_hit["pos"])
	var motion := to - from
	var hit_t := float(crate_receipt["t"])
	if damage_crate:
		_damage_crate(crate_hit, projectile.structure_damage)
	_add_effect(
		&"projectile_cover_impact",
		from + motion * hit_t if hit_t != INF else crate_position,
		projectile.color,
		0.16,
		22.0,
		projectile.velocity.normalized()
	)
	_play_sound(&"cover", _rng.randf_range(0.96, 1.04))
	return true


func _rebuild_crate_collision_cells() -> void:
	_crate_collision_cells.clear()
	for crate in crates:
		var position := Vector2(crate["pos"])
		var cell := Vector2i(
			floori(position.x / CRATE_COLLISION_CELL_SIZE),
			floori(position.y / CRATE_COLLISION_CELL_SIZE)
		)
		if not _crate_collision_cells.has(cell):
			_crate_collision_cells[cell] = []
		var bucket: Array = _crate_collision_cells[cell]
		bucket.append(crate)


func _damage_crate(crate: Dictionary, amount: float) -> void:
	if not bool(crate["alive"]):
		return
	crate["health"] = float(crate["health"]) - amount
	crate["flash"] = 0.12
	if float(crate["health"]) > 0.0:
		return
	crate["alive"] = false
	pickups.append({
		"id": "%s_drop" % String(crate["id"]),
		"kind": StringName(crate["drop"]),
		"pos": Vector2(crate["pos"]),
		"active": true,
		"pulse": 0.0,
		"heal_amount": float(crate.get("heal_amount", 0.0)),
	})
	_add_effect(
		&"crate_destroy",
		Vector2(crate["pos"]),
		Rules.AMBER,
		0.42,
		58.0
	)
	_play_sound(&"destroy", 1.35)


func _find_enemy_by_id(enemy_id: String) -> EnemyState:
	return enemy_store.find(enemy_id)


func _update_denied_zones(delta: float) -> void:
	for index in range(denied_zones.size() - 1, -1, -1):
		var zone: Dictionary = denied_zones[index]
		if float(zone["warning"]) > 0.0:
			zone["warning"] = maxf(0.0, float(zone["warning"]) - delta)
			continue
		zone["duration"] = float(zone["duration"]) - delta
		zone["tick"] = float(zone["tick"]) - delta
		if float(zone["duration"]) <= 0.0:
			denied_zones.remove_at(index)
			continue
		var distance := player_position.distance_to(Vector2(zone["pos"]))
		var damage := AttackContract.radial_damage(
			float(zone["damage"]),
			distance,
			float(zone["radius"])
		)
		if damage > 0.0 and float(zone["tick"]) <= 0.0:
			zone["tick"] = 0.62
			_damage_player(
				damage,
				String(zone["source"]),
				false,
				true,
				bool(zone.get("final_damage", false))
			)


func _update_trails(delta: float) -> void:
	for index in range(damaging_trails.size() - 1, -1, -1):
		var trail: Dictionary = damaging_trails[index]
		trail["time"] = float(trail["time"]) - delta
		if float(trail["time"]) <= 0.0:
			damaging_trails.remove_at(index)
			continue
		var hit_ids: Dictionary = trail["hit_ids"]
		enemy_grid.query_radius_into(Vector2(trail["pos"]), float(trail["radius"]), enemies, _enemy_query_buffer)
		for enemy in _enemy_query_buffer:
			if hit_ids.has(enemy.id):
				continue
			if enemy.pos.distance_to(Vector2(trail["pos"])) <= float(trail["radius"]) + enemy.radius:
				hit_ids[enemy.id] = true
				_damage_enemy(enemy, 18.0, "Ion Wake", &"arc", true)


func _update_effects(delta: float) -> void:
	var index := 0
	while index < effects.size():
		var effect: Dictionary = effects[index]
		effect["time"] = float(effect["time"]) - delta
		if String(effect["kind"]) == "scheduled_aftershock" and float(effect["time"]) <= 0.0:
			_swap_remove_dictionary(effects, index)
			_release_emp(true)
			continue
		if float(effect["time"]) <= 0.0:
			_swap_remove_dictionary(effects, index)
			continue
		index += 1


func _add_effect(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float,
	direction: Vector2 = Vector2.ZERO,
	value: float = 0.0,
	multiplier: float = 1.0,
	target_position: Variant = null
) -> void:
	if effects.size() >= EncounterDirector.EFFECT_CAP:
		for index in effects.size():
			if String(effects[index]["kind"]) != "scheduled_aftershock":
				_swap_remove_dictionary(effects, index)
				break
	effects.append({
		"kind": kind,
		"pos": position,
		"color": color,
		"time": duration,
		"duration": duration,
		"radius": radius,
		"dir": direction,
		"target": target_position if target_position is Vector2 else position,
		"value": value,
		"multiplier": multiplier,
	})


func _swap_remove_dictionary(collection: Array[Dictionary], index: int) -> void:
	var last_index := collection.size() - 1
	if index < 0 or index > last_index:
		return
	if index != last_index:
		collection[index] = collection[last_index]
	collection.pop_back()


func _damage_enemy(
	enemy: EnemyState,
	amount: float,
	source: String,
	attribute: StringName,
	player_owned: bool,
	final_effective: bool = false
) -> float:
	if not enemy.alive:
		return 0.0
	var role := enemy.role
	if (
		role == &"boss_pylon"
		and not enemy.boss_objective_id.is_empty()
		and not boss_exam_runtime.can_damage_module(enemy.id)
	):
		enemy.health_visible_timer = 1.5
		_add_effect(
			&"enemy_barrier_hit",
			enemy.pos,
			Art.BOSS_COMMAND,
			0.20,
			enemy.radius * 1.25
		)
		return 0.0
	if (
		not final_effective
		and terrain_runtime.overdrive_active
		and player_owned
		and not _is_structure_role(role)
	):
		amount *= 1.20
	if not final_effective and player_owned and cycle_runtime.is_active(&"overclock_cycle"):
		amount *= 1.35 if cycle_runtime.level(&"overclock_cycle") >= 2 else 1.25
	var multiplier := 1.0
	if not final_effective and enemy.shielded:
		multiplier *= 0.45
	if not final_effective and enemy.shear_time > 0.0:
		multiplier *= 1.20
	if not final_effective and role == &"rammer" and enemy.vulnerable > 0.0:
		multiplier *= 1.50
	var boss_damage_multiplier := 1.0
	if role == &"stage_boss" and not final_effective:
		boss_damage_multiplier = boss_exam_runtime.boss_damage_multiplier()
		multiplier *= boss_damage_multiplier
	var health_before := enemy.health
	if (
		not final_effective
		and role == &"mine"
		and source != "Arc Surge"
		and amount * multiplier >= health_before
	):
		var mine_applied := maxf(0.0, health_before - 1.0)
		enemy.health = 1.0
		enemy.flash = 0.11
		enemy.health_visible_timer = 1.5
		_arm_mine(enemy, 0.75, true)
		if player_owned and not boss_practice.active and source != "validation":
			stage_telemetry.record_outgoing(
				DamageSourceCatalog.outgoing_id(source), attribute, mine_applied
			)
		_apply_lifesteal(
			mine_applied,
			source,
			role,
			player_owned,
			enemy.pos
		)
		return mine_applied
	var applied_damage := minf(health_before, maxf(0.0, amount * multiplier))
	if applied_damage <= 0.0:
		return 0.0
	enemy.health = health_before - applied_damage
	if role == &"stage_boss" and boss_damage_multiplier < 1.0:
		var impact_direction := (enemy.pos - player_position).normalized()
		if impact_direction.is_zero_approx():
			impact_direction = Vector2.RIGHT
		_add_effect(
			&"boss_core_reduced_hit",
			enemy.pos,
			Art.MUSTARD,
			0.52,
			enemy.radius,
			impact_direction,
			applied_damage,
			boss_damage_multiplier
		)
	if player_owned and not boss_practice.active and source != "validation":
		stage_telemetry.record_outgoing(
			DamageSourceCatalog.outgoing_id(source),
			attribute,
			applied_damage
		)
	enemy.flash = 0.11
	enemy.health_visible_timer = 1.0 if enemy.health_class == &"swarm" else 1.5
	_apply_lifesteal(
		applied_damage,
		source,
		role,
		player_owned,
		enemy.pos
	)
	if (
		role == &"stage_boss"
		and enemy.health > 0.0
		and not boss_practice.active
	):
		var transition := boss_exam_runtime.try_advance_phase(
			enemy.health,
			enemy.max_health
		)
		if not transition.is_empty():
			_begin_boss_exam_phase(enemy, int(transition["phase"]))
	if enemy.health <= 0.0:
		_defeat_enemy(enemy, source)
	return applied_damage


func _is_structure_role(role: StringName) -> bool:
	return role in [
		&"generator", &"turret", &"mine", &"boss_pylon",
		&"interceptor_tower", &"beam_sentinel",
	]


func _telemetry_attribute_for_affinity(affinity: StringName) -> StringName:
	match AttackContract.normalize_affinity(affinity):
		AttackContract.THERMAL:
			return &"thermal"
		AttackContract.TOXIN:
			return &"toxin"
		AttackContract.CRYO:
			return &"cryo"
		AttackContract.ARC:
			return &"arc"
	return &"kinetic"


func _record_status_applications(profile: StatusProfile) -> void:
	if profile == null or boss_practice.active:
		return
	if profile.burn_enabled:
		stage_telemetry.record_status_application(&"burn")
	if profile.poison_enabled:
		stage_telemetry.record_status_application(&"poison")
	if profile.chill_enabled:
		stage_telemetry.record_status_application(&"chill")


func _apply_lifesteal(
	applied_damage: float,
	source: String,
	_role: StringName,
	player_owned: bool,
	source_position: Vector2
) -> void:
	if (
		not player_owned
		or applied_damage <= 0.0
		or not run_build.has(&"siphon_matrix")
		or lifesteal_budget <= 0.0
	):
		return
	if source == "validation":
		return
	var ratio := 0.035 if run_build.level_of(&"siphon_matrix") >= 2 else 0.02
	var healing := minf(minf(applied_damage * ratio, lifesteal_budget), _player_max_health() - player_health)
	if healing <= 0.0:
		return
	player_health += healing
	lifesteal_budget -= healing
	_add_effect(
		&"lifesteal_transfer",
		source_position,
		Art.MINT,
		0.30,
		46.0,
		(player_position - source_position).normalized(),
		0.0,
		1.0,
		player_position
	)


func _enemy_destroy_event(enemy: EnemyState) -> StringName:
	if (
		enemy.role == &"boss_pylon"
		and not enemy.boss_objective_id.is_empty()
	):
		return &"boss_module_resolved"
	if (
		enemy.role == &"stage_boss"
		or enemy.health_class in [&"elite", &"priority", &"boss"]
		or enemy.radius >= 30.0
	):
		return &"enemy_destroy_heavy"
	return &"enemy_destroy_light"


func _defeat_enemy(enemy: EnemyState, source: String) -> void:
	if not enemy.alive:
		return
	collective_tactics.unregister_enemy(enemy.id, enemy.squad_id)
	terrain_runtime.forget_wear_actor(enemy.id)
	var role := enemy.role
	var module_result := {}
	if role == &"boss_pylon" and not enemy.boss_objective_id.is_empty():
		module_result = boss_exam_runtime.register_module_defeat(enemy.id)
		resolved_boss_module_visuals.append({
			"position": enemy.pos,
			"radius": enemy.visual_radius,
			"kind": enemy.boss_module_kind,
			"index": enemy.boss_module_index,
		})
	if boss_practice.active:
		enemy.alive = false
		enemy.active = false
		enemy_grid.update_actor(enemy)
		enemy_store.queue_defeat(enemy)
		_add_effect(
			_enemy_destroy_event(enemy),
			enemy.pos,
			_enemy_color(enemy.role),
			0.48,
			enemy.radius * 1.8
		)
		_handle_boss_module_result(module_result)
		return
	var spreads_poison := StatusRuntime.contagion_enabled(enemy)
	var split_on_defeat := (
		enemy.archetype == &"splitter_barge"
		and not enemy.summoned
		and not enemy.splitter_spawned
	)
	if split_on_defeat:
		enemy.splitter_spawned = true
		_spawn_splitter_children(enemy)
	enemy.alive = false
	enemy.active = false
	enemy_grid.update_actor(enemy)
	enemy_store.queue_defeat(enemy)
	stats_enemies_defeated += 1
	stage_telemetry.record_defeat(enemy.archetype, enemy.elite_trait)
	var reward_source := &""
	if role == &"stage_boss": reward_source = &"boss"
	if not enemy.summoned and role != &"boss_pylon":
		experience_runtime.spawn_shard(enemy.pos, FieldDropRules.experience_for_enemy(enemy), reward_source)
	if _is_countable_stage_enemy(enemy):
		if stage_flow.record_countable_defeat():
			encounter_runtime.stop_spawning()
			boss_arrival_position = _choose_boss_arrival_anchor()
			discovered_markers["boss_warning"] = true
			_discover_guide(StringName("boss_stage_%d" % (current_stage_index + 1)))
			_ui.notify(tr("NOTIFY_BOSS_INBOUND"), 1.5, Rules.CORAL)
			_play_sound(&"boss", 0.82)
	if role in [&"generator", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"boss_pylon"]:
		stats_installations += 1
	if role == &"stage_boss":
		if stage_flow.record_boss_defeat():
			_complete_stage()
	_handle_boss_module_result(module_result)
	var defeated_group := enemy.group_id
	if not defeated_group.is_empty():
		_try_group_completion_reward(defeated_group, enemy.pos)
	if spreads_poison:
		var nearby: Array[EnemyState] = []
		enemy_grid.query_radius_into(enemy.pos, 100.0, enemies, nearby)
		nearby.sort_custom(
			func(a: EnemyState, b: EnemyState) -> bool:
				var a_distance := a.pos.distance_squared_to(enemy.pos)
				var b_distance := b.pos.distance_squared_to(enemy.pos)
				if not is_equal_approx(a_distance, b_distance):
					return a_distance < b_distance
				return a.id < b.id
		)
		var spread_count := 0
		for target in nearby:
			if target != enemy and target.alive and target.pos.distance_to(enemy.pos) <= 100.0:
				StatusRuntime.spread_poison(enemy, target)
				spread_count += 1
				if spread_count >= 8:
					break
	_add_effect(
		_enemy_destroy_event(enemy),
		enemy.pos,
		_enemy_color(role),
		0.65 if role == &"stage_boss" else 0.42,
		enemy.radius * 1.8
	)
	_play_sound(
		&"destroy_priority"
		if role in [&"stage_boss", &"generator", &"interceptor_tower", &"repair_tender", &"drone_carrier", &"beam_sentinel"]
		else &"destroy",
		1.0
	)
	_clear_zones_owned_by_defeated_role(role)


func _spawn_splitter_children(parent: EnemyState) -> void:
	var existing := 0
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.summoned
			and enemy.carrier_id.begins_with("splitter:")
		):
			existing += 1
	var available := mini(
		2,
		mini(
			12 - existing,
			encounter_runtime.available_active_slots(_active_mobile_count())
		)
	)
	for child_index in maxi(0, available):
		var direction := Vector2.RIGHT.rotated(
			TAU * float(child_index) / maxf(1.0, float(available))
			+ float(absi(parent.id.hash()) % 17) * 0.11
		)
		var child := _make_enemy({
			"id":"%s_split_%d" % [parent.id, child_index],
			"role":&"scrap_drone",
			"pos":_move_actor(parent.pos, direction * 44.0, 12.0, false),
			"active":true,
			"summoned":true,
			"carrier_id":"splitter:%s" % parent.id,
			"leash_rect":parent.leash_rect,
		})
		if not _append_enemy(child):
			break


func _is_countable_stage_enemy(enemy: EnemyState) -> bool:
	if enemy.summoned:
		return false
	return enemy.role not in [&"stage_boss", &"boss_pylon"]


func _try_group_completion_reward(group_id: String, position: Vector2) -> void:
	if completed_group_rewards.has(group_id):
		return
	for candidate in enemies:
		if candidate.group_id == group_id and candidate.alive:
			return
	completed_group_rewards[group_id] = true
	_add_effect(&"group_clear", position, Art.MINT, 0.28, 44.0)


func _clear_zones_owned_by_defeated_role(role: StringName) -> void:
	if role in [&"stage_boss", &"boss_pylon"]:
		for index in range(denied_zones.size() - 1, -1, -1):
			if String(denied_zones[index]["source"]).contains("Colossus"):
				denied_zones.remove_at(index)


func _damage_player(amount: float, source: String, blockable: bool, enemy_source: bool = true, final_effective: bool = false) -> void:
	if not _simulation_active() or player_invulnerable > 0.0 or stage_complete:
		return
	var remaining := _scaled_incoming_damage(amount, enemy_source, final_effective)
	if player_barrier_strength > 0.0 and player_barrier_timer > 0.0:
		var absorbed := minf(player_barrier_strength, remaining)
		player_barrier_strength -= absorbed
		remaining -= absorbed
		_add_effect(
			&"player_barrier_hit",
			player_position,
			Rules.CYAN,
			0.20,
			70.0,
			-player_hull_direction
		)
		if player_barrier_strength <= 0.0:
			_ui.notify(tr("NOTIFY_BARRIER_DEPLETED"), 1.6, Rules.CORAL)
	if remaining <= 0.0:
		return
	terrain_runtime.record_player_damage()
	encounter_runtime.record_player_damage(_damage_source_family(source, enemy_source))
	player_health = maxf(
		1.0 if boss_practice.active and boss_practice.invulnerable else 0.0,
		player_health - remaining
	)
	stats_damage_taken += remaining
	if not boss_practice.active:
		stage_telemetry.record_incoming(
			DamageSourceCatalog.incoming_id(source, enemy_source),
			remaining
		)
	player_hit_flash = PLAYER_HIT_FLASH_DURATION
	_add_effect(
		&"player_hull_hit",
		player_position,
		Rules.CORAL,
		0.20,
		46.0,
		-player_hull_direction
	)
	_grant_player_protection(PLAYER_HIT_INVULNERABILITY, &"hit")
	if not _reduced_motion_enabled():
		camera_shake = maxf(camera_shake, 3.0)
	_last_damage_source = source
	_play_sound(&"hurt")
	if player_health <= 0.0:
		_handle_player_defeat()


func _scaled_incoming_damage(amount: float, enemy_source: bool, final_effective: bool = false) -> float:
	if not enemy_source:
		return amount
	var difficulty_damage := RunDifficulty.factor(selected_run_difficulty, "damage")
	if final_effective:
		return amount * difficulty_damage
	return (
		amount
		* EncounterDirector.ENEMY_DAMAGE_MULTIPLIER
		* float(StageDifficulty.multipliers(current_stage_index)["damage"])
		* difficulty_damage
	)


func _damage_source_family(source: String, enemy_source: bool) -> StringName:
	if not enemy_source:
		return &"environment"
	var normalized := source.to_lower()
	if "bolt" in normalized or "shot" in normalized or "volley" in normalized:
		return &"projectile"
	if "mine" in normalized or "burst" in normalized or "zone" in normalized:
		return &"denial"
	return &"contact"


func _handle_player_defeat() -> void:
	_clear_projectiles()
	denied_zones.clear()
	_ui.notify(tr("NOTIFY_HULL_DISABLED"), 3.0, Rules.CORAL)
	if boss_practice.active:
		mode = RunMode.GARAGE
		_ui.show_garage({})
		_set_mouse_for_mode()
		return
	mode = RunMode.FAILURE_REPORT
	_pending_stage_report = StageReportBuilder.build(
		stage_telemetry.freeze_stage(),
		_stage_report_context(false),
		true
	)
	_ui.show_stage_report(_pending_stage_report)
	_set_mouse_for_mode()


func _apply_dash_collision() -> void:
	if player_dash_timer <= 0.0:
		return
	enemy_grid.query_radius_into(player_position, Rules.PLAYER_RADIUS + 96.0, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		if enemy.ram_cooldown > 0.0:
			continue
		if player_position.distance_to(enemy.pos) <= Rules.PLAYER_RADIUS + enemy.radius + 5.0:
			enemy.ram_cooldown = 0.35
			_damage_enemy(enemy, 16.0, "Dash impact", &"kinetic", true)
			var push := (enemy.pos - player_position).normalized()
			enemy.pos = _move_actor(enemy.pos, push * 45.0, enemy.radius, false)
			enemy_grid.update_actor(enemy)
			_add_effect(
				&"player_ram_impact",
				enemy.pos,
				Rules.AMBER,
				0.20,
				34.0,
				push
			)


func _repel_nearby_enemies(radius: float) -> void:
	enemy_grid.query_radius_into(player_position, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		var distance := player_position.distance_to(enemy.pos)
		if distance <= radius and distance > 0.1:
			var push := (enemy.pos - player_position).normalized() * 95.0
			enemy.pos = _move_actor(enemy.pos, push, enemy.radius, false)
			enemy.stun = maxf(enemy.stun, 0.75)
			enemy_grid.update_actor(enemy)


func _damage_enemies_in_radius(
	center: Vector2,
	radius: float,
	damage: float,
	source: String,
	attribute: StringName,
	player_owned: bool,
	excluded_id: String = ""
) -> void:
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if enemy.id == excluded_id:
			continue
		if not _is_player_targetable_enemy(enemy):
			continue
		if enemy.pos.distance_to(center) <= radius + enemy.radius:
			_damage_enemy(enemy, damage, source, attribute, player_owned)


func _clear_hostile_projectiles(center: Vector2, radius: float) -> int:
	return projectile_store.clear_hostiles_in_radius(center, radius)


func _update_aim_target() -> void:
	var ray_end := player_position + player_aim_direction * 900.0
	var best_id := ""
	enemy_grid.query_segment_into(player_position, ray_end, 110.0, enemies, _enemy_query_buffer)
	var candidate_count := 0
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		var enemy_position := enemy.pos
		if Rules.point_segment_distance(enemy_position, player_position, ray_end) > enemy.radius + 22.0:
			continue
		var projection := (enemy_position - player_position).dot(player_aim_direction)
		if projection < 0.0 or projection > 900.0:
			continue
		enemy.target_score = projection
		_enemy_query_buffer[candidate_count] = enemy
		candidate_count += 1
	_enemy_query_buffer.resize(candidate_count)
	_enemy_query_buffer.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		return a.target_score < b.target_score
	)
	# Projection order preserves exact target priority while avoiding repeated
	# terrain line tests behind the first visible target.
	for enemy in _enemy_query_buffer:
		if _runtime_has_line_of_sight(player_position, enemy.pos, 5.0):
			best_id = enemy.id
			break
	_aim_target_id = best_id


func _update_stage_progression(delta: float = 0.0) -> void:
	if stage_flow.state == StageFlow.State.BOSS_WARNING and stage_flow.tick(delta):
		_start_stage_boss()
	if mode == RunMode.STAGE_TRANSITION:
		stage_transition_remaining = maxf(
			0.0,
			stage_transition_remaining - maxf(0.0, delta)
		)
		if stage_transition_remaining <= 0.0:
			stage_flow.record_transition_complete()
			mode = RunMode.PLAYING
			_ui.hide_stage_transition()
			_set_mouse_for_mode()


func _trigger_contains(trigger: Variant, point: Vector2) -> bool:
	if trigger is Rect2:
		return Rect2(trigger).has_point(point)
	if trigger is Array:
		for region in trigger:
			if region is Rect2 and Rect2(region).has_point(point):
				return true
	return false


func _open_upgrade_reward(source_id: StringName) -> void:
	if mode != RunMode.PLAYING:
		return
	var offer_serial := reward_runtime.begin(current_stage_id, source_id)
	if offer_serial < 0:
		return
	mode = RunMode.UPGRADE
	current_card_offer = _build_card_offer(source_id, offer_serial)
	_ui.show_upgrade(current_card_offer)
	_play_sound(&"card", 0.9)
	_set_mouse_for_mode()


func _run_build_summary() -> String:
	var parts: PackedStringArray = []
	for upgrade_id in applied_upgrades.keys():
		var definition := upgrade_catalog.get_definition(StringName(upgrade_id))
		if definition != null:
			parts.append("%s %d" % [tr(definition.title_key), run_build.level_of(StringName(upgrade_id))])
	parts.sort()
	return "  ·  ".join(parts)


func apply_upgrade(upgrade_id: StringName) -> bool:
	var receipt := run_build.apply(upgrade_id)
	if not bool(receipt.get("applied", false)):
		return false
	var definition := upgrade_catalog.get_definition(upgrade_id)
	selected_upgrade_title_key = definition.title_key
	if upgrade_id == &"reinforced_hull":
		player_health = minf(_player_max_health(), player_health + 15.0)
	_status_profile = StatusProfile.from_build(run_build)
	_sync_cycle_upgrades()
	_hud_presenter.mark_guidebook_dirty()
	return true


func _resolve_reward_transaction() -> void:
	var source_id := reward_runtime.current_source()
	if source_id.is_empty():
		return
	if reward_runtime.claim(current_stage_id).is_empty():
		return
	if source_id == RewardRuntime.LEVEL_UP_SOURCE:
		experience_runtime.consume_pending_level()
	encounter_runtime.record_reward()
	current_card_offer.clear()


func _advance_reward_queue() -> void:
	if mode != RunMode.PLAYING:
		return
	if (
		pending_stage_completion
		and (
			experience_recall_timer > 0.0
			or not experience_runtime.shards.is_empty()
		)
	):
		return
	if experience_runtime.pending_level_ups > 0:
		_open_upgrade_reward(RewardRuntime.LEVEL_UP_SOURCE)
		return
	if reward_runtime.has_pending():
		var source := reward_runtime.pop_pending()
		_open_upgrade_reward(source)
		return
	if (
		pending_stage_completion
		and reward_runtime.is_idle()
		and not reward_runtime.has_pending()
		and reward_runtime.has_claimed(current_stage_id, &"boss")
	):
		_finalize_stage_completion()


func _build_card_offer(
	source_id: StringName,
	offer_serial: int
) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var run_seed := field_layout.seed if field_layout != null else run_index
	for definition in upgrade_catalog.offer(
		run_build,
		run_seed,
		current_stage_index,
		source_id,
		offer_serial
	):
		var current_level := run_build.level_of(definition.id)
		cards.append(UpgradeOfferPresenter.snapshot(definition, current_level))
	return cards


func _start_stage_boss() -> void:
	if boss_started or not stage_flow.boss_entry_ready():
		return
	if (
		enemy_store.live_count()
		> EnemyStore.MAX_LIVE_HOSTILES
			- BossExamCatalog.BOSS_ENTRY_SLOT_RESERVE
	):
		return
	boss_started = true
	discovered_markers["stage_boss"] = true
	boss_exam_runtime.configure(current_stage_id)
	if boss_arrival_position.is_zero_approx():
		boss_arrival_position = _choose_boss_arrival_anchor()
	var boss := _make_enemy({
		"id": "stage_boss",
		"role": "stage_boss",
		"pos": boss_arrival_position,
		"zone": "boss",
		"name_key": StageCatalog.profile(current_stage_id)["boss_name_key"],
		"boss_variant":boss_exam_runtime.variant(),
	})
	if boss == null:
		boss_started = false
		return
	boss.active = true
	boss.phase = "boss_read"
	boss.phase_time = 1.35
	boss.pattern = "system_wake"
	boss_runtime.configure(current_stage_id)
	if not _append_enemy(boss):
		boss_started = false
		return
	_begin_boss_exam_phase(boss, 1)
	_play_sound(&"boss")
	camera_shake = 12.0


func _choose_boss_arrival_anchor() -> Vector2:
	var anchors := (
		_active_tactical_layout.boss_arrival_anchors
		if field_layout != null
		else StageCatalog.boss_arrival_anchors(current_stage_id)
	)
	var candidates: Array[Vector2] = []
	var excluded_view := _visible_world_rect(240.0)
	for anchor in anchors:
		var distance := player_position.distance_to(anchor)
		if (
			distance >= BOSS_ARRIVAL_MIN_DISTANCE
			and distance <= BOSS_ARRIVAL_PREFERRED_MAX_DISTANCE
			and not excluded_view.has_point(anchor)
			and pursuit_field.path_cost(anchor, 76.0) >= 0
			):
			candidates.append(anchor)
	if candidates.is_empty():
		for anchor in anchors:
			if (
				player_position.distance_to(anchor) >= BOSS_ARRIVAL_MIN_DISTANCE
				and not excluded_view.has_point(anchor)
				and pursuit_field.path_cost(anchor, 76.0) >= 0
			):
				candidates.append(anchor)
	if candidates.is_empty():
		for anchor in anchors:
			if (
				not excluded_view.has_point(anchor)
				and pursuit_field.path_cost(anchor, 76.0) >= 0
			):
				candidates.append(anchor)
	if candidates.is_empty():
		candidates = anchors.duplicate()
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var a_distance := absf(
			player_position.distance_to(a) - BOSS_ARRIVAL_MIN_DISTANCE
		)
		var b_distance := absf(
			player_position.distance_to(b) - BOSS_ARRIVAL_MIN_DISTANCE
		)
		if not is_equal_approx(a_distance, b_distance):
			return a_distance < b_distance
		return int(a.x + a.y + run_index * 31 + current_stage_index * 17) < int(b.x + b.y + run_index * 31 + current_stage_index * 17)
	)
	return candidates[0] if not candidates.is_empty() else Rules.player_start(current_stage_id)


func _update_stage_boss(boss: EnemyState, delta: float) -> void:
	if not bool(boss.alive):
		return
	boss_exam_runtime.advance(delta)
	boss.boss_module_state = boss_exam_runtime.core_state()
	_show_pending_boss_state_hint()
	if (
		boss_practice.is_pattern_loop()
		and BossPatterns.commit_mode(boss_practice.pattern) == &"autonomous"
	):
		boss_practice.loop_wait -= delta
		_boss_reposition(boss, delta)
		if boss_practice.loop_wait <= 0.0:
			_execute_boss_autonomous(_practice_autonomous_event(boss))
			boss_practice.loop_wait = (
				BossPatterns.startup_seconds(boss_practice.pattern)
				+ BossPatterns.active_seconds(boss_practice.pattern)
				+ 1.5
			)
		return
	if not boss_practice.is_pattern_loop():
		for event in boss_runtime.advance_autonomous(delta, boss, player_position):
			_execute_boss_autonomous(event)

	var phase := String(boss.phase)
	if phase == "boss_read":
		boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
		_boss_reposition(boss, delta)
		if float(boss.phase_time) <= 0.0:
			_boss_select_pattern(boss)
		return
	if phase == "boss_startup":
		boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
		AttackTelegraphs.update_boss_readiness(boss, String(boss.pattern))
		if float(boss.phase_time) <= 0.0:
			_boss_begin_active(boss)
		return
	if phase == "boss_active":
		_boss_update_active(boss, delta)
		return
	if phase == "boss_recovery":
		boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
		_boss_reposition(boss, delta)
		if float(boss.phase_time) <= 0.0:
			boss.phase = "boss_read"
			boss.phase_time = (
				1.5
				if boss_practice.is_pattern_loop()
				else boss_runtime.read_gap(boss.boss_phase)
			)
			boss.pattern = "reading_arena"


func _boss_select_pattern(boss: EnemyState) -> void:
	var pattern := (
		boss_practice.pattern
		if boss_practice.is_pattern_loop()
		else boss_runtime.select_direct(boss)
	)
	boss.pattern = pattern
	boss.phase = "boss_startup"
	boss.phase_time = BossPatterns.startup_seconds(pattern)
	boss.hit_committed = false
	var kind := BossPatterns.kind(pattern)
	var predicted_target := _boss_predicted_target(
		Vector2(boss.pos),
		BossPatterns.projectile_speed(pattern)
	)
	if (
		kind in [&"area", &"pylons", &"summon"]
		and BossPatterns.damage(pattern) > 0.0
	):
		var lead := predicted_target - player_position
		predicted_target = (
			player_position
			+ lead.limit_length(BossPatterns.AREA_TARGET_MAX_LEAD)
		)
	boss.committed_target = predicted_target
	boss.committed_dir = (predicted_target - Vector2(boss.pos)).normalized()
	if Vector2(boss.committed_dir).is_zero_approx():
		boss.committed_dir = Vector2.RIGHT
	if kind == &"lanes":
		boss.lane_centers = [-135.0, 135.0]
	AttackTelegraphs.refresh_boss(
		boss,
		pattern,
		_runtime_attack_path_callable,
		_runtime_charge_path_callable
	)


func _practice_autonomous_event(boss: EnemyState) -> Dictionary:
	var pattern := boss_practice.pattern
	return {
		"id":"practice_system",
		"pattern":pattern,
		"origin":boss.pos,
		"target":player_position,
		"startup":BossPatterns.startup_seconds(pattern),
		"duration":BossPatterns.active_seconds(pattern),
		"damage":BossPatterns.damage(pattern),
		"radius":BossPatterns.radius(pattern),
		"affinity":BossPatterns.affinity(pattern),
		"commit_mode":&"autonomous",
	}


func _boss_begin_active(boss: EnemyState) -> void:
	boss_runtime.begin_active(boss, self)


func _boss_update_active(boss: EnemyState, delta: float) -> void:
	boss_runtime.update_active(boss, delta, self)


func _boss_predicted_target(origin: Vector2, projectile_speed: float) -> Vector2:
	var effective_speed := EncounterDirector.effective_hostile_projectile_speed(projectile_speed)
	var travel_time := clampf(origin.distance_to(player_position) / maxf(effective_speed, 1.0), 0.0, 0.55)
	return player_position + player_velocity * travel_time * 0.72


func _boss_fire_aimed_burst(boss: EnemyState, pattern: String, damage: float) -> void:
	boss.pattern_volleys = 1
	for offset in [-0.13, 0.0, 0.13]:
		var direction := Vector2(boss.committed_dir).rotated(float(offset))
		_spawn_hostile_projectile(
			Vector2(boss.pos) + direction * 76.0,
			direction,
			damage,
			BossPatterns.projectile_speed(pattern),
			pattern,
			BossPatterns.affinity(pattern),
			true,
			false,
			AttackContract.THREAT_BOSS
		)


func _execute_boss_autonomous(event: Dictionary) -> void:
	var pattern := String(event["pattern"])
	if pattern == "beam_sentinel_call":
		if _live_boss_add_count() >= BossExamCatalog.MAX_LIVE_ADDS:
			return
		var sentinel := _make_enemy({
			"id":String(event["id"]),
			"role":&"beam_sentinel",
			"pos":_move_actor(Vector2(event["target"]), Vector2.ZERO, 34.0, false),
			"active":true,
			"summoned":true,
			"zone":"boss_system",
		})
		if _append_enemy(sentinel):
			_add_effect(
				&"hostile_summon_arrival",
				sentinel.pos,
				Art.ATTACK_ARC,
				0.55,
				76.0
			)
		return
	denied_zones.append({
		"id":event["id"],
		"pos":Vector2(event["target"]),
		"radius":float(event["radius"]),
		"warning":float(event["startup"]),
		"duration":maxf(0.62, float(event["duration"])),
		"tick":0.0,
		"damage":float(event["damage"]),
		"source":pattern,
		"affinity":StringName(event["affinity"]),
		"commit_mode":&"autonomous",
		"final_damage":true,
	})


func _boss_reposition(boss: EnemyState, delta: float) -> void:
	_boss_combat_move(boss, delta, 1.0)


func _boss_combat_move(boss: EnemyState, delta: float, speed_scale: float) -> void:
	var position := Vector2(boss.pos)
	var to_player := player_position - position
	var distance := maxf(1.0, to_player.length())
	var direction_to_player := to_player / distance
	var direction := pursuit_field.direction_at(position, float(boss.radius))
	var has_line_of_sight := _runtime_has_line_of_sight(position, player_position, float(boss.radius) * 0.4)
	if has_line_of_sight:
		if distance > 560.0:
			direction = direction_to_player
		elif distance < 340.0:
			direction = -direction_to_player
		else:
			var strafe_sign := -1.0 if int(boss.pattern_index) % 2 == 0 else 1.0
			direction = direction_to_player.rotated(strafe_sign * PI * 0.5)
	elif direction.is_zero_approx():
		direction = direction_to_player
	boss.pos = _move_actor(
		position,
		direction * float(boss.speed) * speed_scale * delta,
		float(boss.radius),
		false
	)
	boss.velocity = (Vector2(boss.pos) - position) / maxf(delta, 0.0001)


func _begin_boss_exam_phase(boss: EnemyState, next_phase: int) -> void:
	_remove_boss_objective_modules()
	resolved_boss_module_visuals.clear()
	if _flush_defeated_enemies() > 0:
		enemy_grid.rebuild(enemies)
	boss.boss_phase = clampi(next_phase, 1, 3)
	boss.phase = &"boss_read"
	boss.phase_time = 0.90
	boss.pattern = &"phase_transition" if boss.boss_phase > 1 else &"system_wake"
	boss.pattern_index = 0
	boss.boss_module_state = &"sealed"
	boss.attack_telegraphs.clear()
	var payload := boss_exam_runtime.begin_phase(
		boss.max_health,
		boss.boss_phase
	)
	_spawn_boss_objective_modules(boss, Array(payload["modules"]))
	if not boss_practice.is_pattern_loop():
		_spawn_boss_exam_adds(
			boss,
			Array(payload.get("add_roles", [])),
			StringName(payload.get("tactic_id", &""))
		)
	_sync_boss_module_states()
	_show_pending_boss_state_hint()
	if boss.boss_phase > 1:
		boss_phase_two_announced = true
		_play_sound(&"boss", 0.78)


func _spawn_boss_objective_modules(
	boss: EnemyState,
	module_specs: Array
) -> void:
	for spec_variant in module_specs:
		var spec := Dictionary(spec_variant)
		var offset := Vector2(spec["offset"])
		var position := _move_actor(
			boss.pos,
			offset,
			33.0,
			false
		)
		var module := _make_enemy({
			"id":String(spec["id"]),
			"role":&"boss_pylon",
			"pos":position,
			"zone":"boss_objective",
			"name_key":_boss_module_name_key(
				StringName(spec["kind"])
			),
			"boss_objective_id":boss_exam_runtime.objective_id(),
			"boss_module_kind":StringName(spec["kind"]),
			"boss_module_index":int(spec["index"]),
			"boss_module_state":&"locked",
			"active":true,
		})
		if module == null:
			continue
		module.health = float(spec["health"])
		module.max_health = module.health
		module.active = true
		if _append_enemy(module):
			_add_effect(
				&"hostile_arrival",
				position,
				Art.BOSS_COMMAND,
				0.55,
				78.0
			)


func _spawn_boss_exam_adds(
	boss: EnemyState,
	roles: Array,
	tactic_id: StringName
) -> void:
	var live_before := _live_boss_add_count()
	var available := maxi(
		0,
		BossExamCatalog.MAX_LIVE_ADDS - live_before
	)
	var spawn_count := mini(available, roles.size())
	var spawned := 0
	var squad_id := "boss_wave_p%d" % boss.boss_phase
	for index in spawn_count:
		var direction := Vector2.RIGHT.rotated(
			TAU * float(index) / float(maxi(1, spawn_count))
			+ float(current_stage_index) * 0.31
		)
		var position := _move_actor(
			boss.pos,
			direction * (250.0 + float(index % 2) * 54.0),
			30.0,
			false
		)
		var add := _make_enemy({
			"id":"%s_%02d" % [squad_id, index],
			"role":StringName(roles[index]),
			"pos":position,
			"zone":"boss_wave",
			"active":true,
			"summoned":true,
			"group_id":squad_id,
			"squad_id":squad_id,
			"squad_leader":index == 0,
			"formation_slot":index,
			"formation_size":spawn_count,
			"collective_tactic_id":tactic_id,
			"collective_beat_kind":&"power_test",
		})
		if add != null and _append_enemy(add):
			spawned += 1
			_add_effect(
				&"hostile_summon_arrival",
				position,
				Art.DANGER,
				0.42,
				56.0
			)
	boss_exam_runtime.note_adds_spawned(
		spawned,
		live_before + spawned
	)


func _live_boss_add_count() -> int:
	var count := 0
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.active
			and (
				enemy.zone in ["boss_wave", "boss_system"]
				or enemy.carrier_id == "stage_boss"
			)
		):
			count += 1
	return count


func _remove_boss_objective_modules() -> void:
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.role == &"boss_pylon"
			and not enemy.boss_objective_id.is_empty()
		):
			enemy.alive = false
			enemy.active = false
			enemy_grid.update_actor(enemy)
			enemy_store.queue_defeat(enemy)


func _sync_boss_module_states() -> void:
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.role == &"boss_pylon"
			and not enemy.boss_objective_id.is_empty()
		):
			enemy.boss_module_state = boss_exam_runtime.module_state(enemy.id)


func _handle_boss_module_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	_sync_boss_module_states()
	if bool(result.get("resolved", false)):
		var boss := _find_enemy_by_id("stage_boss")
		if boss != null and boss.alive:
			boss.vulnerable = float(result.get("vulnerability", 0.0))
			boss.boss_module_state = &"open"
		_show_pending_boss_state_hint()
		_play_sound(&"impact", 1.08)
	else:
		_play_sound(&"impact", 0.82)


func _show_pending_boss_state_hint() -> void:
	var hint_key := boss_exam_runtime.take_state_entry_hint()
	if hint_key.is_empty():
		return
	var color := (
		Art.PLAYER_REWARD
		if hint_key == "BOSS_EXAM_CORE_OPEN"
		else Art.BOSS_COMMAND
	)
	_ui.notify(tr(hint_key), 2.6, color)


func _on_boss_charge_collision(
	boss: EnemyState,
	before: Vector2,
	after: Vector2
) -> void:
	var target_id := boss_exam_runtime.route_collision_target()
	if target_id.is_empty() and boss_exam_runtime.objective_id() == &"forge_plate":
		for module_id in boss_exam_runtime.active_module_ids():
			var module := _find_enemy_by_id(module_id)
			if (
				module != null
				and Rules.point_segment_distance(
					module.pos,
					before,
					after
				) <= module.radius + boss.radius
			):
				target_id = module_id
				break
	if target_id.is_empty():
		return
	var target := _find_enemy_by_id(target_id)
	if target != null and target.alive:
		_damage_enemy(
			target,
			target.health,
			"Boss routed collision",
			&"kinetic",
			true
		)


func _boss_module_name_key(kind: StringName) -> String:
	match kind:
		&"forge_plate":
			return "BOSS_MODULE_FORGE_PLATE"
		&"segment_lock":
			return "BOSS_MODULE_SEGMENT_LOCK"
		&"relay_positive":
			return "BOSS_MODULE_RELAY_POSITIVE"
		&"relay_negative":
			return "BOSS_MODULE_RELAY_NEGATIVE"
		&"route_switch":
			return "BOSS_MODULE_ROUTE_SWITCH"
		&"armor_car":
			return "BOSS_MODULE_ARMOR_CAR"
	return "BOSS_MODULE_LATTICE_OUTER"


func _complete_stage() -> void:
	if stage_complete or pending_stage_completion:
		return
	pending_stage_completion = true
	encounter_runtime.stop_spawning()
	for enemy in enemies:
		if enemy.alive:
			enemy.alive = false
			enemy.active = false
			enemy_grid.update_actor(enemy)
			enemy_store.queue_defeat(enemy)
	projectile_store.retain_player_only()
	denied_zones.clear()
	damaging_trails.clear()
	experience_recall_timer = 0.65
	_ui.notify(tr("NOTIFY_BOSS_SHARD"), 3.0, Rules.AMBER)


func _finalize_stage_completion() -> void:
	if stage_complete:
		return
	stage_complete = true
	pending_stage_completion = false
	_clear_projectiles()
	denied_zones.clear()
	_pending_stage_report = StageReportBuilder.build(
		stage_telemetry.freeze_stage(),
		_stage_report_context(
			current_stage_index < StageCatalog.STAGE_IDS.size() - 1
		)
	)
	completed_stage_reports.append(_pending_stage_report.duplicate(true))
	var has_next_stage := current_stage_index < StageCatalog.STAGE_IDS.size() - 1
	stage_flow.record_rewards_complete(has_next_stage)
	if has_next_stage:
		_begin_stage_transition()
		return
	persistent_clear_count += 1
	persistent_relay_module = true
	_save_persistence()
	_show_final_result()


func _stage_report_context(has_next_stage: bool) -> Dictionary:
	var profile := StageCatalog.profile(current_stage_id)
	return {
		"number":int(profile["number"]),
		"title_key":String(profile["title_key"]),
		"has_next_stage":has_next_stage,
		"clear_time":maxf(0.0, run_time - stage_started_at),
		"hull":player_health,
		"max_hull":_player_max_health(),
	}


func _continue_stage_report() -> void:
	if mode != RunMode.STAGE_REPORT:
		return
	if bool(_pending_stage_report.get("has_next_stage", false)):
		_advance_stage()
		return
	persistent_clear_count += 1
	persistent_relay_module = true
	_save_persistence()
	_show_final_result()


func _begin_stage_transition() -> void:
	if current_stage_index >= StageCatalog.STAGE_IDS.size() - 1:
		return
	var preserved_position := player_position
	var preserved_hull_direction := player_hull_direction
	var preserved_aim_direction := player_aim_direction
	current_stage_index += 1
	current_stage_id = StageCatalog.STAGE_IDS[current_stage_index]
	_active_tactical_layout = field_layout.tactical_layout(current_stage_id)
	if _active_tactical_layout == null:
		push_error("Missing tactical layout for %s" % current_stage_id)
		return
	if is_instance_valid(_backdrop):
		_backdrop.configure(current_stage_id, _active_tactical_layout)
	if is_instance_valid(_camera):
		_apply_camera_stage_limits()
	player_position = preserved_position
	player_hull_direction = preserved_hull_direction
	player_aim_direction = preserved_aim_direction
	player_velocity = Vector2.ZERO
	player_dash_timer = 0.0
	player_dash_trail_timer = 0.0
	player_emp_startup = 0.0
	player_health = _player_max_health()
	_grant_player_protection(
		STAGE_TRANSITION_INVULNERABILITY,
		&"stage_transition"
	)
	experience_recall_timer = 0.0
	experience_runtime.clear_shards()
	experience_runtime.pending_level_ups = 0
	stage_telemetry.reset_stage()
	reward_runtime.reset_stage()
	current_card_offer.clear()
	secondary_runtime.reset(player_position)
	_clear_enemies()
	_clear_projectiles()
	pickups.clear()
	crates.clear()
	denied_zones.clear()
	effects.clear()
	damaging_trails.clear()
	for spec in _active_tactical_layout.stationary_blueprint():
		_append_enemy(_make_enemy(spec))
	encounter_runtime.configure(
		current_stage_id,
		_transition_packets(current_stage_id),
		selected_run_difficulty,
		_active_tactical_layout.ordinary_spawn_anchors,
		_active_tactical_layout.encounter_seed,
		_active_tactical_layout.geometry_snapshot
	)
	stage_flow.configure_transition(
		current_stage_index,
		RunDifficulty.scaled_quota(
			StageCatalog.quota(current_stage_id),
			selected_run_difficulty
		)
	)
	terrain_runtime.configure(
		field_layout.field_definition.get("features", []),
		field_layout.persistent_bulkhead_health,
		true,
		_active_tactical_layout.support_sockets,
		field_layout.seed,
		current_stage_id,
		field_layout.persistent_wear_tile_state
	)
	_rebuild_runtime_blockers()
	pursuit_field.reset(current_stage_id, _runtime_cover_rects())
	_populate_stage_items()
	boss_started = false
	boss_exam_runtime.configure(current_stage_id)
	boss_phase_two_announced = false
	boss_arrival_position = Vector2.ZERO
	stage_complete = false
	pending_stage_completion = false
	completed_group_rewards.clear()
	discovered_markers.clear()
	_elite_pending = 0
	_elite_spawned = 0
	_elite_threshold_cursor = 0
	_threat_contact_cache.clear()
	_threat_sample_timer = 0.0
	_shielded_enemy_ids.clear()
	_pending_shielded_enemy_ids.clear()
	_shield_supports.clear()
	_enemy_coordination_initialized = false
	_aim_target_id = ""
	_marked_enemy_id = ""
	_sheared_enemy_id = ""
	enemy_grid.configure(
		Rules.world_rect(current_stage_id),
		SpatialGrid.DEFAULT_CELL_SIZE
	)
	enemy_grid.rebuild(enemies)
	stage_started_at = run_time
	stage_transition_remaining = STAGE_TRANSITION_SECONDS
	mode = RunMode.STAGE_TRANSITION
	_hud_presenter.reset()
	_present_stage_transition_banner()
	_play_sound(&"card", 1.12)
	_set_mouse_for_mode()


func _present_stage_transition_banner() -> void:
	var profile := StageCatalog.profile(current_stage_id)
	_ui.show_stage_transition(
		int(profile["number"]),
		String(profile["title_key"]),
		_reduced_motion_enabled()
	)


func _transition_packets(stage_id: StringName) -> Array[Dictionary]:
	var authored := StageCatalog.packets(stage_id)
	var result: Array[Dictionary] = []
	if authored.size() <= 1:
		return result
	var authored_first_time := float(authored[1]["trigger"]["at"])
	for packet_index in range(1, authored.size()):
		var packet := authored[packet_index].duplicate(true)
		var trigger := Dictionary(packet["trigger"]).duplicate(true)
		trigger["at"] = (
			STAGE_TRANSITION_CUE_AT
			+ float(trigger["at"])
			- authored_first_time
		)
		packet["trigger"] = trigger
		if packet_index == 1:
			packet["cue_lead"] = (
				STAGE_TRANSITION_FIRST_SPAWN_AT
				- STAGE_TRANSITION_CUE_AT
			)
		result.append(packet)
	return result


func _show_final_result() -> void:
	mode = RunMode.RESULT
	var profile := StageCatalog.profile(current_stage_id)
	_ui.show_result({
		"stage_number": int(profile["number"]),
		"stage_title_key": String(profile["title_key"]),
		"has_next_stage": false,
		"next_stage_key": "",
		"time": _format_time(run_time),
		"health_ratio": player_health / _player_max_health(),
		"upgrade": selected_upgrade_title_key,
		"primary_hits": stats_primary_hits,
		"dash_uses": stats_dash_uses,
		"installations": stats_installations,
		"stage_history": completed_stage_reports.duplicate(true),
	})
	_play_sound(&"card", 0.72)
	_set_mouse_for_mode()


func _format_time(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	var remainder := floori(seconds) % 60
	return "%d:%02d" % [minutes, remainder]


func _mark_visited() -> void:
	var stage_world := Rules.world_rect(current_stage_id)
	var cell_width := stage_world.size.x / float(MINIMAP_COLS)
	var cell_height := stage_world.size.y / float(MINIMAP_ROWS)
	var cell := Vector2i(
		clampi(floori(player_position.x / cell_width), 0, MINIMAP_COLS - 1),
		clampi(floori(player_position.y / cell_height), 0, MINIMAP_ROWS - 1)
	)
	for x_offset in [-1, 0, 1]:
		for y_offset in [-1, 0, 1]:
			var visited := cell + Vector2i(x_offset, y_offset)
			if visited.x >= 0 and visited.y >= 0 and visited.x < MINIMAP_COLS and visited.y < MINIMAP_ROWS:
				visited_cells[visited] = true


func _update_camera(_delta: float) -> void:
	if not is_instance_valid(_camera):
		return
	if _capture_mode:
		_camera.position_smoothing_enabled = false
	var target := player_position
	if camera_shake > 0.0:
		_camera_offset = Vector2(
			_rng.randf_range(-camera_shake, camera_shake),
			_rng.randf_range(-camera_shake, camera_shake)
		)
	else:
		_camera_offset = Vector2.ZERO
	_camera.position = target + _camera_offset


func _build_hud_snapshot(include_world_channels: bool = true, include_guidebook: bool = true) -> Dictionary:
	var objective := _objective_text()
	var stage_profile := StageCatalog.profile(current_stage_id)
	var experience_snapshot := experience_runtime.snapshot()

	var target_snapshot := {"visible": false}
	if not _aim_target_id.is_empty():
		var target := _find_enemy_by_id(_aim_target_id)
		var show_priority_target := (
			target != null
			and (
				target.health_class == &"priority"
				or (target.health_class == &"boss" and target.role != &"stage_boss")
			)
		)
		if target != null and target.alive and show_priority_target:
			target_snapshot = {
				"visible": true,
				"name": tr(String(target["name"])),
				"health": float(target["health"]),
				"max_health": float(target["max_health"]),
				"state": _enemy_state_text(target),
			}

	var boss_snapshot := {"visible": false}
	var boss := _find_enemy_by_id("stage_boss")
	if boss != null and boss.alive:
		var boss_objective := _boss_objective_snapshot()
		boss_snapshot = {
			"visible": true,
			"name": tr("ENEMY_BOSS_PHASE") % [tr(String(boss.name)), int(boss.boss_phase)],
			"health": float(boss.health),
			"max_health": float(boss.max_health),
			"state": _boss_state_text(boss),
			"objective":boss_objective,
		}

	var snapshot := {
		"health": player_health,
		"max_health": _player_max_health(),
		"level": int(experience_snapshot["level"]),
		"experience": int(experience_snapshot["experience"]),
		"experience_required": int(experience_snapshot["required"]),
		"reduced_motion": _reduced_motion_enabled(),
		"objective": "%s · %s" % [tr(String(stage_profile["title_key"])), objective[0]],
		"objective_detail": objective[1],
		"stage_title": tr(String(stage_profile["title_key"])),
		"dash_available":player_dash_cooldown <= 0.0,
		"dash_ratio": clampf(player_dash_cooldown / _dash_cooldown_max(), 0.0, 1.0),
		"seeker_available":secondary_runtime.seeker_cooldown <= 0.0,
		"seeker_ratio": clampf(secondary_runtime.seeker_cooldown / SEEKER_COOLDOWN, 0.0, 1.0),
		"skill_available":player_emp_startup <= 0.0 and player_emp_cooldown <= 0.0,
		"skill_ratio": clampf(player_emp_cooldown / _emp_cooldown_max(), 0.0, 1.0),
		"buff_text": "",
		"target": target_snapshot,
		"boss": boss_snapshot,
	}
	if include_world_channels:
		snapshot["minimap"] = _minimap_snapshot(true)
		snapshot["threat_radar"] = _threat_radar_snapshot()
	if include_guidebook:
		var build_snapshot := _build_snapshot()
		snapshot["build_snapshot"] = build_snapshot
		snapshot["guidebook"] = _guidebook_snapshot(build_snapshot)
	return snapshot


func _build_fast_hud_snapshot() -> Dictionary:
	return _build_hud_snapshot(false, false)


func _guidebook_snapshot(build_snapshot: Dictionary = {}) -> Dictionary:
	var store := get_node_or_null("/root/VehicleGuidebookStore")
	if store == null:
		return {}
	if build_snapshot.is_empty():
		build_snapshot = _build_snapshot()
	return store.snapshot(build_snapshot)


func _build_snapshot() -> Dictionary:
	var experience := experience_runtime.snapshot()
	var primary_interval := maxf(
		PrimaryWeapon.MIN_INTERVAL,
		run_build.stat(&"primary_interval", PrimaryWeapon.BASE_INTERVAL)
	)
	var effective_stats: Array[Dictionary] = [
		{"id":&"hull", "label_key":"SHIP_STAT_HULL", "value":_player_max_health(), "decimals":0, "unit_key":"SHIP_UNIT_HP"},
		{"id":&"speed", "label_key":"SHIP_STAT_SPEED", "value":_player_move_speed(), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
		{"id":&"primary_damage", "label_key":"SHIP_STAT_PRIMARY_DAMAGE", "value":18.0 * run_build.stat(&"primary_damage_multiplier", 1.0), "decimals":1, "unit_key":"SHIP_UNIT_DAMAGE"},
		{"id":&"fire_rate", "label_key":"SHIP_STAT_FIRE_RATE", "value":1.0 / primary_interval, "decimals":2, "unit_key":"SHIP_UNIT_PER_SECOND"},
		{"id":&"projectile_speed", "label_key":"SHIP_STAT_PROJECTILE_SPEED", "value":run_build.stat(&"primary_projectile_speed", PRIMARY_PROJECTILE_SPEED), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
		{"id":&"dash_cooldown", "label_key":"SHIP_STAT_DASH_COOLDOWN", "value":_dash_cooldown_max(), "decimals":2, "unit_key":"SHIP_UNIT_SECONDS"},
		{"id":&"emp_damage", "label_key":"SHIP_STAT_EMP_DAMAGE", "value":62.0 * run_build.stat(&"emp_damage_multiplier", 1.0), "decimals":1, "unit_key":"SHIP_UNIT_DAMAGE"},
		{"id":&"emp_cooldown", "label_key":"SHIP_STAT_EMP_COOLDOWN", "value":_emp_cooldown_max(), "decimals":2, "unit_key":"SHIP_UNIT_SECONDS"},
	]
	return BuildSnapshotBuilder.build(
		run_build,
		upgrade_catalog,
		effective_stats,
		secondary_runtime.equipped_families(run_build),
		{
			"health":player_health,
			"max_health":_player_max_health(),
			"level":int(experience["level"]),
			"experience":int(experience["experience"]),
			"experience_required":int(experience["required"]),
		}
	)


func _discover_guide(entry_id: StringName) -> void:
	if boss_practice.active:
		return
	var store := get_node_or_null("/root/VehicleGuidebookStore")
	if store != null and bool(store.discover(entry_id)):
		_hud_presenter.mark_guidebook_dirty()


func _objective_text() -> Array[String]:
	var profile := StageCatalog.profile(current_stage_id)
	var boss_name := tr(String(profile["boss_name_key"]))
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		return [tr("OBJECTIVE_BOSS_INBOUND").replace("%s", boss_name), tr("OBJECTIVE_BOSS_INBOUND_DETAIL")]
	if boss_started:
		var boss_detail_key := boss_exam_runtime.cue_key()
		match boss_exam_runtime.core_state():
			&"open":
				boss_detail_key = "BOSS_EXAM_CORE_OPEN"
			&"stable":
				boss_detail_key = "BOSS_EXAM_CORE_STABLE"
		return [
			tr("OBJECTIVE_BOSS_STAGE").replace("%s", boss_name),
			tr(boss_detail_key),
		]
	return [tr("OBJECTIVE_THREATS") % [stage_flow.defeats, stage_flow.quota], tr("OBJECTIVE_THREATS_DETAIL")]


func _enemy_state_text(enemy: EnemyState) -> String:
	var parts: Array[String] = []
	if bool(enemy.shielded):
		parts.append(tr("ENEMY_STATE_GENERATOR_SHIELD"))
	if float(enemy.stun) > 0.0:
		parts.append(tr("ENEMY_STATE_STUNNED"))
	var phase := String(enemy.phase)
	if phase == "startup":
		parts.append(tr("ENEMY_STATE_STARTUP"))
	elif phase == "active":
		parts.append(tr("ENEMY_STATE_ACTIVE"))
	elif phase == "recovery":
		parts.append(tr("ENEMY_STATE_RECOVERY"))
	elif StringName(enemy.role) == &"generator":
		parts.append(tr("ENEMY_STATE_SUPPORT"))
	parts.append_array(_localized_status_parts(enemy))
	if parts.is_empty():
		parts.append(tr("ENEMY_STATE_REPOSITION"))
	return "  •  ".join(parts)


func _boss_state_text(boss: EnemyState) -> String:
	var objective := _boss_objective_snapshot()
	var state := StringName(objective.get("state", &"stable"))
	var base_state := ""
	if state == &"sealed":
		var active_modules := Array(objective.get("active_modules", []))
		if active_modules.is_empty():
			base_state = tr("BOSS_CORE_SEALED_STATUS_EMPTY")
		else:
			var active := Dictionary(active_modules[0])
			base_state = tr("BOSS_CORE_SEALED_STATUS") % [
				String(active.get("name", "")),
				roundi(float(active.get("health", 0.0))),
				roundi(float(active.get("max_health", 1.0))),
			]
	elif state == &"open":
		base_state = tr("BOSS_CORE_OPEN_STATUS") % boss_exam_runtime.vulnerability_remaining
	else:
		base_state = tr("BOSS_CORE_STABLE_STATUS")
	var parts: Array[String] = [base_state]
	parts.append_array(_localized_status_parts(boss))
	return "  •  ".join(parts)


func _boss_objective_snapshot() -> Dictionary:
	var modules: Array[Dictionary] = []
	var active_modules: Array[Dictionary] = []
	for enemy in enemies:
		if (
			not enemy.alive
			or enemy.role != &"boss_pylon"
			or enemy.boss_objective_id.is_empty()
		):
			continue
		var module_state := boss_exam_runtime.module_state(enemy.id)
		var descriptor := {
			"id":enemy.id,
			"objective_id":enemy.boss_objective_id,
			"kind":enemy.boss_module_kind,
			"state":module_state,
			"name":tr(String(enemy.name)),
			"health":enemy.health,
			"max_health":enemy.max_health,
			"position":enemy.pos,
		}
		modules.append(descriptor)
		if module_state == &"active":
			active_modules.append(descriptor)
	return {
		"objective_id":boss_exam_runtime.objective_id(),
		"state":boss_exam_runtime.core_state(),
		"damage_multiplier":boss_exam_runtime.boss_damage_multiplier(),
		"active_modules":active_modules,
		"modules":modules,
	}


func _localized_status_parts(enemy: EnemyState) -> Array[String]:
	var parts: Array[String] = []
	var burn_stacks := StatusRuntime.stack_count(enemy, &"burn")
	var poison_stacks := StatusRuntime.stack_count(enemy, &"poison")
	var chill_stacks := StatusRuntime.stack_count(enemy, &"chill")
	if burn_stacks > 0:
		parts.append(tr("STATUS_BURN_STACKS") % burn_stacks)
	if poison_stacks > 0:
		parts.append(tr("STATUS_POISON_STACKS") % poison_stacks)
	if chill_stacks > 0:
		parts.append(tr("STATUS_CHILL_STACKS") % chill_stacks)
	return parts


func _minimap_snapshot(include_static_geometry: bool = true) -> Dictionary:
	var visited: Array[Vector2i] = []
	for cell in visited_cells.keys():
		visited.append(cell)
	var markers: Array[Dictionary] = []
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		markers.append({
			"kind":&"boss",
			"position":boss_arrival_position,
			"discovered":true,
		})
	var stage_boss := _find_enemy_by_id("stage_boss")
	if stage_boss != null and stage_boss.alive:
		markers.append({
			"kind":&"boss",
			"position":stage_boss.pos,
			"discovered":true,
		})
	for enemy in enemies:
		if not enemy.alive or not enemy.active or enemy.role == &"stage_boss":
			continue
		markers.append({
			"kind":&"enemy",
			"position":enemy.pos,
			"discovered":true,
		})
	for pickup in pickups:
		if bool(pickup["active"]):
			markers.append({
				"kind":&"item",
				"position":Vector2(pickup["pos"]),
				"discovered":true,
			})
	for crate in crates:
		if bool(crate["alive"]):
			markers.append({
				"kind":&"item",
				"position":Vector2(crate["pos"]),
				"discovered":true,
			})
	var snapshot := {
		"cols": MINIMAP_COLS,
		"rows": MINIMAP_ROWS,
		"visited": visited,
		"player": player_position,
		"player_facing": player_hull_direction,
		"world_size": Rules.world_rect(current_stage_id).size,
		"markers": markers,
	}
	if include_static_geometry:
		var blocker_polygons: Array = Rules.get_cover_polygons(false, current_stage_id).duplicate()
		for rect in _runtime_cover_rects():
			blocker_polygons.append(StageGeometry.rect_polygon(rect))
		snapshot["floor_polygons"] = StageCatalog.floor_polygons(current_stage_id)
		snapshot["void_polygons"] = StageCatalog.void_polygons(current_stage_id)
		snapshot["blocker_polygons"] = blocker_polygons
	return snapshot


func _combat_presentation_snapshot() -> Dictionary:
	var cursor_position := player_position + player_aim_direction * 230.0
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length() > 8.0:
		cursor_position = get_global_mouse_position()
	return {
		"zones": denied_zones,
		"trails": damaging_trails,
		"player_position": player_position,
		"hull_direction": player_hull_direction,
		"aim_direction": player_aim_direction,
		"player_speed": player_velocity.length(),
		"dash_active": player_dash_timer > 0.0,
		"dash_progress": (
			1.0 - clampf(player_dash_timer / DASH_DURATION, 0.0, 1.0)
			if player_dash_timer > 0.0
			else 0.0
		),
		"dash_direction": player_dash_direction,
		"player_hit": player_hit_flash > 0.0,
		"player_hit_remaining": player_hit_flash,
		"player_invulnerable_remaining": player_invulnerable,
		"protection_sources": player_protection_sources.duplicate(),
		"muzzle_flash": player_muzzle_flash,
		"barrier_strength": player_barrier_strength,
		"reduced_motion": _reduced_motion_enabled(),
		"run_time": run_time,
		"secondary_visual_tier":maxi(
			run_build.level_of(&"seeker_warhead"),
			run_build.level_of(&"escort_drone")
		),
		"support_fields":terrain_runtime.support_snapshot(),
		"resolved_boss_modules":resolved_boss_module_visuals,
		"ion_level": run_build.level_of(&"ion_field"),
		"blade_level": run_build.level_of(&"orbit_blades"),
		"escort_drone": run_build.has(&"escort_drone"),
		"secondary": secondary_runtime.snapshot(run_build),
		"cursor_position": cursor_position,
	}


func _is_world_position_visited(position: Vector2) -> bool:
	var stage_world := Rules.world_rect(current_stage_id)
	var cell_width := stage_world.size.x / float(MINIMAP_COLS)
	var cell_height := stage_world.size.y / float(MINIMAP_ROWS)
	var cell := Vector2i(floori(position.x / cell_width), floori(position.y / cell_height))
	return visited_cells.has(cell)


func _reduced_motion_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsStore")
	return bool(settings.reduced_motion) if settings != null else false


func _update_threat_contacts(delta: float) -> void:
	_threat_sample_timer -= delta
	if _threat_sample_timer > 0.0:
		return
	_threat_sample_timer = THREAT_SAMPLE_INTERVAL
	var contacts: Array[Dictionary] = []
	var viewport_size := get_viewport_rect().size
	var safe_viewport := Rect2(Vector2(90.0, 90.0), viewport_size - Vector2(180.0, 220.0))
	var canvas_transform := get_canvas_transform()
	for feature in terrain_runtime.features:
		var feature_position := (
			feature.rect.get_center()
			if feature.rect.has_area()
			else feature.pos
		)
		if safe_viewport.has_point(canvas_transform * feature_position):
			var terrain_entry := StringName({
				&"arc_surge":&"object_arc_surge",
				&"breakable_bulkhead":&"object_breakable_bulkhead",
				&"transit_gate":&"object_transit_gate",
			}.get(feature.kind, &""))
			if terrain_entry != &"":
				_discover_guide(terrain_entry)
	for support in Array(terrain_runtime.snapshot().get("support_fields", [])):
		var state := StringName(support["state"])
		if state in [&"initial_delay", &"depleted"]:
			continue
		var support_position := Vector2(support["position"])
		if safe_viewport.has_point(canvas_transform * support_position):
			_discover_guide(
				&"object_repair_basin"
				if StringName(support["kind"]) == &"repair"
				else &"object_overdrive_field"
			)
	for enemy in enemies:
		if not bool(enemy.alive) or not bool(enemy.active):
			continue
		var objective_active := (
			enemy.role == &"boss_pylon"
			and not enemy.boss_objective_id.is_empty()
			and boss_exam_runtime.module_state(enemy.id) == &"active"
		)
		if (
			enemy.role == &"boss_pylon"
			and not enemy.boss_objective_id.is_empty()
			and not objective_active
		):
			continue
		var enemy_screen := canvas_transform * Vector2(enemy.pos)
		if safe_viewport.has_point(enemy_screen):
			_discover_guide(GuidebookCatalog.entry_id_for_enemy(enemy.archetype, enemy.role))
			if enemy.elite_trait != &"":
				_discover_guide(StringName("object_elite_%s" % String(enemy.elite_trait)))
		var offset := Vector2(enemy.pos) - player_position
		if (
			not objective_active
			and offset.length_squared()
				> THREAT_SCAN_DISTANCE * THREAT_SCAN_DISTANCE
		):
			continue
		if safe_viewport.has_point(enemy_screen):
			continue
		var health_class := enemy.health_class
		var radar_offset := offset
		if objective_active and radar_offset.length() > THREAT_SCAN_DISTANCE:
			radar_offset = radar_offset.normalized() * THREAT_SCAN_DISTANCE * 0.98
		contacts.append({
			"offset": radar_offset,
			"priority": health_class in [&"priority", &"boss"] or objective_active,
			"targeted": String(enemy.id) == _aim_target_id,
			"objective":objective_active,
			"objective_id":enemy.id if objective_active else "",
			"objective_state":enemy.boss_module_state if objective_active else &"",
			"health":enemy.health if objective_active else 0.0,
			"max_health":enemy.max_health if objective_active else 0.0,
		})
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		contacts.append({"offset":boss_arrival_position - player_position, "priority":true, "targeted":false})
	_threat_contact_cache = contacts


func _threat_radar_snapshot() -> Dictionary:
	return {
		"visible": _simulation_active(),
		"center": get_canvas_transform() * player_position,
		"max_distance": THREAT_SCAN_DISTANCE,
		"contacts": _threat_contact_cache,
	}


func _draw() -> void:
	_draw_terrain()
	_draw_pickups_and_crates()
	_draw_enemies()
	if _debug_collision_overlay:
		_draw_debug_collision_overlay()


func _draw_terrain() -> void:
	var snapshot := terrain_runtime.snapshot()
	for feature in Array(snapshot.get("features", [])):
		var kind := StringName(feature["kind"])
		match kind:
			&"wear_collapse_tile":
				var wear_rect := Rect2(feature["rect"])
				var wear_state := StringName(feature.get("state", &"intact"))
				if wear_state not in [&"intact", &"cracked", &"collapsed"]:
					wear_state = &"intact"
				_draw_semantic_asset_fitted(
					StringName("world/wear_tile_%s" % String(wear_state)),
					wear_rect,
					Color.WHITE
				)
			&"arc_surge":
				var rectangle := Rect2(feature["rect"])
				var readiness := float(feature.get("readiness", 0.0))
				var color := Art.ATTACK_ARC
				_draw_semantic_asset_fitted(
					&"cue/beam_strip_9",
					rectangle,
					Color(color, 0.34 + readiness * 0.58)
				)
				var surge_state := (
					&"active"
					if readiness >= 0.82
					else (&"warning" if readiness > 0.05 else &"idle")
				)
				var horizontal := rectangle.size.x >= rectangle.size.y
				var axis := Vector2.RIGHT if horizontal else Vector2.DOWN
				var segment_extent := (
					rectangle.size.x if horizontal else rectangle.size.y
				)
				for segment in 4:
					var offset := lerpf(
						-segment_extent * 0.34,
						segment_extent * 0.34,
						float(segment) / 3.0
					)
					var center := rectangle.get_center() + axis * offset
					_draw_semantic_asset(
						&"world/facility_arc_surge_strip",
						center,
						32.0 + readiness * 16.0,
						Color(
							color,
							0.44
							if surge_state == &"idle"
							else 0.92
						)
					)
				for index in 3:
					_draw_semantic_asset(
						&"world/facility_arc_surge_strip",
						rectangle.position + rectangle.size * Vector2(
							0.25 + float(index) * 0.25, 0.5
						),
						54.0,
						Color(Art.IVORY_BRIGHT, 0.56 + readiness * 0.44)
					)
			&"breakable_bulkhead":
				var rectangle := Rect2(feature["rect"])
				var feature_health := float(feature.get("health", 0.0))
				if feature_health <= 0.0:
					_draw_semantic_asset_fitted(
						&"world/world_bulkhead_open",
						rectangle,
						Color.WHITE
					)
					continue
				var health_ratio := clampf(
					feature_health
					/ TerrainRuntime.BULKHEAD_HEALTH,
					0.0,
					1.0
				)
				var bulkhead_state := &"cracked" if health_ratio < 0.58 else &"intact"
				_draw_semantic_asset_fitted(
					(
						&"world/world_bulkhead_damaged"
						if bulkhead_state == &"cracked"
						else &"world/world_bulkhead_intact"
					),
					rectangle,
					Color.WHITE
				)
			&"transit_gate":
				var center := Vector2(feature["pos"])
				var progress := clampf(float(feature.get("progress", 0.0)), 0.0, 1.0)
				var cooldown := float(feature.get("cooldown", 0.0))
				var available := cooldown <= 0.0
				var gate_color := Art.SYSTEM if available else Art.TEXT_MUTED
				_draw_semantic_asset(
					&"cue/ring", center, TerrainRuntime.GATE_RADIUS, gate_color
				)
				_draw_semantic_asset(
					&"world/facility_transit_gate",
					center,
					54.0,
					gate_color
				)
				draw_arc(center, TerrainRuntime.GATE_RADIUS - 18.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Art.TEXT_PRIMARY, 10.0)
				if cooldown > 0.0:
					draw_arc(center, 72.0, 0.0, TAU * (1.0 - cooldown / TerrainRuntime.GATE_COOLDOWN), 32, Art.TEXT_MUTED, 10.0)


func _draw_debug_collision_overlay() -> void:
	for polygon in StageCatalog.floor_polygons(current_stage_id):
		_draw_closed_polyline(PackedVector2Array(polygon), Color(Art.MINT, 0.92), 9.0)
	for polygon in StageCatalog.cover_polygons(current_stage_id):
		var blocker := PackedVector2Array(polygon)
		draw_colored_polygon(blocker, Color(Art.CORAL, 0.22))
		_draw_closed_polyline(blocker, Color(Art.CORAL, 0.96), 10.0)
	for rect in _runtime_cover_rects():
		var dynamic_polygon := StageGeometry.rect_polygon(rect)
		draw_colored_polygon(dynamic_polygon, Color(Art.MUSTARD, 0.24))
		_draw_closed_polyline(dynamic_polygon, Art.MUSTARD, 10.0)
	draw_arc(player_position, Rules.PLAYER_RADIUS, 0.0, TAU, 32, Art.IVORY_BRIGHT, 7.0)


func _draw_closed_polyline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	if polygon.size() < 2:
		return
	var loop := polygon.duplicate()
	loop.append(polygon[0])
	draw_polyline(loop, color, width, true)


func _draw_pickups_and_crates() -> void:
	for pickup in pickups:
		if not bool(pickup["active"]):
			continue
		var position := Vector2(pickup["pos"])
		var kind := StringName(pickup["kind"])
		var bob := 0.0 if _reduced_motion_enabled() else sin(float(pickup["pulse"])) * 3.0
		position.y += bob
		var is_experience := kind in [
			&"experience_small", &"experience_medium", &"experience_large"
		]
		var visual_radius := Art.PICKUP_PLINTH_RADIUS
		if kind == &"experience_small":
			visual_radius *= 0.72
		elif kind == &"experience_medium":
			visual_radius *= 0.90
		elif kind == &"experience_large":
			visual_radius *= 1.12
		_draw_semantic_asset(
			(
				&"pickup/experience_master"
				if is_experience
				else StringName("pickup/%s" % kind)
			),
			position,
			visual_radius,
			Art.PLAYER_REWARD if is_experience else Color.WHITE
		)
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		var position := Vector2(crate["pos"])
		var face := (
			Art.IVORY_BRIGHT
			if float(crate["flash"]) > 0.0
			else Art.PLAYER_REWARD
		)
		var content_color := (
			Art.SUPPORT
			if StringName(crate["drop"]) == &"repair"
			else Art.SYSTEM
		)
		_draw_semantic_asset(
			&"pickup/reward_crate",
			position,
			38.0,
			Color(
				face.lerp(content_color, 0.12),
				1.0
			)
		)


func _draw_semantic_asset(
	asset_id: StringName,
	center: Vector2,
	radius: float,
	modulate: Color = Color.WHITE,
	angle: float = 0.0
) -> void:
	var texture := SemanticAssets.texture(asset_id)
	var descriptor := SemanticAssets.descriptor(asset_id)
	if texture == null or descriptor.is_empty():
		return
	var canvas := Vector2(descriptor.get("canvas", texture.get_size()))
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		canvas = Vector2(texture.get_size())
	var pivot := Vector2(descriptor.get("pivot", canvas * 0.5))
	var scale := radius / (maxf(canvas.x, canvas.y) * 0.5)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(
		texture,
		Rect2(-pivot * scale, canvas * scale),
		false,
		modulate
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_semantic_asset_fitted(
	asset_id: StringName,
	target: Rect2,
	modulate: Color = Color.WHITE
) -> void:
	var texture := SemanticAssets.texture(asset_id)
	if texture == null:
		return
	draw_texture_rect(texture, target, false, modulate)


func _draw_semantic_asset_segment(
	asset_id: StringName,
	from: Vector2,
	to: Vector2,
	width: float,
	modulate: Color = Color.WHITE
) -> void:
	var vector := to - from
	var length := vector.length()
	if length <= 0.001 or width <= 0.0:
		return
	var texture := SemanticAssets.texture(asset_id)
	var descriptor := SemanticAssets.descriptor(asset_id)
	if texture == null or descriptor.is_empty():
		return
	var canvas := Vector2(descriptor.get("canvas", texture.get_size()))
	var pivot := Vector2(descriptor.get("pivot", canvas * 0.5))
	draw_set_transform(
		from + vector * 0.5,
		vector.angle(),
		Vector2(length / canvas.x, width / canvas.y)
	)
	draw_texture_rect(texture, Rect2(-pivot, canvas), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemies() -> void:
	var visible_world := _visible_world_rect(180.0)
	for enemy in enemies:
		if not bool(enemy.alive) or not bool(enemy.active):
			continue
		if not visible_world.has_point(Vector2(enemy.pos)):
			continue
		_draw_enemy_overlay(enemy)


func _draw_enemy_overlay(enemy: EnemyState) -> void:
	var role := StringName(enemy.role)
	var position := Vector2(enemy.pos)
	var visual_radius := enemy.visual_radius
	if role == &"repair_tender" and not enemy.repair_target_id.is_empty():
		var repair_target := _find_enemy_by_id(String(enemy.repair_target_id))
		if repair_target != null and repair_target.alive:
			_draw_semantic_asset_segment(
				&"cue/beam_strip_9",
				position,
				repair_target.pos,
				14.0,
				Color(Art.MINT, 0.82)
			)
		_draw_enemy_marks(enemy, position, visual_radius)
	if enemy.vulnerable > 0.0:
		_draw_semantic_asset(
			&"cue/crosshair", position, visual_radius + 14.0, Art.MUSTARD
		)


func _draw_enemy_marks(enemy: EnemyState, position: Vector2, radius: float) -> void:
	if enemy.marked_time > 0.0:
		_draw_semantic_asset(
			&"cue/ring", position, radius + 15.0, Art.MUSTARD
		)
	if enemy.shear_time > 0.0:
		_draw_semantic_asset(
			&"cue/ring", position, radius + 10.0, Art.MINT
		)


func _enemy_color(role: StringName) -> Color:
	match role:
		&"chaser", &"shooter", &"mine", &"artillery_spotter", &"rammer":
			return Art.CORAL
		&"turret", &"interceptor_tower", &"beam_sentinel":
			return Art.CORAL_DARK
		&"generator", &"shield_escort", &"repair_tender":
			return Art.MINT
		&"controller", &"drone_carrier", &"stage_boss", &"boss_pylon":
			return Art.BOSS_MAGENTA
	return Art.CORAL


func _visible_world_rect(margin: float = 0.0) -> Rect2:
	var inverse_canvas := get_canvas_transform().affine_inverse()
	var viewport_size := get_viewport_rect().size
	var top_left := inverse_canvas * Vector2.ZERO
	var bottom_right := inverse_canvas * viewport_size
	return Rect2(top_left, bottom_right - top_left).abs().grow(margin)


func _regular_polygon(origin: Vector2, radius: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(origin + Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return points


func _load_persistence() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	persistent_clear_count = maxi(0, int(config.get_value("progress", "clear_count", 0)))
	persistent_relay_module = bool(config.get_value("progress", "relay_module", false))
	persistent_field_module = bool(config.get_value("progress", "field_module", false))
	selected_primary = &"pulse_cannon"


func _save_persistence() -> void:
	if _capture_mode or boss_practice.active:
		return
	var config := ConfigFile.new()
	config.set_value("progress", "clear_count", persistent_clear_count)
	config.set_value("progress", "relay_module", persistent_relay_module)
	config.set_value("progress", "field_module", persistent_field_module)
	config.set_value("loadout", "primary", String(selected_primary))
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Vehicle run persistence failed: %s" % error_string(result))


func _elapsed_ms(started_usec: int) -> float:
	return float(Time.get_ticks_usec() - started_usec) / 1000.0


func _parse_boss_practice_request() -> Dictionary:
	if not OS.is_debug_build():
		return {}
	var values := {}
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument in arguments:
		if argument.begins_with("--boss-practice="):
			values["stage_id"] = StringName(argument.trim_prefix("--boss-practice="))
		elif argument.begins_with("--practice-field="):
			values["field_id"] = StringName(argument.trim_prefix("--practice-field="))
		elif argument.begins_with("--practice-phase="):
			values["phase"] = int(argument.trim_prefix("--practice-phase="))
		elif argument.begins_with("--practice-pattern="):
			values["pattern"] = argument.trim_prefix("--practice-pattern=")
		elif argument == "--practice-invulnerable":
			values["invulnerable"] = true
	if not values.has("stage_id"):
		return {}
	values["field_id"] = values.get("field_id", &"drowned_ruin_field")
	values["phase"] = values.get("phase", 1)
	values["pattern"] = values.get("pattern", "full")
	values["invulnerable"] = values.get("invulnerable", false)
	var validator := BossPracticeSession.new()
	var errors := validator.configure(values)
	if not errors.is_empty():
		_practice_request_invalid = true
		for message in errors:
			push_error(message)
		return {}
	return values


func _start_boss_practice() -> void:
	var errors := boss_practice.configure(_practice_request)
	if not errors.is_empty():
		return
	current_stage_index = StageCatalog.STAGE_IDS.find(boss_practice.stage_id)
	current_stage_id = boss_practice.stage_id
	_field_id_override = boss_practice.field_id
	field_layout = null
	_reset_run(false, true, false, false)
	encounter_runtime.stop_spawning()
	_clear_enemies()
	_clear_projectiles()
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	player_position = Rules.player_start(current_stage_id)
	boss_runtime.configure(current_stage_id)
	boss_exam_runtime.configure(current_stage_id, boss_practice.phase)
	var boss := _make_enemy({
		"id":"stage_boss",
		"role":&"stage_boss",
		"pos":_choose_boss_arrival_anchor(),
		"zone":"practice",
		"name_key":StageCatalog.profile(current_stage_id)["boss_name_key"],
		"boss_variant":boss_exam_runtime.variant(),
		"active":true,
	})
	boss.active = true
	boss.boss_phase = boss_practice.phase
	boss.health = boss.max_health * boss_practice.health_ratio()
	boss.phase = &"boss_read"
	boss.phase_time = 0.8
	boss.pattern = &"reading_arena"
	_append_enemy(boss)
	boss_started = true
	stage_flow.state = StageFlow.State.BOSS_ACTIVE
	_begin_boss_exam_phase(boss, boss_practice.phase)
	_ui.notify(tr("BOSS_PRACTICE_START"), 1.5, Art.MUSTARD)
	_set_mouse_for_mode()


func _parse_performance_request() -> Dictionary:
	var values := {}
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument in arguments:
		if argument.begins_with("--performance-scenario="):
			values["scenario"] = argument.trim_prefix("--performance-scenario=")
		elif argument.begins_with("--performance-output="):
			values["output"] = argument.trim_prefix("--performance-output=")
		elif argument.begins_with("--performance-warmup="):
			values["warmup"] = float(argument.trim_prefix("--performance-warmup="))
		elif argument.begins_with("--performance-duration="):
			values["duration"] = float(argument.trim_prefix("--performance-duration="))
	if OS.has_feature("web"):
		var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
		if query_value is String:
			var query := String(query_value).trim_prefix("?")
			for pair in query.split("&", false):
				var parts := pair.split("=", true, 1)
				if parts.size() != 2:
					continue
				var key := String(parts[0]).uri_decode()
				var value := String(parts[1]).uri_decode()
				match key:
					"performance_scenario":
						values["scenario"] = value
					"performance_warmup":
						values["warmup"] = float(value)
					"performance_duration":
						values["duration"] = float(value)
	if not values.has("scenario"):
		return {}
	var scenario := PerformanceScenario.new()
	if not scenario.configure(StringName(values["scenario"])):
		push_error("Unknown performance scenario: %s" % String(values["scenario"]))
		return {}
	values["output"] = String(values.get(
		"output",
		"res://build/performance/%s.json" % String(values["scenario"])
	))
	values["warmup"] = maxf(0.0, float(values.get("warmup", 10.0)))
	values["duration"] = maxf(0.25, float(values.get("duration", 60.0)))
	return values


func _start_performance_scenario() -> void:
	_performance_scenario = PerformanceScenario.new()
	if not _performance_scenario.configure(StringName(_performance_request["scenario"])):
		return
	_performance_recorder = PerformanceRecorder.new()
	_performance_recorder.configure(
		StringName(_performance_request["scenario"]),
		String(_performance_request["output"]),
		float(_performance_request["warmup"]),
		float(_performance_request["duration"])
	)
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_performance_scenario.activate(self)
	_ui.show_gameplay()
	_set_mouse_for_mode()


func _finish_performance_scenario() -> void:
	_performance_finishing = true
	var validation := _performance_scenario.validation_snapshot(self)
	_performance_scenario.deactivate()
	_performance_recorder.finish(
		get_viewport(),
		validation,
		_performance_counts(),
		_combat_renderer.debug_snapshot(),
		enemy_grid.debug_snapshot()
	)
	if OS.has_feature("web"):
		mode = RunMode.PAUSED
		set_physics_process(false)
		set_process(false)
	else:
		get_tree().quit(0 if bool(validation.get("valid", false)) else 1)


func _performance_counts() -> Dictionary:
	return {
		"enemies": enemy_store.debug_snapshot(),
		"projectiles": projectile_store.debug_snapshot(),
		"experience": experience_runtime.shards.size(),
		"effects": effects.size(),
		"zones": denied_zones.size(),
		"trails": damaging_trails.size(),
		"layout":field_layout.debug_snapshot(current_stage_id) if field_layout != null else {},
		"collective_tactics":collective_tactics.debug_snapshot(),
		"boss_exam":boss_exam_runtime.snapshot(),
	}






# Pressure validation support --------------------------------------------------

func _debug_append_packet_enemies(limit: int) -> void:
	var appended := 0
	for spec in StageCatalog.packet_enemy_blueprint(current_stage_id):
		if appended >= limit:
			break
		var enemy := _make_enemy(spec)
		if enemy == null:
			break
		enemy.active = true
		_append_enemy(enemy)
		appended += 1
