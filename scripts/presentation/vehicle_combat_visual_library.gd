class_name VehicleCombatVisualLibrary
extends RefCounted

## Prebuilt flat-color geometry for high-count combat families. Runtime
## presentation changes transforms and instance colors, never polygon vertices.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const ActorCatalog = preload("res://scripts/presentation/components/vehicle_actor_visual_catalog.gd")
const ActorRecipes = preload("res://scripts/presentation/components/vehicle_actor_mesh_recipes.gd")
const ProjectileCatalog = preload("res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd")
const ProjectileEffectRecipes = preload(
	"res://scripts/presentation/components/vehicle_projectile_effect_mesh_recipes.gd"
)
const RewardCatalog = preload("res://scripts/presentation/components/vehicle_reward_visual_catalog.gd")
const EffectCatalog = preload("res://scripts/presentation/components/vehicle_effect_visual_catalog.gd")
const Components = preload("res://scripts/presentation/components/vehicle_component_mesh_library.gd")

const ENEMY_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser",
	&"shooter", &"controller", &"turret", &"mine", &"generator",
	&"shield_escort", &"artillery_spotter", &"interceptor_tower",
	&"rammer", &"bulkhead_guard", &"splitter_barge",
	&"repair_tender", &"drone_carrier", &"beam_sentinel",
	&"boss_pylon", &"stage_boss",
]


static func enemy_mesh(archetype: StringName) -> ArrayMesh:
	var descriptor := ActorCatalog.descriptor(archetype)
	var recipe_id := StringName(descriptor.get("recipe", &""))
	var grammar_id := StringName(descriptor.get("grammar", &""))
	return Components.polygon_mesh(
		StringName("actor_enemy_%s" % String(recipe_id)),
		ActorRecipes.enemy_layers(recipe_id, grammar_id)
	)


static func boss_mesh(variant: StringName) -> ArrayMesh:
	var recipe_id := StringName(
		ActorCatalog.descriptor(variant).get("recipe", &"")
	)
	return Components.polygon_mesh(
		StringName("actor_boss_%s" % String(recipe_id)),
		ActorRecipes.boss_layers(recipe_id)
	)


static func debug_boss_signature(variant: StringName) -> PackedVector2Array:
	var recipe_id := StringName(
		ActorCatalog.descriptor(variant).get("recipe", &"")
	)
	return ActorRecipes.boss_signature(recipe_id)


static func boss_module_mesh(
	module_kind: StringName,
	state: StringName = &"active"
) -> ArrayMesh:
	var recipe_id := StringName(
		ActorCatalog.descriptor(module_kind).get("recipe", &"")
	)
	return Components.polygon_mesh(
		StringName(
			"actor_boss_module_%s_%s"
			% [String(recipe_id), String(state)]
		),
		ActorRecipes.boss_module_layers(recipe_id, state)
	)


static func projectile_head_mesh(
	affinity: StringName = AttackContract.KINETIC
) -> ArrayMesh:
	var recipe_id := _projectile_recipe_id(affinity)
	return Components.polygon_mesh(
		StringName("projectile_head_%s" % String(recipe_id)),
		ProjectileEffectRecipes.projectile_head_layers(recipe_id)
	)


static func hostile_projectile_mesh(affinity: StringName) -> ArrayMesh:
	var recipe_id := _projectile_recipe_id(affinity)
	return Components.polygon_mesh(
		StringName("projectile_hostile_%s" % String(recipe_id)),
		ProjectileEffectRecipes.projectile_layers(recipe_id)
	)


static func player_projectile_head_mesh() -> ArrayMesh:
	var recipe_id := _projectile_recipe_id(&"player_primary")
	return Components.polygon_mesh(
		StringName("projectile_player_head_%s" % String(recipe_id)),
		ProjectileEffectRecipes.projectile_head_layers(recipe_id, Art.MUSTARD)
	)


static func hostile_projectile_core_mesh() -> ArrayMesh:
	return polygon_mesh([
		{
			"points":_regular_polygon(Vector2.ZERO, 1.0, 20),
			"color":Art.INK,
		},
		{
			"points":_regular_polygon(Vector2.ZERO, 0.68, 16),
			"color":Art.IVORY_BRIGHT,
		},
	])


