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
		Array(player.get("rear_sockets", [])).size() == 1,
		"player descriptor owns one rigid centered rear engine socket"
	)
	var rear_sockets := Array(player.get("rear_sockets", []))
	_expect(
		Vector2(rear_sockets[0]).x < 0.0
			and is_zero_approx(Vector2(rear_sockets[0]).y),
		"player recipe keeps the engine centered on the rear plane"
	)
	var player_components := Dictionary(player.get("components", {}))
	for component_id in [&"hull", &"engine", &"engine_flare", &"aim_mount"]:
		var recipe_id := StringName(player_components.get(component_id, &""))
		_expect(
			recipe_id in ActorRecipes.PLAYER_COMPONENT_RECIPES
				and not ActorRecipes.player_component_layers(recipe_id).is_empty(),
			"player %s resolves through the actor recipe owner" % component_id
		)
	_expect(
		ActorRecipes.plane_count(
			ActorRecipes.player_component_layers(
				StringName(player_components.get(&"hull", &""))
			)
		) == 5,
		"player hull keeps the approved five-plane mechanical hierarchy"
	)
	for degrees in range(0, 360, 5):
		var angle := deg_to_rad(float(degrees))
		var direction := Vector2.RIGHT.rotated(angle)
		var origin := Vector2(940.0, 520.0)
		var sockets := Renderer.player_engine_sockets(origin, direction)
		for socket_index in sockets.size():
			var local_socket := (sockets[socket_index] - origin).rotated(-angle)
			var expected := (
				Vector2(Array(player["rear_sockets"])[socket_index])
				* Art.PLAYER_VISUAL_RADIUS
			)
			_expect(
				local_socket.distance_to(expected) <= 1.0,
				"engine socket %d stays rigid at %d degrees"
				% [socket_index, degrees]
			)
	for mesh in [
		Visuals.player_hull_mesh(),
		Visuals.player_engine_mesh(),
		Visuals.player_engine_flare_mesh(),
		Visuals.player_primary_mesh(),
	]:
		_expect(mesh.get_surface_count() == 1, "player component mesh has one retained surface")
	for visual_id in ProjectileCatalog.descriptor_ids():
		var projectile_descriptor := ProjectileCatalog.descriptor(visual_id)
		var projectile_recipe_id := StringName(
			projectile_descriptor.get("recipe", &"")
		)
		var head_layers := ProjectileEffectRecipes.projectile_head_layers(
			projectile_recipe_id
		)
		_expect(
			ProjectileEffectRecipes.has_projectile_recipe(projectile_recipe_id)
				and not head_layers.is_empty(),
			"projectile %s resolves through the recipe owner" % visual_id
		)
		_expect(
			_layers_triangulate(head_layers),
			"projectile %s head layers triangulate cleanly" % visual_id
		)
		_expect(
			_mesh_vertex_count(Visuals.projectile_head_mesh(visual_id))
				== _layer_vertex_count(head_layers),
			"projectile %s catalog recipe is consumed by the runtime provider"
			% visual_id
		)
	var hostile_signatures: Array[PackedVector2Array] = []
	for affinity in [&"kinetic", &"thermal", &"toxin", &"cryo", &"arc", &"hybrid"]:
		var descriptor := ProjectileCatalog.descriptor(affinity)
		var recipe_id := StringName(descriptor.get("recipe", &""))
		var signature := ProjectileEffectRecipes.projectile_head_signature(
			recipe_id
		)
		var full_layers := ProjectileEffectRecipes.projectile_layers(recipe_id)
		_expect(
			not descriptor.is_empty(),
			"projectile descriptor exists for %s" % affinity
		)
		_expect(
			absf(Visuals.debug_projectile_head_extent(affinity) - 1.0) <= 0.001,
			"projectile head exactly fills its collision-normalized extent for %s"
			% affinity
		)
		for existing_signature in hostile_signatures:
			_expect(
				signature != existing_signature,
				"hostile projectile %s keeps a shape-distinct affinity silhouette"
				% affinity
			)
		hostile_signatures.append(signature)
		_expect(
			ProjectileEffectRecipes.plane_count(full_layers) >= 3
				and ProjectileEffectRecipes.plane_count(full_layers) <= 5,
			"hostile projectile %s keeps three to five readable planes" % affinity
		)
		_expect(
			_layers_triangulate(full_layers),
			"hostile projectile %s layered geometry triangulates cleanly"
			% affinity
		)
		_expect(
			_minimum_layer_x(full_layers) <= -6.49,
			"hostile projectile %s keeps the approved long-tail extent" % affinity
		)
		var hostile_mesh := Visuals.hostile_projectile_envelope_mesh(affinity)
		_expect(
			hostile_mesh.get_surface_count() == 1
				and _mesh_vertex_count(hostile_mesh)
					== _layer_vertex_count(full_layers),
			"hostile projectile %s recipe is one runtime batch surface"
			% affinity
		)
	var primary_recipe_id := StringName(
		ProjectileCatalog.descriptor(&"player_primary").get("recipe", &"")
	)
	_expect(
		_mesh_vertex_count(Visuals.player_projectile_head_mesh())
			== _layer_vertex_count(
				ProjectileEffectRecipes.projectile_head_layers(
					primary_recipe_id,
					Art.MUSTARD
				)
			),
		"player projectile head consumes the primary capsule recipe"
	)
	_expect(
		Visuals.projectile_trail_mesh(&"kinetic").get_surface_count() == 1
			and _mesh_vertex_count(Visuals.projectile_trail_mesh(&"kinetic"))
				== _layer_vertex_count(
					ProjectileEffectRecipes.player_trail_layers(
						primary_recipe_id
					)
				),
		"player projectile trail consumes the normalized long-tail recipe"
	)
	var dash := EffectCatalog.descriptor(&"dash_afterimage")
	var flare := EffectCatalog.descriptor(&"dash_engine_flare")
	_expect(not bool(dash.get("radial", true)), "dash afterimage is not radial")
	_expect(not bool(flare.get("radial", true)), "dash engine flare is not radial")
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
