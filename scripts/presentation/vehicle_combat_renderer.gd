class_name VehicleCombatRenderer
extends Node2D

## Retained MultiMesh presentation for combat silhouettes and repeated semantic
## overlays. VehicleRun supplies state; this node owns visible instances.

const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const SecondaryCatalog = preload(
	"res://scripts/presentation/components/vehicle_secondary_visual_catalog.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const ProjectileCatalog = preload(
	"res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd"
)
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)
const VisualEventCatalog = preload(
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const ENEMY_STATUS_SHADER = preload(
	"res://scripts/presentation/shaders/vehicle_enemy_status_overlay.gdshader"
)
const WORLD_CHIP_FONT = preload(
	"res://art/visuals/production/ui/fonts/NotoSansKR-Variable.ttf"
)

const ENEMY_CAPACITY := EnemyStore.MAX_LIVE_HOSTILES
const PROJECTILE_CAPACITY := 240
const HOSTILE_PROJECTILE_CAPACITY := 120
const EXPERIENCE_CAPACITY := 192
const BASE_BUFFER_FLOATS_PER_INSTANCE := 12
const CUSTOM_BUFFER_FLOATS_PER_INSTANCE := 16
const CUSTOM_BATCH_AABB := AABB(Vector3(-8192.0, -8192.0, -1.0), Vector3(16384.0, 16384.0, 2.0))
const MAX_INSTALLATION_HEALTH_BARS := 12
const MAX_BOSS_HEALTH_BARS := 1
const MAX_FACILITY_HEALTH_BARS := 1
const HEALTH_BAR_INSTANCE_CAPACITY := 28
const MAX_REPAIR_LINKS := 16
const REPAIR_LINK_SEGMENTS := 5
const PRESENTATION_MIN_INTERVAL := 1.0 / 60.0
const PRESENTATION_MAX_INTERVAL := 1.0 / 20.0
const PRESENTATION_SNAP_DISTANCE := 180.0
const HEALTH_BAR_INSTALLATION_ROLES: Array[StringName] = [
	&"turret", &"interceptor_tower", &"beam_sentinel", &"generator",
]
const ENEMY_BATCH_INITIAL_CAPACITY := 64
const EXPERIENCE_BATCH_INITIAL_CAPACITY := 32
const MYSTERY_DEVICE_CAPACITY := 3
const MYSTERY_DEVICE_VISUAL_RADIUS := 96.0
const SEMANTIC_TEXTURE_DRAW_CAPACITY := 512
const WORLD_CHIP_CAPACITY := 3
const CARDINAL_DIRECTIONS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
]
const STATUS_STACK_MIX := [0.66, 0.76, 0.84]
const STATUS_APPLICATION_MIX_MAX := 0.94
const BEAM_STARTUP_BODY_ALPHA := Vector2(0.16, 0.34)
const BEAM_STARTUP_FILAMENT_ALPHA := Vector2(0.32, 0.66)
const BEAM_STARTUP_FILAMENT_WIDTH_MAX := 3.5
const BEAM_STARTUP_FILAMENT_WIDTH_RATIO := 0.065
const BEAM_ACTIVE_BODY_ALPHA := 0.92
const BEAM_ACTIVE_INNER_ALPHA := 0.88
const BEAM_ACTIVE_INNER_WIDTH_MAX := 20.0
const BEAM_ACTIVE_INNER_WIDTH_RATIO := 0.34
const BEAM_ACTIVE_CORE_WIDTH_MAX := 7.0
const BEAM_ACTIVE_CORE_WIDTH_RATIO := 0.10
class BatchBuffer:
	var values := PackedFloat32Array()
	var floats_per_instance := BASE_BUFFER_FLOATS_PER_INSTANCE
	var custom_data_enabled := false


	func _init(capacity: int, use_custom_data: bool = false) -> void:
		custom_data_enabled = use_custom_data
		floats_per_instance = (
			CUSTOM_BUFFER_FLOATS_PER_INSTANCE
			if custom_data_enabled
			else BASE_BUFFER_FLOATS_PER_INSTANCE
		)
		values.resize(capacity * floats_per_instance)

	func resize(capacity: int) -> void:
		values.resize(capacity * floats_per_instance)


	func write(
		instance_index: int,
		position: Vector2,
		angle: float,
		scale: Vector2,
		color: Color,
		custom_data: Color = Color.TRANSPARENT
	) -> void:
		write_basis(
			instance_index,
			position,
			Vector2(cos(angle), sin(angle)),
			scale,
			color,
			custom_data
		)


	func write_basis(
		instance_index: int,
		position: Vector2,
		x_axis: Vector2,
		scale: Vector2,
		color: Color,
		custom_data: Color = Color.TRANSPARENT
	) -> void:
		var offset := instance_index * floats_per_instance
		# Godot's 2D MultiMesh buffer stores row-major Transform2D values:
		# [x.x, y.x, 0, origin.x, x.y, y.y, 0, origin.y], then RGBA.
		values[offset] = x_axis.x * scale.x
		values[offset + 1] = -x_axis.y * scale.y
		values[offset + 2] = 0.0
		values[offset + 3] = position.x
		values[offset + 4] = x_axis.y * scale.x
		values[offset + 5] = x_axis.x * scale.y
		values[offset + 6] = 0.0
		values[offset + 7] = position.y
		values[offset + 8] = color.r
		values[offset + 9] = color.g
		values[offset + 10] = color.b
		values[offset + 11] = color.a
		if custom_data_enabled:
			values[offset + 12] = custom_data.r
			values[offset + 13] = custom_data.g
			values[offset + 14] = custom_data.b
			values[offset + 15] = custom_data.a


class BatchHandle:
	var instance: MultiMeshInstance2D
	var buffer
	var count := 0
	var max_capacity := 0


	func _init(
		target: MultiMeshInstance2D,
		target_buffer,
		target_max_capacity: int
	) -> void:
		instance = target
		buffer = target_buffer
		max_capacity = target_max_capacity


	func reset() -> void:
		count = 0


	func upload() -> void:
		instance.multimesh.visible_instance_count = count
		if count > 0:
			instance.multimesh.buffer = buffer.values


	func ensure_capacity(required: int) -> bool:
		var current := instance.multimesh.instance_count
		if required <= current:
			return true
		if current >= max_capacity:
			return false
		var next_capacity := mini(
			max_capacity,
			maxi(required, maxi(1, current * 2))
		)
		instance.multimesh.instance_count = next_capacity
		buffer.resize(next_capacity)
		return true


class SemanticTextureDraw:
	var asset_id: StringName = &""
	var position := Vector2.ZERO
	var angle := 0.0
	var radius := 0.0
	var modulate := Color.WHITE


class SemanticTextureSpec:
	var texture: Texture2D
	var canvas := Vector2.ONE
	var pivot := Vector2.ZERO


class WorldChipDraw:
	var text := ""
	var position := Vector2.ZERO
	var color := Color.WHITE


var _enemy_batches: Dictionary = {}
var _boss_variant_batches: Dictionary = {}
var _enemy_status_material: ShaderMaterial
var _projectile_batches: Dictionary = {}
var _experience_batch: BatchHandle
var _mystery_device_batches: Dictionary = {}
var _reinforcement_facility_batch: BatchHandle
var _mystery_effect_ring_batch: BatchHandle
var _electric_field_batch: BatchHandle
var _overlay_batches: Dictionary = {}
var _batches: Array[BatchHandle] = []
var _player_craft_body_batch: BatchHandle
var _last_health_bar_count := 0
var _installation_health_bar_count := 0
var _boss_health_bar_count := 0
var _facility_health_bar_count := 0
var _semantic_texture_draws: Array[SemanticTextureDraw] = []
var _semantic_texture_draw_count := 0
var _semantic_texture_specs: Dictionary = {}
var _world_chip_draws: Array[WorldChipDraw] = []
var _world_chip_draw_count := 0
var _secondary_asset_ids: Dictionary = {}
var _player_rear_anchor := Vector2(-0.84, 0.0)
var _installation_health_candidates: Array[EnemyState] = []
var _installation_health_scores := PackedInt64Array()
var _installation_health_candidate_count := 0
var _repair_link_candidates: Array[EnemyState] = []
var _repair_link_scores := PackedInt64Array()
var _repair_link_candidate_count := 0
var _last_repair_link_count := 0
var _presentation_sync_serial := 0
var _presented_generations := PackedInt32Array()
var _presented_last_seen_serials := PackedInt32Array()
var _presented_origins := PackedVector2Array()
var _presented_positions := PackedVector2Array()
var _presented_targets := PackedVector2Array()
var _presented_elapsed := PackedFloat32Array()
var _presented_durations := PackedFloat32Array()


