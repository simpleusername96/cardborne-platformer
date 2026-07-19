extends SceneTree

const ParserScript := preload("res://tools/tiled/tiled_source_parser.gd")
const RoomScript := preload("res://scripts/rooms/flooded_works_room_3d.gd")
const GateScript := preload("res://scripts/rooms/room_gate_3d.gd")
const FLOOR_ALBEDO := preload("res://art/world/flooded_works/isometric/surfaces/foundry-architecture-albedo-v1.png")

const MAP_DIR := "res://data/rooms/flooded_works/tiled"
const WORLD_PATH := MAP_DIR + "/flooded-works-floor1.world"
const TILESET_PATH := "res://art/world/flooded_works/tiled/flooded-works-authoring.tsx"
const CATALOG_PATH := "res://data/rooms/flooded_works/tiled-room-build-catalog.tres"
const OUTPUT_DIR := "res://scenes/rooms/flooded_works/generated"
const MANIFEST_PATH := "res://data/rooms/flooded_works/generated-room-build-manifest.json"
const STAGING_DIR := "res://.godot/flooded-works-room-build-staging"
const STAGING_MANIFEST_PATH := STAGING_DIR + "/generated-room-build-manifest.json"
const ROOM_OUTPUTS := {
	"movement_check": "MovementCheck3D.tscn",
	"foundry_approach": "FoundryApproach3D.tscn",
	"pump_gallery": "PumpGallery3D.tscn",
	"pressure_vault": "PressureVault3D.tscn",
	"slime_king_reservoir": "SlimeKingReservoir3D.tscn",
}
const CELL_SIZE := 1.0
const TILE_PIXELS := 64.0

var _parser: TiledSourceParser = ParserScript.new()
var _catalog: TiledRoomBuildCatalog
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_catalog = load(CATALOG_PATH) as TiledRoomBuildCatalog
	if _catalog == null:
		_fail("Cannot load build catalog: %s" % CATALOG_PATH)
		_finish()
		return
	var sources := _load_sources()
	if _failures.is_empty():
		_validate_cross_room_contract(sources)
	if not _failures.is_empty():
		_finish()
		return
	var write_mode := OS.get_cmdline_user_args().has("--write") or OS.get_cmdline_args().has("--write")
	if write_mode:
		await _write_all_rooms(sources)
	else:
		_check_generated_outputs(sources)
	_finish()


func _load_sources() -> Dictionary:
	var sources: Dictionary = {}
	var files := DirAccess.get_files_at(MAP_DIR)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tmj"):
			continue
		var result := _parser.parse_map(MAP_DIR.path_join(file_name))
		if not result.ok:
			for message: String in result.errors:
				_fail(message)
			continue
		var room_id := String(result.properties.room_id)
		if not ROOM_OUTPUTS.has(room_id):
			_fail("Unknown room_id %s in %s" % [room_id, file_name])
			continue
		if sources.has(room_id):
			_fail("Duplicate room_id: %s" % room_id)
			continue
		_validate_objects(result)
		sources[room_id] = result
	for room_id: String in ROOM_OUTPUTS:
		if not sources.has(room_id):
			_fail("Missing production source for room_id: %s" % room_id)
	return sources


