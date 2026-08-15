class_name VehicleCombatReportBody
extends VBoxContainer

## Shared, presentation-only report stack. Surface owners provide the one outer
## scroll container; this body never creates nested scrolling or tab navigation.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

const SECTION_DEFINITIONS: Array[Dictionary] = [
	{"id":&"outcome", "heading":"REPORT_OUTCOME", "keys":["outcome_rows"]},
	{"id":&"cycle_progress", "heading":"REPORT_CYCLE_PROGRESS", "keys":["cycle_progress_rows"]},
	{"id":&"build", "heading":"REPORT_BUILD", "keys":["build_rows"]},
	{"id":&"damage", "heading":"REPORT_DAMAGE", "keys":["damage_rows", "outgoing", "attributes"]},
	{"id":&"defense", "heading":"REPORT_DEFENSE", "keys":["defense_rows", "incoming"]},
	{"id":&"enemies", "heading":"REPORT_ENEMIES", "keys":["enemy_rows", "defeats"]},
	{"id":&"bosses", "heading":"REPORT_BOSSES", "keys":["boss_rows"]},
	{"id":&"pacing", "heading":"REPORT_PACING", "keys":["pacing_rows"]},
	{"id":&"diagnostic_limitations", "heading":"REPORT_DIAGNOSTIC_LIMITATIONS", "keys":["diagnostic_limitations"]},
]

var _snapshot: Dictionary = {}
var _rendered_sections: Array[StringName] = []
var _rendered_text_rows := 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	add_theme_constant_override("separation", 14)
	_rebuild()


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_rebuild()


func set_compact_mode(_compact: bool) -> void:
	# The body is one vertical flow at every supported width.
	pass


func set_accessibility_mode(_enabled: bool) -> void:
	# The owning surface controls its sole outer scroll container.
	pass


func refresh_localized_content() -> void:
	_rebuild()


func focus_target() -> Control:
	return self


func _rebuild() -> void:
	if not is_node_ready():
		return
	_clear(self)
	_rendered_sections.clear()
	_rendered_text_rows = 0
	for definition in SECTION_DEFINITIONS:
		var rows := _rows_for(StringName(definition["id"]))
		if rows.is_empty() and not _has_explicit_rows(definition):
			continue
		_append_section(String(definition["heading"]), rows)


func _has_explicit_rows(definition: Dictionary) -> bool:
	for key_variant in Array(definition["keys"]):
		if _snapshot.has(String(key_variant)):
			return true
	return false


func _rows_for(section_id: StringName) -> Array:
	match section_id:
		&"damage":
			if _snapshot.has("damage_rows"):
				return Array(_snapshot.get("damage_rows", []))
			var merged: Array = []
			merged.append_array(Array(_snapshot.get("outgoing", [])))
			merged.append_array(Array(_snapshot.get("attributes", [])))
			return merged
		&"defense":
			return Array(_snapshot.get("defense_rows", _snapshot.get("incoming", [])))
		&"enemies":
			return Array(_snapshot.get("enemy_rows", _snapshot.get("defeats", [])))
		&"diagnostic_limitations":
			var limitations: Variant = _snapshot.get("diagnostic_limitations", [])
			if limitations is Array:
				return Array(limitations)
			return [limitations] if not String(limitations).is_empty() else []
		_:
			return Array(_snapshot.get("%s_rows" % String(section_id), []))


func _append_section(heading_key: String, rows: Array) -> void:
	add_child(Factory.section_heading(tr(heading_key)))
	_rendered_sections.append(_section_id_for_heading(heading_key))
	if rows.is_empty():
		var empty := Factory.label("REPORT_NONE", 16, Art.MINT_SOFT)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(empty)
		return
	for row_variant in rows:
		_append_row(row_variant)


func _append_row(row_variant: Variant) -> void:
	if row_variant is String or row_variant is StringName:
		var text := Factory.label(String(row_variant), 16, Art.TEXT_PRIMARY)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(text)
		return
	var row: Dictionary = Dictionary(row_variant) if row_variant is Dictionary else {}
	var title := _localized_row_title(row)
	var value := _row_value(row)
	var line := Factory.text_row(title, value, {
		"label_min_width":0.0,
		"label_size":16,
		"value_size":16,
		"label_color":Art.IVORY_BRIGHT,
		"value_color":Art.IVORY_BRIGHT,
	})
	line.set_meta("shared_component", "TextRow")
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(line)
	_rendered_text_rows += 1


func _localized_row_title(row: Dictionary) -> String:
	for key in ["title_key", "name_key", "label_key"]:
		var translation_key := String(row.get(key, ""))
		if not translation_key.is_empty():
			return tr(translation_key)
	return String(row.get("title", row.get("label", row.get("id", ""))))


func _row_value(row: Dictionary) -> String:
	if row.has("value_key"):
		return tr(String(row["value_key"]))
	if row.has("value"):
		return String(row["value"])
	if row.has("detail"):
		return String(row["detail"])
	if row.has("count"):
		return "×%d" % int(row["count"])
	if row.has("damage"):
		var value := "%.1f" % float(row["damage"])
		if row.has("percentage_tenths"):
			value += "  %.1f%%" % (float(row["percentage_tenths"]) / 10.0)
		return value
	return ""


func _section_id_for_heading(heading_key: String) -> StringName:
	for definition in SECTION_DEFINITIONS:
		if String(definition["heading"]) == heading_key:
			return StringName(definition["id"])
	return &""


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func debug_contract() -> Dictionary:
	var section_order: Array[StringName] = []
	for definition in SECTION_DEFINITIONS:
		section_order.append(StringName(definition["id"]))
	return {
		"section_order":section_order,
		"rendered_sections":_rendered_sections.duplicate(),
		"vertical_stack":true,
		"tab_count":0,
		"nested_scroll_count":0,
		"shared_text_rows":_rendered_text_rows,
		"decorated_metric_rows":0,
	}
