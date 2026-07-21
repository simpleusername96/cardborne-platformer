class_name VehicleStageOne
extends Node2D

## Complete vehicle-led Stage 1 experiment.
##
## The scene intentionally uses a single authored 2D ground plane and project-owned
## geometry. Manual aim, projectile/cover truth, fixed installations, moving roles,
## pickups, upgrades, optional elite, stage boss, results, and garage all live here.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

enum RunMode {
	DEPLOYMENT,
	PLAYING,
	UPGRADE,
	PAUSED,
	RESULT,
	GARAGE,
}

const SAVE_PATH := "user://vehicle-stage-one.cfg"
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

var mode := RunMode.DEPLOYMENT
var mode_before_pause := RunMode.PLAYING
var _ui: Variant
var _camera: Camera2D
var _rng := RandomNumberGenerator.new()

var player_position := Rules.PLAYER_START
var player_hull_direction := Vector2.RIGHT
var player_aim_direction := Vector2.RIGHT
var player_health := PLAYER_MAX_HEALTH
var player_invulnerable := 0.0
var player_hit_flash := 0.0
var player_primary_cooldown := 0.0
var player_primary_shot_index := 0
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
var attack_boost_timer := 0.0
var overdrive_timer := 0.0
var _aim_target_id := ""
var _last_damage_source := ""

var selected_primary := &"repeater"
var selected_upgrade_title := "None"
var applied_upgrades: Dictionary = {}
var current_card_offer: Array[Dictionary] = []

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

var visited_cells: Dictionary = {}
var discovered_markers: Dictionary = {}
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

var _sound_players: Array[AudioStreamPlayer] = []
var _sound_cursor := 0
var _sounds: Dictionary = {}

var _capture_directory := ""
var _capture_mode := false


func _ready() -> void:
	_rng.seed = 0xC4A2B0
	_build_camera()
	_build_ui()
	_build_audio()
	_load_persistence()
	_reset_run(false)
	_ui.show_deployment(selected_primary)
	_set_mouse_for_mode()
	_parse_capture_arguments()
	queue_redraw()


func _exit_tree() -> void:
	# Procedural streams are runtime-owned; release active playback references so
	# headless validation and scene replacement do not retain audio resources.
	for player in _sound_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_sound_players.clear()
	_sounds.clear()


func _physics_process(delta: float) -> void:
	if mode == RunMode.PLAYING:
		run_time += delta
		_update_player(delta)
		_update_pickups()
		_update_enemies(delta)
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
	if is_instance_valid(_ui):
		_ui.update_hud(_build_hud_snapshot())
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == RunMode.PLAYING:
			_pause_run()
		elif mode == RunMode.PAUSED:
			_resume_run()
		get_viewport().set_input_as_handled()
		return

	if mode == RunMode.UPGRADE and event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_3:
			var index := int(key_event.keycode - KEY_1)
			if index < current_card_offer.size():
				_on_upgrade_selected(StringName(current_card_offer[index]["id"]))
				get_viewport().set_input_as_handled()
				return

	if mode == RunMode.DEPLOYMENT and event is InputEventKey and event.pressed and not event.echo:
		var deployment_event := event as InputEventKey
		if deployment_event.keycode == KEY_1:
			_on_deployment_selected(&"repeater")
		elif deployment_event.keycode == KEY_2:
			_on_deployment_selected(&"scatter")


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "VehicleCamera"
	_camera.enabled = true
	_camera.position = Rules.PLAYER_START
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.limit_left = int(Rules.WORLD_RECT.position.x)
	_camera.limit_top = int(Rules.WORLD_RECT.position.y)
	_camera.limit_right = int(Rules.WORLD_RECT.end.x)
	_camera.limit_bottom = int(Rules.WORLD_RECT.end.y)
	add_child(_camera)


func _build_ui() -> void:
	_ui = StageUI.new()
	_ui.name = "VehicleStageUI"
	add_child(_ui)
	_ui.deployment_selected.connect(_on_deployment_selected)
	_ui.upgrade_selected.connect(_on_upgrade_selected)
	_ui.resume_requested.connect(_resume_run)
	_ui.restart_requested.connect(_restart_stage)
	_ui.garage_requested.connect(_show_garage)
	_ui.replay_requested.connect(_replay_stage)
	_ui.primary_changed.connect(_on_primary_changed)


func _build_audio() -> void:
	for index in 10:
		var player := AudioStreamPlayer.new()
		player.name = "ProceduralSFX%d" % index
		player.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
		add_child(player)
		_sound_players.append(player)
	_sounds = {
		"primary": _make_tone(640.0, 0.055, 0.25, -120.0),
		"scatter": _make_tone(410.0, 0.085, 0.28, -180.0),
		"impact": _make_tone(180.0, 0.07, 0.22, -80.0),
		"dash": _make_tone(260.0, 0.18, 0.32, 720.0),
		"missile": _make_tone(330.0, 0.13, 0.23, 220.0),
		"emp_start": _make_tone(140.0, 0.38, 0.27, 480.0),
		"emp": _make_tone(90.0, 0.48, 0.38, -25.0),
		"pickup": _make_tone(520.0, 0.18, 0.26, 420.0),
		"hurt": _make_tone(115.0, 0.19, 0.30, -65.0),
		"destroy": _make_tone(95.0, 0.30, 0.34, -45.0),
		"boss": _make_tone(72.0, 0.62, 0.42, 35.0),
		"card": _make_tone(390.0, 0.30, 0.25, 360.0),
	}


