class_name SlimeKingPatternRuntime
extends Node2D

signal pattern_started(pattern_id: StringName, snapshot: Dictionary)
signal state_changed(pattern_id: StringName, state: StringName, snapshot: Dictionary)
signal pattern_finished(pattern_id: StringName, snapshot: Dictionary)
signal schedule_finished(snapshot: Dictionary)
signal add_count_changed(active_count: int)
signal damage_committed(pattern_id: StringName, target: Node, damage_info: DamageInfo)

const STATE_IDLE := &"idle"
const STATE_STARTUP := &"startup"
const STATE_ACTIVE := &"active"
const STATE_RECOVERY := &"recovery"
const STATE_NEUTRAL := &"neutral"
const STATE_CANCELLED := &"cancelled"

const SMALL_SLIME_SCENE: PackedScene = preload("res://scenes/enemies/SmallSlime.tscn")
const DAMAGE_ZONE_RUNTIME := preload("res://scripts/bosses/SlimeKingDamageZoneRuntime.gd")
const BODY_BUMP_SPEED := 760.0
const JUMP_HEIGHT := 190.0
const SPAWN_PLAYER_CLEARANCE := 150.0
const SPAWN_MARKER_SEPARATION := 120.0
const POISON_BAND_COUNT := 4

const WARNING_FILL := Color(1.0, 0.72, 0.16, 0.18)
const WARNING_OUTLINE := Color(1.0, 0.88, 0.30, 0.96)
const SAFE_OUTLINE := Color(0.36, 0.94, 0.86, 0.92)
const ACTIVE_FILL := Color(0.94, 0.20, 0.25, 0.72)
const ACTIVE_OUTLINE := Color(1.0, 0.78, 0.24, 1.0)
const POISON_FILL := Color(0.56, 0.16, 0.68, 0.78)
const POISON_OUTLINE := Color(0.94, 0.46, 0.96, 1.0)

var _actor: Node2D
var _ground_rect: Rect2
var _platform_rects: Array[Rect2] = []
var _spawn_candidates := PackedVector2Array()
var _schedule: BossPatternSchedule
var _pattern_index: int = -1
var _current_pattern: BossPatternDefinition
var _state: StringName = STATE_IDLE
var _state_time_remaining: float = 0.0
var _state_duration: float = 0.0
var _state_elapsed: float = 0.0
var _neutral_starts_next: bool = false
var _scheduled_spawn_count: int = 0
var _pattern_serial: int = 0
var _locked_direction: int = -1
var _locked_target: Vector2 = Vector2.ZERO
var _jump_start: Vector2 = Vector2.ZERO
var _damage_enabled: bool = false
var _damaged_targets: Dictionary = {}
var _damage_zones: Array[SlimeKingDamageZoneRuntime] = []
var _zone_motion: Array[Dictionary] = []
var _warning_nodes: Array[Node2D] = []
var _spawn_marker_positions := PackedVector2Array()
var _safe_floor_fraction: float = 1.0
var _adds: Array[EnemyBase] = []
var _shutdown: bool = false


func configure(
	p_actor: Node2D,
	ground_rect: Rect2,
	platform_rects: Array[Rect2],
	spawn_candidates: PackedVector2Array
) -> void:
	_actor = p_actor
	_ground_rect = ground_rect
	_platform_rects = platform_rects.duplicate()
	_spawn_candidates = spawn_candidates.duplicate()
	_shutdown = false
	prepare_for_schedule()


func begin_schedule(schedule: BossPatternSchedule) -> bool:
	if _shutdown or _actor == null or schedule == null or schedule.patterns.is_empty():
		return false
	cancel_execution(false, STATE_IDLE)
	_schedule = schedule
	_pattern_index = 0
	_start_pattern(
		_schedule.patterns[_pattern_index],
		_schedule.spawned_add_count_for(_pattern_index)
	)
	return true


func advance_time(delta: float) -> void:
	if _shutdown or not is_finite(delta) or delta <= 0.0:
		return
	_prune_adds()
	var remaining := delta
	var transition_guard := 0
	# Timeline boundaries consume exact authored durations even when one step crosses states.
	while remaining > 0.000001 and transition_guard < 16:
		transition_guard += 1
		if _state in [STATE_IDLE, STATE_CANCELLED]:
			return
		var consumed := minf(remaining, _state_time_remaining)
		_update_continuous_state(consumed)
		_state_elapsed += consumed
		_state_time_remaining = maxf(_state_time_remaining - consumed, 0.0)
		remaining -= consumed
		if _state_time_remaining > 0.000001:
			return
		_transition_at_boundary()


