extends Control

signal back_requested
signal run_requested(profile_id: StringName)
signal equipment_action_requested(
	character_id: StringName, slot_id: StringName, item_id: StringName, unlock: bool
)
signal mastery_purchase_requested(character_id: StringName, node_id: StringName)
signal mastery_respec_requested(character_id: StringName)
signal persistence_retry_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const EquipmentDecisionPanelScene = preload(
	"res://scenes/ui/production/components/EquipmentDecisionPanel.tscn"
)
const PortraitScene = preload("res://scripts/ui/production/ProductionPortrait.gd")
const StatPresentation = preload("res://scripts/player/PlayerStatPresentation.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var selected_index: int = 0
var _profiles: Array[CharacterProfile] = []
var _character_buttons: Array[Button] = []
var _selected_labels: Array[Label] = []
var _content_host: VBoxContainer
var _wallet_label: Label
var _status_label: Label
var _retry_button: Button
var _mode_button: Button
var _start_button: Button
var _mastery_open: bool = false
var _selected_slot_items: Dictionary = {}
var _selected_mastery_id: StringName
var _equipment_detail: Control
var _focus_after_refresh: StringName = &""
var _compact_layout: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compact_layout = get_viewport_rect().size.y <= 600.0
	for profile in RunState.profiles:
		_profiles.append(profile)
	selected_index = clampi(RunState.selected_profile_index, 0, maxi(_profiles.size() - 1, 0))
	_build_shell()
	_refresh()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	var compact := get_viewport_rect().size.y <= 600.0
	if compact == _compact_layout:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and is_ancestor_of(focus_owner):
		_focus_after_refresh = StringName(focus_owner.name)
	_compact_layout = compact
	_character_buttons.clear()
	_selected_labels.clear()
	_content_host = null
	_wallet_label = null
	_status_label = null
	_retry_button = null
	_mode_button = null
	_start_button = null
	_equipment_detail = null
	_clear_container(self)
	_build_shell()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if _mastery_open:
		_toggle_mode()
	else:
		back_requested.emit()


func _build_shell() -> void:
	add_child(BackdropScene.new())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 16 if _compact_layout else 20)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10 if _compact_layout else 14)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 6 if _compact_layout else 9)
	margin.add_child(page)
	page.add_child(_build_header())
	page.add_child(_build_character_strip())

	_content_host = VBoxContainer.new()
	_content_host.name = "LoadoutContent"
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_host.add_theme_constant_override("separation", 8)
	page.add_child(_content_host)
	page.add_child(_build_footer())


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 38.0 if _compact_layout else 42.0)
	header.add_theme_constant_override("separation", 12)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(78.0 if _compact_layout else 88.0, 36.0 if _compact_layout else 40.0)
	Styles.apply_button(back, Styles.MOSS, true)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)

	var title := Label.new()
	title.text = "RUNNER & LOADOUT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(title, 21 if _compact_layout else 25)
	header.add_child(title)

	_wallet_label = Label.new()
	_wallet_label.custom_minimum_size = Vector2(200.0 if _compact_layout else 240.0, 36.0 if _compact_layout else 40.0)
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(_wallet_label, 11 if _compact_layout else 13, Styles.TEXT_MUTED)
	header.add_child(_wallet_label)
	return header


func _build_character_strip() -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "CharacterStrip"
	strip.custom_minimum_size = Vector2(0.0, 88.0 if _compact_layout else 112.0)
	strip.add_theme_constant_override("separation", 10)
	for profile_index in _profiles.size():
		strip.add_child(_build_character_button(profile_index, _profiles[profile_index]))
	return strip


