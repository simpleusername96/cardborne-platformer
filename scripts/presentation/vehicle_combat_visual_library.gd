class_name VehicleCombatVisualLibrary
extends RefCounted

## Prebuilt flat-color geometry for high-count combat families. Runtime
## presentation changes transforms and instance colors, never polygon vertices.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

const ENEMY_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser",
	&"shooter", &"controller", &"turret", &"mine", &"generator",
	&"shield_escort", &"artillery_spotter", &"interceptor_tower",
	&"rammer", &"bulkhead_guard", &"splitter_barge",
	&"repair_tender", &"drone_carrier", &"beam_sentinel",
	&"boss_pylon", &"stage_boss",
]


static func enemy_mesh(archetype: StringName) -> ArrayMesh:
	var body := _enemy_polygon(archetype)
	var shadow := PackedVector2Array()
	for point in body:
		shadow.append(point + Vector2(0.14, 0.18))
	return polygon_mesh([
		{"points": shadow, "color": Color(0.22, 0.18, 0.22, 0.92)},
		{"points": body, "color": Color.WHITE},
	])


static func boss_mesh(variant: StringName) -> ArrayMesh:
	var body := _boss_polygon(variant)
	var shadow := PackedVector2Array()
	for point in body:
		shadow.append(point + Vector2(0.14, 0.18))
	return polygon_mesh([
		{"points":shadow, "color":Color(0.22, 0.18, 0.22, 0.92)},
		{"points":body, "color":Color.WHITE},
	])


static func projectile_head_mesh() -> ArrayMesh:
	return polygon_mesh([{
		"points": _regular_polygon(Vector2.ZERO, 1.0, 20),
		"color": Color.WHITE,
	}])


static func player_projectile_head_mesh() -> ArrayMesh:
	return polygon_mesh([
		{"points":_regular_polygon(Vector2.ZERO, 1.0, 20), "color":Art.MUSTARD},
		{"points":_regular_polygon(Vector2.ZERO, 0.46, 16), "color":Art.COBALT_DEEP},
	])


static func projectile_trail_mesh(affinity: StringName) -> ArrayMesh:
	var polygons: Array[Dictionary] = []
	match AttackContract.normalize_affinity(affinity):
		AttackContract.THERMAL:
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, -0.5), Vector2(0.5, -0.18),
					Vector2(0.5, 0.18), Vector2(-0.5, 0.5),
				]),
				"color":Color.WHITE,
			})
		AttackContract.TOXIN:
			for center_x in [-0.28, 0.28]:
				polygons.append({
					"points":PackedVector2Array([
						Vector2(center_x - 0.22, 0.0), Vector2(center_x, -0.46),
						Vector2(center_x + 0.22, 0.0), Vector2(center_x, 0.46),
					]),
					"color":Color.WHITE,
				})
		AttackContract.CRYO:
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, -0.48), Vector2(0.5, -0.08),
					Vector2(0.5, 0.05), Vector2(-0.5, -0.16),
				]),
				"color":Color.WHITE,
			})
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, 0.16), Vector2(0.5, -0.05),
					Vector2(0.5, 0.08), Vector2(-0.5, 0.48),
				]),
				"color":Color.WHITE,
			})
		AttackContract.ARC:
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, -0.18), Vector2(-0.18, -0.5),
					Vector2(-0.04, -0.12), Vector2(0.24, -0.42),
					Vector2(0.12, -0.03), Vector2(0.5, 0.18),
					Vector2(0.18, 0.5), Vector2(0.04, 0.12),
					Vector2(-0.24, 0.42), Vector2(-0.12, 0.03),
				]),
				"color":Color.WHITE,
			})
		AttackContract.HYBRID:
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, 0.0), Vector2(-0.08, -0.5),
					Vector2(0.5, 0.0), Vector2(-0.08, 0.5),
				]),
				"color":Color.WHITE,
			})
		_:
			polygons.append({
				"points":PackedVector2Array([
					Vector2(-0.5, -0.5), Vector2(0.5, -0.5),
					Vector2(0.5, 0.5), Vector2(-0.5, 0.5),
				]),
				"color":Color.WHITE,
			})
	return polygon_mesh(polygons)


static func health_bar_mesh() -> ArrayMesh:
	return polygon_mesh([{
		"points": PackedVector2Array([
			Vector2(-0.5, -0.5), Vector2(0.5, -0.5),
			Vector2(0.5, 0.5), Vector2(-0.5, 0.5),
		]),
		"color": Color.WHITE,
	}])


