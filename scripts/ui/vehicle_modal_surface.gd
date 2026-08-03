class_name VehicleModalSurface
extends PanelContainer

## Shared modal host. The production Theme owns one flat code-native surface;
## child Controls own localized text, semantic imagery, focus, and layout.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
func debug_contract() -> Dictionary:
	return {
		"border_width":Art.BORDER_WIDTH,
		"rail_width":Art.SELECTED_RAIL_WIDTH,
		"accent":Art.SYSTEM,
		"layered_depth":false,
		"image_backed":false,
		"corner_cut":3.0,
		"root_surface_count":1,
	}