func _validate_objects(source: Dictionary) -> void:
	var seen_ids: Dictionary = {}
	for layer_name: String in ["structures", "connections", "spawns", "props", "objectives"]:
		var layer: Dictionary = source.layers[layer_name]
		for object_variant: Variant in layer.get("objects", []):
			if not object_variant is Dictionary:
				_fail("%s/%s contains a non-object" % [source.path, layer_name])
				continue
			var object: Dictionary = object_variant
			var properties := _parser.properties_to_dictionary(object.get("properties", []))
			var anchor_id := String(properties.get("anchor_id", properties.get("socket_id", "")))
			if anchor_id.is_empty():
				_fail("%s/%s object %s lacks anchor_id or socket_id" % [source.path, layer_name, object.get("id")])
			elif seen_ids.has(anchor_id):
				_fail("%s duplicates stable ID %s" % [source.path, anchor_id])
			else:
				seen_ids[anchor_id] = true
			var gid := int(object.get("gid", 0))
			if gid & TiledSourceParser.GID_TRANSFORM_MASK:
				_fail("%s object %s uses forbidden GID transform flags" % [source.path, object.get("id")])
			var local_id := _parser.local_id_from_gid(gid)
			match layer_name:
				"structures":
					if local_id not in [8, 9]:
						_fail("%s structure uses local tile ID %d" % [source.path, local_id])
					if not _catalog.registered_archetypes.has(String(properties.get("archetype_id", ""))):
						_fail("%s has unknown archetype_id %s" % [source.path, properties.get("archetype_id")])
				"connections":
					if local_id not in [10, 11]:
						_fail("%s connection uses local tile ID %d" % [source.path, local_id])
					for required: String in ["target_room_id", "target_socket_id", "facing"]:
						if String(properties.get(required, "")).is_empty():
							_fail("%s connection %s lacks %s" % [source.path, anchor_id, required])
					if String(properties.get("facing", "")) not in ["north", "east", "south", "west"]:
						_fail("%s connection %s has invalid facing" % [source.path, anchor_id])
				"spawns":
					if local_id not in [12, 13]:
						_fail("%s spawn uses local tile ID %d" % [source.path, local_id])
					if not _catalog.registered_enemy_roles.has(String(properties.get("enemy_role", ""))):
						_fail("%s has unknown enemy_role %s" % [source.path, properties.get("enemy_role")])
				"props":
					if local_id != 14:
						_fail("%s prop uses local tile ID %d" % [source.path, local_id])
					if not _catalog.registered_components.has(String(properties.get("component_id", ""))):
						_fail("%s has unknown component_id %s" % [source.path, properties.get("component_id")])
				"objectives":
					if local_id != 15:
						_fail("%s objective uses local tile ID %d" % [source.path, local_id])
					if not _catalog.registered_objective_roles.has(String(properties.get("objective_role", ""))):
						_fail("%s has unknown objective_role %s" % [source.path, properties.get("objective_role")])
	var bounds_objects: Array = source.layers.camera_bounds.get("objects", [])
	if bounds_objects.size() != 1 or String(bounds_objects[0].get("name", "")) != "room_bounds":
		_fail("%s must contain exactly one camera_bounds/room_bounds rectangle" % source.path)


func _validate_cross_room_contract(sources: Dictionary) -> void:
	var sockets: Dictionary = {}
	for room_id: String in sources:
		var source: Dictionary = sources[room_id]
		for object: Dictionary in source.layers.connections.get("objects", []):
			var properties := _parser.properties_to_dictionary(object.get("properties", []))
			var key := "%s/%s" % [room_id, properties.socket_id]
			sockets[key] = {"room_id": room_id, "object": object, "properties": properties}
	for key: String in sockets:
		var socket: Dictionary = sockets[key]
		var properties: Dictionary = socket.properties
		var target_key := "%s/%s" % [properties.target_room_id, properties.target_socket_id]
		if not sockets.has(target_key):
			_fail("Socket %s targets missing %s" % [key, target_key])
			continue
		var target: Dictionary = sockets[target_key]
		var target_properties: Dictionary = target.properties
		if String(target_properties.target_room_id) != socket.room_id or String(target_properties.target_socket_id) != String(properties.socket_id):
			_fail("Socket %s is not reciprocal with %s" % [key, target_key])
		var opposites := {"north": "south", "south": "north", "east": "west", "west": "east"}
		if target_properties.facing != opposites.get(properties.facing, ""):
			_fail("Socket %s does not face opposite %s" % [key, target_key])
		if not is_equal_approx(float(socket.object.width), float(target.object.width)):
			_fail("Socket %s width differs from %s" % [key, target_key])
	_validate_world_alignment(sources, sockets)


