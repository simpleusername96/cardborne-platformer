extends Control

signal heal_requested
signal consumable_requested(consumable_id: StringName)
signal forge_item_requested(item_id: StringName)
signal forge_affix_requested(item_id: StringName, affix_id: StringName, confirm_replace: bool)
signal leave_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _snapshot: Dictionary = {}
var _status_message: String = ""
var _status_ok: bool = true
var _pending_replace: Dictionary = {}
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	_render()


func configure(snapshot: Dictionary, result: Dictionary = {}) -> void:
	_snapshot = snapshot.duplicate(true)
	if not result.is_empty():
		_status_message = String(result.get("message", ""))
		_status_ok = bool(result.get("ok", false))
		if bool(result.get("requires_confirmation", false)):
			_pending_replace = {
				"item_id": String(result.get("item_id", "")),
				"affix_id": String(result.get("affix_id", "")),
			}
		elif bool(result.get("ok", false)):
			_pending_replace.clear()
	if is_node_ready():
		_render()


func _build_shell() -> void:
	add_child(BackdropScene.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	margin.add_child(_content)


func _render() -> void:
	if _content == null:
		return
	_clear(_content)
	_content.add_child(_build_header())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	body.add_child(_build_shop())
	body.add_child(VSeparator.new())
	body.add_child(_build_forge())
	_content.add_child(body)
	_content.add_child(_build_footer())


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 46.0)
	var title := Label.new()
	title.text = "REST & FORGE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(title, 27)
	header.add_child(title)
	var facts := Label.new()
	facts.text = "HP %d / %d    COINS %d" % [
		int(_snapshot.get("health", 0)),
		int(_snapshot.get("max_health", 0)),
		int(_snapshot.get("coins", 0)),
	]
	facts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(facts, 15, Styles.AMBER)
	header.add_child(facts)
	return header


func _build_shop() -> VBoxContainer:
	var shop := VBoxContainer.new()
	shop.custom_minimum_size = Vector2(360.0, 0.0)
	shop.add_theme_constant_override("separation", 9)
	shop.add_child(_heading("RECOVER"))
	var heal := Button.new()
	heal.name = "HealButton"
	heal.text = "Heal %d    %d coins" % [
		int(_snapshot.get("heal_amount", 2)), int(_snapshot.get("heal_cost", 8)),
	]
	heal.disabled = not bool(_snapshot.get("can_heal", false))
	heal.custom_minimum_size = Vector2(0.0, 44.0)
	Styles.apply_button(heal, Styles.MOSS)
	heal.pressed.connect(func() -> void: heal_requested.emit())
	shop.add_child(heal)
	shop.add_child(_heading("CONSUMABLE"))
	for row in _snapshot.get("consumables", []):
		var button := Button.new()
		button.text = "%s    %d coins" % [row["display_name"], int(row["cost"])]
		button.tooltip_text = String(row["description"])
		button.disabled = (
			bool(_snapshot.get("consumable_purchased", false))
			or int(_snapshot.get("coins", 0)) < int(row["cost"])
		)
		button.custom_minimum_size = Vector2(0.0, 42.0)
		Styles.apply_button(button, Styles.CYAN, true)
		var consumable_id := StringName(row["id"])
		button.pressed.connect(func() -> void: consumable_requested.emit(consumable_id))
		shop.add_child(button)
	var equipped := Label.new()
	equipped.text = "EQUIPPED  %s" % String(
		_snapshot.get("current_consumable_id", "small_potion")
	).replace("_", " ").to_upper()
	Styles.configure_label(equipped, 12, Styles.TEXT_MUTED)
	shop.add_child(equipped)
	return shop


func _build_forge() -> VBoxContainer:
	var forge := VBoxContainer.new()
	forge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forge.add_theme_constant_override("separation", 8)
	forge.add_child(_heading("FORGE ONE EQUIPPED ITEM    %d COINS" % int(_snapshot.get("forge_cost", 15))))
	var item_picker := OptionButton.new()
	item_picker.name = "ForgeItemPicker"
	item_picker.custom_minimum_size = Vector2(0.0, 42.0)
	Styles.apply_button(item_picker, Styles.AMBER, true)
	var selected_item_index := 0
	var item_rows: Array = _snapshot.get("items", [])
	for index in item_rows.size():
		var row: Dictionary = item_rows[index]
		var affix_text := "" if String(row.get("affix_id", "")).is_empty() else "  [%s]" % String(row["affix_id"]).trim_prefix("forge_").capitalize()
		item_picker.add_item("%s%s" % [row["display_name"], affix_text])
		item_picker.set_item_metadata(index, row)
		if String(row["id"]) == String(_snapshot.get("forge_item_id", "")):
			selected_item_index = index
	if item_rows.is_empty():
		item_picker.add_item("No equipped item")
		item_picker.disabled = true
	else:
		item_picker.select(selected_item_index)
		item_picker.item_selected.connect(func(index: int) -> void:
			var selected: Dictionary = item_picker.get_item_metadata(index)
			forge_item_requested.emit(StringName(selected["id"]))
		)
	forge.add_child(item_picker)

	var offer: Array = _snapshot.get("forge_offer", [])
	if offer.is_empty() and not item_rows.is_empty():
		var open_offer := Button.new()
		open_offer.text = "Inspect Affix Choices"
		open_offer.disabled = bool(_snapshot.get("forge_committed", false))
		open_offer.custom_minimum_size = Vector2(0.0, 44.0)
		Styles.apply_button(open_offer, Styles.AMBER)
		open_offer.pressed.connect(func() -> void:
			var selected: Dictionary = item_picker.get_item_metadata(item_picker.selected)
			forge_item_requested.emit(StringName(selected["id"]))
		)
		forge.add_child(open_offer)
	for row in offer:
		var affix := Button.new()
		affix.text = "%s\n%s" % [row["display_name"], row["description"]]
		affix.alignment = HORIZONTAL_ALIGNMENT_LEFT
		affix.custom_minimum_size = Vector2(0.0, 58.0)
		affix.disabled = (
			bool(_snapshot.get("forge_committed", false))
			or int(_snapshot.get("coins", 0)) < int(_snapshot.get("forge_cost", 15))
		)
		Styles.apply_button(affix, Styles.AMBER, true)
		var item_id := StringName(_snapshot.get("forge_item_id", ""))
		var affix_id := StringName(row["id"])
		affix.pressed.connect(func() -> void:
			forge_affix_requested.emit(item_id, affix_id, false)
		)
		forge.add_child(affix)
	if not _pending_replace.is_empty():
		var confirm := Button.new()
		confirm.text = "Confirm Affix Replacement"
		confirm.custom_minimum_size = Vector2(0.0, 44.0)
		Styles.apply_button(confirm, Styles.CORAL)
		confirm.pressed.connect(func() -> void:
			forge_affix_requested.emit(
				StringName(_pending_replace["item_id"]),
				StringName(_pending_replace["affix_id"]),
				true
			)
		)
		forge.add_child(confirm)
	return forge


func _build_footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0.0, 46.0)
	var status := Label.new()
	status.text = _status_message
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(status, 13, Styles.MOSS if _status_ok else Styles.CORAL)
	footer.add_child(status)
	var leave := Button.new()
	leave.name = "LeaveButton"
	leave.text = "Continue"
	leave.custom_minimum_size = Vector2(190.0, 44.0)
	Styles.apply_button(leave, Styles.AMBER)
	leave.pressed.connect(func() -> void: leave_requested.emit())
	footer.add_child(leave)
	return footer


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	Styles.configure_label(label, 13, Styles.TEXT_MUTED)
	return label


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