func _make_tone(frequency: float, duration: float, volume: float, sweep: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := maxi(1, int(duration * sample_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var progress := float(index) / float(sample_count)
		var current_frequency := frequency + sweep * progress
		var envelope := sin(progress * PI)
		var phase := TAU * current_frequency * float(index) / float(sample_rate)
		var sample := clampi(int(sin(phase) * envelope * volume * 32767.0), -32768, 32767)
		var unsigned := sample & 0xFFFF
		data[index * 2] = unsigned & 0xFF
		data[index * 2 + 1] = (unsigned >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_sound(sound_id: StringName, pitch: float = 1.0) -> void:
	if not _sounds.has(sound_id) or _sound_players.is_empty():
		return
	var player := _sound_players[_sound_cursor % _sound_players.size()]
	_sound_cursor += 1
	player.stream = _sounds[sound_id]
	player.pitch_scale = pitch
	player.play()


func _reset_run(increment_index: bool = true) -> void:
	if increment_index:
		run_index += 1
	mode = RunMode.DEPLOYMENT
	player_position = Rules.PLAYER_START
	player_hull_direction = Vector2.RIGHT
	player_aim_direction = Vector2.RIGHT
	player_health = PLAYER_MAX_HEALTH
	player_invulnerable = 0.0
	player_hit_flash = 0.0
	player_primary_cooldown = 0.0
	player_primary_shot_index = 0
	player_dash_cooldown = 0.0
	player_dash_timer = 0.0
	player_passive_cooldown = 0.0
	player_emp_cooldown = 0.0
	player_emp_startup = 0.0
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	attack_boost_timer = 0.0
	overdrive_timer = 0.0
	_aim_target_id = ""
	_last_damage_source = ""

	applied_upgrades.clear()
	selected_upgrade_title = "None"
	current_card_offer.clear()
	enemies.clear()
	projectiles.clear()
	pickups.clear()
	crates.clear()
	denied_zones.clear()
	effects.clear()
	damaging_trails.clear()
	for spec in Rules.get_enemy_blueprint():
		enemies.append(_make_enemy(spec))
	for spec in Rules.get_pickup_blueprint():
		pickups.append({
			"id": String(spec["id"]),
			"kind": StringName(spec["kind"]),
			"pos": Vector2(spec["pos"]),
			"active": true,
			"pulse": _rng.randf_range(0.0, TAU),
		})
	for spec in Rules.get_crate_blueprint():
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
	run_time = 0.0
	visited_cells.clear()
	discovered_markers.clear()
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
	var role := StringName(spec["role"])
	var health := 60.0
	var speed := 170.0
	var radius := 25.0
	var display_name := "Threat"
	var attack_cooldown := _rng.randf_range(0.4, 1.2)
	match role:
		&"chaser":
			health = 72.0
			speed = 205.0
			radius = 26.0
			display_name = "Rivet Chaser"
		&"shooter":
			health = 58.0
			speed = 155.0
			radius = 24.0
			display_name = "Lane Skirmisher"
		&"controller":
			health = 84.0
			speed = 135.0
			radius = 29.0
			display_name = "Flood Controller"
		&"turret":
			health = 110.0
			speed = 0.0
			radius = 31.0
			display_name = "Foundry Turret"
		&"mine":
			health = 65.0
			speed = 0.0
			radius = 27.0
			display_name = "Arc Proximity Mine"
		&"generator":
			health = 155.0
			speed = 0.0
			radius = 37.0
			display_name = "Barrier Generator"
		&"field_boss":
			health = 620.0
			speed = 185.0
			radius = 52.0
			display_name = "Dredge Warden"
		&"boss_pylon":
			health = 120.0
			speed = 0.0
			radius = 33.0
			display_name = "Colossus Pylon"
		&"stage_boss":
			health = 1450.0
			speed = 150.0
			radius = 76.0
			display_name = "Foundry Colossus"
	var position: Vector2 = spec["pos"]
	return {
		"id": String(spec.get("id", role)),
		"role": role,
		"name": display_name,
		"pos": position,
		"home": position,
		"velocity": Vector2.ZERO,
		"health": health,
		"max_health": health,
		"speed": speed,
		"radius": radius,
		"alive": true,
		"active": role == &"generator" or role == &"turret" or role == &"mine",
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
		"strafe_sign": -1.0 if String(spec.get("id", "")).hash() % 2 == 0 else 1.0,
		"stuck_time": 0.0,
		"reposition_time": 0.0,
		"reposition_dir": Vector2.ZERO,
		"zone": String(spec.get("zone", "")),
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


func _on_deployment_selected(primary_id: StringName) -> void:
	selected_primary = primary_id
	_save_persistence()
	_reset_run(false)
	selected_primary = primary_id
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify(
		"DEPLOYED // Aim at installations before their pressure overlaps.",
		3.2,
		Rules.CYAN
	)
	_play_sound(&"card", 1.15)
	_set_mouse_for_mode()


func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if mode != RunMode.UPGRADE:
		return
	if not apply_upgrade(upgrade_id):
		return
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify("MODULE ONLINE // %s" % selected_upgrade_title, 3.0, Rules.AMBER)
	_play_sound(&"card", 1.0)
	_set_mouse_for_mode()


func _on_primary_changed(primary_id: StringName) -> void:
	selected_primary = primary_id
	_save_persistence()


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
	_reset_run(true)
	selected_primary = primary
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify("STAGE RESET // Build and one-shot rewards cleared.", 2.6, Rules.MUTED)
	_set_mouse_for_mode()


func _replay_stage() -> void:
	var primary := selected_primary
	_reset_run(true)
	selected_primary = primary
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	_ui.notify("REDEPLOYED // Try another route or card combination.", 2.8, Rules.CYAN)
	_set_mouse_for_mode()


func _show_garage() -> void:
	mode = RunMode.GARAGE
	player_health = PLAYER_MAX_HEALTH
	projectiles.clear()
	denied_zones.clear()
	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": persistent_clear_count,
		"relay_module_unlocked": persistent_relay_module,
		"field_module_unlocked": persistent_field_module,
	})
	_set_mouse_for_mode()


func _set_mouse_for_mode() -> void:
	if _capture_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if mode == RunMode.PLAYING else Input.MOUSE_MODE_VISIBLE


func _update_player(delta: float) -> void:
	player_invulnerable = maxf(0.0, player_invulnerable - delta)
	player_primary_cooldown = maxf(0.0, player_primary_cooldown - delta)
	player_dash_cooldown = maxf(0.0, player_dash_cooldown - delta)
	player_passive_cooldown = maxf(0.0, player_passive_cooldown - delta)
	player_emp_cooldown = maxf(0.0, player_emp_cooldown - delta)
	player_barrier_timer = maxf(0.0, player_barrier_timer - delta)
	attack_boost_timer = maxf(0.0, attack_boost_timer - delta)
	overdrive_timer = maxf(0.0, overdrive_timer - delta)
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
		var speed_multiplier := 1.35 if overdrive_timer > 0.0 else 1.0
		var motion := move_input * PLAYER_BASE_SPEED * speed_multiplier * delta
		player_position = _move_actor(player_position, motion, Rules.PLAYER_RADIUS, true)
		if Input.is_action_just_pressed("dash") and player_dash_cooldown <= 0.0:
			_start_dash(move_input)

	if Input.is_action_pressed("primary_fire") and player_primary_cooldown <= 0.0 and player_dash_timer <= 0.0:
		_fire_primary()

	if Input.is_action_just_pressed("active_skill") and player_emp_cooldown <= 0.0 and player_emp_startup <= 0.0:
		_start_emp()

	if player_emp_startup > 0.0:
		player_emp_startup = maxf(0.0, player_emp_startup - delta)
		if player_emp_startup <= 0.0:
			_release_emp(false)

	_update_passive_secondary()
	_update_aim_target()
	_mark_visited()
	_apply_overdrive_ram(delta)

	if tutorial_move and tutorial_aim and tutorial_fire and tutorial_dash and not tutorial_announced:
		tutorial_announced = true
		_ui.notify("CALIBRATION COMPLETE // The north gate was never kill-locked.", 3.0, Rules.MOSS)


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
	player_dash_cooldown = DASH_COOLDOWN
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
	player_dash_trail_timer -= delta
	if player_dash_trail_timer <= 0.0:
		player_dash_trail_timer = 0.035
		_add_effect("afterimage", before, Rules.CYAN, 0.20, 30.0, player_dash_direction)
		if applied_upgrades.has(&"ion_wake"):
			damaging_trails.append({
				"pos": before,
				"radius": 42.0 if overdrive_timer <= 0.0 else 58.0,
				"time": 0.75 if overdrive_timer <= 0.0 else 1.15,
				"duration": 0.75 if overdrive_timer <= 0.0 else 1.15,
				"hit_ids": {},
			})
	if player_dash_timer <= 0.0:
		if applied_upgrades.has(&"ram_pulse"):
			_damage_enemies_in_radius(player_position, 145.0, 32.0, 24.0, "Ram Pulse")
			_clear_hostile_projectiles(player_position, 170.0)
			_add_effect("shock", player_position, Rules.AMBER, 0.38, 170.0)
			_play_sound(&"emp", 1.55)


func _fire_primary() -> void:
	tutorial_fire = true
	player_primary_shot_index += 1
	player_muzzle_flash = 0.075
	var attack_multiplier := 1.50 if attack_boost_timer > 0.0 else 1.0
	var interval_multiplier := 0.72 if attack_boost_timer > 0.0 else 1.0
	var origin := player_position + player_aim_direction * 39.0
	if selected_primary == &"scatter":
		player_primary_cooldown = 0.19 * interval_multiplier
		for offset in [-0.12, 0.0, 0.12]:
			_spawn_player_projectile(
				origin,
				player_aim_direction.rotated(float(offset)),
				7.5 * attack_multiplier,
				780.0,
				0
			)
		_play_sound(&"scatter", _rng.randf_range(0.96, 1.04))
	else:
		player_primary_cooldown = 0.108 * interval_multiplier
		_spawn_player_projectile(
			origin,
			player_aim_direction,
			12.0 * attack_multiplier,
			PRIMARY_PROJECTILE_SPEED,
			0
		)
		_play_sound(&"primary", _rng.randf_range(0.96, 1.05))

	if applied_upgrades.has(&"forked_muzzle") and player_primary_shot_index % 5 == 0:
		for offset in [-0.20, 0.20]:
			_spawn_player_projectile(
				origin,
				player_aim_direction.rotated(float(offset)),
				7.0 * attack_multiplier,
				960.0,
				0
			)
	_add_effect("muzzle", origin, Art.MUSTARD, 0.09, 32.0, player_aim_direction)


func _spawn_player_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, extra_pierce: int) -> void:
	projectiles.append({
		"pos": origin,
		"velocity": direction.normalized() * speed,
		"radius": 5.0,
		"team": &"player",
		"damage": damage,
		"life": PRIMARY_RANGE / speed,
		"color": Art.MUSTARD,
		"owner": "player_primary",
		"pierce": extra_pierce + (1 if applied_upgrades.has(&"phase_lance") else 0),
		"bounces": 1 if applied_upgrades.has(&"ricochet_matrix") else 0,
		"homing": false,
		"target_id": "",
		"explosive": false,
		"stagger": 5.0,
	})


func _update_passive_secondary() -> void:
	if player_passive_cooldown > 0.0 or player_emp_startup > 0.0:
		return
	var targets := _find_passive_targets(2 if applied_upgrades.has(&"twin_seekers") else 1)
	if targets.is_empty():
		return
	var cooldown := PASSIVE_COOLDOWN
	if persistent_field_module:
		cooldown *= 0.85
	player_passive_cooldown = cooldown
	for target in targets:
		var enemy: Dictionary = target
		var direction := (Vector2(enemy["pos"]) - player_position).normalized()
		projectiles.append({
			"pos": player_position + direction * 33.0,
			"velocity": direction * 490.0,
			"radius": 8.0,
			"team": &"player",
			"damage": 25.0,
			"life": 1.8,
			"color": Art.MINT,
			"owner": "passive_seeker",
			"pierce": 0,
			"bounces": 0,
			"homing": true,
			"target_id": String(enemy["id"]),
			"explosive": applied_upgrades.has(&"hunter_firmware"),
			"stagger": 12.0,
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
		if not Rules.has_line_of_sight(player_position, Vector2(enemy["pos"]), 6.0, _boss_gate_closed()):
			continue
		var priority := 0.0
		var role := StringName(enemy["role"])
		if applied_upgrades.has(&"hunter_firmware"):
			if role in [&"generator", &"turret", &"mine", &"boss_pylon"]:
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
	_add_effect("emp_start", player_position, Art.BOSS_MAGENTA, EMP_STARTUP, EMP_RADIUS)


func _release_emp(is_aftershock: bool) -> void:
	var radius := EMP_RADIUS * (0.68 if is_aftershock else 1.0)
	var damage := 34.0 if is_aftershock else 62.0
	_damage_enemies_in_radius(player_position, radius, damage, 42.0, "EMP Aftershock" if is_aftershock else "EMP Nova")
	_clear_hostile_projectiles(player_position, radius + 40.0)
	for enemy in enemies:
		if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(player_position) <= radius:
			enemy["stun"] = maxf(float(enemy["stun"]), 1.25 if is_aftershock else 2.1)
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
	return EMP_COOLDOWN - (1.5 if persistent_relay_module else 0.0)


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
	var duration := 12.0 if applied_upgrades.has(&"field_converter") else 9.0
	match kind:
		&"repair":
			var before := player_health
			player_health = minf(PLAYER_MAX_HEALTH, player_health + 34.0)
			_ui.notify("REPAIR FOAM // +%d hull" % roundi(player_health - before), 2.0, Rules.MOSS)
		&"attack":
			attack_boost_timer = maxf(attack_boost_timer, duration)
			_ui.notify("ATTACK BOOST // Damage and cadence increased", 2.2, Rules.CORAL)
		&"overdrive":
			overdrive_timer = maxf(overdrive_timer, duration)
			_ui.notify("OVERDRIVE // Faster movement, safe ramming", 2.2, Rules.AMBER)
		&"barrier":
			player_barrier_strength = maxf(player_barrier_strength, 48.0)
			if applied_upgrades.has(&"field_converter"):
				player_barrier_strength += 10.0
			player_barrier_timer = maxf(player_barrier_timer, duration + 2.0)
			_clear_hostile_projectiles(player_position, 210.0)
			_repel_nearby_enemies(240.0)
			_ui.notify("REPULSION BARRIER // Projectiles cleared", 2.2, Rules.CYAN)
	_add_effect("pickup", Vector2(pickup["pos"]), _pickup_color(kind), 0.40, 65.0)
	_play_sound(&"pickup")


func _pickup_color(kind: StringName) -> Color:
	match kind:
		&"repair":
			return Art.MINT
		&"attack":
			return Art.CORAL
		&"overdrive":
			return Art.MUSTARD
		&"barrier":
			return Art.COBALT_WATER
	return Art.IVORY_BRIGHT


func _update_enemies(delta: float) -> void:
	var committed_threats := 0
	for enemy in enemies:
		if not bool(enemy["alive"]):
			continue
		if String(enemy["phase"]) in ["startup", "active"] and StringName(enemy["role"]) not in [&"stage_boss", &"field_boss", &"generator", &"boss_pylon"]:
			committed_threats += 1

	for enemy in enemies:
		if not bool(enemy["alive"]):
			continue
		enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
		enemy["stun"] = maxf(0.0, float(enemy["stun"]) - delta)
		enemy["ram_cooldown"] = maxf(0.0, float(enemy["ram_cooldown"]) - delta)
		enemy["vulnerable"] = maxf(0.0, float(enemy["vulnerable"]) - delta)
		_update_enemy_activation(enemy)
		if not bool(enemy["active"]):
			continue
		_update_enemy_shield(enemy)
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
		var started := _update_ordinary_enemy(enemy, delta, committed_threats < 2)
		if started:
			committed_threats += 1


func _update_enemy_activation(enemy: Dictionary) -> void:
	if bool(enemy["active"]):
		return
	var role := StringName(enemy["role"])
	var distance := player_position.distance_to(Vector2(enemy["pos"]))
	if role == &"field_boss":
		enemy["active"] = player_position.x > 2380.0 and player_position.y < 820.0
	elif distance < 920.0:
		enemy["active"] = true


func _update_enemy_shield(enemy: Dictionary) -> void:
	var role := StringName(enemy["role"])
	if role in [&"generator", &"field_boss", &"stage_boss", &"boss_pylon"]:
		enemy["shielded"] = false
		return
	enemy["shielded"] = false
	for support in enemies:
		if not bool(support["alive"]) or StringName(support["role"]) != &"generator":
			continue
		if Vector2(support["pos"]).distance_to(Vector2(enemy["pos"])) <= 390.0:
			enemy["shielded"] = true
			return


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


func _update_boss_pylon(enemy: Dictionary, delta: float) -> void:
	enemy["support_tick"] = float(enemy["support_tick"]) - delta
	if float(enemy["support_tick"]) <= 0.0:
		enemy["support_tick"] = 2.4
		denied_zones.append({
			"pos": Vector2(enemy["pos"]),
			"radius": 125.0,
			"warning": 0.70,
			"duration": 1.8,
			"tick": 0.0,
			"damage": 9.0,
			"source": "Colossus pylon field",
			"color": Rules.VIOLET,
		})


func _update_ordinary_enemy(enemy: Dictionary, delta: float, can_commit: bool) -> bool:
	enemy["attack_cooldown"] = maxf(0.0, float(enemy["attack_cooldown"]) - delta)
	var phase := String(enemy["phase"])
	if phase == "startup":
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
	match role:
		&"chaser":
			return 0.55
		&"shooter":
			return 0.78
		&"controller":
			return 1.15
		&"turret":
			return 1.05
		&"mine":
			return 1.8
	return 0.8


func _enemy_can_attack(enemy: Dictionary) -> bool:
	var role := StringName(enemy["role"])
	var distance := Vector2(enemy["pos"]).distance_to(player_position)
	match role:
		&"chaser":
			return distance <= 175.0
		&"shooter":
			return distance <= 620.0 and Rules.has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0, _boss_gate_closed())
		&"controller":
			return distance <= 590.0 and Rules.has_line_of_sight(Vector2(enemy["pos"]), player_position, 4.0, _boss_gate_closed())
		&"turret":
			return distance <= 760.0 and Rules.has_line_of_sight(Vector2(enemy["pos"]), player_position, 7.0, _boss_gate_closed())
		&"mine":
			return distance <= 190.0
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


func _update_enemy_active(enemy: Dictionary, delta: float) -> void:
	var role := StringName(enemy["role"])
	enemy["phase_time"] = maxf(0.0, float(enemy["phase_time"]) - delta)
	match role:
		&"chaser":
			var before := Vector2(enemy["pos"])
			enemy["pos"] = _move_actor(
				before,
				Vector2(enemy["committed_dir"]) * 570.0 * delta,
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
		_:
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.6


func _move_enemy_role(enemy: Dictionary, delta: float, recovering: bool) -> void:
	var role := StringName(enemy["role"])
	if role in [&"turret", &"mine"]:
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
	var velocity := desired.normalized() * float(enemy["speed"])
	_move_enemy_with_recovery(enemy, velocity, delta)


func _move_enemy_with_recovery(enemy: Dictionary, velocity: Vector2, delta: float) -> void:
	if float(enemy["reposition_time"]) > 0.0:
		enemy["reposition_time"] = maxf(0.0, float(enemy["reposition_time"]) - delta)
		velocity = Vector2(enemy["reposition_dir"]) * float(enemy["speed"])
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
	var result := Rules.move_circle(position, motion, radius, _boss_gate_closed())
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
	if is_player and boss_locked and not Rules.BOSS_ARENA.grow(-20.0).has_point(result):
		result = position
	return result


func _spawn_hostile_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, source: String, color: Color) -> void:
	if _count_hostile_projectiles() >= 42:
		return
	projectiles.append({
		"pos": origin,
		"velocity": direction.normalized() * speed,
		"radius": 7.0,
		"team": &"enemy",
		"damage": damage,
		"life": 2.2,
		"color": color,
		"owner": source,
		"pierce": 0,
		"bounces": 0,
		"homing": false,
		"target_id": "",
		"explosive": false,
		"stagger": 0.0,
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
		if bool(projectile["homing"]):
			var target := _find_enemy_by_id(String(projectile["target_id"]))
			if not target.is_empty() and bool(target["alive"]):
				var desired := (Vector2(target["pos"]) - Vector2(projectile["pos"])).normalized()
				var current := Vector2(projectile["velocity"]).normalized()
				var steered := current.lerp(desired, clampf(delta * 4.2, 0.0, 1.0)).normalized()
				projectile["velocity"] = steered * Vector2(projectile["velocity"]).length()
		var from := Vector2(projectile["pos"])
		var to := from + Vector2(projectile["velocity"]) * delta
		var cover_hit := Rules.first_cover_hit(from, to, float(projectile["radius"]), _boss_gate_closed())
		if bool(cover_hit.get("hit", false)):
			if int(projectile["bounces"]) > 0:
				projectile["bounces"] = int(projectile["bounces"]) - 1
				var normal: Vector2 = cover_hit["normal"]
				projectile["velocity"] = Vector2(projectile["velocity"]).bounce(normal)
				projectile["pos"] = Vector2(cover_hit["point"]) + normal * (float(projectile["radius"]) + 2.0)
				_add_effect("impact", Vector2(projectile["pos"]), Rules.CYAN, 0.15, 18.0)
				continue
			_add_effect("impact", Vector2(cover_hit["point"]), Color(projectile["color"]), 0.14, 20.0)
			projectiles.remove_at(index)
			continue

		projectile["pos"] = to
		if StringName(projectile["team"]) == &"enemy":
			if Rules.point_segment_distance(player_position, from, to) <= Rules.PLAYER_RADIUS + float(projectile["radius"]):
				_damage_player(float(projectile["damage"]), String(projectile["owner"]), true)
				projectiles.remove_at(index)
				continue
		else:
			if _projectile_hits_crate(projectile, from, to):
				projectiles.remove_at(index)
				continue
			var hit_enemy := _first_enemy_on_segment(from, to, float(projectile["radius"]))
			if not hit_enemy.is_empty():
				var hit_position := Vector2(hit_enemy["pos"])
				_damage_enemy(
					hit_enemy,
					float(projectile["damage"]),
					String(projectile["owner"]),
					float(projectile["stagger"])
				)
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


func _projectile_hits_crate(projectile: Dictionary, from: Vector2, to: Vector2) -> bool:
	for crate in crates:
		if not bool(crate["alive"]):
			continue
		if Rules.point_segment_distance(Vector2(crate["pos"]), from, to) <= 31.0 + float(projectile["radius"]):
			_damage_crate(crate, float(projectile["damage"]))
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
			_damage_player(float(zone["damage"]), String(zone["source"]), false)


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
	effects.append({
		"kind": kind,
		"pos": position,
		"color": color,
		"time": duration,
		"duration": duration,
		"radius": radius,
		"dir": direction,
	})


func _damage_enemy(enemy: Dictionary, amount: float, source: String, stagger: float = 0.0) -> void:
	if not bool(enemy["alive"]):
		return
	var role := StringName(enemy["role"])
	var multiplier := 1.0
	if bool(enemy["shielded"]):
		multiplier *= 0.45
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
			enemy["pattern"] = "STAGGER WINDOW"
			enemy["vulnerable"] = 3.0
			_ui.notify("COLOSSUS STAGGERED // Commit damage now", 2.8, Rules.AMBER)
			_play_sound(&"boss", 1.35)
	enemy["health"] = float(enemy["health"]) - amount * multiplier
	enemy["flash"] = 0.11
	if float(enemy["health"]) <= 0.0:
		_defeat_enemy(enemy, source)


func _defeat_enemy(enemy: Dictionary, source: String) -> void:
	if not bool(enemy["alive"]):
		return
	enemy["alive"] = false
	enemy["active"] = false
	stats_enemies_defeated += 1
	var role := StringName(enemy["role"])
	if role in [&"generator", &"turret", &"mine", &"boss_pylon"]:
		stats_installations += 1
		if applied_upgrades.has(&"circuit_harvest"):
			player_passive_cooldown = maxf(0.0, player_passive_cooldown - 0.75)
			player_emp_cooldown = maxf(0.0, player_emp_cooldown - 2.0)
	if role == &"generator" and bool(enemy["required"]):
		generators_destroyed += 1
		_ui.notify(
			"GENERATOR %d / 2 DESTROYED // Nearby shields collapsed" % generators_destroyed,
			2.8,
			Rules.AMBER
		)
	if role == &"field_boss":
		field_boss_defeated = true
		persistent_field_module = true
		player_barrier_strength = maxf(player_barrier_strength, 35.0)
		player_barrier_timer = maxf(player_barrier_timer, 10.0)
		player_passive_cooldown = 0.0
		_save_persistence()
		_ui.notify("DREDGE CAPACITOR ACQUIRED // Seeker cadence improved", 4.0, Rules.AMBER)
	if role == &"stage_boss":
		_complete_stage()
	_add_effect("destroy", Vector2(enemy["pos"]), _enemy_color(role), 0.65 if role in [&"field_boss", &"stage_boss"] else 0.38, float(enemy["radius"]) * 1.8)
	_play_sound(&"destroy", 0.72 if role in [&"field_boss", &"stage_boss"] else 1.0)
	_clear_zones_owned_by_defeated_role(role)


func _clear_zones_owned_by_defeated_role(role: StringName) -> void:
	if role in [&"stage_boss", &"boss_pylon"]:
		for index in range(denied_zones.size() - 1, -1, -1):
			if String(denied_zones[index]["source"]).contains("Colossus"):
				denied_zones.remove_at(index)


func _damage_player(amount: float, source: String, blockable: bool) -> void:
	if mode != RunMode.PLAYING or player_invulnerable > 0.0 or stage_complete:
		return
	var remaining := amount
	if player_barrier_strength > 0.0 and player_barrier_timer > 0.0:
		var absorbed := minf(player_barrier_strength, remaining)
		player_barrier_strength -= absorbed
		remaining -= absorbed
		_add_effect("barrier_hit", player_position, Rules.CYAN, 0.20, 70.0)
		if player_barrier_strength <= 0.0:
			_ui.notify("BARRIER DEPLETED", 1.6, Rules.CORAL)
	if remaining <= 0.0:
		return
	if overdrive_timer > 0.0 and source.contains("lunge"):
		remaining *= 0.20
	player_health = maxf(0.0, player_health - remaining)
	stats_damage_taken += remaining
	player_hit_flash = 0.22
	player_invulnerable = 0.28
	camera_shake = maxf(camera_shake, 8.0)
	_last_damage_source = source
	_ui.notify("HIT // %s  -%d" % [source, roundi(remaining)], 1.45, Rules.CORAL)
	_play_sound(&"hurt")
	if player_health <= 0.0:
		_handle_player_defeat()


func _handle_player_defeat() -> void:
	mode = RunMode.GARAGE
	projectiles.clear()
	denied_zones.clear()
	_ui.notify("HULL DISABLED // Salvage tow returned the skiff", 3.0, Rules.CORAL)
	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": persistent_clear_count,
		"relay_module_unlocked": persistent_relay_module,
		"field_module_unlocked": persistent_field_module,
	})
	_set_mouse_for_mode()


func _apply_overdrive_ram(_delta: float) -> void:
	if overdrive_timer <= 0.0 and player_dash_timer <= 0.0:
		return
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]) or float(enemy["ram_cooldown"]) > 0.0:
			continue
		if player_position.distance_to(Vector2(enemy["pos"])) <= Rules.PLAYER_RADIUS + float(enemy["radius"]) + 5.0:
			enemy["ram_cooldown"] = 0.35
			var damage := 30.0 if overdrive_timer > 0.0 else 16.0
			_damage_enemy(enemy, damage, "Overdrive ram", 18.0)
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
		if not Rules.has_line_of_sight(player_position, enemy_position, 5.0, _boss_gate_closed()):
			continue
		if projection < best_projection:
			best_projection = projection
			best_id = String(enemy["id"])
	_aim_target_id = best_id


func _update_stage_progression() -> void:
	if not entered_approach and player_position.x > 700.0:
		entered_approach = true
		_ui.notify("FOUNDRY APPROACH // Cross or fight; the route remains open", 3.0, Rules.CYAN)
	if not entered_installations and player_position.x > 1950.0:
		entered_installations = true
		discovered_markers["generators"] = true
		_ui.notify("INSTALLATION FIELD // Two generators power the boss relay", 3.0, Rules.AMBER)

	if not chest_claimed and generators_destroyed >= 2 and player_position.distance_to(Rules.CHEST_POSITION) <= 78.0:
		_open_upgrade_cache()

	if generators_destroyed >= 2 and chest_claimed and not boss_started and Rules.BOSS_ARENA.grow(10.0).has_point(player_position):
		_start_stage_boss()

	if boss_started and boss_locked and not Rules.BOSS_ARENA.grow(-20.0).has_point(player_position):
		player_position = Rules.BOSS_ARENA.get_center()

	if player_position.distance_to(Rules.FIELD_BOSS_POSITION) < 560.0:
		discovered_markers["field_boss"] = true
	if player_position.distance_to(Rules.CHEST_POSITION) < 620.0:
		discovered_markers["chest"] = true
	if player_position.x > 3500.0:
		discovered_markers["stage_boss"] = true


func _open_upgrade_cache() -> void:
	if chest_claimed or mode != RunMode.PLAYING:
		return
	mode = RunMode.UPGRADE
	current_card_offer = Rules.get_card_offer(run_index)
	_ui.show_upgrade(current_card_offer)
	_play_sound(&"card", 0.9)
	_set_mouse_for_mode()


func apply_upgrade(upgrade_id: StringName) -> bool:
	if applied_upgrades.has(upgrade_id):
		return false
	var definition := Rules.get_upgrade(upgrade_id)
	if definition.is_empty():
		return false
	applied_upgrades[upgrade_id] = true
	chest_claimed = true
	selected_upgrade_title = String(definition["title"])
	if upgrade_id == &"field_converter" and player_barrier_strength > 0.0:
		player_barrier_strength += 10.0
	if upgrade_id == &"twin_seekers":
		player_passive_cooldown = 0.0
	return true


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
		"id": "foundry_colossus",
		"role": "stage_boss",
		"pos": Rules.STAGE_BOSS_POSITION,
		"zone": "boss",
	})
	boss["active"] = true
	boss["phase"] = "boss_read"
	boss["phase_time"] = 1.35
	boss["pattern"] = "SYSTEM WAKE"
	enemies.append(boss)
	projectiles.clear()
	denied_zones.clear()
	_ui.notify("BOSS ARENA SEALED // Read startup, active, recovery", 3.6, Rules.VIOLET)
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
		boss["pattern"] = "PHASE TWO // COMBINED PRESSURE"
		boss["pattern_index"] = 0
		boss_phase_two_announced = true
		_ui.notify("COLOSSUS PHASE TWO // Learned threats now overlap", 3.4, Rules.VIOLET)
		_play_sound(&"boss", 0.78)

	if String(boss["phase"]) == "staggered":
		boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
		if float(boss["phase_time"]) <= 0.0:
			boss["phase"] = "boss_read"
			boss["phase_time"] = 0.85
			boss["pattern"] = "RECOVERING CONTROL"
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
			boss["phase_time"] = 0.70 if int(boss["boss_phase"]) == 2 else 0.95
			boss["pattern"] = "READING THE ARENA"


