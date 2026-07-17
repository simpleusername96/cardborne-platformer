class_name RasterSurfacePass3D
extends Node

## Applies one project-authored raster material without owning mesh transforms or collision.

@export var albedo_texture: Texture2D
@export var surface_roots: Array[NodePath] = []
@export_range(0.035, 0.08, 0.001) var world_uv_scale := 0.05

var applied_mesh_count := 0
var surface_material: StandardMaterial3D


func _ready() -> void:
	if albedo_texture == null:
		push_error("Raster surface pass requires a project-authored albedo texture")
		return
	surface_material = _build_surface_material()
	call_deferred("_apply_configured_surfaces")


func _apply_configured_surfaces() -> void:
	applied_mesh_count = 0
	for root_path in surface_roots:
		var surface_root := get_node_or_null(root_path)
		if surface_root == null:
			push_warning("Raster surface root is missing: %s" % root_path)
			continue
		_apply_material_recursive(surface_root)


func _build_surface_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = albedo_texture
	material.albedo_color = Color(0.92, 0.97, 0.95, 1.0)
	material.roughness = 0.92
	material.metallic = 0.04
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * world_uv_scale
	return material


func _apply_material_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = surface_material
		applied_mesh_count += 1
	for child in node.get_children():
		_apply_material_recursive(child)
