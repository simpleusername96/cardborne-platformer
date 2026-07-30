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
const MinimapBuilder = preload(
	"res://scripts/ui/vehicle_minimap_mesh_builder.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const FIXED_SEED := 0xC4A2B0

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_catalog()
	for field_id in FieldRegistry.FIELD_IDS:
		await _validate_field(field_id)
	_validate_minimap_tokens()
	_validate_source_retirement()
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
		int(contract.get("pixel_textures", -1)) == 0,
		"%s world owns no pixel textures" % field_id
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
	_expect(
		tactical.fingerprint == before_fingerprint,
		"%s presentation does not mutate layout truth" % field_id
	)

	var mesh_count := 0
	var collision_count := 0
	for child in world.get_children():
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


func _validate_minimap_tokens() -> void:
	var snapshot := {
		"cols": 13,
		"rows": 6,
		"visited": [Vector2i(6, 3)],
		"player": Vector2(3600.0, 2160.0),
		"player_facing": Vector2.RIGHT,
		"world_size": Vector2(7200.0, 4320.0),
		"markers": [
			{"kind":"boss", "position":Vector2(800,800), "color":Art.BOSS_COMMAND, "discovered":true},
			{"kind":"pickup", "position":Vector2(1600,800), "color":Art.SUPPORT, "discovered":true},
			{"kind":"crate", "position":Vector2(2400,800), "color":Art.PLAYER_REWARD, "discovered":true},
			{"kind":"mechanic", "position":Vector2(3200,800), "color":Art.SYSTEM, "discovered":true},
			{"kind":"blocker", "position":Vector2(4000,800), "color":Art.RAISED, "discovered":true},
		],
		"enemy_clusters": [
			{"cell":Vector2i(3,2), "count":5, "average_velocity":Vector2.RIGHT * 60.0},
		],
		"support_fields": [
			{"state":&"active", "position":Vector2(4800,800), "kind":&"repair", "phase_progress":0.25},
			{"state":&"warning", "position":Vector2(5600,800), "kind":&"overdrive", "phase_progress":0.50},
		],
	}
	var mesh := MinimapBuilder.build(snapshot, Vector2(260.0, 120.0))
	_expect(mesh != null, "minimap compiles semantic world and facility markers")
	if mesh == null:
		return
	_expect(mesh.get_surface_count() == 1, "minimap stays in one vertex-colored batch")
	var arrays := mesh.surface_get_arrays(0)
	_expect(
		(PackedVector3Array(arrays[Mesh.ARRAY_VERTEX])).size() > 24,
		"minimap exposes distinct marker geometry"
	)
	_expect(
		(PackedColorArray(arrays[Mesh.ARRAY_COLOR])).has(Art.BOSS_COMMAND),
		"minimap preserves the boss semantic color"
	)
	_expect(
		(PackedColorArray(arrays[Mesh.ARRAY_COLOR])).has(Art.PLAYER_REWARD),
		"minimap preserves player/reward emphasis"
	)


func _validate_source_retirement() -> void:
	var backdrop_source := FileAccess.get_file_as_string(
		"res://scripts/vehicle/vehicle_stage_backdrop.gd"
	)
	var world_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_world_mesh_builder.gd"
	)
	_expect(
		not backdrop_source.contains("vehicle_pixel_world_mesh_builder"),
		"stage backdrop has no pixel world caller"
	)
	for forbidden in [
		"pixel-art-production",
		"Texture2D",
		"TEXTURE_FILTER_NEAREST",
		"space_hangar_tile_variation",
	]:
		_expect(
			not world_source.contains(forbidden),
			"world builder excludes %s" % forbidden
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