func _validate_world_alignment(sources: Dictionary, sockets: Dictionary) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH))
	if not parsed is Dictionary:
		_fail("World file is missing or invalid: %s" % WORLD_PATH)
		return
	var offsets: Dictionary = {}
	for entry: Dictionary in parsed.get("maps", []):
		var file_name := String(entry.get("fileName", ""))
		for room_id: String in sources:
			if String(sources[room_id].path).get_file() == file_name:
				offsets[room_id] = Vector2(float(entry.x), float(entry.y))
	for room_id: String in sources:
		if not offsets.has(room_id):
			_fail("World file does not include %s" % room_id)
	for key: String in sockets:
		var socket: Dictionary = sockets[key]
		var target_key := "%s/%s" % [socket.properties.target_room_id, socket.properties.target_socket_id]
		if not sockets.has(target_key) or not offsets.has(socket.room_id) or not offsets.has(socket.properties.target_room_id):
			continue
		var target: Dictionary = sockets[target_key]
		var center: Vector2 = offsets[socket.room_id] + Vector2(float(socket.object.x) + float(socket.object.width) * 0.5, float(socket.object.y))
		var target_center: Vector2 = offsets[target.room_id] + Vector2(float(target.object.x) + float(target.object.width) * 0.5, float(target.object.y))
		if center.distance_to(target_center) > 1.0:
			_fail("World sockets %s and %s are %.1f px apart" % [key, target_key, center.distance_to(target_center)])


func _write_all_rooms(sources: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STAGING_DIR))
	_cleanup_staging_files()
	var manifest := {
		"schema_version": 1,
		"generator_sha256": FileAccess.get_sha256("res://tools/tiled/build_flooded_works_rooms.gd"),
		"tileset_sha256": FileAccess.get_sha256(TILESET_PATH),
		"catalog_sha256": FileAccess.get_sha256(CATALOG_PATH),
		"world_sha256": FileAccess.get_sha256(WORLD_PATH),
		"rooms": {},
	}
	for room_id: String in ROOM_OUTPUTS:
		var source: Dictionary = sources[room_id]
		var room := _build_room(source)
		root.add_child(room)
		await process_frame
		_bake_navigation(room)
		root.remove_child(room)
		var packed := PackedScene.new()
		var pack_error := packed.pack(room)
		if pack_error != OK:
			_fail("Could not pack %s: %s" % [room_id, error_string(pack_error)])
			room.free()
			continue
		var output_path := OUTPUT_DIR.path_join(ROOM_OUTPUTS[room_id])
		var staging_path := STAGING_DIR.path_join(ROOM_OUTPUTS[room_id])
		var save_error := ResourceSaver.save(packed, staging_path)
		room.free()
		if save_error != OK:
			_fail("Could not stage %s: %s" % [output_path, error_string(save_error)])
			continue
		manifest.rooms[room_id] = {
			"source": source.path,
			"source_sha256": FileAccess.get_sha256(source.path),
			"output": output_path,
			"output_sha256": FileAccess.get_sha256(staging_path),
		}
	if not _failures.is_empty():
		_cleanup_staging_files()
		return
	var file := FileAccess.open(STAGING_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_fail("Cannot stage build manifest: %s" % STAGING_MANIFEST_PATH)
		_cleanup_staging_files()
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	var staged_pairs: Array[Dictionary] = []
	for room_id: String in ROOM_OUTPUTS:
		staged_pairs.append({
			"source": STAGING_DIR.path_join(ROOM_OUTPUTS[room_id]),
			"destination": OUTPUT_DIR.path_join(ROOM_OUTPUTS[room_id]),
		})
	staged_pairs.append({"source": STAGING_MANIFEST_PATH, "destination": MANIFEST_PATH})
	if not _commit_staged_files(staged_pairs):
		_cleanup_staging_files()
		return
	_cleanup_staging_files()
	print("PASS: wrote %d deterministic Flooded Works room scenes" % sources.size())


func _commit_staged_files(pairs: Array[Dictionary]) -> bool:
	var backups: Dictionary = {}
	var existed: Dictionary = {}
	var committed: Array[String] = []
	for pair: Dictionary in pairs:
		var destination := String(pair.destination)
		existed[destination] = FileAccess.file_exists(destination)
		if existed[destination]:
			backups[destination] = FileAccess.get_file_as_bytes(destination)
		var source_bytes := FileAccess.get_file_as_bytes(String(pair.source))
		var write_error := _write_bytes(destination, source_bytes)
		committed.append(destination)
		if write_error != OK:
			for rollback_path: String in committed:
				if bool(existed.get(rollback_path, false)):
					_write_bytes(rollback_path, backups[rollback_path])
				else:
					DirAccess.remove_absolute(ProjectSettings.globalize_path(rollback_path))
			_fail("Could not commit generated build; restored previous outputs after %s: %s" % [destination, error_string(write_error)])
			return false
	return true


func _write_bytes(path: String, bytes: PackedByteArray) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var result := file.get_error()
	file.close()
	return result


func _cleanup_staging_files() -> void:
	for file_name: String in ROOM_OUTPUTS.values():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STAGING_DIR.path_join(file_name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STAGING_MANIFEST_PATH))


