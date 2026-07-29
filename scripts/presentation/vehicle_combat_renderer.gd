class_name VehicleCombatRenderer
extends Node2D

## Retained MultiMesh presentation for combat silhouettes and repeated semantic
## overlays. VehicleRun supplies state; this node owns visible instances.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const PixelCatalog = preload("res://scripts/presentation/vehicle_pixel_asset_catalog.gd")
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
const EFFECT_CAPACITY := 96
const STATUS_ARC_CAPACITY := ENEMY_CAPACITY * 3
const BUFFER_FLOATS_PER_INSTANCE := 12
const ATLAS_BUFFER_FLOATS_PER_INSTANCE := 16
const CUSTOM_BATCH_AABB := AABB(Vector3(-8192.0, -8192.0, -1.0), Vector3(16384.0, 16384.0, 2.0))
const PIXEL_SHADER := preload("res://pixel-art-production/runtime/shaders/pixel_atlas_multimesh.gdshader")
const STATIONARY_PIXEL_ARCHETYPES: Array[StringName] = [
	&"turret", &"mine", &"interceptor_tower", &"beam_sentinel",
	&"generator", &"boss_pylon",
]

class BatchBuffer:
	var values := PackedFloat32Array()


	func _init(capacity: int) -> void:
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


	func _init(target: MultiMeshInstance2D, target_buffer) -> void:
		instance = target
		buffer = target_buffer


	func reset() -> void:
		count = 0


	func upload() -> void:
		instance.multimesh.visible_instance_count = count
		if count > 0:
			instance.multimesh.buffer = buffer.values


class AtlasBatchBuffer:
	var values := PackedFloat32Array()


	func _init(capacity: int) -> void:
		values.resize(capacity * ATLAS_BUFFER_FLOATS_PER_INSTANCE)


	func write_basis(
		instance_index: int,
		position: Vector2,
		x_axis: Vector2,
		scale: Vector2,
		color: Color,
		uv_region: Color
	) -> void:
		var offset := instance_index * ATLAS_BUFFER_FLOATS_PER_INSTANCE
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
		values[offset + 12] = uv_region.r
		values[offset + 13] = uv_region.g
		values[offset + 14] = uv_region.b
		values[offset + 15] = uv_region.a


var _enemy_batches: Dictionary = {}
var _boss_variant_batches: Dictionary = {}
var _projectile_head_batches: Dictionary = {}
var _projectile_trail_batches: Dictionary = {}
var _experience_batches: Dictionary = {}
var _effect_batches: Dictionary = {}
var _overlay_batches: Dictionary = {}
var _batches: Array[BatchHandle] = []
var _pixel_catalog: VehiclePixelAssetCatalog
var _pixel_enabled := false
var _player_pixel_under: BatchHandle
var _player_projectile_pixel: BatchHandle
var _misc_pixel_batch: BatchHandle
var _pixel_frame_cache: Dictionary = {}


func _ready() -> void:
	z_index = -5
	_pixel_catalog = PixelCatalog.new()
	_pixel_enabled = _pixel_catalog.is_ready()
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
	if active:
		_sync_attack_telegraphs(enemies, visible_world)
		_sync_enemies(enemies, visible_world, player_position, run_time, aim_target_id)
		_sync_projectiles(player_projectiles, &"player", visible_world)
		_sync_projectiles(hostile_projectiles, &"enemy", visible_world)
		_sync_experience(shards, visible_world)
		_sync_effects(effects, visible_world)
		_sync_world_overlays(presentation, visible_world)
	_apply_visible_counts()


func debug_snapshot() -> Dictionary:
	var visible := 0
	var batch_counts := {}
	for batch in _batches:
		visible += batch.count
		if batch.count > 0:
			batch_counts[batch.instance.name] = batch.count
	return {
		"batches": _batches.size(),
		"visible_instances": visible,
		"batch_counts": batch_counts,
		"pixel_enabled": _pixel_enabled,
		"enemy_capacity": ENEMY_CAPACITY,
		"status_arc_capacity": STATUS_ARC_CAPACITY,
	}


