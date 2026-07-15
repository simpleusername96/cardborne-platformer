extends Control

signal menu_requested
signal retry_requested
signal end_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const LOADOUT_SLOT_ORDER: Array[String] = [
	"melee", "ranged", "shield", "armor", "spirit_stone",
]
const MATERIAL_NAMES := {
	"rusted_scrap": "Rusted Scrap",
	"steel_fragment": "Steel Fragment",
	"common_timber": "Common Timber",
	"hardwood": "Hardwood",
	"sky_thread": "Sky Thread",
	"reinforced_fabric": "Reinforced Fabric",
	"slime_residue": "Slime Residue",
	"boss_core": "Boss Core",
}

@onready var outcome_marker: ColorRect = %OutcomeMarker
@onready var outcome_title: Label = %OutcomeTitle
@onready var outcome_subtitle: Label = %OutcomeSubtitle
@onready var detail_label: Label = %ResultDetail
@onready var reach_value: Label = %ReachValue
@onready var time_value: Label = %TimeValue
@onready var level_value: Label = %LevelValue
@onready var build_heading: Label = %BuildHeading
@onready var build_label: Label = %BuildSummary
@onready var rewards_heading: Label = %RewardsHeading
@onready var materials_label: Label = %KeptMaterials
@onready var summary_panel: PanelContainer = %SummaryPanel
@onready var summary_rule: ColorRect = %SummaryRule
@onready var summary_divider: ColorRect = %SummaryDivider
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

var _retry_decision := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_style_ui()
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_secondary_pressed)
	retry_button.grab_focus()


func configure(victory: bool, profile_name: String, settlement: Dictionary = {}) -> void:
	_retry_decision = false
	var accent := Styles.AMBER if victory else Styles.CORAL
	outcome_marker.color = accent
	outcome_title.text = "VICTORY" if victory else "DEFEAT"
	outcome_title.add_theme_color_override("font_color", accent)
	outcome_subtitle.text = "SLIME KING DEFEATED" if victory else "EXPEDITION ENDED"
	detail_label.text = _result_detail(victory, profile_name, settlement)
	reach_value.text = _final_reach(settlement)
	time_value.text = _format_duration(
		maxi(int(round(float(settlement.get("duration_seconds", 0.0)))), 0)
	)
	level_value.text = "Lv %d" % maxi(int(_run_build(settlement).get("level", 1)), 1)
	build_heading.text = "%s BUILD" % profile_name.to_upper()
	build_label.text = _build_summary(settlement)
	materials_label.text = _material_summary(settlement)
	rewards_heading.text = "REWARDS KEPT"
	rewards_heading.add_theme_color_override("font_color", accent)
	materials_label.add_theme_color_override(
		"font_color",
		Styles.AMBER if _has_kept_materials(settlement) else Styles.TEXT_MUTED
	)
	retry_button.text = "Begin Another Run"
	menu_button.text = "Main Menu"


func configure_retry_decision(profile_name: String, attempt: Dictionary) -> void:
	_retry_decision = true
	var run_state: Dictionary = attempt.get("run_state", {})
	var stage_index := int(attempt.get("stage_index", 0))
	outcome_marker.color = Styles.CORAL
	outcome_title.text = "DEFEAT"
	outcome_title.add_theme_color_override("font_color", Styles.CORAL)
	outcome_subtitle.text = "CHOOSE YOUR NEXT STEP"
	detail_label.text = (
		"Retry restores %s to the state from this stage's entrance."
		% profile_name
	)
	reach_value.text = (
		"Slime Court"
		if bool(attempt.get("boss_attempt", false))
		else "Stage %d" % (stage_index + 1)
	)
	time_value.text = _format_duration(maxi(int(RunState.get_run_elapsed_seconds()), 0))
	level_value.text = "Lv %d" % maxi(int(run_state.get("run_level", 1)), 1)
	build_heading.text = "%s BUILD" % profile_name.to_upper()
	build_label.text = _build_summary({
		"profile": {"hero_loadout": ProfileState.get_hero_loadout()},
		"run_build": {
			"cards": (run_state.get("card_stacks", {}) as Dictionary).duplicate(true),
		},
	})
	rewards_heading.text = "RETRY RULE"
	rewards_heading.add_theme_color_override("font_color", Styles.CORAL)
	materials_label.text = (
		"Health, run resources, supplies, and equipment condition return to stage "
		+ "entry. Secured materials stay kept."
	)
	materials_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	retry_button.text = "Retry Stage"
	menu_button.text = "End Expedition"
	retry_button.grab_focus()


func get_display_snapshot() -> Dictionary:
	return {
		"outcome": outcome_title.text,
		"subtitle": outcome_subtitle.text,
		"detail": detail_label.text,
		"reach": reach_value.text,
		"time": time_value.text,
		"level": level_value.text,
		"build": build_label.text,
		"materials": materials_label.text,
		"retry_action": retry_button.text,
		"secondary_action": menu_button.text,
		"retry_decision": _retry_decision,
	}


