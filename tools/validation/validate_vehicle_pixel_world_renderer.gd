extends SceneTree

const PixelWorld = preload(
	"res://scripts/presentation/vehicle_pixel_world_mesh_builder.gd"
)

var _failures: Array[String] = []


class LayoutStub:
	extends RefCounted

	var fingerprint := 882731
	var cover_rects: Array[Rect2] = [
		Rect2(Vector2(340.0, 280.0), Vector2(180.0, 120.0)),
	]
	var geometry_snapshot := {
		"wall_segments":PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(800.0, 0.0),
			Vector2(800.0, 0.0), Vector2(800.0, 600.0),
		]),
	}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := PixelWorld.new()
	root.add_child(world)
	world.configure(&"stage_1", LayoutStub.new())
	await process_frame
	var contract: Dictionary = world.debug_contract()
	_expect(bool(contract["geometry_fed"]), "pixel world is geometry-fed")
	_expect(
		String(contract["collision_owner"]) == "vehicle_stage_geometry",
		"pixel world does not own collision"
	)
	_expect(bool(contract["chunk_budget_ok"]), "pixel world stays within 60 chunks")
	_expect(int(contract["chunk_count"]) == world.get_child_count(), "chunk accounting is exact")
	var polygon_count := 0
	var boundary_batch_count := 0
	for child in world.get_children():
		if child is Polygon2D:
			polygon_count += 1
			var polygon := child as Polygon2D
			_expect(
				polygon.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED,
				"world polygons use repeating tile textures"
			)
			_expect(
				polygon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
				"world polygons preserve nearest-neighbor pixels"
			)
		elif child is MultiMeshInstance2D:
			boundary_batch_count += 1
	_expect(polygon_count > 0, "stage geometry produces textured world polygons")
	_expect(boundary_batch_count == 2, "boundary rails use two retained batches")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_PIXEL_WORLD_RENDERER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
