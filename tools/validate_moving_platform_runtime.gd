extends SceneTree

const MOVING_PLATFORM_SCENE := preload("res://scenes/stages/components/MovingPlatform.tscn")

var _failures: Array[String] = []


class CarryProbe extends CharacterBody2D:
	func _ready() -> void:
		collision_layer = 4
		collision_mask = 1
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(24.0, 40.0)
		collision.shape = rectangle
		add_child(collision)

	func _physics_process(delta: float) -> void:
		velocity.y = minf(velocity.y + 900.0 * delta, 320.0)
		move_and_slide()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_anchor_data()
	await _validate_room_contract()
	_validate_cycle_and_reset()
	await _validate_player_carry()
	_finish()


func _validate_anchor_data() -> void:
	var valid := _moving_contract()
	_expect(valid.validate_definition().is_empty(), "valid moving-platform data should pass")

	var invalid := _moving_contract()
	invalid.end_position = invalid.start_position
	invalid.travel_time = 0.0
	invalid.wait_pad_ids = [&"entry_wait"]
	invalid.fall_recovery_id = &""
	invalid.checkpoint_safe_radius = 0.0
	var errors := invalid.validate_definition()
	_expect(errors.size() >= 5, "invalid endpoints, timing, pads, recovery, and radius should fail")


func _validate_room_contract() -> void:
	var fixture := _build_room_fixture()
	var host := fixture["host"] as RoomTemplateHost
	var data := fixture["data"] as RoomTemplateData
	root.add_child(host)
	var errors := host.configure(data)
	_expect(errors.is_empty(), "authored moving-platform room should validate: %s" % "; ".join(errors))

	var contract := data.moving_platform_anchors[0]
	contract.end_position.x += 12.0
	errors = host.configure(data)
	_expect(_contains(errors, "endpoints do not match"), "room validation should reject endpoint drift")
	contract.end_position.x -= 12.0

	var recovery := host.get_anchor_by_id(&"Recovery", &"bridge_recovery")
	recovery.position = Vector2(320.0, 220.0)
	errors = host.configure(data)
	_expect(_contains(errors, "enters its recovery safe radius"), "platform path should stay outside recovery safety")
	host.queue_free()
	await process_frame


func _validate_cycle_and_reset() -> void:
	var platform := MOVING_PLATFORM_SCENE.instantiate() as MovingPlatform
	_expect(platform != null, "moving-platform scene should instantiate")
	if platform == null:
		return
	platform.path_id = &"cycle_fixture"
	platform.position = Vector2(10.0, 20.0)
	platform.travel_offset = Vector2(100.0, 0.0)
	platform.travel_time = 1.0
	platform.start_wait_time = 0.2
	platform.end_wait_time = 0.3
	root.add_child(platform)
	platform.set_physics_process(false)
	platform.sync_to_physics = false
	_expect(platform.position.is_equal_approx(Vector2(10.0, 20.0)), "platform should start at authored endpoint")
	_expect(platform.get_runtime_snapshot()["state"] == "wait_start", "platform should begin in start wait")

	platform.advance_time(0.2)
	_expect(platform.get_runtime_snapshot()["state"] == "travel_to_end", "start wait should precede travel")
	platform.advance_time(0.5)
	_expect(platform.position.is_equal_approx(Vector2(60.0, 20.0)), "half travel should use stable linear position")
	platform.advance_time(0.5)
	_expect(platform.position.is_equal_approx(Vector2(110.0, 20.0)), "platform should reach authored end")
	_expect(platform.get_runtime_snapshot()["state"] == "wait_end", "end wait should follow outbound travel")
	platform.advance_time(0.3)
	platform.advance_time(0.4)
	_expect(platform.position.is_equal_approx(Vector2(70.0, 20.0)), "return travel should mirror outbound travel")
	platform.reset_platform()
	_expect(platform.position.is_equal_approx(Vector2(10.0, 20.0)), "reset should restore authored start")
	_expect(platform.get_runtime_snapshot()["state"] == "wait_start", "reset should restore cycle state")
	platform.free()


func _validate_player_carry() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var platform := MOVING_PLATFORM_SCENE.instantiate() as MovingPlatform
	platform.path_id = &"carry_fixture"
	platform.position = Vector2(0.0, 100.0)
	platform.travel_offset = Vector2(180.0, 0.0)
	platform.travel_time = 0.6
	platform.start_wait_time = 0.1
	platform.end_wait_time = 0.2
	world.add_child(platform)
	var probe := CarryProbe.new()
	probe.position = Vector2(0.0, 68.0)
	world.add_child(probe)
	await _physics_steps(5)
	var initial_platform_x := platform.position.x
	var initial_probe_x := probe.position.x
	var initial_relative_x := probe.position.x - platform.position.x
	await _physics_steps(22)
	var platform_delta := platform.position.x - initial_platform_x
	var probe_delta := probe.position.x - initial_probe_x
	_expect(platform_delta > 40.0, "carry fixture platform should enter outbound travel")
	_expect(probe_delta > 35.0, "standing player should be carried by AnimatableBody2D motion")
	_expect(
		absf((probe.position.x - platform.position.x) - initial_relative_x) < 8.0,
		"carried player should keep a stable horizontal offset"
	)
	world.queue_free()
	await process_frame


