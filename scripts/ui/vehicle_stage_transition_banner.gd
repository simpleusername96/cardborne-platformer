class_name VehicleStageTransitionBanner
extends PanelContainer

## Non-modal stage handoff presentation. The run owns transition state and
## timing; this component owns only the two-line banner and reduced-motion fade.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const DISPLAY_SECONDS := 1.6

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
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(Art.COBALT_DEEP, 0.94)
	panel.border_color = Art.MUSTARD
	panel.set_border_width_all(2)
	panel.content_margin_left = 24.0
	panel.content_margin_right = 24.0
	panel.content_margin_top = 10.0
	panel.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	add_child(stack)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 21)
	_title.add_theme_color_override("font_color", Art.IVORY_BRIGHT)
	stack.add_child(_title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Art.MINT_SOFT)
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
		"size":size,
		"position":position,
	}


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
