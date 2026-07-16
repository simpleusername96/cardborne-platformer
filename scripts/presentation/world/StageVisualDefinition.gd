class_name StageVisualDefinition
extends Resource

const MODE_SEQUENTIAL := &"sequential_panorama"
const MODE_FIXED := &"fixed_composition"

@export var id: StringName
@export var mode: StringName = MODE_SEQUENTIAL
@export var panel_size := Vector2i(2048, 1536)
@export var panel_overlap := 192
@export var scroll_scale := Vector2(0.18, 0.18)
@export var overscan := Vector2i(192, 128)
@export var panel_paths: PackedStringArray = []
@export var procedural_fallback := true
@export var proof_room_id: StringName
@export var proof_status: StringName = &"measured"


func required_coverage(world_bounds: Rect2, maximum_viewport: Vector2i) -> Vector2:
	var viewport := Vector2(maximum_viewport)
	if mode == MODE_FIXED:
		return viewport
	return Vector2(
		viewport.x + maxf(world_bounds.size.x - viewport.x, 0.0) * scroll_scale.x
			+ float(overscan.x * 2),
		viewport.y + maxf(world_bounds.size.y - viewport.y, 0.0) * scroll_scale.y
			+ float(overscan.y * 2)
	)


func minimum_panel_count(world_bounds: Rect2, maximum_viewport: Vector2i) -> int:
	if mode == MODE_FIXED:
		return 1
	var required := required_coverage(world_bounds, maximum_viewport)
	if panel_size.x <= panel_overlap or panel_size.y < ceili(required.y):
		return -1
	var stride := panel_size.x - panel_overlap
	return maxi(1, ceili((required.x - float(panel_size.x)) / float(stride)) + 1)


func composite_size(panel_count: int) -> Vector2i:
	if panel_count <= 0:
		return Vector2i.ZERO
	if mode == MODE_FIXED:
		return panel_size
	return Vector2i(
		panel_size.x + (panel_count - 1) * (panel_size.x - panel_overlap),
		panel_size.y
	)


func estimated_rgba_bytes(panel_count: int) -> int:
	return maxi(panel_count, 0) * panel_size.x * panel_size.y * 4


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("Stage visual definition requires an id.")
	if mode not in [MODE_SEQUENTIAL, MODE_FIXED]:
		errors.append("%s has unsupported mode %s." % [id, mode])
	if panel_size.x <= 0 or panel_size.y <= 0:
		errors.append("%s requires a positive panel size." % id)
	if mode == MODE_SEQUENTIAL and (panel_overlap < 0 or panel_overlap >= panel_size.x):
		errors.append("%s overlap must be smaller than the panel width." % id)
	if scroll_scale.x < 0.0 or scroll_scale.y < 0.0:
		errors.append("%s scroll scale cannot be negative." % id)
	for path in panel_paths:
		if not ResourceLoader.exists(path):
			errors.append("%s cannot resolve panel %s." % [id, path])
	return errors
