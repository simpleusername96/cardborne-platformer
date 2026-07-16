extends Control

signal start_requested
signal tutorial_requested
signal equipment_command_requested(action: StringName, model_id: StringName, slot: StringName)
signal spirit_stone_equip_requested(stone_id: StringName)
signal settings_requested
signal back_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Assets = preload("res://scripts/ui/production/ProductionUIAssets.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")

const SLOT_ORDER: Array[StringName] = [
	&"melee",
	&"ranged",
	&"shield",
	&"armor",
	&"spirit_stone",
	&"consumable",
]
const EQUIPMENT_SLOTS: Array[StringName] = [&"melee", &"ranged", &"shield", &"armor"]
const SLOT_LABELS := {
	"melee": "Melee",
	"ranged": "Ranged",
	"shield": "Shield",
	"armor": "Armor",
	"spirit_stone": "Spirit Stone",
	"consumable": "Consumable",
}
const MATERIAL_BALANCE_LABELS := {
	"rusted_scrap": "Iron",
	"steel_fragment": "Steel",
	"common_timber": "Timber",
	"hardwood": "Hardwood",
	"sky_thread": "Fiber",
	"reinforced_fabric": "Fabric",
}
const MATERIAL_ROWS: Array[Array] = [
	["rusted_scrap", "steel_fragment"],
	["common_timber", "hardwood"],
	["sky_thread", "reinforced_fabric"],
]
@onready var _outer_margin: MarginContainer = %OuterMargin
@onready var _page: VBoxContainer = %Page
@onready var _back_button: Button = %BackButton
@onready var _persistence_label: Label = %PersistenceLabel
@onready var _tutorial_button: Button = %TutorialButton
@onready var _settings_button: Button = %SettingsButton
@onready var _loadout_panel: PanelContainer = %LoadoutPanel
@onready var _model_panel: PanelContainer = %ModelPanel
@onready var _model_heading: Label = %ModelHeading
@onready var _model_subtitle: Label = %ModelSubtitle
@onready var _model_list: VBoxContainer = %ModelList
@onready var _materials_label: Label = %MaterialsLabel
@onready var _supplies_label: Label = %SuppliesLabel
@onready var _traveler_portrait: TextureRect = %TravelerPortrait
@onready var _detail: HeroPreparationDetail = %HeroPreparationDetail
@onready var _status_label: Label = %StatusLabel
@onready var _start_button: Button = %StartButton

