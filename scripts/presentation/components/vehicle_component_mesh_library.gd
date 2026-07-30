class_name VehicleComponentMeshLibrary
extends RefCounted

## Immutable, cached flat-component primitives. This owner knows presentation
## geometry only; catalogs own meaning and gameplay owns every collision shape.

const MAX_ORDINARY_MASSES := 3
const MAX_FUNCTION_ACCENTS := 2
const MAX_SEPARATION_PLANES := 1
const MAX_BOSS_MODULES := 5

static var _mesh_cache: Dictionary = {}


static func polygon_mesh(cache_id: StringName, layers: Array[Dictionary]) -> ArrayMesh:
	if _mesh_cache.has(cache_id):
		return _mesh_cache[cache_id]
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for layer in layers:
		var points := PackedVector2Array(layer.get("points", PackedVector2Array()))
		if points.size() < 3:
			continue
		var triangles := Geometry2D.triangulate_polygon(points)
		var vertex_offset := vertices.size()
		for point in points:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color(layer.get("color", Color.WHITE)))
		for index in triangles:
			indices.append(vertex_offset + index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	if not indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_cache[cache_id] = mesh
	return mesh


static func scaled_points(
	points: PackedVector2Array,
	scale: Vector2
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point * scale)
	return result


static func rect_points(
	center: Vector2,
	half_extent: Vector2
) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half_extent.x, -half_extent.y),
		center + Vector2(half_extent.x, -half_extent.y),
		center + Vector2(half_extent.x, half_extent.y),
		center + Vector2(-half_extent.x, half_extent.y),
	])


static func primitive_points(primitive_id: StringName) -> PackedVector2Array:
	match primitive_id:
		&"player_interceptor":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.44, -0.20),
				Vector2(0.18, -0.54),
				Vector2(-0.34, -0.78),
				Vector2(-0.54, -0.60),
				Vector2(-0.46, -0.30),
				Vector2(-0.78, -0.28),
				Vector2(-0.72, -0.06),
				Vector2(-0.40, -0.03),
				Vector2(-0.34, 0.00),
				Vector2(-0.40, 0.03),
				Vector2(-0.72, 0.06),
				Vector2(-0.78, 0.28),
				Vector2(-0.46, 0.30),
				Vector2(-0.54, 0.60),
				Vector2(-0.34, 0.78),
				Vector2(0.18, 0.54),
				Vector2(0.44, 0.20),
			])
		&"forward_wedge":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.18, -0.72),
				Vector2(-0.82, -0.60), Vector2(-0.58, 0.0),
				Vector2(-0.82, 0.60), Vector2(0.18, 0.72),
			])
		&"solid_chevron":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(-0.40, -0.78),
				Vector2(-0.88, -0.42), Vector2(-0.20, 0.0),
				Vector2(-0.88, 0.42), Vector2(-0.40, 0.78),
			])
		&"split_spear":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(-0.22, -0.78),
				Vector2(-0.82, -0.52), Vector2(-0.42, -0.10),
				Vector2(-0.82, 0.52), Vector2(-0.22, 0.78),
			])
		&"slab":
			return PackedVector2Array([
				Vector2(0.82, -0.62), Vector2(1.0, -0.34),
				Vector2(1.0, 0.34), Vector2(0.82, 0.62),
				Vector2(-0.82, 0.62), Vector2(-1.0, 0.34),
				Vector2(-1.0, -0.34), Vector2(-0.82, -0.62),
			])
		&"diamond":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.0, -1.0),
				Vector2(-1.0, 0.0), Vector2(0.0, 1.0),
			])
	return PackedVector2Array()


static func validate_component_budget(
	filled_masses: int,
	function_accents: int,
	separation_planes: int,
	boss_modules: int = 0
) -> PackedStringArray:
	var errors := PackedStringArray()
	if filled_masses < 1 or filled_masses > MAX_ORDINARY_MASSES:
		errors.append("filled mass count must be 1..%d" % MAX_ORDINARY_MASSES)
	if function_accents < 0 or function_accents > MAX_FUNCTION_ACCENTS:
		errors.append("function accent count must be 0..%d" % MAX_FUNCTION_ACCENTS)
	if separation_planes < 0 or separation_planes > MAX_SEPARATION_PLANES:
		errors.append("separation plane count must be 0..%d" % MAX_SEPARATION_PLANES)
	if boss_modules < 0 or boss_modules > MAX_BOSS_MODULES:
		errors.append("boss module count must be 0..%d" % MAX_BOSS_MODULES)
	return errors


static func debug_contract() -> Dictionary:
	return {
		"cached_meshes": _mesh_cache.size(),
		"ordinary_mass_budget": MAX_ORDINARY_MASSES,
		"function_accent_budget": MAX_FUNCTION_ACCENTS,
		"separation_plane_budget": MAX_SEPARATION_PLANES,
		"boss_module_budget": MAX_BOSS_MODULES,
	}
