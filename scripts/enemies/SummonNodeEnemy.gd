class_name SummonNodeEnemy
extends EnemyBase

const STATE_IDLE := &"idle"
const STATE_WARNING := &"warning"
const TARGET_RETRY_TIME := 0.12

@export var activation_range: float = 520.0
@export var deactivation_range: float = 680.0
@export var initial_spawn_delay: float = 0.6
@export var spawn_interval: float = 2.6
@export var spawn_warning_time: float = 0.45
@export var child_startup_time: float = 0.35
@export var max_active_children: int = 2
@export var max_total_spawned: int = 6
@export var spawn_min_distance_from_player: float = 150.0
@export_flags_2d_physics var support_collision_mask: int = 3
@export var small_slime_scene: PackedScene
@export var body_color: Color = Color(0.42, 0.76, 0.58, 1.0)
@export var warning_color: Color = Color(0.92, 1.0, 0.32, 1.0)

var _state: StringName = STATE_IDLE
var _state_timer: float = 0.6
var _spawned_total: int = 0
var _owned_children: Array[SmallSlimeEnemy] = []
var _spawn_markers: Array[Marker2D] = []
var _next_marker_index: int = 0
var _pending_marker: Marker2D
var _pending_spawn_position: Vector2 = Vector2.ZERO
var _spawn_warning: Line2D


func _ready() -> void:
	max_health = 8
	super._ready()
	_base_visual_color = body_color
	if _visual != null:
		_visual.color = _base_visual_color
	_spawn_markers = _collect_spawn_markers()
	_spawn_warning = _ensure_spawn_warning()
	_set_state(STATE_IDLE, initial_spawn_delay)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_purge_freed_children()
	if hit_stun_timer > 0.0 or is_staggered():
		super._physics_process(delta)
		_update_visual()
		return

	_state_timer -= delta
	match _state:
		STATE_IDLE:
			if _state_timer <= 0.0:
				if _can_attempt_spawn() and _start_spawn_warning():
					_set_state(STATE_WARNING, spawn_warning_time)
				else:
					_state_timer = TARGET_RETRY_TIME
		STATE_WARNING:
			if not _pending_spawn_is_safe():
				_clear_pending_spawn()
				_set_state(STATE_IDLE, spawn_interval)
			elif _state_timer <= 0.0:
				_spawn_pending_child()
				_set_state(STATE_IDLE, spawn_interval)

	velocity.x = 0.0
	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	_clear_children()
	_spawned_total = 0
	_next_marker_index = 0
	_clear_pending_spawn()
	super.reset_enemy()
	_set_state(STATE_IDLE, initial_spawn_delay)


func _defeat() -> void:
	_clear_children()
	_clear_pending_spawn()
	super._defeat()


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["warning"] = _state == STATE_WARNING
	snapshot["state_time_remaining"] = _state_timer
	snapshot["spawned_total"] = _spawned_total
	snapshot["active_children"] = _active_child_count()
	snapshot["owned_children"] = _owned_children.size()
	snapshot["pending_spawn_position"] = _pending_spawn_position
	return snapshot


func _can_attempt_spawn() -> bool:
	return (
		_player_in_range(activation_range)
		and _active_child_count() < max_active_children
		and _spawned_total < max_total_spawned
		and not _spawn_markers.is_empty()
	)


func _player_in_range(range_px: float) -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	return (
		target != null
		and is_target_within_encounter(target)
		and target.global_position.distance_to(global_position) <= range_px
	)


func _start_spawn_warning() -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return false
	for offset_index in _spawn_markers.size():
		var marker_index := (_next_marker_index + offset_index) % _spawn_markers.size()
		var marker := _spawn_markers[marker_index]
		var support := _resolve_supported_position(marker)
		if not bool(support.get("ok", false)):
			continue
		var candidate := support.get("position", Vector2.ZERO) as Vector2
		if not _spawn_position_is_clear(candidate, target):
			continue
		_pending_marker = marker
		_pending_spawn_position = candidate
		_next_marker_index = (marker_index + 1) % _spawn_markers.size()
		_update_spawn_warning_geometry()
		return true
	return false


func _pending_spawn_is_safe() -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null or not _player_in_range(deactivation_range) or _pending_marker == null:
		return false
	var support := _resolve_supported_position(_pending_marker)
	if not bool(support.get("ok", false)):
		return false
	_pending_spawn_position = support.get("position", Vector2.ZERO) as Vector2
	_update_spawn_warning_geometry()
	return _spawn_position_is_clear(_pending_spawn_position, target)


