extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const WALKER_SCENE := "res://scenes/enemies/WalkerRuin.tscn"

var _failures: Array[String] = []
var _feedback_requests: Array[Dictionary] = []
var _fixture_seed := 84_200


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var bus := root.get_node_or_null("/root/SignalBus")
	_expect(bus != null, "production SignalBus should exist")
	if bus == null:
		_finish()
		return
	bus.gameplay_feedback_requested.connect(_on_feedback_requested)
	_validate_guard_binding()
	await _validate_idle_hit()
	await _validate_startup_hit()
	await _validate_precise_block()
	await _validate_normal_block()
	await _validate_outside_angle(Vector2(0.0, -120.0), "side")
	await _validate_outside_angle(Vector2(-120.0, 0.0), "rear")
	await _validate_unblockable_hit()
	await _validate_guard_break()
	await _validate_recovery_hit()
	await _validate_recovery_rearm()
	await _validate_held_guard_after_attack()
	for cue_id in [&"guard_start", &"guard_block", &"precise_guard", &"guard_break", &"guard_recover"]:
		_expect(_has_feedback_cue(cue_id), "production guard path should emit %s" % cue_id)
	if bus.gameplay_feedback_requested.is_connected(_on_feedback_requested):
		bus.gameplay_feedback_requested.disconnect(_on_feedback_requested)
	_release_key(KEY_C)
	_release_key(KEY_X)
	var director := root.get_node_or_null("/root/FeedbackDirector")
	if director != null:
		director.call("clear_feedback")
	_finish()