var _snapshot: Dictionary = {}
var _slot_buttons: Dictionary = {}
var _model_buttons: Array[Button] = []
var _selected_slot: StringName = &"melee"
var _selected_ids: Dictionary = {}
var _compact_layout := false
var _snapshot_available := false
var _persistence_state: StringName = &"saved"
var _status_source := "Select a model to inspect its next action."


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Styles.apply_theme(self)
	_cache_slot_buttons()
	_configure_asset_slots()
	_connect_controls()
	_apply_styles()
	_compact_layout = _is_compact_layout()
	_apply_layout()
	if not ProfileState.profile_changed.is_connected(_on_profile_changed):
		ProfileState.profile_changed.connect(_on_profile_changed)
	if not ProfileState.persistence_failed.is_connected(_on_persistence_failed):
		ProfileState.persistence_failed.connect(_on_persistence_failed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	_apply_copy()
	refresh_from_profile(false)
	call_deferred("_establish_initial_focus")


func _exit_tree() -> void:
	if ProfileState.profile_changed.is_connected(_on_profile_changed):
		ProfileState.profile_changed.disconnect(_on_profile_changed)
	if ProfileState.persistence_failed.is_connected(_on_persistence_failed):
		ProfileState.persistence_failed.disconnect(_on_persistence_failed)


func refresh_from_profile(preserve_focus: bool = true) -> void:
	var focus_key := _focus_key() if preserve_focus else ""
	var snapshot: Dictionary = ProfileState.get_preparation_snapshot()
	_snapshot = snapshot.duplicate(true)
	_snapshot_available = _validate_snapshot(_snapshot)
	if not _snapshot_available:
		_render_unavailable_snapshot()
		_restore_focus(focus_key)
		return

	_start_button.disabled = false
	_update_tutorial_button()
	_update_balances()
	_update_slot_buttons()
	_rebuild_model_list()
	_restore_focus(focus_key)


func show_command_result(result: Dictionary) -> void:
	var ok := bool(result.get("ok", false))
	var persisted := bool(result.get("persisted", true))
	if not persisted:
		_set_persistence_state(&"failed")
		_set_status("The change was not saved. Try again before starting.", Styles.CORAL)
	elif ok:
		_set_persistence_state(&"saved")
		_set_status("Preparation updated.", Styles.MOSS)
	else:
		_set_persistence_state(&"saved")
		_set_status(_command_failure_text(String(result.get("code", ""))), Styles.CORAL)
	refresh_from_profile(true)


func set_start_error(_message: String = "") -> void:
	_set_status("Stage 1 is not ready. Return and try again.", Styles.CORAL)
	_start_button.grab_focus()


func _cache_slot_buttons() -> void:
	_slot_buttons = {
		&"melee": %MeleeButton,
		&"ranged": %RangedButton,
		&"shield": %ShieldButton,
		&"armor": %ArmorButton,
		&"spirit_stone": %SpiritStoneButton,
		&"consumable": %ConsumableButton,
	}


func _connect_controls() -> void:
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_tutorial_button.pressed.connect(func() -> void: tutorial_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	for slot_id in SLOT_ORDER:
		var button := _slot_buttons.get(slot_id) as Button
		button.pressed.connect(_select_slot.bind(slot_id))
	_detail.equipment_command_requested.connect(_on_equipment_command_requested)
	_detail.spirit_stone_equip_requested.connect(_on_spirit_stone_equip_requested)


func _apply_styles() -> void:
	Styles.apply_panel(_loadout_panel)
	Styles.apply_panel(_model_panel)
	for button_value in _slot_buttons.values():
		var button := button_value as Button
		Styles.apply_choice_button(button)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	Styles.apply_button(_back_button, Styles.CYAN, true)
	Styles.apply_button(_tutorial_button, Styles.MOSS, true)
	Styles.apply_button(_settings_button, Styles.CYAN, true)
	Styles.apply_button(_start_button, Styles.AMBER)
	Styles.configure_label(%ScreenEyebrow, Styles.TYPE_CAPTION, Styles.AMBER)
	Styles.configure_label(%HeroNameLabel, 28, Styles.TEXT)
	Styles.configure_label(%StageLabel, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(_persistence_label, Styles.TYPE_CAPTION, Styles.MOSS)
	Styles.configure_label(%LoadoutHeading, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(%MaterialsHeading, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(%SuppliesHeading, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(_materials_label, Styles.TYPE_CAPTION, Styles.TEXT)
	Styles.configure_label(_supplies_label, Styles.TYPE_CAPTION, Styles.TEXT)
	Styles.configure_label(_model_heading, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(_model_subtitle, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	Styles.configure_label(_status_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_set_persistence_state(&"saved")


func _configure_asset_slots() -> void:
	_traveler_portrait.texture = Assets.texture_for_owner(&"traveler")
	_traveler_portrait.tooltip_text = _t("Traveler")
	for slot_id in SLOT_ORDER:
		var button := _slot_buttons.get(slot_id) as Button
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 36)


func _apply_copy() -> void:
	%ScreenEyebrow.text = _t("PREPARATION • STAGE 1")
	%HeroNameLabel.text = _t("Traveler")
	%StageLabel.text = _t("Ruin Approach")
	_back_button.text = _t("Back")
	_tutorial_button.text = _t("Begin Trial")
	_settings_button.text = _t("Settings")
	%LoadoutHeading.text = _t("TRAVELER LOADOUT")
	%MaterialsHeading.text = _t("MATERIALS")
	%SuppliesHeading.text = _t("RANGED SUPPLIES")
	_start_button.text = _t("Start Stage 1")
	_status_label.text = _t(_status_source)
	_set_persistence_state(_persistence_state)


func _apply_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var viewport_width := viewport_size.x
	var horizontal_margin := 12 if _compact_layout else maxi(20, int((viewport_width - 1280.0) * 0.5))
	horizontal_margin = mini(horizontal_margin, 320)
	_outer_margin.add_theme_constant_override("margin_left", horizontal_margin)
	_outer_margin.add_theme_constant_override("margin_right", horizontal_margin)
	var vertical_margin := (
		8
		if _compact_layout
		else maxi(14, int((get_viewport_rect().size.y - 720.0) * 0.5))
	)
	vertical_margin = mini(vertical_margin, 180)
	_outer_margin.add_theme_constant_override("margin_top", vertical_margin)
	_outer_margin.add_theme_constant_override("margin_bottom", vertical_margin)
	_page.add_theme_constant_override("separation", 5 if _compact_layout else 9)
	_traveler_portrait.custom_minimum_size = (
		Vector2(56.0, 56.0) if _compact_layout else Vector2(72.0, 72.0)
	)
	%Body.add_theme_constant_override("separation", 7 if _compact_layout else 11)
	%SlotList.add_theme_constant_override("separation", 2 if _compact_layout else 4)
	%LoadoutContent.add_theme_constant_override("separation", 4 if _compact_layout else 7)
	%ModelContent.add_theme_constant_override("separation", 5 if _compact_layout else 8)
	_loadout_panel.custom_minimum_size.x = 190.0 if _compact_layout else 238.0
	_model_panel.custom_minimum_size.x = 215.0 if _compact_layout else 290.0
	_detail.custom_minimum_size.x = 0.0 if _compact_layout else 420.0
	var header_height := 62.0 if _compact_layout else 85.0
	var footer_height := Styles.TARGET_HEIGHT
	var page_gaps := float((5 if _compact_layout else 9) * 2)
	var available_height := (
		viewport_size.y
		- float(vertical_margin * 2)
		- header_height
		- footer_height
		- page_gaps
	)
	var panel_height := clampf(available_height, 320.0, 560.0)
	for panel in [_loadout_panel, _model_panel, _detail]:
		panel.custom_minimum_size.y = panel_height
		panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for button_value in _slot_buttons.values():
		var slot_button := button_value as Button
		slot_button.custom_minimum_size.y = Styles.TARGET_HEIGHT
		slot_button.add_theme_font_size_override("font_size", Styles.TYPE_CAPTION)
	_back_button.custom_minimum_size.y = Styles.TARGET_HEIGHT
	_tutorial_button.custom_minimum_size.y = Styles.TARGET_HEIGHT
	_settings_button.custom_minimum_size.y = Styles.TARGET_HEIGHT
	_start_button.custom_minimum_size.y = Styles.TARGET_HEIGHT
	for header_button in [_back_button, _tutorial_button, _settings_button]:
		header_button.add_theme_font_size_override("font_size", Styles.TYPE_BUTTON)
	_start_button.add_theme_font_size_override("font_size", Styles.TYPE_BUTTON)
	%StageLabel.visible = not _compact_layout
	%MaterialsHeading.visible = not _compact_layout
	_materials_label.visible = not _compact_layout
	%SuppliesHeading.visible = not _compact_layout
	_supplies_label.visible = not _compact_layout
	Styles.configure_label(%HeroNameLabel, 26 if _compact_layout else 28, Styles.TEXT)
	Styles.configure_label(%StageLabel, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_update_model_detail()


func _is_compact_layout() -> bool:
	var size := get_viewport_rect().size
	return size.x <= 1050.0 or size.y <= 600.0


func _on_viewport_size_changed() -> void:
	var compact := _is_compact_layout()
	if compact == _compact_layout:
		_apply_layout()
		return
	_compact_layout = compact
	_apply_layout()
	_rebuild_model_list()


func _validate_snapshot(snapshot: Dictionary) -> bool:
	if String(snapshot.get("hero_id", "")) != "traveler":
		return false
	if not snapshot.get("loadout", {}) is Dictionary:
		return false
	if not snapshot.get("materials", {}) is Dictionary:
		return false
	if not snapshot.get("ranged_supplies", {}) is Dictionary:
		return false
	if not snapshot.get("tutorial", {}) is Dictionary:
		return false
	var slots_value: Variant = snapshot.get("slots", [])
	if not slots_value is Array or (slots_value as Array).size() != EQUIPMENT_SLOTS.size():
		return false
	for slot_id in EQUIPMENT_SLOTS:
		var row := _find_equipment_slot(snapshot, slot_id)
		if row.is_empty() or not row.get("options", []) is Array:
			return false
	var stones_value: Variant = snapshot.get("spirit_stones", [])
	return stones_value is Array


func _render_unavailable_snapshot() -> void:
	_start_button.disabled = true
	_clear_model_list()
	var label := Label.new()
	label.text = _t("Preparation is unavailable.")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styles.configure_label(label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	_model_list.add_child(label)
	_materials_label.text = _t("Balances unavailable")
	_supplies_label.text = _t("Supplies unavailable")
	_detail.configure_unavailable(
		"Preparation unavailable",
		"Return after preparation finishes loading.",
		_compact_layout
	)
	_set_status("Preparation could not be loaded.", Styles.CORAL)
	_set_persistence_state(&"failed")


func _update_tutorial_button() -> void:
	var tutorial := _as_dictionary(_snapshot.get("tutorial", {}))
	_tutorial_button.text = _t("Replay Trial") if bool(tutorial.get("resolved", false)) else _t("Begin Trial")


func _update_balances() -> void:
	var materials := _as_dictionary(_snapshot.get("materials", {}))
	var material_lines: Array[String] = []
	for pair in MATERIAL_ROWS:
		var left_id := String(pair[0])
		var right_id := String(pair[1])
		material_lines.append("%s %d · %s %d" % [
			_t(MATERIAL_BALANCE_LABELS[left_id]),
			int(materials.get(left_id, 0)),
			_t(MATERIAL_BALANCE_LABELS[right_id]),
			int(materials.get(right_id, 0)),
		])
	_materials_label.text = "\n".join(material_lines)

	var supplies := _as_dictionary(_snapshot.get("ranged_supplies", {}))
	_supplies_label.text = "%s %d\n%s %d" % [
		_t("Arrows"),
		int(supplies.get("arrows", 0)),
		_t("Cartridges"),
		int(supplies.get("cartridges", 0)),
	]
	_supplies_label.text += "\n" + _t("Healing Potion prepared")


func _update_slot_buttons() -> void:
	for slot_id in SLOT_ORDER:
		var button := _slot_buttons.get(slot_id) as Button
		var selected := slot_id == _selected_slot
		var summary := _slot_summary(slot_id)
		button.icon = Assets.texture_for_owner(_slot_owner_id(slot_id), slot_id)
		button.text = (
			_t(SLOT_LABELS[String(slot_id)])
			if _compact_layout
			else "%s\n%s" % [_t(SLOT_LABELS[String(slot_id)]), summary]
		)
		button.button_pressed = selected


func _slot_owner_id(slot_id: StringName) -> StringName:
	if slot_id in EQUIPMENT_SLOTS:
		var row := _find_equipment_slot(_snapshot, slot_id)
		return StringName(String(row.get("equipped_id", "")))
	if slot_id == &"spirit_stone":
		return StringName(_equipped_stone_id(_snapshot.get("spirit_stones", [])))
	if slot_id == &"consumable":
		return StringName(String(_as_dictionary(_snapshot.get("loadout", {})).get("consumable", "")))
	return &""


func _slot_summary(slot_id: StringName) -> String:
	if slot_id in EQUIPMENT_SLOTS:
		var row := _find_equipment_slot(_snapshot, slot_id)
		var equipped_id := String(row.get("equipped_id", ""))
		for option_value in row.get("options", []):
			if option_value is Dictionary:
				var option := option_value as Dictionary
				if String(option.get("model_id", "")) == equipped_id:
					return _t(String(option.get("display_name", "Unavailable")))
		return _t("Unavailable")
	if slot_id == &"spirit_stone":
		for stone_value in _snapshot.get("spirit_stones", []):
			if stone_value is Dictionary and bool((stone_value as Dictionary).get("equipped", false)):
				return _t(String((stone_value as Dictionary).get("display_name", "Unavailable")))
		return _t("Unavailable")
	return _t("Healing Potion")


func _select_slot(slot_id: StringName) -> void:
	if slot_id not in SLOT_ORDER:
		return
	_selected_slot = slot_id
	_set_status("Select a model to inspect its next action.", Styles.TEXT_MUTED)
	_update_slot_buttons()
	_rebuild_model_list()


func _rebuild_model_list() -> void:
	_clear_model_list()
	_model_buttons.clear()
	_model_heading.text = _t(SLOT_LABELS.get(String(_selected_slot), "Equipment")).to_upper()
	_model_subtitle.text = (
		_t("PASSIVE CHOICES")
		if _selected_slot == &"spirit_stone"
		else (_t("STAGE SUPPLY") if _selected_slot == &"consumable" else _t("MODELS AND BLUEPRINTS"))
	)
	if _selected_slot in EQUIPMENT_SLOTS:
		_build_equipment_model_list()
	elif _selected_slot == &"spirit_stone":
		_build_spirit_stone_list()
	else:
		_build_consumable_list()
	_update_model_detail()


func _build_equipment_model_list() -> void:
	var row := _find_equipment_slot(_snapshot, _selected_slot)
	var options: Array = row.get("options", [])
	var selected_id := String(_selected_ids.get(String(_selected_slot), ""))
	if not _option_exists(options, selected_id, "model_id"):
		selected_id = String(row.get("equipped_id", ""))
	if not _option_exists(options, selected_id, "model_id") and not options.is_empty():
		selected_id = String((options[0] as Dictionary).get("model_id", ""))
	_selected_ids[String(_selected_slot)] = selected_id

	for option_value in options:
		if not option_value is Dictionary:
			continue
		var option := option_value as Dictionary
		var model_id := String(option.get("model_id", ""))
		var button := _make_model_button(
			_t(String(option.get("display_name", "Equipment"))),
			_equipment_model_state(option),
			model_id == selected_id,
			StringName(model_id)
		)
		button.set_meta("preparation_id", model_id)
		button.pressed.connect(_select_model.bind(StringName(model_id)))
		_model_list.add_child(button)
		_model_buttons.append(button)


func _build_spirit_stone_list() -> void:
	var stones: Array = _snapshot.get("spirit_stones", [])
	var selected_id := String(_selected_ids.get("spirit_stone", ""))
	if not _option_exists(stones, selected_id, "id"):
		selected_id = _equipped_stone_id(stones)
	if not _option_exists(stones, selected_id, "id") and not stones.is_empty():
		selected_id = String((stones[0] as Dictionary).get("id", ""))
	_selected_ids["spirit_stone"] = selected_id

	for stone_value in stones:
		if not stone_value is Dictionary:
			continue
		var stone := stone_value as Dictionary
		var stone_id := String(stone.get("id", ""))
		var state := _t("Equipped") if bool(stone.get("equipped", false)) else (
			_t("Owned") if bool(stone.get("unlocked", false)) else _t("Locked")
		)
		var button := _make_model_button(
			_t(String(stone.get("display_name", "Spirit Stone"))),
			state,
			stone_id == selected_id,
			StringName(stone_id)
		)
		button.set_meta("preparation_id", stone_id)
		button.pressed.connect(_select_model.bind(StringName(stone_id)))
		_model_list.add_child(button)
		_model_buttons.append(button)


func _build_consumable_list() -> void:
	var consumable_id := StringName(String(_as_dictionary(
		_snapshot.get("loadout", {})
	).get("consumable", "")))
	_selected_ids["consumable"] = String(consumable_id)
	var button := _make_model_button(
		_t("Healing Potion"),
		_t("Prepared · 1 use"),
		true,
		consumable_id
	)
	button.disabled = true
	_model_list.add_child(button)
	_model_buttons.append(button)


func _make_model_button(
	title: String,
	state: String,
	selected: bool,
	asset_owner_id: StringName = &""
) -> Button:
	var button := Button.new()
	button.name = "PreparationModelButton"
	button.text = "%s%s\n%s" % ["› " if selected else "", title, state]
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.button_pressed = selected
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.icon = Assets.texture_for_owner(asset_owner_id)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", 42)
	Styles.apply_choice_button(button)
	button.add_theme_font_size_override("font_size", Styles.TYPE_CAPTION)
	return button


func _equipment_model_state(option: Dictionary) -> String:
	if not bool(option.get("crafted", false)):
		return _t("Blueprint") if bool(option.get("blueprint_unlocked", false)) else _t("Locked blueprint")
	var runtime := _as_dictionary(option.get("runtime", {}))
	var grade := _t("Grade 2") if String(runtime.get("grade_id", "")) == "grade_2" else _t("Grade 1")
	return "%s · %s" % [_t("Equipped") if bool(option.get("equipped", false)) else _t("Owned"), grade]


func _select_model(model_id: StringName) -> void:
	_selected_ids[String(_selected_slot)] = String(model_id)
	_rebuild_model_list()
	for button in _model_buttons:
		if String(button.get_meta("preparation_id", "")) == String(model_id):
			button.grab_focus()
			break


func _update_model_detail() -> void:
	if _detail == null or not _snapshot_available:
		return
	if _selected_slot in EQUIPMENT_SLOTS:
		var model_id := StringName(String(_selected_ids.get(String(_selected_slot), "")))
		var decision: Dictionary = ProfileState.get_equipment_decision_snapshot(model_id)
		_detail.configure_equipment(
			decision,
			_as_dictionary(_snapshot.get("ranged_supplies", {})),
			_compact_layout
		)
	elif _selected_slot == &"spirit_stone":
		var stone := _selected_stone()
		_detail.configure_spirit_stone(stone, _compact_layout)
	else:
		var loadout := _as_dictionary(_snapshot.get("loadout", {}))
		_detail.configure_consumable(
			StringName(String(loadout.get("consumable", ""))),
			_compact_layout
		)


func _selected_stone() -> Dictionary:
	var selected_id := String(_selected_ids.get("spirit_stone", ""))
	for stone_value in _snapshot.get("spirit_stones", []):
		if stone_value is Dictionary:
			var stone := stone_value as Dictionary
			if String(stone.get("id", "")) == selected_id:
				return stone.duplicate(true)
	return {}


func _find_equipment_slot(snapshot: Dictionary, slot_id: StringName) -> Dictionary:
	var slots_value: Variant = snapshot.get("slots", [])
	if not slots_value is Array:
		return {}
	for row_value in slots_value:
		if row_value is Dictionary:
			var row := row_value as Dictionary
			if String(row.get("slot", "")) == String(slot_id):
				return row.duplicate(true)
	return {}


func _option_exists(options: Array, candidate_id: String, key: String) -> bool:
	if candidate_id.is_empty():
		return false
	for option_value in options:
		if option_value is Dictionary and String((option_value as Dictionary).get(key, "")) == candidate_id:
			return true
	return false


func _equipped_stone_id(stones: Array) -> String:
	for stone_value in stones:
		if stone_value is Dictionary and bool((stone_value as Dictionary).get("equipped", false)):
			return String((stone_value as Dictionary).get("id", ""))
	return ""


func _clear_model_list() -> void:
	for child in _model_list.get_children():
		_model_list.remove_child(child)
		child.queue_free()


func _on_equipment_command_requested(
	action: StringName,
	model_id: StringName,
	slot: StringName
) -> void:
	_set_persistence_state(&"saving")
	_set_status("Applying preparation change…", Styles.TEXT_MUTED)
	equipment_command_requested.emit(action, model_id, slot)


func _on_spirit_stone_equip_requested(stone_id: StringName) -> void:
	_set_persistence_state(&"saving")
	_set_status("Applying Spirit Stone change…", Styles.TEXT_MUTED)
	spirit_stone_equip_requested.emit(stone_id)


func _on_profile_changed(_section: StringName) -> void:
	_set_persistence_state(&"saved")
	refresh_from_profile(true)


func _on_persistence_failed(_message: String) -> void:
	_set_persistence_state(&"failed")
	_set_status("The latest change could not be saved.", Styles.CORAL)


func _set_persistence_state(state: StringName) -> void:
	_persistence_state = state
	match state:
		&"saving":
			_persistence_label.text = _t("… Saving")
			_persistence_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
		&"failed":
			_persistence_label.text = _t("! Save failed")
			_persistence_label.add_theme_color_override("font_color", Styles.CORAL)
		_:
			_persistence_label.text = _t("✓ Saved locally")
			_persistence_label.add_theme_color_override("font_color", Styles.MOSS)


func _set_status(message: String, color: Color) -> void:
	_status_source = message
	_status_label.text = _t(message)
	_status_label.add_theme_color_override("font_color", color)


func _command_failure_text(code: String) -> String:
	match code:
		"blueprint_locked":
			return "Find this blueprint before crafting."
		"insufficient_materials":
			return "More materials are required."
		"already_crafted":
			return "This model is already crafted."
		"already_grade_two":
			return "This model is already Grade 2."
		"full_condition":
			return "Condition is already full."
		"incompatible_equipment":
			return "This model does not fit the selected slot."
		_:
			return "The preparation change could not be completed."


func _focus_key() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null or not is_ancestor_of(owner):
		return ""
	if owner is Button and owner.has_meta("preparation_id"):
		return "model:%s" % String(owner.get_meta("preparation_id"))
	return "node:%s" % String(owner.name)


func _restore_focus(focus_key: String) -> void:
	if focus_key.is_empty():
		return
	call_deferred("_restore_focus_deferred", focus_key)


func _restore_focus_deferred(focus_key: String) -> void:
	if not is_inside_tree():
		return
	if focus_key.begins_with("model:"):
		var model_id := focus_key.trim_prefix("model:")
		for button in _model_buttons:
			if String(button.get_meta("preparation_id", "")) == model_id:
				button.grab_focus()
				return
	elif focus_key.begins_with("node:"):
		var target := find_child(focus_key.trim_prefix("node:"), true, false) as Control
		if target != null and target.visible and target.focus_mode != Control.FOCUS_NONE:
			target.grab_focus()


func _establish_initial_focus() -> void:
	var button := _slot_buttons.get(_selected_slot) as Button
	if button != null:
		button.grab_focus()


func _on_locale_changed(_locale: String) -> void:
	_apply_copy()
	refresh_from_profile(true)


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)


func _as_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary) if value is Dictionary else {}
