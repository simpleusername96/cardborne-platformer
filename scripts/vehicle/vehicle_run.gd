class_name VehicleRun
extends Node2D

## Runs the connected authored vehicle campaign and its combat state.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EncounterRuntime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const AudioDirector = preload("res://scripts/presentation/vehicle_audio_director.gd")
const StageBackdrop = preload("res://scripts/vehicle/vehicle_stage_backdrop.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const CycleRuntime = preload("res://scripts/cards/vehicle_cycle_runtime.gd")
const StageGeometry = preload("res://scripts/vehicle/vehicle_stage_geometry.gd")

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
const DASH_DURATION := 0.20
const DASH_SPEED := 1220.0
const DASH_COOLDOWN := 1.25
const PASSIVE_RANGE := 560.0
const PASSIVE_COOLDOWN := 1.35
const EMP_COOLDOWN := 13.0
const EMP_STARTUP := 0.42
const EMP_RADIUS := 285.0
const MINIMAP_COLS := 13
const MINIMAP_ROWS := 6
const THREAT_SCAN_DISTANCE := 1200.0
const THREAT_SAMPLE_INTERVAL := 0.10
const HUD_REFRESH_INTERVAL := 0.05

var mode := RunMode.DEPLOYMENT
var mode_before_pause := RunMode.PLAYING
var _ui: Variant
var _camera: Camera2D
var _backdrop
var _rng := RandomNumberGenerator.new()
var encounter_runtime := EncounterRuntime.new()

var player_position := Vector2.ZERO
var player_hull_direction := Vector2.RIGHT
var player_aim_direction := Vector2.RIGHT
var player_health := PLAYER_MAX_HEALTH
var player_invulnerable := 0.0
var player_hit_flash := 0.0
var player_primary_weapon := PrimaryWeapon.new()
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
var _last_damage_source := ""

var selected_primary := &"pulse_cannon"
var selected_upgrade_title_key := "UPGRADE_NONE"
var upgrade_catalog := UpgradeCatalog.new()
var run_build := RunBuild.new(upgrade_catalog)
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

var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var denied_zones: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var damaging_trails: Array[Dictionary] = []

var tutorial_move := false
var tutorial_aim := false
var tutorial_fire := false
var tutorial_dash := false
var tutorial_announced := false
var entered_approach := false
var entered_installations := false
var generators_destroyed := 0
var chest_claimed := false
var field_boss_defeated := false
var boss_started := false
var boss_locked := false
var boss_phase_two_announced := false
var stage_complete := false
var run_time := 0.0
var run_index := 0
var current_stage_index := 0
var current_stage_id: StringName = StageCatalog.STAGE_IDS[0]
var environment_time := 0.0
var environment_damage_tick := 0.0
var switchyard_gate_state := 0
var reflector_orientations: Dictionary = {}
var _mechanic_contact_latches: Dictionary = {}
var _stage_environment_zones: Array[Dictionary] = []
var _runtime_cover_cache: Array[Rect2] = []
var _objective_trigger_cache: Dictionary = {}
var _vault_alignment_announced := false
var optional_branch_active := false
var optional_branch_failed := false
var optional_branch_timer := 0.0

var visited_cells: Dictionary = {}
var discovered_markers: Dictionary = {}
var _threat_contact_cache: Array[Dictionary] = []
var _threat_sample_timer := 0.0
var _squad_motion_snapshot: Dictionary = {}
var _hud_refresh_timer := 0.0
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


func _ready() -> void:
	_rng.seed = 0xC4A2B0
	_parse_capture_arguments()
	_build_backdrop()
	_build_camera()
	_build_ui()
	_build_audio()
	_load_persistence()
	_reset_run(false)
	_ui.show_deployment(selected_primary)
	_set_mouse_for_mode()
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(_audio):
		_audio.shutdown()


func _physics_process(delta: float) -> void:
	if mode == RunMode.PLAYING:
		run_time += delta
		_update_player(delta)
		_update_cycle_upgrades(delta)
		_update_stage_environment(delta)
		_update_pickups()
		_update_experience(delta)
		_update_encounter(delta)
		_update_enemies(delta)
		_update_threat_contacts(delta)
		_update_projectiles(delta)
		_update_denied_zones(delta)
		_update_trails(delta)
		_update_effects(delta)
		_update_stage_progression()
	else:
		_update_effects(delta)
	_update_camera(delta)


func _process(delta: float) -> void:
	player_hit_flash = maxf(0.0, player_hit_flash - delta)
	player_muzzle_flash = maxf(0.0, player_muzzle_flash - delta)
	camera_shake = maxf(0.0, camera_shake - delta * 18.0)
	if is_instance_valid(_ui) and (mode == RunMode.PLAYING or _capture_mode):
		_hud_refresh_timer -= delta
		if _hud_refresh_timer <= 0.0:
			_hud_refresh_timer = HUD_REFRESH_INTERVAL
			_ui.update_hud(_build_hud_snapshot())
	else:
		_hud_refresh_timer = 0.0
	if is_instance_valid(_audio):
		_audio.update_primary(mode == RunMode.PLAYING and Input.is_action_pressed("primary_fire"))
	if mode == RunMode.PLAYING or _capture_mode or not effects.is_empty() or player_hit_flash > 0.0 or player_muzzle_flash > 0.0:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == RunMode.PLAYING:
			_pause_run()
			get_viewport().set_input_as_handled()
			return
		elif mode == RunMode.PAUSED:
			_resume_run()
			get_viewport().set_input_as_handled()
			return

	if mode == RunMode.DEPLOYMENT and event is InputEventKey and event.pressed and not event.echo:
		var deployment_event := event as InputEventKey
		if deployment_event.keycode in [KEY_ENTER, KEY_SPACE]:
			_on_deployment_selected(&"pulse_cannon")


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


func _stage_landmark(landmark_id: String) -> Vector2:
	return Rules.landmark(landmark_id, current_stage_id)


func _stage_boss_arena() -> Rect2:
	return Rules.boss_arena(current_stage_id)


func _stage_boss_gate() -> Rect2:
	return Rules.boss_gate(current_stage_id)


func _build_backdrop() -> void:
	_backdrop = StageBackdrop.new()
	_backdrop.name = "VehicleStageBackdrop"
	add_child(_backdrop)
	_backdrop.configure(current_stage_id)


func _build_ui() -> void:
	_ui = StageUI.new()
	_ui.name = "VehicleStageUI"
	add_child(_ui)
	_ui.deployment_selected.connect(_on_deployment_selected)
	_ui.upgrade_selected.connect(_on_upgrade_selected)
	_ui.upgrade_declined.connect(_on_upgrade_declined)
	_ui.upgrade_previewed.connect(func(_upgrade_id: StringName) -> void: _play_sound(&"upgrade_select"))
	_ui.resume_requested.connect(_resume_run)
	_ui.restart_requested.connect(_restart_stage)
	_ui.garage_requested.connect(_show_garage)
	_ui.replay_requested.connect(_replay_stage)
	_ui.advance_requested.connect(_advance_stage)


func _build_audio() -> void:
	_audio = AudioDirector.new()
	_audio.name = "VehicleAudioDirector"
	add_child(_audio)


func _play_sound(sound_id: StringName, pitch: float = 1.0) -> void:
	if is_instance_valid(_audio):
		_audio.play(sound_id, pitch)


func _reset_run(increment_index: bool = true, preserve_stage: bool = false, preserve_upgrades: bool = false) -> void:
	if increment_index:
		run_index += 1
	if not preserve_stage:
		current_stage_index = 0
		current_stage_id = StageCatalog.STAGE_IDS[0]
	if is_instance_valid(_backdrop):
		_backdrop.configure(current_stage_id)
	if is_instance_valid(_camera):
		_apply_camera_stage_limits()
	if is_instance_valid(_ui):
		_ui.clear_notifications()
	mode = RunMode.DEPLOYMENT
	player_position = Rules.player_start(current_stage_id)
	player_hull_direction = Vector2.RIGHT
	player_aim_direction = Vector2.RIGHT
	player_health = _player_max_health()
	player_invulnerable = 0.0
	player_hit_flash = 0.0
	player_primary_weapon.set_full_opening_seconds(_opening_charge_seconds())
	player_primary_weapon.reset(true)
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
	_last_damage_source = ""

	if not preserve_upgrades:
		run_build.reset()
		experience_runtime.reset()
		selected_upgrade_title_key = "UPGRADE_NONE"
		claimed_reward_sources.clear()
	else:
		experience_runtime.shards.clear()
		experience_runtime.pending_level_ups = 0
	cycle_runtime.reset()
	_sync_cycle_upgrades()
	experience_recall_timer = 0.0
	lifesteal_budget = 6.0
	player_health = _player_max_health()
	current_card_offer.clear()
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	crates.clear()
	denied_zones.clear()
	effects.clear()
	damaging_trails.clear()
	for spec in StageCatalog.static_enemy_blueprint(current_stage_id):
		enemies.append(_make_enemy(spec))
	encounter_runtime.configure(current_stage_id, StageCatalog.packets(current_stage_id), _combat_preset())
	for spec in Rules.get_pickup_blueprint(current_stage_id):
		pickups.append({
			"id": String(spec["id"]),
			"kind": StringName(spec["kind"]),
			"pos": Vector2(spec["pos"]),
			"active": true,
			"pulse": _rng.randf_range(0.0, TAU),
			"heal_amount": float(spec.get("heal_amount", 35.0)),
		})
	for spec in Rules.get_crate_blueprint(current_stage_id):
		crates.append({
			"id": String(spec["id"]),
			"pos": Vector2(spec["pos"]),
			"drop": StringName(spec["drop"]),
			"health": 24.0,
			"max_health": 24.0,
			"alive": true,
			"flash": 0.0,
		})

	tutorial_move = false
	tutorial_aim = false
	tutorial_fire = false
	tutorial_dash = false
	tutorial_announced = false
	entered_approach = false
	entered_installations = false
	generators_destroyed = 0
	chest_claimed = false
	field_boss_defeated = false
	boss_started = false
	boss_locked = false
	boss_phase_two_announced = false
	stage_complete = false
	pending_stage_completion = false
	pending_reward_sources.clear()
	current_reward_source = &""
	current_reward_optional = false
	completed_group_rewards.clear()
	if not preserve_upgrades:
		run_time = 0.0
	environment_time = 0.0
	environment_damage_tick = 0.0
	_reset_stage_mechanics()
	_objective_trigger_cache = Rules.objective_triggers(current_stage_id)
	visited_cells.clear()
	discovered_markers.clear()
	_threat_contact_cache.clear()
	_threat_sample_timer = 0.0
	_squad_motion_snapshot.clear()
	_hud_refresh_timer = 0.0
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


func _make_enemy(spec: Dictionary) -> Dictionary:
	var archetype := StringName(spec["role"])
	var definition := EnemyArchetypes.definition(archetype)
	var role := StringName(definition["behavior"])
	var attack_cooldown := _rng.randf_range(0.4, 1.2) / EncounterDirector.ENEMY_RECOVERY_RATE
	var health := float(definition["health"])
	var health_class := StringName(definition["health_class"])
	var stage_curve := StageDifficulty.multipliers(current_stage_index)
	if health_class in [&"swarm", &"standard"]:
		health *= EncounterDirector.ENEMY_HEALTH_MULTIPLIER
	if archetype == &"field_boss":
		health = StageDifficulty.boss_health(current_stage_index, true)
	elif archetype == &"stage_boss":
		health = StageDifficulty.boss_health(current_stage_index, false)
	else:
		health *= float(stage_curve["health"])
	var position: Vector2 = spec["pos"]
	var speed := float(definition["speed"]) * EncounterDirector.ENEMY_SPEED_MULTIPLIER
	if archetype not in [&"field_boss", &"stage_boss"]:
		speed *= float(stage_curve["speed"])
	return {
		"id": String(spec.get("id", role)),
		"role": role,
		"archetype": archetype,
		"name": String(spec.get("name_key", definition["name_key"])),
		"pos": position,
		"home": position,
		"velocity": Vector2.ZERO,
		"health": health,
		"max_health": health,
		"speed": speed,
		"radius": float(definition["radius"]),
		"visual_radius": float(definition["visual_radius"]),
		"health_class": health_class,
		"health_visible_timer": 0.0,
		"threat_cost": float(definition["threat_cost"]),
		"threat_kind": StringName(definition["threat_kind"]),
		"counts_active_cap": bool(definition["active_cap"]),
		"alive": true,
		"active": bool(spec.get("active", false)),
		"phase": "move",
		"phase_time": 0.0,
		"attack_cooldown": attack_cooldown,
		"committed_dir": Vector2.LEFT,
		"committed_target": position,
		"hit_committed": false,
		"burst_left": 0,
		"burst_timer": 0.0,
		"stun": 0.0,
		"stagger": 0.0,
		"flash": 0.0,
		"shielded": false,
		"support_tick": 0.0,
		"repair_target_id": "",
		"intercept_charges": 3 if role == &"interceptor_tower" else 0,
		"intercept_recharge": 0.0,
		"strafe_sign": -1.0 if String(spec.get("id", "")).hash() % 2 == 0 else 1.0,
		"stuck_time": 0.0,
		"reposition_time": 0.0,
		"reposition_dir": Vector2.ZERO,
		"zone": String(spec.get("zone", "")),
		"group_id": String(spec.get("group_id", "")),
		"squad_id": String(spec.get("squad_id", "")),
		"squad_leader": bool(spec.get("squad_leader", false)),
		"formation_slot": int(spec.get("formation_slot", 0)),
		"formation_size": int(spec.get("formation_size", 1)),
		"formation_offset": Vector2(spec.get("formation_offset", Vector2.ZERO)),
		"target_sector": Vector2(spec.get("target_sector", Vector2.RIGHT)),
		"packet_beat": int(spec.get("packet_beat", 0)),
		"carrier_id": String(spec.get("carrier_id", "")),
		"summoned": bool(spec.get("summoned", false)),
		"child_serial": 0,
		"carrier_wave_released": false,
		"beam_end": position,
		"requires_reflection": bool(spec.get("requires_reflection", false)),
		"marked_time": 0.0,
		"shear_time": 0.0,
		"leash_rect": Rect2(spec.get("leash_rect", Rect2())),
		"required": bool(spec.get("required", false)),
		"optional": bool(spec.get("optional", false)),
		"ram_cooldown": 0.0,
		"pattern_index": 0,
		"boss_phase": 1,
		"pattern": "",
		"pattern_timer": 0.0,
		"pattern_tick": 0.0,
		"vulnerable": 0.0,
		"lane_centers": [],
	}


func _combat_preset() -> StringName:
	var settings := get_node_or_null("/root/SettingsStore")
	return StringName(settings.combat_preset) if settings != null else &"standard"


func _update_encounter(delta: float) -> void:
	var requests := encounter_runtime.tick(delta, _active_mobile_count(), _active_attack_families())
	for cue in requests["cues"]:
		_add_effect("spawn", Vector2(cue["anchor"]), Art.MUSTARD, 0.9, 126.0)
		_play_sound(&"boss", 0.72)
		if int(cue["beat"]) == 0:
			_ui.notify(tr("NOTIFY_CONTACT_INBOUND"), 1.2, Art.MUSTARD)
	for spawn_spec in requests["spawns"]:
		var enemy := _make_enemy(spawn_spec)
		enemies.append(enemy)
		_add_effect("spawn", Vector2(enemy["pos"]), Art.CORAL, 0.42, 68.0)


func _active_mobile_count() -> int:
	var count := 0
	for enemy in enemies:
		if bool(enemy.get("alive", false)) and bool(enemy.get("active", false)) and bool(enemy.get("counts_active_cap", false)):
			count += 1
	return count


func _active_attack_families() -> Array[StringName]:
	var families: Array[StringName] = []
	for enemy in enemies:
		if not bool(enemy.get("alive", false)) or not bool(enemy.get("active", false)):
			continue
		var family := StringName(enemy.get("threat_kind", &"melee"))
		if family in [&"support", &"boss"] or family in families:
			continue
		families.append(family)
	return families


func _on_deployment_selected(primary_id: StringName) -> void:
	selected_primary = primary_id
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
	_ui.show_pause()
	_set_mouse_for_mode()


func _resume_run() -> void:
	if mode != RunMode.PAUSED:
		return
	mode = mode_before_pause
	_ui.show_gameplay()
	_set_mouse_for_mode()


func _restart_stage() -> void:
	var primary := selected_primary
	_reset_run(false, true, true)
	selected_primary = primary
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_STAGE_RESET"), 2.6, Rules.MUTED)
	_set_mouse_for_mode()


func _replay_stage() -> void:
	var primary := selected_primary
	_reset_run(true)
	selected_primary = primary
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(tr("NOTIFY_REDEPLOYED"), 2.8, Rules.CYAN)
	_set_mouse_for_mode()


func _advance_stage() -> void:
	if current_stage_index >= StageCatalog.STAGE_IDS.size() - 1:
		return
	current_stage_index += 1
	current_stage_id = StageCatalog.STAGE_IDS[current_stage_index]
	_reset_run(false, true, true)
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	var profile := StageCatalog.profile(current_stage_id)
	var arrival_text := tr("NOTIFY_STAGE_ARRIVAL").replace("%d", str(int(profile["number"]))).replace("%s", tr(String(profile["title_key"])))
	_ui.notify(arrival_text, 3.2, Rules.CYAN)
	_play_sound(&"card", 1.12)
	_set_mouse_for_mode()


func _show_garage() -> void:
	mode = RunMode.GARAGE
	player_health = _player_max_health()
	projectiles.clear()
	denied_zones.clear()
	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": persistent_clear_count,
		"relay_module_unlocked": persistent_relay_module,
		"field_module_unlocked": persistent_field_module,
		"build_summary": _run_build_summary(),
	})
	_set_mouse_for_mode()


func _set_mouse_for_mode() -> void:
	if _capture_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if mode == RunMode.PLAYING else Input.MOUSE_MODE_VISIBLE


func _update_player(delta: float) -> void:
	lifesteal_budget = minf(6.0, lifesteal_budget + 6.0 * delta)
	experience_recall_timer = maxf(0.0, experience_recall_timer - delta)
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

	_update_passive_secondary()
	_update_aim_target()
	_mark_visited()
	_apply_dash_collision()

	if tutorial_move and tutorial_aim and tutorial_fire and tutorial_dash and not tutorial_announced:
		tutorial_announced = true
		_ui.notify(tr("NOTIFY_CALIBRATION_COMPLETE"), 3.0, Rules.MOSS)


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
		player_dash_direction * DASH_SPEED * delta,
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
	for enemy in enemies:
		if not bool(enemy.get("alive", false)) or not bool(enemy.get("active", false)):
			continue
		if Rules.point_segment_distance(Vector2(enemy["pos"]), from, to) > float(enemy["radius"]) + Rules.PLAYER_RADIUS:
			continue
		for candidate in enemies:
			candidate["shear_time"] = 0.0
		enemy["shear_time"] = 3.0
		_add_effect("impact", Vector2(enemy["pos"]), Art.MINT, 0.24, 48.0)
		return


func _fire_primary(shot: Dictionary) -> void:
	tutorial_fire = true
	player_muzzle_flash = 0.075
	var attack_multiplier := float(shot["damage_scale"]) * run_build.stat(&"primary_damage_multiplier", 1.0)
	var origin := player_position + player_aim_direction * 39.0
	var is_full_opening := bool(shot["full_opening"])
	var projectile_count := 1 + run_build.level_of(&"forked_muzzle")
	var per_projectile_scale: float = [1.0, 0.70, 0.55][projectile_count - 1]
	var spread_step := deg_to_rad(7.0) * run_build.stat(&"primary_spread", 1.0)
	var projectile_speed := run_build.stat(&"primary_projectile_speed", PRIMARY_PROJECTILE_SPEED)
	var projectile_radius := run_build.stat(&"primary_radius", 5.5) * float(shot["radius_scale"])
	var structure_multiplier := run_build.stat(&"primary_structure", 1.0)
	if float(shot["bonus_ratio"]) > 0.0:
		structure_multiplier *= run_build.stat(&"opening_breach_multiplier", 1.0)
	var range := run_build.stat(&"primary_range", PRIMARY_RANGE)
	for index in projectile_count:
		var centered_index := float(index) - float(projectile_count - 1) * 0.5
		_spawn_player_projectile(
			origin,
			player_aim_direction.rotated(centered_index * spread_step),
			18.0 * attack_multiplier * per_projectile_scale,
			projectile_speed,
			run_build.level_of(&"phase_lance") + (1 if is_full_opening else 0),
			projectile_radius,
			18.0 * float(shot["structure_scale"]) * structure_multiplier * per_projectile_scale,
			5.0 * float(shot["stagger_scale"]) * run_build.stat(&"opening_breach_multiplier", 1.0),
			is_full_opening,
			range,
			StatusRuntime.payload(run_build)
		)
	if is_full_opening:
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


func _reset_stage_mechanics() -> void:
	switchyard_gate_state = 0
	reflector_orientations.clear()
	_mechanic_contact_latches.clear()
	_stage_environment_zones = StageCatalog.environment_zones(current_stage_id)
	_vault_alignment_announced = false
	optional_branch_active = false
	optional_branch_failed = false
	optional_branch_timer = 0.0
	for zone in _stage_environment_zones:
		if StringName(zone.get("kind", &"")) == &"reflector":
			reflector_orientations[StringName(zone["id"])] = int(zone.get("initial_orientation", 0))
	_refresh_runtime_cover_cache()


