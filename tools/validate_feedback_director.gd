extends SceneTree

const DIRECTOR_SCRIPT := preload("res://scripts/presentation/FeedbackDirector.gd")
const CAMERA_BASE_OFFSET := Vector2(3.0, -2.0)

var _failures: Array[String] = []
var _director: Node
var _bus: Node
var _profile: Node
var _run_director: Node
var _fixture: Node2D
var _camera: Camera2D
var _baseline_time_scale := 1.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_director = root.get_node_or_null("/root/FeedbackDirector")
	_bus = root.get_node_or_null("/root/SignalBus")
	_profile = root.get_node_or_null("/root/ProfileState")
	_run_director = root.get_node_or_null("/root/RunDirector")
	_expect(
		null not in [_director, _bus, _profile, _run_director],
		"feedback fixture needs production autoloads"
	)
	if null in [_director, _bus, _profile, _run_director]:
		_finish()
		return

	_profile.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	_baseline_time_scale = Engine.time_scale
	_create_camera_fixture()
	await process_frame

	_validate_public_contract()
	_validate_typed_and_dictionary_requests()
	await _validate_settings_gates()
	await _validate_overlap_caps_and_real_time_pause()
	_validate_safe_global_events()
	_validate_phase_cleanup()
	await _validate_teardown_cleanup()

	_director.call("clear_feedback")
	Engine.time_scale = _baseline_time_scale
	_fixture.queue_free()
	await process_frame
	_finish()


func _validate_public_contract() -> void:
	_expect(_bus.has_signal("gameplay_feedback_requested"), "SignalBus should expose the feedback request event")
	_expect(_director.process_mode == Node.PROCESS_MODE_ALWAYS, "director should process through pause")
	_expect(_director.has_method("request_feedback"), "director should expose a concise request API")
	_expect(_director.has_method("get_feedback_snapshot"), "director should expose a copy-safe snapshot")
	_expect(_director.has_method("clear_feedback"), "director should expose explicit transient cleanup")
	var snapshot := _snapshot()
	_expect(
		int((snapshot["audio"] as Dictionary)["voice_cap"]) == 8,
		"audio overlap should have a fixed voice cap"
	)
	_expect(float((snapshot["shake"] as Dictionary)["strength_cap"]) <= 12.0, "shake strength should be bounded")
	_expect(float((snapshot["pause"] as Dictionary)["combined_cap"]) <= 0.08, "hit pause should stay very short")


func _validate_typed_and_dictionary_requests() -> void:
	_director.call("clear_feedback")
	var before := int(_snapshot()["request_count"])
	var typed := GameplayFeedbackRequest.new()
	typed.cue_id = &"jump"
	typed.shake_strength = 0.0
	typed.pause_duration = 0.0
	var typed_nested := {"label": "typed-before"}
	typed.context = {"source": "typed", "nested": typed_nested}
	_bus.emit_signal("gameplay_feedback_requested", typed)
	typed_nested["label"] = "typed-after"
	_expect(int(_snapshot()["request_count"]) == before + 1, "typed signal requests should be accepted")
	var typed_context: Dictionary = (_snapshot()["last_request"] as Dictionary)["context"]
	_expect(
		String((typed_context["nested"] as Dictionary)["label"]) == "typed-before",
		"typed signal requests should be copied before dispatch"
	)

	var nested := {"label": "before"}
	var source := {
		"cue_id": &"enemy_hit",
		"world_position": Vector2(80.0, 64.0),
		"shake_strength": 0.0,
		"pause_duration": 0.0,
		"context": {"nested": nested},
	}
	var result := _request(source)
	nested["label"] = "after"
	_expect(bool(result.get("accepted", false)), "dictionary requests should be accepted")
	var snapshot := _snapshot()
	var stored_context: Dictionary = (snapshot["last_request"] as Dictionary)["context"]
	_expect(
		String((stored_context["nested"] as Dictionary)["label"]) == "before",
		"director should deep-copy request context"
	)
	result["cue_id"] = &"mutated"
	stored_context["nested"] = {"label": "mutated"}
	var fresh := _snapshot()
	_expect(
		(fresh["last_result"] as Dictionary)["cue_id"] == &"enemy_hit",
		"returned results should not alias director state"
	)
	var fresh_context: Dictionary = (fresh["last_request"] as Dictionary)["context"]
	var fresh_nested: Dictionary = fresh_context["nested"]
	_expect(
		String(fresh_nested["label"]) == "before",
		"returned snapshots should not alias director state"
	)

	var accepted_before := int(fresh["request_count"])
	_expect(not bool(_request(42).get("accepted", true)), "unsupported request types should fail closed")
	_expect(
		not bool(_request({"cue_id": &"missing", "strength": "loud"}).get("accepted", true)),
		"malformed dictionaries should fail closed"
	)
	_expect(
		not bool(_request({"cue_id": &"jump", "shake_duration": -0.5}).get("accepted", true)),
		"only the exact -1 sentinel may represent an unset optional number"
	)
	_expect(int(_snapshot()["request_count"]) == accepted_before, "rejected requests should not enter history")

	result = _request({
		"cue_id": &"critical_hit",
		"strength": 0.0,
		"world_position": Vector2(90.0, 64.0),
	})
	_expect(
		not bool(result["audio_played"])
		and not bool(result["shake_applied"])
		and not bool(result["pause_applied"])
		and not bool(result["burst_spawned"]),
		"zero strength should suppress every feedback channel"
	)
	_director.call("clear_feedback")


