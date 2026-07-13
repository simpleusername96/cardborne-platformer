extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Glyph = preload("res://scripts/ui/production/components/HUDGlyph.gd")
const ClassState = preload("res://scripts/ui/production/components/HUDClassState.gd")
const ActionSlotScene = preload("res://scenes/ui/production/components/HUDActionSlot.tscn")

const OBJECTIVE_EXPANDED_SECONDS := 4.0
const ACTION_SLOT_MINIMUM_SIZE := Vector2(92.0, 104.0)
const ACTION_SLOT_DEFINITIONS: Array[Dictionary] = [
	{"slot_role": &"basic", "input_action": &"attack", "fallback": "F", "fallback_label": "Basic"},
	{"slot_role": &"heavy", "input_action": &"heavy_attack", "fallback": "G", "fallback_label": "Heavy"},
	{"slot_role": &"skill_1", "input_action": &"skill_1", "fallback": "Q", "fallback_label": "Skill 1"},
	{"slot_role": &"skill_2", "input_action": &"skill_2", "fallback": "R", "fallback_label": "Skill 2"},
	{"slot_role": &"skill_3", "input_action": &"skill_3", "fallback": "V", "fallback_label": "Skill 3"},
	{"slot_role": &"consumable", "input_action": &"use_consumable", "fallback": "H", "fallback_label": "Consumable"},
]

var health_panel: PanelContainer
var portrait_frame: PanelContainer
var portrait_glyph: HUDGlyph
var profile_label: Label
var health_value_label: Label
var health_bar: ProgressBar
var level_xp_label: Label
var class_state: HUDClassState

var resource_panel: PanelContainer
var resource_value_labels: Dictionary = {}

var objective_container: Control
var objective_title_label: Label
var objective_detail_label: Label
var objective_timer: Timer

var action_bar: PanelContainer
var action_row: HBoxContainer
var action_slots: Array[Control] = []

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
	_build_ui()
	SignalBus.player_health_changed.connect(_on_health_changed)
	SignalBus.run_state_changed.connect(_on_run_state_changed)
	SignalBus.stage_started.connect(_on_stage_started)
	SignalBus.combat_state_changed.connect(_on_combat_state_changed)
	SignalBus.encounter_state_changed.connect(_on_encounter_state_changed)
	SignalBus.input_bindings_changed.connect(_on_input_bindings_changed)
	SignalBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	var initial_snapshot: Variant = RunState.get_run_snapshot()
	if initial_snapshot != null and initial_snapshot.has_method("to_dictionary"):
		_on_run_state_changed(initial_snapshot.call("to_dictionary"))
	else:
		_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and action_bar != null:
		_layout_responsive()


func get_layout_snapshot() -> Dictionary:
	var slot_snapshots: Array[Dictionary] = []
	for slot in action_slots:
		if slot.has_method("get_display_snapshot"):
			slot_snapshots.append(slot.call("get_display_snapshot"))
	return {
		"viewport": size,
		"health_rect": health_panel.get_rect() if health_panel != null else Rect2(),
		"resources_rect": resource_panel.get_rect() if resource_panel != null else Rect2(),
		"objective_rect": objective_container.get_rect() if objective_container != null else Rect2(),
		"boss_rect": boss_panel.get_rect() if boss_panel != null else Rect2(),
		"action_bar_rect": action_bar.get_rect() if action_bar != null else Rect2(),
		"context_lane_rect": context_lane.get_rect() if context_lane != null else Rect2(),
		"prompt_visible": prompt_panel.visible if prompt_panel != null else false,
		"receipt_active": _receipt_active,
		"slots": slot_snapshots,
		"class_state": class_state.get_display_snapshot() if class_state != null else {},
	}


func _build_ui() -> void:
	_build_health_cluster()
	_build_resource_strip()
	_build_objective()
	_build_boss_panel()
	_build_action_bar()
	_build_context_lane()
	_layout_responsive()


func _build_health_cluster() -> void:
	health_panel = _hud_panel(Color(Styles.SURFACE, 0.95), Styles.OUTLINE)
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
	Styles.configure_label(profile_label, 16, Styles.TEXT)
	heading.add_child(profile_label)
	health_value_label = Label.new()
	health_value_label.name = "HealthValue"
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styles.configure_label(health_value_label, 16, Styles.TEXT)
	heading.add_child(health_value_label)

	health_bar = ProgressBar.new()
	health_bar.name = "PlayerHealth"
	health_bar.custom_minimum_size = Vector2(0.0, 12.0)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override(
		"background", Styles.panel_style(Color("101518"), Color("3e4a4f"), 1)
	)
	health_bar.add_theme_stylebox_override(
		"fill", Styles.panel_style(Styles.HEALTH, Styles.HEALTH, 1)
	)
	details.add_child(health_bar)

	level_xp_label = Label.new()
	level_xp_label.name = "LevelXP"
	Styles.configure_label(level_xp_label, 12, Styles.TEXT_MUTED)
	details.add_child(level_xp_label)

	class_state = ClassState.new()
	class_state.name = "ClassState"
	class_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(class_state)