func _stage_mechanic_zones(kind: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for zone in _stage_environment_zones:
		if StringName(zone.get("kind", &"")) == kind:
			result.append(zone)
	return result


func _runtime_cover_rects() -> Array[Rect2]:
	return _runtime_cover_cache


func _runtime_projectile_cover_rects() -> Array[Rect2]:
	if current_stage_id != &"abyssal_observatory":
		return _runtime_cover_cache
	var result: Array[Rect2] = []
	var reflector_rects: Array[Rect2] = []
	for zone in _stage_mechanic_zones(&"reflector"):
		reflector_rects.append(Rect2(zone["rect"]))
	for rect in _runtime_cover_cache:
		if rect not in reflector_rects:
			result.append(rect)
	return result


func _refresh_runtime_cover_cache() -> void:
	_runtime_cover_cache.clear()
	if current_stage_id == &"coral_switchyard":
		for zone in _stage_mechanic_zones(&"switch_gate"):
			var positions: Array = zone["positions"]
			_runtime_cover_cache.append(Rect2(positions[switchyard_gate_state % positions.size()]))
	elif current_stage_id == &"abyssal_observatory":
		for zone in _stage_mechanic_zones(&"reflector"):
			_runtime_cover_cache.append(Rect2(zone["rect"]))
		if not _observatory_vault_aligned():
			for zone in _stage_mechanic_zones(&"vault_gate"):
				_runtime_cover_cache.append(Rect2(zone["rect"]))


func _runtime_first_cover_hit(from: Vector2, to: Vector2, padding: float) -> Dictionary:
	return Rules.first_cover_hit_with_extra(from, to, padding, _boss_gate_closed(), current_stage_id, _runtime_cover_rects())


func _runtime_has_line_of_sight(from: Vector2, to: Vector2, padding: float) -> bool:
	return Rules.has_line_of_sight_with_extra(from, to, padding, _boss_gate_closed(), current_stage_id, _runtime_cover_rects())


func _observatory_vault_aligned() -> bool:
	if current_stage_id != &"abyssal_observatory":
		return false
	for zone in _stage_mechanic_zones(&"reflector"):
		var reflector_id := StringName(zone["id"])
		if Rules.positive_mod(int(reflector_orientations.get(reflector_id, 0)), 4) != int(zone["vault_orientation"]):
			return false
	return true


func _switchyard_open_lane_y() -> float:
	return 2175.0 if switchyard_gate_state == 0 else 825.0


func _update_stage_interactions() -> void:
	var touched: Dictionary = {}
	for zone in _stage_environment_zones:
		var kind := StringName(zone.get("kind", &""))
		if kind not in [&"switch_pad", &"reflector_console"]:
			continue
		var zone_id := StringName(zone["id"])
		var inside := player_position.distance_to(Vector2(zone["center"])) <= float(zone["radius"]) + Rules.PLAYER_RADIUS
		if inside:
			touched[zone_id] = true
		if not inside or bool(_mechanic_contact_latches.get(zone_id, false)):
			continue
		_mechanic_contact_latches[zone_id] = true
		if kind == &"switch_pad":
			switchyard_gate_state = 1 - switchyard_gate_state
			_refresh_runtime_cover_cache()
			_ui.notify(tr("NOTIFY_SWITCHYARD_ROUTE") % (switchyard_gate_state + 1), 2.0, Art.MUSTARD)
			_play_sound(&"card", 0.82 + float(switchyard_gate_state) * 0.12)
		else:
			var reflector_id := StringName(zone["reflector_id"])
			reflector_orientations[reflector_id] = Rules.positive_mod(int(reflector_orientations.get(reflector_id, 0)) + 1, 4)
			_refresh_runtime_cover_cache()
			_ui.notify(tr("NOTIFY_REFLECTOR_ROTATED"), 1.8, Art.MINT)
			_play_sound(&"card", 1.18)
	for latched_id in _mechanic_contact_latches.keys():
		if not touched.has(latched_id):
			_mechanic_contact_latches[latched_id] = false
	if _observatory_vault_aligned() and not _vault_alignment_announced:
		_vault_alignment_announced = true
		_refresh_runtime_cover_cache()
		discovered_markers["field_boss"] = true
		_ui.notify(tr("NOTIFY_MIRROR_VAULT_OPEN"), 2.8, Art.MUSTARD)


func _update_stage_environment(delta: float) -> void:
	environment_time += delta
	environment_damage_tick = maxf(0.0, environment_damage_tick - delta)
	_update_stage_interactions()
	var profile := StageCatalog.profile(current_stage_id)
	var environment := StringName(profile.get("environment", &"none"))
	if environment == &"current":
		for zone in _stage_environment_zones:
			if Rect2(zone["rect"]).has_point(player_position):
				var drift := Vector2(zone["direction"]) * float(zone["strength"]) * delta
				player_position = _move_actor(player_position, drift, Rules.PLAYER_RADIUS, true)
		for projectile in projectiles:
			for zone in _stage_environment_zones:
				if Rect2(zone["rect"]).has_point(Vector2(projectile["pos"])):
					projectile["velocity"] = Vector2(projectile["velocity"]) + Vector2(zone["direction"]) * float(zone["strength"]) * delta * 2.0
	elif environment == &"storm":
		for zone in _stage_environment_zones:
			var phase := fmod(environment_time + float(zone["phase"]), 5.2)
			if phase >= 1.4 and phase < 2.2 and Rect2(zone["rect"]).has_point(player_position) and environment_damage_tick <= 0.0:
				environment_damage_tick = 0.55
				_damage_player(10.0, "Drydock storm strip", false, false)
	elif environment == &"switchyard" and optional_branch_active and not optional_branch_failed and not field_boss_defeated:
		optional_branch_timer = maxf(0.0, optional_branch_timer - delta)
		if optional_branch_timer <= 0.0:
			_fail_switchyard_convoy()


func _fail_switchyard_convoy() -> void:
	optional_branch_failed = true
	optional_branch_active = false
	for enemy in enemies:
		if String(enemy.get("zone", "")) == "field_boss":
			enemy["alive"] = false
			enemy["active"] = false
	_ui.notify(tr("NOTIFY_CONVOY_ESCAPED"), 2.8, Art.CORAL)


func _spawn_player_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, extra_pierce: int, radius: float = 5.0, structure_damage: float = -1.0, stagger: float = 5.0, opening: bool = false, projectile_range: float = PRIMARY_RANGE, status_payload: Dictionary = {}) -> void:
	_enforce_player_projectile_cap()
	projectiles.append({
		"pos": origin,
		"velocity": direction.normalized() * speed,
		"radius": radius,
		"team": &"player",
		"damage": damage,
		"life": projectile_range / speed,
		"color": Art.MUSTARD,
		"owner": "player_primary",
		"pierce": extra_pierce,
		"bounces": 1 if run_build.has(&"ricochet_matrix") else 0,
		"homing": false,
		"target_id": "",
		"explosive": false,
		"stagger": stagger,
		"structure_damage": damage if structure_damage < 0.0 else structure_damage,
		"opening": opening,
		"reflected": false,
		"reflector_lock": &"",
		"reflector_lock_time": 0.0,
		"status_payload": status_payload.duplicate(true),
	})


func _enforce_player_projectile_cap() -> void:
	var player_count := 0
	for projectile in projectiles:
		if StringName(projectile["team"]) == &"player":
			player_count += 1
	if player_count < EncounterDirector.PLAYER_PROJECTILE_CAP:
		return
	for index in projectiles.size():
		var projectile: Dictionary = projectiles[index]
		if StringName(projectile["team"]) == &"player" and not bool(projectile.get("opening", false)):
			projectiles.remove_at(index)
			return


func _update_passive_secondary() -> void:
	if player_passive_cooldown > 0.0 or player_emp_startup > 0.0:
		return
	var targets := _find_passive_targets(1 + run_build.level_of(&"twin_seekers"))
	if targets.is_empty():
		return
	var cooldown := maxf(PASSIVE_COOLDOWN * 0.60, run_build.stat(&"passive_interval", PASSIVE_COOLDOWN))
	if persistent_field_module:
		cooldown *= 0.85
	player_passive_cooldown = cooldown
	for target in targets:
		var enemy: Dictionary = target
		var direction := (Vector2(enemy["pos"]) - player_position).normalized()
		var seeker_count := 1 + run_build.level_of(&"twin_seekers")
		var seeker_scale: float = [1.0, 0.85, 0.70][seeker_count - 1]
		_enforce_player_projectile_cap()
		var marked_multiplier := 1.25 if float(enemy.get("marked_time", 0.0)) > 0.0 else 1.0
		projectiles.append({
			"pos": player_position + direction * 33.0,
			"velocity": direction * 490.0,
			"radius": 8.0,
			"team": &"player",
			"damage": 25.0 * run_build.stat(&"passive_damage_multiplier", 1.0) * seeker_scale * marked_multiplier,
			"life": 1.8,
			"color": Art.MINT,
			"owner": "passive_seeker",
			"pierce": run_build.level_of(&"phase_seeker"),
			"bounces": 0,
			"homing": true,
			"target_id": String(enemy["id"]),
			"explosive": applied_upgrades.has(&"hunter_firmware"),
			"stagger": 12.0,
			"structure_damage": 25.0,
			"opening": false,
			"status_payload": {},
		})
	_play_sound(&"missile")


func _find_passive_targets(max_targets: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var distance := player_position.distance_to(Vector2(enemy["pos"]))
		if distance > PASSIVE_RANGE:
			continue
		if not _runtime_has_line_of_sight(player_position, Vector2(enemy["pos"]), 6.0):
			continue
		var priority := 0.0
		var role := StringName(enemy["role"])
		if float(enemy.get("marked_time", 0.0)) > 0.0:
			priority -= 900.0
		if applied_upgrades.has(&"hunter_firmware"):
			if role in [&"generator", &"turret", &"mine", &"boss_pylon", &"beam_sentinel", &"repair_tender", &"drone_carrier"]:
				priority -= 500.0
		elif role in [&"chaser", &"shooter", &"controller"]:
			priority -= 60.0
		enemy["_passive_score"] = priority + distance
		candidates.append(enemy)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("_passive_score", 0.0)) < float(b.get("_passive_score", 0.0))
	)
	if candidates.size() > max_targets:
		candidates.resize(max_targets)
	return candidates


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
	for enemy in enemies:
		if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(player_position) <= radius:
			var stun_duration := 1.25 if is_aftershock else 2.1
			if not is_aftershock and run_build.has(&"relay_overload") and SpecialistRuntime.is_support_or_installation(StringName(enemy["role"])):
				stun_duration += 2.5 * run_build.level_of(&"relay_overload")
			enemy["stun"] = maxf(float(enemy["stun"]), stun_duration)
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
	var speed := run_build.stat(&"move_speed_multiplier", PLAYER_BASE_SPEED)
	if cycle_runtime.is_active(&"thruster_cycle"):
		speed *= 1.28 if cycle_runtime.level(&"thruster_cycle") >= 2 else 1.20
	return speed


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
			var before := player_health
			player_health = minf(_player_max_health(), player_health + float(pickup.get("heal_amount", 35.0)))
			_ui.notify(tr("NOTIFY_REPAIR") % roundi(player_health - before), 2.0, Rules.MOSS)
		&"experience_recall":
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
	var result := experience_runtime.advance(delta, player_position, attraction_radius, experience_recall_timer > 0.0)
	if int(result["experience"]) > 0:
		_play_sound(&"pickup", 1.22)
	for source in result["reward_sources"]:
		if source not in pending_reward_sources:
			pending_reward_sources.append(source)
	if int(result["levels"]) > 0:
		_ui.notify(tr("NOTIFY_LEVEL_UP"), 1.8, Art.MUSTARD)
	_advance_reward_queue()


func _update_enemies(delta: float) -> void:
	_enforce_active_enemy_cap()
	var committed_points := 0.0
	var committed_ranged := 0
	var committed_denial := 0
	var active_capped := 0
	for enemy in enemies:
		if not bool(enemy["alive"]):
			continue
		if bool(enemy["active"]) and bool(enemy.get("counts_active_cap", false)):
			active_capped += 1
		if String(enemy["phase"]) in ["startup", "active"] and StringName(enemy["role"]) not in [&"stage_boss", &"field_boss", &"generator", &"boss_pylon"]:
			committed_points += float(enemy.get("threat_cost", 1.0))
			match StringName(enemy.get("threat_kind", &"melee")):
				&"ranged": committed_ranged += 1
				&"denial": committed_denial += 1

	for enemy in enemies:
		if not bool(enemy["alive"]):
			continue
		enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
		enemy["stun"] = maxf(0.0, float(enemy["stun"]) - delta)
		enemy["ram_cooldown"] = maxf(0.0, float(enemy["ram_cooldown"]) - delta)
		enemy["vulnerable"] = maxf(0.0, float(enemy["vulnerable"]) - delta)
		enemy["marked_time"] = maxf(0.0, float(enemy.get("marked_time", 0.0)) - delta)
		enemy["shear_time"] = maxf(0.0, float(enemy.get("shear_time", 0.0)) - delta)
		enemy["health_visible_timer"] = maxf(0.0, float(enemy.get("health_visible_timer", 0.0)) - delta)
		var activated := _update_enemy_activation(enemy, active_capped < encounter_runtime.active_cap())
		if activated and bool(enemy.get("counts_active_cap", false)):
			active_capped += 1

	_squad_motion_snapshot = EncounterDirector.squad_motion_snapshot(enemies)
	var shielded_ids := _build_enemy_shield_assignments()
	for enemy in enemies:
		if not bool(enemy["alive"]):
			continue
		if not bool(enemy["active"]):
			continue
		var status_damage := StatusRuntime.tick(enemy, delta)
		if status_damage > 0.0:
			_damage_enemy(enemy, status_damage, "status", 0.0)
			if not bool(enemy["alive"]):
				continue
		_apply_enemy_shield(enemy, shielded_ids)
		var role := StringName(enemy["role"])
		if role == &"stage_boss":
			_update_stage_boss(enemy, delta)
			continue
		if role == &"field_boss":
			_update_field_boss(enemy, delta)
			continue
		if role == &"generator":
			_update_generator(enemy, delta)
			continue
		if role == &"boss_pylon":
			_update_boss_pylon(enemy, delta)
			continue
		if float(enemy["stun"]) > 0.0:
			enemy["velocity"] = Vector2.ZERO
			continue
		var can_commit := EncounterDirector.can_commit(
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
		var started := _update_ordinary_enemy(enemy, delta, can_commit)
		if started:
			committed_points += float(enemy.get("threat_cost", 1.0))
			match StringName(enemy.get("threat_kind", &"melee")):
				&"ranged": committed_ranged += 1
				&"denial": committed_denial += 1


func _enforce_active_enemy_cap() -> void:
	var active_mobile: Array[Dictionary] = []
	for enemy in enemies:
		if bool(enemy["alive"]) and bool(enemy["active"]) and bool(enemy.get("counts_active_cap", false)):
			active_mobile.append(enemy)
	var cap := encounter_runtime.active_cap()
	if active_mobile.size() <= cap:
		return
	active_mobile.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_committed := String(a["phase"]) in ["startup", "active"]
		var b_committed := String(b["phase"]) in ["startup", "active"]
		if a_committed != b_committed:
			return a_committed
		return player_position.distance_squared_to(Vector2(a["pos"])) < player_position.distance_squared_to(Vector2(b["pos"]))
	)
	for index in range(cap, active_mobile.size()):
		var enemy := active_mobile[index]
		enemy["active"] = false
		enemy["velocity"] = Vector2.ZERO
		enemy["phase"] = "move"


func _update_enemy_activation(enemy: Dictionary, capacity_available: bool) -> bool:
	if bool(enemy["active"]):
		return false
	if encounter_runtime.elapsed < EncounterRuntime.ARRIVAL_GRACE:
		return false
	var role := StringName(enemy["role"])
	var distance := player_position.distance_to(Vector2(enemy["pos"]))
	if role == &"field_boss":
		enemy["active"] = distance < 560.0
		return bool(enemy["active"])
	if not capacity_available and bool(enemy.get("counts_active_cap", false)):
		return false
	if distance < 760.0 and (entered_approach or entered_installations or encounter_runtime.current_beat >= 1):
		enemy["active"] = true
	return bool(enemy["active"])


func _build_enemy_shield_assignments() -> Dictionary:
	var shielded_ids := {}
	var candidates: Array[Dictionary] = []
	var supports: Array[Dictionary] = []
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var role := StringName(enemy["role"])
		if role in [&"generator", &"shield_escort"]:
			supports.append(enemy)
		elif role not in [&"field_boss", &"stage_boss", &"boss_pylon"]:
			candidates.append(enemy)
	for support in supports:
		var support_position := Vector2(support["pos"])
		if StringName(support["role"]) == &"generator":
			for candidate in candidates:
				if support_position.distance_squared_to(Vector2(candidate["pos"])) <= 390.0 * 390.0:
					shielded_ids[String(candidate["id"])] = true
			continue
		var closest_id := ""
		var closest_distance_squared := 300.0 * 300.0
		for candidate in candidates:
			var distance_squared := support_position.distance_squared_to(Vector2(candidate["pos"]))
			if distance_squared <= closest_distance_squared:
				closest_distance_squared = distance_squared
				closest_id = String(candidate["id"])
		if not closest_id.is_empty():
			shielded_ids[closest_id] = true
	return shielded_ids


func _apply_enemy_shield(enemy: Dictionary, shielded_ids: Dictionary) -> void:
	enemy["shielded"] = bool(shielded_ids.get(String(enemy["id"]), false))


func _update_enemy_shield(enemy: Dictionary) -> void:
	# Compatibility path for deterministic single-enemy contract checks.
	_apply_enemy_shield(enemy, _build_enemy_shield_assignments())


func _update_generator(enemy: Dictionary, delta: float) -> void:
	enemy["support_tick"] = float(enemy["support_tick"]) - delta
	if float(enemy["support_tick"]) > 0.0:
		return
	enemy["support_tick"] = 0.75
	for target in enemies:
		if not bool(target["alive"]) or target == enemy:
			continue
		if Vector2(target["pos"]).distance_to(Vector2(enemy["pos"])) <= 390.0:
			target["health"] = minf(float(target["max_health"]), float(target["health"]) + 4.0)
	_add_effect("support", Vector2(enemy["pos"]), Rules.CYAN, 0.28, 105.0)


func _update_repair_tender(enemy: Dictionary, delta: float) -> void:
	var target_id := SpecialistRuntime.repair_target_id(enemy, enemies, current_stage_id, _boss_gate_closed(), _runtime_cover_rects())
	enemy["repair_target_id"] = target_id
	if target_id.is_empty():
		return
	var target := _find_enemy_by_id(target_id)
	if target.is_empty():
		enemy["repair_target_id"] = ""
		return
	target["health"] = minf(float(target["max_health"]), float(target["health"]) + SpecialistRuntime.REPAIR_PER_SECOND * delta)
	enemy["support_tick"] = maxf(0.0, float(enemy["support_tick"]) - delta)
	if float(enemy["support_tick"]) <= 0.0:
		enemy["support_tick"] = 0.32
		_add_effect("support", Vector2(target["pos"]), Art.MINT, 0.24, 46.0)


func _spawn_carrier_child(carrier: Dictionary) -> void:
	if SpecialistRuntime.living_children(String(carrier["id"]), enemies) >= SpecialistRuntime.CARRIER_CHILD_CAP:
		return
	carrier["child_serial"] = int(carrier["child_serial"]) + 1
	var serial := int(carrier["child_serial"])
	var offset := Vector2.RIGHT.rotated(TAU * float(serial % 6) / 6.0) * 58.0
	var spawn_position := _move_actor(Vector2(carrier["pos"]), offset, 12.0, false)
	var child := _make_enemy({
		"id":"%s_child_%02d" % [String(carrier["id"]), serial],
		"role":&"scrap_drone",
		"pos":spawn_position,
		"active":true,
		"carrier_id":String(carrier["id"]),
		"squad_id":"%s_children" % String(carrier["id"]),
		"group_id":String(carrier.get("group_id", "")),
		"leash_rect":Rect2(carrier.get("leash_rect", Rect2())),
	})
	enemies.append(child)
	_add_effect("spawn", spawn_position, Art.CORAL, 0.32, 44.0)


func _update_boss_pylon(enemy: Dictionary, delta: float) -> void:
	enemy["support_tick"] = float(enemy["support_tick"]) - delta
	if float(enemy["support_tick"]) <= 0.0:
		enemy["support_tick"] = 2.4
		denied_zones.append({
			"pos": Vector2(enemy["pos"]),
			"radius": 125.0,
			"warning": 0.80,
			"duration": 1.8,
			"tick": 0.0,
			"damage": 9.0,
			"final_damage": true,
			"source": "Colossus pylon field",
			"color": Rules.VIOLET,
		})


func _update_ordinary_enemy(enemy: Dictionary, delta: float, can_commit: bool) -> bool:
	var leash := Rect2(enemy.get("leash_rect", Rect2()))
	if leash.has_area() and not leash.has_point(player_position):
		enemy["phase"] = "move"
		enemy["attack_cooldown"] = maxf(float(enemy["attack_cooldown"]), 0.35)
		var to_home := Vector2(enemy["home"]) - Vector2(enemy["pos"])
		if to_home.length() <= 18.0:
			enemy["pos"] = Vector2(enemy["home"])
			enemy["active"] = false
		else:
			_move_enemy_with_recovery(enemy, to_home.normalized() * float(enemy["speed"]), delta)
		return false
	if StringName(enemy["role"]) == &"repair_tender":
		_update_repair_tender(enemy, delta)
		_move_enemy_role(enemy, delta, false)
		return false
	if StringName(enemy["role"]) == &"interceptor_tower":
		enemy["intercept_recharge"] = maxf(0.0, float(enemy["intercept_recharge"]) - delta)
		if int(enemy["intercept_charges"]) < 3 and float(enemy["intercept_recharge"]) <= 0.0:
			enemy["intercept_charges"] = int(enemy["intercept_charges"]) + 1
			enemy["intercept_recharge"] = 4.0
	enemy["attack_cooldown"] = maxf(0.0, float(enemy["attack_cooldown"]) - delta * StatusRuntime.speed_multiplier(enemy))
	var phase := String(enemy["phase"])
	if phase == "startup":
		if StringName(enemy["role"]) == &"artillery_spotter" and not _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 5.0):
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.65
			return false
		enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
		if float(enemy["phase_time"]) <= 0.0:
			_begin_enemy_active(enemy)
		return false
	if phase == "active":
		_update_enemy_active(enemy, delta)
		return false
	if phase == "recovery":
		enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
		_move_enemy_role(enemy, delta, true)
		if float(enemy["phase_time"]) <= 0.0:
			enemy["phase"] = "move"
			enemy["attack_cooldown"] = _enemy_recovery_cooldown(StringName(enemy["role"]))
		return false

	_move_enemy_role(enemy, delta, false)
	if not can_commit or float(enemy["attack_cooldown"]) > 0.0:
		return false
	if _enemy_can_attack(enemy):
		_start_enemy_attack(enemy)
		return true
	return false


func _enemy_recovery_cooldown(role: StringName) -> float:
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
	return cooldown / EncounterDirector.ENEMY_RECOVERY_RATE


func _enemy_can_attack(enemy: Dictionary) -> bool:
	var role := StringName(enemy["role"])
	var distance := Vector2(enemy["pos"]).distance_to(player_position)
	match role:
		&"chaser":
			return distance <= 175.0
		&"shooter":
			return distance <= 620.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0)
		&"controller":
			return distance <= 590.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 4.0)
		&"turret":
			return distance <= 760.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0)
		&"mine":
			return distance <= 190.0
		&"artillery_spotter":
			return distance <= 880.0 and distance >= 250.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 5.0)
		&"interceptor_tower":
			return distance <= 700.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0)
		&"rammer":
			return distance <= 640.0 and distance >= 130.0 and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 12.0)
		&"drone_carrier":
			return distance <= 760.0 and SpecialistRuntime.living_children(String(enemy["id"]), enemies) < SpecialistRuntime.CARRIER_CHILD_CAP
		&"beam_sentinel":
			return distance <= SpecialistRuntime.BEAM_RANGE and _runtime_has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0)
	return false


func _start_enemy_attack(enemy: Dictionary) -> void:
	var role := StringName(enemy["role"])
	enemy["phase"] = "startup"
	enemy["hit_committed"] = false
	enemy["committed_dir"] = (player_position - Vector2(enemy["pos"])).normalized()
	enemy["committed_target"] = player_position
	match role:
		&"chaser":
			enemy["phase_time"] = 0.42
		&"shooter":
			enemy["phase_time"] = 0.62
		&"controller":
			enemy["phase_time"] = 0.82
		&"turret":
			enemy["phase_time"] = 0.68
		&"mine":
			enemy["phase_time"] = 0.62
		&"artillery_spotter":
			enemy["phase_time"] = 1.15
		&"interceptor_tower":
			enemy["phase_time"] = 0.78
		&"rammer":
			enemy["phase_time"] = SpecialistRuntime.RAMMER_STARTUP
		&"drone_carrier":
			enemy["phase_time"] = 0.82
		&"beam_sentinel":
			enemy["phase_time"] = SpecialistRuntime.BEAM_STARTUP


