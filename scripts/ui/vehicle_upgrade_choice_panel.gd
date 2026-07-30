class_name VehicleUpgradeChoicePanel
extends VBoxContainer

## Deliberate two-step upgrade selector. It presents catalog snapshots and emits
## intent only; applying or declining a reward remains the stage owner's job.

signal confirmed(upgrade_id: StringName)
signal declined
signal selected(upgrade_id: StringName)

const GUARD_SECONDS := 0.35
const UpgradeChoiceCard = preload("res://scripts/ui/vehicle_upgrade_choice_card.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _cards: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _selected_index := -1
var _guard_remaining := 0.0
var _pending := false
var _optional := false
var _decline_armed := false
var _compact := false

var _kicker: Label
var _title: Label
var _detail: Label
var _row: HBoxContainer
var _message: Label
var _commands: HBoxContainer
var _confirm: Button
var _decline: Button


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_build()
	set_process(true)


func _build() -> void:
	_kicker = _label("UPGRADE_KICKER", 16, Color("d49b27"))
	_kicker.theme_type_variation = &"MetricLabel"
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_kicker)
	_title = _label("UPGRADE_TITLE", 40, Color("f1e6be"))
	_title.theme_type_variation = &"DisplayLabel"
	_title.custom_minimum_size.x = 900.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_detail = _label("UPGRADE_SELECT_DETAIL", 18, Color("b7c7c2"))
	_detail.custom_minimum_size.x = 900.0
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.custom_minimum_size.y = 34.0
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)

	_row = HBoxContainer.new()
	_row.name = "UpgradeButtons"
	_row.add_theme_constant_override("separation", 18)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.custom_minimum_size.y = 330.0
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_row)
	for index in 3:
		var button := UpgradeChoiceCard.new()
		button.name = "UpgradeCard%d" % (index + 1)
		button.pressed.connect(_select.bind(index))
		_row.add_child(button)
		_buttons.append(button)

	_message = _label("", 16, Art.DANGER)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size.y = 20.0
	add_child(_message)
	_commands = HBoxContainer.new()
	_commands.add_theme_constant_override("separation", 12)
	_commands.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_commands)
	_decline = Button.new()
	_decline.custom_minimum_size = Vector2(210.0, 48.0)
	_decline.theme_type_variation = &"SecondaryButton"
	_decline.text = tr("UPGRADE_LEAVE_REWARD")
	_decline.add_theme_font_size_override("font_size", 18)
	_decline.pressed.connect(_request_decline)
	_commands.add_child(_decline)
	_confirm = Button.new()
	_confirm.custom_minimum_size = Vector2(300.0, 48.0)
	_confirm.theme_type_variation = &"PrimaryButton"
	_confirm.text = tr("UPGRADE_EQUIP")
	_confirm.add_theme_font_size_override("font_size", 24)
	_confirm.pressed.connect(_confirm_selected)
	_commands.add_child(_confirm)


func set_compact_mode(value: bool) -> void:
	_compact = value
	add_theme_constant_override("separation", 5 if value else 8)
	if not is_node_ready():
		return
	_kicker.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[1] if value else Art.TYPE_SCALE_WIDE[1])
	)
	_title.custom_minimum_size.x = 0.0 if value else 900.0
	_title.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[4] if value else Art.TYPE_SCALE_WIDE[5])
	)
	_detail.custom_minimum_size.x = 0.0 if value else 900.0
	_detail.custom_minimum_size.y = 30.0 if value else 34.0
	_detail.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[1] if value else Art.TYPE_SCALE_WIDE[2])
	)
	_row.add_theme_constant_override("separation", 12 if value else 18)
	_row.custom_minimum_size.y = 286.0 if value else 330.0
	_message.custom_minimum_size.y = 20.0 if value else 22.0
	_message.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[1] if value else Art.TYPE_SCALE_WIDE[1])
	)
	_decline.custom_minimum_size = Vector2(190.0, 44.0) if value else Vector2(210.0, 48.0)
	_decline.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[2] if value else Art.TYPE_SCALE_WIDE[2])
	)
	_confirm.custom_minimum_size = Vector2(260.0, 44.0) if value else Vector2(300.0, 48.0)
	_confirm.add_theme_font_size_override(
		"font_size",
		int(Art.TYPE_SCALE_COMPACT[3] if value else Art.TYPE_SCALE_WIDE[3])
	)
	for button in _buttons:
		(button as VehicleUpgradeChoiceCard).set_compact_mode(value)


