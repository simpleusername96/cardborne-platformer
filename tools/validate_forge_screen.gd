extends SceneTree

const SCREEN_PATH := "res://scenes/ui/production/ForgeScreen.tscn"
const VIEWPORTS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]

var _failures: Array[String] = []
var _profile_state: Node
var _localization: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_localization = root.get_node_or_null("/root/UILocalization")
	_expect(_profile_state != null, "forge UI fixture needs ProfileState")
	_expect(_localization != null, "forge UI fixture needs UILocalization")
	if _profile_state == null or _localization == null:
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_profile_state.grant_material_command("rusted_scrap", 6)
	_profile_state.grant_material_command("common_timber", 7)
	var unlock: Dictionary = _profile_state.unlock_blueprint(
		&"hunting_spear",
		&"fixture:forge:hunting_spear"
	)
	_expect(bool(unlock.get("ok", false)), "forge fixture should unlock Hunting Spear")

	var spear: Dictionary = _profile_state.get_equipment_decision_snapshot(&"hunting_spear")
	_expect(bool(spear.get("craft", {}).get("can_execute", false)), "Hunting Spear should be craftable")
	var craft_runtime: Dictionary = spear.get("craft", {}).get("result_runtime", {})
	_expect(
		bool(craft_runtime.get("ok", false)) and int(craft_runtime.get("damage", 0)) > 0,
		"craft preview should expose resolver-backed result stats"
	)

	for locale in ["en", "ko"]:
		_expect(bool(_localization.call("set_locale", locale)), "locale should be supported")
		for viewport_size in VIEWPORTS:
			await _validate_viewport(viewport_size, locale)
	_finish()


func _validate_viewport(viewport_size: Vector2i, locale: String) -> void:
	root.size = viewport_size
	var packed := load(SCREEN_PATH) as PackedScene
	_expect(packed != null, "forge screen should load after project autoloads")
	if packed == null:
		return
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	screen.configure(_profile_state.get_preparation_snapshot(), {}, "RUIN WORKBENCH")
	await process_frame
	await process_frame
	screen.select_slot(&"melee")
	screen.call("_select_model", "hunting_spear")
	await process_frame
	var layout: Dictionary = screen.get_layout_snapshot()
	_expect(layout.get("heading", "") == "RUIN WORKBENCH", "forge heading should be player-facing")
	_expect((layout.get("tabs", []) as Array).size() == 5, "forge should expose five equipment tabs")
	_expect((layout.get("models", []) as Array).size() == 2, "melee tab should expose two models")
	_expect(
		String(layout.get("selected_model", "")) == _t("Hunting Spear"),
		"selected model should use localized display name"
	)
	var actions: Array = layout.get("actions", [])
	_expect(actions.size() == 1, "uncrafted model should show one primary craft action")
	if not actions.is_empty():
		_expect(String(actions[0].get("text", "")) == _t("Craft"), "uncrafted action should be Craft")
		_expect(not bool(actions[0].get("disabled", true)), "guaranteed Stage 1 materials should enable Craft")
	for rect_key in ["panel_rect", "model_panel_rect", "detail_panel_rect", "leave_rect"]:
		_expect(_inside(Rect2(layout.get(rect_key, Rect2())), viewport_size), "%s should fit %s" % [rect_key, viewport_size])
	for action in actions:
		var rect: Rect2 = action.get("rect", Rect2())
		_expect(
			rect.size.y >= 48.0 and _inside(rect, viewport_size),
			"forge action needs a 48px in-bounds target: %s %s %s" % [locale, viewport_size, rect]
		)
	var panel_rect: Rect2 = layout.get("panel_rect", Rect2())
	_expect(
		panel_rect.get_center().distance_to(Vector2(viewport_size) * 0.5) <= 1.0,
		"forge modal should stay centered for %s %s" % [locale, viewport_size]
	)
	var command := {"count": 0, "action": &""}
	screen.connect(&"equipment_action_requested", func(action: StringName, _model: StringName, _slot: StringName) -> void:
		command["count"] += 1
		command["action"] = action
	)
	var action_buttons: Array = screen.get("_action_buttons")
	if not action_buttons.is_empty():
		(action_buttons[0] as Button).pressed.emit()
	_expect(command == {"count": 1, "action": &"craft"}, "localized forge action must keep craft semantics")
	var close_calls := {"count": 0}
	screen.connect(&"leave_requested", func() -> void: close_calls["count"] += 1)
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	(screen.get_child(0) as Control).call("_unhandled_input", cancel)
	_expect(close_calls["count"] == 1, "Esc/back should close the forge modal once")
	var visible_text := "%s %s %s" % [
		layout.get("heading", ""),
		layout.get("selected_model", ""),
		layout.get("status", ""),
	]
	for tab in layout.get("tabs", []):
		visible_text += " " + String(tab.get("text", ""))
	for model in layout.get("models", []):
		visible_text += " " + String(model.get("text", ""))
	for action in actions:
		visible_text += " " + String(action.get("text", ""))
	for raw_id in ["hunting_spear", "rusted_scrap", "common_timber", "spirit_stone"]:
		_expect(not visible_text.contains(raw_id), "forge UI should not expose raw ID %s" % raw_id)
	screen.queue_free()
	await process_frame


func _t(source: String) -> String:
	return String(_localization.call("text", StringName(source)))


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
	return rect.size.x > 0.0 and rect.size.y > 0.0 and bounds.encloses(rect)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FORGE_SCREEN_VALIDATION_OK locales=2 viewports=3 tabs=5 command=craft")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