func _begin_enemy_active(enemy: Dictionary) -> void:
	var role := StringName(enemy["role"])
	enemy["phase"] = "active"
	match role:
		&"chaser":
			enemy["phase_time"] = 0.24
		&"shooter":
			_spawn_hostile_projectile(
				Vector2(enemy["pos"]) + Vector2(enemy["committed_dir"]) * 30.0,
				Vector2(enemy["committed_dir"]),
				10.0,
				500.0,
				"Mobile shooter bolt",
				Rules.CORAL
			)
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.72
		&"controller":
			denied_zones.append({
				"pos": Vector2(enemy["committed_target"]),
				"radius": 112.0,
				"warning": 0.82,
				"duration": 2.15,
				"tick": 0.0,
				"damage": 9.0,
				"source": "Controller flood zone",
				"color": Rules.CORAL,
			})
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.88
		&"turret":
			enemy["burst_left"] = 3
			enemy["burst_timer"] = 0.0
			enemy["phase_time"] = 0.55
		&"mine":
			enemy["phase_time"] = 0.15
			if player_position.distance_to(Vector2(enemy["pos"])) <= 205.0:
				_damage_player(16.0, "Arc proximity burst", true)
			_add_effect("shock", Vector2(enemy["pos"]), Rules.CORAL, 0.36, 205.0)
		&"artillery_spotter":
			denied_zones.append({
				"pos": Vector2(enemy["committed_target"]), "radius": 175.0,
				"warning": 0.35, "duration": 1.35, "tick": 0.0,
				"damage": 15.0, "source": "Artillery impact", "color": Rules.CORAL,
			})
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 1.05
		&"interceptor_tower":
			_spawn_hostile_projectile(
				Vector2(enemy["pos"]) + Vector2(enemy["committed_dir"]) * 40.0,
				Vector2(enemy["committed_dir"]), 12.0, 470.0, "Interceptor bolt", Rules.VIOLET
			)
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.9
		&"rammer":
			enemy["phase_time"] = 0.85
		&"drone_carrier":
			enemy["burst_left"] = mini(3, SpecialistRuntime.CARRIER_CHILD_CAP - SpecialistRuntime.living_children(String(enemy["id"]), enemies))
			enemy["burst_timer"] = 0.0
			enemy["phase_time"] = 2.2
		&"beam_sentinel":
			enemy["phase_time"] = SpecialistRuntime.BEAM_ACTIVE
			enemy["hit_committed"] = false
			enemy["beam_end"] = SpecialistRuntime.beam_end(Vector2(enemy["pos"]), Vector2(enemy["committed_dir"]), current_stage_id, _boss_gate_closed(), _runtime_cover_rects())


func _update_enemy_active(enemy: Dictionary, delta: float) -> void:
	var role := StringName(enemy["role"])
	enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
	match role:
		&"chaser":
			var before := Vector2(enemy["pos"])
			enemy["pos"] = _move_actor(
				before,
				Vector2(enemy["committed_dir"]) * 570.0 * EncounterDirector.ENEMY_SPEED_MULTIPLIER * delta,
				float(enemy["radius"]),
				false
			)
			if not bool(enemy["hit_committed"]) and player_position.distance_to(Vector2(enemy["pos"])) <= Rules.PLAYER_RADIUS + float(enemy["radius"]) + 8.0:
				enemy["hit_committed"] = true
				_damage_player(14.0, "Rivet Chaser lunge", true)
			if float(enemy["phase_time"]) <= 0.0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = 0.52
		&"turret":
			enemy["burst_timer"] = float(enemy["burst_timer"]) - delta
			if int(enemy["burst_left"]) > 0 and float(enemy["burst_timer"]) <= 0.0:
				enemy["burst_timer"] = 0.14
				enemy["burst_left"] = int(enemy["burst_left"]) - 1
				var direction := Vector2(enemy["committed_dir"]).rotated(_rng.randf_range(-0.025, 0.025))
				_spawn_hostile_projectile(
					Vector2(enemy["pos"]) + direction * 38.0,
					direction,
					9.0,
					590.0,
					"Foundry turret burst",
					Rules.CORAL
				)
			if int(enemy["burst_left"]) <= 0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = 0.95
		&"mine":
			if float(enemy["phase_time"]) <= 0.0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = 1.2
		&"rammer":
			var before := Vector2(enemy["pos"])
			var requested := Vector2(enemy["committed_dir"]) * 760.0 * delta
			var after := _move_actor(before, requested, float(enemy["radius"]), false)
			enemy["pos"] = after
			var struck_cover := before.distance_to(after) + 1.0 < requested.length()
			if not bool(enemy["hit_committed"]) and player_position.distance_to(after) <= Rules.PLAYER_RADIUS + float(enemy["radius"]) + 8.0:
				enemy["hit_committed"] = true
				_damage_player(20.0, "Rammer charge", true)
			if struck_cover or float(enemy["phase_time"]) <= 0.0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = SpecialistRuntime.RAMMER_RECOVERY
				enemy["vulnerable"] = SpecialistRuntime.RAMMER_RECOVERY
		&"drone_carrier":
			enemy["burst_timer"] = float(enemy["burst_timer"]) - delta
			if int(enemy["burst_left"]) > 0 and float(enemy["burst_timer"]) <= 0.0:
				enemy["burst_timer"] = SpecialistRuntime.CARRIER_RELEASE_SPACING
				enemy["burst_left"] = int(enemy["burst_left"]) - 1
				_spawn_carrier_child(enemy)
			if int(enemy["burst_left"]) <= 0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = SpecialistRuntime.CARRIER_RECOVERY
		&"beam_sentinel":
			var beam_end := Vector2(enemy["beam_end"])
			if not bool(enemy["hit_committed"]) and Rules.point_segment_distance(player_position, Vector2(enemy["pos"]), beam_end) <= Rules.PLAYER_RADIUS + SpecialistRuntime.BEAM_WIDTH * 0.5:
				enemy["hit_committed"] = true
				_damage_player(18.0, "Beam Sentinel sweep", true)
			if float(enemy["phase_time"]) <= 0.0:
				enemy["phase"] = "recovery"
				enemy["phase_time"] = SpecialistRuntime.BEAM_RECOVERY
		_:
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.6


func _move_enemy_role(enemy: Dictionary, delta: float, recovering: bool) -> void:
	var role := StringName(enemy["role"])
	if role in [&"turret", &"mine", &"interceptor_tower", &"beam_sentinel"]:
		return
	var position := Vector2(enemy["pos"])
	var to_player := player_position - position
	var distance := maxf(1.0, to_player.length())
	var direction_to_player := to_player / distance
	var desired := Vector2.ZERO
	match role:
		&"chaser":
			desired = direction_to_player
			if recovering:
				desired = -direction_to_player.rotated(float(enemy["strafe_sign"]) * 0.35)
		&"shooter":
			if distance < 330.0:
				desired = -direction_to_player
			elif distance > 500.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(float(enemy["strafe_sign"]) * PI * 0.5)
		&"controller":
			if distance < 390.0:
				desired = -direction_to_player
			elif distance > 540.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(float(enemy["strafe_sign"]) * PI * 0.5)
		&"shield_escort":
			if distance < 300.0:
				desired = -direction_to_player
			elif distance > 470.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(float(enemy["strafe_sign"]) * PI * 0.5)
		&"artillery_spotter":
			if distance < 520.0:
				desired = -direction_to_player
			elif distance > 760.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(float(enemy["strafe_sign"]) * PI * 0.5)
		&"rammer":
			desired = direction_to_player if not recovering else -direction_to_player
		&"repair_tender", &"drone_carrier":
			if distance < 430.0:
				desired = -direction_to_player
			elif distance > 620.0:
				desired = direction_to_player
			else:
				desired = direction_to_player.rotated(float(enemy["strafe_sign"]) * PI * 0.5)
	var velocity := desired.normalized() * float(enemy["speed"]) * StatusRuntime.speed_multiplier(enemy)
	_move_enemy_with_recovery(enemy, velocity, delta)


func _move_enemy_with_recovery(enemy: Dictionary, velocity: Vector2, delta: float) -> void:
	if float(enemy["reposition_time"]) > 0.0:
		enemy["reposition_time"] = maxf(0.0, float(enemy["reposition_time"]) - delta)
		velocity = Vector2(enemy["reposition_dir"]) * float(enemy["speed"])
	else:
		velocity = EncounterDirector.cohesion_velocity(enemy, _squad_motion_snapshot, velocity)
	var before := Vector2(enemy["pos"])
	var attempt := _move_actor(before, velocity * delta, float(enemy["radius"]), false)
	var moved := before.distance_to(attempt)
	if moved < 0.35 and velocity.length() > 1.0:
		var side_sign := float(enemy["strafe_sign"])
		var side := velocity.normalized().rotated(side_sign * PI * 0.5)
		attempt = _move_actor(before, side * float(enemy["speed"]) * delta, float(enemy["radius"]), false)
		moved = before.distance_to(attempt)
	if moved < 0.25 and velocity.length() > 1.0:
		enemy["stuck_time"] = float(enemy["stuck_time"]) + delta
		if float(enemy["stuck_time"]) > 0.55:
			enemy["stuck_time"] = 0.0
			enemy["strafe_sign"] = -float(enemy["strafe_sign"])
			enemy["reposition_time"] = 0.85
			enemy["reposition_dir"] = velocity.normalized().rotated(float(enemy["strafe_sign"]) * PI * 0.5)
			if String(enemy["phase"]) == "startup":
				enemy["phase"] = "move"
				enemy["attack_cooldown"] = 0.4
	else:
		enemy["stuck_time"] = 0.0
	enemy["pos"] = attempt
	enemy["velocity"] = (attempt - before) / maxf(delta, 0.0001)


func _move_actor(position: Vector2, motion: Vector2, radius: float, is_player: bool) -> Vector2:
	var result := Rules.move_circle_with_extra(position, motion, radius, _boss_gate_closed(), current_stage_id, _runtime_cover_rects())
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		var crate_position := Vector2(crate["pos"])
		if result.distance_to(crate_position) < radius + 31.0:
			var x_attempt := Vector2(result.x, position.y)
			var y_attempt := Vector2(position.x, result.y)
			if x_attempt.distance_to(crate_position) >= radius + 31.0:
				result = x_attempt
			elif y_attempt.distance_to(crate_position) >= radius + 31.0:
				result = y_attempt
			else:
				result = position
	if is_player and boss_locked and not _stage_boss_arena().grow(-20.0).has_point(result):
		result = position
	return result


func _spawn_hostile_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, source: String, color: Color, final_damage: bool = false) -> void:
	if _count_hostile_projectiles() >= EncounterDirector.HOSTILE_PROJECTILE_CAP:
		return
	projectiles.append({
		"pos": origin,
		"velocity": direction.normalized() * speed * EncounterDirector.HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"radius": 7.0,
		"team": &"enemy",
		"damage": damage,
		"final_damage": final_damage,
		"life": 2.2,
		"color": color,
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
	})


func _count_hostile_projectiles() -> int:
	var count := 0
	for projectile in projectiles:
		if StringName(projectile["team"]) == &"enemy":
			count += 1
	return count


func _update_projectiles(delta: float) -> void:
	for index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[index]
		projectile["life"] = float(projectile["life"]) - delta
		if float(projectile["life"]) <= 0.0:
			projectiles.remove_at(index)
			continue
		projectile["reflector_lock_time"] = maxf(0.0, float(projectile.get("reflector_lock_time", 0.0)) - delta)
		if bool(projectile["homing"]):
			var target := _find_enemy_by_id(String(projectile["target_id"]))
			if not target.is_empty() and bool(target["alive"]):
				var desired := (Vector2(target["pos"]) - Vector2(projectile["pos"])).normalized()
				var current := Vector2(projectile["velocity"]).normalized()
				var steered := current.lerp(desired, clampf(delta * 4.2, 0.0, 1.0)).normalized()
				projectile["velocity"] = steered * Vector2(projectile["velocity"]).length()
		var from := Vector2(projectile["pos"])
		var to := from + Vector2(projectile["velocity"]) * delta
		var cover_hit := Rules.first_cover_hit_with_extra(from, to, float(projectile["radius"]), _boss_gate_closed(), current_stage_id, _runtime_projectile_cover_rects())
		var reflector_hit := Rules.first_reflector_hit(from, to, float(projectile["radius"]), reflector_orientations, current_stage_id, _stage_environment_zones)
		var reflector_id := StringName(reflector_hit.get("reflector_id", &""))
		var reflector_is_first := bool(reflector_hit.get("hit", false)) and (
			not bool(cover_hit.get("hit", false)) or float(reflector_hit["t"]) <= float(cover_hit["t"]) + 0.001
		)
		var reflector_unlocked := float(projectile.get("reflector_lock_time", 0.0)) <= 0.0 or StringName(projectile.get("reflector_lock", &"")) != reflector_id
		if reflector_is_first and reflector_unlocked:
			var speed := Vector2(projectile["velocity"]).length()
			projectile["velocity"] = Vector2(reflector_hit["out_direction"]) * speed
			projectile["pos"] = Vector2(reflector_hit["point"]) + Vector2(projectile["velocity"]).normalized() * (float(projectile["radius"]) + 12.0)
			projectile["reflector_lock"] = reflector_id
			projectile["reflector_lock_time"] = 0.16
			projectile["reflected"] = true
			_add_effect("reflect", Vector2(projectile["pos"]), Art.MINT, 0.24, 34.0, Vector2(projectile["velocity"]).normalized())
			_play_sound(&"cover", 1.28)
			continue
		if bool(cover_hit.get("hit", false)):
			if int(projectile["bounces"]) > 0:
				projectile["bounces"] = int(projectile["bounces"]) - 1
				var normal: Vector2 = cover_hit["normal"]
				projectile["velocity"] = Vector2(projectile["velocity"]).bounce(normal)
				projectile["pos"] = Vector2(cover_hit["point"]) + normal * (float(projectile["radius"]) + 2.0)
				_add_effect("impact", Vector2(projectile["pos"]), Rules.CYAN, 0.15, 18.0)
				continue
			_add_effect("impact", Vector2(cover_hit["point"]), Color(projectile["color"]), 0.14, 20.0)
			_play_sound(&"cover", _rng.randf_range(0.96, 1.04))
			projectiles.remove_at(index)
			continue

		projectile["pos"] = to
		if StringName(projectile["team"]) == &"enemy":
			if Rules.point_segment_distance(player_position, from, to) <= Rules.PLAYER_RADIUS + float(projectile["radius"]):
				_damage_player(float(projectile["damage"]), String(projectile["owner"]), true, true, bool(projectile.get("final_damage", false)))
				projectiles.remove_at(index)
				continue
		else:
			if _projectile_intercepted(projectile, from, to):
				projectiles.remove_at(index)
				continue
			if _projectile_hits_crate(projectile, from, to):
				projectiles.remove_at(index)
				continue
			var hit_enemy := _first_enemy_on_segment(from, to, float(projectile["radius"]))
			if not hit_enemy.is_empty():
				var hit_position := Vector2(hit_enemy["pos"])
				var enemy_damage := float(projectile["damage"])
				if StringName(hit_enemy["role"]) in [&"turret", &"mine", &"generator", &"interceptor_tower", &"beam_sentinel", &"boss_pylon"]:
					enemy_damage = float(projectile.get("structure_damage", enemy_damage))
				var opening_result := {"bonus_damage": 0.0, "splash_radius": 0.0}
				if bool(projectile.get("opening", false)):
					opening_result = StatusRuntime.resolve_opening(hit_enemy, run_build, enemy_damage)
				enemy_damage += float(opening_result["bonus_damage"])
				var damage_source := "reflected_%s" % String(projectile["owner"]) if bool(projectile.get("reflected", false)) else String(projectile["owner"])
				_damage_enemy(
					hit_enemy,
					enemy_damage,
					damage_source,
					float(projectile["stagger"])
				)
				if String(projectile["owner"]) == "player_primary" and run_build.has(&"marked_salvo"):
					_mark_enemy(hit_enemy)
				if bool(projectile.get("opening", false)) and run_build.has(&"shock_breach"):
					var shock_damage := _shock_breach_damage(enemy_damage)
					_damage_enemies_in_radius(hit_position, 90.0, shock_damage, 8.0, "Shock Breach", String(hit_enemy["id"]))
					_add_effect("shock", hit_position, Art.MUSTARD, 0.24, 90.0)
				if float(opening_result["splash_radius"]) > 0.0:
					_damage_enemies_in_radius(hit_position, float(opening_result["splash_radius"]), float(opening_result["bonus_damage"]), 0.0, "Flashover", String(hit_enemy["id"]))
				StatusRuntime.apply(hit_enemy, Dictionary(projectile.get("status_payload", {})))
				stats_primary_hits += 1 if String(projectile["owner"]) == "player_primary" else 0
				_add_effect("impact", hit_position, Color(projectile["color"]), 0.18, 24.0)
				_play_sound(&"impact", _rng.randf_range(0.92, 1.08))
				if bool(projectile["explosive"]):
					_damage_enemies_in_radius(hit_position, 95.0, 12.0, 8.0, "Seeker burst", String(hit_enemy["id"]))
					_add_effect("shock", hit_position, Rules.MOSS, 0.28, 95.0)
				if int(projectile["pierce"]) > 0:
					projectile["pierce"] = int(projectile["pierce"]) - 1
					projectile["pos"] = to + Vector2(projectile["velocity"]).normalized() * 8.0
				else:
					projectiles.remove_at(index)

func _mark_enemy(target: Dictionary) -> void:
	for enemy in enemies:
		enemy["marked_time"] = 0.0
	target["marked_time"] = 2.5


func _shock_breach_damage(opening_damage: float) -> float:
	return opening_damage * 0.45 * run_build.level_of(&"shock_breach")


func _projectile_intercepted(projectile: Dictionary, from: Vector2, to: Vector2) -> bool:
	if StringName(projectile["team"]) != &"player":
		return false
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		if StringName(enemy["role"]) != &"interceptor_tower" or int(enemy["intercept_charges"]) <= 0:
			continue
		if Rules.point_segment_distance(Vector2(enemy["pos"]), from, to) > 112.0 + float(projectile["radius"]):
			continue
		enemy["intercept_charges"] = int(enemy["intercept_charges"]) - 1
		enemy["intercept_recharge"] = 4.0
		_add_effect("shock", Vector2(enemy["pos"]), Rules.VIOLET, 0.24, 112.0)
		return true
	return false


func _projectile_hits_crate(projectile: Dictionary, from: Vector2, to: Vector2) -> bool:
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		if Rules.point_segment_distance(Vector2(crate["pos"]), from, to) <= 31.0 + float(projectile["radius"]):
			_damage_crate(crate, float(projectile.get("structure_damage", projectile["damage"])))
			_add_effect("impact", Vector2(crate["pos"]), Rules.AMBER, 0.16, 22.0)
			return true
	return false


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