func open(cards: Array[Dictionary], optional: bool) -> void:
	_cards = cards.duplicate(true)
	_optional = optional
	_selected_index = -1
	_guard_remaining = GUARD_SECONDS
	_pending = false
	_decline_armed = false
	_message.text = ""
	_decline.visible = optional
	_decline.text = tr("UPGRADE_LEAVE_REWARD")
	_detail.text = tr("UPGRADE_SELECT_DETAIL")
	for index in _buttons.size():
		var button := _buttons[index]
		button.visible = index < _cards.size()
		button.disabled = true
		if button.visible:
			var card: Dictionary = _cards[index]
			(button as VehicleUpgradeChoiceCard).set_offer(card)
			(button as VehicleUpgradeChoiceCard).set_selected_state(false)
	_refresh_controls()


func _process(delta: float) -> void:
	if _guard_remaining <= 0.0:
		return
	_guard_remaining = maxf(0.0, _guard_remaining - delta)
	if _guard_remaining <= 0.0:
		_refresh_controls()
		for button in _buttons:
			if button.visible:
				button.grab_focus()
				break


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _guard_remaining > 0.0 or _pending:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode >= KEY_1 and key.keycode <= KEY_3:
			_select(int(key.keycode - KEY_1))
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_ESCAPE:
			_message.text = tr("UPGRADE_MANDATORY_NOTICE") if not _optional else tr("UPGRADE_OPTIONAL_NOTICE")
			get_viewport().set_input_as_handled()


func _select(index: int) -> void:
	if _guard_remaining > 0.0 or _pending or index < 0 or index >= _cards.size():
		return
	_selected_index = index
	_decline_armed = false
	_decline.text = tr("UPGRADE_LEAVE_REWARD")
	var card: Dictionary = _cards[index]
	_message.text = ""
	_refresh_controls()
	selected.emit(StringName(card["id"]))


func _confirm_selected() -> void:
	if _guard_remaining > 0.0 or _pending or _selected_index < 0:
		return
	_pending = true
	_refresh_controls()
	confirmed.emit(StringName(_cards[_selected_index]["id"]))


func _request_decline() -> void:
	if not _optional or _guard_remaining > 0.0 or _pending:
		return
	if not _decline_armed:
		_decline_armed = true
		_decline.text = tr("UPGRADE_CONFIRM_LEAVE")
		_message.text = tr("UPGRADE_OPTIONAL_NOTICE")
		return
	_pending = true
	_refresh_controls()
	declined.emit()


func apply_failed(reason: String) -> void:
	_pending = false
	_message.text = reason
	_refresh_controls()


func buttons() -> Array[Button]:
	return _buttons


func _refresh_controls() -> void:
	var guarded := _guard_remaining > 0.0
	for index in _buttons.size():
		var button := _buttons[index]
		# Cards stay visually readable during the guard; selection handlers discard
		# carried input until the guard expires.
		button.disabled = _pending or not button.visible
		(button as VehicleUpgradeChoiceCard).set_selected_state(index == _selected_index)
	_confirm.disabled = guarded or _pending or _selected_index < 0
	_decline.disabled = guarded or _pending


func debug_contract() -> Dictionary:
	var structured := true
	var card_contracts: Array[Dictionary] = []
	for button in _buttons:
		if button is VehicleUpgradeChoiceCard:
			card_contracts.append((button as VehicleUpgradeChoiceCard).debug_contract())
		else:
			structured = false
	return {
		"structured_cards":structured,
		"card_count":_buttons.size(),
		"confirm_size":_confirm.custom_minimum_size,
		"row_separation":_row.get_theme_constant("separation"),
		"row_minimum_height":_row.custom_minimum_size.y,
		"guard_seconds":GUARD_SECONDS,
		"compact":_compact,
		"type_sizes":{
			"kicker":_kicker.get_theme_font_size("font_size"),
			"title":_title.get_theme_font_size("font_size"),
			"detail":_detail.get_theme_font_size("font_size"),
			"message":_message.get_theme_font_size("font_size"),
			"confirm":_confirm.get_theme_font_size("font_size"),
		},
		"message_color":_message.get_theme_color("font_color"),
		"cards":card_contracts,
	}


func debug_geometry_contract() -> Dictionary:
	var card_contracts: Array[Dictionary] = []
	for button in _buttons:
		if button.visible:
			card_contracts.append(
				(button as VehicleUpgradeChoiceCard).debug_geometry_contract()
			)
	return {
		"rect":get_global_rect(),
		"row_rect":_row.get_global_rect(),
		"command_rect":_commands.get_global_rect(),
		"cards":card_contracts,
		"detail_rect":_detail.get_global_rect(),
		"detail_lines":_detail.get_line_count(),
		"detail_visible_lines":_detail.get_visible_line_count(),
		"message_rect":_message.get_global_rect(),
		"message_lines":_message.get_line_count(),
		"message_visible_lines":_message.get_visible_line_count(),
	}


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key) if not key.is_empty() else ""
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