func _ready() -> void:
	z_index = -5
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for _index in SEMANTIC_TEXTURE_DRAW_CAPACITY:
		_semantic_texture_draws.append(SemanticTextureDraw.new())
	for _index in WORLD_CHIP_CAPACITY:
		_world_chip_draws.append(WorldChipDraw.new())
	_installation_health_candidates.resize(MAX_INSTALLATION_HEALTH_BARS)
	_installation_health_scores.resize(MAX_INSTALLATION_HEALTH_BARS)
	_repair_link_candidates.resize(MAX_REPAIR_LINKS)
	_repair_link_scores.resize(MAX_REPAIR_LINKS)
	_presented_generations.resize(ENEMY_CAPACITY)
	_presented_generations.fill(-1)
	_presented_last_seen_serials.resize(ENEMY_CAPACITY)
	_presented_last_seen_serials.fill(-2)
	_presented_origins.resize(ENEMY_CAPACITY)
	_presented_positions.resize(ENEMY_CAPACITY)
	_presented_targets.resize(ENEMY_CAPACITY)
	_presented_elapsed.resize(ENEMY_CAPACITY)
	_presented_durations.resize(ENEMY_CAPACITY)
	_cache_catalog_asset_ids()
	_build_batches()


func sync(
	enemies: Array[EnemyState],
	player_projectiles: Array[ProjectileState],
	hostile_projectiles: Array[ProjectileState],
	shards: Array[ExperienceShard],
	effects: Array[EffectState],
	visible_world: Rect2,
	player_position: Vector2,
	run_time: float,
	active: bool,
	aim_target_id: String = "",
	presentation: Dictionary = {},
	frame_delta: float = 1.0 / 60.0
) -> void:
	# Presentation is synchronous borrowed scratch; never retain or mutate it.
	_reset_counts()
	_last_repair_link_count = 0
	_semantic_texture_draw_count = 0
	_world_chip_draw_count = 0
	if active:
		_presentation_sync_serial += 1
		_sync_enemies(
			enemies, visible_world, player_position, run_time, aim_target_id,
			bool(presentation.get("reduced_motion", false)),
			maxf(0.0, frame_delta)
		)
		_sync_projectiles(player_projectiles, &"player", visible_world)
		_sync_projectiles(hostile_projectiles, &"enemy", visible_world)
		_sync_experience(shards, visible_world)
		_sync_effects(
			effects,
			visible_world,
			player_position,
			bool(presentation.get("reduced_motion", false))
		)
		_sync_world_overlays(presentation, visible_world)
		_sync_mystery_devices(presentation, visible_world)
		_sync_reinforcement_facility(presentation, visible_world)
		_sync_mystery_effects(presentation, visible_world)
		_last_health_bar_count = (
			_installation_health_bar_count
			+ _boss_health_bar_count
			+ _facility_health_bar_count
		)
	else:
		_reset_enemy_presentation()
	_apply_visible_counts()
	queue_redraw()


func _draw() -> void:
	for index in _semantic_texture_draw_count:
		_draw_semantic_texture(_semantic_texture_draws[index])
	for index in _world_chip_draw_count:
		_draw_world_chip(_world_chip_draws[index])


static func player_rear_anchors(
	player_position: Vector2,
	hull_direction: Vector2
) -> Array[Vector2]:
	var normalized := (
		hull_direction.normalized()
		if not hull_direction.is_zero_approx()
		else Vector2.RIGHT
	)
	var lateral := normalized.rotated(PI * 0.5)
	var descriptor := ActorCatalog.descriptor(&"player")
	var normalized_anchors: Array = descriptor.get(
		"rear_anchors",
		[Vector2(-0.84, 0.0)]
	)
	var result: Array[Vector2] = []
	for anchor_variant in normalized_anchors:
		var anchor := Vector2(anchor_variant)
		result.append(
			player_position
			+ normalized * anchor.x * Art.PLAYER_VISUAL_RADIUS
			+ lateral * anchor.y * Art.PLAYER_VISUAL_RADIUS
		)
	return result


static func radial_outward_direction(
	center: Vector2,
	body_position: Vector2
) -> Vector2:
	var radial := body_position - center
	return radial.normalized() if not radial.is_zero_approx() else Vector2.RIGHT


func _player_rear_anchor_position(
	player_position: Vector2,
	hull_direction: Vector2
) -> Vector2:
	var normalized := (
		hull_direction.normalized()
		if not hull_direction.is_zero_approx()
		else Vector2.RIGHT
	)
	var lateral := normalized.rotated(PI * 0.5)
	return (
		player_position
		+ normalized * _player_rear_anchor.x * Art.PLAYER_VISUAL_RADIUS
		+ lateral * _player_rear_anchor.y * Art.PLAYER_VISUAL_RADIUS
	)


func debug_snapshot() -> Dictionary:
	var visible := 0
	var allocated := 0
	var maximum := 0
	var batch_counts := {}
	var batch_allocations := {}
	for batch in _batches:
		visible += batch.count
		allocated += batch.instance.multimesh.instance_count
		maximum += batch.max_capacity
		batch_allocations[batch.instance.name] = (
			batch.instance.multimesh.instance_count
		)
		if batch.count > 0:
			batch_counts[batch.instance.name] = batch.count
	return {
		"batches": _batches.size(),
		"visible_instances": visible,
		"allocated_instances":allocated,
		"maximum_instances":maximum,
		"batch_counts": batch_counts,
		"batch_allocations":batch_allocations,
		"enemy_capacity": ENEMY_CAPACITY,
		"health_bar_count": _last_health_bar_count,
		"installation_health_bar_count": _installation_health_bar_count,
		"ordinary_health_bar_count": 0,
		"boss_health_bar_count": _boss_health_bar_count,
		"facility_health_bar_count": _facility_health_bar_count,
		"mystery_health_bar_count": 0,
		"priority_marker_count": 0,
		"repair_link_count":_last_repair_link_count,
		"semantic_texture_draw_count":_semantic_texture_draw_count,
		"semantic_texture_draw_capacity":SEMANTIC_TEXTURE_DRAW_CAPACITY,
		"floating_damage_draw_count":0,
		"electric_field_instance_count":_electric_field_batch.count,
		"electric_field_radius":(
			_electric_field_batch.buffer.values[0]
			if _electric_field_batch.count > 0
			else 0.0
		),
	}


func debug_semantic_texture_draws(asset_id: StringName = &"") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in _semantic_texture_draw_count:
		var texture_draw := _semantic_texture_draws[index]
		if asset_id != &"" and texture_draw.asset_id != asset_id:
			continue
		result.append({
			"asset_id":texture_draw.asset_id,
			"position":texture_draw.position,
			"angle":texture_draw.angle,
			"radius":texture_draw.radius,
			"modulate":texture_draw.modulate,
		})
	return result


func _build_batches() -> void:
	_enemy_status_material = ShaderMaterial.new()
	_enemy_status_material.shader = ENEMY_STATUS_SHADER
	var unit_quad_mesh := _build_unit_quad_mesh()
	var health_rect_mesh := _build_unit_quad_mesh(0.5)
	var unit_ring_mesh := _build_unit_ring_mesh()
	var unit_disk_mesh := _build_unit_disk_mesh()
	for archetype in ActorCatalog.ENEMY_ARCHETYPES:
		if archetype == &"stage_boss":
			continue
		_enemy_batches[archetype] = _create_asset_batch(
			"Enemy_%s" % String(archetype),
			StringName("actor/%s" % archetype),
			ENEMY_CAPACITY,
			0,
			archetype,
			ENEMY_BATCH_INITIAL_CAPACITY,
			true,
			_enemy_status_material,
			true
		)
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_boss_variant_batches[variant] = _create_asset_batch(
			"Boss_%s" % String(variant),
			StringName("boss/%s" % variant),
			1,
			0,
			StringName("boss_%s" % String(variant)),
			-1,
			true,
			_enemy_status_material,
			true
		)
	_projectile_batches[ProjectileCatalog.PLAYER_PRIMARY] = _create_asset_batch(
		"Projectile_player_primary",
		ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_PRIMARY),
		PROJECTILE_CAPACITY,
		2,
		&"projectile_player_primary",
		96
	)
	_projectile_batches[ProjectileCatalog.PLAYER_SEEKER] = _create_asset_batch(
		"Projectile_player_seeker",
		ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_SEEKER),
		PROJECTILE_CAPACITY,
		2,
		&"projectile_player_seeker",
		24
	)
	_projectile_batches[ProjectileCatalog.HOSTILE] = _create_asset_batch(
		"Projectile_hostile_barbed_bolt",
		ProjectileCatalog.asset_id(ProjectileCatalog.HOSTILE),
		HOSTILE_PROJECTILE_CAPACITY,
		2,
		&"projectile_hostile",
		64
	)
	_experience_batch = _create_asset_batch(
		"Experience_master",
		&"pickup/experience_master",
		EXPERIENCE_CAPACITY,
		-1,
		&"experience_master",
		EXPERIENCE_BATCH_INITIAL_CAPACITY
	)
	_mystery_device_batches[&"intact"] = _create_asset_batch(
		"MysteryDevice_intact",
		StringName(
			WorldCatalog.world_object_descriptor(
				&"mystery_device_intact"
			).get("asset", &"")
		),
		MYSTERY_DEVICE_CAPACITY, 2, &"mystery_device_intact", MYSTERY_DEVICE_CAPACITY
	)
	_mystery_device_batches[&"resolved"] = _create_asset_batch(
		"MysteryDevice_resolved",
		StringName(
			WorldCatalog.world_object_descriptor(
				&"mystery_device_resolved"
			).get("asset", &"")
		),
		MYSTERY_DEVICE_CAPACITY, 2, &"mystery_device_resolved", MYSTERY_DEVICE_CAPACITY
	)
	_reinforcement_facility_batch = _create_asset_batch(
		"ReinforcementFacility",
		StringName(
			WorldCatalog.world_object_descriptor(
				&"reinforcement_fabricator"
			).get("asset", &"")
		),
		1,
		2,
		&"reinforcement_fabricator",
		-1,
		true
	)
	_mystery_effect_ring_batch = _create_batch(
		"MysteryEffect_ring",
		unit_ring_mesh,
		MYSTERY_DEVICE_CAPACITY,
		-1,
		&"mystery_effect_ring",
		MYSTERY_DEVICE_CAPACITY
	)
	_electric_field_batch = _create_batch(
		"ElectricField_area",
		_build_electric_field_mesh(),
		1,
		-1,
		&"electric_field_area"
	)
	_overlay_batches[&"health"] = _create_batch(
		"Overlay_health", health_rect_mesh, HEALTH_BAR_INSTANCE_CAPACITY, 3,
		&"overlay_health", HEALTH_BAR_INSTANCE_CAPACITY
	)
	_overlay_batches[&"ring"] = _create_batch(
		"Overlay_ring", unit_ring_mesh, 1024, 3, &"overlay_ring", 64
	)
	_overlay_batches[&"shield"] = _overlay_batches[&"ring"]
	_overlay_batches[&"danger_ring"] = _create_batch(
		"Overlay_danger_ring", unit_ring_mesh, 256, 3, &"overlay_danger_ring", 32
	)
	_overlay_batches[&"beam"] = _create_batch(
		"Overlay_beam", unit_quad_mesh, 1024, 3, &"overlay_beam", 128
	)
	_overlay_batches[&"disk"] = _create_batch(
		"Overlay_disk", unit_disk_mesh, 96, 1, &"overlay_disk"
	)
	_overlay_batches[&"diamond"] = _create_batch(
		"Overlay_diamond", unit_quad_mesh, 640, 4, &"overlay_diamond", 48
	)
	_player_craft_body_batch = _create_asset_batch(
		"Player_craft_body",
		&"attachment/player_craft_body",
		1,
		5,
		&"player_craft_body",
		-1,
		true
	)
	_reset_counts()
	_apply_visible_counts()


