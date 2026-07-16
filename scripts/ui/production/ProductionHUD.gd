extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Glyph = preload("res://scripts/ui/production/components/HUDGlyph.gd")
const CombatDock = preload("res://scripts/ui/production/components/HUDCombatDock.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")

const OBJECTIVE_EXPANDED_SECONDS := 4.0

var health_panel: PanelContainer
var portrait_frame: PanelContainer
var portrait_glyph: HUDGlyph
var profile_label: Label
var health_value_label: Label
var health_bar: ProgressBar
var level_xp_label: Label
var armor_label: Label

var objective_container: Control
var objective_title_label: Label
var objective_detail_label: Label
var objective_timer: Timer

var combat_dock: HUDCombatDock

var context_lane: Control
var prompt_panel: PanelContainer
var prompt_binding_label: Label
var prompt_label: Label
var reward_receipt: RewardReceiptPresenter

var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_bar: ProgressBar
var boss_stagger_bar: ProgressBar
var boss_status_label: Label

var _stage_display_name: String = "Ruin Approach"
var _stage_id: String = "ruin_approach"
var _run_snapshot: Dictionary = {}
var _combat_state: Dictionary = {}
var _interaction_prompt_text: String = ""
var _interaction_prompt_active: bool = false
var _receipt_active: bool = false
var _compact_layout: bool = false
var _boss: Node
var _boss_snapshot: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Styles.apply_theme(self)
	_build_ui()
	SignalBus.player_health_changed.connect(_on_health_changed)
	SignalBus.run_state_changed.connect(_on_run_state_changed)
	SignalBus.stage_started.connect(_on_stage_started)
	SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	SignalBus.encounter_state_changed.connect(_on_encounter_state_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)
	SignalBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	var initial_snapshot: Variant = RunState.get_run_snapshot()
	if initial_snapshot != null and initial_snapshot.has_method("to_dictionary"):
		_on_run_state_changed(initial_snapshot.call("to_dictionary"))
	else:
		_refresh_all()


func _exit_tree() -> void:
	# RunDirector replaces the HUD and loads the next stage in the same frame.
	# Disconnect immediately so the detached HUD cannot receive the new stage's
	# singleton events before queue_free is flushed.
	var callbacks := {
		&"player_health_changed": Callable(self, "_on_health_changed"),
		&"run_state_changed": Callable(self, "_on_run_state_changed"),
		&"stage_started": Callable(self, "_on_stage_started"),
		&"combat_state_changed": Callable(self, "_on_combat_state_changed"),
		&"encounter_state_changed": Callable(self, "_on_encounter_state_changed"),
		&"input_bindings_changed": Callable(self, "_on_input_bindings_changed"),
		&"interaction_prompt_changed": Callable(self, "_on_interaction_prompt_changed"),
	}
	for signal_name in callbacks:
		var callback: Callable = callbacks[signal_name]
		if SignalBus.is_connected(signal_name, callback):
			SignalBus.disconnect(signal_name, callback)
	var localization := get_node_or_null("/root/UILocalization")
	var locale_callback := Callable(self, "_on_locale_changed")
	if localization != null and localization.is_connected(&"locale_changed", locale_callback):
		localization.disconnect(&"locale_changed", locale_callback)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and combat_dock != null:
		_layout_responsive()


func get_layout_snapshot() -> Dictionary:
	var dock_snapshot := combat_dock.get_display_snapshot() if combat_dock != null else {}
	var local_safe_gap: Rect2 = dock_snapshot.get("safe_gap_rect", Rect2())
	var safe_gap := Rect2(
		combat_dock.position + local_safe_gap.position,
		local_safe_gap.size
	) if combat_dock != null else Rect2()
	return {
		"viewport": size,
		"health_rect": health_panel.get_rect() if health_panel != null else Rect2(),
		"objective_rect": objective_container.get_rect() if objective_container != null else Rect2(),
		"boss_rect": boss_panel.get_rect() if boss_panel != null else Rect2(),
		"combat_dock_rect": combat_dock.get_rect() if combat_dock != null else Rect2(),
		"player_safe_gap_rect": safe_gap,
		"context_lane_rect": context_lane.get_rect() if context_lane != null else Rect2(),
		"objective_detail": objective_detail_label.text if objective_detail_label != null else "",
		"prompt_visible": prompt_panel.visible if prompt_panel != null else false,
		"prompt_binding": prompt_binding_label.text if prompt_binding_label != null else "",
		"prompt_text": prompt_label.text if prompt_label != null else "",
		"receipt_active": _receipt_active,
		"armor": armor_label.text if armor_label != null else "",
		"combat": dock_snapshot,
	}


