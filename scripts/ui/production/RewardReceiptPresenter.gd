class_name RewardReceiptPresenter
extends Control

signal presentation_state_changed(active: bool)

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const DISPLAY_SECONDS := 2.8
const FADE_SECONDS := 0.22
const MAX_QUEUE_SIZE := 4
const GRANT_ORDER: Array[String] = [
	"coin", "xp", "rusted_scrap", "sky_thread", "slime_residue", "boss_core",
]
const GRANT_LABELS := {
	"coin": "Coins",
	"xp": "XP",
	"rusted_scrap": "Rusted Scrap",
	"sky_thread": "Sky Thread",
	"slime_residue": "Slime Residue",
	"boss_core": "Boss Core",
}

var _panel: PanelContainer
var _title: Label
var _summary: Label
var _queue: Array[Dictionary] = []
var _presenting: bool = false
var _display_serial: int = 0
var _embedded: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	var signal_bus := get_node_or_null("/root/SignalBus")
	if signal_bus != null and signal_bus.has_signal("interactive_reward_claimed"):
		signal_bus.connect("interactive_reward_claimed", present)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel != null:
		_layout_panel()


func present(receipt: Dictionary) -> void:
	if not bool(receipt.get("applied", false)):
		return
	if _queue.size() >= MAX_QUEUE_SIZE:
		_queue.pop_front()
	_queue.append(receipt.duplicate(true))
	if not _presenting:
		_show_next()


func set_embedded(embedded: bool) -> void:
	_embedded = embedded
	if is_node_ready() and _panel != null:
		_layout_panel()


func is_presenting() -> bool:
	return _presenting


func build_view_model(receipt: Dictionary) -> Dictionary:
	var role := StringName(receipt.get("reward_role", &"generic_reward"))
	var replacement_kind := StringName(receipt.get("replacement_kind", &"normal"))
	var discoveries: Variant = receipt.get("equipment_discoveries", [])
	var title := _receipt_title(role, replacement_kind, discoveries)
	var parts := _grant_parts(receipt.get("grants", {}))
	parts.append_array(_equipment_parts(discoveries))
	if replacement_kind == &"forge":
		var forge_text := _forge_text(receipt.get("replacement_payload", {}))
		if not forge_text.is_empty():
			parts.append(forge_text)
	if parts.is_empty():
		parts.append(String(receipt.get("message", "Reward applied.")))
	return {
		"title": title,
		"summary": "  /  ".join(parts),
		"accent": Styles.MOSS if role == &"material_node" else Styles.AMBER,
	}


func get_display_snapshot() -> Dictionary:
	return {
		"visible": _panel != null and _panel.visible,
		"title": _title.text if _title != null else "",
		"summary": _summary.text if _summary != null else "",
		"queue_count": _queue.size(),
		"panel_rect": _panel.get_rect() if _panel != null else Rect2(),
	}


func _show_next() -> void:
	if _queue.is_empty() or _panel == null:
		_set_presenting(false)
		return
	_set_presenting(true)
	_display_serial += 1
	var serial := _display_serial
	var view_model := build_view_model(_queue.pop_front())
	_title.text = String(view_model["title"])
	_title.add_theme_color_override("font_color", view_model["accent"] as Color)
	_summary.text = String(view_model["summary"])
	_panel.visible = true
	_panel.modulate = Color.WHITE
	await get_tree().create_timer(DISPLAY_SECONDS).timeout
	if serial != _display_serial or not is_instance_valid(_panel):
		return
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, FADE_SECONDS)
	await tween.finished
	if serial != _display_serial or not is_instance_valid(_panel):
		return
	_panel.visible = false
	_panel.modulate = Color.WHITE
	_show_next()


func _set_presenting(active: bool) -> void:
	if _presenting == active:
		return
	_presenting = active
	presentation_state_changed.emit(active)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "RewardReceipt"
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE_RAISED, 0.97), Styles.AMBER, 2)
	)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	_title = Label.new()
	_title.name = "ReceiptTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(_title, 13, Styles.AMBER)
	column.add_child(_title)

	_summary = Label.new()
	_summary.name = "ReceiptSummary"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.max_lines_visible = 2
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(_summary, 15, Styles.TEXT)
	column.add_child(_summary)
	_layout_panel()