func prepare_for_schedule() -> void:
	if _shutdown:
		return
	_state = STATE_IDLE
	_state_time_remaining = 0.0
	_state_duration = 0.0
	_state_elapsed = 0.0
	_damage_enabled = false
	_damaged_targets.clear()


func cancel_execution(
	clear_adds: bool = false,
	terminal_state: StringName = STATE_CANCELLED
) -> void:
	_damage_enabled = false
	_damaged_targets.clear()
	_clear_damage_zones()
	_clear_warning_nodes(true)
	_reset_actor_pose()
	_schedule = null
	_current_pattern = null
	_pattern_index = -1
	_scheduled_spawn_count = 0
	_state = terminal_state
	_state_time_remaining = 0.0
	_state_duration = 0.0
	_state_elapsed = 0.0
	_safe_floor_fraction = 1.0
	if clear_adds:
		clear_adds_immediately()
	state_changed.emit(&"", _state, snapshot())


func shutdown() -> void:
	if _shutdown:
		return
	cancel_execution(true)
	_shutdown = true


func clear_adds_immediately() -> void:
	# Runtime-owned adds lose contact before they leave the tree.
	for slime in _adds:
		if not is_instance_valid(slime):
			continue
		var contact := slime.get_node_or_null("ContactHitbox") as Hitbox
		if contact != null:
			contact.set_active(false)
		var hurtbox := slime.get_node_or_null("Hurtbox") as Hurtbox
		if hurtbox != null:
			hurtbox.set_deferred("monitorable", false)
		slime.set_physics_process(false)
		slime.visible = false
		slime.queue_free()
	_adds.clear()
	add_count_changed.emit(0)


func try_damage_contact(area: Area2D, zone_id: StringName) -> bool:
	if (
		not _damage_enabled
		or _state != STATE_ACTIVE
		or _current_pattern == null
		or not get_active_zone_ids().has(zone_id)
		or area == null
		or not area.has_method("receive_damage")
	):
		return false
	var receiver: Node = area
	if area is Hurtbox and (area as Hurtbox).receiver != null:
		receiver = (area as Hurtbox).receiver
	var target_id := receiver.get_instance_id()
	if _damaged_targets.has(target_id):
		return false
	_damaged_targets[target_id] = true
	var damage_info := DamageInfo.new(
		SlimeKing.CONTACT_DAMAGE,
		_actor,
		_damage_knockback(),
		_damage_tags(),
		_current_pattern.id
	)
	area.receive_damage(damage_info)
	damage_committed.emit(_current_pattern.id, receiver, damage_info)
	return true


func get_active_add_count() -> int:
	_prune_adds()
	return _adds.size()


func get_active_adds() -> Array[EnemyBase]:
	_prune_adds()
	return _adds.duplicate()


func get_active_zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for zone in _damage_zones:
		if is_instance_valid(zone) and zone.is_zone_active():
			ids.append(zone.zone_id)
	return ids


func is_idle() -> bool:
	return _state in [STATE_IDLE, STATE_CANCELLED]


func snapshot() -> Dictionary:
	var queued_ids: Array[StringName] = []
	var schedule_ids: Array[StringName] = []
	if _schedule != null:
		schedule_ids = _schedule.pattern_ids()
		for index in range(_pattern_index + 1, _schedule.patterns.size()):
			queued_ids.append(_schedule.patterns[index].id)
	return {
		"pattern_id": _current_pattern.id if _current_pattern != null else &"",
		"state": _state,
		"state_time_remaining": _state_time_remaining,
		"state_duration": _state_duration,
		"state_elapsed": _state_elapsed,
		"pattern_index": _pattern_index,
		"pattern_serial": _pattern_serial,
		"schedule_pattern_ids": schedule_ids,
		"queued_pattern_ids": queued_ids,
		"schedule_is_chain": _schedule != null and _schedule.is_chain(),
		"damage_enabled": _damage_enabled,
		"damaged_target_count": _damaged_targets.size(),
		"active_zone_ids": get_active_zone_ids(),
		"active_zone_count": get_active_zone_ids().size(),
		"warning_count": _warning_nodes.size(),
		"spawn_marker_count": _spawn_marker_positions.size(),
		"spawn_marker_positions": _spawn_marker_positions.duplicate(),
		"scheduled_spawn_count": _scheduled_spawn_count,
		"active_add_count": get_active_add_count(),
		"safe_floor_fraction": _safe_floor_fraction,
		"safe_floor_or_platform_fraction": _safe_floor_or_platform_fraction(),
		"locked_direction": _locked_direction,
		"locked_target": _locked_target,
		"shutdown": _shutdown,
	}