func _build_ui() -> void:
	_build_health_cluster()
	_build_objective()
	_build_boss_panel()
	_build_combat_dock()
	_build_context_lane()
	_layout_responsive()


func _build_health_cluster() -> void:
	health_panel = _hud_panel(Color(Styles.SURFACE, 0.95))
	health_panel.name = "HealthCluster"
	health_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(health_panel)

	var margin := _margin_container(9, 8, 10, 8)
	health_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	portrait_frame = PanelContainer.new()
	portrait_frame.name = "ClassEmblem"
	portrait_frame.custom_minimum_size = Vector2(50.0, 50.0)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color("151c1f"), Styles.AMBER, 2)
	)
	row.add_child(portrait_frame)
	var portrait_margin := _margin_container(7, 7, 7, 7)
	portrait_frame.add_child(portrait_margin)
	portrait_glyph = Glyph.new()
	portrait_glyph.name = "PortraitGlyph"
	portrait_margin.add_child(portrait_glyph)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 2)
	row.add_child(details)

	var heading := HBoxContainer.new()
	details.add_child(heading)
	profile_label = Label.new()
	profile_label.name = "ProfileName"
	profile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(profile_label, Styles.TYPE_BODY, Styles.TEXT)
	heading.add_child(profile_label)
	health_value_label = Label.new()
	health_value_label.name = "HealthValue"
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(health_value_label, Styles.TYPE_BODY, Styles.TEXT)
	heading.add_child(health_value_label)

	health_bar = ProgressBar.new()
	health_bar.name = "PlayerHealth"
	health_bar.custom_minimum_size = Vector2(0.0, 12.0)
	health_bar.show_percentage = false
	health_bar.theme_type_variation = &"HealthMeter"
	details.add_child(health_bar)

	level_xp_label = Label.new()
	level_xp_label.name = "LevelXP"
	Styles.configure_label(level_xp_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	details.add_child(level_xp_label)

	armor_label = Label.new()
	armor_label.name = "ArmorState"
	armor_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(armor_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	details.add_child(armor_label)


func _build_objective() -> void:
	objective_container = Control.new()
	objective_container.name = "ObjectiveBand"
	objective_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_container)
	var rule := ColorRect.new()
	rule.name = "ObjectiveRule"
	rule.color = Color(Styles.OUTLINE, 0.88)
	rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rule.offset_bottom = 2.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_container.add_child(rule)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 7.0
	column.add_theme_constant_override("separation", 1)
	objective_container.add_child(column)
	objective_title_label = Label.new()
	objective_title_label.name = "ObjectiveTitle"
	objective_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(objective_title_label, Styles.TYPE_BODY, Styles.TEXT)
	column.add_child(objective_title_label)
	objective_detail_label = Label.new()
	objective_detail_label.name = "ObjectiveDetail"
	objective_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(objective_detail_label, Styles.TYPE_CAPTION, Styles.TEXT_MUTED)
	column.add_child(objective_detail_label)
	objective_timer = Timer.new()
	objective_timer.one_shot = true
	objective_timer.wait_time = OBJECTIVE_EXPANDED_SECONDS
	objective_timer.timeout.connect(_collapse_objective)
	add_child(objective_timer)
	_show_objective(_t("Defeat enemies"))


func _build_combat_dock() -> void:
	combat_dock = CombatDock.new()
	combat_dock.name = "CombatDock"
	combat_dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	add_child(combat_dock)


func _build_context_lane() -> void:
	context_lane = Control.new()
	context_lane.name = "ContextLane"
	context_lane.set_anchors_preset(Control.PRESET_CENTER_TOP)
	context_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(context_lane)
	prompt_panel = _hud_panel(Color(Styles.SURFACE_RAISED, 0.97))
	prompt_panel.name = "InteractionPrompt"
	Styles.apply_panel(prompt_panel, &"PromptBadge")
	prompt_panel.visible = false
	prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	context_lane.add_child(prompt_panel)
	var margin := _margin_container(12, 9, 12, 9)
	prompt_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(42.0, 28.0)
	Styles.apply_panel(badge, &"PromptBadge")
	row.add_child(badge)
	prompt_binding_label = Label.new()
	prompt_binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_binding_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(prompt_binding_label, Styles.TYPE_CAPTION, Styles.TEXT)
	badge.add_child(prompt_binding_label)
	prompt_label = Label.new()
	prompt_label.name = "PromptText"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(prompt_label, Styles.TYPE_BODY, Styles.TEXT)
	row.add_child(prompt_label)

	reward_receipt = RewardReceiptPresenter.new()
	reward_receipt.name = "RewardReceiptPresenter"
	reward_receipt.set_embedded(true)
	reward_receipt.presentation_state_changed.connect(_on_receipt_state_changed)
	context_lane.add_child(reward_receipt)


func _build_boss_panel() -> void:
	boss_panel = _hud_panel(Color("20292d"))
	boss_panel.name = "BossPanel"
	boss_panel.visible = false
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	add_child(boss_panel)
	var margin := _margin_container(12, 6, 12, 6)
	boss_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	boss_name_label = Label.new()
	boss_name_label.name = "BossName"
	boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(boss_name_label, Styles.TYPE_BODY, Styles.TEXT)
	heading.add_child(boss_name_label)
	boss_status_label = Label.new()
	boss_status_label.name = "BossStatus"
	boss_status_label.custom_minimum_size = Vector2(100.0, 0.0)
	boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(boss_status_label, Styles.TYPE_CAPTION, Styles.AMBER)
	heading.add_child(boss_status_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealth"
	boss_health_bar.custom_minimum_size = Vector2(0.0, 13.0)
	boss_health_bar.show_percentage = false
	boss_health_bar.theme_type_variation = &"BossMeter"
	column.add_child(boss_health_bar)
	boss_stagger_bar = ProgressBar.new()
	boss_stagger_bar.name = "BossStagger"
	boss_stagger_bar.custom_minimum_size = Vector2(0.0, 4.0)
	boss_stagger_bar.show_percentage = false
	boss_stagger_bar.theme_type_variation = &"ResourceMeter"
	column.add_child(boss_stagger_bar)


func _hud_panel(
	background: Color = Styles.SURFACE
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Styles.flat_style(background))
	return panel


func _margin_container(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _layout_responsive() -> void:
	var compact := size.x < 1100.0
	_compact_layout = compact
	health_panel.offset_left = 16.0
	health_panel.offset_top = 14.0
	health_panel.offset_right = 350.0
	health_panel.offset_bottom = 132.0
	var objective_width := 260.0 if compact else 400.0
	objective_container.offset_left = -objective_width * 0.5
	objective_container.offset_top = 17.0
	objective_container.offset_right = objective_width * 0.5
	objective_container.offset_bottom = 78.0
	var boss_width := 372.0 if compact else 500.0
	var boss_shift := 70.0 if compact else 0.0
	boss_panel.offset_left = -boss_width * 0.5 + boss_shift
	boss_panel.offset_top = 14.0
	boss_panel.offset_right = boss_width * 0.5 + boss_shift
	boss_panel.offset_bottom = 92.0
	boss_name_label.add_theme_font_size_override(
		"font_size", Styles.TYPE_CAPTION if compact else Styles.TYPE_BODY
	)

	combat_dock.set_compact(compact)
	var dock_size := Vector2(728.0 if compact else 954.0, 112.0)
	# The two attack choices occupy less width than the three status tiles.
	# Offset the dock so its intentional empty lane, not its outer bounds, follows the player.
	var safe_gap_shift := 49.0 if compact else 137.0
	combat_dock.offset_left = -dock_size.x * 0.5 + safe_gap_shift
	combat_dock.offset_top = -(dock_size.y + 14.0)
	combat_dock.offset_right = dock_size.x * 0.5 + safe_gap_shift
	combat_dock.offset_bottom = -14.0

	var lane_width := 400.0 if compact else minf(620.0, size.x - 620.0)
	var lane_height := 96.0
	context_lane.offset_left = -lane_width * 0.5
	context_lane.offset_top = 140.0
	context_lane.offset_right = lane_width * 0.5
	context_lane.offset_bottom = 140.0 + lane_height
	combat_dock.configure(_run_snapshot, _combat_state)
	_refresh_boss_header()


func _refresh_all() -> void:
	_refresh_health_cluster()
	if combat_dock != null:
		combat_dock.configure(_run_snapshot, _combat_state)
	_refresh_context_lane()


func _on_health_changed(current_health: int, max_health: int) -> void:
	_run_snapshot["health"] = current_health
	_run_snapshot["max_health"] = max_health
	_refresh_health_cluster()


func _on_run_state_changed(snapshot: Dictionary) -> void:
	_run_snapshot = snapshot.duplicate(true)
	_refresh_health_cluster()
	if combat_dock != null:
		combat_dock.configure(_run_snapshot, _combat_state)


func _refresh_health_cluster() -> void:
	if health_bar == null:
		return
	var profile_id := StringName(_run_snapshot.get("profile_id", "traveler"))
	if profile_id == &"":
		profile_id = &"traveler"
	var current_health := maxi(int(_run_snapshot.get("health", 0)), 0)
	var max_health := maxi(int(_run_snapshot.get("max_health", 1)), 1)
	var accent := Styles.hero_accent()
	var profile_display_name := String(_run_snapshot.get("profile_display_name", "")).strip_edges()
	if profile_display_name.is_empty():
		profile_display_name = String(profile_id).replace("_", " ")
	profile_label.text = _t(profile_display_name).to_upper()
	health_value_label.text = "%d / %d" % [current_health, max_health]
	health_bar.max_value = float(max_health)
	health_bar.value = float(current_health)
	var low_health := float(current_health) / float(max_health) <= 0.3
	var health_tone := Styles.HEALTH_LOW if low_health else Styles.HEALTH
	health_bar.add_theme_stylebox_override(
		"fill", Styles.flat_style(health_tone)
	)
	level_xp_label.text = "LV %d   |   %d XP" % [
		maxi(int(_run_snapshot.get("level", 1)), 1),
		maxi(int(_run_snapshot.get("xp", 0)), 0),
	]
	portrait_frame.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color("151c1f"), accent, 2)
	)
	portrait_glyph.configure(profile_id, accent)
	var loadout: Dictionary = _combat_state.get("loadout", {})
	var armor_name := String(loadout.get("armor_display_name", "Traveler Coat"))
	var health_bonus := maxi(int(loadout.get("armor_health_bonus", 0)), 0)
	armor_label.text = "%s%s" % [
		_t(armor_name),
		"  +%d HP" % health_bonus if health_bonus > 0 else "",
	]


func _on_combat_state_changed(state: Dictionary) -> void:
	_combat_state = state.duplicate(true)
	_refresh_health_cluster()
	if combat_dock != null:
		combat_dock.configure(_run_snapshot, _combat_state)


func _on_stage_started(stage_id: String, stage_display_name: String) -> void:
	_stage_id = stage_id
	_stage_display_name = stage_display_name
	if stage_id == "slime_court":
		objective_container.visible = false
		boss_panel.visible = true
		_show_boss_intro_state()
		call_deferred("_bind_boss")
	elif stage_id == "arsenal_trial":
		boss_panel.visible = false
		objective_container.visible = false
	elif stage_id == "safe_intermission":
		boss_panel.visible = false
		objective_container.visible = true
		_show_objective(_t("Prepare, then continue"))
	else:
		boss_panel.visible = false
		objective_container.visible = true
		_show_objective(_t("Defeat enemies"))


func _on_encounter_state_changed(state: Dictionary) -> void:
	if _stage_id == "slime_court":
		return
	var remaining := int(state.get("remaining", 0))
	_show_objective(
		_t("Defeat %d remaining", [remaining])
		if remaining > 0
		else _t("Enter the gate")
	)


func _show_objective(detail: String) -> void:
	if objective_title_label == null:
		return
	objective_title_label.text = _t(_stage_display_name).to_upper()
	objective_detail_label.text = detail
	objective_detail_label.visible = true
	if objective_timer != null and objective_timer.is_inside_tree():
		objective_timer.start()


func _collapse_objective() -> void:
	if objective_detail_label != null:
		objective_detail_label.visible = false


func _on_input_bindings_changed() -> void:
	if combat_dock != null:
		combat_dock.configure(_run_snapshot, _combat_state)
	_refresh_context_lane()


func _on_interaction_prompt_changed(prompt_text: String, active: bool) -> void:
	_interaction_prompt_text = prompt_text
	_interaction_prompt_active = active
	_refresh_context_lane()


func _on_receipt_state_changed(active: bool) -> void:
	_receipt_active = active
	_refresh_context_lane()


func _refresh_context_lane() -> void:
	if prompt_panel == null:
		return
	prompt_panel.visible = (
		not _receipt_active
		and _interaction_prompt_active
		and not _interaction_prompt_text.is_empty()
	)
	prompt_binding_label.text = Game.get_action_binding_text("interact", "E")
	prompt_label.text = _t(_interaction_prompt_text)


func _show_boss_intro_state() -> void:
	_boss_snapshot = {
		"actor_state": &"dormant",
		"health": 80,
		"max_health": 80,
		"phase": 1,
	}
	_refresh_boss_header()
	boss_status_label.text = _t("THE COURT SEALS")
	boss_health_bar.max_value = 80.0
	boss_health_bar.value = 80.0
	boss_stagger_bar.max_value = 100.0
	boss_stagger_bar.value = 0.0


func _bind_boss() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	_boss = tree.get_first_node_in_group("boss")
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
	objective_container.visible = false
	_boss_snapshot = snapshot.duplicate(true)
	var health := maxi(int(_boss_snapshot.get("health", 0)), 0)
	var max_health := maxi(int(_boss_snapshot.get("max_health", 80)), 1)
	_refresh_boss_header()
	boss_health_bar.max_value = float(max_health)
	boss_health_bar.value = float(health)
	boss_stagger_bar.max_value = maxf(float(snapshot.get("stagger_capacity", 100)), 1.0)
	boss_stagger_bar.value = float(snapshot.get("stagger_meter", 0))
	boss_status_label.text = _boss_status(_boss_snapshot)


func _refresh_boss_header() -> void:
	if boss_name_label == null or _boss_snapshot.is_empty():
		return
	var health := maxi(int(_boss_snapshot.get("health", 0)), 0)
	var max_health := maxi(int(_boss_snapshot.get("max_health", 80)), 1)
	var phase := maxi(int(_boss_snapshot.get("phase", 1)), 1)
	if _compact_layout:
		boss_name_label.text = _t("SLIME KING %d/%d P%d", [health, max_health, phase])
	else:
		boss_name_label.text = _t("SLIME KING %d/%d · PHASE %s", [
			health,
			max_health,
			_roman_phase(phase),
		])


func _boss_status(snapshot: Dictionary) -> String:
	var actor_state := StringName(snapshot.get("actor_state", &"dormant"))
	if actor_state == &"phase_transition":
		return _t("PHASE SHIFT")
	if actor_state == &"staggered":
		return _t("STAGGERED · ATTACK")
	if actor_state == &"defeated":
		return _t("CROWN BROKEN")
	if actor_state in [&"dormant", &"cancelled"]:
		return _t("THE COURT SEALS")
	var pattern: Dictionary = snapshot.get("pattern", {})
	var pattern_id := StringName(pattern.get("pattern_id", &""))
	var pattern_state := StringName(pattern.get("state", &"idle"))
	if pattern_state == &"recovery":
		return _t("OPENING · ATTACK")
	if pattern_state == &"neutral":
		return _t("REPOSITION")
	if pattern_state == &"active":
		return _active_pattern_label(pattern_id)
	if pattern_state == &"startup":
		return _startup_pattern_label(pattern_id)
	return _t("WATCH THE CROWN")


func _startup_pattern_label(pattern_id: StringName) -> String:
	return _t(String({
		&"jump_slam": "SHADOW - MOVE",
		&"body_bump": "LANE LOCK - EVADE",
		&"poison_bands": "FIND SAFE FLOOR",
		&"small_slime_summon": "SPAWN MARKERS",
	}.get(pattern_id, "ATTACK INCOMING")))


func _active_pattern_label(pattern_id: StringName) -> String:
	return _t(String({
		&"jump_slam": "JUMP THE SHOCKWAVE",
		&"body_bump": "CLEAR THE LANE",
		&"poison_bands": "HOLD SAFE FLOOR",
	}.get(pattern_id, "DODGE")))


func _on_locale_changed(_locale: String) -> void:
	_refresh_all()
	if _stage_id == "safe_intermission":
		_show_objective(_t("Prepare, then continue"))
	elif _stage_id not in ["slime_court", "arsenal_trial"]:
		_show_objective(_t("Defeat enemies"))
	if boss_panel != null and boss_panel.visible:
		_refresh_boss_header()
		boss_status_label.text = _boss_status(_boss_snapshot)


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)


func _roman_phase(phase: int) -> String:
	return "II" if phase >= 2 else "I"
