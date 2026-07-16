extends Control

signal choice_requested(upgrade_id: StringName)

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")
const ChoiceCardScene = preload(
	"res://scenes/ui/production/components/RewardChoiceCard.tscn"
)

var _choice_buttons: Array[Button] = []
var _choice_row: HBoxContainer
var _margin: MarginContainer
var _page: VBoxContainer
var _status_label: Label
var _title: Label
var _eyebrow: Label
var _commit_error_source := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Styles.apply_theme(self)
	_build_ui()
	_apply_responsive_layout()
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _margin != null:
		_apply_responsive_layout()


func set_commit_error(message: String) -> void:
	_commit_error_source = message
	_status_label.text = _t(message)
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
	_page.name = "RewardPage"
	_page.add_theme_constant_override("separation", 8)
	center.add_child(_page)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	_page.add_child(header)
	_eyebrow = Label.new()
	_eyebrow.name = "Eyebrow"
	_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_eyebrow, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	header.add_child(_eyebrow)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title, Styles.TYPE_TITLE, Styles.AMBER)
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
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0.0, 30.0)
	Styles.configure_label(_status_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_page.add_child(_status_label)
	_set_static_copy()
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
			RunState.max_health,
			self
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
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)


func _apply_responsive_layout() -> void:
	var compact := size.x <= 1000.0 or size.y <= 600.0
	var page_margin := 12 if compact else 24
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, page_margin)
	_title.add_theme_font_size_override("font_size", 28 if compact else Styles.TYPE_TITLE)
	var page_size := Vector2(
		minf(size.x - float(page_margin * 2), 1260.0),
		minf(size.y - float(page_margin * 2), 620.0)
	)
	_page.custom_minimum_size = page_size
	_choice_row.custom_minimum_size = Vector2(
		page_size.x,
		clampf(page_size.y - 105.0, 300.0, 515.0)
	)


func _set_static_copy() -> void:
	_eyebrow.text = _t("RUN LEVEL")
	_title.text = _t("LEVEL %d REWARD", [RunState.run_level])
	if _commit_error_source.is_empty():
		_status_label.text = _t("ONE UPGRADE · APPLIES IMMEDIATELY")
		_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	else:
		_status_label.text = _t(_commit_error_source)


func _rebuild_choices() -> void:
	_choice_buttons.clear()
	for child in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()
	for upgrade_id in RunState.get_pending_level_offer():
		_add_choice(upgrade_id)
	_wire_choice_focus()
	call_deferred("_focus_first_choice")


func _focus_first_choice() -> void:
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _on_locale_changed(_locale: String) -> void:
	_set_static_copy()
	_rebuild_choices()


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)
