class_name VehicleCombatRenderer
extends Node2D

## Retained MultiMesh presentation for combat silhouettes and repeated semantic
## overlays. VehicleRun supplies state; this node owns visible instances.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")

const ENEMY_CAPACITY := 128
const PROJECTILE_CAPACITY := 240
const HOSTILE_PROJECTILE_CAPACITY := 120
const EXPERIENCE_CAPACITY := 192
const EFFECT_CAPACITY := 96
const BUFFER_FLOATS_PER_INSTANCE := 12
const CUSTOM_BATCH_AABB := AABB(Vector3(-8192.0, -8192.0, -1.0), Vector3(16384.0, 16384.0, 2.0))

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
	var buffer: BatchBuffer
	var count := 0


	func _init(target: MultiMeshInstance2D, target_buffer: BatchBuffer) -> void:
		instance = target
		buffer = target_buffer


	func reset() -> void:
		count = 0


	func upload() -> void:
		instance.multimesh.visible_instance_count = count
		if count > 0:
			instance.multimesh.buffer = buffer.values


var _enemy_batches: Dictionary = {}
var _projectile_head_batches: Dictionary = {}
var _projectile_trail_batches: Dictionary = {}
var _experience_batches: Dictionary = {}
var _effect_batches: Dictionary = {}
var _overlay_batches: Dictionary = {}
var _batches: Array[BatchHandle] = []


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
		_sync_enemies(enemies, visible_world, player_position, run_time, aim_target_id)
		_sync_projectiles(player_projectiles, &"player", visible_world)
		_sync_projectiles(hostile_projectiles, &"enemy", visible_world)
		_sync_experience(shards, visible_world)
		_sync_effects(effects, visible_world)
		_sync_world_overlays(presentation, visible_world)
	_apply_visible_counts()


func debug_snapshot() -> Dictionary:
	var visible := 0
	for batch in _batches:
		visible += batch.count
	return {
		"batches": _batches.size(),
		"visible_instances": visible,
	}


