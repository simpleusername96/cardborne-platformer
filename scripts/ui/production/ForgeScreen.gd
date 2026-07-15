class_name ForgeScreen
extends Control

signal equipment_action_requested(action: StringName, model_id: StringName, slot_id: StringName)
signal leave_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const ModalShell = preload("res://scripts/ui/production/components/CenteredModalShell.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")

const SLOT_ORDER: Array[String] = ["melee", "ranged", "shield", "armor", "spirit_stone"]
const SLOT_LABELS := {
	"melee": "MELEE",
	"ranged": "RANGED",
	"shield": "SHIELD",
	"armor": "ARMOR",
	"spirit_stone": "SPIRIT STONE",
}
const MATERIAL_LABELS := {
	"rusted_scrap": "Iron Scrap",
	"common_timber": "Common Timber",
	"sky_thread": "Rough Fiber",
	"steel_fragment": "Steel Fragments",
	"hardwood": "Hardwood",
	"reinforced_fabric": "Reinforced Fabric",
}
const MATERIAL_ORDER: Array[String] = [
	"rusted_scrap", "common_timber", "sky_thread",
	"steel_fragment", "hardwood", "reinforced_fabric",
]

var _snapshot: Dictionary = {}
var _result: Dictionary = {}
var _heading: String = "TRAVELER FORGE"
var _selected_slot: String = "melee"
var _selected_model_id: String = ""
var _selected_model: Dictionary = {}
var _compact := false

var _modal: CenteredModalShell
var _page: VBoxContainer
var _title_label: Label
var _resource_row: HFlowContainer
var _tabs: HFlowContainer
var _body: HBoxContainer
var _model_panel: PanelContainer
var _model_list: VBoxContainer
var _detail_panel: PanelContainer
var _detail_scroll: ScrollContainer
var _detail_column: VBoxContainer
var _slot_label: Label
var _model_title: Label
var _state_label: Label
var _behavior_label: Label
var _weakness_label: Label
var _stats_grid: GridContainer
var _cost_label: Label
var _actions: HFlowContainer
var _status_label: Label
var _leave_button: Button
var _tab_buttons: Dictionary = {}
var _model_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compact = size.x <= 1000.0 or size.y <= 600.0
	_build_ui()
	if _snapshot.is_empty():
		var profile_state := get_node_or_null("/root/ProfileState")
		if profile_state != null and profile_state.has_method("get_preparation_snapshot"):
			_snapshot = profile_state.call("get_preparation_snapshot")
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	_render()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED or _page == null:
		return
	var compact := size.x <= 1000.0 or size.y <= 600.0
	if compact != _compact:
		_compact = compact
		_apply_layout()


func configure(
	snapshot: Dictionary,
	result: Dictionary = {},
	heading: String = "TRAVELER FORGE"
) -> void:
	_snapshot = snapshot.duplicate(true)
	_result = result.duplicate(true)
	_heading = heading
	if is_node_ready():
		_render()


func select_slot(slot_id: StringName) -> void:
	var key := String(slot_id)
	if not SLOT_ORDER.has(key):
		return
	_selected_slot = key
	_selected_model_id = ""
	_render_models()
	_render_detail()


func get_layout_snapshot() -> Dictionary:
	var tabs: Array[Dictionary] = []
	for slot_id in SLOT_ORDER:
		var tab := _tab_buttons.get(slot_id) as Button
		if tab != null:
			tabs.append({
				"slot": slot_id,
				"text": tab.text,
				"pressed": tab.button_pressed,
				"rect": tab.get_global_rect(),
			})
	var models: Array[Dictionary] = []
	for button in _model_buttons:
		models.append({
			"text": button.text,
			"disabled": button.disabled,
			"rect": button.get_global_rect(),
		})
	var actions: Array[Dictionary] = []
	for button in _action_buttons:
		actions.append({
			"text": button.text,
			"disabled": button.disabled,
			"rect": button.get_global_rect(),
		})
	return {
		"heading": _title_label.text if _title_label != null else "",
		"selected_slot": _selected_slot,
		"selected_model": _model_title.text if _model_title != null else "",
		"tabs": tabs,
		"models": models,
		"actions": actions,
		"model_panel_rect": _model_panel.get_global_rect() if _model_panel != null else Rect2(),
		"detail_panel_rect": _detail_panel.get_global_rect() if _detail_panel != null else Rect2(),
		"leave_rect": _leave_button.get_global_rect() if _leave_button != null else Rect2(),
		"panel_rect": _modal.panel_rect() if _modal != null else Rect2(),
		"status": _status_label.text if _status_label != null else "",
	}


