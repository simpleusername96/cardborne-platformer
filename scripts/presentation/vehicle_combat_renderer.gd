class_name VehicleCombatRenderer
extends Node2D

## Retained MultiMesh presentation for combat silhouettes and repeated semantic
## overlays. VehicleRun supplies state; this node owns visible instances.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const SecondaryCatalog = preload(
	"res://scripts/presentation/components/vehicle_secondary_visual_catalog.gd"
)
const DefenseCatalog = preload(
	"res://scripts/presentation/components/vehicle_defense_visual_catalog.gd"
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

const ENEMY_CAPACITY := EnemyStore.MAX_LIVE_HOSTILES
const PROJECTILE_CAPACITY := 240
const HOSTILE_PROJECTILE_CAPACITY := 120
const EXPERIENCE_CAPACITY := 192
const STATUS_ARC_CAPACITY := ENEMY_CAPACITY * 3
const BUFFER_FLOATS_PER_INSTANCE := 12
const CUSTOM_BATCH_AABB := AABB(Vector3(-8192.0, -8192.0, -1.0), Vector3(16384.0, 16384.0, 2.0))
const MAX_ORDINARY_HEALTH_BARS := 12
const MAX_EXTRA_PRIORITY_MARKERS := 8
const ENEMY_BATCH_INITIAL_CAPACITY := 64
const PROJECTILE_BATCH_INITIAL_CAPACITY := 120
const EXPERIENCE_BATCH_INITIAL_CAPACITY := 32
const SEMANTIC_TEXTURE_DRAW_CAPACITY := 512
const FLOATING_DAMAGE_DRAW_CAPACITY := 32
const CARDINAL_DIRECTIONS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
]
const ION_RADII := [120.0, 140.0, 160.0]
class BatchBuffer:
	var values := PackedFloat32Array()


	func _init(capacity: int) -> void:
		values.resize(capacity * BUFFER_FLOATS_PER_INSTANCE)

	func resize(capacity: int) -> void:
		values.resize(capacity * BUFFER_FLOATS_PER_INSTANCE)


	func write(
		instance_index: int,
		position: Vector2,
		angle: float,
		scale: Vector2,
		color: Color
	) -> void:
		write_basis(
			instance_index,
			position,
			Vector2(cos(angle), sin(angle)),
			scale,
			color
		)


	func write_basis(
		instance_index: int,
		position: Vector2,
		x_axis: Vector2,
		scale: Vector2,
		color: Color
	) -> void:
		var offset := instance_index * BUFFER_FLOATS_PER_INSTANCE
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


class FloatingDamageDraw:
	var position := Vector2.ZERO
	var text := ""
	var color := Color.WHITE


var _enemy_batches: Dictionary = {}
var _boss_variant_batches: Dictionary = {}
var _projectile_trail_batches: Dictionary = {}
var _experience_batches: Dictionary = {}
var _status_batches: Dictionary = {}
var _overlay_batches: Dictionary = {}
var _batches: Array[BatchHandle] = []
var _player_craft_body_batch: BatchHandle
var _last_health_bar_count := 0
var _last_priority_marker_count := 0
var _last_tactic_module_count := 0
var _support_field_asset_count := 0
var _semantic_texture_draws: Array[SemanticTextureDraw] = []
var _semantic_texture_draw_count := 0
var _semantic_texture_specs: Dictionary = {}
var _floating_damage_draws: Array[FloatingDamageDraw] = []
var _floating_damage_draw_count := 0
var _secondary_asset_ids: Dictionary = {}
var _defense_asset_ids: Dictionary = {}
var _player_rear_anchor := Vector2(-0.84, 0.0)
var _health_overlay_candidates: Array[EnemyState] = []
var _health_overlay_scores := PackedInt64Array()
var _health_overlay_candidate_count := 0
var _priority_overlay_candidates: Array[EnemyState] = []
var _priority_overlay_scores := PackedInt64Array()
var _priority_overlay_candidate_count := 0


func _ready() -> void:
	z_index = -5
	for _index in SEMANTIC_TEXTURE_DRAW_CAPACITY:
		_semantic_texture_draws.append(SemanticTextureDraw.new())
	for _index in FLOATING_DAMAGE_DRAW_CAPACITY:
		_floating_damage_draws.append(FloatingDamageDraw.new())
	_health_overlay_candidates.resize(MAX_ORDINARY_HEALTH_BARS)
	_health_overlay_scores.resize(MAX_ORDINARY_HEALTH_BARS)
	_priority_overlay_candidates.resize(MAX_EXTRA_PRIORITY_MARKERS)
	_priority_overlay_scores.resize(MAX_EXTRA_PRIORITY_MARKERS)
	_cache_catalog_asset_ids()
	_build_batches()


func sync(
	enemies: Array[EnemyState],
	player_projectiles: Array[ProjectileState],
	hostile_projectiles: Array[ProjectileState],
	shards: Array[ExperienceShard],
	effects: Array[Dictionary],
	visible_world: Rect2,
	player_position: Vector2,
	run_time: float,
	active: bool,
	aim_target_id: String = "",
	presentation: Dictionary = {}
) -> void:
	_reset_counts()
	_support_field_asset_count = 0
	_semantic_texture_draw_count = 0
	_floating_damage_draw_count = 0
	if active:
		_sync_enemies(
			enemies, visible_world, player_position, run_time, aim_target_id
		)
		_sync_projectiles(player_projectiles, &"player", visible_world)
		_sync_projectiles(hostile_projectiles, &"enemy", visible_world)
		_sync_experience(shards, visible_world)
		_sync_effects(effects, visible_world)
		_sync_world_overlays(presentation, visible_world)
		_sync_resolved_boss_modules(presentation, visible_world)
	_apply_visible_counts()
	queue_redraw()