func _build_resource_strip() -> void:
	resource_panel = _hud_panel(Color(Styles.SURFACE, 0.94), Styles.OUTLINE)
	resource_panel.name = "ResourceStrip"
	resource_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	add_child(resource_panel)
	var margin := _margin_container(8, 7, 8, 6)
	resource_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	margin.add_child(row)
	var resources: Array[Dictionary] = [
		{"id": &"coin", "label": "COIN", "tone": Styles.AMBER},
		{"id": &"rusted_scrap", "label": "SCRAP", "tone": Styles.SCRAP},
		{"id": &"sky_thread", "label": "THREAD", "tone": Styles.THREAD},
		{"id": &"slime_residue", "label": "RESID", "tone": Styles.RESIDUE},
		{"id": &"boss_core", "label": "CORE", "tone": Styles.BOSS_CORE},
	]
	for definition in resources:
		row.add_child(_build_resource_item(definition))


func _build_resource_item(definition: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(52.0, 44.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	var value_row := HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 2)
	column.add_child(value_row)
	var glyph := Glyph.new()
	glyph.custom_minimum_size = Vector2(17.0, 17.0)
	glyph.configure(StringName(definition["id"]), definition["tone"] as Color)
	value_row.add_child(glyph)
	var value_label := Label.new()
	value_label.name = "%sValue" % String(definition["id"]).to_pascal_case()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(24.0, 19.0)
	Styles.configure_label(value_label, 13, Styles.TEXT)
	value_row.add_child(value_label)
	resource_value_labels[String(definition["id"])] = value_label
	var id_label := Label.new()
	id_label.text = String(definition["label"])
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styles.configure_label(id_label, 10, Styles.TEXT_MUTED)
	column.add_child(id_label)
	return column


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
	Styles.configure_label(objective_title_label, 16, Styles.TEXT)
	column.add_child(objective_title_label)
	objective_detail_label = Label.new()
	objective_detail_label.name = "ObjectiveDetail"
	objective_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(objective_detail_label, 13, Styles.TEXT_MUTED)
	column.add_child(objective_detail_label)
	objective_timer = Timer.new()
	objective_timer.one_shot = true
	objective_timer.wait_time = OBJECTIVE_EXPANDED_SECONDS
	objective_timer.timeout.connect(_collapse_objective)
	add_child(objective_timer)
	_show_objective("Defeat enemies")


func _build_action_bar() -> void:
	action_bar = _hud_panel(Color(Styles.SURFACE, 0.97), Styles.OUTLINE)
	action_bar.name = "ActionBar"
	action_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	add_child(action_bar)
	var margin := _margin_container(8, 8, 8, 8)
	action_bar.add_child(margin)
	action_row = HBoxContainer.new()
	action_row.name = "ActionSlots"
	action_row.add_theme_constant_override("separation", 5)
	margin.add_child(action_row)
	for definition in ACTION_SLOT_DEFINITIONS:
		var slot := ActionSlotScene.instantiate() as Control
		slot.name = "Action_%s" % String(definition["slot_role"])
		action_row.add_child(slot)
		action_slots.append(slot)


func _build_context_lane() -> void:
	context_lane = Control.new()
	context_lane.name = "ContextLane"
	context_lane.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	context_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(context_lane)
	prompt_panel = _hud_panel(Color(Styles.SURFACE_RAISED, 0.97), Styles.AMBER)
	prompt_panel.name = "InteractionPrompt"
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
	badge.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color("11171a"), Styles.AMBER, 1)
	)
	row.add_child(badge)
	prompt_binding_label = Label.new()
	prompt_binding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_binding_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styles.configure_label(prompt_binding_label, 13, Styles.TEXT)
	badge.add_child(prompt_binding_label)
	prompt_label = Label.new()
	prompt_label.name = "PromptText"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styles.configure_label(prompt_label, 14, Styles.TEXT)
	row.add_child(prompt_label)

	reward_receipt = RewardReceiptPresenter.new()
	reward_receipt.name = "RewardReceiptPresenter"
	reward_receipt.set_embedded(true)
	reward_receipt.presentation_state_changed.connect(_on_receipt_state_changed)
	context_lane.add_child(reward_receipt)