func _check_generated_outputs(sources: Dictionary) -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_fail("Generated build manifest is missing; run with --write")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		_fail("Generated build manifest is invalid JSON")
		return
	var manifest: Dictionary = parsed
	var shared_hashes := {
		"generator_sha256": FileAccess.get_sha256("res://tools/tiled/build_flooded_works_rooms.gd"),
		"tileset_sha256": FileAccess.get_sha256(TILESET_PATH),
		"catalog_sha256": FileAccess.get_sha256(CATALOG_PATH),
		"world_sha256": FileAccess.get_sha256(WORLD_PATH),
	}
	for key: String in shared_hashes:
		if String(manifest.get(key, "")) != String(shared_hashes[key]):
			_fail("Build manifest %s is stale" % key)
	var room_manifest: Dictionary = manifest.get("rooms", {})
	for room_id: String in sources:
		if not room_manifest.has(room_id):
			_fail("Build manifest lacks room %s" % room_id)
			continue
		var entry: Dictionary = room_manifest[room_id]
		if String(entry.get("source_sha256", "")) != FileAccess.get_sha256(sources[room_id].path):
			_fail("Generated room %s has stale source hash" % room_id)
		var output_path := String(entry.get("output", ""))
		if not FileAccess.file_exists(output_path):
			_fail("Generated room output is missing: %s" % output_path)
		elif String(entry.get("output_sha256", "")) != FileAccess.get_sha256(output_path):
			_fail("Generated room output drifted: %s" % output_path)
	if _failures.is_empty():
		print("PASS: Tiled sources, reciprocal sockets, world alignment, and generated hashes")


func _build_room(source: Dictionary) -> FloodedWorksRoom3D:
	var map: Dictionary = source.map
	var room := FloodedWorksRoom3D.new()
	room.name = _pascal_case(String(source.properties.room_id))
	room.set_script(RoomScript)
	room.room_id = StringName(source.properties.room_id)
	room.map_size_m = Vector2(float(map.width), float(map.height))
	room.source_path = source.path
	room.source_sha256 = FileAccess.get_sha256(source.path)
	var bounds_object: Dictionary = source.layers.camera_bounds.objects[0]
	room.camera_bounds = Rect2(
		float(bounds_object.x) / TILE_PIXELS - float(map.width) * 0.5,
		float(bounds_object.y) / TILE_PIXELS - float(map.height) * 0.5,
		float(bounds_object.width) / TILE_PIXELS,
		float(bounds_object.height) / TILE_PIXELS,
	)
	room.set_meta("generated_by", "build_flooded_works_rooms_v1")
	var ground_root := _node("Ground", room, room)
	var structures_root := _node("Structures", room, room)
	var connections_root := _node("Connections", room, room)
	var entries_root := _node("EntryMarkers", room, room)
	var spawns_root := _node("Spawns", room, room)
	var props_root := _node("Props", room, room)
	var objectives_root := _node("Objectives", room, room)
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	_add_owned(room, nav_region, room)
	_build_ground(source, ground_root, structures_root, room)
	_build_structures(source, structures_root, room)
	_build_connections(source, connections_root, entries_root, room)
	_build_markers(source, "spawns", spawns_root, room)
	_build_markers(source, "props", props_root, room)
	_build_markers(source, "objectives", objectives_root, room)
	return room


