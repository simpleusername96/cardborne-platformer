extends Control

var health_label: Label
var profile_label: Label
var stage_label: Label
var counters_label: Label
var controls_label: Label
var prompt_label: Label
var status_label: Label
var health_panel: PanelContainer
var counters_panel: PanelContainer
var controls_panel: PanelContainer
var status_panel: PanelContainer
var prompt_panel: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_connect_signals()
	_sync_from_state()
	_layout_panels()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and health_panel != null:
		_layout_panels()


func _build_ui() -> void:
	var top_left := _make_panel(Vector2(16, 16), Vector2(360, 82))
	health_panel = top_left.get_parent() as PanelContainer
	var top_left_box := VBoxContainer.new()
	top_left_box.add_theme_constant_override("separation", 4)
	top_left.add_child(top_left_box)

	health_label = Label.new()
	health_label.text = "HP"
	top_left_box.add_child(health_label)

	profile_label = Label.new()
	profile_label.text = "Profile"
	top_left_box.add_child(profile_label)

	stage_label = Label.new()
	stage_label.text = "Stage"
	top_left_box.add_child(stage_label)

	var top_right := _make_panel(Vector2(890, 16), Vector2(374, 54))
	counters_panel = top_right.get_parent() as PanelContainer
	counters_label = Label.new()
	counters_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(counters_label)

	var controls := _make_panel(Vector2(890, 82), Vector2(374, 116))
	controls_panel = controls.get_parent() as PanelContainer
	controls_label = Label.new()
	controls_label.text = (
		"Controls\n"
		+"Move A/D or Arrows\n"
		+"Jump Space   Dash K/Shift\n"
		+"Attack J/Click   Interact E/Enter\n"
		+"Profile Tab   Settings Esc"
	)
	controls_label.clip_text = true
	controls_label.add_theme_font_size_override("font_size", 14)
	controls.add_child(controls_label)

	var bottom_left := _make_panel(Vector2(16, 628), Vector2(360, 52))
	status_panel = bottom_left.get_parent() as PanelContainer
	status_panel.visible = false
	status_label = Label.new()
	status_label.text = ""
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_left.add_child(status_label)

	var prompt_panel := _make_panel(Vector2(490, 628), Vector2(300, 52))
	self.prompt_panel = prompt_panel.get_parent() as PanelContainer
	self.prompt_panel.visible = false
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.text = ""
	prompt_panel.add_child(prompt_label)


func _connect_signals() -> void:
	SignalBus.player_health_changed.connect(_on_player_health_changed)
	SignalBus.selected_profile_changed.connect(_on_selected_profile_changed)
	SignalBus.stage_started.connect(_on_stage_started)
	SignalBus.stage_cleared.connect(_on_stage_cleared)
	SignalBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	SignalBus.status_message_changed.connect(_on_status_message_changed)


func _sync_from_state() -> void:
	_on_player_health_changed(RunState.current_health, RunState.max_health)
	if RunState.selected_profile != null:
		_on_selected_profile_changed(
			RunState.selected_profile.id,
			RunState.selected_profile.display_name,
			RunState.selected_profile.visual_color
		)
	counters_label.text = "Lv %d  XP %d  Coins %d" % [RunState.run_level, RunState.current_xp, RunState.coins]


func _layout_panels() -> void:
	var viewport_size := get_viewport_rect().size
	var horizontal_margin := 16.0
	var compact_width := minf(360.0, viewport_size.x - horizontal_margin * 2.0)

	_set_panel_rect(health_panel, Vector2(horizontal_margin, 16.0), Vector2(compact_width, 94.0))

	if viewport_size.x < 760.0:
		_set_panel_rect(counters_panel, Vector2(horizontal_margin, 122.0), Vector2(compact_width, 54.0))
		_set_panel_rect(controls_panel, Vector2(horizontal_margin, 188.0), Vector2(compact_width, 132.0))
		counters_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		_set_panel_rect(counters_panel, Vector2(viewport_size.x - 390.0, 16.0), Vector2(374.0, 54.0))
		_set_panel_rect(controls_panel, Vector2(viewport_size.x - 390.0, 82.0), Vector2(374.0, 116.0))
		counters_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var bottom_y := maxf(16.0, viewport_size.y - 92.0)
	_set_panel_rect(status_panel, Vector2(horizontal_margin, bottom_y), Vector2(compact_width, 52.0))

	var prompt_width := minf(300.0, viewport_size.x - horizontal_margin * 2.0)
	var prompt_y := bottom_y - 60.0 if viewport_size.x < 760.0 else bottom_y
	_set_panel_rect(
		prompt_panel,
		Vector2(maxf(horizontal_margin, (viewport_size.x - prompt_width) * 0.5), prompt_y),
		Vector2(prompt_width, 52.0)
	)


func _set_panel_rect(panel: PanelContainer, panel_position: Vector2, panel_size: Vector2) -> void:
	panel.position = panel_position
	panel.custom_minimum_size = panel_size
	panel.size = panel_size


func _make_panel(panel_position: Vector2, min_size: Vector2) -> MarginContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	return margin


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.82)
	style.border_color = Color(0.40, 0.45, 0.52, 0.65)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "HP %d / %d" % [current_health, max_health]


func _on_selected_profile_changed(_profile_id: String, display_name: String, _color: Color) -> void:
	profile_label.text = "Profile: %s" % display_name


func _on_stage_started(_stage_id: String, stage_display_name: String) -> void:
	stage_label.text = stage_display_name
	status_label.text = ""
	status_panel.visible = false


func _on_stage_cleared(stage_id: String) -> void:
	status_label.text = "Cleared: %s" % stage_id
	status_panel.visible = true


func _on_interaction_prompt_changed(prompt_text: String, active: bool) -> void:
	prompt_label.text = "E / Enter: %s" % prompt_text if active else ""
	prompt_panel.visible = active


func _on_status_message_changed(message: String) -> void:
	status_label.text = message
	status_panel.visible = not message.is_empty()
