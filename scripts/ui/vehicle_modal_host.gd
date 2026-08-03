class_name VehicleModalHost
extends CenterContainer

## Full-viewport modal shell. It applies the shared surface and clamps every
## screen to the supported viewport without owning screen-specific content.

const Factory = preload("res://scripts/ui/vehicle_ui_component_factory.gd")

var preferred_size := Vector2.ZERO
var surface: PanelContainer
var content: Control
var _layout_refresh_frames := 0
var _accessibility_compact := false


func configure(next_content: Control, minimum_size: Vector2) -> void:
	preferred_size = minimum_size
	content = next_content
	if not is_node_ready():
		return
	_install_content()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	resized.connect(_apply_viewport)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if content != null:
		_install_content()
	call_deferred("_apply_viewport")


func _process(_delta: float) -> void:
	if _layout_refresh_frames <= 0:
		set_process(false)
		return
	_apply_viewport()
	update_minimum_size()
	queue_sort()
	if surface != null:
		surface.update_minimum_size()
		surface.queue_sort()
	if content != null:
		content.update_minimum_size()
	for node in find_children("*", "Container", true, false):
		(node as Container).queue_sort()
	for node in find_children("*", "Control", true, false):
		(node as Control).force_update_transform()
	_layout_refresh_frames -= 1


func _install_content() -> void:
	if surface != null:
		return
	surface = Factory.modal_surface(preferred_size)
	add_child(surface)
	surface.add_child(content)
	_apply_viewport()
	call_deferred("_apply_viewport")


func _apply_viewport() -> void:
	if surface == null:
		return
	var available := Vector2(
		maxf(320.0, size.x - 48.0),
		maxf(260.0, size.y - 24.0)
	)
	var target_size := preferred_size
	if (
		_accessibility_compact
		and content != null
		and content.has_method("accessibility_preferred_size")
	):
		target_size = Vector2(content.call("accessibility_preferred_size"))
	surface.custom_minimum_size = Vector2(
		minf(target_size.x, available.x),
		minf(target_size.y, available.y)
	)
	var responsive_compact := size.x < 1100.0 or size.y < 650.0
	var compact := responsive_compact or _accessibility_compact
	surface.theme_type_variation = (
		&"ModalSurfaceCompact" if compact else &"ModalSurface"
	)
	if content != null and content.has_method("set_compact_mode"):
		content.call("set_compact_mode", compact)
	if content != null and content.has_method("set_accessibility_mode"):
		content.call("set_accessibility_mode", _accessibility_compact)


func set_accessibility_compact(enabled: bool) -> void:
	if _accessibility_compact == enabled:
		_apply_viewport()
		return
	_accessibility_compact = enabled
	_apply_viewport()
	refresh_layout()


func surface_rect() -> Rect2:
	return surface.get_global_rect() if surface != null else Rect2()


func refresh_layout() -> void:
	_apply_viewport()
	update_minimum_size()
	queue_sort()
	if surface != null:
		surface.update_minimum_size()
		surface.queue_sort()
	if content != null:
		content.update_minimum_size()
	for node in find_children("*", "Container", true, false):
		(node as Container).queue_sort()
	_layout_refresh_frames = 3
	set_process(true)


func debug_contract() -> Dictionary:
	var overflow_nodes := _visible_overflow_nodes()
	return {
		"preferred_size":preferred_size,
		"surface_rect":surface_rect(),
		"content_rect":(
			content.get_global_rect()
			if content != null
			else Rect2()
		),
		"content_minimum":(
			content.get_combined_minimum_size()
			if content != null
			else Vector2.ZERO
		),
		"focusables":_focusable_count(),
		"primary_actions":_primary_action_count(),
		"overflow_count":overflow_nodes.size(),
		"overflow_nodes":Array(overflow_nodes),
		"missing_copy_count":_missing_copy_count(),
	}


func _focusable_count() -> int:
	var count := 0
	for node in find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode != Control.FOCUS_NONE and control.visible:
			count += 1
	return count


func _primary_action_count() -> int:
	if content == null:
		return 0
	var count := 0
	for node in content.find_children("*", "Button", true, false):
		var button := node as Button
		if (
			button.is_visible_in_tree()
			and not button.disabled
			and button.theme_type_variation == &"PrimaryButton"
		):
			count += 1
	return count


func _visible_overflow_nodes() -> PackedStringArray:
	var result := PackedStringArray()
	if content == null:
		return result
	var bounds := Rect2(
		Vector2.ZERO,
		content.get_global_rect().size
	).grow(0.75)
	for node in content.find_children("*", "Control", true, false):
		var control := node as Control
		if (
			not control.is_visible_in_tree()
			or not control.get_global_rect().has_area()
			or _inside_scroll_container(control)
		):
			continue
		var local_rect := _rect_in_content(control)
		if not bounds.encloses(local_rect):
			result.append("%s %s" % [
				content.get_path_to(control),
				local_rect,
			])
	return result


func _missing_copy_count() -> int:
	if content == null:
		return 0
	var count := 0
	for node in content.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var value := ""
		if control is Label:
			value = (control as Label).text
		elif control is Button:
			value = (control as Button).text
		if (
			not value.is_empty()
			and value.contains("_")
			and tr(value) == value
		):
			count += 1
	return count


func _inside_scroll_container(control: Control) -> bool:
	var current := control.get_parent()
	while current != null and current != content:
		if current is ScrollContainer:
			return true
		current = current.get_parent()
	return false


func _rect_in_content(control: Control) -> Rect2:
	var rect := control.get_rect()
	var current := control.get_parent()
	while current != null and current != content:
		if current is Control:
			rect.position += (current as Control).position
		current = current.get_parent()
	return rect
