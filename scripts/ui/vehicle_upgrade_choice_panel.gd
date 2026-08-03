class_name VehicleUpgradeChoicePanel
extends VBoxContainer

## Deliberate two-step upgrade selector. It presents catalog snapshots and emits
## intent only; applying a mandatory reward remains the stage owner's job.

signal confirmed(upgrade_id: StringName)
signal selected(upgrade_id: StringName)

const GUARD_SECONDS := 0.35
const UpgradeChoiceCard = preload("res://scripts/ui/vehicle_upgrade_choice_card.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var _cards: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _selected_index := -1
var _guard_remaining := 0.0
var _pending := false
var _compact := false

var _row_scroll: ScrollContainer
var _row: HFlowContainer
var _message: Label
var _command_lane: CenterContainer
var _confirm: Button


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_build()
	set_process(true)


func _build() -> void:
	_row_scroll = ScrollContainer.new()
	_row_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_row_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_row_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_row_scroll)
	_row = HFlowContainer.new()
	_row.name = "UpgradeButtons"
	_row.add_theme_constant_override("h_separation", 18)
	_row.add_theme_constant_override("v_separation", 18)
	_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_row.last_wrap_alignment = FlowContainer.LAST_WRAP_ALIGNMENT_CENTER
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.custom_minimum_size.y = 330.0
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row_scroll.add_child(_row)
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
	_command_lane = CenterContainer.new()
	add_child(_command_lane)
	_confirm = Factory.command_button("UPGRADE_EQUIP", Factory.COMMAND_PRIMARY)
	_confirm.custom_minimum_size = Vector2(300.0, 48.0)
	Factory.apply_font_size(_confirm, 24)
	_confirm.pressed.connect(_confirm_selected)
	_command_lane.add_child(_confirm)


func set_compact_mode(value: bool) -> void:
	_compact = value
	add_theme_constant_override("separation", 5 if value else 8)
	if not is_node_ready():
		return
	_row.add_theme_constant_override("h_separation", 12 if value else 18)
	_row.add_theme_constant_override("v_separation", 12 if value else 18)
	_row.custom_minimum_size.y = 286.0 if value else 330.0
	_message.custom_minimum_size.y = 20.0 if value else 22.0
	Factory.apply_font_size(
		_message,
		int(Art.TYPE_SCALE_COMPACT[1] if value else Art.TYPE_SCALE_WIDE[1])
	)
	_confirm.custom_minimum_size = Vector2(260.0, 44.0) if value else Vector2(300.0, 48.0)
	Factory.apply_font_size(
		_confirm,
		int(Art.TYPE_SCALE_COMPACT[3] if value else Art.TYPE_SCALE_WIDE[3])
	)
	for button in _buttons:
		(button as VehicleUpgradeChoiceCard).set_compact_mode(value)


func set_accessibility_mode(enabled: bool) -> void:
	_row_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if enabled
		else ScrollContainer.SCROLL_MODE_DISABLED
	)
	if enabled:
		set_compact_mode(false)
	for button in _buttons:
		(button as VehicleUpgradeChoiceCard).set_accessibility_mode(enabled)
	_row.custom_minimum_size.y = 520.0 if enabled else (286.0 if _compact else 330.0)


func accessibility_preferred_size() -> Vector2:
	return Vector2(1200.0, 680.0)


func open(cards: Array[Dictionary]) -> void:
	_cards = cards.duplicate(true)
	_selected_index = -1
	_guard_remaining = GUARD_SECONDS
	_pending = false
	_message.text = ""
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
			_message.text = tr("UPGRADE_MANDATORY_NOTICE")
			get_viewport().set_input_as_handled()


func _select(index: int) -> void:
	if _guard_remaining > 0.0 or _pending or index < 0 or index >= _cards.size():
		return
	_selected_index = index
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


func debug_contract() -> Dictionary:
	var structured := true
	var card_contracts: Array[Dictionary] = []
	var offer_ids: Array[StringName] = []
	var state_variations: Array[StringName] = []
	var visible_card_count := 0
	for button in _buttons:
		if button is VehicleUpgradeChoiceCard:
			var card := button as VehicleUpgradeChoiceCard
			card_contracts.append(card.debug_contract())
			state_variations.append(card.theme_type_variation)
			if card.visible:
				visible_card_count += 1
				offer_ids.append(card.offer_id())
		else:
			structured = false
	return {
		"structured_cards":structured,
		"card_count":_buttons.size(),
		"confirm_size":_confirm.custom_minimum_size,
		"row_separation":_row.get_theme_constant("h_separation"),
		"row_type":_row.get_class(),
		"row_minimum_height":_row.custom_minimum_size.y,
		"guard_seconds":GUARD_SECONDS,
		"compact":_compact,
		"visible_card_count":visible_card_count,
		"offer_ids":offer_ids,
		"state_variations":state_variations,
		"selected_index":_selected_index,
		"pending":_pending,
		"confirm_disabled":_confirm.disabled,
		"message_text":_message.text,
		"command_count":_command_lane.find_children(
			"*", "Button", true, false
		).size(),
		"exit_action_count":0,
		"header_text_count":0,
		"type_sizes":{
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
		"row_scroll_rect":_row_scroll.get_global_rect(),
		"horizontal_scroll_visible":_row_scroll.get_h_scroll_bar().visible,
		"vertical_scroll_visible":_row_scroll.get_v_scroll_bar().visible,
		"command_rect":_command_lane.get_global_rect(),
		"cards":card_contracts,
		"message_rect":_message.get_global_rect(),
		"message_lines":_message.get_line_count(),
		"message_visible_lines":_message.get_visible_line_count(),
	}


func _label(key: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key) if not key.is_empty() else ""
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Factory.apply_font_size(label, size)
	label.add_theme_color_override("font_color", color)
	return label
