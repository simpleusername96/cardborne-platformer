class_name VehicleBossPracticePanel
extends VBoxContainer

## Debug-only boss practice composition. It emits a complete request snapshot
## and never mutates run state directly.

signal selected(request: Dictionary)
signal back_requested

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")

var _stage: OptionButton
var _field: OptionButton
var _phase: OptionButton
var _pattern: OptionButton
var _invulnerable: CheckBox
var _start: Button
var _back: Button
var _form: VBoxContainer
var _form_scroll: ScrollContainer
var _form_rows: Array[VBoxContainer] = []


func _ready() -> void:
	name = "BossPracticePanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build()
	refresh_localized_content()


func _build() -> void:
	add_child(Factory.label("BOSS_PRACTICE_KICKER", 14, Art.MUSTARD))
	add_child(Factory.label("BOSS_PRACTICE_TITLE", 28, Art.IVORY_BRIGHT))
	_form_scroll = ScrollContainer.new()
	_form_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_form_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_form_scroll.custom_minimum_size.y = 210.0
	add_child(_form_scroll)
	_form = VBoxContainer.new()
	_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_form.add_theme_constant_override("separation", 6)
	_form_scroll.add_child(_form)
	_stage = _option("BOSS_PRACTICE_BOSS")
	_stage.item_selected.connect(
		func(_index: int) -> void: _refresh_patterns()
	)
	_field = _option("BOSS_PRACTICE_FIELD")
	_phase = _option("BOSS_PRACTICE_PHASE")
	_pattern = _option("BOSS_PRACTICE_MODE")
	_invulnerable = CheckBox.new()
	_invulnerable.custom_minimum_size.y = 44.0
	_invulnerable.focus_mode = Control.FOCUS_ALL
	_form.add_child(_control_row("BOSS_PRACTICE_INVULNERABLE", _invulnerable))
	_start = Factory.command_button(
		"BOSS_PRACTICE_START",
		Factory.COMMAND_PRIMARY
	)
	_start.pressed.connect(_emit_request)
	var commands := HBoxContainer.new()
	commands.alignment = BoxContainer.ALIGNMENT_CENTER
	commands.add_theme_constant_override("separation", 10)
	add_child(commands)
	commands.add_child(_start)
	_back = Factory.command_button("COMMON_BACK", Factory.COMMAND_SECONDARY)
	_back.pressed.connect(func() -> void: back_requested.emit())
	commands.add_child(_back)


func open() -> void:
	_start.grab_focus()


func refresh_localized_content() -> void:
	var stage_selection := maxi(0, _stage.selected)
	var field_selection := maxi(0, _field.selected)
	var phase_selection := maxi(0, _phase.selected)
	_stage.clear()
	for stage_id in StageCatalog.STAGE_IDS:
		var profile := StageCatalog.profile(stage_id)
		_stage.add_item(tr(String(profile["boss_name_key"])))
		_stage.set_item_metadata(_stage.item_count - 1, stage_id)
	_stage.select(mini(stage_selection, _stage.item_count - 1))
	_field.clear()
	for field_id in FieldRegistry.FIELD_IDS:
		var definition := FieldRegistry.definition(field_id)
		_field.add_item(tr(String(definition["name_key"])))
		_field.set_item_metadata(_field.item_count - 1, field_id)
	_field.select(mini(field_selection, _field.item_count - 1))
	_phase.clear()
	for phase_value in [1, 2, 3]:
		_phase.add_item(
			tr("BOSS_PRACTICE_PHASE_VALUE").replace(
				"%d",
				str(phase_value)
			)
		)
		_phase.set_item_metadata(_phase.item_count - 1, phase_value)
	_phase.select(mini(phase_selection, _phase.item_count - 1))
	_invulnerable.accessibility_name = tr("BOSS_PRACTICE_INVULNERABLE")
	_refresh_patterns()


func set_compact_mode(compact: bool) -> void:
	add_theme_constant_override("separation", 6 if compact else 10)
	if is_instance_valid(_form):
		_form.add_theme_constant_override("separation", 4 if compact else 6)
	if is_instance_valid(_form_scroll):
		_form_scroll.custom_minimum_size.y = 180.0 if compact else 260.0
	for option in [_stage, _field, _phase, _pattern]:
		option.custom_minimum_size.y = 44.0 if compact else 46.0


func debug_option_texts() -> PackedStringArray:
	var result := PackedStringArray()
	for index in _pattern.item_count:
		result.append(_pattern.get_item_text(index))
	return result


func debug_contract() -> Dictionary:
	return {
		"form_rows":_form_rows.size(),
		"option_controls":4,
		"toggle_controls":1,
		"command_count":2,
		"row_panel_count":0,
		"scroll_region_count":1,
		"start_role":_start.theme_type_variation,
		"back_role":_back.theme_type_variation,
		"minimum_target_height":_minimum_target_height(),
	}


func _option(label_key: String) -> OptionButton:
	var option := OptionButton.new()
	option.fit_to_longest_item = false
	option.custom_minimum_size.y = 46.0
	Factory.apply_font_size(option, 16)
	option.focus_mode = Control.FOCUS_ALL
	_form.add_child(_control_row(label_key, option))
	return option


func _control_row(label_key: String, control: Control) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Factory.label(label_key, 15, Art.TEXT_MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	_form_rows.append(row)
	return row


func _minimum_target_height() -> float:
	var minimum := INF
	for control in [_stage, _field, _phase, _pattern, _invulnerable, _start, _back]:
		minimum = minf(minimum, control.custom_minimum_size.y)
	return 0.0 if is_inf(minimum) else minimum


func _refresh_patterns() -> void:
	if _stage.item_count <= 0:
		return
	_pattern.clear()
	_pattern.add_item(tr("BOSS_PRACTICE_FULL"))
	_pattern.set_item_metadata(0, "full")
	var stage_id := StringName(
		_stage.get_item_metadata(_stage.selected)
	)
	var pattern_ids: Array[StringName] = []
	for value in BossPatterns.sequence(stage_id, 1):
		pattern_ids.append(StringName(value))
	pattern_ids.append_array(BossPatterns.autonomous_sequence(stage_id))
	for pattern_id in pattern_ids:
		var mode_key := BossPatterns.commit_mode_display_key(
			BossPatterns.commit_mode(String(pattern_id))
		)
		var pattern_key := BossPatterns.display_key(String(pattern_id))
		if mode_key.is_empty() or pattern_key.is_empty():
			push_error(
				"Missing boss practice presentation for %s" % pattern_id
			)
			continue
		_pattern.add_item("%s · %s" % [
			tr(mode_key),
			tr(pattern_key),
		])
		_pattern.set_item_metadata(
			_pattern.item_count - 1,
			String(pattern_id)
		)


func _emit_request() -> void:
	selected.emit({
		"stage_id":StringName(_stage.get_item_metadata(_stage.selected)),
		"field_id":StringName(_field.get_item_metadata(_field.selected)),
		"phase":int(_phase.get_item_metadata(_phase.selected)),
		"pattern":String(
			_pattern.get_item_metadata(_pattern.selected)
		),
		"invulnerable":_invulnerable.button_pressed,
	})