func _build_ground(source: Dictionary, ground_root: Node3D, structures_root: Node3D, owner: Node) -> void:
	var map: Dictionary = source.map
	var width := int(map.width)
	var height := int(map.height)
	var data: Array = source.layers.ground.data
	var tiles: Dictionary = source.tileset.tiles
	var visited: Array[bool] = []
	visited.resize(data.size())
	visited.fill(false)
	var walkable: Array[bool] = []
	walkable.resize(data.size())
	for index in data.size():
		var local_id := _parser.local_id_from_gid(int(data[index]))
		walkable[index] = bool(tiles[local_id].get("walkable", false))
	for y in height:
		for x in width:
			var index := y * width + x
			if visited[index]:
				continue
			var local_id := _parser.local_id_from_gid(int(data[index]))
			var tile_properties: Dictionary = tiles[local_id]
			var key := "%s|%s" % [tile_properties.get("walkable", false), tile_properties.runtime_role]
			var run_width := 1
			while x + run_width < width and not visited[index + run_width] and _cell_key(data, tiles, index + run_width) == key:
				run_width += 1
			var run_height := 1
			while y + run_height < height and _row_matches(data, tiles, visited, width, x, y + run_height, run_width, key):
				run_height += 1
			for mark_y in range(y, y + run_height):
				for mark_x in range(x, x + run_width):
					visited[mark_y * width + mark_x] = true
			if local_id == 6:
				continue
			_add_surface_chunk(ground_root, owner, x, y, run_width, run_height, width, height, tile_properties, local_id)
	var gate_edges := _gate_edge_keys(source)
	for y in height:
		for x in width:
			if not walkable[y * width + x]:
				continue
			for side: String in ["north", "south", "west", "east"]:
				if gate_edges.has("%s:%d:%d" % [side, x, y]):
					continue
				var neighbor := _neighbor(x, y, side)
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height or not walkable[int(neighbor.y) * width + int(neighbor.x)]:
					_add_boundary(structures_root, owner, x, y, width, height, side)


func _add_surface_chunk(parent: Node3D, owner: Node, x: int, y: int, cells_w: int, cells_h: int, map_w: int, map_h: int, tile_properties: Dictionary, local_id: int) -> void:
	var size := Vector3(float(cells_w), _catalog.floor_height, float(cells_h))
	var center := Vector3(float(x) + float(cells_w) * 0.5 - float(map_w) * 0.5, -_catalog.floor_height * 0.5, float(y) + float(cells_h) * 0.5 - float(map_h) * 0.5)
	var walkable := bool(tile_properties.get("walkable", false))
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _surface_material(local_id)
	if walkable:
		var body := StaticBody3D.new()
		body.name = "Surface_%d_%d" % [x, y]
		body.position = center
		body.collision_layer = 1
		body.collision_mask = 0
		_add_owned(parent, body, owner)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		mesh_instance.mesh = mesh
		_add_owned(body, mesh_instance, owner)
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		_add_owned(body, collision, owner)
	else:
		var visual := MeshInstance3D.new()
		visual.name = "Water_%d_%d" % [x, y]
		visual.position = center - Vector3.UP * 0.08
		visual.mesh = mesh
		_add_owned(parent, visual, owner)


func _build_structures(source: Dictionary, parent: Node3D, owner: Node) -> void:
	for object: Dictionary in source.layers.structures.objects:
		var properties := _parser.properties_to_dictionary(object.get("properties", []))
		var width := float(object.width) / TILE_PIXELS
		var depth := float(object.height) / TILE_PIXELS
		var height := _catalog.low_cover_height if properties.archetype_id == "low_cover" else _catalog.standard_wall_height
		if properties.get("height_class", "standard") == "cutaway" and properties.archetype_id == "wall":
			height = _catalog.cutaway_wall_height
		_add_box_body(parent, owner, String(properties.anchor_id), _object_center(source.map, object, height), Vector3(width, height, depth), _surface_material(0))


