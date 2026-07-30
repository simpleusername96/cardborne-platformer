extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer := Renderer.new()
	root.add_child(renderer)
	await process_frame
	var snapshot: Dictionary = renderer.debug_snapshot()
	_expect(int(snapshot["enemy_capacity"]) == 320, "renderer shares the 320-hostile store capacity")
	_expect(int(snapshot["status_arc_capacity"]) == 960, "status overlays scale from shared enemy capacity")
	_expect(
		int(snapshot["batches"]) <= 50,
		"combat presentation remains inside the retained fifty-batch ceiling (actual %d)"
		% int(snapshot["batches"])
	)
	_expect(Art.validate_contract().is_empty(), "combat visual profile satisfies the locked readability contract")
	_expect(
		AttackContract.LIGHT_PROJECTILE_RADIUS == 5.0
			and AttackContract.STANDARD_PROJECTILE_RADIUS == 6.0
			and AttackContract.HEAVY_PROJECTILE_RADIUS == 7.0,
		"hostile projectile collision radii remain 5/6/7 world units"
	)
	_expect(
		renderer.get_node_or_null("Projectile_trail_player_kinetic") != null,
		"player ownership uses its rendered kinetic trail batch"
	)
	_expect(
		renderer.get_node_or_null("Player_hull") != null
			and renderer.get_node_or_null("Player_engine") != null
			and renderer.get_node_or_null("Player_engine_flare") != null
			and renderer.get_node_or_null("Player_primary_mount") != null,
		"player hull, rigid engine, flare and independent aim mount use component batches"
	)
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_expect(
			renderer.get_node_or_null("Boss_%s" % String(variant)) != null,
			"%s boss owns a vector silhouette batch" % variant
		)
	for affinity in AttackContract.AFFINITIES:
		_expect(
			absf(Visuals.debug_projectile_head_extent(affinity) - 1.0) <= 0.001,
			"%s hostile head remains bounded by its collision radius" % affinity
		)
		if affinity == AttackContract.SUPPORT:
			continue
		_expect(
			renderer.get_node_or_null(
				"Projectile_trail_enemy_%s" % String(affinity)
			) != null,
			"hostile %s affinity uses its descriptor mesh batch" % affinity
		)
	_expect(
		renderer.get_node_or_null("Projectile_core_enemy") != null,
		"hostile projectiles expose one shared collision-bounded core batch"
	)
	for pair in [
		[&"shooter", &"artillery_spotter"],
		[&"shooter", &"beam_sentinel"],
		[&"controller", &"shield_escort"],
		[&"controller", &"repair_tender"],
		[&"turret", &"interceptor_tower"],
	]:
		_expect(
			Visuals.debug_enemy_signature(pair[0]) != Visuals.debug_enemy_signature(pair[1]),
			"%s and %s have distinct outer silhouettes" % pair
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
	var shard := ExperienceShard.new()
	shard.configure(1, Vector2(340.0, 320.0), 1, &"")
	var shards: Array[ExperienceShard] = [shard]
	var effects: Array[Dictionary] = [{
		"pos":Vector2(360.0,320.0), "duration":1.0, "time":0.5,
		"radius":20.0, "kind":"impact", "color":Color.WHITE,
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
	_expect(int(snapshot["visible_instances"]) >= 10, "renderer publishes bodies and semantic overlays as retained instances")
	var support_timer := renderer.get_node("Overlay_support_timer_segment") as MultiMeshInstance2D
	_expect(
		support_timer.multimesh.visible_instance_count == 12,
		"support-field lifetime uses one retained 24-step timer batch"
	)
	var corridor_caps := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var corridor_boundaries := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	var corridor_cap_buffer := corridor_caps.multimesh.buffer
	_expect(
		corridor_caps.multimesh.visible_instance_count >= 4
			and corridor_boundaries.multimesh.visible_instance_count == 2,
		"corridor warning keeps its two endpoint disks and rings alongside support overlays"
	)
	_expect(
		Vector2(corridor_cap_buffer[3], corridor_cap_buffer[7]).is_equal_approx(
			Vector2(300.0, 300.0)
		)
			and Vector2(corridor_cap_buffer[15], corridor_cap_buffer[19]).is_equal_approx(
				Vector2(500.0, 300.0)
			),
		"corridor warning caps stay centered on the simulated segment endpoints"
	)
	var enemy_batch := renderer.get_node("Enemy_chaser") as MultiMeshInstance2D
	var enemy_buffer := enemy_batch.multimesh.buffer
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
	var projectile_head := renderer.get_node("Projectile_head_player") as MultiMeshInstance2D
	var projectile_trail := renderer.get_node("Projectile_trail_player_kinetic") as MultiMeshInstance2D
	var head_buffer := projectile_head.multimesh.buffer
	var trail_buffer := projectile_trail.multimesh.buffer
	_expect(
		Vector2(head_buffer[3], head_buffer[7]).is_equal_approx(Vector2(330.0, 300.0)),
		"projectile head remains centered on collision state"
	)
	_expect(
		Vector2(head_buffer[0], head_buffer[4]).is_equal_approx(projectile_direction * 5.0),
		"projectile head radius exactly matches its collision radius"
	)
	_expect(
		Vector2(trail_buffer[3], trail_buffer[7]).is_equal_approx(
			Vector2(330.0, 300.0) - projectile_direction * 18.5
		),
		"player ownership trail stays attached behind the five-unit head"
	)
	_expect(
		Vector2(trail_buffer[0], trail_buffer[4]).is_equal_approx(projectile_direction * 47.0),
		"projectile trail preserves direction and fixed length"
	)
	_expect(
		Vector2(trail_buffer[1], trail_buffer[5]).is_equal_approx(
			projectile_direction.rotated(PI * 0.5) * 7.5
		),
		"player ownership trail width follows the collision radius"
	)
	var player_hull := renderer.get_node("Player_hull") as MultiMeshInstance2D
	var player_engine := renderer.get_node("Player_engine") as MultiMeshInstance2D
	var player_primary := renderer.get_node("Player_primary_mount") as MultiMeshInstance2D
	var hull_buffer := player_hull.multimesh.buffer
	var engine_buffer := player_engine.multimesh.buffer
	var primary_buffer := player_primary.multimesh.buffer
	_expect(
		player_hull.multimesh.visible_instance_count == 1
			and Vector2(hull_buffer[3], hull_buffer[7]).is_equal_approx(
				Vector2(260.0, 300.0)
			),
		"player hull uses one centered component instance"
	)
	_expect(
		Vector2(engine_buffer[3], engine_buffer[7]).is_equal_approx(
			Renderer.player_engine_sockets(
				Vector2(260.0, 300.0),
				Vector2.RIGHT
			)[0]
		),
		"engine components stay on the first continuous rear socket"
	)
	_expect(
		Vector2(primary_buffer[0], primary_buffer[4]).normalized().is_equal_approx(
			Vector2.DOWN
		),
		"primary mount follows aim independently from the right-facing hull"
	)
	var status_batch := renderer.get_node("Overlay_status_arc") as MultiMeshInstance2D
	_expect(
		status_batch.multimesh.instance_count == Renderer.STATUS_ARC_CAPACITY,
		"one retained status arc batch reserves three instances per hostile slot"
	)
	_expect(status_batch.multimesh.visible_instance_count == 3, "three simultaneous elements render as three large retained arcs")
	var hostile_trail := renderer.get_node(
		"Projectile_trail_enemy_arc"
	) as MultiMeshInstance2D
	var hostile_trail_buffer := hostile_trail.multimesh.buffer
	var hostile_core := renderer.get_node("Projectile_core_enemy") as MultiMeshInstance2D
	var hostile_core_buffer := hostile_core.multimesh.buffer
	_expect(
		Vector2(hostile_trail_buffer[0], hostile_trail_buffer[4]).is_equal_approx(
			Vector2.LEFT * 5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
		),
		"hostile visual envelope is 4.5 times the collision radius"
	)
	_expect(
		Vector2(hostile_trail_buffer[3], hostile_trail_buffer[7]).is_equal_approx(
			Vector2(390.0, 300.0)
		),
		"hostile affinity head remains centered on collision state"
	)
	_expect(
		Vector2(hostile_trail_buffer[1], hostile_trail_buffer[5]).is_equal_approx(
			Vector2.LEFT.rotated(PI * 0.5) * 5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
		),
		"hostile visual envelope preserves uniform scaling"
	)
	_expect(
		hostile_core.multimesh.visible_instance_count == 1
			and Vector2(hostile_core_buffer[3], hostile_core_buffer[7])
				.is_equal_approx(Vector2(390.0, 300.0))
			and is_equal_approx(
				Vector2(hostile_core_buffer[0], hostile_core_buffer[4]).length(),
				5.0
			),
		"hostile solid core ends at the five-unit collision boundary"
	)
	_expect(
		hostile_trail.multimesh.mesh.get_surface_count() == 1,
		"hostile head and trail share one vertex-colored mesh surface"
	)
	var crowd: Array[EnemyState] = []
	for index in 40:
		var crowd_enemy := EnemyState.new()
		crowd_enemy.id = "crowd_%02d" % index
		crowd_enemy.role = &"chaser"
		crowd_enemy.archetype = &"chaser"
		crowd_enemy.pos = Vector2(
			120.0 + float(index % 10) * 92.0,
			100.0 + float(index / 10) * 120.0
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
		crowd_body.multimesh.visible_instance_count == 40,
		"semantic overlay budgets do not hide ordinary enemy bodies"
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
		area_disk.multimesh.visible_instance_count == 2
			and area_ring.multimesh.visible_instance_count >= 2,
		"an on-screen center-weighted danger footprint renders independently of its off-screen owner"
	)
	var early_area_buffer := area_disk.multimesh.buffer
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
	var late_area_buffer := area_disk.multimesh.buffer
	var late_area_color := Color(
		late_area_buffer[8],
		late_area_buffer[9],
		late_area_buffer[10],
		late_area_buffer[11]
	)
	_expect(
		late_area_color.get_luminance() < early_area_color.get_luminance()
			and late_area_color.a > early_area_color.a,
		"area warning continuously darkens and gains contrast toward impact"
	)
	offscreen_enemy.role = &"stage_boss"
	offscreen_enemy.phase = &"boss_active"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 2
			and area_ring.multimesh.visible_instance_count >= 2,
		"boss area footprint stays visible for its complete damaging window"
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
		beam_batch.multimesh.visible_instance_count >= 5,
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
			and int(snapshot["priority_marker_count"]) == 0,
		"inactive presentation clears semantic overlay diagnostics"
	)
	renderer.queue_free()
	await process_frame
	_finish()


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
