class_name VehicleStatusOrbit
extends Control

## Compatibility surface retained while HUD wiring is removed. Persistent orbit
## badges are intentionally not rendered; action slots and localized target text
## own the useful recurring-state feedback.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_snapshot(_value: Dictionary) -> void:
	queue_redraw()


func _draw() -> void:
	pass


func debug_contract() -> Dictionary:
	return {
		"enabled":false,
		"maximum_badges":0,
		"image_coded":false,
		"code_native_frame":false,
		"semantic_icons":false,
	}
