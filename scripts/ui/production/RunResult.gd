extends Control

signal menu_requested
signal retry_requested
signal end_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Assets = preload("res://scripts/ui/production/ProductionUIAssets.gd")
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
@onready var traveler_art: TextureRect = %TravelerArt
@onready var slime_king_art: TextureRect = %SlimeKingArt
@onready var boss_core_art: TextureRect = %BossCoreArt
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

var _retry_decision := false
var _configuration_kind := ""
var _last_victory := false
var _last_profile_name := "Traveler"
var _last_settlement: Dictionary = {}
var _last_attempt: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Styles.apply_theme(self)
	_configure_art_slots()
	_style_ui()
	_apply_static_copy()
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_secondary_pressed)
	UILocalization.locale_changed.connect(_on_locale_changed)
	retry_button.grab_focus()


func configure(victory: bool, profile_name: String, settlement: Dictionary = {}) -> void:
	_configuration_kind = "result"
	_last_victory = victory
	_last_profile_name = profile_name
	_last_settlement = settlement.duplicate(true)
	_retry_decision = false
	var accent := Styles.AMBER if victory else Styles.CORAL
	outcome_marker.color = accent
	outcome_title.text = (
		UILocalization.text(&"VICTORY") if victory else UILocalization.text(&"DEFEAT")
	)
	outcome_title.add_theme_color_override("font_color", accent)
	outcome_subtitle.text = (
		UILocalization.text(&"SLIME KING DEFEATED")
		if victory
		else UILocalization.text(&"EXPEDITION ENDED")
	)
	detail_label.text = _result_detail(victory, profile_name, settlement)
	reach_value.text = _final_reach(settlement)
	time_value.text = _format_duration(
		maxi(int(round(float(settlement.get("duration_seconds", 0.0)))), 0)
	)
	level_value.text = "Lv %d" % maxi(int(_run_build(settlement).get("level", 1)), 1)
	build_heading.text = UILocalization.text(&"{0} BUILD", [profile_name.to_upper()])
	build_label.text = _build_summary(settlement)
	materials_label.text = _material_summary(settlement)
	rewards_heading.text = UILocalization.text(&"REWARDS KEPT")
	rewards_heading.add_theme_color_override("font_color", accent)
	materials_label.add_theme_color_override(
		"font_color",
		Styles.AMBER if _has_kept_materials(settlement) else Styles.TEXT_MUTED
	)
	_update_result_art(victory, settlement)
	retry_button.text = UILocalization.text(&"Begin Another Run")
	menu_button.text = UILocalization.text(&"Main Menu")
	Styles.apply_button(menu_button, Styles.MOSS, true)


