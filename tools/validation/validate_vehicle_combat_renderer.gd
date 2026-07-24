extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
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
	_expect(int(snapshot["batches"]) <= 50, "combat presentation stays within the retained batch ceiling")
	for team in [&"player", &"enemy"]:
		for affinity in AttackContract.AFFINITIES:
			if affinity == AttackContract.SUPPORT:
				continue
			_expect(
				renderer.get_node_or_null(
					"Projectile_trail_%s_%s" % [String(team), String(affinity)]
				) != null,
				"%s %s projectile trail batch exists" % [team, affinity]
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
			"hull_direction":Vector2.RIGHT, "aim_direction":Vector2.RIGHT,
			"player_hit":false, "muzzle_flash":0.0, "barrier_strength":10.0,
			"reduced_motion":true, "run_time":1.0, "ion_level":0,
			"blade_level":0, "escort_drone":false, "secondary":{},
			"cursor_position":Vector2(460.0,300.0),
		}
	)
	snapshot = renderer.debug_snapshot()
	_expect(int(snapshot["visible_instances"]) >= 10, "renderer publishes bodies and semantic overlays as retained instances")
	var corridor_caps := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var corridor_boundaries := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	var corridor_cap_buffer := corridor_caps.multimesh.buffer
	_expect(
		corridor_caps.multimesh.visible_instance_count == 2
			and corridor_boundaries.multimesh.visible_instance_count == 2,
		"corridor warning uses two endpoint disks and rings for an exact capsule footprint"
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
		is_equal_approx(Vector2(enemy_buffer[0], enemy_buffer[4]).length(), 26.0),
		"batched buffer preserves enemy visual scale"
	)
	var projectile_head := renderer.get_node("Projectile_head_player") as MultiMeshInstance2D
	var projectile_trail := renderer.get_node("Projectile_trail_player_toxin") as MultiMeshInstance2D
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
		"player affinity trail stays attached behind the five-pixel head"
	)
	_expect(
		Vector2(trail_buffer[0], trail_buffer[4]).is_equal_approx(projectile_direction * 47.0),
		"projectile trail preserves direction and fixed length"
	)
	_expect(
		Vector2(trail_buffer[1], trail_buffer[5]).is_equal_approx(
			projectile_direction.rotated(PI * 0.5) * 7.5
		),
		"player affinity trail width follows the collision radius"
	)
	_expect(
		is_equal_approx(trail_buffer[11], 0.5),
		"projectile trail remains translucent"
	)
	var status_batch := renderer.get_node("Overlay_status_arc") as MultiMeshInstance2D
	_expect(status_batch.multimesh.instance_count == 384, "one retained status arc batch reserves exactly 128 by three instances")
	_expect(status_batch.multimesh.visible_instance_count == 3, "three simultaneous elements render as three large retained arcs")
	var hostile_head := renderer.get_node("Projectile_head_enemy") as MultiMeshInstance2D
	var hostile_trail := renderer.get_node("Projectile_trail_enemy_arc") as MultiMeshInstance2D
	var hostile_head_buffer := hostile_head.multimesh.buffer
	var hostile_trail_buffer := hostile_trail.multimesh.buffer
	_expect(
		Vector2(hostile_head_buffer[0], hostile_head_buffer[4]).is_equal_approx(Vector2.LEFT * 5.0),
		"hostile projectile head radius exactly matches its collision radius"
	)
	_expect(
		Vector2(hostile_trail_buffer[0], hostile_trail_buffer[4]).is_equal_approx(Vector2.LEFT * 36.0),
		"hostile projectile trail uses the shorter 36-pixel contract"
	)
	_expect(
		Vector2(hostile_trail_buffer[3], hostile_trail_buffer[7]).is_equal_approx(
			Vector2(390.0, 300.0) - Vector2.LEFT * 13.0
		),
		"hostile affinity trail remains attached behind its five-pixel head"
	)
	_expect(
		Vector2(hostile_trail_buffer[1], hostile_trail_buffer[5]).is_equal_approx(
			Vector2.LEFT.rotated(PI * 0.5) * 6.25
		),
		"hostile projectile trail width follows the reduced collision family"
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
	var offscreen_enemy_batch := renderer.get_node("Enemy_controller") as MultiMeshInstance2D
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
	_expect(int(renderer.debug_snapshot()["visible_instances"]) == 0, "inactive presentation hides all retained instances")
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
