extends SceneTree

const ROOM_PATHS := {
	&"movement_check": "res://scenes/rooms/flooded_works/generated/MovementCheck3D.tscn",
	&"foundry_approach": "res://scenes/rooms/flooded_works/generated/FoundryApproach3D.tscn",
	&"pump_gallery": "res://scenes/rooms/flooded_works/generated/PumpGallery3D.tscn",
	&"pressure_vault": "res://scenes/rooms/flooded_works/generated/PressureVault3D.tscn",
	&"slime_king_reservoir": "res://scenes/rooms/flooded_works/generated/SlimeKingReservoir3D.tscn",
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_validate_generated_rooms()
	await _validate_persistent_route()
	if failures.is_empty():
		print("PASS: five generated room contracts and 20 persistent Movement Check/Foundry round trips")
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _validate_generated_rooms() -> void:
	var silhouettes: Dictionary = {}
	for room_id: StringName in ROOM_PATHS:
		var packed := load(ROOM_PATHS[room_id]) as PackedScene
		_expect(packed != null, "room scene does not load: %s" % room_id)
		if packed == null:
			continue
		var room := packed.instantiate() as FloodedWorksRoom3D
		root.add_child(room)
		_expect(room.room_id == room_id, "%s exports the wrong room_id" % room_id)
		_expect(room.camera_bounds.size.x > 0.0 and room.camera_bounds.size.y > 0.0, "%s has no camera bounds" % room_id)
		_expect(room.find_children("*", "Traveler3D", true, false).is_empty(), "%s owns a Traveler" % room_id)
		_expect(room.find_children("*", "Camera3D", true, false).is_empty(), "%s owns a camera" % room_id)
		var region := room.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
		_expect(region != null and region.navigation_mesh != null, "%s has no baked navigation mesh" % room_id)
		if region != null and region.navigation_mesh != null:
			_expect(region.navigation_mesh.get_polygon_count() > 0, "%s navigation mesh has no polygons" % room_id)
		var ground_count := room.get_node("Ground").get_child_count()
		_expect(ground_count < int(room.map_size_m.x * room.map_size_m.y * 0.35), "%s still reads as per-cell geometry" % room_id)
		_validate_entry_landing_strips(room)
		silhouettes["%s:%s:%s" % [room.map_size_m, ground_count, room.get_node("Structures").get_child_count()]] = true
		room.queue_free()
	_expect(silhouettes.size() == ROOM_PATHS.size(), "room silhouettes are not structurally distinct")


func _validate_persistent_route() -> void:
	var pivot_scene := load("res://scenes/main/PivotRoot.tscn") as PackedScene
	var pivot := pivot_scene.instantiate()
	root.add_child(pivot)
	await process_frame
	await create_timer(0.22).timeout
	var runtime := pivot.get_node("FloorRuntime3D") as FloorRuntime3D
	var traveler_id := runtime.traveler.get_instance_id()
	var camera_id := runtime.camera_rig.get_instance_id()
	var hud_id := runtime.get_node("HUD").get_instance_id()
	var ranged_value := runtime.get_node("HUD/Root/Status/RangedValue") as Label
	_expect(ranged_value.text.contains("∞"), "ranged HUD does not communicate unlimited arrows")
	_expect(runtime.current_room_id == &"movement_check", "floor did not start in Movement Check")
	for _cycle in 20:
		await runtime._on_transition_requested(&"foundry_approach", &"foundry_south")
		_expect(runtime.current_room_id == &"foundry_approach", "transition did not reach Foundry")
		await runtime._on_transition_requested(&"movement_check", &"movement_north")
		_expect(runtime.current_room_id == &"movement_check", "return transition did not reach Movement Check")
	_expect(runtime.traveler.get_instance_id() == traveler_id, "Traveler was replaced during transitions")
	_expect(runtime.camera_rig.get_instance_id() == camera_id, "camera was replaced during transitions")
	_expect(runtime.get_node("HUD").get_instance_id() == hud_id, "HUD was replaced during transitions")
	_expect(get_nodes_in_group(&"room_gates").size() == runtime.current_room.get_gates().size(), "orphan room gates remain")
	_expect(get_nodes_in_group(&"combat_projectiles").is_empty(), "orphan projectiles remain")
	pivot.queue_free()
	await process_frame


func _validate_entry_landing_strips(room: FloodedWorksRoom3D) -> void:
	for entry: Marker3D in room.get_node("EntryMarkers").get_children():
		for prop: Marker3D in room.get_node("Props").get_children():
			var delta := Vector2(entry.position.x - prop.position.x, entry.position.z - prop.position.z)
			_expect(delta.length() >= 4.0, "%s/%s has prop %s inside the 4 m landing strip" % [room.room_id, entry.name, prop.name])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