func _boss_select_pattern(boss: Dictionary) -> void:
	var phase_two := int(boss["boss_phase"]) == 2
	var patterns: Array[String] = (
		["overload_combo", "pylons", "lane_barrage", "charge"]
		if phase_two
		else ["lane_barrage", "charge", "pylons", "lane_barrage", "charge"]
	)
	var index := int(boss["pattern_index"]) % patterns.size()
	var pattern := patterns[index]
	boss["pattern_index"] = int(boss["pattern_index"]) + 1
	boss["pattern"] = pattern
	boss["phase"] = "boss_startup"
	boss["hit_committed"] = false
	match pattern:
		"lane_barrage":
			boss["phase_time"] = 0.95
			var base_y := clampf(player_position.y, Rules.BOSS_ARENA.position.y + 180.0, Rules.BOSS_ARENA.end.y - 180.0)
			boss["lane_centers"] = [base_y - 170.0, base_y + 170.0]
		"charge":
			boss["phase_time"] = 0.86
			boss["committed_dir"] = (player_position - Vector2(boss["pos"])).normalized()
		"pylons":
			boss["phase_time"] = 1.05
		"overload_combo":
			boss["phase_time"] = 1.10
			boss["committed_dir"] = (player_position - Vector2(boss["pos"])).normalized()
			var base_y := clampf(player_position.y, Rules.BOSS_ARENA.position.y + 220.0, Rules.BOSS_ARENA.end.y - 220.0)
			boss["lane_centers"] = [base_y - 210.0, base_y + 210.0]


