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
		Rect2(Vector2(1160.0, 740.0), Vector2(300.0, 170.0)),
		Rect2(Vector2(2120.0, 1160.0), Vector2(340.0, 180.0)),
		Rect2(Vector2(2920.0, 780.0), Vector2(280.0, 170.0)),
		Rect2(Vector2(4020.0, 780.0), Vector2(300.0, 170.0)),
		Rect2(Vector2(4840.0, 1160.0), Vector2(340.0, 180.0)),
		Rect2(Vector2(5740.0, 740.0), Vector2(300.0, 170.0)),
		Rect2(Vector2(3360.0, 3240.0), Vector2(280.0, 170.0)),
	]
	var geometry_snapshot := SnapshotStub.new()


class SnapshotStub:
	extends RefCounted

	var player_start := Vector2(3600.0, 2160.0)
	var walkable_rects: Array[Rect2] = [
		Rect2(240.0, 360.0, 6720.0, 3600.0),
		Rect2(2520.0, 1260.0, 2160.0, 1800.0),
	]
	var void_rects: Array[Rect2] = [
		Rect2(80.0, 60.0, 3000.0, 200.0),
		Rect2(4120.0, 4060.0, 3000.0, 200.0),
	]
	var terrain_zones: Array[Dictionary] = [
		{
			"id":&"surge_1",
			"kind":&"arc_surge",
			"rect":Rect2(3420.0, 3120.0, 360.0, 760.0),
		},
		{
			"id":&"bulkhead_1",
			"kind":&"breakable_bulkhead",
			"rect":Rect2(1580.0, 2040.0, 180.0, 240.0),
		},
		{
			"id":&"bulkhead_2",
			"kind":&"breakable_bulkhead",
			"rect":Rect2(5440.0, 2040.0, 180.0, 240.0),
		},
	]
	var wall_segments := _segments()

	func _segments() -> PackedVector2Array:
		var result := PackedVector2Array()
		for y in range(360, 3961, 360):
			result.append(Vector2(240.0, float(y)))
			result.append(Vector2(720.0, float(y)))
			result.append(Vector2(6480.0, float(y)))
			result.append(Vector2(6960.0, float(y)))
		for x in range(720, 6481, 480):
			result.append(Vector2(float(x), 360.0))
			result.append(Vector2(float(x + 360), 360.0))
			result.append(Vector2(float(x), 3960.0))
			result.append(Vector2(float(x + 360), 3960.0))
		return result


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
		bool(contract["deterministic_tile_variation"]),
		"repeat masters use deterministic per-cell variation"
	)
	_expect(
		is_equal_approx(float(contract["tile_variation_period"]), 384.0),
		"repeat variation preserves the approved 384 world-pixel period"
	)
	_expect(
		String(contract["collision_owner"]) == "vehicle_stage_geometry",
		"pixel world does not own collision"
	)
	_expect(bool(contract["chunk_budget_ok"]), "pixel world stays within 60 chunks")
	_expect(
		int(contract["chunk_count"]) + int(contract["decoration_count"])
		== world.get_child_count(),
		"chunk and decoration accounting is exact"
	)
	_expect(int(contract["decoration_count"]) == 42, "approved decoration set has 42 sprites")
	_expect(bool(contract["decoration_budget_ok"]), "decorations stay within the 48 sprite budget")
	_expect(
		Dictionary(contract["decoration_roles"]) == {
			&"structure":28,
			&"prop":10,
			&"wear":4,
		},
		"decoration roles preserve the approved 28/10/4 split"
	)
	_expect(
		Array(contract["decoration_errors"]).is_empty(),
		"decoration placement reports no invalid stamp or anchor"
	)
	_expect(
		bool(Dictionary(contract["stamp_catalog"])["loaded"]),
		"approved stamp catalog loads"
	)
	_expect(
		int(Dictionary(contract["stamp_catalog"])["stamp_count"]) == 32,
		"stamp catalog exposes the fixed 32 ID table"
	)
	_expect(
		int(contract["decoration_collision_nodes"]) == 0,
		"decorations do not add collision"
	)
	var polygon_count := 0
	var boundary_batch_count := 0
	var decoration_count := 0
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
		elif child is Sprite2D:
			decoration_count += 1
			var sprite := child as Sprite2D
			_expect(sprite.region_enabled, "world decorations use atlas regions")
			_expect(
				sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
				"world decorations preserve nearest-neighbor pixels"
			)
	_expect(polygon_count > 0, "stage geometry produces textured world polygons")
	_expect(boundary_batch_count == 2, "boundary rails use two retained batches")
	_expect(decoration_count == 42, "all approved decorations are Sprite2D nodes")
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
