class_name EquipmentDecisionPanel
extends PanelContainer

const StatPresentation = preload("res://scripts/player/PlayerStatPresentation.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

@onready var _context_label: Label = %ContextLabel
@onready var _margin: MarginContainer = $Margin
@onready var _content: VBoxContainer = $Margin/Content
@onready var _state_label: Label = %StateLabel
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _tradeoff_label: Label = %TradeoffLabel
@onready var _affix_label: Label = %AffixLabel
@onready var _mechanics_heading: Label = %MechanicsHeading
@onready var _mechanics_grid: GridContainer = %MechanicsGrid
@onready var _validation_label: Label = %ValidationLabel

var _data: Dictionary = {}
var _compact: bool = false


func _ready() -> void:
	add_theme_stylebox_override("panel", Styles.panel_style(
		Color(Styles.SURFACE, 0.96),
		Styles.OUTLINE
	))
	_render()


func configure(data: Dictionary, compact: bool = false) -> void:
	_data = data.duplicate(true)
	_compact = compact
	if is_node_ready():
		_render()


func _render() -> void:
	if _context_label == null:
		return
	for side in ["margin_left", "margin_right"]:
		_margin.add_theme_constant_override(side, 9 if _compact else 12)
	for side in ["margin_top", "margin_bottom"]:
		_margin.add_theme_constant_override(side, 3 if _compact else 8)
	_content.add_theme_constant_override("separation", 0 if _compact else 3)
	_context_label.add_theme_font_size_override("font_size", 10 if _compact else 11)
	_state_label.add_theme_font_size_override("font_size", 10 if _compact else 11)
	_title_label.add_theme_font_size_override("font_size", 15 if _compact else 17)
	_description_label.add_theme_font_size_override("font_size", 11 if _compact else 12)
	_tradeoff_label.add_theme_font_size_override("font_size", 10 if _compact else 11)
	_affix_label.add_theme_font_size_override("font_size", 10 if _compact else 11)
	_mechanics_heading.add_theme_font_size_override("font_size", 9 if _compact else 10)
	_context_label.text = String(_data.get("context_text", "EQUIPMENT"))
	_state_label.text = String(_data.get("state_text", ""))
	_state_label.visible = not _state_label.text.is_empty()
	_title_label.text = String(_data.get("title", "Select equipment"))

	_description_label.text = String(_data.get("description", ""))
	_description_label.visible = not _description_label.text.is_empty()
	_description_label.autowrap_mode = (
		TextServer.AUTOWRAP_OFF if _compact else TextServer.AUTOWRAP_WORD_SMART
	)
	_description_label.max_lines_visible = 1 if _compact else 2

	var tradeoff := String(_data.get("tradeoff", ""))
	_tradeoff_label.text = "LIMIT  %s" % (tradeoff if not tradeoff.is_empty() else "None")
	_tradeoff_label.autowrap_mode = (
		TextServer.AUTOWRAP_OFF if _compact else TextServer.AUTOWRAP_WORD_SMART
	)
	_tradeoff_label.max_lines_visible = 1 if _compact else 2

	var affix_text := String(_data.get("affix_text", ""))
	_affix_label.text = affix_text
	_affix_label.visible = not affix_text.is_empty()
	_affix_label.autowrap_mode = (
		TextServer.AUTOWRAP_OFF if _compact else TextServer.AUTOWRAP_WORD_SMART
	)
	_affix_label.max_lines_visible = 1 if _compact else 2

	_clear(_mechanics_grid)
	var mechanic_lines: Array[String] = []
	for effect_value in _data.get("effect_lines", []):
		if effect_value is Dictionary:
			mechanic_lines.append(StatPresentation.format_effect(effect_value))
		else:
			mechanic_lines.append(String(effect_value))
	for delta_value in _data.get("stat_deltas", []):
		if not delta_value is Dictionary:
			continue
		var delta := delta_value as Dictionary
		mechanic_lines.append(StatPresentation.format_transition(
			StringName(delta.get("stat_id", "")),
			float(delta.get("before", 0.0)),
			float(delta.get("after", 0.0))
		))

	var delta_count := (_data.get("stat_deltas", []) as Array).size()
	_mechanics_heading.text = "CURRENT -> CANDIDATE" if delta_count > 0 else "MECHANICS"
	if mechanic_lines.is_empty():
		mechanic_lines.append(String(_data.get(
			"empty_mechanics_text",
			"No numeric stat change."
		)))
	_mechanics_grid.columns = 1 if mechanic_lines.size() == 1 else 2
	for line in mechanic_lines:
		var value_label := Label.new()
		value_label.text = line
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		value_label.tooltip_text = line
		Styles.configure_label(value_label, 11 if _compact else 12, Styles.CYAN)
		_mechanics_grid.add_child(value_label)

	var validation_errors: Array = _data.get("validation_errors", [])
	_validation_label.visible = not validation_errors.is_empty()
	_validation_label.text = (
		"INVALID BUILD  This choice violates a character stat limit."
		if not validation_errors.is_empty()
		else ""
	)


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