func _create_batch(
	batch_name: String,
	mesh: Mesh,
	capacity: int,
	child_z: int,
	_buffer_key: StringName,
	initial_capacity: int = -1,
	texture: Texture2D = null,
	material: Material = null,
	use_custom_data: bool = false
) -> BatchHandle:
	var allocated_capacity := (
		capacity
		if initial_capacity <= 0
		else mini(capacity, initial_capacity)
	)
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
	multi_mesh.use_colors = true
	multi_mesh.use_custom_data = use_custom_data
	multi_mesh.instance_count = allocated_capacity
	multi_mesh.visible_instance_count = 0
	multi_mesh.mesh = mesh
	multi_mesh.custom_aabb = CUSTOM_BATCH_AABB
	var instance := MultiMeshInstance2D.new()
	instance.name = batch_name
	instance.z_index = child_z
	instance.multimesh = multi_mesh
	instance.texture = texture
	instance.material = material
	add_child(instance)
	var handle := BatchHandle.new(
		instance,
		BatchBuffer.new(allocated_capacity, use_custom_data),
		capacity
	)
	_batches.append(handle)
	return handle


static func _build_electric_field_mesh() -> Mesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fill_color := Color(Art.ARC, 0.18)
	var plane_color := Color(Art.ARC, 0.045)
	var segment_count := 64
	for index in segment_count:
		var angle_a := TAU * float(index) / float(segment_count)
		var angle_b := TAU * float(index + 1) / float(segment_count)
		_append_colored_triangle(
			surface,
			Vector2.ZERO,
			Vector2.RIGHT.rotated(angle_a),
			Vector2.RIGHT.rotated(angle_b),
			fill_color
		)
	for plane_index in 2:
		var direction := Vector2.RIGHT.rotated(0.42 + float(plane_index) * 1.73)
		var lateral := direction.rotated(PI * 0.5) * 0.105
		_append_colored_quad(
			surface,
			direction * -0.58 - lateral,
			direction * 0.58 - lateral,
			direction * 0.58 + lateral,
			direction * -0.58 + lateral,
			plane_color
		)
	return surface.commit()


static func _build_unit_quad_mesh(half_height: float = 1.0) -> Mesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_colored_quad(
		surface,
		Vector2(-1.0, -half_height),
		Vector2(1.0, -half_height),
		Vector2(1.0, half_height),
		Vector2(-1.0, half_height),
		Color.WHITE
	)
	return surface.commit()


static func _build_unit_disk_mesh() -> Mesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count := 64
	for index in segment_count:
		var angle_a := TAU * float(index) / float(segment_count)
		var angle_b := TAU * float(index + 1) / float(segment_count)
		_append_colored_triangle(
			surface,
			Vector2.ZERO,
			Vector2.RIGHT.rotated(angle_a),
			Vector2.RIGHT.rotated(angle_b),
			Color.WHITE
		)
	return surface.commit()


static func _build_unit_ring_mesh() -> Mesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count := 64
	var inner_radius := 0.94
	for index in segment_count:
		var angle_a := TAU * float(index) / float(segment_count)
		var angle_b := TAU * float(index + 1) / float(segment_count)
		var outer_a := Vector2.RIGHT.rotated(angle_a)
		var outer_b := Vector2.RIGHT.rotated(angle_b)
		_append_colored_quad(
			surface,
			outer_a * inner_radius,
			outer_a,
			outer_b,
			outer_b * inner_radius,
			Color.WHITE
		)
	return surface.commit()


static func _append_colored_triangle(
	surface: SurfaceTool,
	a: Vector2,
	b: Vector2,
	c: Vector2,
	color: Color
) -> void:
	for point in [a, b, c]:
		surface.set_color(color)
		surface.add_vertex(Vector3(point.x, point.y, 0.0))


static func _append_colored_quad(
	surface: SurfaceTool,
	a: Vector2,
	b: Vector2,
	c: Vector2,
	d: Vector2,
	color: Color
) -> void:
	_append_colored_triangle(surface, a, b, c, color)
	_append_colored_triangle(surface, a, c, d, color)


func _create_asset_batch(
	batch_name: String,
	asset_id: StringName,
	capacity: int,
	child_z: int,
	buffer_key: StringName,
	initial_capacity: int = -1,
	_outlined: bool = false,
	material: Material = null,
	use_custom_data: bool = false
) -> BatchHandle:
	var mesh := AssetProvider.normalized_mesh(asset_id)
	var texture := AssetProvider.texture(asset_id)
	assert(mesh != null, "Missing semantic mesh: %s" % asset_id)
	assert(texture != null, "Missing semantic texture: %s" % asset_id)
	return _create_batch(
		batch_name,
		mesh,
		capacity,
		child_z,
		buffer_key,
		initial_capacity,
		texture,
		material,
		use_custom_data
	)


func _cache_catalog_asset_ids() -> void:
	var player_descriptor := ActorCatalog.descriptor(&"player")
	var anchors: Array = player_descriptor.get(
		"rear_anchors",
		[_player_rear_anchor]
	)
	if not anchors.is_empty():
		_player_rear_anchor = Vector2(anchors[0])
	for visual_id in SecondaryCatalog.descriptor_ids():
		_secondary_asset_ids[visual_id] = StringName(
			SecondaryCatalog.descriptor(visual_id).get("asset", &"")
		)