func _build_batches() -> void:
	var pixel_enemy_family_batches := {}
	for archetype in Visuals.ENEMY_ARCHETYPES:
		if archetype == &"stage_boss":
			continue
		var pixel_family := (
			&"stationary_enemy_set"
			if archetype in STATIONARY_PIXEL_ARCHETYPES
			else &"mobile_enemy_set"
		)
		if _pixel_enabled and _pixel_catalog.has_family(pixel_family):
			if not pixel_enemy_family_batches.has(pixel_family):
				pixel_enemy_family_batches[pixel_family] = _create_atlas_batch(
					"Enemy_%s" % String(pixel_family),
					ENEMY_CAPACITY,
					0,
					pixel_family
				)
			_enemy_batches[archetype] = pixel_enemy_family_batches[pixel_family]
		else:
			_enemy_batches[archetype] = _create_batch(
				"Enemy_%s" % String(archetype),
				Visuals.enemy_mesh(archetype),
				ENEMY_CAPACITY,
				0,
				archetype
			)
	var shared_pixel_boss: BatchHandle
	if _pixel_enabled and _pixel_catalog.has_family(&"boss_set"):
		shared_pixel_boss = _create_atlas_batch(
			"Boss_boss_set", 1, 0, &"boss_set"
		)
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_boss_variant_batches[variant] = (
			shared_pixel_boss
			if shared_pixel_boss != null
			else _create_batch(
				"Boss_%s" % String(variant),
				Visuals.boss_mesh(variant),
				1,
				0,
				StringName("boss_%s" % String(variant))
			)
		)
	for team in [&"player", &"enemy"]:
		var capacity := (
			PROJECTILE_CAPACITY
			if team == &"player"
			else HOSTILE_PROJECTILE_CAPACITY
		)
		if team == &"player" and _pixel_enabled:
			_player_projectile_pixel = _create_atlas_batch(
				"Pixel_player_projectiles",
				PROJECTILE_CAPACITY,
				2,
				&"player_primary_projectiles"
			)
			continue
		var affinity_batches := {}
		var shared_hostile_pixel_batch: BatchHandle
		if (
			team == &"enemy"
			and _pixel_enabled
			and _pixel_catalog.has_family(&"hostile_projectile_affinities")
		):
			shared_hostile_pixel_batch = _create_atlas_batch(
				"Projectile_trail_enemy_affinities",
				capacity,
				1,
				&"hostile_projectile_affinities"
			)
		var rendered_affinities: Array[StringName] = []
		if team == &"player":
			rendered_affinities.append(AttackContract.KINETIC)
		else:
			rendered_affinities.append_array(AttackContract.AFFINITIES)
		for affinity in rendered_affinities:
			if affinity == AttackContract.SUPPORT:
				continue
			affinity_batches[affinity] = (
				shared_hostile_pixel_batch
				if shared_hostile_pixel_batch != null
				else _create_batch(
					"Projectile_trail_%s_%s" % [String(team), String(affinity)],
					(
						Visuals.projectile_trail_mesh(affinity)
						if team == &"player"
						else Visuals.hostile_projectile_envelope_mesh(affinity)
					),
					capacity,
					1,
					StringName("projectile_trail_%s_%s" % [String(team), String(affinity)])
				)
			)
		_projectile_trail_batches[team] = affinity_batches
		if team == &"player":
			_projectile_head_batches[team] = _create_batch(
				"Projectile_head_%s" % String(team),
				Visuals.player_projectile_head_mesh(),
				capacity,
				2,
				StringName("projectile_head_%s" % String(team))
			)
		else:
			_projectile_head_batches[team] = _create_batch(
				"Projectile_core_enemy",
				Visuals.hostile_projectile_core_mesh(),
				capacity,
				2,
				&"projectile_core_enemy"
			)
	var shared_experience_pixel_batch: BatchHandle
	if _pixel_enabled and _pixel_catalog.has_family(&"experience_shards"):
		shared_experience_pixel_batch = _create_atlas_batch(
			"Experience_experience_shards",
			EXPERIENCE_CAPACITY,
			-1,
			&"experience_shards"
		)
	for kind in [&"small", &"medium", &"large"]:
		var family := StringName("experience_%s" % String(kind))
		_experience_batches[kind] = (
			shared_experience_pixel_batch
			if shared_experience_pixel_batch != null
			else _create_batch(
				"Experience_%s" % String(kind),
				Visuals.experience_mesh(kind),
				EXPERIENCE_CAPACITY,
				-1,
				family
			)
		)
	for kind in [&"diamond", &"ring", &"afterimage", &"beam"]:
		# The pixel dash frames already own the player afterimage. Reuse that
		# retired batch slot for all other bounded pixel combat ornaments so
		# the production renderer stays within the existing batch ceiling.
		if _pixel_enabled and kind == &"afterimage":
			continue
		var family := StringName("effect_%s" % String(kind))
		_effect_batches[kind] = _create_batch(
			"Effect_%s" % String(kind),
			Visuals.effect_mesh(kind),
			EFFECT_CAPACITY,
			2,
			family
		)
	_overlay_batches[&"shield"] = _create_batch(
		"Overlay_shield", Visuals.effect_mesh(&"ring"), ENEMY_CAPACITY, 2, &"overlay_shield"
	)
	_overlay_batches[&"health_back"] = _create_batch(
		"Overlay_health_back", Visuals.health_bar_mesh(), ENEMY_CAPACITY, 2, &"overlay_health_back"
	)
	_overlay_batches[&"health_fill"] = _create_batch(
		"Overlay_health_fill", Visuals.health_bar_mesh(), ENEMY_CAPACITY, 3, &"overlay_health_fill"
	)
	_overlay_batches[&"ring"] = _create_batch(
		"Overlay_ring", Visuals.effect_mesh(&"ring"), 256, 3, &"overlay_ring"
	)
	_overlay_batches[&"danger_ring"] = _create_batch(
		"Overlay_danger_ring",
		Visuals.annulus_mesh(48, 0.975),
		256,
		3,
		&"overlay_danger_ring"
	)
	_overlay_batches[&"beam"] = _create_batch(
		"Overlay_beam", Visuals.effect_mesh(&"beam"), 256, 3, &"overlay_beam"
	)
	_overlay_batches[&"disk"] = _create_batch(
		"Overlay_disk", Visuals.disk_mesh(), 96, 1, &"overlay_disk"
	)
	_overlay_batches[&"diamond"] = _create_batch(
		"Overlay_diamond", Visuals.effect_mesh(&"diamond"), 96, 4, &"overlay_diamond"
	)
	if _pixel_enabled:
		_misc_pixel_batch = _create_atlas_batch(
			"Pixel_combat_ornaments", EFFECT_CAPACITY, 4, &"impact_effects"
		)
		_player_pixel_under = _create_atlas_batch(
			"Pixel_player_under", 8, 4, &"player_chassis"
		)
		_overlay_batches[&"player_barrel"] = _create_batch(
			"Overlay_player_barrel",
			Visuals.effect_mesh(&"beam"),
			2,
			5,
			&"overlay_player_barrel"
		)
	else:
		_overlay_batches[&"player_hull"] = _create_batch(
			"Overlay_player_hull", Visuals.player_hull_mesh(), 1, 4, &"overlay_player_hull"
		)
	_overlay_batches[&"status_arc"] = _create_batch(
		"Overlay_status_arc", Visuals.status_arc_mesh(),
		STATUS_ARC_CAPACITY, 3, &"overlay_status_arc"
	)
	_overlay_batches[&"support_timer_segment"] = _create_batch(
		"Overlay_support_timer_segment",
		Visuals.support_timer_segment_mesh(),
		96,
		3,
		&"overlay_support_timer_segment"
	)
	_reset_counts()
	_apply_visible_counts()