func _start_pattern(pattern: BossPatternDefinition, spawn_count: int) -> void:
	_current_pattern = pattern
	_scheduled_spawn_count = maxi(spawn_count, 0)
	_pattern_serial += 1
	_damage_enabled = false
	_damaged_targets.clear()
	_safe_floor_fraction = 1.0
	_setup_startup_presentation()
	_set_state(STATE_STARTUP, pattern.startup_time)
	pattern_started.emit(pattern.id, snapshot())


func _transition_at_boundary() -> void:
	match _state:
		STATE_STARTUP:
			_enter_active()
			if _current_pattern != null and is_zero_approx(_current_pattern.active_time):
				_enter_recovery()
		STATE_ACTIVE:
			_enter_recovery()
		STATE_RECOVERY:
			_complete_current_pattern()
		STATE_NEUTRAL:
			if _neutral_starts_next:
				_start_next_pattern()
			else:
				_finish_schedule()


func _enter_active() -> void:
	_clear_warning_nodes(false)
	_damaged_targets.clear()
	_setup_active_presentation()
	_damage_enabled = not is_zero_approx(_current_pattern.active_time)
	_set_state(STATE_ACTIVE, _current_pattern.active_time)


func _enter_recovery() -> void:
	_damage_enabled = false
	_clear_damage_zones()
	_reset_actor_to_floor()
	if _current_pattern.id == &"small_slime_summon":
		_spawn_small_slimes(_scheduled_spawn_count)
	_set_actor_pose(&"recovery", 0.0, _locked_direction)
	_set_state(STATE_RECOVERY, _current_pattern.recovery_time)


func _complete_current_pattern() -> void:
	var completed_id := _current_pattern.id
	_clear_warning_nodes(true)
	_reset_actor_pose()
	pattern_finished.emit(completed_id, snapshot())
	_current_pattern = null
	if _schedule != null and _pattern_index + 1 < _schedule.patterns.size():
		if _schedule.neutral_between_patterns > 0.0:
			_neutral_starts_next = true
			_set_state(STATE_NEUTRAL, _schedule.neutral_between_patterns)
		else:
			_start_next_pattern()
		return
	if _schedule != null and _schedule.neutral_after > 0.0:
		_neutral_starts_next = false
		_set_state(STATE_NEUTRAL, _schedule.neutral_after)
		return
	_finish_schedule()


func _start_next_pattern() -> void:
	if _schedule == null or _pattern_index + 1 >= _schedule.patterns.size():
		_finish_schedule()
		return
	_pattern_index += 1
	_start_pattern(
		_schedule.patterns[_pattern_index],
		_schedule.spawned_add_count_for(_pattern_index)
	)


func _finish_schedule() -> void:
	_schedule = null
	_pattern_index = -1
	_scheduled_spawn_count = 0
	_state = STATE_IDLE
	_state_time_remaining = 0.0
	_state_duration = 0.0
	_state_elapsed = 0.0
	state_changed.emit(&"", _state, snapshot())
	schedule_finished.emit(snapshot())


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_duration = maxf(duration, 0.0)
	_state_time_remaining = _state_duration
	_state_elapsed = 0.0
	state_changed.emit(
		_current_pattern.id if _current_pattern != null else &"",
		_state,
		snapshot()
	)


