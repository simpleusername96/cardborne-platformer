class_name VehicleStageUI
extends CanvasLayer

## Runtime-built HUD and modal surfaces for the vehicle Stage 1 slice.
## The UI presents snapshots and emits intents; the stage remains the gameplay owner.

signal deployment_selected(primary_id: StringName)
signal upgrade_selected(upgrade_id: StringName)
signal resume_requested
signal restart_requested
signal garage_requested
signal replay_requested
signal primary_changed(primary_id: StringName)

const CANVAS := Color("#12171A")
const SURFACE := Color("#1C2428")
const RAISED := Color("#263136")
const CYAN := Color("#62A9B5")
const MOSS := Color("#6F8F62")
const AMBER := Color("#D4A33F")
const CORAL := Color("#D9654F")
const OFF_WHITE := Color("#F0F1E8")
const MUTED := Color("#A8B4AE")
const VIOLET := Color("#AA89CF")

class StageMinimap:
	extends Control

	var snapshot: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(176.0, 98.0)

	func set_snapshot(value: Dictionary) -> void:
		snapshot = value.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		var panel_rect := Rect2(Vector2.ZERO, size)
		draw_rect(panel_rect, Color("#0B1012"))
		var cols: int = int(snapshot.get("cols", 13))
		var rows: int = int(snapshot.get("rows", 6))
		var cell_size := Vector2(size.x / float(cols), size.y / float(rows))
		var visited: Array = snapshot.get("visited", [])
		for cell_variant in visited:
			var cell: Vector2i = cell_variant
			var rect := Rect2(Vector2(cell.x, cell.y) * cell_size, cell_size - Vector2.ONE)
			draw_rect(rect, Color("#263B3E"))
		for marker_variant in snapshot.get("markers", []):
			var marker: Dictionary = marker_variant
			if not bool(marker.get("discovered", false)):
				continue
			var world: Vector2 = marker.get("position", Vector2.ZERO)
			var world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
			var point := Vector2(world.x / world_size.x * size.x, world.y / world_size.y * size.y)
			var marker_color: Color = marker.get("color", Color.WHITE)
			var kind := String(marker.get("kind", "point"))
			if kind == "boss":
				draw_colored_polygon(PackedVector2Array([
					point + Vector2(0.0, -5.0),
					point + Vector2(5.0, 4.0),
					point + Vector2(-5.0, 4.0),
				]), marker_color)
			elif kind == "objective":
				draw_rect(Rect2(point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), marker_color)
			elif kind == "reward":
				draw_circle(point, 4.0, marker_color)
			else:
				draw_circle(point, 3.0, marker_color)
		var player: Vector2 = snapshot.get("player", Vector2.ZERO)
		var player_world_size: Vector2 = snapshot.get("world_size", Vector2(5200.0, 2200.0))
		var player_point := Vector2(player.x / player_world_size.x * size.x, player.y / player_world_size.y * size.y)
		draw_colored_polygon(PackedVector2Array([
			player_point + Vector2(0.0, -6.0),
			player_point + Vector2(5.0, 5.0),
			player_point + Vector2(-5.0, 5.0),
		]), Color("#F0F1E8"))


var _root: Control
var _hud: Control
var _health_bar: ProgressBar
var _health_value: Label
var _objective_label: Label
var _objective_detail: Label
var _boss_cluster: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_state: Label
var _target_cluster: VBoxContainer
var _target_name: Label
var _target_bar: ProgressBar
var _target_state: Label
var _primary_slot: Label
var _dash_slot: Label
var _passive_slot: Label
var _skill_slot: Label
var _buff_label: Label
var _minimap: StageMinimap
var _notification: Label
var _notification_timer := 0.0

var _dim: ColorRect
var _deployment_center: CenterContainer
var _upgrade_center: CenterContainer
var _pause_center: CenterContainer
var _result_center: CenterContainer
var _garage_center: CenterContainer
var _deployment_buttons: Array[Button] = []
var _upgrade_buttons: Array[Button] = []
var _pause_first_button: Button
var _result_first_button: Button
var _garage_first_button: Button
var _garage_primary_label: Label
var _garage_unlock_label: Label
var _garage_summary_label: Label
var _selected_primary := &"repeater"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_hud()
	_build_deployment()
	_build_upgrade()
	_build_pause()
	_build_result()
	_build_garage()
	hide_all_modals()
	_hud.visible = false