func _create_batch(
	batch_name: String,
	mesh: Mesh,
	capacity: int,
	child_z: int,
	_buffer_key: StringName
) -> BatchHandle:
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = capacity
	multi_mesh.visible_instance_count = 0
	multi_mesh.mesh = mesh
	multi_mesh.custom_aabb = CUSTOM_BATCH_AABB
	var instance := MultiMeshInstance2D.new()
	instance.name = batch_name
	instance.z_index = child_z
	instance.multimesh = multi_mesh
	add_child(instance)
	var handle := BatchHandle.new(instance, BatchBuffer.new(capacity))
	_batches.append(handle)
	return handle


func _create_atlas_batch(
	batch_name: String,
	capacity: int,
	child_z: int,
	texture_family: StringName
) -> BatchHandle:
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
	multi_mesh.use_colors = true
	multi_mesh.use_custom_data = true
	multi_mesh.instance_count = capacity
	multi_mesh.visible_instance_count = 0
	multi_mesh.mesh = Visuals.pixel_quad_mesh()
	multi_mesh.custom_aabb = CUSTOM_BATCH_AABB
	var instance := MultiMeshInstance2D.new()
	instance.name = batch_name
	instance.z_index = child_z
	instance.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	instance.multimesh = multi_mesh
	var material := ShaderMaterial.new()
	material.shader = PIXEL_SHADER
	material.set_shader_parameter("atlas_texture", _pixel_catalog.texture(texture_family))
	instance.material = material
	add_child(instance)
	var handle := BatchHandle.new(instance, AtlasBatchBuffer.new(capacity))
	_batches.append(handle)
	return handle


func _sync_enemies(enemies: Array[EnemyState], visible_world: Rect2, player_position: Vector2, run_time: float, aim_target_id: String) -> void:
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var position := enemy.pos
		if not visible_world.has_point(position):
			continue
		var role := enemy.role
		var archetype := enemy.archetype
		var batch: BatchHandle = (
			_boss_variant_batches.get(enemy.boss_variant)
			if archetype == &"stage_boss"
			else _enemy_batches.get(archetype)
		)
		if batch == null:
			continue
		var angle := _enemy_angle(archetype, enemy, player_position, run_time)
		var radius := enemy.visual_radius
		var color := Art.IVORY_BRIGHT if enemy.flash > 0.0 else Visuals.enemy_color(role)
		if _pixel_enabled:
			var pixel_family := (
				&"boss_set"
				if archetype == &"stage_boss"
				else (
					&"stationary_enemy_set"
					if archetype in STATIONARY_PIXEL_ARCHETYPES
					else &"mobile_enemy_set"
				)
			)
			var pixel_variant := enemy.boss_variant if archetype == &"stage_boss" else archetype
			var pixel_state := (
				&"read"
				if archetype == &"stage_boss"
				else (&"idle" if archetype in STATIONARY_PIXEL_ARCHETYPES else &"move")
			)
			var direction_index := _pixel_catalog.direction_index(
				Vector2.RIGHT.rotated(angle), 8
			)
			var frame := _cached_pixel_frame(
				pixel_family,
				pixel_variant,
				direction_index,
				pixel_state,
				0
			)
			if not frame.is_empty():
				var pixel_scale := radius * (1.10 if archetype == &"stage_boss" else 1.24)
				_write_atlas_instance(
					batch,
					position,
					0.0,
					Vector2.ONE * pixel_scale,
					Color.WHITE if enemy.flash <= 0.0 else Color(1.0, 0.65, 0.65),
					frame
				)
		else:
			_write_instance(batch, position, angle, Vector2.ONE * radius, color)
		_sync_enemy_readability_overlays(enemy, position, radius)
		if enemy.shielded:
			_write_instance(
				_overlay_batches[&"shield"], position, 0.0,
				Vector2.ONE * (radius + 14.0), Color(Art.MINT, 0.76)
			)
		var health_class := enemy.health_class
		var show_health := (
			health_class == &"priority"
			or enemy.id == aim_target_id
			or enemy.health_visible_timer > 0.0
		)
		if role != &"stage_boss" and show_health:
			var health_ratio := clampf(enemy.health / maxf(0.001, enemy.max_health), 0.0, 1.0)
			var bar_width := radius * 1.6
			var bar_position := position + Vector2(0.0, radius + 14.0)
			_write_instance(
				_overlay_batches[&"health_back"], bar_position,
				0.0, Vector2(bar_width, 10.0), Art.IVORY_SHADE
			)
			_write_instance(
				_overlay_batches[&"health_fill"],
				bar_position + Vector2(-bar_width * (1.0 - health_ratio) * 0.5, 0.0),
				0.0, Vector2(bar_width * health_ratio, 10.0), Art.CORAL
			)
		_sync_status_arcs(enemy, position, radius)
		_sync_enemy_semantic_overlays(enemy, position, radius, angle)
		if enemy.id == aim_target_id:
			_sync_target_brackets(position, radius + 16.0)


