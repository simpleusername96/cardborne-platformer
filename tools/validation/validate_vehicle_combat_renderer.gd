extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer := Renderer.new()
	root.add_child(renderer)
	await process_frame
	var snapshot: Dictionary = renderer.debug_snapshot()
	_expect(int(snapshot["enemy_capacity"]) == 320, "renderer shares the 320-hostile store capacity")
	_expect(
		int(snapshot["batches"]) <= 50,
		"combat presentation remains inside the retained fifty-batch ceiling (actual %d)"
		% int(snapshot["batches"])
	)
	_expect(
		int(snapshot["allocated_instances"]) < int(snapshot["maximum_instances"]),
		"component batches reserve bounded working buffers and retain their full growth ceiling"
	)
	_expect(Art.validate_contract().is_empty(), "combat visual profile satisfies the locked readability contract")
	_expect(
		AttackContract.LIGHT_PROJECTILE_RADIUS == 5.0
			and AttackContract.STANDARD_PROJECTILE_RADIUS == 6.0
			and AttackContract.HEAVY_PROJECTILE_RADIUS == 7.0,
		"hostile projectile collision radii remain 5/6/7 world units"
	)
	_expect(
		renderer.get_node_or_null("Projectile_shared_energy_teardrop") != null,
		"all non-beam projectile identities share one semantic texture batch"
	)
	_expect(
		renderer.get_node_or_null("Player_craft_body") != null
			and renderer.get_node_or_null("Player_hull") == null
			and renderer.get_node_or_null("Player_engine") == null
			and renderer.get_node_or_null("Player_engine_flare") == null
			and renderer.get_node_or_null("Player_primary_mount") == null,
		"one integrated player craft batch replaces fixed sub-parts while thrust reuses the overlay beam"
	)
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_expect(
			renderer.get_node_or_null("Boss_%s" % String(variant)) != null,
			"%s boss owns a semantic texture batch" % variant
		)
	_expect(
		renderer.get_node_or_null("Projectile_player_primary") == null
			and renderer.get_node_or_null("Projectile_enemy_arc") == null,
		"legacy player and affinity projectile batches are retired"
	)
	for pair in [
		[&"shooter", &"artillery_spotter"],
		[&"shooter", &"beam_sentinel"],
		[&"controller", &"shield_escort"],
		[&"controller", &"repair_tender"],
		[&"turret", &"interceptor_tower"],
	]:
		_expect(
			AssetProvider.texture(StringName("actor/%s" % String(pair[0])))
				!= AssetProvider.texture(StringName("actor/%s" % String(pair[1]))),
			"%s and %s bind distinct authored silhouette textures" % pair
		)
		_expect(
			renderer.get_node_or_null("Enemy_%s" % String(pair[0])) != null
				and renderer.get_node_or_null("Enemy_%s" % String(pair[1])) != null,
			"%s and %s own descriptor mesh batches" % pair
		)
	var enemy := EnemyState.new()
	enemy.id = "renderer_enemy"
	enemy.role = &"chaser"
	enemy.archetype = &"chaser"
	enemy.pos = Vector2(300.0, 300.0)
	enemy.alive = true
	enemy.active = true
	enemy.visual_radius = 26.0
	enemy.shielded = true
	enemy.health_class = &"priority"
	enemy.health = 20.0
	enemy.max_health = 40.0
	enemy.health_visible_timer = 1.0
	enemy.phase = &"startup"
	enemy.statuses = {
		&"burn":{"stacks":3},
		&"poison":{"stacks":2},
		&"chill":{"stacks":1},
	}
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(500.0, 300.0)
	enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"from":Vector2(300.0, 300.0),
		"to":Vector2(500.0, 300.0),
		"half_width":31.0,
		"damage":14.0,
		"affinity":AttackContract.KINETIC,
		"active_width":0.0,
	}]
	var enemies: Array[EnemyState] = [enemy]
	var projectile_direction := Vector2(3.0, 4.0).normalized()
	var projectile := ProjectileState.new()
	projectile.configure({
		"pos":Vector2(330.0,300.0), "velocity":projectile_direction * 200.0,
		"radius":5.0, "team":&"player", "color":Color.WHITE,
		"affinity":AttackContract.TOXIN,
	}, &"player", 1)
	var projectiles: Array[ProjectileState] = [projectile]
	var hostile_projectile := ProjectileState.new()
	hostile_projectile.configure({
		"pos":Vector2(390.0,300.0), "velocity":Vector2.LEFT * 180.0,
		"radius":5.0, "team":&"enemy", "color":Color.WHITE,
		"affinity":AttackContract.ARC,
	}, &"enemy", 2)
	var hostile_projectiles: Array[ProjectileState] = [hostile_projectile]
	var no_projectiles: Array[ProjectileState] = []
	var no_enemies: Array[EnemyState] = []
	var no_shards: Array[ExperienceShard] = []
	var shard := ExperienceShard.new()
	shard.configure(1, Vector2(340.0, 320.0), 1, &"")
	var shards: Array[ExperienceShard] = [shard]
	var effects: Array[Dictionary] = [{
		"pos":Vector2(360.0,320.0), "duration":1.0, "time":0.5,
		"radius":20.0, "kind":&"projectile_damage_impact",
		"color":Color.WHITE, "dir":Vector2.RIGHT,
	}]
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effects, Rect2(0,0,1280,720),
		Vector2(260.0,300.0), 1.0, true, "renderer_enemy",
		{
			"zones":[], "trails":[], "player_position":Vector2(260.0,300.0),
			"hull_direction":Vector2.RIGHT, "aim_direction":Vector2.DOWN,
			"player_hit":false, "muzzle_flash":0.0, "barrier_strength":10.0,
			"reduced_motion":true, "run_time":1.0, "ion_level":0,
			"blade_level":0, "escort_drone":false, "secondary":{},
			"support_fields":[{
				"state":&"active", "position":Vector2(600.0, 300.0),
				"radius":120.0, "kind":&"repair",
				"phase_progress":0.5, "effect_active":true,
			}],
			"cursor_position":Vector2(460.0,300.0),
		}
	)
	snapshot = renderer.debug_snapshot()
	var experience_batch := renderer.get_node_or_null(
		"Experience_master"
	) as MultiMeshInstance2D
	_expect(
		experience_batch != null
			and experience_batch.texture == AssetProvider.texture(
				&"pickup/experience_master"
			)
			and experience_batch.multimesh.visible_instance_count == 1,
		"all experience values share one authored master batch"
	)
	_expect(
		renderer.get_node_or_null("Experience_small") == null
			and renderer.get_node_or_null("Experience_medium") == null
			and renderer.get_node_or_null("Experience_large") == null,
		"legacy tier-specific experience batches stay retired"
	)
	_expect(int(snapshot["visible_instances"]) >= 10, "renderer publishes bodies and semantic overlays as retained instances")
	_expect(
		int(snapshot["semantic_texture_draw_count"])
			<= int(snapshot["semantic_texture_draw_capacity"]),
		"semantic texture draws stay inside the preallocated record capacity"
	)
	var support_timer := renderer.get_node("Overlay_support_timer_segment") as MultiMeshInstance2D
	_expect(
		support_timer.multimesh.visible_instance_count == 4,
		"support-field lifetime uses one retained eight-step timer batch"
	)
	var corridor_caps := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var corridor_boundaries := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	var corridor_boundary_buffer := corridor_boundaries.multimesh.buffer
	_expect(
		corridor_caps.multimesh.visible_instance_count == 1
			and corridor_boundaries.multimesh.visible_instance_count == 2
			and int(snapshot["support_field_glyph_count"]) == 1,
		"corridor warning adds no interior fill while the beneficial support field keeps one fill and one shared recipe glyph"
	)
	var repair_draws := renderer.debug_semantic_texture_draws(
		&"world/facility_repair_pad"
	)
	_expect(
		repair_draws.size() == 1
			and is_equal_approx(float(repair_draws[0]["radius"]), 120.0),
		"repair floor-pad raster scales to the live gameplay radius"
	)
	_expect(
		Vector2(
			corridor_boundary_buffer[3],
			corridor_boundary_buffer[7]
		).is_equal_approx(
			Vector2(300.0, 300.0)
		)
			and Vector2(
				corridor_boundary_buffer[15],
				corridor_boundary_buffer[19]
			).is_equal_approx(
				Vector2(500.0, 300.0)
			),
		"corridor warning outline caps stay centered on the simulated segment endpoints"
	)
	var enemy_batch := renderer.get_node("Enemy_chaser") as MultiMeshInstance2D
	var enemy_buffer := enemy_batch.multimesh.buffer
	_expect(
		enemy_batch.material == null,
		"authored actor perimeters do not add a runtime outline shader"
	)
	_expect(
		Vector2(enemy_buffer[3], enemy_buffer[7]).is_equal_approx(Vector2(300.0, 300.0)),
		"batched buffer preserves enemy position"
	)
	_expect(
		is_equal_approx(
			Vector2(enemy_buffer[0], enemy_buffer[4]).length(),
			26.0
		),
		"batched buffer preserves the selected enemy presentation scale"
	)
	var projectile_visual := renderer.get_node(
		"Projectile_shared_energy_teardrop"
	) as MultiMeshInstance2D
	var projectile_buffer := projectile_visual.multimesh.buffer
	_expect(
		Vector2(projectile_buffer[3], projectile_buffer[7]).is_equal_approx(
			Vector2(330.0, 300.0)
		),
		"projectile semantic pivot remains centered on collision state"
	)
	_expect(
		Vector2(projectile_buffer[0], projectile_buffer[4]).is_equal_approx(
			projectile_direction * 28.0
		),
		"player primary image uses its authored long-form presentation scale"
	)
	_expect(
		projectile_visual.texture != null,
		"shared projectile batch binds the approved raster image"
	)
	var player_craft := renderer.get_node("Player_craft_body") as MultiMeshInstance2D
	var craft_buffer := player_craft.multimesh.buffer
	_expect(
		player_craft.multimesh.visible_instance_count == 1
			and Vector2(craft_buffer[3], craft_buffer[7]).is_equal_approx(
				Vector2(260.0, 300.0)
			)
			and Vector2(craft_buffer[0], craft_buffer[4]).normalized()
				.is_equal_approx(Vector2.RIGHT)
			and player_craft.texture != null,
		"one authored craft body remains centered and follows the hull direction"
	)
	for status_id in [&"burn", &"poison", &"chill"]:
		_expect(
			renderer.get_node_or_null("Status_%s" % status_id) == null,
			"%s uses actor tint and text instead of a raster orbit icon" % status_id
		)
	_expect(
		Vector2(projectile_buffer[12], projectile_buffer[16]).is_equal_approx(
			Vector2.LEFT * 5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
		),
		"hostile visual envelope is 4.5 times the collision radius"
	)
	_expect(
		Vector2(projectile_buffer[15], projectile_buffer[19]).is_equal_approx(
			Vector2(390.0, 300.0)
		),
		"hostile projectile remains centered on collision state"
	)
	_expect(
		Vector2(projectile_buffer[13], projectile_buffer[17]).is_equal_approx(
			Vector2.LEFT.rotated(PI * 0.5) * 5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
		),
		"hostile visual envelope preserves uniform scaling"
	)
	_expect(
		projectile_visual.texture != null
			and projectile_visual.multimesh.mesh is QuadMesh
			and projectile_visual.multimesh.visible_instance_count == 2,
		"player and hostile projectiles share one texture-capable retained surface"
	)
	_validate_player_directional_cues(
		renderer,
		no_enemies,
		no_projectiles,
		no_shards
	)
	var crowd: Array[EnemyState] = []
	for index in 110:
		var crowd_enemy := EnemyState.new()
		crowd_enemy.id = "crowd_%02d" % index
		crowd_enemy.role = &"chaser"
		crowd_enemy.archetype = &"chaser"
		crowd_enemy.pos = Vector2(
			120.0 + float(index % 10) * 92.0,
			80.0 + float(index / 10) * 52.0
		)
		crowd_enemy.alive = true
		crowd_enemy.active = true
		crowd_enemy.visual_radius = 26.0
		crowd_enemy.health_class = &"priority"
		crowd_enemy.health = 20.0
		crowd_enemy.max_health = 40.0
		crowd_enemy.health_visible_timer = 1.0
		crowd_enemy.phase = &"move"
		crowd.append(crowd_enemy)
	renderer.sync(
		crowd, no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2(640.0,360.0), 2.0, true,
		"crowd_39"
	)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["health_bar_count"]) == Renderer.MAX_ORDINARY_HEALTH_BARS,
		"ordinary health bars stop at the deterministic twelve-actor budget"
	)
	_expect(
		int(snapshot["priority_marker_count"]) == Renderer.MAX_EXTRA_PRIORITY_MARKERS,
		"extra priority markers stop at the deterministic eight-actor budget"
	)
	var crowd_body := renderer.get_node("Enemy_chaser") as MultiMeshInstance2D
	_expect(
		crowd_body.multimesh.visible_instance_count == 110
			and crowd_body.multimesh.instance_count >= 110,
		"adaptive component buffers grow without hiding ordinary enemy bodies"
	)
	var offscreen_enemy := EnemyState.new()
	offscreen_enemy.id = "offscreen_attacker"
	offscreen_enemy.role = &"controller"
	offscreen_enemy.archetype = &"controller"
	offscreen_enemy.pos = Vector2(1800.0, 300.0)
	offscreen_enemy.alive = true
	offscreen_enemy.active = true
	offscreen_enemy.phase = &"startup"
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"area",
		"center":Vector2(640.0, 360.0),
		"radius":175.0,
		"damage":24.0,
		"affinity":AttackContract.THERMAL,
		"readiness":0.0,
	}]
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var offscreen_enemy_batch := renderer.get_node(
		"Enemy_controller"
	) as MultiMeshInstance2D
	var area_disk := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var area_ring := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	_expect(
		offscreen_enemy_batch.multimesh.visible_instance_count == 0,
		"off-screen attacker body remains culled"
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 0
			and area_ring.multimesh.visible_instance_count >= 2,
		"an on-screen outline-only danger footprint renders independently of its off-screen owner"
	)
	var early_area_buffer := area_ring.multimesh.buffer
	var early_area_color := Color(
		early_area_buffer[8],
		early_area_buffer[9],
		early_area_buffer[10],
		early_area_buffer[11]
	)
	offscreen_enemy.attack_telegraphs[0]["readiness"] = 1.0
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var late_area_buffer := area_ring.multimesh.buffer
	var late_area_color := Color(
		late_area_buffer[8],
		late_area_buffer[9],
		late_area_buffer[10],
		late_area_buffer[11]
	)
	_expect(
		late_area_color.get_luminance() < early_area_color.get_luminance()
			and late_area_color.a > early_area_color.a,
		"area outline continuously darkens and gains contrast toward impact"
	)
	offscreen_enemy.role = &"stage_boss"
	offscreen_enemy.phase = &"boss_active"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 0
			and area_ring.multimesh.visible_instance_count >= 2,
		"boss area outline stays visible for its complete damaging window"
	)
	offscreen_enemy.phase = &"active"
	offscreen_enemy.role = &"controller"
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"from":Vector2(-120.0, 360.0),
		"to":Vector2(900.0, 360.0),
		"half_width":58.0,
		"damage":28.0,
		"affinity":AttackContract.ARC,
		"active_width":54.0,
	}]
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	_expect(
		beam_batch.multimesh.visible_instance_count >= 4,
		"active off-screen beam keeps its exact danger boundary and beam body visible"
	)
	renderer.sync([], no_projectiles, no_projectiles, [], [], Rect2(0,0,1280,720), Vector2.ZERO, 0.0, false)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["visible_instances"]) == 0,
		"inactive presentation hides all retained instances"
	)
	_expect(
		int(snapshot["health_bar_count"]) == 0
			and int(snapshot["priority_marker_count"]) == 0
			and int(snapshot["support_field_glyph_count"]) == 0,
		"inactive presentation clears semantic overlay diagnostics"
	)
	renderer.queue_free()
	await process_frame
	_finish()