func _validate_settings_gates() -> void:
	_director.call("clear_feedback")
	_set_setting("master_volume", 1.0)
	_set_setting("sfx_volume", 1.0)
	_set_setting("screen_shake", false)
	_set_setting("damage_flash", false)
	var before_audio := int((_snapshot()["audio"] as Dictionary)["play_count"])
	var result := _request({
		"cue_id": &"enemy_hit",
		"world_position": Vector2(96.0, 72.0),
		"shake_strength": 10.0,
		"shake_duration": 0.2,
		"pause_duration": 0.0,
		"burst": true,
	})
	_expect(bool(result["audio_played"]), "enabled master and SFX volume should allow audio")
	_expect(not bool(result["shake_applied"]), "screen_shake=false should block shake")
	_expect(not bool(result["burst_spawned"]), "damage_flash=false should block the hit burst")
	_expect(
		int((_snapshot()["audio"] as Dictionary)["play_count"]) == before_audio + 1,
		"enabled audio should record one play"
	)

	_set_setting("master_volume", 0.0)
	_expect(
		int((_snapshot()["audio"] as Dictionary)["active_voice_count"]) == 0,
		"zero master volume should stop active feedback voices"
	)
	result = _request({"cue_id": &"jump", "shake_strength": 0.0})
	_expect(not bool(result["audio_played"]), "zero master volume should block cue playback")
	_set_setting("master_volume", 1.0)
	_set_setting("sfx_volume", 0.0)
	result = _request({"cue_id": &"jump", "shake_strength": 0.0})
	_expect(not bool(result["audio_played"]), "zero SFX volume should block cue playback")

	_set_setting("sfx_volume", 1.0)
	_set_setting("screen_shake", true)
	_set_setting("damage_flash", true)
	_camera.offset = CAMERA_BASE_OFFSET
	result = _request({
		"cue_id": &"critical_hit",
		"world_position": Vector2(120.0, 72.0),
		"pause_duration": 0.0,
	})
	await process_frame
	var active := _snapshot()
	_expect(bool((active["shake"] as Dictionary)["active"]), "enabled screen shake should activate")
	_expect(
		int((active["burst"] as Dictionary)["active_count"]) == 1,
		"enabled damage flash should allow one burst"
	)
	_set_setting("screen_shake", false)
	_set_setting("damage_flash", false)
	var gated := _snapshot()
	_expect(not bool((gated["shake"] as Dictionary)["active"]), "disabling shake should cancel active shake")
	_expect(
		int((gated["burst"] as Dictionary)["active_count"]) == 0,
		"disabling damage flash should clear active bursts"
	)
	_expect(_camera.offset.is_equal_approx(CAMERA_BASE_OFFSET), "setting changes should restore camera offset")
	_set_setting("screen_shake", true)
	_set_setting("damage_flash", true)


