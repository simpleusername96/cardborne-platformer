extends Control

signal choice_requested(card_id: StringName)
signal reroll_requested
signal continue_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const ChoiceCardScene = preload(
	"res://scenes/ui/production/components/RewardChoiceCard.tscn"
)

var _page: VBoxContainer
var _choice_row: HBoxContainer
var _choice_buttons: Array[Button] = []
var _status_label: Label
var _balance_label: Label
var _reroll_button: Button
var _continue_button: Button
var _title_label: Label
var _eyebrow_label: Label
var _reroll_request_pending := false
var _reroll_used_locally := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_offer()
	call_deferred("_fit_page")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _page != null:
		_fit_page()


func refresh_offer() -> void:
	if _reroll_request_pending:
		_reroll_request_pending = false
		_reroll_used_locally = true
	_clear_choices()
	_eyebrow_label.text = "STAGE REWARD"
	_title_label.text = "CHOOSE A CARD"
	for card_id in RunState.get_pending_card_offer():
		var button := _build_choice_button(card_id)
		_choice_row.add_child(button)

	var reroll_cost := RunState.get_card_reroll_cost()
	_balance_label.text = "%d COINS" % RunState.coins
	_reroll_button.visible = true
	_reroll_button.disabled = not RunState.can_reroll_card_offer()
	_reroll_button.text = (
		"FREE REROLL" if reroll_cost <= 0 else "REROLL  -%d COINS" % reroll_cost
	)
	_continue_button.visible = false
	_status_label.text = _offer_status(reroll_cost)
	_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	_wire_choice_focus()
	call_deferred("_focus_first_choice")


func set_commit_error(message: String) -> void:
	_reroll_request_pending = false
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Styles.CORAL)
	if _continue_button.visible:
		_continue_button.disabled = false
		_continue_button.grab_focus()
		return
	for button in _choice_buttons:
		button.call("restore_interaction")
	_reroll_button.disabled = not RunState.can_reroll_card_offer()
	_focus_first_choice()


func show_commit_result(result: Dictionary) -> void:
	var committed_id := StringName(result.get("card_id", &""))
	for button in _choice_buttons:
		button.call(
			"mark_committed",
			StringName(button.get("choice_id")) == committed_id
		)
	_reroll_button.visible = false
	_balance_label.visible = false
	_eyebrow_label.text = "RUN BUILD UPDATED"
	_title_label.text = "CARD ADDED"
	_status_label.text = "%s is now stack %d." % [
		str(result.get("display_name", "Card")),
		int(result.get("stack", 1)),
	]
	_status_label.add_theme_color_override("font_color", Styles.MOSS)
	_continue_button.visible = true
	_continue_button.disabled = false
	_continue_button.grab_focus()


func _build_ui() -> void:
	add_child(BackdropScene.new())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_page = VBoxContainer.new()
	_page.name = "RewardPage"
	_page.add_theme_constant_override("separation", 10)
	center.add_child(_page)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	_page.add_child(header)
	_eyebrow_label = Label.new()
	_eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_eyebrow_label, 12, Styles.AMBER)
	header.add_child(_eyebrow_label)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title_label, 28, Styles.TEXT)
	header.add_child(_title_label)

	_choice_row = HBoxContainer.new()
	_choice_row.name = "CardChoices"
	_choice_row.add_theme_constant_override("separation", 12)
	_choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(_choice_row)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(0.0, 22.0)
	Styles.configure_label(_status_label, 13, Styles.TEXT_MUTED)
	_page.add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	_page.add_child(actions)
	_balance_label = Label.new()
	_balance_label.custom_minimum_size = Vector2(100.0, 40.0)
	_balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(_balance_label, 13, Styles.TEXT_MUTED)
	actions.add_child(_balance_label)
	_reroll_button = Button.new()
	_reroll_button.name = "Reroll"
	_reroll_button.custom_minimum_size = Vector2(190.0, 40.0)
	Styles.apply_button(_reroll_button, Styles.CYAN, true)
	_reroll_button.pressed.connect(_request_reroll)
	actions.add_child(_reroll_button)
	_continue_button = Button.new()
	_continue_button.name = "Continue"
	_continue_button.text = "CONTINUE"
	_continue_button.custom_minimum_size = Vector2(180.0, 40.0)
	Styles.apply_button(_continue_button, Styles.MOSS)
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	actions.add_child(_continue_button)


func _build_choice_button(card_id: StringName) -> Button:
	var card := RunState.get_card_definition(card_id)
	var current_stack := RunState.get_card_stack(card_id)
	var next_stack := current_stack + 1
	var button := ChoiceCardScene.instantiate() as Button
	button.name = "Choice_%s" % card_id
	var view := (
		ChoiceViewModel.for_card(card, current_stack, next_stack)
		if card != null
		else {
			"category": "CARD",
			"rarity": "UNAVAILABLE",
			"glyph": &"card",
			"accent": Styles.CORAL,
			"title": "Unavailable Card",
			"description": "Card data is unavailable.",
			"value": "",
			"footer": "",
			"action": "UNAVAILABLE",
			"enabled": false,
		}
	)
	if card != null:
		view["enabled"] = (
			next_stack <= card.max_stacks
			and card.is_compatible(StringName(RunState.selected_profile.id))
		)
	button.call("configure_choice", card_id, view)
	button.pressed.connect(func() -> void: _request_choice(card_id))
	_choice_buttons.append(button)
	return button


func _request_choice(card_id: StringName) -> void:
	_disable_actions(card_id)
	choice_requested.emit(card_id)


func _request_reroll() -> void:
	_reroll_request_pending = true
	_disable_actions()
	reroll_requested.emit()


func _disable_actions(selected_id: StringName = &"") -> void:
	for button in _choice_buttons:
		button.call(
			"set_commit_pending",
			selected_id != &"" and StringName(button.get("choice_id")) == selected_id
		)
	_reroll_button.disabled = true
	_continue_button.disabled = true


func _clear_choices() -> void:
	_choice_buttons.clear()
	if _choice_row == null:
		return
	for child in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()


func _offer_status(reroll_cost: int) -> String:
	if _reroll_used_locally:
		return "Reroll used. Choose one card for the next stage."
	if RunState.coins < reroll_cost:
		return "Choose one card. Need %d more coins to reroll." % (reroll_cost - RunState.coins)
	if not RunState.can_reroll_card_offer():
		return "Choose one card. No different complete offer is available."
	return "Choose one card for the next stage, or reroll once."


func _wire_choice_focus() -> void:
	if _choice_buttons.is_empty():
		return
	for index in _choice_buttons.size():
		var button := _choice_buttons[index]
		var left := _choice_buttons[(index - 1 + _choice_buttons.size()) % _choice_buttons.size()]
		var right := _choice_buttons[(index + 1) % _choice_buttons.size()]
		button.focus_neighbor_left = button.get_path_to(left)
		button.focus_neighbor_right = button.get_path_to(right)
		button.focus_neighbor_bottom = button.get_path_to(_reroll_button)
	_reroll_button.focus_neighbor_top = _reroll_button.get_path_to(_choice_buttons[0])


func _focus_first_choice() -> void:
	if not _choice_buttons.is_empty() and not _choice_buttons[0].disabled:
		_choice_buttons[0].grab_focus()


func _fit_page() -> void:
	if _page == null:
		return
	_page.custom_minimum_size = Vector2(
		minf(1120.0, maxf(size.x - 40.0, 0.0)),
		minf(700.0, maxf(size.y - 40.0, 0.0))
	)