func _setup_startup_presentation() -> void:
	match _current_pattern.id:
		&"jump_slam":
			_jump_start = _actor.global_position
			var target := _target_actor()
			var target_x := target.global_position.x if target != null else _actor.global_position.x
			_locked_target = Vector2(
				clampf(target_x, _ground_rect.position.x + 70.0, _ground_rect.end.x - 70.0),
				_ground_rect.end.y
			)
			_create_warning_rect(
				"LandingShadow",
				Rect2(_locked_target.x - 68.0, _ground_rect.position.y - 8.0, 136.0, 18.0),
				WARNING_FILL,
				WARNING_OUTLINE,
				true
			)
		&"body_bump":
			var target := _target_actor()
			_locked_direction = (
				int(sign(target.global_position.x - _actor.global_position.x))
				if target != null and not is_zero_approx(target.global_position.x - _actor.global_position.x)
				else -1
			)
			var lane_left := _actor.global_position.x if _locked_direction > 0 else _ground_rect.position.x
			var lane_right := _ground_rect.end.x if _locked_direction > 0 else _actor.global_position.x
			_create_warning_rect(
				"BodyBumpLane",
				Rect2(lane_left, _ground_rect.end.y - 94.0, lane_right - lane_left, 94.0),
				WARNING_FILL,
				WARNING_OUTLINE,
				true
			)
			_set_actor_pose(&"body_bump_startup", 0.0, _locked_direction)
		&"poison_bands":
			_safe_floor_fraction = 0.5
			var band_width := _ground_rect.size.x / float(POISON_BAND_COUNT)
			for band_index in range(0, POISON_BAND_COUNT, 2):
				_create_warning_rect(
					"PoisonWarning%d" % band_index,
					Rect2(
						_ground_rect.position.x + band_width * float(band_index),
						_ground_rect.position.y,
						band_width,
						_ground_rect.size.y
					),
					Color(0.72, 0.24, 0.74, 0.18),
					POISON_OUTLINE,
					true
				)
		&"small_slime_summon":
			_spawn_marker_positions = _choose_spawn_markers()
			for marker_index in _spawn_marker_positions.size():
				var marker_position := _spawn_marker_positions[marker_index]
				_create_warning_rect(
					"SummonMarker%d" % marker_index,
					Rect2(marker_position - Vector2(34.0, 18.0), Vector2(68.0, 18.0)),
					WARNING_FILL,
					SAFE_OUTLINE,
					true
				)


func _setup_active_presentation() -> void:
	match _current_pattern.id:
		&"jump_slam":
			_actor.global_position = _locked_target
			var landing := _create_damage_zone(
				&"jump_landing",
				Vector2(136.0, 90.0),
				_actor.global_position + Vector2(0.0, -45.0),
				ACTIVE_FILL,
				ACTIVE_OUTLINE
			)
			landing.set_meta("role", "landing")
			_create_traveling_shockwave(&"shockwave_left", -1)
			_create_traveling_shockwave(&"shockwave_right", 1)
			_set_actor_pose(&"jump_slam_active", 1.0, _locked_direction)
		&"body_bump":
			_create_damage_zone(
				&"body_bump_contact",
				Vector2(116.0, 94.0),
				_actor.global_position + Vector2(0.0, -47.0),
				ACTIVE_FILL,
				ACTIVE_OUTLINE
			)
			_set_actor_pose(&"body_bump_active", 0.0, _locked_direction)
		&"poison_bands":
			var band_width := _ground_rect.size.x / float(POISON_BAND_COUNT)
			for band_index in range(0, POISON_BAND_COUNT, 2):
				_create_damage_zone(
					StringName("poison_band_%d" % band_index),
					Vector2(band_width, _ground_rect.size.y),
					Vector2(
						_ground_rect.position.x + band_width * (float(band_index) + 0.5),
						_ground_rect.get_center().y
					),
					POISON_FILL,
					POISON_OUTLINE
				)
		&"small_slime_summon":
			pass


func _update_continuous_state(delta: float) -> void:
	if delta <= 0.0 or _current_pattern == null:
		return
	var next_elapsed := _state_elapsed + delta
	var progress := clampf(next_elapsed / maxf(_state_duration, 0.0001), 0.0, 1.0)
	match _current_pattern.id:
		&"jump_slam":
			if _state == STATE_STARTUP:
				_actor.global_position = _jump_start.lerp(_locked_target, progress)
				_actor.global_position.y -= sin(progress * PI) * JUMP_HEIGHT
				_set_actor_pose(&"jump_slam_startup", progress, _locked_direction)
			elif _state == STATE_ACTIVE:
				_update_traveling_zones(progress)
		&"body_bump":
			if _state == STATE_STARTUP:
				_set_actor_pose(&"body_bump_startup", progress, _locked_direction)
			elif _state == STATE_ACTIVE:
				_actor.global_position.x = clampf(
					_actor.global_position.x + float(_locked_direction) * BODY_BUMP_SPEED * delta,
					_ground_rect.position.x + 58.0,
					_ground_rect.end.x - 58.0
				)
				if not _damage_zones.is_empty():
					_damage_zones[0].global_position = _actor.global_position + Vector2(0.0, -47.0)
				_set_actor_pose(&"body_bump_active", progress, _locked_direction)
		&"poison_bands":
			if _state == STATE_ACTIVE:
				for zone in _damage_zones:
					if is_instance_valid(zone):
						zone.modulate.a = 0.82 + sin(progress * TAU * 4.0) * 0.18
		&"small_slime_summon":
			if _state == STATE_STARTUP:
				for warning in _warning_nodes:
					if is_instance_valid(warning):
						var pulse := 1.0 + sin(progress * PI * 4.0) * 0.08
						warning.scale = Vector2.ONE * pulse