func _build_boss_panel() -> void:
	boss_panel = _hud_panel(Color("20292d"), Styles.AMBER)
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
	Styles.configure_label(boss_name_label, 14, Styles.TEXT)
	heading.add_child(boss_name_label)
	boss_status_label = Label.new()
	boss_status_label.name = "BossStatus"
	boss_status_label.custom_minimum_size = Vector2(100.0, 0.0)
	boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(boss_status_label, 13, Styles.AMBER)
	heading.add_child(boss_status_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealth"
	boss_health_bar.custom_minimum_size = Vector2(0.0, 13.0)
	boss_health_bar.show_percentage = false
	boss_health_bar.add_theme_stylebox_override(
		"background", Styles.panel_style(Color("11171a"), Color("414c51"), 1)
	)
	boss_health_bar.add_theme_stylebox_override(
		"fill", Styles.panel_style(Styles.CORAL, Styles.HEALTH_LOW, 1)
	)
	column.add_child(boss_health_bar)
	boss_stagger_bar = ProgressBar.new()
	boss_stagger_bar.name = "BossStagger"
	boss_stagger_bar.custom_minimum_size = Vector2(0.0, 4.0)
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
	panel.add_theme_stylebox_override("panel", Styles.panel_style(background, border))
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
	health_panel.offset_right = 312.0
	health_panel.offset_bottom = 112.0
	resource_panel.offset_left = -306.0
	resource_panel.offset_top = 14.0
	resource_panel.offset_right = -16.0
	resource_panel.offset_bottom = 78.0
	var objective_width := 280.0 if compact else 340.0
	objective_container.offset_left = -objective_width * 0.5
	objective_container.offset_top = 17.0
	objective_container.offset_right = objective_width * 0.5
	objective_container.offset_bottom = 70.0
	var boss_width := 324.0 if compact else 440.0
	boss_panel.offset_left = -boss_width * 0.5
	boss_panel.offset_top = 14.0
	boss_panel.offset_right = boss_width * 0.5
	boss_panel.offset_bottom = 82.0

	var slot_size := ACTION_SLOT_MINIMUM_SIZE
	for slot in action_slots:
		slot.custom_minimum_size = slot_size
	var separation := float(action_row.get_theme_constant("separation"))
	var bar_width := slot_size.x * float(action_slots.size()) + separation * float(action_slots.size() - 1) + 16.0
	var bar_height := slot_size.y + 16.0
	action_bar.offset_left = -bar_width * 0.5
	action_bar.offset_top = -(bar_height + 14.0)
	action_bar.offset_right = bar_width * 0.5
	action_bar.offset_bottom = -14.0

	var lane_width := minf(560.0, maxf(size.x - 32.0, 320.0))
	var lane_height := 58.0
	var lane_bottom := action_bar.offset_top - 10.0
	context_lane.offset_left = -lane_width * 0.5
	context_lane.offset_top = lane_bottom - lane_height
	context_lane.offset_right = lane_width * 0.5
	context_lane.offset_bottom = lane_bottom
	_refresh_action_slots()
	_refresh_boss_header()


func _refresh_all() -> void:
	_refresh_health_cluster()
	_refresh_resources()
	_refresh_action_slots()
	_refresh_context_lane()


func _on_health_changed(current_health: int, max_health: int) -> void:
	_run_snapshot["health"] = current_health
	_run_snapshot["max_health"] = max_health
	_refresh_health_cluster()


func _on_run_state_changed(snapshot: Dictionary) -> void:
	_run_snapshot = snapshot.duplicate(true)
	_refresh_health_cluster()
	_refresh_resources()
	_refresh_action_slots()


func _refresh_health_cluster() -> void:
	if health_bar == null:
		return
	var profile_id := StringName(_run_snapshot.get("profile_id", "warrior"))
	if profile_id == &"":
		profile_id = &"warrior"
	var current_health := maxi(int(_run_snapshot.get("health", 0)), 0)
	var max_health := maxi(int(_run_snapshot.get("max_health", 1)), 1)
	var accent := Styles.class_accent(profile_id)
	profile_label.text = String(profile_id).replace("_", " ").to_upper()
	health_value_label.text = "%d / %d" % [current_health, max_health]
	health_bar.max_value = float(max_health)
	health_bar.value = float(current_health)
	var low_health := float(current_health) / float(max_health) <= 0.3
	var health_tone := Styles.HEALTH_LOW if low_health else Styles.HEALTH
	health_bar.add_theme_stylebox_override(
		"fill", Styles.panel_style(health_tone, health_tone, 1)
	)
	level_xp_label.text = "LV %d   |   %d XP" % [
		maxi(int(_run_snapshot.get("level", 1)), 1),
		maxi(int(_run_snapshot.get("xp", 0)), 0),
	]
	portrait_frame.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color("151c1f"), accent, 2)
	)
	portrait_glyph.configure(profile_id, accent)
	class_state.configure(profile_id, _combat_state)


