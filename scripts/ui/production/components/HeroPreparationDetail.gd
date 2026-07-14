class_name HeroPreparationDetail
extends PanelContainer

signal equipment_command_requested(action: StringName, model_id: StringName, slot: StringName)
signal spirit_stone_equip_requested(stone_id: StringName)

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

const MATERIAL_LABELS := {
	"rusted_scrap": "Iron Scrap",
	"steel_fragment": "Steel Fragment",
	"common_timber": "Common Timber",
	"hardwood": "Hardwood",
	"sky_thread": "Rough Fiber",
	"reinforced_fabric": "Reinforced Fabric",
}
const MATERIAL_ORDER: Array[String] = [
	"rusted_scrap",
	"steel_fragment",
	"common_timber",
	"hardwood",
	"sky_thread",
	"reinforced_fabric",
]
const SLOT_LABELS := {
	"melee": "MELEE",
	"ranged": "RANGED",
	"shield": "SHIELD",
	"armor": "ARMOR",
}
const SUPPLY_LABELS := {
	"arrows": "Arrows",
	"cartridges": "Cartridges",
}

@onready var _margin: MarginContainer = $Margin
@onready var _content: VBoxContainer = $Margin/Content
@onready var _context_label: Label = %ContextLabel
@onready var _state_label: Label = %StateLabel
@onready var _title_label: Label = %TitleLabel
@onready var _behavior_heading: Label = %BehaviorHeading
@onready var _behavior_label: Label = %BehaviorLabel
@onready var _weakness_heading: Label = %WeaknessHeading
@onready var _weakness_label: Label = %WeaknessLabel
@onready var _stats_heading: Label = %StatsHeading
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _condition_label: Label = %ConditionLabel
@onready var _cost_label: Label = %CostLabel
@onready var _reason_label: Label = %ReasonLabel
@onready var _action_button: Button = %PrimaryActionButton

var _kind: StringName = &"unavailable"
var _action: StringName
var _model_id: StringName
var _slot_id: StringName
var _stone_id: StringName
var _compact := false


func _ready() -> void:
	add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.97), Styles.OUTLINE)
	)
	Styles.apply_button(_action_button, Styles.AMBER)
	_action_button.pressed.connect(_on_action_pressed)
	_apply_density()


func configure_equipment(
	decision: Dictionary,
	supplies: Dictionary,
	compact: bool = false
) -> void:
	_kind = &"equipment"
	_compact = compact
	_action = &""
	_model_id = StringName(String(decision.get("model_id", "")))
	_slot_id = StringName(String(decision.get("slot", "")))
	_stone_id = &""
	_apply_density()
	if not bool(decision.get("ok", false)):
		_render_unavailable("Equipment unavailable", "This model cannot be inspected right now.")
		return
	_render_equipment(decision.duplicate(true), supplies.duplicate(true))


func configure_spirit_stone(stone: Dictionary, compact: bool = false) -> void:
	_kind = &"spirit_stone"
	_compact = compact
	_action = &""
	_model_id = &""
	_slot_id = &"spirit_stone"
	_stone_id = StringName(String(stone.get("id", "")))
	_apply_density()
	if _stone_id == &"" or String(stone.get("display_name", "")).strip_edges().is_empty():
		_render_unavailable("Spirit Stone unavailable", "No Stone can be inspected right now.")
		return

	_context_label.text = "SPIRIT STONE"
	_title_label.text = String(stone.get("display_name", "Spirit Stone"))
	_behavior_label.text = String(stone.get("description", "Passive effect unavailable."))
	_weakness_label.text = String(stone.get("weakness", "No weakness description available."))
	_clear_stats()
	_add_stat("TYPE", "Passive")
	_add_stat("TRIGGER", "Automatic")
	_condition_label.text = "Activates when its stated condition is met."
	_cost_label.text = ""
	_cost_label.visible = false

	var unlocked := bool(stone.get("unlocked", false))
	var equipped := bool(stone.get("equipped", false))
	_state_label.text = "EQUIPPED" if equipped else ("OWNED" if unlocked else "LOCKED")
	if equipped:
		_reason_label.text = "This passive is active for the next stage."
		_set_action("Equipped", false)
	elif unlocked:
		_reason_label.text = "Ready to equip."
		_set_action("Equip Spirit Stone", true)
	else:
		_reason_label.text = "Discover this Spirit Stone before equipping it."
		_set_action("Locked", false)


