extends Control

signal choice_requested(card_id: StringName)
signal reroll_requested
signal continue_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _choice_row: HBoxContainer
var _choice_buttons: Array[Button] = []
var _status_label: Label
var _reroll_button: Button
var _continue_button: Button
var _title_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_offer()


func refresh_offer() -> void:
	_clear_choices()
	_title_label.text = "CHOOSE A CARD"
	for card_id in RunState.get_pending_card_offer():
		_choice_row.add_child(_build_choice_button(card_id))
	_reroll_button.visible = true
	_reroll_button.disabled = not RunState.can_reroll_card_offer()
	_reroll_button.text = "REROLL  %d COINS   (YOU HAVE %d)" % [
		RunState.CARD_REROLL_COST,
		RunState.coins,
	]
	_continue_button.visible = false
	_status_label.text = "Choose one card. The change applies in the next stage."
	_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func set_commit_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Styles.CORAL)
	for button in _choice_buttons:
		button.disabled = false
	_reroll_button.disabled = not RunState.can_reroll_card_offer()
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func show_commit_result(result: Dictionary) -> void:
	for button in _choice_buttons:
		button.disabled = true
	_reroll_button.visible = false
	_title_label.text = "CARD ADDED"
	_status_label.text = "%s  -  Stack %d" % [
		str(result.get("display_name", "Card")),
		int(result.get("stack", 1)),
	]
	_status_label.add_theme_color_override("font_color", Styles.MOSS)
	_continue_button.visible = true
	_continue_button.grab_focus()


func _build_ui() -> void:
	add_child(BackdropScene.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title_label, 30, Styles.AMBER)
	page.add_child(_title_label)

	_choice_row = HBoxContainer.new()
	_choice_row.name = "CardChoices"
	_choice_row.add_theme_constant_override("separation", 16)
	_choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_choice_row)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(0.0, 26.0)
	Styles.configure_label(_status_label, 14, Styles.TEXT_MUTED)
	page.add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	page.add_child(actions)
	_reroll_button = Button.new()
	_reroll_button.name = "Reroll"
	_reroll_button.custom_minimum_size = Vector2(280.0, 44.0)
	Styles.apply_button(_reroll_button, Styles.CYAN)
	_reroll_button.pressed.connect(_request_reroll)
	actions.add_child(_reroll_button)
	_continue_button = Button.new()
	_continue_button.name = "Continue"
	_continue_button.text = "CONTINUE"
	_continue_button.custom_minimum_size = Vector2(220.0, 44.0)
	Styles.apply_button(_continue_button, Styles.MOSS)
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	actions.add_child(_continue_button)


func _build_choice_button(card_id: StringName) -> Button:
	var card := RunState.get_card_definition(card_id)
	var next_stack := RunState.get_card_stack(card_id) + 1
	var button := Button.new()
	button.name = "Choice_%s" % card_id
	button.text = "%s\n%s\n\n%s\n\nSTACK %d / %d" % [
		card.display_name.to_upper(),
		String(card.rarity).to_upper(),
		card.description,
		next_stack,
		card.max_stacks,
	]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(230.0, 270.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Styles.apply_button(button, _rarity_color(card.rarity))
	button.pressed.connect(func() -> void: _request_choice(card_id))
	_choice_buttons.append(button)
	return button


func _request_choice(card_id: StringName) -> void:
	_disable_actions()
	choice_requested.emit(card_id)


func _request_reroll() -> void:
	_disable_actions()
	reroll_requested.emit()


func _disable_actions() -> void:
	for button in _choice_buttons:
		button.disabled = true
	_reroll_button.disabled = true


func _clear_choices() -> void:
	_choice_buttons.clear()
	if _choice_row == null:
		return
	for child in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()


func _rarity_color(rarity: StringName) -> Color:
	match rarity:
		&"legendary":
			return Styles.AMBER
		&"rare":
			return Styles.CYAN
	return Styles.MOSS