func _build_batches() -> void:
	for archetype in Visuals.ENEMY_ARCHETYPES:
		_enemy_batches[archetype] = _create_batch(
			"Enemy_%s" % String(archetype),
			Visuals.enemy_mesh(archetype),
			ENEMY_CAPACITY,
			0,
			archetype
		)
	for team in [&"player", &"enemy"]:
		var capacity := (
			PROJECTILE_CAPACITY
			if team == &"player"
			else HOSTILE_PROJECTILE_CAPACITY
		)
		_projectile_trail_batches[team] = _create_batch(
			"Projectile_trail_%s" % String(team),
			Visuals.projectile_trail_mesh(),
			capacity,
			1,
			StringName("projectile_trail_%s" % String(team))
		)
		_projectile_head_batches[team] = _create_batch(
			"Projectile_head_%s" % String(team),
			Visuals.projectile_head_mesh(),
			capacity,
			2,
			StringName("projectile_head_%s" % String(team))
		)
	for kind in [&"small", &"medium", &"large"]:
		var family := StringName("experience_%s" % String(kind))
		_experience_batches[kind] = _create_batch(
			"Experience_%s" % String(kind),
			Visuals.experience_mesh(kind),
			EXPERIENCE_CAPACITY,
			-1,
			family
		)
	for kind in [&"diamond", &"ring", &"afterimage", &"beam"]:
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
	_overlay_batches[&"beam"] = _create_batch(
		"Overlay_beam", Visuals.effect_mesh(&"beam"), 256, 3, &"overlay_beam"
	)
	_overlay_batches[&"disk"] = _create_batch(
		"Overlay_disk", Visuals.disk_mesh(), 96, 1, &"overlay_disk"
	)
	_overlay_batches[&"diamond"] = _create_batch(
		"Overlay_diamond", Visuals.effect_mesh(&"diamond"), 96, 4, &"overlay_diamond"
	)
	_overlay_batches[&"player"] = _create_batch(
		"Overlay_player", Visuals.player_mesh(), 1, 4, &"overlay_player"
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


func _sync_enemies(enemies: Array[EnemyState], visible_world: Rect2, player_position: Vector2, run_time: float, aim_target_id: String) -> void:
	for enemy in enemies:
		if not enemy.alive or not enemy.active:
			continue
		var position := enemy.pos
		if not visible_world.has_point(position):
			continue
		var role := enemy.role
		var archetype := enemy.archetype
		var batch: BatchHandle = _enemy_batches.get(archetype)
		if batch == null:
			continue
		var angle := _enemy_angle(archetype, enemy, player_position, run_time)
		var radius := enemy.visual_radius
		var color := Art.IVORY_BRIGHT if enemy.flash > 0.0 else Visuals.enemy_color(role)
		_write_instance(batch, position, angle, Vector2.ONE * radius, color)
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
		_sync_enemy_telegraph(enemy, role, position)
		if enemy.id == aim_target_id:
			_sync_target_brackets(position, radius + 16.0)


func _sync_projectiles(
	projectiles: Array[ProjectileState],
	team: StringName,
	visible_world: Rect2
) -> void:
	var head_batch: BatchHandle = _projectile_head_batches[team]
	var trail_batch: BatchHandle = _projectile_trail_batches[team]
	for projectile in projectiles:
		var position := projectile.pos
		if not visible_world.has_point(position):
			continue
		var hostile := team == &"enemy"
		var minimum_radius := 7.0 if not hostile or projectile.final_damage else 6.0
		var radius := maxf(minimum_radius, projectile.radius * 1.15)
		var direction := projectile.velocity.normalized()
		var trail_length := 36.0 if hostile else 47.0
		var trail_offset := trail_length * 0.5 - radius
		var trail_width := radius * (1.25 if hostile else 1.5)
		_write_instance_basis(
			trail_batch,
			position - direction * trail_offset,
			direction,
			Vector2(trail_length, trail_width),
			Color(projectile.color, 0.50)
		)
		_write_instance_basis(
			head_batch,
			position,
			direction,
			Vector2.ONE * radius,
			projectile.color
		)


func _sync_experience(shards: Array[ExperienceShard], visible_world: Rect2) -> void:
	for shard in shards:
		var position := shard.pos
		if not visible_world.has_point(position):
			continue
		var value := shard.value
		var kind := &"small" if value == 1 else (&"medium" if value <= 4 else &"large")
		var radius := 9.0 if value == 1 else (12.0 if value <= 4 else 17.0)
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
		if not visible_world.has_point(position):
			continue
		var radius := float(zone["radius"])
		if float(zone["warning"]) > 0.0:
			_write_ring(position, radius, Color(Art.CORAL, 0.88))
			_write_diamond(position, 13.0, Art.CORAL)
		else:
			_write_disk(position, radius, Color(Art.CORAL, 0.26))
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
	var player_color := Color.WHITE
	if hit_remaining > 0.0:
		var hit_progress := 1.0 - clampf(hit_remaining / 0.20, 0.0, 1.0)
		player_color = Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.24)
		if not reduced_motion:
			var amplitude := 5.0 * (1.0 - hit_progress)
			var jitter_direction := Vector2(
				sin(float(state.get("run_time", 0.0)) * 91.0),
				cos(float(state.get("run_time", 0.0)) * 73.0)
			).normalized()
			displayed_player_position += jitter_direction * amplitude
	elif invulnerable_remaining > 0.0:
		if reduced_motion:
			player_color = Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.56)
		else:
			var pale_coral := Color(Art.CORAL).lerp(Art.IVORY_BRIGHT, 0.62)
			pale_coral.a = 0.78
			if int(floor(float(state.get("run_time", 0.0)) * 16.0)) % 2 == 0:
				player_color = pale_coral
	_write_instance(
		_overlay_batches[&"player"], displayed_player_position,
		hull_direction.angle(), Vector2.ONE * Art.PLAYER_VISUAL_RADIUS,
		player_color
	)
	if invulnerable_remaining > 0.0:
		_write_ring(player_position, Art.PLAYER_VISUAL_RADIUS + 12.0, Color(Art.CORAL, 0.78))
	_write_beam(player_position, player_position + aim_direction * 61.0, 17.0, Art.INK)
	_write_beam(player_position, player_position + aim_direction * 61.0, 10.0, Art.IVORY_BRIGHT)
	_write_diamond(
		player_position + aim_direction * 64.0,
		9.0 + float(state.get("muzzle_flash", 0.0)) * 58.0,
		Art.MUSTARD
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
			_write_diamond(blade_position, 13.0, Art.MUSTARD)
	for mine in Array(secondary.get("mines", [])):
		_write_diamond(Vector2(mine["pos"]), 16.0, Art.CORAL)
	if bool(state.get("escort_drone", false)):
		_write_diamond(Vector2(secondary.get("drone_position", player_position)), 18.0, Art.MINT_SOFT)
	var cursor_position := Vector2(state.get("cursor_position", player_position + aim_direction * 230.0))
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_write_diamond(cursor_position + direction * 18.0, 6.0, Art.MUSTARD)
	_write_diamond(cursor_position, 4.0, Art.IVORY_BRIGHT)


func _sync_enemy_telegraph(enemy: EnemyState, role: StringName, position: Vector2) -> void:
	var phase := enemy.phase
	var direction := enemy.committed_dir
	if phase == &"startup":
		match role:
			&"chaser":
				_write_warning_beam(position, direction, 190.0, 34.0, Art.CORAL)
			&"shooter", &"turret":
				_write_warning_beam(position, direction, 620.0, 20.0, Color(Art.CORAL, 0.72))
			&"controller":
				_write_ring(enemy.committed_target, 112.0, Art.CORAL)
			&"mine":
				_write_ring(position, 190.0, Art.CORAL)
			&"artillery_spotter":
				_write_ring(enemy.committed_target, 175.0, Art.CORAL)
			&"interceptor_tower":
				_write_warning_beam(position, direction, 700.0, 18.0, Color(Art.BOSS_MAGENTA, 0.72))
			&"rammer":
				_write_warning_beam(position, direction, 640.0, 54.0, Art.CORAL)
			&"drone_carrier":
				_write_ring(position, 86.0, Art.MINT)
			&"beam_sentinel":
				_write_warning_beam(position, direction, 920.0, 54.0, Color(Art.CORAL, 0.78))
	if role == &"beam_sentinel" and phase == &"active":
		_write_beam(position, enemy.beam_end, 54.0, Art.CORAL)
		_write_beam(position, enemy.beam_end, 9.0, Art.IVORY_BRIGHT)


func _sync_target_brackets(position: Vector2, radius: float) -> void:
	for corner in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		var typed_corner := Vector2(corner)
		var anchor: Vector2 = position + typed_corner * radius
		_write_beam(anchor, anchor - Vector2(typed_corner.x, 0.0) * 18.0, 6.0, Art.MUSTARD)
		_write_beam(anchor, anchor - Vector2(0.0, typed_corner.y) * 18.0, 6.0, Art.MUSTARD)


func _write_warning_beam(origin: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	_write_beam(origin, origin + direction.normalized() * length, width, Color(color, color.a * 0.62))


func _write_beam(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var vector := to - from
	var length := vector.length()
	if length <= 0.001:
		return
	_write_instance_basis(
		_overlay_batches[&"beam"], from + vector * 0.5,
		vector / length, Vector2(length * 0.5, width / 0.32), color
	)


func _write_ring(position: Vector2, radius: float, color: Color) -> void:
	_write_instance(
		_overlay_batches[&"ring"], position, 0.0,
		Vector2.ONE * radius, color
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
	if archetype in [&"scrap_drone", &"needle_drone", &"chaser", &"shooter", &"artillery_spotter", &"stage_boss"]:
		return (player_position - enemy.pos).angle()
	if archetype in [&"turret", &"rammer", &"beam_sentinel"]:
		return enemy.committed_dir.angle()
	if archetype == &"controller":
		return run_time * 0.22
	return 0.0


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