func _sync_enemies(
	enemies: Array[EnemyState],
	visible_world: Rect2,
	player_position: Vector2,
	run_time: float,
	_aim_target_id: String,
	reduced_motion: bool,
	frame_delta: float
) -> void:
	_installation_health_candidate_count = 0
	_repair_link_candidate_count = 0
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var position := _advance_enemy_presentation(enemy, frame_delta)
		var radius := enemy.visual_radius
		if (
			not enemy.attack_telegraphs.is_empty()
			and enemy.phase in [
				&"startup", &"boss_startup", &"active", &"boss_active",
			]
		):
			# A telegraph may cross the viewport while its source body is offscreen.
			_sync_enemy_attack_telegraphs(enemy, visible_world)
		if not visible_world.grow(radius).has_point(position):
			continue
		var role := enemy.role
		var archetype := enemy.archetype
		var angle := _enemy_angle(
			archetype,
			enemy,
			player_position,
			run_time
		)
		var batch: BatchHandle = (
			_boss_variant_batches.get(enemy.boss_variant)
			if archetype == &"stage_boss"
			else _enemy_batches.get(archetype)
		)
		if batch == null:
			continue
		_write_instance(
			batch,
			position,
			angle,
			Vector2.ONE * radius,
			_enemy_body_modulate(enemy),
			_enemy_status_custom_data(enemy, reduced_motion)
		)
		if role == &"stage_boss" and _boss_health_bar_count < MAX_BOSS_HEALTH_BARS:
			_sync_health_bar(
				position,
				radius,
				enemy.health,
				enemy.max_health,
				1.9,
				96.0,
				120.0,
				18.0,
				18.0,
				Art.BOSS_COMMAND,
				visible_world
			)
			_boss_health_bar_count += 1
		if role in HEALTH_BAR_INSTALLATION_ROLES:
			_installation_health_candidate_count = _offer_overlay_candidate(
				enemy,
				_installation_health_score(enemy, player_position),
				_installation_health_candidates,
				_installation_health_scores,
				_installation_health_candidate_count,
				MAX_INSTALLATION_HEALTH_BARS
			)
		if enemy.shielded:
			_write_ring(position, radius + 7.0, Color(Art.MINT, 0.78))
		if enemy.role == &"repair_tender" and not enemy.repair_target_id.is_empty():
			_repair_link_candidate_count = _offer_overlay_candidate(
				enemy,
				_installation_health_score(enemy, player_position),
				_repair_link_candidates,
				_repair_link_scores,
				_repair_link_candidate_count,
				MAX_REPAIR_LINKS
			)
		_sync_enemy_semantic_overlays(
			enemy,
			position,
			radius,
			angle
		)
	for index in _installation_health_candidate_count:
		_sync_installation_health_bar(
			_installation_health_candidates[index], visible_world
		)
	_installation_health_bar_count = _installation_health_candidate_count
	var repair_links_drawn := 0
	for index in _repair_link_candidate_count:
		if _sync_repair_link(
			_repair_link_candidates[index], enemies, run_time, reduced_motion
		):
			repair_links_drawn += 1
	_last_repair_link_count = repair_links_drawn


func _reset_enemy_presentation() -> void:
	_presentation_sync_serial = 0
	_presented_generations.fill(-1)
	_presented_last_seen_serials.fill(-2)


func _advance_enemy_presentation(
	enemy: EnemyState,
	frame_delta: float
) -> Vector2:
	var slot := enemy.spatial_slot
	if slot < 0 or slot >= ENEMY_CAPACITY:
		return enemy.pos
	var generation_changed := (
		_presented_generations[slot] != enemy.runtime_generation
	)
	var reactivated := (
		_presented_last_seen_serials[slot] != _presentation_sync_serial - 1
	)
	if generation_changed or reactivated:
		_snap_enemy_presentation(slot, enemy)
		return enemy.pos
	var duration := maxf(PRESENTATION_MIN_INTERVAL, _presented_durations[slot])
	var elapsed := minf(duration, _presented_elapsed[slot] + frame_delta)
	var current := _presented_origins[slot].lerp(
		_presented_targets[slot],
		clampf(elapsed / duration, 0.0, 1.0)
	)
	_presented_elapsed[slot] = elapsed
	_presented_positions[slot] = current
	if not enemy.pos.is_equal_approx(_presented_targets[slot]):
		var discontinuity_threshold := maxf(
			PRESENTATION_SNAP_DISTANCE,
			maxf(enemy.visual_radius * 4.0, enemy.speed * 0.22)
		)
		if enemy.speed <= 0.001 or current.distance_to(enemy.pos) >= discontinuity_threshold:
			_snap_enemy_presentation(slot, enemy)
			return enemy.pos
		_presented_origins[slot] = current
		_presented_targets[slot] = enemy.pos
		_presented_durations[slot] = _enemy_presentation_duration(
			enemy, current.distance_to(enemy.pos)
		)
		_presented_elapsed[slot] = minf(
			frame_delta, _presented_durations[slot]
		)
		current = _presented_origins[slot].lerp(
			_presented_targets[slot],
			clampf(
				_presented_elapsed[slot] / _presented_durations[slot],
				0.0,
				1.0
			)
		)
		_presented_positions[slot] = current
	_presented_last_seen_serials[slot] = _presentation_sync_serial
	return current


func _snap_enemy_presentation(slot: int, enemy: EnemyState) -> void:
	_presented_generations[slot] = enemy.runtime_generation
	_presented_last_seen_serials[slot] = _presentation_sync_serial
	_presented_origins[slot] = enemy.pos
	_presented_positions[slot] = enemy.pos
	_presented_targets[slot] = enemy.pos
	_presented_elapsed[slot] = PRESENTATION_MIN_INTERVAL
	_presented_durations[slot] = PRESENTATION_MIN_INTERVAL


func _enemy_presentation_duration(enemy: EnemyState, distance: float) -> float:
	if enemy.speed <= 0.001 or distance <= 0.001:
		return PRESENTATION_MIN_INTERVAL
	return clampf(
		distance / enemy.speed,
		PRESENTATION_MIN_INTERVAL,
		PRESENTATION_MAX_INTERVAL
	)


func _presented_enemy_position(enemy: EnemyState) -> Vector2:
	var slot := enemy.spatial_slot
	if (
		slot < 0
		or slot >= ENEMY_CAPACITY
		or _presented_generations[slot] != enemy.runtime_generation
		or _presented_last_seen_serials[slot] != _presentation_sync_serial
	):
		return enemy.pos
	return _presented_positions[slot]


func _sync_repair_link(
	repairer: EnemyState,
	enemies: Array[EnemyState],
	run_time: float,
	reduced_motion: bool
) -> bool:
	var target: EnemyState = null
	for candidate in enemies:
		if candidate.id == repairer.repair_target_id:
			target = candidate
			break
	if target == null or not target.alive or not target.active:
		return false
	var source_position := _presented_enemy_position(repairer)
	var target_position := _presented_enemy_position(target)
	var direction := (target_position - source_position).normalized()
	if direction.is_zero_approx():
		return false
	var start := source_position + direction * (repairer.visual_radius * 0.55)
	var finish := target_position - direction * (target.visual_radius * 0.72)
	var link := finish - start
	var link_length := link.length()
	if link_length <= 12.0:
		return false
	var packet_length := minf(26.0, link_length / float(REPAIR_LINK_SEGMENTS * 2))
	var phase := 0.35 if reduced_motion else fposmod(run_time * 1.35, 1.0)
	for segment_index in REPAIR_LINK_SEGMENTS:
		var fraction := fposmod(
			(float(segment_index) + phase) / float(REPAIR_LINK_SEGMENTS),
			1.0
		)
		var packet_start := start + link * fraction
		var packet_end := packet_start + direction * packet_length
		if packet_end.distance_to(start) > link_length:
			packet_end = finish
		_write_beam(packet_start, packet_end, 5.0, Color(Art.MINT, 0.78))
	var lateral := direction.rotated(PI * 0.5)
	var chevron_back := finish - direction * 16.0
	_write_beam(
		chevron_back + lateral * 8.0,
		finish,
		4.0,
		Color(Art.MINT, 0.88)
	)
	_write_beam(
		chevron_back - lateral * 8.0,
		finish,
		4.0,
		Color(Art.MINT, 0.88)
	)
	return true


func _enemy_body_modulate(enemy: EnemyState) -> Color:
	if enemy.flash > 0.0:
		return Color(1.0, 0.66, 0.66, 1.0)
	var body_color := Color.WHITE
	if enemy.role == &"mine" and enemy.phase == &"mine_armed":
		body_color = Art.IVORY_BRIGHT.lerp(Art.DANGER, 0.42)
	elif enemy.shielded:
		body_color = Color(0.72, 1.0, 0.88, 1.0)
	elif enemy.guard_plate_structure > 0.0:
		body_color = Color(0.82, 0.90, 1.0, 1.0)
	return body_color


func _enemy_status_custom_data(
	enemy: EnemyState,
	reduced_motion: bool
) -> Color:
	if enemy.flash > 0.0:
		return Color.TRANSPARENT
	var toxin_mix := _status_overlay_mix(
		enemy.toxin_stack_ratio,
		enemy.toxin_application_pulse,
		reduced_motion
	)
	var cryo_mix := _status_overlay_mix(
		enemy.cryo_stack_ratio,
		enemy.cryo_application_pulse,
		reduced_motion
	)
	var shock_mix := _status_overlay_mix(
		enemy.shock_stack_ratio,
		enemy.shock_application_pulse,
		reduced_motion
	)
	if enemy.mystery_cryo_remaining > 0.0:
		cryo_mix = maxf(cryo_mix, STATUS_STACK_MIX[1])
	var total_mix := toxin_mix + cryo_mix + shock_mix
	if total_mix <= 0.0:
		return Color.TRANSPARENT
	var toxin_color := Color(Art.TOXIN, 1.0)
	var cryo_color := Color(Art.CRYO, 1.0)
	var shock_color := Color(Art.ARC, 1.0)
	var semantic_color := Color(
		(toxin_color.r * toxin_mix + cryo_color.r * cryo_mix + shock_color.r * shock_mix) / total_mix,
		(toxin_color.g * toxin_mix + cryo_color.g * cryo_mix + shock_color.g * shock_mix) / total_mix,
		(toxin_color.b * toxin_mix + cryo_color.b * cryo_mix + shock_color.b * shock_mix) / total_mix,
		maxf(toxin_mix, maxf(cryo_mix, shock_mix))
	)
	return semantic_color


