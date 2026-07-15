extends Node

# Owns transient presentation only; gameplay systems remain authoritative for outcomes.
const REQUEST_TYPE := preload("res://scripts/presentation/GameplayFeedbackRequest.gd")
const CUE_SYNTHESIZER := preload("res://scripts/presentation/FeedbackCueSynthesizer.gd")
const HIT_BURST_TYPE := preload("res://scripts/presentation/FeedbackHitBurst.gd")

const AUDIO_VOICE_COUNT := 8
const MAX_STRENGTH := 2.0
const MAX_SHAKE_STRENGTH := 12.0
const MAX_SHAKE_DURATION := 0.35
const MAX_SINGLE_PAUSE_DURATION := 0.045
const MAX_COMBINED_PAUSE_DURATION := 0.075
const HIT_PAUSE_TIME_SCALE := 0.05
const MAX_BURST_RADIUS := 48.0

var _cue_library: Dictionary = {}
var _audio_voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _audio_play_count := 0

var _request_count := 0
var _rejected_count := 0
var _last_request: Dictionary = {}
var _last_result: Dictionary = {}

var _active_bursts: Array[Node] = []

var _shake_started_usec := 0
var _shake_deadline_usec := 0
var _shake_strength := 0.0
var _shake_seed := 0
var _shake_camera: Camera2D
var _camera_applied_offset := Vector2.ZERO

var _pause_started_usec := 0
var _pause_deadline_usec := 0
var _pause_active := false
var _pre_pause_time_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cue_library = CUE_SYNTHESIZER.build_library()
	_create_audio_pool()
	_connect_global_events()


func _process(_delta: float) -> void:
	var now_usec := Time.get_ticks_usec()
	if _pause_active and now_usec >= _pause_deadline_usec:
		_restore_time_scale()
	_update_shake(now_usec)
	_prune_bursts()


func _exit_tree() -> void:
	clear_feedback()


func request_feedback(value: Variant) -> Dictionary:
	var request: GameplayFeedbackRequest = REQUEST_TYPE.from_value(value)
	if request == null:
		return _reject_request("request must be a GameplayFeedbackRequest or Dictionary")
	var errors := request.validate()
	if not _cue_library.has(request.cue_id):
		errors.append("unknown cue_id '%s'" % request.cue_id)
	if not errors.is_empty():
		return _reject_request("; ".join(errors))

	_request_count += 1
	var resolved := _resolve_request(request)
	_last_request = resolved.duplicate(true)
	var settings := _get_settings()
	var audio_played := _play_cue(
		resolved["cue_id"],
		float(resolved["strength"]),
		settings
	)
	var shake_applied := false
	if bool(settings.get("screen_shake", true)):
		shake_applied = _request_shake(
			float(resolved["shake_strength"]),
			float(resolved["shake_duration"]),
			_request_count
		)
	var pause_applied := _request_hit_pause(float(resolved["pause_duration"]))
	var burst_spawned := false
	if bool(settings.get("damage_flash", true)):
		burst_spawned = _spawn_hit_burst(resolved)

	_last_result = {
		"accepted": true,
		"cue_id": resolved["cue_id"],
		"audio_played": audio_played,
		"shake_applied": shake_applied,
		"pause_applied": pause_applied,
		"burst_spawned": burst_spawned,
	}
	return _last_result.duplicate(true)


func get_feedback_snapshot() -> Dictionary:
	_prune_bursts()
	var now_usec := Time.get_ticks_usec()
	return {
		"request_count": _request_count,
		"rejected_count": _rejected_count,
		"last_request": _last_request.duplicate(true),
		"last_result": _last_result.duplicate(true),
		"cue_ids": CUE_SYNTHESIZER.get_cue_ids(),
		"audio": {
			"play_count": _audio_play_count,
			"active_voice_count": _active_voice_count(),
			"voice_cap": AUDIO_VOICE_COUNT,
		},
		"burst": {
			"active_count": _active_bursts.size(),
			"radius_cap": MAX_BURST_RADIUS,
		},
		"shake": {
			"active": _shake_deadline_usec > now_usec,
			"strength": _shake_strength,
			"remaining": _remaining_seconds(_shake_deadline_usec, now_usec),
			"strength_cap": MAX_SHAKE_STRENGTH,
			"duration_cap": MAX_SHAKE_DURATION,
		},
		"pause": {
			"active": _pause_active,
			"remaining": _remaining_seconds(_pause_deadline_usec, now_usec),
			"single_request_cap": MAX_SINGLE_PAUSE_DURATION,
			"combined_cap": MAX_COMBINED_PAUSE_DURATION,
		},
	}