static func status_arc_mesh() -> ArrayMesh:
	var segments := 12
	var start_angle := deg_to_rad(-55.0)
	var sweep := deg_to_rad(110.0)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index in segments:
		var angle_a := start_angle + sweep * float(index) / float(segments)
		var angle_b := start_angle + sweep * float(index + 1) / float(segments)
		var outer_a := Vector2.RIGHT.rotated(angle_a)
		var outer_b := Vector2.RIGHT.rotated(angle_b)
		var inner_a := outer_a * 0.78
		var inner_b := outer_b * 0.78
		var offset := vertices.size()
		for point in [outer_a, outer_b, inner_b, inner_a]:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color.WHITE)
		for local_index in [0, 1, 2, 0, 2, 3]:
			indices.append(offset + local_index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func disk_mesh(segments: int = 32) -> ArrayMesh:
	return polygon_mesh([{
		"points": _regular_polygon(Vector2.ZERO, 1.0, segments),
		"color": Color.WHITE,
	}])


static func player_hull_mesh() -> ArrayMesh:
	var hull := PackedVector2Array([
		Vector2(1.0, 0.0), Vector2(0.18, -0.74),
		Vector2(-0.72, -1.0), Vector2(-0.48, -0.18),
		Vector2(-1.0, 0.54), Vector2(0.08, 0.70),
	])
	var shadow := PackedVector2Array()
	for point in hull:
		shadow.append(point + Vector2(0.20, 0.25))
	return polygon_mesh([
		{"points": shadow, "color": Color(0.42, 0.34, 0.18, 0.88)},
		{"points": hull, "color": Color.WHITE},
	])


static func player_primary_mesh() -> ArrayMesh:
	return polygon_mesh([
		{"points":PackedVector2Array([
			Vector2(-0.18, -0.18), Vector2(1.0, -0.18),
			Vector2(1.0, 0.18), Vector2(-0.18, 0.18),
		]), "color":Color.WHITE},
		{"points":_regular_polygon(Vector2(-0.14, 0.0), 0.26, 16), "color":Color.WHITE},
	])


static func player_engine_mesh() -> ArrayMesh:
	return polygon_mesh([{
		"points":PackedVector2Array([
			Vector2(0.28, -0.34), Vector2(0.38, 0.34),
			Vector2(-0.72, 0.24), Vector2(-1.0, 0.0),
			Vector2(-0.72, -0.24),
		]),
		"color":Color.WHITE,
	}])


static func player_secondary_core_mesh() -> ArrayMesh:
	return polygon_mesh([
		{"points":_regular_polygon(Vector2.ZERO, 1.0, 16), "color":Color.WHITE},
		{"points":_regular_polygon(Vector2.ZERO, 0.46, 12), "color":Art.IVORY_BRIGHT},
	])


static func player_mesh() -> ArrayMesh:
	return player_hull_mesh()


static func experience_mesh(kind: StringName) -> ArrayMesh:
	var points := _regular_polygon(Vector2.ZERO, 1.0, 4, PI / 4.0)
	if kind == &"medium":
		points = _regular_polygon(Vector2.ZERO, 1.0, 6, PI / 6.0)
	elif kind == &"large":
		points = _alternating_polygon(16, 1.0, 0.68, -PI * 0.5)
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0.20, 0.25))
	return polygon_mesh([
		{"points": shadow, "color": Color(0.12, 0.18, 0.30, 0.90)},
		{"points": points, "color": Color.WHITE},
	])


static func effect_mesh(kind: StringName) -> ArrayMesh:
	match kind:
		&"diamond":
			return polygon_mesh([{
				"points": _regular_polygon(Vector2.ZERO, 1.0, 4, PI / 4.0),
				"color": Color.WHITE,
			}])
		&"afterimage":
			return polygon_mesh([{
				"points": PackedVector2Array([
					Vector2(1.0, 0.0), Vector2(-0.78, -0.62), Vector2(-0.62, 0.62),
				]),
				"color": Color.WHITE,
			}])
		&"beam":
			return polygon_mesh([{
				"points": PackedVector2Array([
					Vector2(-1.0, -0.16), Vector2(1.0, -0.16),
					Vector2(1.0, 0.16), Vector2(-1.0, 0.16),
				]),
				"color": Color.WHITE,
			}])
		_:
			return annulus_mesh(32, 0.78)


static func enemy_color(role: StringName) -> Color:
	match role:
		&"chaser", &"shooter", &"controller", &"mine", &"artillery_spotter", &"rammer":
			return Art.CORAL
		&"turret", &"interceptor_tower", &"beam_sentinel":
			return Art.CORAL_DARK
		&"generator", &"shield_escort", &"repair_tender", &"drone_carrier":
			return Art.MINT
		&"stage_boss", &"boss_pylon":
			return Art.BOSS_MAGENTA
	return Art.INK_MUTED


