extends Control

signal choice_requested(upgrade_id: StringName)

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const ChoiceCardScene = preload(
	"res://scenes/ui/production/components/RewardChoiceCard.tscn"
)

var _choice_buttons: Array[Button] = []
var _choice_row: HBoxContainer
var _margin: MarginContainer
var _page: VBoxContainer
var _status_label: Label
var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_responsive_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _margin != null:
		_apply_responsive_layout()


func set_commit_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Styles.CORAL)
	for button in _choice_buttons:
		button.call("restore_interaction")
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _build_ui() -> void:
	add_child(BackdropScene.new())
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)

	var center := CenterContainer.new()
	_margin.add_child(center)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 10)
	center.add_child(_page)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	_page.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = "RUN LEVEL"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(eyebrow, 12, Styles.TEXT_MUTED)
	header.add_child(eyebrow)
	_title = Label.new()
	_title.text = "LEVEL %d REWARD" % RunState.run_level
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title, 30, Styles.AMBER)
	header.add_child(_title)

	var choice_center := CenterContainer.new()
	choice_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(choice_center)
	_choice_row = HBoxContainer.new()
	_choice_row.name = "UpgradeChoices"
	_choice_row.add_theme_constant_override("separation", 12)
	choice_center.add_child(_choice_row)
	for upgrade_id in RunState.get_pending_level_offer():
		_add_choice(upgrade_id)
	_wire_choice_focus()

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.text = "ONE UPGRADE  /  APPLIES IMMEDIATELY"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(0.0, 26.0)
	Styles.configure_label(_status_label, 13, Styles.TEXT_MUTED)
	_page.add_child(_status_label)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _add_choice(upgrade_id: StringName) -> void:
	var upgrade := RunState.get_micro_upgrade(upgrade_id)
	if upgrade == null:
		return
	var preview: Dictionary = RunState.preview_micro_upgrade(upgrade_id)
	var snapshot: Dictionary = RunState.get_run_snapshot().to_dictionary()
	var stacks: Dictionary = snapshot.get("micro_upgrades", {})
	var button := ChoiceCardScene.instantiate() as Button
	button.name = "Choice_%s" % upgrade_id
	_choice_row.add_child(button)
	button.call(
		"configure_choice",
		upgrade_id,
		ChoiceViewModel.for_level_upgrade(
			upgrade,
			preview,
			int(stacks.get(String(upgrade_id), 0)),
			RunState.current_health,
			RunState.max_health
		)
	)
	button.pressed.connect(func() -> void: _request_choice(upgrade_id, button))
	_choice_buttons.append(button)


func _request_choice(upgrade_id: StringName, selected: Button) -> void:
	for button in _choice_buttons:
		button.call("set_commit_pending", button == selected)
	choice_requested.emit(upgrade_id)


func _wire_choice_focus() -> void:
	if _choice_buttons.size() < 2:
		return
	for index in _choice_buttons.size():
		var button := _choice_buttons[index]
		button.focus_neighbor_left = button.get_path_to(
			_choice_buttons[(index - 1 + _choice_buttons.size()) % _choice_buttons.size()]
		)
		button.focus_neighbor_right = button.get_path_to(
			_choice_buttons[(index + 1) % _choice_buttons.size()]
		)


func _apply_responsive_layout() -> void:
	var compact := size.x <= 1000.0 or size.y <= 600.0
	var page_margin := 14 if compact else 28
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, page_margin)
	_title.add_theme_font_size_override("font_size", 26 if compact else 30)
	var page_size := Vector2(
		minf(size.x - float(page_margin * 2), 1260.0),
		minf(size.y - float(page_margin * 2), 580.0)
	)
	_page.custom_minimum_size = page_size
	_choice_row.custom_minimum_size = Vector2(
		page_size.x,
		clampf(page_size.y - 140.0, 320.0, 430.0)
	)