func clear_feedback() -> void:
	_restore_time_scale()
	_finish_shake()
	for voice in _audio_voices:
		voice.stop()
		voice.stream = null
	for burst in _active_bursts:
		if is_instance_valid(burst):
			burst.queue_free()
	_active_bursts.clear()


func _connect_global_events() -> void:
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.gameplay_feedback_requested.connect(_on_feedback_requested)
		bus.reward_applied.connect(_on_reward_applied)
		bus.field_pickup_collected.connect(_on_field_pickup_collected)
		bus.stage_cleared.connect(_on_stage_cleared)
		bus.boss_defeated.connect(_on_boss_defeated)
	var profile := get_node_or_null("/root/ProfileState")
	if profile != null and profile.has_signal("setting_changed"):
		profile.connect("setting_changed", Callable(self, "_on_setting_changed"))
	var run_director := get_node_or_null("/root/RunDirector")
	if run_director != null and run_director.has_signal("phase_changed"):
		run_director.connect("phase_changed", Callable(self, "_on_phase_changed"))


func _on_feedback_requested(request: Variant) -> void:
	var result := request_feedback(request)
	if not bool(result.get("accepted", false)):
		push_warning("Gameplay feedback request rejected: %s" % result.get("message", "unknown error"))


func _on_reward_applied(result: Dictionary) -> void:
	if not bool(result.get("applied", result.get("ok", false))):
		return
	var transaction_id := String(result.get("transaction_id", ""))
	if transaction_id.begins_with("field:"):
		return
	request_feedback({
		"cue_id": &"reward",
		"context": {
			"source": "reward_applied",
			"transaction_id": transaction_id,
		},
	})


func _on_field_pickup_collected(result: Dictionary) -> void:
	if not bool(result.get("applied", false)):
		return
	request_feedback({
		"cue_id": &"reward",
		"context": {
			"source": "field_pickup",
			"pickup_id": String(result.get("pickup_id", "")),
		},
	})


func _on_stage_cleared(stage_id: String) -> void:
	request_feedback({
		"cue_id": &"stage_clear",
		"context": {"source": "stage_cleared", "stage_id": stage_id},
	})


func _on_boss_defeated(reward_table_id: StringName) -> void:
	request_feedback({
		"cue_id": &"boss_defeat",
		"context": {
			"source": "boss_defeated",
			"reward_table_id": String(reward_table_id),
		},
	})


func _on_phase_changed(_phase_name: String) -> void:
	_clear_phase_transients()


func _on_setting_changed(setting_id: StringName, value: Variant) -> void:
	if setting_id == &"screen_shake" and value is bool and not value:
		_finish_shake()
	elif setting_id == &"damage_flash" and value is bool and not value:
		for burst in _active_bursts:
			if is_instance_valid(burst):
				burst.queue_free()
		_active_bursts.clear()
	elif setting_id in [&"master_volume", &"sfx_volume"]:
		_refresh_active_voice_volumes()