func _draw() -> void:
	for index in _semantic_texture_draw_count:
		_draw_semantic_texture(_semantic_texture_draws[index])
	for index in _floating_damage_draw_count:
		_draw_floating_damage(_floating_damage_draws[index])


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
		"status_arc_capacity": STATUS_ARC_CAPACITY,
		"health_bar_count": _last_health_bar_count,
		"priority_marker_count": _last_priority_marker_count,
		"tactic_module_count": _last_tactic_module_count,
		"support_field_glyph_count":_support_field_asset_count,
		"semantic_texture_draw_count":_semantic_texture_draw_count,
		"semantic_texture_draw_capacity":SEMANTIC_TEXTURE_DRAW_CAPACITY,
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
		})
	return result


func _build_batches() -> void:
	for archetype in Visuals.ENEMY_ARCHETYPES:
		if archetype == &"stage_boss":
			continue
		_enemy_batches[archetype] = _create_asset_batch(
			"Enemy_%s" % String(archetype),
			StringName("actor/%s" % archetype),
			ENEMY_CAPACITY,
			0,
			archetype,
			ENEMY_BATCH_INITIAL_CAPACITY,
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
			true
		)
	var player_projectile_batches := {}
	for visual_id in [&"primary", &"opening_breach", &"seeker"]:
		var asset_suffix := (
			"player_primary"
			if visual_id == &"primary"
			else "player_%s" % visual_id
		)
		player_projectile_batches[visual_id] = _create_asset_batch(
			"Projectile_player_%s" % visual_id,
			StringName("projectile/%s" % asset_suffix),
			PROJECTILE_CAPACITY,
			2,
			StringName("projectile_player_%s" % visual_id),
			PROJECTILE_BATCH_INITIAL_CAPACITY
		)
	_projectile_trail_batches[&"player"] = player_projectile_batches
	var hostile_projectile_batches := {}
	for affinity in AttackContract.AFFINITIES:
		if affinity == AttackContract.SUPPORT:
			continue
		hostile_projectile_batches[affinity] = _create_asset_batch(
			"Projectile_enemy_%s" % affinity,
			StringName("projectile/hostile_%s" % affinity),
			HOSTILE_PROJECTILE_CAPACITY,
			2,
			StringName("projectile_enemy_%s" % affinity),
			PROJECTILE_BATCH_INITIAL_CAPACITY
		)
	_projectile_trail_batches[&"enemy"] = hostile_projectile_batches
	for kind in [&"small", &"medium", &"large"]:
		var family := StringName("experience_%s" % String(kind))
		_experience_batches[kind] = _create_asset_batch(
			"Experience_%s" % String(kind),
			StringName("pickup/%s" % family),
			EXPERIENCE_CAPACITY,
			-1,
			family,
			EXPERIENCE_BATCH_INITIAL_CAPACITY
		)
	_overlay_batches[&"health"] = _create_batch(
		"Overlay_health",
		Visuals.health_bar_mesh(),
		ENEMY_CAPACITY * 2,
		3,
		&"overlay_health",
		32
	)
	_overlay_batches[&"ring"] = _create_batch(
		"Overlay_ring", Visuals.effect_mesh(&"ring"), 1024, 3, &"overlay_ring",
		64
	)
	_overlay_batches[&"shield"] = _overlay_batches[&"ring"]
	_overlay_batches[&"danger_ring"] = _create_batch(
		"Overlay_danger_ring",
		Visuals.annulus_mesh(48, 0.975),
		256,
		3,
		&"overlay_danger_ring",
		32
	)
	_overlay_batches[&"beam"] = _create_batch(
		"Overlay_beam", Visuals.effect_mesh(&"beam"), 1024, 3, &"overlay_beam",
		128
	)
	_overlay_batches[&"disk"] = _create_batch(
		"Overlay_disk", Visuals.disk_mesh(), 96, 1, &"overlay_disk"
	)
	_overlay_batches[&"diamond"] = _create_batch(
		"Overlay_diamond", Visuals.effect_mesh(&"diamond"), 640, 4, &"overlay_diamond",
		48
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
	for status_id in [&"burn", &"poison", &"chill"]:
		_status_batches[status_id] = _create_asset_batch(
			"Status_%s" % status_id,
			StringName("state/%s" % status_id),
			ENEMY_CAPACITY,
			3,
			StringName("status_%s" % status_id)
		)
	_overlay_batches[&"support_timer_segment"] = _create_batch(
		"Overlay_support_timer_segment",
		Visuals.support_timer_segment_mesh(),
		96,
		3,
		&"overlay_support_timer_segment",
		64
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
	material: Material = null
) -> BatchHandle:
	var allocated_capacity := (
		capacity
		if initial_capacity <= 0
		else mini(capacity, initial_capacity)
	)
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
	multi_mesh.use_colors = true
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
		BatchBuffer.new(allocated_capacity),
		capacity
	)
	_batches.append(handle)
	return handle