func configure_retry_decision(profile_name: String, attempt: Dictionary) -> void:
	_configuration_kind = "retry"
	_last_profile_name = profile_name
	_last_attempt = attempt.duplicate(true)
	_retry_decision = true
	var run_state: Dictionary = attempt.get("run_state", {})
	var stage_index := int(attempt.get("stage_index", 0))
	outcome_marker.color = Styles.CORAL
	outcome_title.text = UILocalization.text(&"DEFEAT")
	outcome_title.add_theme_color_override("font_color", Styles.CORAL)
	outcome_subtitle.text = UILocalization.text(&"CHOOSE YOUR NEXT STEP")
	detail_label.text = UILocalization.text(
		&"Retry restores {0} to this stage's entrance.", [profile_name]
	)
	reach_value.text = (
		UILocalization.text(&"Slime Court")
		if bool(attempt.get("boss_attempt", false))
		else UILocalization.text(&"Stage {0}", [stage_index + 1])
	)
	time_value.text = _format_duration(maxi(int(RunState.get_run_elapsed_seconds()), 0))
	level_value.text = "Lv %d" % maxi(int(run_state.get("run_level", 1)), 1)
	build_heading.text = UILocalization.text(&"{0} BUILD", [profile_name.to_upper()])
	build_label.text = _build_summary({
		"profile": {"hero_loadout": ProfileState.get_hero_loadout()},
		"run_build": {
			"cards": (run_state.get("card_stacks", {}) as Dictionary).duplicate(true),
		},
	})
	rewards_heading.text = UILocalization.text(&"RETRY RULE")
	rewards_heading.add_theme_color_override("font_color", Styles.CORAL)
	materials_label.text = UILocalization.text(
		&"Health, coins, potions, cards, and equipment condition return to stage-entry values. Secured materials stay kept."
	)
	materials_label.add_theme_color_override("font_color", Styles.TEXT_MUTED)
	traveler_art.visible = true
	slime_king_art.visible = bool(attempt.get("boss_attempt", false))
	boss_core_art.visible = false
	retry_button.text = UILocalization.text(
		&"Retry Boss" if bool(attempt.get("boss_attempt", false)) else &"Retry Stage"
	)
	menu_button.text = UILocalization.text(&"End Expedition")
	Styles.apply_button(menu_button, Styles.CORAL, true)
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
	Styles.configure_label(outcome_title, Styles.TYPE_HERO, Styles.AMBER)
	Styles.configure_label(outcome_subtitle, Styles.TYPE_SECTION, Styles.TEXT)
	Styles.configure_label(detail_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	for label in [%ReachHeading, %TimeHeading, %LevelHeading]:
		Styles.configure_label(label as Label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	for label in [reach_value, time_value, level_value]:
		Styles.configure_label(label, Styles.TYPE_BUTTON, Styles.TEXT)
	Styles.configure_label(build_heading, Styles.TYPE_CAPTION, Styles.CYAN)
	Styles.configure_label(build_label, Styles.TYPE_BODY, Styles.TEXT_MUTED)
	Styles.configure_label(rewards_heading, Styles.TYPE_CAPTION, Styles.AMBER)
	Styles.configure_label(materials_label, Styles.TYPE_BODY, Styles.AMBER)
	Styles.apply_panel(summary_panel)
	summary_rule.color = Color(Styles.OUTLINE, 0.72)
	summary_divider.color = Color(Styles.OUTLINE, 0.72)
	Styles.apply_button(retry_button, Styles.AMBER)
	Styles.apply_button(menu_button, Styles.MOSS, true)


func _configure_art_slots() -> void:
	traveler_art.texture = Assets.texture_for_owner(&"traveler")
	slime_king_art.texture = Assets.texture_for_owner(&"slime_king")
	boss_core_art.texture = Assets.texture_for_owner(&"boss_core")
	for art in [traveler_art, slime_king_art, boss_core_art]:
		art.visible = art.texture != null


func _update_result_art(victory: bool, settlement: Dictionary) -> void:
	var delta: Dictionary = settlement.get("persistent_material_delta", {})
	traveler_art.visible = traveler_art.texture != null
	slime_king_art.visible = slime_king_art.texture != null and (
		victory or bool(settlement.get("boss_reached", false))
	)
	boss_core_art.visible = (
		boss_core_art.texture != null
		and victory
		and int(delta.get("boss_core", 0)) > 0
	)


func _result_detail(victory: bool, profile_name: String, settlement: Dictionary) -> String:
	if victory:
		return UILocalization.text(&"{0} defeated the Slime King.", [profile_name])
	match String(settlement.get("terminal_reason", "player_defeated")):
		"run_abandoned":
			return UILocalization.text(
				&"{0} ended the expedition. Secured materials were kept.", [profile_name]
			)
		"player_defeated":
			return UILocalization.text(&"{0} fell before reaching the crown.", [profile_name])
		_:
			return UILocalization.text(&"{0}'s expedition could not continue.", [profile_name])


func _final_reach(settlement: Dictionary) -> String:
	if bool(settlement.get("boss_reached", false)):
		return UILocalization.text(&"Slime Court")
	return UILocalization.text(
		&"Stage {0}", [clampi(int(settlement.get("stage_reached", 1)), 1, 3)]
	)


func _build_summary(settlement: Dictionary) -> String:
	var lines: Array[String] = []
	var equipment_names := _loadout_names(settlement)
	lines.append(
		"%s  %s" % [UILocalization.text(&"Equipment"), " / ".join(equipment_names)]
		if not equipment_names.is_empty()
		else "%s  %s" % [
			UILocalization.text(&"Equipment"), UILocalization.text(&"Starting gear")
		]
	)

	var card_names := _card_names(_run_build(settlement).get("cards", {}))
	lines.append(
		"%s  %s" % [UILocalization.text(&"Cards"), ", ".join(card_names)]
		if not card_names.is_empty()
		else "%s  %s" % [
			UILocalization.text(&"Cards"), UILocalization.text(&"None collected")
		]
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
				names.append(UILocalization.text(StringName(stone.display_name)))
			continue
		var model := catalog.get_model(item_id)
		if model != null:
			names.append(UILocalization.text(StringName(model.display_name)))
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
		names.append(
			"%s%s" % [
				UILocalization.text(StringName(card.display_name)),
				" x%d" % stacks if stacks > 1 else "",
			]
		)
	return names


func _material_summary(settlement: Dictionary) -> String:
	var delta: Dictionary = settlement.get("persistent_material_delta", {})
	var parts: Array[String] = []
	for material_id in MATERIAL_NAMES:
		var amount := int(delta.get(material_id, 0))
		if amount > 0:
			parts.append(
				"%s  +%d" % [
					UILocalization.text(StringName(MATERIAL_NAMES[material_id])), amount
				]
			)
	return (
		"\n".join(parts)
		if not parts.is_empty()
		else UILocalization.text(&"No new materials secured")
	)


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


func _apply_static_copy() -> void:
	%ReachHeading.text = UILocalization.text(&"FINAL REACH")
	%TimeHeading.text = UILocalization.text(&"RUN TIME")
	%LevelHeading.text = UILocalization.text(&"FINAL LEVEL")
	traveler_art.tooltip_text = UILocalization.text(&"Traveler")
	slime_king_art.tooltip_text = UILocalization.text(&"Slime King")
	boss_core_art.tooltip_text = UILocalization.text(&"Boss Core")


func _on_locale_changed(_locale: String = "") -> void:
	_apply_static_copy()
	match _configuration_kind:
		"result":
			configure(_last_victory, _last_profile_name, _last_settlement)
		"retry":
			configure_retry_decision(_last_profile_name, _last_attempt)
