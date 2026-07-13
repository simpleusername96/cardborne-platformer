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
	result.call("configure", true, "Warrior", _victory_settlement())
	await process_frame

	var snapshot: Dictionary = result.call("get_display_snapshot")
	_expect(snapshot.get("outcome", "") == "VICTORY", "victory outcome should be explicit")
	_expect(snapshot.get("subtitle", "") == "SLIME KING DEFEATED", "victory subtitle should name the boss result")
	_expect(String(snapshot.get("reach", "")).contains("Slime Court"), "summary should name the boss arena")
	_expect(snapshot.get("time", "") == "14:05", "summary should format run duration")
	_expect(String(snapshot.get("build", "")).contains("Dash Wake x2"), "summary should show final card stacks")
	_expect(String(snapshot.get("materials", "")).contains("Boss Core  +1"), "summary should show the kept Boss Core")
	_expect(result.size.is_equal_approx(Vector2(root.size)), "run result should fill compact viewport")

	result.call("configure", false, "Archer", _death_settlement())
	await process_frame
	snapshot = result.call("get_display_snapshot")
	_expect(snapshot.get("outcome", "") == "DEFEAT", "death outcome should be distinct from clear")
	_expect(snapshot.get("subtitle", "") == "EXPEDITION ENDED", "death subtitle should be distinct from clear")
	_expect(String(snapshot.get("detail", "")).contains("fell before reaching the crown"), "death summary should explain the terminal reason")
	_expect(String(snapshot.get("materials", "")).contains("Sky Thread  +2"), "death summary should show materials that persist")

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
		"run_build": {"level": 6, "cards": {"dash_wake": 2, "warrior_seismic_edge": 1}},
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
		"run_build": {"level": 3, "cards": {}},
		"persistent_material_delta": {"sky_thread": 2},
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