func _layout_panel() -> void:
	if _embedded:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	var panel_width := minf(540.0, maxf(size.x - 40.0, 320.0))
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -panel_width * 0.5
	_panel.offset_top = -168.0
	_panel.offset_right = panel_width * 0.5
	_panel.offset_bottom = -92.0


func _receipt_title(
	role: StringName,
	replacement_kind: StringName,
	discoveries: Variant
) -> String:
	if replacement_kind == &"forge":
		return "FORGE APPLIED"
	if discoveries is Array and not discoveries.is_empty():
		for value in discoveries:
			if value is Dictionary and not bool(value.get("duplicate", false)):
				return "EQUIPMENT FOUND"
		return "CACHE SALVAGED"
	if replacement_kind == &"equipment":
		return "EQUIPMENT FOUND"
	match role:
		&"cache_reward", &"optional_route", &"route_choice":
			return "CHEST OPENED"
		&"material_node":
			return "MATERIAL EXTRACTED"
	return "REWARD COLLECTED"


func _grant_parts(grants_value: Variant) -> Array[String]:
	var parts: Array[String] = []
	if not grants_value is Dictionary:
		return parts
	var grants := grants_value as Dictionary
	var grant_ids: Array[String] = []
	for raw_id in grants:
		grant_ids.append(String(raw_id))
	grant_ids.sort_custom(func(left: String, right: String) -> bool:
		var left_index := GRANT_ORDER.find(left)
		var right_index := GRANT_ORDER.find(right)
		left_index = left_index if left_index >= 0 else GRANT_ORDER.size()
		right_index = right_index if right_index >= 0 else GRANT_ORDER.size()
		return left_index < right_index if left_index != right_index else left < right
	)
	for grant_id in grant_ids:
		parts.append("+%d %s" % [
			int(grants.get(grant_id, 0)),
			String(GRANT_LABELS.get(grant_id, grant_id.capitalize())),
		])
	return parts


func _equipment_parts(discoveries_value: Variant) -> Array[String]:
	var parts: Array[String] = []
	if not discoveries_value is Array:
		return parts
	for value in discoveries_value:
		if not value is Dictionary:
			continue
		var discovery := value as Dictionary
		var item_id := StringName(discovery.get("item_id", &""))
		var item: Variant = _equipment_item(item_id)
		var item_name: String = (
			String(item.get("display_name")) if item != null else String(item_id).capitalize()
		)
		if bool(discovery.get("duplicate", false)):
			var payload: Dictionary = discovery.get("payload", {})
			var salvage := _grant_parts(payload.get("salvage", {}))
			parts.append(
				"%s duplicate -> %s" % [item_name, ", ".join(salvage)]
				if not salvage.is_empty()
				else "%s duplicate" % item_name
			)
		else:
			parts.append("%s unlocked" % item_name)
	return parts


func _forge_text(payload_value: Variant) -> String:
	if not payload_value is Dictionary:
		return ""
	var payload := payload_value as Dictionary
	var item_id := StringName(payload.get("item_id", &""))
	var affix_id := StringName(payload.get("affix_id", &""))
	var item: Variant = _equipment_item(item_id)
	var affix: Variant = _forge_affix(affix_id)
	var item_name: String = (
		String(item.get("display_name")) if item != null else String(item_id).capitalize()
	)
	var affix_name: String = (
		String(affix.get("display_name")) if affix != null else String(affix_id).capitalize()
	)
	if item_id == &"" or affix_id == &"":
		return ""
	return "%s: %s" % [item_name, affix_name]


func _equipment_item(item_id: StringName) -> Variant:
	var profile_state := get_node_or_null("/root/ProfileState")
	if profile_state == null:
		return null
	var catalog: Variant = profile_state.get("equipment_catalog")
	return catalog.get_item(item_id) if catalog != null else null


func _forge_affix(affix_id: StringName) -> Variant:
	var run_state := get_node_or_null("/root/RunState")
	if run_state == null:
		return null
	var catalog: Variant = run_state.get("forge_catalog")
	return catalog.get_affix(affix_id) if catalog != null else null
