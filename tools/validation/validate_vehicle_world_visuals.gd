extends SceneTree

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const LayoutGenerator = preload(
	"res://scripts/vehicle/vehicle_field_layout_generator.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const WorldBuilder = preload(
	"res://scripts/presentation/vehicle_world_mesh_builder.gd"
)
const SurfacePatternCompiler = preload(
	"res://scripts/presentation/vehicle_field_surface_pattern_compiler.gd"
)
const MinimapBuilder = preload(
	"res://scripts/ui/vehicle_minimap_mesh_builder.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const FIXED_SEED := 0xC4A2B0

var _failures: Array[String] = []
var _seen_module_types := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_catalog()
	_validate_surface_compiler_contract()
	for field_id in FieldRegistry.FIELD_IDS:
		await _validate_field(field_id)
	for module_type in ["1x1", "2x1", "1x2", "2x2"]:
		_expect(
			_seen_module_types.has(module_type),
			"surface compiler emits %s modules across the three fields"
			% module_type
		)
	_validate_minimap_tokens()
	_finish()


func _validate_catalog() -> void:
	var rhythms := {}
	for field_id in FieldRegistry.FIELD_IDS:
		var descriptor: Dictionary = WorldCatalog.FIELD_DESCRIPTORS.get(
			field_id, {}
		)
		_expect(not descriptor.is_empty(), "%s has a world descriptor" % field_id)
		var rhythm := StringName(descriptor.get("rhythm", &""))
		_expect(not rhythm.is_empty(), "%s has a surface rhythm" % field_id)
		rhythms[rhythm] = true
		_expect(
			int(descriptor.get("decoration_budget", -1)) == 24,
			"%s preserves the 24-decoration ceiling" % field_id
		)
	_expect(rhythms.size() == 3, "the three fields have distinct surface rhythms")

	var facility_shapes := {}
	for facility_id in [
		&"repair_field",
		&"transit_gate",
		&"overdrive_field",
		&"arc_surge_strip",
		&"breakable_bulkhead",
	]:
		var descriptor: Dictionary = WorldCatalog.FACILITY_DESCRIPTORS.get(
			facility_id, {}
		)
		_expect(not descriptor.is_empty(), "%s has a facility descriptor" % facility_id)
		var shape := StringName(descriptor.get("shape", &""))
		_expect(not shape.is_empty(), "%s has a shape token" % facility_id)
		facility_shapes[shape] = true
	_expect(
		facility_shapes.size() == 5,
		"facility roles remain shape-distinct without color"
	)
	_validate_circular_runtime_pad(&"world/facility_repair_pad")
	_validate_circular_runtime_pad(&"world/facility_overdrive_pad")


func _validate_circular_runtime_pad(asset_id: StringName) -> void:
	var descriptor := AssetProvider.descriptor(asset_id)
	var path := String(descriptor.get("path", ""))
	_expect(not path.is_empty(), "%s has a runtime image path" % asset_id)
	if path.is_empty():
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_expect(image != null and not image.is_empty(), "%s loads as an image" % asset_id)
	if image == null or image.is_empty():
		return
	var used := image.get_used_rect()
	_expect(
		abs(used.size.x - used.size.y) <= 2,
		"%s keeps a square circular-pad footprint" % asset_id
	)
	var opaque_pixels := 0
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a >= 0.12:
				opaque_pixels += 1
	var used_area := maxi(1, used.size.x * used.size.y)
	var fill_ratio := float(opaque_pixels) / float(used_area)
	_expect(
		fill_ratio >= 0.68 and fill_ratio <= 0.86,
		"%s keeps a filled circular alpha footprint" % asset_id
	)


func _validate_surface_compiler_contract() -> void:
	_expect(
		is_equal_approx(SurfacePatternCompiler.MODULE_SIZE, 288.0),
		"surface compiler keeps the 288-unit base grid"
	)
	_expect(
		is_equal_approx(SurfacePatternCompiler.GUTTER, 12.0),
		"surface compiler keeps the 12-unit module gutter"
	)
	_expect(
		is_equal_approx(SurfacePatternCompiler.PANEL_ALPHA_MIN, 0.34)
		and SurfacePatternCompiler.PANEL_ALPHA_MAX <= 0.50,
		"surface module mass stays readable but below combat-cue contrast"
	)
	_expect(
		SurfacePatternCompiler.MODULE_CELL_SIZES
		== [
			Vector2i(1, 1),
			Vector2i(2, 1),
			Vector2i(1, 2),
			Vector2i(2, 2),
		],
		"surface compiler exposes only 1x1/2x1/1x2/2x2 modules"
	)
	var walkable_rects: Array[Rect2] = [
		Rect2(0.0, 0.0, 864.0, 576.0),
	]
	var void_rects: Array[Rect2] = [
		Rect2(288.0, 0.0, 288.0, 288.0),
	]
	var cover_rects: Array[Rect2] = [
		Rect2(0.0, 288.0, 144.0, 144.0),
	]
	var first := SurfacePatternCompiler.compile(
		&"storm_drydock_field",
		731,
		walkable_rects,
		void_rects,
		cover_rects,
		Vector2(720.0, 432.0)
	)
	var replay := SurfacePatternCompiler.compile(
		&"storm_drydock_field",
		731,
		walkable_rects,
		void_rects,
		cover_rects,
		Vector2(720.0, 432.0)
	)
	var changed_seed := SurfacePatternCompiler.compile(
		&"storm_drydock_field",
		732,
		walkable_rects,
		void_rects,
		cover_rects,
		Vector2(720.0, 432.0)
	)
	_expect(
		String(first.get("fingerprint", ""))
		== String(replay.get("fingerprint", "")),
		"surface compiler repeats the same synthetic fingerprint"
	)
	_expect(
		var_to_str(first.get("modules", []))
		== var_to_str(replay.get("modules", [])),
		"surface compiler repeats the same synthetic module descriptors"
	)
	_expect(
		String(first.get("fingerprint", ""))
		!= String(changed_seed.get("fingerprint", "")),
		"layout fingerprint changes the synthetic surface composition"
	)
	_validate_pattern_geometry(
		"synthetic clipped field",
		first,
		walkable_rects,
		void_rects
	)


func _validate_field(field_id: StringName) -> void:
	var run_layout := LayoutGenerator.generate(
		FIXED_SEED,
		StageCatalog.STAGE_IDS,
		field_id
	)
	_expect(run_layout != null, "%s fixed layout generates" % field_id)
	if run_layout == null:
		return
	var tactical := run_layout.tactical_layout(&"stage_1")
	_expect(tactical != null, "%s exposes the stage tactical layout" % field_id)
	if tactical == null:
		return

	var before_fingerprint := tactical.fingerprint
	var geometry_snapshot = tactical.geometry_snapshot
	var walkable_rects: Array[Rect2] = []
	walkable_rects.assign(geometry_snapshot.walkable_rects)
	var void_rects: Array[Rect2] = []
	void_rects.assign(geometry_snapshot.void_rects)
	var cover_rects: Array[Rect2] = []
	cover_rects.assign(tactical.cover_rects)
	var navigation_before: PackedByteArray = (
		geometry_snapshot.navigation_occupancy.duplicate()
	)
	var wall_segments_before: PackedVector2Array = (
		geometry_snapshot.wall_segments.duplicate()
	)
	var walkable_before := var_to_str(geometry_snapshot.walkable_rects)
	var voids_before := var_to_str(geometry_snapshot.void_rects)
	var covers_before := var_to_str(tactical.cover_rects)
	var compiled_pattern := SurfacePatternCompiler.compile(
		field_id,
		before_fingerprint,
		walkable_rects,
		void_rects,
		cover_rects,
		geometry_snapshot.player_start
	)
	var replayed_pattern := SurfacePatternCompiler.compile(
		field_id,
		before_fingerprint,
		walkable_rects,
		void_rects,
		cover_rects,
		geometry_snapshot.player_start
	)
	var alternate_pattern := SurfacePatternCompiler.compile(
		field_id,
		before_fingerprint + 1,
		walkable_rects,
		void_rects,
		cover_rects,
		geometry_snapshot.player_start
	)
	_expect(
		String(compiled_pattern.get("fingerprint", ""))
		== String(replayed_pattern.get("fingerprint", "")),
		"%s surface modules are deterministic" % field_id
	)
	_expect(
		var_to_str(compiled_pattern.get("modules", []))
		== var_to_str(replayed_pattern.get("modules", [])),
		"%s surface module descriptors are order-stable" % field_id
	)
	_expect(
		String(compiled_pattern.get("fingerprint", ""))
		!= String(alternate_pattern.get("fingerprint", "")),
		"%s layout fingerprint changes its surface composition" % field_id
	)
	_validate_pattern_geometry(
		String(field_id),
		compiled_pattern,
		walkable_rects,
		void_rects
	)
	_validate_field_grammar(field_id, compiled_pattern)

	var world := WorldBuilder.new()
	root.add_child(world)
	world.configure(&"stage_1", tactical)
	await process_frame
	var contract: Dictionary = world.debug_contract()
	_expect(bool(contract.get("geometry_fed", false)), "%s world is geometry-fed" % field_id)
	_expect(
		String(contract.get("collision_owner", "")) == "vehicle_stage_geometry",
		"%s world does not own collision" % field_id
	)
	_expect(bool(contract.get("batch_budget_ok", false)), "%s stays within 12 batches" % field_id)
	_expect(
		int(contract.get("batch_count", 99)) <= 12,
		"%s reports no more than 12 retained batches" % field_id
	)
	_expect(
		bool(contract.get("decoration_budget_ok", false)),
		"%s stays within 24 decorations" % field_id
	)
	_expect(
		int(contract.get("decoration_count", 99)) <= 24,
		"%s reports no more than 24 decorations" % field_id
	)
	_expect(
		int(contract.get("decoration_collision_nodes", -1)) == 0,
		"%s decorations own no collision nodes" % field_id
	)
	_expect(
		not String(contract.get("geometry_fingerprint", "")).is_empty(),
		"%s compiles a geometry fingerprint" % field_id
	)
	_expect(
		StringName(contract.get("field_id", &"")) == field_id,
		"%s retains its field identity" % field_id
	)
	_expect(
		Dictionary(contract.get("field_descriptor", {}))
		== Dictionary(WorldCatalog.FIELD_DESCRIPTORS[field_id]),
		"%s consumes the catalog descriptor" % field_id
	)
	var surface_contract := Dictionary(contract.get("surface_pattern", {}))
	_expect(
		bool(surface_contract.get("presentation_only", false)),
		"%s surface pattern remains presentation-only" % field_id
	)
	_expect(
		String(surface_contract.get("fingerprint", ""))
		== String(compiled_pattern.get("fingerprint", "")),
		"%s world consumes the compiler fingerprint" % field_id
	)
	_expect(
		is_equal_approx(
			float(surface_contract.get("module_size", 0.0)),
			288.0
		),
		"%s world reports the 288-unit module grid" % field_id
	)
	_expect(
		Vector2(surface_contract.get(
			"panel_alpha_range",
			Vector2.ZERO
		)).is_equal_approx(
			Vector2(compiled_pattern.get(
				"panel_alpha_range",
				Vector2.ZERO
			))
		),
		"%s world reports the compiler's visible module-alpha range"
		% field_id
	)
	_expect(
		int(surface_contract.get("module_count", 0))
		== int(compiled_pattern.get("module_count", -1)),
		"%s world retains every compiled surface module" % field_id
	)
	_expect(
		int(surface_contract.get("service_rail_count", -1))
		== int(contract.get("decoration_count", -2)),
		"%s decoration accounting matches sparse service rails" % field_id
	)
	_expect(
		tactical.fingerprint == before_fingerprint,
		"%s presentation does not mutate layout truth" % field_id
	)
	_expect(
		geometry_snapshot.navigation_occupancy == navigation_before,
		"%s presentation preserves navigation occupancy" % field_id
	)
	_expect(
		geometry_snapshot.wall_segments == wall_segments_before,
		"%s presentation preserves boundary geometry" % field_id
	)
	_expect(
		var_to_str(geometry_snapshot.walkable_rects) == walkable_before,
		"%s presentation preserves walkable geometry" % field_id
	)
	_expect(
		var_to_str(geometry_snapshot.void_rects) == voids_before,
		"%s presentation preserves void geometry" % field_id
	)
	_expect(
		var_to_str(tactical.cover_rects) == covers_before,
		"%s presentation preserves selected cover geometry" % field_id
	)

	var mesh_count := 0
	var collision_count := 0
	var child_names := PackedStringArray()
	for child in world.get_children():
		child_names.append(String(child.name))
		if child is MeshInstance2D:
			mesh_count += 1
			var mesh := (child as MeshInstance2D).mesh
			var arrays := mesh.surface_get_arrays(0) if mesh != null else []
			var texture_uvs = (
				arrays[Mesh.ARRAY_TEX_UV]
				if arrays.size() == Mesh.ARRAY_MAX
				else null
			)
			_expect(
				mesh != null
				and (
					texture_uvs == null
					or (texture_uvs is PackedVector2Array and texture_uvs.is_empty())
				),
				"%s mesh batches are vertex-colored" % field_id
			)
		if child is CollisionObject2D:
			collision_count += 1
	_expect(
		mesh_count == int(contract.get("batch_count", -1)),
		"%s retained batch accounting is exact" % field_id
	)
	_expect(collision_count == 0, "%s visual builder adds no collision objects" % field_id)
	_expect(
		child_names.count("SurfacePattern") == 1,
		"%s surface modules occupy one retained mesh batch" % field_id
	)
	_expect(
		not child_names.has("FieldRhythm")
		and not child_names.has("SparseServicePlates"),
		"%s removes the fixed rhythm and sparse-plate batches" % field_id
	)

	var replay := WorldBuilder.new()
	root.add_child(replay)
	replay.configure(&"stage_1", tactical)
	await process_frame
	_expect(
		String(replay.debug_contract().get("geometry_fingerprint", ""))
		== String(contract.get("geometry_fingerprint", "")),
		"%s world compilation is deterministic" % field_id
	)
	world.queue_free()
	replay.queue_free()


func _validate_pattern_geometry(
	label: String,
	pattern: Dictionary,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2]
) -> void:
	_expect(
		bool(pattern.get("presentation_only", false)),
		"%s pattern declares presentation-only ownership" % label
	)
	_expect(
		PackedStringArray(pattern.get("hash_inputs", PackedStringArray()))
		== PackedStringArray([
			"field_id",
			"layout_fingerprint",
			"cell_x",
			"cell_y",
		]),
		"%s variants use only field/layout/cell hash inputs" % label
	)
	_expect(
		not String(pattern.get("fingerprint", "")).is_empty(),
		"%s pattern exposes a deterministic fingerprint" % label
	)
	var panel_alpha_range := Vector2(
		pattern.get("panel_alpha_range", Vector2.ZERO)
	)
	_expect(
		panel_alpha_range.x >= 0.34
		and panel_alpha_range.y <= 0.50
		and panel_alpha_range.y > panel_alpha_range.x,
		"%s module mass remains visible without matching combat cues" % label
	)
	var modules := Array(pattern.get("modules", []))
	_expect(not modules.is_empty(), "%s pattern emits surface modules" % label)
	_expect(
		int(pattern.get("module_count", -1)) == modules.size(),
		"%s pattern module accounting is exact" % label
	)
	_expect(
		int(pattern.get("service_rail_count", 99))
		<= SurfacePatternCompiler.MAX_SERVICE_RAILS,
		"%s pattern stays within 24 sparse service rails" % label
	)
	var claimed_cells := {}
	for module_value in modules:
		var module := Dictionary(module_value)
		var cell := Vector2i(module.get("cell", Vector2i.ZERO))
		var size := Vector2i(module.get("size", Vector2i.ZERO))
		_expect(
			size in SurfacePatternCompiler.MODULE_CELL_SIZES,
			"%s module %s uses an allowed cell size" % [label, cell]
		)
		var expected_rect := Rect2(
			Vector2(cell) * SurfacePatternCompiler.MODULE_SIZE,
			Vector2(size) * SurfacePatternCompiler.MODULE_SIZE
		)
		_expect(
			Rect2(module.get("rect", Rect2())).is_equal_approx(expected_rect),
			"%s module %s aligns to the 288-unit grid" % [label, cell]
		)
		for offset_y in size.y:
			for offset_x in size.x:
				var occupied_cell := cell + Vector2i(offset_x, offset_y)
				_expect(
					not claimed_cells.has(occupied_cell),
					"%s module cells never overlap at %s"
					% [label, occupied_cell]
				)
				claimed_cells[occupied_cell] = true
		var fragments := Array(module.get("fragments", []))
		_expect(
			not fragments.is_empty(),
			"%s module %s retains clipped surface area" % [label, cell]
		)
		for fragment_value in fragments:
			_validate_surface_rect(
				label,
				cell,
				Rect2(fragment_value),
				walkable_rects,
				void_rects
			)

	for layer_value in Array(pattern.get("layers", [])):
		var layer := Dictionary(layer_value)
		var points := PackedVector2Array(
			layer.get("points", PackedVector2Array())
		)
		if StringName(layer.get("kind", &"")) == &"panel":
			var panel_color := Color(layer.get("color", Color.TRANSPARENT))
			_expect(
				panel_color.a >= panel_alpha_range.x
				and panel_color.a <= panel_alpha_range.y,
				"%s panel layers honor the reported visibility range"
				% label
			)
		_expect(
			points.size() >= 3,
			"%s pattern layers remain triangulatable polygons" % label
		)
		for point in points:
			_expect(
				_point_in_rect_union(point, walkable_rects),
				"%s pattern polygon remains inside walkable geometry" % label
			)
			_expect(
				not _point_strictly_in_rects(point, void_rects),
				"%s pattern polygon excludes void geometry" % label
			)


