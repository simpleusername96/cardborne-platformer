extends Control

signal choice_requested(card_id: StringName)
signal reroll_requested
signal continue_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const ChoiceCardScene = preload(
	"res://scenes/ui/production/components/RewardChoiceCard.tscn"
)

var _page: VBoxContainer
var _margin: MarginContainer
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
var _offer_ids: Array[StringName] = []
var _offer_stacks: Dictionary = {}
var _last_commit_result: Dictionary = {}
var _commit_error_source := ""
var _committed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_offer()
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	call_deferred("_fit_page")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _page != null:
		_fit_page()


func refresh_offer() -> void:
	if _reroll_request_pending:
		_reroll_request_pending = false
		_reroll_used_locally = true
	_commit_error_source = ""
	_committed = false
	_last_commit_result.clear()
	_offer_ids = RunState.get_pending_card_offer()
	_offer_stacks.clear()
	for card_id in _offer_ids:
		_offer_stacks[String(card_id)] = RunState.get_card_stack(card_id)
	_rebuild_choice_buttons()

	var reroll_cost := RunState.get_card_reroll_cost()
	_eyebrow_label.text = _t("STAGE REWARD")
	_title_label.text = _t("CHOOSE A CARD")
	_balance_label.text = _t("%d COINS", [RunState.coins])
	_balance_label.visible = true
	_reroll_button.visible = true
	_reroll_button.disabled = not RunState.can_reroll_card_offer()
	_reroll_button.text = (
		_t("FREE REROLL") if reroll_cost <= 0 else _t("REROLL · %d COINS", [reroll_cost])
	)
	_continue_button.visible = false
	_status_label.text = _offer_status(reroll_cost)
	_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	_wire_choice_focus()
	call_deferred("_focus_first_choice")