func _first_enemy_on_segment(from: Vector2, to: Vector2, projectile_radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var position := Vector2(enemy["pos"])
		if Rules.point_segment_distance(position, from, to) > float(enemy["radius"]) + projectile_radius:
			continue
		var distance := from.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _find_enemy_by_id(enemy_id: String) -> Dictionary:
	for enemy in enemies:
		if String(enemy["id"]) == enemy_id:
			return enemy
	return {}


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
		if player_position.distance_to(Vector2(zone["pos"])) <= float(zone["radius"]) and float(zone["tick"]) <= 0.0:
			zone["tick"] = 0.62
			_damage_player(float(zone["damage"]), String(zone["source"]), false, true, bool(zone.get("final_damage", false)))


func _update_trails(delta: float) -> void:
	for index in range(damaging_trails.size() - 1, -1, -1):
		var trail: Dictionary = damaging_trails[index]
		trail["time"] = float(trail["time"]) - delta
		if float(trail["time"]) <= 0.0:
			damaging_trails.remove_at(index)
			continue
		var hit_ids: Dictionary = trail["hit_ids"]
		for enemy in enemies:
			if not bool(enemy["alive"]) or hit_ids.has(String(enemy["id"])):
				continue
			if Vector2(enemy["pos"]).distance_to(Vector2(trail["pos"])) <= float(trail["radius"]) + float(enemy["radius"]):
				hit_ids[String(enemy["id"])] = true
				_damage_enemy(enemy, 18.0, "Ion Wake", 12.0)


func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		effect["time"] = float(effect["time"]) - delta
		if String(effect["kind"]) == "scheduled_aftershock" and float(effect["time"]) <= 0.0:
			effects.remove_at(index)
			_release_emp(true)
			continue
		if float(effect["time"]) <= 0.0:
			effects.remove_at(index)


func _add_effect(kind: String, position: Vector2, color: Color, duration: float, radius: float, direction: Vector2 = Vector2.ZERO) -> void:
	if effects.size() >= EncounterDirector.EFFECT_CAP:
		for index in effects.size():
			if String(effects[index]["kind"]) != "scheduled_aftershock":
				effects.remove_at(index)
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


func _damage_enemy(enemy: Dictionary, amount: float, source: String, stagger: float = 0.0) -> float:
	if not bool(enemy["alive"]):
		return 0.0
	var role := StringName(enemy["role"])
	if role == &"boss_pylon" and bool(enemy.get("requires_reflection", false)) and not source.begins_with("reflected_"):
		enemy["health_visible_timer"] = 1.5
		_add_effect("barrier_hit", Vector2(enemy["pos"]), Art.MINT, 0.20, float(enemy["radius"]) * 1.25)
		return 0.0
	if cycle_runtime.is_active(&"overclock_cycle"):
		amount *= 1.35 if cycle_runtime.level(&"overclock_cycle") >= 2 else 1.25
	var multiplier := 1.0
	if bool(enemy["shielded"]):
		multiplier *= 0.45
	if float(enemy.get("shear_time", 0.0)) > 0.0:
		multiplier *= 1.20
	if role == &"rammer" and float(enemy.get("vulnerable", 0.0)) > 0.0:
		multiplier *= 1.50
	if role == &"stage_boss":
		if _boss_has_live_pylons():
			multiplier *= 0.28
		if float(enemy["vulnerable"]) > 0.0 or String(enemy["phase"]) == "staggered":
			multiplier *= 1.55
		enemy["stagger"] = float(enemy["stagger"]) + stagger
		if float(enemy["stagger"]) >= 100.0 and String(enemy["phase"]) != "staggered":
			enemy["stagger"] = 0.0
			enemy["phase"] = "staggered"
			enemy["phase_time"] = 3.0
			enemy["pattern"] = "stagger_window"
			enemy["vulnerable"] = 3.0
			_ui.notify(tr("NOTIFY_COLOSSUS_STAGGERED"), 2.8, Rules.AMBER)
			_play_sound(&"boss", 1.35)
	var health_before := float(enemy["health"])
	var applied_damage := minf(health_before, maxf(0.0, amount * multiplier))
	enemy["health"] = health_before - applied_damage
	enemy["flash"] = 0.11
	enemy["health_visible_timer"] = 1.0 if StringName(enemy.get("health_class", &"standard")) == &"swarm" else 1.5
	_apply_lifesteal(applied_damage, source, role)
	if float(enemy["health"]) <= 0.0:
		_defeat_enemy(enemy, source)
	return applied_damage


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


func _defeat_enemy(enemy: Dictionary, source: String) -> void:
	if not bool(enemy["alive"]):
		return
	var had_poison := Dictionary(enemy.get("statuses", {})).has(&"poison")
	enemy["alive"] = false
	enemy["active"] = false
	stats_enemies_defeated += 1
	var role := StringName(enemy["role"])
	var reward_source := &""
	if role == &"field_boss": reward_source = &"field_boss"
	elif role == &"stage_boss": reward_source = &"boss"
	experience_runtime.spawn_shard(Vector2(enemy["pos"]), FieldDropRules.experience_for_enemy(enemy), reward_source)
	if role in [&"generator", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"boss_pylon"]:
		stats_installations += 1
	if role == &"generator" and bool(enemy["required"]):
		generators_destroyed += 1
		if generators_destroyed >= 2:
			encounter_runtime.signal_event(&"generators_complete")
		_ui.notify(
			tr("NOTIFY_GENERATOR_DESTROYED") % generators_destroyed,
			2.8,
			Rules.AMBER
		)
	if role == &"field_boss":
		field_boss_defeated = true
		persistent_field_module = true
		_save_persistence()
		_ui.notify(tr("NOTIFY_FIELD_BOSS_SHARD"), 3.0, Rules.AMBER)
	if role == &"stage_boss":
		_complete_stage()
	var defeated_group := String(enemy.get("group_id", ""))
	if not defeated_group.is_empty():
		_try_group_completion_reward(defeated_group, Vector2(enemy["pos"]))
	if had_poison and run_build.has(&"contagion"):
		var poison_payload := StatusRuntime.payload(run_build)
		for target in enemies:
			if target != enemy and bool(target["alive"]) and Vector2(target["pos"]).distance_to(Vector2(enemy["pos"])) <= 100.0:
				StatusRuntime.apply(target, poison_payload)
	_add_effect("destroy", Vector2(enemy["pos"]), _enemy_color(role), 0.65 if role in [&"field_boss", &"stage_boss"] else 0.38, float(enemy["radius"]) * 1.8)
	_play_sound(
		&"destroy_priority"
		if role in [&"field_boss", &"stage_boss", &"generator", &"interceptor_tower", &"repair_tender", &"drone_carrier", &"beam_sentinel"]
		else &"destroy",
		1.0
	)
	_clear_zones_owned_by_defeated_role(role)


func _try_group_completion_reward(group_id: String, position: Vector2) -> void:
	if completed_group_rewards.has(group_id):
		return
	for candidate in enemies:
		if String(candidate.get("group_id", "")) == group_id and bool(candidate["alive"]):
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
	encounter_runtime.record_player_damage(_damage_source_family(source, enemy_source))
	player_health = maxf(0.0, player_health - remaining)
	stats_damage_taken += remaining
	player_hit_flash = 0.22
	player_invulnerable = 0.28
	camera_shake = maxf(camera_shake, 8.0)
	_last_damage_source = source
	_play_sound(&"hurt")
	if player_health <= 0.0:
		_handle_player_defeat()


func _scaled_incoming_damage(amount: float, enemy_source: bool, final_effective: bool = false) -> float:
	if not enemy_source or final_effective:
		return amount
	return amount * EncounterDirector.ENEMY_DAMAGE_MULTIPLIER * float(StageDifficulty.multipliers(current_stage_index)["damage"])


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
	projectiles.clear()
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
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]) or float(enemy["ram_cooldown"]) > 0.0:
			continue
		if player_position.distance_to(Vector2(enemy["pos"])) <= Rules.PLAYER_RADIUS + float(enemy["radius"]) + 5.0:
			enemy["ram_cooldown"] = 0.35
			_damage_enemy(enemy, 16.0, "Dash impact", 18.0)
			var push := (Vector2(enemy["pos"]) - player_position).normalized()
			enemy["pos"] = _move_actor(Vector2(enemy["pos"]), push * 45.0, float(enemy["radius"]), false)
			_add_effect("impact", Vector2(enemy["pos"]), Rules.AMBER, 0.20, 34.0)


func _repel_nearby_enemies(radius: float) -> void:
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var distance := player_position.distance_to(Vector2(enemy["pos"]))
		if distance <= radius and distance > 0.1:
			var push := (Vector2(enemy["pos"]) - player_position).normalized() * 95.0
			enemy["pos"] = _move_actor(Vector2(enemy["pos"]), push, float(enemy["radius"]), false)
			enemy["stun"] = maxf(float(enemy["stun"]), 0.75)


func _damage_enemies_in_radius(center: Vector2, radius: float, damage: float, stagger: float, source: String, excluded_id: String = "") -> void:
	for enemy in enemies:
		if not bool(enemy["alive"]) or String(enemy["id"]) == excluded_id:
			continue
		if Vector2(enemy["pos"]).distance_to(center) <= radius + float(enemy["radius"]):
			_damage_enemy(enemy, damage, source, stagger)


func _clear_hostile_projectiles(center: Vector2, radius: float) -> int:
	var cleared := 0
	for index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[index]
		if StringName(projectile["team"]) != &"enemy":
			continue
		if Vector2(projectile["pos"]).distance_to(center) <= radius:
			projectiles.remove_at(index)
			cleared += 1
	return cleared


func _update_aim_target() -> void:
	var ray_end := player_position + player_aim_direction * 900.0
	var best_id := ""
	var best_projection := INF
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var enemy_position := Vector2(enemy["pos"])
		if Rules.point_segment_distance(enemy_position, player_position, ray_end) > float(enemy["radius"]) + 22.0:
			continue
		var projection := (enemy_position - player_position).dot(player_aim_direction)
		if projection < 0.0 or projection > 900.0:
			continue
		if not _runtime_has_line_of_sight(player_position, enemy_position, 5.0):
			continue
		if projection < best_projection:
			best_projection = projection
			best_id = String(enemy["id"])
	_aim_target_id = best_id


func _update_stage_progression() -> void:
	var triggers := _objective_trigger_cache
	if not entered_approach and _trigger_contains(triggers.get("approach"), player_position):
		entered_approach = true
		encounter_runtime.signal_event(&"approach_entered")
	if not entered_installations and _trigger_contains(triggers.get("installations"), player_position):
		entered_installations = true
		encounter_runtime.signal_event(&"installations_entered")
		discovered_markers["generators"] = true
	if not encounter_runtime.has_event(&"upper_route_entered") and _trigger_contains(triggers.get("upper_route_event"), player_position):
		encounter_runtime.signal_event(&"upper_route_entered")
	if not encounter_runtime.has_event(&"lower_route_entered") and _trigger_contains(triggers.get("lower_route_event"), player_position):
		encounter_runtime.signal_event(&"lower_route_entered")

	if entered_approach and tutorial_announced and _trigger_contains(triggers.get("calibration"), player_position) and not _reward_claimed(&"calibration"):
		claimed_reward_sources[_reward_transaction_id(&"calibration")] = &"experience"
		experience_runtime.spawn_cluster(Vector2(StageCatalog.reward_anchors(current_stage_id)[&"calibration_cache"]), 18)
		encounter_runtime.signal_event(&"calibration_claimed")
		encounter_runtime.record_reward()
		_ui.notify(tr("NOTIFY_EXPERIENCE_CACHE"), 2.2, Art.MUSTARD)

	if not chest_claimed and generators_destroyed >= 2 and player_position.distance_to(_stage_landmark("chest")) <= 78.0:
		chest_claimed = true
		claimed_reward_sources[_reward_transaction_id(&"relay")] = &"experience"
		experience_runtime.spawn_cluster(Vector2(StageCatalog.reward_anchors(current_stage_id)[&"relay_cache"]), 30)
		encounter_runtime.record_reward()
		_ui.notify(tr("NOTIFY_EXPERIENCE_CACHE"), 2.2, Art.MUSTARD)

	if generators_destroyed >= 2 and chest_claimed and not boss_started and _trigger_contains(triggers.get("boss_start"), player_position):
		_start_stage_boss()

	if boss_started and boss_locked and not _stage_boss_arena().grow(-20.0).has_point(player_position):
		player_position = _stage_boss_arena().get_center()

	if _trigger_contains(triggers.get("field_boss_discovery"), player_position):
		discovered_markers["field_boss"] = true
		if current_stage_id == &"coral_switchyard" and not optional_branch_active and not optional_branch_failed and not field_boss_defeated:
			optional_branch_active = true
			optional_branch_timer = 26.0
			_ui.notify(tr("NOTIFY_CONVOY_DEPARTING"), 2.8, Art.CORAL)
	if _trigger_contains(triggers.get("relay_discovery"), player_position):
		discovered_markers["chest"] = true
	if _trigger_contains(triggers.get("boss_discovery"), player_position):
		discovered_markers["stage_boss"] = true


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
	_sync_cycle_upgrades()
	player_primary_weapon.set_full_opening_seconds(_opening_charge_seconds())
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
		_open_upgrade_reward(source, source == &"field_boss")
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


func _boss_gate_closed() -> bool:
	if boss_locked:
		return true
	return not (generators_destroyed >= 2 and chest_claimed)


func _start_stage_boss() -> void:
	if boss_started:
		return
	boss_started = true
	boss_locked = true
	discovered_markers["stage_boss"] = true
	var boss := _make_enemy({
		"id": "stage_boss",
		"role": "stage_boss",
		"pos": _stage_landmark("boss"),
		"zone": "boss",
		"name_key": StageCatalog.profile(current_stage_id)["boss_name_key"],
	})
	boss["active"] = true
	boss["phase"] = "boss_read"
	boss["phase_time"] = 1.35
	boss["pattern"] = "system_wake"
	enemies.append(boss)
	if current_stage_id == &"abyssal_observatory":
		_spawn_boss_pylons()
	projectiles.clear()
	denied_zones.clear()
	_play_sound(&"boss")
	camera_shake = 12.0


func _update_stage_boss(boss: Dictionary, delta: float) -> void:
	if not bool(boss["alive"]):
		return
	var health_ratio := float(boss["health"]) / float(boss["max_health"])
	if health_ratio <= 0.5 and int(boss["boss_phase"]) == 1:
		boss["boss_phase"] = 2
		boss["phase"] = "boss_read"
		boss["phase_time"] = 1.8
		boss["pattern"] = "phase_two"
		boss["pattern_index"] = 0
		boss_phase_two_announced = true
		_ui.notify(tr("NOTIFY_COLOSSUS_PHASE_TWO"), 3.4, Rules.VIOLET)
		_play_sound(&"boss", 0.78)

	if String(boss["phase"]) == "staggered":
		boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
		if float(boss["phase_time"]) <= 0.0:
			boss["phase"] = "boss_read"
			boss["phase_time"] = 0.85
			boss["pattern"] = "recovering_control"
		return

	var phase := String(boss["phase"])
	if phase == "boss_read":
		boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
		_boss_reposition(boss, delta)
		if float(boss["phase_time"]) <= 0.0:
			_boss_select_pattern(boss)
		return
	if phase == "boss_startup":
		boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
		if float(boss["phase_time"]) <= 0.0:
			_boss_begin_active(boss)
		return
	if phase == "boss_active":
		_boss_update_active(boss, delta)
		return
	if phase == "boss_recovery":
		boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
		_boss_reposition(boss, delta)
		if float(boss["phase_time"]) <= 0.0:
			boss["phase"] = "boss_read"
			boss["phase_time"] = 0.60 if int(boss["boss_phase"]) == 2 else 0.75
			boss["pattern"] = "reading_arena"


func _boss_select_pattern(boss: Dictionary) -> void:
	var phase_two := int(boss["boss_phase"]) == 2
	var patterns: Array[String] = BossPatterns.sequence(current_stage_id, phase_two)
	var index := int(boss["pattern_index"]) % patterns.size()
	var pattern := patterns[index]
	boss["pattern_index"] = int(boss["pattern_index"]) + 1
	boss["pattern"] = pattern
	boss["phase"] = "boss_startup"
	boss["phase_time"] = BossPatterns.startup_seconds(pattern)
	boss["hit_committed"] = false
	var kind := BossPatterns.kind(pattern)
	boss["committed_target"] = player_position
	boss["committed_dir"] = (player_position - Vector2(boss["pos"])).normalized()
	if kind == &"lanes":
		var base_y := clampf(player_position.y, _stage_boss_arena().position.y + 190.0, _stage_boss_arena().end.y - 190.0)
		boss["lane_centers"] = [base_y - 170.0, base_y + 170.0]
	elif pattern == "open_lane_charge":
		boss["committed_target"] = Vector2(_stage_boss_arena().position.x + 100.0, _switchyard_open_lane_y())
		boss["committed_dir"] = (Vector2(boss["committed_target"]) - Vector2(boss["pos"])).normalized()
	if kind == &"beam":
		boss["beam_end"] = SpecialistRuntime.beam_end(Vector2(boss["pos"]), Vector2(boss["committed_dir"]), current_stage_id, false, _runtime_cover_rects())


func _boss_begin_active(boss: Dictionary) -> void:
	boss["phase"] = "boss_active"
	boss["pattern_tick"] = 0.0
	var pattern := String(boss["pattern"])
	boss["phase_time"] = BossPatterns.active_seconds(pattern)
	boss["pattern_fired"] = false
	var kind := BossPatterns.kind(pattern)
	if kind == &"pylons":
		_spawn_boss_pylons()
	elif kind == &"summon":
		for child_index in 3:
			_spawn_carrier_child(boss)


func _boss_update_active(boss: Dictionary, delta: float) -> void:
	boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
	boss["pattern_tick"] = float(boss["pattern_tick"]) - delta
	var pattern := String(boss["pattern"])
	var kind := BossPatterns.kind(pattern)
	var damage := BossPatterns.damage(pattern)
	if kind == &"lanes" and float(boss["pattern_tick"]) <= 0.0:
		boss["pattern_tick"] = 0.32
		for lane_y_variant in boss["lane_centers"]:
			_spawn_hostile_projectile(Vector2(_stage_boss_arena().end.x - 70.0, float(lane_y_variant)), Vector2.LEFT, damage, 690.0, pattern, Rules.VIOLET, true)
	elif kind in [&"fan", &"cross"] and not bool(boss["pattern_fired"]):
		boss["pattern_fired"] = true
		var offsets := [-0.34, -0.17, 0.0, 0.17, 0.34] if kind == &"fan" else [0.0, PI * 0.5, PI, PI * 1.5]
		for offset in offsets:
			_spawn_hostile_projectile(Vector2(boss["pos"]) + Vector2(boss["committed_dir"]) * 72.0, Vector2(boss["committed_dir"]).rotated(float(offset)), damage, 560.0, pattern, Rules.VIOLET, true)
	elif kind == &"charge":
		var before := Vector2(boss["pos"])
		var requested := Vector2(boss["committed_dir"]) * 790.0 * EncounterDirector.ENEMY_SPEED_MULTIPLIER * delta
		boss["pos"] = _move_actor(before, requested, float(boss["radius"]), false)
		if not bool(boss["hit_committed"]) and player_position.distance_to(Vector2(boss["pos"])) <= Rules.PLAYER_RADIUS + float(boss["radius"]) + 10.0:
			boss["hit_committed"] = true
			_damage_player(damage, pattern, true, true, true)
		if before.distance_to(Vector2(boss["pos"])) + 1.0 < requested.length():
			boss["phase_time"] = 0.0
	elif kind == &"beam":
		if not bool(boss["hit_committed"]) and Rules.point_segment_distance(player_position, Vector2(boss["pos"]), Vector2(boss["beam_end"])) <= Rules.PLAYER_RADIUS + BossPatterns.width(pattern) * 0.5:
			boss["hit_committed"] = true
			_damage_player(damage, pattern, true, true, true)
	elif kind in [&"area", &"pylons", &"summon"] and damage > 0.0:
		if not bool(boss["hit_committed"]) and player_position.distance_to(Vector2(boss["committed_target"])) <= BossPatterns.radius(pattern):
			boss["hit_committed"] = true
			_damage_player(damage, pattern, false, true, true)

	if float(boss["phase_time"]) <= 0.0:
		boss["phase"] = "boss_recovery"
		boss["phase_time"] = BossPatterns.recovery_seconds(pattern)
		boss["vulnerable"] = 1.55 if kind in [&"charge", &"area"] else 0.65
		boss["last_pattern"] = pattern
		boss["pattern"] = "recovery_window"


func _boss_reposition(boss: Dictionary, delta: float) -> void:
	var center := _stage_boss_arena().get_center() + Vector2(220.0, 0.0)
	var desired := center + Vector2(
		cos(run_time * 0.55) * 180.0,
		sin(run_time * 0.72) * 310.0
	)
	var direction := (desired - Vector2(boss["pos"])).normalized()
	boss["pos"] = _move_actor(
		Vector2(boss["pos"]),
		direction * float(boss["speed"]) * delta,
		float(boss["radius"]),
		false
	)


func _spawn_boss_pylons() -> void:
	var positions: Array[Vector2] = []
	var reflection_required := current_stage_id == &"abyssal_observatory"
	if reflection_required:
		for zone in _stage_mechanic_zones(&"reflector"):
			positions.append(Vector2(zone["relay_position"]))
	else:
		var arena := _stage_boss_arena()
		positions = [arena.position + Vector2(arena.size.x * 0.38, arena.size.y * 0.25), arena.position + Vector2(arena.size.x * 0.38, arena.size.y * 0.75)]
	for position in positions:
		var existing := false
		for enemy in enemies:
			if bool(enemy["alive"]) and StringName(enemy["role"]) == &"boss_pylon" and Vector2(enemy["pos"]).distance_to(position) < 40.0:
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
		pylon["active"] = true
		enemies.append(pylon)
		_add_effect("spawn", position, Rules.VIOLET, 0.55, 78.0)
	_ui.notify(tr("NOTIFY_CROWN_RELAYS") if reflection_required else tr("NOTIFY_COLOSSUS_PYLONS"), 2.8, Rules.VIOLET)


func _boss_has_live_pylons() -> bool:
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) == &"boss_pylon":
			return true
	return false


func _update_field_boss(enemy: Dictionary, delta: float) -> void:
	var leash := Rect2(enemy.get("leash_rect", Rect2()))
	if not leash.has_area():
		var trigger: Variant = _objective_trigger_cache.get("field_boss_discovery")
		if trigger is Rect2:
			leash = Rect2(trigger)
	if leash.has_area() and not leash.grow(80.0).has_point(player_position):
		var home_direction := (Vector2(enemy["home"]) - Vector2(enemy["pos"]))
		if home_direction.length() > 20.0:
			enemy["pos"] = _move_actor(
				Vector2(enemy["pos"]),
				home_direction.normalized() * float(enemy["speed"]) * delta,
				float(enemy["radius"]),
				false
			)
		enemy["phase"] = "move"
		enemy["attack_cooldown"] = maxf(float(enemy["attack_cooldown"]), 0.6)
		return
	if current_stage_id == &"coral_switchyard" and optional_branch_active:
		for zone in _stage_mechanic_zones(&"convoy_route"):
			var convoy_progress := clampf(1.0 - optional_branch_timer / float(zone["duration"]), 0.0, 1.0)
			enemy["home"] = Vector2(zone["start"]).lerp(Vector2(zone["end"]), convoy_progress)
			var convoy_motion := Vector2(enemy["home"]) - Vector2(enemy["pos"])
			if convoy_motion.length() > 8.0:
				enemy["pos"] = _move_actor(Vector2(enemy["pos"]), convoy_motion.normalized() * 72.0 * delta, float(enemy["radius"]), false)
			break
		enemy["support_tick"] = maxf(0.0, float(enemy["support_tick"]) - delta)
		if float(enemy["support_tick"]) <= 0.0:
			enemy["support_tick"] = 0.5
			for target in enemies:
				if target != enemy and bool(target["alive"]) and String(target.get("zone", "")) == "field_boss" and Vector2(target["pos"]).distance_to(Vector2(enemy["pos"])) <= 360.0:
					target["health"] = minf(float(target["max_health"]), float(target["health"]) + 2.0)
	if float(enemy["stun"]) > 0.0:
		return
	enemy["attack_cooldown"] = maxf(0.0, float(enemy["attack_cooldown"]) - delta)
	var phase := String(enemy["phase"])
	if phase == "startup":
		enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
		if float(enemy["phase_time"]) <= 0.0:
			_field_boss_execute(enemy)
		return
	if phase == "active":
		enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
		var active_pattern := String(enemy["pattern"])
		var active_definition := BossPatterns.field_definition(active_pattern)
		var active_kind := StringName(active_definition["kind"])
		if active_kind == &"charge":
			enemy["pos"] = _move_actor(
				Vector2(enemy["pos"]),
				Vector2(enemy["committed_dir"]) * 660.0 * EncounterDirector.ENEMY_SPEED_MULTIPLIER * delta,
				float(enemy["radius"]),
				false
			)
			if not bool(enemy["hit_committed"]) and player_position.distance_to(Vector2(enemy["pos"])) <= Rules.PLAYER_RADIUS + float(enemy["radius"]):
				enemy["hit_committed"] = true
				_damage_player(float(active_definition["damage"]), active_pattern, true, true, true)
		elif active_kind == &"area" and not bool(enemy["hit_committed"]):
			if player_position.distance_to(Vector2(enemy["committed_target"])) <= float(active_definition["radius"]):
				enemy["hit_committed"] = true
				_damage_player(float(active_definition["damage"]), active_pattern, false, true, true)
		if float(enemy["phase_time"]) <= 0.0:
			enemy["phase"] = "recovery"
			enemy["phase_time"] = float(active_definition["recovery"])
		return
	if phase == "recovery":
		enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
		_field_boss_orbit(enemy, delta)
		if float(enemy["phase_time"]) <= 0.0:
			enemy["phase"] = "move"
			enemy["attack_cooldown"] = 0.8
		return

	_field_boss_orbit(enemy, delta)
	if float(enemy["attack_cooldown"]) <= 0.0:
		var patterns := BossPatterns.field_sequence(current_stage_id)
		var pattern: StringName = patterns[int(enemy["pattern_index"]) % patterns.size()]
		var field_definition := BossPatterns.field_definition(String(pattern))
		enemy["pattern_index"] = int(enemy["pattern_index"]) + 1
		enemy["pattern"] = pattern
		enemy["phase"] = "startup"
		enemy["phase_time"] = float(field_definition["startup"])
		enemy["committed_dir"] = (player_position - Vector2(enemy["pos"])).normalized()
		enemy["committed_target"] = player_position
		enemy["hit_committed"] = false


func _field_boss_orbit(enemy: Dictionary, delta: float) -> void:
	var to_player := player_position - Vector2(enemy["pos"])
	var distance := maxf(1.0, to_player.length())
	var direction := to_player / distance
	var desired := direction.rotated(PI * 0.5 * float(enemy["strafe_sign"]))
	if distance > 470.0:
		desired = (desired + direction * 0.7).normalized()
	elif distance < 300.0:
		desired = (desired - direction * 0.8).normalized()
	_move_enemy_with_recovery(enemy, desired * float(enemy["speed"]), delta)


