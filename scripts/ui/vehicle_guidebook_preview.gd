class_name VehicleGuidebookPreview
extends Control

## Displays guide entries through the approved semantic-v2 runtime provider.
## Preview geometry stays presentation-only and never substitutes for collision.

const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _textures: Array[TextureRect] = []
var _asset_ids: Array[StringName] = []


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 150.0)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_textures)
	queue_redraw()


func show_preview(preview: Dictionary) -> void:
	_clear_textures()
	if preview.is_empty():
		visible = false
		return
	visible = true
	var kind := StringName(preview.get("kind", &"enemy"))
	var preview_id := StringName(preview.get("id", &"chaser"))
	match kind:
		&"locked":
			_add_asset(&"hud/minimap_marker_objective_locked", 54.0)
		&"boss":
			_add_asset(StringName("boss/%s" % preview_id), 220.0)
		&"terrain":
			_add_terrain(preview_id)
		&"facility":
			_add_facility(preview_id)
		&"elite":
			_add_asset(&"actor/chaser", 92.0)
			_add_asset(
				&"hud/minimap_marker_elite",
				34.0,
				Vector2(44.0, -38.0)
			)
		&"pickup":
			_add_pickup(preview_id)
		_:
			_add_asset(StringName("actor/%s" % preview_id), 94.0)
	_layout_textures()
	queue_redraw()


func debug_contract() -> Dictionary:
	return {
		"semantic_provider":true,
		"asset_ids":_asset_ids.duplicate(),
		"texture_count":_textures.size(),
	}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Art.COBALT_VOID.lightened(0.04))
	draw_rect(
		Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0)),
		Art.STRUCTURE_BASE,
		false,
		3.0
	)


func _add_terrain(terrain_id: StringName) -> void:
	var asset_id := StringName({
		&"arc_surge":&"world/facility_arc_surge_strip",
		&"breakable_bulkhead":&"world/world_bulkhead_intact",
	}.get(terrain_id, &"world/terrain_solid_cover_block"))
	_add_asset(asset_id, 116.0)


func _add_facility(facility_id: StringName) -> void:
	match facility_id:
		&"transit_gate":
			_add_asset(&"world/facility_transit_gate", 126.0)
		&"repair_basin":
			_add_asset(&"world/facility_repair_pad", 116.0)
			_add_asset(&"world/facility_repair_pad_core", 48.0)
		&"overdrive_field":
			_add_asset(&"world/facility_overdrive_lane", 116.0)
		_:
			_add_asset(&"world/terrain_solid_cover_block", 96.0)


func _add_pickup(pickup_id: StringName) -> void:
	var asset_id := StringName({
		&"experience":&"pickup/experience_large",
		&"repair":&"pickup/repair",
		&"experience_recall":&"pickup/experience_recall",
		&"reward_crate":&"pickup/reward_crate",
	}.get(pickup_id, &"pickup/experience_large"))
	_add_asset(asset_id, 72.0)


func _add_asset(
	asset_id: StringName,
	extent: float,
	offset: Vector2 = Vector2.ZERO,
	modulate: Color = Color.WHITE
) -> TextureRect:
	var texture := SemanticAssets.texture(asset_id)
	if texture == null:
		return null
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.modulate = modulate
	view.size = Vector2.ONE * extent
	view.set_meta("preview_offset", offset)
	add_child(view)
	_textures.append(view)
	_asset_ids.append(asset_id)
	return view


func _layout_textures() -> void:
	for view in _textures:
		var offset := Vector2(view.get_meta("preview_offset", Vector2.ZERO))
		view.position = size * 0.5 + offset - view.size * 0.5


func _clear_textures() -> void:
	for view in _textures:
		view.queue_free()
	_textures.clear()
	_asset_ids.clear()