func _build_ui() -> void:
	_modal = ModalShell.new()
	_modal.configure_size(Vector2(920.0, 680.0))
	_modal.close_requested.connect(func() -> void: leave_requested.emit())
	add_child(_modal)
	_page = _modal.content

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_page.add_child(header)
	var heading_column := VBoxContainer.new()
	heading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_column.add_theme_constant_override("separation", 0)
	header.add_child(heading_column)
	var eyebrow := Label.new()
	eyebrow.name = "ForgeEyebrow"
	Styles.configure_label(eyebrow, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	heading_column.add_child(eyebrow)
	_title_label = Label.new()
	Styles.configure_label(_title_label, Styles.TYPE_TITLE, Styles.TEXT)
	heading_column.add_child(_title_label)
	_leave_button = Button.new()
	_leave_button.custom_minimum_size = Vector2(132.0, Styles.TARGET_HEIGHT)
	Styles.apply_button(_leave_button, Styles.TEXT_MUTED, true)
	_leave_button.pressed.connect(func() -> void: leave_requested.emit())
	header.add_child(_leave_button)

	var resource_panel := PanelContainer.new()
	resource_panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.96), Styles.OUTLINE)
	)
	_page.add_child(resource_panel)
	var resource_margin := MarginContainer.new()
	resource_margin.add_theme_constant_override("margin_left", 12)
	resource_margin.add_theme_constant_override("margin_right", 12)
	resource_margin.add_theme_constant_override("margin_top", 7)
	resource_margin.add_theme_constant_override("margin_bottom", 7)
	resource_panel.add_child(resource_margin)
	_resource_row = HFlowContainer.new()
	_resource_row.add_theme_constant_override("separation", 18)
	_resource_row.add_theme_constant_override("v_separation", 6)
	resource_margin.add_child(_resource_row)

	_tabs = HFlowContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	_page.add_child(_tabs)
	for slot_id in SLOT_ORDER:
		var tab := Button.new()
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(148.0, Styles.TARGET_HEIGHT)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Styles.apply_button(tab, Styles.CYAN, true)
		tab.pressed.connect(func() -> void: select_slot(StringName(slot_id)))
		_tabs.add_child(tab)
		_tab_buttons[slot_id] = tab

	_body = HBoxContainer.new()
	_body.custom_minimum_size = Vector2(0.0, 300.0)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	_page.add_child(_body)
	_model_panel = PanelContainer.new()
	_model_panel.custom_minimum_size = Vector2(280.0, 0.0)
	_model_panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.96), Styles.OUTLINE)
	)
	_body.add_child(_model_panel)
	var model_margin := MarginContainer.new()
	model_margin.add_theme_constant_override("margin_left", 8)
	model_margin.add_theme_constant_override("margin_right", 8)
	model_margin.add_theme_constant_override("margin_top", 8)
	model_margin.add_theme_constant_override("margin_bottom", 8)
	_model_panel.add_child(model_margin)
	var model_scroll := ScrollContainer.new()
	model_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	model_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	model_margin.add_child(model_scroll)
	_model_list = VBoxContainer.new()
	_model_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_list.add_theme_constant_override("separation", 7)
	model_scroll.add_child(_model_list)

	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.96), Styles.CYAN)
	)
	_detail_panel.clip_contents = true
	_body.add_child(_detail_panel)
	var detail_margin := MarginContainer.new()
	for side in ["left", "right"]:
		detail_margin.add_theme_constant_override("margin_%s" % side, 18)
	for side in ["top", "bottom"]:
		detail_margin.add_theme_constant_override("margin_%s" % side, 13)
	_detail_panel.add_child(detail_margin)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_margin.add_child(_detail_scroll)
	_detail_column = VBoxContainer.new()
	_detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_column.add_theme_constant_override("separation", 7)
	_detail_scroll.add_child(_detail_column)
	_slot_label = Label.new()
	Styles.configure_label(_slot_label, Styles.TYPE_CAPTION, Styles.CYAN)
	_detail_column.add_child(_slot_label)
	_model_title = Label.new()
	Styles.configure_label(_model_title, 28, Styles.TEXT)
	_detail_column.add_child(_model_title)
	_state_label = Label.new()
	Styles.configure_label(_state_label, Styles.TYPE_CAPTION, Styles.AMBER)
	_detail_column.add_child(_state_label)
	_behavior_label = _wrapping_label(Styles.TYPE_BODY, Styles.TEXT, 3)
	_detail_column.add_child(_behavior_label)
	_weakness_label = _wrapping_label(Styles.TYPE_CAPTION, Styles.TEXT_MUTED, 2)
	_detail_column.add_child(_weakness_label)
	var separator := HSeparator.new()
	_detail_column.add_child(separator)
	_stats_grid = GridContainer.new()
	_stats_grid.columns = 3
	_stats_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_column.add_child(_stats_grid)
	_cost_label = _wrapping_label(Styles.TYPE_CAPTION, Styles.TEXT_MUTED, 2)
	_detail_column.add_child(_cost_label)
	_actions = HFlowContainer.new()
	_actions.alignment = FlowContainer.ALIGNMENT_END
	_actions.add_theme_constant_override("separation", 8)
	_detail_column.add_child(_actions)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(0.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	Styles.configure_label(_status_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_page.add_child(_status_label)
	_apply_layout()


func _apply_layout() -> void:
	_page.add_theme_constant_override("separation", 7 if _compact else 10)
	_model_panel.custom_minimum_size.x = 250.0 if _compact else 290.0
	_body.custom_minimum_size.y = 300.0 if _compact else 330.0
	_title_label.add_theme_font_size_override("font_size", 28 if _compact else Styles.TYPE_TITLE)
	_model_title.add_theme_font_size_override("font_size", 24 if _compact else 28)
	var eyebrow := _page.find_child("ForgeEyebrow", true, false) as Label
	if eyebrow != null:
		eyebrow.visible = not _compact
	_behavior_label.max_lines_visible = 1 if _compact else 3
	_weakness_label.visible = not _compact
	_cost_label.max_lines_visible = 1 if _compact else 2
	for tab_value in _tab_buttons.values():
		var tab := tab_value as Button
		tab.custom_minimum_size = Vector2(130.0 if _compact else 148.0, Styles.TARGET_HEIGHT)


func _render() -> void:
	var eyebrow := _page.find_child("ForgeEyebrow", true, false) as Label
	if eyebrow != null:
		eyebrow.text = _t("TRAVELER WORKBENCH")
	_title_label.text = _t(_heading)
	_leave_button.text = _t("Close")
	_render_resources()
	_render_tabs()
	_render_models()
	_render_detail()
	_render_status()
	call_deferred("_refresh_focus_path")


func _render_resources() -> void:
	_clear(_resource_row)
	var materials: Dictionary = _snapshot.get("materials", {})
	for material_id in MATERIAL_ORDER:
		var amount := int(materials.get(material_id, 0))
		if _compact and amount <= 0:
			continue
		var label := Label.new()
		label.text = "%s  %d" % [_t(MATERIAL_LABELS[material_id]), amount]
		Styles.configure_label(
			label,
			Styles.TYPE_CAPTION,
			Styles.AMBER if material_id in ["steel_fragment", "hardwood", "reinforced_fabric"] else Styles.TEXT_MUTED
		)
		_resource_row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_row.add_child(spacer)
	var supplies: Dictionary = _snapshot.get("ranged_supplies", {})
	var supply := Label.new()
	supply.text = _t("Arrows %d · Cartridges %d", [
		int(supplies.get("arrows", 0)),
		int(supplies.get("cartridges", 0)),
	])
	Styles.configure_label(supply, Styles.TYPE_CAPTION, Styles.CYAN)
	_resource_row.add_child(supply)


func _render_tabs() -> void:
	for slot_id in SLOT_ORDER:
		var tab := _tab_buttons.get(slot_id) as Button
		if tab == null:
			continue
		tab.text = _t(SLOT_LABELS[slot_id])
		tab.button_pressed = slot_id == _selected_slot
		Styles.apply_button(tab, Styles.AMBER if tab.button_pressed else Styles.CYAN, true)


func _render_models() -> void:
	_clear(_model_list)
	_model_buttons.clear()
	var options := _options_for_slot(_selected_slot)
	if options.is_empty():
		_selected_model_id = ""
		_selected_model = {}
		var empty := Label.new()
		empty.text = _t("No unlocked options yet.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Styles.configure_label(empty, Styles.TYPE_BODY, Styles.TEXT_MUTED)
		_model_list.add_child(empty)
		return
	if _selected_model_id.is_empty() or not _contains_model(options, _selected_model_id):
		_selected_model_id = String(options[0].get("model_id", options[0].get("id", "")))
	for option in options:
		var option_id := String(option.get("model_id", option.get("id", "")))
		var button := Button.new()
		button.name = "Model_%s" % option_id
		button.text = _model_button_text(option)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0.0, 58.0 if _compact else 66.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = _t(String(option.get("display_name", "Equipment")))
		var selected := option_id == _selected_model_id
		Styles.apply_character_card(button, Styles.AMBER if selected else Styles.CYAN, selected)
		button.pressed.connect(func() -> void: _select_model(option_id))
		_model_list.add_child(button)
		_model_buttons.append(button)
		if selected:
			_selected_model = option.duplicate(true)


func _render_detail() -> void:
	_clear(_stats_grid)
	_clear(_actions)
	_action_buttons.clear()
	if _selected_model.is_empty():
		_slot_label.text = _t(SLOT_LABELS.get(_selected_slot, "EQUIPMENT"))
		_model_title.text = _t("Nothing selected")
		_state_label.text = ""
		_behavior_label.text = ""
		_weakness_label.text = ""
		_cost_label.text = ""
		return
	if _selected_slot == "spirit_stone":
		_render_spirit_detail()
		return
	var model := _selected_model
	_slot_label.text = _t(SLOT_LABELS.get(_selected_slot, "EQUIPMENT"))
	_model_title.text = _t(String(model.get("display_name", "Equipment")))
	_state_label.text = _equipment_state_text(model)
	_behavior_label.text = _t(String(model.get("behavior", "")))
	_weakness_label.text = _t(
		"Tradeoff: %s", [_t(String(model.get("weakness", "None")))]
	)
	var current: Dictionary = model.get("runtime", {})
	var preview := _primary_preview(model)
	var result_runtime: Dictionary = preview.get("result_runtime", {})
	_render_runtime_stats(_selected_slot, current, result_runtime)
	_cost_label.text = _preview_cost_text(preview)
	_build_equipment_actions(model)


func _render_spirit_detail() -> void:
	var stone := _selected_model
	_slot_label.text = _t("PASSIVE SPIRIT STONE")
	_model_title.text = _t(String(stone.get("display_name", "Spirit Stone")))
	_state_label.text = _t("EQUIPPED") if bool(stone.get("equipped", false)) else (
		_t("AVAILABLE") if bool(stone.get("unlocked", false)) else _t("NOT ATTUNED")
	)
	_behavior_label.text = _t(String(stone.get("description", "")))
	_weakness_label.text = _t(
		"Limit: %s", [_t(String(stone.get("weakness", "None")))]
	)
	_add_stat_row("Trigger", _t("Passive"), _t("No input"))
	_cost_label.text = _t("Spirit Stones grant one passive effect.")
	_add_action_button(
		"Equip",
		&"equip",
		bool(stone.get("unlocked", false)) and not bool(stone.get("equipped", false)),
		String(stone.get("id", "")),
		&"spirit_stone",
		"Attune this Spirit Stone" if bool(stone.get("unlocked", false)) else "Find this Spirit Stone first"
	)


func _build_equipment_actions(model: Dictionary) -> void:
	var model_id := String(model.get("model_id", ""))
	var slot_id := StringName(model.get("slot", _selected_slot))
	if not bool(model.get("crafted", false)):
		var craft: Dictionary = model.get("craft", {})
		_add_action_button(
			"Craft",
			&"craft",
			bool(craft.get("can_execute", false)),
			model_id,
			slot_id,
			String(craft.get("reason", "Crafting unavailable"))
		)
		return
	_add_action_button(
		"Equip",
		&"equip",
		not bool(model.get("equipped", false)),
		model_id,
		slot_id,
		"Already equipped" if bool(model.get("equipped", false)) else "Equip this model"
	)
	var recraft: Dictionary = model.get("recraft", {})
	_add_action_button(
		"Upgrade to Grade 2",
		&"recraft",
		bool(recraft.get("can_execute", false)),
		model_id,
		slot_id,
		String(recraft.get("reason", "Recrafting unavailable"))
	)
	var repair: Dictionary = model.get("repair", {})
	if bool((repair.get("model", {}) as Dictionary).get("has_condition", false)):
		_add_action_button(
			"Repair",
			&"repair",
			bool(repair.get("can_execute", false)),
			model_id,
			slot_id,
			String(repair.get("reason", "Repair unavailable"))
		)


func _add_action_button(
	label: String,
	action: StringName,
	enabled: bool,
	model_id: String,
	slot_id: StringName,
	reason: String
) -> void:
	var button := Button.new()
	button.text = _t(label)
	button.custom_minimum_size = Vector2(150.0, Styles.TARGET_HEIGHT)
	button.disabled = not enabled
	button.tooltip_text = _t(reason)
	Styles.apply_button(button, Styles.AMBER if enabled else Styles.OUTLINE)
	button.pressed.connect(func() -> void:
		equipment_action_requested.emit(action, StringName(model_id), slot_id)
	)
	_actions.add_child(button)
	_action_buttons.append(button)


func _render_runtime_stats(
	slot_id: String,
	current: Dictionary,
	result: Dictionary
) -> void:
	match slot_id:
		"melee", "ranged":
			_add_runtime_stat("Damage", "damage", current, result)
			_add_runtime_stat("Reach", "reach", current, result, " px")
			_add_runtime_stat("Recovery", "recovery_seconds", current, result, " s", 2)
			if not _compact:
				_add_runtime_stat("Stagger", "stagger_damage", current, result)
				_add_runtime_stat("Startup", "startup_seconds", current, result, " s", 2)
			if slot_id == "ranged" and not _compact:
				_add_runtime_stat("Capacity", "maximum_ranged_resource", current, result)
		"shield":
			_add_runtime_stat("Stability", "guard_stability", current, result)
			_add_runtime_stat("Guard Arc", "guard_angle_degrees", current, result, " deg")
			_add_runtime_stat("Condition", "condition", current, result)
			if not _compact:
				_add_runtime_stat("Precise Guard", "precise_guard_window_seconds", current, result, " s", 2)
				_add_runtime_stat("Move While Guarding", "guard_move_speed_multiplier", current, result, "x", 2)
		"armor":
			_add_runtime_stat("Max HP", "max_health_bonus", current, result, " bonus")
			_add_runtime_stat("Knockback Resist", "knockback_reduction_fraction", current, result, "%", 0, 100.0)
			_add_runtime_stat("Dash Delay", "dash_cooldown_addition_seconds", current, result, " s", 2)


func _add_runtime_stat(
	label: String,
	key: String,
	current: Dictionary,
	result: Dictionary,
	suffix: String = "",
	decimals: int = 0,
	scale: float = 1.0
) -> void:
	var before_text := "--"
	if current.has(key):
		before_text = _number_text(float(current.get(key, 0.0)) * scale, decimals) + suffix
	var after_text := before_text
	if result.has(key):
		after_text = _number_text(float(result.get(key, 0.0)) * scale, decimals) + suffix
	_add_stat_row(label, before_text, after_text)


func _add_stat_row(label_text: String, current_text: String, result_text: String) -> void:
	var label := Label.new()
	label.text = _t(label_text)
	Styles.configure_label(label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	_stats_grid.add_child(label)
	var current := Label.new()
	current.text = current_text
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(current, Styles.TYPE_CAPTION, Styles.TEXT)
	_stats_grid.add_child(current)
	var result := Label.new()
	result.text = result_text if result_text == current_text else "%s -> %s" % [current_text, result_text]
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(
		result,
		Styles.TYPE_CAPTION,
		Styles.MOSS if result_text != current_text else Styles.TEXT_MUTED
	)
	_stats_grid.add_child(result)


func _render_status() -> void:
	if _result.is_empty():
		_status_label.text = _t("Choose equipment to see its cost and result.")
		_status_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
		return
	_status_label.text = _t(String(_result.get("message", "Equipment updated.")))
	_status_label.add_theme_color_override(
		"font_color", Styles.MOSS if bool(_result.get("ok", false)) else Styles.CORAL
	)


func _select_model(model_id: String) -> void:
	_selected_model_id = model_id
	_render_models()
	_render_detail()
	if not _action_buttons.is_empty():
		_focus_action(_action_buttons[0])


func _focus_action(button: Button) -> void:
	button.grab_focus()
	if _detail_scroll != null:
		_detail_scroll.ensure_control_visible(button)


func _options_for_slot(slot_id: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if slot_id == "spirit_stone":
		for stone_value in _snapshot.get("spirit_stones", []):
			if stone_value is Dictionary:
				options.append((stone_value as Dictionary).duplicate(true))
		return options
	for slot_value in _snapshot.get("slots", []):
		if not slot_value is Dictionary:
			continue
		var slot := slot_value as Dictionary
		if String(slot.get("slot", "")) != slot_id:
			continue
		for option_value in slot.get("options", []):
			if option_value is Dictionary:
				options.append((option_value as Dictionary).duplicate(true))
		break
	return options


func _contains_model(options: Array[Dictionary], model_id: String) -> bool:
	for option in options:
		if String(option.get("model_id", option.get("id", ""))) == model_id:
			return true
	return false


func _model_button_text(option: Dictionary) -> String:
	var title := _t(String(option.get("display_name", "Equipment")))
	if _selected_slot == "spirit_stone":
		if bool(option.get("equipped", false)):
			return "%s\n%s" % [title, _t("Equipped")]
		return "%s\n%s" % [
			title,
			_t("Available") if bool(option.get("unlocked", false)) else _t("Not attuned"),
		]
	if bool(option.get("equipped", false)):
		return "%s\n%s" % [title, _t("Equipped")]
	if bool(option.get("crafted", false)):
		var grade := String((option.get("runtime", {}) as Dictionary).get("grade_id", "grade_1"))
		return "%s\n%s" % [
			title,
			_t("Grade 2") if grade == "grade_2" else _t("Grade 1"),
		]
	if not bool(option.get("blueprint_unlocked", false)):
		return "%s\n%s" % [title, _t("Blueprint needed")]
	return "%s\n%s" % [title, _t("Ready to craft")]


func _equipment_state_text(model: Dictionary) -> String:
	if not bool(model.get("crafted", false)):
		return _t("BLUEPRINT READY") if bool(model.get("blueprint_unlocked", false)) else _t("BLUEPRINT NOT FOUND")
	var runtime: Dictionary = model.get("runtime", {})
	var grade := _t("GRADE 2") if String(runtime.get("grade_id", "")) == "grade_2" else _t("GRADE 1")
	var equipped := "  /  %s" % _t("EQUIPPED") if bool(model.get("equipped", false)) else ""
	if float(runtime.get("maximum_condition", 0.0)) > 0.0:
		return _t("%s%s / CONDITION %d%%", [
			grade,
			equipped,
			roundi(float(runtime.get("condition_ratio", 0.0)) * 100.0),
		])
	return "%s%s" % [grade, equipped]


func _primary_preview(model: Dictionary) -> Dictionary:
	if not bool(model.get("crafted", false)):
		return model.get("craft", {})
	var runtime: Dictionary = model.get("runtime", {})
	if String(runtime.get("grade_id", "")) != "grade_2":
		return model.get("recraft", {})
	return model.get("repair", {})


func _preview_cost_text(preview: Dictionary) -> String:
	var costs: Dictionary = preview.get("costs", {})
	if costs.is_empty():
		return _t(String(preview.get("reason", "No material cost.")))
	var parts: Array[String] = []
	var ids := costs.keys()
	ids.sort()
	var owned: Dictionary = preview.get("owned_amounts", {})
	for material_value in ids:
		var material_id := String(material_value)
		parts.append("%s %d/%d" % [
			_t(MATERIAL_LABELS.get(material_id, "Material")),
			int(owned.get(material_id, 0)),
			int(costs.get(material_id, 0)),
		])
	return _t("Materials: %s", [" · ".join(parts)])


func _refresh_focus_path() -> void:
	if _modal == null:
		return
	var controls: Array[Control] = []
	for slot_id in SLOT_ORDER:
		var tab := _tab_buttons.get(slot_id) as Button
		if tab != null:
			controls.append(tab)
	for button in _model_buttons:
		controls.append(button)
	for button in _action_buttons:
		controls.append(button)
	controls.append(_leave_button)
	_modal.link_vertical_focus(controls)
	var first := _tab_buttons.get(_selected_slot) as Button
	if first != null and get_viewport().gui_get_focus_owner() == null:
		first.grab_focus()


func _on_locale_changed(_locale: String) -> void:
	_render()


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)


func _number_text(value: float, decimals: int) -> String:
	if decimals <= 0:
		return str(roundi(value))
	return ("%.*f" % [decimals, value]).trim_suffix("0").trim_suffix(".")


func _wrapping_label(font_size: int, color: Color, max_lines: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = max_lines
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(label, font_size, color)
	return label


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