func _resolve_request(request: GameplayFeedbackRequest) -> Dictionary:
	var defaults := _cue_defaults(request.cue_id)
	var strength := clampf(request.strength, 0.0, MAX_STRENGTH)
	var burst_enabled := bool(defaults["burst"])
	if request.burst_mode != GameplayFeedbackRequest.BURST_DEFAULT:
		burst_enabled = request.burst_mode == GameplayFeedbackRequest.BURST_ENABLED
	var burst_color: Color = defaults["burst_color"]
	if request.burst_color.a > 0.0:
		burst_color = request.burst_color
	var shake_strength := _optional_value(
		request.shake_strength, defaults["shake_strength"]
	) * strength
	var pause_duration := _optional_value(
		request.pause_duration, defaults["pause_duration"]
	) * minf(strength, 1.0)
	var burst_radius := _optional_value(
		request.burst_radius, defaults["burst_radius"]
	) * minf(strength, 1.5)
	return {
		"cue_id": request.cue_id,
		"strength": strength,
		"has_world_position": request.has_world_position,
		"world_position": request.world_position,
		"shake_strength": clampf(
			shake_strength,
			0.0,
			MAX_SHAKE_STRENGTH
		),
		"shake_duration": clampf(
			_optional_value(request.shake_duration, defaults["shake_duration"]),
			0.0,
			MAX_SHAKE_DURATION
		),
		"pause_duration": clampf(
			pause_duration,
			0.0,
			MAX_SINGLE_PAUSE_DURATION
		),
		"burst": burst_enabled,
		"burst_radius": clampf(
			burst_radius,
			4.0,
			MAX_BURST_RADIUS
		),
		"burst_color": burst_color,
		"context": request.context.duplicate(true),
	}


func _cue_defaults(cue_id: StringName) -> Dictionary:
	var defaults := {
		"shake_strength": 0.0,
		"shake_duration": 0.0,
		"pause_duration": 0.0,
		"burst": false,
		"burst_radius": 16.0,
		"burst_color": Color(0.86, 0.93, 1.0),
	}
	match cue_id:
		&"jump":
			defaults["shake_strength"] = 0.5
			defaults["shake_duration"] = 0.08
		&"dash":
			defaults["shake_strength"] = 1.25
			defaults["shake_duration"] = 0.10
		&"enemy_hit":
			defaults.merge({
				"shake_strength": 2.5,
				"shake_duration": 0.12,
				"pause_duration": 0.018,
				"burst": true,
				"burst_radius": 16.0,
				"burst_color": Color(1.0, 0.86, 0.42),
			}, true)
		&"critical_hit":
			defaults.merge({
				"shake_strength": 6.0,
				"shake_duration": 0.18,
				"pause_duration": 0.035,
				"burst": true,
				"burst_radius": 27.0,
				"burst_color": Color(1.0, 0.68, 0.20),
			}, true)
		&"player_hurt":
			defaults.merge({
				"shake_strength": 7.0,
				"shake_duration": 0.20,
				"pause_duration": 0.030,
				"burst": true,
				"burst_radius": 24.0,
				"burst_color": Color(1.0, 0.32, 0.28),
			}, true)
		&"guard_block":
			defaults.merge({
				"shake_strength": 1.5,
				"shake_duration": 0.08,
				"pause_duration": 0.010,
				"burst": true,
				"burst_radius": 14.0,
				"burst_color": Color(0.31, 0.83, 0.91),
			}, true)
		&"precise_guard":
			defaults.merge({
				"shake_strength": 2.5,
				"shake_duration": 0.10,
				"pause_duration": 0.020,
				"burst": true,
				"burst_radius": 19.0,
				"burst_color": Color(1.0, 0.84, 0.34),
			}, true)
		&"guard_break":
			defaults.merge({
				"shake_strength": 6.0,
				"shake_duration": 0.18,
				"pause_duration": 0.030,
				"burst": true,
				"burst_radius": 26.0,
				"burst_color": Color(1.0, 0.35, 0.27),
			}, true)
		&"enemy_defeat":
			defaults.merge({
				"shake_strength": 4.0,
				"shake_duration": 0.16,
				"pause_duration": 0.022,
				"burst": true,
				"burst_radius": 22.0,
				"burst_color": Color(0.47, 0.91, 0.78),
			}, true)
		&"boss_warning":
			defaults["shake_strength"] = 2.0
			defaults["shake_duration"] = 0.20
		&"boss_defeat":
			defaults.merge({
				"shake_strength": 12.0,
				"shake_duration": 0.35,
				"pause_duration": 0.045,
				"burst": true,
				"burst_radius": 40.0,
				"burst_color": Color(0.67, 0.94, 0.44),
			}, true)
		&"stage_clear":
			defaults["shake_strength"] = 2.0
			defaults["shake_duration"] = 0.18
	return defaults


