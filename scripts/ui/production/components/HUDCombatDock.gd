class_name HUDCombatDock
extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Glyph = preload("res://scripts/ui/production/components/HUDGlyph.gd")

const POTION_LABELS := {
	"small_potion": "Small Potion",
}

var _run_snapshot: Dictionary = {}
var _combat_snapshot: Dictionary = {}
var _compact := false

var _row: HBoxContainer
var _safe_gap: Control
var _attack_panel: PanelContainer
var _melee_panel: PanelContainer
var _ranged_panel: PanelContainer
var _melee_name: Label
var _melee_state: Label
var _ranged_name: Label
var _ranged_state: Label
var _guard_panel: PanelContainer
var _guard_name: Label
var _guard_condition: Label
var _guard_stability: Label
var _spirit_panel: PanelContainer
var _spirit_name: Label
var _spirit_state: Label
var _potion_panel: PanelContainer
var _potion_name: Label
var _potion_count: Label
var _input_labels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_apply_layout()
	_render()


func configure(run_snapshot: Dictionary, combat_snapshot: Dictionary) -> void:
	_run_snapshot = run_snapshot.duplicate(true)
	_combat_snapshot = combat_snapshot.duplicate(true)
	if is_node_ready():
		_render()


func set_compact(compact: bool) -> void:
	if _compact == compact:
		return
	_compact = compact
	if is_node_ready():
		_apply_layout()
		_render()


func get_display_snapshot() -> Dictionary:
	var intent: Dictionary = _combat_snapshot.get("committed_intent", {})
	return {
		"rect": get_rect(),
		"safe_gap_rect": _local_rect(_safe_gap),
		"attack_rect": _local_rect(_attack_panel),
		"guard_rect": _local_rect(_guard_panel),
		"spirit_rect": _local_rect(_spirit_panel),
		"potion_rect": _local_rect(_potion_panel),
		"intent": String(intent.get("mode", "")),
		"melee": {
			"name": _melee_name.text,
			"state": _melee_state.text,
			"active": String(intent.get("mode", "")) == "melee",
		},
		"ranged": {
			"name": _ranged_name.text,
			"state": _ranged_state.text,
			"active": String(intent.get("mode", "")) == "ranged",
		},
		"guard": {
			"name": _guard_name.text,
			"condition": _guard_condition.text,
			"stability": _guard_stability.text,
			"phase": String((_combat_snapshot.get("guard", {}) as Dictionary).get("phase", "idle")),
			"outcome": String((_combat_snapshot.get("defense_feedback", {}) as Dictionary).get("outcome", "")),
			"reason": String((_combat_snapshot.get("defense_feedback", {}) as Dictionary).get("reason", "")),
			"feedback_visible": bool((_combat_snapshot.get("defense_feedback", {}) as Dictionary).get("active", false)),
		},
		"spirit": {"name": _spirit_name.text, "state": _spirit_state.text},
		"potion": {"name": _potion_name.text, "count": _potion_count.text},
	}


func _build_ui() -> void:
	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 6)
	add_child(_row)

	_attack_panel = _panel(Styles.AMBER)
	_row.add_child(_attack_panel)
	var attack_margin := _margin(8, 6, 8, 6)
	_attack_panel.add_child(attack_margin)
	var attack_column := VBoxContainer.new()
	attack_column.add_theme_constant_override("separation", 4)
	attack_margin.add_child(attack_column)
	attack_column.add_child(_header("attack", "attack", "X", "ATTACK", Styles.AMBER))
	var attack_pair := HBoxContainer.new()
	attack_pair.add_theme_constant_override("separation", 4)
	attack_column.add_child(attack_pair)
	var melee := _attack_choice("melee", "MELEE")
	_melee_panel = melee["panel"]
	_melee_name = melee["name"]
	_melee_state = melee["state"]
	attack_pair.add_child(_melee_panel)
	var ranged := _attack_choice("ranged", "RANGED")
	_ranged_panel = ranged["panel"]
	_ranged_name = ranged["name"]
	_ranged_state = ranged["state"]
	attack_pair.add_child(_ranged_panel)

	_safe_gap = Control.new()
	_safe_gap.name = "PlayerSafeGap"
	_safe_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_safe_gap)

	var guard := _status_panel("guard", "guard", "C", "GUARD", Styles.CYAN)
	_guard_panel = guard["panel"]
	_guard_name = guard["name"]
	_guard_condition = guard["primary"]
	_guard_stability = guard["secondary"]
	_row.add_child(_guard_panel)

	var spirit := _status_panel("spirit", "", "", "SPIRIT", Styles.MOSS)
	_spirit_panel = spirit["panel"]
	_spirit_name = spirit["name"]
	_spirit_state = spirit["primary"]
	(spirit["secondary"] as Label).visible = false
	_row.add_child(_spirit_panel)

	var potion := _status_panel(
		"potion", "use_consumable", "A", "POTION", Color("63b987")
	)
	_potion_panel = potion["panel"]
	_potion_name = potion["name"]
	_potion_count = potion["primary"]
	(potion["secondary"] as Label).visible = false
	_row.add_child(_potion_panel)


