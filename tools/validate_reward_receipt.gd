extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

var _failures: Array[String] = []
var _checkpoint := "initialize"


func _initialize() -> void:
	create_timer(6.0).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run")


func _run() -> void:
	_checkpoint = "load autoloads"
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "receipt fixture needs profile/run autoloads")
	if profile_state == null or run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_checkpoint = "start run"
	_expect(run_state.start_new_run(0, 9227), "receipt fixture run should start")
	root.size = Vector2i(960, 540)
	var presenter := RewardReceiptPresenter.new()
	root.add_child(presenter)
	_checkpoint = "presenter ready"
	await process_frame
	presenter.present({"applied": false, "duplicate": true})
	_expect(
		not bool(presenter.get_display_snapshot()["visible"]),
		"duplicate transaction replay should not show a receipt"
	)

	var currency := {
		"applied": true,
		"reward_role": &"cache_reward",
		"grants": {"coin": 7, "xp": 3, "rusted_scrap": 1},
		"equipment_discoveries": [],
	}
	var view := presenter.build_view_model(currency)
	_expect(view["title"] == "CHEST OPENED", "currency cache should use chest title")
	_expect(
		String(view["summary"]).contains("+7 Coins")
		and String(view["summary"]).contains("+3 XP")
		and String(view["summary"]).contains("+1 Rusted Scrap"),
		"currency receipt should name every grant"
	)

	var discovery := currency.duplicate(true)
	discovery["equipment_discoveries"] = [{
		"item_id": "bell_hammer",
		"duplicate": false,
		"payload": {"item_id": "bell_hammer", "salvage": {}},
	}]
	view = presenter.build_view_model(discovery)
	_expect(view["title"] == "EQUIPMENT FOUND", "new equipment should lead the receipt")
	_expect(String(view["summary"]).contains("Bell Hammer unlocked"), "equipment receipt should use display name")
	var replacement := discovery.duplicate(true)
	replacement["reward_role"] = &"optional_route"
	replacement["replacement_kind"] = &"equipment"
	view = presenter.build_view_model(replacement)
	_expect(view["title"] == "EQUIPMENT FOUND", "Treasure equipment replacement should identify its result")

	var duplicate := discovery.duplicate(true)
	duplicate["equipment_discoveries"][0]["duplicate"] = true
	duplicate["equipment_discoveries"][0]["payload"]["salvage"] = {"rusted_scrap": 4}
	view = presenter.build_view_model(duplicate)
	_expect(view["title"] == "CACHE SALVAGED", "duplicate equipment should identify salvage")
	_expect(
		String(view["summary"]).contains("Bell Hammer duplicate")
		and String(view["summary"]).contains("+4 Rusted Scrap"),
		"duplicate receipt should identify item and salvage"
	)

	var forge := {
		"applied": true,
		"reward_role": &"optional_route",
		"replacement_kind": &"forge",
		"replacement_payload": {"item_id": &"bell_hammer", "affix_id": &"forge_force"},
		"grants": {},
		"equipment_discoveries": [],
	}
	view = presenter.build_view_model(forge)
	_expect(view["title"] == "FORGE APPLIED", "forge replacement should use forge title")
	_expect(String(view["summary"]).contains("Bell Hammer: Force"), "forge receipt should name item and affix")

	_checkpoint = "present first receipt"
	presenter.present(currency)
	await process_frame
	_checkpoint = "inspect first receipt"
	var snapshot := presenter.get_display_snapshot()
	_expect(bool(snapshot["visible"]), "presented receipt should become visible")
	_expect(snapshot["title"] == "CHEST OPENED", "visible receipt should expose current title")
	var panel_rect := snapshot["panel_rect"] as Rect2
	_expect(panel_rect.position.y >= 0.0 and panel_rect.end.y <= 540.0, "compact receipt should remain inside viewport")
	presenter.present({
		"applied": true,
		"reward_role": &"material_node",
		"grants": {"sky_thread": 2},
		"equipment_discoveries": [],
	})
	_checkpoint = "inspect queue"
	_expect(
		int(presenter.get_display_snapshot()["queue_count"]) == 1,
		"a second receipt should queue while the first is visible"
	)

	presenter.queue_free()
	_checkpoint = "free presenter"
	await process_frame
	_checkpoint = "finish"
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REWARD_RECEIPT_VALIDATION_OK scenarios=7 viewport=960x540 queue=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _on_watchdog_timeout() -> void:
	push_error("Reward receipt validator timed out at: %s" % _checkpoint)
	quit(2)