func _sync_enemy_readability_overlays(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	if enemy.health_class == &"priority":
		_write_instance(
			_overlay_batches[&"ring"],
			position,
			0.0,
			Vector2.ONE * (radius + 7.0),
			Color(Art.INK, 0.92)
		)
		_write_instance(
			_overlay_batches[&"diamond"],
			position - Vector2(0.0, radius + 12.0),
			0.0,
			Vector2(9.0, 7.0),
			Art.IVORY_BRIGHT
		)
	if enemy.threat_kind == &"ranged" and enemy.phase == &"startup":
		_write_instance(
			_overlay_batches[&"diamond"],
			position - Vector2(0.0, radius + 13.0),
			0.0,
			Vector2(13.0, 10.0),
			Art.MUSTARD
		)


func _sync_enemy_semantic_overlays(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	angle: float
) -> void:
	var forward := Vector2.RIGHT.rotated(angle)
	var side := forward.rotated(PI * 0.5)
	if enemy.guard_plate_structure > 0.0:
		for sign_value in [-1.0, 1.0]:
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position + forward * radius * 0.58 + side * sign_value * radius * 0.48,
				side,
				Vector2(radius * 0.48, 9.0),
				Art.IVORY_BRIGHT
			)
	if enemy.elite_trait == &"armored" and enemy.armor_structure > 0.0:
		for sign_value in [-1.0, 1.0]:
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position + side * sign_value * radius * 0.72,
				forward,
				Vector2(radius * 0.58, 10.0),
				Art.IVORY_BRIGHT
			)
	elif enemy.elite_trait == &"overclocked":
		for sign_value in [-1.0, 1.0]:
			_write_instance_basis(
				_overlay_batches[&"diamond"],
				position - forward * radius * 0.70 + side * sign_value * radius * 0.62,
				forward,
				Vector2(radius * 0.42, radius * 0.22),
				Art.MUSTARD
			)
		_write_instance(
			_overlay_batches[&"ring"], position, 0.0,
			Vector2.ONE * (radius + 11.0), Art.MUSTARD
		)
	elif enemy.elite_trait == &"heavy":
		_write_instance(
			_overlay_batches[&"ring"], position, 0.0,
			Vector2.ONE * (radius * 0.72), Art.IVORY_BRIGHT
		)
	if enemy.role != &"mine":
		return
	var mobile := enemy.archetype == &"spark_minelet"
	var activation_radius := 160.0 if mobile else 230.0
	var damage_radius := 100.0 if mobile else 160.0
	_write_instance(
		_overlay_batches[&"ring"], position, 0.0,
		Vector2.ONE * activation_radius, Color(Art.MUSTARD, 0.38)
	)
	_write_instance(
		_overlay_batches[&"danger_ring"], position, 0.0,
		Vector2.ONE * damage_radius, Color(Art.CORAL, 0.82)
	)
	if enemy.phase == &"mine_armed":
		var fuse := 1.0 if mobile else 1.25
		var readiness := 1.0 - clampf(enemy.phase_time / fuse, 0.0, 1.0)
		_write_instance(
			_overlay_batches[&"disk"], position, 0.0,
			Vector2.ONE * damage_radius * readiness, Color(Art.CORAL, 0.16 + readiness * 0.22)
		)


func _sync_status_arcs(enemy: EnemyState, position: Vector2, radius: float) -> void:
	var statuses := enemy.statuses
	var arc_radius := radius + 11.0
	if statuses.has(&"burn"):
		_write_instance(
			_overlay_batches[&"status_arc"], position, deg_to_rad(-120.0),
			Vector2.ONE * arc_radius, Art.CORAL
		)
	if statuses.has(&"poison"):
		_write_instance(
			_overlay_batches[&"status_arc"], position, 0.0,
			Vector2.ONE * arc_radius, Art.MINT
		)
	if statuses.has(&"chill"):
		_write_instance(
			_overlay_batches[&"status_arc"], position, deg_to_rad(120.0),
			Vector2.ONE * arc_radius, Art.COBALT_WATER
		)


