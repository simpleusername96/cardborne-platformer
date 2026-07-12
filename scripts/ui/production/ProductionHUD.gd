extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var health_label: Label
var build_label: Label
var objective_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	SignalBus.player_health_changed.connect(_on_health_changed)
	SignalBus.player_stats_changed.connect(_on_stats_changed)
	SignalBus.stage_started.connect(_on_stage_started)
	SignalBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	_refresh()


func _build_ui() -> void:
	var left_panel := _hud_panel()
	left_panel.name = "HealthPanel"
	left_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_panel.offset_left = 20.0
	left_panel.offset_top = 18.0
	left_panel.offset_right = 306.0
	left_panel.offset_bottom = 90.0
	add_child(left_panel)

	health_label = Label.new()
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(health_label, 20)
	left_panel.add_child(_with_margin(health_label, 14))

	var right_panel := _hud_panel()
	right_panel.name = "BuildPanel"
	right_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_panel.offset_left = -326.0
	right_panel.offset_top = 18.0
	right_panel.offset_right = -20.0
	right_panel.offset_bottom = 90.0
	add_child(right_panel)

	build_label = Label.new()
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(build_label, 16)
	right_panel.add_child(_with_margin(build_label, 14))

	objective_label = Label.new()
	objective_label.name = "Objective"
	objective_label.text = "Reach the gate"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_label.offset_left = -142.0
	objective_label.offset_top = 28.0
	objective_label.offset_right = 142.0
	objective_label.offset_bottom = 58.0
	Styles.configure_label(objective_label, 14, Styles.TEXT_MUTED)
	add_child(objective_label)

	prompt_panel = _hud_panel(Styles.SURFACE_RAISED, Styles.AMBER)
	prompt_panel.name = "InteractionPrompt"
	prompt_panel.visible = false
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.offset_left = -180.0
	prompt_panel.offset_top = -78.0
	prompt_panel.offset_right = 180.0
	prompt_panel.offset_bottom = -24.0
	add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(prompt_label, 16)
	prompt_panel.add_child(_with_margin(prompt_label, 10))


func _hud_panel(
	background: Color = Styles.SURFACE,
	border: Color = Styles.OUTLINE
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Styles.panel_style(Color(background, 0.94), border))
	return panel


func _with_margin(control: Control, amount: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(control)
	return margin


func _refresh() -> void:
	_on_health_changed(RunState.current_health, RunState.max_health)
	_on_stats_changed(RunState.get_effective_stats())


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "HP  %d / %d" % [current_health, max_health]


func _on_stats_changed(_stats: Dictionary) -> void:
	var profile_name := "Adventurer"
	if RunState.selected_profile != null:
		profile_name = RunState.selected_profile.display_name
	build_label.text = "%s\nLv %d   XP %d   Coins %d" % [
		profile_name,
		RunState.run_level,
		RunState.current_xp,
		RunState.coins,
	]


func _on_stage_started(_stage_id: String, stage_display_name: String) -> void:
	objective_label.text = "%s  -  Reach the gate" % stage_display_name


func _on_interaction_prompt_changed(prompt_text: String, active: bool) -> void:
	prompt_panel.visible = active and not prompt_text.is_empty()
	prompt_label.text = "E  %s" % prompt_text