func configure_consumable(consumable_id: StringName, compact: bool = false) -> void:
	_kind = &"consumable"
	_compact = compact
	_action = &""
	_model_id = &""
	_slot_id = &"consumable"
	_stone_id = &""
	_apply_density()

	_context_label.text = "CONSUMABLE"
	_state_label.text = "PREPARED"
	_title_label.text = "Healing Potion" if consumable_id == &"small_potion" else "Recovery Item"
	_behavior_label.text = "Restores 2 health and is not spent when health is already full."
	_weakness_label.text = "One use is prepared for the next stage."
	_clear_stats()
	_add_stat("RECOVERY", "2 health")
	_add_stat("USES", "1")
	_condition_label.text = "Carried with the Traveler's loadout."
	_cost_label.text = ""
	_cost_label.visible = false
	_reason_label.text = "Ready for Stage 1."
	_set_action("Prepared", false)


func configure_unavailable(title: String, message: String, compact: bool = false) -> void:
	_kind = &"unavailable"
	_compact = compact
	_action = &""
	_model_id = &""
	_slot_id = &""
	_stone_id = &""
	_apply_density()
	_render_unavailable(title, message)


func _render_equipment(decision: Dictionary, supplies: Dictionary) -> void:
	var slot := String(decision.get("slot", ""))
	var crafted := bool(decision.get("crafted", false))
	var equipped := bool(decision.get("equipped", false))
	var blueprint_unlocked := bool(decision.get("blueprint_unlocked", false))
	var runtime := _as_dictionary(decision.get("runtime", {}))
	_action = _choose_equipment_action(decision, runtime, crafted, equipped)
	var preview := _as_dictionary(decision.get(String(_action), {}))
	var result_runtime := _as_dictionary(preview.get("result_runtime", {}))
	if result_runtime.is_empty():
		result_runtime = runtime.duplicate(true)

	_context_label.text = String(SLOT_LABELS.get(slot, "EQUIPMENT"))
	_title_label.text = String(decision.get("display_name", "Equipment"))
	_behavior_label.text = String(decision.get("behavior", "Behavior unavailable."))
	_weakness_label.text = String(decision.get("weakness", "Weakness unavailable."))
	_state_label.text = _equipment_state_text(
		crafted,
		equipped,
		blueprint_unlocked,
		runtime,
		result_runtime
	)

	_clear_stats()
	_render_equipment_stats(slot, runtime, result_runtime)
	_render_condition_or_supply(slot, runtime, result_runtime, supplies, crafted)
	_render_cost(preview)
	_render_equipment_action(preview, crafted, equipped)


func _choose_equipment_action(
	decision: Dictionary,
	runtime: Dictionary,
	crafted: bool,
	equipped: bool
) -> StringName:
	if not crafted:
		return &"craft"
	if not equipped:
		return &"equip"
	var maximum := float(runtime.get("maximum_condition", 0.0))
	var current := float(runtime.get("condition", maximum))
	if maximum > 0.0 and current < maximum and not is_equal_approx(current, maximum):
		return &"repair"
	if String(runtime.get("grade_id", "")) != "grade_2":
		return &"recraft"
	return &""


func _equipment_state_text(
	crafted: bool,
	equipped: bool,
	blueprint_unlocked: bool,
	runtime: Dictionary,
	result_runtime: Dictionary
) -> String:
	var grade_source := runtime if crafted else result_runtime
	var grade := _grade_text(String(grade_source.get("grade_id", "")))
	if equipped:
		return "EQUIPPED • %s" % grade
	if crafted:
		return "OWNED • %s" % grade
	if blueprint_unlocked:
		return "BLUEPRINT • %s" % grade
	return "LOCKED • %s" % grade


func _render_equipment_stats(
	slot: String,
	current: Dictionary,
	result: Dictionary
) -> void:
	match slot:
		"melee", "ranged":
			_add_stat("DAMAGE", _number_transition(current, result, "damage"))
			_add_stat("REACH", _distance_transition(current, result, "reach"))
			_add_stat("POSTURE", _number_transition(current, result, "stagger_damage"))
			_add_stat("RECOVERY", _seconds_transition(current, result, "recovery_seconds"))
			if slot == "ranged" and float(result.get("reload_seconds", 0.0)) > 0.0:
				_add_stat("RELOAD", _seconds_transition(current, result, "reload_seconds"))
		"shield":
			_add_stat("STABILITY", _number_transition(current, result, "guard_stability"))
			_add_stat("COVERAGE", _degrees_transition(current, result, "guard_angle_degrees"))
			_add_stat("RAISE", _seconds_transition(current, result, "startup_seconds"))
			_add_stat("LOWER", _seconds_transition(current, result, "recovery_seconds"))
		"armor":
			_add_stat("HEALTH", _signed_transition(current, result, "max_health_bonus"))
			_add_stat("KNOCKBACK", _percent_transition(
				current,
				result,
				"knockback_reduction_fraction"
			))
			_add_stat("DASH BURDEN", _seconds_transition(
				current,
				result,
				"dash_cooldown_addition_seconds"
			))
		_:
			_add_stat("DETAILS", "Unavailable")