func _validate_overlap_caps_and_real_time_pause() -> void:
	_director.call("clear_feedback")
	_camera.offset = CAMERA_BASE_OFFSET
	var request := {
		"cue_id": &"critical_hit",
		"strength": 999.0,
		"world_position": Vector2(180.0, 100.0),
		"shake_strength": 999.0,
		"shake_duration": 999.0,
		"pause_duration": 999.0,
		"burst_radius": 999.0,
	}
	_expect(bool(_request(request)["accepted"]), "oversized finite requests should clamp instead of failing")
	_expect(bool(_request(request)["accepted"]), "overlapping requests should remain accepted")
	await process_frame
	var snapshot := _snapshot()
	var last: Dictionary = snapshot["last_request"]
	var shake: Dictionary = snapshot["shake"]
	var pause: Dictionary = snapshot["pause"]
	_expect(float(last["strength"]) == 2.0, "request strength should clamp")
	_expect(float(last["burst_radius"]) == 48.0, "burst radius should clamp")
	_expect(float(shake["strength"]) <= float(shake["strength_cap"]), "overlapping shake should respect its cap")
	_expect(float(shake["remaining"]) <= float(shake["duration_cap"]), "shake duration should respect its cap")
	_expect(
		float(pause["remaining"]) <= float(pause["combined_cap"]),
		"overlapping pause should respect its real-time cap"
	)
	_expect(Engine.time_scale <= 0.05, "active hit pause should reduce time scale")
	_expect(not _camera.offset.is_equal_approx(CAMERA_BASE_OFFSET), "active shake should apply a camera delta")

	await create_timer(0.11, true, false, true).timeout
	await process_frame
	snapshot = _snapshot()
	_expect(not bool((snapshot["pause"] as Dictionary)["active"]), "hit pause should expire by real time")
	_expect(
		is_equal_approx(Engine.time_scale, _baseline_time_scale),
		"expired hit pause should restore time scale"
	)
	_expect(
		int((snapshot["audio"] as Dictionary)["active_voice_count"])
		<= int((snapshot["audio"] as Dictionary)["voice_cap"]),
		"audio overlap should never exceed the voice pool"
	)
	var external_camera_delta := Vector2(5.0, 7.0)
	_camera.offset += external_camera_delta
	_director.call("clear_feedback")
	_expect(
		_camera.offset.is_equal_approx(CAMERA_BASE_OFFSET + external_camera_delta),
		"cleanup should preserve camera offset added by another system"
	)
	_camera.offset = CAMERA_BASE_OFFSET

	Engine.time_scale = 0.8
	_request({
		"cue_id": &"enemy_hit",
		"shake_strength": 0.0,
		"pause_duration": 0.02,
		"burst": false,
	})
	_expect(Engine.time_scale <= 0.05, "hit pause should also apply from a custom time scale")
	_director.call("clear_feedback")
	_expect(is_equal_approx(Engine.time_scale, 0.8), "cleanup should restore the captured custom time scale")
	Engine.time_scale = _baseline_time_scale


func _validate_safe_global_events() -> void:
	_director.call("clear_feedback")
	var before := int(_snapshot()["request_count"])
	_bus.emit_signal("reward_applied", {"ok": false, "transaction_id": "failed"})
	_expect(
		int(_snapshot()["request_count"]) == before,
		"failed rewards should not produce celebration feedback"
	)
	_bus.emit_signal("reward_applied", {"applied": true, "transaction_id": "reward-test"})
	_expect_last_cue(&"reward", "applied rewards should request reward feedback")
	var before_field_reward := int(_snapshot()["request_count"])
	_bus.emit_signal("reward_applied", {"applied": true, "transaction_id": "field:arrows-1"})
	_expect(
		int(_snapshot()["request_count"]) == before_field_reward,
		"field currency settlement should wait for the field pickup event"
	)
	_bus.emit_signal("field_pickup_collected", {
		"applied": true,
		"pickup_id": "arrows-1",
		"effect_type": "grant_ranged_supply",
	})
	_expect_last_cue(&"reward", "field pickups should request one reward cue")
	_bus.emit_signal("stage_cleared", "lower_ruins")
	_expect_last_cue(&"stage_clear", "stage clear should request its own cue")
	_bus.emit_signal("boss_defeated", &"boss_clear_slime_king")
	_expect_last_cue(&"boss_defeat", "boss defeat should request boss feedback")
	_director.call("clear_feedback")


