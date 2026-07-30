class_name VehicleProjectileEffectMeshRecipes
extends RefCounted

## Approved directed combat geometry. Catalogs select these recipes; this owner
## defines layered presentation meshes without changing gameplay collision truth.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorRecipes = preload(
	"res://scripts/presentation/components/vehicle_actor_mesh_recipes.gd"
)
const Components = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)

const PROJECTILE_RECIPES: Array[StringName] = [
	&"player_primary_capsule",
	&"player_breach_split_capsule",
	&"player_seeker_capsule",
	&"hostile_kinetic_capsule",
	&"hostile_thermal_capsule",
	&"hostile_toxin_capsule",
	&"hostile_cryo_capsule",
	&"hostile_arc_capsule",
	&"hostile_hybrid_capsule",
]

const EFFECT_RECIPES: Array[StringName] = [
	&"dash_player_hull_afterimage",
]

const TAIL_MIN_X := -6.5
const TAIL_MAX_X := -0.58


static func has_projectile_recipe(recipe_id: StringName) -> bool:
	return recipe_id in PROJECTILE_RECIPES


static func has_effect_recipe(recipe_id: StringName) -> bool:
	return recipe_id in EFFECT_RECIPES


static func projectile_head_layers(
	recipe_id: StringName,
	semantic_color: Color = Color.WHITE
) -> Array[Dictionary]:
	var outer := projectile_head_signature(recipe_id)
	if outer.is_empty():
		return []
	var layers: Array[Dictionary] = [
		_layer(outer, Art.INK, &"perimeter"),
		_layer(
			Components.scaled_points(outer, Vector2(0.84, 0.84)),
			semantic_color,
			&"semantic_main"
		),
	]
	var secondary_color := semantic_color.lerp(Art.INK_MUTED, 0.46)
	for points in _head_secondary_parts(recipe_id):
		layers.append(_layer(points, secondary_color, &"secondary_mass"))
	for points in _head_highlight_parts(recipe_id):
		layers.append(
			_layer(
				points,
				semantic_color.lerp(Art.IVORY_BRIGHT, 0.78),
				&"hard_highlight"
			)
		)
	return layers


static func projectile_tail_layers(
	recipe_id: StringName,
	normalized_for_player_batch: bool = false
) -> Array[Dictionary]:
	if not has_projectile_recipe(recipe_id):
		return []
	var outer_parts := _tail_outer_parts(recipe_id)
	var layers: Array[Dictionary] = []
	for raw_points in outer_parts:
		var points := PackedVector2Array(raw_points)
		if normalized_for_player_batch:
			points = _normalized_tail_points(points)
		layers.append(_layer(points, Color(Art.INK, 0.82), &"perimeter"))
		layers.append(
			_layer(
				Components.scaled_points(points, Vector2(0.96, 0.62)),
				Color(1.0, 1.0, 1.0, 0.64),
				&"semantic_main"
			)
		)
		layers.append(
			_layer(
				Components.scaled_points(points, Vector2(0.88, 0.20)),
				Color(1.0, 1.0, 1.0, 0.92),
				&"hard_highlight"
			)
		)
	return layers


static func projectile_layers(
	recipe_id: StringName,
	semantic_color: Color = Color.WHITE
) -> Array[Dictionary]:
	var layers := projectile_tail_layers(recipe_id)
	layers.append_array(projectile_head_layers(recipe_id, semantic_color))
	return layers


static func player_trail_layers(recipe_id: StringName) -> Array[Dictionary]:
	return projectile_tail_layers(recipe_id, true)


static func projectile_head_signature(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"player_primary_capsule", &"hostile_kinetic_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.72, -0.40),
				Vector2(0.20, -0.56),
				Vector2(-0.54, -0.52),
				Vector2(-0.90, -0.28),
				Vector2(-1.00, 0.00),
				Vector2(-0.90, 0.28),
				Vector2(-0.54, 0.52),
				Vector2(0.20, 0.56),
				Vector2(0.72, 0.40),
			])
		&"player_breach_split_capsule", &"hostile_hybrid_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.62, -0.44),
				Vector2(0.04, -0.66),
				Vector2(-0.42, -0.52),
				Vector2(-0.90, -0.20),
				Vector2(-0.64, 0.00),
				Vector2(-0.90, 0.20),
				Vector2(-0.42, 0.52),
				Vector2(0.04, 0.66),
				Vector2(0.62, 0.44),
			])
		&"player_seeker_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.50, -0.52),
				Vector2(-0.24, -0.62),
				Vector2(-0.70, -0.34),
				Vector2(-0.96, 0.00),
				Vector2(-0.70, 0.34),
				Vector2(-0.24, 0.62),
				Vector2(0.50, 0.52),
			])
		&"hostile_thermal_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.58, -0.34),
				Vector2(0.30, -0.74),
				Vector2(-0.04, -0.58),
				Vector2(-0.34, -0.90),
				Vector2(-0.62, -0.52),
				Vector2(-0.94, 0.00),
				Vector2(-0.62, 0.52),
				Vector2(-0.34, 0.90),
				Vector2(-0.04, 0.58),
				Vector2(0.30, 0.74),
				Vector2(0.58, 0.34),
			])
		&"hostile_toxin_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.58, -0.42),
				Vector2(0.08, -0.68),
				Vector2(-0.42, -0.60),
				Vector2(-0.78, -0.34),
				Vector2(-0.96, 0.00),
				Vector2(-0.72, 0.42),
				Vector2(-0.34, 0.76),
				Vector2(0.24, 0.64),
				Vector2(0.66, 0.30),
			])
		&"hostile_cryo_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.44, -0.28),
				Vector2(0.05, -0.64),
				Vector2(-0.50, -0.40),
				Vector2(-1.00, 0.00),
				Vector2(-0.50, 0.40),
				Vector2(0.05, 0.64),
				Vector2(0.44, 0.28),
			])
		&"hostile_arc_capsule":
			return PackedVector2Array([
				Vector2(1.00, 0.00),
				Vector2(0.64, -0.22),
				Vector2(0.36, -0.60),
				Vector2(0.04, -0.34),
				Vector2(-0.20, -0.78),
				Vector2(-0.46, -0.36),
				Vector2(-0.94, -0.08),
				Vector2(-0.62, 0.16),
				Vector2(-0.82, 0.54),
				Vector2(-0.22, 0.40),
				Vector2(0.10, 0.72),
				Vector2(0.42, 0.32),
			])
	return PackedVector2Array()