func _create_traveling_shockwave(zone_id: StringName, direction: int) -> void:
	var start := _actor.global_position + Vector2(float(direction) * 76.0, -15.0)
	var finish := Vector2(
		_ground_rect.end.x - 60.0 if direction > 0 else _ground_rect.position.x + 60.0,
		_ground_rect.end.y - 15.0
	)
	var zone := _create_damage_zone(
		zone_id,
		Vector2(120.0, 30.0),
		start,
		Color(1.0, 0.48, 0.18, 0.72),
		ACTIVE_OUTLINE
	)
	_zone_motion.append({"zone": zone, "start": start, "finish": finish})


func _update_traveling_zones(progress: float) -> void:
	for motion in _zone_motion:
		var zone := motion.get("zone") as SlimeKingDamageZoneRuntime
		if is_instance_valid(zone):
			zone.global_position = (motion["start"] as Vector2).lerp(
				motion["finish"] as Vector2,
				progress
			)


func _create_damage_zone(
	zone_id: StringName,
	size: Vector2,
	world_position: Vector2,
	fill_color: Color,
	outline_color: Color
) -> SlimeKingDamageZoneRuntime:
	var zone := DAMAGE_ZONE_RUNTIME.new() as SlimeKingDamageZoneRuntime
	zone.name = String(zone_id).to_pascal_case()
	add_child(zone)
	zone.top_level = true
	zone.global_position = world_position
	zone.configure(zone_id, size, fill_color, outline_color)
	zone.contact_requested.connect(_on_zone_contact_requested)
	zone.set_zone_active(true)
	_damage_zones.append(zone)
	return zone


func _create_warning_rect(
	node_name: String,
	world_rect: Rect2,
	fill_color: Color,
	outline_color: Color,
	add_cross: bool
) -> Node2D:
	var warning := Node2D.new()
	warning.name = node_name
	add_child(warning)
	warning.top_level = true
	warning.global_position = world_rect.get_center()
	var half := world_rect.size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var fill := Polygon2D.new()
	fill.color = fill_color
	fill.polygon = corners
	warning.add_child(fill)
	var outline := Line2D.new()
	outline.width = 4.0
	outline.default_color = outline_color
	outline.points = PackedVector2Array([
		corners[0], corners[1], corners[2], corners[3], corners[0],
	])
	warning.add_child(outline)
	if add_cross:
		var cross := Line2D.new()
		cross.width = 3.0
		cross.default_color = outline_color
		cross.points = PackedVector2Array([
			corners[0], corners[2], corners[1], corners[3],
		])
		warning.add_child(cross)
	_warning_nodes.append(warning)
	return warning


func _clear_damage_zones() -> void:
	for zone in _damage_zones:
		if is_instance_valid(zone):
			zone.set_zone_active(false)
			zone.queue_free()
	_damage_zones.clear()
	_zone_motion.clear()


func _clear_warning_nodes(clear_marker_positions: bool) -> void:
	for warning in _warning_nodes:
		if is_instance_valid(warning):
			warning.queue_free()
	_warning_nodes.clear()
	if clear_marker_positions:
		_spawn_marker_positions.clear()


