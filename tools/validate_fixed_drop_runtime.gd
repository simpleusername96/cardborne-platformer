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
	{
		"id": "sanctum_reliquary_drop",
		"kind": &"drop",
		"scene": "res://scenes/rooms/broken_sanctum/BsReliquaryCache.tscn",
		"target_scene": "res://scenes/rooms/broken_sanctum/BsTwinReliquaryChoice.tscn",
		"recovery": "Anchors/Recovery/CacheReturnRecovery",
		"target_landing": "OneWay/UpperReturnLanding",
	},
	{
		"id": "ruin_cache_return_rope",
		"kind": &"cross_room_rope",
		"scene": "res://scenes/rooms/lower_ruins/LrDestructibleCache.tscn",
		"target_scene": "res://scenes/rooms/lower_ruins/LrLowerUpperChoice.tscn",
		"recovery": "Anchors/Recovery/CacheRecovery",
		"rope": "Anchors/Objective/ReturnRope",
		"target_landing": "OneWay/ReturnShaftCover",
	},
	{
		"id": "flooded_cache_return_rope",
		"kind": &"cross_room_rope",
		"scene": "res://scenes/rooms/flooded_works/FwSunkenCache.tscn",
		"target_scene": "res://scenes/rooms/flooded_works/FwLowerUpperChoice.tscn",
		"recovery": "Anchors/Recovery/SunkenExitRecovery",
		"rope": "Anchors/Objective/ReturnRope",
		"target_landing": "Terrain/ReturnShaftCover",
	},
	{
		"id": "sanctum_crypt_return_rope",
		"kind": &"cross_room_rope",
		"scene": "res://scenes/rooms/broken_sanctum/BsMaterialCrypt.tscn",
		"target_scene": "res://scenes/rooms/broken_sanctum/BsTwinReliquaryChoice.tscn",
		"recovery": "Anchors/Recovery/CryptReturnRecovery",
		"rope": "Anchors/Objective/ReturnRope",
		"target_landing": "Terrain/LowerReturnHatch",
	},
]

var _failures: Array[String] = []
var _game: Node
var _run_state: Node
var _validated_profiles: Dictionary = {}
var _validated_fixture_ids: Dictionary = {}


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
	var profile_filter := OS.get_environment("FIXED_DROP_PROFILE")
	var requested_profile := int(profile_filter) if not profile_filter.is_empty() else -1
	var requested_fixture := OS.get_environment("FIXED_DROP_FIXTURE")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--profile="):
			requested_profile = int(argument.trim_prefix("--profile="))
		elif argument.begins_with("--fixture="):
			requested_fixture = argument.trim_prefix("--fixture=")
	for profile_index in 3:
		if requested_profile >= 0 and profile_index != requested_profile:
			continue
		for fixture in FIXTURES:
			if not requested_fixture.is_empty() and String(fixture["id"]) != requested_fixture:
				continue
			_validated_profiles[profile_index] = true
			_validated_fixture_ids[String(fixture["id"])] = true
			await _validate_fixture(profile_index, fixture, packed_player)
	_finish()


func _validate_fixture(
	profile_index: int,
	fixture: Dictionary,
	packed_player: PackedScene
) -> void:
	if fixture.get("kind", &"rope") == &"drop":
		await _validate_drop_fixture(profile_index, fixture, packed_player)
		return
	if fixture.get("kind", &"rope") == &"cross_room_rope":
		await _validate_cross_room_rope(profile_index, fixture, packed_player)
		return
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


func _validate_cross_room_rope(
	profile_index: int,
	fixture: Dictionary,
	packed_player: PackedScene
) -> void:
	_release_inputs()
	_expect(
		bool(_run_state.call("start_new_run", profile_index, 73021)),
		"Profile %d should start for %s." % [profile_index, fixture["id"]]
	)
	var source_packed := load(String(fixture["scene"])) as PackedScene
	var target_packed := load(String(fixture["target_scene"])) as PackedScene
	_expect(
		source_packed != null and target_packed != null,
		"%s room scenes should load." % fixture["id"]
	)
	if source_packed == null or target_packed == null:
		return
	var world := Node2D.new()
	world.name = "FixedDropRuntime_%s_%d" % [fixture["id"], profile_index]
	root.add_child(world)
	var target_room := target_packed.instantiate() as Node2D
	world.add_child(target_room)
	var source_room := source_packed.instantiate() as Node2D
	source_room.position = Vector2(0.0, 720.0)
	world.add_child(source_room)
	_disable_pickups(source_room)
	_disable_pickups(target_room)
	var recovery := source_room.get_node_or_null(String(fixture["recovery"])) as Marker2D
	var rope := source_room.get_node_or_null(String(fixture["rope"])) as Area2D
	var landing := target_room.get_node_or_null(String(fixture["target_landing"])) as StaticBody2D
	_expect(
		recovery != null and rope != null and landing != null,
		"%s runtime route nodes should exist." % fixture["id"]
	)
	if recovery == null or rope == null or landing == null:
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

	await _approach_rope(player, rope)
	_expect(
		int(player.climbable_count) > 0,
		"%s profile %d should physically enter the cross-room rope; position=%s floor=%s jumps=%d."
		% [
			fixture["id"],
			profile_index,
			player.global_position,
			player.is_on_floor(),
			int(player.get_meta("validator_approach_jumps", 0)),
		]
	)

	var landing_top := _collision_top(landing)
	var highest_y: float = player.global_position.y
	Input.action_press("climb_up")
	for _step in 320:
		highest_y = minf(highest_y, player.global_position.y)
		if player.global_position.y <= landing_top - 24.0:
			break
		await _physics_steps(1)
	Input.action_release("climb_up")
	var release_y: float = player.global_position.y
	var release_was_climbing := bool(player.is_climbing)
	var release_climbable_count := int(player.climbable_count)
	Input.action_press("jump")
	await _physics_steps(1)
	Input.action_release("jump")
	for _step in 90:
		if player.is_on_floor() and absf(player.global_position.y - landing_top) <= 2.0:
			break
		await _physics_steps(1)
	var landing_shape := landing.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var landing_rectangle := (
		landing_shape.shape as RectangleShape2D
		if landing_shape != null else null
	)
	var landing_half_width := (
		landing_rectangle.size.x * 0.5
		if landing_rectangle != null else 100.0
	)
	_expect(
		player.is_on_floor() and absf(player.global_position.y - landing_top) <= 2.0,
		"%s profile %d should dismount onto the target support; position=%s highest=%.2f release=%.2f climbing=%s count=%d mask=%d."
		% [
			fixture["id"], profile_index, player.global_position, highest_y, release_y,
			release_was_climbing, release_climbable_count, player.collision_mask,
		]
	)
	_expect(
		absf(player.global_position.x - landing.global_position.x) <= landing_half_width - 14.0,
		"%s profile %d should remain inside the target support; position=%s."
		% [fixture["id"], profile_index, player.global_position]
	)
	world.queue_free()
	await process_frame
	await process_frame