func _validate_surface_rect(
	label: String,
	cell: Vector2i,
	rectangle: Rect2,
	walkable_rects: Array[Rect2],
	void_rects: Array[Rect2]
) -> void:
	var inset := minf(0.01, minf(rectangle.size.x, rectangle.size.y) * 0.25)
	var samples := [
		rectangle.get_center(),
		rectangle.position + Vector2.ONE * inset,
		Vector2(rectangle.end.x - inset, rectangle.position.y + inset),
		Vector2(rectangle.position.x + inset, rectangle.end.y - inset),
		rectangle.end - Vector2.ONE * inset,
	]
	for sample in samples:
		_expect(
			_point_in_rect_union(sample, walkable_rects),
			"%s module %s fragment stays in walkable geometry"
			% [label, cell]
		)
		_expect(
			not _point_strictly_in_rects(sample, void_rects),
			"%s module %s fragment excludes void geometry"
			% [label, cell]
		)


func _validate_field_grammar(
	field_id: StringName,
	pattern: Dictionary
) -> void:
	var counts := Dictionary(pattern.get("module_type_counts", {}))
	for module_type in counts:
		if int(counts[module_type]) > 0:
			_seen_module_types[String(module_type)] = true
	match field_id:
		&"drowned_ruin_field":
			_expect(
				int(counts.get("1x1", 0)) > 0
				and int(counts.get("2x2", 0)) > 0,
				"Drowned Ruin mixes 1x1 and 2x2 court modules"
			)
			_expect(
				int(counts.get("2x1", 0)) == 0
				and int(counts.get("1x2", 0)) == 0,
				"Drowned Ruin keeps an orthogonal court grammar"
			)
		&"tidal_archive_field":
			_expect(
				int(counts.get("1x1", 0)) > 0
				and int(counts.get("2x1", 0)) > 0,
				"Tidal Archive uses horizontal 2x1 bay modules"
			)
			_expect(
				int(counts.get("1x2", 0)) == 0
				and int(counts.get("2x2", 0)) == 0,
				"Tidal Archive keeps its lateral bay grammar"
			)
		&"storm_drydock_field":
			_expect(
				int(counts.get("1x2", 0)) > 0
				and int(counts.get("2x2", 0)) > 0,
				"Storm Drydock alternates 1x2 and 2x2 dock modules"
			)
			_expect(
				int(counts.get("2x1", 0)) == 0,
				"Storm Drydock keeps its vertical dock grammar"
			)


