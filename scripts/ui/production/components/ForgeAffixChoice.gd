class_name ForgeAffixChoice
extends Button

signal affix_chosen(affix_id: StringName)

const StatPresentation = preload("res://scripts/player/PlayerStatPresentation.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

@onready var _name_label: Label = %NameLabel
@onready var _scope_label: Label = %ScopeLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _delta_label: Label = %DeltaLabel
@onready var _cost_label: Label = %CostLabel

var _affix_id: StringName
var _row: Dictionary = {}
var _current_coins: int = 0
var _disabled_reason: String = ""
var _compact: bool = false


func _ready() -> void:
	Styles.apply_button(self, Styles.AMBER, true)
	pressed.connect(func() -> void: affix_chosen.emit(_affix_id))
	_render()


func configure(
	row: Dictionary,
	current_coins: int,
	disabled_reason: String = "",
	compact: bool = false
) -> void:
	_row = row.duplicate(true)
	_affix_id = StringName(_row.get("id", ""))
	_current_coins = current_coins
	_disabled_reason = disabled_reason
	_compact = compact
	disabled = not _disabled_reason.is_empty()
	custom_minimum_size.y = 88.0 if _compact else 96.0
	if is_node_ready():
		_render()


func _render() -> void:
	if _name_label == null:
		return
	_name_label.text = String(_row.get("display_name", "Unknown affix"))
	_scope_label.text = "THIS RUN"
	_description_label.text = String(_row.get("description", ""))
	_description_label.max_lines_visible = 1 if _compact else 2

	var delta_lines: Array[String] = []
	for delta_value in _row.get("stat_deltas", []):
		if not delta_value is Dictionary:
			continue
		var delta := delta_value as Dictionary
		delta_lines.append(StatPresentation.format_transition(
			StringName(delta.get("stat_id", "")),
			float(delta.get("before", 0.0)),
			float(delta.get("after", 0.0))
		))
	_delta_label.text = (
		" | ".join(delta_lines)
		if not delta_lines.is_empty()
		else "Behavior change only; see description."
	)
	_delta_label.tooltip_text = "\n".join(delta_lines)
	_delta_label.max_lines_visible = 2

	if _disabled_reason.is_empty():
		_cost_label.text = "COINS  %d -> %d" % [
			_current_coins,
			int(_row.get("final_coins", _current_coins)),
		]
	else:
		_cost_label.text = "%s | COINS STAY %d" % [_disabled_reason, _current_coins]
	_cost_label.add_theme_color_override(
		"font_color",
		Styles.CORAL if disabled else Styles.AMBER
	)