func _field_boss_execute(enemy: Dictionary) -> void:
	var pattern := String(enemy["pattern"])
	var field_definition := BossPatterns.field_definition(pattern)
	var kind := StringName(field_definition["kind"])
	if kind == &"fan":
		for offset in [-0.30, -0.15, 0.0, 0.15, 0.30]:
			_spawn_hostile_projectile(
				Vector2(enemy["pos"]) + Vector2(enemy["committed_dir"]) * 50.0,
				Vector2(enemy["committed_dir"]).rotated(float(offset)),
				float(field_definition["damage"]), 520.0, pattern, Rules.VIOLET, true
			)
		enemy["phase"] = "recovery"
		enemy["phase_time"] = float(field_definition["recovery"])
	else:
		enemy["phase"] = "active"
		enemy["phase_time"] = float(field_definition["active"])


func _complete_stage() -> void:
	if stage_complete or pending_stage_completion:
		return
	pending_stage_completion = true
	boss_locked = false
	projectiles.clear()
	denied_zones.clear()
	_ui.notify(tr("NOTIFY_BOSS_SHARD"), 3.0, Rules.AMBER)


func _finalize_stage_completion() -> void:
	if stage_complete:
		return
	stage_complete = true
	pending_stage_completion = false
	boss_locked = false
	var has_next_stage := current_stage_index < StageCatalog.STAGE_IDS.size() - 1
	if not has_next_stage:
		persistent_clear_count += 1
		persistent_relay_module = true
		_save_persistence()
	projectiles.clear()
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
		"field_boss_defeated": field_boss_defeated,
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


func _build_hud_snapshot() -> Dictionary:
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
		var target_class := StringName(target.get("health_class", &"standard"))
		var target_role := StringName(target.get("role", &""))
		var show_priority_target := target_class == &"priority" or (target_class == &"boss" and target_role != &"stage_boss")
		if not target.is_empty() and bool(target["alive"]) and show_priority_target:
			target_snapshot = {
				"visible": true,
				"name": tr(String(target["name"])),
				"health": float(target["health"]),
				"max_health": float(target["max_health"]),
				"state": _enemy_state_text(target),
			}

	var boss_snapshot := {"visible": false}
	var boss := _find_enemy_by_id("stage_boss")
	if not boss.is_empty() and bool(boss["alive"]):
		boss_snapshot = {
			"visible": true,
			"name": tr("ENEMY_BOSS_PHASE") % [tr(String(boss["name"])), int(boss["boss_phase"])],
			"health": float(boss["health"]),
			"max_health": float(boss["max_health"]),
			"state": _boss_state_text(boss),
		}

	return {
		"health": player_health,
		"max_health": _player_max_health(),
		"level": int(experience_snapshot["level"]),
		"experience": int(experience_snapshot["experience"]),
		"experience_required": int(experience_snapshot["required"]),
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
		"minimap": _minimap_snapshot(),
		"threat_radar": _threat_radar_snapshot(),
		"status_orbit": {"center":get_canvas_transform() * player_position, "states":cycle_runtime.hud_states(), "reduced_motion":_reduced_motion_enabled()},
	}


func _objective_text() -> Array[String]:
	var profile := StageCatalog.profile(current_stage_id)
	var stage_name := tr(String(profile["title_key"]))
	var boss_name := tr(String(profile["boss_name_key"]))
	if boss_started:
		return [tr("OBJECTIVE_BOSS_STAGE").replace("%s", boss_name), tr("OBJECTIVE_BOSS_DETAIL")]
	if generators_destroyed < 2 and entered_installations:
		return [
			tr("OBJECTIVE_GENERATORS") % generators_destroyed,
			tr("OBJECTIVE_GENERATORS_DETAIL_GENERIC"),
		]
	if generators_destroyed >= 2 and not chest_claimed:
		return [tr("OBJECTIVE_CACHE"), tr("OBJECTIVE_CACHE_DETAIL")]
	if generators_destroyed >= 2 and chest_claimed:
		return [tr("OBJECTIVE_BASIN_STAGE").replace("%s", boss_name), tr("OBJECTIVE_BASIN_DETAIL")]
	if entered_approach:
		return [tr("OBJECTIVE_APPROACH_STAGE").replace("%s", stage_name), tr("OBJECTIVE_APPROACH_DETAIL")]
	return [tr("OBJECTIVE_CALIBRATE"), tr("OBJECTIVE_CALIBRATE_DETAIL") % [
		"✓" if tutorial_move else "—",
		"✓" if tutorial_aim else "—",
		"✓" if tutorial_fire else "—",
		"✓" if tutorial_dash else "—",
	]]


func _enemy_state_text(enemy: Dictionary) -> String:
	var parts: Array[String] = []
	if bool(enemy["shielded"]):
		parts.append(tr("ENEMY_STATE_GENERATOR_SHIELD"))
	if float(enemy["stun"]) > 0.0:
		parts.append(tr("ENEMY_STATE_STUNNED"))
	var phase := String(enemy["phase"])
	if phase == "startup":
		parts.append(tr("ENEMY_STATE_STARTUP"))
	elif phase == "active":
		parts.append(tr("ENEMY_STATE_ACTIVE"))
	elif phase == "recovery":
		parts.append(tr("ENEMY_STATE_RECOVERY"))
	elif StringName(enemy["role"]) == &"generator":
		parts.append(tr("ENEMY_STATE_SUPPORT"))
	if parts.is_empty():
		parts.append(tr("ENEMY_STATE_REPOSITION"))
	return "  •  ".join(parts)


func _boss_state_text(boss: Dictionary) -> String:
	var pattern := _localized_pattern(String(boss["pattern"]))
	if _boss_has_live_pylons():
		return tr("BOSS_STATE_PYLON_SHIELD") % pattern
	if float(boss["vulnerable"]) > 0.0 or String(boss["phase"]) == "staggered":
		return tr("BOSS_STATE_DAMAGE_WINDOW") % pattern
	return pattern


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
		"stagger_window": "PATTERN_STAGGER_WINDOW",
		"recovery_window": "PATTERN_RECOVERY_WINDOW",
		"twin_foundry_lanes": "PATTERN_TWIN_FOUNDRY_LANES",
		"foundry_ram": "PATTERN_FOUNDRY_RAM",
		"furnace_ring": "PATTERN_FURNACE_RING",
		"pylon_overload": "PATTERN_PYLON_OVERLOAD",
		"current_fan": "PATTERN_CURRENT_FAN",
		"undertow_sweep": "PATTERN_UNDERTOW_SWEEP",
		"depth_charge": "PATTERN_DEPTH_CHARGE",
		"archive_ram": "PATTERN_ARCHIVE_RAM",
		"arc_lanes": "PATTERN_ARC_LANES",
		"grounded_ring": "PATTERN_GROUNDED_RING",
		"thunder_drop": "PATTERN_THUNDER_DROP",
		"escort_surge": "PATTERN_ESCORT_SURGE",
		"open_lane_charge": "PATTERN_OPEN_LANE_CHARGE",
		"gate_shockwave": "PATTERN_GATE_SHOCKWAVE",
		"ricochet_volley": "PATTERN_RICOCHET_VOLLEY",
		"switch_sweep": "PATTERN_SWITCH_SWEEP",
		"crown_beam": "PATTERN_CROWN_BEAM",
		"mirror_cross": "PATTERN_MIRROR_CROSS",
		"carrier_wave": "PATTERN_CARRIER_WAVE",
		"relay_pulse": "PATTERN_RELAY_PULSE",
	}.get(pattern, pattern)
	return tr(String(key))