func _build_character_button(profile_index: int, profile: CharacterProfile) -> Button:
	var card := Button.new()
	card.name = "Character_%s" % profile.id
	card.text = ""
	card.custom_minimum_size = Vector2(0.0, 84.0 if _compact_layout else 108.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(func() -> void: _select_profile(profile_index))
	_character_buttons.append(card)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 8.0 if _compact_layout else 12.0
	margin.offset_top = 6.0 if _compact_layout else 8.0
	margin.offset_right = -8.0 if _compact_layout else -12.0
	margin.offset_bottom = -6.0 if _compact_layout else -8.0
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var portrait := PortraitScene.new()
	portrait.custom_minimum_size = Vector2(58.0, 68.0) if _compact_layout else Vector2(78.0, 84.0)
	portrait.configure(profile.id, profile.visual_color)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)

	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	row.add_child(text)

	var name_label := Label.new()
	name_label.text = profile.display_name.to_upper()
	Styles.configure_label(name_label, 15 if _compact_layout else 18)
	text.add_child(name_label)

	var trait_label := Label.new()
	trait_label.text = profile.trait_summary
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.max_lines_visible = 1 if _compact_layout else 2
	trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trait_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Styles.configure_label(trait_label, 10 if _compact_layout else 11, Styles.TEXT_MUTED)
	text.add_child(trait_label)

	var facts := Label.new()
	facts.text = "HP %d   MOVE %d   DASH %d" % [
		profile.max_health, roundi(profile.move_speed), profile.dash_charges,
	]
	Styles.configure_label(facts, 10 if _compact_layout else 11, profile.visual_color)
	text.add_child(facts)

	var selected := Label.new()
	selected.text = "SELECTED"
	Styles.configure_label(selected, 10, profile.visual_color)
	text.add_child(selected)
	_selected_labels.append(selected)
	return card


func _build_footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0.0, 40.0 if _compact_layout else 44.0)
	footer.add_theme_constant_override("separation", 10)

	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styles.configure_label(_status_label, 13, Styles.CORAL)
	footer.add_child(_status_label)

	_retry_button = Button.new()
	_retry_button.text = "Retry Save"
	_retry_button.visible = false
	_retry_button.custom_minimum_size = Vector2(104.0, 38.0 if _compact_layout else 42.0)
	Styles.apply_button(_retry_button, Styles.CORAL, true)
	_retry_button.pressed.connect(func() -> void: persistence_retry_requested.emit())
	footer.add_child(_retry_button)

	_mode_button = Button.new()
	_mode_button.name = "ModeButton"
	_mode_button.custom_minimum_size = Vector2(126.0 if _compact_layout else 150.0, 38.0 if _compact_layout else 42.0)
	Styles.apply_button(_mode_button, Styles.CYAN, true)
	_mode_button.pressed.connect(_toggle_mode)
	footer.add_child(_mode_button)

	_start_button = Button.new()
	_start_button.name = "StartRunButton"
	_start_button.text = "Start Run"
	_start_button.custom_minimum_size = Vector2(156.0 if _compact_layout else 190.0, 38.0 if _compact_layout else 42.0)
	Styles.apply_button(_start_button, Styles.AMBER)
	_start_button.pressed.connect(_begin_start)
	footer.add_child(_start_button)
	return footer


func _refresh() -> void:
	if _profiles.is_empty():
		_start_button.disabled = true
		return
	for profile_index in _character_buttons.size():
		var selected := profile_index == selected_index
		Styles.apply_character_card(
			_character_buttons[profile_index], _profiles[profile_index].visual_color, selected
		)
		_selected_labels[profile_index].visible = selected
	_update_wallet()
	_clear_container(_content_host)
	if _mastery_open:
		_build_mastery_view()
	else:
		_build_loadout_view()
	_mode_button.text = "Loadout" if _mastery_open else "Mastery"
	_start_button.visible = not _mastery_open
	_restore_focus_after_refresh()


func _restore_focus_after_refresh() -> void:
	var requested_name := _focus_after_refresh
	_focus_after_refresh = &""
	if requested_name != &"":
		var requested := find_child(String(requested_name), true, false) as Control
		if (
			requested != null
			and requested.is_visible_in_tree()
			and requested.focus_mode != Control.FOCUS_NONE
			and (not (requested is BaseButton) or not (requested as BaseButton).disabled)
		):
			requested.grab_focus()
			return
	if _mastery_open:
		_mode_button.grab_focus()
	elif not _character_buttons.is_empty():
		_character_buttons[selected_index].grab_focus()


