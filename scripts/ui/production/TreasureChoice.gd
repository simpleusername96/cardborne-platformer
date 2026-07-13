extends Control

signal choice_requested(request_id: StringName, choice_id: StringName)

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const ChoiceCardScene = preload(
	"res://scenes/ui/production/components/RewardChoiceCard.tscn"
)

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
	call_deferred("_layout_panel")


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
			var button := _build_option(option_value)
			_option_row.add_child(button)
	_status.text = ""
	_wire_choice_focus()
	call_deferred("_focus_first_option")


func set_commit_error(message: String) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", Styles.CORAL)
	for button in _buttons:
		button.call("restore_interaction")
	_focus_first_option()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.99), Styles.AMBER, 2)
	)
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	_panel.add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title, 26, Styles.TEXT)
	page.add_child(_title)

	_instruction = Label.new()
	_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styles.configure_label(_instruction, 13, Styles.TEXT_MUTED)
	page.add_child(_instruction)

	_option_row = HBoxContainer.new()
	_option_row.name = "TreasureOptions"
	_option_row.add_theme_constant_override("separation", 12)
	_option_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_option_row)

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(0.0, 20.0)
	Styles.configure_label(_status, 13, Styles.TEXT_MUTED)
	page.add_child(_status)


func _build_option(option: Dictionary) -> Button:
	var choice_id := StringName(option.get("id", &""))
	var button := ChoiceCardScene.instantiate() as Button
	button.name = "Choice_%s" % choice_id
	button.custom_minimum_size.x = 360.0
	button.call(
		"configure_choice",
		choice_id,
		ChoiceViewModel.for_treasure_option(option)
	)
	button.pressed.connect(func() -> void: _request_choice(choice_id))
	_buttons.append(button)
	return button


func _request_choice(choice_id: StringName) -> void:
	for button in _buttons:
		button.call(
			"set_commit_pending",
			StringName(button.get("choice_id")) == choice_id
		)
	choice_requested.emit(_request_id, choice_id)


func _clear_options() -> void:
	_buttons.clear()
	for child in _option_row.get_children():
		_option_row.remove_child(child)
		child.queue_free()


func _wire_choice_focus() -> void:
	if _buttons.size() < 2:
		return
	for index in _buttons.size():
		var button := _buttons[index]
		var left := _buttons[(index - 1 + _buttons.size()) % _buttons.size()]
		var right := _buttons[(index + 1) % _buttons.size()]
		button.focus_neighbor_left = button.get_path_to(left)
		button.focus_neighbor_right = button.get_path_to(right)


func _focus_first_option() -> void:
	if not _buttons.is_empty() and not _buttons[0].disabled:
		_buttons[0].grab_focus()


func _layout_panel() -> void:
	if _panel == null:
		return
	var panel_size := Vector2(
		minf(1040.0, maxf(size.x - 40.0, 0.0)),
		minf(580.0, maxf(size.y - 24.0, 0.0))
	)
	var panel_position := (size - panel_size) * 0.5
	_panel.offset_left = panel_position.x
	_panel.offset_top = panel_position.y
	_panel.offset_right = panel_position.x + panel_size.x
	_panel.offset_bottom = panel_position.y + panel_size.y
