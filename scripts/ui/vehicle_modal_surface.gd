class_name VehicleModalSurface
extends PanelContainer

## Shared modal host. The production Theme owns its 9-slice image chrome;
## child Controls own localized text, icons, focus, and layout.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const CORNER_CUT := 12.0
func debug_contract() -> Dictionary:
	return {
		"border_width":Art.BORDER_WIDTH,
		"rail_width":Art.SELECTED_RAIL_WIDTH,
		"accent":Art.SYSTEM,
		"layered_depth":true,
		"image_backed":true,
		"corner_cut":CORNER_CUT,
	}
