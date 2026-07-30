class_name VehicleRetainedMinimapMesh
extends RefCounted

## Owns one fixed-capacity minimap vertex buffer and updates it in place.
## Color channels are preallocated so marker motion never creates GPU resources.

const Builder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const VERTICES_PER_COLOR := 9216

var mesh: ArrayMesh
var canvas_size := Vector2.ZERO
var _color_offsets := {}
var _visible_vertex_counts := {}
var _vertex_stride_bytes := 12


func _init(size: Vector2) -> void:
	canvas_size = size
	_create_mesh()


func update(snapshot: Dictionary) -> void:
	if mesh == null:
		return
	var channels := Builder.build_triangle_channels(snapshot, canvas_size)
	for key_variant in channels:
		var key := int(key_variant)
		if not _color_offsets.has(key):
			push_error("Unsupported minimap color channel: %d" % key)
			continue
		var source: PackedVector3Array = channels[key]
		if source.size() > VERTICES_PER_COLOR:
			push_error(
				"Minimap channel capacity exceeded: %d > %d"
				% [source.size(), VERTICES_PER_COLOR]
			)
		var visible_count := mini(source.size(), VERTICES_PER_COLOR)
		var previous_count := int(_visible_vertex_counts.get(key, 0))
		var upload_count := maxi(visible_count, previous_count)
		if upload_count <= 0:
			continue
		var upload := PackedVector3Array()
		upload.resize(upload_count)
		for index in visible_count:
			upload[index] = source[index]
		mesh.surface_update_vertex_region(
			0,
			int(_color_offsets[key]) * _vertex_stride_bytes,
			upload.to_byte_array()
		)
		_visible_vertex_counts[key] = visible_count
	for key_variant in _visible_vertex_counts.keys():
		var key := int(key_variant)
		if channels.has(key) or int(_visible_vertex_counts[key]) <= 0:
			continue
		var previous_count := int(_visible_vertex_counts[key])
		var empty_upload := PackedVector3Array()
		empty_upload.resize(previous_count)
		mesh.surface_update_vertex_region(
			0,
			int(_color_offsets[key]) * _vertex_stride_bytes,
			empty_upload.to_byte_array()
		)
		_visible_vertex_counts[key] = 0


func debug_snapshot() -> Dictionary:
	var visible_vertices := 0
	var visible_vertices_by_color := {}
	for count in _visible_vertex_counts.values():
		visible_vertices += int(count)
	for key in _visible_vertex_counts:
		visible_vertices_by_color[key] = int(_visible_vertex_counts[key])
	return {
		"color_channels":_color_offsets.size(),
		"vertices_per_color":VERTICES_PER_COLOR,
		"visible_vertices":visible_vertices,
		"visible_vertices_by_color":visible_vertices_by_color,
		"surface_count":mesh.get_surface_count() if mesh != null else 0,
	}


func _create_mesh() -> void:
	var palette := Builder.dynamic_colors()
	var total_vertices := palette.size() * VERTICES_PER_COLOR
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(total_vertices)
	colors.resize(total_vertices)
	_color_offsets.clear()
	_visible_vertex_counts.clear()
	for channel_index in palette.size():
		var color: Color = palette[channel_index]
		var key := color.to_rgba32()
		var offset := channel_index * VERTICES_PER_COLOR
		_color_offsets[key] = offset
		_visible_vertex_counts[key] = 0
		for index in VERTICES_PER_COLOR:
			colors[offset + index] = color
	var stride_probe := PackedVector3Array([Vector3.ZERO]).to_byte_array()
	_vertex_stride_bytes = stride_probe.size()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays,
		[],
		{},
		Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE
	)
	mesh.custom_aabb = AABB(
		Vector3.ZERO,
		Vector3(maxf(1.0, canvas_size.x), maxf(1.0, canvas_size.y), 1.0)
	)