func _validate_phase_cleanup() -> void:
	_camera.offset = CAMERA_BASE_OFFSET
	_request({
		"cue_id": &"player_hurt",
		"world_position": Vector2(200.0, 100.0),
		"shake_strength": 8.0,
		"shake_duration": 0.3,
		"pause_duration": 0.04,
	})
	_run_director.emit_signal("phase_changed", "validator_phase")
	var snapshot := _snapshot()
	_expect(not bool((snapshot["shake"] as Dictionary)["active"]), "phase changes should clear shake")
	_expect(not bool((snapshot["pause"] as Dictionary)["active"]), "phase changes should clear hit pause")
	_expect(int((snapshot["burst"] as Dictionary)["active_count"]) == 0, "phase changes should clear bursts")
	_expect(
		int((snapshot["audio"] as Dictionary)["active_voice_count"])
		<= int((snapshot["audio"] as Dictionary)["voice_cap"]),
		"phase changes should leave bounded completion audio intact"
	)
	_expect(is_equal_approx(Engine.time_scale, _baseline_time_scale), "phase changes should restore time scale")
	_expect(_camera.offset.is_equal_approx(CAMERA_BASE_OFFSET), "phase changes should restore camera offset")


func _validate_teardown_cleanup() -> void:
	_director.call("clear_feedback")
	_camera.offset = CAMERA_BASE_OFFSET
	var isolated := DIRECTOR_SCRIPT.new() as Node
	isolated.name = "FeedbackDirectorTeardownFixture"
	root.add_child(isolated)
	isolated.call("request_feedback", {
		"cue_id": &"critical_hit",
		"world_position": Vector2(220.0, 100.0),
		"shake_strength": 9.0,
		"shake_duration": 0.3,
		"pause_duration": 0.04,
	})
	await process_frame
	_expect(Engine.time_scale <= 0.05, "teardown fixture should own an active hit pause")
	isolated.queue_free()
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, _baseline_time_scale), "teardown should restore time scale")
	_expect(_camera.offset.is_equal_approx(CAMERA_BASE_OFFSET), "teardown should restore camera offset")


func _create_camera_fixture() -> void:
	_fixture = Node2D.new()
	_fixture.name = "FeedbackCameraFixture"
	root.add_child(_fixture)
	_camera = Camera2D.new()
	_camera.name = "FeedbackCamera"
	_camera.offset = CAMERA_BASE_OFFSET
	_camera.enabled = true
	_fixture.add_child(_camera)
	_camera.make_current()


func _request(value: Variant) -> Dictionary:
	var result: Variant = _director.call("request_feedback", value)
	return result as Dictionary if result is Dictionary else {}


func _snapshot() -> Dictionary:
	var snapshot: Variant = _director.call("get_feedback_snapshot")
	return snapshot as Dictionary if snapshot is Dictionary else {}


func _set_setting(setting_id: String, value: Variant) -> void:
	_expect(bool(_profile.call("set_setting", setting_id, value)), "%s setting should update" % setting_id)


func _expect_last_cue(cue_id: StringName, message: String) -> void:
	_expect((_snapshot()["last_request"] as Dictionary)["cue_id"] == cue_id, message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		var snapshot := _snapshot() if _director != null else {}
		print(
			"FEEDBACK_DIRECTOR_VALIDATION_OK requests=%d rejected=%d"
			% [int(snapshot.get("request_count", 0)), int(snapshot.get("rejected_count", 0))]
		)
		quit()
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
