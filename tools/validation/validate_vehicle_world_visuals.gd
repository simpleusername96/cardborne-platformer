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
const SurfaceDetailCompiler = preload(
	"res://scripts/presentation/vehicle_surface_detail_compiler.gd"
)
const MinimapBuilder = preload(
	"res://scripts/ui/vehicle_minimap_mesh_builder.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const FIXED_SEED := 0xC4A2B0
const SOLID_MESH_NAMES := [
	"SurfaceSolid",
	"VoidSolid",
	"OuterWallSolid",
	"InnerWallSolid",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_catalog()
	for field_id in FieldRegistry.FIELD_IDS:
		await _validate_field(field_id)
	_validate_minimap_tokens()
	_finish()


func _validate_catalog() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		var descriptor: Dictionary = WorldCatalog.FIELD_DESCRIPTORS.get(
			field_id, {}
		)
		_expect(not descriptor.is_empty(), "%s has a world descriptor" % field_id)
		_expect(
			int(descriptor.get("decoration_budget", -1)) == 192,
			"%s allocates only the bounded SurfaceDetail budget" % field_id
		)

	var expected_objects := {
		&"transit_gate": [ &"world/facility_transit_gate", &"round_portal" ],
		&"mystery_device_intact": [ &"world/mystery_device_intact", &"neutral_mechanical_body" ],
		&"mystery_device_resolved": [ &"world/mystery_device_resolved", &"resolved_wreck" ],
	}
	_expect(
		WorldCatalog.WORLD_OBJECT_DESCRIPTORS.size() == expected_objects.size(),
		"world object catalog has no retired support, wear, or bulkhead roles"
	)
	for visual_id in expected_objects:
		var descriptor := Dictionary(WorldCatalog.WORLD_OBJECT_DESCRIPTORS.get(visual_id, {}))
		var expected: Array = expected_objects[visual_id]
		_expect(
			StringName(descriptor.get("asset", &"")) == expected[0]
				and StringName(descriptor.get("shape", &"")) == expected[1],
			"%s retains its approved world visual identity" % visual_id
		)
	var expected_details := {
		&"surface_detail_crack": [&"world/surface_detail_crack", &"crack"],
		&"surface_detail_stain": [&"world/surface_detail_stain", &"stain"],
		&"surface_detail_embedded_chip": [&"world/surface_detail_embedded_chip", &"embedded_chip"],
	}
	_expect(
		WorldCatalog.SURFACE_DETAIL_DESCRIPTORS.size() == expected_details.size(),
		"surface catalog contains exactly the three user-approved detail families"
	)
	for visual_id in expected_details:
		var descriptor := Dictionary(WorldCatalog.SURFACE_DETAIL_DESCRIPTORS.get(visual_id, {}))
		var expected: Array = expected_details[visual_id]
		_expect(
			StringName(descriptor.get("asset", &"")) == expected[0]
				and StringName(descriptor.get("family", &"")) == expected[1],
			"%s retains its approved SurfaceDetail identity" % visual_id
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
	var navigation_before: PackedByteArray = (
		geometry_snapshot.navigation_occupancy.duplicate()
	)
	var wall_segments_before: PackedVector2Array = (
		geometry_snapshot.wall_segments.duplicate()
	)
	var walkable_before := var_to_str(geometry_snapshot.walkable_rects)
	var voids_before := var_to_str(geometry_snapshot.void_rects)
	var terrain_before := var_to_str(geometry_snapshot.terrain_zones)
	var covers_before := var_to_str(tactical.cover_rects)
	var structural_wall_count := 0
	for feature_variant in geometry_snapshot.terrain_zones:
		if StringName(Dictionary(feature_variant).get("kind", &"")) == &"structural_wall":
			structural_wall_count += 1

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
		"%s reports the bounded SurfaceDetail contract" % field_id
	)
	_expect(
		int(contract.get("decoration_count", -1)) == 192,
		"%s emits exactly the approved presentation-only SurfaceDetail budget" % field_id
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

	var solid := Dictionary(contract.get("solid_geometry", {}))
	var surface_detail := Dictionary(contract.get("surface_detail", {}))
	_validate_surface_detail_contract(field_id, geometry_snapshot, surface_detail)
	_expect(
		bool(solid.get("presentation_only", false)),
		"%s solid map geometry remains presentation-only" % field_id
	)
	_expect(
		Color(solid.get("surface_color", Color.TRANSPARENT)).is_equal_approx(
			Art.MAP_SURFACE_FILL
		),
		"%s surface uses the light-gray map role" % field_id
	)
	_expect(
		Color(solid.get("outer_wall_color", Color.TRANSPARENT)).is_equal_approx(
			Art.MAP_OUTER_WALL_FILL
		),
		"%s outer wall uses the black map role" % field_id
	)
	_expect(
		Color(solid.get("inner_wall_color", Color.TRANSPARENT)).is_equal_approx(
			Art.MAP_INNER_WALL_FILL
		),
		"%s inner wall uses the dark-gray map role" % field_id
	)
	_expect(
		int(solid.get("surface_rect_count", -1))
		== geometry_snapshot.walkable_rects.size(),
		"%s renders every walkable rectangle as one flat surface" % field_id
	)
	_expect(
		int(solid.get("outer_wall_segment_count", -1))
		== geometry_snapshot.wall_segments.size() / 2,
		"%s renders every compiled boundary segment" % field_id
	)
	_expect(
		int(solid.get("inner_wall_rect_count", -1)) == structural_wall_count,
		"%s renders every structural wall rectangle" % field_id
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
		var_to_str(geometry_snapshot.terrain_zones) == terrain_before,
		"%s presentation preserves terrain geometry" % field_id
	)
	_expect(
		var_to_str(tactical.cover_rects) == covers_before,
		"%s presentation preserves selected cover geometry" % field_id
	)

	var child_names := PackedStringArray()
	var texture_batch_count := 0
	var texture_instance_count := 0
	var collision_count := 0
	var solid_mesh_count := 0
	for child in world.get_children():
		var child_name := String(child.name)
		child_names.append(child_name)
		if child is MeshInstance2D and child_name in SOLID_MESH_NAMES:
			solid_mesh_count += 1
			match child_name:
				"SurfaceSolid":
					_validate_solid_mesh(
						field_id,
						child as MeshInstance2D,
						Art.MAP_SURFACE_FILL,
						geometry_snapshot.walkable_rects.size(),
						0
					)
				"VoidSolid":
					_validate_solid_mesh(
						field_id,
						child as MeshInstance2D,
						Art.SPACE_BLACK,
						geometry_snapshot.void_rects.size(),
						1
					)
				"OuterWallSolid":
					_validate_solid_mesh(
						field_id,
						child as MeshInstance2D,
						Art.MAP_OUTER_WALL_FILL,
						geometry_snapshot.wall_segments.size() / 2,
						3
					)
				"InnerWallSolid":
					_validate_solid_mesh(
						field_id,
						child as MeshInstance2D,
						Art.MAP_INNER_WALL_FILL,
						structural_wall_count,
						3
					)
		if child is MultiMeshInstance2D:
			texture_batch_count += 1
			var multi_mesh := (child as MultiMeshInstance2D).multimesh
			_expect(
				multi_mesh != null and (child as MultiMeshInstance2D).texture != null,
				"%s retained authored-object batch binds its raster and multimesh" % field_id
			)
			if multi_mesh != null:
				texture_instance_count += multi_mesh.visible_instance_count
		if child is CollisionObject2D:
			collision_count += 1
	_expect(solid_mesh_count == 4, "%s exposes four flat world-role meshes" % field_id)
	_expect(
		not child_names.has("Raster_world_surface_panel_9")
		and not child_names.has("Raster_world_wall_segment_9"),
		"%s does not render legacy patterned floor or shared-wall rasters" % field_id
	)
	_expect(
		int(contract.get("batch_count", -1))
		== solid_mesh_count + texture_batch_count,
		"%s batch accounting includes flat geometry and retained authored objects" % field_id
	)
	_expect(
		int(contract.get("flushed_transform_count", -1))
		== texture_instance_count,
		"%s flushes every retained authored-object transform exactly once" % field_id
	)
	_expect(collision_count == 0, "%s visual builder adds no collision objects" % field_id)
	_expect(
		texture_batch_count in [3, 4],
		"%s uses exactly three SurfaceDetail batches and at most one cover batch" % field_id
	)
	_expect(
		texture_instance_count == tactical.cover_rects.size() + 192,
		"%s retains cover plus exactly 192 static SurfaceDetail instances" % field_id
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
	_expect(
		String(Dictionary(replay.debug_contract().get("surface_detail", {})).get("fingerprint", ""))
		== String(surface_detail.get("fingerprint", "")),
		"%s SurfaceDetail compilation is deterministic" % field_id
	)
	var final_stage_tactical := run_layout.tactical_layout(&"stage_5")
	_expect(final_stage_tactical != null, "%s exposes the final-stage tactical layout" % field_id)
	if final_stage_tactical != null:
		var final_stage_details := SurfaceDetailCompiler.compile(final_stage_tactical.geometry_snapshot)
		_expect(
			String(final_stage_details.get("fingerprint", ""))
				== String(surface_detail.get("fingerprint", "")),
			"%s keeps identical SurfaceDetail placement across all stages" % field_id
		)
	world.queue_free()
	replay.queue_free()


func _validate_surface_detail_contract(
	field_id: StringName,
	geometry_snapshot: Object,
	contract: Dictionary
) -> void:
	_expect(bool(contract.get("presentation_only", false)), "%s SurfaceDetail is presentation-only" % field_id)
	_expect(int(contract.get("collision_nodes", -1)) == 0, "%s SurfaceDetail owns zero collision nodes" % field_id)
	_expect(int(contract.get("runtime_updates", -1)) == 0, "%s SurfaceDetail owns zero runtime updates" % field_id)
	_expect(int(contract.get("batch_count", -1)) == 3, "%s SurfaceDetail stays in three retained batches" % field_id)
	_expect(int(contract.get("placement_count", -1)) == 192, "%s compiles the full 192-detail budget" % field_id)
	var family_counts := Dictionary(contract.get("family_counts", {}))
	_expect(
		int(family_counts.get(&"crack", 0)) == 72
			and int(family_counts.get(&"stain", 0)) == 72
			and int(family_counts.get(&"embedded_chip", 0)) == 48,
		"%s uses the approved 72/72/48 family distribution" % field_id
	)
	var placements := Array(contract.get("placements", []))
	var allowed_rotations := SurfaceDetailCompiler.ROTATIONS
	var allowed_scales := SurfaceDetailCompiler.SCALES
	for index in placements.size():
		var placement := Dictionary(placements[index])
		var position := Vector2(placement.get("position", Vector2.ZERO))
		_expect(
			geometry_snapshot.is_spawnable_disc(position, SurfaceDetailCompiler.EDGE_AND_GEOMETRY_CLEARANCE),
			"%s detail %d clears edges, voids, walls, and cover" % [field_id, index]
		)
		_expect(
			position.distance_to(geometry_snapshot.player_start) >= SurfaceDetailCompiler.PLAYER_START_CLEARANCE,
			"%s detail %d clears the player start" % [field_id, index]
		)
		_expect(allowed_rotations.has(float(placement.get("rotation", -1.0))), "%s detail %d uses a discrete rotation" % [field_id, index])
		_expect(allowed_scales.has(float(placement.get("scale", -1.0))), "%s detail %d uses an approved scale" % [field_id, index])
		for other_index in index:
			var other := Vector2(Dictionary(placements[other_index]).get("position", Vector2.ZERO))
			_expect(
				position.distance_to(other) >= SurfaceDetailCompiler.MINIMUM_SEPARATION,
				"%s details %d/%d keep minimum separation" % [field_id, other_index, index]
			)


func _validate_solid_mesh(
	field_id: StringName,
	instance: MeshInstance2D,
	expected_color: Color,
	expected_quad_count: int,
	expected_z: int
) -> void:
	var label := "%s/%s" % [String(field_id), String(instance.name)]
	_expect(instance.z_index == expected_z, "%s keeps its draw order" % label)
	var mesh := instance.mesh
	_expect(mesh != null and mesh.get_surface_count() == 1, "%s has one mesh surface" % label)
	if mesh == null or mesh.get_surface_count() != 1:
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices := PackedVector3Array(arrays[Mesh.ARRAY_VERTEX])
	var colors := PackedColorArray(arrays[Mesh.ARRAY_COLOR])
	var indices := PackedInt32Array(arrays[Mesh.ARRAY_INDEX])
	_expect(
		vertices.size() == expected_quad_count * 4,
		"%s has one quad per source geometry record" % label
	)
	_expect(
		indices.size() == expected_quad_count * 6,
		"%s triangulates every source quad exactly once" % label
	)
	_expect(colors.size() == vertices.size(), "%s colors every vertex" % label)
	for color in colors:
		_expect(
			color.is_equal_approx(expected_color),
			"%s uses only its assigned solid color" % label
		)
	var uv_variant: Variant = arrays[Mesh.ARRAY_TEX_UV]
	_expect(
		uv_variant == null
		or (uv_variant is PackedVector2Array and uv_variant.is_empty()),
		"%s has no texture coordinates or pattern dependency" % label
	)


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
			{"kind":&"field_pickup", "position":Vector2(1400,800), "discovered":true},
			{"kind":&"mystery_device", "position":Vector2(2600,800), "discovered":true},
			{"kind":&"mobile_enemy", "position":Vector2(3200,800), "discovered":true},
			{"kind":&"priority_enemy", "position":Vector2(3800,800), "discovered":true},
			{
				"kind":&"objective",
				"position":Vector2(5000,800),
				"color":Color(0.123, 0.456, 0.789),
				"discovered":true,
			},
		],
	}
	var mesh := MinimapBuilder.build(snapshot, Vector2(260.0, 120.0))
	_expect(mesh != null, "minimap compiles all six bounded semantic roles")
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
		and colors.has(Art.TEXT_MUTED)
		and colors.has(Art.DANGER),
		"minimap preserves player, pickup, neutral-device, and enemy semantics"
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
