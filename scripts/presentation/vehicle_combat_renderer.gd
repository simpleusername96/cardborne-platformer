class_name VehicleCombatRenderer
extends Node2D

## Retained MultiMesh presentation for combat silhouettes and repeated semantic
## overlays. VehicleRun supplies state; this node owns visible instances.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
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
const EFFECT_CAPACITY := 96
const STATUS_ARC_CAPACITY := ENEMY_CAPACITY * 3
const BUFFER_FLOATS_PER_INSTANCE := 12
const CUSTOM_BATCH_AABB := AABB(Vector3(-8192.0, -8192.0, -1.0), Vector3(16384.0, 16384.0, 2.0))
const MAX_ORDINARY_HEALTH_BARS := 12
const MAX_EXTRA_PRIORITY_MARKERS := 8
const ENEMY_BATCH_INITIAL_CAPACITY := 96
const PROJECTILE_BATCH_INITIAL_CAPACITY := 96
const EXPERIENCE_BATCH_INITIAL_CAPACITY := 64
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


var _enemy_batches: Dictionary = {}
var _boss_variant_batches: Dictionary = {}
var _projectile_head_batches: Dictionary = {}
var _projectile_trail_batches: Dictionary = {}
var _experience_batches: Dictionary = {}
var _effect_batches: Dictionary = {}
var _overlay_batches: Dictionary = {}
var _batches: Array[BatchHandle] = []
var _player_hull_batch: BatchHandle
var _player_engine_batch: BatchHandle
var _player_engine_flare_batch: BatchHandle
var _player_primary_batch: BatchHandle
var _player_secondary_batch: BatchHandle
var _last_health_bar_count := 0
var _last_priority_marker_count := 0
var _last_tactic_module_count := 0


func _ready() -> void:
	z_index = -5
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
		_sync_enemies(
			enemies, visible_world, player_position, run_time, aim_target_id
		)
		_sync_projectiles(player_projectiles, &"player", visible_world)
		_sync_projectiles(hostile_projectiles, &"enemy", visible_world)
		_sync_experience(shards, visible_world)
		_sync_effects(effects, visible_world)
		_sync_world_overlays(presentation, visible_world)
	_apply_visible_counts()


