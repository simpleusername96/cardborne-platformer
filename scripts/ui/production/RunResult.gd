extends Control

signal menu_requested
signal retry_requested

const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var title_label: Label
var detail_label: Label
var facts_label: Label
var build_label: Label
var materials_label: Label
var retry_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func configure(
	victory: bool,
	profile_name: String,
	settlement: Dictionary = {}
) -> void:
	if title_label == null:
		return
	title_label.text = "SLIME KING DEFEATED" if victory else "EXPEDITION ENDED"
	title_label.add_theme_color_override("font_color", Styles.AMBER if victory else Styles.CORAL)
	detail_label.text = _result_detail(victory, profile_name, settlement)
	facts_label.text = _fact_line(settlement)
	build_label.text = _build_summary(settlement)
	materials_label.text = _material_summary(settlement)
	materials_label.add_theme_color_override(
		"font_color",
		Styles.AMBER if victory else Styles.TEXT_MUTED
	)
	retry_button.text = "Run Again" if victory else "Retry"


func _build_ui() -> void:
	var backdrop := BackdropScene.new()
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(620.0, 0.0)
	content.add_theme_constant_override("separation", 11)
	center.add_child(content)

	var marker := ColorRect.new()
	marker.color = Styles.AMBER
	marker.custom_minimum_size = Vector2(90.0, 5.0)
	marker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(marker)

	title_label = Label.new()
	title_label.name = "ResultTitle"
	title_label.text = "EXPEDITION COMPLETE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(title_label, 34, Styles.AMBER)
	content.add_child(title_label)

	detail_label = Label.new()
	detail_label.name = "ResultDetail"
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(0.0, 36.0)
	Styles.configure_label(detail_label, 16, Styles.TEXT_MUTED)
	content.add_child(detail_label)

	var summary_panel := PanelContainer.new()
	summary_panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.96), Styles.OUTLINE)
	)
	content.add_child(summary_panel)

	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 18)
	summary_margin.add_theme_constant_override("margin_top", 12)
	summary_margin.add_theme_constant_override("margin_right", 18)
	summary_margin.add_theme_constant_override("margin_bottom", 12)
	summary_panel.add_child(summary_margin)

	var summary := VBoxContainer.new()
	summary.add_theme_constant_override("separation", 7)
	summary_margin.add_child(summary)

	facts_label = Label.new()
	facts_label.name = "RunFacts"
	facts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(facts_label, 16)
	summary.add_child(facts_label)

	var rule := ColorRect.new()
	rule.color = Color(Styles.OUTLINE, 0.7)
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	summary.add_child(rule)

	build_label = Label.new()
	build_label.name = "FinalBuild"
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(build_label, 14, Styles.TEXT_MUTED)
	summary.add_child(build_label)

	materials_label = Label.new()
	materials_label.name = "KeptMaterials"
	materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	materials_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(materials_label, 14, Styles.AMBER)
	summary.add_child(materials_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	content.add_child(button_row)

	retry_button = Button.new()
	retry_button.text = "Run Again"
	retry_button.custom_minimum_size = Vector2(180.0, 48.0)
	Styles.apply_button(retry_button, Styles.AMBER)
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	button_row.add_child(retry_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(180.0, 48.0)
	Styles.apply_button(menu_button, Styles.MOSS, true)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	button_row.add_child(menu_button)
	retry_button.grab_focus()


func _result_detail(victory: bool, profile_name: String, settlement: Dictionary) -> String:
	if victory:
		return "%s broke the crown and secured the Slime King's core." % profile_name
	var reason := _display_id(String(settlement.get("terminal_reason", "player_defeated")))
	return "%s's expedition ended: %s." % [profile_name, reason]


func _fact_line(settlement: Dictionary) -> String:
	var location := "Slime Court" if bool(settlement.get("boss_reached", false)) else (
		"Stage %d" % maxi(int(settlement.get("stage_reached", 1)), 1)
	)
	var seed := int(settlement.get("seed", 0))
	var elapsed := maxi(int(round(float(settlement.get("duration_seconds", 0.0)))), 0)
	return "%s     Seed %d     %s" % [location, seed, _format_duration(elapsed)]


func _build_summary(settlement: Dictionary) -> String:
	var build: Dictionary = settlement.get("run_build", {})
	var cards: Dictionary = build.get("cards", {})
	var card_parts: Array[String] = []
	var card_ids := cards.keys()
	card_ids.sort()
	for card_id in card_ids:
		var stacks := int(cards.get(card_id, 0))
		card_parts.append("%s%s" % [
			_display_id(String(card_id)),
			" x%d" % stacks if stacks > 1 else "",
		])
	var card_text := ", ".join(card_parts) if not card_parts.is_empty() else "No cards"
	return "Final build: Lv %d  |  %s" % [maxi(int(build.get("level", 1)), 1), card_text]


func _material_summary(settlement: Dictionary) -> String:
	var delta: Dictionary = settlement.get("persistent_material_delta", {})
	var parts: Array[String] = []
	var material_ids := delta.keys()
	material_ids.sort()
	for material_id in material_ids:
		var amount := int(delta.get(material_id, 0))
		if amount > 0:
			parts.append("%s +%d" % [_display_id(String(material_id)), amount])
	return "Kept: %s" % ", ".join(parts) if not parts.is_empty() else "No new materials kept"


func _display_id(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _format_duration(total_seconds: int) -> String:
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
