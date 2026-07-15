class_name CenteredModalShell
extends Control

signal close_requested

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")

var content: VBoxContainer
var panel: PanelContainer

var _desired_size := Vector2(760.0, 600.0)
var _viewport_padding := 16.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.name = "ModalDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	panel = PanelContainer.new()
	panel.name = "ModalPanel"
	panel.clip_contents = true
	panel.add_theme_stylebox_override(
		"panel", Styles.panel_style(Color(Styles.SURFACE, 0.99), Styles.CYAN, 2)
	)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "ModalMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "ModalScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	content = VBoxContainer.new()
	content.name = "ModalContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)


func _ready() -> void:
	_layout_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func configure_size(desired_size: Vector2, viewport_padding: float = 16.0) -> void:
	_desired_size = desired_size
	_viewport_padding = viewport_padding
	if is_inside_tree():
		_layout_panel()


func panel_rect() -> Rect2:
	return panel.get_global_rect() if panel != null else Rect2()


func link_vertical_focus(controls: Array[Control]) -> void:
	var focusable: Array[Control] = []
	for control in controls:
		if control != null and control.visible and control.focus_mode != Control.FOCUS_NONE:
			focusable.append(control)
	if focusable.is_empty():
		return
	for index in focusable.size():
		var control := focusable[index]
		control.focus_neighbor_top = control.get_path_to(
			focusable[(index - 1 + focusable.size()) % focusable.size()]
		)
		control.focus_neighbor_bottom = control.get_path_to(
			focusable[(index + 1) % focusable.size()]
		)


func _layout_panel() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var maximum := Vector2(
		maxf(viewport_size.x - _viewport_padding * 2.0, 1.0),
		maxf(viewport_size.y - _viewport_padding * 2.0, 1.0)
	)
	var actual := Vector2(minf(_desired_size.x, maximum.x), minf(_desired_size.y, maximum.y))
	var origin := (viewport_size - actual) * 0.5
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = origin.x
	panel.offset_top = origin.y
	panel.offset_right = origin.x + actual.x
	panel.offset_bottom = origin.y + actual.y
