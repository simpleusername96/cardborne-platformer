class_name VehicleRun
extends Node2D

## Runs the connected authored vehicle campaign and its combat state.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const HudPresenter = preload("res://scripts/ui/vehicle_hud_presenter.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EliteTraits = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
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
const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossPracticeSession = preload("res://scripts/bosses/vehicle_boss_practice_session.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const CycleRuntime = preload("res://scripts/cards/vehicle_cycle_runtime.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")
const StageFlow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const PursuitField = preload("res://scripts/enemies/vehicle_pursuit_field.gd")
const SecondaryRuntime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const GuidebookCatalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileStore = preload("res://scripts/combat/vehicle_projectile_store.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const PerformanceRecorder = preload("res://scripts/performance/vehicle_performance_recorder.gd")
const PerformanceScenario = preload("res://scripts/performance/vehicle_performance_scenario.gd")
const FieldLayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

enum RunMode {
	DEPLOYMENT,
	PLAYING,
	UPGRADE,
	PAUSED,
	RESULT,
	GARAGE,
}

const SAVE_PATH := "user://vehicle-run.cfg"
const PLAYER_MAX_HEALTH := 120.0
const PLAYER_BASE_SPEED := 280.0
const PRIMARY_RANGE := 1100.0
const PRIMARY_PROJECTILE_SPEED := 1120.0
const PRIMARY_PROJECTILE_RADIUS := 7.0
const DASH_DURATION := 0.20
const DASH_SPEED := 1220.0
const DASH_COOLDOWN := 1.25
const PASSIVE_RANGE := 560.0
const PASSIVE_COOLDOWN := 1.35
const EMP_COOLDOWN := 13.0
const EMP_STARTUP := 0.42
const EMP_RADIUS := 285.0
const MINIMAP_COLS := 20
const MINIMAP_ROWS := 12
const THREAT_SCAN_DISTANCE := 1200.0
const THREAT_SAMPLE_INTERVAL := 0.10
const LOW_COUNT_OVERLAY_INTERVAL := 0.05
const ORDINARY_DECISION_BUCKET_COUNT := 6
const FAR_SIMULATION_DISTANCE := 820.0
const FAR_SIMULATION_DISTANCE_SQUARED := FAR_SIMULATION_DISTANCE * FAR_SIMULATION_DISTANCE
const FAR_ENEMY_SIMULATION_BUCKET_COUNT := 3
const CRATE_COLLISION_RADIUS := 31.0
const CRATE_COLLISION_CELL_SIZE := 320.0
const CHARGE_PATH_SAMPLE_STEP := 8.0
const CHARGE_PATH_BINARY_STEPS := 8
# Prime relative to the six-way enemy decision buckets so profiling eventually
# observes every scheduling phase without timing every physics tick.
const PERFORMANCE_DETAIL_SAMPLE_STRIDE := 7
const PLAYER_HIT_FLASH_DURATION := 0.20
const PLAYER_HIT_INVULNERABILITY := 1.0
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
var encounter_runtime := EncounterRuntime.new()
var stage_flow := StageFlow.new()
var pursuit_field := PursuitField.new()
var secondary_runtime := SecondaryRuntime.new()
var terrain_runtime := TerrainRuntime.new()
var boss_runtime := BossRuntime.new()
var boss_practice := BossPracticeSession.new()
var _runtime_blockers: Array[Rect2] = []

var player_position := Vector2.ZERO
var player_velocity := Vector2.ZERO
var player_hull_direction := Vector2.RIGHT
var player_aim_direction := Vector2.RIGHT
var player_health := PLAYER_MAX_HEALTH
var player_invulnerable := 0.0
var player_hit_flash := 0.0
var player_primary_weapon := PrimaryWeapon.new()
var _primary_shot_serial := 0
var player_muzzle_flash := 0.0
var player_dash_cooldown := 0.0
var player_dash_timer := 0.0
var player_dash_direction := Vector2.RIGHT
var player_dash_trail_timer := 0.0
var player_passive_cooldown := 0.0
var player_emp_cooldown := 0.0
var player_emp_startup := 0.0
var player_barrier_strength := 0.0
var player_barrier_timer := 0.0
var coolant_surge_timer := 0.0
var _last_primary_tier: StringName = &"ready"
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
var current_reward_source: StringName = &""
var current_reward_optional := false
var claimed_reward_sources: Dictionary = {}
var completed_group_rewards: Dictionary = {}
var pending_stage_completion := false
var pending_reward_sources: Array[StringName] = []
var experience_recall_timer := 0.0
var lifesteal_budget := 6.0

var enemy_store := EnemyStore.new()
var enemy_grid := SpatialGrid.new()
var enemies: Array[EnemyState] = enemy_store.live
var _enemy_query_buffer: Array[EnemyState] = []
var projectile_store := ProjectileStore.new()
var player_projectiles: Array[ProjectileState] = projectile_store.player_live
var hostile_projectiles: Array[ProjectileState] = projectile_store.hostile_live
var pickups: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var _crate_collision_cells: Dictionary = {}
var denied_zones: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var damaging_trails: Array[Dictionary] = []
var _empty_cover_rects: Array[Rect2] = []
var _projectile_cover_query: Array[Rect2] = []
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
var run_index := 0
var current_stage_index := 0
var current_stage_id: StringName = StageCatalog.STAGE_IDS[0]

var visited_cells: Dictionary = {}
var discovered_markers: Dictionary = {}
var _threat_contact_cache: Array[Dictionary] = []
var _threat_sample_timer := 0.0
var _squad_motion_snapshot: Dictionary = {}
var _shielded_enemy_ids: Dictionary = {}
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

var _capture_directory := ""
var _capture_mode := false
var _capture_locale := ""
var _capture_size := Vector2i.ZERO
var _debug_collision_overlay := false
var _performance_request: Dictionary = {}
var _performance_recorder: VehiclePerformanceRecorder
var _performance_scenario: VehiclePerformanceScenario
var _performance_finishing := false
var _performance_enemy_sections: Dictionary = {}
var _performance_detail_sample_active := false
var _practice_request: Dictionary = {}


func _ready() -> void:
	_rng.seed = 0xC4A2B0
	_layout_session_rng.randomize()
	_layout_session_seed = _layout_session_rng.seed
	_parse_capture_arguments()
	_performance_request = _parse_performance_request()
	_practice_request = _parse_boss_practice_request()
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
	selected_run_difficulty = _preferred_run_difficulty()
	_reset_run(false)
	_ui.show_deployment(
		selected_primary,
		selected_run_difficulty,
		String(field_layout.field_definition["name_key"])
	)
	_set_mouse_for_mode()
	queue_redraw()
	if not _practice_request.is_empty():
		call_deferred("_start_boss_practice")
	elif not _performance_request.is_empty():
		call_deferred("_start_performance_scenario")


func _exit_tree() -> void:
	_release_tree_pause()
	if is_instance_valid(_audio):
		_audio.shutdown()


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
	if mode == RunMode.PLAYING:
		_simulation_lod_bucket = 1 - _simulation_lod_bucket
		_far_enemy_simulation_bucket = (
			(_far_enemy_simulation_bucket + 1)
			% FAR_ENEMY_SIMULATION_BUCKET_COUNT
		)
		run_time += delta
		var section_started := Time.get_ticks_usec() if _performance_detail_sample_active else 0
		_update_player(delta)
		_update_terrain(delta)
		_update_cycle_upgrades(delta)
		_update_pickups()
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
		if _simulation_lod_bucket == 0:
			enemy_grid.rebuild(enemies)
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
			enemy_grid.rebuild(enemies)
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
	if is_instance_valid(_ui) and (mode == RunMode.PLAYING or _capture_mode):
		var hud_started := Time.get_ticks_usec() if performance_active else 0
		var hud_update := _hud_presenter.advance(
			delta,
			Callable(self, "_build_fast_hud_snapshot"),
			Callable(self, "_minimap_snapshot"),
			Callable(self, "_threat_radar_snapshot"),
			Callable(self, "_status_orbit_snapshot"),
			Callable(self, "_guidebook_snapshot")
		)
		if not hud_update.is_empty():
			_ui.update_hud(hud_update)
		if performance_active:
			hud_ms = _elapsed_ms(hud_started)
	else:
		_hud_presenter.reset()
	if is_instance_valid(_audio):
		var primary_held := (
			mode == RunMode.PLAYING
			and InputMap.has_action("primary_fire")
			and Input.is_action_pressed("primary_fire")
		)
		_audio.update_primary(primary_held)
	var presentation_active := mode == RunMode.PLAYING or _capture_mode
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
			_visible_world_rect(220.0),
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
		and (mode == RunMode.PLAYING or _capture_mode or _debug_collision_overlay)
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
	_backdrop.configure(current_stage_id, field_layout)


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
	_ui.upgrade_declined.connect(_on_upgrade_declined)
	_ui.upgrade_previewed.connect(func(_upgrade_id: StringName) -> void: _play_sound(&"upgrade_select"))
	_ui.pause_requested.connect(_pause_run)
	_ui.resume_requested.connect(_resume_run)
	_ui.restart_requested.connect(_restart_stage)
	_ui.garage_requested.connect(_show_garage)
	_ui.replay_requested.connect(_replay_stage)


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
	if is_instance_valid(_backdrop):
		_backdrop.configure(current_stage_id, field_layout)
	if is_instance_valid(_camera):
		_apply_camera_stage_limits()
	if is_instance_valid(_ui):
		_ui.clear_notifications()
	mode = RunMode.DEPLOYMENT
	player_position = Rules.player_start(current_stage_id)
	player_velocity = Vector2.ZERO
	player_hull_direction = Vector2.RIGHT
	player_aim_direction = Vector2.RIGHT
	player_health = _player_max_health()
	player_invulnerable = 0.0
	player_hit_flash = 0.0
	player_primary_weapon.set_full_opening_seconds(_opening_charge_seconds())
	player_primary_weapon.reset(true)
	_primary_shot_serial = 0
	player_dash_cooldown = 0.0
	player_dash_timer = 0.0
	player_passive_cooldown = 0.0
	player_emp_cooldown = 0.0
	player_emp_startup = 0.0
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	coolant_surge_timer = 0.0
	_last_primary_tier = &"ready"
	_aim_target_id = ""
	_marked_enemy_id = ""
	_sheared_enemy_id = ""
	_last_damage_source = ""
	_elite_pending = 0
	_elite_spawned = 0
	_elite_threshold_cursor = 0

	if not preserve_upgrades:
		run_build.reset()
		experience_runtime.reset()
		selected_upgrade_title_key = "UPGRADE_NONE"
		claimed_reward_sources.clear()
	else:
		experience_runtime.clear_shards()
		experience_runtime.pending_level_ups = 0
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
	damaging_trails.clear()
	for spec in field_layout.stationary_blueprint(current_stage_id):
		_append_enemy(_make_enemy(spec))
	encounter_runtime.configure(
		current_stage_id,
		StageCatalog.packets(current_stage_id),
		selected_run_difficulty,
		field_layout.ordinary_spawn_anchors,
		field_layout.encounter_seed(current_stage_id)
	)
	stage_flow.configure(
		current_stage_index,
		RunDifficulty.scaled_quota(StageCatalog.quota(current_stage_id), selected_run_difficulty)
	)
	terrain_runtime.configure(
		field_layout.field_definition.get("features", []),
		field_layout.persistent_bulkhead_health,
		preserve_field_state
	)
	_rebuild_runtime_blockers()
	pursuit_field.reset(current_stage_id, _runtime_cover_rects())
	for spec in field_layout.pickup_blueprint(current_stage_id):
		pickups.append({
			"id": String(spec["id"]),
			"kind": StringName(spec["kind"]),
			"pos": Vector2(spec["pos"]),
			"active": true,
			"pulse": _rng.randf_range(0.0, TAU),
			"heal_amount": float(spec.get("heal_amount", 35.0)),
		})
	for spec in field_layout.crate_blueprint(current_stage_id):
		crates.append({
			"id": String(spec["id"]),
			"pos": Vector2(spec["pos"]),
			"drop": StringName(spec["drop"]),
			"health": 24.0,
			"max_health": 24.0,
			"alive": true,
			"flash": 0.0,
		})
	_rebuild_crate_collision_cells()

	tutorial_move = false
	tutorial_aim = false
	tutorial_fire = false
	tutorial_dash = false
	tutorial_announced = false
	boss_started = false
	boss_phase_two_announced = false
	boss_arrival_position = Vector2.ZERO
	stage_complete = false
	pending_stage_completion = false
	pending_reward_sources.clear()
	current_reward_source = &""
	current_reward_optional = false
	completed_group_rewards.clear()
	if not preserve_upgrades:
		run_time = 0.0
	if not preserve_upgrades:
		visited_cells.clear()
	discovered_markers.clear()
	_threat_contact_cache.clear()
	_threat_sample_timer = 0.0
	_squad_motion_snapshot.clear()
	_shielded_enemy_ids.clear()
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
		player_passive_cooldown = 0.0
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
	var speed := (
		float(definition["speed"])
		* EncounterDirector.ENEMY_SPEED_MULTIPLIER
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
	enemy.visual_radius = float(definition["visual_radius"])
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
	enemy.stagger = 0.0
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
	enemy.formation_offset = Vector2(spec.get("formation_offset", Vector2.ZERO))
	enemy.target_sector = Vector2(spec.get("target_sector", Vector2.RIGHT))
	enemy.packet_beat = int(spec.get("packet_beat", 0))
	enemy.carrier_id = String(spec.get("carrier_id", ""))
	enemy.summoned = bool(spec.get("summoned", false))
	enemy.child_serial = 0
	enemy.carrier_wave_released = false
	enemy.beam_end = position
	enemy.requires_reflection = bool(spec.get("requires_reflection", false))
	enemy.marked_time = 0.0
	enemy.shear_time = 0.0
	enemy.leash_rect = Rect2(spec.get("leash_rect", Rect2()))
	enemy.required = bool(spec.get("required", false))
	enemy.optional = bool(spec.get("optional", false))
	enemy.ram_cooldown = 0.0
	enemy.pattern_index = 0
	enemy.boss_phase = 1
	enemy.boss_variant = StringName(spec.get("boss_variant", &"colossus"))
	enemy.pattern = &""
	enemy.last_pattern = &""
	enemy.pattern_timer = 0.0
	enemy.pattern_tick = 0.0
	enemy.pattern_volleys = 0
	enemy.vulnerable = 0.0
	enemy.breach_exposed = 0.0
	enemy.breach_exposed_recovery_used = false
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
	return enemy_store.add(enemy)


func _clear_enemies() -> void:
	enemy_store.clear()


func _flush_defeated_enemies() -> int:
	return enemy_store.flush_defeated()


func _clear_projectiles() -> void:
	projectile_store.clear()


func _rebuild_enemy_runtime_indexes() -> void:
	enemy_store.rebuild_index()
	enemy_grid.rebuild(enemies)


func _preferred_run_difficulty() -> StringName:
	var settings := get_node_or_null("/root/SettingsStore")
	return RunDifficulty.normalize(settings.run_difficulty) if settings != null else RunDifficulty.DEFAULT


func _update_encounter(delta: float) -> void:
	_refresh_elite_reservations()
	var requests := encounter_runtime.tick(
		delta,
		_active_mobile_count(),
		_active_attack_families(),
		player_position,
		_visible_world_rect(0.0)
	)
	for cue in requests["cues"]:
		_add_effect("spawn", Vector2(cue["anchor"]), Art.MUSTARD, 0.9, 126.0)
		_play_sound(&"boss", 0.72)
		if int(cue["beat"]) == 0:
			_ui.notify(tr("NOTIFY_CONTACT_INBOUND"), 1.2, Art.MUSTARD)
	for spawn_spec in requests["spawns"]:
		var bounded_spec := _bounded_spawn_spec(Dictionary(spawn_spec))
		var enemy := _make_enemy(bounded_spec)
		_apply_pending_elite(enemy)
		if _append_enemy(enemy):
			_add_effect("spawn", Vector2(enemy.pos), Art.CORAL, 0.42, 68.0)


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
		current_stage_index, _elite_spawned, field_layout.layout_seed
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


func _on_deployment_selected(primary_id: StringName, difficulty_id: StringName) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null:
		settings.set_run_difficulty(RunDifficulty.normalize(difficulty_id))
	_start_deployed_run(primary_id, difficulty_id)


func _on_boss_practice_selected(request: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	_practice_request = request.duplicate(true)
	_start_boss_practice()


func _start_deployed_run(primary_id: StringName, difficulty_id: StringName) -> void:
	selected_primary = primary_id
	selected_run_difficulty = RunDifficulty.normalize(difficulty_id)
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


func _on_upgrade_declined() -> void:
	if mode != RunMode.UPGRADE or not current_reward_optional:
		return
	claimed_reward_sources[_reward_transaction_id(current_reward_source)] = &"declined"
	_resolve_reward_transaction()
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_REWARD_DECLINED"), 2.2, Rules.MUTED)
	_set_mouse_for_mode()
	_advance_reward_queue()


func _pause_run() -> void:
	if mode != RunMode.PLAYING:
		return
	mode_before_pause = mode
	mode = RunMode.PAUSED
	_ui.update_hud({"guidebook": _guidebook_snapshot()})
	_ui.show_pause()
	_acquire_tree_pause()
	_set_mouse_for_mode()


func _resume_run() -> void:
	if mode != RunMode.PAUSED:
		return
	_release_tree_pause()
	mode = mode_before_pause
	_ui.show_gameplay()
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
		selected_run_difficulty,
		String(field_layout.field_definition["name_key"])
	)
	_set_mouse_for_mode()


func _advance_stage() -> void:
	if current_stage_index >= StageCatalog.STAGE_IDS.size() - 1:
		return
	current_stage_index += 1
	current_stage_id = StageCatalog.STAGE_IDS[current_stage_index]
	_reset_run(false, true, true, true)
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	var profile := StageCatalog.profile(current_stage_id)
	var arrival_text := tr("NOTIFY_STAGE_ARRIVAL").replace("%d", str(int(profile["number"]))).replace("%s", tr(String(profile["title_key"])))
	_ui.notify(arrival_text, 3.2, Rules.CYAN)
	_play_sound(&"card", 1.12)
	_set_mouse_for_mode()


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
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if mode == RunMode.PLAYING else Input.MOUSE_MODE_VISIBLE


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
	var primary_held := Input.is_action_pressed("primary_fire")
	player_primary_weapon.tick(delta, primary_held, player_dash_timer <= 0.0)
	var primary_tier := player_primary_weapon.tier()
	if primary_tier == &"ready" and _last_primary_tier != &"ready":
		_play_sound(&"opening_ready")
	_last_primary_tier = primary_tier
	player_dash_cooldown = maxf(0.0, player_dash_cooldown - delta)
	player_passive_cooldown = maxf(0.0, player_passive_cooldown - delta)
	player_emp_cooldown = maxf(0.0, player_emp_cooldown - delta)
	player_barrier_timer = maxf(0.0, player_barrier_timer - delta)
	coolant_surge_timer = maxf(0.0, coolant_surge_timer - delta)
	if player_barrier_timer <= 0.0:
		player_barrier_strength = 0.0

	_update_player_aim()
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length_squared() > 0.01:
		tutorial_move = true
		player_hull_direction = move_input.normalized()

	if player_dash_timer > 0.0:
		_update_dash(delta)
	else:
		var flow := terrain_runtime.flow_vector_at(player_position)
		var motion := (move_input * _player_move_speed() + flow) * delta
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

	_update_passive_secondary(delta)
	_update_aim_target()
	_mark_visited()
	_apply_dash_collision()
	player_velocity = (player_position - previous_position) / maxf(delta, 0.0001)

	if tutorial_move and tutorial_aim and tutorial_fire and tutorial_dash and not tutorial_announced:
		tutorial_announced = true
		_ui.notify(tr("NOTIFY_CALIBRATION_COMPLETE"), 3.0, Rules.MOSS)


func _update_terrain(delta: float) -> void:
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
				player_invulnerable = maxf(
					player_invulnerable, float(event["invulnerability"])
				)
				_add_effect("transit", player_position, Art.MINT, 0.34, 96.0)
				_play_sound(&"dash", 1.18)
	var surge_damage := terrain_runtime.surge_damage_for(
		"player", player_position, &"player"
	)
	if surge_damage > 0.0:
		_damage_player(surge_damage, "Arc Surge", false, false, true)


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
	player_invulnerable = DASH_DURATION + 0.08
	player_dash_trail_timer = 0.0
	stats_dash_uses += 1
	tutorial_dash = true
	camera_shake = maxf(camera_shake, 4.0)
	_play_sound(&"dash")
	_add_effect("dash_start", player_position, Rules.CYAN, 0.22, 52.0, player_dash_direction)


func _update_dash(delta: float) -> void:
	player_dash_timer = maxf(0.0, player_dash_timer - delta)
	var before := player_position
	player_position = _move_actor(
		player_position,
		(
			player_dash_direction * DASH_SPEED
			+ terrain_runtime.flow_vector_at(player_position)
		) * delta,
		Rules.PLAYER_RADIUS,
		true
	)
	if run_build.has(&"phase_shear"):
		_apply_phase_shear(before, player_position)
	player_dash_trail_timer -= delta
	if player_dash_trail_timer <= 0.0:
		player_dash_trail_timer = 0.035
		_add_effect("afterimage", before, Rules.CYAN, 0.20, 30.0, player_dash_direction)
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
			_damage_enemies_in_radius(player_position, 145.0, 32.0, 24.0, "Ram Pulse")
			_clear_hostile_projectiles(player_position, 170.0)
			_add_effect("shock", player_position, Rules.AMBER, 0.38, 170.0)
			_play_sound(&"emp", 1.55)


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
		_add_effect("impact", enemy.pos, Art.MINT, 0.24, 48.0)
		return


func _fire_primary(shot: Dictionary) -> void:
	tutorial_fire = true
	player_muzzle_flash = 0.075
	_primary_shot_serial += 1
	var primary_multiplier := run_build.stat(&"primary_damage_multiplier", 1.0)
	var origin := player_position + player_aim_direction * 39.0
	var breach_ready := bool(shot["full_opening"])
	var fork_level := mini(2, run_build.level_of(&"forked_muzzle"))
	var spread_step := deg_to_rad(7.0) * run_build.stat(&"primary_spread", 1.0)
	var projectile_speed := run_build.stat(&"primary_projectile_speed", PRIMARY_PROJECTILE_SPEED)
	var base_radius := run_build.stat(&"primary_radius", PRIMARY_PROJECTILE_RADIUS)
	var primary_structure := run_build.stat(&"primary_structure", 1.0)
	var range := run_build.stat(&"primary_range", PRIMARY_RANGE)
	var projectile_specs: Array[Dictionary] = [{"angle":0.0, "scale":1.0, "center":true}]
	if fork_level == 1:
		var side_sign := -1.0 if _primary_shot_serial % 2 == 0 else 1.0
		projectile_specs.append({"angle":side_sign * spread_step, "scale":0.40, "center":false})
	elif fork_level >= 2:
		projectile_specs.append({"angle":-spread_step, "scale":0.325, "center":false})
		projectile_specs.append({"angle":spread_step, "scale":0.325, "center":false})
	for spec in projectile_specs:
		var center_projectile := bool(spec["center"])
		var scale := float(spec["scale"])
		var owns_breach := breach_ready and center_projectile
		var health_scale := (
			PrimaryWeapon.FULL_HEALTH_SCALE
			+ run_build.stat(&"breach_health_scale_bonus", 0.0)
			if owns_breach
			else 1.0
		)
		var radius_scale := PrimaryWeapon.FULL_RADIUS_SCALE if owns_breach else 1.0
		var unprimed_structure_damage := 18.0 * primary_structure * scale
		var structure_damage := (
			maxf(TerrainRuntime.BULKHEAD_HEALTH, 18.0 * PrimaryWeapon.FULL_STRUCTURE_SCALE)
			if owns_breach
			else unprimed_structure_damage
		)
		_spawn_player_projectile(
			origin,
			player_aim_direction.rotated(float(spec["angle"])),
			18.0 * primary_multiplier * health_scale * scale,
			projectile_speed,
			run_build.level_of(&"phase_lance") + (1 if owns_breach else 0),
			base_radius * radius_scale,
			structure_damage,
			5.0,
			owns_breach,
			range,
			_status_profile,
			false,
			unprimed_structure_damage
		)
	if breach_ready:
		_play_sound(&"opening_fire", _rng.randf_range(0.97, 1.03))
	_add_effect("muzzle", origin, Art.MUSTARD, 0.09, 32.0, player_aim_direction)


func _try_fire_primary() -> bool:
	if not player_primary_weapon.can_fire(player_dash_timer <= 0.0):
		return false
	var interval := _primary_fire_interval()
	var shot := player_primary_weapon.consume_shot(interval)
	_fire_primary(shot)
	return true


func _primary_fire_interval() -> float:
	var interval := maxf(PrimaryWeapon.MIN_INTERVAL, run_build.stat(&"primary_interval", PrimaryWeapon.BASE_INTERVAL))
	if coolant_surge_timer > 0.0:
		interval = maxf(PrimaryWeapon.MIN_INTERVAL, interval * 0.85)
	return interval


func _runtime_cover_rects() -> Array[Rect2]:
	return _runtime_blockers


func _runtime_projectile_cover_rects(from: Vector2, to: Vector2, radius: float) -> Array[Rect2]:
	_projectile_cover_query.clear()
	if field_layout != null:
		field_layout.covers_near_motion_into(
			from, to, radius, _projectile_cover_query
		)
	for bulkhead in terrain_runtime.live_bulkhead_rects():
		_projectile_cover_query.append(bulkhead)
	return _projectile_cover_query


func _rebuild_runtime_blockers() -> void:
	_runtime_blockers.clear()
	if field_layout != null:
		_runtime_blockers.append_array(field_layout.cover_rects)
	_runtime_blockers.append_array(terrain_runtime.live_bulkhead_rects())


func _runtime_first_cover_hit(from: Vector2, to: Vector2, padding: float) -> Dictionary:
	return Rules.first_cover_hit_with_extra(
		from, to, padding, false, current_stage_id,
		_runtime_projectile_cover_rects(from, to, padding)
	)


func _runtime_has_line_of_sight(from: Vector2, to: Vector2, padding: float) -> bool:
	if bool(_runtime_first_cover_hit(from, to, padding).get("hit", false)):
		return false
	return not _segment_hits_live_crate(from, to, padding)


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
	var crate_hit: Variant = _first_live_crate_hit(origin, result, padding)
	if crate_hit == null:
		return result
	var hit_t := AttackContract.segment_circle_first_t(
		origin,
		result,
		Vector2(crate_hit["pos"]),
		CRATE_COLLISION_RADIUS + padding
	)
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
	stagger: float = 5.0,
	breach_token: bool = false,
	projectile_range: float = PRIMARY_RANGE,
	status_profile: VehicleStatusProfile = null,
	wall_piercing: bool = false,
	unprimed_structure_damage: float = -1.0
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
		"stagger": stagger,
		"structure_damage": damage if structure_damage < 0.0 else structure_damage,
		"breach_token_available": breach_token,
		"breach_visual": breach_token,
		"unprimed_structure_damage": (
			damage if unprimed_structure_damage < 0.0 else unprimed_structure_damage
		),
		"reflected": false,
		"wall_piercing": wall_piercing,
		"affinity": affinity,
		"condition_mask": condition_mask,
		"reflector_lock": &"",
		"reflector_lock_time": 0.0,
		"status_profile": status_profile,
	})


func _update_passive_secondary(delta: float) -> void:
	if player_passive_cooldown <= 0.0 and player_emp_startup <= 0.0:
		var targets := _find_passive_targets(1 + run_build.level_of(&"twin_seekers"))
		if not targets.is_empty():
			var cooldown := maxf(PASSIVE_COOLDOWN * 0.60, run_build.stat(&"passive_interval", PASSIVE_COOLDOWN))
			if persistent_field_module:
				cooldown *= 0.85
			player_passive_cooldown = cooldown
			for target in targets:
				var enemy: EnemyState = target
				var direction := (enemy.pos - player_position).normalized()
				var seeker_count := 1 + run_build.level_of(&"twin_seekers")
				var seeker_scale: float = [1.0, 0.85, 0.70][seeker_count - 1]
				var marked_multiplier := 1.25 if enemy.marked_time > 0.0 else 1.0
				projectile_store.add_player({
					"pos": player_position + direction * 33.0, "velocity":direction * 490.0,
					"radius":8.0,
					"damage":25.0 * run_build.stat(&"passive_damage_multiplier", 1.0) * seeker_scale * marked_multiplier,
					"life":1.8, "color":Art.MINT, "owner":"passive_seeker",
					"pierce":run_build.level_of(&"phase_seeker"), "bounces":0, "homing":true,
					"target_id":enemy.id, "explosive":applied_upgrades.has(&"hunter_firmware"),
					"stagger":12.0, "structure_damage":25.0,
					"breach_token_available":false, "status_profile":null,
					"wall_piercing":false,
				})
			_play_sound(&"missile")
	var secondary_result := secondary_runtime.update(
		delta,
		player_position,
		player_hull_direction,
		run_build,
		enemies,
		Callable(self, "_runtime_has_line_of_sight"),
		Callable(self, "_query_enemy_radius_into")
	)
	for intent in secondary_result["damage"]:
		var target := _find_enemy_by_id(String(intent["enemy_id"]))
		if target != null:
			_damage_enemy(target, float(intent["damage"]), String(intent["source"]), 6.0)
	for effect in secondary_result["effects"]:
		_add_effect("secondary", Vector2(effect["pos"]), Art.MINT, 0.18, float(effect.get("radius", 24.0)), (Vector2(effect.get("target", effect["pos"])) - Vector2(effect["pos"])).normalized())


func _find_passive_targets(max_targets: int) -> Array[EnemyState]:
	var candidates: Array[EnemyState] = []
	enemy_grid.query_radius_into(player_position, PASSIVE_RANGE, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		var distance := player_position.distance_to(enemy.pos)
		if distance > PASSIVE_RANGE:
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
		enemy.passive_score = priority + distance
		candidates.append(enemy)
	candidates.sort_custom(func(a: EnemyState, b: EnemyState) -> bool:
		return a.passive_score < b.passive_score
	)
	if candidates.size() > max_targets:
		candidates.resize(max_targets)
	return candidates


func _query_enemy_radius_into(center: Vector2, radius: float, output: Array[EnemyState]) -> void:
	enemy_grid.query_radius_into(center, radius, enemies, output)


func _start_emp() -> void:
	player_emp_startup = EMP_STARTUP
	player_emp_cooldown = _emp_cooldown_max()
	player_invulnerable = maxf(player_invulnerable, 0.24)
	_play_sound(&"emp_start")
	_add_effect("emp_start", player_position, Art.BOSS_MAGENTA, EMP_STARTUP, _emp_radius())


func _release_emp(is_aftershock: bool) -> void:
	var radius := _emp_radius() * (0.68 if is_aftershock else 1.0)
	var damage := (34.0 if is_aftershock else 62.0) * run_build.stat(&"emp_damage_multiplier", 1.0)
	_damage_enemies_in_radius(player_position, radius, damage, 42.0, "EMP Aftershock" if is_aftershock else "EMP Nova")
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
	_add_effect("shock", player_position, Art.BOSS_MAGENTA, 0.55, radius)
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


func _opening_charge_seconds() -> float:
	return run_build.stat(&"opening_seconds_multiplier", PrimaryWeapon.FULL_OPENING_SECONDS)


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
	_add_effect("barrier_hit", player_position, Art.MINT, 0.22, 74.0)


func _update_pickups() -> void:
	for pickup in pickups:
		if not bool(pickup["active"]):
			continue
		pickup["pulse"] = float(pickup["pulse"]) + 0.06
		if player_position.distance_to(Vector2(pickup["pos"])) <= 48.0:
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
	_add_effect("pickup", Vector2(pickup["pos"]), _pickup_color(kind), 0.40, 65.0)
	_play_sound(&"pickup")


func _pickup_color(kind: StringName) -> Color:
	match kind:
		&"repair":
			return Art.MINT
		&"experience_recall":
			return Art.COBALT_WATER
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
		if source not in pending_reward_sources:
			pending_reward_sources.append(source)
	if int(result["levels"]) > 0:
		_ui.notify(tr("NOTIFY_LEVEL_UP"), 1.8, Art.MUSTARD)
	_advance_reward_queue()


func _update_enemies(delta: float) -> void:
	var performance_active := _performance_detail_sample_active
	var section_started := Time.get_ticks_usec() if performance_active else 0
	_enforce_active_enemy_cap()
	var decision_bucket := _enemy_decision_bucket
	_enemy_decision_bucket = (_enemy_decision_bucket + 1) % ORDINARY_DECISION_BUCKET_COUNT
	var committed_points := 0.0
	var committed_ranged := 0
	var committed_denial := 0
	var active_capped := 0
	for enemy in enemies:
		if not enemy.alive:
			continue
		if enemy.active and enemy.counts_active_cap:
			active_capped += 1
		if enemy.phase in [&"startup", &"active"] and enemy.role not in [&"stage_boss", &"generator", &"boss_pylon"]:
			committed_points += enemy.threat_cost
			match enemy.threat_kind:
				&"ranged": committed_ranged += 1
				&"denial": committed_denial += 1
	if performance_active:
		_performance_enemy_sections["budget_scan"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()

	for enemy in enemies:
		if not enemy.alive:
			continue
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
		if enemy.breach_exposed > 0.0:
			enemy.breach_exposed = maxf(0.0, enemy.breach_exposed - delta)
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
			var activated := _update_enemy_activation(enemy, active_capped < encounter_runtime.active_cap())
			if activated and enemy.counts_active_cap:
				active_capped += 1
	if performance_active:
		_performance_enemy_sections["status_activation"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()

	if decision_bucket == 0 or not _enemy_coordination_initialized:
		_squad_motion_snapshot = EncounterDirector.squad_motion_snapshot(enemies)
		_shielded_enemy_ids = _build_enemy_shield_assignments()
		for enemy in enemies:
			if enemy.alive and enemy.active:
				_apply_enemy_shield(enemy, _shielded_enemy_ids)
		_enemy_coordination_initialized = true
	if performance_active:
		_performance_enemy_sections["coordination"] = _elapsed_ms(section_started)
		section_started = Time.get_ticks_usec()
	for enemy in enemies:
		if not enemy.alive:
			continue
		if not enemy.active:
			continue
		var terrain_damage := terrain_runtime.surge_damage_for(
			enemy.id,
			enemy.pos,
			&"boss" if enemy.role == &"stage_boss" else &"ordinary"
		)
		if terrain_damage > 0.0:
			_damage_enemy(enemy, terrain_damage, "Arc Surge", 0.0)
			if not enemy.alive:
				continue
		var status_damage := StatusRuntime.tick(enemy, delta)
		if status_damage > 0.0:
			_damage_enemy(enemy, status_damage, "status", 0.0)
			if not enemy.alive:
				continue
		var role := enemy.role
		if role == &"stage_boss":
			_update_stage_boss(enemy, delta)
			continue
		if role == &"generator":
			_update_generator(enemy, delta)
			continue
		if role == &"boss_pylon":
			_update_boss_pylon(enemy, delta)
			continue
		if enemy.stun > 0.0:
			enemy.velocity = Vector2.ZERO
			continue
		var decision_due := enemy.decision_bucket == decision_bucket
		var motion_delta := _ordinary_enemy_motion_delta(enemy, delta)
		var can_commit := false
		if decision_due:
			can_commit = EncounterDirector.can_commit(
				committed_points,
				committed_ranged,
				committed_denial,
				enemy,
				encounter_runtime.threat_budget(),
				encounter_runtime.ranged_commit_cap(),
				encounter_runtime.denial_commit_cap()
			)
			if role == &"rammer" and not SpecialistRuntime.rammer_can_commit(enemy, enemies):
				can_commit = false
		var started := _update_ordinary_enemy(enemy, delta, can_commit, decision_due, motion_delta)
		if started:
			committed_points += enemy.threat_cost
			match enemy.threat_kind:
				&"ranged": committed_ranged += 1
				&"denial": committed_denial += 1
	if performance_active:
		_performance_enemy_sections["behavior_and_motion"] = _elapsed_ms(section_started)


func _enforce_active_enemy_cap() -> void:
	var active_count := 0
	for enemy in enemies:
		if enemy.alive and enemy.active and enemy.counts_active_cap:
			active_count += 1
	var cap := encounter_runtime.active_cap()
	if active_count <= cap:
		return
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


func _update_enemy_activation(enemy: EnemyState, capacity_available: bool) -> bool:
	if enemy.active:
		return false
	if not capacity_available and enemy.counts_active_cap:
		return false
	enemy.active = true
	return true


func _build_enemy_shield_assignments() -> Dictionary:
	var shielded_ids := {}
	var supports: Array[EnemyState] = []
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var role := enemy.role
		if role in [&"generator", &"shield_escort"]:
			supports.append(enemy)
	for support in supports:
		var support_position := support.pos
		var support_radius := 390.0 if support.role == &"generator" else 300.0
		var nearby: Array[EnemyState] = []
		enemy_grid.query_radius_into(support_position, support_radius, enemies, nearby)
		if support.role == &"generator":
			for candidate in nearby:
				var candidate_role := candidate.role
				if candidate != support and candidate_role not in [&"generator", &"shield_escort", &"stage_boss", &"boss_pylon"] and support_position.distance_squared_to(candidate.pos) <= 390.0 * 390.0:
					shielded_ids[candidate.id] = true
			continue
		var closest_id := ""
		var closest_distance_squared := 300.0 * 300.0
		for candidate in nearby:
			var candidate_role := candidate.role
			if candidate == support or candidate_role in [&"generator", &"shield_escort", &"stage_boss", &"boss_pylon"]:
				continue
			var distance_squared := support_position.distance_squared_to(candidate.pos)
			if distance_squared <= closest_distance_squared:
				closest_distance_squared = distance_squared
				closest_id = candidate.id
		if not closest_id.is_empty():
			shielded_ids[closest_id] = true
	return shielded_ids


func _apply_enemy_shield(enemy: EnemyState, shielded_ids: Dictionary) -> void:
	var shielded := bool(shielded_ids.get(enemy.id, false))
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
	var nearby: Array[EnemyState] = []
	enemy_grid.query_radius_into(enemy.pos, 390.0, enemies, nearby)
	for target in nearby:
		if target == enemy:
			continue
		if target.pos.distance_to(enemy.pos) <= 390.0:
			target.health = minf(target.max_health, target.health + 4.0)
	_add_effect("support", enemy.pos, Rules.CYAN, 0.28, 105.0)


func _update_repair_tender(enemy: EnemyState, delta: float, refresh_target: bool) -> void:
	if refresh_target:
		var nearby: Array[EnemyState] = []
		enemy_grid.query_radius_into(enemy.pos, SpecialistRuntime.REPAIR_RANGE, enemies, nearby)
		enemy.repair_target_id = SpecialistRuntime.repair_target_id(enemy, nearby, current_stage_id, false, _runtime_cover_rects())
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
		_add_effect("support", target.pos, Art.MINT, 0.24, 46.0)


func _spawn_carrier_child(carrier: EnemyState) -> void:
	if SpecialistRuntime.living_children(carrier.id, enemies) >= SpecialistRuntime.CARRIER_CHILD_CAP:
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
		_add_effect("spawn", spawn_position, Art.CORAL, 0.32, 44.0)


func _update_boss_pylon(enemy: EnemyState, delta: float) -> void:
	enemy.support_tick -= delta
	if enemy.support_tick <= 0.0:
		enemy.support_tick = 2.4
		denied_zones.append({
			"pos": enemy.pos,
			"radius": 125.0,
			"warning": 0.80,
			"warning_total": 0.80,
			"duration": 1.8,
			"tick": 0.0,
			"damage": 9.0,
			"final_damage": true,
			"source": "Colossus pylon field",
			"affinity": AttackContract.ARC,
		})


func _ordinary_enemy_motion_delta(enemy: EnemyState, delta: float) -> float:
	# Locomotion collision is the dominant ordinary-enemy cost. Combat windows
	# remain 60 Hz, nearby travel runs at 30 Hz, and distant travel at 20 Hz.
	if enemy.phase in [&"startup", &"active"]:
		return delta
	if player_position.distance_squared_to(enemy.pos) > FAR_SIMULATION_DISTANCE_SQUARED:
		if enemy.runtime_slot % FAR_ENEMY_SIMULATION_BUCKET_COUNT != _far_enemy_simulation_bucket:
			return 0.0
		return delta * float(FAR_ENEMY_SIMULATION_BUCKET_COUNT)
	if enemy.runtime_slot % 2 != _simulation_lod_bucket:
		return 0.0
	return delta * 2.0


func _update_ordinary_enemy(
	enemy: EnemyState,
	delta: float,
	can_commit: bool,
	decision_due: bool = true,
	motion_delta: float = -1.0
) -> bool:
	if motion_delta < 0.0:
		motion_delta = delta
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
			return distance <= 760.0 and SpecialistRuntime.living_children(enemy.id, enemies) < SpecialistRuntime.CARRIER_CHILD_CAP
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
		Callable(self, "_runtime_attack_path_end"),
		Callable(self, "_runtime_charge_path_end")
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
				StringName(shooter_attack["affinity"])
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
				"shock",
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
				StringName(interceptor_attack["affinity"])
			)
			enemy.phase = &"recovery"
			enemy.phase_time = 0.9
		&"rammer":
			enemy.phase_time = SpecialistRuntime.RAMMER_ACTIVE
		&"drone_carrier":
			enemy.burst_left = mini(3, SpecialistRuntime.CARRIER_CHILD_CAP - SpecialistRuntime.living_children(enemy.id, enemies))
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
					StringName(turret_attack["affinity"])
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
		enemy.desired_velocity = _desired_enemy_velocity(enemy, recovering)
	_move_enemy_with_recovery(enemy, enemy.desired_velocity, delta)


func _desired_enemy_velocity(enemy: EnemyState, recovering: bool) -> Vector2:
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
	return EncounterDirector.cohesion_velocity(enemy, _squad_motion_snapshot, role_velocity)


func _move_enemy_with_recovery(enemy: EnemyState, velocity: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	if enemy.reposition_time > 0.0:
		enemy.reposition_time = maxf(0.0, enemy.reposition_time - delta)
		velocity = enemy.reposition_dir * enemy.speed
	var before := enemy.pos
	var flow := terrain_runtime.flow_vector_at(
		before,
		enemy.role == &"stage_boss",
		enemy.role in [&"turret", &"generator", &"interceptor_tower", &"beam_sentinel"]
			or (enemy.role == &"mine" and enemy.archetype != &"spark_minelet")
	)
	var attempt := _move_actor(before, (velocity + flow) * delta, enemy.radius, false)
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
			_damage_enemy(target, damage, source)
	_arm_chain_mines(enemy, origin, mobile)
	_add_effect("shock", origin, Art.ATTACK_ARC, 0.36, radius)
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
	var result := Rules.move_circle_with_extra(position, motion, radius, false, current_stage_id, _runtime_cover_rects())
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		var crate_position := Vector2(crate["pos"])
		var clearance := radius + CRATE_COLLISION_RADIUS
		if result.distance_squared_to(crate_position) < clearance * clearance:
			var x_attempt := Vector2(result.x, position.y)
			var y_attempt := Vector2(position.x, result.y)
			if x_attempt.distance_squared_to(crate_position) >= clearance * clearance:
				result = x_attempt
			elif y_attempt.distance_squared_to(crate_position) >= clearance * clearance:
				result = y_attempt
			else:
				result = position
	return result


func _spawn_hostile_projectile(
	origin: Vector2,
	direction: Vector2,
	damage: float,
	speed: float,
	source: String,
	affinity: StringName = AttackContract.KINETIC,
	final_damage: bool = false,
	wall_piercing: bool = false
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
		"stagger": 0.0,
		"reflected": false,
		"reflector_lock": &"",
		"reflector_lock_time": 0.0,
		"wall_piercing": wall_piercing,
		"affinity": normalized_affinity,
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
						var structure_damage := projectile.structure_damage
						if projectile.breach_token_available:
							structure_damage = TerrainRuntime.BULKHEAD_HEALTH
						if terrain_runtime.damage_bulkhead(bulkhead_id, structure_damage):
							_on_bulkhead_broken(Vector2(cover_hit["point"]))
				if projectile.breach_token_available:
					_consume_breach_token(projectile)
				if projectile.bounces > 0:
					projectile.bounces -= 1
					var normal: Vector2 = cover_hit["normal"]
					projectile.velocity = projectile.velocity.bounce(normal)
					projectile.pos = Vector2(cover_hit["point"]) + normal * (radius + 2.0)
					_add_effect("impact", projectile.pos, Rules.CYAN, 0.15, 18.0)
					index += 1
					continue
				_add_effect("impact", Vector2(cover_hit["point"]), projectile.color, 0.14, 20.0)
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
			enemy_grid.query_segment_into(
				from,
				to,
				112.0 + projectile_radius,
				enemies,
				_enemy_query_buffer
			)
			var contact: Variant = _player_projectile_contact(
				projectile,
				from,
				to,
				projectile_radius,
				_enemy_query_buffer
			)
			if contact is bool:
				projectile_store.remove_player_at_swap(index)
				continue
			var hit_enemy := contact as EnemyState
			if hit_enemy != null:
				var hit_position := hit_enemy.pos
				if _try_absorb_protective_structure(hit_enemy, projectile):
					if projectile.breach_token_available:
						_consume_breach_token(projectile)
					stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
					_add_effect("barrier_hit", hit_position, Art.IVORY_BRIGHT, 0.20, hit_enemy.radius * 1.35)
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
				var opening_result := {
					"bonus_damage":0.0,
					"splash_damage":0.0,
					"splash_radius":0.0,
				}
				var breach_contact := projectile.breach_token_available
				if breach_contact:
					opening_result = StatusRuntime.resolve_opening(
						hit_enemy, projectile.status_profile, enemy_damage
					)
				enemy_damage += float(opening_result["bonus_damage"])
				var damage_source := "reflected_%s" % projectile.owner if projectile.reflected else projectile.owner
				_damage_enemy(
					hit_enemy,
					enemy_damage,
					damage_source,
					projectile.stagger
				)
				if breach_contact:
					_resolve_breach_contact(hit_enemy)
				if projectile.owner == "player_primary" and run_build.has(&"marked_salvo"):
					_mark_enemy(hit_enemy)
				if breach_contact and run_build.has(&"shock_breach"):
					var shock_damage := _shock_breach_damage(enemy_damage)
					_damage_enemies_in_radius(hit_position, 90.0, shock_damage, 8.0, "Shock Breach", hit_enemy.id)
					_add_effect("shock", hit_position, Art.MUSTARD, 0.24, 90.0)
				if float(opening_result["splash_radius"]) > 0.0:
					_damage_enemies_in_radius(
						hit_position,
						float(opening_result["splash_radius"]),
						float(opening_result["splash_damage"]),
						0.0,
						"Flashover",
						hit_enemy.id
					)
				StatusRuntime.apply(hit_enemy, projectile.status_profile)
				if breach_contact:
					_consume_breach_token(projectile)
				stats_primary_hits += 1 if projectile.owner == "player_primary" else 0
				_add_effect("impact", hit_position, projectile.color, 0.18, 24.0)
				_play_sound(&"impact", _rng.randf_range(0.92, 1.08))
				if projectile.explosive:
					_damage_enemies_in_radius(hit_position, 95.0, 12.0, 8.0, "Seeker burst", hit_enemy.id)
					_add_effect("shock", hit_position, Rules.MOSS, 0.28, 95.0)
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


func _consume_breach_token(projectile: ProjectileState) -> void:
	projectile.breach_token_available = false
	projectile.breach_visual = false
	projectile.structure_damage = projectile.unprimed_structure_damage


func _resolve_breach_contact(enemy: EnemyState) -> void:
	if not enemy.alive:
		return
	if enemy.role == &"mine":
		_arm_mine(enemy, 0.75, true)
		return
	if enemy.role == &"stage_boss":
		if boss_runtime.update_phase_transition(enemy):
			return
		if boss_runtime.try_interrupt_signature(enemy):
			_add_effect("impact", enemy.pos, Art.MUSTARD, 0.24, enemy.radius * 1.45)
			_play_sound(&"impact", 0.78)
			return
	if enemy.phase == &"startup" and AttackContract.startup_is_interruptible(enemy.role):
		enemy.phase = &"interrupted_recovery"
		enemy.phase_time = 0.45
		enemy.velocity = Vector2.ZERO
		enemy.burst_left = 0
		enemy.burst_timer = 0.0
		enemy.attack_telegraphs.clear()
		_add_effect("impact", enemy.pos, Art.MUSTARD, 0.20, enemy.radius * 1.35)
		_play_sound(&"impact", 0.82)
		return
	var eligible := enemy.role in [
		&"repair_tender", &"drone_carrier", &"turret", &"interceptor_tower",
		&"beam_sentinel", &"generator",
	]
	if enemy.role == &"stage_boss":
		eligible = enemy.phase == &"boss_recovery" and not enemy.breach_exposed_recovery_used
	if not eligible or enemy.breach_exposed > 0.0:
		return
	enemy.breach_exposed = 1.25
	if enemy.role == &"stage_boss":
		enemy.breach_exposed_recovery_used = true
	_add_effect("impact", enemy.pos, Art.MUSTARD, 0.12, enemy.radius * 1.24)


func _on_bulkhead_broken(position: Vector2) -> void:
	_rebuild_runtime_blockers()
	pursuit_field.request_rebuild()
	if is_instance_valid(_backdrop):
		_backdrop.queue_redraw()
	_add_effect("destroy", position, Art.MUSTARD, 0.24, 90.0)
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


func _shock_breach_damage(opening_damage: float) -> float:
	return opening_damage * 0.45 * run_build.level_of(&"shock_breach")


func _player_projectile_contact(
	projectile: ProjectileState,
	from: Vector2,
	to: Vector2,
	projectile_radius: float,
	candidates: Array[EnemyState]
) -> Variant:
	var best: EnemyState
	var best_distance := INF
	for enemy in candidates:
		var distance_to_segment := Rules.point_segment_distance(enemy.pos, from, to)
		if (
			enemy.role == &"interceptor_tower"
			and enemy.intercept_charges > 0
			and distance_to_segment <= 112.0 + projectile.radius
		):
			enemy.intercept_charges -= 1
			enemy.intercept_recharge = 4.0
			_add_effect("shock", enemy.pos, Rules.VIOLET, 0.24, 112.0)
			return true
		if distance_to_segment > enemy.radius + projectile_radius:
			continue
		var distance := from.distance_squared_to(enemy.pos)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _segment_hits_live_crate(from: Vector2, to: Vector2, padding: float) -> bool:
	return _first_live_crate_hit(from, to, padding) != null


func _first_live_crate_hit(from: Vector2, to: Vector2, padding: float) -> Variant:
	var clearance := CRATE_COLLISION_RADIUS + padding
	var minimum := Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2.ONE * clearance
	var maximum := Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2.ONE * clearance
	var min_cell := Vector2i(floori(minimum.x / CRATE_COLLISION_CELL_SIZE), floori(minimum.y / CRATE_COLLISION_CELL_SIZE))
	var max_cell := Vector2i(floori(maximum.x / CRATE_COLLISION_CELL_SIZE), floori(maximum.y / CRATE_COLLISION_CELL_SIZE))
	var best_t := INF
	var best_crate: Variant = null
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
				if hit_t < best_t:
					best_t = hit_t
					best_crate = crate
	return best_crate


func _projectile_hits_crate(
	projectile: ProjectileState,
	from: Vector2,
	to: Vector2,
	damage_crate: bool
) -> bool:
	var crate_hit: Variant = _first_live_crate_hit(from, to, projectile.radius)
	if crate_hit == null:
		return false
	var crate_position := Vector2(crate_hit["pos"])
	var motion := to - from
	var hit_t := AttackContract.segment_circle_first_t(
		from,
		to,
		crate_position,
		CRATE_COLLISION_RADIUS + projectile.radius
	)
	if damage_crate:
		_damage_crate(crate_hit, projectile.structure_damage)
	_add_effect(
		"impact",
		from + motion * hit_t if hit_t != INF else crate_position,
		projectile.color,
		0.16,
		22.0
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
	})
	_add_effect("destroy", Vector2(crate["pos"]), Rules.AMBER, 0.42, 58.0)
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
				_damage_enemy(enemy, 18.0, "Ion Wake", 12.0)


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


func _add_effect(kind: String, position: Vector2, color: Color, duration: float, radius: float, direction: Vector2 = Vector2.ZERO) -> void:
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
	})


func _swap_remove_dictionary(collection: Array[Dictionary], index: int) -> void:
	var last_index := collection.size() - 1
	if index < 0 or index > last_index:
		return
	if index != last_index:
		collection[index] = collection[last_index]
	collection.pop_back()


func _damage_enemy(enemy: EnemyState, amount: float, source: String, stagger: float = 0.0) -> float:
	if not enemy.alive:
		return 0.0
	var role := enemy.role
	if role == &"boss_pylon" and enemy.requires_reflection and not source.begins_with("reflected_"):
		enemy.health_visible_timer = 1.5
		_add_effect("barrier_hit", enemy.pos, Art.MINT, 0.20, enemy.radius * 1.25)
		return 0.0
	if (
		terrain_runtime.overdrive_active
		and _is_player_owned_damage_source(source)
		and not _is_structure_role(role)
	):
		amount *= 1.20
	if cycle_runtime.is_active(&"overclock_cycle"):
		amount *= 1.35 if cycle_runtime.level(&"overclock_cycle") >= 2 else 1.25
	var multiplier := 1.0
	if enemy.shielded:
		multiplier *= 0.45
	if enemy.shear_time > 0.0:
		multiplier *= 1.20
	if enemy.breach_exposed > 0.0:
		multiplier *= 1.20 + 0.05 * run_build.level_of(&"breach_round")
	if role == &"rammer" and enemy.vulnerable > 0.0:
		multiplier *= 1.50
	if role == &"stage_boss":
		if _boss_has_live_pylons():
			multiplier *= 0.28
		if enemy.vulnerable > 0.0:
			multiplier *= 1.55
	var health_before := enemy.health
	if (
		role == &"mine"
		and source != "Arc Surge"
		and amount * multiplier >= health_before
	):
		var mine_applied := maxf(0.0, health_before - 1.0)
		enemy.health = 1.0
		enemy.flash = 0.11
		enemy.health_visible_timer = 1.5
		_arm_mine(enemy, 0.75, true)
		return mine_applied
	var applied_damage := minf(health_before, maxf(0.0, amount * multiplier))
	enemy.health = health_before - applied_damage
	enemy.flash = 0.11
	enemy.health_visible_timer = 1.0 if enemy.health_class == &"swarm" else 1.5
	_apply_lifesteal(applied_damage, source, role)
	if enemy.health <= 0.0:
		_defeat_enemy(enemy, source)
	return applied_damage


func _is_player_owned_damage_source(source: String) -> bool:
	return source not in ["Arc Surge", "enemy_mine", "validation"]


func _is_structure_role(role: StringName) -> bool:
	return role in [
		&"generator", &"turret", &"mine", &"boss_pylon",
		&"interceptor_tower", &"beam_sentinel",
	]


func _apply_lifesteal(applied_damage: float, source: String, _role: StringName) -> void:
	if applied_damage <= 0.0 or not run_build.has(&"siphon_matrix") or lifesteal_budget <= 0.0:
		return
	if source == "validation" or source.begins_with("reflected_"):
		return
	var ratio := 0.035 if run_build.level_of(&"siphon_matrix") >= 2 else 0.02
	var healing := minf(minf(applied_damage * ratio, lifesteal_budget), _player_max_health() - player_health)
	if healing <= 0.0:
		return
	player_health += healing
	lifesteal_budget -= healing
	_add_effect("lifesteal", player_position, Art.MINT, 0.18, 46.0)


func _defeat_enemy(enemy: EnemyState, source: String) -> void:
	if not enemy.alive:
		return
	if boss_practice.active:
		enemy.alive = false
		enemy.active = false
		enemy_store.queue_defeat(enemy)
		_add_effect("destroy", enemy.pos, _enemy_color(enemy.role), 0.38, enemy.radius * 1.8)
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
	enemy_store.queue_defeat(enemy)
	stats_enemies_defeated += 1
	var role := enemy.role
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
	_add_effect("destroy", enemy.pos, _enemy_color(role), 0.65 if role in [&"stage_boss"] else 0.38, enemy.radius * 1.8)
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
		mini(12 - existing, 72 - _active_mobile_count())
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
	_add_effect("group_clear", position, Art.MINT, 0.28, 44.0)


func _clear_zones_owned_by_defeated_role(role: StringName) -> void:
	if role in [&"stage_boss", &"boss_pylon"]:
		for index in range(denied_zones.size() - 1, -1, -1):
			if String(denied_zones[index]["source"]).contains("Colossus"):
				denied_zones.remove_at(index)


func _damage_player(amount: float, source: String, blockable: bool, enemy_source: bool = true, final_effective: bool = false) -> void:
	if mode != RunMode.PLAYING or player_invulnerable > 0.0 or stage_complete:
		return
	var remaining := _scaled_incoming_damage(amount, enemy_source, final_effective)
	if player_barrier_strength > 0.0 and player_barrier_timer > 0.0:
		var absorbed := minf(player_barrier_strength, remaining)
		player_barrier_strength -= absorbed
		remaining -= absorbed
		_add_effect("barrier_hit", player_position, Rules.CYAN, 0.20, 70.0)
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
	player_hit_flash = PLAYER_HIT_FLASH_DURATION
	player_invulnerable = maxf(player_invulnerable, PLAYER_HIT_INVULNERABILITY)
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
	mode = RunMode.GARAGE
	_clear_projectiles()
	denied_zones.clear()
	_ui.notify(tr("NOTIFY_HULL_DISABLED"), 3.0, Rules.CORAL)
	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": persistent_clear_count,
		"relay_module_unlocked": persistent_relay_module,
		"field_module_unlocked": persistent_field_module,
	})
	_set_mouse_for_mode()


