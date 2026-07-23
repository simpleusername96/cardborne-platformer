extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
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
	_expect(int(snapshot["batches"]) <= 40, "combat presentation stays within the retained batch ceiling")
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
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(500.0, 300.0)
	var enemies: Array[EnemyState] = [enemy]
	var projectile_direction := Vector2(3.0, 4.0).normalized()
	var projectile := ProjectileState.new()
	projectile.configure({
		"pos":Vector2(330.0,300.0), "velocity":projectile_direction * 200.0,
		"radius":5.0, "team":&"player", "color":Color.WHITE,
	}, &"player", 1)
	var projectiles: Array[ProjectileState] = [projectile]
	var no_projectiles: Array[ProjectileState] = []
	var shard := ExperienceShard.new()
	shard.configure(1, Vector2(340.0, 320.0), 1, &"")
	var shards: Array[ExperienceShard] = [shard]
	var effects: Array[Dictionary] = [{
		"pos":Vector2(360.0,320.0), "duration":1.0, "time":0.5,
		"radius":20.0, "kind":"impact", "color":Color.WHITE,
	}]
	renderer.sync(
		enemies, projectiles, no_projectiles, shards, effects, Rect2(0,0,1280,720),
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
	var projectile_trail := renderer.get_node("Projectile_trail_player") as MultiMeshInstance2D
	var head_buffer := projectile_head.multimesh.buffer
	var trail_buffer := projectile_trail.multimesh.buffer
	_expect(
		Vector2(head_buffer[3], head_buffer[7]).is_equal_approx(Vector2(330.0, 300.0)),
		"projectile head remains centered on collision state"
	)
	_expect(
		Vector2(head_buffer[0], head_buffer[4]).is_equal_approx(projectile_direction * 7.0),
		"projectile head preserves direction and the minimum seven-pixel visual radius"
	)
	_expect(
		Vector2(trail_buffer[3], trail_buffer[7]).is_equal_approx(
			Vector2(330.0, 300.0) - projectile_direction * 16.5
		),
		"projectile trail preserves the original 40 px back and 7 px front span"
	)
	_expect(
		Vector2(trail_buffer[0], trail_buffer[4]).is_equal_approx(projectile_direction * 47.0),
		"projectile trail preserves direction and fixed length"
	)
	_expect(
		Vector2(trail_buffer[1], trail_buffer[5]).is_equal_approx(
			projectile_direction.rotated(PI * 0.5) * 10.5
		),
		"projectile trail width remains perpendicular and follows the visual radius"
	)
	_expect(
		is_equal_approx(trail_buffer[11], 0.5),
		"projectile trail remains translucent"
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
