extends Control

signal choice_requested(upgrade_id: StringName)

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _choice_buttons: Array[Button] = []
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func set_commit_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Styles.CORAL)
	for button in _choice_buttons:
		button.disabled = false
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _build_ui() -> void:
	add_child(BackdropScene.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)

	var title := Label.new()
	title.text = "LEVEL %d  -  CHOOSE ONE" % RunState.run_level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(title, 30, Styles.AMBER)
	page.add_child(title)

	var choices := HBoxContainer.new()
	choices.name = "UpgradeChoices"
	choices.add_theme_constant_override("separation", 16)
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(choices)
	for upgrade_id in RunState.get_pending_level_offer():
		choices.add_child(_build_choice_button(upgrade_id))

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.text = "Select one upgrade to continue"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(0.0, 28.0)
	Styles.configure_label(_status_label, 14, Styles.TEXT_MUTED)
	page.add_child(_status_label)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _build_choice_button(upgrade_id: StringName) -> Button:
	var upgrade := RunState.get_micro_upgrade(upgrade_id)
	var preview: Dictionary = RunState.preview_micro_upgrade(upgrade_id)
	var button := Button.new()
	button.name = "Choice_%s" % upgrade_id
	button.text = "%s\n\n%s\n\n%s" % [
		upgrade.display_name.to_upper(),
		upgrade.description,
		_preview_text(preview),
	]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(250.0, 310.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Styles.apply_button(button, Styles.AMBER)
	button.pressed.connect(func() -> void: _request_choice(upgrade_id))
	_choice_buttons.append(button)
	return button


func _request_choice(upgrade_id: StringName) -> void:
	for button in _choice_buttons:
		button.disabled = true
	choice_requested.emit(upgrade_id)


func _preview_text(preview: Dictionary) -> String:
	var lines: Array[String] = []
	var changes: Dictionary = preview.get("changes", {})
	var stat_ids := changes.keys()
	stat_ids.sort()
	for stat_id in stat_ids:
		var values: Dictionary = changes[stat_id]
		lines.append("%s  %s -> %s" % [
			String(stat_id).replace("_", " ").capitalize(),
			_format_number(float(values["before"])),
			_format_number(float(values["after"])),
		])
	if int(preview.get("heal", 0)) > 0:
		lines.append("Heal now  +%d" % int(preview["heal"]))
	return "\n".join(lines)


func _format_number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, round(value)) else "%.2f" % value