static func effect_layers(recipe_id: StringName) -> Array[Dictionary]:
	if recipe_id != &"dash_player_hull_afterimage":
		return []
	var outer := effect_signature(recipe_id)
	return [
		_layer(outer, Art.INK, &"perimeter"),
		_layer(
			Components.scaled_points(outer, Vector2(0.91, 0.88)),
			Color(1.0, 1.0, 1.0, 0.78),
			&"semantic_main"
		),
		_layer(
			PackedVector2Array([
				Vector2(0.64, -0.10),
				Vector2(0.08, -0.24),
				Vector2(-0.48, -0.20),
				Vector2(-0.24, 0.00),
				Vector2(-0.48, 0.20),
				Vector2(0.08, 0.24),
				Vector2(0.64, 0.10),
				Vector2(0.34, 0.00),
			]),
			Color(0.62, 0.68, 0.74, 0.72),
			&"secondary_mass"
		),
		_layer(
			PackedVector2Array([
				Vector2(0.92, 0.00),
				Vector2(0.42, -0.055),
				Vector2(-0.46, -0.045),
				Vector2(-0.68, 0.00),
				Vector2(-0.46, 0.045),
				Vector2(0.42, 0.055),
			]),
			Color(1.0, 1.0, 1.0, 0.92),
			&"hard_highlight"
		),
	]


static func effect_signature(recipe_id: StringName) -> PackedVector2Array:
	if recipe_id != &"dash_player_hull_afterimage":
		return PackedVector2Array()
	var result := PackedVector2Array()
	for point in ActorRecipes.player_signature():
		result.append(point * Vector2(1.12, 0.72))
	return result


static func plane_count(layers: Array[Dictionary]) -> int:
	var planes := {}
	for layer in layers:
		planes[StringName(layer.get("plane", &""))] = true
	planes.erase(&"")
	return planes.size()


static func _tail_outer_parts(recipe_id: StringName) -> Array:
	match recipe_id:
		&"player_breach_split_capsule":
			return [
				_tail_rail(-0.24, 0.16),
				_tail_rail(0.24, 0.16),
			]
		&"player_seeker_capsule":
			return [PackedVector2Array([
				Vector2(TAIL_MIN_X, 0.00),
				Vector2(-5.92, -0.28),
				Vector2(-0.72, -0.22),
				Vector2(TAIL_MAX_X, 0.00),
				Vector2(-0.72, 0.22),
				Vector2(-5.92, 0.28),
			])]
		&"hostile_thermal_capsule":
			return [PackedVector2Array([
				Vector2(TAIL_MIN_X, 0.00),
				Vector2(-5.82, -0.48),
				Vector2(-0.72, -0.20),
				Vector2(TAIL_MAX_X, 0.00),
				Vector2(-0.72, 0.20),
				Vector2(-5.82, 0.48),
			])]
		&"hostile_toxin_capsule":
			return [
				_tail_rail(0.0, 0.10),
				_tail_bead(-5.55, 0.34),
				_tail_bead(-3.55, 0.40),
				_tail_bead(-1.55, 0.30),
			]
		&"hostile_cryo_capsule":
			return [
				_tail_rail(-0.26, 0.13),
				_tail_rail(0.26, 0.13),
			]
		&"hostile_arc_capsule":
			return [PackedVector2Array([
				Vector2(TAIL_MIN_X, -0.16),
				Vector2(-5.34, -0.48),
				Vector2(-4.26, 0.08),
				Vector2(-3.08, -0.43),
				Vector2(-1.92, 0.14),
				Vector2(-0.72, -0.16),
				Vector2(TAIL_MAX_X, 0.02),
				Vector2(-1.92, 0.46),
				Vector2(-3.08, -0.09),
				Vector2(-4.26, 0.40),
				Vector2(-5.34, -0.18),
			])]
		&"hostile_hybrid_capsule":
			return [
				PackedVector2Array([
					Vector2(TAIL_MIN_X, -0.08),
					Vector2(-5.72, -0.42),
					Vector2(-0.72, -0.24),
					Vector2(TAIL_MAX_X, -0.08),
					Vector2(-0.84, 0.02),
					Vector2(-5.70, -0.12),
				]),
				PackedVector2Array([
					Vector2(TAIL_MIN_X, 0.08),
					Vector2(-5.70, 0.12),
					Vector2(-0.84, -0.02),
					Vector2(TAIL_MAX_X, 0.08),
					Vector2(-0.72, 0.24),
					Vector2(-5.72, 0.42),
				]),
			]
		_:
			return [_tail_rail(0.0, 0.30)]


