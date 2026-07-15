class_name FeedbackCueSynthesizer
extends RefCounted

# Generates the complete PCM cue family without reading or mutating global RNG state.
const MIX_RATE := 22_050
const CUE_IDS: Array[StringName] = [
	&"jump",
	&"dash",
	&"enemy_hit",
	&"critical_hit",
	&"player_hurt",
	&"guard_start",
	&"guard_block",
	&"precise_guard",
	&"guard_break",
	&"guard_recover",
	&"enemy_defeat",
	&"boss_warning",
	&"boss_defeat",
	&"reward",
	&"stage_clear",
]


static func build_library() -> Dictionary:
	var library: Dictionary = {}
	for cue_id in CUE_IDS:
		library[cue_id] = build_cue(cue_id)
	return library


static func build_cue(cue_id: StringName) -> AudioStreamWAV:
	var spec := _cue_spec(cue_id)
	if spec.is_empty():
		return null
	var duration := float(spec["duration"])
	var sample_count := maxi(int(ceil(duration * MIX_RATE)), 1)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var seed := _stable_seed(cue_id)
	for sample_index in sample_count:
		var time_seconds := float(sample_index) / float(MIX_RATE)
		var sample := _sample(cue_id, spec, time_seconds, duration, sample_index, seed)
		_write_16_bit_sample(pcm, sample_index, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm
	return stream


static func get_cue_ids() -> Array[StringName]:
	return CUE_IDS.duplicate()


static func _cue_spec(cue_id: StringName) -> Dictionary:
	match cue_id:
		&"jump":
			return _spec(0.14, 250.0, 610.0, 0.18, 0.015, 0.68)
		&"dash":
			return _spec(0.11, 430.0, 115.0, 0.08, 0.16, 0.72)
		&"enemy_hit":
			return _spec(0.09, 205.0, 92.0, 0.22, 0.22, 0.76)
		&"critical_hit":
			return _spec(0.16, 390.0, 118.0, 0.32, 0.27, 0.86)
		&"player_hurt":
			return _spec(0.18, 180.0, 72.0, 0.26, 0.32, 0.82)
		&"guard_start":
			return _spec(0.10, 230.0, 360.0, 0.12, 0.01, 0.54)
		&"guard_block":
			return _spec(0.12, 290.0, 145.0, 0.34, 0.16, 0.70)
		&"precise_guard":
			return _spec(0.18, 520.0, 780.0, 0.18, 0.01, 0.72)
		&"guard_break":
			return _spec(0.24, 210.0, 48.0, 0.38, 0.38, 0.88)
		&"guard_recover":
			return _spec(0.09, 260.0, 190.0, 0.08, 0.01, 0.42)
		&"enemy_defeat":
			return _spec(0.22, 310.0, 82.0, 0.20, 0.20, 0.78)
		&"boss_warning":
			return _spec(0.34, 98.0, 82.0, 0.38, 0.08, 0.80)
		&"boss_defeat":
			return _spec(0.48, 196.0, 49.0, 0.30, 0.24, 0.90)
		&"reward":
			return _spec(0.32, 440.0, 660.0, 0.16, 0.01, 0.66)
		&"stage_clear":
			return _spec(0.44, 330.0, 660.0, 0.20, 0.015, 0.72)
		_:
			return {}


static func _spec(
	duration: float,
	start_frequency: float,
	end_frequency: float,
	harmonic_mix: float,
	noise_mix: float,
	gain: float
) -> Dictionary:
	return {
		"duration": duration,
		"start_frequency": start_frequency,
		"end_frequency": end_frequency,
		"harmonic_mix": harmonic_mix,
		"noise_mix": noise_mix,
		"gain": gain,
	}


static func _sample(
	cue_id: StringName,
	spec: Dictionary,
	time_seconds: float,
	duration: float,
	sample_index: int,
	seed: int
) -> float:
	var progress := clampf(time_seconds / duration, 0.0, 1.0)
	var start_frequency := float(spec["start_frequency"])
	var end_frequency := float(spec["end_frequency"])
	var cycles := (
		start_frequency * time_seconds
		+ 0.5 * (end_frequency - start_frequency) * time_seconds * progress
	)
	var phase := TAU * cycles
	var harmonic_mix := float(spec["harmonic_mix"])
	var tone := sin(phase) + harmonic_mix * sin(phase * 2.0 + 0.35)
	var texture := _deterministic_noise(sample_index, seed) * float(spec["noise_mix"])
	var envelope := _shared_envelope(time_seconds, duration, progress)

	match cue_id:
		&"dash":
			tone *= 0.72 + 0.28 * sin(TAU * 31.0 * time_seconds)
		&"critical_hit":
			tone += 0.28 * sin(TAU * 790.0 * time_seconds) * pow(1.0 - progress, 2.0)
		&"player_hurt":
			tone *= 0.78 + 0.22 * sin(TAU * 18.0 * time_seconds)
		&"guard_block":
			tone += 0.26 * sin(TAU * 860.0 * time_seconds) * pow(1.0 - progress, 2.0)
		&"precise_guard":
			tone = _note_sequence_sample(
				time_seconds, duration, PackedFloat32Array([523.25, 783.99])
			)
			texture = 0.0
			envelope = 1.0
		&"guard_break":
			tone *= 0.7 + 0.3 * sin(TAU * 23.0 * time_seconds)
			texture *= 1.0 - progress * 0.35
		&"enemy_defeat":
			tone += 0.22 * sin(phase * 0.5) * (1.0 - progress)
		&"boss_warning":
			var pulse := 0.45 + 0.55 * maxf(sin(TAU * 5.0 * time_seconds), 0.0)
			tone *= pulse
			envelope = minf(time_seconds / 0.02, 1.0) * minf(
				(duration - time_seconds) / 0.04, 1.0
			)
		&"boss_defeat":
			tone += 0.35 * sin(phase * 0.5) * (1.0 - progress)
			texture *= 1.0 - progress
		&"reward":
			tone = _note_sequence_sample(
				time_seconds, duration, PackedFloat32Array([440.0, 554.37, 659.25])
			)
			texture = 0.0
			envelope = 1.0
		&"stage_clear":
			tone = _note_sequence_sample(
				time_seconds, duration, PackedFloat32Array([329.63, 440.0, 554.37, 659.25])
			)
			texture = 0.0
			envelope = 1.0

	return clampf((tone + texture) * envelope * float(spec["gain"]), -1.0, 1.0)


static func _note_sequence_sample(
	time_seconds: float,
	duration: float,
	frequencies: PackedFloat32Array
) -> float:
	var note_duration := duration / float(frequencies.size())
	var note_index := mini(int(time_seconds / note_duration), frequencies.size() - 1)
	var local_time := time_seconds - float(note_index) * note_duration
	var local_progress := clampf(local_time / note_duration, 0.0, 1.0)
	var note_envelope := minf(local_time / 0.008, 1.0) * pow(1.0 - local_progress, 0.55)
	var phase := TAU * float(frequencies[note_index]) * local_time
	return (sin(phase) + 0.18 * sin(phase * 2.0)) * note_envelope


static func _shared_envelope(
	time_seconds: float,
	duration: float,
	progress: float
) -> float:
	var attack := minf(time_seconds / 0.006, 1.0)
	var release := minf((duration - time_seconds) / 0.025, 1.0)
	return attack * maxf(release, 0.0) * pow(1.0 - progress, 0.72)


static func _deterministic_noise(sample_index: int, seed: int) -> float:
	var value := (sample_index * 1_103_515_245 + seed * 12_345) & 0x7fffffff
	value = (value ^ (value >> 11) ^ (value << 7)) & 0x7fffffff
	return float(value % 65_536) / 32_767.5 - 1.0


static func _stable_seed(cue_id: StringName) -> int:
	var seed := 2_166_136_261
	for byte in String(cue_id).to_utf8_buffer():
		seed = ((seed ^ int(byte)) * 16_777_619) & 0x7fffffff
	return seed


static func _write_16_bit_sample(
	data: PackedByteArray,
	sample_index: int,
	sample: float
) -> void:
	var encoded := int(round(clampf(sample, -1.0, 1.0) * 32_767.0))
	if encoded < 0:
		encoded += 65_536
	data[sample_index * 2] = encoded & 0xff
	data[sample_index * 2 + 1] = (encoded >> 8) & 0xff