func _refresh_resources() -> void:
	if resource_value_labels.is_empty():
		return
	var materials_value: Variant = _run_snapshot.get("materials", {})
	var materials: Dictionary = materials_value if materials_value is Dictionary else {}
	resource_value_labels["coin"].text = str(maxi(int(_run_snapshot.get("coins", 0)), 0))
	for material_id in ["rusted_scrap", "sky_thread", "slime_residue", "boss_core"]:
		resource_value_labels[material_id].text = str(maxi(int(materials.get(material_id, 0)), 0))


func _on_combat_state_changed(state: Dictionary) -> void:
	_combat_state = state.duplicate(true)
	_refresh_action_slots()
	_refresh_health_cluster()


func _refresh_action_slots() -> void:
	if action_slots.is_empty():
		return
	# Availability and timing mirror snapshots; presentation never predicts combat legality.
	var actions_by_input: Dictionary = {}
	for action_value in _combat_state.get("actions", []):
		if not action_value is Dictionary:
			continue
		var action := action_value as Dictionary
		actions_by_input[String(action.get("input_action", ""))] = action
	var current_attack_id := String(_combat_state.get("current_attack_id", ""))
	var global_charge := clampf(float(_combat_state.get("charge_fraction", 0.0)), 0.0, 1.0)
	for index in ACTION_SLOT_DEFINITIONS.size():
		var definition := ACTION_SLOT_DEFINITIONS[index]
		var role := StringName(definition["slot_role"])
		var input_action := StringName(definition["input_action"])
		var view_model := {
			"slot_role": role,
			"input": Game.get_action_binding_text(String(input_action), String(definition["fallback"])),
			"label": String(definition["fallback_label"]),
			"available": false,
			"active": false,
			"cooldown": 0.0,
			"charge_fraction": 0.0,
			"charges": -1,
		}
		if role == &"consumable":
			var consumable_id := String(_run_snapshot.get("consumable_id", ""))
			var charges := maxi(int(_run_snapshot.get("consumable_charges", 0)), 0)
			var consumable_label := (
				consumable_id.replace("_", " ").capitalize()
				if not consumable_id.is_empty()
				else "Consumable"
			)
			view_model["label"] = _compact_action_label(consumable_label)
			view_model["available"] = not consumable_id.is_empty() and charges > 0
			view_model["charges"] = charges
		else:
			var action_value: Variant = actions_by_input.get(String(input_action), null)
			if action_value is Dictionary:
				var action := action_value as Dictionary
				var action_id := String(action.get("id", ""))
				view_model["label"] = _compact_action_label(
					String(action.get("label", definition["fallback_label"]))
				)
				view_model["available"] = not action_id.is_empty()
				view_model["active"] = not action_id.is_empty() and action_id == current_attack_id
				view_model["cooldown"] = maxf(float(action.get("cooldown", 0.0)), 0.0)
				if bool(view_model["active"]) and global_charge > 0.0:
					view_model["charge_fraction"] = global_charge
		action_slots[index].call("configure", view_model)


func _compact_action_label(label: String) -> String:
	if not _compact_layout:
		return label
	return {
		"Guard Breaker": "Breaker",
		"Ground Splitter": "Splitter",
		"Shadow Lunge": "Lunge",
		"Small Potion": "Potion",
		"Dash Tonic": "Tonic",
		"Salvage Kit": "Salvage",
	}.get(label, label)


func _on_stage_started(stage_id: String, stage_display_name: String) -> void:
	_stage_id = stage_id
	_stage_display_name = stage_display_name
	if stage_id == "slime_court":
		objective_container.visible = false
		boss_panel.visible = true
		_show_boss_intro_state()
		call_deferred("_bind_boss")
	else:
		boss_panel.visible = false
		objective_container.visible = true
		_show_objective("Defeat enemies")


func _on_encounter_state_changed(state: Dictionary) -> void:
	if _stage_id == "slime_court":
		return
	var remaining := int(state.get("remaining", 0))
	_show_objective(
		"Defeat %d remaining" % remaining if remaining > 0 else "Enter the gate"
	)


func _show_objective(detail: String) -> void:
	if objective_title_label == null:
		return
	objective_title_label.text = _stage_display_name.to_upper()
	objective_detail_label.text = detail
	objective_detail_label.visible = true
	if objective_timer != null:
		objective_timer.start()


func _collapse_objective() -> void:
	if objective_detail_label != null:
		objective_detail_label.visible = false


func _on_input_bindings_changed() -> void:
	_refresh_action_slots()
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
	prompt_label.text = _interaction_prompt_text


func _show_boss_intro_state() -> void:
	_boss_snapshot = {
		"actor_state": &"dormant",
		"health": 80,
		"max_health": 80,
		"phase": 1,
	}
	_refresh_boss_header()
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
		boss_name_label.text = "SLIME KING  %d/%d  P%d" % [health, max_health, phase]
	else:
		boss_name_label.text = "SLIME KING   %d / %d   PHASE %s" % [
			health,
			max_health,
			_roman_phase(phase),
		]


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