func _point_in_rect_union(
	point: Vector2,
	rectangles: Array[Rect2]
) -> bool:
	const EPSILON := 0.01
	for rectangle in rectangles:
		if (
			point.x >= rectangle.position.x - EPSILON
			and point.x <= rectangle.end.x + EPSILON
			and point.y >= rectangle.position.y - EPSILON
			and point.y <= rectangle.end.y + EPSILON
		):
			return true
	return false


func _point_strictly_in_rects(
	point: Vector2,
	rectangles: Array[Rect2]
) -> bool:
	const EPSILON := 0.01
	for rectangle in rectangles:
		if (
			point.x > rectangle.position.x + EPSILON
			and point.x < rectangle.end.x - EPSILON
			and point.y > rectangle.position.y + EPSILON
			and point.y < rectangle.end.y - EPSILON
		):
			return true
	return false


func _validate_minimap_tokens() -> void:
	var snapshot := {
		"cols": 13,
		"rows": 6,
		"visited": [Vector2i(6, 3)],
		"player": Vector2(3600.0, 2160.0),
		"player_facing": Vector2.RIGHT,
		"world_size": Vector2(7200.0, 4320.0),
		"markers": [
			{"kind":&"boss", "position":Vector2(800,800), "discovered":true},
			{"kind":&"item", "position":Vector2(1600,800), "discovered":true},
			{"kind":&"enemy", "position":Vector2(2400,800), "discovered":true},
			{
				"kind":&"objective",
				"position":Vector2(3200,800),
				"color":Color(0.123, 0.456, 0.789),
				"discovered":true,
			},
		],
	}
	var mesh := MinimapBuilder.build(snapshot, Vector2(260.0, 120.0))
	_expect(mesh != null, "minimap compiles the four semantic marker roles")
	if mesh == null:
		return
	_expect(mesh.get_surface_count() == 1, "minimap stays in one vertex-colored batch")
	var arrays := mesh.surface_get_arrays(0)
	_expect(
		(PackedVector3Array(arrays[Mesh.ARRAY_VERTEX])).size() > 24,
		"minimap exposes shape-distinct role geometry"
	)
	var colors := PackedColorArray(arrays[Mesh.ARRAY_COLOR])
	_expect(
		colors.has(Art.BOSS_COMMAND),
		"minimap preserves the boss semantic color"
	)
	_expect(
		colors.has(Art.PLAYER_REWARD)
			and colors.has(Art.SUPPORT)
			and colors.has(Art.DANGER),
		"minimap preserves player, item, and enemy semantic colors"
	)
	_expect(
		not colors.has(Color(0.123, 0.456, 0.789)),
		"minimap suppresses legacy objective and subtype marker channels"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 64:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_WORLD_VISUALS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