func _boss_begin_active(boss: Dictionary) -> void:
	boss["phase"] = "boss_active"
	boss["pattern_tick"] = 0.0
	var pattern := String(boss["pattern"])
	match pattern:
		"lane_barrage":
			boss["phase_time"] = 1.55
		"charge":
			boss["phase_time"] = 0.58
		"pylons":
			_spawn_boss_pylons()
			boss["phase"] = "boss_recovery"
			boss["phase_time"] = 1.15
		"overload_combo":
			boss["phase_time"] = 1.35
			denied_zones.append({
				"pos": player_position,
				"radius": 135.0,
				"warning": 0.68,
				"duration": 1.6,
				"tick": 0.0,
				"damage": 10.0,
				"source": "Colossus overload zone",
				"color": Rules.VIOLET,
			})


func _boss_update_active(boss: Dictionary, delta: float) -> void:
	boss["phase_time"] = maxf(0.0, float(boss["phase_time"]) - delta)
	boss["pattern_tick"] = float(boss["pattern_tick"]) - delta
	var pattern := String(boss["pattern"])
	match pattern:
		"lane_barrage":
			if float(boss["pattern_tick"]) <= 0.0:
				boss["pattern_tick"] = 0.24
				for lane_y_variant in boss["lane_centers"]:
					var lane_y := float(lane_y_variant)
					_spawn_hostile_projectile(
						Vector2(Rules.BOSS_ARENA.end.x - 70.0, lane_y),
						Vector2.LEFT,
						11.0,
						690.0,
						"Colossus lane barrage",
						Rules.VIOLET
					)
		"charge":
			var before := Vector2(boss["pos"])
			boss["pos"] = _move_actor(
				before,
				Vector2(boss["committed_dir"]) * 770.0 * delta,
				float(boss["radius"]),
				false
			)
			if not bool(boss["hit_committed"]) and player_position.distance_to(Vector2(boss["pos"])) <= Rules.PLAYER_RADIUS + float(boss["radius"]) + 10.0:
				boss["hit_committed"] = true
				_damage_player(24.0, "Colossus charge", true)
		"overload_combo":
			if float(boss["pattern_tick"]) <= 0.0:
				boss["pattern_tick"] = 0.30
				for lane_y_variant in boss["lane_centers"]:
					_spawn_hostile_projectile(
						Vector2(Rules.BOSS_ARENA.end.x - 70.0, float(lane_y_variant)),
						Vector2.LEFT,
						10.0,
						650.0,
						"Colossus overload lane",
						Rules.VIOLET
					)
			if float(boss["phase_time"]) < 0.72:
				boss["pos"] = _move_actor(
					Vector2(boss["pos"]),
					Vector2(boss["committed_dir"]) * 530.0 * delta,
					float(boss["radius"]),
					false
				)
				if not bool(boss["hit_committed"]) and player_position.distance_to(Vector2(boss["pos"])) <= Rules.PLAYER_RADIUS + float(boss["radius"]) + 8.0:
					boss["hit_committed"] = true
					_damage_player(20.0, "Colossus overload charge", true)

	if float(boss["phase_time"]) <= 0.0:
		boss["phase"] = "boss_recovery"
		boss["phase_time"] = 1.05 if pattern != "charge" else 1.30
		boss["vulnerable"] = 1.55 if pattern in ["charge", "overload_combo"] else 0.65
		boss["pattern"] = "RECOVERY // DAMAGE WINDOW"


