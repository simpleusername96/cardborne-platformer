class_name ProductionStageBackdrop
extends Parallax2D

const VISUAL_CATALOG: StageVisualCatalog = preload(
	"res://data/presentation/stage_visual_catalog.tres"
)
const MAXIMUM_VIEWPORT := Vector2i(1920, 1080)

var _world_bounds := Rect2(0.0, 0.0, 2400.0, 720.0)
var _draw_bounds := _world_bounds.grow(240.0)
var _stage_id: StringName = &"ruin_approach"
var _definition: StageVisualDefinition
var _loaded_panel_paths := PackedStringArray()
var _loaded_source_bytes := 0
var _fallback_active := true


func _ready() -> void:
	z_index = -20
	repeat_size = Vector2.ZERO
	repeat_times = 1
	autoscroll = Vector2.ZERO
	queue_redraw()


func configure(world_bounds: Rect2, stage_id: StringName = &"ruin_approach") -> void:
	if world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0:
		_world_bounds = world_bounds
		_draw_bounds = world_bounds.grow(240.0)
	_stage_id = stage_id
	_definition = VISUAL_CATALOG.get_definition(stage_id)
	_clear_panels()
	if _definition == null:
		scroll_scale = Vector2.ONE
		_fallback_active = true
	else:
		scroll_scale = _definition.scroll_scale
		_load_current_location_panels()
	queue_redraw()


func get_visual_snapshot() -> Dictionary:
	var minimum_count := 0
	var composite := Vector2i.ZERO
	var estimated_bytes := 0
	if _definition != null:
		minimum_count = _definition.minimum_panel_count(_world_bounds, MAXIMUM_VIEWPORT)
		composite = _definition.composite_size(maxi(minimum_count, 0))
		estimated_bytes = _definition.estimated_rgba_bytes(_loaded_panel_paths.size())
	return {
		"stage_id": String(_stage_id),
		"definition_id": String(_definition.id) if _definition != null else "",
		"world_bounds": _world_bounds,
		"scroll_scale": scroll_scale,
		"loaded_panel_paths": _loaded_panel_paths.duplicate(),
		"loaded_panel_count": _loaded_panel_paths.size(),
		"minimum_panel_count": minimum_count,
		"panel_overlap": _definition.panel_overlap if _definition != null else 0,
		"composite_size": composite,
		"procedural_fallback_active": _fallback_active,
		"estimated_loaded_rgba_bytes": estimated_bytes,
		"loaded_source_bytes": _loaded_source_bytes,
		"loading_policy": "current_location_only",
	}


func _clear_panels() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_loaded_panel_paths.clear()
	_loaded_source_bytes = 0
	_fallback_active = true


func _load_current_location_panels() -> void:
	if _definition.panel_paths.is_empty():
		_fallback_active = _definition.procedural_fallback
		return
	var expected_count := _definition.minimum_panel_count(_world_bounds, MAXIMUM_VIEWPORT)
	if expected_count <= 0 or _definition.panel_paths.size() < expected_count:
		_fallback_active = _definition.procedural_fallback
		return
	var origin := Vector2(
		_world_bounds.position.x * scroll_scale.x - float(_definition.overscan.x),
		_world_bounds.position.y * scroll_scale.y - float(_definition.overscan.y)
	)
	var stride := _definition.panel_size.x - _definition.panel_overlap
	for panel_index in expected_count:
		var panel_path := _definition.panel_paths[panel_index]
		var texture := load(panel_path) as Texture2D
		if texture == null:
			_clear_panels()
			_fallback_active = _definition.procedural_fallback
			return
		var sprite := Sprite2D.new()
		sprite.name = "Panel%02d" % (panel_index + 1)
		sprite.centered = false
		sprite.position = origin + Vector2(float(panel_index * stride), 0.0)
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		_loaded_panel_paths.append(panel_path)
		var source_image := texture.get_image()
		if source_image != null:
			_loaded_source_bytes += source_image.get_data_size()
	_fallback_active = false


func _draw() -> void:
	if not _fallback_active:
		return
	var left := _draw_bounds.position.x
	var top := _draw_bounds.position.y
	var right := _draw_bounds.end.x
	var bottom := _draw_bounds.end.y
	var width := _draw_bounds.size.x
	var ridge_y := top + _draw_bounds.size.y * 0.48
	var palette := _palette_for_stage()
	var background: Color = palette["background"]
	var distant: Color = palette["distant"]
	var structure: Color = palette["structure"]
	var trim: Color = palette["trim"]
	draw_rect(_draw_bounds, background)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, ridge_y),
		Vector2(left + width * 0.12, ridge_y - 70.0),
		Vector2(left + width * 0.25, ridge_y + 10.0),
		Vector2(left + width * 0.40, ridge_y - 95.0),
		Vector2(left + width * 0.55, ridge_y - 20.0),
		Vector2(left + width * 0.72, ridge_y - 110.0),
		Vector2(left + width * 0.88, ridge_y - 35.0),
		Vector2(right, ridge_y - 90.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	]), distant)

	var pillar_x := left + 160.0
	while pillar_x < right:
		draw_rect(Rect2(pillar_x, top + 170.0, 44.0, 350.0), structure)
		draw_rect(Rect2(pillar_x - 14.0, top + 170.0, 72.0, 16.0), trim)
		pillar_x += 420.0
	draw_rect(Rect2(left, ridge_y + 40.0, width, 8.0), Color("253034"))
	if _stage_id == &"flooded_works":
		var water_y := bottom - 150.0
		draw_rect(Rect2(left, water_y, width, 150.0), Color("17434a", 0.62))
		draw_rect(Rect2(left, water_y, width, 5.0), Color("67b7b2", 0.78))
		var pipe_x := left + 300.0
		while pipe_x < right:
			draw_rect(Rect2(pipe_x, top + 90.0, 120.0, 20.0), Color("664f3f"))
			draw_rect(Rect2(pipe_x + 100.0, top + 90.0, 20.0, 105.0), Color("664f3f"))
			pipe_x += 760.0
	elif _stage_id == &"broken_sanctum":
		var arch_x := left + 260.0
		while arch_x < right:
			draw_rect(Rect2(arch_x, top + 105.0, 18.0, 250.0), Color("424339"))
			draw_rect(Rect2(arch_x + 132.0, top + 105.0, 18.0, 250.0), Color("424339"))
			draw_rect(Rect2(arch_x, top + 105.0, 150.0, 14.0), Color("8b7541"))
			arch_x += 620.0


func _palette_for_stage() -> Dictionary:
	match _stage_id:
		&"flooded_works":
			return {
				"background": Color("11191a"),
				"distant": Color("173033"),
				"structure": Color("26383a"),
				"trim": Color("4d817b"),
			}
		&"broken_sanctum":
			return {
				"background": Color("171719"),
				"distant": Color("273029"),
				"structure": Color("37383a"),
				"trim": Color("8b7541"),
			}
		_:
			return {
				"background": Color("12171a"),
				"distant": Color("182225"),
				"structure": Color("222d31"),
				"trim": Color("314038"),
			}
