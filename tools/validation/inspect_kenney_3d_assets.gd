extends SceneTree

const ASSETS := [
	"res://third_party/kenney_modular_dungeon/models/room-large.glb",
	"res://third_party/kenney_modular_dungeon/models/room-wide.glb",
	"res://third_party/kenney_modular_dungeon/models/corridor-wide.glb",
	"res://third_party/kenney_modular_dungeon/models/gate.glb",
	"res://third_party/kenney_modular_dungeon/models/stairs-wide.glb",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for asset_path in ASSETS:
		var scene: PackedScene = load(asset_path)
		var instance := scene.instantiate()
		root.add_child(instance)
		await process_frame
		print("ASSET %s meshes=%d bounds=%s" % [asset_path, _mesh_count(instance), _world_bounds(instance)])
		instance.queue_free()
		await process_frame
	quit(0)


func _mesh_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_count(child)
	return count


func _world_bounds(node: Node) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var local_bounds := mesh_instance.mesh.get_aabb()
		for corner_index in 8:
			var corner := Vector3(
				local_bounds.position.x + local_bounds.size.x * float(corner_index & 1),
				local_bounds.position.y + local_bounds.size.y * float((corner_index >> 1) & 1),
				local_bounds.position.z + local_bounds.size.z * float((corner_index >> 2) & 1)
			)
			var point := mesh_instance.global_transform * corner
			if not has_bounds:
				bounds = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(point)
	return bounds