func _sync_projectiles(
	projectiles: Array[ProjectileState],
	team: StringName,
	visible_world: Rect2
) -> void:
	var hostile := team == &"enemy"
	for projectile in projectiles:
		var position := projectile.pos
		if not visible_world.has_point(position):
			continue
		var affinity := AttackContract.normalize_affinity(projectile.affinity)
		if affinity == AttackContract.SUPPORT:
			affinity = AttackContract.KINETIC
		var render_affinity := AttackContract.KINETIC if team == &"player" else affinity
		var radius := maxf(1.0, projectile.radius)
		var direction := projectile.velocity.normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		if team == &"player" and _pixel_enabled:
			var pixel_family := (
				&"secondary_seeker"
				if projectile.owner == "passive_seeker"
				else &"player_primary_projectiles"
			)
			var variant := (
				&"seeker_missile"
				if pixel_family == &"secondary_seeker"
				else (&"opening_breach" if projectile.breach_visual else &"standard")
			)
			var direction_index := _pixel_catalog.direction_index(direction, 8)
			var sequence_index: int = posmod(projectile.spawn_serial, 2)
			var frame := _cached_pixel_frame(
				pixel_family,
				variant,
				direction_index,
				StringName("flight_%d" % sequence_index),
				0 if pixel_family == &"secondary_seeker" else sequence_index
			)
			if not frame.is_empty():
				_write_atlas_instance(
					_player_projectile_pixel,
					position,
					0.0,
					Vector2.ONE * (
						22.0
						if pixel_family == &"secondary_seeker"
						else (
							16.0
							* Art.PLAYER_PRIMARY_PROJECTILE_SCALE
							* radius / 6.0
						)
					),
					Color.WHITE,
					frame
				)
			continue
		var affinity_batches: Dictionary = _projectile_trail_batches[team]
		var trail_batch: BatchHandle = affinity_batches[render_affinity]
		var color := Art.attack_color(affinity) if hostile else Art.MUSTARD
		if hostile:
			if _pixel_enabled:
				var motion_state := StringName(
					"affinity_motion_%d" % posmod(projectile.spawn_serial, 2)
				)
				var hostile_frame := _cached_pixel_frame(
					&"hostile_projectile_affinities",
					affinity,
					0,
					motion_state,
					0
				)
				if not hostile_frame.is_empty():
					_write_atlas_instance_basis(
						trail_batch,
						position,
						direction,
						Vector2.ONE * (
							radius * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
						),
						Color.WHITE,
						hostile_frame
					)
			else:
				_write_instance_basis(
					trail_batch,
					position,
					direction,
					Vector2.ONE * (
						radius * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
					),
					Color(color, 0.72)
				)
			# The bright core ends at the collision boundary. Everything in
			# the larger affinity envelope is presentation-only.
			_write_instance_basis(
				_projectile_head_batches[team],
				position,
				direction,
				Vector2.ONE * radius,
				Color.WHITE
			)
			continue
		var trail_length := (
			47.0 + maxf(0.0, radius - 7.0) * 3.0
		)
		var trail_offset := trail_length * 0.5 - radius
		var trail_width := radius * 1.5
		if team == &"player" and projectile.breach_visual:
			_write_instance_basis(
				trail_batch,
				position - direction * (trail_length * 0.5 - radius),
				direction,
				Vector2(maxf(48.0, trail_length), maxf(10.0, radius * 1.7)),
				Color(Art.MUSTARD, 0.72)
			)
			_write_instance_basis(
				_overlay_batches[&"diamond"],
				position,
				direction,
				Vector2(radius * 1.35, radius),
				Art.IVORY_BRIGHT
			)
			_write_instance_basis(
				_overlay_batches[&"diamond"],
				position,
				direction,
				Vector2(radius * 0.62, radius * 0.46),
				Art.COBALT_DEEP
			)
			continue
		_write_instance_basis(
			trail_batch,
			position - direction * trail_offset,
			direction,
			Vector2(trail_length, trail_width),
			Color(color, 0.50)
		)
		_write_instance_basis(
			_projectile_head_batches[team],
			position,
			direction,
			Vector2.ONE * (
				radius * Art.PLAYER_PRIMARY_PROJECTILE_SCALE
			),
			Color.WHITE
		)


func _sync_attack_telegraphs(
	enemies: Array[EnemyState],
	visible_world: Rect2
) -> void:
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var startup := enemy.phase in [&"startup", &"boss_startup"]
		var active := enemy.phase in [&"active", &"boss_active"]
		for telegraph in enemy.attack_telegraphs:
			if not _telegraph_intersects_view(telegraph, visible_world):
				continue
			var shape := StringName(telegraph.get("shape", &""))
			if startup and shape == &"corridor":
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
				and float(telegraph.get("active_width", 0.0)) > 0.0
			):
				_sync_active_beam(telegraph)
			if startup:
				_sync_commit_marker(telegraph)