func _build_room_fixture() -> Dictionary:
	var host := RoomTemplateHost.new()
	host.name = "MovingRoomFixture"
	host.room_id = &"moving_room_fixture"
	for root_name in RoomTemplateHost.REQUIRED_ROOTS:
		var child := Node2D.new()
		child.name = root_name
		host.add_child(child)
	var anchors := host.get_node("Anchors")
	for group_name in RoomTemplateHost.REQUIRED_ANCHOR_GROUPS:
		var group := Node2D.new()
		group.name = group_name
		anchors.add_child(group)

	var socket_entry := Marker2D.new()
	socket_entry.name = "Entry"
	socket_entry.position = Vector2(0.0, 500.0)
	host.get_node("Anchors/Sockets").add_child(socket_entry)
	var socket_exit := Marker2D.new()
	socket_exit.name = "Exit"
	socket_exit.position = Vector2(1280.0, 500.0)
	host.get_node("Anchors/Sockets").add_child(socket_exit)

	var entry_wait := _room_anchor(&"entry_wait", &"objective", Vector2(120.0, 220.0), 80.0)
	var exit_wait := _room_anchor(&"exit_wait", &"objective", Vector2(520.0, 220.0), 80.0)
	host.get_node("Anchors/Objective").add_child(entry_wait)
	host.get_node("Anchors/Objective").add_child(exit_wait)
	var recovery := _room_anchor(&"bridge_recovery", &"recovery", Vector2(320.0, 500.0), 110.0)
	host.get_node("Anchors/Recovery").add_child(recovery)

	var moving_root := Node2D.new()
	moving_root.name = "MovingPlatforms"
	host.add_child(moving_root)
	var platform := MOVING_PLATFORM_SCENE.instantiate() as MovingPlatform
	platform.path_id = &"bridge_cycle"
	platform.position = Vector2(200.0, 220.0)
	platform.travel_offset = Vector2(240.0, 0.0)
	platform.travel_time = 1.8
	platform.start_wait_time = 0.45
	platform.end_wait_time = 0.45
	platform.set_physics_process(false)
	moving_root.add_child(platform)

	var data := RoomTemplateData.new()
	data.id = host.room_id
	data.display_name = "Moving Room Fixture"
	data.scene = PackedScene.new()
	data.role = &"traversal"
	data.stage_tags = [&"fixture"]
	data.bounds = Rect2(0.0, 0.0, 1280.0, 720.0)
	data.entry_sockets = [_socket(&"entry", &"left", socket_entry.position)]
	data.exit_sockets = [_socket(&"exit", &"right", socket_exit.position)]
	data.recovery_anchor_ids = [&"bridge_recovery"]
	data.moving_platform_anchors = [_moving_contract()]
	return {"host": host, "data": data}


func _moving_contract() -> RoomMovingPlatformAnchorData:
	var contract := RoomMovingPlatformAnchorData.new()
	contract.path_id = &"bridge_cycle"
	contract.start_position = Vector2(200.0, 220.0)
	contract.end_position = Vector2(440.0, 220.0)
	contract.travel_time = 1.8
	contract.start_wait_time = 0.45
	contract.end_wait_time = 0.45
	contract.wait_pad_ids = [&"entry_wait", &"exit_wait"]
	contract.fall_recovery_id = &"bridge_recovery"
	contract.checkpoint_safe_radius = 96.0
	return contract


func _socket(id: StringName, direction: StringName, local_position: Vector2) -> RoomSocketData:
	var socket := RoomSocketData.new()
	socket.id = id
	socket.direction = direction
	socket.local_position = local_position
	socket.support_top = local_position.y
	return socket


func _room_anchor(
	id: StringName,
	type: StringName,
	local_position: Vector2,
	safe_radius: float
) -> RoomAnchor:
	var anchor := RoomAnchor.new()
	anchor.name = String(id).to_pascal_case()
	anchor.anchor_id = id
	anchor.anchor_type = type
	anchor.position = local_position
	anchor.safe_radius = safe_radius
	return anchor


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _contains(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if fragment in error:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MOVING_PLATFORM_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