func _attack_choice(icon_id: StringName, fallback_name: String) -> Dictionary:
	var panel := _panel(Styles.OUTLINE)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := _margin(4, 3, 4, 3)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	var glyph := Glyph.new()
	glyph.custom_minimum_size = Vector2(18.0, 18.0)
	glyph.configure(icon_id, Styles.AMBER if icon_id == &"melee" else Styles.CYAN)
	row.add_child(glyph)
	var name := _label(fallback_name, 10, Styles.TEXT_MUTED)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var state := _label("--", 11, Styles.TEXT)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(state)
	return {"panel": panel, "name": name, "state": state}


func _status_panel(
	icon_id: StringName,
	input_action: String,
	input_fallback: String,
	title: String,
	accent: Color
) -> Dictionary:
	var panel := _panel(accent)
	var margin := _margin(7, 6, 7, 5)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	column.add_child(_header(icon_id, input_action, input_fallback, title, accent))
	var name := _label("--", 11, Styles.TEXT)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(name)
	var primary := _label("--", 11, Styles.TEXT_MUTED)
	primary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(primary)
	var secondary := _label("--", 10, Styles.TEXT_MUTED)
	secondary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(secondary)
	return {
		"panel": panel,
		"name": name,
		"primary": primary,
		"secondary": secondary,
	}


func _header(
	icon_id: StringName,
	input_action: String,
	input_fallback: String,
	title: String,
	accent: Color
) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var glyph := Glyph.new()
	glyph.custom_minimum_size = Vector2(16.0, 16.0)
	glyph.configure(icon_id, accent)
	row.add_child(glyph)
	var title_label := _label(title, 10, accent)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	if not input_fallback.is_empty():
		var input := _label(input_fallback, 11, Styles.TEXT)
		input.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input.custom_minimum_size = Vector2(28.0, 18.0)
		input.add_theme_stylebox_override(
			"normal", Styles.panel_style(Color("101518"), Color(accent, 0.8), 1)
		)
		_input_labels[input_action] = input
		row.add_child(input)
	return row


func _apply_layout() -> void:
	custom_minimum_size = Vector2(724.0 if _compact else 810.0, 92.0)
	_attack_panel.custom_minimum_size = Vector2(196.0 if _compact else 224.0, 92.0)
	_safe_gap.custom_minimum_size = Vector2(120.0 if _compact else 150.0, 92.0)
	_guard_panel.custom_minimum_size = Vector2(132.0 if _compact else 148.0, 92.0)
	_spirit_panel.custom_minimum_size = Vector2(132.0 if _compact else 148.0, 92.0)
	_potion_panel.custom_minimum_size = Vector2(92.0 if _compact else 108.0, 92.0)


func _render() -> void:
	if _melee_name == null:
		return
	for input_action in _input_labels:
		var input := _input_labels[input_action] as Label
		var fallback := String(
			{"attack": "X", "guard": "C", "use_consumable": "A"}.get(
				input_action, "--"
			)
		)
		input.text = Game.get_action_binding_text(input_action, fallback)

	var loadout: Dictionary = _combat_snapshot.get("loadout", {})
	var intent: Dictionary = _combat_snapshot.get("committed_intent", {})
	var intent_mode := String(intent.get("mode", ""))
	_melee_name.text = _compact_name(String(loadout.get("melee_display_name", "Melee")))
	_melee_state.text = "CND %s" % _percent(
		int(loadout.get("melee_condition", 0)),
		int(loadout.get("melee_maximum_condition", 0))
	)
	_ranged_name.text = _compact_name(String(loadout.get("ranged_display_name", "Ranged")))
	_ranged_state.text = "%s %d/%d" % [
		_supply_label(String(loadout.get("ranged_resource_id", ""))),
		maxi(int(loadout.get("ranged_resource_count", 0)), 0),
		maxi(int(loadout.get("ranged_resource_maximum", 0)), 0),
	]
	_apply_choice_style(_melee_panel, Styles.AMBER, intent_mode == "melee")
	_apply_choice_style(_ranged_panel, Styles.CYAN, intent_mode == "ranged")

	var shield_name := _compact_name(String(loadout.get("shield_display_name", "Shield")))
	var shield_condition := _percent(
		int(loadout.get("shield_condition", 0)),
		int(loadout.get("shield_maximum_condition", 0))
	)
	var guard: Dictionary = _combat_snapshot.get("guard", {})
	var stability_percent := int(round(
		clampf(float(guard.get("stability_fraction", 0.0)), 0.0, 1.0) * 100.0
	))
	var feedback: Dictionary = _combat_snapshot.get("defense_feedback", {})
	var feedback_active := bool(feedback.get("active", false))
	var phase := StringName(guard.get("phase", &"idle"))
	_guard_name.text = _guard_title(shield_name, phase, feedback, feedback_active)
	_guard_condition.text = "Condition %s" % shield_condition
	_guard_stability.text = "Stability %d%%" % stability_percent
	if feedback_active:
		var condition_cost := maxi(int(feedback.get("condition_cost", 0)), 0)
		var stability_cost := maxi(int(feedback.get("stability_cost", 0)), 0)
		var damage := maxi(int(feedback.get("damage", 0)), 0)
		if condition_cost > 0:
			_guard_condition.text = "-%d CND  •  %s" % [condition_cost, shield_condition]
		elif StringName(feedback.get("outcome", &"")) == &"precise_block":
			_guard_condition.text = "CND: NO COST"
		if stability_cost > 0:
			_guard_stability.text = "-%d STB  •  %d%%" % [stability_cost, stability_percent]
		elif damage > 0:
			_guard_stability.text = "DAMAGE %d  •  %d%%" % [damage, stability_percent]
	_apply_guard_style(phase, feedback, feedback_active)

	var spirit: Dictionary = _combat_snapshot.get("spirit", {})
	_spirit_name.text = _compact_name(String(loadout.get("spirit_stone_display_name", "Spirit Stone")))
	_spirit_state.text = _spirit_status(spirit)

	var consumable_id := String(_run_snapshot.get("consumable_id", ""))
	var charges := maxi(int(_run_snapshot.get("consumable_charges", 0)), 0)
	_potion_name.text = POTION_LABELS.get(consumable_id, "No Potion")
	_potion_count.text = "x%d" % charges if charges > 0 else "EMPTY"
	_potion_count.add_theme_color_override("font_color", Styles.TEXT if charges > 0 else Styles.TEXT_MUTED)


