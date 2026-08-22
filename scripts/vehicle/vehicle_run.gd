class_name VehicleRun
extends Node2D

## Runs the connected authored vehicle campaign and its combat state.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const HudPresenter = preload("res://scripts/ui/vehicle_hud_presenter.gd")
const ConditionalStatusSnapshot = preload(
	"res://scripts/ui/vehicle_conditional_status_snapshot.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload("res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const CollectiveTacticRuntime = preload(
	"res://scripts/encounters/vehicle_collective_tactic_runtime.gd"
)
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const LifestealRuntime = preload("res://scripts/cards/vehicle_lifesteal_runtime.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const PrimaryComboRuntime = preload("res://scripts/combat/vehicle_primary_combo_runtime.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const SpatialGrid = preload("res://scripts/combat/vehicle_spatial_grid.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const CombatRenderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const StageBackdrop = preload("res://scripts/vehicle/vehicle_stage_backdrop.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const BossShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const UpgradeOfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const LateBossMechanics = preload("res://scripts/bosses/vehicle_late_boss_mechanics.gd")
const BossDeathRuntime = preload("res://scripts/bosses/vehicle_boss_death_runtime.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const EnemySpeedProfile = preload("res://scripts/enemies/vehicle_enemy_speed_profile.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const RewardRuntime = preload("res://scripts/rewards/vehicle_reward_runtime.gd")
const PickupContact = preload("res://scripts/rewards/vehicle_pickup_contact.gd")
const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const StageTransitionRuntime = preload(
	"res://scripts/vehicle/vehicle_stage_transition_runtime.gd"
)
const PursuitField = preload("res://scripts/enemies/vehicle_pursuit_field.gd")
const EnemyMovementPolicy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const EnemyTargetingPolicy = preload(
	"res://scripts/enemies/vehicle_enemy_targeting_policy.gd"
)
const EngagementRelevancePolicy = preload(
	"res://scripts/enemies/vehicle_engagement_relevance_policy.gd"
)
const SecondaryRuntime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const ActiveWeaponRuntime = preload("res://scripts/player/vehicle_active_weapon_runtime.gd")
const RecallReplenishmentRuntime = preload("res://scripts/rewards/vehicle_recall_replenishment_runtime.gd")
const ActiveRechargeRuntime = preload(
	"res://scripts/player/vehicle_active_recharge_runtime.gd"
)
const GuidebookCatalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyUpdateSchedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")
const EnemyLocalSteering = preload("res://scripts/enemies/vehicle_enemy_local_steering.gd")
const EnemyContactRuntime = preload(
	"res://scripts/enemies/vehicle_enemy_contact_runtime.gd"
)
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const VisualEventCatalog = preload(
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)
const ThreatRadarFeed = preload(
	"res://scripts/presentation/vehicle_threat_radar_feed.gd"
)
const PerformanceRecorder = preload("res://scripts/performance/vehicle_performance_recorder.gd")
const PerformanceScenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const ManualPerformanceTrace = preload("res://scripts/performance/vehicle_manual_performance_trace.gd")
const SlowTickReceiptBuffer = preload(
	"res://scripts/performance/vehicle_slow_tick_receipt_buffer.gd"
)
const EngagementTelemetry = preload("res://scripts/performance/vehicle_engagement_telemetry.gd")
const FieldLayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const StageTacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")
const MysteryDeviceRuntime = preload(
	"res://scripts/vehicle/vehicle_mystery_device_runtime.gd"
)
const DamageSourceCatalog = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const StageTelemetry = preload("res://scripts/combat/vehicle_stage_telemetry.gd")
const BuildSnapshotBuilder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")
const ViewportSupplyPolicy = preload("res://scripts/rewards/vehicle_viewport_supply_policy.gd")
const PrimaryUpgradeRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)
const PlayerRecoveryPolicy = preload(
	"res://scripts/player/vehicle_player_recovery_policy.gd"
)
const DashUpgradeRuntime = preload(
	"res://scripts/player/vehicle_dash_upgrade_runtime.gd"
)
const StageReportBuilder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const RunResultBuilder = preload("res://scripts/combat/vehicle_run_result_builder.gd")
const CaptureDriver = preload("res://scripts/vehicle/vehicle_run_capture_driver.gd")
const CaptureGateway = preload("res://scripts/vehicle/vehicle_run_capture_gateway.gd")
const BuildIdentity = preload("res://scripts/diagnostics/vehicle_build_identity.gd")
const SessionSignalRecorder = preload(
	"res://scripts/diagnostics/vehicle_session_signal_recorder.gd"
)
const SessionDiagnosticStore = preload(
	"res://scripts/diagnostics/vehicle_session_diagnostic_store.gd"
)
const EncounterPacingCaptureDriver = preload(
	"res://scripts/diagnostics/vehicle_encounter_pacing_capture_driver.gd"
)
const DiagnosticExporter = preload(
	"res://scripts/diagnostics/vehicle_diagnostic_exporter.gd"
)

enum RunMode {
	DEPLOYMENT,
	PLAYING,
	UPGRADE,
	PAUSED,
	STAGE_REPORT,
	FAILURE_REPORT,
	RESULT,
}

const SAVE_PATH := "user://vehicle-run.cfg"
const TRANSIT_GATE_ASSET_ID := &"world/facility_transit_gate"
const PLAYER_MAX_HEALTH := 120.0
const PLAYER_BASE_SPEED := 280.0
const PLAYER_GRAVITY_RESPONSE_SPEED := 2400.0
const PRIMARY_RANGE := 1600.0
const PRIMARY_VISIBLE_RANGE_MARGIN := 80.0
const PRIMARY_PROJECTILE_SPEED := 1120.0
const PRIMARY_PROJECTILE_RADIUS := 7.0
const DASH_DURATION := 0.20
const DASH_SPEED := 1220.0
const DASH_COOLDOWN := 1.25
const MAX_DASH_AFTERIMAGES := 1
const SEEKER_RANGE := 560.0
const SEEKER_COOLDOWN := 1.35
const MINIMAP_COLS := 20
const MINIMAP_ROWS := 12
const MINIMAP_FRAME_COUNT := 2
const MINIMAP_MARKER_CAPACITY := EnemyStore.MAX_LIVE_HOSTILES + 24
const MINIMAP_PRIORITY_ENEMY_ROLES: Array[StringName] = [
	&"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01", &"ordinary_fixed_support_01",
]
const MINIMAP_STATIC_KEYS: Array[StringName] = [
	&"floor_polygons", &"void_polygons", &"blocker_polygons",
]
const THREAT_SCAN_DISTANCE := 1200.0
const ORDINARY_ARRIVAL_CUE_CAPACITY := 8
const ORDINARY_ARRIVAL_POST_BIRTH_HOLD := 1.10
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
const VISIBLE_SIMULATION_MARGIN := 240.0
const ENGAGEMENT_GAP_STEER_DELAY := 1.0
const ENGAGEMENT_GAP_SPEED_MULTIPLIER := 2.2
const THREAT_OFFSCREEN_BAND := 480.0
const FAR_ENEMY_SIMULATION_BUCKET_COUNT := 3
const PICKUP_BODY_RADIUS := Art.PICKUP_PLINTH_RADIUS
const CHARGE_PATH_SAMPLE_STEP := 8.0
const CHARGE_PATH_BINARY_STEPS := 8
# Prime relative to the six-way enemy decision buckets so profiling eventually
# observes every scheduling phase without timing every physics tick.
const PERFORMANCE_DETAIL_SAMPLE_STRIDE := 7
const PLAYER_HIT_FLASH_DURATION := 0.20
const PLAYER_BARRIER_HIT_FLASH_DURATION := 0.16
const PLAYER_HIT_INVULNERABILITY := 1.0
const CONTINUATION_FIRST_CUE_AT := 0.0
const CONTINUATION_FIRST_SPAWN_AT := 0.9
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
var stage_transition_runtime := StageTransitionRuntime.new()
var pursuit_field := PursuitField.new()
var secondary_runtime := SecondaryRuntime.new()
var active_weapon_runtime := ActiveWeaponRuntime.new()
var active_recharge_runtime := ActiveRechargeRuntime.new()
var terrain_runtime := TerrainRuntime.new()
var mystery_device_runtime := MysteryDeviceRuntime.new()
var stage_telemetry := StageTelemetry.new()
var boss_runtime := BossRuntime.new()
var boss_shield_runtime := BossShieldRuntime.new()
var boss_death_runtime := BossDeathRuntime.new()
var _dying_boss_id := ""
# The common barrage schedules exactly three rows and never allocates beyond it.
var _pending_boss_barrage_rows: Array[Dictionary] = []
const DISTANCE_GROWTH_LATERAL_OFFSET := 180.0
const DISTANCE_GROWTH_FORWARD_OFFSET := 72.0
var _boss_barrage_hit_lock_remaining := 0.0
var _runtime_blockers: Array[Rect2] = []
var _runtime_structural_walls: Array[Rect2] = []
var _motion_cover_static_safe := false
var _motion_cover_static_cover_clear := false

var player_position := Vector2.ZERO
var _player_combat_previous_position := Vector2.ZERO
var player_velocity := Vector2.ZERO
var player_hull_direction := Vector2.RIGHT
var player_aim_direction := Vector2.RIGHT
var player_health := PLAYER_MAX_HEALTH
var player_invulnerable := 0.0
var player_slow_timer := 0.0
var player_protection_sources: Dictionary = {}
var player_hit_flash := 0.0
var player_barrier_hit_flash := 0.0
var player_primary_weapon := PrimaryWeapon.new()
var _primary_shot_serial := 0
var _dash_action_serial := 0
var _damage_receipt_serial := 0
var player_muzzle_flash := 0.0
var player_dash_cooldown := 0.0
var player_dash_timer := 0.0
var player_dash_direction := Vector2.RIGHT
var player_dash_trail_timer := 0.0
var player_barrier_strength := 0.0
var player_barrier_timer := 0.0
var _aim_target_id := ""
var _last_damage_source := ""

var selected_primary := &"pulse_cannon"
var selected_run_difficulty: StringName = RunDifficulty.DEFAULT
var selected_upgrade_title_key := "UPGRADE_NONE"
var upgrade_catalog := UpgradeCatalog.new()
var run_build := RunBuild.new(upgrade_catalog)
var lifesteal_runtime := LifestealRuntime.new()
var dash_upgrade_runtime := DashUpgradeRuntime.new()
var primary_combo_runtime := PrimaryComboRuntime.new()
var _primary_shot_groups: Dictionary = {}
var _primary_payload: VehiclePrimaryPayloadProfile = PrimaryPayload.from_build(run_build)
var experience_runtime := ExperienceRuntime.new()
var applied_upgrades: Dictionary = run_build.levels
var current_card_offer: Array[Dictionary] = []
var upgrade_offer_error: Dictionary = {}
var upgrade_selection_applied := false
var reward_runtime := RewardRuntime.new()
var completed_group_rewards: Dictionary = {}
var experience_recall_timer := 0.0
var recall_replenishment_runtime := RecallReplenishmentRuntime.new()
var completed_stage_reports: Array[Dictionary] = []

var enemy_store := EnemyStore.new()
var _enemy_update_schedule := EnemyUpdateSchedule.new()
var _enemy_contact_runtime := EnemyContactRuntime.new()
var _enemy_frame_aggregate_valid := false
var _enemy_frame_active_mobile_count := 0
var _enemy_frame_visible_ordinary_count := 0
var _enemy_frame_attack_families: Array[StringName] = []
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
var _pickup_validation_anchors: Array[Vector2] = []
var denied_zones: Array[Dictionary] = []
var effect_store := EffectStore.new()
var effects: Array[VehicleEffectState] = effect_store.live
var _empty_cover_rects: Array[Rect2] = []
var _projectile_cover_query: Array[Rect2] = []
var _projectile_runtime_cover_query: Array[Rect2] = []
var _projectile_runtime_wall_query: Array[Rect2] = []
var _motion_cover_query: Array[Rect2] = []
var _motion_runtime_wall_query: Array[Rect2] = []
var _los_cover_query: Array[Rect2] = []
var _los_runtime_wall_query: Array[Rect2] = []
var _cover_hit_receipt: Dictionary = {"hit":false, "t":2.0}
var _cover_hit_candidate: Dictionary = {"hit":false, "t":2.0}
var _mystery_device_hit_receipt: Dictionary = {}
var _mystery_device_snapshot_buffer: Array[Dictionary] = []
var _mystery_device_event_buffer: Array[Dictionary] = []
var _mystery_device_result_receipt: Dictionary = {}
var _facility_modifier_buffer: Array[Dictionary] = []
var _runtime_fast_hud_frame: Dictionary = {}
var _runtime_minimap_frames: Array[Dictionary] = []
var _runtime_minimap_visited_buffers: Array = []
var _runtime_minimap_marker_buffers: Array = []
var _runtime_minimap_marker_pool: Array[Dictionary] = []
var _runtime_minimap_frame_index := -1
var _runtime_threat_radar_frame: Dictionary = {}
var _threat_radar_feed := ThreatRadarFeed.new(THREAT_SCAN_DISTANCE)
var _runtime_threat_scan_distance := THREAT_SCAN_DISTANCE
var _near_simulation_distance_squared := FAR_SIMULATION_DISTANCE_SQUARED
var _ordinary_arrival_cue_positions := PackedVector2Array()
var _ordinary_arrival_cue_remaining := PackedFloat32Array()
var _ordinary_arrival_cue_count := 0
var _runtime_combat_presentation_frame: Dictionary = {}
var _runtime_secondary_presentation_frame: Dictionary = {}
var _runtime_boss_shield_presentation_frame: Dictionary = {}
var _build_fast_hud_snapshot_callable: Callable
var _minimap_snapshot_callable: Callable
var _threat_radar_snapshot_callable: Callable
var _guidebook_snapshot_callable: Callable
var _runtime_line_of_sight_callable: Callable
var _query_enemy_radius_callable: Callable
var _enemy_find_callable: Callable
var _runtime_attack_path_callable: Callable
var _runtime_charge_path_callable: Callable
var _damage_player_callable: Callable
var _enemy_contact_damage_callable: Callable

var tutorial_move := false
var tutorial_aim := false
var tutorial_fire := false
var tutorial_dash := false
var tutorial_announced := false
var boss_started := false
var boss_phase_two_announced := false
var boss_arrival_position := Vector2.ZERO
var stage_complete := false
var _pending_continuation_layout: Variant
var _pending_continuation_stage_index := -1
var _pending_continuation_stage_id: StringName = &""
var _pending_final_result_snapshot: Dictionary = {}
var active_run_elapsed_seconds := 0.0
var stage_started_at_active_run_seconds := 0.0
var run_index := 0
var current_stage_index := 0
var current_stage_id: StringName = StageCatalog.STAGE_IDS[0]

var visited_cells: Dictionary = {}
var discovered_markers: Dictionary = {}
var _threat_sample_timer := 0.0
var _enemy_local_steering := EnemyLocalSteering.new()
## Per-actor Melee Ordinary Enemy Lv.2 stacks stay here rather than on pooled enemy state.
## The specialist runtime owns eligibility and modifier arithmetic.
var _ordinary_melee_02_stacks: Dictionary = {}
var _enemy_overlap_refresh_mask := PackedByteArray()
var _shielded_enemy_ids: Dictionary = {}
var _pending_shielded_enemy_ids: Dictionary = {}
var _shield_supports: Array[EnemyState] = []
var _enemy_decision_bucket := 0
var _enemy_decision_cycle_epoch := 0
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
var _performance_ablation: StringName = &"none"
var _performance_deep_owner: StringName = &"none"
var _performance_enemy_sections: Dictionary = {}
var _performance_detail_sample_active := false
var _slow_tick_coarse_ms := PackedFloat64Array()
var _slow_tick_scalars := PackedInt32Array()
var _slow_tick_spawn_count := 0
var _slow_tick_cue_count := 0
var _slow_tick_anomaly_scan_count := 0
var _slow_tick_recording_active := false
var _performance_subsystem_ms: Dictionary = {}
var _manual_performance_request: Dictionary = {}
var _manual_performance_trace: ManualPerformanceTrace
var _encounter_pacing_capture_request: Dictionary = {}
var _encounter_pacing_capture_driver: VehicleEncounterPacingCaptureDriver
var _engagement_telemetry: VehicleEngagementTelemetry
var _manual_performance_pressure: Dictionary = {}
var _manual_performance_context: Dictionary = {}
var _pending_stage_report: Dictionary = {}
var _session_diagnostics := SessionSignalRecorder.new()
var _latest_session_diagnostic: Dictionary = {}
var _diagnostic_arrivals_began: Dictionary = {}
var _diagnostic_first_visible := false
var _diagnostic_first_commit := false
var _diagnostic_visible_threat_current := false
var _visible_ordinary_threat_current := false
var _diagnostic_visible_gap_active := false
var _diagnostic_visible_gap_started := 0.0
var _diagnostic_visible_gap_event_count := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_slow_tick_coarse_ms.resize(SlowTickReceiptBuffer.coarse_field_count())
	_slow_tick_scalars.resize(SlowTickReceiptBuffer.scalar_field_count())
	_initialize_hud_staging()
	_build_fast_hud_snapshot_callable = Callable(
		self, "_runtime_fast_hud_snapshot"
	)
	_minimap_snapshot_callable = Callable(self, "_runtime_minimap_snapshot")
	_threat_radar_snapshot_callable = Callable(
		self, "_runtime_threat_radar_snapshot"
	)
	_guidebook_snapshot_callable = Callable(self, "_guidebook_snapshot")
	_runtime_line_of_sight_callable = Callable(
		self, "_runtime_has_line_of_sight"
	)
	_query_enemy_radius_callable = Callable(self, "_query_enemy_radius_into")
	_enemy_find_callable = Callable(enemy_store, "find")
	_runtime_attack_path_callable = Callable(self, "_runtime_attack_path_end")
	_runtime_charge_path_callable = Callable(self, "_runtime_charge_path_end")
	_damage_player_callable = Callable(self, "_damage_player")
	_enemy_contact_damage_callable = Callable(self, "_enemy_contact_damage")
	_enemy_contact_runtime.configure(
		_damage_player_callable, _enemy_contact_damage_callable
	)
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
	_manual_performance_request = _parse_manual_performance_request()
	_encounter_pacing_capture_request = _parse_encounter_pacing_capture_request()
	if (
		_capture_mode
		or not _performance_request.is_empty()
		or not _encounter_pacing_capture_request.is_empty()
	) and not _has_layout_seed_override:
		_layout_seed_override = FIXED_LAYOUT_SEED
		_has_layout_seed_override = true
	_build_backdrop()
	_build_combat_renderer()
	_build_camera()
	_build_ui()
	_build_audio()
	_load_persistence()
	selected_run_difficulty = RunDifficulty.HARD
	_reset_run(false)
	_present_deployment()
	_set_mouse_for_mode()
	queue_redraw()
	_prepare_manual_performance_trace()
	if _capture_mode:
		call_deferred("_start_capture")
	elif not _performance_request.is_empty():
		call_deferred("_start_performance_scenario")
	elif not _encounter_pacing_capture_request.is_empty():
		call_deferred("_start_encounter_pacing_capture")


func _initialize_hud_staging() -> void:
	if not _runtime_minimap_frames.is_empty():
		return
	for frame_index in MINIMAP_FRAME_COUNT:
		var visited: Array[Vector2i] = []
		visited.resize(MINIMAP_COLS * MINIMAP_ROWS)
		visited.clear()
		var markers: Array[Dictionary] = []
		markers.resize(MINIMAP_MARKER_CAPACITY)
		markers.clear()
		_runtime_minimap_visited_buffers.append(visited)
		_runtime_minimap_marker_buffers.append(markers)
		_runtime_minimap_frames.append({
			"cols":MINIMAP_COLS,
			"rows":MINIMAP_ROWS,
			"visited":visited,
			"player":Vector2.ZERO,
			"player_facing":Vector2.RIGHT,
			"world_size":Vector2.ZERO,
			"markers":markers,
		})
		for _marker_index in MINIMAP_MARKER_CAPACITY:
			_runtime_minimap_marker_pool.append({
				"kind":&"mobile_enemy",
				"position":Vector2.ZERO,
				"discovered":true,
			})
	_ordinary_arrival_cue_positions.resize(ORDINARY_ARRIVAL_CUE_CAPACITY)
	_ordinary_arrival_cue_remaining.resize(ORDINARY_ARRIVAL_CUE_CAPACITY)
	_runtime_threat_radar_frame = {
		"visible":false,
		"generation":0,
		"sample_origin":Vector2.ZERO,
		"max_distance":THREAT_SCAN_DISTANCE,
		"sectors":[],
	}


func _exit_tree() -> void:
	_finish_session_diagnostics("normal_exit")
	_finish_manual_performance_trace("normal_exit")
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
	_advance_active_run_clock(delta)
	var performance_active := is_instance_valid(_performance_recorder)
	var manual_trace_active := (
		is_instance_valid(_manual_performance_trace)
		and _manual_performance_trace.is_recording()
		and _simulation_active()
	)
	var timing_active := performance_active or manual_trace_active
	_slow_tick_recording_active = timing_active
	_performance_detail_sample_active = (
		timing_active
		and _physics_serial % PERFORMANCE_DETAIL_SAMPLE_STRIDE == 0
	)
	var physics_started := Time.get_ticks_usec() if timing_active else 0
	var subsystem_ms := _performance_subsystem_ms
	if timing_active:
		subsystem_ms.clear()
		_slow_tick_coarse_ms.fill(0.0)
		_slow_tick_scalars.fill(0)
		_slow_tick_spawn_count = 0
		_slow_tick_cue_count = 0
		_slow_tick_anomaly_scan_count = 0
	if _performance_detail_sample_active:
		_performance_enemy_sections.clear()
	if is_instance_valid(_performance_scenario) and mode == RunMode.PLAYING:
		_performance_scenario.before_physics(self, delta)
	if _simulation_active():
		var pickup_motion_start := player_position
		mystery_device_runtime.advance(delta, _mystery_device_event_buffer)
		for facility_event in _mystery_device_event_buffer:
			if StringName(facility_event.get("kind", &"")) == &"facility_lava_tick":
				_apply_lava_facility_tick(facility_event)
			else:
				_handle_mystery_device_event(facility_event)
		_simulation_lod_bucket = 1 - _simulation_lod_bucket
		_far_enemy_simulation_bucket = (
			(_far_enemy_simulation_bucket + 1)
			% FAR_ENEMY_SIMULATION_BUCKET_COUNT
		)
		var section_started := Time.get_ticks_usec() if timing_active else 0
		_update_player(delta)
		_refresh_visible_world_runtime_ranges()
		_refresh_viewport_supply(delta)
		var pickup_motion_end := player_position
		_update_terrain(delta, pickup_motion_start)
		_update_pickups(delta, pickup_motion_start, pickup_motion_end)
		recall_replenishment_runtime.advance(delta, active_run_elapsed_seconds, pickups)
		if experience_recall_timer > 0.0:
			_update_experience(delta)
		elif _simulation_lod_bucket == 0:
			_update_experience(delta * 2.0)
		if timing_active:
			_slow_tick_coarse_ms[0] = _elapsed_ms(section_started)
		if _performance_detail_sample_active:
			subsystem_ms["player_and_rewards"] = _slow_tick_coarse_ms[0]
		if timing_active:
			section_started = Time.get_ticks_usec()
		_update_encounter(delta)
		var pursuit_started := (
			Time.get_ticks_usec()
			if timing_active and _performance_deep_owner == &"pursuit"
			else 0
		)
		pursuit_field.update(
			delta, player_position, _slow_tick_recording_active
		)
		if pursuit_started > 0:
			subsystem_ms["deep_pursuit"] = _elapsed_ms(pursuit_started)
		if timing_active:
			_slow_tick_coarse_ms[1] = _elapsed_ms(section_started)
		if _performance_detail_sample_active:
			subsystem_ms["encounter_and_pursuit"] = _slow_tick_coarse_ms[1]
		if timing_active:
			section_started = Time.get_ticks_usec()
		_update_enemies(delta, pickup_motion_start)
		_update_threat_contacts(delta)
		if timing_active:
			_slow_tick_coarse_ms[2] = _elapsed_ms(section_started)
		if _performance_detail_sample_active:
			subsystem_ms["enemies_and_grid"] = _slow_tick_coarse_ms[2]
		if timing_active:
			section_started = Time.get_ticks_usec()
		if _performance_ablation != &"attacks":
			_update_projectiles(delta, pickup_motion_start)
		var effects_started := (
			Time.get_ticks_usec() if _performance_detail_sample_active else 0
		)
		_update_denied_zones(delta, pickup_motion_start)
		if _simulation_lod_bucket == 0:
			_update_effects(delta * 2.0)
		if _performance_detail_sample_active:
			_performance_enemy_sections["zones_and_effects"] = _elapsed_ms(
				effects_started
			)
			for section_name in _performance_enemy_sections:
				subsystem_ms["enemy_%s" % String(section_name)] = (
					_performance_enemy_sections[section_name]
				)
		if timing_active:
			_slow_tick_coarse_ms[3] = _elapsed_ms(section_started)
		if _performance_detail_sample_active:
			subsystem_ms["combat_and_effects"] = _slow_tick_coarse_ms[3]
		if timing_active:
			section_started = Time.get_ticks_usec()
		_update_stage_progression(delta)
		var transition_flush_diagnostics := (
			stage_transition_runtime.active()
			and _session_diagnostics.is_active()
		)
		var transition_flush_started := (
			Time.get_ticks_usec() if transition_flush_diagnostics else 0
		)
		var flushed_defeats := _flush_defeated_enemies()
		if flushed_defeats > 0:
			enemy_grid.sync(enemies)
		if transition_flush_diagnostics:
			_session_diagnostics.emit_event("stage_transition_flush", {
				"elapsed_ms":float(
					Time.get_ticks_usec() - transition_flush_started
				) / 1000.0,
				"flushed_defeats":flushed_defeats,
				"live_enemies":enemy_store.live_count(),
			})
		_advance_stage_transition()
		if is_instance_valid(_engagement_telemetry):
			_engagement_telemetry.advance(
				delta, encounter_runtime, enemies, player_position, player_velocity
			)
		if timing_active:
			_slow_tick_coarse_ms[4] = _elapsed_ms(section_started)
		if _performance_detail_sample_active:
			subsystem_ms["progression_and_cleanup"] = _slow_tick_coarse_ms[4]
	else:
		_update_effects(delta)
	_update_camera(delta)
	var deferred_scenario_diagnostic := false
	if is_instance_valid(_performance_scenario) and mode == RunMode.PLAYING:
		deferred_scenario_diagnostic = (
			_performance_scenario.after_physics_is_diagnostic_only()
		)
		if not deferred_scenario_diagnostic:
			_performance_scenario.after_physics(self)
	var physics_total_ms := _elapsed_ms(physics_started) if timing_active else 0.0
	if deferred_scenario_diagnostic:
		_performance_scenario.after_physics(self)
	if is_instance_valid(_encounter_pacing_capture_driver):
		if _encounter_pacing_capture_driver.after_physics(self):
			get_tree().quit(0 if _encounter_pacing_capture_driver.succeeded() else 1)
	if timing_active:
		_fill_slow_tick_receipt_scalars()
	if performance_active:
		_performance_recorder.record_physics(physics_total_ms, subsystem_ms)
		_performance_recorder.record_slow_tick_receipt(
			_physics_serial,
			physics_total_ms,
			_slow_tick_coarse_ms,
			_slow_tick_scalars
		)
	if manual_trace_active:
		_manual_performance_trace.record_physics(
			physics_total_ms, subsystem_ms
		)
		_manual_performance_trace.record_slow_tick_receipt(
			_physics_serial,
			physics_total_ms,
			_slow_tick_coarse_ms,
			_slow_tick_scalars
		)
	_physics_serial += 1
	_slow_tick_recording_active = false


func _process(delta: float) -> void:
	var performance_active := is_instance_valid(_performance_recorder)
	if (
		performance_active
		and not OS.has_feature("web")
		and not DisplayServer.window_is_focused()
		and DisplayServer.has_method("window_move_to_foreground")
	):
		# Native qualification rejects even transient background samples. Reclaim
		# focus before the recorder observes this rendered frame.
		DisplayServer.window_move_to_foreground()
	var manual_trace_recording := (
		is_instance_valid(_manual_performance_trace)
		and _manual_performance_trace.is_recording()
	)
	var manual_frame_active := (
		manual_trace_recording
		and (
			_simulation_active()
			or _manual_performance_trace.has_pending_physics()
		)
	)
	var timing_active := performance_active or manual_frame_active
	var hud_ms := 0.0
	var presentation_ms := 0.0
	player_hit_flash = maxf(0.0, player_hit_flash - delta)
	player_barrier_hit_flash = maxf(0.0, player_barrier_hit_flash - delta)
	player_muzzle_flash = maxf(0.0, player_muzzle_flash - delta)
	camera_shake = maxf(0.0, camera_shake - delta * 18.0)
	if is_instance_valid(_ui) and (_simulation_active() or _capture_mode):
		var hud_started := Time.get_ticks_usec() if timing_active else 0
		_ui.update_threat_anchor(
			player_position,
			get_canvas_transform() * player_position,
			_simulation_active()
		)
		var hud_update := _hud_presenter.advance(
			delta,
			_build_fast_hud_snapshot_callable,
			_minimap_snapshot_callable,
			_threat_radar_snapshot_callable,
			_guidebook_snapshot_callable
		)
		if not hud_update.is_empty():
			_ui.update_hud(hud_update)
		if timing_active:
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
		and _performance_ablation != &"presentation"
		and (
			_presented_physics_serial != _physics_serial
			or _last_presentation_active != presentation_active
		)
	):
		var presentation_started := Time.get_ticks_usec() if timing_active else 0
		_combat_renderer.sync(
			enemies,
			player_projectiles,
			hostile_projectiles,
			experience_runtime.shards,
			effects,
			_visible_world_rect(0.0),
			player_position,
			active_run_elapsed_seconds,
			presentation_active,
			_aim_target_id,
			_runtime_combat_presentation_snapshot(),
			delta
		)
		if timing_active:
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
	if manual_trace_recording:
		var active_simulation := (
			_simulation_active()
			or _manual_performance_trace.has_pending_physics()
		)
		if active_simulation:
			_fill_manual_performance_frame()
		_manual_performance_trace.advance_frame(
			delta,
			presentation_ms,
			hud_ms,
			get_viewport(),
			_manual_performance_pressure,
			_manual_performance_context,
			active_simulation
		)
	if _run_clock_active():
		_session_diagnostics.advance_frame(
			delta,
			delta * 1000.0,
			enemy_store.live_count(),
			_diagnostic_visible_threat_current,
			current_stage_index,
			_diagnostic_run_mode_id()
		)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "VehicleCamera"
	_camera.enabled = true
	_camera.zoom = Rules.GAMEPLAY_CAMERA_ZOOM
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
	_ui.upgrade_selected.connect(_on_upgrade_selected)
	_ui.upgrade_previewed.connect(_on_upgrade_previewed)
	_ui.pause_requested.connect(_pause_run)
	_ui.resume_requested.connect(_resume_run)
	_ui.deployment_requested.connect(_return_to_deployment)
	_ui.stage_report_continued.connect(_continue_stage_report)
	_ui.diagnostic_export_requested.connect(_export_session_diagnostics)
	_ui.gameplay_announcement_receipt.connect(_on_gameplay_announcement_receipt)


func _on_upgrade_previewed(upgrade_id: StringName) -> void:
	_play_sound(&"upgrade_select")
	_session_diagnostics.emit_event("upgrade_focused", {
		"upgrade_id":upgrade_id,
		"stage_index":current_stage_index,
	})


func _on_gameplay_announcement_receipt(receipt: Dictionary) -> void:
	var status := StringName(receipt.get("status", &""))
	if status not in [&"queued", &"shown", &"interrupted", &"dropped"]:
		return
	_session_diagnostics.emit_event("announcement_%s" % status, {
		"semantic_id":StringName(receipt.get("semantic_id", &"system")),
		"priority":int(receipt.get("priority", 1)),
		"reason":StringName(receipt.get("reason", &"")),
	})


func _reset_stage_diagnostic_signals() -> void:
	_diagnostic_arrivals_began.clear()
	_diagnostic_first_visible = false
	_diagnostic_first_commit = false
	_diagnostic_visible_threat_current = false
	_visible_ordinary_threat_current = false
	_diagnostic_visible_gap_active = true
	_diagnostic_visible_gap_started = active_run_elapsed_seconds
	_diagnostic_visible_gap_event_count = 0


func _record_diagnostic_arrival_began(enemy: EnemyState) -> void:
	if not _session_diagnostics.is_active():
		return
	var arrival_id := StringName(enemy.squad_id)
	if arrival_id.is_empty() or _diagnostic_arrivals_began.has(arrival_id):
		return
	_diagnostic_arrivals_began[arrival_id] = true
	_session_diagnostics.emit_event("arrival_began", {
		"arrival_id":arrival_id,
		"stage_index":current_stage_index,
	})


func _record_diagnostic_threat_sample(
	visible_threat: bool,
	ordinary_commit: bool
) -> void:
	_diagnostic_visible_threat_current = visible_threat
	var retain_pacing_capture_flags := is_instance_valid(
		_encounter_pacing_capture_driver
	)
	if not _session_diagnostics.is_active() and not retain_pacing_capture_flags:
		return
	if visible_threat and not _diagnostic_first_visible:
		_diagnostic_first_visible = true
		if _session_diagnostics.is_active():
			_session_diagnostics.emit_event("first_visible", {
				"stage_index":current_stage_index,
			})
	if ordinary_commit and not _diagnostic_first_commit:
		_diagnostic_first_commit = true
		if _session_diagnostics.is_active():
			_session_diagnostics.emit_event("first_commit", {
				"stage_index":current_stage_index,
			})
	if not visible_threat:
		if not _diagnostic_visible_gap_active:
			_diagnostic_visible_gap_active = true
			_diagnostic_visible_gap_started = active_run_elapsed_seconds
		return
	if not _diagnostic_visible_gap_active:
		return
	var gap_seconds := maxf(
		0.0,
		active_run_elapsed_seconds - _diagnostic_visible_gap_started
	)
	_diagnostic_visible_gap_active = false
	if gap_seconds < 0.4 or _diagnostic_visible_gap_event_count >= 16:
		return
	_diagnostic_visible_gap_event_count += 1
	if _session_diagnostics.is_active():
		_session_diagnostics.emit_event("visible_gap_closed", {
			"stage_index":current_stage_index,
			"gap_seconds":gap_seconds,
		})


func _begin_session_diagnostics() -> void:
	if DisplayServer.get_name() == "headless" or _capture_mode or not _performance_request.is_empty() or not _encounter_pacing_capture_request.is_empty():
		return
	var session_id := "session-%d-%d-%d" % [
		int(Time.get_unix_time_from_system()),
		Time.get_ticks_usec(),
		run_index,
	]
	if not _session_diagnostics.begin(
		session_id,
		BuildIdentity.evidence_identity(),
		_diagnostic_session_context()
	):
		return
	_session_diagnostics.emit_event("stage_started", {
		"stage_id":current_stage_id,
		"stage_index":current_stage_index,
	})


func _diagnostic_session_context() -> Dictionary:
	var settings := get_node_or_null("/root/SettingsStore")
	var viewport_width := get_viewport_rect().size.x
	return {
		"locale":StringName(TranslationServer.get_locale().left(2)),
		"viewport_class":StringName(
			"compact"
			if viewport_width < 1100.0
			else ("large" if viewport_width >= 1600.0 else "standard")
		),
		"reduced_motion":(
			bool(settings.reduced_motion) if settings != null else false
		),
		"renderer":StringName(RenderingServer.get_current_rendering_method()),
	}


func _diagnostic_run_mode_id() -> StringName:
	match mode:
		RunMode.PLAYING:
			return &"playing"
		RunMode.PAUSED:
			return &"paused"
		RunMode.UPGRADE:
			return &"upgrade"
		RunMode.STAGE_REPORT:
			return &"stage_report"
		RunMode.FAILURE_REPORT:
			return &"failure_report"
		RunMode.RESULT:
			return &"result"
	return &"deployment"


func _checkpoint_session_diagnostics(reason: String) -> void:
	var bundle := _session_diagnostics.checkpoint(reason)
	if bundle.is_empty():
		return
	_latest_session_diagnostic = bundle
	var error := SessionDiagnosticStore.persist_completed(bundle)
	if error != OK:
		push_warning("Session diagnostic checkpoint was not persisted: %s" % error_string(error))


func _finish_session_diagnostics(reason: String) -> void:
	var bundle := _session_diagnostics.finish(reason)
	if bundle.is_empty():
		return
	_latest_session_diagnostic = bundle
	var error := SessionDiagnosticStore.persist_completed(bundle)
	if error != OK:
		push_warning("Session diagnostic result was not persisted: %s" % error_string(error))


func _export_session_diagnostics(absolute_path: String) -> void:
	var bundle := _latest_session_diagnostic
	if _session_diagnostics.is_active():
		bundle = _session_diagnostics.checkpoint("explicit_export")
		if not bundle.is_empty():
			_latest_session_diagnostic = bundle
			var persist_error := SessionDiagnosticStore.persist_completed(bundle)
			if persist_error != OK:
				push_warning(
					"Session diagnostic export checkpoint was not persisted: %s"
					% error_string(persist_error)
				)
	if bundle.is_empty():
		var retained := SessionDiagnosticStore.load_completed()
		if not retained.is_empty():
			bundle = retained.back()
	if bundle.is_empty():
		_ui.set_diagnostic_export_status("DIAGNOSTICS_EXPORT_NO_DATA")
		return
	if OS.has_feature("web"):
		var redacted := DiagnosticExporter.make_redacted_bundle(bundle)
		JavaScriptBridge.download_buffer(
			JSON.stringify(redacted).to_utf8_buffer(),
			"cardborne-diagnostics.json",
			"application/json"
		)
		_ui.set_diagnostic_export_status("DIAGNOSTICS_EXPORT_SUCCESS")
		return
	var error := DiagnosticExporter.write_native(bundle, absolute_path)
	_ui.set_diagnostic_export_status(
		"DIAGNOSTICS_EXPORT_SUCCESS"
		if error == OK
		else "DIAGNOSTICS_EXPORT_FAILED"
	)


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
	_preserve_field_state: bool = false
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
	mode = RunMode.DEPLOYMENT
	stage_transition_runtime.reset()
	_pending_continuation_layout = null
	_pending_continuation_stage_index = -1
	_pending_continuation_stage_id = &""
	_pending_final_result_snapshot.clear()
	player_position = Rules.player_start(current_stage_id)
	_player_combat_previous_position = player_position
	player_velocity = Vector2.ZERO
	player_slow_timer = 0.0
	player_hull_direction = Vector2.RIGHT
	player_aim_direction = Vector2.RIGHT
	player_health = _player_max_health()
	player_invulnerable = 0.0
	player_protection_sources.clear()
	player_hit_flash = 0.0
	player_barrier_hit_flash = 0.0
	player_primary_weapon.reset()
	_primary_shot_serial = 0
	primary_combo_runtime.reset()
	_primary_shot_groups.clear()
	_dash_action_serial = 0
	_damage_receipt_serial = 0
	player_dash_cooldown = 0.0
	player_dash_timer = 0.0
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	_aim_target_id = ""
	_last_damage_source = ""

	if not preserve_upgrades:
		run_build.reset()
		stage_telemetry.reset_run()
		encounter_runtime.reset_run()
		experience_runtime.reset()
		reward_runtime.reset_run()
		completed_stage_reports.clear()
		selected_upgrade_title_key = "UPGRADE_NONE"
	else:
		stage_telemetry.reset_stage()
		experience_runtime.clear_shards()
		experience_runtime.clear_pending_levels()
		reward_runtime.reset_stage()
	_primary_payload = PrimaryPayload.from_build(run_build)
	lifesteal_runtime.reset(run_build.stat(&"lifesteal_percent", 0.0))
	secondary_runtime.reset(player_position)
	active_weapon_runtime.reset(player_position)
	active_weapon_runtime.configure(run_build)
	active_recharge_runtime.reset()
	dash_upgrade_runtime.reset()
	experience_recall_timer = 0.0
	recall_replenishment_runtime.reset()
	player_health = _player_max_health()
	current_card_offer.clear()
	upgrade_offer_error.clear()
	upgrade_selection_applied = false
	_clear_enemies()
	_ordinary_melee_02_stacks.clear()
	_clear_projectiles()
	pickups.clear()
	denied_zones.clear()
	_clear_effects()
	encounter_runtime.configure(
		current_stage_id,
		StageCatalog.packets(current_stage_id),
		selected_run_difficulty,
		_active_tactical_layout.ordinary_spawn_anchors,
		_active_tactical_layout.encounter_seed,
		_active_tactical_layout.geometry_snapshot,
		current_stage_index
	)
	stage_flow.configure(
		current_stage_index,
		RunDifficulty.scaled_quota(StageCatalog.quota(current_stage_id), selected_run_difficulty),
		StageCatalog.has_boss(current_stage_id)
	)
	_configure_stage_map_runtime()
	_rebuild_runtime_blockers()
	pursuit_field.reset(current_stage_id, _runtime_cover_rects())
	_populate_stage_items()

	tutorial_move = false
	tutorial_aim = false
	tutorial_fire = false
	tutorial_dash = false
	tutorial_announced = false
	boss_started = false
	boss_shield_runtime.configure(current_stage_id)
	boss_death_runtime.reset()
	_dying_boss_id = ""
	_pending_boss_barrage_rows.clear()
	boss_runtime.clear_pending_attacks()
	_boss_barrage_hit_lock_remaining = 0.0
	boss_phase_two_announced = false
	boss_arrival_position = Vector2.ZERO
	stage_complete = false
	completed_group_rewards.clear()
	_pending_stage_report.clear()
	if not preserve_upgrades:
		_reset_active_run_clock()
	stage_started_at_active_run_seconds = active_run_elapsed_seconds
	if not preserve_upgrades:
		visited_cells.clear()
	discovered_markers.clear()
	_reset_threat_radar_feed()
	_clear_ordinary_arrival_cues()
	_threat_sample_timer = 0.0
	_shielded_enemy_ids.clear()
	_pending_shielded_enemy_ids.clear()
	_shield_supports.clear()
	_enemy_decision_bucket = 0
	_enemy_decision_cycle_epoch = 0
	_simulation_lod_bucket = 0
	_far_enemy_simulation_bucket = 0
	_enemy_coordination_initialized = false
	_enemy_overlap_refresh_mask.resize(SpatialGrid.MAX_TRACKED_ACTORS)
	_enemy_overlap_refresh_mask.fill(0)
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


func _configure_stage_map_runtime() -> void:
	terrain_runtime.configure(field_layout.run_feature_blueprint())
	_configure_stage_local_runtime()


func _configure_stage_local_runtime() -> void:
	mystery_device_runtime.configure(
		_active_tactical_layout.mystery_device_blueprint(),
		field_layout.seed,
		current_stage_id
	)
	_refresh_pressure_observation_mode()
	_mystery_device_result_receipt.clear()
	_reset_stage_diagnostic_signals()


func _populate_stage_items() -> void:
	pickups.clear()
	_pickup_validation_anchors.clear()
	for spec in _active_tactical_layout.pickup_blueprint():
		_pickup_validation_anchors.append(Vector2(spec["pos"]))
		if StringName(spec["kind"]) == &"experience_shard":
			experience_runtime.spawn_shard(
				Vector2(spec["pos"]), int(spec.get("experience", 5)), &"", true
			)
			continue
		pickups.append({
			"id": String(spec["id"]),
			"kind": StringName(spec["kind"]),
			"pos": Vector2(spec["pos"]),
			"active": true,
			"published": false,
			"published_elapsed": 0.0,
			"pulse": _rng.randf_range(0.0, TAU),
			"heal_amount": float(spec.get("heal_amount", 0.0)),
		})


func _make_enemy(spec: Dictionary) -> EnemyState:
	var enemy: EnemyState = enemy_store.acquire()
	if enemy == null:
		return null
	var archetype := StringName(spec["role"])
	var definition := EnemyArchetypes.definition(archetype)
	var family := StringName(spec.get(
		"family", spec.get("pack_family", definition.get("family", &""))
	))
	var pack_family := StringName(spec.get("pack_family", family))
	var pack_trait := StringName(spec.get("pack_trait", &""))
	var family_trait := StringName(spec.get(
		"family_trait", pack_trait if family == pack_family else &""
	))
	var role := StringName(definition["behavior"])
	if family == &"emitter" and family_trait == &"artillery":
		role = &"ordinary_growth_01"
	var attack_cooldown := _rng.randf_range(0.4, 1.2) / EncounterDirector.ENEMY_RECOVERY_RATE
	var health := float(definition["health"])
	var health_class := StringName(definition["health_class"])
	var stage_curve := StageDifficulty.multipliers(current_stage_index)
	var difficulty_profile := RunDifficulty.profile(selected_run_difficulty)
	if health_class in [&"swarm", &"standard"]:
		health *= EncounterDirector.ENEMY_HEALTH_MULTIPLIER
	if archetype == &"boss_actor":
		health = StageDifficulty.boss_health(current_stage_index)
	else:
		health *= (
			StageDifficulty.ordinary_health_multiplier(current_stage_index)
			* float(stage_curve["ordinary_health_pressure"])
			* float(difficulty_profile["health"])
			* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER
			* StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER
		)
	var position: Vector2 = spec["pos"]
	var speed := EnemySpeedProfile.effective_speed(archetype, current_stage_index, selected_run_difficulty)
	if family_trait == &"frenzy":
		speed *= FamilyTraits.FRENZY_SPEED_MULTIPLIER
		attack_cooldown *= FamilyTraits.FRENZY_CADENCE_MULTIPLIER
	enemy.id = String(spec.get("id", role))
	enemy.role = role
	enemy.archetype = archetype
	enemy.family = family
	enemy.tier = int(spec.get("tier", spec.get("pack_tier", definition.get("tier", 0))))
	enemy.size_percent = int(definition.get("size_percent", 100))
	enemy.family_trait = family_trait
	enemy.pack_family = pack_family
	enemy.pack_trait = pack_trait
	enemy.movement_family = EnemyMovementPolicy.family(archetype, role)
	enemy.name = String(spec.get("name_key", definition["name_key"]))
	enemy.pos = position
	enemy.home = position
	enemy.velocity = Vector2.ZERO
	enemy.desired_velocity = Vector2.ZERO
	var initial_facing := (player_position - position).normalized()
	enemy.presentation_facing = (
		initial_facing if not initial_facing.is_zero_approx() else Vector2.RIGHT
	)
	enemy.health = health
	enemy.max_health = health
	enemy.speed = speed
	enemy.radius = float(definition["radius"])
	enemy.visual_radius = (
		Art.enemy_visual_radius(archetype) * float(enemy.size_percent) / 100.0
	)
	enemy.projectile_hit_radius = EnemyArchetypes.projectile_target_radius(archetype)
	enemy.health_class = health_class
	enemy.health_visible_timer = 0.0
	enemy.threat_cost = float(definition["threat_cost"])
	enemy.threat_kind = (
		&"denial"
		if family == &"emitter" and family_trait == &"artillery"
		else StringName(definition["threat_kind"])
	)
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
	enemy.movement_reason = &"none"
	enemy.shield_source = &"none"
	enemy.support_tick = 0.0
	enemy.repair_target_id = ""
	enemy.intercept_charges = 3 if role == &"ordinary_fixed_ranged_02" else 0
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
	enemy.leash_rect = Rect2(spec.get("leash_rect", Rect2()))
	enemy.required = bool(spec.get("required", false))
	enemy.optional = bool(spec.get("optional", false))
	enemy.ram_cooldown = 0.0
	enemy.pattern_index = 0
	enemy.boss_phase = 1
	enemy.boss_variant = StringName(spec.get("boss_variant", &"boss_stage_01"))
	enemy.boss_shield_state = StringName(spec.get("boss_shield_state", &""))
	enemy.boss_attack_damage_multiplier = 1.0
	enemy.pattern = &""
	enemy.last_pattern = &""
	enemy.pattern_timer = 0.0
	enemy.mechanic_state = &""
	enemy.mechanic_cue_active = false
	enemy.mechanic_inner_radius = 0.0
	enemy.mechanic_outer_radius = 0.0
	enemy.pattern_tick = 0.0
	enemy.pattern_volleys = 0
	enemy.vulnerable = 0.0
	enemy.armor_structure = 0.0
	enemy.guard_plate_structure = (
		SpecialistRuntime.GUARD_PLATE_STRUCTURE
		if enemy.family == &"defender" else 0.0
	)
	enemy.mine_armed_by_player = false
	enemy.mine_fast_cue_played = false
	enemy.splitter_spawned = false
	enemy.reset_runtime_collections()
	enemy.escort_target_id = String(spec.get("escort_target_id", ""))
	var engagement_handle: Dictionary = spec.get("engagement_handle", {})
	if not engagement_handle.is_empty():
		enemy.engagement_slot = int(engagement_handle.get("slot", -1))
		enemy.engagement_generation = int(engagement_handle.get("generation", 0))
		enemy.engagement_gate = Vector2(spec.get("engagement_gate", position))
		enemy.engagement_expiry = float(spec.get("engagement_expiry", 0.0))
		enemy.engagement_started_at = float(spec.get("engagement_started_at", encounter_runtime.elapsed))
		enemy.engagement_active = enemy.engagement_slot >= 0
	# The store assigns the stable runtime slot during admission. `_append_enemy`
	# maps that slot to a decision lane so authored ID patterns cannot cluster work.
	enemy.decision_bucket = 0
	return enemy


func _append_enemy(enemy: EnemyState) -> bool:
	if enemy == null:
		return false
	# VehicleEnemyStore returns rejected pooled actors immediately, which clears
	# their scalar fields. Retain the cold reservation handle before admission.
	var engagement_handle := (
		_enemy_engagement_handle(enemy) if enemy.engagement_active else {}
	)
	var added := enemy_store.add(enemy)
	if added:
		# Pool slots are dense and recycled, which keeps all six 10 Hz lanes
		# balanced without reducing any actor's decision cadence or accuracy.
		enemy.decision_bucket = posmod(
			enemy.runtime_slot, ORDINARY_DECISION_BUCKET_COUNT
		)
		if enemy.engagement_active:
			encounter_runtime.confirm_engagement(engagement_handle)
		collective_tactics.register_enemy(enemy)
		enemy_grid.update_actor(enemy)
		_note_enemy_frame_aggregate_added(enemy)
	elif not engagement_handle.is_empty():
		encounter_runtime.cancel_engagement(engagement_handle)
	return added


func _enemy_engagement_handle(enemy: EnemyState) -> Dictionary:
	return {"slot":enemy.engagement_slot, "generation":enemy.engagement_generation}


func _release_enemy_engagement(enemy: EnemyState, outcome: StringName = &"release") -> void:
	if enemy == null or not enemy.engagement_active:
		return
	var handle := _enemy_engagement_handle(enemy)
	if outcome == &"complete":
		encounter_runtime.complete_engagement(handle)
	elif outcome == &"expire":
		encounter_runtime.expire_engagement(handle, encounter_runtime.elapsed)
	else:
		encounter_runtime.release_engagement(handle)
	enemy.engagement_active = false
	enemy.engagement_slot = -1
	enemy.engagement_generation = 0
	enemy.engagement_gate = Vector2.ZERO
	enemy.engagement_expiry = 0.0
	enemy.engagement_started_at = 0.0
	enemy.engagement_last_player_distance = -1.0
	enemy.engagement_divergence_started_at = -1.0


func _clear_enemies() -> void:
	_enemy_frame_aggregate_valid = false
	collective_tactics.reset()
	_ordinary_melee_02_stacks.clear()
	for enemy in enemies:
		_release_enemy_engagement(enemy)
	enemy_store.clear()
	enemy_grid.rebuild(enemies)


func _flush_defeated_enemies() -> int:
	return enemy_store.flush_defeated()


func _clear_projectiles() -> void:
	projectile_store.clear()
	_primary_shot_groups.clear()


func _rebuild_enemy_runtime_indexes() -> void:
	enemy_store.rebuild_index()
	enemy_grid.rebuild(enemies)


func _simulation_active() -> bool:
	return mode == RunMode.PLAYING


func _run_clock_active() -> bool:
	return mode in [RunMode.PLAYING, RunMode.UPGRADE]


func _advance_active_run_clock(delta: float) -> void:
	if _run_clock_active():
		active_run_elapsed_seconds += maxf(0.0, delta)


func _reset_active_run_clock() -> void:
	active_run_elapsed_seconds = 0.0
	stage_started_at_active_run_seconds = 0.0


func _update_encounter(delta: float) -> void:
	_refresh_enemy_frame_aggregate()
	_advance_ordinary_arrival_cues(delta)
	var requests := encounter_runtime.tick(
		delta,
		_enemy_frame_active_mobile_count,
		_enemy_frame_attack_families,
		player_position,
		_visible_world_rect(0.0),
		enemies,
		projectile_store.hostile_count(),
		player_velocity,
		_visible_ordinary_threat_current,
		_enemy_frame_visible_ordinary_count
	)
	if _slow_tick_recording_active:
		_slow_tick_cue_count = Array(requests["cues"]).size()
		_slow_tick_spawn_count = Array(requests["spawns"]).size()
	for cue in requests["cues"]:
		var cue_record := Dictionary(cue)
		_record_ordinary_arrival_cue(cue_record)
		_session_diagnostics.emit_event("arrival_cued", {
			"arrival_id":StringName(cue_record.get("squad_id", &"")),
			"stage_index":current_stage_index,
			"unit_count":int(cue_record.get("unit_count", 0)),
		})
		_play_sound(&"boss", 0.72)
	for spawn_spec in requests["spawns"]:
		var bounded_spec := _bounded_spawn_spec(Dictionary(spawn_spec))
		var enemy := _make_enemy(bounded_spec)
		if enemy == null:
			if enemy_store.live_count() >= EnemyStore.MAX_LIVE_HOSTILES:
				_refresh_nearest_ordinary_pursuit()
			encounter_runtime.note_spawn_materialization_failed(bounded_spec)
			continue
		if _append_enemy(enemy):
			_record_diagnostic_arrival_began(enemy)
		else:
			encounter_runtime.note_spawn_materialization_failed(bounded_spec)


func _refresh_nearest_ordinary_pursuit() -> void:
	var nearest: EnemyState = null
	var nearest_distance := INF
	for enemy in enemies:
		if not enemy.alive or enemy.role == &"boss":
			continue
		var distance := enemy.pos.distance_squared_to(player_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	if nearest == null:
		return
	nearest.active = true
	var direction := (player_position - nearest.pos).normalized()
	nearest.desired_velocity = direction * _effective_enemy_speed(nearest)
	nearest.attack_cooldown = minf(nearest.attack_cooldown, 0.10)

func _record_ordinary_arrival_cue(cue: Dictionary) -> void:
	if not cue.has("birth_position"):
		return
	var slot := _ordinary_arrival_cue_count
	if slot < ORDINARY_ARRIVAL_CUE_CAPACITY:
		_ordinary_arrival_cue_count += 1
	else:
		slot = 0
		for index in range(1, ORDINARY_ARRIVAL_CUE_CAPACITY):
			if (
				_ordinary_arrival_cue_remaining[index]
				< _ordinary_arrival_cue_remaining[slot]
			):
				slot = index
	_ordinary_arrival_cue_positions[slot] = Vector2(cue["birth_position"])
	_ordinary_arrival_cue_remaining[slot] = (
		maxf(0.0, float(cue.get("visual_duration", 0.0)))
		+ ORDINARY_ARRIVAL_POST_BIRTH_HOLD
	)


func _advance_ordinary_arrival_cues(delta: float) -> void:
	var step := maxf(0.0, delta)
	var index := 0
	while index < _ordinary_arrival_cue_count:
		_ordinary_arrival_cue_remaining[index] -= step
		if _ordinary_arrival_cue_remaining[index] > 0.0:
			index += 1
			continue
		_ordinary_arrival_cue_count -= 1
		if index < _ordinary_arrival_cue_count:
			_ordinary_arrival_cue_positions[index] = (
				_ordinary_arrival_cue_positions[_ordinary_arrival_cue_count]
			)
			_ordinary_arrival_cue_remaining[index] = (
				_ordinary_arrival_cue_remaining[_ordinary_arrival_cue_count]
			)


func _clear_ordinary_arrival_cues() -> void:
	_ordinary_arrival_cue_count = 0


func _bounded_spawn_spec(spec: Dictionary) -> Dictionary:
	# Whole-window reservation and the global store are the population bounds.
	# Per-archetype substitutions would corrupt authored pack composition.
	return spec


func _active_mobile_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap:
			count += 1
	return count


func _refresh_enemy_frame_aggregate() -> void:
	var aggregate_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	_enemy_frame_active_mobile_count = 0
	_enemy_frame_visible_ordinary_count = 0
	_enemy_frame_attack_families.clear()
	var visible_world := _visible_world_rect(0.0)
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		if enemy.counts_active_cap:
			_enemy_frame_active_mobile_count += 1
			if visible_world.has_point(enemy.pos):
				_enemy_frame_visible_ordinary_count += 1
		var family := enemy.threat_kind
		if (
			family in [&"support", &"boss"]
			or family in _enemy_frame_attack_families
		):
			continue
		_enemy_frame_attack_families.append(family)
	_enemy_frame_aggregate_valid = true
	_performance_accumulate_enemy_section(
		"encounter_aggregate_scans", aggregate_started
	)


func _note_enemy_frame_aggregate_added(enemy: EnemyState) -> void:
	if (
		not _enemy_frame_aggregate_valid
		or enemy == null
		or not enemy.alive
		or not enemy.active
	):
		return
	if enemy.counts_active_cap:
		_enemy_frame_active_mobile_count += 1
		if _visible_world_rect(0.0).has_point(enemy.pos):
			_enemy_frame_visible_ordinary_count += 1
	var family := enemy.threat_kind
	if (
		family not in [&"support", &"boss"]
		and family not in _enemy_frame_attack_families
	):
		_enemy_frame_attack_families.append(family)


func _on_deployment_selected(primary_id: StringName) -> void:
	_start_deployed_run(primary_id)


func _start_deployed_run(primary_id: StringName) -> void:
	selected_primary = primary_id
	selected_run_difficulty = RunDifficulty.HARD
	_save_persistence()
	_reset_run(false)
	selected_primary = primary_id
	_begin_session_diagnostics()
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_play_sound(&"card", 1.15)
	_set_mouse_for_mode()
	_start_manual_performance_trace()


func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if mode != RunMode.UPGRADE:
		return
	if not apply_upgrade(upgrade_id):
		_ui.upgrade_apply_failed(tr("UPGRADE_APPLY_FAILED"))
		return
	_session_diagnostics.emit_event("upgrade_confirmed", {
		"upgrade_id":upgrade_id,
		"stage_index":current_stage_index,
	})
	stage_telemetry.record_upgrade_confirmed(active_run_elapsed_seconds)
	_ui.update_hud({"build_snapshot":_build_snapshot()})
	_resolve_reward_transaction()
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_play_sound(&"card", 1.0)
	_set_mouse_for_mode()
	_advance_reward_queue()


func _pause_run() -> void:
	if not _simulation_active():
		return
	mode_before_pause = mode
	mode = RunMode.PAUSED
	var build_snapshot := _build_snapshot()
	_ui.update_hud({
		"build_snapshot":build_snapshot,
		"guidebook":_guidebook_snapshot(build_snapshot),
	})
	_ui.show_pause()
	_acquire_tree_pause()
	_checkpoint_session_diagnostics("settled_pause")
	_set_mouse_for_mode()


func _resume_run() -> void:
	if mode != RunMode.PAUSED:
		return
	_release_tree_pause()
	mode = mode_before_pause
	_ui.show_gameplay()
	_set_mouse_for_mode()


func _return_to_deployment() -> void:
	_finish_session_diagnostics("aborted")
	_release_tree_pause()
	_reset_run(true)
	_present_deployment()
	_set_mouse_for_mode()


func _present_deployment() -> void:
	var build_snapshot := _build_snapshot()
	_ui.update_hud({
		"build_snapshot":build_snapshot,
		"guidebook":_guidebook_snapshot(build_snapshot),
	})
	_ui.show_deployment(selected_primary)


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
	active_recharge_runtime.advance(delta)
	lifesteal_runtime.advance(delta)
	_update_dash_upgrade_effects(delta)
	player_invulnerable = maxf(0.0, player_invulnerable - delta)
	player_slow_timer = maxf(0.0, player_slow_timer - delta)
	_advance_player_protection_sources(delta)
	var primary_held := Input.is_action_pressed("primary_fire")
	player_primary_weapon.tick(delta * _player_facility_attack_cadence_multiplier(), primary_held)
	player_dash_cooldown = maxf(0.0, player_dash_cooldown - delta)
	player_barrier_timer = maxf(0.0, player_barrier_timer - delta)
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
		if player_dash_timer <= 0.0:
			dash_upgrade_runtime.complete_dash(
				player_position,
				run_build.level_of(&"dash_overdrive"),
				run_build.level_of(&"dash_afterburn_field")
			)
	else:
		var target_velocity := (
			move_input * _player_move_speed() * _player_facility_movement_multiplier()
			* (FamilyTraits.SLOW_MOVEMENT_MULTIPLIER if player_slow_timer > 0.0 else 1.0)
		)
		var acceleration_multiplier := _player_facility_acceleration_multiplier()
		if acceleration_multiplier < 1.0:
			player_velocity = player_velocity.move_toward(
				target_velocity,
				PLAYER_GRAVITY_RESPONSE_SPEED * acceleration_multiplier * delta
			)
		else:
			player_velocity = target_velocity
		var motion := player_velocity * delta
		player_position = _move_actor(player_position, motion, Rules.PLAYER_RADIUS, true)
		if Input.is_action_just_pressed("dash") and player_dash_cooldown <= 0.0:
			_start_dash(move_input)

	if primary_held:
		_try_fire_primary()

	if Input.is_action_just_pressed("active_skill"):
		_start_active_weapon()
	_advance_active_weapon(delta * _player_facility_attack_cadence_multiplier())

	_update_aim_target()
	_mark_visited()
	_apply_dash_collision()
	player_velocity = (player_position - previous_position) / maxf(delta, 0.0001)
	primary_combo_runtime.advance_motion(
		delta,
		player_position.distance_to(previous_position),
		player_velocity.length(),
		run_build.level_of(&"braced_fire")
	)
	_apply_player_facility_recovery(delta)
	_update_secondary_weapons(delta, player_velocity)

	if tutorial_move and tutorial_aim and tutorial_fire and tutorial_dash and not tutorial_announced:
		tutorial_announced = true


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
	var events := terrain_runtime.advance(delta, player_position)
	for event in events:
		match StringName(event["kind"]):
			&"transit":
				player_position = Vector2(event["destination"])
				player_velocity = Vector2.ZERO
				_grant_player_protection(
					float(event["invulnerability"]),
					&"transit"
				)
				_play_sound(&"dash", 1.18)


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
	_dash_action_serial += 1
	player_dash_direction = move_input.normalized() if move_input.length_squared() > 0.01 else player_aim_direction
	if player_dash_direction.length_squared() <= 0.01:
		player_dash_direction = player_hull_direction
	player_dash_timer = DASH_DURATION
	dash_upgrade_runtime.begin_dash(player_position)
	player_dash_cooldown = _dash_cooldown_max()
	_grant_player_protection(DASH_DURATION + 0.08, &"dash")
	player_dash_trail_timer = 0.0
	stats_dash_uses += 1
	tutorial_dash = true
	camera_shake = maxf(camera_shake, 4.0)
	_play_sound(&"dash")


func _update_dash(delta: float) -> void:
	player_dash_timer = maxf(0.0, player_dash_timer - delta)
	var before := player_position
	player_position = _move_actor(
		player_position,
		player_dash_direction * DASH_SPEED * delta,
		Rules.PLAYER_RADIUS,
		true
	)
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


func _update_dash_upgrade_effects(delta: float) -> void:
	var due_trails: Array = dash_upgrade_runtime.advance(delta)
	for trail_variant in due_trails:
		var trail: DashUpgradeRuntime.TrailState = trail_variant
		var midpoint := (trail.start + trail.end) * 0.5
		var query_radius := trail.start.distance_to(trail.end) * 0.5 \
			+ DashUpgradeRuntime.TRAIL_HALF_WIDTH + 96.0
		enemy_grid.query_radius_into(
			midpoint, query_radius, enemies, _enemy_query_buffer
		)
		for enemy in _enemy_query_buffer:
			if (
				_is_player_targetable_enemy(enemy)
				and DashUpgradeRuntime.contains(trail, enemy.pos, enemy.radius)
			):
				_damage_enemy(
					enemy,
					DashUpgradeRuntime.damage_per_tick(trail.level),
					"dash_afterburn",
					&"thermal",
					true,
					false,
					true,
					OutgoingDamagePolicy.DAMAGE_PERIODIC,
					trail.serial * 16 + trail.tick_index,
					&"dash_periodic"
				)


func _live_effect_count(kind: StringName) -> int:
	return effect_store.count_kind(kind)


func _fire_primary() -> void:
	tutorial_fire = true
	player_muzzle_flash = 0.075
	_primary_shot_serial += 1
	var origin := player_position + player_aim_direction * 39.0
	var fork_level := run_build.level_of(&"split_muzzle")
	var combo_multiplier := primary_combo_runtime.next_hit_multiplier(
		run_build.level_of(&"miss_compensation"),
		run_build.level_of(&"hit_chain")
	) * primary_combo_runtime.braced_multiplier(run_build.level_of(&"braced_fire"))
	var volley_count := PrimaryUpgradeRules.projectiles_per_volley(fork_level)
	var primary_base_damage := (
		18.0
		* PrimaryUpgradeRules.piercing_damage_multiplier(
			run_build.level_of(&"piercing_rounds")
		)
		* run_build.fallback_primary_damage_multiplier()
	)
	_primary_shot_groups[_primary_shot_serial] = {"remaining":volley_count, "hit":false}
	var projectile_range := _primary_projectile_range()
	for projectile_index in volley_count:
		var scale := PrimaryUpgradeRules.projectile_damage_scale(
			fork_level, projectile_index
		)
		_spawn_player_projectile(
			origin,
			player_aim_direction.rotated(PrimaryUpgradeRules.projectile_angle(
				fork_level, _primary_shot_serial, projectile_index
			)),
			primary_base_damage * scale * combo_multiplier,
			PRIMARY_PROJECTILE_SPEED,
			PrimaryUpgradeRules.additional_penetrations(
				run_build.level_of(&"piercing_rounds")
			),
			PRIMARY_PROJECTILE_RADIUS,
			primary_base_damage * scale * combo_multiplier,
			projectile_range,
			_primary_payload,
			false,
			&"primary",
			_primary_shot_serial
		)
	secondary_runtime.record_primary_success(origin, player_aim_direction)


func _try_fire_primary() -> bool:
	if not player_primary_weapon.can_fire(player_dash_timer <= 0.0):
		return false
	player_primary_weapon.consume_shot()
	_fire_primary()
	return true


func _primary_projectile_range() -> float:
	var visible_diagonal := _visible_world_rect(0.0).size.length()
	return maxf(
		PRIMARY_RANGE,
		visible_diagonal + PRIMARY_VISIBLE_RANGE_MARGIN
	)


func _runtime_cover_rects() -> Array[Rect2]:
	return _runtime_blockers


func _runtime_projectile_cover_rects(from: Vector2, to: Vector2, radius: float) -> Array[Rect2]:
	_projectile_cover_query.clear()
	var swept := Rect2(from, Vector2.ZERO).expand(to).grow(radius)
	for cover in StageCatalog.cover_rects_near_motion(
		current_stage_id, from, to, radius
	):
		if swept.intersects(cover.grow(radius), true):
			_projectile_cover_query.append(cover)
	if field_layout != null:
		_active_tactical_layout.covers_near_motion_into(
			from, to, radius, _projectile_runtime_cover_query
		)
		_projectile_cover_query.append_array(
			_projectile_runtime_cover_query
		)
	if _active_tactical_layout != null:
		_active_tactical_layout.runtime_walls_near_motion_into(
			from, to, radius, _projectile_runtime_wall_query
		)
		_projectile_cover_query.append_array(_projectile_runtime_wall_query)
	return _projectile_cover_query


func _runtime_motion_cover_rects(
	from: Vector2,
	to: Vector2,
	radius: float
) -> Array[Rect2]:
	_motion_cover_query.clear()
	_motion_cover_static_cover_clear = false
	var catalog_fast_safe := StageCatalog.is_fast_motion_clear(
		current_stage_id, from, to, radius
	)
	var layout_fast_safe := (
		_active_tactical_layout != null
		and _active_tactical_layout.is_fast_motion_clear(from, to, radius)
	)
	# The catalog cache knows shared field geometry; the tactical layout cache
	# additionally certifies this run's selected covers and functional terrain.
	# Only their intersection may bypass the exact circle solver.
	_motion_cover_static_safe = catalog_fast_safe and layout_fast_safe
	if _motion_cover_static_safe:
		_motion_cover_static_cover_clear = true
		return _motion_cover_query
	if field_layout != null and not _motion_cover_static_safe:
		_active_tactical_layout.covers_near_motion_into(
			from, to, radius, _motion_cover_query
		)
		_motion_cover_static_cover_clear = _motion_cover_query.is_empty()
	if _active_tactical_layout != null:
		_active_tactical_layout.runtime_walls_near_motion_into(
			from, to, radius, _motion_runtime_wall_query
		)
		_motion_cover_query.append_array(_motion_runtime_wall_query)
	return _motion_cover_query


func _rebuild_runtime_blockers() -> void:
	_runtime_blockers.clear()
	if field_layout != null:
		_runtime_blockers.append_array(_active_tactical_layout.cover_rects)
	_runtime_structural_walls = terrain_runtime.structural_wall_rects()
	_runtime_blockers.append_array(_runtime_structural_walls)


func _runtime_first_cover_hit(from: Vector2, to: Vector2, padding: float) -> Dictionary:
	var runtime_cover := _runtime_projectile_cover_rects(from, to, padding)
	if runtime_cover.is_empty():
		_cover_hit_receipt["hit"] = false
		_cover_hit_receipt["t"] = 2.0
		return _cover_hit_receipt
	return Rules.first_cover_hit_candidates_into(
		from,
		to,
		padding,
		runtime_cover,
		_cover_hit_receipt,
		_cover_hit_candidate
	)


func _runtime_has_line_of_sight(from: Vector2, to: Vector2, padding: float) -> bool:
	return _runtime_cover_has_line_of_sight(from, to, padding)


func _runtime_cover_has_line_of_sight(
	from: Vector2,
	to: Vector2,
	padding: float
) -> bool:
	var swept := Rect2(from, Vector2.ZERO).expand(to).grow(padding)
	var static_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	if field_layout != null:
		_active_tactical_layout.covers_near_motion_into(
			from, to, padding, _los_cover_query
		)
		for blocker in _los_cover_query:
			if (
				swept.intersects(blocker.grow(padding), true)
				and Rules.segment_rect_intersects(from, to, blocker, padding)
			):
				_performance_accumulate_enemy_section(
					"los_static_cover", static_started
				)
				return false
	_performance_accumulate_enemy_section(
		"los_static_cover", static_started
	)
	var dynamic_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	_los_runtime_wall_query.clear()
	if _active_tactical_layout != null:
		_active_tactical_layout.runtime_walls_near_motion_into(
			from, to, padding, _los_runtime_wall_query
		)
	for blocker in _los_runtime_wall_query:
		if (
			swept.intersects(blocker.grow(padding), true)
			and Rules.segment_rect_intersects(from, to, blocker, padding)
		):
			_performance_accumulate_enemy_section(
				"los_dynamic_structure", dynamic_started
			)
			return false
	_performance_accumulate_enemy_section(
		"los_dynamic_structure", dynamic_started
	)
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
	return (
		Vector2(cover_hit["point"])
		if bool(cover_hit.get("hit", false))
		else desired
	)


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
	primary_payload: VehiclePrimaryPayloadProfile = null,
	wall_piercing: bool = false,
	combat_action_family: StringName = &"",
	combat_action_serial: int = 0
) -> void:
	var condition_mask := AttackContract.condition_mask_for_profile(primary_payload)
	var affinity := (
		AttackContract.normalize_affinity(primary_payload.affinity())
		if primary_payload != null
		else AttackContract.KINETIC
	)
	_ensure_player_projectile_capacity()
	projectile_store.add_player({
		"pos": origin,
		"spawn_origin": origin,
		"velocity": direction.normalized() * speed,
		"radius": radius,
		"damage": damage,
		"life": projectile_range / speed,
		"color": Art.attack_color(affinity, true),
		"owner": "player_primary",
		"pierce": extra_pierce,
		"bounces": 0,
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
		"primary_payload": primary_payload,
		"combat_action_family": combat_action_family,
		"combat_action_serial": combat_action_serial,
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
		active_weapon_runtime.equipped_id == &"emp"
			and active_weapon_runtime.startup_remaining > 0.0,
		0.85 if persistent_field_module else 1.0,
		_runtime_attack_path_callable,
		player_aim_direction
	)
	var emitted_projectiles: Array = secondary_result.get("projectiles", [])
	if not emitted_projectiles.is_empty():
		for projectile in emitted_projectiles:
			_ensure_player_projectile_capacity()
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
				&"arc" if secondary_source == "Electric Field" else &"kinetic",
				true,
				false,
				true,
				int(intent.get("damage_flags", 0)),
				int(intent.get("attack_serial", 0)),
				&"secondary"
			)
	# Mine gameplay resolves before its one origin receipt becomes visible.
	for detonation_variant in secondary_result.get("detonations", []):
		var detonation: Dictionary = detonation_variant
		_add_effect(
			EffectStore.DROP_MINE_DETONATION_KIND,
			Vector2(detonation["position"]),
			Color.WHITE,
			0.18,
			float(detonation["radius"])
		)
		_play_sound(&"impact", 0.90)
	for impact_variant in secondary_result.get("impacts", []):
		var impact: Dictionary = impact_variant
		var impact_position := Vector2(impact["position"])
		var impact_radius := float(impact["radius"])
		var impact_damage := float(impact.get("damage", 0.0))
		_damage_mystery_devices_in_radius(
			impact_position, impact_radius, impact_damage
		)
		_play_sound(&"impact", 0.96)


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
		if role in [&"ordinary_edge_01", &"ordinary_lane_01", &"ordinary_gap_01"]:
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


func _start_active_weapon() -> void:
	var event := active_weapon_runtime.try_start(
		player_position,
		player_aim_direction,
		Rules.world_rect(current_stage_id),
		run_build,
		1.5 if persistent_relay_module else 0.0
	)
	if not bool(event.get("started", false)):
		return
	var weapon_id := StringName(event["weapon_id"])
	_play_sound(&"emp_start")
	if weapon_id == &"emp":
		_grant_player_protection(0.24, &"emp")
		_add_effect(
			EffectStore.EMP_CHARGE_KIND,
			Vector2(event["center"]),
			Art.SYSTEM,
			float(event["startup"]),
			float(event["size"]),
			Vector2.ZERO,
			0.0,
			1.0,
			float(event["auxiliary_size"])
		)


func _advance_active_weapon(delta: float) -> void:
	var event := active_weapon_runtime.advance(delta, run_build)
	for _step in int(event.get("pull_steps", 0)):
		_apply_black_hole_pull()
	if bool(event.get("collapse", false)):
		_release_active_weapon(&"black_hole")
	elif bool(event.get("released", false)):
		_release_active_weapon(active_weapon_runtime.equipped_id)


func _release_active_weapon(weapon_id: StringName) -> void:
	match weapon_id:
		&"emp":
			_release_emp_weapon()
		&"black_hole":
			camera_shake = maxf(camera_shake, 8.0)
			_play_sound(&"emp")
		&"shockwave":
			_release_shockwave()
		&"cross_beam":
			_release_cross_beam()


func _release_emp_weapon() -> void:
	var center := active_weapon_runtime.center
	var radius := active_weapon_runtime.size
	var clear_radius := active_weapon_runtime.catalog.get_definition(&"emp").auxiliary_size(
		active_weapon_runtime.level
	)
	projectile_store.clear_hostiles_in_radius(center, clear_radius)
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if (
			_is_player_targetable_enemy(enemy)
			and Vector2(enemy.pos).distance_to(center) <= radius
		):
			_apply_active_stagger(enemy, active_weapon_runtime.duration)
	_add_effect(
		EffectStore.EMP_RELEASE_KIND,
		center,
		Color.WHITE,
		0.55,
		radius,
		Vector2.ZERO,
		0.0,
		1.0,
		clear_radius
	)
	camera_shake = maxf(camera_shake, 11.0)
	_play_sound(&"emp")


func _apply_black_hole_pull() -> void:
	var center := active_weapon_runtime.center
	var radius := active_weapon_runtime.size
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		var offset := center - enemy.pos
		if offset.length() > radius + enemy.radius and offset.length_squared() > 0.01:
			continue
		StatusRuntime.apply_active_slow(
			enemy, active_weapon_runtime.strength, active_weapon_runtime.duration
		)
		if enemy.role == &"boss" or _is_fixed_structure_enemy(enemy):
			continue
		enemy.pos = _move_actor(
			enemy.pos,
			offset.normalized() * VehicleActiveWeaponRuntime.BLACK_HOLE_PULL_INTERVAL * 360.0,
			enemy.radius,
			false
		)
		enemy_grid.update_actor(enemy)


func _release_shockwave() -> void:
	var center := active_weapon_runtime.center
	var radius := active_weapon_runtime.size
	var push_distance := active_weapon_runtime.catalog.get_definition(&"shockwave").auxiliary_size(
		active_weapon_runtime.level
	)
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		var offset := enemy.pos - center
		if offset.length() > radius + enemy.radius:
			continue
		_apply_active_stagger(enemy, active_weapon_runtime.duration)
		if (
			offset.length_squared() <= 0.01
			or enemy.role == &"boss"
			or _is_fixed_structure_enemy(enemy)
		):
			continue
		enemy.pos = _move_actor(enemy.pos, offset.normalized() * push_distance, enemy.radius, false)
		enemy_grid.update_actor(enemy)
	camera_shake = maxf(camera_shake, 8.0)
	_play_sound(&"impact", 0.86)


func _release_cross_beam() -> void:
	var center := active_weapon_runtime.center
	var direction := active_weapon_runtime.direction.normalized()
	var side := direction.rotated(PI * 0.5)
	var half_width := active_weapon_runtime.size
	for enemy in enemies:
		if not _is_player_targetable_enemy(enemy):
			continue
		var offset := enemy.pos - center
		if (
			absf(offset.dot(side)) > half_width + enemy.radius
			and absf(offset.dot(direction)) > half_width + enemy.radius
		):
			continue
		StatusRuntime.apply_active_slow(
			enemy, active_weapon_runtime.strength, active_weapon_runtime.duration
		)
	camera_shake = maxf(camera_shake, 9.0)
	_play_sound(&"emp", 1.08)


func _apply_active_stagger(enemy: EnemyState, duration: float) -> void:
	var duration_scale := 0.5 if enemy.role == &"boss" else 1.0
	enemy.stun = maxf(float(enemy.stun), maxf(0.0, duration) * duration_scale)


func _player_move_speed() -> float:
	return run_build.stat(&"move_speed_multiplier", PLAYER_BASE_SPEED)


func _player_facility_movement_multiplier() -> float:
	var multiplier := 1.0
	mystery_device_runtime.fill_modifiers_at(player_position, _facility_modifier_buffer)
	for modifier in _facility_modifier_buffer:
		var profile := Dictionary(modifier["profile"])
		multiplier *= float(profile.get(
			"movement_multiplier", profile.get("max_speed_multiplier", 1.0)
		))
	return multiplier


func _player_facility_acceleration_multiplier() -> float:
	var multiplier := 1.0
	mystery_device_runtime.fill_modifiers_at(player_position, _facility_modifier_buffer)
	for modifier in _facility_modifier_buffer:
		multiplier *= float(Dictionary(modifier["profile"]).get("acceleration_multiplier", 1.0))
	return multiplier


func _player_facility_attack_cadence_multiplier() -> float:
	var multiplier := 1.0
	mystery_device_runtime.fill_modifiers_at(player_position, _facility_modifier_buffer)
	for modifier in _facility_modifier_buffer:
		multiplier *= float(Dictionary(modifier["profile"]).get("attack_cadence_multiplier", 1.0))
	return multiplier


func _apply_player_facility_recovery(delta: float) -> void:
	mystery_device_runtime.fill_modifiers_at(player_position, _facility_modifier_buffer)
	var maximum_hull := _player_max_health()
	for modifier in _facility_modifier_buffer:
		var profile := Dictionary(modifier["profile"])
		if profile.has("hull_restore_per_second"):
			player_health = minf(
				maximum_hull,
				player_health + maximum_hull * float(profile["hull_restore_per_second"]) * delta
			)
		if profile.has("shield_restore_per_second"):
			var barrier_cap := maximum_hull * float(profile.get("shield_cap_max_hull_ratio", 1.0))
			player_barrier_strength = minf(
				barrier_cap,
				player_barrier_strength + maximum_hull * float(profile["shield_restore_per_second"]) * delta
			)
			if player_barrier_strength > 0.0:
				player_barrier_timer = maxf(player_barrier_timer, 0.25)


func _player_facility_received_damage_multiplier() -> float:
	var multiplier := 1.0
	mystery_device_runtime.fill_modifiers_at(player_position, _facility_modifier_buffer)
	for modifier in _facility_modifier_buffer:
		multiplier *= float(Dictionary(modifier["profile"]).get("received_damage_multiplier", 1.0))
	return multiplier


func _apply_enemy_facility_modifiers(enemy: EnemyState, delta: float) -> void:
	enemy.facility_movement_multiplier = 1.0
	enemy.facility_acceleration_multiplier = 1.0
	enemy.facility_cadence_multiplier = 1.0
	enemy.facility_received_damage_multiplier = 1.0
	mystery_device_runtime.fill_modifiers_at(enemy.pos, _facility_modifier_buffer)
	for modifier in _facility_modifier_buffer:
		var profile := Dictionary(modifier["profile"])
		enemy.facility_movement_multiplier *= float(profile.get(
			"movement_multiplier", profile.get("max_speed_multiplier", 1.0)
		))
		enemy.facility_acceleration_multiplier *= float(profile.get("acceleration_multiplier", 1.0))
		enemy.facility_cadence_multiplier *= float(profile.get("attack_cadence_multiplier", 1.0))
		enemy.facility_received_damage_multiplier *= float(profile.get("received_damage_multiplier", 1.0))
		if profile.has("hull_restore_per_second"):
			enemy.health = minf(
				enemy.max_health,
				enemy.health + enemy.max_health * float(profile["hull_restore_per_second"]) * delta
			)
		if profile.has("shield_restore_per_second"):
			enemy.facility_barrier_max = enemy.max_health * float(profile.get("shield_cap_max_hull_ratio", 1.0))
			enemy.facility_barrier_strength = minf(
				enemy.facility_barrier_max,
				enemy.facility_barrier_strength + enemy.max_health * float(profile["shield_restore_per_second"]) * delta
			)


func _dash_cooldown_max() -> float:
	return DASH_COOLDOWN * run_build.fallback_dash_cooldown_multiplier()


func _player_max_health() -> float:
	return run_build.stat(&"max_health_bonus", PLAYER_MAX_HEALTH)


func _update_pickups(
	delta: float,
	motion_start: Vector2,
	motion_end: Vector2
) -> void:
	for pickup in pickups:
		if not bool(pickup["active"]) or not bool(pickup.get("published", true)):
			continue
		var pickup_position := Vector2(pickup["pos"])
		var crossed_during_motion := PickupContact.should_collect(
			true,
			motion_start,
			motion_end,
			Rules.PLAYER_RADIUS,
			pickup_position,
			PICKUP_BODY_RADIUS
		)
		if crossed_during_motion:
			_collect_pickup(pickup)


func _refresh_viewport_supply(delta: float) -> void:
	var visible := _visible_world_rect(0.0)
	ViewportSupplyPolicy.refresh_direct_items(
		pickups, experience_runtime.shards, _pickup_validation_anchors,
		visible, player_position, delta
	)
	mystery_device_runtime.refresh_publication(visible, player_position)


func _collect_pickup(pickup: Dictionary) -> void:
	if not bool(pickup["active"]):
		return
	pickup["active"] = false
	pickup["published"] = false
	var kind := StringName(pickup["kind"])
	match kind:
		&"experience_recall":
			_discover_guide(&"object_recall")
			experience_recall_timer = 0.65
	_play_sound(&"pickup")


func _update_experience(delta: float) -> void:
	var attraction_radius := 92.0 + run_build.stat(&"pickup_radius_bonus", 0.0)
	var result := experience_runtime.advance(
		delta,
		player_position,
		attraction_radius,
		experience_recall_timer
	)
	experience_recall_timer = maxf(0.0, experience_recall_timer - delta)
	stage_telemetry.record_experience(
		int(result["experience"]), experience_runtime.run_level
	)
	if int(result["experience"]) > 0:
		_discover_guide(&"object_experience")
		_play_sound(&"pickup", 1.22)
	if is_instance_valid(_performance_scenario):
		# Synthetic and production-replay fixtures exercise shard motion/collection,
		# but a card-modal transition would end the declared PLAYING workload.
		experience_runtime.clear_pending_levels()
		return
	for source in result["reward_sources"]:
		reward_runtime.enqueue(StringName(source))
	_advance_reward_queue()


func _update_enemies(
	delta: float,
	player_contact_previous_position: Vector2
) -> void:
	_player_combat_previous_position = player_contact_previous_position
	var performance_active := _performance_detail_sample_active
	var section_started := Time.get_ticks_usec() if performance_active else 0
	var decision_bucket := _enemy_decision_bucket
	_enemy_decision_bucket = (_enemy_decision_bucket + 1) % ORDINARY_DECISION_BUCKET_COUNT
	if decision_bucket == 0:
		_enemy_decision_cycle_epoch += 1
	# Rebuild on every physics tick so motion-only buckets are published at
	# 30/20 Hz and each decision bucket gets its own 10 Hz opportunity. The
	# scheduler accumulators are lane-owned; rebuilding only on bucket zero
	# would discard five-sixths of decision/motion cadence.
	_enemy_update_schedule.rebuild(
		enemies, delta, player_position, _near_simulation_distance_squared,
		decision_bucket, _simulation_lod_bucket, _far_enemy_simulation_bucket,
		enemy_store.membership_revision
	)
	# Already-materialized actors remain exact across stage changes. If their
	# count exceeds a newly lowered beat cap, encounter admission stays blocked
	# until defeats create room; live actors are never hidden to repair the cap.
	var active_capped := _enemy_update_schedule.active_cap_count
	if performance_active:
		_performance_enemy_sections["budget_scan"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()

	for enemy in enemies:
		if not enemy.alive:
			continue
		_apply_enemy_facility_modifiers(enemy, delta)
		if enemy.active:
			enemy.contact_previous_position = enemy.pos
			enemy.contact_attack = &""
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
	for enemy in _enemy_update_schedule.active:
		if not enemy.statuses.is_empty():
			var status_damage := StatusRuntime.tick(enemy, delta)
			if float(status_damage["poison"]) > 0.0:
				_damage_enemy(
					enemy,
					float(status_damage["poison"]),
					"status",
					&"toxin",
					true,
					false,
					false,
					OutgoingDamagePolicy.DAMAGE_PERIODIC
				)
				if not enemy.alive:
					continue
		var role := enemy.role
		if role == &"boss":
			if enemy.stun > 0.0:
				enemy.velocity = Vector2.ZERO
				enemy_grid.update_actor(enemy)
				continue
			_refresh_enemy_presentation_facing(enemy)
			_update_stage_boss(enemy, delta)
			_refresh_enemy_presentation_facing(enemy)
			enemy_grid.update_actor(enemy)
			continue
		if role == &"ordinary_fixed_support_01":
			_update_generator(enemy, delta)
			continue
		if enemy.stun > 0.0:
			enemy.velocity = Vector2.ZERO
	if performance_active:
		_performance_enemy_sections["active_states"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	var scheduled_started := section_started
	if _performance_ablation != &"overlap":
		_prepare_enemy_local_overlap_cache()
	if performance_active:
		_performance_enemy_sections["overlap_cache"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	for enemy in _enemy_update_schedule.critical:
		_update_scheduled_ordinary_enemy(enemy, delta)
	if performance_active:
		_performance_enemy_sections["critical"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	for due_index in _enemy_update_schedule.ordinary_due.size():
		_update_scheduled_ordinary_enemy(
			_enemy_update_schedule.ordinary_due[due_index],
			-1.0,
			_enemy_update_schedule.ordinary_due_flags[due_index],
			_enemy_update_schedule.ordinary_due_decision_deltas[due_index],
			_enemy_update_schedule.ordinary_due_motion_deltas[due_index]
		)
	if performance_active:
		_performance_enemy_sections["ordinary_due"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	if performance_active:
		_performance_enemy_sections["scheduled_ordinary"] = _elapsed_ms(
			scheduled_started
		)
		section_started = Time.get_ticks_usec()
	_enemy_contact_runtime.advance(
		_enemy_update_schedule.active,
		player_contact_previous_position,
		player_position,
		delta
	)
	if performance_active:
		_performance_enemy_sections["contact_resolution"] = _elapsed_ms(
			section_started
		)


func _prepare_enemy_local_overlap_cache() -> void:
	if _enemy_overlap_refresh_mask.size() != SpatialGrid.MAX_TRACKED_ACTORS:
		_enemy_overlap_refresh_mask.resize(SpatialGrid.MAX_TRACKED_ACTORS)
	_enemy_overlap_refresh_mask.fill(0)
	for enemy in _enemy_update_schedule.critical:
		_mark_enemy_overlap_refresh(enemy)
	for due_index in _enemy_update_schedule.ordinary_due.size():
		if (
			_enemy_update_schedule.ordinary_due_flags[due_index]
			& EnemyUpdateSchedule.WORK_DECISION_DUE
		) != 0:
			var enemy := _enemy_update_schedule.ordinary_due[due_index]
			_mark_enemy_overlap_refresh(enemy)
	enemy_grid.rebuild_local_overlap_cache(
		_enemy_overlap_refresh_mask,
		_performance_detail_sample_active,
		_slow_tick_recording_active
	)
	if _performance_detail_sample_active:
		_performance_enemy_sections["overlap_snapshot_clear"] = (
			enemy_grid.last_overlap_snapshot_ms
		)
		_performance_enemy_sections["overlap_candidate_query"] = (
			enemy_grid.last_overlap_query_ms
		)


func _mark_enemy_overlap_refresh(enemy: EnemyState) -> void:
	var slot := enemy.spatial_slot if enemy.spatial_slot >= 0 else enemy.runtime_slot
	if (
		slot >= 0
		and slot < _enemy_overlap_refresh_mask.size()
		and posmod(slot + _enemy_decision_cycle_epoch, 2) == 0
	):
		_enemy_overlap_refresh_mask[slot] = 1


func _update_scheduled_ordinary_enemy(
	enemy: EnemyState,
	critical_delta: float = -1.0,
	work_flags: int = 0,
	decision_delta_receipt: float = 0.0,
	motion_delta_receipt: float = 0.0
) -> void:
	if not enemy.alive or not enemy.active:
		return
	if enemy.stun > 0.0:
		enemy.movement_reason = &"stunned"
		return
	var critical := critical_delta >= 0.0
	var decision_due := critical or (
		work_flags & EnemyUpdateSchedule.WORK_DECISION_DUE
	) != 0
	var motion_due := critical or (
		work_flags & EnemyUpdateSchedule.WORK_MOTION_DUE
	) != 0
	var motion_delta := critical_delta if critical else motion_delta_receipt
	var decision_delta := critical_delta if critical else decision_delta_receipt
	# Critical actors stay on the full update path so startup/active/recovery
	# timers advance at 60 Hz. They are not granted a new commitment budget;
	# `can_commit` remains false for this path below.
	if _performance_ablation == &"decision" and not critical:
		decision_due = false
	if not motion_due and not decision_due:
		return
	if motion_due and not decision_due:
		var motion_started := (
			Time.get_ticks_usec() if _performance_detail_sample_active else 0
		)
		_update_motion_only_ordinary_enemy(enemy, motion_delta)
		_apply_engagement_gap_steering(enemy, motion_delta, true)
		if _performance_detail_sample_active:
			_performance_accumulate_enemy_section(
				"ordinary_motion_policy", motion_started
			)
		return
	var previous_position := enemy.pos
	var previous_alive := enemy.alive
	var previous_active := enemy.active
	var can_commit := (
		not critical
		and decision_due
		and _performance_ablation != &"attacks"
		and _enemy_update_schedule.can_commit(
			enemy,
			encounter_runtime.threat_budget(),
			encounter_runtime.ranged_commit_cap(),
			encounter_runtime.denial_commit_cap()
		)
	)
	var policy_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	if _update_ordinary_enemy(
		enemy, decision_delta, can_commit, decision_due, motion_delta
	):
		_enemy_update_schedule.note_commit(enemy)
	_apply_engagement_gap_steering(enemy, motion_delta, false)
	if _performance_detail_sample_active:
		_performance_accumulate_enemy_section(
			"ordinary_decision_policy", policy_started
		)
	# The spatial grid is already correct when a scheduled tick only advances
	# timers or attack state. Re-index only after a position/occupancy change;
	# collision truth and the next exact query remain unchanged.
	if (
		enemy.pos != previous_position
		or enemy.alive != previous_alive
		or enemy.active != previous_active
	):
		if enemy.alive and enemy.active and previous_alive and previous_active:
			enemy_grid.update_actor_position(enemy)
		else:
			enemy_grid.update_actor(enemy)
	_refresh_enemy_presentation_facing(enemy)


func _apply_engagement_gap_steering(
	enemy: EnemyState,
	delta: float,
	update_spatial_grid: bool
) -> void:
	if (
		delta <= 0.0
		or not _diagnostic_visible_gap_active
		or active_run_elapsed_seconds - _diagnostic_visible_gap_started
			< ENGAGEMENT_GAP_STEER_DELAY
		or enemy.phase not in [&"move", &"recovery"]
		or not enemy.counts_active_cap
		or _visible_world_rect(64.0).has_point(enemy.pos)
	):
		return
	var offset := player_position - enemy.pos
	if offset.length_squared() <= 1.0:
		return
	var previous_position := enemy.pos
	var extra_speed := enemy.speed * (ENGAGEMENT_GAP_SPEED_MULTIPLIER - 1.0)
	enemy.pos = _move_actor(
		enemy.pos,
		offset.normalized() * extra_speed * delta,
		enemy.radius,
		false
	)
	if enemy.pos == previous_position:
		return
	enemy.velocity = (enemy.pos - previous_position) / delta
	enemy.movement_reason = &"engagement_gap_regroup"
	if update_spatial_grid:
		enemy_grid.update_actor_position(enemy)


func _refresh_enemy_presentation_facing(enemy: EnemyState) -> void:
	## Directional actors publish simulation-owned facing. Controller spin and
	## nondirectional mine/generator bodies remain explicit renderer exceptions.
	if (
		enemy.role == &"boss"
		and boss_death_runtime.active()
		and enemy.id == _dying_boss_id
	):
		return
	if enemy.role in [&"ordinary_gap_01", &"ordinary_fixed_area_01", &"ordinary_fixed_support_01"]:
		return
	var facing := Vector2.ZERO
	if enemy.phase in [&"startup", &"active", &"boss_startup", &"boss_active"]:
		facing = enemy.committed_dir
	else:
		facing = player_position - enemy.pos
	if not facing.is_zero_approx():
		enemy.presentation_facing = facing.normalized()


func _update_motion_only_ordinary_enemy(
	enemy: EnemyState,
	motion_delta: float
) -> void:
	## Motion-only ticks consume cached intent and never perform decision queries.
	var previous_position := enemy.pos
	var previous_active := enemy.active
	if _update_collective_enemy(enemy, motion_delta):
		_record_motion_only_enemy_change(enemy, previous_position, previous_active)
		return
	var leash := enemy.leash_rect
	if leash.has_area() and not leash.has_point(player_position):
		enemy.movement_reason = &"leash_home"
		enemy.phase = &"move"
		enemy.attack_cooldown = maxf(enemy.attack_cooldown, 0.35)
		var to_home := enemy.home - enemy.pos
		if to_home.length() <= 18.0:
			enemy.pos = enemy.home
			enemy.active = false
		else:
			_move_enemy_with_recovery(enemy, to_home.normalized() * _effective_enemy_speed(enemy), motion_delta)
		_record_motion_only_enemy_change(enemy, previous_position, previous_active)
		return
	if enemy.role in [
		&"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01", &"ordinary_fixed_support_01",
	]:
		enemy.movement_reason = &"stationary_role"
		_record_motion_only_enemy_change(enemy, previous_position, previous_active)
		return
	if enemy.role == &"ordinary_fixed_area_01":
		enemy.movement_reason = &"mine_role"
		if enemy.archetype == &"ordinary_area_01" and enemy.phase != &"mine_armed":
			_move_cached_enemy_role(enemy, motion_delta)
		_record_motion_only_enemy_change(enemy, previous_position, previous_active)
		return
	if enemy.phase == &"move" or enemy.role in [&"ordinary_support_01", &"ordinary_shield_01", &"ordinary_pulse_01"]:
		_move_cached_enemy_role(enemy, motion_delta)
	_record_motion_only_enemy_change(enemy, previous_position, previous_active)


func _move_cached_enemy_role(enemy: EnemyState, delta: float) -> void:
	if delta <= 0.0 or enemy.desired_velocity.is_zero_approx():
		return
	_move_enemy_with_recovery(
		enemy,
		_smoothed_enemy_velocity(enemy, delta, false),
		delta
	)


func _record_motion_only_enemy_change(
	enemy: EnemyState,
	previous_position: Vector2,
	previous_active: bool
) -> void:
	if (
		enemy.pos != previous_position
		or enemy.active != previous_active
	):
		if enemy.alive and enemy.active and previous_active:
			enemy_grid.update_actor_position(enemy)
		else:
			enemy_grid.update_actor(enemy)
	_refresh_enemy_presentation_facing(enemy)


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
	for enemy in _enemy_update_schedule.active:
		if (
			enemy.family_trait == &"bulwark"
			and enemy.pack_trait_active
		):
			_shield_supports.append(enemy)


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
		var is_bulwark := (
			support.family_trait == &"bulwark"
			and support.pack_trait_active
		)
		var support_radius := (
			FamilyTraits.BULWARK_RADIUS
			if is_bulwark
			else (
				SpecialistRuntime.FIXED_SUPPORT_RANGE
				if support.role == &"ordinary_fixed_support_01"
				else SpecialistRuntime.SHIELD_SUPPORT_RANGE
			)
		)
		enemy_grid.query_radius_into(
			support_position,
			support_radius,
			enemies,
			_support_query_buffer
		)
		if is_bulwark:
			var radius_squared := (
				FamilyTraits.BULWARK_RADIUS * FamilyTraits.BULWARK_RADIUS
			)
			for candidate in _support_query_buffer:
				if (
					candidate.alive
					and candidate.active
					and candidate.squad_id == support.squad_id
					and support_position.distance_squared_to(candidate.pos)
						<= radius_squared
				):
					shielded_ids[candidate.id] = &"bulwark"
			continue
		if support.role == &"ordinary_fixed_support_01":
			for candidate in _support_query_buffer:
				var candidate_role := candidate.role
				if candidate != support and candidate_role not in [&"ordinary_fixed_support_01", &"ordinary_support_02", &"boss"] and support_position.distance_squared_to(candidate.pos) <= SpecialistRuntime.FIXED_SUPPORT_RANGE * SpecialistRuntime.FIXED_SUPPORT_RANGE:
					shielded_ids[candidate.id] = &"ordinary_fixed_support_01"
			continue
		var closest_id := ""
		var closest_distance_squared := (
			SpecialistRuntime.SHIELD_SUPPORT_RANGE
			* SpecialistRuntime.SHIELD_SUPPORT_RANGE
		)
		for candidate in _support_query_buffer:
			var candidate_role := candidate.role
			if candidate == support or candidate_role in [&"ordinary_fixed_support_01", &"ordinary_support_02", &"boss"]:
				continue
			var distance_squared := support_position.distance_squared_to(candidate.pos)
			if distance_squared <= closest_distance_squared:
				closest_distance_squared = distance_squared
				closest_id = candidate.id
		if not closest_id.is_empty():
			# Generator protection keeps precedence if both support types overlap.
			if not shielded_ids.has(closest_id):
				shielded_ids[closest_id] = &"ordinary_support_02"


func _apply_enemy_shield(enemy: EnemyState, shielded_ids: Dictionary) -> void:
	var tactic_shield := (
		enemy.collective_mode in [&"shield", &"support", &"escort"]
		and enemy.collective_phase in [&"lock", &"execute"]
	)
	var bulwark_shield := (
		enemy.family_trait == &"bulwark" and enemy.pack_trait_active
	)
	var reflector_baseline := (
		enemy.family == &"defender" and enemy.family_trait == &"reflector"
	)
	var shield_source: StringName = StringName(shielded_ids.get(enemy.id, &"none"))
	if bulwark_shield:
		shield_source = &"bulwark"
	elif reflector_baseline:
		shield_source = &"reflector"
	elif tactic_shield:
		shield_source = &"collective_tactic"
	var shielded := shield_source != &"none"
	enemy.shield_source = shield_source
	if enemy.shielded != shielded:
		enemy.shielded = shielded


func _update_enemy_shield(enemy: EnemyState) -> void:
	# Compatibility path for deterministic single-enemy contract checks.
	_apply_enemy_shield(enemy, _build_enemy_shield_assignments())


func _update_generator(enemy: EnemyState, delta: float) -> void:
	enemy.support_tick -= delta
	if enemy.support_tick > 0.0:
		return
	enemy.support_tick = SpecialistRuntime.FIXED_SUPPORT_TICK_SECONDS
	enemy_grid.query_radius_into(
		enemy.pos,
		SpecialistRuntime.FIXED_SUPPORT_RANGE,
		enemies,
		_support_query_buffer
	)
	for target in _support_query_buffer:
		if target == enemy:
			continue
		if target.pos.distance_to(enemy.pos) <= SpecialistRuntime.FIXED_SUPPORT_RANGE:
			target.health = minf(
				target.max_health,
				target.health + SpecialistRuntime.FIXED_SUPPORT_HEAL_PER_TICK
			)


func _update_ordinary_support_01(enemy: EnemyState, delta: float, refresh_target: bool) -> void:
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


func _spawn_carrier_child(carrier: EnemyState) -> void:
	if (
		encounter_runtime.available_active_slots(_active_mobile_count()) <= 0
		or
		_enemy_update_schedule.carrier_child_count(carrier.id)
		>= SpecialistRuntime.MOBILE_SUPPORT_CHILD_CAP
		or (
			carrier.role == &"boss"
			and _live_boss_add_count()
				>= BossPhaseCatalog.MAX_LIVE_ADDS
		)
	):
		return
	carrier.child_serial += 1
	var serial := carrier.child_serial
	var offset := Vector2.RIGHT.rotated(TAU * float(serial % 6) / 6.0) * 58.0
	var spawn_position := _move_actor(carrier.pos, offset, 12.0, false)
	var child := _make_enemy({
		"id":"%s_child_%02d" % [carrier.id, serial],
		"role":&"ordinary_melee_01",
		"pos":spawn_position,
		"active":true,
		"carrier_id":carrier.id,
		"squad_id":"%s_children" % carrier.id,
		"group_id":carrier.group_id,
		"leash_rect":carrier.leash_rect,
	})
	if _append_enemy(child):
		_enemy_update_schedule.note_carrier_child(carrier.id)


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
		enemy.movement_reason = &"leash_home"
		enemy.phase = &"move"
		enemy.attack_cooldown = maxf(enemy.attack_cooldown, 0.35)
		var to_home := enemy.home - enemy.pos
		if to_home.length() <= 18.0:
			enemy.pos = enemy.home
			enemy.active = false
		else:
			_move_enemy_with_recovery(enemy, to_home.normalized() * _effective_enemy_speed(enemy), motion_delta)
		return false
	if enemy.role == &"ordinary_support_01":
		enemy.movement_reason = &"repair_role"
		_update_ordinary_support_01(enemy, delta, decision_due)
		_move_enemy_role(enemy, motion_delta, false, decision_due)
		return false
	if enemy.role == &"ordinary_fixed_area_01":
		enemy.movement_reason = &"mine_role"
		_update_mine(enemy, delta, motion_delta, decision_due)
		return false
	if enemy.role == &"ordinary_fixed_ranged_02":
		enemy.intercept_recharge = maxf(0.0, enemy.intercept_recharge - delta)
		if enemy.intercept_charges < 3 and enemy.intercept_recharge <= 0.0:
			enemy.intercept_charges += 1
			enemy.intercept_recharge = 4.0
	enemy.attack_cooldown = maxf(0.0, enemy.attack_cooldown - delta * StatusRuntime.speed_multiplier(enemy))
	var phase := enemy.phase
	if phase == &"self_destruct_fuse":
		enemy.movement_reason = &"self_destruct_fuse"
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		enemy.velocity = Vector2.ZERO
		enemy.mechanic_cue_active = true
		enemy.mechanic_inner_radius = 72.0
		enemy.mechanic_outer_radius = 170.0
		if enemy.phase_time <= 0.0:
			if _player_sweep_distance_to_point(enemy.pos) <= enemy.mechanic_outer_radius + Rules.PLAYER_RADIUS:
				_damage_player(26.0 * enemy.pack_damage_multiplier, "Charger self-destruct", true)
			_add_effect(EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND, enemy.pos, Art.DANGER, 0.24, enemy.mechanic_outer_radius)
			_defeat_enemy(enemy, "self_destruct")
		return false
	if phase == &"interrupted_recovery":
		enemy.movement_reason = &"interrupted_recovery"
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		enemy.velocity = Vector2.ZERO
		if enemy.phase_time <= 0.0:
			enemy.phase = &"move"
			enemy.pattern_index = 0
			enemy.attack_cooldown = _enemy_recovery_cooldown(enemy)
		return false
	if phase == &"startup":
		enemy.movement_reason = &"attack_startup"
		enemy.phase_time = maxf(0.0, enemy.phase_time - delta)
		AttackTelegraphs.update_ordinary_readiness(enemy)
		if enemy.phase_time <= 0.0:
			_begin_enemy_active(enemy)
		return false
	if phase == &"active":
		enemy.movement_reason = &"attack_active"
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
	if (
		not decision_due
		or not can_commit
		or enemy.attack_cooldown > 0.0
	):
		return false
	var attack_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	if _enemy_can_attack(enemy):
		_start_enemy_attack(enemy)
		_performance_accumulate_enemy_section(
			"attack_admission_commit", attack_started
		)
		return true
	_performance_accumulate_enemy_section(
		"attack_admission_commit", attack_started
	)
	return false


func _update_collective_enemy(
	enemy: EnemyState,
	delta: float
) -> bool:
	# Individual commitments always finish. Pursuit families also retain normal
	# approach ownership until a collective charge/fuse actually executes.
	if enemy.phase in [&"startup", &"active"]:
		return false
	if enemy.movement_family == EnemyMovementPolicy.PURSUIT and not (
		enemy.collective_phase == &"execute"
		and enemy.collective_mode in [&"charge", &"fuse"]
	):
		return false
	if enemy.family == &"defender" and _protected_emitter(enemy) != null:
		return false
	match enemy.collective_phase:
		&"gather":
			enemy.movement_reason = &"collective_gather"
			var to_slot := enemy.collective_target - enemy.pos
			if to_slot.length_squared() > 4.0:
				_move_enemy_with_recovery(
					enemy,
					to_slot.normalized() * _effective_enemy_speed(enemy),
					delta
				)
			else:
				enemy.velocity = Vector2.ZERO
			return true
		&"lock":
			enemy.movement_reason = &"collective_lock"
			enemy.velocity = Vector2.ZERO
			return true
		&"execute":
			enemy.movement_reason = &"collective_execute"
			if enemy.collective_mode in [&"charge", &"fuse"]:
				enemy.contact_attack = EnemyContactRuntime.ATTACK_COLLECTIVE
				var before := enemy.pos
				var requested := (
					enemy.collective_direction
					* _effective_enemy_speed(enemy)
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
			else:
				var to_slot := enemy.collective_target - enemy.pos
				if to_slot.length_squared() > 4.0:
					_move_enemy_with_recovery(
						enemy,
						to_slot.normalized()
							* _effective_enemy_speed(enemy)
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
		elif kind == &"pack_trait":
			var action := StringName(event.get("action", &""))
			if action == &"blink_request":
				_try_blink_pack(event)
			elif action in [&"warning", &"active"]:
				_play_sound(&"boss", 0.54)


func _try_blink_pack(event: Dictionary) -> bool:
	var squad_id := String(event.get("squad_id", ""))
	if squad_id.is_empty() or _active_tactical_layout == null:
		return false
	var members: Array[EnemyState] = []
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.squad_id == squad_id:
			members.append(enemy)
	if members.is_empty():
		return false
	members.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		return a.formation_slot < b.formation_slot
	)
	var centroid := Vector2.ZERO
	for member in members:
		centroid += member.pos
	centroid /= float(members.size())
	var radial := (centroid - player_position).normalized()
	if radial.is_zero_approx():
		radial = Vector2.RIGHT
	var side_sign := -1.0 if posmod(hash(squad_id), 2) == 0 else 1.0
	var destination_center := (
		player_position + radial * 110.0 + radial.rotated(side_sign * PI * 0.5) * 410.0
	)
	var candidates: Array[Vector2] = []
	var geometry = _active_tactical_layout.geometry_snapshot
	for member in members:
		var formation_offset := (member.collective_target - centroid).limit_length(150.0)
		var candidate := destination_center + formation_offset
		if (
			candidate.distance_to(player_position) < 190.0
			or not geometry.is_spawnable_disc(candidate, member.radius)
			or not _blink_position_clear(candidate, member.radius, squad_id)
		):
			return false
		candidates.append(candidate)
	for index in members.size():
		var member := members[index]
		member.pos = candidates[index]
		member.home = candidates[index]
		member.velocity = Vector2.ZERO
		member.desired_velocity = Vector2.ZERO
		enemy_grid.update_actor(member)
	_add_effect(EffectStore.EMP_RELEASE_KIND, destination_center, Art.SYSTEM, 0.24, 118.0)
	return true


func _blink_position_clear(position: Vector2, radius: float, squad_id: String) -> bool:
	for other in enemies:
		if (
			not other.alive
			or not other.active
			or other.squad_id == squad_id
		):
			continue
		if position.distance_to(other.pos) < radius + other.radius + 18.0:
			return false
	return true


func _enemy_recovery_cooldown(enemy: EnemyState) -> float:
	var role := enemy.role
	var cooldown := 0.8
	match role:
		&"ordinary_edge_01":
			cooldown = 0.55
		&"ordinary_lane_01":
			cooldown = 0.78
		&"ordinary_gap_01":
			cooldown = 1.15
		&"ordinary_fixed_ranged_01":
			cooldown = 1.05
		&"ordinary_fixed_area_01":
			cooldown = 1.8
		&"ordinary_growth_01":
			cooldown = 1.65
		&"ordinary_shield_01", &"ordinary_pulse_01":
			# These roles express their complete post-active recovery in phase_time.
			cooldown = 0.0
		&"ordinary_fixed_ranged_02":
			cooldown = 1.25
		&"ordinary_pull_01":
			cooldown = SpecialistRuntime.PULL_CHARGE_RECOVERY
		&"ordinary_support_03":
			cooldown = SpecialistRuntime.MOBILE_SUPPORT_RECOVERY
		&"ordinary_fixed_beam_01":
			cooldown = SpecialistRuntime.BEAM_RECOVERY
		&"ordinary_beam_01", &"ordinary_range_01", &"ordinary_sweep_01", &"ordinary_melee_02":
			cooldown = float(AttackContract.ordinary_attack(role).get("recovery", cooldown))
	var growth_enemy_interval := _ordinary_melee_02_attack_interval_multiplier(enemy)
	var trait_scale := (
		FamilyTraits.FRENZY_CADENCE_MULTIPLIER
		if enemy.family_trait == &"frenzy" else 1.0
	)
	return (
		cooldown
		* growth_enemy_interval
		* trait_scale
		* EncounterDirector.ordinary_recovery_scale(enemy.family)
	) / (
		EncounterDirector.ENEMY_RECOVERY_RATE
		* maxf(0.01, enemy.facility_cadence_multiplier)
	)


func _enter_ordinary_recovery(enemy: EnemyState, authored_seconds: float) -> void:
	enemy.phase = &"recovery"
	enemy.phase_time = (
		maxf(0.0, authored_seconds)
		* EncounterDirector.ordinary_recovery_scale(enemy.family)
	)


func _enemy_can_attack(enemy: EnemyState) -> bool:
	var role := enemy.role
	var target := player_position
	var distance := enemy.pos.distance_to(target)
	match role:
		&"ordinary_edge_01":
			return distance <= 175.0
		&"ordinary_lane_01":
			return distance <= 620.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_gap_01":
			return distance <= 590.0 and _runtime_has_line_of_sight(enemy.pos, target, 4.0)
		&"ordinary_fixed_ranged_01":
			return distance <= 760.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_fixed_area_01":
			return distance <= 190.0
		&"ordinary_growth_01":
			return distance <= 650.0 and distance >= 250.0
		&"ordinary_shield_01":
			return _protected_emitter(enemy) == null and distance <= 190.0
		&"ordinary_pulse_01":
			return distance <= 620.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_fixed_ranged_02":
			return distance <= 700.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_pull_01":
			return distance <= 640.0 and distance >= 130.0 and _runtime_has_line_of_sight(enemy.pos, target, 12.0)
		&"ordinary_support_03":
			return (
				distance <= 760.0
				and _enemy_update_schedule.carrier_child_count(enemy.id)
					< SpecialistRuntime.MOBILE_SUPPORT_CHILD_CAP
			)
		&"ordinary_fixed_beam_01":
			return distance <= SpecialistRuntime.BEAM_RANGE and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_beam_01":
			return distance <= 900.0 and distance >= 300.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_range_01":
			return distance <= 620.0 and _runtime_has_line_of_sight(enemy.pos, target, 7.0)
		&"ordinary_sweep_01":
			return distance <= 700.0 and distance >= 120.0
		&"ordinary_melee_02":
			return distance <= 470.0 and distance >= 90.0
	return false


func _start_enemy_attack(enemy: EnemyState) -> void:
	var role := enemy.role
	var pressure_focus := player_position
	var attack := AttackContract.ordinary_attack(role)
	var startup := 0.0
	var attack_speed := 0.0
	if not attack.is_empty():
		startup = AttackContract.warned_startup_seconds(
			float(attack["startup"]), StringName(attack.get("kind", &""))
		)
		match StringName(attack.get("kind", &"")):
			&"projectile":
				attack_speed = EncounterDirector.effective_hostile_projectile_speed(
					float(attack.get("speed", 0.0))
				)
			&"charge":
				attack_speed = (
					float(attack.get("speed", 0.0))
					* EncounterDirector.ENEMY_SPEED_MULTIPLIER
				)
	elif role == &"ordinary_pull_01":
		startup = SpecialistRuntime.PULL_CHARGE_STARTUP
		attack_speed = SpecialistRuntime.PULL_CHARGE_SPEED
	elif role == &"ordinary_fixed_beam_01":
		startup = SpecialistRuntime.BEAM_STARTUP
	var target := EnemyTargetingPolicy.attack_target(
		role,
		enemy.pos,
		pressure_focus,
		player_velocity,
		startup,
		attack_speed
	)
	if (
		not target.is_equal_approx(pressure_focus)
		and not _runtime_has_line_of_sight(
			enemy.pos,
			target,
			_enemy_attack_line_padding(enemy)
		)
	):
		target = pressure_focus
	enemy.phase = &"startup"
	encounter_runtime.record_attack_preparation(enemy.family)
	stage_telemetry.record_attack_commit(enemy.family)
	enemy.hit_committed = false
	enemy.committed_dir = (target - enemy.pos).normalized()
	enemy.committed_target = target
	enemy.phase_time = startup
	AttackTelegraphs.refresh_ordinary(
		enemy,
		_runtime_attack_path_callable,
		_runtime_charge_path_callable
	)
	if enemy.archetype == &"ordinary_compression_01":
		_append_boss_compression_pass({
			"id":"teaching_%s" % enemy.id,
			"pattern":"ordinary_compression_01",
			"duration":1.0,
			"damage":12.0,
			"affinity":&"kinetic",
			"commit_mode":&"committed",
			"owner_kind":&"ordinary",
		}, enemy.committed_dir, 0.0, 0.0, "teaching")


func _begin_enemy_active(enemy: EnemyState) -> void:
	var role := enemy.role
	enemy.phase = &"active"
	match role:
		&"ordinary_edge_01":
			enemy.phase_time = float(AttackContract.ORDINARY_ATTACKS[role]["active"])
		&"ordinary_lane_01":
			var shooter_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(shooter_attack["origin_offset"]),
				enemy.committed_dir,
				float(shooter_attack["damage"]) * enemy.pack_damage_multiplier,
				float(shooter_attack["speed"]),
				"Emitter bolt",
				StringName(shooter_attack["affinity"]),
				false,
				false,
				AttackContract.threat_tier_for(enemy.role, enemy.family_trait),
				&"",
				enemy.family_trait == &"slow",
				FamilyTraits.SLOW_DURATION
			)
			_enter_ordinary_recovery(enemy, 0.72)
		&"ordinary_gap_01":
			if enemy.archetype == &"ordinary_compression_01":
				_enter_ordinary_recovery(enemy, 1.0)
				return
			var controller_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(controller_attack["origin_offset"]),
				enemy.committed_dir,
				float(controller_attack["damage"]),
				float(controller_attack["speed"]),
				"Controller bolt",
				StringName(controller_attack["affinity"]),
				false,
				false,
				AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
			)
			_enter_ordinary_recovery(enemy, 0.88)
		&"ordinary_fixed_ranged_01":
			enemy.burst_left = 3
			enemy.burst_timer = 0.0
			enemy.phase_time = 0.55
		&"ordinary_fixed_area_01":
			var mine_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			enemy.phase_time = 0.15
			var mine_distance := _player_sweep_distance_to_point(enemy.pos)
			var mine_damage := AttackContract.radial_damage(
				float(mine_attack["damage"]),
				mine_distance,
				float(mine_attack["radius"])
			)
			if mine_damage > 0.0:
				_damage_player(mine_damage, "Arc proximity burst", true)
		&"ordinary_growth_01":
			var artillery_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			denied_zones.append({
				"id":"%s_artillery" % enemy.id,
				"owner_kind":&"ordinary", "owner":&"hostile",
				"shape":&"area", "pos":enemy.committed_target,
				"radius":float(artillery_attack["radius"]),
				"damage":float(artillery_attack["damage"])
					* enemy.pack_damage_multiplier,
				"affinity":StringName(artillery_attack["affinity"]),
				"warning":0.0, "warning_total":0.0,
				"duration":0.22, "tick":0.0,
				"single_hit":true, "hit_committed":false,
				"source":"Emitter artillery impact", "final_damage":false,
			})
			_enter_ordinary_recovery(enemy, float(artillery_attack["recovery"]))
		&"ordinary_shield_01":
			enemy.phase_time = float(AttackContract.ORDINARY_ATTACKS[role]["active"])
		&"ordinary_pulse_01":
			var coordinator_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(coordinator_attack["origin_offset"]),
				enemy.committed_dir,
				float(coordinator_attack["damage"]) * enemy.pack_damage_multiplier,
				float(coordinator_attack["speed"]),
				"Coordinator pulse bolt",
				StringName(coordinator_attack["affinity"]), false, false,
				AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
			)
			_enter_ordinary_recovery(enemy, float(coordinator_attack["recovery"]))
		&"ordinary_beam_01":
			var rail_attack := AttackContract.ordinary_attack(role)
			_spawn_hostile_projectile(
				enemy.pos + enemy.committed_dir * float(rail_attack["origin_offset"]),
				enemy.committed_dir,
				float(rail_attack["damage"]),
				float(rail_attack["speed"]),
				"Beam Ordinary Enemy Lv.1 shot",
				StringName(rail_attack["affinity"]), false, false,
				AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
			)
			# The recovery relocation breaks the next rail lane without teleporting.
			enemy.reposition_time = 0.72
			enemy.reposition_dir = enemy.committed_dir.rotated(enemy.strafe_sign * PI * 0.5)
			_enter_ordinary_recovery(enemy, float(rail_attack["recovery"]))
		&"ordinary_range_01":
			var orbit_attack := AttackContract.ordinary_attack(role)
			enemy.burst_left = int(orbit_attack["burst_count"])
			enemy.burst_timer = 0.0
			enemy.phase_time = float(orbit_attack["burst_count"]) * float(orbit_attack["burst_spacing"]) + 0.08
		&"ordinary_sweep_01":
			var bombing_attack := AttackContract.ordinary_attack(role)
			for blast_index in int(bombing_attack["blast_count"]):
				var blast_position := enemy.committed_target + enemy.committed_dir * float(blast_index) * 64.0
				var warning := AttackContract.bombardment_warning(
					float(bombing_attack["blast_delay"])
					+ float(blast_index) * float(bombing_attack["blast_spacing"])
				)
				denied_zones.append({
					"id":"%s_bomb_%d" % [enemy.id, blast_index], "owner_kind":&"ordinary",
					"owner":&"hostile", "shape":&"area", "pos":blast_position,
					"radius":float(bombing_attack["radius"]),
					"damage":float(bombing_attack["damage"]),
					"warning":warning, "warning_total":warning,
					"duration":0.22, "tick":0.0, "source":"Sweep Ordinary Enemy Lv.1 ground burst", "final_damage":false,
				})
			enemy.phase_time = float(bombing_attack["pass_seconds"])
		&"ordinary_melee_02":
			enemy.phase_time = float(AttackContract.ordinary_attack(role)["active"])
		&"ordinary_fixed_ranged_02":
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
				AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
			)
			_enter_ordinary_recovery(enemy, 0.9)
		&"ordinary_pull_01":
			enemy.phase_time = SpecialistRuntime.PULL_CHARGE_ACTIVE
		&"ordinary_support_03":
			enemy.burst_left = mini(
				3,
				SpecialistRuntime.MOBILE_SUPPORT_CHILD_CAP
					- _enemy_update_schedule.carrier_child_count(enemy.id)
			)
			enemy.burst_timer = 0.0
			enemy.phase_time = 2.2
		&"ordinary_fixed_beam_01":
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
		&"ordinary_edge_01":
			enemy.contact_attack = EnemyContactRuntime.ATTACK_EDGE_CONTACT
			var edge_enemy_attack: Dictionary = AttackContract.ORDINARY_ATTACKS[role]
			var before := enemy.pos
			enemy.pos = _runtime_charge_path_end(
				before,
				enemy.committed_dir,
				float(edge_enemy_attack["speed"])
					* EncounterDirector.ENEMY_SPEED_MULTIPLIER
					* delta,
				enemy.radius
			)
			if enemy.phase_time <= 0.0:
				_enter_ordinary_recovery(enemy, 0.52)
		&"ordinary_shield_01":
			enemy.contact_attack = EnemyContactRuntime.ATTACK_SHIELD_BASH
			var bash := AttackContract.ordinary_attack(role)
			var before := enemy.pos
			enemy.pos = _runtime_charge_path_end(
				before,
				enemy.committed_dir,
				float(bash["speed"])
					* EncounterDirector.ENEMY_SPEED_MULTIPLIER
					* delta,
				enemy.radius
			)
			if enemy.phase_time <= 0.0:
				_enter_ordinary_recovery(enemy, float(bash["recovery"]))
		&"ordinary_fixed_ranged_01":
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
					AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
				)
			if enemy.burst_left <= 0:
				_enter_ordinary_recovery(enemy, 0.95)
		&"ordinary_range_01":
			var orbit_attack := AttackContract.ordinary_attack(role)
			enemy.burst_timer -= delta
			if enemy.burst_left > 0 and enemy.burst_timer <= 0.0:
				enemy.burst_timer = float(orbit_attack["burst_spacing"])
				enemy.burst_left -= 1
				_spawn_hostile_projectile(
					enemy.pos + enemy.committed_dir * float(orbit_attack["origin_offset"]),
					enemy.committed_dir, float(orbit_attack["damage"]), float(orbit_attack["speed"]),
					"Range Ordinary Enemy Lv.1 burst", StringName(orbit_attack["affinity"]), false, false,
					AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
				)
			if enemy.burst_left <= 0:
				_enter_ordinary_recovery(enemy, float(orbit_attack["recovery"]))
		&"ordinary_sweep_01":
			var bombing_attack := AttackContract.ordinary_attack(role)
			var before := enemy.pos
			enemy.pos = _runtime_charge_path_end(
				before, enemy.committed_dir,
				float(bombing_attack["pass_speed"]) * EncounterDirector.ENEMY_SPEED_MULTIPLIER * delta,
				enemy.radius
			)
			if enemy.phase_time <= 0.0:
				_enter_ordinary_recovery(enemy, float(bombing_attack["recovery"]))
		&"ordinary_melee_02":
			enemy.contact_attack = EnemyContactRuntime.ATTACK_EDGE_CONTACT
			var growth_enemy_attack := AttackContract.ordinary_attack(role)
			var before := enemy.pos
			var growth_enemy_speed := float(growth_enemy_attack["speed"]) * EncounterDirector.ENEMY_SPEED_MULTIPLIER * _ordinary_melee_02_speed_multiplier(enemy)
			enemy.pos = _runtime_charge_path_end(before, enemy.committed_dir, growth_enemy_speed * delta, enemy.radius)
			if enemy.phase_time <= 0.0:
				enemy.phase = &"recovery"
				enemy.phase_time = _enemy_recovery_cooldown(enemy)
		&"ordinary_fixed_area_01":
			if enemy.phase_time <= 0.0:
				_enter_ordinary_recovery(enemy, 1.2)
		&"ordinary_pull_01":
			enemy.contact_attack = EnemyContactRuntime.ATTACK_PULL_CHARGE
			var before := enemy.pos
			var requested := enemy.committed_dir * SpecialistRuntime.PULL_CHARGE_SPEED * delta
			var after := _runtime_charge_path_end(
				before,
				enemy.committed_dir,
				requested.length(),
				enemy.radius
			)
			enemy.pos = after
			var struck_cover := before.distance_to(after) + 1.0 < requested.length()
			if struck_cover or enemy.phase_time <= 0.0:
				_finish_charger_charge(enemy)
		&"ordinary_support_03":
			enemy.burst_timer -= delta
			if enemy.burst_left > 0 and enemy.burst_timer <= 0.0:
				enemy.burst_timer = SpecialistRuntime.MOBILE_SUPPORT_RELEASE_SPACING
				enemy.burst_left -= 1
				_spawn_carrier_child(enemy)
			if enemy.burst_left <= 0:
				_enter_ordinary_recovery(enemy, SpecialistRuntime.MOBILE_SUPPORT_RECOVERY)
		&"ordinary_fixed_beam_01":
			var beam_end := enemy.beam_end
			var growth_ratio := AttackContract.emitted_beam_growth_ratio(
				enemy.phase_time,
				SpecialistRuntime.BEAM_ACTIVE
			)
			var live_beam_end := AttackContract.emitted_beam_live_endpoint(
				enemy.pos, beam_end, growth_ratio
			)
			if (
				not enemy.hit_committed
				and _player_sweep_hits_corridor(
					enemy.pos,
					live_beam_end,
					SpecialistRuntime.BEAM_WIDTH * 0.5
				)
			):
				enemy.hit_committed = true
				_damage_player(SpecialistRuntime.BEAM_DAMAGE, "Fixed Beam Ordinary Enemy Lv.1 sweep", true)
			if enemy.phase_time <= 0.0:
				_enter_ordinary_recovery(enemy, SpecialistRuntime.BEAM_RECOVERY)
		_:
			_enter_ordinary_recovery(enemy, 0.6)

func _finish_charger_charge(enemy: EnemyState) -> void:
	if enemy.family_trait == &"double" and enemy.pattern_index == 0:
		enemy.pattern_index = 1
		enemy.phase = &"startup"
		enemy.phase_time = 0.45
		enemy.committed_dir = (player_position - enemy.pos).normalized()
		if enemy.committed_dir.is_zero_approx():
			enemy.committed_dir = enemy.presentation_facing
		AttackTelegraphs.refresh_ordinary(
			enemy,
			_runtime_attack_path_callable,
			_runtime_charge_path_callable
		)
		return
	if enemy.family_trait == &"self_destruct":
		enemy.phase = &"self_destruct_fuse"
		enemy.phase_time = 1.0
		enemy.mechanic_state = &"self_destruct_fuse"
		enemy.mechanic_cue_active = true
		return
	_enter_ordinary_recovery(enemy, SpecialistRuntime.PULL_CHARGE_RECOVERY)
	enemy.vulnerable = SpecialistRuntime.PULL_CHARGE_RECOVERY


func _move_enemy_role(enemy: EnemyState, delta: float, recovering: bool, decision_due: bool = true) -> void:
	var role := enemy.role
	if (
		role in [&"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01", &"ordinary_fixed_support_01"]
		or (role == &"ordinary_fixed_area_01" and enemy.archetype != &"ordinary_area_01")
	):
		return
	var refresh_overlap := false
	if decision_due or enemy.desired_velocity.is_zero_approx():
		var intent_started := (
			Time.get_ticks_usec() if _performance_detail_sample_active else 0
		)
		var steering_slot := (
			enemy.spatial_slot
			if enemy.spatial_slot >= 0
			else enemy.runtime_slot
		)
		refresh_overlap = (
			decision_due
			and (
				steering_slot < 0
				or posmod(steering_slot + _enemy_decision_cycle_epoch, 2) == 0
			)
		)
		enemy.desired_velocity = _desired_enemy_velocity(
			enemy, recovering
		)
		_performance_accumulate_enemy_section(
			"movement_intent", intent_started
	)
	var steering_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	var smoothed_velocity := _smoothed_enemy_velocity(
		enemy, delta, refresh_overlap
	)
	_performance_accumulate_enemy_section(
		"movement_smoothing", steering_started
	)
	var collision_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	_move_enemy_with_recovery(enemy, smoothed_velocity, delta)
	_performance_accumulate_enemy_section(
		"movement_collision", collision_started
	)


func _desired_enemy_velocity(
	enemy: EnemyState,
	recovering: bool
) -> Vector2:
	var position := enemy.pos
	var pressure_focus := player_position
	var movement_family := enemy.movement_family
	if movement_family.is_empty():
		movement_family = EnemyMovementPolicy.family(enemy.archetype, enemy.role)
		enemy.movement_family = movement_family
	var movement_band := EnemyMovementPolicy.distance_band(enemy.role)
	var movement_focus := EnemyTargetingPolicy.movement_focus(
		movement_family,
		position,
		pressure_focus,
		player_velocity,
		enemy.speed
	)
	if movement_family == EnemyMovementPolicy.ESCORT and not recovering:
		var protected_emitter := _protected_emitter(enemy)
		if protected_emitter != null:
			var screen_direction := (pressure_focus - protected_emitter.pos).normalized()
			if not screen_direction.is_zero_approx():
				movement_focus = protected_emitter.pos + screen_direction * (
					protected_emitter.radius + enemy.radius + 18.0
				)
	var engagement_focus := false
	if enemy.engagement_active and enemy.phase == &"move" and not recovering:
		var relevance := EngagementRelevancePolicy.sample(
			enemy.pos,
			player_position,
			enemy.engagement_gate,
			enemy.engagement_last_player_distance,
			enemy.engagement_divergence_started_at,
			encounter_runtime.elapsed,
			enemy.engagement_started_at
		)
		enemy.engagement_last_player_distance = float(relevance["player_distance"])
		enemy.engagement_divergence_started_at = float(relevance["divergence_started_at"])
		if bool(relevance["release"]):
			_release_enemy_engagement(enemy, StringName(relevance["reason"]))
		elif enemy.pos.distance_to(enemy.engagement_gate) <= 96.0:
			_release_enemy_engagement(enemy, &"complete")
		elif encounter_runtime.elapsed >= enemy.engagement_expiry:
			_release_enemy_engagement(enemy, &"expire")
		else:
			movement_focus = enemy.engagement_gate
			engagement_focus = true
	var movement_path_blocked := not _runtime_has_line_of_sight(
		position, movement_focus, enemy.radius * 0.45
	)
	var firing_lane_blocked := (
		movement_family == EnemyMovementPolicy.STANDOFF
		and not _runtime_has_line_of_sight(
			position,
			pressure_focus,
			_enemy_attack_line_padding(enemy)
		)
	)
	var line_recovery := EnemyMovementPolicy.line_of_fire_recovery_for_profile(
		movement_family,
		movement_band,
		position,
		pressure_focus,
		firing_lane_blocked,
		recovering
	)
	var desired := EnemyMovementPolicy.direction_for_profile(
		movement_family,
		enemy.role,
		movement_band,
		position,
		movement_focus,
		enemy.strafe_sign,
		recovering,
		line_recovery
	)
	if engagement_focus:
		# The gate is a one-shot approach point, not the role's final range band.
		desired = (movement_focus - position).normalized()
	var requests_approach := EnemyMovementPolicy.requests_approach_for_profile(
		movement_family,
		enemy.role,
		movement_band,
		position,
		movement_focus,
		recovering
	)
	var route_requested := EnemyMovementPolicy.hot_route_guidance_requested(
		requests_approach,
		movement_path_blocked,
		line_recovery
	)
	if route_requested:
		var pursuit_started := (
			Time.get_ticks_usec() if _performance_detail_sample_active else 0
		)
		var route_direction := pursuit_field.direction_at(position, enemy.radius)
		_performance_accumulate_enemy_section(
			"pursuit_sampling", pursuit_started
		)
		if not route_direction.is_zero_approx():
			var route_weight := 0.55 if line_recovery else 0.86
			desired = (
				route_direction * route_weight
				+ desired * (1.0 - route_weight)
			).normalized()
	if engagement_focus:
		enemy.movement_reason = &"engagement_gate"
	elif route_requested:
		enemy.movement_reason = &"pursuit_route"
	elif recovering:
		enemy.movement_reason = &"recovery"
	elif enemy.role == &"ordinary_support_01":
		enemy.movement_reason = &"repair_role"
	elif movement_family == EnemyMovementPolicy.PURSUIT:
		enemy.movement_reason = &"pursuit_role"
	else:
		enemy.movement_reason = &"role_movement"
	return desired.normalized() * _effective_enemy_speed(enemy) * StatusRuntime.speed_multiplier(enemy)


func _protected_emitter(enemy: EnemyState) -> EnemyState:
	if enemy == null or enemy.escort_target_id.is_empty():
		return null
	var candidate := _find_enemy_by_id(enemy.escort_target_id)
	if (
		candidate == null
		or not candidate.alive
		or not candidate.active
		or candidate.family != &"emitter"
		or candidate.squad_id != enemy.squad_id
	):
		return null
	return candidate


func _smoothed_enemy_velocity(
	enemy: EnemyState,
	delta: float,
	refresh_overlap: bool
) -> Vector2:
	if enemy.movement_family.is_empty():
		enemy.movement_family = EnemyMovementPolicy.family(
			enemy.archetype, enemy.role
		)
	var speed_cap := _effective_enemy_speed(enemy) * StatusRuntime.speed_multiplier(enemy)
	var role_velocity := EnemyMovementPolicy.smooth_velocity(
		enemy.velocity,
		enemy.desired_velocity,
		EnemyMovementPolicy.turn_response(enemy.movement_family) * enemy.facility_acceleration_multiplier,
		delta,
		speed_cap
	)
	var adjusted := _enemy_local_steering.adjusted_velocity(
		enemy, role_velocity, enemy_grid, enemies, refresh_overlap
	)
	if (
		enemy.movement_family == EnemyMovementPolicy.PURSUIT
		and _allows_player_pursuit_bias(enemy)
		and enemy.phase in [&"move", &"recovery"]
		and enemy.reposition_time <= 0.0
	):
		var toward_player := (player_position - enemy.pos).normalized()
		if not toward_player.is_zero_approx() and adjusted.dot(toward_player) <= 0.0:
			var lateral := adjusted - toward_player * adjusted.dot(toward_player)
			adjusted = (lateral + toward_player * speed_cap * 0.05).limit_length(speed_cap)
	return adjusted


func _allows_player_pursuit_bias(_enemy: EnemyState) -> bool:
	return true


func _move_enemy_with_recovery(enemy: EnemyState, velocity: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	if enemy.reposition_time > 0.0:
		enemy.movement_reason = &"wall_reposition"
		enemy.reposition_time = maxf(0.0, enemy.reposition_time - delta)
		velocity = enemy.reposition_dir * _effective_enemy_speed(enemy)
	var before := enemy.pos
	var requested_motion := velocity * delta
	var requested_destination := before + requested_motion
	var attempt := _move_actor(before, requested_motion, enemy.radius, false)
	if attempt == requested_destination:
		enemy.stuck_time = 0.0
		enemy.pos = attempt
		enemy.velocity = velocity
		return
	var moved_squared := before.distance_squared_to(attempt)
	var velocity_squared := velocity.length_squared()
	if moved_squared < 0.35 * 0.35 and velocity_squared > 1.0:
		var side_sign := enemy.strafe_sign
		var side := velocity.normalized().rotated(side_sign * PI * 0.5)
		attempt = _move_actor(before, side * _effective_enemy_speed(enemy) * delta, enemy.radius, false)
		moved_squared = before.distance_squared_to(attempt)
	if moved_squared < 0.25 * 0.25 and velocity_squared > 1.0:
		enemy.stuck_time += delta
		if enemy.stuck_time > 0.55:
			enemy.stuck_time = 0.0
			enemy.strafe_sign = -enemy.strafe_sign
			enemy.reposition_time = 0.85
			enemy.reposition_dir = velocity.normalized().rotated(enemy.strafe_sign * PI * 0.5)
			enemy.movement_reason = &"wall_reposition"
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
	var mobile := enemy.archetype == &"ordinary_area_01"
	var trigger_radius := 160.0 if mobile else 230.0
	if enemy.phase != &"mine_armed":
		if mobile:
			_move_enemy_role(enemy, motion_delta, false, decision_due)
		if decision_due and enemy.pos.distance_to(player_position) <= trigger_radius:
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
			and enemy.archetype == &"ordinary_area_01"
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
	var mobile := enemy.archetype == &"ordinary_area_01"
	var radius := (
		SpecialistRuntime.MOBILE_MINE_RADIUS
		if mobile else SpecialistRuntime.STATIC_MINE_RADIUS
	)
	var center_damage := (
		SpecialistRuntime.MOBILE_MINE_DAMAGE
		if mobile else SpecialistRuntime.STATIC_MINE_DAMAGE
	)
	var origin := enemy.pos
	var source := "player_ordinary_area_01" if mobile else "player_arc_mine"
	if (
		_runtime_has_line_of_sight(origin, player_position, 2.0)
		and origin.distance_to(player_position) <= radius
	):
		var player_damage := AttackContract.radial_damage(
			center_damage, origin.distance_to(player_position), radius
		)
		if player_damage > 0.0:
			_damage_player(player_damage, "Area Ordinary Enemy Lv.1" if mobile else "Arc Mine", true)
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
		if target.role == &"boss":
			damage *= 0.25
		if damage > 0.0:
			_damage_enemy(
				target,
				damage,
				source,
				&"arc",
				enemy.mine_armed_by_player,
				false,
				true,
				(
					OutgoingDamagePolicy.DAMAGE_DIRECT
					if enemy.mine_armed_by_player
					else 0
				)
			)
	_arm_chain_mines(enemy, origin, mobile)
	_defeat_enemy(enemy, source)


func _arm_chain_mines(source_mine: EnemyState, origin: Vector2, mobile: bool) -> void:
	var candidates: Array[EnemyState] = []
	enemy_grid.query_radius_into(origin, 320.0, enemies, candidates)
	candidates = candidates.filter(
		func(target: EnemyState) -> bool:
			return (
				target != source_mine
				and target.alive
				and target.role == &"ordinary_fixed_area_01"
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
	var damage := base_damage
	if enemy.archetype == &"ordinary_overload_01" and enemy.phase == &"active":
		damage *= LateBossMechanics.OVERLOAD_DEALT_DAMAGE_SCALE
	if enemy.role == &"ordinary_melee_02":
		damage = float(AttackContract.ordinary_attack(&"ordinary_melee_02").get("damage", base_damage))
		damage *= _ordinary_melee_02_damage_multiplier(enemy)
	return damage * enemy.pack_damage_multiplier


func _ordinary_melee_02_stack_count(enemy: EnemyState) -> int:
	return clampi(int(_ordinary_melee_02_stacks.get(enemy.id, 0)), 0, SpecialistRuntime.MELEE_GROWTH_MAX_STACKS)


func _ordinary_melee_02_damage_multiplier(enemy: EnemyState) -> float:
	return float(SpecialistRuntime.ordinary_melee_02_modifiers(_ordinary_melee_02_stack_count(enemy)).get("damage_multiplier", 1.0))


func _ordinary_melee_02_speed_multiplier(enemy: EnemyState) -> float:
	return float(SpecialistRuntime.ordinary_melee_02_modifiers(_ordinary_melee_02_stack_count(enemy)).get("speed_multiplier", 1.0))


func _ordinary_melee_02_attack_interval_multiplier(enemy: EnemyState) -> float:
	return float(SpecialistRuntime.ordinary_melee_02_modifiers(_ordinary_melee_02_stack_count(enemy)).get("attack_interval_multiplier", 1.0))


func _effective_enemy_speed(enemy: EnemyState) -> float:
	return (
		enemy.speed
		* (_ordinary_melee_02_speed_multiplier(enemy) if enemy.role == &"ordinary_melee_02" else 1.0)
		* enemy.pack_speed_multiplier
		* enemy.facility_movement_multiplier
	)


func _notify_ordinary_melee_02s_of_defeat(defeated: EnemyState) -> void:
	for candidate in enemies:
		if candidate == defeated or not candidate.alive or not candidate.active:
			continue
		if candidate.archetype != &"ordinary_melee_02":
			continue
		var receipt := SpecialistRuntime.ordinary_melee_02_defeat_receipt(
			candidate, defeated, _ordinary_melee_02_stack_count(candidate)
		)
		if bool(receipt.get("claimed", false)):
			_ordinary_melee_02_stacks[candidate.id] = int(receipt["stacks"])


func _apply_pack_feed_receipt(receipt: Dictionary) -> void:
	if receipt.is_empty() or not receipt.has("survivor_ids"):
		return
	var heal_ratio := float(receipt.get("heal_ratio", 0.0))
	for survivor_id in PackedStringArray(receipt["survivor_ids"]):
		var survivor := _find_enemy_by_id(survivor_id)
		if survivor == null or not survivor.alive or survivor.summoned:
			continue
		survivor.health = minf(
			survivor.max_health,
			survivor.health + survivor.max_health * heal_ratio
		)
		survivor.health_visible_timer = maxf(survivor.health_visible_timer, 0.9)


func _move_actor(position: Vector2, motion: Vector2, radius: float, is_player: bool) -> Vector2:
	var destination := position + motion
	var extra_cover := _runtime_motion_cover_rects(position, destination, radius)
	var result := destination
	if not (_motion_cover_static_safe and extra_cover.is_empty()):
		result = Rules.move_circle_with_extra_safe(
			position,
			motion,
			radius,
			current_stage_id,
			extra_cover,
			_motion_cover_static_safe,
			_motion_cover_static_cover_clear
		)
	if _position_clear_of_stage_objects(result, radius):
		return result
	var x_attempt := Vector2(result.x, position.y)
	var y_attempt := Vector2(position.x, result.y)
	if _position_clear_of_stage_objects(x_attempt, radius):
		return x_attempt
	if _position_clear_of_stage_objects(y_attempt, radius):
		return y_attempt
	return position


func _position_clear_of_stage_objects(position: Vector2, actor_radius: float) -> bool:
	if not mystery_device_runtime.is_position_clear(position, actor_radius):
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
	threat_tier: StringName = AttackContract.THREAT_ORDINARY,
	distance_growth_kind: StringName = &"",
	applies_player_slow: bool = false,
	player_slow_duration: float = 0.0
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
		"distance_growth_kind":distance_growth_kind,
		"applies_player_slow":applies_player_slow,
		"player_slow_duration":player_slow_duration,
	}, final_damage)


func _count_hostile_projectiles() -> int:
	return projectile_store.hostile_count()


func _update_projectiles(delta: float, player_motion_from: Variant = null) -> void:
	_player_combat_previous_position = (
		player_position
		if player_motion_from == null
		else Vector2(player_motion_from)
	)
	_boss_barrage_hit_lock_remaining = maxf(0.0, _boss_barrage_hit_lock_remaining - maxf(0.0, delta))
	var section_started := (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	_update_projectile_buffer(
		hostile_projectiles, true, delta, _player_combat_previous_position
	)
	_performance_accumulate_enemy_section(
		"projectile_hostile", section_started
	)
	section_started = (
		Time.get_ticks_usec() if _performance_detail_sample_active else 0
	)
	_update_projectile_buffer(
		player_projectiles, false, delta, _player_combat_previous_position
	)
	_performance_accumulate_enemy_section(
		"projectile_player", section_started
	)


func _update_projectile_buffer(
	buffer: Array[ProjectileState],
	hostile: bool,
	delta: float,
	player_from: Vector2
) -> void:
	var index := 0
	while index < buffer.size():
		var projectile := buffer[index]
		var from := projectile.pos
		var simulation_delta := delta
		if player_position.distance_squared_to(from) > _near_simulation_distance_squared:
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
		projectile.advance_distance_growth(
			projectile.velocity.length() * simulation_delta
		)
		var to := from + projectile.velocity * simulation_delta
		var radius := projectile.radius
		if mystery_device_runtime.first_damageable_segment_hit(
			from, to, radius, _mystery_device_hit_receipt
		):
			var device_index := int(_mystery_device_hit_receipt["device_index"])
			var device_bit := 1 << device_index
			# A blocking player-primary hit is resolved once through the ordered
			# structure route below. Pass-through projectile families retain this
			# one-hit-per-device path.
			var resolves_as_blocking_structure := (
				not hostile and projectile.owner == "player_primary"
			)
			if (
				not resolves_as_blocking_structure
				and (projectile.facility_hit_mask & device_bit) == 0
			):
				projectile.facility_hit_mask |= device_bit
				_damage_mystery_device(
					StringName(_mystery_device_hit_receipt["device_id"]),
					projectile.structure_damage,
					&"projectile",
					Vector2(_mystery_device_hit_receipt["position"]),
					projectile.color,
					projectile.velocity.normalized(),
					&"hostile" if hostile else &"player"
				)
		var structure_query_started := (
			Time.get_ticks_usec()
			if _performance_detail_sample_active and not hostile else 0
		)
		var mystery_hit := (
			not hostile
			and projectile.owner == "player_primary"
			and mystery_device_runtime.first_intact_segment_hit(
				from, to, radius, _mystery_device_hit_receipt
			)
		)
		if not hostile:
			_performance_accumulate_enemy_section(
				"projectile_structure_query", structure_query_started
			)
		if not projectile.wall_piercing:
			var cover_query_started := (
				Time.get_ticks_usec()
				if _performance_detail_sample_active else 0
			)
			var cover_hit := _runtime_first_cover_hit(from, to, radius)
			_performance_accumulate_enemy_section(
				"projectile_cover_query", cover_query_started
			)
			if (
				mystery_hit
				and (
					not bool(cover_hit.get("hit", false))
					or float(_mystery_device_hit_receipt["t"])
						< float(cover_hit.get("t", INF))
				)
			):
				if _damage_mystery_device(
					StringName(_mystery_device_hit_receipt["device_id"]),
					projectile.structure_damage,
					&"direct",
					Vector2(_mystery_device_hit_receipt["position"]),
					projectile.color,
					projectile.velocity.normalized()
				):
					stats_primary_hits += 1
				_remove_projectile_at(hostile, index)
				continue
			if bool(cover_hit.get("hit", false)):
				if projectile.bounces > 0:
					projectile.bounces -= 1
					var normal: Vector2 = cover_hit["normal"]
					projectile.velocity = projectile.velocity.bounce(normal)
					projectile.pos = Vector2(cover_hit["point"]) + normal * (radius + 2.0)
					index += 1
					continue
				_play_sound(&"cover", _rng.randf_range(0.96, 1.04))
				_remove_projectile_at(hostile, index)
				continue
		elif mystery_hit:
			if _damage_mystery_device(
				StringName(_mystery_device_hit_receipt["device_id"]),
				projectile.structure_damage,
				&"direct",
				Vector2(_mystery_device_hit_receipt["position"]),
				projectile.color,
				projectile.velocity.normalized()
			):
				stats_primary_hits += 1
			_remove_projectile_at(hostile, index)
			continue

		projectile.pos = to
		if hostile:
			var direct_contact_t := AttackContract.relative_sweep_first_t(
				player_from,
				player_position,
				from,
				to,
				Rules.PLAYER_RADIUS + projectile.radius
			)
			var direct_contact := not is_inf(direct_contact_t)
			if (
				projectile.distance_growth_kind
					== ProjectileState.DISTANCE_GROWTH_GROWTH_KIND
				and projectile.distance_growth_proximity_armed
			):
				var trigger_t := AttackContract.relative_sweep_first_t(
					player_from,
					player_position,
					from,
					to,
					ProjectileState.DISTANCE_GROWTH_PROXIMITY_TRIGGER_RADIUS
						+ Rules.PLAYER_RADIUS
				)
				if not is_inf(trigger_t):
					projectile.pos = from.lerp(to, clampf(trigger_t, 0.0, 1.0))
					_detonate_distance_growth_projectile(
						projectile,
						player_from.lerp(
							player_position, clampf(trigger_t, 0.0, 1.0)
						)
					)
					projectile_store.remove_hostile_at_swap(index)
					continue
			if direct_contact:
				if projectile.owner.begins_with("boss_barrage:") and _boss_barrage_hit_lock_remaining > 0.0:
					projectile_store.remove_hostile_at_swap(index)
					continue
				_damage_player(projectile.damage, projectile.owner, true, true, projectile.final_damage)
				if projectile.applies_player_slow:
					player_slow_timer = maxf(player_slow_timer, projectile.player_slow_duration)
				if projectile.owner.begins_with("boss_barrage:"):
					_boss_barrage_hit_lock_remaining = 0.80
				projectile_store.remove_hostile_at_swap(index)
				continue
		else:
			var projectile_radius := radius
			var query_started := (
				Time.get_ticks_usec()
				if _performance_detail_sample_active else 0
			)
			enemy_grid.query_segment_cells_into(
				from,
				to,
				projectile_radius,
				enemies,
				_enemy_query_buffer,
				_enemy_query_group_ends,
				_enemy_query_group_exit_t
			)
			_performance_accumulate_enemy_section(
				"projectile_candidate_query", query_started
			)
			var hit_started := (
				Time.get_ticks_usec()
				if _performance_detail_sample_active else 0
			)
			var contact: Variant = _player_projectile_contact(
				projectile,
				from,
				to,
				projectile_radius,
				_enemy_query_buffer,
				_enemy_query_group_ends,
				_enemy_query_group_exit_t,
				INF
			)
			_performance_accumulate_enemy_section(
				"projectile_hit_resolution", hit_started
			)
			if contact is bool:
				_remove_projectile_at(false, index)
				continue
			var hit_enemy := contact as EnemyState
			if hit_enemy != null:
				if _try_reflect_direct_projectile(hit_enemy, projectile):
					_remove_projectile_at(false, index)
					continue
				_mark_primary_shot_group_hit(projectile)
				var hit_position := hit_enemy.pos
				if _try_absorb_protective_structure(hit_enemy, projectile):
					stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
					_play_sound(&"cover", 1.06)
					if projectile.pierce > 0:
						projectile.pierce -= 1
						projectile.pos = to + projectile.velocity.normalized() * 8.0
					else:
						_remove_projectile_at(false, index)
						continue
					index += 1
					continue
				var enemy_damage := projectile.damage
				if hit_enemy.role in [&"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01", &"ordinary_fixed_support_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01"]:
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
					true,
					false,
					true,
					OutgoingDamagePolicy.DAMAGE_DIRECT,
					projectile.combat_action_serial,
					(
						projectile.combat_action_family
						if not projectile.reflected
						else &""
					)
				)
				var status_receipt := StatusRuntime.apply(
					hit_enemy, projectile.primary_payload
				)
				_record_status_applications(projectile.primary_payload)
				if bool(status_receipt.get("cryo_shatter", false)):
					_damage_enemy(
						hit_enemy,
						float(status_receipt["cryo_shatter_damage"]),
						"cryo_shatter",
						&"cryo",
						true,
						false,
						true,
						0,
						projectile.combat_action_serial
					)
				if (
					projectile.primary_payload != null
					and projectile.primary_payload.can_trigger_thermal_burst(
						projectile.owner, projectile.reflected
					)
					and not _is_fixed_structure_enemy(hit_enemy)
				):
					_apply_thermal_burst(
						hit_enemy,
						hit_position,
						projectile.primary_payload
					)
				stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
				_play_sound(&"impact", _rng.randf_range(0.92, 1.08))
				if projectile.explosive:
					_damage_enemies_in_radius(
						hit_position, 95.0, 12.0,
						"Seeker burst", &"kinetic", true, hit_enemy.id
					)
					_add_effect(
						EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND,
						hit_position,
						projectile.color,
						0.18,
						95.0
					)
				if projectile.pierce > 0:
					projectile.pierce -= 1
					projectile.pos = to + projectile.velocity.normalized() * 8.0
				else:
					_remove_projectile_at(false, index)
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


func _try_reflect_direct_projectile(
	enemy: EnemyState,
	projectile: ProjectileState
) -> bool:
	if projectile.reflected or projectile.owner != "player_primary":
		return false
	var is_reflect_boss := enemy.role == &"boss" and current_stage_index == 9
	var is_teaching_enemy := (
		enemy.family_trait == &"reflector" and enemy.pack_trait_active
	)
	if not is_reflect_boss and not is_teaching_enemy:
		return false
	var reflected := (
		boss_shield_runtime.reflects_projectile(projectile.velocity)
		if is_reflect_boss
		else LateBossMechanics.hits_reflection_arc(
			enemy.presentation_facing,
			projectile.velocity
		)
	)
	if not reflected:
		return false
	var normal := (
		boss_shield_runtime.reflection_normal(projectile.velocity)
		if is_reflect_boss
		else enemy.presentation_facing.normalized()
	)
	if normal.is_zero_approx():
		normal = -projectile.velocity.normalized()
	var reflected_velocity := projectile.velocity.bounce(normal)
	projectile_store.add_hostile({
		"pos":enemy.pos + normal * (enemy.projectile_hit_radius + projectile.radius + 2.0),
		"spawn_origin":enemy.pos,
		"velocity":reflected_velocity,
		"radius":projectile.radius,
		"damage":LateBossMechanics.reflected_damage(projectile.damage),
		"structure_damage":0.0,
		"life":projectile.life,
		"color":Art.CORAL,
		"owner":"boss_reflection" if is_reflect_boss else "ordinary_reflection",
		"pierce":0,
		"bounces":0,
		"homing":false,
		"explosive":false,
		"reflected":true,
		"final_damage":true,
		"affinity":projectile.affinity,
		"threat_tier":AttackContract.THREAT_BOSS if is_reflect_boss else AttackContract.THREAT_ORDINARY,
	}, is_reflect_boss)
	# Capacity rejection still absorbs the shot at a live segment and never
	# the owner, as required by the reflection contract.
	_play_sound(&"cover", 1.12)
	return true


func _detonate_distance_growth_projectile(
	projectile: ProjectileState,
	player_sample: Vector2 = Vector2.INF
) -> bool:
	if projectile == null or not projectile.consume_distance_growth_detonation():
		return false
	if not is_finite(player_sample.x) or not is_finite(player_sample.y):
		player_sample = player_position
	var explosion_radius := ProjectileState.DISTANCE_GROWTH_EXPLOSION_RADIUS
	var explosion_damage := AttackContract.radial_damage(
		projectile.damage,
		player_sample.distance_to(projectile.pos),
		explosion_radius
	)
	if explosion_damage > 0.0:
		_damage_player(
			explosion_damage,
			"%s proximity detonation" % projectile.owner,
			false,
			true,
			projectile.final_damage
		)
	_add_effect(
		EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND,
		projectile.pos,
		Art.DANGER,
		0.18,
		explosion_radius
	)
	_play_sound(&"impact", 0.92)
	return true


func _remove_projectile_at(hostile: bool, index: int) -> void:
	if hostile:
		projectile_store.remove_hostile_at_swap(index)
	else:
		if index >= 0 and index < player_projectiles.size():
			_retire_primary_shot_group_projectile(player_projectiles[index])
		projectile_store.remove_player_at_swap(index)


func _ensure_player_projectile_capacity() -> void:
	if player_projectiles.size() < projectile_store.PLAYER_CAPACITY:
		return
	var oldest_index := -1
	var oldest_serial := 0x7FFFFFFFFFFFFFFF
	for index in player_projectiles.size():
		var serial := player_projectiles[index].spawn_serial
		if serial < oldest_serial:
			oldest_serial = serial
			oldest_index = index
	if oldest_index >= 0:
		_remove_projectile_at(false, oldest_index)


func _mark_primary_shot_group_hit(projectile: ProjectileState) -> void:
	if projectile.owner != "player_primary" or projectile.combat_action_serial <= 0:
		return
	var serial := projectile.combat_action_serial
	if _primary_shot_groups.has(serial):
		_primary_shot_groups[serial]["hit"] = true


func _retire_primary_shot_group_projectile(projectile: ProjectileState) -> void:
	if projectile.owner != "player_primary" or projectile.combat_action_serial <= 0:
		return
	var serial := projectile.combat_action_serial
	if not _primary_shot_groups.has(serial):
		return
	var group: Dictionary = _primary_shot_groups[serial]
	group["remaining"] = maxi(0, int(group.get("remaining", 1)) - 1)
	if int(group["remaining"]) > 0:
		return
	primary_combo_runtime.record_shot_group(
		bool(group.get("hit", false)),
		run_build.level_of(&"miss_compensation"),
		run_build.level_of(&"hit_chain")
	)
	_primary_shot_groups.erase(serial)


func _is_player_targetable_enemy(enemy: EnemyState) -> bool:
	if enemy == null or not enemy.alive or not enemy.active:
		return false
	return true


func _player_projectile_contact(
	projectile: ProjectileState,
	from: Vector2,
	to: Vector2,
	projectile_radius: float,
	candidates: Array[EnemyState],
	group_ends: PackedInt32Array = PackedInt32Array(),
	group_exit_t: PackedFloat32Array = PackedFloat32Array(),
	maximum_hit_t: float = INF
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
			if enemy.role == &"ordinary_fixed_ranged_02" and enemy.intercept_charges > 0:
				var intercept_t := AttackContract.segment_circle_first_t(
					from,
					to,
					enemy.pos,
					AttackContract.INTERCEPTOR_PROJECTILE_RADIUS
						+ projectile.radius
				)
				if intercept_t < best_hit_t and intercept_t < maximum_hit_t:
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
			if hit_t < best_hit_t and hit_t < maximum_hit_t:
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
		return true
	return best


func _find_enemy_by_id(enemy_id: String) -> EnemyState:
	return enemy_store.find(enemy_id)


func _player_sweep_distance_to_point(point: Vector2) -> float:
	return Rules.point_segment_distance(
		point, _player_combat_previous_position, player_position
	)


func _player_sweep_hits_corridor(
	corridor_from: Vector2,
	corridor_to: Vector2,
	half_width: float,
	translation: Vector2 = Vector2.ZERO
) -> bool:
	# Subtracting a corridor's same-tick translation from the player's endpoint
	# turns parallel segment motion into one static-corridor sweep.
	return AttackContract.segment_segment_distance(
		_player_combat_previous_position,
		player_position - translation,
		corridor_from,
		corridor_to
	) <= Rules.PLAYER_RADIUS + maxf(0.0, half_width)


func _boss_charge_contact_hits(
	charge_from: Vector2,
	charge_to: Vector2,
	boss_radius: float,
	contact_padding: float
) -> bool:
	return not is_inf(AttackContract.relative_sweep_first_t(
		_player_combat_previous_position,
		player_position,
		charge_from,
		charge_to,
		Rules.PLAYER_RADIUS + boss_radius + contact_padding
	))


func _update_denied_zones(delta: float, player_motion_from: Variant = null) -> void:
	_player_combat_previous_position = (
		player_position
		if player_motion_from == null
		else Vector2(player_motion_from)
	)
	for index in range(denied_zones.size() - 1, -1, -1):
		# A lethal zone hit can transition the run and clear the array while this
		# reverse pass is still unwinding. Treat that transition as terminal for
		# this pass instead of indexing the cleared snapshot.
		if index >= denied_zones.size():
			continue
		var zone: Dictionary = denied_zones[index]
		if float(zone["warning"]) > 0.0:
			zone["warning"] = maxf(0.0, float(zone["warning"]) - delta)
			continue
		zone["duration"] = float(zone["duration"]) - delta
		zone["tick"] = float(zone["tick"]) - delta
		if float(zone["duration"]) <= 0.0:
			denied_zones.remove_at(index)
			continue
		var shape := StringName(zone.get("shape", &"area"))
		var corridor_translation := Vector2.ZERO
		if shape == &"corridor" and zone.has("motion"):
			corridor_translation = Vector2(zone["motion"]) * delta
			zone["from"] = Vector2(zone["from"]) + corridor_translation
			zone["to"] = Vector2(zone["to"]) + corridor_translation
		var damage := 0.0
		if shape == &"area":
			damage = AttackContract.radial_damage(
				float(zone["damage"]),
				_player_sweep_distance_to_point(Vector2(zone["pos"])),
				float(zone["radius"])
			)
		elif shape == &"corridor":
			var corridor_from := Vector2(zone["from"])
			var corridor_to := Vector2(zone["to"])
			var beam_growth_seconds := float(
				zone.get("beam_growth_seconds", 0.0)
			)
			if beam_growth_seconds > 0.0:
				var growth_ratio := AttackContract.emitted_beam_growth_ratio(
					float(zone["duration"]),
					float(zone.get("duration_total", zone["duration"])),
					beam_growth_seconds
				)
				var emitter := Vector2(zone.get("beam_emitter", corridor_from))
				var emission_mode := StringName(zone.get(
					"beam_emission_mode", AttackContract.EMITTED_BEAM_FORWARD
				))
				corridor_from = AttackContract.emitted_beam_live_origin(
					corridor_from, emitter, growth_ratio, emission_mode
				)
				corridor_to = AttackContract.emitted_beam_live_endpoint(
					emitter, corridor_to, growth_ratio
				)
			if _player_sweep_hits_corridor(
				corridor_from - corridor_translation,
				corridor_to - corridor_translation,
				float(zone["width"]) * 0.5,
				corridor_translation
			):
				damage = float(zone["damage"])
		else:
			push_error("Unsupported denied-zone shape: %s" % String(shape))
			denied_zones.remove_at(index)
			continue
		if damage > 0.0 and float(zone["tick"]) <= 0.0:
			if bool(zone.get("single_hit", false)) and bool(zone.get("hit_committed", false)):
				continue
			zone["tick"] = 0.62
			zone["hit_committed"] = true
			_damage_player(
				damage,
				String(zone["source"]),
				false,
				true,
				bool(zone.get("final_damage", false))
			)


func _update_effects(delta: float) -> void:
	var index := 0
	while index < effects.size():
		var effect: VehicleEffectState = effects[index]
		effect.time -= delta
		if effect.time <= 0.0:
			effect_store.remove_at_swap(index)
			continue
		index += 1


func _clear_effects() -> void:
	effect_store.clear()


func _add_effect(
	kind: StringName,
	position: Vector2,
	color: Color,
	duration: float,
	radius: float,
	direction: Vector2 = Vector2.ZERO,
	value: float = 0.0,
	multiplier: float = 1.0,
	secondary_radius: float = 0.0
) -> void:
	if not VisualEventCatalog.has_event(kind):
		push_error("Unknown transient visual event: %s" % kind)
		return
	if kind == EffectStore.THERMAL_BURST_IMPACT_KIND:
		effect_store.add_thermal_burst_impact(
			position, color, duration, radius
		)
		return
	if kind == EffectStore.DROP_MINE_DETONATION_KIND:
		effect_store.add_drop_mine_detonation(
			position, color, duration, radius
		)
		return
	if kind == EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND:
		effect_store.add_explosive_seeker_impact(
			position, color, duration, radius
		)
		return
	if kind == EffectStore.EMP_CHARGE_KIND or kind == EffectStore.EMP_RELEASE_KIND:
		effect_store.add_emp_footprint(
			kind, position, color, duration, radius, secondary_radius
		)
		return
	effect_store.add(
		kind,
		position,
		color,
		duration,
		radius,
		direction,
		value,
		multiplier
	)


func _damage_enemy(
	enemy: EnemyState,
	amount: float,
	source: String,
	attribute: StringName,
	player_owned: bool,
	final_effective: bool = false,
	show_hit_flash: bool = true,
	damage_flags: int = 0,
	attack_serial: int = 0,
	combat_action_family: StringName = &"",
	grant_defeat_credit: bool = true
) -> float:
	if not enemy.alive:
		return 0.0
	# The body remains renderable during the destruction receipt, but it no
	# longer participates in combat, score, or life-steal resolution.
	if enemy.role == &"boss" and boss_death_runtime.active() and enemy.id == _dying_boss_id:
		return 0.0
	if player_owned:
		if attack_serial <= 0:
			_damage_receipt_serial += 1
			attack_serial = _damage_receipt_serial
		amount = OutgoingDamagePolicy.resolve_damage(
			amount,
			run_build.level_of(&"critical_targeting"),
			run_build.level_of(&"dash_overdrive"),
			run_build.level_of(&"last_stand_amplifier"),
			player_health / maxf(1.0, _player_max_health()),
			dash_upgrade_runtime.overdrive_active(),
			damage_flags,
			field_layout.seed if field_layout != null else run_index,
			attack_serial,
			hash(enemy.id),
			hash(source)
		)
	var role := enemy.role
	var multiplier := 1.0
	if not final_effective:
		multiplier *= enemy.facility_received_damage_multiplier
	if not final_effective and enemy.shielded:
		multiplier *= SpecialistRuntime.SHIELDED_RECEIVED_DAMAGE_MULTIPLIER
	if not final_effective and role == &"ordinary_pull_01" and enemy.vulnerable > 0.0:
		multiplier *= 1.50
	if not final_effective and player_owned:
		if role == &"boss" and current_stage_index == 10:
			multiplier *= LateBossMechanics.resonance_damage_multiplier(
				player_position.distance_to(enemy.pos), enemy.pattern_timer
			)
		elif enemy.archetype == &"ordinary_resonance_01":
			multiplier *= LateBossMechanics.resonance_damage_multiplier(
				player_position.distance_to(enemy.pos), 0.0
			)
		if enemy.archetype == &"ordinary_overload_01" and enemy.phase == &"active":
			multiplier *= LateBossMechanics.OVERLOAD_RECEIVED_DAMAGE_SCALE
		if (
			role == &"boss"
			and current_stage_index == 11
			and LateBossMechanics.overload_active(enemy.pattern_timer)
		):
			multiplier *= LateBossMechanics.OVERLOAD_RECEIVED_DAMAGE_SCALE
	var boss_damage_multiplier := 1.0
	if role == &"boss" and not final_effective:
		var hit_direction := (
			(player_position - enemy.pos).normalized()
			if player_owned and (damage_flags & OutgoingDamagePolicy.DAMAGE_DIRECT) != 0
			else Vector2.ZERO
		)
		boss_damage_multiplier = boss_shield_runtime.boss_damage_multiplier(
			hit_direction,
			enemy.presentation_facing,
			amount
		)
		multiplier *= boss_damage_multiplier
	var health_before := enemy.health
	if (
		not final_effective
		and role == &"ordinary_fixed_area_01"
		and amount * multiplier >= health_before
	):
		var mine_applied := maxf(0.0, health_before - 1.0)
		enemy.health = 1.0
		if show_hit_flash:
			enemy.flash = 0.11
		enemy.health_visible_timer = 1.5
		_arm_mine(enemy, 0.75, true)
		if player_owned and source != "validation":
			stage_telemetry.record_outgoing(
				DamageSourceCatalog.outgoing_id(source), attribute, mine_applied
			)
		_apply_lifesteal(mine_applied, source, player_owned)
		_credit_active_recharge_for_outgoing(
			mine_applied, combat_action_family, attack_serial, damage_flags
		)
		return mine_applied
	var resolved_damage := maxf(0.0, amount * multiplier)
	var barrier_damage := minf(enemy.facility_barrier_strength, resolved_damage)
	enemy.facility_barrier_strength -= barrier_damage
	var health_damage := minf(health_before, maxf(0.0, resolved_damage - barrier_damage))
	var applied_damage := barrier_damage + health_damage
	if applied_damage <= 0.0:
		return 0.0
	enemy.health = health_before - health_damage
	if player_owned and source != "validation":
		stage_telemetry.record_outgoing(
			DamageSourceCatalog.outgoing_id(source),
			attribute,
			applied_damage
		)
	if show_hit_flash:
		enemy.flash = 0.11
	enemy.health_visible_timer = 1.0 if enemy.health_class == &"swarm" else 1.5
	_apply_lifesteal(applied_damage, source, player_owned)
	_credit_active_recharge_for_outgoing(
		applied_damage, combat_action_family, attack_serial, damage_flags
	)
	if role == &"boss" and enemy.health > 0.0:
		var transition := boss_shield_runtime.try_advance_phase(
			enemy.health,
			enemy.max_health
		)
		if not transition.is_empty():
			_begin_boss_shield_phase(enemy, int(transition["phase"]))
	if enemy.health <= 0.0:
		_defeat_enemy(enemy, source, grant_defeat_credit)
	return applied_damage


func _credit_active_recharge_for_outgoing(
	applied_damage: float,
	action_family: StringName,
	action_serial: int,
	damage_flags: int
) -> void:
	if applied_damage <= 0.0 or action_family == &"" or action_serial <= 0:
		return
	var credited := active_recharge_runtime.credit_outgoing(
		action_family,
		action_serial,
		(damage_flags & OutgoingDamagePolicy.DAMAGE_PERIODIC) != 0
	)
	active_weapon_runtime.reduce_cooldown(credited)


func _apply_lifesteal(
	applied_damage: float,
	source: String,
	player_owned: bool
) -> void:
	if not player_owned or source == "validation":
		return
	var healing := lifesteal_runtime.consume(
		applied_damage,
		PlayerRecoveryPolicy.gross_capacity(
			run_build.level_of(&"overflow_barrier"),
			player_health,
			_player_max_health(),
			player_barrier_strength
		)
	)
	if healing > 0.0:
		_apply_player_recovery(healing)


func _apply_player_recovery(gross_recovery: float) -> float:
	var level := run_build.level_of(&"overflow_barrier")
	var split := PlayerRecoveryPolicy.split(
		gross_recovery,
		level,
		player_health,
		_player_max_health(),
		player_barrier_strength
	)
	player_health += split.x
	if split.y > 0.0:
		player_barrier_strength += split.y
		player_barrier_timer = PlayerRecoveryPolicy.BARRIER_DURATION
	return split.z


func _enemy_attack_line_padding(enemy: EnemyState) -> float:
	match enemy.role:
		&"ordinary_gap_01":
			return 4.0
		&"ordinary_growth_01":
			return 5.0
		&"ordinary_pull_01":
			return 12.0
	return 7.0


func _is_fixed_structure_enemy(enemy: EnemyState) -> bool:
	return (
		enemy.role in [
			&"ordinary_fixed_support_01", &"ordinary_fixed_ranged_01",
			&"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01",
		]
		or (
			enemy.role == &"ordinary_fixed_area_01"
			and enemy.archetype != &"ordinary_area_01"
		)
	)


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


func _record_status_applications(profile: VehiclePrimaryPayloadProfile) -> void:
	if profile == null:
		return
	if profile.poison_enabled:
		stage_telemetry.record_status_application(&"poison")
	if profile.chill_enabled:
		stage_telemetry.record_status_application(&"chill")


func _defeat_enemy(
	enemy: EnemyState,
	source: String,
	grant_defeat_credit: bool = true
) -> void:
	if not enemy.alive:
		return
	if enemy.role == &"boss":
		_begin_boss_destruction(enemy, source)
		return
	# Claim before retirement so nearby Scavengers observe a valid live wreck.
	_notify_ordinary_melee_02s_of_defeat(enemy)
	_apply_pack_feed_receipt(collective_tactics.record_member_defeat(enemy))
	_release_enemy_engagement(enemy)
	collective_tactics.unregister_enemy(enemy.id, enemy.squad_id)
	var role := enemy.role
	var split_on_defeat := (
		enemy.family_trait == &"splitter"
		and not enemy.summoned
		and not enemy.splitter_spawned
	)
	if split_on_defeat:
		enemy.splitter_spawned = true
		_spawn_splitter_children(enemy)
	enemy.alive = false
	enemy.active = false
	_ordinary_melee_02_stacks.erase(enemy.id)
	enemy_grid.update_actor(enemy)
	enemy_store.queue_defeat(enemy)
	if grant_defeat_credit:
		stats_enemies_defeated += 1
		stage_telemetry.record_defeat(
			enemy.archetype, enemy.family, enemy.family_trait
		)
		experience_runtime.spawn_shard(
			enemy.pos,
			FieldDropRules.experience_for_enemy(enemy),
			&""
		)
	if grant_defeat_credit and _is_countable_stage_enemy(enemy):
		encounter_runtime.record_ordinary_defeat(
			enemy.family, enemy.family_trait
		)
		var stage_receipt := stage_flow.record_countable_defeat()
		var stage_command := StringName(stage_receipt.get("command", &""))
		if stage_command == StageFlow.COMMAND_BEGIN_BOSS_WARNING:
			encounter_runtime.seal_for_quota()
			_session_diagnostics.emit_event("boss_warning", {
				"stage_index":current_stage_index,
				"ordinary_defeats":stage_flow.defeats,
			})
			boss_arrival_position = _choose_boss_arrival_anchor()
			discovered_markers["boss_warning"] = true
			var boss_profile_id := StageCatalog.boss_profile_id(current_stage_id)
			var boss_number := String(boss_profile_id).trim_prefix("stage_").to_int()
			_discover_guide(StringName("boss_stage_%d" % boss_number))
			_ui.notify_immediate(
				tr("NOTIFY_BOSS_INBOUND"), 1.5, Rules.CORAL, &"boss_inbound"
			)
			_play_sound(&"boss", 0.82)
		elif stage_command == StageFlow.COMMAND_COMPLETE_WITHOUT_BOSS:
			encounter_runtime.seal_for_quota()
			_complete_stage(StageTransitionRuntime.COMPLETION_WITHOUT_BOSS)
	if (
		grant_defeat_credit
		and role in [&"ordinary_fixed_support_01", &"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01"]
	):
		stats_installations += 1
	var defeated_group := enemy.group_id
	if grant_defeat_credit and not defeated_group.is_empty():
		_try_group_completion_reward(defeated_group, enemy.pos)
	_play_sound(
		&"destroy_priority"
		if role in [&"ordinary_fixed_support_01", &"ordinary_fixed_ranged_02", &"ordinary_support_01", &"ordinary_support_03", &"ordinary_fixed_beam_01"]
		else &"destroy",
		1.0
	)
	_clear_zones_owned_by_defeated_role(role)


func _begin_boss_destruction(boss: EnemyState, source: String) -> void:
	if boss_death_runtime.active() or not boss.alive:
		return
	var boss_receipt := stage_flow.record_boss_defeat()
	if StringName(boss_receipt.get("command", &"")) != StageFlow.COMMAND_BEGIN_BOSS_CLEANUP:
		return
	_dying_boss_id = boss.id
	boss.health = 0.0
	boss.phase = &"boss_dying"
	boss.phase_time = 0.0
	boss.velocity = Vector2.ZERO
	boss.attack_telegraphs.clear()
	boss.contact_attack = &""
	# Hazards stop at the death input. Adds/facilities are retired by staggered
	# receipts while this boss body remains alive for the presentation snapshot.
	encounter_runtime.stop_boss_maintenance()
	projectile_store.retire_boss_hostiles()
	_retire_denied_zones_by_owner(&"boss_actor")
	_pending_boss_barrage_rows.clear()
	boss_runtime.clear_pending_attacks()
	var owned_ids: Array[StringName] = []
	for enemy in enemies:
		if enemy != boss and enemy.alive and _is_boss_owned_enemy(enemy):
			owned_ids.append(StringName(enemy.id))
	var began := boss_death_runtime.begin(owned_ids, _reduced_motion_enabled())
	if not bool(began.get("accepted", false)):
		return
	_session_diagnostics.emit_event("boss_cleanup_started", {
		"stage_index":current_stage_index,
		"source":source,
		"owned_count":owned_ids.size(),
	})
	stage_telemetry.record_boss_lifecycle(
		StringName(StageCatalog.profile(current_stage_id).get("boss_name_key", "")),
		true,
		false,
		owned_ids.size()
	)
	_play_sound(&"destroy_priority", 1.05)
	if not _reduced_motion_enabled():
		camera_shake = maxf(camera_shake, 16.0)


func _advance_boss_destruction(delta: float) -> void:
	if not boss_death_runtime.active():
		return
	for receipt in boss_death_runtime.advance(delta):
		match StringName(receipt.get("kind", &"")):
			&"retire_owned":
				_retire_boss_owned_enemy_by_id(String(receipt.get("id", &"")), receipt)
			&"cleanup_complete":
				_finalize_boss_destruction(receipt)


func _retire_boss_owned_enemy_by_id(enemy_id: String, cleanup_receipt: Dictionary) -> void:
	if (
		bool(cleanup_receipt.get("grant_experience", true))
		or bool(cleanup_receipt.get("grant_group_reward", true))
		or bool(cleanup_receipt.get("count_for_quota", true))
	):
		push_error("Boss cleanup receipts must not grant progression rewards")
		return
	var owned := _find_enemy_by_id(enemy_id)
	if owned == null or not owned.alive or not _is_boss_owned_enemy(owned):
		return
	_release_enemy_engagement(owned)
	collective_tactics.unregister_enemy(owned.id, owned.squad_id)
	owned.alive = false
	owned.active = false
	enemy_grid.update_actor(owned)
	enemy_store.queue_defeat(owned)
	_enemy_frame_aggregate_valid = false


func _finalize_boss_destruction(cleanup_receipt: Dictionary) -> void:
	if (
		bool(cleanup_receipt.get("grant_experience", true))
		or bool(cleanup_receipt.get("grant_group_reward", true))
		or bool(cleanup_receipt.get("count_for_quota", true))
	):
		push_error("Boss cleanup completion must not grant progression rewards")
		return
	var boss := _find_enemy_by_id(_dying_boss_id)
	if boss != null and boss.alive:
		_release_enemy_engagement(boss)
		collective_tactics.unregister_enemy(boss.id, boss.squad_id)
		boss.alive = false
		boss.active = false
		enemy_grid.update_actor(boss)
		enemy_store.queue_defeat(boss)
		# The boss remains a truthful combat defeat in reports, but its cleanup
		# receipt cannot advance the ordinary quota or grant progression rewards.
		stats_enemies_defeated += 1
		stage_telemetry.record_defeat(
			boss.archetype, boss.family, boss.family_trait
		)
	_session_diagnostics.emit_event("boss_ended", {"stage_index":current_stage_index})
	stage_telemetry.record_boss_lifecycle(
		StringName(StageCatalog.profile(current_stage_id).get("boss_name_key", "")),
		true,
		true,
		0,
		float(boss_death_runtime.snapshot().get("elapsed", 0.0))
	)
	var flow_receipt := stage_flow.record_boss_cleanup_complete()
	if StringName(flow_receipt.get("command", &"")) == StageFlow.COMMAND_COMPLETE_AFTER_BOSS_CLEANUP:
		_complete_stage(StageTransitionRuntime.COMPLETION_AFTER_BOSS)
	_dying_boss_id = ""


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
			"role":&"ordinary_pursuer_t1",
			"pack_family":&"pursuer",
			"pack_tier":1,
			"pack_trait":&"",
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
	return enemy.role != &"boss"


func _try_group_completion_reward(group_id: String, _position: Vector2) -> void:
	if completed_group_rewards.has(group_id):
		return
	for candidate in enemies:
		if candidate.group_id == group_id and candidate.alive:
			return
	completed_group_rewards[group_id] = true


func _clear_zones_owned_by_defeated_role(role: StringName) -> void:
	if role == &"boss":
		_retire_denied_zones_by_owner(&"boss_actor")


func _damage_player(
	amount: float,
	source: String,
	blockable: bool,
	enemy_source: bool = true,
	final_effective: bool = false,
	grant_hit_protection: bool = true,
	bypass_invulnerability: bool = false
) -> bool:
	if (
		not _simulation_active()
		or (player_invulnerable > 0.0 and not bypass_invulnerability)
		or stage_complete
	):
		return false
	var remaining := (
		_scaled_incoming_damage(amount, enemy_source, final_effective)
		* (1.0 if final_effective else _player_facility_received_damage_multiplier())
	)
	if remaining <= 0.0:
		return false
	var accepted := false
	var barrier_loss := 0.0
	if blockable and player_barrier_strength > 0.0 and player_barrier_timer > 0.0:
		var absorbed := minf(player_barrier_strength, remaining)
		player_barrier_strength -= absorbed
		remaining -= absorbed
		barrier_loss = absorbed
		if absorbed > 0.0:
			accepted = true
			player_barrier_hit_flash = PLAYER_BARRIER_HIT_FLASH_DURATION
			_play_sound(&"cover", 1.04)
		if player_barrier_strength <= 0.0:
			_ui.notify_immediate(
				tr("NOTIFY_BARRIER_DEPLETED"),
				1.6,
				Rules.CORAL,
				&"barrier_depleted"
			)
	if remaining <= 0.0:
		_credit_active_recharge_for_incoming(barrier_loss, 0.0, enemy_source)
		return accepted
	accepted = true
	encounter_runtime.record_player_damage(_damage_source_family(source, enemy_source))
	var health_before := player_health
	player_health = maxf(0.0, player_health - remaining)
	var hull_loss := maxf(0.0, health_before - player_health)
	stats_damage_taken += remaining
	stage_telemetry.record_incoming(
		DamageSourceCatalog.incoming_id(source, enemy_source),
		remaining
	)
	player_hit_flash = PLAYER_HIT_FLASH_DURATION
	if grant_hit_protection:
		_grant_player_protection(PLAYER_HIT_INVULNERABILITY, &"hit")
	if not _reduced_motion_enabled():
		camera_shake = maxf(camera_shake, 3.0)
	_last_damage_source = source
	_play_sound(&"hurt")
	_credit_active_recharge_for_incoming(barrier_loss, hull_loss, enemy_source)
	if player_health <= 0.0:
		_handle_player_defeat()
	return accepted


func _credit_active_recharge_for_incoming(
	barrier_loss: float,
	hull_loss: float,
	enemy_source: bool
) -> void:
	if not enemy_source:
		return
	var credited := active_recharge_runtime.credit_incoming(
		barrier_loss, hull_loss
	)
	active_weapon_runtime.reduce_cooldown(credited)


func _scaled_incoming_damage(amount: float, enemy_source: bool, final_effective: bool = false) -> float:
	if not enemy_source:
		return amount
	var difficulty_damage := RunDifficulty.factor(selected_run_difficulty, "damage")
	if final_effective:
		return amount * difficulty_damage
	var stage_curve := StageDifficulty.multipliers(current_stage_index)
	return (
		amount
		* EncounterDirector.ENEMY_DAMAGE_MULTIPLIER
		* float(stage_curve["damage"])
		* float(stage_curve["ordinary_damage_pressure"])
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
	mode = RunMode.FAILURE_REPORT
	_session_diagnostics.emit_event("run_failed", {
		"stage_index":current_stage_index,
		"ordinary_defeats":stage_flow.defeats,
	})
	_pending_stage_report = StageReportBuilder.build(
		stage_telemetry.freeze_stage(),
		_stage_report_context(false),
		true
	)
	_ui.show_stage_report(_pending_stage_report)
	_finish_session_diagnostics("run_failed")
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
			_damage_enemy(
				enemy, 16.0, "Dash impact", &"kinetic", true,
				false, true, OutgoingDamagePolicy.DAMAGE_DIRECT,
				_dash_action_serial, &"dash"
			)
			var push := (enemy.pos - player_position).normalized()
			enemy.pos = _move_actor(enemy.pos, push * 45.0, enemy.radius, false)
			enemy_grid.update_actor(enemy)


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
			_damage_enemy(
				enemy, damage, source, attribute, player_owned,
				false, true,
				OutgoingDamagePolicy.DAMAGE_DIRECT if player_owned else 0
			)
	_damage_mystery_devices_in_radius(
		center, radius, damage, &"player" if player_owned else &"hostile"
	)


func _apply_thermal_burst(
	direct_target: EnemyState,
	center: Vector2,
	profile: VehiclePrimaryPayloadProfile
) -> void:
	## One bounded splash query per eligible primary contact. Splash never
	## targets its direct hit, fixed structures, devices, or facilities.
	if profile == null or not profile.thermal_enabled:
		return
	var radius := profile.thermal_burst_radius
	_add_effect(
		&"thermal_burst_impact",
		center,
		Color.WHITE,
		0.18,
		radius
	)
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if (
			enemy == direct_target
			or not _is_player_targetable_enemy(enemy)
			or _is_fixed_structure_enemy(enemy)
		):
			continue
		if enemy.pos.distance_to(center) <= radius + enemy.radius:
			_damage_enemy(
				enemy,
				profile.thermal_burst_damage,
				"thermal_burst",
				&"thermal",
				true,
				false,
				true,
				OutgoingDamagePolicy.DAMAGE_DIRECT
			)


func _damage_mystery_devices_in_radius(
	center: Vector2,
	radius: float,
	damage: float,
	source_team: StringName = &"player"
) -> void:
	mystery_device_runtime.fill_device_snapshot(
		_mystery_device_snapshot_buffer
	)
	for device in _mystery_device_snapshot_buffer:
		if StringName(device["state"]) != &"dormant" or not bool(device.get("published", true)):
			continue
		var device_position := Vector2(device["position"])
		var device_radius := float(device.get(
			"radius", MysteryDeviceRuntime.DEVICE_RADIUS
		))
		if (
			device_position.distance_to(center)
			> radius + device_radius
		):
			continue
		_damage_mystery_device(
			StringName(device["id"]),
			damage,
			&"area",
			device_position,
			Art.SYSTEM,
			(device_position - center).normalized(),
			source_team
		)


func _damage_mystery_device(
	device_id: StringName,
	damage: float,
	attack_kind: StringName,
	_hit_position: Vector2,
	_color: Color,
	_direction: Vector2,
	source_team: StringName = &"player"
) -> bool:
	var receipt := mystery_device_runtime.receive_damage(
		device_id, damage, source_team, attack_kind
	)
	if not bool(receipt["accepted"]):
		return false
	_play_sound(&"cover", _rng.randf_range(0.96, 1.04))
	if bool(receipt["broken"]):
		_handle_mystery_device_break(Dictionary(receipt["break_event"]))
	queue_redraw()
	return true


func _handle_mystery_device_break(event: Dictionary) -> Dictionary:
	var device_id := StringName(event.get("device_id", &""))
	_publish_facility_notification(event)
	_play_sound(&"destroy_priority", 1.02)
	_mystery_device_result_receipt.clear()
	_mystery_device_result_receipt["device_id"] = device_id
	_session_diagnostics.emit_event("neutral_facility_activated", {
		"device_id":device_id,
	})
	return _mystery_device_result_receipt


func _handle_mystery_device_event(event: Dictionary) -> void:
	_publish_facility_notification(event)
	_session_diagnostics.emit_event(StringName(event.get("kind", &"facility_event")), {
		"device_id":StringName(event.get("device_id", &"")),
		"outcome":StringName(event.get("outcome", &"")),
	})


func _apply_lava_facility_tick(event: Dictionary) -> void:
	var center := Vector2(event.get("position", Vector2.ZERO))
	var radius := maxf(0.0, float(event.get("radius", 0.0)))
	var tick_count := clampi(int(event.get("tick_count", 0)), 0, 24)
	var damage := maxf(0.0, float(event.get("damage_per_tick", 0.0))) * tick_count
	if radius <= 0.0 or damage <= 0.0:
		return
	if player_position.distance_to(center) <= radius:
		_damage_player(damage, "lava facility", false, false, true, false, true)
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if not _is_player_targetable_enemy(enemy):
			continue
		if Vector2(enemy.pos).distance_to(center) > radius:
			continue
		_damage_enemy(
			enemy, damage, "lava_facility", &"thermal", false,
			true, false, 0, 0, &"", false
		)


func _publish_facility_notification(event: Dictionary) -> void:
	var kind := StringName(event.get("kind", &""))
	var outcome := StringName(event.get("outcome", &""))
	var message_key := _facility_notification_key(kind, outcome)
	if message_key.is_empty():
		return
	var message := tr(message_key)
	if kind in [&"facility_expiry_warning", &"facility_shutdown"]:
		var outcome_name_key := _facility_outcome_name_key(outcome)
		if outcome_name_key.is_empty():
			return
		message = message % tr(outcome_name_key)
	_ui.notify(
		message,
		2.4 if kind == &"facility_expiry_warning" else 1.8,
		Art.SYSTEM,
		2 if kind == &"facility_expiry_warning" else 1,
		StringName("%s_%s" % [String(kind), String(outcome)])
	)


func _facility_notification_key(kind: StringName, outcome: StringName) -> String:
	if kind == &"facility_expiry_warning":
		return "NOTIFY_FACILITY_EXPIRY_WARNING"
	if kind == &"facility_shutdown":
		return "NOTIFY_FACILITY_SHUTDOWN"
	if kind != &"facility_activated":
		return ""
	match outcome:
		&"repair": return "NOTIFY_FACILITY_REPAIR_ACTIVATED"
		&"cryo": return "NOTIFY_FACILITY_CRYO_ACTIVATED"
		&"weakpoint": return "NOTIFY_FACILITY_WEAKPOINT_ACTIVATED"
		&"lava": return "NOTIFY_FACILITY_LAVA_ACTIVATED"
	return ""


func _facility_outcome_name_key(outcome: StringName) -> String:
	match outcome:
		&"repair": return "MYSTERY_OUTCOME_REPAIR"
		&"cryo": return "MYSTERY_OUTCOME_CRYO"
		&"weakpoint": return "MYSTERY_OUTCOME_WEAKPOINT"
		&"lava": return "MYSTERY_OUTCOME_LAVA"
	return ""


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
	_advance_pending_boss_barrage(delta)
	boss_runtime.advance_pending_attacks(delta, self)
	_advance_boss_destruction(delta)
	var receipt := stage_flow.advance(delta)
	if (
		StageFlow.valid_receipt(receipt)
		and StringName(receipt["command"]) == StageFlow.COMMAND_ENTER_BOSS
		and not boss_started
	):
		_start_stage_boss()


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
	current_card_offer = _build_card_offer(source_id, offer_serial)
	if current_card_offer.is_empty():
		var offer_seed := field_layout.seed if field_layout != null else run_index
		var compatible := upgrade_catalog.compatible_definitions(run_build)
		if not compatible.is_empty():
			upgrade_offer_error = {
				"source":source_id,
				"seed":offer_seed,
				"stage_index":current_stage_index,
				"offer_serial":offer_serial,
				"offer_size":current_card_offer.size(),
				"compatible_count":compatible.size(),
				"build_levels":run_build.levels.duplicate(true),
			}
			push_error(
				"Vehicle upgrade offer invariant failed: %s"
				% JSON.stringify(upgrade_offer_error)
			)
			return
		upgrade_offer_error.clear()
		current_card_offer = _build_fallback_offer()
		if not current_card_offer.is_empty():
			mode = RunMode.UPGRADE
			upgrade_selection_applied = false
			stage_telemetry.record_upgrade_opened(active_run_elapsed_seconds)
			_ui.show_upgrade(current_card_offer, _build_snapshot())
			_play_sound(&"card", 0.9)
			_set_mouse_for_mode()
			return
		if experience_runtime.complete_progression():
			_ui.notify(
				tr("NOTIFY_ALL_UPGRADES_COMPLETE"),
				2.4,
				Art.SYSTEM,
				1,
				&"all_upgrades_complete"
			)
		_resolve_reward_transaction()
		return
	upgrade_offer_error.clear()
	mode = RunMode.UPGRADE
	upgrade_selection_applied = false
	stage_telemetry.record_upgrade_opened(active_run_elapsed_seconds)
	_session_diagnostics.emit_event("upgrade_opened", {
		"source_id":source_id,
		"stage_index":current_stage_index,
		"offer_count":current_card_offer.size(),
	})
	_ui.show_upgrade(current_card_offer, _build_snapshot())
	_play_sound(&"card", 0.9)
	_set_mouse_for_mode()


func apply_upgrade(upgrade_id: StringName) -> bool:
	if (
		mode != RunMode.UPGRADE
		or reward_runtime.current_source().is_empty()
		or upgrade_selection_applied
		or current_card_offer.is_empty()
		or current_card_offer.size() > 3
		or not upgrade_offer_error.is_empty()
		or not _current_offer_contains(upgrade_id)
	):
		return false
	var fallback := upgrade_id in VehicleRunBuild.FALLBACK_IDS
	var receipt := (
		run_build.apply_fallback(upgrade_id)
		if fallback else run_build.apply(upgrade_id)
	)
	if not bool(receipt.get("applied", false)):
		return false
	var definition := upgrade_catalog.get_definition(upgrade_id)
	selected_upgrade_title_key = (
		"UPGRADE_%s_TITLE" % String(upgrade_id).to_upper()
		if fallback else definition.title_key
	)
	if fallback and StringName(receipt.get("effect_id", &"")) == &"max_hull":
		player_health = minf(_player_max_health(), player_health + 3.0)
	if upgrade_id == &"hull_integrity":
		player_health = minf(_player_max_health(), player_health + 15.0)
	lifesteal_runtime.configure(run_build.stat(&"lifesteal_percent", 0.0))
	_primary_payload = PrimaryPayload.from_build(run_build)
	_hud_presenter.mark_guidebook_dirty()
	upgrade_selection_applied = true
	return true


func _current_offer_contains(upgrade_id: StringName) -> bool:
	for card in current_card_offer:
		if StringName(card.get("id", &"")) == upgrade_id:
			return true
	return false


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
	upgrade_selection_applied = false


func _advance_reward_queue() -> void:
	if mode != RunMode.PLAYING:
		return
	if experience_runtime.pending_level_ups > 0:
		_open_upgrade_reward(RewardRuntime.LEVEL_UP_SOURCE)
		return
	if reward_runtime.has_pending():
		var source := reward_runtime.pop_pending()
		_open_upgrade_reward(source)


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
		offer_serial,
		reward_runtime.current_level_up_offer_index() == 0
	):
		var current_level := run_build.level_of(definition.id)
		cards.append(UpgradeOfferPresenter.snapshot(definition, current_level))
	return cards


func _build_fallback_offer() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fallback_id in VehicleRunBuild.FALLBACK_IDS:
		var preview := run_build.fallback_preview(fallback_id)
		if not bool(preview.get("valid", false)):
			continue
		var representative := StringName({
			&"fallback_firepower":&"critical_targeting",
			&"fallback_chassis":&"hull_integrity",
			&"fallback_operations":&"pickup_radius",
		}[fallback_id])
		var representative_definition := upgrade_catalog.get_definition(representative)
		var effect_id := StringName(preview["effect_id"])
		result.append({
			"id":fallback_id,
			"title_key":"UPGRADE_%s_TITLE" % String(fallback_id).to_upper(),
			"description_key":"UPGRADE_%s_DESCRIPTION" % String(fallback_id).to_upper(),
			"category_key":"UPGRADE_CATEGORY_FALLBACK",
			"category":&"fallback",
			"current_level":int(preview["old_rank"]),
			"next_level":int(preview["new_rank"]),
			"max_level":VehicleRunBuild.FALLBACK_MAX_RANK,
			"change_kind":&"stats",
			"change_label_key":"",
			"activation_mode":&"",
			"effect_rows":[{
				"stat_key":"UPGRADE_FALLBACK_EFFECT_%s" % String(effect_id).to_upper(),
				"operation":"add",
				"display_unit":"percent" if "percent" in String(effect_id) else "none",
				"current":0.0,
				"next":float(preview["value"]),
				"show_current":false,
				"absolute_value":true,
			}],
			"artwork_asset_id":representative_definition.artwork_asset_id,
		})
	return result


func _start_stage_boss() -> void:
	if boss_started or not stage_flow.boss_entry_ready():
		return
	if (
		enemy_store.live_count()
		> EnemyStore.MAX_LIVE_HOSTILES
			- BossPhaseCatalog.BOSS_ENTRY_SLOT_RESERVE
	):
		return
	boss_started = true
	discovered_markers["boss_actor"] = true
	boss_shield_runtime.configure(current_stage_id)
	if boss_arrival_position.is_zero_approx():
		boss_arrival_position = _choose_boss_arrival_anchor()
	var boss := _make_enemy({
		"id": "boss_actor",
		"role": "boss_actor",
		"pos": boss_arrival_position,
		"zone": "boss",
		"name_key": StageCatalog.profile(current_stage_id)["boss_name_key"],
		"boss_variant":boss_shield_runtime.variant(),
		"boss_shield_state":boss_shield_runtime.state(),
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
	_session_diagnostics.emit_event("boss_started", {
		"stage_index":current_stage_index,
		"boss_id":current_stage_id,
	})
	_begin_boss_shield_phase(boss, 1)
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
	if not bool(boss.alive) or (boss_death_runtime.active() and boss.id == _dying_boss_id):
		return
	boss.pattern_timer += maxf(0.0, delta)
	_refresh_late_boss_mechanic_state(boss)
	boss_shield_runtime.advance(delta)
	boss.boss_shield_state = boss_shield_runtime.state()
	_show_pending_boss_state_hint()
	var cadence_delta := delta
	if (
		current_stage_index == 11
		and boss.phase in [&"boss_read", &"boss_recovery"]
	):
		cadence_delta = LateBossMechanics.overload_cadence_delta(
			delta, boss.pattern_timer
		)
	for event in boss_runtime.advance_autonomous(
		LateBossMechanics.overload_cadence_delta(delta, boss.pattern_timer)
			if current_stage_index == 11 else delta,
		boss,
		player_position
	):
		_execute_boss_autonomous(event)
	var signature_active := (
		boss.phase in [&"boss_startup", &"boss_active"]
		and BossPatterns.is_signature(current_stage_id, String(boss.pattern))
	)
	var squad_event := boss_runtime.advance_squad(delta, boss, signature_active)
	if not squad_event.is_empty():
		_spawn_boss_phase_adds(
			boss,
			Array(squad_event.get("roles", [])),
			StringName(squad_event.get("tactic_id", &"")),
			String(squad_event.get("id", ""))
		)
	var receipt := boss_runtime.advance_direct_phase(boss, cadence_delta, false)
	if not BossRuntime.valid_phase_receipt(receipt):
		push_error("Boss runtime emitted an invalid phase receipt")
		return
	match StringName(receipt["action"]):
		BossRuntime.ACTION_REPOSITION:
			_boss_reposition(boss, delta)
		BossRuntime.ACTION_SELECT_DIRECT:
			_boss_select_pattern(boss)
		BossRuntime.ACTION_REFRESH_STARTUP:
			AttackTelegraphs.update_boss_readiness(
				boss, String(boss.pattern), current_stage_index
			)
		BossRuntime.ACTION_BEGIN_ACTIVE:
			AttackTelegraphs.update_boss_readiness(
				boss, String(boss.pattern), current_stage_index
			)
			_boss_begin_active(boss)
		BossRuntime.ACTION_UPDATE_ACTIVE:
			_boss_update_active(boss, delta)


func _boss_select_pattern(boss: EnemyState) -> void:
	var pattern := boss_runtime.select_direct(boss)
	var kind := BossPatterns.kind(pattern)
	boss.pattern = pattern
	boss.phase = "boss_startup"
	boss.phase_time = AttackContract.warned_startup_seconds(
		BossPatterns.startup_seconds(pattern, current_stage_index),
		kind
	)
	boss.hit_committed = false
	var predicted_target := _boss_predicted_target(
		Vector2(boss.pos),
		BossPatterns.projectile_speed(pattern)
	)
	if (
		kind in [&"area", &"pylons", &"summon"]
		and BossPatterns.damage(pattern, current_stage_index) > 0.0
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
		var spacing := BossPatterns.lane_spacing(current_stage_index)
		boss.lane_centers = [-spacing, spacing]
	if kind in [&"crossing_weave", &"radial_volley", &"compression"]:
		_prepare_boss_identity_pattern(boss, pattern)
	AttackTelegraphs.refresh_boss(
		boss,
		pattern,
		_runtime_attack_path_callable,
		_runtime_charge_path_callable,
		current_stage_index
	)


func _boss_begin_active(boss: EnemyState) -> void:
	boss.boss_attack_damage_multiplier = (
		boss_shield_runtime.consume_counterburst_multiplier()
		if String(boss.pattern) == "shield_counterburst"
		else 1.0
	)
	if current_stage_index == 11 and LateBossMechanics.overload_active(boss.pattern_timer):
		boss.boss_attack_damage_multiplier *= LateBossMechanics.OVERLOAD_DEALT_DAMAGE_SCALE
	boss_runtime.begin_active(boss, self)


func _boss_update_active(boss: EnemyState, delta: float) -> void:
	boss_runtime.update_active(boss, delta, self)


func _prepare_boss_identity_pattern(boss: EnemyState, pattern: String) -> void:
	if boss == null or not boss.alive or boss_death_runtime.active():
		return
	var event := {
		"id":"direct_%s_%d" % [boss.id, boss.pattern_index],
		"pattern":pattern,
		"kind":BossPatterns.kind(pattern),
		"origin":Vector2(boss.pos),
		"target":Vector2(boss.committed_target),
		"startup":BossPatterns.startup_seconds(pattern, current_stage_index),
		"duration":BossPatterns.active_seconds(pattern, current_stage_index),
		"damage":BossPatterns.damage(pattern, current_stage_index),
		"radius":BossPatterns.radius(pattern, current_stage_index),
		"width":BossPatterns.width(pattern, current_stage_index),
		"lane_spacing":BossPatterns.lane_spacing(current_stage_index),
		"affinity":BossPatterns.affinity(pattern),
		"commit_mode":&"committed",
		"direct_boss_id":boss.id,
	}
	_execute_boss_identity_event(event)


func _activate_boss_identity_pattern(boss: EnemyState, pattern: String) -> void:
	if boss == null or not boss.alive:
		return
	var prepared := false
	for zone in denied_zones:
		if (
			String(zone.get("direct_boss_id", "")) == boss.id
			and String(zone.get("source", "")) == pattern
		):
			zone["direct_active"] = true
			prepared = true
	if not prepared:
		push_error("Boss identity pattern reached active without prepared geometry: %s" % pattern)


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


func _spawn_boss_broad_barrage(boss: EnemyState, rows: Array[Dictionary]) -> void:
	if boss == null or not boss.alive or boss_death_runtime.active():
		return
	_pending_boss_barrage_rows.clear()
	for row in rows:
		if _pending_boss_barrage_rows.size() >= 3:
			break
		var scheduled := row.duplicate(true)
		scheduled["remaining"] = maxf(0.0, float(row.get("at", 0.0)))
		scheduled["origin"] = Vector2(boss.pos)
		scheduled["owner"] = "boss_barrage:%s:%d" % [boss.id, int(row.get("row", 0))]
		_pending_boss_barrage_rows.append(scheduled)
	_advance_pending_boss_barrage(0.0)


func _append_boss_cross_corridors(
	boss: EnemyState,
	pattern: String,
	damage: float
) -> void:
	if boss == null or not boss.alive:
		return
	var half_width := BossPatterns.width(pattern, current_stage_index) * 0.5
	for corridor_index in 2:
		var offset := -PI * 0.25 if corridor_index == 0 else PI * 0.25
		var axis := Vector2(boss.committed_dir).rotated(offset).normalized()
		var from := _runtime_attack_path_end(
			boss.pos, -axis, BossPatterns.BEAM_RANGE, half_width
		)
		var to := _runtime_attack_path_end(
			boss.pos, axis, BossPatterns.BEAM_RANGE, half_width
		)
		denied_zones.append({
			"id":"%s_cross_%d" % [boss.id, corridor_index],
			"shape":&"corridor",
			"from":from,
			"to":to,
			"width":half_width * 2.0,
			"warning":0.0,
			"warning_total":BossPatterns.startup_seconds(pattern, current_stage_index),
			"duration":BossPatterns.active_seconds(pattern, current_stage_index),
			"tick":0.0,
			"damage":damage,
			"source":pattern,
			"owner_kind":&"boss_actor",
			"affinity":BossPatterns.affinity(pattern),
			"commit_mode":&"committed",
			"final_damage":true,
			"single_hit":true,
			"hit_committed":false,
			"beam_growth_seconds":AttackContract.EMITTED_BEAM_GROWTH_SECONDS,
			"beam_emission_mode":AttackContract.EMITTED_BEAM_BIDIRECTIONAL,
			"beam_emitter":Vector2(boss.pos),
			"emitter_radius":boss.visual_radius,
			"duration_total":BossPatterns.active_seconds(pattern, current_stage_index),
		})
	# Collision and active presentation transfer to the zones above. Retiring the
	# startup descriptors prevents the same X beams from being submitted twice.
	boss.attack_telegraphs.clear()


func _advance_pending_boss_barrage(delta: float) -> void:
	for index in range(_pending_boss_barrage_rows.size() - 1, -1, -1):
		var row := _pending_boss_barrage_rows[index]
		row["remaining"] = float(row.get("remaining", 0.0)) - maxf(0.0, delta)
		if float(row["remaining"]) > 0.0:
			continue
		_fire_boss_barrage_row(row)
		_pending_boss_barrage_rows.remove_at(index)


func _fire_boss_barrage_row(row: Dictionary) -> void:
	var count := clampi(int(row.get("count", 4)), 4, 6)
	var axis := Vector2(row.get("axis", Vector2.RIGHT)).normalized()
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	var tangent := axis.rotated(PI * 0.5)
	var mode := StringName(row.get("mode", &"spread"))
	var origin := Vector2(row.get("origin", Vector2.ZERO))
	var spacing := float(row.get("spacing", 96.0))
	for shot_index in count:
		var centered := float(shot_index) - float(count - 1) * 0.5
		var direction := axis
		if mode == &"spread":
			var ratio := centered / maxf(1.0, float(count - 1) * 0.5)
			direction = axis.rotated(deg_to_rad(21.0) * ratio)
		var spawn_position := origin + tangent * spacing * centered + direction * 72.0
		_spawn_hostile_projectile(
			spawn_position,
			direction,
			float(row.get("damage", 14.0)),
			BossPatterns.projectile_speed("common_broad_barrage"),
			String(row.get("owner", "boss_barrage")),
			BossPatterns.affinity("common_broad_barrage"),
			true,
			false,
			AttackContract.THREAT_BOSS
		)


func _fire_boss_radial_volley(volley: Dictionary) -> void:
	var origin := Vector2(volley.get("origin", Vector2.ZERO))
	var count := clampi(int(volley.get("count", 12)), 6, 16)
	var rotation := float(volley.get("rotation", 0.0))
	for shot_index in count:
		var direction := Vector2.RIGHT.rotated(
			rotation + TAU * float(shot_index) / float(count)
		)
		_spawn_hostile_projectile(
			origin + direction * 66.0,
			direction,
			float(volley.get("damage", 12.0)),
			540.0,
			String(volley.get("source", "boss_radial_volley")),
			StringName(volley.get("affinity", &"arc")),
			true,
			false,
			AttackContract.THREAT_BOSS
		)


func _execute_boss_autonomous(event: Dictionary) -> void:
	var pattern := String(event["pattern"])
	var kind := StringName(event.get("kind", BossPatterns.kind(pattern)))
	if kind == &"summon" and pattern == "boss_pattern_fixed_beam_01_call":
		if _live_boss_add_count() >= BossPhaseCatalog.MAX_LIVE_ADDS:
			return
		var sentinel := _make_enemy({
			"id":String(event["id"]),
			"role":&"boss_pattern_fixed_beam_01",
			"pos":_move_actor(Vector2(event["target"]), Vector2.ZERO, 34.0, false),
			"active":true,
			"summoned":true,
			"zone":"boss_system",
		})
		_append_enemy(sentinel)
		return
	if kind == &"area":
		_append_boss_area_zone(event)
		return
	if kind == &"lanes":
		_append_boss_lane_zones(event)
		return
	if kind == &"beam":
		_append_boss_beam_zone(event)
		return
	if kind == &"long_banks":
		_spawn_boss_long_banks(event)
		return
	if kind in [&"crossing_weave", &"radial_volley", &"compression"]:
		_execute_boss_identity_event(event)
		return
	push_error("Unsupported autonomous boss pattern kind: %s (%s)" % [String(kind), pattern])


func _execute_boss_identity_event(event: Dictionary) -> void:
	match StringName(event.get("kind", &"")):
		&"crossing_weave":
			_append_boss_crossing_weave(event)
		&"radial_volley":
			if not boss_runtime.schedule_radial_volley(event):
				push_error("Stage 8 radial-volley queue exceeded its fixed capacity")
		&"compression":
			_append_boss_compression(event)
		_:
			push_error("Unsupported boss identity event: %s" % String(event.get("kind", &"")))


func _append_boss_compression(event: Dictionary) -> void:
	var pattern := String(event["pattern"])
	var primary_axis := Vector2.RIGHT
	if pattern in ["compression_shift", "compression_reverse"]:
		primary_axis = Vector2.LEFT
	var shift := 0.0
	if pattern == "compression_shift":
		shift = LateBossMechanics.COMPRESSION_MAX_SHIFT
	elif pattern == "compression_reverse":
		shift = -LateBossMechanics.COMPRESSION_MAX_SHIFT
	_append_boss_compression_pass(event, primary_axis, shift, 0.0, "primary")
	if pattern == "compression_pair":
		_append_boss_compression_pass(
			event,
			-primary_axis,
			shift,
			LateBossMechanics.COMPRESSION_PAIR_DELAY,
			"paired"
		)


func _append_boss_compression_pass(
	event: Dictionary,
	inward_axis: Vector2,
	gap_offset: float,
	warning_offset: float,
	pass_id: String
) -> void:
	var visible := _visible_world_rect(0.0)
	inward_axis = (
		Vector2(signf(inward_axis.x), 0.0)
		if absf(inward_axis.x) >= absf(inward_axis.y)
		else Vector2(0.0, signf(inward_axis.y))
	)
	if inward_axis.is_zero_approx():
		inward_axis = Vector2.RIGHT
	var horizontal_entry := absf(inward_axis.x) > absf(inward_axis.y)
	var tangent := inward_axis.rotated(PI * 0.5)
	var edge_center := visible.get_center()
	if horizontal_entry:
		edge_center.x = (
			visible.position.x - LateBossMechanics.COMPRESSION_DEPTH * 0.5
			if inward_axis.x > 0.0
			else visible.end.x + LateBossMechanics.COMPRESSION_DEPTH * 0.5
		)
	else:
		edge_center.y = (
			visible.position.y - LateBossMechanics.COMPRESSION_DEPTH * 0.5
			if inward_axis.y > 0.0
			else visible.end.y + LateBossMechanics.COMPRESSION_DEPTH * 0.5
		)
	var span := visible.size.y if horizontal_entry else visible.size.x
	var gap_center := edge_center + tangent * clampf(
		gap_offset,
		-LateBossMechanics.COMPRESSION_MAX_SHIFT,
		LateBossMechanics.COMPRESSION_MAX_SHIFT
	)
	var gap_half := LateBossMechanics.COMPRESSION_GAP * 0.5
	var boss_owned := StringName(event.get("owner_kind", &"boss_actor")) == &"boss_actor"
	var motion_speed := (
		LateBossMechanics.compression_wall_speed()
		if boss_owned else LateBossMechanics.COMPRESSION_WALL_BASE_SPEED
	)
	var wall_damage := (
		LateBossMechanics.compression_wall_damage(float(event["damage"]))
		if boss_owned else float(event["damage"])
	)
	for segment_index in [-1, 1]:
		var segment_from := gap_center - tangent * span * 0.5 if segment_index < 0 else gap_center + tangent * gap_half
		var segment_to := gap_center - tangent * gap_half if segment_index < 0 else gap_center + tangent * span * 0.5
		denied_zones.append({
			"id":"%s_%s_segment_%d" % [String(event["id"]), pass_id, segment_index],
			"shape":&"corridor",
			"from":segment_from,
			"to":segment_to,
			"width":LateBossMechanics.COMPRESSION_DEPTH,
			"motion":inward_axis.normalized() * motion_speed,
			"warning":LateBossMechanics.COMPRESSION_EDGE_CUE_SECONDS + warning_offset,
			"warning_total":LateBossMechanics.COMPRESSION_EDGE_CUE_SECONDS + warning_offset,
			"duration":maxf(1.2, float(event["duration"])),
			"tick":0.0,
			"damage":wall_damage,
			"source":String(event["pattern"]),
			"owner_kind":StringName(event.get("owner_kind", &"boss_actor")),
			"affinity":StringName(event["affinity"]),
			"commit_mode":StringName(event.get("commit_mode", &"autonomous")),
			"final_damage":true,
			"single_hit":true,
			"hit_committed":false,
			"safe_gap":LateBossMechanics.COMPRESSION_GAP,
			"compression_slab":true,
			"edge_axis":inward_axis,
			"edge_marker_seconds":LateBossMechanics.COMPRESSION_EDGE_CUE_SECONDS,
			"direct_boss_id":String(event.get("direct_boss_id", "")),
		})


func _spawn_boss_long_banks(event: Dictionary) -> void:
	var origin := Vector2(event["origin"])
	var axis := (Vector2(event["target"]) - origin).normalized()
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	if not boss_runtime.schedule_distance_growth_pairs({
		"origin":origin,
		"axis":axis,
		"damage":float(event["damage"]),
		"pattern":String(event["pattern"]),
		"affinity":StringName(event["affinity"]),
	}):
		push_error("Stage 6 distance-growth pair queue was still occupied")
		return
	boss_runtime.advance_pending_attacks(0.0, self)


func _fire_distance_growth_pair(pair: Dictionary) -> void:
	var axis := Vector2(pair.get("axis", Vector2.RIGHT)).normalized()
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	var tangent := axis.rotated(PI * 0.5)
	var origin := Vector2(pair.get("origin", Vector2.ZERO))
	for side in [-1.0, 1.0]:
		_spawn_hostile_projectile(
			origin
				+ tangent * float(side) * DISTANCE_GROWTH_LATERAL_OFFSET
				+ axis * DISTANCE_GROWTH_FORWARD_OFFSET,
			axis,
			float(pair.get("damage", 18.0)),
			520.0,
			String(pair.get("pattern", "long_bank_barrage")),
			StringName(pair.get("affinity", &"kinetic")),
			true,
			false,
			AttackContract.THREAT_BOSS,
			ProjectileState.DISTANCE_GROWTH_GROWTH_KIND
		)


func _append_boss_crossing_weave(event: Dictionary) -> void:
	var origin := Vector2(event["origin"])
	var axis := (Vector2(event["target"]) - origin).normalized()
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	var reverse := String(event["pattern"]) == "crossing_weave_b"
	if reverse:
		axis = -axis
	_append_boss_weave_pass(event, axis, 0.0, 120.0, "primary")
	_append_boss_weave_pass(event, axis.rotated(PI * 0.5), 0.65, -120.0, "orthogonal")


func _append_boss_weave_pass(
	event: Dictionary,
	axis: Vector2,
	warning_offset: float,
	gap_offset: float,
	pass_id: String
) -> void:
	var origin := Vector2(event["origin"])
	var tangent := axis.rotated(PI * 0.5)
	var half_length := 680.0
	var gap_half_length := 100.0
	for wall_index in [-1, 1]:
		var center := origin + axis * float(wall_index) * 440.0
		var gap_center := center + tangent * gap_offset * float(wall_index)
		for segment_index in [-1, 1]:
			var segment_from := gap_center - tangent * half_length if segment_index < 0 else gap_center + tangent * gap_half_length
			var segment_to := gap_center - tangent * gap_half_length if segment_index < 0 else gap_center + tangent * half_length
			denied_zones.append({
				"id":"%s_%s_wall_%d_segment_%d" % [String(event["id"]), pass_id, wall_index, segment_index],
				"shape":&"corridor",
				"from":segment_from,
				"to":segment_to,
				"width":72.0,
				"motion":axis * (
					-LateBossMechanics.crossing_wall_speed() * float(wall_index)
				),
				"warning":float(event["startup"]) + warning_offset,
				"warning_total":float(event["startup"]) + warning_offset,
				"duration":1.10,
				"tick":0.0,
				"damage":LateBossMechanics.crossing_wall_damage(float(event["damage"])),
				"source":String(event["pattern"]),
				"owner_kind":&"boss_actor",
				"affinity":StringName(event["affinity"]),
				"commit_mode":StringName(event.get("commit_mode", &"autonomous")),
				"final_damage":true,
				"single_hit":true,
				"hit_committed":false,
				"safe_gap":gap_half_length * 2.0,
				"weave_pass":StringName(pass_id),
				"direct_boss_id":String(event.get("direct_boss_id", "")),
			})


func _append_boss_area_zone(event: Dictionary) -> void:
	var warning := AttackContract.warned_startup_seconds(
		float(event["startup"]), &"area"
	)
	denied_zones.append({
		"id":event["id"],
		"shape":&"area",
		"pos":Vector2(event["target"]),
		"radius":float(event["radius"]),
		"warning":warning,
		"warning_total":warning,
		"duration":maxf(0.62, float(event["duration"])),
		"tick":0.0,
		"damage":float(event["damage"]),
		"source":String(event["pattern"]),
		"owner_kind":&"boss_actor",
		"affinity":StringName(event["affinity"]),
		"commit_mode":&"autonomous",
		"final_damage":true,
	})


func _append_boss_lane_zones(event: Dictionary) -> void:
	var origin := Vector2(event["origin"])
	var direction := (Vector2(event["target"]) - origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var tangent := direction.rotated(PI * 0.5)
	var spacing := float(event["lane_spacing"])
	for lane_index in [-1, 1]:
		var lane_origin := origin + tangent * spacing * float(lane_index)
		var lane_end := _runtime_attack_path_end(
			lane_origin,
			direction,
			BossPatterns.BEAM_RANGE,
			float(event["width"]) * 0.5
		)
		_append_boss_corridor_zone(
			event,
			"%s_lane_%d" % [String(event["id"]), lane_index],
			lane_origin,
			lane_end,
			AttackContract.EMITTED_BEAM_FORWARD
		)


func _append_boss_beam_zone(event: Dictionary) -> void:
	var origin := Vector2(event["origin"])
	var direction := (Vector2(event["target"]) - origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var topology := StringName(event.get(
		"beam_topology", AttackContract.BEAM_TOPOLOGY_PARALLEL
	))
	var axes: Array[Vector2] = []
	var emitters: Array[Vector2] = []
	var emission_mode := AttackContract.EMITTED_BEAM_BIDIRECTIONAL
	if topology == AttackContract.BEAM_TOPOLOGY_PARALLEL:
		emission_mode = AttackContract.EMITTED_BEAM_FORWARD
		var tangent := direction.rotated(PI * 0.5)
		for offset in [-54.0, 54.0]:
			axes.append(direction)
			emitters.append(origin + tangent * offset)
	elif topology == AttackContract.BEAM_TOPOLOGY_X:
		axes = [direction.rotated(-PI * 0.25), direction.rotated(PI * 0.25)]
		emitters = [origin, origin]
	else:
		axes = [direction, direction.rotated(PI * 0.5)]
		emitters = [origin, origin]
	for branch_index in axes.size():
		var axis := axes[branch_index]
		var emitter := emitters[branch_index]
		var from := emitter
		if emission_mode == AttackContract.EMITTED_BEAM_BIDIRECTIONAL:
			from = _runtime_attack_path_end(
				emitter, -axis, BossPatterns.BEAM_RANGE, float(event["width"]) * 0.5
			)
		var to := _runtime_attack_path_end(
			emitter, axis, BossPatterns.BEAM_RANGE, float(event["width"]) * 0.5
		)
		_append_boss_corridor_zone(
			event, "%s_branch_%d" % [String(event["id"]), branch_index],
			from, to, emission_mode
		)
		denied_zones[-1]["beam_emitter"] = emitter
		denied_zones[-1]["beam_topology"] = topology


func _append_boss_corridor_zone(
	event: Dictionary,
	zone_id: String,
	from: Vector2,
	to: Vector2,
	emission_mode: StringName = &""
) -> void:
	var active_seconds := maxf(0.62, float(event["duration"]))
	var zone := {
		"id":zone_id,
		"shape":&"corridor",
		"from":from,
		"to":to,
		"width":float(event["width"]),
		"warning":float(event["startup"]),
		"warning_total":float(event["startup"]),
		"duration":active_seconds,
		"tick":0.0,
		"damage":float(event["damage"]),
		"source":String(event["pattern"]),
		"owner_kind":&"boss_actor",
		"affinity":StringName(event["affinity"]),
		"commit_mode":&"autonomous",
		"final_damage":true,
	}
	if not emission_mode.is_empty():
		zone["beam_growth_seconds"] = AttackContract.EMITTED_BEAM_GROWTH_SECONDS
		zone["beam_emission_mode"] = emission_mode
		zone["beam_emitter"] = from
		zone["duration_total"] = active_seconds
		zone["emitter_radius"] = float(event.get("emitter_radius", 0.0))
	denied_zones.append(zone)


func _boss_reposition(boss: EnemyState, delta: float) -> void:
	_boss_combat_move(boss, delta, float(boss.speed))


func _boss_combat_move(boss: EnemyState, delta: float, requested_speed: float) -> void:
	if current_stage_index == 11 and LateBossMechanics.overload_active(boss.pattern_timer):
		requested_speed *= LateBossMechanics.OVERLOAD_MOVE_SCALE
	var position := Vector2(boss.pos)
	var to_player := player_position - position
	var distance := maxf(1.0, to_player.length())
	var direction_to_player := to_player / distance
	var direction := pursuit_field.direction_at(position, float(boss.radius))
	var has_line_of_sight := _runtime_has_line_of_sight(position, player_position, float(boss.radius) * 0.4)
	if has_line_of_sight:
		if distance > 240.0:
			direction = direction_to_player
		elif distance < 140.0:
			direction = -direction_to_player
		else:
			var strafe_sign := -1.0 if int(boss.pattern_index) % 2 == 0 else 1.0
			direction = direction_to_player.rotated(strafe_sign * PI * 0.5)
	elif direction.is_zero_approx():
		direction = direction_to_player
	boss.pos = _move_actor(
		position,
		direction * requested_speed * StatusRuntime.speed_multiplier(boss) * delta,
		float(boss.radius),
		false
	)
	boss.velocity = (Vector2(boss.pos) - position) / maxf(delta, 0.0001)


func _refresh_late_boss_mechanic_state(boss: EnemyState) -> void:
	boss.mechanic_cue_active = false
	boss.mechanic_inner_radius = 0.0
	boss.mechanic_outer_radius = 0.0
	match current_stage_index:
		8:
			boss.mechanic_state = &"compression"
		9:
			# Stage 10 reflection is a shared segmented defense; its state and cue
			# are published by VehicleBossShieldRuntime instead of this overlay.
			boss.mechanic_state = &""
		10:
			boss.mechanic_state = &"resonance_range"
			boss.mechanic_outer_radius = LateBossMechanics.resonance_max_distance()
		11:
			boss.mechanic_state = &"overload_active" if LateBossMechanics.overload_active(boss.pattern_timer) else &"overload_cooldown"
		_:
			boss.mechanic_state = &""


func _begin_boss_shield_phase(boss: EnemyState, next_phase: int) -> void:
	boss.boss_phase = clampi(next_phase, 1, 3)
	boss.phase = &"boss_read"
	boss.phase_time = 0.90
	boss.pattern = &"phase_transition" if boss.boss_phase > 1 else &"system_wake"
	boss.pattern_index = 0
	boss.attack_telegraphs.clear()
	boss_shield_runtime.begin_phase(boss.boss_phase)
	boss.boss_shield_state = boss_shield_runtime.state()
	_show_pending_boss_state_hint()
	if boss.boss_phase > 1:
		boss_phase_two_announced = true
		_play_sound(&"boss", 0.78)


func _spawn_boss_phase_adds(
	boss: EnemyState,
	roles: Array,
	tactic_id: StringName,
	squad_id_override: String = ""
) -> void:
	var live_before := _live_boss_add_count()
	var available := maxi(
		0,
		BossPhaseCatalog.MAX_LIVE_ADDS - live_before
	)
	var spawn_count := mini(available, roles.size())
	var spawned := 0
	var squad_id := (
		squad_id_override
		if not squad_id_override.is_empty()
		else "boss_wave_p%d" % boss.boss_phase
	)
	var emitter_indices: Array[int] = []
	var pack_family: StringName = &"pursuer"
	if spawn_count > 0:
		pack_family = StringName(
			EnemyArchetypes.definition(StringName(roles[0])).get(
				"family", &"pursuer"
			)
		)
	var pack_trait := FamilyTraits.trait_for_pack(
		pack_family,
		current_stage_index,
		boss.boss_phase * BossPhaseCatalog.MAX_LIVE_ADDS
	)
	for role_index in spawn_count:
		var role_definition := EnemyArchetypes.definition(StringName(roles[role_index]))
		if StringName(role_definition.get("family", &"")) == &"emitter":
			emitter_indices.append(role_index)
	var defender_escort_ids := {}
	var next_emitter := 0
	for role_index in spawn_count:
		var role_definition := EnemyArchetypes.definition(StringName(roles[role_index]))
		if (
			StringName(role_definition.get("family", &"")) == &"defender"
			and next_emitter < emitter_indices.size()
		):
			defender_escort_ids[role_index] = "%s_%02d" % [
				squad_id, emitter_indices[next_emitter]
			]
			next_emitter += 1
	for index in spawn_count:
		var role_id := StringName(roles[index])
		var role_definition := EnemyArchetypes.definition(role_id)
		var member_family := StringName(role_definition.get("family", &""))
		var member_tier := int(role_definition.get("tier", 0))
		var member_trait := pack_trait if member_family == pack_family else &""
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
			"role":role_id,
			"pos":position,
			"zone":"boss_wave",
			"active":true,
			"summoned":true,
			"group_id":squad_id,
			"squad_id":squad_id,
			"squad_leader":index == 0,
			"formation_slot":index,
			"formation_size":spawn_count,
			"family":member_family,
			"tier":member_tier,
			"family_trait":member_trait,
			"pack_family":pack_family,
			"pack_trait":pack_trait,
			"escort_target_id":String(defender_escort_ids.get(index, "")),
			"collective_tactic_id":tactic_id,
			"collective_beat_kind":&"power_test",
		})
		if add != null and _append_enemy(add):
			spawned += 1
	boss_shield_runtime.note_adds_spawned(
		spawned,
		live_before + spawned
	)


func _live_boss_add_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.alive and enemy.active and _is_boss_owned_enemy(enemy):
			count += 1
	return count


func _show_pending_boss_state_hint() -> void:
	var hint_key := boss_shield_runtime.take_state_entry_hint()
	if hint_key != "BOSS_SHIELD_DOWN_HINT":
		return
	_ui.notify(tr(hint_key), 2.6, Art.SYSTEM, 2, &"boss_shield_down")


func _on_boss_direct_attack_complete(boss: EnemyState) -> void:
	if boss == null or not boss.alive:
		return
	boss.boss_attack_damage_multiplier = 1.0


func _complete_stage(
	completion_kind: StringName = StageTransitionRuntime.COMPLETION_AFTER_BOSS
) -> void:
	if stage_complete:
		return
	var transition_receipt := stage_transition_runtime.begin(
		current_stage_index,
		StageCatalog.STAGE_IDS.size(),
		completion_kind,
		_physics_serial
	)
	if not bool(transition_receipt.get("accepted", false)):
		push_error("Stage transition rejected a completed stage receipt")
		return
	var diagnostics_active := _session_diagnostics.is_active()
	var teardown_started := Time.get_ticks_usec() if diagnostics_active else 0
	stage_complete = true
	_session_diagnostics.emit_event("stage_ended", {
		"stage_id":current_stage_id,
		"stage_index":current_stage_index,
	})
	encounter_runtime.stop_boss_maintenance()
	encounter_runtime.stop_spawning()
	_retire_boss_owned_enemies()
	projectile_store.retire_boss_hostiles()
	_retire_denied_zones_by_owner(&"boss_actor")
	if diagnostics_active:
		_session_diagnostics.emit_event("stage_transition_boss_teardown", {
			"elapsed_ms":float(Time.get_ticks_usec() - teardown_started) / 1000.0,
			"stage_index":current_stage_index,
			"has_next_stage":bool(transition_receipt.get("has_next_stage", false)),
			"completion_kind":completion_kind,
		})


func _advance_stage_transition() -> void:
	if not stage_transition_runtime.active():
		return
	# XP collection can open a card modal earlier in this physics tick. Keep the
	# transition command parked until that reward transaction is resolved so a
	# continuation cannot hide the modal and leave the reward owner busy forever.
	if mode != RunMode.PLAYING:
		return
	var receipt := stage_transition_runtime.advance(_physics_serial)
	if receipt.is_empty() or not StageTransitionRuntime.valid_command(receipt):
		return
	var command := StringName(receipt["command"])
	if command == &"defeat_flush_complete":
		return
	var diagnostics_active := _session_diagnostics.is_active()
	var started_usec := Time.get_ticks_usec() if diagnostics_active else 0
	match command:
		&"capture_report":
			_freeze_completed_stage_report(bool(receipt["has_next_stage"]))
		&"prepare_continuation":
			_prepare_next_stage_continuation(int(receipt["next_stage_index"]))
		&"configure_world":
			_configure_next_stage_world()
		&"finalize_continuation":
			_finalize_next_stage_continuation()
		&"build_final_result":
			persistent_clear_count += 1
			persistent_relay_module = true
			_save_persistence()
			_pending_final_result_snapshot = _build_final_result_snapshot()
		&"show_final_result":
			_present_final_result(_pending_final_result_snapshot)
	if diagnostics_active:
		_session_diagnostics.emit_event("stage_transition_step", {
			"step":command,
			"elapsed_ms":float(Time.get_ticks_usec() - started_usec) / 1000.0,
			"stage_index":current_stage_index,
		})


func _freeze_completed_stage_report(has_next_stage: bool) -> void:
	_pending_stage_report = StageReportBuilder.build(
		stage_telemetry.freeze_stage(),
		_stage_report_context(has_next_stage)
	)
	completed_stage_reports.append(_pending_stage_report.duplicate(true))


func _retire_boss_owned_enemies() -> void:
	for enemy in enemies:
		if not enemy.alive or not _is_boss_owned_enemy(enemy):
			continue
		_release_enemy_engagement(enemy)
		collective_tactics.unregister_enemy(enemy.id, enemy.squad_id)
		enemy.alive = false
		enemy.active = false
		enemy_grid.update_actor(enemy)
		enemy_store.queue_defeat(enemy)
	_enemy_frame_aggregate_valid = false


func _is_boss_owned_enemy(enemy: EnemyState) -> bool:
	return (
		enemy.role == &"boss"
		or enemy.zone in ["boss_wave", "boss_system"]
		or enemy.carrier_id == "boss_actor"
	)


func _retire_denied_zones_by_owner(owner_kind: StringName) -> void:
	for index in range(denied_zones.size() - 1, -1, -1):
		if StringName(denied_zones[index].get("owner_kind", &"")) == owner_kind:
			denied_zones.remove_at(index)


func _stage_report_context(has_next_stage: bool) -> Dictionary:
	var profile := StageCatalog.profile(current_stage_id)
	var build_rows := StageReportBuilder.build_rows(_build_snapshot())
	var encounter_snapshot := encounter_runtime.debug_snapshot()
	return {
		"number":int(profile["number"]),
		"title_key":String(profile["title_key"]),
		"has_boss":bool(profile.get("has_boss", false)),
		"has_next_stage":has_next_stage,
		"run_time_seconds":maxf(0.0, active_run_elapsed_seconds),
		"hull":player_health,
		"max_hull":_player_max_health(),
		"build_rows":build_rows,
		"pacing":{
			"active_seconds":maxf(0.0, active_run_elapsed_seconds - stage_started_at_active_run_seconds),
			"visible_gap_count":_diagnostic_visible_gap_event_count,
			"first_attack_preparation_seconds":encounter_runtime.first_attack_preparation_time(),
		},
		"diagnostics":_session_diagnostics.summary(),
		"spawn_composition":{
			"emitted_packs":Array(
				encounter_snapshot.get("stage_emitted_packs", [])
			).duplicate(true),
			"invariant_failures":Array(
				encounter_snapshot.get("composition_invariant_failures", [])
			).duplicate(),
			"run_ordinary_defeats":int(
				encounter_snapshot.get("run_ordinary_defeats", 0)
			),
			"bridge_admitted":bool(
				encounter_snapshot.get("onboarding_bridge_admitted", false)
			),
		},
	}


func _continue_stage_report() -> void:
	if mode == RunMode.FAILURE_REPORT:
		_return_to_deployment()


func _prepare_next_stage_continuation(next_stage_index: int) -> void:
	if (
		next_stage_index != current_stage_index + 1
		or next_stage_index < 0
		or next_stage_index >= StageCatalog.STAGE_IDS.size()
	):
		return
	var next_stage_id: StringName = StageCatalog.STAGE_IDS[next_stage_index]
	if _active_tactical_layout == null:
		push_error("Cannot advance the combat cycle without an active field layout")
		return
	# A boss cycle is a combat-profile boundary, not a physical field boundary.
	# Keep this guard reference so the ordered transition can reject incomplete
	# preparation without selecting or applying another tactical child.
	_pending_continuation_layout = _active_tactical_layout
	_pending_continuation_stage_index = next_stage_index
	_pending_continuation_stage_id = next_stage_id


func _configure_next_stage_world() -> void:
	if _pending_continuation_layout == null:
		return
	# Only future combat admissions advance. Terrain, facilities, pickups,
	# exploration, blockers, pursuit geometry, camera limits, and the active
	# tactical layout remain the same objects for the complete run.
	current_stage_index = _pending_continuation_stage_index
	current_stage_id = _pending_continuation_stage_id


func _finalize_next_stage_continuation() -> void:
	if _pending_continuation_layout == null:
		return
	stage_telemetry.reset_stage()
	var continuation_slots := maxi(0, 6 - _ordinary_active_count())
	encounter_runtime.configure(
		current_stage_id,
		_continuation_packets(current_stage_id, continuation_slots),
		selected_run_difficulty,
		_active_tactical_layout.ordinary_spawn_anchors,
		_active_tactical_layout.encounter_seed,
		_active_tactical_layout.geometry_snapshot,
		current_stage_index
	)
	stage_flow.configure(
		current_stage_index,
		RunDifficulty.scaled_quota(
			StageCatalog.quota(current_stage_id),
			selected_run_difficulty
		),
		StageCatalog.has_boss(current_stage_id)
	)
	boss_started = false
	boss_shield_runtime.configure(current_stage_id)
	boss_death_runtime.reset()
	_dying_boss_id = ""
	_pending_boss_barrage_rows.clear()
	boss_runtime.clear_pending_attacks()
	_boss_barrage_hit_lock_remaining = 0.0
	boss_phase_two_announced = false
	boss_arrival_position = Vector2.ZERO
	stage_complete = false
	stage_started_at_active_run_seconds = active_run_elapsed_seconds
	mode = RunMode.PLAYING
	_session_diagnostics.emit_event("stage_started", {
		"stage_id":current_stage_id,
		"stage_index":current_stage_index,
	})
	_hud_presenter.reset()
	_ui.show_gameplay()
	_set_mouse_for_mode()
	_pending_continuation_layout = null
	_pending_continuation_stage_index = -1
	_pending_continuation_stage_id = &""


func _ordinary_active_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap and not _is_boss_owned_enemy(enemy):
			count += 1
	return count


func _continuation_packets(stage_id: StringName, opening_slots: int = 6) -> Array[Dictionary]:
	var authored := StageCatalog.packets(stage_id)
	var result: Array[Dictionary] = []
	if authored.is_empty():
		return result
	var opening: Dictionary = authored[0].duplicate(true)
	var opening_roles: Array = Array(opening["squads"])[0]
	var opening_pack := (
		Dictionary(Array(opening.get("packs", []))[0]).duplicate(true)
		if not Array(opening.get("packs", [])).is_empty()
		else {}
	)
	var admitted_roles: Array = opening_roles.slice(0, clampi(opening_slots, 0, opening_roles.size()))
	var reserve_roles: Array = opening_roles.slice(admitted_roles.size())
	if not admitted_roles.is_empty():
		opening["squads"] = [admitted_roles]
		if not opening_pack.is_empty():
			var admitted_pack := opening_pack.duplicate(true)
			admitted_pack["pack_size"] = admitted_roles.size()
			opening["packs"] = [admitted_pack]
		opening["trigger"] = {"kind":&"time", "at":CONTINUATION_FIRST_CUE_AT}
		opening["cue_lead"] = CONTINUATION_FIRST_SPAWN_AT - CONTINUATION_FIRST_CUE_AT
		result.append(opening)
	if not reserve_roles.is_empty():
		var reserve_pack := opening_pack.duplicate(true)
		reserve_pack["pack_size"] = reserve_roles.size()
		result.append({"id":"%s_continuation_reserve" % stage_id, "beat":1, "trigger":{"kind":&"time", "at":4.0}, "squads":[reserve_roles], "packs":[reserve_pack], "spawn_composition":true, "unit_spacing":0.16, "cue_lead":0.9, "engagement_patterns":[&"none"], "zone":"field", "leash":Rect2(Rules.world_rect(stage_id))})
	var authored_first_time := float(authored[1]["trigger"]["at"]) if authored.size() > 1 else 4.0
	for packet_index in range(1, authored.size()):
		var packet := authored[packet_index].duplicate(true)
		var trigger := Dictionary(packet["trigger"]).duplicate(true)
		trigger["at"] = (
			CONTINUATION_FIRST_CUE_AT
			+ float(trigger["at"])
			- authored_first_time
		)
		packet["trigger"] = trigger
		if packet_index == 1:
			packet["cue_lead"] = (
				CONTINUATION_FIRST_SPAWN_AT
				- CONTINUATION_FIRST_CUE_AT
			)
		result.append(packet)
	return result


func _show_final_result() -> void:
	_present_final_result(_build_final_result_snapshot())


func _build_final_result_snapshot() -> Dictionary:
	var build_snapshot := _build_snapshot()
	var active_weapon_snapshot := active_weapon_runtime.snapshot(
		run_build, 1.5 if persistent_relay_module else 0.0
	)
	var active_weapon_definition = active_weapon_runtime.catalog.get_definition(
		StringName(active_weapon_snapshot.get("weapon_id", &""))
	)
	var secondary_titles: Array[String] = []
	for secondary in secondary_runtime.equipped_families(run_build):
		secondary_titles.append(String(secondary.get("name_key", "")))
	return RunResultBuilder.build(completed_stage_reports, {
		"active_run_elapsed_seconds":active_run_elapsed_seconds,
		"hull":player_health,
		"max_hull":_player_max_health(),
		"health_ratio":player_health / _player_max_health(),
		"primary_hits":stats_primary_hits,
		"dash_uses":stats_dash_uses,
		"installations":stats_installations,
		"build_snapshot":build_snapshot,
		"build_rows":StageReportBuilder.build_rows(build_snapshot),
		"loadout":{
			"primary_title_key":"PRIMARY_PULSE_CANNON",
			"secondary_title_keys":secondary_titles,
			"active_title_key":(
				String(active_weapon_definition.name_key)
				if active_weapon_definition != null
				else ""
			),
		},
	})


func _present_final_result(result_snapshot: Dictionary) -> void:
	if result_snapshot.is_empty():
		push_error("Final Result cannot open without a complete run snapshot")
		return
	mode = RunMode.RESULT
	_ui.show_result(result_snapshot)
	_session_diagnostics.emit_event("result_shown", {
		"stage_count":completed_stage_reports.size(),
		"total_defeats":int(result_snapshot.get("total_defeats", 0)),
	})
	_session_diagnostics.emit_event("run_completed", {
		"stage_count":completed_stage_reports.size(),
		"active_seconds":active_run_elapsed_seconds,
	})
	_finish_session_diagnostics("run_completed")
	_play_sound(&"card", 0.72)
	_set_mouse_for_mode()
	_pending_final_result_snapshot.clear()


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
	var snapshot := _build_fast_hud_snapshot()
	if include_world_channels:
		snapshot["minimap"] = _minimap_snapshot(true)
		snapshot["threat_radar"] = _threat_radar_snapshot()
	if include_guidebook:
		var build_snapshot := _build_snapshot()
		snapshot["build_snapshot"] = build_snapshot
		snapshot["guidebook"] = _guidebook_snapshot(build_snapshot)
	return snapshot


func _build_fast_hud_snapshot() -> Dictionary:
	return _fill_fast_hud_snapshot({})


func _runtime_fast_hud_snapshot() -> Dictionary:
	return _fill_fast_hud_snapshot(_runtime_fast_hud_frame)


func _fill_fast_hud_snapshot(snapshot: Dictionary) -> Dictionary:
	snapshot.clear()
	var stage_profile := StageCatalog.profile(current_stage_id)
	snapshot["health"] = player_health
	snapshot["max_health"] = _player_max_health()
	snapshot["level"] = experience_runtime.run_level
	snapshot["experience"] = experience_runtime.experience
	snapshot["experience_required"] = experience_runtime.required_experience()
	snapshot["experience_complete"] = experience_runtime.progression_complete
	snapshot["reduced_motion"] = _reduced_motion_enabled()
	snapshot["stage_number"] = int(stage_profile["number"])
	snapshot["stage_total"] = StageCatalog.STAGE_IDS.size()
	snapshot["stage_quota_remaining"] = maxi(0, stage_flow.quota - stage_flow.defeats)
	snapshot["cumulative_defeated"] = stats_enemies_defeated
	snapshot["dash_available"] = player_dash_cooldown <= 0.0
	snapshot["dash_remaining"] = maxf(0.0, player_dash_cooldown)
	var active_weapon := active_weapon_runtime.snapshot(
		run_build, 1.5 if persistent_relay_module else 0.0
	)
	snapshot["skill_owned"] = not StringName(active_weapon["weapon_id"]).is_empty()
	snapshot["skill_available"] = bool(active_weapon["available"])
	snapshot["skill_remaining"] = float(active_weapon["remaining"])
	snapshot["active_weapon_id"] = StringName(active_weapon["weapon_id"])
	var combo := primary_combo_runtime.snapshot()
	var max_hull := maxf(1.0, _player_max_health())
	snapshot["conditional_statuses"] = ConditionalStatusSnapshot.build(
		run_build.level_of(&"overflow_barrier"),
		player_barrier_strength,
		player_barrier_timer,
		run_build.level_of(&"dash_overdrive"),
		dash_upgrade_runtime.overdrive_remaining,
		run_build.level_of(&"braced_fire"),
		maxi(int(combo["braced_active_segments"]), int(combo["braced_segments"])),
		float(combo["braced_seconds"]),
		run_build.level_of(&"hit_chain"),
		int(combo["hit_stacks"]),
		run_build.level_of(&"miss_compensation"),
		int(combo["miss_stacks"]),
		run_build.level_of(&"last_stand_amplifier"),
		OutgoingDamagePolicy.crisis_bonus(
			run_build.level_of(&"last_stand_amplifier"),
			player_health / max_hull
		)
	)
	return snapshot


func _guidebook_snapshot(build_snapshot: Dictionary = {}) -> Dictionary:
	var store := get_node_or_null("/root/VehicleGuidebookStore")
	if store == null:
		return {}
	if build_snapshot.is_empty():
		build_snapshot = _build_snapshot()
	var guide_context := {}
	if (
		mode in [RunMode.PLAYING, RunMode.UPGRADE]
		or (mode == RunMode.PAUSED and mode_before_pause != RunMode.DEPLOYMENT)
	):
		guide_context["active_stage_index"] = current_stage_index
	return store.snapshot(build_snapshot, guide_context)


func _build_snapshot() -> Dictionary:
	var experience := experience_runtime.snapshot()
	var combo := primary_combo_runtime.snapshot()
	var max_hull := maxf(1.0, _player_max_health())
	var conditional_statuses := ConditionalStatusSnapshot.build(
		run_build.level_of(&"overflow_barrier"), player_barrier_strength, player_barrier_timer,
		run_build.level_of(&"dash_overdrive"), dash_upgrade_runtime.overdrive_remaining,
		run_build.level_of(&"braced_fire"),
		maxi(int(combo["braced_active_segments"]), int(combo["braced_segments"])),
		float(combo["braced_seconds"]), run_build.level_of(&"hit_chain"),
		int(combo["hit_stacks"]), run_build.level_of(&"miss_compensation"),
		int(combo["miss_stacks"]), run_build.level_of(&"last_stand_amplifier"),
		OutgoingDamagePolicy.crisis_bonus(
			run_build.level_of(&"last_stand_amplifier"), player_health / max_hull
		)
	)
	var active_weapon := active_weapon_runtime.snapshot(
		run_build, 1.5 if persistent_relay_module else 0.0
	)
	var effective_stats: Array[Dictionary] = [
		{"id":&"hull", "label_key":"SHIP_STAT_HULL", "value":_player_max_health(), "decimals":0, "unit_key":"SHIP_UNIT_HP"},
		{"id":&"speed", "label_key":"SHIP_STAT_SPEED", "value":_player_move_speed(), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
		{"id":&"primary_damage", "label_key":"SHIP_STAT_PRIMARY_DAMAGE", "value":18.0 * PrimaryUpgradeRules.piercing_damage_multiplier(run_build.level_of(&"piercing_rounds")) * run_build.fallback_primary_damage_multiplier(), "decimals":1, "unit_key":"SHIP_UNIT_DAMAGE"},
		{"id":&"fire_rate", "label_key":"SHIP_STAT_FIRE_RATE", "value":1.0 / PrimaryWeapon.BASE_INTERVAL, "decimals":2, "unit_key":"SHIP_UNIT_PER_SECOND"},
		{"id":&"projectile_speed", "label_key":"SHIP_STAT_PROJECTILE_SPEED", "value":run_build.stat(&"primary_projectile_speed", PRIMARY_PROJECTILE_SPEED), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
		{"id":&"dash_cooldown", "label_key":"SHIP_STAT_DASH_COOLDOWN", "value":_dash_cooldown_max(), "decimals":2, "unit_key":"SHIP_UNIT_SECONDS"},
		{"id":&"active_range", "label_key":"SHIP_STAT_ACTIVE_RANGE", "value":float(active_weapon["size"]), "decimals":0, "unit_key":"SHIP_UNIT_PX"},
		{"id":&"active_duration", "label_key":"SHIP_STAT_ACTIVE_DURATION", "value":float(active_weapon["duration"]), "decimals":2, "unit_key":"SHIP_UNIT_SECONDS"},
		{"id":&"active_cooldown", "label_key":"SHIP_STAT_ACTIVE_COOLDOWN", "value":float(active_weapon["cooldown_max"]), "decimals":2, "unit_key":"SHIP_UNIT_SECONDS"},
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
			"experience_complete":bool(experience["complete"]),
			"fallback_ranks":run_build.fallback_snapshot(),
			"conditional_statuses":conditional_statuses,
		}
	)


func _discover_guide(entry_id: StringName) -> void:
	if entry_id.is_empty():
		return
	var store := get_node_or_null("/root/VehicleGuidebookStore")
	if store != null and bool(store.discover(entry_id)):
		_hud_presenter.mark_guidebook_dirty()


func _minimap_snapshot(include_static_geometry: bool = true) -> Dictionary:
	var visited: Array[Vector2i] = []
	for cell in visited_cells:
		visited.append(Vector2i(cell))
	var markers: Array[Dictionary] = []
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		markers.append({
			"kind":&"boss",
			"position":boss_arrival_position,
			"discovered":true,
		})
	var stage_boss := _find_enemy_by_id("boss_actor")
	if stage_boss != null and stage_boss.alive:
		markers.append({
			"kind":&"boss",
			"position":stage_boss.pos,
			"discovered":true,
		})
	for enemy in enemies:
		if not enemy.alive or not enemy.active or enemy.role == &"boss":
			continue
		markers.append({
			"kind":_minimap_role_for_enemy(enemy),
			"position":enemy.pos,
			"discovered":true,
		})
	for pickup in pickups:
		if bool(pickup["active"]) and bool(pickup.get("published", true)):
			markers.append({
				"kind":&"field_pickup",
				"position":Vector2(pickup["pos"]),
				"discovered":true,
			})
	mystery_device_runtime.fill_device_snapshot(
		_mystery_device_snapshot_buffer
	)
	for device in _mystery_device_snapshot_buffer:
		if (
			StringName(device["state"]) in [&"dormant", &"active"]
			and (StringName(device["state"]) != &"dormant" or bool(device.get("published", true)))
		):
			markers.append({
				"kind":&"mystery_device",
				"position":Vector2(device["position"]),
				"discovered":true,
				"tint":Art.TEXT_MUTED,
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
		_append_minimap_static_geometry(snapshot)
	return snapshot


func _runtime_minimap_snapshot(
	include_static_geometry: bool = true
) -> Dictionary:
	_initialize_hud_staging()
	_runtime_minimap_frame_index = (
		(_runtime_minimap_frame_index + 1) % MINIMAP_FRAME_COUNT
	)
	var frame_index := _runtime_minimap_frame_index
	var snapshot: Dictionary = _runtime_minimap_frames[frame_index]
	var visited: Array[Vector2i] = _runtime_minimap_visited_buffers[frame_index]
	var markers: Array[Dictionary] = _runtime_minimap_marker_buffers[frame_index]
	visited.clear()
	markers.clear()
	for cell in visited_cells:
		visited.append(Vector2i(cell))
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		_append_runtime_minimap_marker(
			frame_index, markers, &"boss", boss_arrival_position
		)
	var stage_boss := _find_enemy_by_id("boss_actor")
	if stage_boss != null and stage_boss.alive:
		_append_runtime_minimap_marker(
			frame_index, markers, &"boss", stage_boss.pos
		)
	for enemy in enemies:
		if not enemy.alive or not enemy.active or enemy.role == &"boss":
			continue
		_append_runtime_minimap_marker(
			frame_index, markers, _minimap_role_for_enemy(enemy), enemy.pos
		)
	for pickup in pickups:
		if bool(pickup["active"]) and bool(pickup.get("published", true)):
			_append_runtime_minimap_marker(
				frame_index, markers, &"field_pickup", Vector2(pickup["pos"])
			)
	mystery_device_runtime.fill_device_snapshot(
		_mystery_device_snapshot_buffer
	)
	for device in _mystery_device_snapshot_buffer:
		if (
			StringName(device["state"]) in [&"dormant", &"active"]
			and (StringName(device["state"]) != &"dormant" or bool(device.get("published", true)))
		):
			_append_runtime_minimap_marker(
				frame_index,
				markers,
				&"mystery_device",
				Vector2(device["position"]),
				1.0,
				Art.TEXT_MUTED
			)
	snapshot["player"] = player_position
	snapshot["player_facing"] = player_hull_direction
	snapshot["world_size"] = Rules.world_rect(current_stage_id).size
	for static_key in MINIMAP_STATIC_KEYS:
		snapshot.erase(static_key)
	if include_static_geometry:
		_append_minimap_static_geometry(snapshot)
	return snapshot


func _append_runtime_minimap_marker(
	frame_index: int,
	markers: Array[Dictionary],
	kind: StringName,
	position: Vector2,
	emphasis: float = 1.0,
	tint: Color = Color.TRANSPARENT
) -> void:
	var marker_index := markers.size()
	if marker_index >= MINIMAP_MARKER_CAPACITY:
		return
	var marker := _runtime_minimap_marker_pool[
		frame_index * MINIMAP_MARKER_CAPACITY + marker_index
	]
	marker["kind"] = kind
	marker["position"] = position
	marker["discovered"] = true
	marker["emphasis"] = emphasis
	if tint.a > 0.0:
		marker["tint"] = tint
	else:
		marker.erase("tint")
	markers.append(marker)


func _minimap_role_for_enemy(enemy: EnemyState) -> StringName:
	if enemy.role in MINIMAP_PRIORITY_ENEMY_ROLES:
		return &"priority_enemy"
	return &"mobile_enemy"


func _append_minimap_static_geometry(snapshot: Dictionary) -> void:
	var blocker_polygons: Array = Rules.get_cover_polygons(
		false, current_stage_id
	).duplicate()
	for rect in _runtime_cover_rects():
		blocker_polygons.append(StageGeometry.rect_polygon(rect))
	snapshot["floor_polygons"] = StageCatalog.floor_polygons(current_stage_id)
	snapshot["void_polygons"] = StageCatalog.void_polygons(current_stage_id)
	snapshot["blocker_polygons"] = blocker_polygons


func _combat_presentation_snapshot() -> Dictionary:
	var mystery_devices: Array[Dictionary] = []
	var boss_shield_presentation := boss_shield_runtime.presentation_snapshot()
	return _fill_combat_presentation_snapshot(
		{},
		player_protection_sources.duplicate(),
		secondary_runtime.snapshot(run_build),
		mystery_devices,
		boss_shield_presentation
	)


func _runtime_combat_presentation_snapshot() -> Dictionary:
	secondary_runtime.fill_presentation_snapshot(
		_runtime_secondary_presentation_frame,
		run_build
	)
	boss_shield_runtime.fill_presentation_snapshot(
		_runtime_boss_shield_presentation_frame
	)
	return _fill_combat_presentation_snapshot(
		_runtime_combat_presentation_frame,
		player_protection_sources,
		_runtime_secondary_presentation_frame,
		_mystery_device_snapshot_buffer,
		_runtime_boss_shield_presentation_frame
	)


func _fill_combat_presentation_snapshot(
	snapshot: Dictionary,
	protection_sources: Dictionary,
	secondary: Dictionary,
	mystery_devices: Array[Dictionary],
	boss_shield_presentation: Dictionary
) -> Dictionary:
	var cursor_position := player_position + player_aim_direction * 230.0
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length() > 8.0:
		cursor_position = get_global_mouse_position()
	snapshot.clear()
	snapshot["zones"] = denied_zones
	snapshot["player_position"] = player_position
	snapshot["hull_direction"] = (
		player_dash_direction
		if player_dash_timer > 0.0
		else player_hull_direction
	)
	snapshot["aim_direction"] = player_aim_direction
	snapshot["player_speed"] = player_velocity.length()
	snapshot["dash_active"] = player_dash_timer > 0.0
	snapshot["dash_progress"] = (
		1.0 - clampf(player_dash_timer / DASH_DURATION, 0.0, 1.0)
		if player_dash_timer > 0.0
		else 0.0
	)
	snapshot["dash_direction"] = player_dash_direction
	snapshot["player_hit"] = player_hit_flash > 0.0
	snapshot["player_hit_remaining"] = player_hit_flash
	snapshot["player_barrier_hit_remaining"] = player_barrier_hit_flash
	snapshot["player_invulnerable_remaining"] = player_invulnerable
	snapshot["protection_sources"] = protection_sources
	snapshot["muzzle_flash"] = player_muzzle_flash
	snapshot["barrier_strength"] = player_barrier_strength
	snapshot["reduced_motion"] = _reduced_motion_enabled()
	snapshot["run_time"] = active_run_elapsed_seconds
	snapshot["secondary_visual_tier"] = 0
	snapshot["orbiting_blade_level"] = run_build.level_of(&"orbiting_blades")
	snapshot["secondary"] = secondary
	snapshot["dash_afterburn_trails"] = dash_upgrade_runtime.trails
	snapshot["dash_boost_active"] = dash_upgrade_runtime.overdrive_active()
	snapshot["dash_boost_remaining"] = dash_upgrade_runtime.overdrive_remaining
	snapshot["active_weapon"] = active_weapon_runtime.snapshot(
		run_build, 1.5 if persistent_relay_module else 0.0
	)
	snapshot["map_pickups"] = pickups
	mystery_device_runtime.fill_device_snapshot(mystery_devices)
	snapshot["mystery_devices"] = mystery_devices
	# Renderer may keep the living boss body visible while this receipt fades it;
	# combat truth stays disabled by the death runtime above.
	snapshot["boss_destruction"] = boss_death_runtime.presentation()
	snapshot["dying_boss_id"] = _dying_boss_id
	snapshot["boss_shield"] = boss_shield_presentation
	snapshot["cursor_position"] = cursor_position
	return snapshot


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
	_threat_radar_feed.set_maximum_distance(_runtime_threat_scan_distance)
	_threat_radar_feed.begin_sample(player_position)
	var viewport_size := get_viewport_rect().size
	var safe_viewport := Rect2(Vector2(90.0, 90.0), viewport_size - Vector2(180.0, 220.0))
	var canvas_transform := get_canvas_transform()
	var visible_world := _visible_world_rect(0.0)
	for feature in terrain_runtime.features:
		var feature_position := (
			feature.rect.get_center()
			if feature.rect.has_area()
			else feature.pos
		)
		if safe_viewport.has_point(canvas_transform * feature_position):
			var terrain_entry := StringName({
				&"transit_gate":&"object_transit_gate",
			}.get(feature.kind, &""))
			if terrain_entry != &"":
				_discover_guide(terrain_entry)
	mystery_device_runtime.fill_device_snapshot(
		_mystery_device_snapshot_buffer
	)
	for device in _mystery_device_snapshot_buffer:
		if (
			StringName(device.get("state", &"expired")) in [&"dormant", &"active"]
			and (
				StringName(device.get("state", &"expired")) != &"dormant"
				or bool(device.get("published", true))
			)
			and safe_viewport.has_point(
				canvas_transform * Vector2(device["position"])
			)
		):
			_discover_guide(&"object_mystery_device")
	for cue_index in _ordinary_arrival_cue_count:
		var cue_position := _ordinary_arrival_cue_positions[cue_index]
		if visible_world.has_point(cue_position):
			continue
		var cue_offset := _direction_only_threat_offset(
			cue_position - player_position
		)
		if not cue_offset.is_zero_approx():
			_append_runtime_threat_contact(
				cue_offset,
				CombatCuePolicy.CONTACT_NEARBY_ENEMY,
				0.0
			)
	var diagnostic_visible_threat := false
	var visible_ordinary_threat := false
	var diagnostic_ordinary_commit := false
	for enemy in enemies:
		if not bool(enemy.alive) or not bool(enemy.active):
			continue
		var enemy_screen := canvas_transform * Vector2(enemy.pos)
		if (
			(enemy.counts_active_cap or enemy.role == &"boss")
			and visible_world.has_point(enemy.pos)
		):
			diagnostic_visible_threat = true
		if enemy.counts_active_cap and visible_world.has_point(enemy.pos):
			visible_ordinary_threat = true
		if (
			enemy.counts_active_cap
			and enemy.phase in [&"startup", &"active"]
		):
			diagnostic_ordinary_commit = true
		if safe_viewport.has_point(enemy_screen):
			_discover_guide(GuidebookCatalog.entry_id_for_enemy(enemy.archetype, enemy.role))
			if enemy.family_trait != &"":
				_discover_guide(StringName("object_trait_%s" % String(enemy.family_trait)))
		var offset := Vector2(enemy.pos) - player_position
		var readiness := CombatCuePolicy.unseen_committed_attack_readiness(
			enemy.pos,
			enemy.visual_radius,
			enemy.phase,
			enemy.attack_telegraphs,
			visible_world
		)
		if readiness >= 0.0:
			_append_runtime_threat_contact(
				offset, CombatCuePolicy.CONTACT_INCOMING_ATTACK, readiness
			)
		elif (
			enemy.role != &"boss"
			and CombatCuePolicy.nearby_enemy_is_eligible(
				enemy.pos,
				enemy.visual_radius,
				player_position,
				visible_world,
				_runtime_threat_scan_distance
			)
		):
			_append_runtime_threat_contact(
				offset, CombatCuePolicy.CONTACT_NEARBY_ENEMY, 0.0
			)
	for projectile in hostile_projectiles:
		if projectile.distance_growth_kind != ProjectileState.DISTANCE_GROWTH_GROWTH_KIND:
			continue
		var projectile_offset := projectile.pos - player_position
		if (
			visible_world.grow(projectile.radius).has_point(projectile.pos)
			or projectile_offset.length_squared()
				> _runtime_threat_scan_distance * _runtime_threat_scan_distance
			or projectile.velocity.normalized().dot(-projectile_offset.normalized()) < 0.30
		):
			continue
		_append_runtime_threat_contact(
			projectile_offset,
			CombatCuePolicy.CONTACT_INCOMING_ATTACK,
			projectile.distance_growth_ratio
		)
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		_append_runtime_threat_contact(
			boss_arrival_position - player_position,
			CombatCuePolicy.CONTACT_BOSS_ARRIVAL,
			1.0
		)
	_record_diagnostic_threat_sample(
		diagnostic_visible_threat,
		diagnostic_ordinary_commit
	)
	_visible_ordinary_threat_current = visible_ordinary_threat
	_threat_radar_feed.commit_sample()


func _direction_only_threat_offset(offset: Vector2) -> Vector2:
	var maximum := _runtime_threat_scan_distance - 0.01
	if offset.length_squared() <= maximum * maximum:
		return offset
	return offset.normalized() * maximum


func _append_runtime_threat_contact(
	offset: Vector2,
	kind: StringName,
	readiness: float
) -> void:
	_threat_radar_feed.append_offset(offset, kind, readiness)


func _threat_radar_snapshot() -> Dictionary:
	return _fill_threat_radar_snapshot({})


func _runtime_threat_radar_snapshot() -> Dictionary:
	return _fill_threat_radar_snapshot(_runtime_threat_radar_frame)


func _fill_threat_radar_snapshot(frame: Dictionary) -> Dictionary:
	var sample := _threat_radar_feed.snapshot()
	frame["visible"] = _simulation_active()
	frame["generation"] = int(sample.get("generation", 0))
	frame["sample_origin"] = Vector2(sample.get(
		"sample_origin", player_position
	))
	frame["max_distance"] = float(sample.get(
		"max_distance", THREAT_SCAN_DISTANCE
	))
	frame["sectors"] = sample.get("sectors", [])
	return frame


func _reset_threat_radar_feed() -> void:
	_threat_radar_feed.begin_sample(player_position)
	_threat_radar_feed.commit_sample()


func _draw() -> void:
	_draw_terrain()
	if _debug_collision_overlay:
		_draw_debug_collision_overlay()


func _draw_terrain() -> void:
	var snapshot := terrain_runtime.snapshot()
	for feature in Array(snapshot.get("features", [])):
		var kind := StringName(feature["kind"])
		match kind:
			&"transit_gate":
				var center := Vector2(feature["pos"])
				var progress := clampf(float(feature.get("progress", 0.0)), 0.0, 1.0)
				var cooldown := float(feature.get("cooldown", 0.0))
				_draw_semantic_asset(
					TRANSIT_GATE_ASSET_ID,
					center,
					TerrainRuntime.GATE_RADIUS,
					Color.WHITE
				)
				if progress > 0.0:
					draw_arc(center, TerrainRuntime.GATE_RADIUS - 18.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Art.TEXT_PRIMARY, 10.0)
				if cooldown > 0.0:
					draw_arc(center, 72.0, 0.0, TAU * (1.0 - cooldown / TerrainRuntime.GATE_COOLDOWN), 32, Art.TEXT_MUTED, 10.0)


func debug_transit_gate_visual_contract() -> Dictionary:
	return {
		"asset_id":TRANSIT_GATE_ASSET_ID,
		"asset_radius":TerrainRuntime.GATE_RADIUS,
		"neutral_modulate":Color.WHITE,
		"legacy_ring":false,
		"zero_progress_visible":false,
	}


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


func _enemy_color(role: StringName) -> Color:
	match role:
		&"ordinary_edge_01", &"ordinary_lane_01", &"ordinary_fixed_area_01", &"ordinary_growth_01", &"ordinary_pull_01":
			return Art.CORAL
		&"ordinary_fixed_ranged_01", &"ordinary_fixed_ranged_02", &"ordinary_fixed_beam_01":
			return Art.CORAL_DARK
		&"ordinary_fixed_support_01", &"ordinary_support_02", &"ordinary_support_01":
			return Art.MINT
		&"ordinary_gap_01", &"ordinary_support_03", &"boss":
			return Art.BOSS_MAGENTA
	return Art.CORAL


func _visible_world_rect(margin: float = 0.0) -> Rect2:
	var inverse_canvas := get_canvas_transform().affine_inverse()
	var viewport_size := get_viewport_rect().size
	var top_left := inverse_canvas * Vector2.ZERO
	var bottom_right := inverse_canvas * viewport_size
	return Rect2(top_left, bottom_right - top_left).abs().grow(margin)


func _refresh_visible_world_runtime_ranges() -> void:
	## Compute the enlarged-view thresholds once per physics tick. This keeps
	## visible actors smooth and radar coverage coherent without changing counts.
	var visible_world := _visible_world_rect(0.0)
	var farthest_squared := 0.0
	for corner in [
		visible_world.position,
		Vector2(visible_world.end.x, visible_world.position.y),
		visible_world.end,
		Vector2(visible_world.position.x, visible_world.end.y),
	]:
		farthest_squared = maxf(
			farthest_squared,
			player_position.distance_squared_to(corner)
		)
	var farthest := sqrt(farthest_squared)
	var near_distance := maxf(
		FAR_SIMULATION_DISTANCE,
		farthest + VISIBLE_SIMULATION_MARGIN
	)
	_near_simulation_distance_squared = near_distance * near_distance
	_runtime_threat_scan_distance = maxf(
		THREAT_SCAN_DISTANCE,
		farthest + THREAT_OFFSCREEN_BAND
	)


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
	if _capture_mode:
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


func _fill_slow_tick_receipt_scalars() -> void:
	var simulation_active := _simulation_active()
	_slow_tick_scalars[0] = enemy_store.live_count()
	_slow_tick_scalars[1] = encounter_runtime.pressure_visible_count()
	_slow_tick_scalars[2] = _enemy_update_schedule.ordinary_due.size()
	_slow_tick_scalars[3] = _enemy_update_schedule.critical.size()
	_slow_tick_scalars[4] = posmod(
		_enemy_decision_bucket - 1, ORDINARY_DECISION_BUCKET_COUNT
	)
	_slow_tick_scalars[5] = _simulation_lod_bucket
	_slow_tick_scalars[6] = 1 if pursuit_field.rebuild_active() else 0
	_slow_tick_scalars[7] = pursuit_field.last_processed_cells()
	_slow_tick_scalars[8] = enemy_grid.last_local_overlap_owner_count()
	_slow_tick_scalars[9] = enemy_grid.last_local_overlap_candidate_count()
	_slow_tick_scalars[10] = _slow_tick_spawn_count
	_slow_tick_scalars[11] = _slow_tick_cue_count
	_slow_tick_scalars[12] = projectile_store.player_count()
	_slow_tick_scalars[13] = projectile_store.hostile_count()
	_slow_tick_scalars[14] = effects.size()
	_slow_tick_scalars[15] = 1 if simulation_active else 0
	_slow_tick_scalars[16] = (
		1 if encounter_runtime.pressure_scan_happened() else 0
	)
	_slow_tick_scalars[17] = 1 if simulation_active else 0
	_slow_tick_scalars[18] = 1 if simulation_active else 0
	_slow_tick_scalars[19] = 1 if simulation_active else 0
	_slow_tick_scalars[20] = _slow_tick_anomaly_scan_count


func _performance_accumulate_enemy_section(
	section_name: String,
	started_usec: int
) -> void:
	if not _performance_detail_sample_active or started_usec <= 0:
		return
	_performance_enemy_sections[section_name] = (
		float(_performance_enemy_sections.get(section_name, 0.0))
		+ _elapsed_ms(started_usec)
	)


func _parse_manual_performance_request() -> Dictionary:
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	var request := _manual_performance_request_from_arguments(arguments)
	if request.is_empty():
		return {}
	if not OS.is_debug_build() or OS.has_feature("web"):
		push_error("Manual performance tracing is available only in native debug builds.")
		return {}
	return request


static func _manual_performance_request_from_arguments(arguments: Array) -> Dictionary:
	var output_path := ""
	for argument in arguments:
		if argument.begins_with("--manual-performance-output="):
			output_path = argument.trim_prefix("--manual-performance-output=")
	if output_path.is_empty():
		return {}
	if not ManualPerformanceTrace.is_safe_output_path(output_path):
		push_error("Unsafe manual performance output path: %s" % output_path)
		return {}
	return {"output":output_path}


func _prepare_manual_performance_trace() -> void:
	if _manual_performance_request.is_empty():
		return
	if (
		_capture_mode
		or not _performance_request.is_empty()
	):
		push_warning(
			"Manual performance tracing cannot be combined with capture or "
			+ "synthetic performance modes."
		)
		_manual_performance_request.clear()
		return
	_manual_performance_trace = ManualPerformanceTrace.new()
	if not _manual_performance_trace.configure(
		String(_manual_performance_request["output"]),
		PERFORMANCE_DETAIL_SAMPLE_STRIDE,
		{
			"gameplay_path":"normal_deployment",
			"pressure_source":"existing_encounter_snapshot",
			"render_measurement_requested":RenderingServer.has_method(
				"viewport_set_measure_render_time"
			),
			"pressure_definitions":{
				"ordinary_authored_pressure_cap":"Logical authored ordinary pressure target for the current beat.",
				"ordinary_materialized_cap":"Maximum exact ordinary combat actors for the current beat.",
				"ordinary_virtual_reserve":"Authored ordinary units held as scheduler data without combat state.",
				"ordinary_quota_canceled_reserve":"Authored ordinary units canceled when the defeat quota sealed new admissions.",
				"ordinary_reserved_arrival_slots":"Exact slots promised by cues whose births are still pending.",
				"ordinary_materialized":"Map-wide exact cap-counting ordinary combat actors.",
				"ordinary_center_in_viewport":"Ordinary enemy bodies whose center is inside the visible world rectangle.",
				"ordinary_offscreen_active":"ordinary_materialized minus ordinary_center_in_viewport.",
			},
		}
	):
		push_error("Could not configure manual performance tracing.")
		_manual_performance_trace = null


func _start_manual_performance_trace() -> void:
	if not is_instance_valid(_manual_performance_trace):
		return
	if not _manual_performance_trace.start():
		return
	_refresh_pressure_observation_mode()
	_start_engagement_telemetry()
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.viewport_set_measure_render_time(
			get_viewport().get_viewport_rid(), true
		)
	print(
		"MANUAL_PERFORMANCE_TRACE_STARTED "
		+ String(_manual_performance_request["output"])
	)


func _finish_manual_performance_trace(reason: String) -> void:
	if not is_instance_valid(_manual_performance_trace):
		return
	if is_instance_valid(_engagement_telemetry):
		_manual_performance_trace.set_engagement_telemetry(_engagement_telemetry.snapshot())
		_stop_engagement_telemetry()
	_manual_performance_trace.finish(reason)
	_refresh_pressure_observation_mode()
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.viewport_set_measure_render_time(
			get_viewport().get_viewport_rid(), false
		)


func _start_engagement_telemetry() -> void:
	if is_instance_valid(_engagement_telemetry):
		return
	_engagement_telemetry = EngagementTelemetry.new()
	if is_instance_valid(encounter_runtime):
		encounter_runtime.set_engagement_telemetry_enabled(true)


func _stop_engagement_telemetry() -> void:
	if is_instance_valid(encounter_runtime):
		encounter_runtime.set_engagement_telemetry_enabled(false)
	_engagement_telemetry = null


func _fill_manual_performance_frame() -> void:
	encounter_runtime.fill_current_pressure(_manual_performance_pressure)
	_manual_performance_pressure["enemy_live"] = enemy_store.live_count()
	_manual_performance_pressure["player_projectiles"] = (
		projectile_store.player_count()
	)
	_manual_performance_pressure["hostile_projectiles"] = (
		projectile_store.hostile_count()
	)
	_manual_performance_pressure["experience_shards"] = (
		experience_runtime.shards.size()
	)
	_manual_performance_pressure["effects"] = effects.size()
	_manual_performance_pressure["denied_zones"] = denied_zones.size()
	_manual_performance_context.clear()
	_manual_performance_context["stage_id"] = String(current_stage_id)
	_manual_performance_context["stage_index"] = current_stage_index
	_manual_performance_context["encounter_beat"] = encounter_runtime.current_beat
	_manual_performance_context["run_time_seconds"] = active_run_elapsed_seconds
	_manual_performance_context["stage_time_seconds"] = maxf(
		0.0,
		active_run_elapsed_seconds - stage_started_at_active_run_seconds
	)
	_manual_performance_context["run_mode"] = "playing"


func _parse_encounter_pacing_capture_request() -> Dictionary:
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	return _encounter_pacing_capture_request_from_arguments(arguments)


static func _encounter_pacing_capture_request_from_arguments(arguments: Array) -> Dictionary:
	var output_path := ""
	var evidence_id := ""
	var expected_commit := ""
	var expected_fingerprint := ""
	for argument in arguments:
		if argument.begins_with("--encounter-pacing-output="):
			output_path = argument.trim_prefix("--encounter-pacing-output=")
		elif argument.begins_with("--encounter-pacing-evidence-id="):
			evidence_id = argument.trim_prefix("--encounter-pacing-evidence-id=")
		elif argument.begins_with("--encounter-pacing-expected-commit="):
			expected_commit = argument.trim_prefix("--encounter-pacing-expected-commit=")
		elif argument.begins_with("--encounter-pacing-expected-fingerprint="):
			expected_fingerprint = argument.trim_prefix(
				"--encounter-pacing-expected-fingerprint="
			)
	var any_requested := (
		not output_path.is_empty()
		or not evidence_id.is_empty()
		or not expected_commit.is_empty()
		or not expected_fingerprint.is_empty()
	)
	if not any_requested:
		return {}
	if (
		output_path.is_empty()
		or evidence_id.is_empty()
		or expected_commit.length() != 40
		or not expected_commit.is_valid_hex_number()
		or expected_fingerprint.length() != 64
		or not expected_fingerprint.is_valid_hex_number()
		or not EncounterPacingCaptureDriver.is_safe_output_path(output_path)
		or OS.has_feature("web")
	):
		return {"invalid":true}
	return {
		"output":output_path,
		"evidence_id":evidence_id,
		"expected_commit":expected_commit.to_lower(),
		"expected_fingerprint":expected_fingerprint.to_lower(),
	}


func _start_encounter_pacing_capture() -> void:
	if bool(_encounter_pacing_capture_request.get("invalid", false)):
		push_error(
			"Encounter pacing capture requires native output, evidence ID, commit, and fingerprint."
		)
		get_tree().quit(1)
		return
	if (
		_capture_mode
		or not _performance_request.is_empty()
		or not _manual_performance_request.is_empty()
	):
		push_error("Encounter pacing capture cannot be combined with other capture or performance modes.")
		get_tree().quit(1)
		return
	_encounter_pacing_capture_driver = EncounterPacingCaptureDriver.new()
	if not _encounter_pacing_capture_driver.configure(
		String(_encounter_pacing_capture_request["output"]),
		String(_encounter_pacing_capture_request["evidence_id"]),
		String(_encounter_pacing_capture_request["expected_commit"]),
		String(_encounter_pacing_capture_request["expected_fingerprint"])
	):
		push_error("Could not configure encounter pacing capture.")
		get_tree().quit(1)
		return
	_encounter_pacing_capture_driver.start(self)
	_ui.show_gameplay()
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
		elif argument.begins_with("--performance-enemy-count="):
			values["enemy_count"] = int(
				argument.trim_prefix("--performance-enemy-count=")
			)
		elif argument.begins_with("--performance-ablation="):
			values["ablation"] = argument.trim_prefix(
				"--performance-ablation="
			)
		elif argument.begins_with("--performance-deep-owner="):
			values["deep_owner"] = argument.trim_prefix(
				"--performance-deep-owner="
			)
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
	var enemy_count := int(values.get("enemy_count", -1))
	if not scenario.configure(StringName(values["scenario"]), enemy_count):
		push_error("Unknown performance scenario: %s" % String(values["scenario"]))
		return {}
	var ablation := StringName(values.get("ablation", "none"))
	if ablation not in [&"none", &"decision", &"attacks", &"presentation", &"overlap"]:
		push_error("Unknown performance ablation: %s" % String(ablation))
		return {}
	var deep_owner := StringName(values.get("deep_owner", "none"))
	if deep_owner not in [&"none", &"pursuit"]:
		push_error("Unknown performance deep owner: %s" % String(deep_owner))
		return {}
	values["output"] = String(values.get(
		"output",
		"res://build/performance/%s.json" % String(values["scenario"])
	))
	values["warmup"] = maxf(0.0, float(values.get("warmup", 10.0)))
	values["duration"] = maxf(0.25, float(values.get("duration", 60.0)))
	values["enemy_count"] = enemy_count
	values["ablation"] = ablation
	values["deep_owner"] = deep_owner
	return values


func _start_performance_scenario() -> void:
	_performance_scenario = PerformanceScenario.new()
	if not _performance_scenario.configure(
		StringName(_performance_request["scenario"]),
		int(_performance_request.get("enemy_count", -1))
	):
		return
	_performance_ablation = StringName(
		_performance_request.get("ablation", &"none")
	)
	_performance_deep_owner = StringName(
		_performance_request.get("deep_owner", &"none")
	)
	if (
		not OS.has_feature("web")
		and DisplayServer.has_method("window_move_to_foreground")
	):
		# Native performance samples must observe the visible game window, not a
		# background editor/terminal surface whose compositor path is unfocused.
		DisplayServer.window_move_to_foreground()
	_performance_recorder = PerformanceRecorder.new()
	_performance_recorder.configure(
		StringName(_performance_request["scenario"]),
		String(_performance_request["output"]),
		float(_performance_request["warmup"]),
		float(_performance_request["duration"]),
		_performance_deep_owner
	)
	_start_engagement_telemetry()
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_performance_scenario.activate(self)
	_refresh_pressure_observation_mode()
	_ui.show_gameplay()
	_set_mouse_for_mode()


func _finish_performance_scenario() -> void:
	_performance_finishing = true
	_refresh_pressure_observation_mode()
	var validation := _performance_scenario.validation_snapshot(self)
	_performance_scenario.deactivate()
	_performance_recorder.finish(
		get_viewport(),
		validation,
		_performance_counts(),
		_combat_renderer.debug_snapshot(),
		enemy_grid.debug_snapshot(),
		_engagement_telemetry.snapshot() if is_instance_valid(_engagement_telemetry) else {}
	)
	_stop_engagement_telemetry()
	if OS.has_feature("web"):
		mode = RunMode.PAUSED
		set_physics_process(false)
		set_process(false)
	else:
		get_tree().quit(0 if bool(validation.get("valid", false)) else 1)


func _refresh_pressure_observation_mode() -> void:
	if not is_instance_valid(encounter_runtime):
		return
	var performance_recording := (
		is_instance_valid(_performance_recorder)
		and not _performance_finishing
	)
	var manual_recording := (
		is_instance_valid(_manual_performance_trace)
		and _manual_performance_trace.is_recording()
	)
	encounter_runtime.set_pressure_observation_enabled(
		performance_recording or manual_recording
	)


func _performance_counts() -> Dictionary:
	return {
		"enemies": enemy_store.debug_snapshot(),
		"projectiles": projectile_store.debug_snapshot(),
		"experience": experience_runtime.shards.size(),
		"effects": effects.size(),
		"effect_store":effect_store.debug_snapshot(),
		"zones": denied_zones.size(),
		"layout":field_layout.debug_snapshot(current_stage_id) if field_layout != null else {},
		"collective_tactics":collective_tactics.debug_snapshot(),
		"boss_shield":boss_shield_runtime.snapshot(),
		"diagnostic":{
			"enemy_count":int(_performance_request.get("enemy_count", -1)),
			"ablation":String(_performance_ablation),
		},
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