func _build_loadout_view() -> void:
	var profile := _profiles[selected_index]
	var snapshot: Dictionary = ProfileState.get_character_loadout_snapshot(profile)
	_selected_slot_items.clear()
	_start_button.disabled = not bool(snapshot.get("ok", false))

	var body := HBoxContainer.new()
	body.name = "LoadoutBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16 if _compact_layout else 24)
	_content_host.add_child(body)

	var loadout_column := VBoxContainer.new()
	loadout_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_column.add_theme_constant_override("separation", 4 if _compact_layout else 5)
	body.add_child(loadout_column)
	loadout_column.add_child(_section_label("LOADOUT"))
	var first_slot_id := ""
	var first_equipped_id := ""
	for slot_row in snapshot.get("slots", []):
		loadout_column.add_child(_build_slot_row(slot_row))
		if first_slot_id.is_empty():
			first_slot_id = String(slot_row.get("slot", ""))
			first_equipped_id = String(slot_row.get("equipped_id", ""))
	loadout_column.add_child(_build_consumable_row(snapshot.get("loadout", {})))
	_equipment_detail = EquipmentDecisionPanelScene.instantiate() as Control
	_equipment_detail.name = "SelectedEquipmentDetail"
	_equipment_detail.custom_minimum_size.y = 112.0 if _compact_layout else 132.0
	_equipment_detail.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	loadout_column.add_child(_equipment_detail)
	if not first_slot_id.is_empty():
		_show_loadout_option(
			first_slot_id,
			_selected_slot_items.get(first_slot_id, {}),
			first_equipped_id
		)

	var divider := VSeparator.new()
	body.add_child(divider)

	var summary := VBoxContainer.new()
	summary.custom_minimum_size = Vector2(290.0 if _compact_layout else 330.0, 0.0)
	summary.add_theme_constant_override("separation", 6)
	body.add_child(summary)
	summary.add_child(_section_label("EFFECTIVE BUILD"))
	summary.add_child(_build_stat_grid(snapshot.get("effective_stats", {})))
	var mastery_count := ProfileState.get_mastery_unlocks(profile.id).size()
	var mastery_summary := Label.new()
	mastery_summary.text = "MASTERY  %d / 6" % mastery_count
	Styles.configure_label(mastery_summary, 13, profile.visual_color)
	summary.add_child(mastery_summary)
	var source_label := Label.new()
	var source_count := 0
	for source_id in snapshot.get("source_breakdown", {}):
		if String(source_id) not in [PlayerBuild.BASE_CHARACTER_SOURCE, PlayerBuild.BUILD_LIMITS_SOURCE]:
			source_count += 1
	source_label.text = "%d active loadout modifier%s" % [source_count, "" if source_count == 1 else "s"]
	Styles.configure_label(source_label, 12, Styles.TEXT_MUTED)
	summary.add_child(source_label)