func _sync_commit_marker(telegraph: Dictionary) -> void:
	var commit_mode := StringName(telegraph.get("commit_mode", &""))
	if commit_mode.is_empty():
		return
	var center := (
		Vector2(telegraph.get("center", Vector2.ZERO))
		if telegraph.has("center")
		else Vector2(telegraph.get("from", Vector2.ZERO))
	)
	if commit_mode == &"interruptible_signature":
		for side in [-1.0, 1.0]:
			_write_instance(
				_overlay_batches[&"diamond"],
				center + Vector2(side * 19.0, 0.0),
				0.0,
				Vector2(10.0, 16.0),
				Art.MUSTARD
			)
	elif commit_mode == &"committed":
		_write_instance(
			_overlay_batches[&"diamond"], center, 0.0,
			Vector2.ONE * 18.0, Art.CORAL
		)
	elif commit_mode == &"autonomous":
		_write_instance(
			_overlay_batches[&"ring"], center, 0.0,
			Vector2.ONE * 22.0, Art.ATTACK_ARC
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
	var fill_alpha := lerpf(0.035, 0.11, intensity)
	var boundary_alpha := lerpf(0.36, 0.88, intensity)
	var accent_alpha := lerpf(0.24, 0.68, intensity)
	# A swept circle produces a capsule, not a rectangle. These endpoint disks
	# make the warning footprint match the same point-to-segment hit test.
	_write_beam(from, to, half_width * 2.0, Color(color, fill_alpha))
	_write_disk(from, half_width, Color(color, fill_alpha))
	_write_disk(to, half_width, Color(color, fill_alpha))
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
	_write_disk(center, radius, Color(color, lerpf(0.025, 0.075, intensity)))
	_write_disk(center, radius * 0.55, Color(color, lerpf(0.045, 0.15, intensity)))
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
		if not visible_world.has_point(position):
			continue
		var value := shard.value
		var kind := &"small" if value == 1 else (&"medium" if value <= 4 else &"large")
		var radius := float(Art.EXPERIENCE_RADII[kind])
		var batch: BatchHandle = _experience_batches[kind]
		if _pixel_enabled:
			var frame := _cached_pixel_frame(
				&"experience_shards", kind, 0, &"idle", 0
			)
			if not frame.is_empty():
				_write_atlas_instance(
					batch,
					position,
					0.0,
					Vector2.ONE * (radius * 2.0),
					Color.WHITE,
					frame
				)
		else:
			_write_instance(batch, position, 0.0, Vector2.ONE * radius, Art.MUSTARD)


func _sync_effects(effects: Array[Dictionary], visible_world: Rect2) -> void:
	for effect in effects:
		var position := Vector2(effect["pos"])
		if not visible_world.has_point(position):
			continue
		var duration := maxf(0.001, float(effect["duration"]))
		var progress := 1.0 - clampf(float(effect["time"]) / duration, 0.0, 1.0)
		var radius := float(effect["radius"])
		var kind := String(effect["kind"])
		if _pixel_enabled and kind in ["impact", "muzzle"]:
			var frame_index := clampi(int(floor(progress * 4.0)), 0, 3)
			var impact_frame := _cached_pixel_frame(
				&"impact_effects",
				&"enemy" if kind == "impact" else &"player_hull",
				0,
				StringName("frame_%d" % frame_index),
				frame_index
			)
			if not impact_frame.is_empty():
				_write_atlas_instance(
					_misc_pixel_batch,
					position,
					0.0,
					Vector2.ONE * maxf(18.0, radius),
					Color.WHITE,
					impact_frame
				)
			continue
		if _pixel_enabled and kind == "afterimage":
			continue
		var family := &"ring"
		var angle := 0.0
		var scale := Vector2.ONE * lerpf(maxf(5.0, radius * 0.25), radius, progress)
		if kind in ["impact", "muzzle"]:
			family = &"diamond"
			scale = Vector2.ONE * lerpf(8.0, radius, progress)
		elif kind == "afterimage":
			family = &"afterimage"
			angle = Vector2(effect.get("dir", Vector2.RIGHT)).angle()
			scale = Vector2.ONE * Art.PLAYER_VISUAL_RADIUS
		elif kind == "reflect":
			family = &"beam"
			angle = Vector2(effect.get("dir", Vector2.RIGHT)).angle()
			scale = Vector2(radius, 9.0)
		elif kind == "dash_start":
			scale = Vector2.ONE * lerpf(radius, radius * 0.20, progress)
		var color := Color(effect["color"])
		color.a *= 1.0 - progress
		var batch: BatchHandle = _effect_batches[family]
		_write_instance(batch, position, angle, scale, color)


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
			var color := Art.attack_color(affinity)
			_sync_area_telegraph(descriptor)
			_write_disk(position, radius, Color(color, 0.18))
	for trail in Array(state.get("trails", [])):
		var position := Vector2(trail["pos"])
		if visible_world.has_point(position):
			var alpha := clampf(float(trail["time"]) / maxf(0.001, float(trail["duration"])), 0.0, 1.0)
			_write_disk(position, float(trail["radius"]), Color(Art.MUSTARD, alpha * 0.28))
	var player_position := Vector2(state["player_position"])
	var hull_direction := Vector2(state["hull_direction"])
	var aim_direction := Vector2(state["aim_direction"])
	var reduced_motion := bool(state.get("reduced_motion", false))
	var hit_remaining := float(state.get("player_hit_remaining", 0.0))
	var invulnerable_remaining := float(state.get("player_invulnerable_remaining", 0.0))
	var displayed_player_position := player_position
	var hull_color := _upgrade_shade(
		Art.MUSTARD, Art.MUSTARD_DARK, int(state.get("hull_visual_tier", 0))
	)
	var primary_color := _upgrade_shade(
		Art.MUSTARD, Art.MUSTARD_DARK, int(state.get("primary_visual_tier", 0))
	)
	var secondary_color := _upgrade_shade(
		Art.MINT, Art.CERAMIC_GREEN, int(state.get("secondary_visual_tier", 0))
	)
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
	elif invulnerable_remaining > 0.0:
		if reduced_motion:
			feedback_color = Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.56)
		else:
			var pale_coral := Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.62)
			pale_coral.a = 0.78
			if int(floor(float(state.get("run_time", 0.0)) * 16.0)) % 2 == 0:
				feedback_color = pale_coral
	if feedback_color.a > 0.0:
		hull_color = feedback_color
		primary_color = feedback_color
		secondary_color = feedback_color
	var hull_angle := hull_direction.angle()
	var engine_count := clampi(int(state.get("engine_visual_count", 0)), 0, 3)
	var rear := -hull_direction.normalized()
	var side := rear.rotated(PI * 0.5)
	if _pixel_enabled:
		_sync_pixel_player(
			state,
			displayed_player_position,
			hull_direction,
			aim_direction,
			hull_color,
			primary_color,
			engine_count,
			feedback_color
		)
	else:
		for engine_index in engine_count:
			var offset_index := float(engine_index) - float(engine_count - 1) * 0.5
			_write_instance(
				_overlay_batches[&"diamond"],
				displayed_player_position + rear * 31.0 + side * offset_index * 18.0,
				hull_angle,
				Vector2(18.0, 12.0),
				hull_color
			)
		_write_instance(
			_overlay_batches[&"player_hull"], displayed_player_position,
			hull_angle, Vector2.ONE * Art.PLAYER_VISUAL_RADIUS,
			hull_color
		)
		_write_beam(
			displayed_player_position,
			displayed_player_position + aim_direction * 61.0,
			17.0,
			Art.INK
		)
		_write_beam(
			displayed_player_position,
			displayed_player_position + aim_direction * 61.0,
			10.0,
			primary_color
		)
		_write_diamond(
			displayed_player_position + aim_direction * 64.0,
			9.0 + float(state.get("muzzle_flash", 0.0)) * 58.0,
			Art.MUSTARD
		)
	if int(state.get("secondary_visual_tier", 0)) > 0:
		_write_diamond(
			displayed_player_position - hull_direction * 5.0 - side * 25.0,
			12.0,
			secondary_color
		)
	if invulnerable_remaining > 0.0:
		_write_ring(player_position, Art.PLAYER_VISUAL_RADIUS + 12.0, Color(Art.CORAL, 0.78))
	if float(state.get("barrier_strength", 0.0)) > 0.0:
		var barrier_radius := 61.0
		if not reduced_motion:
			barrier_radius += sin(float(state.get("run_time", 0.0)) * 5.0) * 3.0
		_write_ring(player_position, barrier_radius, Color(Art.MINT, 0.86))
	var ion_level := int(state.get("ion_level", 0))
	if ion_level > 0:
		var ion_radius: float = [120.0, 140.0, 160.0][ion_level - 1]
		_write_ring(player_position, ion_radius, Color(Art.MINT, 0.48))
	var secondary: Dictionary = state.get("secondary", {})
	var blade_level := int(state.get("blade_level", 0))
	if blade_level > 0:
		var blade_count: int = [2, 3, 4][blade_level - 1]
		var blade_frame := _cached_pixel_frame(
			&"secondary_orbit_blades", &"blade", 0, &"orbit", 0
		) if _pixel_enabled else {}
		for blade_index in blade_count:
			var blade_position := player_position + Vector2.RIGHT.rotated(
				float(secondary.get("orbit_angle", 0.0)) + TAU * float(blade_index) / float(blade_count)
			) * 78.0
			if not blade_frame.is_empty():
				_write_atlas_instance(
					_misc_pixel_batch,
					blade_position,
					float(secondary.get("orbit_angle", 0.0)),
					Vector2.ONE * 22.0,
					Color.WHITE,
					blade_frame
				)
			else:
				_write_diamond(blade_position, 13.0, Art.MUSTARD)
	for mine in Array(secondary.get("mines", [])):
		var mine_state := &"armed" if bool(mine.get("armed", false)) else &"idle"
		var mine_frame := _cached_pixel_frame(
			&"secondary_wake_mines", &"mine", 0, mine_state, 0
		) if _pixel_enabled else {}
		if not mine_frame.is_empty():
			_write_atlas_instance(
				_misc_pixel_batch,
				Vector2(mine["pos"]),
				0.0,
				Vector2.ONE * 26.0,
				Color.WHITE,
				mine_frame
			)
		else:
			_write_diamond(Vector2(mine["pos"]), 16.0, Art.CORAL)
	if bool(state.get("escort_drone", false)):
		var drone_position := Vector2(secondary.get("drone_position", player_position))
		var drone_direction := (player_position - drone_position).normalized()
		var drone_frame := _cached_pixel_frame(
			&"secondary_escort_drone",
			&"drone",
			_pixel_catalog.direction_index(drone_direction, 8),
			&"follow",
			0
		) if _pixel_enabled else {}
		if not drone_frame.is_empty():
			_write_atlas_instance(
				_misc_pixel_batch,
				drone_position,
				0.0,
				Vector2.ONE * 32.0,
				Color.WHITE,
				drone_frame
			)
		else:
			_write_diamond(drone_position, 18.0, Art.MINT_SOFT)
	var cursor_position := Vector2(state.get("cursor_position", player_position + aim_direction * 230.0))
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_write_diamond(cursor_position + direction * 18.0, 6.0, Art.MUSTARD)
	_write_diamond(cursor_position, 4.0, Art.IVORY_BRIGHT)


