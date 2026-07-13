extends Control

signal heal_requested
signal consumable_requested(consumable_id: StringName)
signal forge_item_requested(item_id: StringName)
signal forge_affix_requested(item_id: StringName, affix_id: StringName, confirm_replace: bool)
signal leave_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const EquipmentDecisionPanelScene = preload(
	"res://scenes/ui/production/components/EquipmentDecisionPanel.tscn"
)
const ForgeAffixChoiceScene = preload(
	"res://scenes/ui/production/components/ForgeAffixChoice.tscn"
)
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var _snapshot: Dictionary = {}
var _status_message: String = ""
var _status_ok: bool = true
var _pending_replace: Dictionary = {}
var _content: VBoxContainer
var _compact_layout: bool = false
var _focus_targets: Array[BaseButton] = []
var _previous_focus_name: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compact_layout = get_viewport_rect().size.y <= 600.0
	_build_shell()
	_render()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	var compact := get_viewport_rect().size.y <= 600.0
	if compact == _compact_layout:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	var focus_name: String = (
		String(focus_owner.name)
		if focus_owner != null and is_ancestor_of(focus_owner)
		else ""
	)
	_compact_layout = compact
	_content = null
	_focus_targets.clear()
	_clear(self)
	_build_shell()
	_render()
	_previous_focus_name = focus_name


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
		margin.add_theme_constant_override("margin_%s" % side, 16 if _compact_layout else 22)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10 if _compact_layout else 16)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 7 if _compact_layout else 12)
	margin.add_child(_content)


func _render() -> void:
	if _content == null:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	_previous_focus_name = focus_owner.name if focus_owner != null else ""
	_focus_targets.clear()
	_clear(_content)
	_content.add_child(_build_header())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16 if _compact_layout else 24)
	body.add_child(_build_shop())
	body.add_child(VSeparator.new())
	body.add_child(_build_forge())
	_content.add_child(body)
	_content.add_child(_build_footer())
	call_deferred("_restore_focus")


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 38.0 if _compact_layout else 46.0)
	var title := Label.new()
	title.text = "REST & FORGE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(title, 22 if _compact_layout else 27)
	header.add_child(title)
	var facts := Label.new()
	facts.text = "HP %d / %d    COINS %d" % [
		int(_snapshot.get("health", 0)),
		int(_snapshot.get("max_health", 0)),
		int(_snapshot.get("coins", 0)),
	]
	facts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(facts, 13 if _compact_layout else 15, Styles.AMBER)
	header.add_child(facts)
	return header


func _build_shop() -> VBoxContainer:
	var shop := VBoxContainer.new()
	shop.custom_minimum_size = Vector2(250.0 if _compact_layout else 330.0, 0.0)
	shop.add_theme_constant_override("separation", 6 if _compact_layout else 9)
	shop.add_child(_heading("RECOVER"))
	var heal := Button.new()
	heal.name = "HealButton"
	heal.text = "Heal %d    %d coins" % [
		int(_snapshot.get("heal_amount", 2)), int(_snapshot.get("heal_cost", 8)),
	]
	heal.disabled = not bool(_snapshot.get("can_heal", false))
	heal.custom_minimum_size = Vector2(0.0, 38.0 if _compact_layout else 44.0)
	Styles.apply_button(heal, Styles.MOSS)
	heal.pressed.connect(func() -> void: heal_requested.emit())
	shop.add_child(heal)
	_focus_targets.append(heal)
	shop.add_child(_heading("CONSUMABLE"))
	for row in _snapshot.get("consumables", []):
		var button := Button.new()
		button.text = "%s    %d coins" % [row["display_name"], int(row["cost"])]
		button.tooltip_text = String(row["description"])
		button.disabled = (
			bool(_snapshot.get("consumable_purchased", false))
			or int(_snapshot.get("coins", 0)) < int(row["cost"])
		)
		button.custom_minimum_size = Vector2(0.0, 38.0 if _compact_layout else 42.0)
		Styles.apply_button(button, Styles.CYAN, true)
		var consumable_id := StringName(row["id"])
		button.pressed.connect(func() -> void: consumable_requested.emit(consumable_id))
		shop.add_child(button)
		_focus_targets.append(button)
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
	forge.add_theme_constant_override("separation", 6 if _compact_layout else 8)
	forge.add_child(_heading("FORGE ONE EQUIPPED ITEM    %d COINS" % int(
		_snapshot.get("forge_cost", 15)
	)))

	var item_picker := OptionButton.new()
	item_picker.name = "ForgeItemPicker"
	item_picker.custom_minimum_size = Vector2(0.0, 38.0 if _compact_layout else 42.0)
	Styles.apply_button(item_picker, Styles.AMBER, true)
	var selected_item_index := 0
	var item_rows: Array = _snapshot.get("items", [])
	for index in item_rows.size():
		var row: Dictionary = item_rows[index]
		var affix_name := String(row.get("affix_name", ""))
		var affix_text := "" if affix_name.is_empty() else "  [THIS RUN: %s]" % affix_name
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
	_focus_targets.append(item_picker)

	var comparison_row := HBoxContainer.new()
	comparison_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	comparison_row.add_theme_constant_override("separation", 10 if _compact_layout else 14)
	forge.add_child(comparison_row)

	var selected_item: Dictionary = {}
	if not item_rows.is_empty():
		selected_item = item_rows[selected_item_index]
	var item_detail := EquipmentDecisionPanelScene.instantiate() as Control
	item_detail.name = "ForgeEquipmentDetail"
	item_detail.custom_minimum_size.x = 238.0 if _compact_layout else 300.0
	item_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_detail.size_flags_stretch_ratio = 0.9
	item_detail.call("configure", _forge_item_detail_data(selected_item), _compact_layout)
	comparison_row.add_child(item_detail)

	comparison_row.add_child(VSeparator.new())
	var offers_column := VBoxContainer.new()
	offers_column.name = "ForgeOffers"
	offers_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offers_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	offers_column.size_flags_stretch_ratio = 1.25
	offers_column.add_theme_constant_override("separation", 5 if _compact_layout else 7)
	comparison_row.add_child(offers_column)

	var offer: Array = _snapshot.get("forge_offer", [])
	if offer.is_empty() and not item_rows.is_empty():
		var open_offer := Button.new()
		open_offer.name = "InspectAffixesButton"
		open_offer.text = "Review 3 Run Affixes"
		open_offer.disabled = bool(_snapshot.get("forge_committed", false))
		open_offer.custom_minimum_size = Vector2(0.0, 42.0)
		Styles.apply_button(open_offer, Styles.AMBER)
		open_offer.pressed.connect(func() -> void:
			var selected: Dictionary = item_picker.get_item_metadata(item_picker.selected)
			forge_item_requested.emit(StringName(selected["id"]))
		)
		offers_column.add_child(open_offer)
		_focus_targets.append(open_offer)
	for row in offer:
		var affix := ForgeAffixChoiceScene.instantiate() as BaseButton
		affix.name = "Affix_%s" % String(row.get("id", "unknown"))
		var item_id := StringName(_snapshot.get("forge_item_id", ""))
		affix.call("configure", row, int(_snapshot.get("coins", 0)), _forge_disabled_reason(row), _compact_layout)
		affix.connect("affix_chosen", func(affix_id: StringName) -> void:
			forge_affix_requested.emit(item_id, affix_id, false)
		)
		offers_column.add_child(affix)
		_focus_targets.append(affix)
	return forge