static func _status_overlay_mix(
	stack_ratio: float,
	application_pulse: float,
	reduced_motion: bool
) -> float:
	if stack_ratio <= 0.0:
		return 0.0
	var stack_index := clampi(ceili(stack_ratio * 3.0) - 1, 0, 2)
	var persistent_mix: float = STATUS_STACK_MIX[stack_index]
	if reduced_motion:
		return persistent_mix
	return lerpf(
		persistent_mix,
		STATUS_APPLICATION_MIX_MAX,
		clampf(application_pulse, 0.0, 1.0)
	)


func _installation_health_score(
	enemy: EnemyState,
	player_position: Vector2
) -> int:
	var distance_key := mini(
		99999999,
		roundi(player_position.distance_squared_to(enemy.pos))
	)
	return distance_key * 10000 + clampi(enemy.runtime_slot, 0, 9999)


func _offer_overlay_candidate(
	enemy: EnemyState,
	score: int,
	candidates: Array[EnemyState],
	scores: PackedInt64Array,
	count: int,
	capacity: int
) -> int:
	var insert_at := count
	for index in count:
		if score < scores[index]:
			insert_at = index
			break
	if insert_at >= capacity:
		return count
	var next_count := mini(capacity, count + 1)
	for index in range(next_count - 1, insert_at, -1):
		candidates[index] = candidates[index - 1]
		scores[index] = scores[index - 1]
	candidates[insert_at] = enemy
	scores[insert_at] = score
	return next_count


func _sync_installation_health_bar(
	enemy: EnemyState,
	visible_world: Rect2
) -> void:
	if enemy == null:
		return
	_sync_health_bar(
		_presented_enemy_position(enemy),
		enemy.visual_radius,
		enemy.health,
		enemy.max_health,
		1.8,
		42.0,
		72.0,
		16.0,
		16.0,
		Art.CORAL,
		visible_world
	)


func _sync_health_bar(
	position: Vector2,
	radius: float,
	health: float,
	max_health: float,
	width_scale: float,
	min_half_width: float,
	max_half_width: float,
	height: float,
	vertical_gap: float,
	fill_color: Color,
	visible_world: Rect2
) -> void:
	var health_ratio := clampf(health / maxf(0.001, max_health), 0.0, 1.0)
	var bar_half_width := clampf(
		radius * width_scale,
		min_half_width,
		max_half_width
	)
	var bar_position := position - Vector2(0.0, radius + vertical_gap)
	var backing_half_width := bar_half_width + 2.0
	var backing_half_height := (height + 4.0) * 0.5
	if bar_position.y - backing_half_height < visible_world.position.y:
		bar_position.y = position.y + radius + vertical_gap
	bar_position.x = clampf(
		bar_position.x,
		visible_world.position.x + backing_half_width,
		visible_world.end.x - backing_half_width
	)
	bar_position.y = clampf(
		bar_position.y,
		visible_world.position.y + backing_half_height,
		visible_world.end.y - backing_half_height
	)
	_write_instance(
		_overlay_batches[&"health"],
		bar_position,
		0.0,
		Vector2(backing_half_width, height + 4.0),
		Art.IVORY_SHADE
	)
	_write_instance(
		_overlay_batches[&"health"],
		bar_position + Vector2(
			-bar_half_width * (1.0 - health_ratio),
			0.0
		),
		0.0,
		Vector2(bar_half_width * health_ratio, height),
		fill_color
	)
func _sync_enemy_semantic_overlays(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	angle: float
) -> void:
	var forward := Vector2.RIGHT.rotated(angle)
	if enemy.role == &"stage_boss":
		_sync_boss_core_overlay(enemy, position, radius)
	if (
		enemy.elite_trait != &""
		and (
			enemy.elite_trait != &"armored"
			or enemy.armor_structure > 0.0
		)
	):
		_write_diamond(
			position - forward.rotated(-PI * 0.5) * (radius + 15.0),
			8.0,
			Art.BOSS_COMMAND
		)