func _build_slot_row(slot_row: Dictionary) -> HBoxContainer:
	var slot_id := String(slot_row.get("slot", ""))
	var options: Array = slot_row.get("options", [])
	var equipped_id := String(slot_row.get("equipped_id", ""))
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 34.0 if _compact_layout else 38.0)
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = slot_id.to_upper()
	label.custom_minimum_size = Vector2(66.0 if _compact_layout else 76.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(label, 12, Styles.TEXT_MUTED)
	row.add_child(label)

	var picker := OptionButton.new()
	picker.name = "Slot_%s" % slot_id
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.custom_minimum_size = Vector2(0.0, 32.0 if _compact_layout else 36.0)
	Styles.apply_button(picker, _profiles[selected_index].visual_color, true)
	var selected_index_in_picker := 0
	for option_index in options.size():
		var option: Dictionary = options[option_index]
		var suffix := "" if bool(option.get("owned", false)) else "  [LOCKED]"
		picker.add_item("%s%s" % [option.get("display_name", "Unknown"), suffix])
		picker.set_item_metadata(option_index, option)
		if String(option.get("id", "")) == equipped_id:
			selected_index_in_picker = option_index
	if options.is_empty():
		picker.add_item("None available")
		picker.disabled = true
	else:
		picker.select(selected_index_in_picker)
		_selected_slot_items[slot_id] = options[selected_index_in_picker]
	row.add_child(picker)

	var action := Button.new()
	action.custom_minimum_size = Vector2(98.0 if _compact_layout else 112.0, 32.0 if _compact_layout else 36.0)
	Styles.apply_button(action, Styles.AMBER, true)
	row.add_child(action)
	_update_slot_action(action, slot_id, equipped_id)
	picker.item_selected.connect(func(option_index: int) -> void:
		_selected_slot_items[slot_id] = picker.get_item_metadata(option_index)
		_update_slot_action(action, slot_id, equipped_id)
		_show_loadout_option(slot_id, _selected_slot_items[slot_id], equipped_id)
	)
	picker.focus_entered.connect(func() -> void:
		_show_loadout_option(slot_id, _selected_slot_items.get(slot_id, {}), equipped_id)
	)
	action.focus_entered.connect(func() -> void:
		_show_loadout_option(slot_id, _selected_slot_items.get(slot_id, {}), equipped_id)
	)
	action.pressed.connect(func() -> void: _commit_slot_action(slot_id))
	return row


func _build_consumable_row(loadout: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 34.0 if _compact_layout else 38.0)
	var label := Label.new()
	label.text = "CONSUMABLE"
	label.custom_minimum_size = Vector2(84.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(label, 12, Styles.TEXT_MUTED)
	row.add_child(label)
	var value := Label.new()
	value.text = String(loadout.get("consumable", "small_potion")).replace("_", " ").capitalize()
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(value, 14)
	row.add_child(value)
	return row


func _show_loadout_option(slot_id: String, option: Dictionary, equipped_id: String) -> void:
	if _equipment_detail == null or not is_instance_valid(_equipment_detail):
		return
	var item_id := String(option.get("id", ""))
	var owned := bool(option.get("owned", false))
	var state_text := "LOCKED"
	if item_id == equipped_id:
		state_text = "EQUIPPED"
	elif owned:
		state_text = "OWNED | AVAILABLE"
	else:
		state_text = "LOCKED | %s" % _cost_text(option.get("unlock_costs", {}), false)
	var empty_text := (
		"No build change; this item is already equipped."
		if item_id == equipped_id
		else "No numeric change; the behavior is described above."
	)
	_equipment_detail.call("configure", {
		"context_text": "%s | PERMANENT LOADOUT" % slot_id.to_upper(),
		"state_text": state_text,
		"title": String(option.get("display_name", "Unavailable")),
		"description": String(option.get("description", "No item is available for this slot.")),
		"tradeoff": String(option.get("tradeoff", "")),
		"stat_deltas": option.get("stat_deltas", []),
		"validation_errors": option.get("validation_errors", []),
		"empty_mechanics_text": empty_text,
	}, _compact_layout)


func _update_slot_action(button: Button, slot_id: String, equipped_id: String) -> void:
	var option: Dictionary = _selected_slot_items.get(slot_id, {})
	var item_id := String(option.get("id", ""))
	if item_id.is_empty():
		button.text = "Unavailable"
		button.disabled = true
	elif item_id == equipped_id:
		button.text = "Equipped"
		button.disabled = true
	elif bool(option.get("owned", false)):
		button.text = "Equip"
		button.disabled = false
	else:
		button.text = "Unlock %s" % _cost_text(option.get("unlock_costs", {}), true)
		button.disabled = not _can_afford(option.get("unlock_costs", {}))
	button.tooltip_text = String(option.get("description", ""))


func _commit_slot_action(slot_id: String) -> void:
	var option: Dictionary = _selected_slot_items.get(slot_id, {})
	var item_id := StringName(option.get("id", ""))
	_focus_after_refresh = StringName("Slot_%s" % slot_id)
	equipment_action_requested.emit(
		StringName(_profiles[selected_index].id),
		StringName(slot_id),
		item_id,
		not bool(option.get("owned", false))
	)


func _build_stat_grid(stats: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "StatGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 5)
	for stat_id in [
		&"max_health",
		&"attack_damage",
		&"attack_range",
		&"move_speed",
		&"jump_velocity",
		&"extra_jumps",
		&"dash_cooldown",
		&"dash_charges",
	]:
		var name_label := Label.new()
		name_label.text = StatPresentation.display_name(stat_id)
		Styles.configure_label(name_label, 11 if _compact_layout else 12, Styles.TEXT_MUTED)
		grid.add_child(name_label)
		var value_label := Label.new()
		value_label.text = StatPresentation.format_value(
			stat_id,
			float(stats.get(String(stat_id), 0.0))
		)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Styles.configure_label(value_label, 13 if _compact_layout else 14)
		grid.add_child(value_label)
	return grid


func _build_mastery_view() -> void:
	var profile := _profiles[selected_index]
	var snapshot := ProfileState.get_character_loadout_snapshot(profile)
	var mastery_rows: Array = snapshot.get("mastery", [])
	var purchased_ids := ProfileState.get_mastery_unlocks(profile.id)

	var heading := HBoxContainer.new()
	heading.add_child(_section_label("%s MASTERY" % profile.display_name.to_upper()))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	if OS.is_debug_build():
		var respec := Button.new()
		respec.text = "Refund Mastery"
		respec.disabled = purchased_ids.is_empty()
		respec.custom_minimum_size = Vector2(154.0, 34.0)
		Styles.apply_button(respec, Styles.CORAL, true)
		respec.pressed.connect(_commit_respec)
		heading.add_child(respec)
	_content_host.add_child(heading)

	var grid := GridContainer.new()
	grid.name = "MasteryGrid"
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_content_host.add_child(grid)
	if _selected_mastery_id == &"" and not mastery_rows.is_empty():
		_selected_mastery_id = StringName(mastery_rows[0].get("id", ""))
	for row in mastery_rows:
		var node := Button.new()
		var state := _mastery_state(row, purchased_ids)
		var node_id := StringName(row.get("id", ""))
		node.name = "Mastery_%s" % node_id
		node.text = "%s\n%s  %s" % [
			row.get("display_name", "Unknown"),
			String(row.get("depth", "")).to_upper(),
			state,
		]
		node.custom_minimum_size = Vector2(0.0, 64.0)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Styles.apply_button(node, profile.visual_color, state != "AVAILABLE")
		node.pressed.connect(func() -> void:
			_selected_mastery_id = node_id
			_focus_after_refresh = StringName(node.name)
			_refresh()
		)
		grid.add_child(node)
	_content_host.add_child(_build_mastery_detail(mastery_rows, purchased_ids))


func _build_mastery_detail(rows: Array, purchased_ids: Array[String]) -> HBoxContainer:
	var selected: Dictionary = {}
	for row in rows:
		if StringName(row.get("id", "")) == _selected_mastery_id:
			selected = row
			break
	var detail := HBoxContainer.new()
	detail.custom_minimum_size = Vector2(0.0, 58.0)
	detail.add_theme_constant_override("separation", 12)
	var description := Label.new()
	description.text = String(selected.get("description", "Select a mastery node."))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 3
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(description, 12, Styles.TEXT_MUTED)
	detail.add_child(description)
	var action := Button.new()
	var state := _mastery_state(selected, purchased_ids)
	action.text = "Purchased" if state == "OWNED" else "Purchase %s" % _cost_text(selected.get("costs", {}), false)
	action.custom_minimum_size = Vector2(190.0, 42.0)
	action.disabled = state != "AVAILABLE"
	Styles.apply_button(action, Styles.AMBER)
	action.pressed.connect(_commit_mastery_purchase)
	detail.add_child(action)
	return detail


func _mastery_state(row: Dictionary, purchased_ids: Array[String]) -> String:
	var node_id := String(row.get("id", ""))
	if node_id.is_empty():
		return "LOCKED"
	if purchased_ids.has(node_id):
		return "OWNED"
	for required_id in row.get("requires_all", []):
		if not purchased_ids.has(String(required_id)):
			return "LOCKED"
	var requires_any: Array = row.get("requires_any", [])
	if not requires_any.is_empty():
		var has_any := false
		for required_id in requires_any:
			has_any = has_any or purchased_ids.has(String(required_id))
		if not has_any:
			return "LOCKED"
	return "AVAILABLE" if _can_afford(row.get("costs", {})) else "NEED MATERIAL"


func _commit_mastery_purchase() -> void:
	_focus_after_refresh = StringName("Mastery_%s" % _selected_mastery_id)
	mastery_purchase_requested.emit(
		StringName(_profiles[selected_index].id), _selected_mastery_id
	)


func _commit_respec() -> void:
	_focus_after_refresh = &"ModeButton"
	mastery_respec_requested.emit(StringName(_profiles[selected_index].id))


func _toggle_mode() -> void:
	_mastery_open = not _mastery_open
	_status_label.text = ""
	_refresh()
	_mode_button.grab_focus()


func set_start_error(message: String) -> void:
	_set_status({"ok": false, "message": message})
	var snapshot := ProfileState.get_character_loadout_snapshot(_profiles[selected_index])
	_start_button.disabled = not bool(snapshot.get("ok", false))
	_start_button.grab_focus()


func show_profile_command_result(result: Dictionary) -> void:
	_set_status(result)
	_refresh()


func _begin_start() -> void:
	if _start_button.disabled:
		return
	_start_button.disabled = true
	_mode_button.disabled = true
	for button in _character_buttons:
		button.disabled = true
	_status_label.text = "Starting run..."
	_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	run_requested.emit(StringName(_profiles[selected_index].id))


func _select_profile(profile_index: int) -> void:
	selected_index = clampi(profile_index, 0, maxi(_profiles.size() - 1, 0))
	_selected_slot_items.clear()
	_selected_mastery_id = &""
	_status_label.text = ""
	_refresh()


func _set_status(result: Dictionary) -> void:
	var persisted := bool(result.get("persisted", true))
	_status_label.text = (
		String(result.get("message", "Unable to update profile."))
		if persisted
		else "Change is active in memory. Save failed."
	)
	_status_label.add_theme_color_override(
		"font_color",
		Styles.MOSS if bool(result.get("ok", false)) and persisted else Styles.CORAL
	)
	_retry_button.visible = not persisted


func _update_wallet() -> void:
	var materials := ProfileState.get_materials()
	_wallet_label.text = "SCRAP %d   THREAD %d   RESIDUE %d   CORE %d" % [
		int(materials.get("rusted_scrap", 0)),
		int(materials.get("sky_thread", 0)),
		int(materials.get("slime_residue", 0)),
		int(materials.get("boss_core", 0)),
	]


func _can_afford(costs: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for material_id in costs:
		if ProfileState.get_material_count(String(material_id)) < int(costs[material_id]):
			return false
	return true


func _cost_text(costs: Dictionary, compact: bool) -> String:
	if costs.is_empty():
		return "Unavailable"
	var parts: Array[String] = []
	var ids := costs.keys()
	ids.sort()
	for material_id in ids:
		var name := String(material_id)
		if compact:
			name = {"rusted_scrap": "S", "sky_thread": "T", "slime_residue": "R", "boss_core": "C"}.get(name, name)
		else:
			name = name.replace("_", " ").capitalize()
		parts.append("%d %s" % [int(costs[material_id]), name])
	return " + ".join(parts)


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	Styles.configure_label(label, 14, Styles.TEXT_MUTED)
	return label


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