func _on_retry_pressed() -> void:
	retry_requested.emit()


func _on_secondary_pressed() -> void:
	if _retry_decision:
		end_requested.emit()
	else:
		menu_requested.emit()


func _style_ui() -> void:
	Styles.configure_label(outcome_title, 46, Styles.AMBER)
	Styles.configure_label(outcome_subtitle, 18, Styles.TEXT)
	Styles.configure_label(detail_label, 15, Styles.TEXT_MUTED)
	for label in [%ReachHeading, %TimeHeading, %LevelHeading]:
		Styles.configure_label(label as Label, 12, Styles.TEXT_MUTED)
	for label in [reach_value, time_value, level_value]:
		Styles.configure_label(label, 19, Styles.TEXT)
	Styles.configure_label(build_heading, 13, Styles.CYAN)
	Styles.configure_label(build_label, 14, Styles.TEXT_MUTED)
	Styles.configure_label(rewards_heading, 13, Styles.AMBER)
	Styles.configure_label(materials_label, 14, Styles.AMBER)
	summary_panel.add_theme_stylebox_override(
		"panel",
		Styles.panel_style(Color(Styles.SURFACE, 0.97), Styles.OUTLINE)
	)
	summary_rule.color = Color(Styles.OUTLINE, 0.72)
	summary_divider.color = Color(Styles.OUTLINE, 0.72)
	Styles.apply_button(retry_button, Styles.AMBER)
	Styles.apply_button(menu_button, Styles.MOSS, true)


func _result_detail(victory: bool, profile_name: String, settlement: Dictionary) -> String:
	if victory:
		return "%s broke the crown and returned with its core." % profile_name
	match String(settlement.get("terminal_reason", "player_defeated")):
		"run_abandoned":
			return "%s ended the expedition. Secured materials were kept." % profile_name
		"player_defeated":
			return "%s fell before reaching the crown." % profile_name
		_:
			return "%s's expedition could not continue." % profile_name


func _final_reach(settlement: Dictionary) -> String:
	if bool(settlement.get("boss_reached", false)):
		return "Slime Court"
	return "Stage %d" % clampi(int(settlement.get("stage_reached", 1)), 1, 3)


func _build_summary(settlement: Dictionary) -> String:
	var lines: Array[String] = []
	var equipment_names := _loadout_names(settlement)
	lines.append(
		"Equipment  %s" % " / ".join(equipment_names)
		if not equipment_names.is_empty()
		else "Equipment  Starting gear"
	)

	var card_names := _card_names(_run_build(settlement).get("cards", {}))
	lines.append(
		"Cards  %s" % ", ".join(card_names)
		if not card_names.is_empty()
		else "Cards  None collected"
	)

	return "\n".join(lines)


func _loadout_names(settlement: Dictionary) -> Array[String]:
	var names: Array[String] = []
	var profile: Dictionary = settlement.get("profile", {})
	var loadout: Dictionary = profile.get("hero_loadout", {})
	var catalog := ProfileState.progression_catalog as EquipmentProgressionCatalog
	if catalog == null:
		return names
	for slot_id in LOADOUT_SLOT_ORDER:
		var item_id := StringName(loadout.get(slot_id, ""))
		if item_id == &"":
			continue
		if slot_id == "spirit_stone":
			var stone := catalog.get_spirit_stone(item_id)
			if stone != null:
				names.append(stone.display_name)
			continue
		var model := catalog.get_model(item_id)
		if model != null:
			names.append(model.display_name)
	return names


func _card_names(cards_value: Variant) -> Array[String]:
	var names: Array[String] = []
	if not cards_value is Dictionary:
		return names
	var cards := cards_value as Dictionary
	var card_ids := cards.keys()
	card_ids.sort()
	for card_id in card_ids:
		var card := RunState.get_card_definition(StringName(card_id))
		if card == null:
			continue
		var stacks := int(cards.get(card_id, 0))
		if stacks <= 0:
			continue
		names.append("%s%s" % [card.display_name, " x%d" % stacks if stacks > 1 else ""])
	return names


func _material_summary(settlement: Dictionary) -> String:
	var delta: Dictionary = settlement.get("persistent_material_delta", {})
	var parts: Array[String] = []
	for material_id in MATERIAL_NAMES:
		var amount := int(delta.get(material_id, 0))
		if amount > 0:
			parts.append("%s  +%d" % [MATERIAL_NAMES[material_id], amount])
	return "\n".join(parts) if not parts.is_empty() else "No new materials secured"


func _has_kept_materials(settlement: Dictionary) -> bool:
	var delta: Dictionary = settlement.get("persistent_material_delta", {})
	for amount in delta.values():
		if int(amount) > 0:
			return true
	return false


func _run_build(settlement: Dictionary) -> Dictionary:
	var value: Variant = settlement.get("run_build", {})
	return value as Dictionary if value is Dictionary else {}


func _format_duration(total_seconds: int) -> String:
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
