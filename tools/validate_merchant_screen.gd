extends SceneTree

const SCREEN_PATH := "res://scenes/ui/production/MerchantScreen.tscn"
const VIEWPORTS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]

var _failures: Array[String] = []
var _localization: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_localization = root.get_node_or_null("/root/UILocalization")
	_expect(_localization != null, "merchant UI fixture needs UILocalization")
	if _localization == null:
		_finish()
		return
	for locale in ["en", "ko"]:
		_expect(bool(_localization.call("set_locale", locale)), "locale should be supported")
		for viewport_size in VIEWPORTS:
			await _validate_viewport(viewport_size, locale)
	_finish()


func _validate_viewport(viewport_size: Vector2i, locale: String) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	var packed := load(SCREEN_PATH) as PackedScene
	_expect(packed != null, "merchant screen should load")
	if packed == null:
		return
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	var snapshot := {
		"coins": 40,
		"run_salvage": 6,
		"consumable_charges": 0,
		"max_consumable_charges": 1,
		"buy_potion": {"can_apply": true, "coin_cost": 15},
		"sell_all_salvage": {"can_apply": true, "coin_gain": 18},
	}
	screen.call("configure", snapshot, {}, "TRAVELING MERCHANT")
	for _frame in 3:
		await process_frame
	var layout: Dictionary = screen.call("get_layout_snapshot")
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var panel_rect: Rect2 = layout.get("panel_rect", Rect2())
	_expect(bounds.encloses(panel_rect), "merchant modal must fit %s %s" % [locale, viewport_size])
	_expect(
		panel_rect.get_center().distance_to(Vector2(viewport_size) * 0.5) <= 1.0,
		"merchant modal must be centered %s %s" % [locale, viewport_size]
	)
	for rect_key in ["buy_rect", "sell_rect", "leave_rect"]:
		var rect: Rect2 = layout.get(rect_key, Rect2())
		_expect(
			bounds.encloses(rect) and rect.size.y >= 48.0,
			"%s must be an in-bounds 48px target %s %s" % [rect_key, locale, viewport_size]
		)
	_expect(bool(layout.get("buy_enabled", false)), "potion purchase should be enabled")
	_expect(bool(layout.get("sell_enabled", false)), "salvage sale should be enabled")
	_expect(String(layout.get("heading", "")) == _t("TRAVELING MERCHANT"), "heading should localize")
	_expect(String(layout.get("buy_text", "")) == _t("Buy Potion"), "buy action should localize")
	_expect(String(layout.get("sell_text", "")) == _t("Sell All Salvage"), "sell action should localize")
	_expect(String(layout.get("leave_text", "")) == _t("Close"), "close action should localize")
	_expect(String(layout.get("coins", "")).contains("40"), "coin balance should stay visible")
	_expect(String(layout.get("salvage", "")).contains("6"), "salvage balance should stay visible")
	_expect(screen.find_child("Backdrop", true, false) == null, "merchant modal must preserve the map behind it")
	await _capture_if_requested(viewport_size, locale)

	var calls := {"buy": 0, "sell": 0, "leave": 0}
	screen.connect(&"buy_potion_requested", func() -> void: calls["buy"] += 1)
	screen.connect(&"sell_salvage_requested", func() -> void: calls["sell"] += 1)
	screen.connect(&"leave_requested", func() -> void: calls["leave"] += 1)
	var buy_button := _button_with_text(screen, _t("Buy Potion"))
	var sell_button := _button_with_text(screen, _t("Sell All Salvage"))
	_expect(root.gui_get_focus_owner() == buy_button, "merchant should focus its first available trade")
	if buy_button != null:
		buy_button.pressed.emit()
		_expect(not buy_button.focus_neighbor_bottom.is_empty(), "Down Arrow needs an explicit trade path")
	if sell_button != null:
		sell_button.pressed.emit()
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	(screen.get_child(0) as Control).call("_unhandled_input", cancel)
	_expect(calls == {"buy": 1, "sell": 1, "leave": 1}, "merchant inputs must keep trade/close semantics")
	screen.queue_free()
	await process_frame


func _button_with_text(node: Node, expected: String) -> Button:
	if node is Button and (node as Button).text == expected:
		return node as Button
	for child in node.get_children():
		var found := _button_with_text(child, expected)
		if found != null:
			return found
	return null


func _t(source: String) -> String:
	return String(_localization.call("text", StringName(source)))


func _capture_if_requested(viewport_size: Vector2i, locale: String) -> void:
	if OS.get_environment("CAPTURE_MERCHANT_SCREEN") != "1":
		return
	var output_dir := "user://merchant_screen_validation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	for _draw_pass in 3:
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		await process_frame
	var image := root.get_texture().get_image()
	var output_path := "%s/merchant_%s_%dx%d.png" % [
		output_dir,
		locale,
		viewport_size.x,
		viewport_size.y,
	]
	var error := image.save_png(output_path) if image != null else ERR_CANT_CREATE
	_expect(error == OK, "merchant capture should save %s" % output_path)
	if error == OK:
		print("MERCHANT_SCREEN_CAPTURE %s" % ProjectSettings.globalize_path(output_path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MERCHANT_SCREEN_VALIDATION_OK locales=2 viewports=3 actions=buy>sell>close")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