func _render_condition_or_supply(
	slot: String,
	current: Dictionary,
	result: Dictionary,
	supplies: Dictionary,
	crafted: bool
) -> void:
	if slot == "ranged":
		var supply_id := String(result.get("ranged_resource_id", current.get("ranged_resource_id", "")))
		var current_supply := int(supplies.get(supply_id, 0))
		var maximum_supply := int(result.get(
			"maximum_ranged_resource",
			current.get("maximum_ranged_resource", 0)
		))
		_condition_label.text = "%s  %d / %d" % [
			String(SUPPLY_LABELS.get(supply_id, "Supply")),
			current_supply,
			maximum_supply,
		]
		return

	var maximum := float(current.get("maximum_condition", result.get("maximum_condition", 0.0)))
	if maximum <= 0.0:
		_condition_label.text = "Condition  —  Not used by this slot"
		return
	var condition := float(current.get("condition", maximum))
	var result_condition := float(result.get("condition", condition))
	var result_maximum := float(result.get("maximum_condition", maximum))
	if not crafted:
		_condition_label.text = "Condition after craft  %d / %d" % [
			int(round(result_condition)),
			int(round(result_maximum)),
		]
		return
	var state := "Worn" if is_zero_approx(condition) else ("Low" if condition / maximum <= 0.25 else "Ready")
	var condition_text := "%d / %d" % [int(round(condition)), int(round(maximum))]
	if not is_equal_approx(condition, result_condition) or not is_equal_approx(maximum, result_maximum):
		condition_text += "  →  %d / %d" % [
			int(round(result_condition)),
			int(round(result_maximum)),
		]
	_condition_label.text = "Condition  %s  •  %s" % [condition_text, state]


func _render_cost(preview: Dictionary) -> void:
	if _action not in [&"craft", &"recraft", &"repair"]:
		_cost_label.text = ""
		_cost_label.visible = false
		return
	var costs := _as_dictionary(preview.get("costs", {}))
	var owned := _as_dictionary(preview.get("owned_amounts", {}))
	var parts: Array[String] = []
	for material_id in MATERIAL_ORDER:
		if not costs.has(material_id):
			continue
		var required := int(costs.get(material_id, 0))
		var balance := int(owned.get(material_id, 0))
		parts.append("%s %d/%d" % [
			String(MATERIAL_LABELS.get(material_id, "Material")),
			balance,
			required,
		])
	_cost_label.visible = true
	_cost_label.text = "COST  %s" % ("  •  ".join(parts) if not parts.is_empty() else "Unavailable")


func _render_equipment_action(
	preview: Dictionary,
	crafted: bool,
	equipped: bool
) -> void:
	match _action:
		&"craft":
			_reason_label.text = _action_reason(preview)
			_set_action("Craft", bool(preview.get("can_execute", false)))
		&"recraft":
			_reason_label.text = _action_reason(preview)
			_set_action("Recraft to Grade 2", bool(preview.get("can_execute", false)))
		&"repair":
			_reason_label.text = _action_reason(preview)
			_set_action("Repair", bool(preview.get("can_execute", false)))
		&"equip":
			_reason_label.text = "Owned and ready to equip."
			_set_action("Equip", crafted and not equipped)
		_:
			_reason_label.text = "This model is fully prepared."
			_set_action("Equipped", false)


func _action_reason(preview: Dictionary) -> String:
	if bool(preview.get("can_execute", false)):
		return "Ready. Costs and results are fixed."
	match String(preview.get("code", "")):
		"blueprint_locked":
			return "Find this blueprint before crafting."
		"insufficient_materials":
			return "More materials are required."
		"already_crafted":
			return "This model is already crafted."
		"not_crafted":
			return "Craft this model first."
		"already_grade_two":
			return "This model is already Grade 2."
		"full_condition":
			return "Condition is already full."
		"conditionless_model":
			return "This slot does not use condition."
		_:
			return "This action is currently unavailable."


func _render_unavailable(title: String, message: String) -> void:
	_context_label.text = "PREPARATION"
	_state_label.text = "UNAVAILABLE"
	_title_label.text = title
	_behavior_label.text = message
	_weakness_label.text = "Return after preparation data is available."
	_clear_stats()
	_add_stat("STATUS", "Unavailable")
	_condition_label.text = ""
	_cost_label.text = ""
	_cost_label.visible = false
	_reason_label.text = "No command can be sent."
	_set_action("Unavailable", false)