func _boss_reposition(boss: Dictionary, delta: float) -> void:
	var center := Rules.BOSS_ARENA.get_center() + Vector2(220.0, 0.0)
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
	for position in [
		Vector2(4320.0, 760.0),
		Vector2(4320.0, 1440.0),
	]:
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
		})
		pylon["active"] = true
		enemies.append(pylon)
		_add_effect("spawn", position, Rules.VIOLET, 0.55, 78.0)
	_ui.notify("COLOSSUS PYLONS ONLINE // Destroy priority targets", 2.8, Rules.VIOLET)


func _boss_has_live_pylons() -> bool:
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) == &"boss_pylon":
			return true
	return false


func _update_field_boss(enemy: Dictionary, delta: float) -> void:
	if player_position.x < 2320.0 or player_position.y > 950.0:
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
		if String(enemy["pattern"]) == "charge":
			enemy["pos"] = _move_actor(
				Vector2(enemy["pos"]),
				Vector2(enemy["committed_dir"]) * 660.0 * delta,
				float(enemy["radius"]),
				false
			)
			if not bool(enemy["hit_committed"]) and player_position.distance_to(Vector2(enemy["pos"])) <= Rules.PLAYER_RADIUS + float(enemy["radius"]):
				enemy["hit_committed"] = true
				_damage_player(20.0, "Dredge Warden charge", true)
		if float(enemy["phase_time"]) <= 0.0:
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.85
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
		var patterns: Array[StringName] = [&"fan", &"charge", &"zone"]
		var pattern: StringName = patterns[int(enemy["pattern_index"]) % patterns.size()]
		enemy["pattern_index"] = int(enemy["pattern_index"]) + 1
		enemy["pattern"] = pattern
		enemy["phase"] = "startup"
		enemy["phase_time"] = 0.82 if pattern != "zone" else 1.0
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
	match pattern:
		"fan":
			for offset in [-0.28, -0.14, 0.0, 0.14, 0.28]:
				_spawn_hostile_projectile(
					Vector2(enemy["pos"]) + Vector2(enemy["committed_dir"]) * 50.0,
					Vector2(enemy["committed_dir"]).rotated(float(offset)),
					10.0,
					520.0,
					"Dredge Warden fan",
					Rules.VIOLET
				)
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 0.95
		"charge":
			enemy["phase"] = "active"
			enemy["phase_time"] = 0.50
		"zone":
			denied_zones.append({
				"pos": Vector2(enemy["committed_target"]),
				"radius": 150.0,
				"warning": 0.75,
				"duration": 2.0,
				"tick": 0.0,
				"damage": 11.0,
				"source": "Dredge Warden pressure field",
				"color": Rules.VIOLET,
			})
			enemy["phase"] = "recovery"
			enemy["phase_time"] = 1.0