func _validate_player_directional_cues(
	renderer: Renderer,
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard]
) -> void:
	var player_position := Vector2(640.0, 360.0)
	var presentation := _player_presentation(player_position, false)
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		[],
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	_expect(
		beam_batch.multimesh.visible_instance_count == 0,
		"idle and ordinary movement render no engine thrust cue"
	)
	presentation["dash_active"] = true
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		[],
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 1,
		"dash renders exactly one rear engine thrust cue"
	)
	for asset_id in [&"secondary/orbit_blade", &"secondary/escort_drone"]:
		var draws := renderer.debug_semantic_texture_draws(asset_id)
		_expect(not draws.is_empty(), "%s owns a rendered directional fixture" % asset_id)
		for draw in draws:
			var radial := Vector2(draw["position"]) - player_position
			var texture_forward := Vector2.RIGHT.rotated(float(draw["angle"]))
			_expect(
				not radial.is_zero_approx()
					and radial.normalized().dot(texture_forward) >= 0.999,
				"%s faces radially outward" % asset_id
			)


func _player_presentation(
	player_position: Vector2,
	dash_active: bool
) -> Dictionary:
	return {
		"zones":[],
		"trails":[],
		"player_position":player_position,
		"hull_direction":Vector2.RIGHT,
		"aim_direction":Vector2.UP,
		"player_speed":280.0,
		"dash_active":dash_active,
		"dash_progress":0.5 if dash_active else 0.0,
		"dash_direction":Vector2.RIGHT,
		"player_hit":false,
		"player_hit_remaining":0.0,
		"protection_sources":{},
		"muzzle_flash":0.0,
		"barrier_strength":0.0,
		"reduced_motion":false,
		"run_time":1.0,
		"secondary_visual_tier":0,
		"support_fields":[],
		"resolved_boss_modules":[],
		"ion_level":0,
		"blade_level":1,
		"escort_drone":true,
		"secondary":{
			"orbit_angle":0.37,
			"mines":[],
			"drone_position":player_position + Vector2.DOWN * 92.0,
		},
		"cursor_position":player_position + Vector2.UP * 230.0,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_COMBAT_RENDERER_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
