extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var health_label: Label
var build_label: Label
var objective_label: Label
var combat_panel: PanelContainer
var combat_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var reward_receipt: RewardReceiptPresenter
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_bar: ProgressBar
var boss_stagger_bar: ProgressBar
var boss_status_label: Label
var _stage_display_name: String = "Ruin Approach"
var _stage_id: String = "ruin_approach"
var _combat_state: Dictionary = {}
var _interaction_prompt_text: String = ""
var _interaction_prompt_active: bool = false
var _boss: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	SignalBus.player_health_changed.connect(_on_health_changed)
	SignalBus.player_stats_changed.connect(_on_stats_changed)
	SignalBus.run_state_changed.connect(_on_run_state_changed)
	SignalBus.stage_started.connect(_on_stage_started)
	SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	SignalBus.encounter_state_changed.connect(_on_encounter_state_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)
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

	combat_panel = _hud_panel()
	combat_panel.name = "CombatPanel"
	combat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	combat_panel.offset_left = 20.0
	combat_panel.offset_top = 104.0
	combat_panel.offset_right = 370.0
	combat_panel.offset_bottom = 264.0
	add_child(combat_panel)

	combat_label = Label.new()
	combat_label.name = "CombatState"
	combat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(combat_label, 14)
	combat_panel.add_child(_with_margin(combat_label, 14))

	_build_boss_panel()

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
	prompt_label.name = "PromptText"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(prompt_label, 16)
	prompt_panel.add_child(_with_margin(prompt_label, 10))

	reward_receipt = RewardReceiptPresenter.new()
	reward_receipt.name = "RewardReceiptPresenter"
	add_child(reward_receipt)