func _create_asset_batch(
	batch_name: String,
	asset_id: StringName,
	capacity: int,
	child_z: int,
	buffer_key: StringName,
	initial_capacity: int = -1,
	_outlined: bool = false
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
		texture
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
	for visual_id in DefenseCatalog.descriptor_ids():
		_defense_asset_ids[visual_id] = StringName(
			DefenseCatalog.descriptor(visual_id).get("asset", &"")
		)


func _sync_enemies(
	enemies: Array[EnemyState],
	visible_world: Rect2,
	player_position: Vector2,
	run_time: float,
	aim_target_id: String
) -> void:
	_health_overlay_candidate_count = 0
	_priority_overlay_candidate_count = 0
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var position := enemy.pos
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
		if role == &"boss_pylon":
			_queue_semantic_texture(
				_boss_module_asset_id(enemy),
				position,
				angle,
				radius,
				(
					Color.WHITE
					if enemy.boss_module_state == &"active"
					else Color(0.52, 0.58, 0.66, 0.56)
				)
			)
		var batch: BatchHandle = (
			_boss_variant_batches.get(enemy.boss_variant)
			if archetype == &"stage_boss"
			else _enemy_batches.get(archetype)
		)
		if batch == null and role != &"boss_pylon":
			continue
		if role != &"boss_pylon":
			var color := (
				Color(1.0, 0.66, 0.66, 1.0)
				if enemy.flash > 0.0
				else (
					Color(0.72, 1.0, 0.88, 1.0)
					if enemy.shielded
					else (
						Color(0.82, 0.90, 1.0, 1.0)
						if enemy.guard_plate_structure > 0.0
						else Color.WHITE
					)
				)
			)
			_write_instance(
				batch,
				position,
				angle,
				Vector2.ONE * radius,
				color
			)
		if (
			role != &"stage_boss"
			and (
				enemy.health_class == &"priority"
				or enemy.id == aim_target_id
				or enemy.health_visible_timer > 0.0
				or enemy.phase in [&"startup", &"active"]
			)
		):
			_health_overlay_candidate_count = _offer_overlay_candidate(
				enemy,
				_enemy_overlay_score(enemy, player_position, aim_target_id),
				_health_overlay_candidates,
				_health_overlay_scores,
				_health_overlay_candidate_count,
				MAX_ORDINARY_HEALTH_BARS
			)
		if enemy.health_class == &"priority":
			_priority_overlay_candidate_count = _offer_overlay_candidate(
				enemy,
				_enemy_overlay_score(enemy, player_position, aim_target_id),
				_priority_overlay_candidates,
				_priority_overlay_scores,
				_priority_overlay_candidate_count,
				MAX_EXTRA_PRIORITY_MARKERS
			)
		_sync_collective_tactic_module(enemy, position, radius)
		if enemy.threat_kind == &"ranged" and enemy.phase == &"startup":
			var attack_direction := enemy.committed_dir.normalized()
			if attack_direction.is_zero_approx():
				attack_direction = Vector2.RIGHT.rotated(angle)
			_queue_semantic_texture(
				&"cue/ranged_startup",
				position + attack_direction * (radius + 17.0),
				attack_direction.angle(),
				15.0,
				Color.WHITE
			)
		var shield_source_asset := _enemy_shield_asset_id(enemy)
		if shield_source_asset != &"":
			_queue_semantic_texture(
				shield_source_asset,
				position,
				angle,
				radius + 7.0,
				Color(1.0, 1.0, 1.0, 0.90)
			)
		_sync_status_arcs(enemy, position, radius)
		_sync_enemy_semantic_overlays(
			enemy,
			position,
			radius,
			angle,
			player_position,
			enemy.id == aim_target_id
		)
		if enemy.id == aim_target_id:
			_sync_target_brackets(position, radius + 16.0)
	for index in _health_overlay_candidate_count:
		_sync_enemy_health_bar(_health_overlay_candidates[index])
	for index in _priority_overlay_candidate_count:
		var enemy := _priority_overlay_candidates[index]
		_sync_enemy_priority_marker(
			enemy,
			enemy.pos,
			enemy.visual_radius,
			true
		)
	_last_health_bar_count = _health_overlay_candidate_count
	_last_priority_marker_count = _priority_overlay_candidate_count


func _sync_collective_tactic_module(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	var phase := enemy.collective_phase
	if phase in [&"", &"dormant", &"cooldown"]:
		return
	var direction := enemy.collective_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var cue_id := StringName("cue/collective_%s" % String(phase))
	if not AssetProvider.has_asset(cue_id):
		return
	_queue_semantic_texture(
		cue_id,
		position + direction.rotated(-PI * 0.5) * (radius + 15.0),
		direction.angle(),
		14.0,
		Color.WHITE
	)
	_last_tactic_module_count += 1
func _enemy_overlay_score(
	enemy: EnemyState,
	player_position: Vector2,
	aim_target_id: String
) -> int:
	var distance_key := mini(
		99999999,
		roundi(player_position.distance_squared_to(enemy.pos))
	)
	var score := (
		_enemy_overlay_rank(enemy, aim_target_id) * 1000000000000
		+ distance_key * 10000
		+ clampi(enemy.runtime_slot, 0, 9999)
	)
	return score


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


func _sync_enemy_health_bar(enemy: EnemyState) -> void:
	if enemy == null:
		return
	var radius := enemy.visual_radius
	var health_ratio := clampf(
		enemy.health / maxf(0.001, enemy.max_health),
		0.0,
		1.0
	)
	var bar_width := radius * 1.6
	var bar_position := enemy.pos + Vector2(0.0, radius + 14.0)
	_write_instance(
		_overlay_batches[&"health"],
		bar_position,
		0.0,
		Vector2(bar_width, 10.0),
		Art.IVORY_SHADE
	)
	_write_instance(
		_overlay_batches[&"health"],
		bar_position + Vector2(
			-bar_width * (1.0 - health_ratio) * 0.5,
			0.0
		),
		0.0,
		Vector2(bar_width * health_ratio, 10.0),
		Art.CORAL
	)


func _enemy_overlay_rank(enemy: EnemyState, aim_target_id: String) -> int:
	if enemy.id == aim_target_id:
		return 0
	if enemy.phase in [&"startup", &"active"]:
		return 1
	if enemy.health_visible_timer > 0.0:
		return 2
	if enemy.health_class == &"priority":
		return 3
	return 4


func _sync_enemy_priority_marker(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	show_priority_marker: bool
) -> void:
	if enemy.role == &"boss_pylon":
		return
	if show_priority_marker:
		_queue_semantic_texture(
			&"cue/priority_target",
			position - Vector2(0.0, radius + 12.0),
			0.0,
			14.0,
			Color.WHITE
		)


func _sync_enemy_semantic_overlays(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	angle: float,
	player_position: Vector2,
	is_current_target: bool
) -> void:
	var forward := Vector2.RIGHT.rotated(angle)
	if enemy.role == &"boss_pylon":
		_sync_boss_module_overlay(enemy, position, radius)
		return
	if enemy.role == &"stage_boss":
		_sync_boss_core_overlay(enemy, position, radius)
	var elite_cue := StringName("cue/elite_%s" % String(enemy.elite_trait))
	if (
		enemy.elite_trait != &""
		and AssetProvider.has_asset(elite_cue)
		and (
			enemy.elite_trait != &"armored"
			or enemy.armor_structure > 0.0
		)
	):
		_queue_semantic_texture(
			elite_cue,
			position - forward.rotated(-PI * 0.5) * (radius + 15.0),
			angle,
			14.0,
			Color.WHITE
		)
	if enemy.role != &"mine":
		return
	var mobile := enemy.archetype == &"spark_minelet"
	var activation_radius := 160.0 if mobile else 230.0
	var damage_radius := 100.0 if mobile else 160.0
	if enemy.phase == &"mine_armed":
		var fuse := 1.0 if mobile else 1.25
		var readiness := 1.0 - clampf(enemy.phase_time / fuse, 0.0, 1.0)
		_write_instance(
			_overlay_batches[&"danger_ring"],
			position,
			0.0,
			Vector2.ONE * damage_radius,
			Color(Art.CORAL, 0.82)
		)
		_write_instance(
			_overlay_batches[&"diamond"],
			position + Vector2.RIGHT.rotated(-PI * 0.5 + readiness * TAU)
				* damage_radius,
			readiness * TAU,
			Vector2(7.0, 5.0),
			Art.IVORY_BRIGHT
		)
	elif (
		is_current_target
		or player_position.distance_to(position) <= activation_radius * 1.20
	):
		_write_instance(
			_overlay_batches[&"ring"],
			position,
			0.0,
			Vector2.ONE * activation_radius,
			Color(Art.MUSTARD, 0.30)
		)


func _sync_boss_core_overlay(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	var cue_id := (
		&"cue/boss_core_open"
		if enemy.boss_module_state == &"open"
		else &"cue/boss_core_stable"
		if enemy.boss_module_state == &"stable"
		else &"cue/boss_core_sealed"
	)
	_queue_semantic_texture(
		cue_id,
		position,
		0.0,
		radius * 0.25,
		Color.WHITE
	)


func _sync_boss_module_overlay(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	var cue_id := (
		&"cue/objective_active"
		if enemy.boss_module_state == &"active"
		else &"cue/objective_resolved"
		if enemy.boss_module_state in [&"resolved", &"disabled"]
		else &"cue/commit_locked"
	)
	_queue_semantic_texture(
		cue_id,
		position - Vector2(0.0, radius + 14.0),
		0.0,
		14.0,
		Color.WHITE
	)


func _sync_status_arcs(enemy: EnemyState, position: Vector2, radius: float) -> void:
	var statuses := enemy.statuses
	var icon_distance := radius + 17.0
	var icon_radius := 11.0
	if statuses.has(&"burn"):
		_write_instance(
			_status_batches[&"burn"],
			position + Vector2.RIGHT.rotated(deg_to_rad(-120.0)) * icon_distance,
			deg_to_rad(-120.0),
			Vector2.ONE * icon_radius,
			Color.WHITE
		)
	if statuses.has(&"poison"):
		_write_instance(
			_status_batches[&"poison"],
			position + Vector2.RIGHT * icon_distance,
			0.0,
			Vector2.ONE * icon_radius,
			Color.WHITE
		)
	if statuses.has(&"chill"):
		_write_instance(
			_status_batches[&"chill"],
			position + Vector2.RIGHT.rotated(deg_to_rad(120.0)) * icon_distance,
			deg_to_rad(120.0),
			Vector2.ONE * icon_radius,
			Color.WHITE
		)


func _sync_projectiles(
	projectiles: Array[ProjectileState],
	team: StringName,
	visible_world: Rect2
) -> void:
	var hostile := team == &"enemy"
	for projectile in projectiles:
		var position := projectile.pos
		var affinity := AttackContract.normalize_affinity(projectile.affinity)
		var threat_tier := AttackContract.normalize_threat_tier(projectile.threat_tier)
		if affinity == AttackContract.SUPPORT:
			affinity = AttackContract.KINETIC
		var render_affinity := AttackContract.KINETIC if team == &"player" else affinity
		var radius := maxf(1.0, projectile.radius)
		var direction := projectile.velocity.normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		var projectile_batches: Dictionary = _projectile_trail_batches[team]
		if hostile:
			# Tier-aware assets may be added later; current fallback remains affinity-owned.
			var tier_key := StringName("%s_%s" % [threat_tier, render_affinity])
			var projectile_key: StringName = (
				tier_key if projectile_batches.has(tier_key) else render_affinity
			)
			var hostile_visual_radius := (
				radius * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
			)
			if not visible_world.grow(hostile_visual_radius).has_point(position):
				continue
			_write_instance_basis(
				projectile_batches[projectile_key],
				position,
				direction,
				Vector2.ONE * hostile_visual_radius,
				Color.WHITE
			)
			continue
		var visual_id := (
			&"seeker"
			if projectile.homing or projectile.owner == "passive_seeker"
			else (&"opening_breach" if projectile.wall_piercing else &"primary")
		)
		var visual_radius := radius * (
			5.8 if visual_id == &"opening_breach" else (
				5.0 if visual_id == &"seeker" else 5.6
			)
		)
		if not visible_world.grow(visual_radius).has_point(position):
			continue
		_write_instance_basis(
			projectile_batches[visual_id],
			position,
			direction,
			Vector2.ONE * visual_radius,
			Color.WHITE
		)


func _sync_enemy_attack_telegraphs(
	enemy: EnemyState,
	visible_world: Rect2
) -> void:
	var startup := enemy.phase in [&"startup", &"boss_startup"]
	var active := enemy.phase in [&"active", &"boss_active"]
	var commit_marker_drawn := false
	for telegraph in enemy.attack_telegraphs:
		if not _telegraph_intersects_view(telegraph, visible_world):
			continue
		var shape := StringName(telegraph.get("shape", &""))
		if startup and shape == &"corridor":
			match StringName(telegraph.get("delivery", &"")):
				&"projectile":
					_sync_projectile_telegraph(telegraph)
				&"charge":
					_sync_charge_telegraph(telegraph)
				&"beam":
					_sync_corridor_telegraph(telegraph)
				_:
					_sync_corridor_telegraph(telegraph)
		elif startup and shape == &"area":
			_sync_area_telegraph(telegraph)
		elif startup and shape == &"support":
			_sync_support_telegraph(telegraph)
		elif (
			enemy.phase == &"boss_active"
			and shape == &"area"
		):
			# Boss area damage can remain live for its authored active window.
			# Keep the committed footprint visible until it is no longer harmful.
			_sync_area_telegraph(telegraph)
		elif (
			active
			and shape == &"corridor"
			and StringName(telegraph.get("delivery", &"beam")) == &"beam"
			and float(telegraph.get("active_width", 0.0)) > 0.0
		):
			_sync_active_beam(telegraph)
		if startup and not commit_marker_drawn:
			_sync_commit_marker(telegraph)
			commit_marker_drawn = true


func _sync_commit_marker(telegraph: Dictionary) -> void:
	var commit_mode := StringName(telegraph.get("commit_mode", &""))
	if commit_mode.is_empty():
		return
	var center := (
		Vector2(telegraph.get("center", Vector2.ZERO))
		if telegraph.has("center")
		else Vector2(telegraph.get("from", Vector2.ZERO))
	)
	var cue_id := (
		&"cue/commit_locked"
		if commit_mode == &"committed"
		else &"cue/commit_autonomous"
		if commit_mode == &"autonomous"
		else &""
	)
	if cue_id != &"":
		_queue_semantic_texture(
			cue_id,
			center,
			0.0,
			18.0,
			Color.WHITE
		)


func _telegraph_intersects_view(
	telegraph: Dictionary,
	visible_world: Rect2
) -> bool:
	var shape := StringName(telegraph.get("shape", &""))
	if shape == &"corridor":
		var from := Vector2(telegraph["from"])
		var to := Vector2(telegraph["to"])
		var half_width := maxf(0.0, float(telegraph.get("half_width", 0.0)))
		return Rect2(from, to - from).abs().grow(half_width).intersects(
			visible_world,
			true
		)
	if shape in [&"area", &"support"]:
		var center := Vector2(telegraph["center"])
		var radius := maxf(0.0, float(telegraph.get("radius", 0.0)))
		return visible_world.grow(radius).has_point(center)
	return false


func _sync_projectile_telegraph(telegraph: Dictionary) -> void:
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	var direction := vector / length
	var half_width := maxf(1.0, float(telegraph["half_width"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var readiness := clampf(float(telegraph.get("readiness", 1.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var color := Art.attack_warning_color(affinity, readiness)
	var damage := float(telegraph.get("damage", 0.0))
	var line_width := 4.0 if AttackContract.power_tier(damage) == &"heavy" else 3.0
	var boundary_alpha := lerpf(0.42, 0.94, intensity)
	# A projectile startup is a short launch preview, not a full-lifetime lane.
	# A directional authored cap distinguishes it from beam and charge lanes.
	_write_beam(from, to, line_width, Color(color, boundary_alpha))
	_queue_semantic_texture(
		&"cue/ranged_startup",
		from + direction * minf(18.0, length * 0.18),
		direction.angle(),
		minf(16.0, maxf(11.0, half_width)),
		Color.WHITE
	)


func _sync_charge_telegraph(telegraph: Dictionary) -> void:
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	var direction := vector / length
	var tangent := direction.rotated(PI * 0.5)
	var half_width := maxf(1.0, float(telegraph["half_width"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var readiness := clampf(float(telegraph.get("readiness", 1.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var color := Art.attack_warning_color(affinity, readiness)
	var damage := float(telegraph.get("damage", 0.0))
	var boundary_width := 4.0 if AttackContract.power_tier(damage) == &"heavy" else 3.0
	var boundary_offset := maxf(0.0, half_width - boundary_width * 0.5)
	var boundary_alpha := lerpf(0.38, 0.92, intensity)
	var accent_alpha := lerpf(0.30, 0.78, intensity)
	_write_beam(
		from + tangent * boundary_offset,
		to + tangent * boundary_offset,
		boundary_width,
		Color(color, boundary_alpha)
	)
	_write_beam(
		from - tangent * boundary_offset,
		to - tangent * boundary_offset,
		boundary_width,
		Color(color, boundary_alpha)
	)
	_write_danger_ring(to, half_width, Color(color, boundary_alpha))
	for offset in [-0.36, 0.0, 0.36]:
		var endpoint := to + tangent * half_width * float(offset)
		_write_beam(
			endpoint - direction * minf(half_width * 0.46, 24.0),
			endpoint,
			3.0,
			Color(color, accent_alpha)
		)


func _sync_corridor_telegraph(telegraph: Dictionary) -> void:
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	var direction := vector / length
	var tangent := direction.rotated(PI * 0.5)
	var half_width := maxf(1.0, float(telegraph["half_width"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var readiness := clampf(float(telegraph.get("readiness", 1.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var color := Art.attack_warning_color(affinity, readiness)
	var damage := float(telegraph.get("damage", 0.0))
	var boundary_width := 4.0 if AttackContract.power_tier(damage) == &"heavy" else 3.0
	var boundary_offset := maxf(0.0, half_width - boundary_width * 0.5)
	var boundary_alpha := lerpf(0.36, 0.88, intensity)
	var accent_alpha := lerpf(0.24, 0.68, intensity)
	# Exact capsule boundaries remain visible without accumulating interior fill.
	_write_beam(from + tangent * boundary_offset, to + tangent * boundary_offset, boundary_width, Color(color, boundary_alpha))
	_write_beam(from - tangent * boundary_offset, to - tangent * boundary_offset, boundary_width, Color(color, boundary_alpha))
	_write_danger_ring(from, half_width, Color(color, boundary_alpha))
	_write_danger_ring(to, half_width, Color(color, boundary_alpha))
	match affinity:
		AttackContract.KINETIC:
			_write_beam(from, to, 2.0, Color(color, accent_alpha))
		AttackContract.THERMAL:
			_write_beam(from, to, 2.5, Color(color, accent_alpha))
		AttackContract.TOXIN:
			for progress in [0.34, 0.68]:
				_write_diamond(from.lerp(to, float(progress)), 9.0, Color(color, accent_alpha))
		AttackContract.CRYO:
			for offset in [-0.42, 0.42]:
				_write_beam(
					from,
					to + tangent * half_width * float(offset),
					2.0,
					Color(color, accent_alpha)
				)
		AttackContract.ARC:
			_write_diamond(to, 11.0, Color(color, accent_alpha))
		AttackContract.HYBRID:
			_write_diamond(from.lerp(to, 0.5), 12.0, Color(color, accent_alpha))


func _sync_active_beam(telegraph: Dictionary) -> void:
	# Keep the exact player-center danger boundary visible around the beam body.
	_sync_corridor_telegraph(telegraph)
	var from := Vector2(telegraph["from"])
	var to := Vector2(telegraph["to"])
	var width := maxf(1.0, float(telegraph["active_width"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var color := Art.attack_color(affinity)
	_write_beam(from, to, width, Color(color, 0.92))
	_write_beam(from, to, minf(11.0, width * 0.24), Art.IVORY_BRIGHT)


func _sync_area_telegraph(telegraph: Dictionary) -> void:
	var center := Vector2(telegraph["center"])
	var radius := maxf(1.0, float(telegraph["radius"]))
	var affinity := AttackContract.normalize_affinity(StringName(telegraph["affinity"]))
	var readiness := clampf(float(telegraph.get("readiness", 1.0)), 0.0, 1.0)
	var intensity := smoothstep(0.0, 1.0, readiness)
	var color := Art.attack_warning_color(affinity, readiness)
	var damage := float(telegraph.get("damage", 0.0))
	var boundary_width := 4.0 if AttackContract.power_tier(damage) == &"heavy" else 3.0
	var boundary_alpha := lerpf(0.38, 0.90, intensity)
	var accent_alpha := lerpf(0.24, 0.66, intensity)
	_write_danger_ring(center, radius, Color(color, boundary_alpha))
	match affinity:
		AttackContract.THERMAL:
			_write_danger_ring(center, radius * 0.62, Color(color, accent_alpha))
		AttackContract.TOXIN:
			_write_danger_ring(center, radius * 0.70, Color(color, accent_alpha))
			_write_diamond(center, maxf(11.0, radius * 0.10), Color(color, accent_alpha))
		AttackContract.CRYO:
			_write_diamond(center, maxf(11.0, radius * 0.12), Color(color, accent_alpha))
		AttackContract.ARC:
			_write_beam(
				center - Vector2.RIGHT * radius * 0.68,
				center + Vector2.RIGHT * radius * 0.68,
				boundary_width,
				Color(color, accent_alpha)
			)
			_write_beam(
				center - Vector2.DOWN * radius * 0.68,
				center + Vector2.DOWN * radius * 0.68,
				boundary_width,
				Color(color, accent_alpha)
			)
		AttackContract.HYBRID:
			_write_danger_ring(center, radius * 0.55, Color(color, accent_alpha))
			_write_diamond(center, maxf(11.0, radius * 0.11), Color(color, accent_alpha))
		_:
			_write_diamond(center, maxf(10.0, radius * 0.09), Color(color, accent_alpha))


func _sync_support_telegraph(telegraph: Dictionary) -> void:
	var center := Vector2(telegraph["center"])
	var radius := maxf(1.0, float(telegraph["radius"]))
	_write_ring(center, radius, Color(Art.MINT, 0.88))
	_write_diamond(center, maxf(13.0, radius * 0.14), Art.MINT)


func _sync_experience(shards: Array[ExperienceShard], visible_world: Rect2) -> void:
	for shard in shards:
		var position := shard.pos
		var value := shard.value
		var kind := &"small" if value == 1 else (&"medium" if value <= 4 else &"large")
		var radius := float(Art.EXPERIENCE_RADII[kind])
		if not visible_world.grow(radius).has_point(position):
			continue
		var batch: BatchHandle = _experience_batches[kind]
		_write_instance(batch, position, 0.0, Vector2.ONE * radius, Color.WHITE)


func _sync_effects(effects: Array[Dictionary], visible_world: Rect2) -> void:
	for effect in effects:
		var position := Vector2(effect["pos"])
		var duration := maxf(0.001, float(effect["duration"]))
		var progress := 1.0 - clampf(float(effect["time"]) / duration, 0.0, 1.0)
		var radius := float(effect["radius"])
		if not visible_world.grow(radius).has_point(position):
			continue
		var event_id := StringName(effect["kind"])
		if not VisualEventCatalog.has_event(event_id):
			continue
		var event := VisualEventCatalog.descriptor(event_id)
		var mode := StringName(event.get("mode", &"animation"))
		var color := Color(effect["color"])
		color.a *= 1.0 - progress
		var direction := Vector2(effect.get("dir", Vector2.RIGHT)).normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		var target := Vector2(effect.get("target", position))
		var angle := (
			(target - position).angle()
			if event.get("rotation", &"") == &"target"
			and not target.is_equal_approx(position)
			else direction.angle()
			if event.get("rotation", &"") == &"direction"
			else 0.0
		)
		if mode == &"hud_only":
			continue
		if mode == &"live_emp_radius":
			_write_ring(
				position,
				radius,
				Color(color, maxf(0.20, color.a * 0.62))
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
		var draw_position := position
		if mode == &"pickup_intake" and not target.is_equal_approx(position):
			draw_position = position.lerp(target, ease(progress, 2.0))
		elif mode == &"directed_transfer" and not target.is_equal_approx(position):
			draw_position = position.lerp(target, progress)
			_write_beam(
				position,
				target,
				2.0,
				Color(color, color.a * 0.34)
			)
		var animation_id := StringName(event.get("animation", &""))
		if animation_id != &"":
			var frame_asset := AssetProvider.animation_frame_asset(
				animation_id,
				progress
			)
			_queue_semantic_texture(
				frame_asset,
				draw_position,
				angle,
				radius,
				color
			)
		if bool(event.get("floating_damage", false)):
			_queue_floating_damage(
				position + Vector2(
					-34.0,
					-radius * 0.62 - progress * 22.0
				),
				"%d  ×%d%%" % [
					maxi(1, roundi(float(effect.get("value", 0.0)))),
					roundi(float(effect.get("multiplier", 1.0)) * 100.0),
				],
				Color(color, 1.0 - progress)
			)


func _sync_world_overlays(state: Dictionary, visible_world: Rect2) -> void:
	if state.is_empty():
		return
	for zone in Array(state.get("zones", [])):
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
			"readiness": 1.0,
		}
		var warning := float(zone["warning"])
		if warning > 0.0:
			var warning_total := maxf(
				warning,
				float(zone.get("warning_total", warning))
			)
			descriptor["readiness"] = AttackContract.warning_readiness(
				warning,
				warning_total
			)
			_sync_area_telegraph(descriptor)
		else:
			_sync_area_telegraph(descriptor)
	for trail in Array(state.get("trails", [])):
		var position := Vector2(trail["pos"])
		if visible_world.has_point(position):
			var alpha := clampf(float(trail["time"]) / maxf(0.001, float(trail["duration"])), 0.0, 1.0)
			_write_ring(
				position,
				float(trail["radius"]),
				Color(Art.MUSTARD, alpha * 0.64)
			)
	var player_position := Vector2(state["player_position"])
	var hull_direction := Vector2(state["hull_direction"])
	var aim_direction := Vector2(state["aim_direction"])
	var reduced_motion := bool(state.get("reduced_motion", false))
	var hit_remaining := float(state.get("player_hit_remaining", 0.0))
	var protection_sources: Dictionary = state.get("protection_sources", {})
	var displayed_player_position := player_position
	var hull_color := Color.WHITE
	_sync_support_fields(Array(state.get("support_fields", [])))
	var feedback_color := Color.TRANSPARENT
	if hit_remaining > 0.0:
		var hit_progress := 1.0 - clampf(hit_remaining / 0.20, 0.0, 1.0)
		feedback_color = Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.24)
		if not reduced_motion:
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
	if bool(state.get("dash_active", false)):
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
	if float(state.get("muzzle_flash", 0.0)) > 0.0:
		_write_diamond(
			displayed_player_position + aim_direction * 64.0,
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
	if float(state.get("barrier_strength", 0.0)) > 0.0:
		var barrier_radius := 61.0
		if not reduced_motion:
			barrier_radius += sin(float(state.get("run_time", 0.0)) * 5.0) * 3.0
		for plate_index in 4:
			var plate_angle := TAU * float(plate_index) / 4.0
			_queue_semantic_texture(
				StringName(_defense_asset_ids.get(&"barrier", &"")),
				player_position + Vector2.RIGHT.rotated(plate_angle) * barrier_radius,
				plate_angle,
				22.0,
				Color.WHITE
			)
	var ion_level := int(state.get("ion_level", 0))
	if ion_level > 0:
		var ion_radius: float = ION_RADII[ion_level - 1]
		_write_ring(player_position, ion_radius, Color(Art.MINT, 0.48))
		_queue_semantic_texture(
			StringName(_defense_asset_ids.get(&"ion_field", &"")),
			player_position,
			0.0,
			24.0,
			Color.WHITE
		)
	var secondary: Dictionary = state.get("secondary", {})
	var blade_level := int(state.get("blade_level", 0))
	if blade_level > 0:
		var blade_count: int = [2, 3, 4][blade_level - 1]
		for blade_index in blade_count:
			var blade_position := player_position + Vector2.RIGHT.rotated(
				float(secondary.get("orbit_angle", 0.0)) + TAU * float(blade_index) / float(blade_count)
			) * 78.0
			var blade_direction := radial_outward_direction(
				player_position,
				blade_position
			)
			_queue_semantic_texture(
				StringName(_secondary_asset_ids.get(&"orbit_blade", &"")),
				blade_position,
				blade_direction.angle(),
				19.0,
				Color.WHITE
			)
	for mine in Array(secondary.get("mines", [])):
		_queue_semantic_texture(
			StringName(_secondary_asset_ids.get(&"wake_mine", &"")),
			Vector2(mine["pos"]),
			0.0,
			16.0,
			Color.WHITE
		)
	if bool(state.get("escort_drone", false)):
		var drone_position := Vector2(secondary.get("drone_position", player_position))
		var drone_direction := radial_outward_direction(
			player_position,
			drone_position
		)
		_queue_semantic_texture(
			StringName(_secondary_asset_ids.get(&"escort_drone", &"")),
			drone_position,
			drone_direction.angle(),
			19.0,
			Color.WHITE
		)
	var cursor_position := Vector2(state.get("cursor_position", player_position + aim_direction * 230.0))
	for direction in CARDINAL_DIRECTIONS:
		_write_diamond(cursor_position + direction * 18.0, 6.0, Art.MUSTARD)
	_write_diamond(cursor_position, 4.0, Art.IVORY_BRIGHT)


func _sync_support_fields(support_fields: Array) -> void:
	const TIMER_SEGMENTS := 8
	for support_variant in support_fields:
		var support := Dictionary(support_variant)
		var state := StringName(support.get("state", &"initial_delay"))
		if state in [&"initial_delay", &"depleted"]:
			continue
		var center := Vector2(support["position"])
		var radius := float(support["radius"])
		var kind := StringName(support["kind"])
		var progress := clampf(float(support["phase_progress"]), 0.0, 1.0)
		var active := bool(support["effect_active"])
		var color := Art.SUPPORT if kind == &"repair" else Art.PLAYER_REWARD
		if active:
			_write_disk(center, radius, Color(color, 0.20))
		_write_ring(center, radius, Color(color, 0.76))
		var visible_segments := clampi(
			ceili((1.0 - progress) * TIMER_SEGMENTS),
			0,
			TIMER_SEGMENTS
		)
		for segment in visible_segments:
			_write_instance(
				_overlay_batches[&"support_timer_segment"],
				center,
				-PI * 0.5 + TAU * float(segment) / float(TIMER_SEGMENTS),
				Vector2.ONE * (radius - 12.0),
				color
			)
		_queue_semantic_texture(
			(
				&"world/facility_repair_pad"
				if kind == &"repair"
				else &"world/facility_overdrive_lane"
			),
			center,
			0.0,
			48.0,
			Color.WHITE
		)
		if kind == &"repair" and active:
			_queue_semantic_texture(
				&"world/facility_repair_pad_core",
				center,
				0.0,
				24.0,
				Color.WHITE
			)
		_support_field_asset_count += 1


func _sync_resolved_boss_modules(
	state: Dictionary,
	visible_world: Rect2
) -> void:
	for module_variant in Array(state.get("resolved_boss_modules", [])):
		var module := Dictionary(module_variant)
		var position := Vector2(module["position"])
		var radius := float(module["radius"])
		if not visible_world.grow(radius).has_point(position):
			continue
		_queue_semantic_texture(
			_boss_module_asset_id_for(
				StringName(module["kind"]),
				int(module["index"]),
				true
			),
			position,
			0.0,
			radius,
			Color(0.52, 0.58, 0.66, 0.78)
		)
		_queue_semantic_texture(
			&"cue/objective_resolved",
			position - Vector2(0.0, radius + 14.0),
			0.0,
			14.0,
			Color.WHITE
		)


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


func _queue_floating_damage(
	position: Vector2,
	text: String,
	color: Color
) -> void:
	if _floating_damage_draw_count >= FLOATING_DAMAGE_DRAW_CAPACITY:
		return
	var damage_draw := _floating_damage_draws[
		_floating_damage_draw_count
	]
	damage_draw.position = position
	damage_draw.text = text
	damage_draw.color = color
	_floating_damage_draw_count += 1


func _draw_floating_damage(damage_draw: FloatingDamageDraw) -> void:
	var position := damage_draw.position
	var text := damage_draw.text
	var color := damage_draw.color
	draw_string(
		ThemeDB.fallback_font,
		position + Vector2(2.0, 2.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		Color(Art.COBALT_VOID, color.a)
	)
	draw_string(
		ThemeDB.fallback_font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		color
	)


func _boss_module_asset_id(enemy: EnemyState) -> StringName:
	var disabled := enemy.boss_module_state in [&"disabled", &"resolved"]
	return _boss_module_asset_id_for(
		enemy.boss_module_kind,
		enemy.boss_module_index,
		disabled
	)


func _boss_module_asset_id_for(
	module_kind: StringName,
	module_index: int,
	disabled: bool
) -> StringName:
	match module_kind:
		&"forge_plate":
			return (
				&"boss_module/forge_plate_disabled"
				if disabled
				else &"boss_module/forge_plate_active"
			)
		&"segment_lock":
			return (
				&"boss_module/segment_lock_disabled"
				if disabled
				else &"boss_module/segment_lock_active"
			)
		&"relay_positive":
			return &"boss_module/relay_positive"
		&"relay_negative":
			return &"boss_module/relay_negative"
		&"route_switch":
			return &"boss_module/route_switch"
		&"armor_car":
			return &"boss_module/armor_car"
		&"lattice_outer":
			return (
				&"boss_module/crown_lattice"
				if module_index == 0
				else &"boss_module/crown_pylon"
			)
	return &"actor/boss_pylon"


func _enemy_shield_asset_id(enemy: EnemyState) -> StringName:
	if enemy.archetype == &"generator":
		return StringName(_defense_asset_ids.get(&"generator_shield", &""))
	if enemy.archetype == &"shield_escort":
		return StringName(_defense_asset_ids.get(&"shield_escort", &""))
	return &""


func _sync_target_brackets(position: Vector2, radius: float) -> void:
	_queue_semantic_texture(
		&"cue/target_bracket_corner",
		position,
		0.0,
		radius + 8.0,
		Color.WHITE
	)


func _write_beam(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	_write_instance_basis(
		_overlay_batches[&"beam"], from + vector * 0.5,
		vector / length, Vector2(length * 0.5, width / 0.32), color
	)


func _write_player_barrel(
	position: Vector2,
	aim_direction: Vector2,
	tip_distance: float,
	color: Color
) -> void:
	if aim_direction.is_zero_approx():
		return
	var direction := aim_direction.normalized()
	var barrel_start := position + direction * 12.0
	var barrel_end := position + direction * tip_distance
	var vector := barrel_end - barrel_start
	var length := vector.length()
	if length <= 0.001:
		return
	var center := barrel_start + vector * 0.5
	_write_instance_basis(
		_overlay_batches[&"player_barrel"],
		center,
		direction,
		Vector2(length * 0.5, 7.0 / 0.32),
		Art.INK
	)
	_write_instance_basis(
		_overlay_batches[&"player_barrel"],
		center,
		direction,
		Vector2(length * 0.5, 3.0 / 0.32),
		color
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


func _enemy_angle(archetype: StringName, enemy: EnemyState, player_position: Vector2, run_time: float) -> float:
	if archetype in [
		&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser",
		&"shooter", &"artillery_spotter", &"bulkhead_guard",
		&"splitter_barge", &"stage_boss",
	]:
		return (player_position - enemy.pos).angle()
	if archetype in [&"turret", &"rammer", &"beam_sentinel"]:
		return enemy.committed_dir.angle()
	if archetype == &"controller":
		return run_time * 0.22
	return 0.0


func _write_instance(batch: BatchHandle, position: Vector2, angle: float, scale: Vector2, color: Color) -> void:
	if not batch.ensure_capacity(batch.count + 1):
		return
	batch.buffer.write(batch.count, position, angle, scale, color)
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
	_last_priority_marker_count = 0
	_last_tactic_module_count = 0
	for batch in _batches:
		batch.reset()


func _apply_visible_counts() -> void:
	for batch in _batches:
		batch.upload()
