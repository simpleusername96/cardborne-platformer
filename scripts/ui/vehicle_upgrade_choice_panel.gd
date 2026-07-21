class_name VehicleUpgradeChoicePanel
extends VBoxContainer

## Deliberate two-step upgrade selector. It presents catalog snapshots and emits
## intent only; applying or declining a reward remains the stage owner's job.

signal confirmed(upgrade_id: StringName)
signal declined
signal selected(upgrade_id: StringName)

const GUARD_SECONDS := 0.35

var _cards: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _selected_index := -1
var _guard_remaining := 0.0
var _pending := false
var _optional := false
var _decline_armed := false

var _detail: Label
var _message: Label
var _confirm: Button
var _decline: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()
	set_process(true)


func _build() -> void:
	var kicker := _label("UPGRADE_KICKER", 14, Color("d49b27"))
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(kicker)
	var title := _label("UPGRADE_TITLE", 28, Color("102e38"))
	title.custom_minimum_size.x = 800.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_detail = _label("UPGRADE_SELECT_DETAIL", 15, Color("315963"))
	_detail.custom_minimum_size.x = 800.0
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.custom_minimum_size.y = 44.0
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)

	var row := HBoxContainer.new()
	row.name = "UpgradeButtons"
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	for index in 3:
		var button := Button.new()
		button.name = "UpgradeCard%d" % (index + 1)
		button.custom_minimum_size = Vector2(272.0, 244.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
		button.focus_mode = Control.FOCUS_ALL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select.bind(index))
		row.add_child(button)
		_buttons.append(button)

	_message = _label("", 14, Color("7b2444"))
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size.y = 24.0
	add_child(_message)
	var commands := HBoxContainer.new()
	commands.add_theme_constant_override("separation", 12)
	add_child(commands)
	_decline = Button.new()
	_decline.custom_minimum_size = Vector2(210.0, 48.0)
	_decline.text = tr("UPGRADE_LEAVE_REWARD")
	_decline.pressed.connect(_request_decline)
	commands.add_child(_decline)
	_confirm = Button.new()
	_confirm.custom_minimum_size = Vector2(250.0, 48.0)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.text = tr("UPGRADE_EQUIP")
	_confirm.pressed.connect(_confirm_selected)
	commands.add_child(_confirm)


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
			var values := _value_preview_text(card.get("value_previews", []))
			button.text = "%s  ·  %s\n\n%s%s\n\n%s" % [
				tr(String(card["family_key"])),
				tr(String(card["title_key"])),
				tr(String(card["description_key"])),
				values,
				tr("UPGRADE_LEVEL_PREVIEW") % [int(card["current_level"]), int(card["next_level"]), int(card["max_level"])],
			]
			button.set_meta("upgrade_id", StringName(card["id"]))
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
	_detail.text = "%s  ·  %s" % [tr(String(card["title_key"])), tr(String(card["description_key"]))]
	if String(card.get("family_key", "")) == "UPGRADE_FAMILY_ELEMENT":
		_detail.text += "  ·  %s" % tr("UPGRADE_ELEMENT_LOCK_NOTICE")
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


func _value_preview_text(previews: Array) -> String:
	var lines: PackedStringArray = []
	for preview_variant in previews:
		var preview: Dictionary = preview_variant
		var operation := String(preview["operation"])
		var current := float(preview["current"])
		var next := float(preview["next"])
		var current_text := "×%.2f" % current if operation == "multiply" else "%+.0f" % current
		var next_text := "×%.2f" % next if operation == "multiply" else "%+.0f" % next
		lines.append("%s %s → %s" % [tr(String(preview["stat_key"])), current_text, next_text])
	return "\n" + "\n".join(lines) if not lines.is_empty() else ""


func _refresh_controls() -> void:
	var guarded := _guard_remaining > 0.0
	for index in _buttons.size():
		var button := _buttons[index]
		# Cards stay visually readable during the guard; selection handlers discard
		# carried input until the guard expires.
		button.disabled = _pending or not button.visible
		button.theme_type_variation = &"SelectedChoiceButton" if index == _selected_index else &"ChoiceButton"
	_confirm.disabled = guarded or _pending or _selected_index < 0
	_decline.disabled = guarded or _pending


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key) if not key.is_empty() else ""
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
