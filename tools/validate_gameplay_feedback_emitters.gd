extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const WALKER_SCENE := "res://scenes/enemies/WalkerSanctum.tscn"
const BOSS_STAGE_SCENE := "res://scenes/stages/boss/SlimeCourt.tscn"

var _failures: Array[String] = []
var _requests: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var bus := root.get_node_or_null("/root/SignalBus")
	var run_state := root.get_node_or_null("/root/RunState")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	_expect(bus != null and run_state != null and profile_state != null, "feedback emitters need production autoloads")
	if bus == null or run_state == null or profile_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	run_state.start_new_run(0, 95101)
	bus.gameplay_feedback_requested.connect(_on_feedback_requested)

	await _validate_player_feedback()
	await _validate_enemy_feedback()
	await _validate_boss_warning_feedback(run_state)
	var cue_ids: Array[StringName] = []
	for request in _requests:
		cue_ids.append(StringName(request.get("cue_id", &"")))
	for cue_id in [&"jump", &"dash", &"player_hurt", &"enemy_hit", &"critical_hit", &"enemy_defeat", &"boss_warning"]:
		_expect(cue_ids.has(cue_id), "runtime paths should emit %s feedback" % cue_id)
	for request in _requests:
		var cue_id := StringName(request.get("cue_id", &""))
		if cue_id in [&"player_hurt", &"enemy_hit", &"critical_hit", &"enemy_defeat"]:
			_expect(request.get("world_position") is Vector2, "%s should carry a world position" % cue_id)

	if bus.gameplay_feedback_requested.is_connected(_on_feedback_requested):
		bus.gameplay_feedback_requested.disconnect(_on_feedback_requested)
	var feedback := root.get_node_or_null("/root/FeedbackDirector")
	if feedback != null:
		feedback.clear_feedback()
	_finish()


func _validate_player_feedback() -> void:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	player.call("_perform_jump")
	Input.action_press("dash")
	player.call("_update_dash", 1.0, 0.016)
	Input.action_release("dash")
	player.receive_damage(DamageInfo.new(1, null, Vector2(120.0, -80.0), ["enemy_attack"], &"feedback_probe"))
	player.queue_free()
	await process_frame


func _validate_enemy_feedback() -> void:
	var first := (load(WALKER_SCENE) as PackedScene).instantiate()
	root.add_child(first)
	await process_frame
	first.receive_damage(DamageInfo.new(1, null, Vector2.ZERO, ["player_attack"], &"normal_probe"))
	first.receive_damage(DamageInfo.new(99, null, Vector2.ZERO, ["player_attack"], &"defeat_probe"))
	var second := (load(WALKER_SCENE) as PackedScene).instantiate()
	root.add_child(second)
	await process_frame
	second.receive_damage(DamageInfo.new(1, null, Vector2.ZERO, ["player_attack"], &"critical_probe", 0, true))
	first.queue_free()
	second.queue_free()
	await process_frame


func _validate_boss_warning_feedback(run_state: Node) -> void:
	run_state.start_new_run(0, 95102)
	run_state.set("current_stage_index", 3)
	var stage := (load(BOSS_STAGE_SCENE) as PackedScene).instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_manual_simulation(true)
	stage.advance_runtime(0.90)
	await process_frame
	stage.queue_free()
	await process_frame


func _on_feedback_requested(request: Variant) -> void:
	if request is Dictionary:
		_requests.append((request as Dictionary).duplicate(true))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("GAMEPLAY_FEEDBACK_EMITTER_VALIDATION_OK requests=%d cues=7" % _requests.size())
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