func _apply_dash_collision() -> void:
	if player_dash_timer <= 0.0:
		return
	enemy_grid.query_radius_into(player_position, Rules.PLAYER_RADIUS + 96.0, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if enemy.ram_cooldown > 0.0:
			continue
		if player_position.distance_to(enemy.pos) <= Rules.PLAYER_RADIUS + enemy.radius + 5.0:
			enemy.ram_cooldown = 0.35
			_damage_enemy(enemy, 16.0, "Dash impact", 18.0)
			var push := (enemy.pos - player_position).normalized()
			enemy.pos = _move_actor(enemy.pos, push * 45.0, enemy.radius, false)
			_add_effect("impact", enemy.pos, Rules.AMBER, 0.20, 34.0)


func _repel_nearby_enemies(radius: float) -> void:
	enemy_grid.query_radius_into(player_position, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		var distance := player_position.distance_to(enemy.pos)
		if distance <= radius and distance > 0.1:
			var push := (enemy.pos - player_position).normalized() * 95.0
			enemy.pos = _move_actor(enemy.pos, push, enemy.radius, false)
			enemy.stun = maxf(enemy.stun, 0.75)


func _damage_enemies_in_radius(center: Vector2, radius: float, damage: float, stagger: float, source: String, excluded_id: String = "") -> void:
	enemy_grid.query_radius_into(center, radius, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		if enemy.id == excluded_id:
			continue
		if enemy.pos.distance_to(center) <= radius + enemy.radius:
			_damage_enemy(enemy, damage, source, stagger)


func _clear_hostile_projectiles(center: Vector2, radius: float) -> int:
	return projectile_store.clear_hostiles_in_radius(center, radius)


func _update_aim_target() -> void:
	var ray_end := player_position + player_aim_direction * 900.0
	var best_id := ""
	var best_projection := INF
	enemy_grid.query_segment_into(player_position, ray_end, 110.0, enemies, _enemy_query_buffer)
	for enemy in _enemy_query_buffer:
		var enemy_position := enemy.pos
		if Rules.point_segment_distance(enemy_position, player_position, ray_end) > enemy.radius + 22.0:
			continue
		var projection := (enemy_position - player_position).dot(player_aim_direction)
		if projection < 0.0 or projection > 900.0:
			continue
		if not _runtime_has_line_of_sight(player_position, enemy_position, 5.0):
			continue
		if projection < best_projection:
			best_projection = projection
			best_id = enemy.id
	_aim_target_id = best_id


func _update_stage_progression(delta: float = 0.0) -> void:
	if stage_flow.state == StageFlow.State.BOSS_WARNING and stage_flow.tick(delta):
		_start_stage_boss()


func _trigger_contains(trigger: Variant, point: Vector2) -> bool:
	if trigger is Rect2:
		return Rect2(trigger).has_point(point)
	if trigger is Array:
		for region in trigger:
			if region is Rect2 and Rect2(region).has_point(point):
				return true
	return false


func _open_upgrade_reward(source_id: StringName, optional: bool) -> void:
	if mode != RunMode.PLAYING or (source_id != &"level_up" and _reward_claimed(source_id)):
		return
	mode = RunMode.UPGRADE
	current_reward_source = source_id
	current_reward_optional = optional
	current_card_offer = _build_card_offer(source_id)
	_ui.show_upgrade(current_card_offer, optional)
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
	if upgrade_id == &"twin_seekers":
		player_passive_cooldown = 0.0
	if upgrade_id == &"reinforced_hull":
		player_health = minf(_player_max_health(), player_health + 15.0)
	_status_profile = StatusProfile.from_build(run_build)
	_sync_cycle_upgrades()
	player_primary_weapon.set_full_opening_seconds(_opening_charge_seconds())
	_hud_presenter.mark_guidebook_dirty()
	return true


func _reward_transaction_id(source_id: StringName) -> StringName:
	return StringName("%s:%s" % [String(current_stage_id), String(source_id)])


func _reward_claimed(source_id: StringName) -> bool:
	return claimed_reward_sources.has(_reward_transaction_id(source_id))


func _resolve_reward_transaction() -> void:
	if current_reward_source == &"":
		return
	if current_reward_source == &"level_up":
		experience_runtime.consume_pending_level()
	else:
		claimed_reward_sources[_reward_transaction_id(current_reward_source)] = &"claimed"
	encounter_runtime.record_reward()
	current_reward_source = &""
	current_reward_optional = false
	current_card_offer.clear()


func _advance_reward_queue() -> void:
	if mode != RunMode.PLAYING:
		return
	if experience_runtime.pending_level_ups > 0:
		_open_upgrade_reward(&"level_up", false)
		return
	if not pending_reward_sources.is_empty():
		var source: StringName = pending_reward_sources.pop_front()
		_open_upgrade_reward(source, false)
		return
	if pending_stage_completion and _reward_claimed(&"boss"):
		_finalize_stage_completion()


func _build_card_offer(source_id: StringName) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for definition in upgrade_catalog.offer(run_build, run_index, current_stage_index, source_id):
		var value_previews: Array[Dictionary] = []
		var current_level := run_build.level_of(definition.id)
		for modifier in definition.modifiers:
			value_previews.append({
				"stat_key": "UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
				"operation": modifier.operation,
				"current": modifier.value_at(current_level),
				"next": modifier.value_at(current_level + 1),
			})
		cards.append({
			"id": definition.id,
			"title_key": definition.title_key,
			"description_key": definition.description_key,
			"family_key": "UPGRADE_FAMILY_%s" % String(definition.family).to_upper(),
			"current_level": current_level,
			"next_level": current_level + 1,
			"max_level": definition.max_level,
			"value_previews": value_previews,
		})
	return cards


func _start_stage_boss() -> void:
	if boss_started or not stage_flow.boss_entry_ready():
		return
	boss_started = true
	discovered_markers["stage_boss"] = true
	if boss_arrival_position.is_zero_approx():
		boss_arrival_position = _choose_boss_arrival_anchor()
	var boss := _make_enemy({
		"id": "stage_boss",
		"role": "stage_boss",
		"pos": boss_arrival_position,
		"zone": "boss",
		"name_key": StageCatalog.profile(current_stage_id)["boss_name_key"],
		"boss_variant": [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"][current_stage_index],
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
	if current_stage_index == StageCatalog.STAGE_IDS.size() - 1:
		_spawn_boss_pylons()
	_play_sound(&"boss")
	camera_shake = 12.0


func _choose_boss_arrival_anchor() -> Vector2:
	var anchors := (
		field_layout.boss_arrival_anchors
		if field_layout != null
		else StageCatalog.boss_arrival_anchors(current_stage_id)
	)
	var candidates: Array[Vector2] = []
	var excluded_view := _visible_world_rect(240.0)
	for anchor in anchors:
		var distance := player_position.distance_to(anchor)
		if (
			distance >= 900.0
			and distance <= 1500.0
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
		var a_distance := absf(player_position.distance_to(a) - 1200.0)
		var b_distance := absf(player_position.distance_to(b) - 1200.0)
		if not is_equal_approx(a_distance, b_distance):
			return a_distance < b_distance
		return int(a.x + a.y + run_index * 31 + current_stage_index * 17) < int(b.x + b.y + run_index * 31 + current_stage_index * 17)
	)
	return candidates[0] if not candidates.is_empty() else Rules.player_start(current_stage_id)


func _update_stage_boss(boss: EnemyState, delta: float) -> void:
	if not bool(boss.alive):
		return
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
	if boss_runtime.update_phase_transition(boss):
		boss_phase_two_announced = true
		_ui.notify(tr("NOTIFY_COLOSSUS_PHASE_TWO"), 3.4, Rules.VIOLET)
		_play_sound(&"boss", 0.78)
	if not boss_practice.is_pattern_loop():
		for event in boss_runtime.advance_autonomous(delta, boss, player_position):
			_execute_boss_autonomous(event)

	var phase := String(boss.phase)
	if phase == "boss_interrupted_recovery":
		boss.phase_time = maxf(0.0, boss.phase_time - delta)
		if boss.phase_time <= 0.0:
			boss_runtime.finish_interrupted_recovery(boss)
		return
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
		Callable(self, "_runtime_attack_path_end"),
		Callable(self, "_runtime_charge_path_end")
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
			true
		)


func _execute_boss_autonomous(event: Dictionary) -> void:
	var pattern := String(event["pattern"])
	if pattern == "overload_pylons":
		_spawn_boss_pylons()
		return
	if pattern == "beam_sentinel_call":
		var sentinel := _make_enemy({
			"id":String(event["id"]),
			"role":&"beam_sentinel",
			"pos":_move_actor(Vector2(event["target"]), Vector2.ZERO, 34.0, false),
			"active":true,
			"summoned":true,
			"zone":"boss_system",
		})
		if _append_enemy(sentinel):
			_add_effect("spawn", sentinel.pos, Art.ATTACK_ARC, 0.55, 76.0)
		return
	if pattern == "switchyard_mines":
		for index in 4:
			var direction := Vector2.RIGHT.rotated(TAU * float(index) / 4.0)
			var mine := _make_enemy({
				"id":"%s_mine_%d" % [String(event["id"]), index],
				"role":&"mine",
				"pos":_move_actor(
					Vector2(event["target"]),
					direction * 150.0,
					27.0,
					false
				),
				"active":true,
				"summoned":true,
				"zone":"boss_system",
			})
			if _append_enemy(mine):
				_add_effect("spawn", mine.pos, Art.ATTACK_ARC, 0.45, 58.0)
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
		(
			direction * float(boss.speed) * speed_scale
			+ terrain_runtime.flow_vector_at(position, true)
		) * delta,
		float(boss.radius),
		false
	)
	boss.velocity = (Vector2(boss.pos) - position) / maxf(delta, 0.0001)


func _spawn_boss_pylons() -> void:
	var positions: Array[Vector2] = []
	var reflection_required := false
	var boss := _find_enemy_by_id("stage_boss")
	var boss_position := boss.pos if boss != null else boss_arrival_position
	for offset in [Vector2(-210.0, -160.0), Vector2(-210.0, 160.0)]:
		var candidate: Vector2 = boss_position + Vector2(offset).rotated(float(current_stage_index) * 0.47)
		if Rules.is_position_walkable(candidate, 34.0, current_stage_id):
			positions.append(candidate)
	for position in positions:
		var existing := false
		for enemy in enemies:
			if bool(enemy.alive) and StringName(enemy.role) == &"boss_pylon" and Vector2(enemy.pos).distance_to(position) < 40.0:
				existing = true
				break
		if existing:
			continue
		var pylon := _make_enemy({
			"id": "boss_pylon_%d_%d" % [roundi(position.x), roundi(position.y)],
			"role": "boss_pylon",
			"pos": position,
			"zone": "boss",
			"name_key": "ENEMY_CROWN_RELAY" if reflection_required else "ENEMY_COLOSSUS_PYLON",
			"requires_reflection": reflection_required,
		})
		if pylon == null:
			continue
		pylon.active = true
		if _append_enemy(pylon):
			_add_effect("spawn", position, Rules.VIOLET, 0.55, 78.0)
	_ui.notify(tr("NOTIFY_CROWN_RELAYS") if reflection_required else tr("NOTIFY_COLOSSUS_PYLONS"), 2.8, Rules.VIOLET)


func _boss_has_live_pylons() -> bool:
	for enemy in enemies:
		if bool(enemy.alive) and StringName(enemy.role) == &"boss_pylon":
			return true
	return false


func _complete_stage() -> void:
	if stage_complete or pending_stage_completion:
		return
	pending_stage_completion = true
	encounter_runtime.stop_spawning()
	for enemy in enemies:
		if enemy.alive:
			enemy.alive = false
			enemy.active = false
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
	stage_flow.record_rewards_complete()
	var has_next_stage := current_stage_index < StageCatalog.STAGE_IDS.size() - 1
	if has_next_stage:
		_advance_stage()
		return
	else:
		persistent_clear_count += 1
		persistent_relay_module = true
		_save_persistence()
	_clear_projectiles()
	denied_zones.clear()
	mode = RunMode.RESULT
	var profile := StageCatalog.profile(current_stage_id)
	var next_profile := StageCatalog.profile(StageCatalog.STAGE_IDS[current_stage_index + 1]) if has_next_stage else {}
	_ui.show_result({
		"stage_number": int(profile["number"]),
		"stage_title_key": String(profile["title_key"]),
		"has_next_stage": has_next_stage,
		"next_stage_key": String(next_profile.get("title_key", "")),
		"time": _format_time(run_time),
		"health_ratio": player_health / _player_max_health(),
		"upgrade": selected_upgrade_title_key,
		"primary_hits": stats_primary_hits,
		"dash_uses": stats_dash_uses,
		"installations": stats_installations,
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

	var dash_state := tr("STATE_READY") if player_dash_cooldown <= 0.0 else "%.1fs" % player_dash_cooldown
	var passive_state := tr("STATE_READY") if player_passive_cooldown <= 0.0 else "%.1fs" % player_passive_cooldown
	var skill_state := tr("STATE_STARTUP") if player_emp_startup > 0.0 else (tr("STATE_READY") if player_emp_cooldown <= 0.0 else "%.1fs" % player_emp_cooldown)
	var primary_snapshot := player_primary_weapon.snapshot()
	var primary_ratio := float(primary_snapshot["charge_ratio"])
	var primary_state_key := "STATE_PRIMARY_IDLE"
	match StringName(primary_snapshot["tier"]):
		&"firing":
			primary_state_key = "STATE_PRIMARY_FIRING"
		&"charging":
			primary_state_key = "STATE_PRIMARY_CHARGING"
		&"ready":
			primary_state_key = "STATE_PRIMARY_OPENING_READY"
	var primary_state := tr(primary_state_key).replace("%d", str(roundi(primary_ratio * 100.0)))
	var primary_name := tr("PRIMARY_PULSE_CANNON")

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
		boss_snapshot = {
			"visible": true,
			"name": tr("ENEMY_BOSS_PHASE") % [tr(String(boss.name)), int(boss.boss_phase)],
			"health": float(boss.health),
			"max_health": float(boss.max_health),
			"state": _boss_state_text(boss),
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
		"primary_name": primary_name,
		"primary_state": primary_state,
		"primary_ratio": primary_ratio,
		"dash_state": dash_state,
		"dash_ratio": clampf(player_dash_cooldown / _dash_cooldown_max(), 0.0, 1.0),
		"passive_state": passive_state,
		"passive_ratio": clampf(player_passive_cooldown / PASSIVE_COOLDOWN, 0.0, 1.0),
		"skill_state": skill_state,
		"skill_ratio": clampf(player_emp_cooldown / _emp_cooldown_max(), 0.0, 1.0),
		"buff_text": "",
		"target": target_snapshot,
		"boss": boss_snapshot,
	}
	if include_world_channels:
		snapshot["minimap"] = _minimap_snapshot(true)
		snapshot["threat_radar"] = _threat_radar_snapshot()
		snapshot["status_orbit"] = _status_orbit_snapshot()
	if include_guidebook:
		snapshot["guidebook"] = _guidebook_snapshot()
	return snapshot


func _build_fast_hud_snapshot() -> Dictionary:
	return _build_hud_snapshot(false, false)


func _guidebook_snapshot() -> Dictionary:
	var store := get_node_or_null("/root/VehicleGuidebookStore")
	if store == null:
		return {}
	var experience := experience_runtime.snapshot()
	var upgrades: Array[Dictionary] = []
	for upgrade_id in run_build.levels.keys():
		var definition := upgrade_catalog.get_definition(StringName(upgrade_id))
		if definition != null:
			upgrades.append({"id":StringName(upgrade_id), "title_key":definition.title_key, "level":run_build.level_of(StringName(upgrade_id))})
	return store.snapshot({
		"health":player_health, "max_health":_player_max_health(),
		"level":int(experience["level"]), "experience":int(experience["experience"]),
		"experience_required":int(experience["required"]),
		"base_speed":PLAYER_BASE_SPEED, "current_speed":_player_move_speed(),
		"secondaries":secondary_runtime.equipped_families(run_build), "upgrades":upgrades,
	})


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
		return [tr("OBJECTIVE_BOSS_STAGE").replace("%s", boss_name), tr("OBJECTIVE_BOSS_DETAIL")]
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
	var pattern := _localized_pattern(String(boss.pattern))
	var base_state := pattern
	if _boss_has_live_pylons():
		base_state = tr("BOSS_STATE_PYLON_SHIELD") % pattern
	elif float(boss.vulnerable) > 0.0:
		base_state = tr("BOSS_STATE_DAMAGE_WINDOW") % pattern
	var parts: Array[String] = [base_state]
	parts.append_array(_localized_status_parts(boss))
	return "  •  ".join(parts)


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


func _localized_pattern(pattern: String) -> String:
	var key: String = {
		"lane_barrage": "PATTERN_LANE_BARRAGE",
		"charge": "PATTERN_CHARGE",
		"pylons": "PATTERN_PYLONS",
		"overload_combo": "PATTERN_OVERLOAD_COMBO",
		"fan": "PATTERN_FAN",
		"system_wake": "PATTERN_SYSTEM_WAKE",
		"phase_two": "PATTERN_PHASE_TWO",
		"recovering_control": "PATTERN_RECOVERING_CONTROL",
		"reading_arena": "PATTERN_READING_ARENA",
		"recovery_window": "PATTERN_RECOVERY_WINDOW",
		"twin_foundry_lanes": "PATTERN_TWIN_FOUNDRY_LANES",
		"foundry_ram": "PATTERN_FOUNDRY_RAM",
		"furnace_ring": "PATTERN_FURNACE_RING",
		"furnace_gates": "PATTERN_FURNACE_GATES",
		"foundry_burst": "PATTERN_FOUNDRY_BURST",
		"slag_ring": "PATTERN_SLAG_RING",
		"overload_pylons": "PATTERN_OVERLOAD_PYLONS",
		"pylon_overload": "PATTERN_PYLON_OVERLOAD",
		"current_fan": "PATTERN_CURRENT_FAN",
		"archive_lunge": "PATTERN_ARCHIVE_LUNGE",
		"archive_cross": "PATTERN_ARCHIVE_CROSS",
		"archive_depth": "PATTERN_ARCHIVE_DEPTH",
		"undertow_lanes": "PATTERN_UNDERTOW_LANES",
		"depth_charges": "PATTERN_DEPTH_CHARGES",
		"undertow_sweep": "PATTERN_UNDERTOW_SWEEP",
		"depth_charge": "PATTERN_DEPTH_CHARGE",
		"archive_ram": "PATTERN_ARCHIVE_RAM",
		"arc_lanes": "PATTERN_ARC_LANES",
		"grounded_ring": "PATTERN_GROUNDED_RING",
		"thunder_drop": "PATTERN_THUNDER_DROP",
		"grounding_grid": "PATTERN_GROUNDING_GRID",
		"titan_pulse": "PATTERN_TITAN_PULSE",
		"titan_burst": "PATTERN_TITAN_BURST",
		"titan_ram": "PATTERN_TITAN_RAM",
		"thunder_chain": "PATTERN_THUNDER_CHAIN",
		"beam_sentinel_call": "PATTERN_BEAM_SENTINEL_CALL",
		"escort_surge": "PATTERN_ESCORT_SURGE",
		"open_lane_charge": "PATTERN_OPEN_LANE_CHARGE",
		"breaker_charge": "PATTERN_BREAKER_CHARGE",
		"gate_shockwave": "PATTERN_GATE_SHOCKWAVE",
		"ricochet_volley": "PATTERN_RICOCHET_VOLLEY",
		"switch_sweep": "PATTERN_SWITCH_SWEEP",
		"switchyard_mines": "PATTERN_SWITCHYARD_MINES",
		"switch_sweeps": "PATTERN_SWITCH_SWEEPS",
		"crown_beam": "PATTERN_CROWN_BEAM",
		"mirror_cross": "PATTERN_MIRROR_CROSS",
		"carrier_wave": "PATTERN_CARRIER_WAVE",
		"relay_pulse": "PATTERN_RELAY_PULSE",
		"crown_burst": "PATTERN_CROWN_BURST",
		"crown_lattice": "PATTERN_CROWN_LATTICE",
		"relay_pulse_rings": "PATTERN_RELAY_PULSE_RINGS",
		"signature_interrupted": "PATTERN_SIGNATURE_INTERRUPTED",
		"phase_transition": "PATTERN_PHASE_TRANSITION",
	}.get(pattern, pattern)
	return tr(String(key))


func _minimap_snapshot(include_static_geometry: bool = true) -> Dictionary:
	var visited: Array[Vector2i] = []
	for cell in visited_cells.keys():
		visited.append(cell)
	var markers: Array[Dictionary] = []
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		markers.append({
			"kind":"boss", "position":boss_arrival_position,
			"color":Rules.CORAL, "discovered":true,
			"variant":[&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"][current_stage_index],
		})
	var stage_boss := _find_enemy_by_id("stage_boss")
	if stage_boss != null and stage_boss.alive:
		markers.append({
			"kind":"boss", "position":stage_boss.pos, "color":Rules.CORAL,
			"discovered":true, "variant":stage_boss.boss_variant,
		})
	for enemy in enemies:
		if (
			enemy.alive
			and enemy.active
			and not enemy.elite_trait.is_empty()
			and _is_world_position_visited(enemy.pos)
		):
			markers.append({
				"kind":"elite",
				"position":enemy.pos,
				"color":Rules.CORAL,
				"discovered":true,
			})
	for pickup in pickups:
		if bool(pickup["active"]) and _is_world_position_visited(Vector2(pickup["pos"])):
			markers.append({
				"kind": "reward",
				"position": Vector2(pickup["pos"]),
				"color": _pickup_color(StringName(pickup["kind"])),
				"discovered": true,
			})
	var snapshot := {
		"cols": MINIMAP_COLS,
		"rows": MINIMAP_ROWS,
		"visited": visited,
		"player": player_position,
		"world_size": Rules.world_rect(current_stage_id).size,
		"markers": markers,
	}
	if include_static_geometry:
		var blocker_polygons: Array = Rules.get_cover_polygons(false, current_stage_id).duplicate()
		for rect in _runtime_cover_rects():
			blocker_polygons.append(StageGeometry.rect_polygon(rect))
		snapshot["floor_polygons"] = StageCatalog.floor_polygons(current_stage_id)
		snapshot["water_polygons"] = StageCatalog.water_polygons(current_stage_id)
		snapshot["blocker_polygons"] = blocker_polygons
	return snapshot


func _status_orbit_snapshot() -> Dictionary:
	return {
		"center": get_canvas_transform() * player_position,
		"states": cycle_runtime.hud_states(),
		"reduced_motion": _reduced_motion_enabled(),
	}


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
		"player_hit": player_hit_flash > 0.0,
		"player_hit_remaining": player_hit_flash,
		"player_invulnerable_remaining": player_invulnerable,
		"muzzle_flash": player_muzzle_flash,
		"barrier_strength": player_barrier_strength,
		"reduced_motion": _reduced_motion_enabled(),
		"run_time": run_time,
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
	for enemy in enemies:
		if not bool(enemy.alive) or not bool(enemy.active):
			continue
		var enemy_screen := canvas_transform * Vector2(enemy.pos)
		if safe_viewport.has_point(enemy_screen):
			_discover_guide(GuidebookCatalog.entry_id_for_enemy(enemy.archetype, enemy.role))
		var offset := Vector2(enemy.pos) - player_position
		if offset.length_squared() > THREAT_SCAN_DISTANCE * THREAT_SCAN_DISTANCE:
			continue
		if safe_viewport.has_point(enemy_screen):
			continue
		var health_class := enemy.health_class
		contacts.append({
			"offset": offset,
			"priority": health_class in [&"priority", &"boss"],
			"targeted": String(enemy.id) == _aim_target_id,
		})
	if stage_flow.state == StageFlow.State.BOSS_WARNING:
		contacts.append({"offset":boss_arrival_position - player_position, "priority":true, "targeted":false})
	_threat_contact_cache = contacts


func _threat_radar_snapshot() -> Dictionary:
	return {
		"visible": mode == RunMode.PLAYING,
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
			&"flow_channel":
				var rectangle := Rect2(feature["rect"])
				draw_rect(rectangle, Color(Art.MINT, 0.30))
				var vector := Vector2(feature["vector"]).normalized()
				for index in 3:
					var center := rectangle.position + rectangle.size * Vector2(
						0.25 + float(index) * 0.25, 0.5
					)
					var side := vector.rotated(PI * 0.5)
					draw_polyline(PackedVector2Array([
						center - vector * 34.0 + side * 26.0,
						center + vector * 10.0,
						center - vector * 34.0 - side * 26.0,
					]), Art.IVORY_BRIGHT, 14.0, true)
			&"arc_surge":
				var rectangle := Rect2(feature["rect"])
				var readiness := float(feature.get("readiness", 0.0))
				var color := Art.ATTACK_ARC
				draw_rect(rectangle, Color(color, 0.12 + readiness * 0.38))
				draw_rect(rectangle, color, false, 12.0)
			&"breakable_bulkhead":
				if float(feature.get("health", 0.0)) <= 0.0:
					continue
				var rectangle := Rect2(feature["rect"])
				draw_rect(Rect2(rectangle.position + Art.WALL_SHADOW_OFFSET, rectangle.size), Art.WALL_SHADOW)
				draw_rect(rectangle, Art.WALL_FILL)
				var center := rectangle.get_center()
				draw_polyline(PackedVector2Array([
					center + Vector2(-34,-72), center + Vector2(8,-22),
					center + Vector2(-16,18), center + Vector2(36,72),
				]), Art.MUSTARD, 14.0, true)
			&"transit_gate":
				var center := Vector2(feature["pos"])
				var progress := clampf(float(feature.get("progress", 0.0)), 0.0, 1.0)
				var cooldown := float(feature.get("cooldown", 0.0))
				draw_circle(center, TerrainRuntime.GATE_RADIUS, Color(Art.CERAMIC_GREEN_MID, 0.72))
				draw_arc(center, TerrainRuntime.GATE_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Art.IVORY_BRIGHT, 14.0)
				if cooldown > 0.0:
					draw_arc(center, 72.0, 0.0, TAU * (1.0 - cooldown / TerrainRuntime.GATE_COOLDOWN), 32, Art.INK_MUTED, 10.0)
			&"repair_basin":
				var center := Vector2(feature["pos"])
				var budget_ratio := clampf(float(feature.get("budget", 0.0)) / TerrainRuntime.REPAIR_BUDGET, 0.0, 1.0)
				draw_circle(center, TerrainRuntime.REPAIR_RADIUS, Color(Art.MINT, 0.18))
				for index in 6:
					if float(index) / 6.0 >= budget_ratio:
						continue
					var start := -PI * 0.5 + TAU * float(index) / 6.0
					draw_arc(center, 118.0, start, start + TAU / 7.2, 12, Art.MINT, 18.0)
			&"overdrive_field":
				var center := Vector2(feature["pos"])
				var active := bool(feature.get("active", false))
				draw_circle(center, TerrainRuntime.OVERDRIVE_RADIUS, Color(Art.MUSTARD, 0.16 if not active else 0.32))
				draw_arc(center, TerrainRuntime.OVERDRIVE_RADIUS, 0.0, TAU, 48, Art.MUSTARD, 12.0)
				draw_circle(center, 42.0, Art.MUSTARD)


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
		var color := _pickup_color(kind)
		var bob := 0.0 if _reduced_motion_enabled() else sin(float(pickup["pulse"])) * 3.0
		position.y += bob
		var plinth_radius := Art.PICKUP_PLINTH_RADIUS
		draw_circle(position + Vector2(7.0, 9.0), plinth_radius, Art.COBALT_DEEP)
		draw_circle(position, plinth_radius, Art.IVORY_BRIGHT)
		draw_circle(position, plinth_radius - 8.0, Art.CERAMIC_GREEN_MID)
		match kind:
			&"repair":
				draw_rect(Rect2(position - Vector2(7.0, 22.0), Vector2(14.0, 44.0)), color)
				draw_rect(Rect2(position - Vector2(22.0, 7.0), Vector2(44.0, 14.0)), color)
			&"experience_recall":
				draw_arc(position, 22.0, -PI * 0.15, PI * 1.55, 20, color, 8.0)
				draw_colored_polygon(PackedVector2Array([
					position + Vector2(24.0, -11.0), position + Vector2(30.0, 9.0), position + Vector2(10.0, 3.0),
				]), color)
				draw_colored_polygon(_regular_polygon(position, 8.0, 4, PI / 4.0), Art.MUSTARD)
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		var position := Vector2(crate["pos"])
		var face := Art.IVORY_BRIGHT if float(crate["flash"]) > 0.0 else Art.IVORY_SHADE
		var crate_rect := Rect2(position - Vector2(38.0, 38.0), Vector2(76.0, 76.0))
		var edge := crate_rect
		edge.position += Vector2(8.0, 10.0)
		draw_colored_polygon(Art.stepped_rect(edge, 12.0), Art.MUSTARD_DARK)
		draw_colored_polygon(Art.stepped_rect(crate_rect, 12.0), face)
		draw_colored_polygon(_regular_polygon(position, 23.0, 4, PI / 4.0), Art.MUSTARD)
		draw_colored_polygon(_regular_polygon(position, 11.0, 4, PI / 4.0), Art.CERAMIC_GREEN)


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
			draw_line(position, repair_target.pos, Color(Art.MINT, 0.82), 14.0, true)
		_draw_enemy_marks(enemy, position, visual_radius)
	if enemy.vulnerable > 0.0:
		draw_arc(position, visual_radius + 12.0, 0.0, TAU, 28, Art.MUSTARD, 7.0)


func _draw_enemy_marks(enemy: EnemyState, position: Vector2, radius: float) -> void:
	if enemy.marked_time > 0.0:
		draw_arc(position, radius + 15.0, -PI * 0.3, PI * 1.3, 22, Art.MUSTARD, 6.0)
	if enemy.shear_time > 0.0:
		draw_arc(position, radius + 10.0, PI * 0.7, PI * 2.3, 22, Art.MINT, 6.0)


func _enemy_color(role: StringName) -> Color:
	match role:
		&"chaser", &"shooter", &"controller", &"mine", &"artillery_spotter", &"rammer":
			return Art.CORAL
		&"turret", &"interceptor_tower", &"beam_sentinel":
			return Art.CORAL_DARK
		&"generator", &"shield_escort", &"repair_tender", &"drone_carrier":
			return Art.MINT
		&"stage_boss", &"boss_pylon":
			return Art.BOSS_MAGENTA
	return Art.INK_MUTED


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
	var boss := _make_enemy({
		"id":"stage_boss",
		"role":&"stage_boss",
		"pos":_choose_boss_arrival_anchor(),
		"zone":"practice",
		"name_key":StageCatalog.profile(current_stage_id)["boss_name_key"],
		"boss_variant":[&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"][current_stage_index],
		"active":true,
	})
	boss.active = true
	boss.boss_phase = boss_practice.phase
	boss.health = boss.max_health * boss_practice.health_ratio()
	boss.phase = &"boss_read"
	boss.phase_time = 0.8
	boss.pattern = &"practice"
	_append_enemy(boss)
	boss_started = true
	stage_flow.state = StageFlow.State.BOSS_ACTIVE
	_ui.notify("PRACTICE", 1.5, Art.MUSTARD)
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
		"layout":field_layout.debug_snapshot() if field_layout != null else {},
	}


func _parse_capture_arguments() -> void:
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument in arguments:
		if argument.begins_with("--capture-all="):
			_capture_directory = argument.trim_prefix("--capture-all=")
			_capture_mode = true
		elif argument.begins_with("--capture-locale="):
			_capture_locale = argument.trim_prefix("--capture-locale=")
		elif argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2:
				_capture_size = Vector2i(maxi(640, int(parts[0])), maxi(360, int(parts[1])))
		elif argument.begins_with("--layout-seed="):
			_layout_seed_override = int(argument.trim_prefix("--layout-seed="))
			_has_layout_seed_override = true
		elif argument.begins_with("--field-id="):
			_field_id_override = StringName(argument.trim_prefix("--field-id="))
	if _capture_locale in ["ko", "en"]:
		TranslationServer.set_locale(_capture_locale)
	if _capture_mode:
		call_deferred("_run_capture_sequence")


func _run_capture_sequence() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_directory)
	if _capture_size.x > 0 and _capture_size.y > 0:
		get_window().size = _capture_size
	_camera.position_smoothing_enabled = false
	_ui.show_deployment(
		selected_primary,
		RunDifficulty.HARD,
		String(field_layout.field_definition["name_key"])
	)
	await get_tree().process_frame
	await get_tree().process_frame
	_save_capture("01-deployment.png")
	_ui.debug_modal_contract("settings")
	await _settle_capture()
	_save_capture("01b-shared-settings.png")
	_ui.debug_gameplay_settings_contract()
	await _settle_capture()
	_save_capture("01d-gameplay-settings.png")
	_ui.debug_modal_contract("guidebook")
	await _settle_capture()
	_save_capture("01c-guidebook.png")

	_capture_prepare_stage(0)
	await _settle_capture()
	_save_capture("02-safe-arrival.png")
	_update_encounter(5.1)
	await _settle_capture()
	_save_capture("02b-first-contact-cue.png")

	await _capture_pressure_evidence()
	await _capture_cycle_evidence()
	await _capture_field_item_evidence()
	await _capture_level_up_evidence()
	await _capture_boss_preview()
	await _capture_stage_map_evidence()
	if _capture_full_evidence():
		await _capture_damage_feedback_evidence()
		await _capture_collision_overlay_evidence()
		await _capture_all_boss_evidence()

	_capture_prepare_stage(0, true)
	mode = RunMode.PAUSED
	_ui.show_pause()
	await _settle_capture()
	_save_capture("90-pause.png")

	mode = RunMode.RESULT
	_ui.show_result({
		"stage_number": 1, "stage_title_key": "STAGE_DROWNED_RUINS_1",
		"has_next_stage": true, "next_stage_key": "STAGE_DROWNED_RUINS_2",
		"time": "4:18", "health_ratio": 0.76, "upgrade": "UPGRADE_ION_WAKE_TITLE",
		"primary_hits": 42, "dash_uses": 11, "installations": 5,
	})
	await _settle_capture()
	_save_capture("91-stage-transition.png")

	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": 1,
		"relay_module_unlocked": true,
		"field_module_unlocked": true,
		"build_summary": _run_build_summary(),
	})
	await _settle_capture()
	_save_capture("92-garage.png")
	print("VEHICLE_STAGE_CAPTURE_COMPLETE dir=%s" % _capture_directory)
	get_tree().quit(0)


func _capture_prepare_stage(stage_index: int, preserve_upgrades: bool = false) -> void:
	current_stage_index = clampi(stage_index, 0, StageCatalog.STAGE_IDS.size() - 1)
	current_stage_id = StageCatalog.STAGE_IDS[current_stage_index]
	_reset_run(false, true, preserve_upgrades)
	mode = RunMode.PLAYING
	player_position = Rules.player_start(current_stage_id)
	player_invulnerable = 99.0
	_camera.zoom = Vector2.ONE
	_ui.show_gameplay()


func _capture_pressure_evidence() -> void:
	_capture_prepare_stage(0)
	_clear_enemies()
	var roles: Array[StringName] = [&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser", &"shooter", &"controller"]
	for index in EncounterDirector.ACTIVE_CAPS[-1]:
		var position := Vector2(
			2440.0 + float(index % 10) * 80.0,
			1320.0 + float(index / 10) * 108.0
		)
		var enemy := _make_enemy({"id":"capture_pressure_%02d" % index, "role":roles[index % roles.size()], "pos":position, "active":true})
		if enemy == null:
			break
		enemy.active = true
		enemy.health_visible_timer = 99.0 if index < 12 else 0.0
		enemy.committed_dir = (player_position - position).normalized()
		if index < 3:
			enemy.phase = "startup"
			enemy.committed_target = player_position
			AttackTelegraphs.refresh_ordinary(
				enemy,
				Callable(self, "_runtime_attack_path_end"),
				Callable(self, "_runtime_charge_path_end")
			)
		_append_enemy(enemy)
	experience_runtime.clear_shards()
	for index in ExperienceRuntime.MAX_SHARDS:
		var angle := TAU * float(index % 24) / 24.0
		var radius := 145.0 + float(index % 5) * 58.0
		var shard_position := player_position + Vector2.RIGHT.rotated(angle) * radius
		if index >= 72:
			shard_position = Vector2(580.0 + float(index % 20) * 34.0, 520.0 + float((index - 72) / 20) * 36.0)
		experience_runtime.spawn_shard(shard_position, 1 + int(index % 11 == 0) * 3)
	_update_threat_contacts(0.2)
	mode = RunMode.PAUSED
	await _settle_capture()
	_save_capture("03-maximum-pressure-xp.png")


func _capture_cycle_evidence() -> void:
	_capture_prepare_stage(0)
	_clear_enemies()
	for index in 4:
		var angle := -0.75 + float(index) * 0.5
		var position := player_position + Vector2.RIGHT.rotated(angle) * (260.0 + float(index) * 35.0)
		var role: StringName = &"controller" if index == 0 else &"chaser"
		var enemy := _make_enemy({"id":"capture_cycle_%d" % index, "role":role, "pos":position, "active":true})
		if enemy == null:
			break
		enemy.active = true
		enemy.health_visible_timer = 99.0
		_append_enemy(enemy)
	_aim_target_id = "capture_cycle_0"
	apply_upgrade(&"aegis_cycle")
	apply_upgrade(&"overclock_cycle")
	apply_upgrade(&"ion_field")
	_threat_contact_cache = [
		{"offset":Vector2(-760.0, -180.0), "priority":false, "targeted":false},
		{"offset":Vector2(820.0, 120.0), "priority":true, "targeted":true},
		{"offset":Vector2(120.0, -900.0), "priority":false, "targeted":false},
	]
	await _settle_capture()
	_save_capture("04-three-cycles-threat-radar.png")


func _capture_field_item_evidence() -> void:
	_capture_prepare_stage(0)
	_clear_enemies()
	crates.clear()
	pickups.clear()
	player_health = 64.0
	pickups.append({"id":"capture_repair", "kind":&"repair", "pos":player_position + Vector2(-150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":35.0})
	pickups.append({"id":"capture_recall", "kind":&"experience_recall", "pos":player_position + Vector2(150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":0.0})
	experience_runtime.clear_shards()
	experience_runtime.spawn_shard(player_position + Vector2(245.0, -90.0), 1)
	experience_runtime.spawn_shard(player_position + Vector2(300.0, 35.0), 4)
	experience_runtime.spawn_shard(player_position + Vector2(245.0, 150.0), 18)
	await _settle_capture()
	_save_capture("05-two-field-items.png")


func _capture_level_up_evidence() -> void:
	_capture_prepare_stage(0)
	experience_runtime.spawn_shard(player_position, experience_runtime.required_experience())
	_update_experience(0.0)
	await _settle_capture()
	_save_capture("06-level-up-choice.png")
	if current_card_offer.is_empty():
		return
	_ui.debug_select_upgrade(0)
	await _settle_capture()
	_save_capture("06b-level-up-selected.png")
	_on_upgrade_selected(StringName(current_card_offer[0]["id"]))
	await _settle_capture()
	_save_capture("06c-level-up-confirmed.png")


func _capture_boss_preview() -> void:
	var boss := _capture_prepare_boss(0)
	if boss == null:
		return
	_boss_select_pattern(boss)
	mode = RunMode.PAUSED
	await _settle_capture()
	_save_capture("07-stage-boss-startup.png")


func _capture_stage_map_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		_capture_prepare_stage(stage_index, true)
		mode = RunMode.PAUSED
		var bounds := Rules.world_rect(current_stage_id)
		player_position = bounds.get_center()
		_fit_camera_to_stage(bounds)
		await _settle_capture()
		_save_capture("10-map-%02d-%s.png" % [stage_index + 1, String(current_stage_id).replace("_", "-")])
	_camera.zoom = Vector2.ONE


func _capture_damage_feedback_evidence() -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	var original_reduced_motion := bool(settings.reduced_motion) if settings != null else false
	for reduced_motion in [false, true]:
		_capture_prepare_stage(0, true)
		_clear_enemies()
		if settings != null:
			settings.reduced_motion = reduced_motion
		player_health = _player_max_health()
		player_invulnerable = 0.0
		player_hit_flash = 0.0
		player_barrier_strength = 0.0
		player_barrier_timer = 0.0
		mode = RunMode.PLAYING
		_damage_player(34.0, "capture hull hit", false, false)
		if reduced_motion:
			player_hit_flash = 0.0
			player_invulnerable = 0.72
		mode = RunMode.PAUSED
		await _settle_capture()
		_save_capture(
			"08-player-hit-reduced-motion.png"
			if reduced_motion
			else "08-player-hit-standard.png"
		)

	_capture_prepare_stage(0, true)
	_clear_enemies()
	if settings != null:
		settings.reduced_motion = false
	player_health = _player_max_health()
	player_invulnerable = 0.0
	player_hit_flash = 0.0
	player_barrier_strength = 100.0
	player_barrier_timer = 1.0
	mode = RunMode.PLAYING
	_damage_player(34.0, "capture barrier hit", true, false)
	mode = RunMode.PAUSED
	await _settle_capture()
	_save_capture("08-player-barrier-only.png")
	if settings != null:
		settings.reduced_motion = original_reduced_motion


func _capture_collision_overlay_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		_capture_prepare_stage(stage_index, true)
		mode = RunMode.PAUSED
		var bounds := Rules.world_rect(current_stage_id)
		player_position = bounds.get_center()
		_fit_camera_to_stage(bounds)
		_debug_collision_overlay = true
		await _settle_capture()
		var stage_slug := String(current_stage_id).replace("_", "-")
		_save_capture("20-collision-%02d-%s-default.png" % [stage_index + 1, stage_slug])
		_debug_collision_overlay = false
	_camera.zoom = Vector2.ONE


func _capture_all_boss_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		var boss := _capture_prepare_boss(stage_index)
		if boss == null:
			continue
		var stage_slug := String(current_stage_id).replace("_", "-")
		_boss_select_pattern(boss)
		mode = RunMode.PAUSED
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
		_boss_begin_active(boss)
		_boss_update_active(boss, 0.05)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-active.png" % [stage_index + 1, stage_slug])

		_clear_projectiles()
		denied_zones.clear()
		boss.phase = "boss_recovery"
		boss.phase_time = BossPatterns.recovery_seconds(String(boss.pattern))
		boss.vulnerable = 1.55
		boss.last_pattern = boss.pattern
		boss.pattern = "recovery_window"
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-recovery.png" % [stage_index + 1, stage_slug])

		boss.health = float(boss.max_health) * 0.48
		boss.boss_phase = 2
		boss.pattern_index = 0
		_boss_select_pattern(boss)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-phase-two.png" % [stage_index + 1, stage_slug])
		if stage_index == 0:
			boss.pos = player_position + Vector2(920.0, 0.0)
			boss.phase = &"boss_startup"
			boss.phase_time = BossPatterns.startup_seconds("furnace_ring")
			boss.pattern = "furnace_ring"
			boss.committed_target = player_position
			boss.committed_dir = (player_position - Vector2(boss.pos)).normalized()
			AttackTelegraphs.refresh_boss(
				boss,
				"furnace_ring",
				Callable(self, "_runtime_attack_path_end"),
				Callable(self, "_runtime_charge_path_end")
			)
			_camera.position = player_position
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
			_boss_begin_active(boss)
			_boss_update_active(boss, 0.05)
			await _settle_capture()
			_save_capture(
				"30-boss-01-stage-1-offscreen-furnace-active.png"
			)


func _capture_prepare_boss(stage_index: int) -> EnemyState:
	_capture_prepare_stage(stage_index, true)
	_clear_enemies()
	_clear_projectiles()
	denied_zones.clear()
	player_position = Rules.player_start(current_stage_id)
	boss_arrival_position = (
		field_layout.boss_arrival_anchors[0]
		if field_layout != null
		else StageCatalog.boss_arrival_anchors(current_stage_id)[0]
	)
	stage_flow.defeats = stage_flow.quota
	stage_flow.state = StageFlow.State.BOSS_ACTIVE
	_start_stage_boss()
	var boss := _find_enemy_by_id("stage_boss")
	if boss == null:
		return null
	boss.pos = player_position + Vector2(240.0, -100.0)
	player_aim_direction = (Vector2(boss.pos) - player_position).normalized()
	return boss


func _fit_camera_to_stage(bounds: Rect2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y) * 0.86
	_camera.zoom = Vector2.ONE * fit
	_camera.position = bounds.get_center()


func _capture_full_evidence() -> bool:
	var width := _capture_size.x if _capture_size.x > 0 else roundi(get_viewport().get_visible_rect().size.x)
	return _capture_locale == "ko" and width == 1280


func _settle_capture() -> void:
	for frame in 4:
		await get_tree().process_frame


func _save_capture(file_name: String) -> void:
	var path := _capture_directory.path_join(file_name)
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save capture %s: %s" % [path, error_string(error)])
	else:
		print("CAPTURE_SAVED %s" % path)


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
