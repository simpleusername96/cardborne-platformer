extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer := Renderer.new()
	root.add_child(renderer)
	await process_frame
	var enemies: Array[EnemyState] = []
	for index in 320:
		var enemy := EnemyState.new()
		enemy.id = "health_fixture_%03d" % index
		enemy.role = &"ordinary_edge_01"
		enemy.archetype = &"ordinary_pursuer_t1"
		enemy.pos = Vector2(32.0 + float(index % 20) * 62.0, 30.0 + float(index / 20) * 42.0)
		enemy.visual_radius = 18.0
		enemy.health = float((index % 10) + 1)
		enemy.max_health = 10.0
		enemy.alive = true
		enemy.active = true
		enemies.append(enemy)
	renderer.sync(
		enemies, [], [], [], [], Rect2(0.0, 0.0, 1280.0, 720.0),
		Vector2(640.0, 360.0), 0.0, true
	)
	var snapshot := renderer.debug_snapshot()
	_expect(int(snapshot["ordinary_health_bar_count"]) == 320, "all 320 visible ordinary enemies receive a bar")
	_expect(int(snapshot["health_bar_count"]) == 320, "health bar classification has no omissions")
	_expect(int(snapshot["health_bar_capacity"]) == 640, "retained health batch has 640 instances")
	_expect(int(snapshot["health_bar_overflow"]) == 0, "320 enemies do not overflow the retained batch")
	var batch := renderer.get_node("Overlay_health") as MultiMeshInstance2D
	_expect(batch.multimesh.visible_instance_count == 640, "backing and fill use exactly two instances per enemy")
	var fixed_enemy := _enemy(&"ordinary_fixed_beam_01", &"boss_pattern_fixed_beam_01", Vector2(300.0, 300.0))
	var boss := _enemy(&"boss", &"boss_actor", Vector2(640.0, 360.0))
	boss.boss_variant = &"boss_stage_01"
	var classification: Array[EnemyState] = [enemies[0], fixed_enemy, boss]
	renderer.sync(
		classification, [], [], [], [],
		Rect2(0.0, 0.0, 1280.0, 720.0), Vector2(640.0, 360.0), 0.0, true
	)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["ordinary_health_bar_count"]) == 1
		and int(snapshot["fixed_health_bar_count"]) == 1
		and int(snapshot["boss_health_bar_count"]) == 1
		and int(snapshot["health_bar_count"]) == 3,
		"ordinary, fixed, and boss health bars publish distinct diagnostics"
	)
	if failures.is_empty():
		print("VEHICLE_HEALTH_BAR_CAPACITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _enemy(role: StringName, archetype: StringName, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = "%s_fixture" % role
	enemy.role = role
	enemy.archetype = archetype
	enemy.pos = position
	enemy.visual_radius = 34.0
	enemy.health = 100.0
	enemy.max_health = 100.0
	enemy.alive = true
	enemy.active = true
	return enemy