func set_commit_error(message: String) -> void:
	_reroll_request_pending = false
	_commit_error_source = message
	_status_label.text = _error_copy(message)
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
	_committed = true
	_commit_error_source = ""
	_last_commit_result = result.duplicate(true)
	var committed_id := StringName(result.get("card_id", &""))
	for button in _choice_buttons:
		button.call(
			"mark_committed",
			StringName(button.get("choice_id")) == committed_id
		)
	_reroll_button.visible = false
	_balance_label.visible = false
	_eyebrow_label.text = _t("RUN BUILD UPDATED")
	_title_label.text = _t("CARD ADDED")
	_status_label.text = _t("%s is now stack %d.", [
		_t(result.get("display_name", "Card")),
		int(result.get("stack", 1)),
	])
	_status_label.add_theme_color_override("font_color", Styles.MOSS)
	_continue_button.visible = true
	_continue_button.disabled = false
	_continue_button.grab_focus()


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
	_eyebrow_label = Label.new()
	_eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_eyebrow_label, Styles.TYPE_CAPTION, Styles.AMBER)
	header.add_child(_eyebrow_label)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title_label, Styles.TYPE_TITLE, Styles.TEXT)
	header.add_child(_title_label)

	_choice_row = HBoxContainer.new()
	_choice_row.name = "CardChoices"
	_choice_row.add_theme_constant_override("separation", 12)
	_choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(_choice_row)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0.0, 30.0)
	Styles.configure_label(_status_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_page.add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	_page.add_child(actions)
	_balance_label = Label.new()
	_balance_label.custom_minimum_size = Vector2(130.0, Styles.TARGET_HEIGHT)
	_balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(_balance_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	actions.add_child(_balance_label)
	_reroll_button = Button.new()
	_reroll_button.name = "Reroll"
	_reroll_button.custom_minimum_size = Vector2(220.0, Styles.TARGET_HEIGHT)
	Styles.apply_button(_reroll_button, Styles.CYAN, true)
	_reroll_button.pressed.connect(_request_reroll)
	actions.add_child(_reroll_button)
	_continue_button = Button.new()
	_continue_button.name = "Continue"
	_continue_button.text = _t("Continue")
	_continue_button.custom_minimum_size = Vector2(190.0, Styles.TARGET_HEIGHT)
	Styles.apply_button(_continue_button, Styles.MOSS)
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	actions.add_child(_continue_button)


func _build_choice_button(card_id: StringName, current_stack: int) -> Button:
	var card := RunState.get_card_definition(card_id)
	var next_stack := current_stack + 1
	var button := ChoiceCardScene.instantiate() as Button
	button.name = "Choice_%s" % card_id
	var view := (
		ChoiceViewModel.for_card(card, current_stack, next_stack, self)
		if card != null
		else {
			"category": _t("RUN CARD"),
			"rarity": _t("UNAVAILABLE"),
			"glyph": &"card",
			"accent": Styles.CORAL,
			"title": _t("Unavailable Card"),
			"description": _t("Card data is unavailable."),
			"value": "",
			"footer": "",
			"action": _t("UNAVAILABLE"),
			"enabled": false,
		}
	)
	if card != null:
		var hero_id := StringName(
			RunState.get_hero_combat_loadout_snapshot().get("hero_id", "traveler")
		)
		view["enabled"] = (
			bool(view.get("enabled", false))
			and next_stack <= card.max_stacks
			and card.is_compatible(hero_id)
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
		return _t("Reroll used. Choose one card for the next stage.")
	if RunState.coins < reroll_cost:
		return _t(
			"Choose one card. Need %d more coins to reroll.",
			[reroll_cost - RunState.coins]
		)
	if not RunState.can_reroll_card_offer():
		return _t("Choose one card. No different complete offer is available.")
	return _t("Choose one card for the next stage, or reroll once.")


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
	_reroll_button.focus_neighbor_left = _reroll_button.get_path_to(
		_choice_buttons[_choice_buttons.size() - 1]
	)
	_reroll_button.focus_neighbor_right = _reroll_button.get_path_to(_choice_buttons[0])
	_continue_button.focus_neighbor_top = _continue_button.get_path_to(_continue_button)
	_continue_button.focus_neighbor_bottom = _continue_button.get_path_to(_continue_button)


func _focus_first_choice() -> void:
	if not _choice_buttons.is_empty() and not _choice_buttons[0].disabled:
		_choice_buttons[0].grab_focus()


func _fit_page() -> void:
	if _page == null:
		return
	var compact := size.x <= 1000.0 or size.y <= 600.0
	var page_margin := 12 if compact else 24
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, page_margin)
	_title_label.add_theme_font_size_override("font_size", 28 if compact else Styles.TYPE_TITLE)
	_page.custom_minimum_size = Vector2(
		minf(1180.0, maxf(size.x - float(page_margin * 2), 0.0)),
		minf(620.0, maxf(size.y - float(page_margin * 2), 0.0))
	)
	_choice_row.custom_minimum_size.y = clampf(
		_page.custom_minimum_size.y - 163.0,
		300.0,
		460.0
	)


func _rebuild_choice_buttons() -> void:
	_clear_choices()
	for card_id in _offer_ids:
		var current_stack := int(_offer_stacks.get(String(card_id), RunState.get_card_stack(card_id)))
		_choice_row.add_child(_build_choice_button(card_id, current_stack))
	_wire_choice_focus()


func _on_locale_changed(_locale: String) -> void:
	_rebuild_choice_buttons()
	_continue_button.text = _t("Continue")
	if _committed:
		show_commit_result(_last_commit_result)
		return
	var reroll_cost := RunState.get_card_reroll_cost()
	_eyebrow_label.text = _t("STAGE REWARD")
	_title_label.text = _t("CHOOSE A CARD")
	_balance_label.text = _t("%d COINS", [RunState.coins])
	_reroll_button.text = (
		_t("FREE REROLL") if reroll_cost <= 0 else _t("REROLL · %d COINS", [reroll_cost])
	)
	_status_label.text = (
		_error_copy(_commit_error_source)
		if not _commit_error_source.is_empty()
		else _offer_status(reroll_cost)
	)
	call_deferred("_focus_first_choice")


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)


func _error_copy(source: String) -> String:
	const REROLL_PREFIX := "Reroll needs "
	const REROLL_SUFFIX := " coins."
	if source.begins_with(REROLL_PREFIX) and source.ends_with(REROLL_SUFFIX):
		var amount_text := source.trim_prefix(REROLL_PREFIX).trim_suffix(REROLL_SUFFIX)
		return _t("Reroll needs %d coins.", [amount_text.to_int()])
	return _t(source)