func _spirit_status(spirit: Dictionary) -> String:
	var trigger := String(spirit.get("trigger", ""))
	if trigger == "direct_attack_sequence":
		return "%d/4 direct hits" % clampi(int(spirit.get("direct_attack_count", 0)), 0, 4)
	if trigger == "precise_guard":
		return "Precise guard"
	return "Passive"


func _apply_choice_style(panel: PanelContainer, accent: Color, active: bool) -> void:
	panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(
			Color(Styles.SURFACE_RAISED, 0.98 if active else 0.72),
			accent if active else Styles.OUTLINE,
			2 if active else 1
		)
	)


func _guard_title(
	shield_name: String,
	phase: StringName,
	feedback: Dictionary,
	feedback_active: bool
) -> String:
	if feedback_active:
		return String(feedback.get("label", "GUARD"))
	return {
		&"startup": "RAISING  •  %s" % shield_name,
		&"active": "ACTIVE  •  %s" % shield_name,
		&"recovery": "RECOVER  •  %s" % shield_name,
	}.get(phase, shield_name)


func _apply_guard_style(
	phase: StringName,
	feedback: Dictionary,
	feedback_active: bool
) -> void:
	var outcome := StringName(feedback.get("outcome", &"")) if feedback_active else &""
	var accent := Styles.OUTLINE
	var width := 1
	var title_color := Styles.TEXT
	if phase in [&"startup", &"active"]:
		accent = Styles.CYAN
		width = 2
	if phase == &"recovery":
		title_color = Styles.TEXT_MUTED
	match outcome:
		&"normal_block":
			accent = Styles.CYAN
			width = 3
			title_color = Styles.CYAN.lightened(0.2)
		&"precise_block":
			accent = Styles.AMBER
			width = 3
			title_color = Styles.AMBER.lightened(0.2)
		&"guard_break", &"guard_failed":
			accent = Styles.CORAL
			width = 3 if outcome == &"guard_break" else 2
			title_color = Styles.CORAL.lightened(0.2)
	_guard_panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.96), accent, width)
	)
	_guard_name.add_theme_color_override("font_color", title_color)


func _compact_name(value: String) -> String:
	var always_short := String({
		"Traveler Sword": "Sword",
		"Hunting Spear": "Spear",
	}.get(value, value))
	if not _compact:
		return always_short
	return {
		"Hunting Bow": "Bow",
		"Round Shield": "Round Shield",
		"Ember Spirit Stone": "Ember Stone",
		"Frost Spirit Stone": "Frost Stone",
	}.get(always_short, always_short)


func _supply_label(resource_id: String) -> String:
	return {"arrows": "ARROW", "cartridges": "SHOT"}.get(resource_id, "AMMO")


func _percent(current: int, maximum: int) -> String:
	if maximum <= 0:
		return "--"
	return "%d%%" % int(round(clampf(float(current) / float(maximum), 0.0, 1.0) * 100.0))


func _panel(border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.96), border, 1)
	)
	return panel


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(label, font_size, color)
	return label


func _local_rect(control: Control) -> Rect2:
	return Rect2(control.global_position - global_position, control.size)
