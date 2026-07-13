extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const FIXTURES: Array[Dictionary] = [
	{
		"id": "flooded_sunken_cache",
		"scene": "res://scenes/rooms/flooded_works/FwSunkenCache.tscn",
		"recovery": "Anchors/Recovery/SunkenRecovery",
		"rope": "Anchors/Objective/BasinRope",
		"exit_top": 520.0,
		"exit_center_x": 984.0,
	},
	{
		"id": "sanctum_material_crypt",
		"scene": "res://scenes/rooms/broken_sanctum/BsMaterialCrypt.tscn",
		"recovery": "Anchors/Recovery/CryptBasinRecovery",
		"rope": "Anchors/Objective/BasinReturnRope",
		"exit_top": 520.0,
		"exit_center_x": 984.0,
	},
]

var _failures: Array[String] = []
var _game: Node
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null("/root/Game")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_game != null and _run_state != null, "Fixed drop runtime needs production autoloads.")
	if _game == null or _run_state == null:
		_finish()
		return
	_game.call("ensure_input_map")
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(packed_player != null, "Fixed drop runtime should load the player scene.")
	if packed_player == null:
		_finish()
		return
	for profile_index in 3:
		for fixture in FIXTURES:
			await _validate_fixture(profile_index, fixture, packed_player)
	_finish()


func _validate_fixture(
	profile_index: int,
	fixture: Dictionary,
	packed_player: PackedScene
) -> void:
	_release_inputs()
	_expect(
		bool(_run_state.call("start_new_run", profile_index, 73021)),
		"Profile %d should start for %s." % [profile_index, fixture["id"]]
	)
	var packed := load(String(fixture["scene"])) as PackedScene
	_expect(packed != null, "%s room scene should load." % fixture["id"])
	if packed == null:
		return
	var world := Node2D.new()
	world.name = "FixedDropRuntime_%s_%d" % [fixture["id"], profile_index]
	root.add_child(world)
	var room := packed.instantiate() as Node2D
	world.add_child(room)
	_disable_pickups(room)
	var recovery := room.get_node_or_null(String(fixture["recovery"])) as Marker2D
	var rope := room.get_node_or_null(String(fixture["rope"])) as Area2D
	_expect(recovery != null and rope != null, "%s runtime anchors should exist." % fixture["id"])
	if recovery == null or rope == null:
		world.queue_free()
		await process_frame
		return
	var player := packed_player.instantiate()
	world.add_child(player)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = false
	player.global_position = recovery.global_position
	await _physics_steps(4)

	Input.action_press("move_right")
	for _step in 180:
		if player.global_position.x >= rope.global_position.x - 18.0:
			break
		await _physics_steps(1)
	Input.action_release("move_right")
	await _physics_steps(3)
	_expect(
		int(player.climbable_count) > 0,
		"%s profile %d should physically enter the basin rope." % [fixture["id"], profile_index]
	)

	Input.action_press("climb_up")
	Input.action_press("move_right")
	for _step in 110:
		if (
			player.global_position.y <= float(fixture["exit_top"]) + 1.0
			and player.global_position.x >= float(fixture["exit_center_x"])
		):
			break
		await _physics_steps(1)
	Input.action_release("climb_up")
	Input.action_release("move_right")
	await _physics_steps(10)
	_expect(
		player.global_position.y <= float(fixture["exit_top"]) + 2.0,
		"%s profile %d should climb from basin to the return shelf; position=%s."
		% [fixture["id"], profile_index, player.global_position]
	)
	_expect(
		player.global_position.x >= float(fixture["exit_center_x"]),
		"%s profile %d should dismount onto the return shelf; position=%s."
		% [fixture["id"], profile_index, player.global_position]
	)
	world.queue_free()
	await process_frame
	await process_frame


func _disable_pickups(room: Node) -> void:
	var pickups := room.get_node_or_null("FieldPickups")
	if pickups == null:
		return
	for pickup in pickups.get_children():
		pickup.set_deferred("monitoring", false)
		pickup.set_deferred("monitorable", false)


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _release_inputs() -> void:
	for action in ["move_left", "move_right", "climb_up", "climb_down", "jump", "dash"]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	_release_inputs()
	if _failures.is_empty():
		print("FIXED_DROP_RUNTIME_VALIDATION_OK profiles=3 fixtures=2")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
