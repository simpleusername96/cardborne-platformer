extends SceneTree

const RUN_RESULT_SCENE := "res://scenes/ui/production/RunResult.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 540)
	var packed := load(RUN_RESULT_SCENE) as PackedScene
	_expect(packed != null, "run result scene should load")
	if packed == null:
		_finish()
		return
	var result := packed.instantiate() as Control
	root.add_child(result)
	await process_frame
	result.call("configure", true, "Traveler", _victory_settlement())
	await process_frame

	var snapshot: Dictionary = result.call("get_display_snapshot")
	_expect(snapshot.get("outcome", "") == "VICTORY", "victory outcome should be explicit")
	_expect(snapshot.get("subtitle", "") == "SLIME KING DEFEATED", "victory subtitle should name the boss result")
	_expect(String(snapshot.get("reach", "")).contains("Slime Court"), "summary should name the boss arena")
	_expect(snapshot.get("time", "") == "14:05", "summary should format run duration")
	_expect(String(snapshot.get("build", "")).contains("Dash Wake x2"), "summary should show final card stacks")
	_expect(String(snapshot.get("materials", "")).contains("Boss Core  +1"), "summary should show the kept Boss Core")
	_expect(result.size.is_equal_approx(Vector2(root.size)), "run result should fill compact viewport")

	result.call("configure", false, "Traveler", _death_settlement())
	await process_frame
	snapshot = result.call("get_display_snapshot")
	_expect(snapshot.get("outcome", "") == "DEFEAT", "death outcome should be distinct from clear")
	_expect(snapshot.get("subtitle", "") == "EXPEDITION ENDED", "death subtitle should be distinct from clear")
	_expect(String(snapshot.get("detail", "")).contains("fell before reaching the crown"), "death summary should explain the terminal reason")
	_expect(String(snapshot.get("materials", "")).contains("Sky Thread  +2"), "death summary should show materials that persist")

	result.call("configure_retry_decision", "Traveler", _attempt_snapshot())
	await process_frame
	snapshot = result.call("get_display_snapshot")
	_expect(bool(snapshot.get("retry_decision", false)), "death choice should use retry-decision mode")
	_expect(snapshot.get("retry_action", "") == "Retry Stage", "death choice should retry the current stage")
	_expect(snapshot.get("secondary_action", "") == "End Expedition", "death choice should expose explicit settlement")
	var retry_button := result.get_node("%RetryButton") as Button
	var end_button := result.get_node("%MenuButton") as Button
	_expect(retry_button.custom_minimum_size.y >= 44.0, "Retry Stage should retain a usable keyboard target")
	_expect(end_button.custom_minimum_size.y >= 44.0, "End Expedition should retain a usable keyboard target")
	_expect(root.gui_get_focus_owner() == retry_button, "retry decision should focus its primary action")
	var calls := {"end": 0}
	result.connect(&"end_requested", func() -> void: calls["end"] += 1)
	end_button.pressed.emit()
	_expect(calls["end"] == 1, "End Expedition control should emit its dedicated command once")

	result.queue_free()
	await process_frame
	_finish()


func _victory_settlement() -> Dictionary:
	return {
		"victory": true,
		"terminal_reason": "boss_defeated",
		"seed": 73021,
		"stage_reached": 3,
		"boss_reached": true,
		"duration_seconds": 845.0,
		"profile": {"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true)},
		"run_build": {"level": 6, "cards": {"dash_wake": 2, "perfect_punish": 1}},
		"persistent_material_delta": {"slime_residue": 8, "boss_core": 1},
	}


func _death_settlement() -> Dictionary:
	return {
		"victory": false,
		"terminal_reason": "player_defeated",
		"seed": 1204,
		"stage_reached": 2,
		"boss_reached": false,
		"duration_seconds": 301.0,
		"profile": {"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true)},
		"run_build": {"level": 3, "cards": {}},
		"persistent_material_delta": {"sky_thread": 2},
	}


func _attempt_snapshot() -> Dictionary:
	return {
		"version": StageAttemptSnapshot.VERSION,
		"run_seed": 1204,
		"stage_index": 1,
		"stage_path": "res://scenes/stages/production/ProductionStageHost.tscn",
		"boss_attempt": false,
		"run_state": {
			"run_level": 3,
			"card_stacks": {"dash_wake": 1},
		},
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("RUN_RESULT_UI_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