func _create_audio_pool() -> void:
	for voice_index in AUDIO_VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.name = "FeedbackVoice%d" % (voice_index + 1)
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		_audio_voices.append(voice)


func _play_cue(
	cue_id: StringName,
	request_strength: float,
	settings: Dictionary
) -> bool:
	var stream := _cue_library.get(cue_id) as AudioStreamWAV
	var linear_volume := _audio_volume(settings, request_strength)
	if stream == null or linear_volume <= 0.0001:
		return false
	# Headless runs validate dispatch but have no listener or useful playback backend.
	if DisplayServer.get_name() == "headless":
		_audio_play_count += 1
		return true
	var voice := _next_audio_voice()
	if voice == null:
		return false
	voice.stop()
	voice.stream = stream
	voice.set_meta("feedback_request_strength", request_strength)
	voice.volume_db = linear_to_db(linear_volume)
	voice.play()
	_audio_play_count += 1
	return true


func _next_audio_voice() -> AudioStreamPlayer:
	for offset in _audio_voices.size():
		var index := (_voice_cursor + offset) % _audio_voices.size()
		if not _audio_voices[index].playing:
			_voice_cursor = (index + 1) % _audio_voices.size()
			return _audio_voices[index]
	if _audio_voices.is_empty():
		return null
	var voice := _audio_voices[_voice_cursor]
	_voice_cursor = (_voice_cursor + 1) % _audio_voices.size()
	return voice


func _refresh_active_voice_volumes() -> void:
	var settings := _get_settings()
	for voice in _audio_voices:
		if not voice.playing:
			continue
		var request_strength := float(voice.get_meta("feedback_request_strength", 1.0))
		var adjusted := _audio_volume(settings, request_strength)
		if adjusted <= 0.0001:
			voice.stop()
		else:
			voice.volume_db = linear_to_db(adjusted)


func _request_shake(strength: float, duration: float, request_seed: int) -> bool:
	if strength <= 0.0 or duration <= 0.0:
		return false
	var now_usec := Time.get_ticks_usec()
	if now_usec >= _shake_deadline_usec:
		_finish_shake()
		_shake_started_usec = now_usec
		_shake_deadline_usec = now_usec + int(duration * 1_000_000.0)
		_shake_strength = strength
	else:
		_shake_strength = minf(_shake_strength + strength, MAX_SHAKE_STRENGTH)
		var requested_deadline := now_usec + int(duration * 1_000_000.0)
		var capped_deadline := _shake_started_usec + int(MAX_SHAKE_DURATION * 1_000_000.0)
		_shake_deadline_usec = mini(maxi(_shake_deadline_usec, requested_deadline), capped_deadline)
	_shake_seed = ((_shake_seed * 1_103_515_245) + request_seed * 7_919) & 0x7fffffff
	return true


func _update_shake(now_usec: int) -> void:
	if _shake_deadline_usec <= now_usec:
		_finish_shake()
		return
	var active_camera := get_viewport().get_camera_2d()
	if active_camera != _shake_camera:
		_restore_camera_offset()
		_shake_camera = active_camera
	if _shake_camera == null or not is_instance_valid(_shake_camera):
		return

	var base_offset := _shake_camera.offset - _camera_applied_offset
	var elapsed := float(now_usec - _shake_started_usec) / 1_000_000.0
	var remaining := _remaining_seconds(_shake_deadline_usec, now_usec)
	var full_duration := maxf(
		float(_shake_deadline_usec - _shake_started_usec) / 1_000_000.0,
		0.001
	)
	var falloff := pow(clampf(remaining / full_duration, 0.0, 1.0), 1.25)
	var seed_phase := float(_shake_seed % 10_000) * 0.001
	_camera_applied_offset = Vector2(
		sin(elapsed * 91.0 + seed_phase),
		sin(elapsed * 113.0 + seed_phase * 1.73)
	) * (_shake_strength * falloff)
	_shake_camera.offset = base_offset + _camera_applied_offset


func _finish_shake() -> void:
	_restore_camera_offset()
	_shake_started_usec = 0
	_shake_deadline_usec = 0
	_shake_strength = 0.0


