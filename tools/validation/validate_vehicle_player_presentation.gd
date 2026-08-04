extends SceneTree

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorCatalog = preload("res://scripts/presentation/components/vehicle_actor_visual_catalog.gd")
const ActorRecipes = preload("res://scripts/presentation/components/vehicle_actor_mesh_recipes.gd")
const ProjectileCatalog = preload("res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd")
const EffectCatalog = preload("res://scripts/presentation/components/vehicle_effect_visual_catalog.gd")
const ProjectileEffectRecipes = preload(
	"res://scripts/presentation/components/vehicle_projectile_effect_mesh_recipes.gd"
)
const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Run = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: PackedStringArray = []


func _initialize() -> void:
	var player := ActorCatalog.descriptor(&"player")
	_expect(not player.is_empty(), "player descriptor exists")
	_expect(
		Array(player.get("rear_anchors", [])).size() == 1,
		"player descriptor owns one rear anchor for transient dash feedback"
	)
	var rear_anchors := Array(player.get("rear_anchors", []))
	_expect(
		Vector2(rear_anchors[0]).x < 0.0
			and is_zero_approx(Vector2(rear_anchors[0]).y),
		"player recipe keeps the dash anchor centered on the rear plane"
	)
	var player_components := Dictionary(player.get("components", {}))
	_expect(
		player_components.size() == 2
			and player_components.has(&"body")
			and player_components.has(&"engine_flare"),
		"player recipe exposes one fixed body and one transient flare"
	)
	for component_id in [&"body", &"engine_flare"]:
		var recipe_id := StringName(player_components.get(component_id, &""))
		_expect(
			recipe_id in ActorRecipes.PLAYER_COMPONENT_RECIPES
				and not ActorRecipes.player_component_layers(recipe_id).is_empty(),
			"player %s resolves through the actor recipe owner" % component_id
		)
	_expect(
		ActorRecipes.plane_count(
			ActorRecipes.player_component_layers(
				StringName(player_components.get(&"body", &""))
			)
		) == 5,
		"player craft fallback keeps the approved five-plane mechanical hierarchy"
	)
	for degrees in range(0, 360, 5):
		var angle := deg_to_rad(float(degrees))
		var direction := Vector2.RIGHT.rotated(angle)
		var origin := Vector2(940.0, 520.0)
		var anchors := Renderer.player_rear_anchors(origin, direction)
		for anchor_index in anchors.size():
			var local_anchor := (anchors[anchor_index] - origin).rotated(-angle)
			var expected := (
				Vector2(Array(player["rear_anchors"])[anchor_index])
					* Art.PLAYER_VISUAL_RADIUS
			)
			_expect(
				local_anchor.distance_to(expected) <= 1.0,
				"rear anchor %d stays rigid at %d degrees"
				% [anchor_index, degrees]
			)
	for mesh in [
		Visuals.player_craft_body_mesh(),
		Visuals.player_engine_flare_mesh(),
	]:
		_expect(mesh.get_surface_count() == 1, "player component mesh has one retained surface")
	var projectile_ids := ProjectileCatalog.descriptor_ids()
	var projectile_descriptor := ProjectileCatalog.descriptor(
		ProjectileCatalog.SHARED_VISUAL_ID
	)
	_expect(
		projectile_ids == [ProjectileCatalog.SHARED_VISUAL_ID]
			and StringName(projectile_descriptor.get("asset", &""))
				== &"projectile/energy_teardrop",
		"all non-beam projectiles share one authored energy-teardrop asset"
	)
	_expect(
		bool(projectile_descriptor.get("collision_centered", false))
			and not bool(projectile_descriptor.get("tail", true))
			and bool(projectile_descriptor.get("runtime_tint", false))
			and bool(projectile_descriptor.get("runtime_scale", false)),
		"shared projectile keeps collision-centered runtime tint and scale ownership"
	)
	_expect(
		ProjectileCatalog.descriptor(&"kinetic").is_empty(),
		"legacy affinity projectile identities are not catalog fallbacks"
	)
	var dash := EffectCatalog.descriptor(&"dash_afterimage")
	_expect(not bool(dash.get("radial", true)), "dash afterimage is not radial")
	_expect(
		EffectCatalog.descriptor_ids() == [&"dash_afterimage"],
		"geometry catalog exposes no duplicate runtime feedback semantics"
	)
	var dash_recipe_id := StringName(dash.get("recipe", &""))
	var dash_layers := ProjectileEffectRecipes.effect_layers(dash_recipe_id)
	var dash_signature := ProjectileEffectRecipes.effect_signature(
		dash_recipe_id
	)
	var dash_bounds := _point_bounds(dash_signature)
	_expect(
		ProjectileEffectRecipes.has_effect_recipe(dash_recipe_id)
			and ProjectileEffectRecipes.plane_count(dash_layers) >= 3
			and ProjectileEffectRecipes.plane_count(dash_layers) <= 5,
		"dash afterimage resolves to a layered effect recipe"
	)
	_expect(
		_layers_triangulate(dash_layers),
		"dash afterimage layered hull triangulates cleanly"
	)
	_expect(
		dash_signature.size() == ActorRecipes.player_signature().size()
			and dash_signature.size() > 3
			and dash_bounds.size.x > dash_bounds.size.y * 1.5,
		"dash afterimage is an elongated player-hull silhouette, not a triangle"
	)
	_expect(
		Visuals.effect_mesh(&"afterimage").get_surface_count() == 1
			and _mesh_vertex_count(Visuals.effect_mesh(&"afterimage"))
				== _layer_vertex_count(dash_layers),
		"dash afterimage catalog recipe is consumed by its runtime batch mesh"
	)
	var beam_bounds := Visuals.effect_mesh(&"beam").get_aabb()
	_expect(
		Vector2(beam_bounds.position.x, beam_bounds.position.y)
			.is_equal_approx(Vector2(-1.0, -0.16))
			and Vector2(beam_bounds.size.x, beam_bounds.size.y)
				.is_equal_approx(Vector2(2.0, 0.32)),
		"utility beam keeps its exact overlay footprint"
	)
	_expect(
		_mesh_vertex_count(Visuals.effect_mesh(&"diamond")) == 4
			and is_equal_approx(
				_mesh_max_radius(Visuals.effect_mesh(&"diamond")),
				1.0
			),
		"utility diamond keeps four vertices at unit radius"
	)
	_expect(
		_mesh_vertex_count(Visuals.effect_mesh(&"ring")) == 128
			and is_equal_approx(
				_mesh_max_radius(Visuals.effect_mesh(&"ring")),
				1.0
			),
		"utility ring keeps 32 segments and unit outer radius"
	)
	_expect(Run.MAX_DASH_AFTERIMAGES <= 5, "dash afterimage cap is at most five")
	var run := Run.new()
	run._grant_player_protection(0.28, &"dash")
	run._grant_player_protection(1.0, &"hit")
	_expect(
		is_equal_approx(run.player_invulnerable, 1.0),
		"overlapping source cues preserve the existing maximum invulnerability window"
	)
	run._advance_player_protection_sources(0.30)
	_expect(
		not run.player_protection_sources.has(&"dash")
		and is_equal_approx(float(run.player_protection_sources.get(&"hit", 0.0)), 0.70),
		"source cues expire independently"
	)
	var renderer_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	_expect(
		not renderer_source.contains(
			"_write_ring(player_position, Art.PLAYER_VISUAL_RADIUS"
		),
		"generic invulnerability no longer draws a player danger ring"
	)
	for legacy_token in [
		"attachment/player_hull",
		"attachment/player_engine",
		"attachment/player_aim_mount",
		"Player_hull",
		"Player_engine",
		"Player_primary_mount",
	]:
		_expect(
			not renderer_source.contains(legacy_token),
			"renderer omits legacy fixed player part: %s" % legacy_token
		)
	run.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _layer_vertex_count(layers: Array[Dictionary]) -> int:
	var count := 0
	for layer in layers:
		count += PackedVector2Array(
			layer.get("points", PackedVector2Array())
		).size()
	return count