func _complete_stage() -> void:
	if stage_complete:
		return
	stage_complete = true
	boss_locked = false
	persistent_clear_count += 1
	persistent_relay_module = true
	_save_persistence()
	projectiles.clear()
	denied_zones.clear()
	mode = RunMode.RESULT
	_ui.show_result({
		"time": _format_time(run_time),
		"health_ratio": player_health / PLAYER_MAX_HEALTH,
		"upgrade": selected_upgrade_title,
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
	var cell_width := Rules.WORLD_RECT.size.x / float(MINIMAP_COLS)
	var cell_height := Rules.WORLD_RECT.size.y / float(MINIMAP_ROWS)
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
	var buffs: Array[String] = []
	if attack_boost_timer > 0.0:
		buffs.append("ATTACK %.1fs" % attack_boost_timer)
	if overdrive_timer > 0.0:
		buffs.append("OVERDRIVE %.1fs" % overdrive_timer)
	if player_barrier_strength > 0.0:
		buffs.append("BARRIER %d" % roundi(player_barrier_strength))
	for upgrade_id in applied_upgrades.keys():
		var definition := Rules.get_upgrade(StringName(upgrade_id))
		if not definition.is_empty():
			buffs.append(String(definition["title"]).to_upper())

	var dash_state := "READY" if player_dash_cooldown <= 0.0 else "%.1fs" % player_dash_cooldown
	var passive_state := "READY" if player_passive_cooldown <= 0.0 else "%.1fs" % player_passive_cooldown
	var skill_state := "STARTUP" if player_emp_startup > 0.0 else ("READY" if player_emp_cooldown <= 0.0 else "%.1fs" % player_emp_cooldown)
	var primary_state := "FIRING" if player_primary_cooldown > 0.0 else "LIVE"
	var primary_name := "SCATTER" if selected_primary == &"scatter" else "REPEATER"

	var target_snapshot := {"visible": false}
	if not _aim_target_id.is_empty():
		var target := _find_enemy_by_id(_aim_target_id)
		if not target.is_empty() and bool(target["alive"]):
			target_snapshot = {
				"visible": true,
				"name": String(target["name"]).to_upper(),
				"health": float(target["health"]),
				"max_health": float(target["max_health"]),
				"state": _enemy_state_text(target),
			}

	var boss_snapshot := {"visible": false}
	var boss := _find_enemy_by_id("foundry_colossus")
	if not boss.is_empty() and bool(boss["alive"]):
		boss_snapshot = {
			"visible": true,
			"name": "FOUNDRY COLOSSUS // PHASE %d" % int(boss["boss_phase"]),
			"health": float(boss["health"]),
			"max_health": float(boss["max_health"]),
			"state": _boss_state_text(boss),
		}

	return {
		"health": player_health,
		"max_health": PLAYER_MAX_HEALTH,
		"objective": objective[0],
		"objective_detail": objective[1],
		"primary_name": primary_name,
		"primary_state": primary_state,
		"primary_ratio": 0.0,
		"dash_state": dash_state,
		"dash_ratio": clampf(player_dash_cooldown / DASH_COOLDOWN, 0.0, 1.0),
		"passive_state": passive_state,
		"passive_ratio": clampf(player_passive_cooldown / PASSIVE_COOLDOWN, 0.0, 1.0),
		"skill_state": skill_state,
		"skill_ratio": clampf(player_emp_cooldown / _emp_cooldown_max(), 0.0, 1.0),
		"buff_text": "  •  ".join(buffs),
		"target": target_snapshot,
		"boss": boss_snapshot,
		"minimap": _minimap_snapshot(),
	}


func _objective_text() -> Array[String]:
	if boss_started:
		return ["BREAK THE FOUNDRY COLOSSUS", "Read the tell. Remove pylons. Fire during recovery."]
	if generators_destroyed < 2 and entered_installations:
		return [
			"DISABLE THE BARRIER GRID  %d / 2" % generators_destroyed,
			"Upper route: Warden. Lower route: traps and field power.",
		]
	if generators_destroyed >= 2 and not chest_claimed:
		return ["CLAIM THE SALVAGE CACHE", "Combat suspends at the amber cache. Choose one live circuit."]
	if generators_destroyed >= 2 and chest_claimed:
		return ["ENTER THE COLOSSUS BASIN", "The relay gate is open. Living ordinary enemies do not block it."]
	if entered_approach:
		return ["CROSS THE FOUNDRY APPROACH", "The eastern route stays open; fighting is optional."]
	var checklist := "MOVE %s  AIM %s  FIRE %s  DASH %s" % [
		"✓" if tutorial_move else "—",
		"✓" if tutorial_aim else "—",
		"✓" if tutorial_fire else "—",
		"✓" if tutorial_dash else "—",
	]
	return ["CALIBRATE THE SALVAGE SKIFF", checklist]


func _enemy_state_text(enemy: Dictionary) -> String:
	var parts: Array[String] = []
	if bool(enemy["shielded"]):
		parts.append("GENERATOR SHIELD")
	if float(enemy["stun"]) > 0.0:
		parts.append("STUNNED")
	var phase := String(enemy["phase"])
	if phase == "startup":
		parts.append("ATTACK STARTUP")
	elif phase == "active":
		parts.append("ATTACK ACTIVE")
	elif phase == "recovery":
		parts.append("RECOVERING")
	elif StringName(enemy["role"]) == &"generator":
		parts.append("SHIELDS + REPAIRS")
	if parts.is_empty():
		parts.append("REPOSITIONING")
	return "  •  ".join(parts)


func _boss_state_text(boss: Dictionary) -> String:
	if _boss_has_live_pylons():
		return "%s  •  PYLON SHIELD ACTIVE" % String(boss["pattern"]).to_upper()
	if float(boss["vulnerable"]) > 0.0 or String(boss["phase"]) == "staggered":
		return "%s  •  DAMAGE WINDOW" % String(boss["pattern"]).to_upper()
	return String(boss["pattern"]).to_upper()


func _minimap_snapshot() -> Dictionary:
	var visited: Array[Vector2i] = []
	for cell in visited_cells.keys():
		visited.append(cell)
	var markers: Array[Dictionary] = [
		{
			"kind": "objective",
			"position": Rules.GENERATOR_A_POSITION,
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("generators", false)),
		},
		{
			"kind": "objective",
			"position": Rules.GENERATOR_B_POSITION,
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("generators", false)),
		},
		{
			"kind": "boss",
			"position": Rules.FIELD_BOSS_POSITION,
			"color": Rules.VIOLET,
			"discovered": bool(discovered_markers.get("field_boss", false)),
		},
		{
			"kind": "reward",
			"position": Rules.CHEST_POSITION,
			"color": Rules.AMBER,
			"discovered": bool(discovered_markers.get("chest", false)),
		},
		{
			"kind": "boss",
			"position": Rules.STAGE_BOSS_POSITION,
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
	return {
		"cols": MINIMAP_COLS,
		"rows": MINIMAP_ROWS,
		"visited": visited,
		"player": player_position,
		"world_size": Rules.WORLD_RECT.size,
		"markers": markers,
	}


func _is_world_position_visited(position: Vector2) -> bool:
	var cell_width := Rules.WORLD_RECT.size.x / float(MINIMAP_COLS)
	var cell_height := Rules.WORLD_RECT.size.y / float(MINIMAP_ROWS)
	var cell := Vector2i(floori(position.x / cell_width), floori(position.y / cell_height))
	return visited_cells.has(cell)


func _draw() -> void:
	_draw_world()
	_draw_water_and_floor()
	_draw_cover()
	_draw_landmarks()
	_draw_zones_and_trails()
	_draw_pickups_and_crates()
	_draw_enemies()
	_draw_projectiles()
	_draw_effects()
	_draw_player()
	_draw_aim_feedback()


func _draw_world() -> void:
	draw_rect(Rules.WORLD_RECT, Art.COBALT_VOID)
	for region in Rules.get_floor_regions():
		var edge_rect := Rect2(region["rect"])
		edge_rect.position += Art.COVER_EDGE_OFFSET
		draw_colored_polygon(Art.stepped_rect(edge_rect, 52.0), Art.COBALT_DEEP)
	for region in Rules.get_floor_regions():
		draw_colored_polygon(Art.stepped_rect(Rect2(region["rect"]), 52.0), Art.IVORY)
	_draw_major_motifs()


func _draw_major_motifs() -> void:
	for motif in Art.major_motifs():
		var kind := StringName(motif["kind"])
		var center := Vector2(motif["center"])
		var radius := float(motif["radius"])
		var rotation := float(motif["rotation"])
		var color := Color(motif["color"])
		match kind:
			&"tide_curl":
				_draw_tide_curl(center, radius, rotation, color)
			&"split_current":
				_draw_split_current(center, radius, rotation, color)
			&"relay_flower":
				_draw_relay_flower(center, radius, rotation, color)
			&"sun_gate":
				_draw_sun_gate(center, radius, rotation, color)


func _draw_tide_curl(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var sweep := PackedVector2Array()
	for index in 18:
		var progress := float(index) / 17.0
		var angle := rotation + progress * PI * 1.55
		var distance := lerpf(radius, radius * 0.16, progress)
		sweep.append(center + Vector2.RIGHT.rotated(angle) * distance)
	for index in range(sweep.size() - 1):
		draw_line(sweep[index], sweep[index + 1], color, lerpf(58.0, 26.0, float(index) / 17.0), true)
	draw_circle(center + Vector2.RIGHT.rotated(rotation + PI * 1.55) * radius * 0.16, radius * 0.13, color)


func _draw_split_current(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array([
			Vector2(-radius * 0.82, side * radius * 0.16),
			Vector2(-radius * 0.18, side * radius * 0.46),
			Vector2(radius * 0.72, side * radius * 0.24),
			Vector2(radius * 0.28, side * radius * 0.02),
			Vector2(-radius * 0.12, side * radius * 0.12),
		])
		for index in points.size():
			points[index] = center + points[index].rotated(rotation)
		draw_colored_polygon(points, color)
	draw_circle(center, radius * 0.18, Color(Art.IVORY, 0.86))


func _draw_relay_flower(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	for index in 4:
		var angle := rotation + TAU * float(index) / 4.0
		var petal_center := center + Vector2.RIGHT.rotated(angle) * radius * 0.42
		draw_colored_polygon(_regular_polygon(petal_center, radius * 0.42, 8, angle), color)
	draw_circle(center, radius * 0.24, Color(Art.IVORY, 0.82))


func _draw_sun_gate(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	draw_circle(center, radius * 0.68, color)
	draw_circle(center, radius * 0.43, Color(Art.IVORY, 0.95))
	for index in 8:
		var angle := rotation + TAU * float(index) / 8.0
		var direction := Vector2.RIGHT.rotated(angle)
		var tangent := direction.rotated(PI * 0.5)
		var root := center + direction * radius * 0.72
		draw_colored_polygon(PackedVector2Array([
			root - tangent * radius * 0.11,
			center + direction * radius,
			root + tangent * radius * 0.11,
		]), color)


func _draw_water_and_floor() -> void:
	for water in Rules.get_water_rects():
		var edge := water
		edge.position += Vector2(10.0, 14.0)
		draw_colored_polygon(Art.stepped_rect(edge, 30.0), Art.COBALT_DEEP)
		draw_colored_polygon(Art.stepped_rect(water, 30.0), Art.COBALT_WATER)
		var wave_y := water.get_center().y
		draw_line(
			Vector2(water.position.x + 28.0, wave_y),
			Vector2(water.end.x - 28.0, wave_y),
			Color(Art.IVORY_BRIGHT, 0.22),
			8.0,
			true
		)
	# Broad route inlays replace repeated rails and remain decorative only.
	draw_rect(Rect2(720.0, 1010.0, 1240.0, 42.0), Color(Art.IVORY_SHADE, 0.82))
	draw_rect(Rect2(720.0, 1150.0, 1240.0, 42.0), Color(Art.IVORY_SHADE, 0.82))
	draw_rect(Rect2(3320.0, 1038.0, 540.0, 44.0), Color(Art.MINT, 0.42))
	draw_rect(Rect2(3320.0, 1188.0, 540.0, 44.0), Color(Art.MINT, 0.42))


func _draw_cover() -> void:
	for rect in Rules.get_cover_rects(false):
		var edge := rect
		edge.position += Art.COVER_EDGE_OFFSET
		draw_colored_polygon(Art.stepped_rect(edge, 24.0), Art.COBALT_DEEP)
		draw_colored_polygon(Art.stepped_rect(rect, 24.0), Art.CERAMIC_GREEN)
		var cap := rect.grow(-12.0)
		if cap.size.x > 24.0 and cap.size.y > 24.0:
			draw_colored_polygon(Art.stepped_rect(cap, 16.0), Art.CERAMIC_GREEN_MID)
	if _boss_gate_closed():
		draw_colored_polygon(Art.stepped_rect(Rules.BOSS_GATE, 18.0), Art.CERAMIC_GREEN)
		var gate_center := Rules.BOSS_GATE.get_center()
		for offset in [-150.0, -50.0, 50.0, 150.0]:
			draw_rect(Rect2(gate_center + Vector2(-24.0, offset - 14.0), Vector2(48.0, 28.0)), Art.MUSTARD)


func _draw_landmarks() -> void:
	if not chest_claimed:
		var chest_rect := Rect2(Rules.CHEST_POSITION - Art.CACHE_HALF_SIZE, Art.CACHE_HALF_SIZE * 2.0)
		var edge := chest_rect
		edge.position += Vector2(10.0, 14.0)
		draw_colored_polygon(Art.stepped_rect(edge, 18.0), Art.MUSTARD_DARK)
		draw_colored_polygon(Art.stepped_rect(chest_rect, 18.0), Art.MUSTARD)
		draw_colored_polygon(_regular_polygon(Rules.CHEST_POSITION, 25.0, 4, PI / 4.0), Art.IVORY_BRIGHT)
		draw_colored_polygon(_regular_polygon(Rules.CHEST_POSITION, 12.0, 4, PI / 4.0), Art.CERAMIC_GREEN)
	if generators_destroyed >= 2 and chest_claimed and not boss_started:
		var exit_center := Vector2(3860.0, 1100.0)
		var pulse := 54.0 + sin(run_time * 3.0) * 7.0
		draw_circle(exit_center, pulse, Color(Art.MUSTARD, 0.28))
		draw_colored_polygon(_regular_polygon(exit_center, 24.0, 4, PI / 4.0), Art.MUSTARD)


func _draw_zones_and_trails() -> void:
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
	for pickup in pickups:
		if not bool(pickup["active"]):
			continue
		var position := Vector2(pickup["pos"])
		var kind := StringName(pickup["kind"])
		var color := _pickup_color(kind)
		var bob := sin(float(pickup["pulse"])) * 3.0
		position.y += bob
		var plinth_radius := Art.PICKUP_PLINTH_RADIUS
		draw_circle(position + Vector2(7.0, 9.0), plinth_radius, Art.COBALT_DEEP)
		draw_circle(position, plinth_radius, Art.IVORY_BRIGHT)
		draw_circle(position, plinth_radius - 8.0, Art.CERAMIC_GREEN_MID)
		match kind:
			&"repair":
				draw_rect(Rect2(position - Vector2(7.0, 22.0), Vector2(14.0, 44.0)), color)
				draw_rect(Rect2(position - Vector2(22.0, 7.0), Vector2(44.0, 14.0)), color)
			&"attack":
				draw_colored_polygon(PackedVector2Array([
					position + Vector2(0.0, -25.0),
					position + Vector2(24.0, 20.0),
					position + Vector2(-24.0, 20.0),
				]), color)
			&"overdrive":
				draw_colored_polygon(PackedVector2Array([
					position + Vector2(-24.0, -22.0),
					position + Vector2(2.0, 0.0),
					position + Vector2(-24.0, 22.0),
					position + Vector2(5.0, 22.0),
					position + Vector2(28.0, 0.0),
					position + Vector2(5.0, -22.0),
				]), color)
			&"barrier":
				draw_colored_polygon(_regular_polygon(position, 25.0, 6, PI / 6.0), color)
				draw_colored_polygon(_regular_polygon(position, 14.0, 6, PI / 6.0), Art.IVORY_BRIGHT)
				draw_circle(position, 7.0, color)
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
	for enemy in enemies:
		if not bool(enemy["alive"]) or not bool(enemy["active"]):
			continue
		_draw_enemy(enemy)


func _draw_enemy(enemy: Dictionary) -> void:
	var role := StringName(enemy["role"])
	var position := Vector2(enemy["pos"])
	var visual_radius := Art.enemy_visual_radius(role)
	var base_color := Art.IVORY_BRIGHT if float(enemy["flash"]) > 0.0 else _enemy_color(role)
	if bool(enemy["shielded"]):
		draw_circle(position, visual_radius + 14.0, Color(Art.MINT, 0.20))
		draw_arc(position, visual_radius + 14.0, 0.0, TAU, 32, Art.MINT, 8.0)
	match role:
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
		&"generator":
			_draw_generator(position, visual_radius, base_color)
		&"field_boss":
			_draw_field_boss(position, visual_radius, Vector2(enemy["committed_dir"]).angle(), base_color)
		&"boss_pylon":
			_draw_boss_pylon(position, visual_radius, base_color)
		&"stage_boss":
			_draw_stage_boss(position, visual_radius, (player_position - position).angle(), base_color)

	_draw_enemy_telegraph(enemy)
	if role != &"stage_boss":
		var health_ratio := clampf(float(enemy["health"]) / float(enemy["max_health"]), 0.0, 1.0)
		var bar_width := visual_radius * 1.6
		var bar_position := position + Vector2(-bar_width * 0.5, visual_radius + 14.0)
		draw_rect(Rect2(bar_position, Vector2(bar_width, 10.0)), Art.IVORY_SHADE)
		draw_rect(Rect2(bar_position, Vector2(bar_width * health_ratio, 10.0)), Art.CORAL)


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
	for index in 3:
		var angle := run_time * 0.22 + TAU * float(index) / 3.0
		var petal := position + Vector2.RIGHT.rotated(angle) * radius * 0.54
		draw_colored_polygon(_regular_polygon(petal, radius * 0.48, 4, angle), color)
	draw_circle(position + Vector2(6.0, 8.0), radius * 0.56, Art.CORAL_DARK)
	draw_circle(position, radius * 0.56, Art.IVORY_BRIGHT)
	draw_colored_polygon(_regular_polygon(position, radius * 0.30, 6, run_time * -0.25), Art.CORAL)


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
	draw_circle(position, radius * 0.36 + sin(run_time * 3.0) * 3.0, color)
	draw_colored_polygon(_regular_polygon(position, radius * 0.20, 4, PI / 4.0), Art.MUSTARD)


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
		&"chaser", &"shooter", &"controller", &"mine":
			return Art.CORAL
		&"turret":
			return Art.CORAL_DARK
		&"generator":
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
			&"chaser", &"field_boss":
				_draw_warning_beam(position, direction, 190.0, 34.0, Art.CORAL)
			&"shooter", &"turret":
				_draw_warning_beam(position, direction, 620.0, 20.0, Color(Art.CORAL, 0.72))
			&"controller":
				draw_circle(Vector2(enemy["committed_target"]), 112.0, Color(Art.CORAL, 0.14))
				draw_arc(Vector2(enemy["committed_target"]), 112.0, 0.0, TAU, 36, Art.CORAL, 10.0)
			&"mine":
				draw_circle(position, 190.0, Color(Art.CORAL, 0.12))
				draw_arc(position, 190.0, 0.0, TAU, 40, Art.CORAL, 10.0)
	if role == &"stage_boss" and phase == "boss_startup":
		var pattern := String(enemy["pattern"])
		if pattern == "charge" or pattern == "overload_combo":
			_draw_warning_beam(position, Vector2(enemy["committed_dir"]), 850.0, 64.0, Color(Art.CORAL, 0.72))
		if pattern == "lane_barrage" or pattern == "overload_combo":
			for lane_y_variant in enemy["lane_centers"]:
				var lane_y := float(lane_y_variant)
				draw_rect(Rect2(Rules.BOSS_ARENA.position.x, lane_y - 40.0, Rules.BOSS_ARENA.size.x, 80.0), Color(Art.CORAL, 0.22))
		if pattern == "pylons":
			for pylon_position in [Vector2(4320.0, 760.0), Vector2(4320.0, 1440.0)]:
				draw_circle(pylon_position, 68.0, Color(Art.BOSS_MAGENTA, 0.18))
				draw_arc(pylon_position, 68.0, 0.0, TAU, 32, Art.BOSS_MAGENTA, 9.0)


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
	for projectile in projectiles:
		var position := Vector2(projectile["pos"])
		var velocity := Vector2(projectile["velocity"])
		var color := Color(projectile["color"])
		var direction := velocity.normalized()
		var radius := maxf(7.0, float(projectile["radius"]) * 1.35)
		draw_line(position - direction * 40.0, position + direction * 7.0, Color(color, 0.50), radius * 1.5, true)
		draw_colored_polygon(_regular_polygon(position, radius, 4, direction.angle() + PI / 4.0), color)


func _draw_effects() -> void:
	for effect in effects:
		var kind := String(effect["kind"])
		var position := Vector2(effect["pos"])
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
			"scheduled_aftershock":
				draw_arc(position, radius, 0.0, TAU * progress, 32, Color(color, 0.35), 3.0)


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
		draw_circle(player_position, 61.0 + sin(run_time * 5.0) * 3.0, Color(Art.MINT, 0.14))
		draw_arc(player_position, 61.0 + sin(run_time * 5.0) * 3.0, 0.0, TAU, 36, Art.MINT, 8.0)
	if overdrive_timer > 0.0:
		draw_arc(player_position, 72.0, -PI * 0.7, PI * 0.7, 24, Art.MUSTARD, 10.0)


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


func _load_persistence() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	persistent_clear_count = maxi(0, int(config.get_value("progress", "clear_count", 0)))
	persistent_relay_module = bool(config.get_value("progress", "relay_module", false))
	persistent_field_module = bool(config.get_value("progress", "field_module", false))
	var primary_value := StringName(config.get_value("loadout", "primary", "repeater"))
	selected_primary = primary_value if primary_value in [&"repeater", &"scatter"] else &"repeater"


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
		push_warning("Vehicle Stage 1 persistence failed: %s" % error_string(result))


func _parse_capture_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-all="):
			_capture_directory = argument.trim_prefix("--capture-all=")
			_capture_mode = true
			call_deferred("_run_capture_sequence")
			return


func _run_capture_sequence() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_directory)
	_camera.position_smoothing_enabled = false
	await get_tree().process_frame
	await get_tree().process_frame
	_save_capture("01-deployment.png")

	mode = RunMode.PLAYING
	_ui.show_gameplay()
	player_position = Vector2(1250.0, 1080.0)
	player_aim_direction = Vector2(0.92, -0.38).normalized()
	_activate_capture_zone("approach")
	await _settle_capture()
	_save_capture("02-open-combat.png")

	player_position = Vector2(2460.0, 520.0)
	player_aim_direction = Vector2.RIGHT
	_activate_capture_zone("installations")
	entered_installations = true
	discovered_markers["generators"] = true
	await _settle_capture()
	_save_capture("03-installations-route.png")

	generators_destroyed = 2
	player_position = Rules.CHEST_POSITION - Vector2(140.0, 0.0)
	_open_upgrade_cache()
	await _settle_capture()
	_save_capture("04-upgrade-choice.png")

	apply_upgrade(&"ion_wake")
	mode = RunMode.PLAYING
	_ui.show_gameplay()
	player_position = Vector2(2720.0, 470.0)
	var field_boss := _find_enemy_by_id("dredge_warden")
	if not field_boss.is_empty():
		field_boss["active"] = true
		field_boss["phase"] = "startup"
		field_boss["pattern"] = "fan"
		field_boss["phase_time"] = 0.5
	player_aim_direction = (Rules.FIELD_BOSS_POSITION - player_position).normalized()
	await _settle_capture()
	_save_capture("05-optional-field-boss.png")

	chest_claimed = true
	player_position = Vector2(4190.0, 1110.0)
	_start_stage_boss()
	var boss := _find_enemy_by_id("foundry_colossus")
	if not boss.is_empty():
		boss["phase"] = "boss_startup"
		boss["pattern"] = "lane_barrage"
		boss["phase_time"] = 0.6
		boss["lane_centers"] = [850.0, 1300.0]
	player_aim_direction = (Rules.STAGE_BOSS_POSITION - player_position).normalized()
	await _settle_capture()
	_save_capture("06-stage-boss.png")

	mode = RunMode.RESULT
	_ui.show_result({
		"time": "6:42",
		"health_ratio": 0.68,
		"upgrade": "Ion Wake",
		"field_boss_defeated": true,
		"primary_hits": 214,
		"dash_uses": 17,
		"installations": 8,
	})
	await _settle_capture()
	_save_capture("07-result.png")

	_ui.show_garage({
		"selected_primary": selected_primary,
		"clear_count": 1,
		"relay_module_unlocked": true,
		"field_module_unlocked": true,
	})
	await _settle_capture()
	_save_capture("08-garage.png")
	print("VEHICLE_STAGE_CAPTURE_COMPLETE dir=%s" % _capture_directory)
	get_tree().quit(0)


func _activate_capture_zone(zone: String) -> void:
	for enemy in enemies:
		if String(enemy["zone"]) == zone:
			enemy["active"] = true


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
		"living_ordinary": debug_living_ordinary_count(),
	}


func debug_living_ordinary_count() -> int:
	var count := 0
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) in [&"chaser", &"shooter", &"controller", &"turret", &"mine"]:
			count += 1
	return count


func debug_apply_upgrade(upgrade_id: StringName) -> bool:
	return apply_upgrade(upgrade_id)


func debug_force_required_progression() -> Dictionary:
	for enemy in enemies:
		if bool(enemy["alive"]) and StringName(enemy["role"]) == &"generator":
			_damage_enemy(enemy, 9999.0, "validation", 0.0)
	if not chest_claimed:
		apply_upgrade(&"ion_wake")
	player_position = Rules.BOSS_ARENA.get_center()
	_update_stage_progression()
	return debug_snapshot()


func debug_defeat_stage_boss() -> Dictionary:
	var boss := _find_enemy_by_id("foundry_colossus")
	if boss.is_empty():
		_start_stage_boss()
		boss = _find_enemy_by_id("foundry_colossus")
	_damage_enemy(boss, 99999.0, "validation", 999.0)
	return debug_snapshot()


func debug_full_run() -> Dictionary:
	var primary := selected_primary
	_reset_run(false)
	selected_primary = primary
	mode = RunMode.PLAYING
	var living_before := debug_living_ordinary_count()
	var progress := debug_force_required_progression()
	var boss_started_with_living := bool(progress["boss_started"]) and debug_living_ordinary_count() > 0
	debug_defeat_stage_boss()
	return {
		"living_before": living_before,
		"boss_started_with_living": boss_started_with_living,
		"complete": stage_complete,
		"mode": mode,
		"upgrade_count": applied_upgrades.size(),
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
	player_position = Vector2(900.0, 700.0)
	var open_target := _make_enemy({
		"id": "debug_open_target",
		"role": "shooter",
		"pos": Vector2(900.0, 950.0),
		"zone": "debug",
	})
	open_target["active"] = true
	var blocked_target := _make_enemy({
		"id": "debug_blocked_target",
		"role": "shooter",
		"pos": Vector2(1250.0, 700.0),
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
	player_barrier_strength = 0.0
	player_barrier_timer = 0.0
	attack_boost_timer = 0.0
	overdrive_timer = 0.0
	var pickup := {"active": true, "kind": kind, "pos": player_position}
	_collect_pickup(pickup)
	return {
		"collected_once": not bool(pickup["active"]),
		"health": player_health,
		"barrier": player_barrier_strength,
		"attack_timer": attack_boost_timer,
		"overdrive_timer": overdrive_timer,
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
