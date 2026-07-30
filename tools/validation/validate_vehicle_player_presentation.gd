extends SceneTree

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorCatalog = preload("res://scripts/presentation/components/vehicle_actor_visual_catalog.gd")
const ProjectileCatalog = preload("res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd")
const EffectCatalog = preload("res://scripts/presentation/components/vehicle_effect_visual_catalog.gd")
const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Run = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: PackedStringArray = []


func _initialize() -> void:
	var player := ActorCatalog.descriptor(&"player")
	_expect(not player.is_empty(), "player descriptor exists")
	_expect(
		Array(player.get("rear_sockets", [])).size() == 2,
		"player descriptor owns two rigid rear engine sockets"
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
	for affinity in [&"kinetic", &"thermal", &"toxin", &"cryo", &"arc", &"hybrid"]:
		_expect(
			not ProjectileCatalog.descriptor(affinity).is_empty(),
			"projectile descriptor exists for %s" % affinity
		)
		_expect(
			Visuals.debug_projectile_head_extent(affinity) <= 1.01,
			"projectile core stays inside collision-normalized extent for %s" % affinity
		)
	var dash := EffectCatalog.descriptor(&"dash_afterimage")
	var flare := EffectCatalog.descriptor(&"dash_engine_flare")
	_expect(not bool(dash.get("radial", true)), "dash afterimage is not radial")
	_expect(not bool(flare.get("radial", true)), "dash engine flare is not radial")
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
	for retired_family in [
		"player_chassis",
		"player_engine_flame",
		"player_engine_modules",
		"player_dash_effect",
		"player_primary_projectiles",
		"hostile_projectile_affinities",
		"experience_shards",
	]:
		_expect(
			not renderer_source.contains(retired_family),
			"migrated combat family has no pixel fallback: %s" % retired_family
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


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PLAYER_PRESENTATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