func _approach_rope(player: CharacterBody2D, rope: Area2D) -> void:
	var direction := 1.0 if rope.global_position.x >= player.global_position.x else -1.0
	var approach_action := "move_right" if direction > 0.0 else "move_left"
	var previous_x := player.global_position.x
	var stalled_steps := 0
	var jump_attempts := 0
	Input.action_press(approach_action)
	for step in 300:
		if int(player.climbable_count) > 0:
			break
		var progress := (player.global_position.x - previous_x) * direction
		stalled_steps = stalled_steps + 1 if progress < 0.5 else 0
		if player.is_on_floor() and (step == 0 or stalled_steps >= 4):
			jump_attempts += 1
			Input.action_press("jump")
			await _physics_steps(8)
			Input.action_release("jump")
			stalled_steps = 0
		previous_x = player.global_position.x
		await _physics_steps(1)
	Input.action_release(approach_action)
	await _physics_steps(3)
	player.set_meta("validator_approach_jumps", jump_attempts)


func _validate_drop_fixture(
	profile_index: int,
	fixture: Dictionary,
	packed_player: PackedScene
) -> void:
	_release_inputs()
	_expect(
		bool(_run_state.call("start_new_run", profile_index, 73021)),
		"Profile %d should start for %s." % [profile_index, fixture["id"]]
	)
	var source_packed := load(String(fixture["scene"])) as PackedScene
	var target_packed := load(String(fixture["target_scene"])) as PackedScene
	_expect(
		source_packed != null and target_packed != null,
		"%s room scenes should load." % fixture["id"]
	)
	if source_packed == null or target_packed == null:
		return
	var world := Node2D.new()
	world.name = "FixedDropRuntime_%s_%d" % [fixture["id"], profile_index]
	root.add_child(world)
	var target_room := target_packed.instantiate() as Node2D
	world.add_child(target_room)
	var source_room := source_packed.instantiate() as Node2D
	source_room.position = Vector2(0.0, -720.0)
	world.add_child(source_room)
	_disable_pickups(source_room)
	_disable_pickups(target_room)
	var recovery := source_room.get_node_or_null(String(fixture["recovery"])) as Marker2D
	var landing := target_room.get_node_or_null(String(fixture["target_landing"])) as StaticBody2D
	_expect(recovery != null and landing != null, "%s runtime anchors should exist." % fixture["id"])
	if recovery == null or landing == null:
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

	Input.action_press("move_left")
	for _step in 90:
		if player.global_position.x <= 1040.0:
			break
		await _physics_steps(1)
	Input.action_release("move_left")
	await _physics_steps(3)
	Input.action_press("crouch")
	await _physics_steps(2)
	Input.action_press("jump")
	await _physics_steps(1)
	Input.action_release("jump")
	await _physics_steps(5)
	Input.action_release("crouch")
	var landing_top := _collision_top(landing)
	for _step in 120:
		if player.is_on_floor() and player.global_position.y >= landing_top - 1.0:
			break
		await _physics_steps(1)
	_expect(
		player.is_on_floor()
		and absf(player.global_position.y - landing_top) <= 2.0,
		"%s profile %d should land on the lower return support; position=%s."
		% [fixture["id"], profile_index, player.global_position]
	)
	_expect(
		absf(player.global_position.x - landing.global_position.x) <= 100.0,
		"%s profile %d should remain inside the return landing; position=%s."
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


func _collision_top(body: StaticBody2D) -> float:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rectangle := shape_node.shape as RectangleShape2D if shape_node != null else null
	return (
		shape_node.global_position.y - rectangle.size.y * 0.5
		if rectangle != null else body.global_position.y
	)


func _release_inputs() -> void:
	for action in ["move_left", "move_right", "climb_up", "climb_down", "crouch", "jump", "dash"]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	_release_inputs()
	if _failures.is_empty():
		print(
			"FIXED_DROP_RUNTIME_VALIDATION_OK profiles=%d fixtures=%d"
			% [_validated_profiles.size(), _validated_fixture_ids.size()]
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