static func polygon_mesh(polygons: Array[Dictionary]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for polygon in polygons:
		var points := PackedVector2Array(polygon["points"])
		var triangles := Geometry2D.triangulate_polygon(points)
		var vertex_offset := vertices.size()
		for point in points:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color(polygon["color"]))
		for index in triangles:
			indices.append(vertex_offset + index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func annulus_mesh(segments: int, inner_radius: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index in segments:
		var angle_a := TAU * float(index) / float(segments)
		var angle_b := TAU * float(index + 1) / float(segments)
		var outer_a := Vector2.RIGHT.rotated(angle_a)
		var outer_b := Vector2.RIGHT.rotated(angle_b)
		var inner_a := outer_a * inner_radius
		var inner_b := outer_b * inner_radius
		var offset := vertices.size()
		for point in [outer_a, outer_b, inner_b, inner_a]:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color.WHITE)
		for local_index in [0, 1, 2, 0, 2, 3]:
			indices.append(offset + local_index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _enemy_polygon(archetype: StringName) -> PackedVector2Array:
	match archetype:
		&"scrap_drone":
			return PackedVector2Array([Vector2(1.0, 0.0), Vector2(-0.45, -0.72), Vector2(-0.18, 0.0), Vector2(-0.45, 0.72)])
		&"needle_drone":
			return PackedVector2Array([Vector2(1.2, 0.0), Vector2(0.0, -0.62), Vector2(-0.72, 0.0), Vector2(0.0, 0.62)])
		&"spark_minelet":
			return _alternating_polygon(12, 1.0, 0.46)
		&"chaser":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.08, -1.0), Vector2(-0.82, -0.42),
				Vector2(-0.48, 0.0), Vector2(-0.82, 0.42), Vector2(0.08, 1.0),
			])
		&"shooter", &"artillery_spotter", &"beam_sentinel", &"boss_pylon":
			return _regular_polygon(Vector2.ZERO, 1.0, 4, PI / 4.0)
		&"controller":
			return _regular_polygon(Vector2.ZERO, 1.0, 6, PI / 6.0)
		&"turret", &"interceptor_tower":
			return _stepped_square()
		&"mine":
			return _alternating_polygon(16, 1.0, 0.54)
		&"generator":
			return _regular_polygon(Vector2.ZERO, 1.0, 8, PI / 8.0)
		&"shield_escort", &"repair_tender":
			return _regular_polygon(Vector2.ZERO, 1.0, 6, PI / 6.0)
		&"rammer":
			return PackedVector2Array([Vector2(1.2, 0.0), Vector2(-0.45, -1.0), Vector2(-1.0, 0.0), Vector2(-0.45, 1.0)])
		&"bulkhead_guard":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.62, -0.88), Vector2(-0.38, -0.72),
				Vector2(-1.0, -0.24), Vector2(-1.0, 0.24), Vector2(-0.38, 0.72),
				Vector2(0.62, 0.88),
			])
		&"splitter_barge":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.42, -0.62), Vector2(-0.16, -1.0),
				Vector2(-0.82, -0.48), Vector2(-0.56, 0.0), Vector2(-0.82, 0.48),
				Vector2(-0.16, 1.0), Vector2(0.42, 0.62),
			])
		&"drone_carrier":
			return PackedVector2Array([
				Vector2(-0.82, -0.72), Vector2(0.82, -0.72), Vector2(1.0, -0.50),
				Vector2(1.0, 0.50), Vector2(0.82, 0.72), Vector2(-0.82, 0.72),
				Vector2(-1.0, 0.50), Vector2(-1.0, -0.50),
			])
		&"stage_boss":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.50, -0.36), Vector2(0.25, -1.0),
				Vector2(-0.12, -0.58), Vector2(-0.66, -0.78), Vector2(-0.48, 0.0),
				Vector2(-0.66, 0.78), Vector2(-0.12, 0.58), Vector2(0.25, 1.0),
				Vector2(0.50, 0.36),
			])
	return _regular_polygon(Vector2.ZERO, 1.0, 6)


static func _boss_polygon(variant: StringName) -> PackedVector2Array:
	match variant:
		&"leviathan":
			return PackedVector2Array([
				Vector2(1.25, 0.0), Vector2(0.40, -0.42), Vector2(-0.65, -0.78),
				Vector2(-1.0, -0.30), Vector2(-0.35, 0.0), Vector2(-1.0, 0.30),
				Vector2(-0.65, 0.78), Vector2(0.40, 0.42),
			])
		&"titan":
			return _stepped_square()
		&"behemoth":
			return PackedVector2Array([
				Vector2(1.30, 0.0), Vector2(0.35, -0.82), Vector2(-0.62, -1.0),
				Vector2(-1.0, -0.32), Vector2(-0.72, 0.0), Vector2(-1.0, 0.32),
				Vector2(-0.62, 1.0), Vector2(0.35, 0.82),
			])
		&"crown":
			return _alternating_polygon(16, 1.15, 0.68, -PI * 0.5)
		_:
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.45, -0.46), Vector2(0.24, -1.15),
				Vector2(-0.22, -0.72), Vector2(-0.90, -0.92), Vector2(-0.62, 0.0),
				Vector2(-0.90, 0.92), Vector2(-0.22, 0.72), Vector2(0.24, 1.15),
				Vector2(0.45, 0.46),
			])


static func _regular_polygon(origin: Vector2, radius: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(origin + Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return points


static func _alternating_polygon(sides: int, outer_radius: float, inner_radius: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		points.append(Vector2.RIGHT.rotated(rotation + TAU * float(index) / float(sides)) * radius)
	return points


static func _stepped_square() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-0.64, -1.0), Vector2(0.64, -1.0), Vector2(1.0, -0.64),
		Vector2(1.0, 0.64), Vector2(0.64, 1.0), Vector2(-0.64, 1.0),
		Vector2(-1.0, 0.64), Vector2(-1.0, -0.64),
	])