func _minimap_snapshot() -> Dictionary:
	var visited: Array[Vector2i] = []
	for cell in visited_cells.keys():
		visited.append(cell)
	var markers: Array[Dictionary] = [
		{
			"kind": "objective",
			"position": _stage_landmark("generator_a"),
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("generators", false)),
		},
		{
			"kind": "objective",
			"position": _stage_landmark("generator_b"),
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("generators", false)),
		},
		{
			"kind": "boss",
			"position": _stage_landmark("field_boss"),
			"color": Rules.VIOLET,
			"discovered": bool(discovered_markers.get("field_boss", false)),
		},
		{
			"kind": "reward",
			"position": _stage_landmark("chest"),
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("chest", false)),
		},
		{
			"kind": "boss",
			"position": _stage_landmark("boss"),
			"color": Rules.CORAL,
			"discovered": bool(discovered_markers.get("stage_boss", false)),
		},
	]
	for pickup in pickups:
		if bool(pickup["active"]) and _is_world_position_visited(Vector2(pickup["pos"])):
			markers.append({
				"kind": "reward",
				"position": Vector2(pickup["pos"]),
				"color": _pickup_color(StringName(pickup["kind"])),
				"discovered": true,
			})
	if current_stage_id == &"coral_switchyard":
		for zone in _stage_mechanic_zones(&"switch_pad"):
			markers.append({"kind":"mechanic", "position":Vector2(zone["center"]), "color":Art.MUSTARD, "discovered":true, "orientation":switchyard_gate_state})
		for gate_rect in _runtime_cover_rects():
			markers.append({"kind":"blocker", "position":gate_rect.get_center(), "color":Art.MUSTARD, "discovered":true})
	elif current_stage_id == &"abyssal_observatory":
		for zone in _stage_mechanic_zones(&"reflector"):
			var reflector_id := StringName(zone["id"])
			markers.append({
				"kind":"mechanic", "position":Vector2(zone["center"]), "color":Art.MINT,
				"discovered":true, "orientation":int(reflector_orientations.get(reflector_id, 0)),
			})
	var blocker_polygons: Array = Rules.get_cover_polygons(_boss_gate_closed(), current_stage_id).duplicate()
	for rect in _runtime_cover_rects():
		blocker_polygons.append(StageGeometry.rect_polygon(rect))
	return {
		"cols": MINIMAP_COLS,
		"rows": MINIMAP_ROWS,
		"visited": visited,
		"player": player_position,
		"world_size": Rules.world_rect(current_stage_id).size,
		"floor_polygons": StageCatalog.floor_polygons(current_stage_id),
		"water_polygons": StageCatalog.water_polygons(current_stage_id),
		"blocker_polygons": blocker_polygons,
		"markers": markers,
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
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		var offset := Vector2(enemy["pos"]) - player_position
		if offset.length_squared() > THREAT_SCAN_DISTANCE * THREAT_SCAN_DISTANCE:
			continue
		if safe_viewport.has_point(canvas_transform * Vector2(enemy["pos"])):
			continue
		var health_class := StringName(enemy.get("health_class", &"standard"))
		contacts.append({
			"offset": offset,
			"priority": health_class in [&"priority", &"boss"],
			"targeted": String(enemy["id"]) == _aim_target_id,
		})
	_threat_contact_cache = contacts


func _threat_radar_snapshot() -> Dictionary:
	return {
		"visible": mode == RunMode.PLAYING,
		"center": get_canvas_transform() * player_position,
		"max_distance": THREAT_SCAN_DISTANCE,
		"contacts": _threat_contact_cache,
	}


func _draw() -> void:
	_draw_boss_gate()
	_draw_stage_mechanics()
	_draw_landmarks()
	_draw_zones_and_trails()
	_draw_pickups_and_crates()
	_draw_enemies()
	_draw_projectiles()
	_draw_effects()
	_draw_player()
	_draw_aim_feedback()
	if _debug_collision_overlay:
		_draw_debug_collision_overlay()


func _draw_debug_collision_overlay() -> void:
	for polygon in StageCatalog.floor_polygons(current_stage_id):
		_draw_closed_polyline(PackedVector2Array(polygon), Color(Art.MINT, 0.92), 9.0)
	for polygon in StageCatalog.cover_polygons(current_stage_id):
		var blocker := PackedVector2Array(polygon)
		draw_colored_polygon(blocker, Color(Art.CORAL, 0.22))
		_draw_closed_polyline(blocker, Color(Art.CORAL, 0.96), 10.0)
	if _boss_gate_closed():
		var boss_gate_polygon := StageGeometry.rect_polygon(_stage_boss_gate())
		draw_colored_polygon(boss_gate_polygon, Color(Art.BOSS_MAGENTA, 0.24))
		_draw_closed_polyline(boss_gate_polygon, Art.BOSS_MAGENTA, 10.0)
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


func _draw_boss_gate() -> void:
	if _boss_gate_closed():
		draw_rect(_stage_boss_gate(), Art.BLOCKER_FILL)
		var gate_center := _stage_boss_gate().get_center()
		for offset in [-150.0, -50.0, 50.0, 150.0]:
			draw_rect(Rect2(gate_center + Vector2(-24.0, offset - 14.0), Vector2(48.0, 28.0)), Art.MUSTARD)


func _draw_stage_mechanics() -> void:
	if current_stage_id == &"coral_switchyard":
		for zone in _stage_mechanic_zones(&"switch_gate"):
			var positions: Array = zone["positions"]
			for state_index in positions.size():
				var rect := Rect2(positions[state_index])
				draw_colored_polygon(Art.stepped_rect(rect, 18.0), Color(Art.CERAMIC_GREEN_MID, 0.16))
			var active_rect := Rect2(positions[switchyard_gate_state % positions.size()])
			draw_rect(active_rect, Art.BLOCKER_FILL)
			for marker_y in range(int(active_rect.position.y + 90.0), int(active_rect.end.y), 150):
				draw_colored_polygon(_regular_polygon(Vector2(active_rect.get_center().x, marker_y), 17.0, 4, PI / 4.0), Art.MUSTARD)
		for zone in _stage_mechanic_zones(&"switch_pad"):
			var center := Vector2(zone["center"])
			var radius := float(zone["radius"])
			draw_circle(center, radius, Color(Art.MUSTARD, 0.14))
			draw_arc(center, radius, 0.0, TAU, 36, Art.MUSTARD, 12.0)
			draw_colored_polygon(_regular_polygon(center, 34.0, 4, PI / 4.0), Art.CERAMIC_GREEN)
	elif current_stage_id == &"abyssal_observatory":
		for rect in _runtime_cover_rects():
			draw_rect(rect, Art.BLOCKER_FILL)
		for zone in _stage_mechanic_zones(&"reflector_console"):
			var center := Vector2(zone["center"])
			draw_circle(center, float(zone["radius"]), Color(Art.MINT, 0.14))
			draw_arc(center, float(zone["radius"]), 0.0, TAU, 32, Art.MINT, 11.0)
			draw_colored_polygon(_regular_polygon(center, 31.0, 6, PI / 6.0), Art.MUSTARD)
		for zone in _stage_mechanic_zones(&"reflector"):
			var reflector_id := StringName(zone["id"])
			var orientation := Rules.positive_mod(int(reflector_orientations.get(reflector_id, zone["initial_orientation"])), 4)
			var center := Vector2(zone["center"])
			var direction := Vector2.RIGHT.rotated(float(orientation) * PI * 0.5)
			draw_circle(center + Vector2(10.0, 12.0), 78.0, Art.COBALT_DEEP)
			draw_colored_polygon(_regular_polygon(center, 78.0, 4, PI / 4.0), Art.MINT)
			draw_line(center - direction * 44.0, center + direction * 44.0, Art.IVORY_BRIGHT, 18.0)
			draw_colored_polygon(PackedVector2Array([
				center + direction * 54.0,
				center + direction.rotated(2.45) * 29.0,
				center + direction.rotated(-2.45) * 29.0,
			]), Art.MUSTARD)
		var diagram_center := Vector2(600.0, 1500.0)
		for index in 2:
			var direction := Vector2.RIGHT.rotated(float(index * 2) * PI * 0.5)
			var center := diagram_center + Vector2(0.0, -95.0 + float(index) * 190.0)
			draw_line(center - direction * 55.0, center + direction * 55.0, Color(Art.MINT, 0.58), 14.0)


func _draw_landmarks() -> void:
	if not chest_claimed:
		var chest_position := _stage_landmark("chest")
		var chest_rect := Rect2(chest_position - Art.CACHE_HALF_SIZE, Art.CACHE_HALF_SIZE * 2.0)
		var edge := chest_rect
		edge.position += Vector2(10.0, 14.0)
		draw_colored_polygon(Art.stepped_rect(edge, 18.0), Art.MUSTARD_DARK)
		draw_colored_polygon(Art.stepped_rect(chest_rect, 18.0), Art.MUSTARD)
		draw_colored_polygon(_regular_polygon(chest_position, 25.0, 4, PI / 4.0), Art.IVORY_BRIGHT)
		draw_colored_polygon(_regular_polygon(chest_position, 12.0, 4, PI / 4.0), Art.CERAMIC_GREEN)
	if generators_destroyed >= 2 and chest_claimed and not boss_started:
		var exit_center := _stage_landmark("boss_gate")
		var pulse := 54.0 if _reduced_motion_enabled() else 54.0 + sin(run_time * 3.0) * 7.0
		draw_circle(exit_center, pulse, Color(Art.MUSTARD, 0.28))
		draw_colored_polygon(_regular_polygon(exit_center, 24.0, 4, PI / 4.0), Art.MUSTARD)


func _draw_zones_and_trails() -> void:
	for environment_zone in _stage_environment_zones:
		if current_stage_id == &"tidal_archive":
			var environment_rect: Rect2 = environment_zone["rect"]
			draw_rect(environment_rect, Color(Art.COBALT_WATER, 0.34))
			var direction := Vector2(environment_zone["direction"])
			for x in range(int(environment_rect.position.x + 90.0), int(environment_rect.end.x), 180):
				var center := Vector2(float(x), environment_rect.get_center().y)
				draw_line(center - direction * 30.0, center + direction * 30.0, Color(Art.IVORY_BRIGHT, 0.64), 9.0)
				draw_colored_polygon(PackedVector2Array([
					center + direction * 42.0,
					center + direction.rotated(2.45) * 24.0,
					center + direction.rotated(-2.45) * 24.0,
				]), Color(Art.IVORY_BRIGHT, 0.64))
		elif current_stage_id == &"storm_drydock":
			var environment_rect: Rect2 = environment_zone["rect"]
			var phase := fmod(environment_time + float(environment_zone["phase"]), 5.2)
			var active := phase >= 1.4 and phase < 2.2
			var warning := phase < 1.4
			var color := Color(Art.BOSS_MAGENTA, 0.34 if active else (0.18 if warning else 0.06))
			draw_rect(environment_rect, color)
			if active or warning:
				for x in range(int(environment_rect.position.x + 70.0), int(environment_rect.end.x), 180):
					draw_line(Vector2(x, environment_rect.position.y + 24.0), Vector2(x + 90.0, environment_rect.end.y - 24.0), Art.IVORY_BRIGHT if active else Art.BOSS_MAGENTA, 8.0)
	for zone in denied_zones:
		var position := Vector2(zone["pos"])
		var radius := float(zone["radius"])
		var color := Color(zone["color"])
		if float(zone["warning"]) > 0.0:
			var progress := 1.0 - float(zone["warning"]) / 0.82
			draw_circle(position, radius, Color(Art.CORAL, 0.10))
			draw_arc(position, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Art.CORAL, 11.0)
			draw_colored_polygon(_regular_polygon(position, 13.0, 4, PI / 4.0), Art.CORAL)
		else:
			draw_circle(position, radius, Color(Art.CORAL, 0.30))
			draw_circle(position, radius * 0.70, Color(Art.CORAL_DARK, 0.16))
	for trail in damaging_trails:
		var alpha := clampf(float(trail["time"]) / float(trail["duration"]), 0.0, 1.0)
		draw_circle(Vector2(trail["pos"]), float(trail["radius"]), Color(Art.MUSTARD, alpha * 0.28))


func _draw_pickups_and_crates() -> void:
	for shard in experience_runtime.shards:
		var shard_position := Vector2(shard["pos"])
		var value := int(shard["value"])
		var radius := 9.0 if value == 1 else (12.0 if value <= 4 else 17.0)
		var shape := _regular_polygon(shard_position, radius, 4, PI / 4.0)
		if value in [2, 3, 4]:
			shape = _regular_polygon(shard_position, radius, 6, PI / 6.0)
		elif value >= 5:
			shape = _core_polygon(shard_position, radius)
		var shadow := PackedVector2Array()
		for point in shape:
			shadow.append(point + Vector2(3.0, 4.0))
		draw_colored_polygon(shadow, Art.COBALT_DEEP)
		draw_colored_polygon(shape, Art.MUSTARD)
		if value >= 5:
			draw_circle(shard_position, radius * 0.34, Art.IVORY_BRIGHT)
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
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		if not visible_world.has_point(Vector2(enemy["pos"])):
			continue
		_draw_enemy(enemy)


func _draw_enemy(enemy: Dictionary) -> void:
	var role := StringName(enemy["role"])
	var archetype := StringName(enemy.get("archetype", role))
	var position := Vector2(enemy["pos"])
	var visual_radius := float(enemy.get("visual_radius", Art.enemy_visual_radius(role)))
	var base_color := Art.IVORY_BRIGHT if float(enemy["flash"]) > 0.0 else _enemy_color(role)
	if bool(enemy["shielded"]):
		draw_circle(position, visual_radius + 14.0, Color(Art.MINT, 0.20))
		draw_arc(position, visual_radius + 14.0, 0.0, TAU, 32, Art.MINT, 8.0)
	if role == &"repair_tender" and not String(enemy.get("repair_target_id", "")).is_empty():
		var repair_target := _find_enemy_by_id(String(enemy["repair_target_id"]))
		if not repair_target.is_empty() and bool(repair_target.get("alive", false)):
			draw_line(position, Vector2(repair_target["pos"]), Color(Art.MINT, 0.82), 14.0, true)
	match archetype:
		&"scrap_drone":
			_draw_scrap_drone(position, visual_radius, (player_position - position).angle(), base_color)
		&"needle_drone":
			_draw_needle_drone(position, visual_radius, (player_position - position).angle(), base_color)
		&"spark_minelet":
			_draw_spark_minelet(position, visual_radius, base_color)
		&"chaser":
			_draw_chaser(position, visual_radius, (player_position - position).angle(), base_color)
		&"shooter":
			_draw_shooter(position, visual_radius, (player_position - position).angle(), base_color)
		&"controller":
			_draw_controller(position, visual_radius, base_color)
		&"turret":
			var turret_dir := Vector2(enemy["committed_dir"]) if String(enemy["phase"]) != "move" else (player_position - position).normalized()
			_draw_turret(position, visual_radius, turret_dir.angle(), base_color)
		&"mine":
			_draw_mine(position, visual_radius, base_color)
		&"shield_escort":
			_draw_shield_escort(position, visual_radius, base_color)
		&"artillery_spotter":
			_draw_artillery_spotter(position, visual_radius, (player_position - position).angle(), base_color)
		&"interceptor_tower":
			_draw_interceptor_tower(position, visual_radius, base_color, int(enemy["intercept_charges"]))
		&"rammer":
			_draw_rammer(position, visual_radius, Vector2(enemy["committed_dir"]).angle(), base_color)
		&"repair_tender":
			_draw_repair_tender(position, visual_radius, base_color)
		&"drone_carrier":
			_draw_drone_carrier(position, visual_radius, base_color, String(enemy["phase"]) == "startup")
		&"beam_sentinel":
			_draw_beam_sentinel(position, visual_radius, Vector2(enemy["committed_dir"]).angle(), base_color)
		&"generator":
			_draw_generator(position, visual_radius, base_color)
		&"field_boss":
			_draw_field_boss(position, visual_radius, Vector2(enemy["committed_dir"]).angle(), base_color)
		&"boss_pylon":
			_draw_boss_pylon(position, visual_radius, base_color)
		&"stage_boss":
			_draw_stage_boss(position, visual_radius, (player_position - position).angle(), base_color)
	_draw_enemy_statuses(enemy, position, visual_radius)
	if float(enemy.get("vulnerable", 0.0)) > 0.0:
		draw_arc(position, visual_radius + 12.0, 0.0, TAU, 28, Art.MUSTARD, 7.0)

	_draw_enemy_telegraph(enemy)
	var health_class := StringName(enemy.get("health_class", &"standard"))
	var show_health := health_class == &"priority" or String(enemy["id"]) == _aim_target_id or float(enemy.get("health_visible_timer", 0.0)) > 0.0
	if role != &"stage_boss" and show_health:
		var health_ratio := clampf(float(enemy["health"]) / float(enemy["max_health"]), 0.0, 1.0)
		var bar_width := visual_radius * 1.6
		var bar_position := position + Vector2(-bar_width * 0.5, visual_radius + 14.0)
		draw_rect(Rect2(bar_position, Vector2(bar_width, 10.0)), Art.IVORY_SHADE)
		draw_rect(Rect2(bar_position, Vector2(bar_width * health_ratio, 10.0)), Art.CORAL)


func _draw_enemy_statuses(enemy: Dictionary, position: Vector2, radius: float) -> void:
	var statuses: Dictionary = enemy.get("statuses", {})
	if float(enemy.get("marked_time", 0.0)) > 0.0:
		draw_arc(position, radius + 15.0, -PI * 0.3, PI * 1.3, 22, Art.MUSTARD, 6.0)
	if float(enemy.get("shear_time", 0.0)) > 0.0:
		draw_arc(position, radius + 10.0, PI * 0.7, PI * 2.3, 22, Art.MINT, 6.0)
	if statuses.has(&"burn"):
		draw_arc(position, radius + 9.0, -PI * 0.9, PI * 0.2, 18, Art.CORAL, 6.0)
		draw_colored_polygon(PackedVector2Array([position + Vector2(0.0, -radius - 18.0), position + Vector2(8.0, -radius - 5.0), position + Vector2(-8.0, -radius - 5.0)]), Art.MUSTARD)
	if statuses.has(&"poison"):
		draw_arc(position, radius + 10.0, PI * 0.1, PI * 1.25, 18, Art.MINT, 6.0)
		draw_circle(position + Vector2(radius + 7.0, -radius * 0.4), 6.0, Art.MINT)
	if statuses.has(&"slow"):
		draw_arc(position, radius + 11.0, 0.0, TAU, 20, Art.COBALT_WATER, 5.0)
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_rect(Rect2(position + direction * (radius + 10.0) - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Art.IVORY_BRIGHT)


func _draw_scrap_drone(position: Vector2, radius: float, angle: float, color: Color) -> void:
	var points := [
		Vector2(radius, 0.0), Vector2(-radius * 0.45, -radius * 0.72),
		Vector2(-radius * 0.18, 0.0), Vector2(-radius * 0.45, radius * 0.72),
	]
	draw_colored_polygon(_rotated_polygon(position + Vector2(4.0, 5.0), points, angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, points, angle), color)
	draw_circle(position, radius * 0.24, Art.IVORY_BRIGHT)


func _draw_needle_drone(position: Vector2, radius: float, angle: float, color: Color) -> void:
	var points := [
		Vector2(radius * 1.2, 0.0), Vector2(0.0, -radius * 0.62),
		Vector2(-radius * 0.72, 0.0), Vector2(0.0, radius * 0.62),
	]
	draw_colored_polygon(_rotated_polygon(position + Vector2(4.0, 5.0), points, angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, points, angle), color)
	draw_line(position, position + Vector2.RIGHT.rotated(angle) * radius * 1.35, Art.IVORY_BRIGHT, 5.0)


func _draw_spark_minelet(position: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 12:
		var point_radius := radius if index % 2 == 0 else radius * 0.46
		points.append(position + Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * point_radius)
	draw_colored_polygon(points, color)
	draw_circle(position, radius * 0.28, Art.IVORY_BRIGHT)


func _draw_chaser(position: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_colored_polygon(_rotated_polygon(position + Vector2(7.0, 9.0), [
		Vector2(radius, 0.0), Vector2(radius * 0.08, -radius),
		Vector2(-radius * 0.94, -radius * 0.50), Vector2(-radius * 0.58, 0.0),
		Vector2(-radius * 0.94, radius * 0.50), Vector2(radius * 0.08, radius),
	], angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, [
		Vector2(radius, 0.0), Vector2(radius * 0.08, -radius),
		Vector2(-radius * 0.82, -radius * 0.42), Vector2(-radius * 0.48, 0.0),
		Vector2(-radius * 0.82, radius * 0.42), Vector2(radius * 0.08, radius),
	], angle), color)
	draw_colored_polygon(_rotated_polygon(position, [
		Vector2(radius * 0.52, 0.0), Vector2(-radius * 0.08, -radius * 0.30),
		Vector2(-radius * 0.18, 0.0), Vector2(-radius * 0.08, radius * 0.30),
	], angle), Art.IVORY_BRIGHT)


func _draw_shooter(position: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_colored_polygon(_rotated_polygon(position + Vector2(7.0, 9.0), [
		Vector2(radius * 0.72, 0.0), Vector2(0.0, -radius),
		Vector2(-radius * 0.72, 0.0), Vector2(0.0, radius),
	], angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, [
		Vector2(radius * 0.72, 0.0), Vector2(0.0, -radius),
		Vector2(-radius * 0.72, 0.0), Vector2(0.0, radius),
	], angle), color)
	var direction := Vector2.RIGHT.rotated(angle)
	draw_line(position - direction * radius * 0.08, position + direction * radius * 1.35, Art.IVORY_BRIGHT, 15.0)
	draw_circle(position, radius * 0.24, Art.CORAL_DARK)


func _draw_controller(position: Vector2, radius: float, color: Color) -> void:
	var motion_time := 0.0 if _reduced_motion_enabled() else run_time
	for index in 3:
		var angle := motion_time * 0.22 + TAU * float(index) / 3.0
		var petal := position + Vector2.RIGHT.rotated(angle) * radius * 0.54
		draw_colored_polygon(_regular_polygon(petal, radius * 0.48, 4, angle), color)
	draw_circle(position + Vector2(6.0, 8.0), radius * 0.56, Art.CORAL_DARK)
	draw_circle(position, radius * 0.56, Art.IVORY_BRIGHT)
	draw_colored_polygon(_regular_polygon(position, radius * 0.30, 6, motion_time * -0.25), Art.CORAL)


func _draw_turret(position: Vector2, radius: float, angle: float, color: Color) -> void:
	var base_rect := Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var edge := base_rect
	edge.position += Vector2(8.0, 10.0)
	draw_colored_polygon(Art.stepped_rect(edge, 15.0), Art.COBALT_DEEP)
	draw_colored_polygon(Art.stepped_rect(base_rect, 15.0), Art.CERAMIC_GREEN)
	draw_circle(position, radius * 0.55, color)
	var direction := Vector2.RIGHT.rotated(angle)
	draw_line(position, position + direction * radius * 1.35, Art.IVORY_BRIGHT, 18.0)
	draw_circle(position, radius * 0.22, Art.CORAL_DARK)


func _draw_mine(position: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 16:
		var point_radius := radius if index % 2 == 0 else radius * 0.54
		points.append(position + Vector2.RIGHT.rotated(TAU * float(index) / 16.0) * point_radius)
	draw_colored_polygon(points, color)
	draw_circle(position, radius * 0.42, Art.CORAL_DARK)
	draw_colored_polygon(_regular_polygon(position, radius * 0.22, 4, PI / 4.0), Art.IVORY_BRIGHT)


func _draw_generator(position: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(_regular_polygon(position + Vector2(8.0, 10.0), radius, 8, PI / 8.0), Art.COBALT_DEEP)
	draw_colored_polygon(_regular_polygon(position, radius, 8, PI / 8.0), Art.CERAMIC_GREEN)
	for index in 4:
		var angle := TAU * float(index) / 4.0
		var petal := position + Vector2.RIGHT.rotated(angle) * radius * 0.42
		draw_circle(petal, radius * 0.29, Art.IVORY_BRIGHT)
	var pulse := 0.0 if _reduced_motion_enabled() else sin(run_time * 3.0) * 3.0
	draw_circle(position, radius * 0.36 + pulse, color)
	draw_colored_polygon(_regular_polygon(position, radius * 0.20, 4, PI / 4.0), Art.MUSTARD)


func _draw_shield_escort(position: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(_regular_polygon(position + Vector2(7.0, 9.0), radius, 6, PI / 6.0), Art.COBALT_DEEP)
	draw_colored_polygon(_regular_polygon(position, radius, 6, PI / 6.0), Art.MINT)
	draw_circle(position, radius * 0.58, Art.IVORY_BRIGHT)
	draw_colored_polygon(_regular_polygon(position, radius * 0.32, 6, PI / 6.0), color)
	draw_arc(position, radius * 1.45, -PI * 0.75, PI * 0.75, 24, Art.MINT, 8.0)


func _draw_artillery_spotter(position: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_colored_polygon(_regular_polygon(position + Vector2(8.0, 10.0), radius, 4, PI / 4.0), Art.CORAL_DARK)
	draw_colored_polygon(_regular_polygon(position, radius, 4, PI / 4.0), color)
	var direction := Vector2.RIGHT.rotated(angle)
	draw_line(position, position + direction * radius * 1.7, Art.IVORY_BRIGHT, 13.0)
	draw_circle(position, radius * 0.28, Art.BOSS_MAGENTA)


func _draw_interceptor_tower(position: Vector2, radius: float, color: Color, charges: int) -> void:
	draw_colored_polygon(Art.stepped_rect(Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), 12.0), Art.CERAMIC_GREEN)
	draw_colored_polygon(_regular_polygon(position, radius * 0.7, 8, PI / 8.0), color)
	draw_circle(position, radius * 0.28, Art.IVORY_BRIGHT)
	for index in charges:
		var angle := -PI * 0.65 + float(index) * PI * 0.65
		draw_circle(position + Vector2.RIGHT.rotated(angle) * (radius + 13.0), 6.0, Art.BOSS_MAGENTA)


func _draw_rammer(position: Vector2, radius: float, angle: float, color: Color) -> void:
	var hull := [Vector2(radius * 1.2, 0.0), Vector2(-radius * 0.45, -radius), Vector2(-radius, 0.0), Vector2(-radius * 0.45, radius)]
	draw_colored_polygon(_rotated_polygon(position + Vector2(7.0, 9.0), hull, angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, hull, angle), color)
	draw_colored_polygon(_rotated_polygon(position, [Vector2(radius * 1.35, 0.0), Vector2(radius * 0.3, -radius * 0.35), Vector2(radius * 0.3, radius * 0.35)], angle), Art.IVORY_BRIGHT)


func _draw_repair_tender(position: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(_regular_polygon(position + Vector2(7.0, 9.0), radius, 6, PI / 6.0), Art.COBALT_DEEP)
	draw_colored_polygon(_regular_polygon(position, radius, 6, PI / 6.0), Art.MINT)
	draw_rect(Rect2(position - Vector2(radius * 0.14, radius * 0.58), Vector2(radius * 0.28, radius * 1.16)), Art.IVORY_BRIGHT)
	draw_rect(Rect2(position - Vector2(radius * 0.58, radius * 0.14), Vector2(radius * 1.16, radius * 0.28)), Art.IVORY_BRIGHT)
	draw_circle(position, radius * 0.20, color)


func _draw_drone_carrier(position: Vector2, radius: float, color: Color, bay_open: bool) -> void:
	draw_colored_polygon(Art.stepped_rect(Rect2(position - Vector2(radius, radius * 0.72) + Vector2(8,10), Vector2(radius * 2.0, radius * 1.44)), 14.0), Art.COBALT_DEEP)
	draw_colored_polygon(Art.stepped_rect(Rect2(position - Vector2(radius, radius * 0.72), Vector2(radius * 2.0, radius * 1.44)), 14.0), color)
	var bay_color := Art.CORAL if bay_open else Art.CERAMIC_GREEN
	draw_rect(Rect2(position - Vector2(radius * 0.52, radius * 0.22), Vector2(radius * 1.04, radius * 0.44)), bay_color)
	for side in [-1.0, 1.0]:
		draw_circle(position + Vector2(side * radius * 0.72, 0.0), radius * 0.18, Art.MINT)


func _draw_beam_sentinel(position: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_colored_polygon(Art.stepped_rect(Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), 12.0), Art.CERAMIC_GREEN)
	draw_colored_polygon(_regular_polygon(position, radius * 0.72, 4, PI / 4.0), color)
	var direction := Vector2.RIGHT.rotated(angle)
	draw_line(position, position + direction * radius * 1.25, Art.IVORY_BRIGHT, 18.0)
	draw_circle(position, radius * 0.22, Art.BOSS_MAGENTA)


func _draw_field_boss(position: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_colored_polygon(_rotated_polygon(position + Vector2(10.0, 12.0), [
		Vector2(radius, 0.0), Vector2(radius * 0.34, -radius * 0.74),
		Vector2(-radius * 0.72, -radius), Vector2(-radius * 0.45, 0.0),
		Vector2(-radius * 0.72, radius), Vector2(radius * 0.34, radius * 0.74),
	], angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, [
		Vector2(radius, 0.0), Vector2(radius * 0.34, -radius * 0.74),
		Vector2(-radius * 0.72, -radius), Vector2(-radius * 0.45, 0.0),
		Vector2(-radius * 0.72, radius), Vector2(radius * 0.34, radius * 0.74),
	], angle), color)
	draw_colored_polygon(_regular_polygon(position, radius * 0.42, 6, angle), Art.IVORY_BRIGHT)
	draw_circle(position, radius * 0.22, Art.CORAL)


func _draw_boss_pylon(position: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(_regular_polygon(position + Vector2(8.0, 10.0), radius, 4, PI / 4.0), Art.COBALT_DEEP)
	draw_colored_polygon(_regular_polygon(position, radius, 4, PI / 4.0), color)
	draw_colored_polygon(_regular_polygon(position, radius * 0.56, 4, PI / 4.0), Art.IVORY_BRIGHT)
	draw_circle(position, radius * 0.22, Art.BOSS_MAGENTA)


func _draw_stage_boss(position: Vector2, radius: float, angle: float, color: Color) -> void:
	var mask := [
		Vector2(radius, 0.0), Vector2(radius * 0.50, -radius * 0.36),
		Vector2(radius * 0.25, -radius), Vector2(-radius * 0.12, -radius * 0.58),
		Vector2(-radius * 0.66, -radius * 0.78), Vector2(-radius * 0.48, 0.0),
		Vector2(-radius * 0.66, radius * 0.78), Vector2(-radius * 0.12, radius * 0.58),
		Vector2(radius * 0.25, radius), Vector2(radius * 0.50, radius * 0.36),
	]
	draw_colored_polygon(_rotated_polygon(position + Vector2(12.0, 15.0), mask, angle), Art.CORAL_DARK)
	draw_colored_polygon(_rotated_polygon(position, mask, angle), color)
	draw_colored_polygon(_regular_polygon(position, radius * 0.45, 8, angle + PI / 8.0), Art.IVORY_BRIGHT)
	draw_colored_polygon(_regular_polygon(position, radius * 0.24, 4, angle + PI / 4.0), Art.CORAL)
	var direction := Vector2.RIGHT.rotated(angle)
	draw_line(position, position + direction * radius * 1.12, Art.CORAL_DARK, 24.0)


func _enemy_color(role: StringName) -> Color:
	match role:
		&"chaser", &"shooter", &"controller", &"mine", &"artillery_spotter", &"rammer":
			return Art.CORAL
		&"turret", &"interceptor_tower", &"beam_sentinel":
			return Art.CORAL_DARK
		&"generator", &"shield_escort", &"repair_tender", &"drone_carrier":
			return Art.MINT
		&"field_boss", &"stage_boss", &"boss_pylon":
			return Art.BOSS_MAGENTA
	return Art.INK_MUTED


func _draw_enemy_telegraph(enemy: Dictionary) -> void:
	var phase := String(enemy["phase"])
	var role := StringName(enemy["role"])
	var position := Vector2(enemy["pos"])
	if phase == "startup":
		var direction := Vector2(enemy["committed_dir"])
		match role:
			&"chaser":
				_draw_warning_beam(position, direction, 190.0, 34.0, Art.CORAL)
			&"field_boss":
				var field_definition := BossPatterns.field_definition(String(enemy["pattern"]))
				var field_kind := StringName(field_definition["kind"])
				if field_kind == &"area":
					var field_target := Vector2(enemy["committed_target"])
					draw_circle(field_target, float(field_definition["radius"]), Color(Art.CORAL, 0.14))
					draw_arc(field_target, float(field_definition["radius"]), 0.0, TAU, 40, Art.CORAL, 11.0)
				else:
					_draw_warning_beam(position, direction, 620.0 if field_kind == &"charge" else 520.0, 58.0 if field_kind == &"charge" else 26.0, Art.CORAL)
			&"shooter", &"turret":
				_draw_warning_beam(position, direction, 620.0, 20.0, Color(Art.CORAL, 0.72))
			&"controller":
				draw_circle(Vector2(enemy["committed_target"]), 112.0, Color(Art.CORAL, 0.14))
				draw_arc(Vector2(enemy["committed_target"]), 112.0, 0.0, TAU, 36, Art.CORAL, 10.0)
			&"mine":
				draw_circle(position, 190.0, Color(Art.CORAL, 0.12))
				draw_arc(position, 190.0, 0.0, TAU, 40, Art.CORAL, 10.0)
			&"artillery_spotter":
				draw_circle(Vector2(enemy["committed_target"]), 175.0, Color(Art.CORAL, 0.15))
				draw_arc(Vector2(enemy["committed_target"]), 175.0, 0.0, TAU, 40, Art.CORAL, 12.0)
			&"interceptor_tower":
				_draw_warning_beam(position, direction, 700.0, 18.0, Color(Art.BOSS_MAGENTA, 0.72))
			&"rammer":
				_draw_warning_beam(position, direction, 640.0, 54.0, Art.CORAL)
			&"drone_carrier":
				draw_arc(position, 86.0, 0.0, TAU, 32, Art.MINT, 10.0)
			&"beam_sentinel":
				_draw_warning_beam(position, direction, SpecialistRuntime.BEAM_RANGE, SpecialistRuntime.BEAM_WIDTH, Color(Art.CORAL, 0.78))
	if role == &"beam_sentinel" and phase == "active":
		draw_line(position, Vector2(enemy["beam_end"]), Art.CORAL, SpecialistRuntime.BEAM_WIDTH, true)
		draw_line(position, Vector2(enemy["beam_end"]), Art.IVORY_BRIGHT, 9.0, true)
	if role == &"stage_boss" and phase == "boss_startup":
		var pattern := String(enemy["pattern"])
		var boss_kind := BossPatterns.kind(pattern)
		if boss_kind == &"charge":
			_draw_warning_beam(position, Vector2(enemy["committed_dir"]), 850.0, 64.0, Color(Art.CORAL, 0.72))
		if boss_kind == &"beam":
			_draw_warning_beam(position, Vector2(enemy["committed_dir"]), position.distance_to(Vector2(enemy["beam_end"])), BossPatterns.width(pattern), Color(Art.BOSS_MAGENTA, 0.76))
		if boss_kind == &"summon":
			draw_arc(position, 112.0, 0.0, TAU, 40, Art.MINT, 13.0)
		if boss_kind == &"lanes":
			for lane_y_variant in enemy["lane_centers"]:
				var lane_y := float(lane_y_variant)
				draw_rect(Rect2(_stage_boss_arena().position.x, lane_y - 40.0, _stage_boss_arena().size.x, 80.0), Color(Art.CORAL, 0.22))
		if boss_kind in [&"area", &"pylons"]:
			var target := Vector2(enemy["committed_target"])
			draw_circle(target, BossPatterns.radius(pattern), Color(Art.CORAL, 0.14))
			draw_arc(target, BossPatterns.radius(pattern), 0.0, TAU, 48, Art.CORAL, 11.0)
		if boss_kind == &"fan":
			for offset in [-0.34, -0.17, 0.0, 0.17, 0.34]:
				_draw_warning_beam(position, Vector2(enemy["committed_dir"]).rotated(float(offset)), 620.0, 18.0, Color(Art.CORAL, 0.58))
		if boss_kind == &"cross":
			for offset in [0.0, PI * 0.5, PI, PI * 1.5]:
				_draw_warning_beam(position, Vector2(enemy["committed_dir"]).rotated(float(offset)), 620.0, 28.0, Color(Art.BOSS_MAGENTA, 0.62))
		if boss_kind == &"pylons":
			for pylon in enemies:
				if StringName(pylon.get("role", &"")) == &"boss_pylon" and bool(pylon.get("alive", false)):
					var pylon_position := Vector2(pylon["pos"])
					draw_circle(pylon_position, 68.0, Color(Art.BOSS_MAGENTA, 0.18))
					draw_arc(pylon_position, 68.0, 0.0, TAU, 32, Art.BOSS_MAGENTA, 9.0)
	if role == &"stage_boss" and phase == "boss_active" and BossPatterns.kind(String(enemy["pattern"])) == &"beam":
		draw_line(position, Vector2(enemy["beam_end"]), Art.BOSS_MAGENTA, BossPatterns.width(String(enemy["pattern"])), true)
		draw_line(position, Vector2(enemy["beam_end"]), Art.IVORY_BRIGHT, 11.0, true)


func _draw_warning_beam(origin: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	var normalized := direction.normalized()
	var tangent := normalized.rotated(PI * 0.5)
	draw_colored_polygon(PackedVector2Array([
		origin - tangent * width * 0.5,
		origin + normalized * length - tangent * width * 0.18,
		origin + normalized * length + tangent * width * 0.18,
		origin + tangent * width * 0.5,
	]), Color(color, color.a * 0.42))


func _draw_projectiles() -> void:
	var visible_world := _visible_world_rect(80.0)
	for projectile in projectiles:
		var position := Vector2(projectile["pos"])
		if not visible_world.has_point(position):
			continue
		var velocity := Vector2(projectile["velocity"])
		var color := Color(projectile["color"])
		var direction := velocity.normalized()
		var radius := maxf(7.0, float(projectile["radius"]) * 1.35)
		draw_line(position - direction * 40.0, position + direction * 7.0, Color(color, 0.50), radius * 1.5, true)
		draw_colored_polygon(_regular_polygon(position, radius, 4, direction.angle() + PI / 4.0), color)


func _draw_effects() -> void:
	var visible_world := _visible_world_rect(220.0)
	for effect in effects:
		var kind := String(effect["kind"])
		var position := Vector2(effect["pos"])
		if not visible_world.has_point(position):
			continue
		var color := Color(effect["color"])
		var duration := maxf(0.001, float(effect["duration"]))
		var progress := 1.0 - clampf(float(effect["time"]) / duration, 0.0, 1.0)
		var radius := float(effect["radius"])
		match kind:
			"impact", "muzzle":
				draw_colored_polygon(_regular_polygon(position, lerpf(8.0, radius, progress), 4, PI / 4.0), Color(color, 1.0 - progress))
			"destroy":
				draw_circle(position, lerpf(radius * 0.3, radius, progress), Color(color, (1.0 - progress) * 0.28))
				draw_arc(position, lerpf(radius * 0.3, radius, progress), 0.0, TAU, 30, Color(color, 1.0 - progress), 12.0)
			"shock", "pickup", "spawn":
				draw_circle(position, lerpf(10.0, radius, progress), Color(color, (1.0 - progress) * 0.18))
				draw_arc(position, lerpf(10.0, radius, progress), 0.0, TAU, 42, Color(color, 1.0 - progress), 11.0)
			"dash_start":
				draw_arc(position, lerpf(radius, radius * 0.2, progress), 0.0, TAU, 24, Color(color, 1.0 - progress), 12.0)
			"afterimage":
				draw_colored_polygon(_rotated_polygon(position, [
					Vector2(Art.PLAYER_VISUAL_RADIUS, 0.0),
					Vector2(-Art.PLAYER_VISUAL_RADIUS * 0.78, -Art.PLAYER_VISUAL_RADIUS * 0.62),
					Vector2(-Art.PLAYER_VISUAL_RADIUS * 0.62, Art.PLAYER_VISUAL_RADIUS * 0.62),
				], Vector2(effect["dir"]).angle()), Color(color, (1.0 - progress) * 0.28))
			"emp_start":
				draw_circle(position, radius * (0.45 + progress * 0.55), Color(color, 0.10))
				draw_arc(position, radius * (0.45 + progress * 0.55), 0.0, TAU * progress, 48, Color(color, 0.8), 13.0)
			"barrier_hit", "support":
				draw_arc(position, lerpf(radius * 0.7, radius, progress), 0.0, TAU, 32, Color(color, 1.0 - progress), 5.0)
			"reflect":
				var direction := Vector2(effect["dir"])
				draw_line(position - direction.rotated(PI * 0.5) * radius, position, Color(color, 1.0 - progress), 9.0)
				draw_line(position, position + direction * radius, Color(color, 1.0 - progress), 9.0)
			"scheduled_aftershock":
				draw_arc(position, radius, 0.0, TAU * progress, 32, Color(color, 0.35), 3.0)


func _visible_world_rect(margin: float = 0.0) -> Rect2:
	var inverse_canvas := get_canvas_transform().affine_inverse()
	var viewport_size := get_viewport_rect().size
	var top_left := inverse_canvas * Vector2.ZERO
	var bottom_right := inverse_canvas * viewport_size
	return Rect2(top_left, bottom_right - top_left).abs().grow(margin)


func _draw_player() -> void:
	var hull_color := Art.IVORY_BRIGHT if player_hit_flash > 0.0 else Art.MUSTARD
	var hull_angle := player_hull_direction.angle()
	var radius := Art.PLAYER_VISUAL_RADIUS
	var hull_points := [
		Vector2(radius, 0.0),
		Vector2(radius * 0.18, -radius * 0.74),
		Vector2(-radius * 0.72, -radius),
		Vector2(-radius * 0.48, -radius * 0.18),
		Vector2(-radius, radius * 0.54),
		Vector2(radius * 0.08, radius * 0.70),
	]
	draw_colored_polygon(_rotated_polygon(player_position + Vector2(8.0, 10.0), hull_points, hull_angle), Art.MUSTARD_DARK)
	draw_colored_polygon(_rotated_polygon(player_position, hull_points, hull_angle), hull_color)
	draw_colored_polygon(_rotated_polygon(player_position, [
		Vector2(radius * 0.58, 0.0),
		Vector2(-radius * 0.12, -radius * 0.38),
		Vector2(-radius * 0.38, 0.0),
		Vector2(-radius * 0.12, radius * 0.38),
	], hull_angle), Art.IVORY_BRIGHT)
	draw_circle(player_position, 16.0, Art.CERAMIC_GREEN)
	draw_line(player_position, player_position + player_aim_direction * 61.0, Art.INK, 17.0)
	draw_line(player_position, player_position + player_aim_direction * 61.0, Art.IVORY_BRIGHT, 10.0)
	draw_colored_polygon(_regular_polygon(player_position + player_aim_direction * 64.0, 9.0 + player_muzzle_flash * 58.0, 4, PI / 4.0), Art.MUSTARD)
	if player_barrier_strength > 0.0:
		var barrier_radius := 61.0 if _reduced_motion_enabled() else 61.0 + sin(run_time * 5.0) * 3.0
		draw_circle(player_position, barrier_radius, Color(Art.MINT, 0.14))
		draw_arc(player_position, barrier_radius, 0.0, TAU, 36, Art.MINT, 8.0)


func _draw_aim_feedback() -> void:
	if mode != RunMode.PLAYING and not _capture_mode:
		return
	var cursor_position := player_position + player_aim_direction * 230.0
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length() > 8.0:
		cursor_position = get_global_mouse_position()
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_colored_polygon(_regular_polygon(cursor_position + direction * 18.0, 6.0, 4, PI / 4.0), Art.MUSTARD)
	draw_circle(cursor_position, 4.0, Art.IVORY_BRIGHT)
	if not _aim_target_id.is_empty():
		var target := _find_enemy_by_id(_aim_target_id)
		if not target.is_empty() and bool(target["alive"]):
			var target_position := Vector2(target["pos"])
			var target_radius := Art.enemy_visual_radius(StringName(target["role"])) + 16.0
			for corner_variant in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
				var corner: Vector2 = corner_variant
				var anchor: Vector2 = target_position + corner * target_radius
				draw_line(anchor, anchor - Vector2(corner.x, 0.0) * 18.0, Art.MUSTARD, 6.0)
				draw_line(anchor, anchor - Vector2(0.0, corner.y) * 18.0, Art.MUSTARD, 6.0)


func _rotated_polygon(origin: Vector2, local_points: Array, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point_variant in local_points:
		var local_point: Vector2 = local_point_variant
		points.append(origin + local_point.rotated(angle))
	return points


func _regular_polygon(origin: Vector2, radius: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(origin + Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return points


func _core_polygon(origin: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 16:
		var point_radius := radius if index % 2 == 0 else radius * 0.68
		points.append(origin + Vector2.RIGHT.rotated(-PI * 0.5 + TAU * float(index) / 16.0) * point_radius)
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


func _parse_capture_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-all="):
			_capture_directory = argument.trim_prefix("--capture-all=")
			_capture_mode = true
		elif argument.begins_with("--capture-locale="):
			_capture_locale = argument.trim_prefix("--capture-locale=")
		elif argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2:
				_capture_size = Vector2i(maxi(640, int(parts[0])), maxi(360, int(parts[1])))
	if _capture_locale in ["ko", "en"]:
		TranslationServer.set_locale(_capture_locale)
	if _capture_mode:
		call_deferred("_run_capture_sequence")


func _run_capture_sequence() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_directory)
	if _capture_size.x > 0 and _capture_size.y > 0:
		get_window().size = _capture_size
	_camera.position_smoothing_enabled = false
	await get_tree().process_frame
	await get_tree().process_frame
	_save_capture("01-deployment.png")
	_ui.debug_modal_contract("settings")
	await _settle_capture()
	_save_capture("01b-shared-settings.png")

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
		await _capture_collision_overlay_evidence()
		await _capture_all_boss_evidence()

	_capture_prepare_stage(0, true)
	mode = RunMode.PAUSED
	_ui.show_pause()
	await _settle_capture()
	_save_capture("90-pause.png")

	mode = RunMode.RESULT
	_ui.show_result({
		"stage_number": 1, "stage_title_key": "STAGE_FLOODED_WORKS",
		"has_next_stage": true, "next_stage_key": "STAGE_TIDAL_ARCHIVE",
		"time": "4:18", "health_ratio": 0.76, "upgrade": "UPGRADE_ION_WAKE_TITLE",
		"field_boss_defeated": true, "primary_hits": 42, "dash_uses": 11, "installations": 5,
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
	enemies.clear()
	var roles: Array[StringName] = [&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser", &"shooter", &"controller"]
	for index in 32:
		var position := Vector2(1900.0 + float(index % 8) * 85.0, 1140.0 + float(index / 8) * 170.0)
		var enemy := _make_enemy({"id":"capture_pressure_%02d" % index, "role":roles[index % roles.size()], "pos":position, "active":true})
		enemy["active"] = true
		enemy["health_visible_timer"] = 99.0
		enemy["committed_dir"] = (player_position - position).normalized()
		if index < 3:
			enemy["phase"] = "startup"
			enemy["committed_target"] = player_position
		enemies.append(enemy)
	experience_runtime.shards.clear()
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
	enemies.clear()
	for index in 4:
		var angle := -0.75 + float(index) * 0.5
		var position := player_position + Vector2.RIGHT.rotated(angle) * (260.0 + float(index) * 35.0)
		var role: StringName = &"controller" if index == 0 else &"chaser"
		var enemy := _make_enemy({"id":"capture_cycle_%d" % index, "role":role, "pos":position, "active":true})
		enemy["active"] = true
		enemy["health_visible_timer"] = 99.0
		enemies.append(enemy)
	_aim_target_id = "capture_cycle_0"
	apply_upgrade(&"aegis_cycle")
	apply_upgrade(&"overclock_cycle")
	apply_upgrade(&"thruster_cycle")
	_threat_contact_cache = [
		{"offset":Vector2(-760.0, -180.0), "priority":false, "targeted":false},
		{"offset":Vector2(820.0, 120.0), "priority":true, "targeted":true},
		{"offset":Vector2(120.0, -900.0), "priority":false, "targeted":false},
	]
	await _settle_capture()
	_save_capture("04-three-cycles-threat-radar.png")


func _capture_field_item_evidence() -> void:
	_capture_prepare_stage(0)
	enemies.clear()
	crates.clear()
	pickups.clear()
	player_health = 64.0
	pickups.append({"id":"capture_repair", "kind":&"repair", "pos":player_position + Vector2(-150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":35.0})
	pickups.append({"id":"capture_recall", "kind":&"experience_recall", "pos":player_position + Vector2(150.0, 45.0), "active":true, "pulse":0.0, "heal_amount":0.0})
	experience_runtime.shards.clear()
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
	if boss.is_empty():
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
		if current_stage_id == &"coral_switchyard":
			switchyard_gate_state = 1
			_refresh_runtime_cover_cache()
			await _settle_capture()
			_save_capture("20-collision-04-coral-switchyard-alternate.png")
		elif current_stage_id == &"abyssal_observatory":
			for zone in _stage_mechanic_zones(&"reflector"):
				reflector_orientations[StringName(zone["id"])] = int(zone["vault_orientation"])
			_refresh_runtime_cover_cache()
			await _settle_capture()
			_save_capture("20-collision-05-abyssal-observatory-vault-open.png")
		_debug_collision_overlay = false
	_camera.zoom = Vector2.ONE


func _capture_all_boss_evidence() -> void:
	for stage_index in StageCatalog.STAGE_IDS.size():
		var boss := _capture_prepare_boss(stage_index)
		if boss.is_empty():
			continue
		var stage_slug := String(current_stage_id).replace("_", "-")
		_boss_select_pattern(boss)
		mode = RunMode.PAUSED
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-startup.png" % [stage_index + 1, stage_slug])

		_boss_begin_active(boss)
		_boss_update_active(boss, 0.05)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-active.png" % [stage_index + 1, stage_slug])

		projectiles.clear()
		denied_zones.clear()
		boss["phase"] = "boss_recovery"
		boss["phase_time"] = BossPatterns.recovery_seconds(String(boss["pattern"]))
		boss["vulnerable"] = 1.55
		boss["last_pattern"] = String(boss["pattern"])
		boss["pattern"] = "recovery_window"
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-recovery.png" % [stage_index + 1, stage_slug])

		boss["health"] = float(boss["max_health"]) * 0.48
		boss["boss_phase"] = 2
		boss["pattern_index"] = 0
		_boss_select_pattern(boss)
		await _settle_capture()
		_save_capture("30-boss-%02d-%s-phase-two.png" % [stage_index + 1, stage_slug])


func _capture_prepare_boss(stage_index: int) -> Dictionary:
	_capture_prepare_stage(stage_index, true)
	enemies.clear()
	projectiles.clear()
	denied_zones.clear()
	generators_destroyed = 2
	chest_claimed = true
	var arena := _stage_boss_arena()
	player_position = arena.get_center() - Vector2(210.0, 0.0)
	_start_stage_boss()
	var boss := _find_enemy_by_id("stage_boss")
	if boss.is_empty():
		return {}
	boss["pos"] = arena.get_center() + Vector2(190.0, 0.0)
	boss["home"] = boss["pos"]
	player_aim_direction = (Vector2(boss["pos"]) - player_position).normalized()
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


# Focused validation/debug API -------------------------------------------------

func debug_snapshot() -> Dictionary:
	return {
		"mode": mode,
		"player_position": player_position,
		"health": player_health,
		"generators_destroyed": generators_destroyed,
		"chest_claimed": chest_claimed,
		"boss_started": boss_started,
		"boss_locked": boss_locked,
		"stage_complete": stage_complete,
		"applied_upgrades": applied_upgrades.duplicate(),
		"primary_energy": player_primary_weapon.charge_ratio(),
		"primary_tier": player_primary_weapon.tier(),
		"living_ordinary": debug_living_ordinary_count(),
	}


func debug_primary_charge_contract() -> Dictionary:
	player_primary_weapon.reset(false)
	player_primary_weapon.tick(0.0, true, true)
	projectiles.clear()
	var immediate_fired := _try_fire_primary()
	var normal_projectile: Dictionary = projectiles[0] if not projectiles.is_empty() else {}
	var normal_damage := float(normal_projectile.get("damage", 0.0))
	player_primary_weapon.tick(PrimaryWeapon.BASE_INTERVAL, true, true)
	var held_second_fired := _try_fire_primary()
	projectiles.clear()
	player_primary_weapon.tick(PrimaryWeapon.FULL_OPENING_SECONDS, false, true)
	player_primary_weapon.tick(0.0, true, true)
	var full_fired := _try_fire_primary()
	var full_projectile: Dictionary = projectiles[0] if not projectiles.is_empty() else {}
	var full_damage := float(full_projectile.get("damage", 0.0))
	var full_structure := float(full_projectile.get("structure_damage", 0.0))
	var full_pierce := int(full_projectile.get("pierce", 0))
	return {
		"minimum_energy": 0.0,
		"full_charge_seconds": PrimaryWeapon.FULL_OPENING_SECONDS,
		"immediate_fired": immediate_fired,
		"held_second_fired": held_second_fired,
		"normal_damage": normal_damage,
		"full_fired": full_fired,
		"full_damage": full_damage,
		"full_structure": full_structure,
		"full_pierce": full_pierce,
		"normal_fire_available": true,
	}


func debug_living_ordinary_count() -> int:
	var count := 0
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) in [&"chaser", &"shooter", &"controller", &"turret", &"mine", &"shield_escort", &"artillery_spotter", &"interceptor_tower", &"rammer", &"repair_tender", &"drone_carrier", &"beam_sentinel"]:
			count += 1
	return count


func _debug_append_packet_enemies(limit: int) -> void:
	var appended := 0
	for spec in StageCatalog.packet_enemy_blueprint(current_stage_id):
		if appended >= limit:
			break
		var enemy := _make_enemy(spec)
		enemy["active"] = true
		enemies.append(enemy)
		appended += 1


func debug_apply_upgrade(upgrade_id: StringName) -> bool:
	return apply_upgrade(upgrade_id)


func debug_force_required_progression() -> Dictionary:
	tutorial_move = true
	tutorial_aim = true
	tutorial_fire = true
	tutorial_dash = true
	tutorial_announced = true
	entered_approach = true
	player_position = _stage_landmark("calibration_cache")
	_update_stage_progression()
	_debug_collect_all_experience_and_rewards()
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) == &"generator":
			_damage_enemy(enemy, 9999.0, "validation", 0.0)
	player_position = _stage_landmark("chest")
	_update_stage_progression()
	_debug_collect_all_experience_and_rewards()
	player_position = _stage_boss_arena().get_center()
	_update_stage_progression()
	return debug_snapshot()


func debug_defeat_stage_boss() -> Dictionary:
	var boss := _find_enemy_by_id("stage_boss")
	if boss.is_empty():
		_start_stage_boss()
		boss = _find_enemy_by_id("stage_boss")
	_damage_enemy(boss, 99999.0, "validation", 999.0)
	_debug_collect_all_experience_and_rewards()
	return debug_snapshot()


func _debug_accept_current_reward() -> void:
	if mode != RunMode.UPGRADE or current_card_offer.is_empty():
		return
	_on_upgrade_selected(StringName(current_card_offer[0]["id"]))


func _debug_collect_all_experience_and_rewards() -> void:
	for shard in experience_runtime.shards:
		shard["pos"] = player_position
	_update_experience(0.0)
	for _transaction in 32:
		if mode == RunMode.UPGRADE:
			if current_card_offer.is_empty():
				break
			_debug_accept_current_reward()
		elif experience_runtime.pending_level_ups > 0 or not pending_reward_sources.is_empty():
			_advance_reward_queue()
		else:
			break


func debug_full_run() -> Dictionary:
	var primary := selected_primary
	_reset_run(false)
	selected_primary = primary
	mode = RunMode.PLAYING
	_debug_append_packet_enemies(12)
	var living_before := debug_living_ordinary_count()
	var progress := debug_force_required_progression()
	var boss_started_with_living := bool(progress["boss_started"]) and debug_living_ordinary_count() > 0
	debug_defeat_stage_boss()
	return {
		"living_before": living_before,
		"boss_started_with_living": boss_started_with_living,
		"complete": stage_complete,
		"mode": mode,
		"upgrade_count": run_build.total_levels(),
	}


func debug_multistage_contract() -> Dictionary:
	_reset_run(false)
	mode = RunMode.PLAYING
	var stage_ids: Array[StringName] = []
	var role_sets: Array = []
	var upgrade_counts: Array[int] = []
	var environments: Array[StringName] = []
	var packet_counts: Array[int] = []
	var reward_ids: Array = []
	for stage_number in StageCatalog.STAGE_IDS.size():
		stage_ids.append(current_stage_id)
		environments.append(StringName(StageCatalog.profile(current_stage_id)["environment"]))
		packet_counts.append(StageCatalog.packets(current_stage_id).size())
		reward_ids.append(StageCatalog.reward_anchors(current_stage_id).keys())
		var roles: Array[StringName] = []
		for spec in StageCatalog.enemy_blueprint(current_stage_id):
			var definition := EnemyArchetypes.definition(StringName(spec["role"]))
			var role := StringName(definition["behavior"])
			if role not in roles:
				roles.append(role)
		role_sets.append(roles)
		upgrade_counts.append(run_build.total_levels())
		debug_force_required_progression()
		debug_defeat_stage_boss()
		if stage_number < StageCatalog.STAGE_IDS.size() - 1:
			_advance_stage()
	return {
		"stage_ids": stage_ids,
		"role_sets": role_sets,
		"environments": environments,
		"packet_counts": packet_counts,
		"reward_ids": reward_ids,
		"upgrade_counts": upgrade_counts,
		"final_stage_index": current_stage_index,
		"final_complete": stage_complete,
		"final_mode": mode,
		"final_upgrade_count": run_build.total_levels(),
		"claimed_reward_count": claimed_reward_sources.size(),
	}


func debug_added_stage_mechanics_contract() -> Dictionary:
	current_stage_index = StageCatalog.index_of(&"coral_switchyard")
	current_stage_id = &"coral_switchyard"
	_reset_run(false, true, false)
	mode = RunMode.PLAYING
	var switch_covers_before := _runtime_cover_rects().duplicate()
	var pad := _stage_mechanic_zones(&"switch_pad")[0]
	player_position = Vector2(pad["center"])
	_update_stage_interactions()
	var switched_state := switchyard_gate_state
	var switch_covers_after := _runtime_cover_rects().duplicate()
	var switch_minimap_markers: int = _minimap_snapshot()["markers"].filter(func(marker: Dictionary) -> bool: return String(marker.get("kind", "")) in ["mechanic", "blocker"]).size()
	var behemoth := _make_enemy({"id":"debug_behemoth", "role":&"stage_boss", "pos":_stage_landmark("boss"), "active":true})
	enemies.append(behemoth)
	_boss_select_pattern(behemoth)
	var behemoth_lane_y := float(Vector2(behemoth["committed_target"]).y)
	_boss_begin_active(behemoth)
	for step in 30:
		if String(behemoth["phase"]) != "boss_active":
			break
		_boss_update_active(behemoth, 0.05)
	var behemoth_crash_recovery := String(behemoth["phase"]) == "boss_recovery" and float(behemoth["vulnerable"]) > 1.4
	optional_branch_active = true
	optional_branch_timer = 0.01
	_update_stage_environment(0.02)
	var convoy_failure_optional := optional_branch_failed and not stage_complete and not _reward_claimed(&"field_boss")
	var switch_boss_patterns := BossPatterns.sequence(current_stage_id, false)

	current_stage_index = StageCatalog.index_of(&"abyssal_observatory")
	current_stage_id = &"abyssal_observatory"
	_reset_run(false, true, false)
	mode = RunMode.PLAYING
	var vault_closed_before := not _runtime_cover_rects().is_empty()
	for zone in _stage_mechanic_zones(&"reflector"):
		reflector_orientations[StringName(zone["id"])] = int(zone["vault_orientation"])
	_refresh_runtime_cover_cache()
	var vault_open_after_alignment := _observatory_vault_aligned() and _runtime_cover_rects().size() == _stage_mechanic_zones(&"reflector").size()
	var upper_reflector := _stage_mechanic_zones(&"reflector")[0]
	var reflector_rect := Rect2(upper_reflector["rect"])
	var incoming := Vector2.RIGHT
	var reflection := Rules.first_reflector_hit(
		Vector2(reflector_rect.position.x - 220.0, reflector_rect.get_center().y),
		Vector2(reflector_rect.end.x + 220.0, reflector_rect.get_center().y),
		5.0,
		reflector_orientations,
		current_stage_id,
		_stage_environment_zones
	)
	var outgoing := Vector2(reflection.get("out_direction", Vector2.ZERO))
	var ninety_degree_turn := bool(reflection.get("hit", false)) and absf(incoming.dot(outgoing)) <= 0.001

	var relay := _make_enemy({
		"id":"debug_crown_relay", "role":&"boss_pylon", "pos":Vector2(upper_reflector["relay_position"]),
		"active":true, "requires_reflection":true,
	})
	enemies = [relay]
	var relay_health := float(relay["health"])
	_damage_enemy(relay, 40.0, "player_primary")
	var direct_round_rejected := is_equal_approx(float(relay["health"]), relay_health)
	projectiles.clear()
	_spawn_player_projectile(
		Vector2(reflector_rect.position.x - 220.0, reflector_rect.get_center().y),
		Vector2.RIGHT, 42.0, PRIMARY_PROJECTILE_SPEED, 0
	)
	_update_projectiles(0.22)
	for step in 12:
		_update_projectiles(0.05)
	var reflected_round_damaged_relay := float(relay["health"]) < relay_health
	var observatory_boss_patterns := BossPatterns.sequence(current_stage_id, false)
	var reflector_minimap_markers: int = _minimap_snapshot()["markers"].filter(func(marker: Dictionary) -> bool: return String(marker.get("kind", "")) == "mechanic").size()
	_reset_run(false, true, false)
	mode = RunMode.PLAYING
	player_position = _stage_boss_arena().get_center()
	_start_stage_boss()
	var crown := _find_enemy_by_id("stage_boss")
	var crown_relay_count: int = enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy["alive"]) and StringName(enemy["role"]) == &"boss_pylon").size()
	crown["phase"] = "boss_read"
	crown["pattern_index"] = 0
	_boss_select_pattern(crown)
	_boss_begin_active(crown)
	var children_before_beam := SpecialistRuntime.living_children(String(crown["id"]), enemies)
	for step in 16:
		_boss_update_active(crown, 0.05)
	var beam_spawned_no_children := SpecialistRuntime.living_children(String(crown["id"]), enemies) == children_before_beam
	crown["phase"] = "boss_startup"
	crown["pattern"] = "carrier_wave"
	crown["committed_target"] = player_position
	crown["committed_dir"] = (player_position - Vector2(crown["pos"])).normalized()
	_boss_begin_active(crown)
	for step in 50:
		if String(crown["phase"]) != "boss_active":
			break
		_boss_update_active(crown, 0.05)
	var crown_carrier_children := SpecialistRuntime.living_children(String(crown["id"]), enemies)
	return {
		"switch_cover_count":switch_covers_before.size(),
		"switch_state":switched_state,
		"switch_covers_moved":switch_covers_before != switch_covers_after,
		"switch_minimap_markers":switch_minimap_markers,
		"convoy_failure_optional":convoy_failure_optional,
		"switch_boss_patterns":switch_boss_patterns,
		"behemoth_lane_y":behemoth_lane_y,
		"behemoth_crash_recovery":behemoth_crash_recovery,
		"vault_closed_before":vault_closed_before,
		"vault_open_after_alignment":vault_open_after_alignment,
		"ninety_degree_turn":ninety_degree_turn,
		"direct_round_rejected":direct_round_rejected,
		"reflected_round_damaged_relay":reflected_round_damaged_relay,
		"observatory_boss_patterns":observatory_boss_patterns,
		"reflector_minimap_markers":reflector_minimap_markers,
		"crown_relay_count":crown_relay_count,
		"beam_spawned_no_children":beam_spawned_no_children,
		"crown_carrier_children":crown_carrier_children,
	}


func debug_new_enemy_contract() -> Dictionary:
	current_stage_index = 1
	current_stage_id = StageCatalog.STAGE_IDS[1]
	_reset_run(false, true, false)
	mode = RunMode.PLAYING
	var interceptor := _find_enemy_by_id("archive_interceptor_a")
	interceptor["active"] = true
	var charges_before := int(interceptor["intercept_charges"])
	var intercept_pos := Vector2(interceptor["pos"])
	var probe := {"team": &"player", "radius": 5.0}
	var intercepted := _projectile_intercepted(probe, intercept_pos - Vector2(180.0, 0.0), intercept_pos + Vector2(10.0, 0.0))
	var charges_after := int(interceptor["intercept_charges"])
	var spotter := _make_enemy({"id":"debug_archive_spotter", "role":&"artillery_spotter", "pos":Vector2(1400,1100)})
	enemies.append(spotter)
	spotter["active"] = true
	spotter["committed_target"] = Vector2(1400.0, 1100.0)
	denied_zones.clear()
	_begin_enemy_active(spotter)
	var artillery_zone_created := not denied_zones.is_empty()

	current_stage_index = 2
	current_stage_id = StageCatalog.STAGE_IDS[2]
	_reset_run(false, true, false)
	for enemy in enemies:
		enemy["active"] = false
	var escort := _make_enemy({"id":"debug_drydock_escort", "role":&"shield_escort", "pos":Vector2(1520,1100)})
	var protected := _make_enemy({"id":"debug_drydock_shooter", "role":&"shooter", "pos":Vector2(1640,1100)})
	enemies.append(escort)
	enemies.append(protected)
	escort["active"] = true
	protected["active"] = true
	escort["pos"] = Vector2(protected["pos"]) + Vector2(120.0, 0.0)
	_update_enemy_shield(protected)
	return {
		"intercepted": intercepted,
		"charges_before": charges_before,
		"charges_after": charges_after,
		"artillery_zone_created": artillery_zone_created,
		"escort_shielded_ally": bool(protected["shielded"]),
	}


func debug_specialist_enemy_contract() -> Dictionary:
	current_stage_index = 0
	current_stage_id = StageCatalog.STAGE_IDS[0]
	_reset_run(false, true, false)
	mode = RunMode.PLAYING
	encounter_runtime.elapsed = 10.0

	var rammer := _make_enemy({"id":"debug_rammer", "role":&"rammer", "pos":Vector2(1270,1400), "active":true, "squad_id":"ram_a"})
	enemies = [rammer]
	player_position = Vector2(1700,1400)
	_start_enemy_attack(rammer)
	var rammer_startup := float(rammer["phase_time"])
	_begin_enemy_active(rammer)
	_update_enemy_active(rammer, 0.10)
	var rammer_recovered := String(rammer["phase"]) == "recovery" and float(rammer["vulnerable"]) >= 1.19
	var rammer_health := float(rammer["health"])
	_damage_enemy(rammer, 10.0, "validation")
	var rammer_vulnerability_damage := rammer_health - float(rammer["health"])
	var committed_rammer := _make_enemy({"id":"committed_rammer", "role":&"rammer", "pos":Vector2(1800,1200), "active":true, "squad_id":"shared"})
	committed_rammer["phase"] = "startup"
	var same_squad_rammer := _make_enemy({"id":"same_squad_rammer", "role":&"rammer", "pos":Vector2(1850,1200), "active":true, "squad_id":"shared"})
	var other_squad_rammer := _make_enemy({"id":"other_squad_rammer", "role":&"rammer", "pos":Vector2(1900,1200), "active":true, "squad_id":"other"})
	var rammer_same_squad_blocked := not SpecialistRuntime.rammer_can_commit(same_squad_rammer, [committed_rammer, same_squad_rammer])
	var rammer_second_global_allowed := SpecialistRuntime.rammer_can_commit(other_squad_rammer, [committed_rammer, other_squad_rammer])

	var tender := _make_enemy({"id":"debug_tender", "role":&"repair_tender", "pos":Vector2(2000,1400), "active":true})
	var ally := _make_enemy({"id":"debug_ally", "role":&"chaser", "pos":Vector2(2100,1400), "active":true})
	ally["health"] = float(ally["max_health"]) - 10.0
	enemies = [tender, ally]
	var ally_before := float(ally["health"])
	_update_repair_tender(tender, 0.5)
	var repair_amount := float(ally["health"]) - ally_before
	var blocked_tender := _make_enemy({"id":"blocked_tender", "role":&"repair_tender", "pos":Vector2(1270,1400), "active":true})
	var blocked_ally := _make_enemy({"id":"blocked_ally", "role":&"chaser", "pos":Vector2(1600,1400), "active":true})
	blocked_ally["health"] = 1.0
	var repair_respects_cover := SpecialistRuntime.repair_target_id(blocked_tender, [blocked_tender, blocked_ally], current_stage_id, false).is_empty()

	var carrier := _make_enemy({"id":"debug_carrier", "role":&"drone_carrier", "pos":Vector2(2200,1400), "active":true})
	enemies = [carrier]
	carrier["committed_dir"] = Vector2.RIGHT
	_begin_enemy_active(carrier)
	_update_enemy_active(carrier, 0.01)
	var carrier_first_release := SpecialistRuntime.living_children(String(carrier["id"]), enemies)
	_update_enemy_active(carrier, 0.30)
	var carrier_holds_spacing := SpecialistRuntime.living_children(String(carrier["id"]), enemies) == carrier_first_release
	_update_enemy_active(carrier, 0.351)
	var carrier_second_release := SpecialistRuntime.living_children(String(carrier["id"]), enemies)
	_update_enemy_active(carrier, 0.65)
	for child_attempt in 10:
		_spawn_carrier_child(carrier)
	var carrier_children := SpecialistRuntime.living_children(String(carrier["id"]), enemies)
	_damage_enemy(carrier, 999.0, "validation")
	var children_before_cleanup := SpecialistRuntime.living_children(String(carrier["id"]), enemies)
	_update_enemies(0.7)
	var carrier_queue_cancelled := SpecialistRuntime.living_children(String(carrier["id"]), enemies) == children_before_cleanup

	var beam := _make_enemy({"id":"debug_beam", "role":&"beam_sentinel", "pos":Vector2(1100,1400), "active":true})
	enemies = [beam]
	player_position = Vector2(1700,1400)
	beam["committed_dir"] = Vector2.RIGHT
	_begin_enemy_active(beam)
	var beam_blocked_by_cover := Vector2(beam["beam_end"]).x < player_position.x
	var health_before_blocked := player_health
	_update_enemy_active(beam, 0.1)
	var cover_prevented_damage := is_equal_approx(player_health, health_before_blocked)
	player_position = Vector2(1200,1400)
	player_invulnerable = 0.0
	beam["hit_committed"] = false
	beam["phase"] = "active"
	beam["phase_time"] = SpecialistRuntime.BEAM_ACTIVE
	var health_before_beam := player_health
	_update_enemy_active(beam, 0.1)
	_update_enemy_active(beam, 0.5)
	return {
		"archetype_count":EnemyArchetypes.DEFINITIONS.size(),
		"rammer_startup":rammer_startup,
		"rammer_recovered":rammer_recovered,
		"rammer_vulnerability_damage":rammer_vulnerability_damage,
		"rammer_same_squad_blocked":rammer_same_squad_blocked,
		"rammer_second_global_allowed":rammer_second_global_allowed,
		"repair_amount":repair_amount,
		"repair_target":String(tender["repair_target_id"]),
		"repair_respects_cover":repair_respects_cover,
		"carrier_first_release":carrier_first_release,
		"carrier_holds_spacing":carrier_holds_spacing,
		"carrier_second_release":carrier_second_release,
		"carrier_children":carrier_children,
		"carrier_queue_cancelled":carrier_queue_cancelled,
		"beam_blocked_by_cover":beam_blocked_by_cover,
		"cover_prevented_damage":cover_prevented_damage,
		"beam_dealt_damage":player_health < health_before_beam,
		"beam_recovered":String(beam["phase"]) == "recovery",
	}


func debug_new_upgrade_contract() -> Dictionary:
	_reset_run(false)
	mode = RunMode.PLAYING
	var retired_ids: Array[StringName] = [&"burst_capacitor", &"relay_rounds", &"reserve_charge", &"guardian_seeker", &"emergency_vector", &"field_converter", &"salvage_booster"]
	var retired_missing := true
	var retired_rejected := true
	for upgrade_id in retired_ids:
		retired_missing = retired_missing and upgrade_catalog.get_definition(upgrade_id) == null
		retired_rejected = retired_rejected and not apply_upgrade(upgrade_id)
	for upgrade_id in [&"shock_breach", &"marked_salvo", &"phase_shear", &"coolant_wake", &"static_aegis", &"relay_overload", &"forked_muzzle"]:
		apply_upgrade(upgrade_id)
	player_primary_weapon.reset(false)
	player_primary_weapon.tick(0.0, true, true)
	projectiles.clear()
	_try_fire_primary()
	var forked_level_one_projectiles := projectiles.size()
	apply_upgrade(&"forked_muzzle")
	player_primary_weapon.reset(false)
	player_primary_weapon.tick(0.0, true, true)
	projectiles.clear()
	_try_fire_primary()
	var forked_level_two_projectiles := projectiles.size()
	var shock_breach_damage := _shock_breach_damage(100.0)

	var target := _make_enemy({"id":"debug_upgrade_target", "role":&"chaser", "pos":player_position + Vector2(100,0), "active":true})
	enemies = [target]
	_mark_enemy(target)
	var marked_time := float(target["marked_time"])
	var health_before_shear := float(target["health"])
	target["shear_time"] = 3.0
	_damage_enemy(target, 10.0, "validation")
	var shear_damage := health_before_shear - float(target["health"])

	player_dash_timer = DASH_DURATION
	player_dash_direction = Vector2.RIGHT
	_update_dash(DASH_DURATION)
	var coolant_surge_seconds := coolant_surge_timer
	var coolant_interval := _primary_fire_interval()

	var support := _make_enemy({"id":"debug_support", "role":&"repair_tender", "pos":player_position + Vector2(80,0), "active":true})
	enemies = [support]
	projectiles = []
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	_release_emp(false)
	var aegis_barrier := player_barrier_strength
	var overload_stun := float(support["stun"])
	apply_upgrade(&"static_aegis")
	player_barrier_strength = 0.0
	projectiles.clear()
	_release_emp(false)
	var aegis_level_two_barrier := player_barrier_strength

	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	apply_upgrade(&"aegis_cycle")
	apply_upgrade(&"overclock_cycle")
	apply_upgrade(&"thruster_cycle")
	var cycle_immediate := player_barrier_strength >= 20.0
	for cycle_id in [&"aegis_cycle", &"overclock_cycle", &"thruster_cycle"]:
		cycle_immediate = cycle_immediate and cycle_runtime.is_active(cycle_id)
	apply_upgrade(&"siphon_matrix")
	cycle_runtime.states[&"overclock_cycle"]["active"] = 0.0
	cycle_runtime.states[&"overclock_cycle"]["recharge"] = 12.0
	var siphon_target := _make_enemy({"id":"debug_siphon_target", "role":&"chaser", "pos":player_position + Vector2(100,0), "active":true})
	siphon_target["health"] = 200.0
	siphon_target["max_health"] = 200.0
	enemies = [siphon_target]
	player_health = 50.0
	lifesteal_budget = 6.0
	_damage_enemy(siphon_target, 100.0, "player_primary")
	var siphon_healing := player_health - 50.0
	apply_upgrade(&"siphon_matrix")
	var siphon_cap_target := _make_enemy({"id":"debug_siphon_cap", "role":&"stage_boss", "pos":player_position + Vector2(100,0), "active":true})
	siphon_cap_target["health"] = 500.0
	siphon_cap_target["max_health"] = 500.0
	enemies = [siphon_cap_target]
	player_health = 50.0
	lifesteal_budget = 6.0
	_damage_enemy(siphon_cap_target, 300.0, "EMP")
	var siphon_capped_healing := player_health - 50.0
	var siphon_overkill_target := _make_enemy({"id":"debug_siphon_overkill", "role":&"chaser", "pos":player_position + Vector2(100,0), "active":true})
	siphon_overkill_target["health"] = 10.0
	siphon_overkill_target["max_health"] = 10.0
	enemies = [siphon_overkill_target]
	player_health = 50.0
	lifesteal_budget = 6.0
	_damage_enemy(siphon_overkill_target, 100.0, "player_primary")
	var siphon_overkill_healing := player_health - 50.0
	return {
		"catalog_count":upgrade_catalog.definitions.size(),
		"retired_missing":retired_missing,
		"retired_rejected":retired_rejected,
		"forked_level_one_projectiles":forked_level_one_projectiles,
		"forked_level_two_projectiles":forked_level_two_projectiles,
		"shock_breach_damage":shock_breach_damage,
		"marked_time":marked_time,
		"shear_damage":shear_damage,
		"coolant_surge_timer":coolant_surge_seconds,
		"coolant_interval":coolant_interval,
		"aegis_barrier":aegis_barrier,
		"aegis_level_two_barrier":aegis_level_two_barrier,
		"overload_stun":overload_stun,
		"cycle_immediate":cycle_immediate,
		"cycle_count":cycle_runtime.states.size(),
		"siphon_healing":siphon_healing,
		"siphon_capped_healing":siphon_capped_healing,
		"siphon_overkill_healing":siphon_overkill_healing,
	}


func debug_projectile_cover_contract() -> Dictionary:
	var cover := Rect2(100.0, 100.0, 100.0, 100.0)
	var hit := Rules.segment_rect_hit(Vector2(0.0, 150.0), Vector2(300.0, 150.0), cover, 5.0)
	var miss := Rules.segment_rect_hit(Vector2(0.0, 20.0), Vector2(300.0, 20.0), cover, 5.0)
	return {
		"hit": bool(hit.get("hit", false)),
		"normal": hit.get("normal", Vector2.ZERO),
		"miss": bool(miss.get("hit", false)),
	}


func debug_passive_line_of_sight_contract() -> Dictionary:
	var original_player_position := player_position
	var original_enemies := enemies
	var original_stage_id := current_stage_id
	current_stage_id = &"flooded_works"
	player_position = Vector2(1200.0, 1400.0)
	var open_target := _make_enemy({
		"id": "debug_open_target",
		"role": "shooter",
		"pos": Vector2(1000.0, 1400.0),
		"zone": "debug",
	})
	open_target["active"] = true
	var blocked_target := _make_enemy({
		"id": "debug_blocked_target",
		"role": "shooter",
		"pos": Vector2(1700.0, 1400.0),
		"zone": "debug",
	})
	blocked_target["active"] = true
	enemies = [open_target, blocked_target]
	var targets := _find_passive_targets(2)
	var open_detected := targets.any(func(enemy: Dictionary) -> bool:
		return String(enemy["id"]) == "debug_open_target"
	)
	var blocked_detected := targets.any(func(enemy: Dictionary) -> bool:
		return String(enemy["id"]) == "debug_blocked_target"
	)
	player_position = original_player_position
	enemies = original_enemies
	current_stage_id = original_stage_id
	return {"open": open_detected, "blocked": blocked_detected}


func debug_dash_contract() -> Dictionary:
	var start := Vector2(800.0, 1100.0)
	player_position = start
	player_dash_cooldown = 0.0
	_start_dash(Vector2.RIGHT)
	for step in 20:
		_update_dash(DASH_DURATION / 20.0)
	var displacement := player_position.distance_to(start)
	return {
		"displacement": displacement,
		"cooldown": player_dash_cooldown,
		"invulnerable": player_invulnerable > 0.0,
	}


func debug_pickup_contract(kind: StringName) -> Dictionary:
	player_health = 50.0
	experience_recall_timer = 0.0
	var pickup := {"active": true, "kind": kind, "pos": player_position, "heal_amount": 35.0}
	_collect_pickup(pickup)
	return {
		"collected_once": not bool(pickup["active"]),
		"health": player_health,
		"recall_timer": experience_recall_timer,
	}


func debug_enemy_pressure_contract() -> Dictionary:
	var original_stage_index := current_stage_index
	var original_stage_id := current_stage_id
	var definition := EnemyArchetypes.definition(&"chaser")
	var priority_definition := EnemyArchetypes.definition(&"turret")
	current_stage_index = 0
	current_stage_id = StageCatalog.STAGE_IDS[0]
	var sample := _make_enemy({"id": "debug_pressure_chaser", "role": &"chaser", "pos": Vector2.ZERO})
	var priority_sample := _make_enemy({"id": "debug_pressure_priority", "role": &"turret", "pos": Vector2.ZERO})
	var boss_definition := EnemyArchetypes.definition(&"field_boss")
	var boss_sample := _make_enemy({"id": "debug_pressure_boss", "role": &"field_boss", "pos": Vector2.ZERO})
	var stage_one_damage := _scaled_incoming_damage(10.0, true)
	current_stage_index = 4
	current_stage_id = StageCatalog.STAGE_IDS[4]
	var final_sample := _make_enemy({"id": "debug_pressure_final_chaser", "role": &"chaser", "pos": Vector2.ZERO})
	var final_priority_sample := _make_enemy({"id": "debug_pressure_final_priority", "role": &"turret", "pos": Vector2.ZERO})
	var final_damage := _scaled_incoming_damage(10.0, true)
	current_stage_index = original_stage_index
	current_stage_id = original_stage_id
	return {
		"base_health": float(definition["health"]),
		"runtime_health": float(sample["max_health"]),
		"base_boss_health": float(boss_definition["health"]),
		"runtime_boss_health": float(boss_sample["max_health"]),
		"base_priority_health": float(priority_definition["health"]),
		"stage_one_priority_health": float(priority_sample["max_health"]),
		"stage_five_priority_health": float(final_priority_sample["max_health"]),
		"base_speed": float(definition["speed"]),
		"runtime_speed": float(sample["speed"]),
		"stage_five_health": float(final_sample["max_health"]),
		"stage_five_speed": float(final_sample["speed"]),
		"base_projectile_speed": 100.0,
		"runtime_projectile_speed": 100.0 * EncounterDirector.HOSTILE_PROJECTILE_SPEED_MULTIPLIER,
		"base_damage": 10.0,
		"runtime_damage": stage_one_damage,
		"stage_five_damage": final_damage,
		"boss_final_damage": _scaled_incoming_damage(34.0, true, true),
		"environment_damage": _scaled_incoming_damage(10.0, false),
		"base_recovery": 0.55,
		"runtime_recovery": _enemy_recovery_cooldown(&"chaser"),
	}


func debug_performance_contract() -> Dictionary:
	current_stage_index = 2
	current_stage_id = StageCatalog.STAGE_IDS[2]
	_reset_run(false, true, false)
	encounter_runtime.current_beat = 4
	_debug_append_packet_enemies(encounter_runtime.active_cap() + 12)
	var committed_ids: Array[String] = []
	for enemy in enemies:
		if not bool(enemy.get("counts_active_cap", false)):
			continue
		enemy["active"] = true
		if committed_ids.size() < 3:
			enemy["phase"] = "startup"
			committed_ids.append(String(enemy["id"]))
	_enforce_active_enemy_cap()
	var active_capped := 0
	var committed_preserved := true
	for enemy in enemies:
		if bool(enemy["active"]) and bool(enemy.get("counts_active_cap", false)):
			active_capped += 1
		if String(enemy["id"]) in committed_ids and not bool(enemy["active"]):
			committed_preserved = false
	var backdrop_contract: Dictionary = _backdrop.debug_contract()
	return {
		"active_capped": active_capped,
		"active_cap": encounter_runtime.active_cap(),
		"committed_preserved": committed_preserved,
		"backdrop_cached": bool(backdrop_contract["static_cached"]),
		"backdrop_behind": bool(backdrop_contract["behind_gameplay"]),
		"threat_sample_interval": THREAT_SAMPLE_INTERVAL,
		"hud_refresh_interval": HUD_REFRESH_INTERVAL,
		"stage_definition_build_count": int(StageCatalog.debug_cache_contract(current_stage_id)["definition_build_count"]),
	}


func debug_reset_contract() -> Dictionary:
	apply_upgrade(&"ram_pulse")
	var before := applied_upgrades.size()
	_reset_run(false)
	return {
		"before": before,
		"after": applied_upgrades.size(),
		"chest_claimed": chest_claimed,
		"generators": generators_destroyed,
	}