func _build_connections(source: Dictionary, parent: Node3D, entries: Node3D, owner: Node) -> void:
	for object: Dictionary in source.layers.connections.objects:
		var properties := _parser.properties_to_dictionary(object.get("properties", []))
		var gate := RoomGate3D.new()
		gate.name = String(properties.socket_id)
		gate.socket_id = StringName(properties.socket_id)
		gate.target_room_id = StringName(properties.target_room_id)
		gate.target_socket_id = StringName(properties.target_socket_id)
		gate.facing = StringName(properties.facing)
		gate.position = Vector3(
			float(object.x) / TILE_PIXELS + float(object.width) / (TILE_PIXELS * 2.0) - float(source.map.width) * 0.5,
			0.0,
			float(object.y) / TILE_PIXELS - float(source.map.height) * 0.5
		)
		gate.collision_layer = 0
		gate.collision_mask = 2
		_add_owned(parent, gate, owner)
		var trigger := CollisionShape3D.new()
		trigger.name = "Trigger"
		trigger.position.y = 0.8
		var trigger_shape := BoxShape3D.new()
		trigger_shape.size = Vector3(float(object.width) / TILE_PIXELS, 1.6, 1.8)
		trigger.shape = trigger_shape
		_add_owned(gate, trigger, owner)
		_add_gate_visual(gate, owner, float(object.width) / TILE_PIXELS)
		var marker := Marker3D.new()
		marker.name = String(properties.socket_id)
		marker.position = gate.position + _facing_vector(String(properties.facing)) * -1.5
		_add_owned(entries, marker, owner)


func _build_markers(source: Dictionary, layer_name: String, parent: Node3D, owner: Node) -> void:
	for object: Dictionary in source.layers[layer_name].objects:
		var properties := _parser.properties_to_dictionary(object.get("properties", []))
		var marker := Marker3D.new()
		marker.name = String(properties.get("anchor_id", "marker_%s" % object.id))
		marker.position = _object_center(source.map, object, 0.0)
		for key: String in properties:
			marker.set_meta(key, properties[key])
		_add_owned(parent, marker, owner)


func _bake_navigation(room: FloodedWorksRoom3D) -> void:
	var region := room.get_node("NavigationRegion3D") as NavigationRegion3D
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.agent_height = 2.0
	navigation_mesh.agent_radius = 0.5
	navigation_mesh.agent_max_climb = 0.25
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	var source_geometry := NavigationMeshSourceGeometryData3D.new()
	NavigationMeshGenerator.parse_source_geometry_data(navigation_mesh, source_geometry, room)
	NavigationMeshGenerator.bake_from_source_geometry_data(navigation_mesh, source_geometry)
	region.navigation_mesh = navigation_mesh


func _add_boundary(parent: Node3D, owner: Node, x: int, y: int, map_w: int, map_h: int, side: String) -> void:
	var thickness := _catalog.boundary_thickness
	var size := Vector3(1.0 + thickness, _catalog.boundary_height, thickness)
	var position := Vector3(float(x) + 0.5 - float(map_w) * 0.5, _catalog.boundary_height * 0.5, float(y) - float(map_h) * 0.5)
	if side == "south":
		position.z += 1.0
	elif side == "west" or side == "east":
		size = Vector3(thickness, _catalog.boundary_height, 1.0 + thickness)
		position = Vector3(float(x) - float(map_w) * 0.5, _catalog.boundary_height * 0.5, float(y) + 0.5 - float(map_h) * 0.5)
		if side == "east":
			position.x += 1.0
	_add_box_body(parent, owner, "Boundary_%s_%d_%d" % [side, x, y], position, size, _surface_material(0))