func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer = maxf(0.0, _notification_timer - delta)
		_notification.modulate.a = minf(1.0, _notification_timer * 3.0)
		if _notification_timer <= 0.0:
			_notification.visible = false


func _build_root() -> void:
	_root = Control.new()
	_root.name = "VehicleStageUIRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_dim = ColorRect.new()
	_dim.name = "ModalDim"
	_dim.color = Color(0.035, 0.055, 0.063, 0.84)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)

	_notification = Label.new()
	_notification.name = "Notification"
	_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notification.add_theme_font_size_override("font_size", 18)
	_notification.add_theme_color_override("font_color", OFF_WHITE)
	_notification.add_theme_color_override("font_shadow_color", CANVAS)
	_notification.add_theme_constant_override("shadow_offset_x", 2)
	_notification.add_theme_constant_override("shadow_offset_y", 2)
	_notification.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notification.position = Vector2(-260.0, 102.0)
	_notification.size = Vector2(520.0, 44.0)
	_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification.visible = false
	_root.add_child(_notification)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "GameplayHUD"
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_hud)

	var health_panel := _flat_panel()
	health_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	health_panel.position = Vector2(20.0, 18.0)
	health_panel.size = Vector2(280.0, 94.0)
	_hud.add_child(health_panel)
	var health_box := VBoxContainer.new()
	health_box.add_theme_constant_override("separation", 3)
	health_panel.add_child(health_box)
	var health_header := HBoxContainer.new()
	health_box.add_child(health_header)
	var hull_label := _label("HULL", 14, AMBER)
	hull_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_header.add_child(hull_label)
	_health_value = _label("120 / 120", 15, OFF_WHITE)
	health_header.add_child(_health_value)
	_health_bar = ProgressBar.new()
	_health_bar.theme_type_variation = &"HealthMeter"
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(248.0, 18.0)
	_health_bar.max_value = 120.0
	_health_bar.value = 120.0
	health_box.add_child(_health_bar)
	var hull_hint := _label("Movement keeps the hull alive.", 12, MUTED)
	health_box.add_child(hull_hint)

	var objective_panel := _flat_panel()
	objective_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_panel.position = Vector2(-310.0, 18.0)
	objective_panel.size = Vector2(620.0, 88.0)
	_hud.add_child(objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.alignment = BoxContainer.ALIGNMENT_CENTER
	objective_panel.add_child(objective_box)
	_objective_label = _label("DEPLOYMENT", 18, OFF_WHITE)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_box.add_child(_objective_label)
	_objective_detail = _label("Select a primary weapon.", 13, MUTED)
	_objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_box.add_child(_objective_detail)

	var minimap_panel := _flat_panel()
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.position = Vector2(-212.0, 18.0)
	minimap_panel.size = Vector2(192.0, 128.0)
	_hud.add_child(minimap_panel)
	var minimap_box := VBoxContainer.new()
	minimap_panel.add_child(minimap_box)
	var map_title := _label("SECTOR MAP", 12, AMBER)
	minimap_box.add_child(map_title)
	_minimap = StageMinimap.new()
	minimap_box.add_child(_minimap)

	_boss_cluster = VBoxContainer.new()
	_boss_cluster.name = "BossCluster"
	_boss_cluster.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_cluster.position = Vector2(-300.0, 116.0)
	_boss_cluster.size = Vector2(600.0, 64.0)
	_boss_cluster.add_theme_constant_override("separation", 1)
	_hud.add_child(_boss_cluster)
	_boss_name = _label("FOUNDRY COLOSSUS", 15, VIOLET)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_cluster.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.theme_type_variation = &"BossMeter"
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	_boss_bar.custom_minimum_size = Vector2(600.0, 15.0)
	_boss_cluster.add_child(_boss_bar)
	_boss_state = _label("READING THE ARENA", 12, OFF_WHITE)
	_boss_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_cluster.add_child(_boss_state)
	_boss_cluster.visible = false

	var target_panel := _flat_panel()
	target_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	target_panel.position = Vector2(-238.0, -76.0)
	target_panel.size = Vector2(218.0, 152.0)
	_hud.add_child(target_panel)
	_target_cluster = VBoxContainer.new()
	target_panel.add_child(_target_cluster)
	var target_header := _label("AIMED TARGET", 12, AMBER)
	_target_cluster.add_child(target_header)
	_target_name = _label("—", 15, OFF_WHITE)
	_target_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_name)
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.max_value = 1.0
	_target_bar.value = 1.0
	_target_bar.custom_minimum_size = Vector2(184.0, 12.0)
	_target_cluster.add_child(_target_bar)
	_target_state = _label("", 12, MUTED)
	_target_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_cluster.add_child(_target_state)
	target_panel.visible = false
	_target_cluster.set_meta("panel", target_panel)

	var dock_panel := _flat_panel()
	dock_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock_panel.position = Vector2(-390.0, -100.0)
	dock_panel.size = Vector2(780.0, 80.0)
	_hud.add_child(dock_panel)
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 4)
	dock_panel.add_child(dock)
	_primary_slot = _action_slot(dock, "LMB / SHIFT\nPRIMARY", CYAN)
	_dash_slot = _action_slot(dock, "SPACE\nDASH", AMBER)
	_passive_slot = _action_slot(dock, "AUTO\nSEEKER", MOSS)
	_skill_slot = _action_slot(dock, "Z\nEMP NOVA", VIOLET)

	_buff_label = _label("", 13, OFF_WHITE)
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buff_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_label.position = Vector2(-390.0, -132.0)
	_buff_label.size = Vector2(780.0, 28.0)
	_hud.add_child(_buff_label)


