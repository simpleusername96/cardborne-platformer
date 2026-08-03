class_name VehicleStageTransitionBanner
extends Control

## Non-modal stage handoff presentation. The run owns transition state and
## timing; this component owns only the two-line banner and reduced-motion fade.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")
const DISPLAY_SECONDS := 1.6

var _surface: PanelContainer
var _title: Label
var _status: Label
var _remaining := 0.0
var _reduced_motion := false
var _stage_number := 0
var _stage_title_key := ""


func _ready() -> void:
	name = "StageTransitionBanner"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	_surface = Factory.surface(Factory.SURFACE_TOAST)
	_surface.name = "TransitionSurface"
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 2)
	_surface.add_child(stack)
	_title = Factory.label("", 22, Art.TEXT_PRIMARY)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_title)
	_status = Factory.label("", 14, Art.TEXT_MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_status)
	visible = false
	set_process(false)


func show_stage(
	stage_number: int,
	stage_title_key: String,
	reduced_motion: bool
) -> void:
	_stage_number = stage_number
	_stage_title_key = stage_title_key
	refresh_localized_content()
	_reduced_motion = reduced_motion
	_remaining = DISPLAY_SECONDS
	modulate.a = 1.0
	visible = true
	set_process(true)


func refresh_localized_content() -> void:
	if not is_instance_valid(_title):
		return
	_title.text = (
		tr("STAGE_TRANSITION_TITLE")
		.replace("%d", str(_stage_number))
		.replace("%s", tr(_stage_title_key))
	)
	_status.text = tr("STAGE_TRANSITION_STATUS")


func hide_banner() -> void:
	_remaining = 0.0
	visible = false
	set_process(false)


func apply_viewport(viewport_size: Vector2) -> void:
	var width := minf(520.0, viewport_size.x - 48.0)
	size = Vector2(width, 76.0)
	position = Vector2((viewport_size.x - width) * 0.5, 126.0)


func debug_snapshot() -> Dictionary:
	return {
		"visible":visible,
		"remaining":_remaining,
		"title":_title.text if is_instance_valid(_title) else "",
		"status":_status.text if is_instance_valid(_status) else "",
		"mouse_filter":mouse_filter,
		"input_passthrough":_input_passthrough(),
		"size":size,
		"position":position,
		"surface_variation":(
			_surface.theme_type_variation
			if is_instance_valid(_surface)
			else &""
		),
		"shared_toast_surface":(
			is_instance_valid(_surface)
			and _surface.theme_type_variation == &"ToastSurface"
		),
		"mechanical_frame":{"layered_depth":false},
		"reduced_motion":_reduced_motion,
		"alpha":modulate.a,
		"title_variation":(
			_title.theme_type_variation
			if is_instance_valid(_title)
			else &""
		),
		"title_font_size":(
			_title.get_theme_font_size("font_size")
			if is_instance_valid(_title)
			else 0
		),
		"status_font_size":(
			_status.get_theme_font_size("font_size")
			if is_instance_valid(_status)
			else 0
		),
	}


func _input_passthrough() -> bool:
	for node in find_children("*", "Control", true, false):
		if (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
	return true


func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - maxf(0.0, delta))
	if _remaining <= 0.0:
		hide_banner()
		return
	if _reduced_motion:
		modulate.a = 1.0
	else:
		modulate.a = minf(1.0, minf(
			(DISPLAY_SECONDS - _remaining) * 6.0,
			_remaining * 4.0
		))