func _validate_guard_binding() -> void:
	var has_c := false
	for event in InputMap.action_get_events("guard"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := (
				key_event.physical_keycode
				if key_event.physical_keycode != KEY_NONE
				else key_event.keycode
			)
			has_c = has_c or keycode == KEY_C
	_expect(has_c, "configured guard action should include the C key")


func _validate_idle_hit() -> void:
	var fixture := await _spawn_fixture()
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack"])
	await process_frame
	_expect(_health() == before - 1, "idle frontal hit should damage the player")
	_assert_feedback(fixture, &"guard_failed", &"not_guarding", "GUARD DOWN")
	await _free_fixture(fixture)


func _validate_startup_hit() -> void:
	var fixture := await _spawn_fixture()
	_press_key(KEY_C)
	await physics_frame
	fixture.combat.call("update_combat", 0.0)
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack"])
	_expect(_health() == before - 1, "guard startup should not block")
	_assert_feedback(fixture, &"guard_failed", &"guard_startup", "TOO EARLY")
	await _free_fixture(fixture)


func _validate_precise_block() -> void:
	var fixture := await _spawn_active_guard_fixture(0.08)
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack"])
	await process_frame
	_expect(_health() == before, "initial active guard should prevent health damage")
	_assert_feedback(fixture, &"precise_block", &"precise_block", "PRECISE GUARD")
	var feedback := _defense_feedback(fixture)
	_expect(int(feedback.get("condition_cost", -1)) == 0, "precise guard should report zero condition cost")
	_expect(int(feedback.get("stability_cost", -1)) >= 0, "precise guard should report stability cost")
	_assert_overlay(fixture, &"active", &"precise_block")
	await _free_fixture(fixture)


func _validate_normal_block() -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack"])
	await process_frame
	_expect(_health() == before, "held active guard should prevent frontal health damage")
	_assert_feedback(fixture, &"normal_block", &"blocked", "BLOCKED")
	var feedback := _defense_feedback(fixture)
	_expect(int(feedback.get("condition_cost", 0)) == 1, "normal block should report one condition cost")
	_expect(int(feedback.get("stability_cost", 0)) == 20, "normal block should report exact stability cost")
	var guard_view := _guard_view(fixture)
	_expect(String(guard_view.get("condition", "")).contains("-1 CND"), "HUD should show condition spent")
	_expect(String(guard_view.get("stability", "")).contains("-20 STB"), "HUD should show stability spent")
	_assert_overlay(fixture, &"active", &"normal_block")
	await _free_fixture(fixture)


func _validate_outside_angle(offset: Vector2, label: String) -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	var before := _health()
	_hit_player(fixture, offset, ["enemy_attack"])
	await process_frame
	_expect(_health() == before - 1, "%s hit should pass the frontal guard" % label)
	_assert_feedback(fixture, &"guard_failed", &"outside_guard_angle", "OUTSIDE GUARD")
	await _free_fixture(fixture)


func _validate_unblockable_hit() -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack", "unblockable"])
	await process_frame
	_expect(_health() == before - 1, "unblockable hit should damage through active guard")
	_assert_feedback(fixture, &"guard_failed", &"unblockable", "UNBLOCKABLE")
	await _free_fixture(fixture)


func _validate_guard_break() -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack", "heavy"], 100)
	await process_frame
	_expect(_health() == before - 1, "guard-breaking hit should pass health damage")
	_assert_feedback(fixture, &"guard_break", &"guard_broken", "GUARD BROKEN")
	var guard: Dictionary = fixture.combat.call("get_state_snapshot").get("guard", {})
	_expect(guard.get("phase", &"") == &"recovery", "guard break should enter recovery")
	_expect(int(guard.get("stability", -1)) == 0, "guard break should consume remaining stability")
	_assert_overlay(fixture, &"recovery", &"guard_break")
	await _free_fixture(fixture)


func _validate_recovery_rearm() -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	_release_key(KEY_C)
	await physics_frame
	var recovery: Dictionary = fixture.combat.call("get_state_snapshot")
	_expect((recovery.get("guard", {}) as Dictionary).get("phase", &"") == &"recovery", "guard release should enter recovery")
	_assert_feedback(fixture, &"guard_recovery", &"guard_recovery", "GUARD RECOVERY")
	_press_key(KEY_C)
	await physics_frame
	fixture.combat.call("update_combat", 0.30)
	var rearmed: Dictionary = fixture.combat.call("get_state_snapshot")
	_expect((rearmed.get("guard", {}) as Dictionary).get("phase", &"") == &"active", "held C during recovery should re-enter active guard")
	_expect(
		(rearmed.get("defense_feedback", {}) as Dictionary).get("outcome", &"") == &"guard_start",
		"rearmed guard should replace stale recovery feedback with GUARD RAISED"
	)
	await _free_fixture(fixture)


func _validate_recovery_hit() -> void:
	var fixture := await _spawn_active_guard_fixture(0.30)
	_release_key(KEY_C)
	await physics_frame
	var before := _health()
	_hit_player(fixture, Vector2(120.0, 0.0), ["enemy_attack"])
	await process_frame
	_expect(_health() == before - 1, "guard recovery should not block")
	_assert_feedback(fixture, &"guard_failed", &"guard_recovery", "RECOVERING")
	await _free_fixture(fixture)


func _validate_held_guard_after_attack() -> void:
	var fixture := await _spawn_fixture()
	_press_key(KEY_X)
	var started := bool(fixture.combat.call("try_start_input"))
	_release_key(KEY_X)
	_expect(started and fixture.combat.get("current_attack") != null, "configured X input should start the contextual attack")
	_press_key(KEY_C)
	var entered_guard := false
	for _frame in 90:
		await physics_frame
		var guard: Dictionary = fixture.combat.call("get_state_snapshot").get("guard", {})
		if guard.get("phase", &"") == &"active":
			entered_guard = true
			break
	_expect(entered_guard, "held C should enter guard after attack recovery instead of being swallowed")
	await _free_fixture(fixture)


func _spawn_active_guard_fixture(active_elapsed: float) -> Dictionary:
	var fixture := await _spawn_fixture()
	_press_key(KEY_C)
	await physics_frame
	fixture.combat.call("update_combat", active_elapsed)
	var guard: Dictionary = fixture.combat.call("get_state_snapshot").get("guard", {})
	_expect(guard.get("phase", &"") == &"active", "held C should reach active guard")
	return fixture


func _spawn_fixture() -> Dictionary:
	_release_key(KEY_C)
	_release_key(KEY_X)
	await physics_frame
	var profile := root.get_node("/root/ProfileState")
	profile.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_fixture_seed += 1
	_expect(root.get_node("/root/RunState").call("start_new_run", 0, _fixture_seed), "fixture run should start")
	var world := Node2D.new()
	world.name = "GuardProductionPathFixture"
	root.add_child(world)
	var hud_packed := load(HUD_SCENE) as PackedScene
	var player_packed := load(PLAYER_SCENE) as PackedScene
	_expect(hud_packed != null and player_packed != null, "production Player and HUD scenes should load")
	if hud_packed == null or player_packed == null:
		world.queue_free()
		return {}
	var hud := hud_packed.instantiate() as Control
	world.add_child(hud)
	var player := player_packed.instantiate() as CharacterBody2D
	world.add_child(player)
	player.global_position = Vector2(480.0, 420.0)
	player.facing = 1
	await process_frame
	return {
		"world": world,
		"hud": hud,
		"player": player,
		"combat": player.get_node("CombatController"),
	}


func _hit_player(
	fixture: Dictionary,
	source_offset: Vector2,
	tags: Array[String],
	stagger: int = 0
) -> void:
	var player := fixture.player as CharacterBody2D
	var enemy_packed := load(WALKER_SCENE) as PackedScene
	_expect(enemy_packed != null, "production Walker scene should load")
	if enemy_packed == null:
		return
	var source := enemy_packed.instantiate() as CharacterBody2D
	source.name = "GuardPathWalker"
	fixture.world.add_child(source)
	source.global_position = player.global_position + source_offset
	source.set_physics_process(false)
	var hitbox := source.get_node_or_null("ContactHitbox") as Hitbox
	_expect(hitbox != null, "production Walker should own a ContactHitbox")
	if hitbox == null:
		return
	hitbox.tags = tags
	if stagger > 0:
		hitbox.set_damage_info_provider(func(_area: Area2D) -> DamageInfo:
			return DamageInfo.new(1, hitbox, Vector2.ZERO, tags, &"guard_path_probe", stagger)
		)
	hitbox.set_active(true)
	hitbox.call("_on_area_entered", player.get_node("Hurtbox"))


func _assert_feedback(
	fixture: Dictionary,
	expected_outcome: StringName,
	expected_reason: StringName,
	expected_label: String
) -> void:
	var feedback := _defense_feedback(fixture)
	_expect(feedback.get("outcome", &"") == expected_outcome, "defense outcome should be %s, got %s" % [expected_outcome, feedback])
	_expect(feedback.get("reason", &"") == expected_reason, "defense reason should be %s, got %s" % [expected_reason, feedback])
	_expect(String(feedback.get("label", "")) == expected_label, "defense label should explain %s" % expected_reason)
	_expect(bool(feedback.get("active", false)), "defense feedback should remain visible after the hit")
	var guard_view := _guard_view(fixture)
	_expect(String(guard_view.get("outcome", "")) == String(expected_outcome), "HUD should receive the defense outcome")
	_expect(String(guard_view.get("reason", "")) == String(expected_reason), "HUD should receive the defense reason")
	_expect(String(guard_view.get("name", "")) == expected_label, "HUD should show the defense label")


func _assert_overlay(
	fixture: Dictionary,
	expected_phase: StringName,
	expected_outcome: StringName
) -> void:
	var overlay: Node = fixture.player.get_node("Visual/PlayerVisualOverlay")
	overlay.call("_update_guard_visual", 0.0)
	var visual: Dictionary = overlay.call("get_visual_contract")
	_expect(visual.get("guard_phase", &"") == expected_phase, "player pose should expose %s guard phase" % expected_phase)
	_expect(visual.get("defense_outcome", &"") == expected_outcome, "player effect should expose %s" % expected_outcome)
	_expect(bool(visual.get("defense_effect_visible", false)), "player defense effect should be visible")


func _defense_feedback(fixture: Dictionary) -> Dictionary:
	return fixture.combat.call("get_state_snapshot").get("defense_feedback", {})


func _guard_view(fixture: Dictionary) -> Dictionary:
	var layout: Dictionary = fixture.hud.call("get_layout_snapshot")
	return (layout.get("combat", {}) as Dictionary).get("guard", {})


func _health() -> int:
	return int(root.get_node("/root/RunState").get("current_health"))


func _press_key(keycode: Key) -> void:
	_send_key(keycode, true)


func _release_key(keycode: Key) -> void:
	_send_key(keycode, false)


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	# Parsed test events are buffered in production; flush so the next explicit
	# combat tick observes the same state as the following engine frame.
	Input.flush_buffered_events()


func _has_feedback_cue(cue_id: StringName) -> bool:
	for request in _feedback_requests:
		if request.get("cue_id", &"") == cue_id:
			return true
	return false


func _on_feedback_requested(request: Variant) -> void:
	if request is Dictionary:
		_feedback_requests.append((request as Dictionary).duplicate(true))


func _free_fixture(fixture: Dictionary) -> void:
	_release_key(KEY_C)
	_release_key(KEY_X)
	fixture.world.queue_free()
	await process_frame
	var director := root.get_node_or_null("/root/FeedbackDirector")
	if director != null:
		director.call("clear_feedback")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("GUARD_PRODUCTION_PATH_VALIDATION_OK outcomes=9 input=C path=WalkerContactHitbox>Hurtbox>PlayerController")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