static func _head_secondary_parts(recipe_id: StringName) -> Array:
	match recipe_id:
		&"hostile_thermal_capsule":
			return [PackedVector2Array([
				Vector2(0.50, 0.00),
				Vector2(0.02, -0.46),
				Vector2(-0.36, -0.24),
				Vector2(-0.16, 0.00),
				Vector2(-0.36, 0.24),
				Vector2(0.02, 0.46),
			])]
		&"hostile_toxin_capsule":
			return [PackedVector2Array([
				Vector2(0.42, -0.08),
				Vector2(0.06, -0.42),
				Vector2(-0.42, -0.22),
				Vector2(-0.56, 0.08),
				Vector2(-0.18, 0.44),
				Vector2(0.30, 0.30),
			])]
		&"hostile_cryo_capsule":
			return [
				PackedVector2Array([
					Vector2(0.54, -0.06),
					Vector2(-0.34, -0.34),
					Vector2(-0.56, -0.12),
					Vector2(0.20, 0.00),
				]),
				PackedVector2Array([
					Vector2(0.54, 0.06),
					Vector2(0.20, 0.00),
					Vector2(-0.56, 0.12),
					Vector2(-0.34, 0.34),
				]),
			]
		&"hostile_arc_capsule":
			return [PackedVector2Array([
				Vector2(0.58, -0.12),
				Vector2(0.12, -0.28),
				Vector2(0.28, 0.00),
				Vector2(-0.36, -0.06),
				Vector2(-0.02, 0.34),
				Vector2(-0.52, 0.20),
				Vector2(-0.20, 0.48),
				Vector2(0.22, 0.18),
			])]
		&"player_breach_split_capsule", &"hostile_hybrid_capsule":
			return [
				PackedVector2Array([
					Vector2(0.54, -0.10),
					Vector2(0.06, -0.42),
					Vector2(-0.52, -0.20),
					Vector2(-0.10, -0.02),
				]),
				PackedVector2Array([
					Vector2(0.54, 0.10),
					Vector2(-0.10, 0.02),
					Vector2(-0.52, 0.20),
					Vector2(0.06, 0.42),
				]),
			]
		&"player_seeker_capsule":
			return [PackedVector2Array([
				Vector2(0.58, 0.00),
				Vector2(-0.10, -0.36),
				Vector2(-0.48, 0.00),
				Vector2(-0.10, 0.36),
			])]
		_:
			return [PackedVector2Array([
				Vector2(0.58, -0.16),
				Vector2(-0.38, -0.24),
				Vector2(-0.56, 0.00),
				Vector2(-0.38, 0.24),
				Vector2(0.58, 0.16),
			])]


static func _head_highlight_parts(recipe_id: StringName) -> Array:
	var vertical_offset := 0.0
	if recipe_id == &"hostile_toxin_capsule":
		vertical_offset = -0.08
	elif recipe_id == &"hostile_arc_capsule":
		vertical_offset = 0.07
	return [PackedVector2Array([
		Vector2(0.76, vertical_offset),
		Vector2(0.36, vertical_offset - 0.07),
		Vector2(-0.34, vertical_offset - 0.055),
		Vector2(-0.52, vertical_offset),
		Vector2(-0.34, vertical_offset + 0.055),
		Vector2(0.36, vertical_offset + 0.07),
	])]


static func _tail_rail(center_y: float, half_height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(TAIL_MIN_X, center_y),
		Vector2(-6.10, center_y - half_height),
		Vector2(-0.72, center_y - half_height * 0.82),
		Vector2(TAIL_MAX_X, center_y),
		Vector2(-0.72, center_y + half_height * 0.82),
		Vector2(-6.10, center_y + half_height),
	])


static func _tail_bead(center_x: float, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(center_x - radius, 0.0),
		Vector2(center_x, -radius),
		Vector2(center_x + radius, 0.0),
		Vector2(center_x, radius),
	])


static func _normalized_tail_points(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(
			Vector2(
				lerpf(
					-0.5,
					0.5,
					inverse_lerp(TAIL_MIN_X, TAIL_MAX_X, point.x)
				),
				point.y
			)
		)
	return result


static func _layer(
	points: PackedVector2Array,
	color: Color,
	plane: StringName
) -> Dictionary:
	return {"points": points, "color": color, "plane": plane}
