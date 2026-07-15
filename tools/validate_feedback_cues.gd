extends SceneTree

const REQUIRED_CUES: Array[StringName] = [
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
]

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_cue_catalog()
	_validate_global_rng_is_untouched()
	_validate_vector_burst_contract()
	_finish()


func _validate_cue_catalog() -> void:
	var cue_ids := FeedbackCueSynthesizer.get_cue_ids()
	for cue_id in REQUIRED_CUES:
		_expect(cue_ids.has(cue_id), "required cue '%s' should exist" % cue_id)
	_expect(cue_ids.size() >= REQUIRED_CUES.size(), "cue family should include all required cues")

	var first := FeedbackCueSynthesizer.build_library()
	var repeated := FeedbackCueSynthesizer.build_library()
	var signatures: Dictionary = {}
	for cue_id in cue_ids:
		var stream := first.get(cue_id) as AudioStreamWAV
		var repeated_stream := repeated.get(cue_id) as AudioStreamWAV
		_expect(stream != null and repeated_stream != null, "%s should synthesize" % cue_id)
		if stream == null or repeated_stream == null:
			continue
		_expect(stream != repeated_stream, "%s generations should own separate resources" % cue_id)
		_expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s should use 16-bit PCM" % cue_id)
		_expect(stream.mix_rate == FeedbackCueSynthesizer.MIX_RATE, "%s mix rate should be stable" % cue_id)
		_expect(not stream.stereo, "%s should be mono" % cue_id)
		_expect(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s should not loop" % cue_id)
		_expect(stream.data.size() >= 3_000, "%s should contain an audible PCM body" % cue_id)
		_expect(stream.data == repeated_stream.data, "%s PCM should be byte-deterministic" % cue_id)
		_expect(_has_non_zero_sample(stream.data), "%s should not synthesize silence" % cue_id)
		signatures[_sha256(stream.data)] = true
	_expect(signatures.size() == cue_ids.size(), "each feedback cue should have distinct PCM data")


func _validate_global_rng_is_untouched() -> void:
	seed(94_217)
	var expected := randi()
	seed(94_217)
	FeedbackCueSynthesizer.build_library()
	var actual := randi()
	_expect(actual == expected, "cue synthesis must not consume or reseed global randomness")


func _validate_vector_burst_contract() -> void:
	var burst := FeedbackHitBurst.new()
	burst.configure(Vector2(120.0, 80.0), Color.ORANGE, 999.0, 999.0, 42)
	var snapshot := burst.get_snapshot()
	_expect(burst.process_mode == Node.PROCESS_MODE_ALWAYS, "hit burst should ignore tree pause")
	_expect(float(snapshot["duration"]) <= 0.15, "hit burst should stay very short")
	_expect(int(snapshot["ray_count"]) >= 8, "hit burst should expose a readable vector ray family")
	_expect(float(snapshot["radius"]) <= 48.0, "hit burst radius should be bounded")
	_expect(float(snapshot["strength"]) <= 2.0, "hit burst strength should be bounded")
	burst.free()


func _has_non_zero_sample(data: PackedByteArray) -> bool:
	for byte in data:
		if byte != 0:
			return true
	return false


func _sha256(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"FEEDBACK_CUE_VALIDATION_OK cues=%d mix_rate=%d"
			% [FeedbackCueSynthesizer.get_cue_ids().size(), FeedbackCueSynthesizer.MIX_RATE]
		)
		quit()
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