func _sync_pixel_player(
	state: Dictionary,
	position: Vector2,
	hull_direction: Vector2,
	aim_direction: Vector2,
	_hull_color: Color,
	_primary_color: Color,
	engine_count: int,
	feedback_color: Color
) -> void:
	var player_scale := Art.PLAYER_VISUAL_RADIUS
	var hull_direction_index := _pixel_catalog.direction_index(hull_direction, 16)
	var hull_tier := clampi(int(state.get("hull_visual_tier", 0)), 0, 3)
	var hull_tint := Color.WHITE * (1.0 - float(hull_tier) * 0.10)
	# The invulnerability ring already carries that state; preserve the authored
	# pixel palette unless this frame is responding to an actual hit.
	if float(state.get("player_hit_remaining", 0.0)) > 0.0 and feedback_color.a > 0.0:
		hull_tint = Color(1.0, 0.50, 0.50, feedback_color.a)
	var moving := float(state.get("player_speed", 0.0)) > 12.0
	var flame_variant := &"thrust" if moving else &"idle"
	var flame_frame := _cached_pixel_frame(
		&"player_engine_flame",
		flame_variant,
		hull_direction_index,
		flame_variant,
		0
	)
	if not flame_frame.is_empty():
		_write_atlas_instance(
			_player_pixel_under,
			position,
			0.0,
			Vector2.ONE * player_scale,
			hull_tint,
			flame_frame
		)
	if bool(state.get("dash_active", false)):
		var dash_progress := clampf(float(state.get("dash_progress", 0.0)), 0.0, 1.0)
		var dash_variant := &"travel"
		if dash_progress < 0.22:
			dash_variant = &"start"
		elif dash_progress > 0.78:
			dash_variant = &"end"
		var dash_direction := Vector2(state.get("dash_direction", hull_direction))
		var dash_frame := _cached_pixel_frame(
			&"player_dash_effect",
			dash_variant,
			_pixel_catalog.direction_index(dash_direction, 16),
			&"frame_0",
			0
		)
		if not dash_frame.is_empty():
			_write_atlas_instance(
				_player_pixel_under,
				position,
				0.0,
				Vector2.ONE * player_scale,
				Color(1.0, 1.0, 1.0, 0.88),
				dash_frame
			)
	var module_frame := _cached_pixel_frame(
		&"player_engine_modules",
		StringName("module_count_%d" % engine_count),
		_pixel_catalog.direction_index(hull_direction, 4),
		&"installed",
		0
	)
	if not module_frame.is_empty():
		_write_atlas_instance(
			_player_pixel_under,
			position,
			0.0,
			Vector2.ONE * player_scale,
			hull_tint,
			module_frame
		)
	var hull_frame := _cached_pixel_frame(
		&"player_chassis",
		&"base",
		hull_direction_index,
		&"normal",
		0
	)
	if not hull_frame.is_empty():
		_write_atlas_instance(
			_player_pixel_under,
			position,
			0.0,
			Vector2.ONE * player_scale,
			hull_tint,
			hull_frame
		)
	var muzzle_flash := float(state.get("muzzle_flash", 0.0))
	var barrel_tip_distance := 28.0 if muzzle_flash > 0.0 else 32.0
	_write_player_barrel(
		position,
		aim_direction,
		barrel_tip_distance,
		_primary_color
	)
	if muzzle_flash > 0.0:
		_write_diamond(
			position + aim_direction * barrel_tip_distance,
			7.0 + muzzle_flash * 45.0,
			Art.IVORY_BRIGHT
		)