static func hostile_projectile_envelope_mesh(affinity: StringName) -> ArrayMesh:
	return hostile_projectile_mesh(affinity)


static func projectile_trail_mesh(_affinity: StringName) -> ArrayMesh:
	var recipe_id := _projectile_recipe_id(&"player_primary")
	return Components.polygon_mesh(
		StringName("projectile_player_trail_%s" % String(recipe_id)),
		ProjectileEffectRecipes.player_trail_layers(recipe_id)
	)


static func debug_projectile_head_extent(affinity: StringName) -> float:
	var extent := 0.0
	for point in ProjectileEffectRecipes.projectile_head_signature(
		_projectile_recipe_id(affinity)
	):
		extent = maxf(extent, point.length())
	return extent


static func _projectile_recipe_id(visual_id: StringName) -> StringName:
	var descriptor := ProjectileCatalog.descriptor(visual_id)
	if descriptor.is_empty():
		var normalized := AttackContract.normalize_affinity(visual_id)
		descriptor = ProjectileCatalog.descriptor(
			&"seeker" if normalized == AttackContract.SUPPORT else normalized
		)
	return StringName(descriptor.get("recipe", &""))


static func debug_enemy_signature(archetype: StringName) -> PackedVector2Array:
	var descriptor := ActorCatalog.descriptor(archetype)
	return ActorRecipes.enemy_signature(
		StringName(descriptor.get("recipe", &""))
	)


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


static func support_timer_segment_mesh() -> ArrayMesh:
	var half_sweep := deg_to_rad(6.5)
	var inner_radius := 0.80
	return polygon_mesh([{
		"points":PackedVector2Array([
			Vector2.RIGHT.rotated(-half_sweep),
			Vector2.RIGHT.rotated(half_sweep),
			Vector2.RIGHT.rotated(half_sweep) * inner_radius,
			Vector2.RIGHT.rotated(-half_sweep) * inner_radius,
		]),
		"color":Color.WHITE,
	}])


static func _player_component_mesh(component_id: StringName) -> ArrayMesh:
	var recipe_id := ActorCatalog.player_component_recipe(component_id)
	return Components.polygon_mesh(
		StringName("actor_player_%s" % String(recipe_id)),
		ActorRecipes.player_component_layers(recipe_id)
	)


static func player_hull_mesh() -> ArrayMesh:
	return _player_component_mesh(&"hull")


static func player_primary_mesh() -> ArrayMesh:
	return _player_component_mesh(&"aim_mount")


static func player_engine_mesh() -> ArrayMesh:
	return _player_component_mesh(&"engine")


static func player_engine_flare_mesh() -> ArrayMesh:
	return _player_component_mesh(&"engine_flare")


static func player_secondary_core_mesh() -> ArrayMesh:
	return polygon_mesh([
		{"points":_regular_polygon(Vector2.ZERO, 1.0, 16), "color":Color.WHITE},
		{"points":_regular_polygon(Vector2.ZERO, 0.46, 12), "color":Art.IVORY_BRIGHT},
	])


static func player_mesh() -> ArrayMesh:
	return player_hull_mesh()


static func experience_mesh(kind: StringName) -> ArrayMesh:
	var _descriptor := RewardCatalog.descriptor(
		StringName("experience_%s" % String(kind))
	)
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
			var recipe_id := StringName(
				EffectCatalog.descriptor(&"dash_afterimage").get(
					"recipe",
					&""
				)
			)
			return Components.polygon_mesh(
				StringName("effect_%s" % String(recipe_id)),
				ProjectileEffectRecipes.effect_layers(recipe_id)
			)
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
		&"chaser", &"shooter", &"mine", &"artillery_spotter", &"rammer":
			return Art.DANGER
		&"turret", &"interceptor_tower", &"beam_sentinel":
			return Art.CORAL_DARK
		&"generator", &"shield_escort", &"repair_tender":
			return Art.SUPPORT
		&"controller", &"drone_carrier", &"stage_boss", &"boss_pylon":
			return Art.BOSS_COMMAND
	return Art.DANGER


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