static func player_engine_sockets(
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
	var normalized_sockets: Array = descriptor.get(
		"rear_sockets",
		[Vector2(-0.58, -0.43), Vector2(-0.58, 0.43)]
	)
	var result: Array[Vector2] = []
	for socket_variant in normalized_sockets:
		var socket := Vector2(socket_variant)
		result.append(
			player_position
			+ normalized * socket.x * Art.PLAYER_VISUAL_RADIUS
			+ lateral * socket.y * Art.PLAYER_VISUAL_RADIUS
		)
	return result


func debug_snapshot() -> Dictionary:
	var visible := 0
	var allocated := 0
	var maximum := 0
	var batch_counts := {}
	for batch in _batches:
		visible += batch.count
		allocated += batch.instance.multimesh.instance_count
		maximum += batch.max_capacity
		if batch.count > 0:
			batch_counts[batch.instance.name] = batch.count
	return {
		"batches": _batches.size(),
		"visible_instances": visible,
		"allocated_instances":allocated,
		"maximum_instances":maximum,
		"batch_counts": batch_counts,
		"enemy_capacity": ENEMY_CAPACITY,
		"status_arc_capacity": STATUS_ARC_CAPACITY,
		"health_bar_count": _last_health_bar_count,
		"priority_marker_count": _last_priority_marker_count,
		"tactic_module_count": _last_tactic_module_count,
	}


func _build_batches() -> void:
	for archetype in Visuals.ENEMY_ARCHETYPES:
		if archetype == &"stage_boss":
			continue
		_enemy_batches[archetype] = _create_batch(
			"Enemy_%s" % String(archetype),
			Visuals.enemy_mesh(archetype),
			ENEMY_CAPACITY,
			0,
			archetype,
			ENEMY_BATCH_INITIAL_CAPACITY
		)
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_boss_variant_batches[variant] = _create_batch(
			"Boss_%s" % String(variant),
			Visuals.boss_mesh(variant),
			1,
			0,
			StringName("boss_%s" % String(variant))
		)
	for team in [&"player", &"enemy"]:
		var capacity := (
			PROJECTILE_CAPACITY
			if team == &"player"
			else HOSTILE_PROJECTILE_CAPACITY
		)
		var affinity_batches := {}
		var rendered_affinities: Array[StringName] = []
		if team == &"player":
			rendered_affinities.append(AttackContract.KINETIC)
		else:
			rendered_affinities.append_array(AttackContract.AFFINITIES)
		for affinity in rendered_affinities:
			if affinity == AttackContract.SUPPORT:
				continue
			affinity_batches[affinity] = _create_batch(
				"Projectile_trail_%s_%s" % [String(team), String(affinity)],
				(
					Visuals.projectile_trail_mesh(affinity)
					if team == &"player"
					else Visuals.hostile_projectile_envelope_mesh(affinity)
				),
				capacity,
				1,
				StringName("projectile_trail_%s_%s" % [String(team), String(affinity)]),
				PROJECTILE_BATCH_INITIAL_CAPACITY
			)
		_projectile_trail_batches[team] = affinity_batches
		if team == &"player":
			_projectile_head_batches[team] = _create_batch(
				"Projectile_head_%s" % String(team),
				Visuals.player_projectile_head_mesh(),
				capacity,
				2,
				StringName("projectile_head_%s" % String(team)),
				PROJECTILE_BATCH_INITIAL_CAPACITY
			)
		else:
			_projectile_head_batches[team] = _create_batch(
				"Projectile_core_enemy",
				Visuals.hostile_projectile_core_mesh(),
				capacity,
				2,
				&"projectile_core_enemy",
				PROJECTILE_BATCH_INITIAL_CAPACITY
			)
	for kind in [&"small", &"medium", &"large"]:
		var family := StringName("experience_%s" % String(kind))
		_experience_batches[kind] = _create_batch(
			"Experience_%s" % String(kind),
			Visuals.experience_mesh(kind),
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
		384
	)
	_overlay_batches[&"shield"] = _overlay_batches[&"ring"]
	_overlay_batches[&"danger_ring"] = _create_batch(
		"Overlay_danger_ring",
		Visuals.annulus_mesh(48, 0.975),
		256,
		3,
		&"overlay_danger_ring",
		64
	)
	_overlay_batches[&"beam"] = _create_batch(
		"Overlay_beam", Visuals.effect_mesh(&"beam"), 1024, 3, &"overlay_beam",
		256
	)
	_overlay_batches[&"disk"] = _create_batch(
		"Overlay_disk", Visuals.disk_mesh(), 96, 1, &"overlay_disk"
	)
	_overlay_batches[&"diamond"] = _create_batch(
		"Overlay_diamond", Visuals.effect_mesh(&"diamond"), 640, 4, &"overlay_diamond",
		96
	)
	_effect_batches[&"ring"] = _overlay_batches[&"ring"]
	_effect_batches[&"beam"] = _overlay_batches[&"beam"]
	_effect_batches[&"diamond"] = _overlay_batches[&"diamond"]
	_effect_batches[&"afterimage"] = _create_batch(
		"Effect_afterimage",
		Visuals.effect_mesh(&"afterimage"),
		EFFECT_CAPACITY,
		2,
		&"effect_afterimage",
		16
	)
	_player_engine_flare_batch = _create_batch(
		"Player_engine_flare",
		Visuals.player_engine_flare_mesh(),
		4,
		3,
		&"player_engine_flare"
	)
	_player_engine_batch = _create_batch(
		"Player_engine",
		Visuals.player_engine_mesh(),
		4,
		4,
		&"player_engine"
	)
	_player_hull_batch = _create_batch(
		"Player_hull",
		Visuals.player_hull_mesh(),
		1,
		5,
		&"player_hull"
	)
	_player_primary_batch = _create_batch(
		"Player_primary_mount",
		Visuals.player_primary_mesh(),
		1,
		6,
		&"player_primary_mount"
	)
	_player_secondary_batch = _create_batch(
		"Player_secondary",
		Visuals.player_secondary_core_mesh(),
		8,
		6,
		&"player_secondary"
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
	_buffer_key: StringName,
	initial_capacity: int = -1
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
	add_child(instance)
	var handle := BatchHandle.new(
		instance,
		BatchBuffer.new(allocated_capacity),
		capacity
	)
	_batches.append(handle)
	return handle


func _sync_enemies(
	enemies: Array[EnemyState],
	visible_world: Rect2,
	player_position: Vector2,
	run_time: float,
	aim_target_id: String
) -> void:
	var budgets := _enemy_overlay_budgets(
		enemies, visible_world, player_position, aim_target_id
	)
	var health_ids: Dictionary = budgets["health"]
	var priority_ids: Dictionary = budgets["priority"]
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
		_write_instance(
			batch,
			position,
			angle,
			Vector2.ONE * radius,
			color
		)
		_sync_collective_tactic_module(enemy, position, radius)
		_sync_enemy_priority_marker(
			enemy, position, radius, priority_ids.has(enemy.id)
		)
		if enemy.threat_kind == &"ranged" and enemy.phase == &"startup":
			_write_instance(
				_overlay_batches[&"diamond"],
				position - Vector2(0.0, radius + 13.0),
				0.0,
				Vector2(13.0, 10.0),
				Art.MUSTARD
			)
		if enemy.shielded:
			_write_instance(
				_overlay_batches[&"shield"], position, 0.0,
				Vector2.ONE * (radius + 14.0), Color(Art.MINT, 0.76)
			)
		if health_ids.has(enemy.id):
			var health_ratio := clampf(
				enemy.health / maxf(0.001, enemy.max_health), 0.0, 1.0
			)
			var bar_width := radius * 1.6
			var bar_position := position + Vector2(0.0, radius + 14.0)
			_write_instance(
				_overlay_batches[&"health"], bar_position,
				0.0, Vector2(bar_width, 10.0), Art.IVORY_SHADE
			)
			_write_instance(
				_overlay_batches[&"health"],
				bar_position + Vector2(
					-bar_width * (1.0 - health_ratio) * 0.5, 0.0
				),
				0.0, Vector2(bar_width * health_ratio, 10.0), Art.CORAL
			)
		_sync_status_arcs(enemy, position, radius)
		_sync_enemy_semantic_overlays(enemy, position, radius, angle)
		if enemy.id == aim_target_id:
			_sync_target_brackets(position, radius + 16.0)


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
	var side := direction.rotated(PI * 0.5)
	match phase:
		&"gather":
			_write_instance(
				_overlay_batches[&"diamond"],
				position - direction * radius * 0.56,
				direction.angle(),
				Vector2.ONE * 5.0,
				Art.TEXT_MUTED
			)
			_last_tactic_module_count += 1
		&"lock":
			var tip := position + direction * radius * 0.78
			_write_beam(
				tip,
				position - direction * radius * 0.08 + side * radius * 0.44,
				5.0,
				Art.BOSS_COMMAND
			)
			_write_beam(
				tip,
				position - direction * radius * 0.08 - side * radius * 0.44,
				5.0,
				Art.BOSS_COMMAND
			)
			_last_tactic_module_count += 1
		&"execute":
			_write_instance(
				_overlay_batches[&"diamond"],
				position + direction * radius * 0.62,
				direction.angle(),
				Vector2(8.0, 5.0),
				Art.TEXT_PRIMARY
			)
			_write_beam(
				position - direction * radius * 0.72,
				position + direction * radius * 0.20,
				4.0,
				Art.BOSS_COMMAND
			)
			_last_tactic_module_count += 1
		&"break":
			_write_beam(
				position - direction * radius * 0.42 - side * radius * 0.42,
				position + direction * radius * 0.42 + side * radius * 0.42,
				5.0,
				Art.INK
			)
			_write_beam(
				position - direction * radius * 0.42 + side * radius * 0.42,
				position + direction * radius * 0.42 - side * radius * 0.42,
				5.0,
				Art.INK
			)
			_last_tactic_module_count += 1
func _enemy_overlay_budgets(
	enemies: Array[EnemyState],
	visible_world: Rect2,
	player_position: Vector2,
	aim_target_id: String
) -> Dictionary:
	var health_scores := PackedInt64Array()
	var priority_scores := PackedInt64Array()
	var health_by_score: Dictionary = {}
	var priority_by_score: Dictionary = {}
	for enemy in enemies:
		if (
			enemy == null
			or not enemy.alive
			or not enemy.active
			or not visible_world.has_point(enemy.pos)
		):
			continue
		if (
			enemy.role != &"stage_boss"
			and (
				enemy.health_class == &"priority"
				or enemy.id == aim_target_id
				or enemy.health_visible_timer > 0.0
				or enemy.phase in [&"startup", &"active"]
			)
		):
			var health_score := _unique_overlay_score(
				enemy, player_position, aim_target_id, health_by_score
			)
			health_scores.append(health_score)
			health_by_score[health_score] = enemy
		if enemy.health_class == &"priority":
			var priority_score := _unique_overlay_score(
				enemy, player_position, aim_target_id, priority_by_score
			)
			priority_scores.append(priority_score)
			priority_by_score[priority_score] = enemy
	health_scores.sort()
	priority_scores.sort()
	var health_ids := {}
	var priority_ids := {}
	for index in mini(MAX_ORDINARY_HEALTH_BARS, health_scores.size()):
		var candidate: EnemyState = health_by_score[health_scores[index]]
		health_ids[candidate.id] = true
	for index in mini(MAX_EXTRA_PRIORITY_MARKERS, priority_scores.size()):
		var candidate: EnemyState = priority_by_score[priority_scores[index]]
		priority_ids[candidate.id] = true
	_last_health_bar_count = health_ids.size()
	_last_priority_marker_count = priority_ids.size()
	return {"health": health_ids, "priority": priority_ids}


func _unique_overlay_score(
	enemy: EnemyState,
	player_position: Vector2,
	aim_target_id: String,
	occupied: Dictionary
) -> int:
	var distance_key := mini(
		99999999,
		roundi(player_position.distance_squared_to(enemy.pos))
	)
	var score := (
		_enemy_overlay_rank(enemy, aim_target_id) * 1000000000000
		+ distance_key * 10000
		+ (enemy.id.hash() & 0x1fff)
	)
	while occupied.has(score):
		score += 1
	return score


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


func _sync_enemy_semantic_overlays(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	angle: float
) -> void:
	var forward := Vector2.RIGHT.rotated(angle)
	var side := forward.rotated(PI * 0.5)
	if enemy.role == &"boss_pylon":
		_sync_boss_module_overlay(enemy, position, radius, forward, side)
		return
	if enemy.role == &"stage_boss":
		_sync_boss_core_overlay(enemy, position, radius)
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
	elif enemy.elite_trait == &"heavy":
		for sign_value in [-1.0, 1.0]:
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position + forward * sign_value * radius * 0.52,
				side,
				Vector2(radius * 0.46, 9.0),
				Art.TEXT_PRIMARY
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


func _sync_boss_core_overlay(
	enemy: EnemyState,
	position: Vector2,
	radius: float
) -> void:
	var core_color := (
		Art.PLAYER_REWARD
		if enemy.boss_module_state == &"open"
		else Art.BOSS_COMMAND
	)
	_write_instance(
		_overlay_batches[&"diamond"],
		position,
		PI / 4.0,
		Vector2.ONE * radius * 0.19,
		core_color
	)


func _sync_boss_module_overlay(
	enemy: EnemyState,
	position: Vector2,
	radius: float,
	forward: Vector2,
	side: Vector2
) -> void:
	var cue_color := (
		Art.PLAYER_REWARD
		if enemy.boss_module_state == &"active"
		else Art.TEXT_MUTED
	)
	var short := radius * 0.46
	match enemy.boss_module_kind:
		&"forge_plate":
			for sign_value in [-1.0, 1.0]:
				_write_instance_basis(
					_overlay_batches[&"beam"],
					position + side * sign_value * radius * 0.30,
					forward,
					Vector2(short, 7.0),
					cue_color
				)
		&"segment_lock":
			var tip := position + forward * radius * 0.42
			_write_beam(
				tip,
				position - forward * radius * 0.20 + side * radius * 0.38,
				6.0,
				cue_color
			)
			_write_beam(
				tip,
				position - forward * radius * 0.20 - side * radius * 0.38,
				6.0,
				cue_color
			)
		&"relay_positive":
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position,
				forward,
				Vector2(short, 7.0),
				cue_color
			)
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position,
				side,
				Vector2(short, 7.0),
				cue_color
			)
		&"relay_negative":
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position,
				forward,
				Vector2(short, 7.0),
				cue_color
			)
		&"route_switch":
			_write_beam(
				position - forward * radius * 0.44,
				position + forward * radius * 0.10,
				7.0,
				cue_color
			)
			_write_beam(
				position + forward * radius * 0.08,
				position + forward * radius * 0.42 + side * radius * 0.34,
				7.0,
				cue_color
			)
			_write_beam(
				position + forward * radius * 0.08,
				position + forward * radius * 0.42 - side * radius * 0.34,
				7.0,
				cue_color
			)
		&"armor_car":
			for sign_value in [-1.0, 1.0]:
				_write_instance_basis(
					_overlay_batches[&"beam"],
					position + forward * sign_value * radius * 0.24,
					side,
					Vector2(short, 8.0),
					cue_color
				)
		_:
			_write_instance(
				_overlay_batches[&"diamond"],
				position,
				PI / 4.0,
				Vector2.ONE * radius * 0.34,
				cue_color
			)
			_write_instance_basis(
				_overlay_batches[&"beam"],
				position,
				forward,
				Vector2(short, 6.0),
				Art.INK
			)
	if enemy.boss_module_state == &"active":
		_write_instance(
			_overlay_batches[&"diamond"],
			position - side * radius * 0.72,
			0.0,
			Vector2(7.0, 5.0),
			Art.TEXT_PRIMARY
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
			Vector2.ONE * arc_radius, Art.COBALT_ENERGY
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
		var affinity_batches: Dictionary = _projectile_trail_batches[team]
		var trail_batch: BatchHandle = affinity_batches[render_affinity]
		var color := Art.attack_color(affinity) if hostile else Art.MUSTARD
		if hostile:
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
			Vector2.ONE * radius,
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
	if commit_mode == &"committed":
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
			family = &"beam"
			angle = Vector2(effect.get("dir", Vector2.RIGHT)).angle()
			scale = Vector2(
				lerpf(radius * 1.65, radius * 0.25, progress),
				lerpf(18.0, 4.0, progress)
			)
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
	var protection_sources: Dictionary = state.get("protection_sources", {})
	var displayed_player_position := player_position
	var hull_color := _upgrade_shade(
		Art.MUSTARD, Art.MUSTARD_DARK, int(state.get("hull_visual_tier", 0))
	)
	var primary_color := _upgrade_shade(
		Art.MUSTARD, Art.MUSTARD_DARK, int(state.get("primary_visual_tier", 0))
	)
	var secondary_color := _upgrade_shade(
		Art.MINT, Art.STRUCTURE_BASE, int(state.get("secondary_visual_tier", 0))
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
	if feedback_color.a > 0.0:
		hull_color = feedback_color
		primary_color = feedback_color
		secondary_color = feedback_color
	var hull_angle := hull_direction.angle()
	var engine_upgrade_count := clampi(
		int(state.get("engine_visual_count", 0)),
		0,
		2
	)
	var rear := -hull_direction.normalized()
	var side := rear.rotated(PI * 0.5)
	var engine_sockets := player_engine_sockets(
		displayed_player_position,
		hull_direction
	)
	if engine_upgrade_count > 0:
		engine_sockets.append(
			displayed_player_position
			+ rear * Art.PLAYER_VISUAL_RADIUS * 0.50
		)
	if engine_upgrade_count > 1:
		engine_sockets.append(
			displayed_player_position
			+ rear * Art.PLAYER_VISUAL_RADIUS * 0.30
		)
	var thrust_ratio := clampf(float(state.get("player_speed", 0.0)) / 560.0, 0.0, 1.0)
	if bool(state.get("dash_active", false)):
		thrust_ratio = 1.0
	for mount_position in engine_sockets:
		_write_instance(
			_player_engine_flare_batch,
			mount_position + rear * (13.0 + thrust_ratio * 9.0),
			hull_angle,
			Vector2(14.0 + thrust_ratio * 19.0, 6.0),
			Color(Art.SYSTEM, 0.56 + thrust_ratio * 0.38)
		)
		_write_instance(
			_player_engine_batch,
			mount_position,
			hull_angle,
			Vector2(15.0, 10.0),
			Art.IVORY_SHADE
		)
	_write_instance(
		_player_hull_batch,
		displayed_player_position,
		hull_angle,
		Vector2.ONE * Art.PLAYER_VISUAL_RADIUS,
		hull_color
	)
	var primary_mount_position := displayed_player_position + aim_direction * 12.0
	_write_instance(
		_player_primary_batch,
		primary_mount_position,
		aim_direction.angle(),
		Vector2(25.0, 10.0),
		primary_color
	)
	if float(state.get("muzzle_flash", 0.0)) > 0.0:
		_write_diamond(
			displayed_player_position + aim_direction * 64.0,
			9.0 + float(state.get("muzzle_flash", 0.0)) * 58.0,
			Art.MUSTARD
		)
	if int(state.get("secondary_visual_tier", 0)) > 0:
		_write_instance(
			_player_secondary_batch,
			displayed_player_position - hull_direction * 5.0 - side * 25.0,
			hull_angle,
			Vector2.ONE * 12.0,
			secondary_color
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
		_write_ring(player_position, barrier_radius, Color(Art.MINT, 0.86))
	var ion_level := int(state.get("ion_level", 0))
	if ion_level > 0:
		var ion_radius: float = [120.0, 140.0, 160.0][ion_level - 1]
		_write_ring(player_position, ion_radius, Color(Art.MINT, 0.48))
	var secondary: Dictionary = state.get("secondary", {})
	var blade_level := int(state.get("blade_level", 0))
	if blade_level > 0:
		var blade_count: int = [2, 3, 4][blade_level - 1]
		for blade_index in blade_count:
			var blade_position := player_position + Vector2.RIGHT.rotated(
				float(secondary.get("orbit_angle", 0.0)) + TAU * float(blade_index) / float(blade_count)
			) * 78.0
			_write_instance(
				_player_secondary_batch,
				blade_position,
				float(secondary.get("orbit_angle", 0.0)),
				Vector2(19.0, 8.0),
				Art.MUSTARD
			)
	for mine in Array(secondary.get("mines", [])):
		_write_diamond(Vector2(mine["pos"]), 16.0, Art.CORAL)
	if bool(state.get("escort_drone", false)):
		var drone_position := Vector2(secondary.get("drone_position", player_position))
		var drone_direction := (player_position - drone_position).normalized()
		_write_instance(
			_player_secondary_batch,
			drone_position,
			drone_direction.angle(),
			Vector2(19.0, 15.0),
			Art.MINT_SOFT
		)
	var cursor_position := Vector2(state.get("cursor_position", player_position + aim_direction * 230.0))
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_write_diamond(cursor_position + direction * 18.0, 6.0, Art.MUSTARD)
	_write_diamond(cursor_position, 4.0, Art.IVORY_BRIGHT)


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
		var color := Art.SUPPORT if kind == &"repair" else Art.PLAYER_REWARD
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
				Art.LINE if kind == &"repair" else Art.RAISED,
				0.92
			)
		)
		if kind == &"repair":
			_write_beam(
				center - Vector2(0.0, 30.0),
				center + Vector2(0.0, 30.0),
				20.0,
				Art.TEXT_PRIMARY
			)
			_write_beam(
				center - Vector2(30.0, 0.0),
				center + Vector2(30.0, 0.0),
				20.0,
				Art.TEXT_PRIMARY
			)
		else:
			for index in 2:
				var point := center + Vector2(0.0, 12.0 - index * 25.0)
				_write_beam(
					point + Vector2(-14.0, 8.0),
					point,
					9.0,
					Art.TEXT_PRIMARY
				)
				_write_beam(
					point,
					point + Vector2(14.0, 8.0),
					9.0,
					Art.TEXT_PRIMARY
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