func _sync_support_fields(support_fields: Array) -> void:
	const TIMER_SEGMENTS := 24
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
		var color := Art.MINT if kind == &"repair" else Art.MUSTARD
		var opacity := 0.26 if active else (0.14 if state == &"warning" else 0.07)
		_write_disk(center, radius, Color(color, opacity))
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
		_write_disk(
			center,
			48.0,
			Color(
				Art.CERAMIC_GREEN_MID if kind == &"repair" else Art.MUSTARD_DARK,
				0.92
			)
		)
		if _pixel_enabled:
			var fixture_family := (
				&"repair_field" if kind == &"repair" else &"overdrive_field"
			)
			var fixture_state := &"active" if active else &"dormant"
			if state == &"warning":
				fixture_state = &"warning"
			var fixture_frame := _cached_pixel_frame(
				fixture_family, &"center_fixture", 0, fixture_state, 0
			)
			if not fixture_frame.is_empty():
				_write_atlas_instance(
					_misc_pixel_batch,
					center,
					0.0,
					Vector2.ONE * 46.0,
					Color.WHITE,
					fixture_frame
				)
				continue
		if kind == &"repair":
			_write_beam(
				center - Vector2(0.0, 30.0),
				center + Vector2(0.0, 30.0),
				20.0,
				Art.IVORY_BRIGHT
			)
			_write_beam(
				center - Vector2(30.0, 0.0),
				center + Vector2(30.0, 0.0),
				20.0,
				Art.IVORY_BRIGHT
			)
		else:
			for index in 2:
				var point := center + Vector2(0.0, 12.0 - index * 25.0)
				_write_beam(
					point + Vector2(-14.0, 8.0),
					point,
					9.0,
					Art.IVORY_BRIGHT
				)
				_write_beam(
					point,
					point + Vector2(14.0, 8.0),
					9.0,
					Art.IVORY_BRIGHT
				)


func _upgrade_shade(base: Color, target: Color, tier: int) -> Color:
	var mix_values := [0.0, 0.28, 0.52, 0.72]
	return base.lerp(target, mix_values[clampi(tier, 0, 3)])


func _sync_target_brackets(position: Vector2, radius: float) -> void:
	for corner in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		var typed_corner := Vector2(corner)
		var anchor: Vector2 = position + typed_corner * radius
		_write_beam(anchor, anchor - Vector2(typed_corner.x, 0.0) * 18.0, 6.0, Art.MUSTARD)
		_write_beam(anchor, anchor - Vector2(0.0, typed_corner.y) * 18.0, 6.0, Art.MUSTARD)


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


func _cached_pixel_frame(
	family: StringName,
	variant: StringName,
	direction_index: int,
	state: StringName,
	sequence_index: int
) -> Dictionary:
	var key := hash(family)
	key = key * 31 + hash(variant)
	key = key * 31 + direction_index
	key = key * 31 + hash(state)
	key = key * 31 + sequence_index
	if _pixel_frame_cache.has(key):
		return _pixel_frame_cache[key]
	var frame := _pixel_catalog.frame(
		family,
		variant,
		direction_index,
		state,
		sequence_index
	)
	if not frame.is_empty():
		frame["_cached_uv"] = _pixel_catalog.frame_uv(frame)
	_pixel_frame_cache[key] = frame
	return frame


func _write_atlas_instance(
	batch: BatchHandle,
	position: Vector2,
	angle: float,
	scale: Vector2,
	color: Color,
	frame: Dictionary
) -> void:
	_write_atlas_instance_basis(
		batch,
		position,
		Vector2(cos(angle), sin(angle)),
		scale,
		color,
		frame
	)


func _write_atlas_instance_basis(
	batch: BatchHandle,
	position: Vector2,
	x_axis: Vector2,
	scale: Vector2,
	color: Color,
	frame: Dictionary
) -> void:
	if batch == null or batch.count >= batch.instance.multimesh.instance_count:
		return
	var atlas_buffer: AtlasBatchBuffer = batch.buffer
	atlas_buffer.write_basis(
		batch.count,
		position,
		x_axis,
		scale,
		color,
		Color(frame["_cached_uv"])
	)
	batch.count += 1


func _write_instance(batch: BatchHandle, position: Vector2, angle: float, scale: Vector2, color: Color) -> void:
	if batch.count >= batch.instance.multimesh.instance_count:
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
	if batch.count >= batch.instance.multimesh.instance_count:
		return
	batch.buffer.write_basis(batch.count, position, x_axis, scale, color)
	batch.count += 1


func _reset_counts() -> void:
	for batch in _batches:
		batch.reset()


func _apply_visible_counts() -> void:
	for batch in _batches:
		batch.upload()