func _forge_item_detail_data(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {
			"context_text": "EQUIPPED ITEM",
			"state_text": "UNAVAILABLE",
			"title": "No equipped item",
			"description": "Forge requires an equipped item.",
			"empty_mechanics_text": "No forge baseline is available.",
		}
	var affix_name := String(item.get("affix_name", ""))
	var affix_description := String(item.get("affix_description", ""))
	var affix_text := "CURRENT AFFIX (THIS RUN)  None"
	if not affix_name.is_empty():
		affix_text = "CURRENT AFFIX (THIS RUN)  %s - %s" % [
			affix_name,
			affix_description,
		]
	return {
		"context_text": "%s | PERMANENT BASE" % String(item.get("slot", "item")).to_upper(),
		"state_text": "EQUIPPED",
		"title": String(item.get("display_name", "Unknown item")),
		"description": String(item.get("description", "")),
		"tradeoff": String(item.get("tradeoff", "")),
		"affix_text": affix_text,
		"effect_lines": item.get("base_effects", []),
		"empty_mechanics_text": "No numeric base effect.",
	}


func _forge_disabled_reason(row: Dictionary) -> String:
	if not (row.get("validation_errors", []) as Array).is_empty():
		return "INVALID BUILD"
	if bool(_snapshot.get("forge_committed", false)):
		return "FORGE ALREADY USED"
	var cost := int(_snapshot.get("forge_cost", 15))
	if int(_snapshot.get("coins", 0)) < cost:
		return "NEED %d COINS" % cost
	return ""


func _build_footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0.0, 40.0 if _compact_layout else 46.0)
	footer.add_theme_constant_override("separation", 10)
	var status := Label.new()
	status.text = _status_message
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(status, 13, Styles.MOSS if _status_ok else Styles.CORAL)
	footer.add_child(status)
	if not _pending_replace.is_empty():
		var confirm := Button.new()
		confirm.name = "ConfirmAffixReplacement"
		confirm.text = "Replace Affix (This Run)"
		confirm.custom_minimum_size = Vector2(206.0, 38.0 if _compact_layout else 44.0)
		Styles.apply_button(confirm, Styles.CORAL)
		confirm.pressed.connect(func() -> void:
			forge_affix_requested.emit(
				StringName(_pending_replace["item_id"]),
				StringName(_pending_replace["affix_id"]),
				true
			)
		)
		footer.add_child(confirm)
		_focus_targets.append(confirm)
	var leave := Button.new()
	leave.name = "LeaveButton"
	leave.text = "Continue"
	leave.custom_minimum_size = Vector2(156.0 if _compact_layout else 190.0, 38.0 if _compact_layout else 44.0)
	Styles.apply_button(leave, Styles.AMBER)
	leave.pressed.connect(func() -> void: leave_requested.emit())
	footer.add_child(leave)
	_focus_targets.append(leave)
	return footer


func _restore_focus() -> void:
	if _focus_targets.is_empty():
		return
	for target in _focus_targets:
		if is_instance_valid(target) and target.name == _previous_focus_name and not target.disabled:
			target.grab_focus()
			return
	for target in _focus_targets:
		if is_instance_valid(target) and not target.disabled:
			target.grab_focus()
			return


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	Styles.configure_label(label, 13, Styles.TEXT_MUTED)
	return label


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