func _layers_triangulate(layers: Array[Dictionary]) -> bool:
	for layer in layers:
		var points := PackedVector2Array(
			layer.get("points", PackedVector2Array())
		)
		if points.size() < 3 or Geometry2D.triangulate_polygon(points).is_empty():
			return false
	return true


func _mesh_vertex_count(mesh: ArrayMesh) -> int:
	if mesh.get_surface_count() != 1:
		return 0
	var arrays := mesh.surface_get_arrays(0)
	return PackedVector3Array(arrays[Mesh.ARRAY_VERTEX]).size()


func _mesh_max_radius(mesh: ArrayMesh) -> float:
	if mesh.get_surface_count() != 1:
		return 0.0
	var maximum := 0.0
	var arrays := mesh.surface_get_arrays(0)
	for vertex in PackedVector3Array(arrays[Mesh.ARRAY_VERTEX]):
		maximum = maxf(maximum, Vector2(vertex.x, vertex.y).length())
	return maximum


func _minimum_layer_x(layers: Array[Dictionary]) -> float:
	var minimum := INF
	for layer in layers:
		for point in PackedVector2Array(
			layer.get("points", PackedVector2Array())
		):
			minimum = minf(minimum, point.x)
	return minimum


func _point_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PLAYER_PRESENTATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
