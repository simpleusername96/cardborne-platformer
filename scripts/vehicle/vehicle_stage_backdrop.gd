class_name VehicleStageBackdrop
extends Node2D

## Cached presentation shell for the geometry-fed flat world. Combat and
## collision truth stay outside this node.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Visual = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const TacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")
const WorldMeshBuilder = preload(
	"res://scripts/presentation/vehicle_world_mesh_builder.gd"
)

var stage_id: StringName = &"stage_1"
var _layout: TacticalLayout
var _layout_fingerprint := 0
var _world_mesh


func _ready() -> void:
	z_index = -20
	show_behind_parent = true
	_world_mesh = WorldMeshBuilder.new()
	_world_mesh.name = "WorldMesh"
	add_child(_world_mesh)
	_world_mesh.configure(stage_id, _layout)


func configure(value: StringName, layout: TacticalLayout = null) -> void:
	var next_fingerprint := layout.fingerprint if layout != null else 0
	if stage_id == value and _layout_fingerprint == next_fingerprint and is_node_ready():
		return
	stage_id = value
	_layout = layout
	_layout_fingerprint = next_fingerprint
	if _world_mesh != null:
		_world_mesh.configure(stage_id, layout)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rules.world_rect(stage_id), Visual.WORLD_CANVAS)


func debug_contract() -> Dictionary:
	return {
		"stage_id": stage_id,
		"static_cached": not is_processing() and not is_physics_processing(),
		"behind_gameplay": show_behind_parent and z_index < 0,
		"world_rect": Rules.world_rect(stage_id),
		"walkable_count": Rules.get_floor_regions(stage_id).size(),
		"cover_count": Rules.get_cover_rects(false, stage_id).size(),
		"layout_fingerprint":_layout_fingerprint,
		"runtime_cover_count":_layout.cover_rects.size() if _layout != null else 0,
		"world_mesh":_world_mesh.debug_contract() if _world_mesh != null else {},
	}