func _build_deployment() -> void:
	_deployment_center = CenterContainer.new()
	_deployment_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_deployment_center)
	var panel := _modal_panel(Vector2(820.0, 500.0))
	_deployment_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var kicker := _label("FLOODED WORKS // STAGE 1", 14, AMBER)
	box.add_child(kicker)
	var title := _label("DEPLOY THE SALVAGE SKIFF", 30, OFF_WHITE)
	box.add_child(title)
	var body := _label(
		"Move with arrows or WASD. Aim with the mouse. Hold left mouse or Left Shift to fire. " +
		"Space dashes through pressure; Z releases an EMP Nova. The seeker launcher fires automatically at visible targets.",
		16,
		MUTED
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 72.0
	box.add_child(body)
	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 12)
	choice_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(choice_row)
	var repeater := _choice_button(
		"RAPID REPEATER\n\nLong range • 9 rounds/sec\nReliable installation pressure\n\nLaunch with this loadout",
		Vector2(365.0, 230.0)
	)
	repeater.pressed.connect(func() -> void: deployment_selected.emit(&"repeater"))
	choice_row.add_child(repeater)
	_deployment_buttons.append(repeater)
	var scatter := _choice_button(
		"SCATTER ARRAY\n\nShort range • 3 projectiles\nStrong while circling close targets\n\nLaunch with this loadout",
		Vector2(365.0, 230.0)
	)
	scatter.pressed.connect(func() -> void: deployment_selected.emit(&"scatter"))
	choice_row.add_child(scatter)
	_deployment_buttons.append(scatter)
	var footer := _label("Ordinary threats can be bypassed. Only the final arena locks behind you.", 13, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)


