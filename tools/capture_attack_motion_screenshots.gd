extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux"
const PLAYER_SCENE := "res://scenes/player/Player.tscn"

var _captures: Array[Dictionary] = [
	{"name": "attack_warrior", "profile_index": 0},
	{"name": "attack_archer", "profile_index": 1},
	{"name": "attack_assassin", "profile_index": 2},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var game := root.get_node_or_null("/root/Game")
	if game != null:
		game.ensure_input_map()

	for capture in _captures:
		await _capture_attack(capture)

	quit()


func _capture_attack(capture: Dictionary) -> void:
	root.size = Vector2i(520, 260)
	DisplayServer.window_set_size(root.size)

	var run_state := root.get_node_or_null("/root/RunState")
	if run_state != null:
		run_state.start_new_run(int(capture["profile_index"]))

	var world := Node2D.new()
	world.name = "AttackCaptureWorld"
	root.add_child(world)
	_add_stage_floor(world)

	var packed_scene := load(PLAYER_SCENE) as PackedScene
	var player := packed_scene.instantiate()
	player.position = Vector2(160.0, 190.0)
	world.add_child(player)
	await process_frame

	Input.action_press("attack")
	await _wait_for_attack_startup(player)
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)

	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	root.get_texture().get_image().save_png(output_path)

	Input.action_release("attack")
	world.queue_free()
	await process_frame


func _wait_for_attack_startup(player: Node) -> void:
	var combat := player.get_node_or_null("CombatController") as PlayerCombatController
	for _frame in 30:
		await physics_frame
		if combat == null or combat.current_attack == null:
			continue
		if String(combat.get_state_snapshot().get("phase", "")) != "startup":
			return


func _add_stage_floor(world: Node2D) -> void:
	var backdrop := Polygon2D.new()
	backdrop.color = Color(0.08, 0.09, 0.11, 1.0)
	backdrop.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(520.0, 0.0),
		Vector2(520.0, 260.0),
		Vector2(0.0, 260.0),
	])
	world.add_child(backdrop)

	var floor := Polygon2D.new()
	floor.color = Color(0.28, 0.34, 0.42, 1.0)
	floor.polygon = PackedVector2Array([
		Vector2(40.0, 190.0),
		Vector2(480.0, 190.0),
		Vector2(480.0, 226.0),
		Vector2(40.0, 226.0),
	])
	world.add_child(floor)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(260.0, 208.0)
	world.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(440.0, 36.0)
	shape.shape = rect
	body.add_child(shape)