func _resolve_supported_position(marker: Marker2D) -> Dictionary:
	if marker == null or not is_instance_valid(marker):
		return {"ok": false}
	var query := PhysicsRayQueryParameters2D.new()
	query.from = marker.global_position + Vector2(0.0, -48.0)
	query.to = marker.global_position + Vector2(0.0, 64.0)
	query.collision_mask = support_collision_mask
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"ok": false}
	var normal := hit.get("normal", Vector2.DOWN) as Vector2
	if normal.y > -0.7:
		return {"ok": false}
	return {"ok": true, "position": hit.get("position", marker.global_position)}


func _spawn_position_is_clear(candidate: Vector2, target: Node2D) -> bool:
	if target.global_position.distance_to(candidate) < spawn_min_distance_from_player:
		return false
	for child in _owned_children:
		if _is_active_child(child) and child.global_position.distance_to(candidate) < 48.0:
			return false
	return true


func _spawn_pending_child() -> void:
	if not _pending_spawn_is_safe() or _active_child_count() >= max_active_children:
		_clear_pending_spawn()
		return
	var parent_node := get_parent()
	if parent_node == null:
		_clear_pending_spawn()
		return
	var slime: SmallSlimeEnemy
	if small_slime_scene != null:
		slime = small_slime_scene.instantiate() as SmallSlimeEnemy
	if slime == null:
		slime = SmallSlimeEnemy.new()
	slime.name = "%sChild%d" % [name, _spawned_total + 1]
	slime.auto_reset_on_defeat = false
	slime.spawn_startup_time = child_startup_time
	slime.position = parent_node.to_local(_pending_spawn_position)
	parent_node.add_child(slime)
	_owned_children.append(slime)
	slime.tree_exiting.connect(_on_child_tree_exiting.bind(slime), CONNECT_ONE_SHOT)
	_spawned_total += 1
	SignalBus.status_message_changed.emit(
		"%s spawned %d / %d" % [name, _spawned_total, max_total_spawned]
	)
	_clear_pending_spawn()


func _active_child_count() -> int:
	var count := 0
	for child in _owned_children:
		if _is_active_child(child):
			count += 1
	return count


func _is_active_child(child: SmallSlimeEnemy) -> bool:
	return (
		child != null
		and is_instance_valid(child)
		and not child.is_queued_for_deletion()
		and child.current_health > 0
		and child.visible
	)


func _purge_freed_children() -> void:
	var retained: Array[SmallSlimeEnemy] = []
	for child in _owned_children:
		if child != null and is_instance_valid(child) and not child.is_queued_for_deletion():
			retained.append(child)
	_owned_children = retained


func _on_child_tree_exiting(child: SmallSlimeEnemy) -> void:
	_owned_children.erase(child)


func _clear_children() -> void:
	for child in _owned_children:
		if child != null and is_instance_valid(child):
			child.queue_free()
	_owned_children.clear()


func _collect_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	var container := get_node_or_null("SpawnMarkers")
	if container == null:
		return markers
	for child in container.get_children():
		if child is Marker2D:
			markers.append(child as Marker2D)
	return markers


func _clear_pending_spawn() -> void:
	_pending_marker = null
	_pending_spawn_position = Vector2.ZERO
	if _spawn_warning != null:
		_spawn_warning.visible = false


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0)
	_update_visual()


func _refresh_visual_color() -> void:
	_update_visual()


func _update_visual() -> void:
	if _visual != null:
		if is_staggered():
			_visual.color = Color(0.36, 0.88, 0.92, 1.0)
		elif _state == STATE_WARNING:
			_visual.color = warning_color
		else:
			_visual.color = _base_visual_color
	if _spawn_warning != null:
		_spawn_warning.visible = current_health > 0 and _state == STATE_WARNING


func _update_spawn_warning_geometry() -> void:
	if _spawn_warning == null:
		return
	_spawn_warning.position = to_local(_pending_spawn_position) + Vector2(0.0, -3.0)


func _ensure_spawn_warning() -> Line2D:
	var line := get_node_or_null("SpawnWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "SpawnWarning"
		line.width = 6.0
		line.default_color = warning_color
		line.points = PackedVector2Array([
			Vector2(-30.0, 0.0),
			Vector2(0.0, -16.0),
			Vector2(30.0, 0.0),
			Vector2(0.0, 10.0),
			Vector2(-30.0, 0.0),
		])
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line


# Summon Nodes are stationary encounter owners, not contact-damage actors.
func _ensure_contact_hitbox() -> void:
	pass
