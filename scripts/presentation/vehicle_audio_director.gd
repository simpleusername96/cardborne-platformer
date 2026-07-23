class_name VehicleAudioDirector
extends Node

## Routes stored project-owned SFX and owns the held-fire loop/impact limiter.

const ROOT := "res://art/audio/vehicle/sfx/"
const FILES := {
	&"primary_start": "primary_start.wav", &"primary_loop": "primary_loop.wav",
	&"primary_end": "primary_end.wav", &"opening_ready": "opening_ready.wav",
	&"opening_fire": "opening_fire.wav", &"impact_enemy": "impact_enemy.wav",
	&"impact_cover": "impact_cover.wav", &"enemy_destroy_small": "enemy_destroy_small.wav",
	&"enemy_destroy_priority": "enemy_destroy_priority.wav", &"pickup": "pickup.wav",
	&"upgrade_select": "upgrade_select.wav", &"upgrade_confirm": "upgrade_confirm.wav",
	&"boss_warning": "boss_warning.wav", &"player_hull_hit": "player_hull_hit.wav",
}

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _impact_voices: Array[AudioStreamPlayer] = []
var _voice_cursor := 0
var _impact_cursor := 0
var _primary_active := false
var _primary_loop: AudioStreamPlayer
var _playback_available := true


func _ready() -> void:
	for sound_id in FILES:
		_streams[sound_id] = load(ROOT + String(FILES[sound_id]))
	_playback_available = AudioServer.get_driver_name() != "Dummy"
	if not _playback_available:
		return
	for index in 6:
		_voices.append(_make_player("SFXVoice%d" % index))
	for index in 2:
		_impact_voices.append(_make_player("ImpactVoice%d" % index))
	_primary_loop = _make_player("PrimaryLoop")
	_primary_loop.finished.connect(_continue_primary_loop)


func _make_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	add_child(player)
	return player


func update_primary(active: bool) -> void:
	if not _playback_available:
		_primary_active = active
		return
	if active == _primary_active:
		return
	_primary_active = active
	if active:
		play(&"primary_start")
		_primary_loop.stream = _streams[&"primary_loop"]
		_primary_loop.play()
	else:
		_primary_loop.stop()
		play(&"primary_end")


func _continue_primary_loop() -> void:
	if _primary_active:
		_primary_loop.play()


func play(sound_id: StringName, pitch: float = 1.0) -> void:
	if not _playback_available:
		return
	var resolved := _resolve(sound_id)
	if not _streams.has(resolved):
		return
	var pool := _impact_voices if resolved in [&"impact_enemy", &"impact_cover"] else _voices
	var cursor := _impact_cursor if pool == _impact_voices else _voice_cursor
	var player := pool[cursor % pool.size()]
	if pool == _impact_voices:
		_impact_cursor += 1
	else:
		_voice_cursor += 1
	player.stream = _streams[resolved]
	player.pitch_scale = pitch
	player.play()


func stop_all() -> void:
	_primary_active = false
	if is_instance_valid(_primary_loop):
		_primary_loop.stop()
	for player in _voices + _impact_voices:
		player.stop()


## Releases playback and stream references before the owning tree exits.
func shutdown() -> void:
	stop_all()
	if is_instance_valid(_primary_loop):
		_primary_loop.stream = null
	for player in _voices + _impact_voices:
		player.stream = null
	_streams.clear()


func has_all_required() -> bool:
	return _streams.size() == FILES.size() and _streams.values().all(func(stream: Variant) -> bool: return stream != null)


func _resolve(sound_id: StringName) -> StringName:
	match sound_id:
		&"primary": return &"primary_loop"
		&"impact": return &"impact_enemy"
		&"cover": return &"impact_cover"
		&"destroy": return &"enemy_destroy_small"
		&"destroy_priority": return &"enemy_destroy_priority"
		&"card": return &"upgrade_confirm"
		&"boss": return &"boss_warning"
		&"missile", &"dash", &"emp_start": return &"upgrade_select"
		&"emp": return &"impact_cover"
		&"hurt": return &"player_hull_hit"
	return sound_id