func _build_boss_panel() -> void:
	boss_panel = _hud_panel(Color("20292d"), Styles.AMBER)
	boss_panel.name = "BossPanel"
	boss_panel.visible = false
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.offset_left = -230.0
	boss_panel.offset_top = 98.0
	boss_panel.offset_right = 230.0
	boss_panel.offset_bottom = 181.0
	add_child(boss_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 7)
	boss_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var heading := HBoxContainer.new()
	column.add_child(heading)
	boss_name_label = Label.new()
	boss_name_label.name = "BossName"
	boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(boss_name_label, 14, Styles.TEXT)
	heading.add_child(boss_name_label)
	boss_status_label = Label.new()
	boss_status_label.name = "BossStatus"
	boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(boss_status_label, 13, Styles.AMBER)
	heading.add_child(boss_status_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealth"
	boss_health_bar.custom_minimum_size = Vector2(0.0, 15.0)
	boss_health_bar.show_percentage = false
	boss_health_bar.add_theme_stylebox_override(
		"background", Styles.panel_style(Color("11171a"), Color("414c51"), 1)
	)
	boss_health_bar.add_theme_stylebox_override(
		"fill", Styles.panel_style(Color("73ba4d"), Color("a9d36f"), 1)
	)
	column.add_child(boss_health_bar)

	boss_stagger_bar = ProgressBar.new()
	boss_stagger_bar.name = "BossStagger"
	boss_stagger_bar.custom_minimum_size = Vector2(0.0, 5.0)
	boss_stagger_bar.show_percentage = false
	boss_stagger_bar.add_theme_stylebox_override(
		"background", Styles.panel_style(Color("11171a"), Color("354147"), 0)
	)
	boss_stagger_bar.add_theme_stylebox_override(
		"fill", Styles.panel_style(Styles.CYAN, Styles.CYAN, 0)
	)
	column.add_child(boss_stagger_bar)


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
	_refresh_run_summary()


func _on_run_state_changed(_snapshot: Dictionary) -> void:
	_refresh_run_summary()


func _refresh_run_summary() -> void:
	var profile_name := "Adventurer"
	if RunState.selected_profile != null:
		profile_name = RunState.selected_profile.display_name
	build_label.text = "%s\nLv %d   XP %d   Coins %d" % [
		profile_name,
		RunState.run_level,
		RunState.current_xp,
		RunState.coins,
	]


func _on_stage_started(stage_id: String, stage_display_name: String) -> void:
	_stage_id = stage_id
	_stage_display_name = stage_display_name
	if stage_id == "slime_court":
		objective_label.text = "Defeat the Slime King"
		boss_panel.visible = true
		_set_boss_combat_layout(true)
		_show_boss_intro_state()
		call_deferred("_bind_boss")
	else:
		objective_label.text = "%s  -  Defeat enemies" % _stage_display_name
		boss_panel.visible = false
		_set_boss_combat_layout(false)


func _on_combat_state_changed(state: Dictionary) -> void:
	_combat_state = state.duplicate(true)
	_refresh_combat_state()


func _refresh_combat_state() -> void:
	if combat_label == null:
		return
	var lines: Array[String] = []
	for action in _combat_state.get("actions", []):
		var input_action := str(action.get("input_action", ""))
		var binding := Game.get_input_action_label(input_action)
		binding = Game.get_action_binding_text(input_action, binding)
		var cooldown := float(action.get("cooldown", 0.0))
		var readiness := "READY" if cooldown <= 0.05 else "%.1fs" % cooldown
		lines.append("%s  %s   %s" % [binding, str(action.get("label", "Action")), readiness])
	var guarded_time := float(_combat_state.get("guarded_time", 0.0))
	var rearm_time := float(_combat_state.get("guarded_rearm_time", 0.0))
	if guarded_time > 0.0:
		lines.append("Resolve Guard   %.1fs" % guarded_time)
	elif rearm_time > 0.0:
		lines.append("Resolve Guard   %.1fs" % rearm_time)
	var charge_fraction := float(_combat_state.get("charge_fraction", 0.0))
	if charge_fraction > 0.0:
		lines.append("Charge   %d%%" % int(floor(charge_fraction * 100.0 + 0.5)))
	if _combat_state.has("hunter_mark_count"):
		var mark_count := int(_combat_state.get("hunter_mark_count", 0))
		if mark_count > 0:
			lines.append("Hunter's Mark   %d" % mark_count)
	if _combat_state.has("flow_stacks"):
		var flow_stacks := int(_combat_state.get("flow_stacks", 0))
		var flow_time := float(_combat_state.get("flow_time", 0.0))
		lines.append("Flow   %d / 3   %.1fs" % [flow_stacks, flow_time])
	var death_mark_count := int(_combat_state.get("death_mark_count", 0))
	if death_mark_count > 0:
		lines.append("Death Mark   %d" % death_mark_count)
	combat_label.text = "\n".join(lines)


func _on_encounter_state_changed(state: Dictionary) -> void:
	if _stage_id == "slime_court":
		return
	var remaining := int(state.get("remaining", 0))
	if remaining > 0:
		objective_label.text = "%s  -  Defeat enemies  %d" % [_stage_display_name, remaining]
	else:
		objective_label.text = "%s  -  Enter the gate" % _stage_display_name


func _on_input_bindings_changed() -> void:
	_refresh_combat_state()
	_refresh_interaction_prompt()


func _on_interaction_prompt_changed(prompt_text: String, active: bool) -> void:
	_interaction_prompt_text = prompt_text
	_interaction_prompt_active = active
	_refresh_interaction_prompt()


func _refresh_interaction_prompt() -> void:
	if prompt_panel == null:
		return
	prompt_panel.visible = _interaction_prompt_active and not _interaction_prompt_text.is_empty()
	var binding := Game.get_action_binding_text("interact", "E")
	prompt_label.text = "%s  %s" % [binding, _interaction_prompt_text]


func _set_boss_combat_layout(enabled: bool) -> void:
	if combat_panel == null:
		return
	if enabled:
		combat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		combat_panel.offset_left = 20.0
		combat_panel.offset_top = 104.0
		combat_panel.offset_right = 240.0
		combat_panel.offset_bottom = 264.0
	else:
		combat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		combat_panel.offset_left = 20.0
		combat_panel.offset_top = 104.0
		combat_panel.offset_right = 370.0
		combat_panel.offset_bottom = 264.0


func _show_boss_intro_state() -> void:
	boss_name_label.text = "SLIME KING   80 / 80"
	boss_status_label.text = "THE COURT SEALS"
	boss_health_bar.max_value = 80.0
	boss_health_bar.value = 80.0
	boss_stagger_bar.max_value = 100.0
	boss_stagger_bar.value = 0.0


func _bind_boss() -> void:
	_boss = get_tree().get_first_node_in_group("boss")
	if _boss == null:
		return
	var snapshot_callback := Callable(self, "_on_boss_snapshot")
	if _boss.has_signal("snapshot_changed") and not _boss.is_connected("snapshot_changed", snapshot_callback):
		_boss.connect("snapshot_changed", snapshot_callback)
	if _boss.has_method("get_runtime_snapshot"):
		_on_boss_snapshot(_boss.call("get_runtime_snapshot"))


func _on_boss_snapshot(snapshot: Dictionary) -> void:
	if boss_panel == null:
		return
	boss_panel.visible = true
	var health := maxi(int(snapshot.get("health", 0)), 0)
	var max_health := maxi(int(snapshot.get("max_health", 80)), 1)
	var phase := maxi(int(snapshot.get("phase", 1)), 1)
	boss_name_label.text = "SLIME KING   %d / %d   PHASE %s" % [
		health,
		max_health,
		_roman_phase(phase),
	]
	boss_health_bar.max_value = float(max_health)
	boss_health_bar.value = float(health)
	boss_stagger_bar.max_value = maxf(float(snapshot.get("stagger_capacity", 100)), 1.0)
	boss_stagger_bar.value = float(snapshot.get("stagger_meter", 0))
	boss_status_label.text = _boss_status(snapshot)


func _boss_status(snapshot: Dictionary) -> String:
	var actor_state := StringName(snapshot.get("actor_state", &"dormant"))
	if actor_state == &"phase_transition":
		return "PHASE SHIFT"
	if actor_state == &"staggered":
		return "STAGGERED - ATTACK"
	if actor_state == &"defeated":
		return "CROWN BROKEN"
	if actor_state in [&"dormant", &"cancelled"]:
		return "THE COURT SEALS"
	var pattern: Dictionary = snapshot.get("pattern", {})
	var pattern_id := StringName(pattern.get("pattern_id", &""))
	var pattern_state := StringName(pattern.get("state", &"idle"))
	if pattern_state == &"recovery":
		return "OPENING - ATTACK"
	if pattern_state == &"neutral":
		return "REPOSITION"
	if pattern_state == &"active":
		return _active_pattern_label(pattern_id)
	if pattern_state == &"startup":
		return _startup_pattern_label(pattern_id)
	return "WATCH THE CROWN"


func _startup_pattern_label(pattern_id: StringName) -> String:
	return {
		&"jump_slam": "SHADOW - MOVE",
		&"body_bump": "LANE LOCK - EVADE",
		&"poison_bands": "FIND SAFE FLOOR",
		&"small_slime_summon": "SPAWN MARKERS",
	}.get(pattern_id, "ATTACK INCOMING")


func _active_pattern_label(pattern_id: StringName) -> String:
	return {
		&"jump_slam": "JUMP THE SHOCKWAVE",
		&"body_bump": "CLEAR THE LANE",
		&"poison_bands": "HOLD SAFE FLOOR",
	}.get(pattern_id, "DODGE")


func _roman_phase(phase: int) -> String:
	return "II" if phase >= 2 else "I"