func _add_gate_visual(gate: Node3D, owner: Node, width: float) -> void:
	var material := _surface_material(3)
	for x in [-width * 0.5 + 0.18, width * 0.5 - 0.18]:
		var pillar := MeshInstance3D.new()
		pillar.position = Vector3(x, 0.9, 0.0)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.36, 1.8, 0.45)
		mesh.material = material
		pillar.mesh = mesh
		_add_owned(gate, pillar, owner)
	var lintel := MeshInstance3D.new()
	lintel.position = Vector3(0.0, 1.65, 0.0)
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(width, 0.3, 0.45)
	lintel_mesh.material = material
	lintel.mesh = lintel_mesh
	_add_owned(gate, lintel, owner)


func _add_box_body(parent: Node3D, owner: Node, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	_add_owned(parent, body, owner)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	_add_owned(body, mesh_instance, owner)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	_add_owned(body, collision, owner)


func _surface_material(local_id: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.92
	material.metallic = 0.06
	if local_id == 4 or local_id == 5:
		material.albedo_color = Color("17383f")
		material.metallic = 0.0
	elif local_id == 7:
		material.albedo_color = Color("59433b")
	elif local_id == 3:
		material.albedo_texture = FLOOR_ALBEDO
		material.albedo_color = Color("b5cbc5")
	else:
		material.albedo_texture = FLOOR_ALBEDO
		material.albedo_color = Color("9db7b2")
	if material.albedo_texture != null:
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * 0.05
	return material


func _cell_key(data: Array, tiles: Dictionary, index: int) -> String:
	var local_id := _parser.local_id_from_gid(int(data[index]))
	var tile: Dictionary = tiles[local_id]
	return "%s|%s" % [tile.get("walkable", false), tile.runtime_role]


func _row_matches(data: Array, tiles: Dictionary, visited: Array[bool], width: int, x: int, y: int, run_width: int, key: String) -> bool:
	for row_x in range(x, x + run_width):
		var index := y * width + row_x
		if visited[index] or _cell_key(data, tiles, index) != key:
			return false
	return true


func _gate_edge_keys(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var map: Dictionary = source.map
	for object: Dictionary in source.layers.connections.objects:
		var properties := _parser.properties_to_dictionary(object.properties)
		var start_x := int(round(float(object.x) / TILE_PIXELS))
		var cells := int(round(float(object.width) / TILE_PIXELS))
		if properties.facing == "north":
			for x in range(start_x, start_x + cells):
				result["north:%d:0" % x] = true
		elif properties.facing == "south":
			for x in range(start_x, start_x + cells):
				result["south:%d:%d" % [x, int(map.height) - 1]] = true
	return result


func _neighbor(x: int, y: int, side: String) -> Vector2i:
	match side:
		"north": return Vector2i(x, y - 1)
		"south": return Vector2i(x, y + 1)
		"west": return Vector2i(x - 1, y)
		_: return Vector2i(x + 1, y)


func _object_center(map: Dictionary, object: Dictionary, height: float) -> Vector3:
	return Vector3(
		float(object.x) / TILE_PIXELS + float(object.width) / TILE_PIXELS * 0.5 - float(map.width) * 0.5,
		height * 0.5,
		float(object.y) / TILE_PIXELS + float(object.height) / TILE_PIXELS * 0.5 - float(map.height) * 0.5,
	)


func _facing_vector(facing: String) -> Vector3:
	match facing:
		"north": return Vector3(0, 0, -1)
		"south": return Vector3(0, 0, 1)
		"west": return Vector3(-1, 0, 0)
		_: return Vector3(1, 0, 0)


func _node(node_name: String, parent: Node, owner: Node) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	_add_owned(parent, node, owner)
	return node


func _add_owned(parent: Node, child: Node, owner: Node) -> void:
	parent.add_child(child)
	child.owner = owner


func _pascal_case(value: String) -> String:
	var result := ""
	for part in value.split("_"):
		result += part.capitalize()
	return result + "3D"


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		push_error("FAIL: %s" % message)
	quit(1)