func _sync_boss_core_overlay(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	if enemy.boss_shield_state != &"shield_up":
		return
	_write_ring(position, radius + 8.0, Color(Art.BOSS_COMMAND, 0.38))


func _sync_projectiles(
	projectiles: Array[ProjectileState],
	team: StringName,
	visible_world: Rect2
) -> void:
	var hostile := team == &"enemy"
	for projectile in projectiles:
		var position := projectile.pos
		var affinity := AttackContract.normalize_affinity(projectile.affinity)
		if affinity == AttackContract.SUPPORT:
			affinity = AttackContract.KINETIC
		var radius := maxf(1.0, projectile.radius)
		var direction := projectile.velocity.normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		if hostile:
			var hostile_batch: BatchHandle = _projectile_batches[
				ProjectileCatalog.HOSTILE
			]
			var hostile_visual_radius := (
				radius * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
			)
			if not visible_world.grow(hostile_visual_radius).has_point(position):
				continue
			_write_instance_basis(
				hostile_batch,
				position,
				direction,
				Vector2(
					hostile_visual_radius * Art.PROJECTILE_LENGTH_FACTOR,
					hostile_visual_radius
						* Art.HOSTILE_PROJECTILE_THICKNESS_FACTOR
				),
				Color.WHITE
			)
			continue
		var visual_id := (
			&"seeker"
			if projectile.homing or projectile.owner == "seeker"
			else (&"opening_breach" if projectile.wall_piercing else &"primary")
		)
		var visual_scale := Art.PLAYER_PRIMARY_PROJECTILE_SCALE
		var projectile_batch: BatchHandle = _projectile_batches[
			ProjectileCatalog.PLAYER_PRIMARY
		]
		if visual_id == &"seeker":
			visual_scale = Art.PLAYER_SEEKER_PROJECTILE_SCALE
			projectile_batch = _projectile_batches[
				ProjectileCatalog.PLAYER_SEEKER
			]
		elif visual_id == &"opening_breach":
			visual_scale = Art.PLAYER_OPENING_BREACH_PROJECTILE_SCALE
		var visual_radius := radius * visual_scale
		if not visible_world.grow(visual_radius).has_point(position):
			continue
		_write_instance_basis(
			projectile_batch,
			position,
			direction,
			Vector2(
				visual_radius * Art.PROJECTILE_LENGTH_FACTOR,
				visual_radius * Art.PROJECTILE_THICKNESS_FACTOR
			),
			Color.WHITE if visual_id == &"seeker" else Art.attack_color(affinity, true)
		)


func _sync_enemy_attack_telegraphs(
	enemy: EnemyState,
	visible_world: Rect2
) -> void:
	for telegraph in enemy.attack_telegraphs:
		match CombatCuePolicy.telegraph_mode(
			enemy.pos,
			enemy.visual_radius,
			enemy.phase,
			telegraph,
			visible_world
		):
			CombatCuePolicy.MODE_BEAM_STARTUP:
				_sync_beam_startup(telegraph)
			CombatCuePolicy.MODE_ACTIVE_BEAM:
				_sync_active_beam(telegraph)
			CombatCuePolicy.MODE_AREA_FOOTPRINT:
				_sync_area_telegraph(telegraph)


func _sync_beam_startup(telegraph: Dictionary) -> void:
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var width := maxf(1.0, float(telegraph["active_width"]))
	var readiness := clampf(float(telegraph.get("readiness", 0.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var color := Art.attack_color(
		AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	)
	_write_beam(
		from,
		to,
		width,
		Color(color, lerpf(
			BEAM_STARTUP_BODY_ALPHA.x,
			BEAM_STARTUP_BODY_ALPHA.y,
			intensity
		))
	)
	_write_beam(
		from,
		to,
		minf(
			BEAM_STARTUP_FILAMENT_WIDTH_MAX,
			width * BEAM_STARTUP_FILAMENT_WIDTH_RATIO
		),
		Color(Art.IVORY_BRIGHT, lerpf(
			BEAM_STARTUP_FILAMENT_ALPHA.x,
			BEAM_STARTUP_FILAMENT_ALPHA.y,
			intensity
		))
	)


func _sync_active_beam(telegraph: Dictionary) -> void:
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var width := maxf(1.0, float(telegraph["active_width"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var color := Art.attack_color(affinity)
	_write_beam(from, to, width, Color(color, BEAM_ACTIVE_BODY_ALPHA))
	_write_beam(
		from,
		to,
		minf(BEAM_ACTIVE_INNER_WIDTH_MAX, width * BEAM_ACTIVE_INNER_WIDTH_RATIO),
		Color(color.lerp(Art.IVORY_BRIGHT, 0.62), BEAM_ACTIVE_INNER_ALPHA)
	)
	_write_beam(
		from,
		to,
		minf(BEAM_ACTIVE_CORE_WIDTH_MAX, width * BEAM_ACTIVE_CORE_WIDTH_RATIO),
		Art.IVORY_BRIGHT
	)


func _sync_area_telegraph(telegraph: Dictionary) -> void:
	var center := Vector2(telegraph["center"])
	var radius := maxf(1.0, float(telegraph["radius"]))
	var readiness := clampf(float(telegraph.get("readiness", 1.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var boundary_alpha := lerpf(0.03, 0.06, intensity)
	_write_disk(center, radius, Color(Art.THERMAL, lerpf(0.10, 0.20, readiness)))
	_write_danger_ring(center, radius, Color(Art.THERMAL, boundary_alpha))


func _sync_experience(shards: Array[ExperienceShard], visible_world: Rect2) -> void:
	for shard in shards:
		var position := shard.pos
		var value := shard.value
		var kind := &"small" if value == 1 else (&"medium" if value <= 4 else &"large")
		var radius := float(Art.EXPERIENCE_RADII[kind])
		if not visible_world.grow(radius).has_point(position):
			continue
		_write_instance(
			_experience_batch,
			position,
			0.0,
			Vector2.ONE * radius,
			Art.PLAYER_REWARD
		)


func _sync_effects(
	effects: Array[EffectState],
	visible_world: Rect2,
	player_position: Vector2,
	_reduced_motion: bool
) -> void:
	for effect in effects:
		var event_id := effect.kind
		if not VisualEventCatalog.has_event(event_id):
			continue
		var event := VisualEventCatalog.descriptor(event_id)
		var mode := StringName(event.get("mode", &""))
		var position := (
			player_position if mode == &"live_emp_radius" else effect.pos
		)
		var duration := maxf(0.001, effect.duration)
		var progress := 1.0 - clampf(effect.time / duration, 0.0, 1.0)
		var radius := effect.radius
		var secondary_radius := effect.secondary_radius
		if not visible_world.grow(maxf(radius, secondary_radius)).has_point(position):
			continue
		var color := effect.color
		color.a *= 1.0 - progress
		var direction := effect.direction.normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		var angle := (
			direction.angle()
			if event.get("rotation", &"") == &"direction"
			else 0.0
		)
		if mode == &"live_emp_radius":
			_write_disk(
				position,
				radius,
				Color(Art.SYSTEM, 0.12)
			)
			_write_emp_utility_fringe(
				position,
				radius,
				secondary_radius,
				Color(Art.SYSTEM, 0.24)
			)
			continue
		if mode == &"hull_afterimage":
			_queue_semantic_texture(
				&"attachment/player_craft_body",
				position,
				angle,
				Art.PLAYER_VISUAL_RADIUS,
				Color(color, color.a * 0.62)
			)
			continue
		if mode == &"emp_area":
			var fade := 1.0 - progress
			_write_disk(
				position,
				radius,
				Color(Art.SYSTEM, 0.20 * fade)
			)
			_write_emp_utility_fringe(
				position,
				radius,
				secondary_radius,
				Color(Art.SYSTEM, 0.34 * fade)
			)
			continue
		if mode == &"thermal_area":
			_write_disk(
				position,
				radius,
				Color(Art.THERMAL, 0.20 * _instant_impact_alpha(progress))
			)
			continue
		if mode == &"drop_mine_area":
			_write_disk(
				position,
				radius,
				Color(Art.PLAYER_REWARD, 0.18 * _instant_impact_alpha(progress))
			)
			continue
		if mode == &"explosive_seeker_area":
			_write_disk(
				position,
				radius,
				Color(effect.color, 0.18 * _instant_impact_alpha(progress))
			)
			continue
		if mode == &"mystery_purge_pulse":
			_write_disk(
				position,
				radius,
				Color(Art.SYSTEM, 0.14 * (1.0 - progress))
			)
			_write_ring(
				position,
				radius,
				Color(Art.SYSTEM, color.a * 0.14)
			)
			continue


static func _instant_impact_alpha(progress: float) -> float:
	var bounded := clampf(progress, 0.0, 1.0)
	if bounded < 0.20:
		return lerpf(0.55, 1.0, smoothstep(0.0, 0.20, bounded))
	if bounded <= 0.50:
		return 1.0
	return 1.0 - smoothstep(0.50, 1.0, bounded)


func _write_emp_utility_fringe(
	position: Vector2,
	inner_radius: float,
	outer_radius: float,
	color: Color
) -> void:
	if outer_radius <= inner_radius or color.a <= 0.0:
		return
	var band_radius := (inner_radius + outer_radius) * 0.5
	var band_width := maxf(3.0, (outer_radius - inner_radius) * 0.22)
	var segment_length := maxf(10.0, band_radius * 0.12)
	for segment_index in 12:
		var radial := Vector2.RIGHT.rotated(
			TAU * float(segment_index) / 12.0
		)
		var tangent := radial.rotated(PI * 0.5)
		var center := position + radial * band_radius
		_write_beam(
			center - tangent * segment_length * 0.5,
			center + tangent * segment_length * 0.5,
			band_width,
			color
		)


func _sync_active_weapon(active: Dictionary, visible_world: Rect2) -> void:
	var weapon_id := StringName(active.get("weapon_id", &"emp"))
	if weapon_id == &"emp":
		return
	var center := Vector2(active.get("center", Vector2.ZERO))
	var direction := Vector2(active.get("direction", Vector2.RIGHT)).normalized()
	var size := float(active.get("size", 0.0))
	var startup := float(active.get("startup_remaining", 0.0))
	var active_remaining := float(active.get("active_remaining", 0.0))
	var release_remaining := float(active.get("release_remaining", 0.0))
	var color := Art.SYSTEM
	match weapon_id:
		&"black_hole": color = Color(0.56, 0.42, 0.94, 1.0)
		&"shockwave": color = Art.MINT
		&"cross_beam": color = Art.MUSTARD
	if startup > 0.0:
		var startup_alpha := 0.18 + 0.18 * sin(startup * 26.0)
		if weapon_id == &"cross_beam":
			_write_active_cross(center, direction, size * 2.0, Color(color, startup_alpha), visible_world)
		else:
			_write_ring(center, maxf(12.0, size), Color(color, startup_alpha + 0.30))
	if weapon_id == &"black_hole" and active_remaining > 0.0:
		_write_disk(center, size, Color(color, 0.16))
		_write_ring(center, size, Color(color, 0.78))
		_write_ring(center, size * 0.42, Color(Art.INK, 0.90))
	if release_remaining <= 0.0:
		return
	var release_alpha := clampf(release_remaining / 0.18, 0.0, 1.0)
	if weapon_id == &"cross_beam":
		_write_active_cross(center, direction, size * 2.0, Color(color, release_alpha), visible_world)
	elif weapon_id == &"shockwave":
		_write_disk(center, size, Color(color, release_alpha * 0.16))
		_write_ring(center, size, Color(color, release_alpha))
	else:
		_write_ring(center, size, Color(color, release_alpha))


func _write_active_cross(
	center: Vector2,
	direction: Vector2,
	width: float,
	color: Color,
	visible_world: Rect2
) -> void:
	var half_length := visible_world.size.length()
	var side := direction.rotated(PI * 0.5)
	_write_beam(center - direction * half_length, center + direction * half_length, width, color)
	_write_beam(center - side * half_length, center + side * half_length, width, color)


func _sync_world_overlays(state: Dictionary, visible_world: Rect2) -> void:
	if state.is_empty():
		return
	var active_weapon_variant: Variant = state.get("active_weapon")
	if active_weapon_variant is Dictionary:
		_sync_active_weapon(active_weapon_variant, visible_world)
	var zones_variant: Variant = state.get("zones")
	if zones_variant is Array:
		for zone_variant in zones_variant:
			var zone: Dictionary = zone_variant
			var shape := StringName(zone.get("shape", &"area"))
			var warning := float(zone["warning"])
			var warning_total := maxf(
				warning,
				float(zone.get("warning_total", warning))
			)
			var readiness := (
				AttackContract.warning_readiness(warning, warning_total)
				if warning > 0.0 else 1.0
			)
			if shape == &"corridor":
				var corridor := {
					"from":Vector2(zone["from"]),
					"to":Vector2(zone["to"]),
					"active_width":float(zone["width"]),
					"damage":float(zone.get("damage", 0.0)),
					"affinity":AttackContract.normalize_affinity(
						StringName(zone.get("affinity", AttackContract.KINETIC))
					),
					"readiness":readiness,
				}
				if warning > 0.0:
					_sync_beam_startup(corridor)
				else:
					_sync_active_beam(corridor)
				continue
			if shape != &"area":
				continue
			var position := Vector2(zone["pos"])
			var radius := float(zone["radius"])
			if not visible_world.grow(radius).has_point(position):
				continue
			var affinity := AttackContract.normalize_affinity(
				StringName(zone.get("affinity", AttackContract.KINETIC))
			)
			var damage := float(zone.get("damage", 0.0))
			var descriptor := {
				"center": position,
				"radius": radius,
				"damage": damage,
				"affinity": affinity,
				"readiness": readiness,
			}
			_sync_area_telegraph(descriptor)
	var dash_trails_variant: Variant = state.get("dash_afterburn_trails")
	if dash_trails_variant is Array:
		for trail_variant in dash_trails_variant:
			if not (trail_variant is Object):
				continue
			var trail_start := Vector2(trail_variant.get("start"))
			var trail_end := Vector2(trail_variant.get("end"))
			var trail_radius := 72.0
			var trail_alpha := 0.10 + 0.08 * clampf(
				float(trail_variant.get("remaining")) / 3.0, 0.0, 1.0
			)
			var trail_color := Color(Art.THERMAL, trail_alpha)
			_write_beam(
				trail_start, trail_end, trail_radius * 2.0, trail_color
			)
			_write_disk(trail_start, trail_radius, trail_color)
			_write_disk(trail_end, trail_radius, trail_color)
	var player_position := Vector2(state["player_position"])
	var hull_direction := Vector2(state["hull_direction"])
	var aim_direction := Vector2(state["aim_direction"])
	var reduced_motion := bool(state.get("reduced_motion", false))
	var hit_remaining := float(state.get("player_hit_remaining", 0.0))
	var dash_active := bool(state.get("dash_active", false))
	var protection_sources: Dictionary = state.get("protection_sources", {})
	var displayed_player_position := player_position
	var hull_color := Color.WHITE
	var feedback_color := Color.TRANSPARENT
	if hit_remaining > 0.0:
		var hit_progress := 1.0 - clampf(hit_remaining / 0.20, 0.0, 1.0)
		feedback_color = Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.24)
		if not reduced_motion and not dash_active:
			var amplitude := 5.0 * (1.0 - hit_progress)
			var jitter_direction := Vector2(
				sin(float(state.get("run_time", 0.0)) * 91.0),
				cos(float(state.get("run_time", 0.0)) * 73.0)
			).normalized()
			displayed_player_position += jitter_direction * amplitude
	if feedback_color.a > 0.0:
		hull_color = feedback_color
	var hull_angle := hull_direction.angle()
	var rear := -hull_direction.normalized()
	var side := rear.rotated(PI * 0.5)
	var rear_anchor := _player_rear_anchor_position(
		displayed_player_position,
		hull_direction
	)
	if dash_active:
		_write_beam(
			rear_anchor + rear * 8.0,
			rear_anchor + rear * 47.0,
			7.0,
			Color(Art.SYSTEM, 0.94)
		)
	_write_instance(
		_player_craft_body_batch,
		displayed_player_position,
		hull_angle,
		Vector2.ONE * Art.PLAYER_VISUAL_RADIUS,
		hull_color
	)
	if bool(state.get("dash_boost_active", false)):
		var front_rail_center := (
			displayed_player_position + hull_direction.normalized() * 24.0
		)
		_write_beam(
			front_rail_center - side * 13.0,
			front_rail_center + side * 13.0,
			6.0,
			Color(Art.MUSTARD, 0.92)
		)
	if float(state.get("muzzle_flash", 0.0)) > 0.0:
		_write_diamond(
			displayed_player_position + aim_direction * (Art.PLAYER_VISUAL_RADIUS * 1.28),
			9.0 + float(state.get("muzzle_flash", 0.0)) * 58.0,
			Art.MUSTARD
		)
	if int(state.get("secondary_visual_tier", 0)) > 0:
		_queue_semantic_texture(
			StringName(_secondary_asset_ids.get(&"seeker", &"")),
			displayed_player_position - hull_direction * 5.0 - side * 25.0,
			hull_angle,
			14.0,
			Color.WHITE
		)
	if (
		float(protection_sources.get(&"stage_transition", 0.0)) > 0.0
		or float(protection_sources.get(&"transit", 0.0)) > 0.0
	):
		_sync_target_brackets(player_position, Art.PLAYER_VISUAL_RADIUS + 13.0)
	if float(protection_sources.get(&"emp", 0.0)) > 0.0:
		_write_beam(
			player_position - side * 33.0,
			player_position + side * 33.0,
			5.0,
			Color(Art.MINT, 0.84)
		)
	var barrier_strength := float(state.get("barrier_strength", 0.0))
	var barrier_hit_remaining := float(
		state.get("player_barrier_hit_remaining", 0.0)
	)
	if barrier_strength > 0.0 or barrier_hit_remaining > 0.0:
		var barrier_flash := clampf(barrier_hit_remaining / 0.16, 0.0, 1.0)
		_write_ring(
			player_position,
			Art.PLAYER_VISUAL_RADIUS + 11.0 + barrier_flash * 3.0,
			Color(Art.MINT, lerpf(0.78, 1.0, barrier_flash))
		)
	var secondary: Dictionary = state.get("secondary", {})
	var auto_laser_remaining := float(
		secondary.get("auto_laser_active_remaining", 0.0)
	)
	if auto_laser_remaining > 0.0:
		var laser_alpha := clampf(
			auto_laser_remaining / 0.14, 0.0, 1.0
		)
		_write_beam(
			Vector2(secondary.get("auto_laser_origin", player_position)),
			Vector2(secondary.get("auto_laser_end", player_position)),
			36.0,
			Color(Art.SYSTEM, 0.50 + 0.35 * laser_alpha)
		)
	var storm_radius := 140.0
	var storm_position := Vector2(
		secondary.get("storm_position", player_position)
	)
	var storm_warning_remaining := float(
		secondary.get("storm_warning_remaining", 0.0)
	)
	if bool(secondary.get("storm_pending", false)):
		var warning_alpha := 0.10 + 0.12 * clampf(
			storm_warning_remaining / 0.55, 0.0, 1.0
		)
		_write_disk(
			storm_position, storm_radius, Color(Art.ARC, warning_alpha)
		)
	var storm_impact_remaining := float(
		secondary.get("storm_impact_remaining", 0.0)
	)
	if storm_impact_remaining > 0.0:
		var impact_alpha := clampf(
			storm_impact_remaining / 0.18, 0.0, 1.0
		)
		_write_disk(
			storm_position,
			storm_radius,
			Color(Art.ARC, 0.18 + 0.22 * impact_alpha)
		)
		_write_beam(
			storm_position + Vector2(-storm_radius, 0.0),
			storm_position + Vector2(storm_radius, 0.0),
			24.0,
			Color(Art.SYSTEM, 0.64 * impact_alpha)
		)
	var field_radius := float(secondary.get("electric_field_radius", 0.0))
	if field_radius > 0.0:
		_write_instance(
			_electric_field_batch,
			player_position,
			0.0,
			Vector2.ONE * field_radius,
			Color.WHITE
		)
	var orbiting_blade_level := int(state.get("orbiting_blade_level", 0))
	if orbiting_blade_level > 0:
		var blade_count := int(secondary.get("blade_count", 0))
		var orbit_radius := float(secondary.get("orbit_radius", 88.0))
		var blade_radius := float(secondary.get(
			"blade_radius", Art.PLAYER_ORBIT_BLADE_HALF_SIZE
		))
		for blade_index in blade_count:
			var blade_position := player_position + Vector2.RIGHT.rotated(
				float(secondary.get("orbit_angle", 0.0)) + TAU * float(blade_index) / float(blade_count)
			) * orbit_radius
			var blade_direction := radial_outward_direction(
				player_position,
				blade_position
			)
			_queue_semantic_texture(
				StringName(_secondary_asset_ids.get(&"orbit_blade", &"")),
				blade_position,
				blade_direction.angle(),
				blade_radius,
				Color.WHITE
			)
	var mines_variant: Variant = secondary.get("mines")
	if mines_variant is Array:
		for mine_variant in mines_variant:
			var mine: Dictionary = mine_variant
			_queue_semantic_texture(
				StringName(_secondary_asset_ids.get(&"wake_mine", &"")),
				Vector2(mine["pos"]),
				0.0,
				Art.PLAYER_DROP_MINE_HALF_SIZE,
				Color.WHITE
			)
	var cursor_position := Vector2(state.get("cursor_position", player_position + aim_direction * 230.0))
	for direction in CARDINAL_DIRECTIONS:
		_write_diamond(cursor_position + direction * 18.0, 6.0, Art.SYSTEM)
	_write_diamond(cursor_position, 4.0, Art.IVORY_BRIGHT)


func _sync_mystery_devices(state: Dictionary, visible_world: Rect2) -> void:
	var devices_variant: Variant = state.get("mystery_devices")
	if not devices_variant is Array:
		return
	for device_variant in devices_variant:
		var device := Dictionary(device_variant)
		if not bool(device.get("visible", false)):
			continue
		var device_state := StringName(device.get("state", &""))
		if device_state not in [&"intact", &"resolved"]:
			continue
		var position := Vector2(device.get("position", Vector2.ZERO))
		if not visible_world.grow(MYSTERY_DEVICE_VISUAL_RADIUS).has_point(position):
			continue
		_write_instance(
			_mystery_device_batches[device_state] as BatchHandle,
			position,
			0.0,
			Vector2.ONE * MYSTERY_DEVICE_VISUAL_RADIUS,
			Color.WHITE
		)
		var outcome_label := String(device.get("outcome_label", ""))
		if not outcome_label.is_empty():
			_queue_world_chip(
				"%s · %d" % [
					outcome_label,
					int(device.get("target_count", 0)),
				],
				position - Vector2(0.0, MYSTERY_DEVICE_VISUAL_RADIUS + 18.0),
				_mystery_outcome_color(StringName(
					device.get("revealed_outcome", &"")
				))
			)


func _mystery_outcome_color(outcome: StringName) -> Color:
	match outcome:
		&"cryo_lock":
			return Art.CRYO
		&"projectile_purge":
			return Art.MINT
		&"decoy_signal":
			return Art.MUSTARD
	return Art.SYSTEM


func _queue_world_chip(text_value: String, position: Vector2, color: Color) -> void:
	if text_value.is_empty() or _world_chip_draw_count >= WORLD_CHIP_CAPACITY:
		return
	var chip := _world_chip_draws[_world_chip_draw_count]
	chip.text = text_value
	chip.position = position
	chip.color = color
	_world_chip_draw_count += 1


func _draw_world_chip(chip: WorldChipDraw) -> void:
	var font_size := 14
	var text_size := WORLD_CHIP_FONT.get_string_size(
		chip.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	)
	var size := text_size + Vector2(14.0, 8.0)
	var rectangle := Rect2(chip.position - size * 0.5, size)
	draw_rect(rectangle, Color(Art.SPACE_BLACK, 0.90), true)
	draw_rect(rectangle, Color(chip.color, 0.86), false, 2.0)
	draw_string(
		WORLD_CHIP_FONT,
		chip.position + Vector2(-text_size.x * 0.5, text_size.y * 0.32),
		chip.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Art.TEXT_PRIMARY
	)
func _sync_mystery_effects(state: Dictionary, visible_world: Rect2) -> void:
	var effects_variant: Variant = state.get("mystery_effects")
	if not effects_variant is Array:
		return
	for effect_variant in effects_variant:
		var effect := Dictionary(effect_variant)
		var effect_id := StringName(effect.get("effect_id", &""))
		if effect_id not in [&"gravity_pull", &"cryo_lock", &"decoy_signal"]:
			continue
		var position := Vector2(effect.get("position", Vector2.ZERO))
		var radius := float(effect.get("radius", 0.0))
		if radius <= 0.0 or not visible_world.grow(radius).has_point(position):
			continue
		var color := Art.CRYO if effect_id == &"cryo_lock" else Art.SYSTEM
		var body_alpha := (
			0.12
			if effect_id == &"cryo_lock"
			else (0.10 if effect_id == &"gravity_pull" else 0.08)
		)
		_write_disk(position, radius, Color(color, body_alpha))
		_write_instance(
			_mystery_effect_ring_batch,
			position,
			0.0,
			Vector2.ONE * radius,
			Color(color, 0.10)
		)


func _sync_reinforcement_facility(
	state: Dictionary,
	visible_world: Rect2
) -> void:
	var facility_variant: Variant = state.get("reinforcement_facility")
	if not facility_variant is Dictionary:
		return
	var facility := Dictionary(facility_variant)
	if not bool(facility.get("visible", false)):
		return
	var position := Vector2(facility.get("position", Vector2.ZERO))
	var radius := float(facility.get("radius", 112.0))
	if not visible_world.grow(radius).has_point(position):
		return
	var facility_state := StringName(facility.get("state", &"offline"))
	var facility_modulate := Color.WHITE
	if facility_state == &"offline":
		facility_modulate = Color(Art.TEXT_MUTED, 0.62)
	elif facility_state == &"spent":
		facility_modulate = Color(Art.TEXT_MUTED, 0.42)
	_write_instance(
		_reinforcement_facility_batch,
		position,
		0.0,
		Vector2.ONE * radius,
		facility_modulate
	)
	if facility_state != &"active":
		return
	_sync_health_bar(
		position,
		radius,
		float(facility.get("health", 0.0)),
		float(facility.get("max_health", 1.0)),
		1.65,
		88.0,
		112.0,
		16.0,
		16.0,
		Art.CORAL,
		visible_world
	)
	_sync_health_bar(
		position,
		radius + 26.0,
		1.0 - float(facility.get("spawn_ratio", 1.0)),
		1.0,
		1.15,
		72.0,
		96.0,
		8.0,
		12.0,
		Art.MUSTARD,
		visible_world
	)
	_facility_health_bar_count = 1


func _queue_semantic_texture(
	asset_id: StringName,
	position: Vector2,
	angle: float,
	radius: float,
	modulate: Color
) -> void:
	if (
		asset_id == &""
		or radius <= 0.0
		or _semantic_texture_draw_count >= SEMANTIC_TEXTURE_DRAW_CAPACITY
		or not AssetProvider.has_asset(asset_id)
	):
		return
	var texture_draw := _semantic_texture_draws[
		_semantic_texture_draw_count
	]
	texture_draw.asset_id = asset_id
	texture_draw.position = position
	texture_draw.angle = angle
	texture_draw.radius = radius
	texture_draw.modulate = modulate
	_semantic_texture_draw_count += 1


func _draw_semantic_texture(texture_draw: SemanticTextureDraw) -> void:
	var spec := _semantic_texture_spec(texture_draw.asset_id)
	if spec == null or spec.texture == null:
		return
	var scale := texture_draw.radius / (
		maxf(spec.canvas.x, spec.canvas.y) * 0.5
	)
	draw_set_transform(
		texture_draw.position,
		texture_draw.angle,
		Vector2.ONE
	)
	draw_texture_rect(
		spec.texture,
		Rect2(-spec.pivot * scale, spec.canvas * scale),
		false,
		texture_draw.modulate
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _semantic_texture_spec(
	asset_id: StringName
) -> SemanticTextureSpec:
	if _semantic_texture_specs.has(asset_id):
		return _semantic_texture_specs[asset_id] as SemanticTextureSpec
	var texture := AssetProvider.texture(asset_id)
	var descriptor := AssetProvider.descriptor(asset_id)
	if texture == null or descriptor.is_empty():
		return null
	var spec := SemanticTextureSpec.new()
	spec.texture = texture
	spec.canvas = Vector2(descriptor.get("canvas", texture.get_size()))
	if spec.canvas.x <= 0.0 or spec.canvas.y <= 0.0:
		spec.canvas = Vector2(texture.get_size())
	spec.pivot = Vector2(
		descriptor.get("pivot", spec.canvas * 0.5)
	)
	_semantic_texture_specs[asset_id] = spec
	return spec


func _sync_target_brackets(position: Vector2, radius: float) -> void:
	for direction in CARDINAL_DIRECTIONS:
		_write_diamond(position + direction * (radius + 8.0), 5.0, Art.SYSTEM)


func _sync_status_brackets(
	position: Vector2,
	radius: float,
	color: Color
) -> void:
	for direction in CARDINAL_DIRECTIONS:
		_write_diamond(position + direction * radius, 5.0, color)


func _write_beam(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	_write_instance_basis(
		_overlay_batches[&"beam"], from + vector * 0.5,
		vector / length, Vector2(length * 0.5, width * 0.5), color
	)


func _write_ring(position: Vector2, radius: float, color: Color) -> void:
	_write_instance(
		_overlay_batches[&"ring"], position, 0.0,
		Vector2.ONE * radius, color
	)


func _write_danger_ring(
	position: Vector2,
	radius: float,
	color: Color
) -> void:
	_write_instance(
		_overlay_batches[&"danger_ring"],
		position,
		0.0,
		Vector2.ONE * radius,
		color
	)


func _write_disk(position: Vector2, radius: float, color: Color) -> void:
	_write_instance(
		_overlay_batches[&"disk"], position, 0.0,
		Vector2.ONE * radius, color
	)


func _write_diamond(position: Vector2, radius: float, color: Color) -> void:
	_write_instance(
		_overlay_batches[&"diamond"], position, PI / 4.0,
		Vector2.ONE * radius, color
	)


func _enemy_angle(
	archetype: StringName,
	enemy: EnemyState,
	_player_position: Vector2,
	run_time: float
) -> float:
	if archetype == &"controller":
		return run_time * 0.22
	if enemy.role in [&"mine", &"generator"]:
		return 0.0
	if not enemy.presentation_facing.is_zero_approx():
		return enemy.presentation_facing.angle()
	return 0.0


func _write_instance(
	batch: BatchHandle,
	position: Vector2,
	angle: float,
	scale: Vector2,
	color: Color,
	custom_data: Color = Color.TRANSPARENT
) -> void:
	if not batch.ensure_capacity(batch.count + 1):
		return
	batch.buffer.write(
		batch.count,
		position,
		angle,
		scale,
		color,
		custom_data
	)
	batch.count += 1


func _write_instance_basis(
	batch: BatchHandle,
	position: Vector2,
	x_axis: Vector2,
	scale: Vector2,
	color: Color
) -> void:
	if not batch.ensure_capacity(batch.count + 1):
		return
	batch.buffer.write_basis(batch.count, position, x_axis, scale, color)
	batch.count += 1


func _reset_counts() -> void:
	_last_health_bar_count = 0
	_installation_health_bar_count = 0
	_boss_health_bar_count = 0
	_facility_health_bar_count = 0
	for batch in _batches:
		batch.reset()


func _apply_visible_counts() -> void:
	for batch in _batches:
		batch.upload()