func _set_action(text: String, enabled: bool) -> void:
	_action_button.text = text
	_action_button.disabled = not enabled
	_action_button.tooltip_text = _reason_label.text if not enabled else text


func _on_action_pressed() -> void:
	if _action_button.disabled:
		return
	if _kind == &"equipment" and _action != &"" and _model_id != &"" and _slot_id != &"":
		equipment_command_requested.emit(_action, _model_id, _slot_id)
	elif _kind == &"spirit_stone" and _stone_id != &"":
		spirit_stone_equip_requested.emit(_stone_id)


func _clear_stats() -> void:
	for child in _stats_grid.get_children():
		_stats_grid.remove_child(child)
		child.queue_free()


func _add_stat(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(label, 10 if _compact else 11, Styles.TEXT_MUTED)
	_stats_grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.tooltip_text = value_text
	Styles.configure_label(value, 11 if _compact else 12, Styles.TEXT)
	_stats_grid.add_child(value)


func _number_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	return _transition_text(current, result, key, 1.0, "%.0f")


func _signed_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	var text := _transition_text(current, result, key, 1.0, "%+.0f")
	return text.replace("+0", "0")


func _distance_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	return "%s px" % _transition_text(current, result, key, 1.0, "%.0f")


func _seconds_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	return "%s s" % _transition_text(current, result, key, 1.0, "%.2f")


func _degrees_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	return "%s°" % _transition_text(current, result, key, 1.0, "%.0f")


func _percent_transition(current: Dictionary, result: Dictionary, key: String) -> String:
	return "%s%%" % _transition_text(current, result, key, 100.0, "%.0f")


func _transition_text(
	current: Dictionary,
	result: Dictionary,
	key: String,
	multiplier: float,
	format: String
) -> String:
	var has_current := current.has(key)
	var has_result := result.has(key)
	var current_value := float(current.get(key, result.get(key, 0.0))) * multiplier
	var result_value := float(result.get(key, current.get(key, 0.0))) * multiplier
	var result_text := format % result_value
	if has_current and has_result and not is_equal_approx(current_value, result_value):
		return "%s → %s" % [format % current_value, result_text]
	return result_text


func _grade_text(grade_id: String) -> String:
	return "Grade 2" if grade_id == "grade_2" else "Grade 1"


func _as_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary) if value is Dictionary else {}


func _apply_density() -> void:
	if _margin == null:
		return
	var horizontal := 10 if _compact else 14
	var vertical := 8 if _compact else 12
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_%s" % side, horizontal)
	for side in ["top", "bottom"]:
		_margin.add_theme_constant_override("margin_%s" % side, vertical)
	_content.add_theme_constant_override("separation", 4 if _compact else 7)
	Styles.configure_label(_context_label, 10 if _compact else 11, Styles.TEXT_MUTED)
	Styles.configure_label(_state_label, 10 if _compact else 11, Styles.AMBER)
	Styles.configure_label(_title_label, 19 if _compact else 24, Styles.TEXT)
	for heading in [_behavior_heading, _weakness_heading, _stats_heading]:
		Styles.configure_label(heading, 9 if _compact else 10, Styles.TEXT_MUTED)
	Styles.configure_label(_behavior_label, 11 if _compact else 13, Styles.TEXT)
	Styles.configure_label(_weakness_label, 11 if _compact else 12, Styles.TEXT_MUTED)
	Styles.configure_label(_condition_label, 11 if _compact else 12, Styles.CYAN)
	Styles.configure_label(_cost_label, 10 if _compact else 11, Styles.TEXT)
	Styles.configure_label(_reason_label, 10 if _compact else 11, Styles.TEXT_MUTED)
	_behavior_label.max_lines_visible = 2 if _compact else 3
	_weakness_label.max_lines_visible = 2 if _compact else 3
	_behavior_label.custom_minimum_size.y = 28.0 if _compact else 36.0
	_weakness_label.custom_minimum_size.y = 28.0 if _compact else 34.0
	_cost_label.custom_minimum_size.y = 28.0 if _compact else 32.0
	_reason_label.custom_minimum_size.y = 28.0 if _compact else 32.0
	_cost_label.max_lines_visible = 2
	_reason_label.max_lines_visible = 2
	_action_button.custom_minimum_size.y = 40.0 if _compact else 44.0
	_action_button.add_theme_font_size_override("font_size", 14 if _compact else 17)