func _build_upgrade() -> void:
	_upgrade_center = CenterContainer.new()
	_upgrade_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_upgrade_center)
	var panel := _modal_panel(Vector2(900.0, 470.0))
	_upgrade_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var kicker := _label("SALVAGE CACHE", 14, AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("CHOOSE ONE LIVE CIRCUIT", 27, OFF_WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var detail := _label("Combat is safely suspended. The selected behavior applies immediately and once.", 14, MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(detail)
	var row := HBoxContainer.new()
	row.name = "UpgradeButtons"
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for index in 3:
		var button := _choice_button("CARD %d" % (index + 1), Vector2(272.0, 290.0))
		button.name = "UpgradeCard%d" % (index + 1)
		button.pressed.connect(_on_upgrade_button_pressed.bind(button))
		row.add_child(button)
		_upgrade_buttons.append(button)


func _build_pause() -> void:
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_pause_center)
	var panel := _modal_panel(Vector2(480.0, 430.0))
	_pause_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _label("PAUSED", 30, OFF_WHITE)
	box.add_child(title)
	var resume := _command_button("RESUME", &"PrimaryButton")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	_pause_first_button = resume
	var restart := _command_button("RESTART STAGE 1", &"SecondaryButton")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)
	box.add_child(_label("MASTER", 13, MUTED))
	var master := HSlider.new()
	master.name = "MasterVolume"
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.value_changed.connect(_on_master_volume_changed)
	box.add_child(master)
	box.add_child(_label("SFX", 13, MUTED))
	var sfx := HSlider.new()
	sfx.name = "SFXVolume"
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(sfx)
	var garage := _command_button("ABORT TO GARAGE", &"SecondaryButton")
	garage.pressed.connect(func() -> void: garage_requested.emit())
	box.add_child(garage)


func _build_result() -> void:
	_result_center = CenterContainer.new()
	_result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_result_center)
	var panel := _modal_panel(Vector2(720.0, 510.0))
	_result_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var kicker := _label("STAGE 1 COMPLETE", 14, AMBER)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("THE RELAY IS QUIET", 34, OFF_WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var summary := _label("", 16, MUTED)
	summary.name = "RunSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.custom_minimum_size.y = 190.0
	box.add_child(summary)
	box.set_meta("summary", summary)
	var garage := _command_button("REVIEW GARAGE & MODULE", &"PrimaryButton")
	garage.pressed.connect(func() -> void: garage_requested.emit())
	box.add_child(garage)
	_result_first_button = garage
	var replay := _command_button("REPLAY STAGE 1", &"SecondaryButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	box.add_child(replay)


func _build_garage() -> void:
	_garage_center = CenterContainer.new()
	_garage_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_garage_center)
	var panel := _modal_panel(Vector2(820.0, 500.0))
	_garage_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var kicker := _label("COMPACT GARAGE", 14, AMBER)
	box.add_child(kicker)
	var title := _label("SALVAGE SKIFF LOADOUT", 30, OFF_WHITE)
	box.add_child(title)
	_garage_summary_label = _label("Hull reset to full. Repairs never block another deployment.", 15, MUTED)
	box.add_child(_garage_summary_label)
	var loadout_panel := _flat_panel()
	loadout_panel.custom_minimum_size = Vector2(760.0, 150.0)
	box.add_child(loadout_panel)
	var loadout_box := VBoxContainer.new()
	loadout_panel.add_child(loadout_box)
	_garage_primary_label = _label("PRIMARY // RAPID REPEATER", 18, CYAN)
	loadout_box.add_child(_garage_primary_label)
	loadout_box.add_child(_label("PASSIVE // AUTO SEEKER LAUNCHER", 16, MOSS))
	loadout_box.add_child(_label("Z SKILL // EMP NOVA", 16, VIOLET))
	_garage_unlock_label = _label("MODULE // Colossus Relay locked", 15, MUTED)
	loadout_box.add_child(_garage_unlock_label)
	var toggle := _command_button("TOGGLE PRIMARY WEAPON", &"SecondaryButton")
	toggle.pressed.connect(_on_toggle_primary)
	box.add_child(toggle)
	var replay := _command_button("LAUNCH STAGE 1", &"PrimaryButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	box.add_child(replay)
	_garage_first_button = replay
	var settings_row := HBoxContainer.new()
	settings_row.add_theme_constant_override("separation", 12)
	box.add_child(settings_row)
	var master_label := _label("MASTER", 13, MUTED)
	master_label.custom_minimum_size.x = 92.0
	settings_row.add_child(master_label)
	var master := HSlider.new()
	master.min_value = 0.0
	master.max_value = 1.0
	master.step = 0.05
	master.value = _settings_value("master_volume", 1.0)
	master.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master.value_changed.connect(_on_master_volume_changed)
	settings_row.add_child(master)
	var sfx_label := _label("SFX", 13, MUTED)
	sfx_label.custom_minimum_size.x = 50.0
	settings_row.add_child(sfx_label)
	var sfx := HSlider.new()
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.05
	sfx.value = _settings_value("sfx_volume", 1.0)
	sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx.value_changed.connect(_on_sfx_volume_changed)
	settings_row.add_child(sfx)


func update_hud(snapshot: Dictionary) -> void:
	if not is_instance_valid(_hud):
		return
	_health_bar.max_value = maxf(1.0, float(snapshot.get("max_health", 1.0)))
	_health_bar.value = float(snapshot.get("health", 0.0))
	_health_value.text = "%d / %d" % [
		roundi(float(snapshot.get("health", 0.0))),
		roundi(float(snapshot.get("max_health", 0.0))),
	]
	_objective_label.text = String(snapshot.get("objective", ""))
	_objective_detail.text = String(snapshot.get("objective_detail", ""))

	var primary_state := String(snapshot.get("primary_state", "LIVE"))
	_primary_slot.text = "LMB / SHIFT\n%s\n%s" % [String(snapshot.get("primary_name", "PRIMARY")), primary_state]
	_dash_slot.text = "SPACE\nDASH\n%s" % String(snapshot.get("dash_state", "READY"))
	_passive_slot.text = "AUTO\nSEEKER\n%s" % String(snapshot.get("passive_state", "READY"))
	_skill_slot.text = "Z\nEMP NOVA\n%s" % String(snapshot.get("skill_state", "READY"))
	_buff_label.text = String(snapshot.get("buff_text", ""))

	var boss: Dictionary = snapshot.get("boss", {})
	_boss_cluster.visible = bool(boss.get("visible", false))
	_notification.position.y = 188.0 if _boss_cluster.visible else 110.0
	if _boss_cluster.visible:
		_boss_name.text = String(boss.get("name", "BOSS"))
		_boss_bar.max_value = maxf(1.0, float(boss.get("max_health", 1.0)))
		_boss_bar.value = float(boss.get("health", 0.0))
		_boss_state.text = String(boss.get("state", ""))

	var target: Dictionary = snapshot.get("target", {})
	var target_panel: Control = _target_cluster.get_meta("panel")
	target_panel.visible = bool(target.get("visible", false))
	if target_panel.visible:
		_target_name.text = String(target.get("name", "TARGET"))
		_target_bar.max_value = maxf(1.0, float(target.get("max_health", 1.0)))
		_target_bar.value = float(target.get("health", 0.0))
		_target_state.text = String(target.get("state", ""))

	_minimap.set_snapshot(snapshot.get("minimap", {}))


func show_deployment(selected_primary: StringName = &"repeater") -> void:
	hide_all_modals()
	_selected_primary = selected_primary
	_dim.visible = true
	_deployment_center.visible = true
	_hud.visible = false
	for button in _deployment_buttons:
		button.disabled = false
	if not _deployment_buttons.is_empty():
		var index := 0 if selected_primary == &"repeater" else 1
		_deployment_buttons[index].grab_focus()


func show_upgrade(cards: Array[Dictionary]) -> void:
	hide_all_modals()
	_dim.visible = true
	_upgrade_center.visible = true
	_hud.visible = true
	for index in _upgrade_buttons.size():
		var button := _upgrade_buttons[index]
		if index >= cards.size():
			button.visible = false
			continue
		var card: Dictionary = cards[index]
		button.visible = true
		button.disabled = false
		button.set_meta("upgrade_id", StringName(card["id"]))
		button.text = "%s\n\n%s\n\n%s\n\n[%d]" % [
			String(card["family"]),
			String(card["title"]),
			String(card["description"]),
			index + 1,
		]
	if not _upgrade_buttons.is_empty():
		_upgrade_buttons[0].grab_focus()


func show_pause() -> void:
	hide_all_modals()
	_dim.visible = true
	_pause_center.visible = true
	_hud.visible = true
	_pause_first_button.grab_focus()


func show_result(summary: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_result_center.visible = true
	_hud.visible = false
	var summary_label: Label = _result_center.get_child(0).get_child(0).get_meta("summary")
	summary_label.text = (
		"Clear time: %s\nHull integrity: %d%%\nUpgrade: %s\nOptional Warden: %s\n"
		+ "Primary hits: %d  •  Dash uses: %d  •  Priority installations destroyed: %d\n\n"
		+ "Persistent reward acquired: COLOSSUS RELAY MODULE"
	) % [
		String(summary.get("time", "0:00")),
		roundi(float(summary.get("health_ratio", 0.0)) * 100.0),
		String(summary.get("upgrade", "None")),
		"DEFEATED" if bool(summary.get("field_boss_defeated", false)) else "BYPASSED",
		int(summary.get("primary_hits", 0)),
		int(summary.get("dash_uses", 0)),
		int(summary.get("installations", 0)),
	]
	_result_first_button.grab_focus()


func show_garage(data: Dictionary) -> void:
	hide_all_modals()
	_dim.visible = true
	_garage_center.visible = true
	_hud.visible = false
	_selected_primary = StringName(data.get("selected_primary", "repeater"))
	_refresh_garage_primary()
	var clear_count := int(data.get("clear_count", 0))
	var field_module := bool(data.get("field_module_unlocked", false))
	var relay_module := bool(data.get("relay_module_unlocked", false))
	_garage_summary_label.text = "Stage clears: %d. Hull reset to full; repairs never block another deployment." % clear_count
	var unlocks: Array[String] = []
	if relay_module:
		unlocks.append("Colossus Relay: EMP starts each run 20% charged")
	if field_module:
		unlocks.append("Dredge Capacitor: seeker cadence improved")
	if unlocks.is_empty():
		_garage_unlock_label.text = "MODULE // No persistent module unlocked yet"
		_garage_unlock_label.add_theme_color_override("font_color", MUTED)
	else:
		_garage_unlock_label.text = "MODULE // " + "  •  ".join(unlocks)
		_garage_unlock_label.add_theme_color_override("font_color", AMBER)
	_garage_first_button.grab_focus()


func show_gameplay() -> void:
	hide_all_modals()
	_hud.visible = true


func hide_all_modals() -> void:
	if not is_instance_valid(_dim):
		return
	_dim.visible = false
	_deployment_center.visible = false
	_upgrade_center.visible = false
	_pause_center.visible = false
	_result_center.visible = false
	_garage_center.visible = false


func notify(message: String, duration: float = 2.4, color: Color = OFF_WHITE) -> void:
	_notification.text = message
	_notification.add_theme_color_override("font_color", color)
	_notification.modulate.a = 1.0
	_notification.visible = true
	_notification_timer = duration


func set_hud_visible(visible: bool) -> void:
	_hud.visible = visible


func is_modal_visible() -> bool:
	return _dim.visible


func debug_layout_minimums() -> Dictionary:
	return {
		"deployment": Vector2(820.0, 500.0),
		"upgrade": Vector2(900.0, 470.0),
		"pause": Vector2(480.0, 430.0),
		"result": Vector2(720.0, 510.0),
		"garage": Vector2(820.0, 500.0),
	}


func _on_upgrade_button_pressed(button: Button) -> void:
	if button.disabled:
		return
	for other in _upgrade_buttons:
		other.disabled = true
	upgrade_selected.emit(StringName(button.get_meta("upgrade_id", "")))


func _on_toggle_primary() -> void:
	_selected_primary = &"scatter" if _selected_primary == &"repeater" else &"repeater"
	_refresh_garage_primary()
	primary_changed.emit(_selected_primary)


func _refresh_garage_primary() -> void:
	if _selected_primary == &"scatter":
		_garage_primary_label.text = "PRIMARY // SCATTER ARRAY"
	else:
		_garage_primary_label.text = "PRIMARY // RAPID REPEATER"


func _on_master_volume_changed(value: float) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_method("set_master_volume"):
		settings.call("set_master_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings != null and settings.has_method("set_sfx_volume"):
		settings.call("set_sfx_volume", value)


func _settings_value(property_name: StringName, fallback: float) -> float:
	var settings := get_node_or_null("/root/SettingsStore")
	if settings == null:
		return fallback
	var value: Variant = settings.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback


func _flat_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"FlatPanel"
	panel.add_theme_constant_override("margin_left", 14)
	panel.add_theme_constant_override("margin_top", 10)
	panel.add_theme_constant_override("margin_right", 14)
	panel.add_theme_constant_override("margin_bottom", 10)
	return panel


func _modal_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ModalSurface"
	panel.custom_minimum_size = minimum_size
	panel.add_theme_constant_override("margin_left", 24)
	panel.add_theme_constant_override("margin_top", 22)
	panel.add_theme_constant_override("margin_right", 24)
	panel.add_theme_constant_override("margin_bottom", 22)
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _action_slot(parent: HBoxContainer, text: String, color: Color) -> Label:
	var panel := _flat_panel()
	panel.custom_minimum_size = Vector2(184.0, 58.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var label := _label(text, 13, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return label


func _choice_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ChoiceButton"
	button.text = text
	button.custom_minimum_size = minimum_size
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	return button


func _command_button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.theme_type_variation = variation
	button.text = text
	button.custom_minimum_size.y = 44.0
	button.focus_mode = Control.FOCUS_ALL
	return button
