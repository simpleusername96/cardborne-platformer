class_name MerchantScreen
extends Control

signal buy_potion_requested
signal sell_salvage_requested
signal leave_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _snapshot: Dictionary = {}
var _result: Dictionary = {}
var _heading := "TRAVELING MERCHANT"

var _coins_label: Label
var _title_label: Label
var _salvage_label: Label
var _potion_label: Label
var _sale_label: Label
var _status_label: Label
var _buy_button: Button
var _sell_button: Button
var _leave_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		leave_requested.emit()


func configure(
	snapshot: Dictionary,
	result: Dictionary = {},
	heading: String = "TRAVELING MERCHANT"
) -> void:
	_snapshot = snapshot.duplicate(true)
	_result = result.duplicate(true)
	_heading = heading
	if is_node_ready():
		_render()


func get_layout_snapshot() -> Dictionary:
	return {
		"heading": _heading,
		"coins": _coins_label.text if _coins_label != null else "",
		"salvage": _salvage_label.text if _salvage_label != null else "",
		"buy_enabled": _buy_button != null and not _buy_button.disabled,
		"sell_enabled": _sell_button != null and not _sell_button.disabled,
		"buy_rect": _buy_button.get_global_rect() if _buy_button != null else Rect2(),
		"sell_rect": _sell_button.get_global_rect() if _sell_button != null else Rect2(),
		"leave_rect": _leave_button.get_global_rect() if _leave_button != null else Rect2(),
		"status": _status_label.text if _status_label != null else "",
	}


func _build_ui() -> void:
	add_child(BackdropScene.new())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640.0, 430.0)
	panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.98), Styles.CYAN)
	)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	panel.add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)

	_title_label = Label.new()
	Styles.configure_label(_title_label, 28, Styles.TEXT)
	page.add_child(_title_label)
	_coins_label = _label(20, Styles.AMBER)
	_salvage_label = _label(20, Styles.CYAN)
	page.add_child(_coins_label)
	page.add_child(_salvage_label)
	page.add_child(HSeparator.new())

	_potion_label = _label(19, Styles.TEXT)
	_potion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_potion_label)
	_buy_button = _button("BUY POTION")
	_buy_button.pressed.connect(func() -> void: buy_potion_requested.emit())
	page.add_child(_buy_button)

	_sale_label = _label(19, Styles.TEXT)
	_sale_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_sale_label)
	_sell_button = _button("SELL ALL SALVAGE")
	_sell_button.pressed.connect(func() -> void: sell_salvage_requested.emit())
	page.add_child(_sell_button)

	_status_label = _label(18, Styles.TEXT_MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_status_label)

	_leave_button = _button("LEAVE")
	_leave_button.pressed.connect(func() -> void: leave_requested.emit())
	page.add_child(_leave_button)


func _render() -> void:
	if _coins_label == null:
		return
	_title_label.text = _heading
	var coins := int(_snapshot.get("coins", 0))
	var salvage := int(_snapshot.get("run_salvage", 0))
	var charges := int(_snapshot.get("consumable_charges", 0))
	var buy_preview: Dictionary = _snapshot.get("buy_potion", {})
	var sell_preview: Dictionary = _snapshot.get("sell_all_salvage", {})
	_coins_label.text = "Coins: %d" % coins
	_salvage_label.text = "Run Salvage: %d" % salvage
	_potion_label.text = "Healing Potion — %d coins  |  Charges %d/%d" % [
		int(buy_preview.get("coin_cost", buy_preview.get("price", 0))),
		charges,
		int(_snapshot.get("max_consumable_charges", 1)),
	]
	_sale_label.text = "Sell all Run Salvage — %d coins total" % int(
		sell_preview.get("coin_gain", sell_preview.get("total", 0))
	)
	_buy_button.disabled = not _preview_can_apply(buy_preview)
	_sell_button.disabled = not _preview_can_apply(sell_preview)
	if _result.is_empty():
		_status_label.text = "Choose one trade, or leave without trading."
		_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	else:
		_status_label.text = String(_result.get("message", "Trade updated."))
		_status_label.add_theme_color_override(
			"font_color", Styles.MOSS if bool(_result.get("ok", false)) else Styles.CORAL
		)
	var first_focus := _buy_button if not _buy_button.disabled else (
		_sell_button if not _sell_button.disabled else _leave_button
	)
	first_focus.call_deferred("grab_focus")


func _preview_can_apply(preview: Dictionary) -> bool:
	return bool(preview.get("can_apply", preview.get("ok", false)))


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	Styles.configure_label(label, font_size, color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	Styles.apply_button(button, Styles.CYAN, true)
	return button