func _restore_camera_offset() -> void:
	# Remove only our delta so another camera system's concurrent offset survives cleanup.
	if _shake_camera != null and is_instance_valid(_shake_camera):
		_shake_camera.offset -= _camera_applied_offset
	_shake_camera = null
	_camera_applied_offset = Vector2.ZERO


func _request_hit_pause(duration: float) -> bool:
	if duration <= 0.0:
		return false
	var now_usec := Time.get_ticks_usec()
	if not _pause_active or now_usec >= _pause_deadline_usec:
		if _pause_active:
			_restore_time_scale()
		_pause_active = true
		_pause_started_usec = now_usec
		_pre_pause_time_scale = Engine.time_scale
		_pause_deadline_usec = now_usec + int(duration * 1_000_000.0)
	else:
		var requested_deadline := now_usec + int(duration * 1_000_000.0)
		var capped_deadline := (
			_pause_started_usec + int(MAX_COMBINED_PAUSE_DURATION * 1_000_000.0)
		)
		_pause_deadline_usec = mini(maxi(_pause_deadline_usec, requested_deadline), capped_deadline)
	# The deadline uses monotonic real time; process delta is intentionally ignored.
	Engine.time_scale = minf(_pre_pause_time_scale, HIT_PAUSE_TIME_SCALE)
	return true


func _restore_time_scale() -> void:
	if _pause_active:
		Engine.time_scale = _pre_pause_time_scale
	_pause_active = false
	_pause_started_usec = 0
	_pause_deadline_usec = 0


func _clear_phase_transients() -> void:
	_restore_time_scale()
	_finish_shake()
	for burst in _active_bursts:
		if is_instance_valid(burst):
			burst.queue_free()
	_active_bursts.clear()


func _spawn_hit_burst(request: Dictionary) -> bool:
	if (
		not bool(request["burst"])
		or not bool(request["has_world_position"])
		or float(request["strength"]) <= 0.0
	):
		return false
	var burst := HIT_BURST_TYPE.new() as FeedbackHitBurst
	add_child(burst)
	burst.configure(
		request["world_position"],
		request["burst_color"],
		float(request["burst_radius"]),
		float(request["strength"]),
		_stable_text_seed(String(request["cue_id"])) + _request_count * 97
	)
	_active_bursts.append(burst)
	return true


func _prune_bursts() -> void:
	var active: Array[Node] = []
	for burst in _active_bursts:
		if is_instance_valid(burst) and not burst.is_queued_for_deletion():
			active.append(burst)
	_active_bursts = active


func _get_settings() -> Dictionary:
	var settings := {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"screen_shake": true,
		"damage_flash": true,
	}
	var profile := get_node_or_null("/root/ProfileState")
	if profile != null and profile.has_method("get_settings"):
		var profile_settings: Variant = profile.call("get_settings")
		if profile_settings is Dictionary:
			for setting_id in settings:
				if profile_settings.has(setting_id):
					settings[setting_id] = profile_settings[setting_id]
	return settings


func _audio_volume(settings: Dictionary, request_strength: float) -> float:
	var master := clampf(float(settings.get("master_volume", 1.0)), 0.0, 1.0)
	var sfx := clampf(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	return clampf(master * sfx * minf(request_strength, 1.25), 0.0, 1.0)


func _active_voice_count() -> int:
	var count := 0
	for voice in _audio_voices:
		if voice.playing:
			count += 1
	return count


func _reject_request(message: String) -> Dictionary:
	_rejected_count += 1
	return {"accepted": false, "message": message}


func _optional_value(value: float, fallback: Variant) -> float:
	return float(fallback) if value == GameplayFeedbackRequest.UNSET_FLOAT else value


func _remaining_seconds(deadline_usec: int, now_usec: int) -> float:
	return maxf(float(deadline_usec - now_usec) / 1_000_000.0, 0.0)


func _stable_text_seed(value: String) -> int:
	var seed := 17
	for byte in value.to_utf8_buffer():
		seed = (seed * 31 + int(byte)) & 0x7fffffff
	return seed