func _choose_spawn_markers() -> PackedVector2Array:
	var player := _target_actor()
	var player_position := (
		player.global_position
		if player != null
		else Vector2(_ground_rect.get_center().x, _ground_rect.end.y)
	)
	var ranked: Array[Dictionary] = []
	for candidate in _spawn_candidates:
		ranked.append({
			"position": candidate,
			"distance": candidate.distance_to(player_position),
		})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if not is_equal_approx(float(left["distance"]), float(right["distance"])):
			return float(left["distance"]) > float(right["distance"])
		return (left["position"] as Vector2).x < (right["position"] as Vector2).x
	)
	var selected := PackedVector2Array()
	for entry in ranked:
		var position := entry["position"] as Vector2
		if position.distance_to(player_position) + 0.001 < SPAWN_PLAYER_CLEARANCE:
			continue
		var separated := true
		for existing in selected:
			if existing.distance_to(position) < SPAWN_MARKER_SEPARATION:
				separated = false
				break
		if separated:
			selected.append(position)
		if selected.size() == 2:
			break
	return selected


func _spawn_small_slimes(requested_count: int) -> void:
	_prune_adds()
	var spawn_count := mini(maxi(requested_count, 0), 2 - _adds.size())
	spawn_count = mini(spawn_count, _spawn_marker_positions.size())
	for index in spawn_count:
		var slime := SMALL_SLIME_SCENE.instantiate() as SmallSlimeEnemy
		if slime == null:
			continue
		add_child(slime)
		slime.top_level = true
		var spawn_position := _spawn_marker_positions[index]
		slime.global_position = spawn_position
		slime.spawn_position = spawn_position
		slime.left_limit = spawn_position.x - slime.patrol_half_width
		slime.right_limit = spawn_position.x + slime.patrol_half_width
		slime.encounter_bounds = Rect2(
			_ground_rect.position.x,
			_ground_rect.end.y - 360.0,
			_ground_rect.size.x,
			380.0
		)
		slime.begin_spawn(0.0)
		slime.defeated.connect(func(_defeated: EnemyBase) -> void:
			_on_add_defeated(slime)
		)
		_adds.append(slime)
	add_count_changed.emit(_adds.size())


func _on_add_defeated(slime: EnemyBase) -> void:
	_adds.erase(slime)
	if is_instance_valid(slime):
		slime.queue_free()
	add_count_changed.emit(_adds.size())


func _prune_adds() -> void:
	var previous_count := _adds.size()
	for index in range(_adds.size() - 1, -1, -1):
		var slime := _adds[index]
		if not is_instance_valid(slime) or slime.current_health <= 0:
			_adds.remove_at(index)
	if _adds.size() != previous_count:
		add_count_changed.emit(_adds.size())


func _on_zone_contact_requested(
	area: Area2D,
	zone: SlimeKingDamageZoneRuntime
) -> void:
	try_damage_contact(area, zone.zone_id)


func _damage_knockback() -> Vector2:
	match _current_pattern.id:
		&"body_bump":
			return Vector2(float(_locked_direction) * 270.0, -120.0)
		&"jump_slam":
			var target := _target_actor()
			var direction := 1
			if target != null and target.global_position.x < _actor.global_position.x:
				direction = -1
			return Vector2(float(direction) * 190.0, -180.0)
		&"poison_bands":
			return Vector2(0.0, -90.0)
	return Vector2.ZERO


func _damage_tags() -> Array[String]:
	var tags: Array[String] = ["enemy_attack", "boss_pattern"]
	match _current_pattern.id:
		&"body_bump":
			tags.append("enemy_contact")
		&"jump_slam":
			tags.append("ground_shockwave")
		&"poison_bands":
			tags.append("hazard")
			tags.append("poison")
	return tags


func _safe_floor_or_platform_fraction() -> float:
	if _safe_floor_fraction >= 1.0:
		return 1.0
	var safe_width := _ground_rect.size.x * _safe_floor_fraction
	var total_width := _ground_rect.size.x
	for platform_rect in _platform_rects:
		safe_width += platform_rect.size.x
		total_width += platform_rect.size.x
	return safe_width / total_width if total_width > 0.0 else 0.0


func _target_actor() -> Node2D:
	if _actor != null and _actor.has_method("get_target_actor"):
		return _actor.call("get_target_actor") as Node2D
	return null


func _set_actor_pose(pose: StringName, progress: float, direction: int) -> void:
	if _actor != null and _actor.has_method("set_pattern_pose"):
		_actor.call("set_pattern_pose", pose, progress, direction)


func _reset_actor_pose() -> void:
	_reset_actor_to_floor()
	if _actor != null and _actor.has_method("reset_pattern_pose"):
		_actor.call("reset_pattern_pose")


func _reset_actor_to_floor() -> void:
	if _actor == null or not _ground_rect.has_area():
		return
	_actor.global_position.y = _ground_rect.end.y
