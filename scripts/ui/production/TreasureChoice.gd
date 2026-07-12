extends Control

signal choice_requested(request_id: StringName, choice_id: StringName)

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _panel: PanelContainer
var _title: Label
var _instruction: Label
var _option_row: HBoxContainer
var _status: Label
var _buttons: Array[Button] = []
var _request_id: StringName


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel != null:
		_layout_panel()


func configure(snapshot: Dictionary) -> void:
	_request_id = StringName(snapshot.get("request_id", &""))
	_title.text = String(snapshot.get("title", "TREASURE CHOICE")).to_upper()
	_instruction.text = String(
		snapshot.get("instruction", "Choose one reward. The other is discarded.")
	)
	_clear_options()
	for option_value in snapshot.get("options", []):
		if option_value is Dictionary:
			_option_row.add_child(_build_option(option_value))
	_status.text = ""
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func set_commit_error(message: String) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", Styles.CORAL)
	for button in _buttons:
		button.disabled = false
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.99), Styles.AMBER, 2)
	)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title, 28, Styles.AMBER)
	page.add_child(_title)

	_instruction = Label.new()
	_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_instruction, 14, Styles.TEXT_MUTED)
	page.add_child(_instruction)

	_option_row = HBoxContainer.new()
	_option_row.name = "TreasureOptions"
	_option_row.add_theme_constant_override("separation", 16)
	_option_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_option_row)

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(0.0, 24.0)
	Styles.configure_label(_status, 14, Styles.TEXT_MUTED)
	page.add_child(_status)
	_layout_panel()


func _build_option(option: Dictionary) -> Button:
	var choice_id := StringName(option.get("id", &""))
	var button := Button.new()
	button.name = "Choice_%s" % choice_id
	button.text = "%s\n\n%s\n\n%s" % [
		String(option.get("label", "CHOOSE")),
		String(option.get("title", "Reward")),
		String(option.get("description", "")),
	]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(360.0, 280.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Styles.apply_button(
		button,
		Styles.AMBER if choice_id == TreasureChoiceService.REPLACEMENT_CHOICE_ID else Styles.CYAN
	)
	button.pressed.connect(func() -> void: _request_choice(choice_id))
	_buttons.append(button)
	return button


func _request_choice(choice_id: StringName) -> void:
	for button in _buttons:
		button.disabled = true
	choice_requested.emit(_request_id, choice_id)


func _clear_options() -> void:
	_buttons.clear()
	for child in _option_row.get_children():
		_option_row.remove_child(child)
		child.queue_free()


func _layout_panel() -> void:
	var panel_size := Vector2(
		minf(900.0, maxf(size.x - 40.0, 640.0)),
		minf(500.0, maxf(size.y - 32.0, 440.0))
	)
	var panel_position := (size - panel_size) * 0.5
	_panel.offset_left = panel_position.x
	_panel.offset_top = panel_position.y
	_panel.offset_right = panel_position.x + panel_size.x
	_panel.offset_bottom = panel_position.y + panel_size.y
