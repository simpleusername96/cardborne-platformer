class_name SummonNodeEnemy
extends EnemyBase

@export var activation_range: float = 520.0
@export var deactivation_range: float = 680.0
@export var spawn_interval: float = 2.6
@export var spawn_warning_time: float = 0.45
@export var max_active_children: int = 2
@export var max_total_spawned: int = 6
@export var spawn_min_distance_from_player: float = 150.0
@export var spawn_offsets: Array[Vector2] = [Vector2(-92.0, 0.0), Vector2(92.0, 0.0)]

var _state: String = "idle"
var _state_timer: float = 1.0
var _spawned_total: int = 0
var _children: Array[SmallSlimeEnemy] = []


func _ready() -> void:
	max_health = 4
	super._ready()
	_base_visual_color = Color(0.42, 0.86, 0.62, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_purge_children()
	if hit_stun_timer > 0.0:
		super._physics_process(delta)
		return

	_state_timer -= delta
	match _state:
		"idle":
			if _can_attempt_spawn() and _state_timer <= 0.0:
				_set_state("warning", spawn_warning_time)
		"warning":
			if not _player_in_range(deactivation_range):
				_set_state("idle", spawn_interval)
			elif _state_timer <= 0.0:
				_spawn_child_if_allowed()
				_set_state("idle", spawn_interval)

	velocity.x = 0.0
	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	_clear_children()
	_spawned_total = 0
	super.reset_enemy()
	_set_state("idle", spawn_interval)


func _defeat() -> void:
	_clear_children()
	super._defeat()


func _can_attempt_spawn() -> bool:
	return _player_in_range(activation_range) and _children.size() < max_active_children and _spawned_total < max_total_spawned


func _player_in_range(range_px: float) -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	return target != null and target.global_position.distance_to(global_position) <= range_px


func _spawn_child_if_allowed() -> void:
	if not _can_attempt_spawn():
		return

	var target := get_tree().get_first_node_in_group("player") as Node2D
	for offset in spawn_offsets:
		var spawn_position := global_position + offset
		if target != null and target.global_position.distance_to(spawn_position) < spawn_min_distance_from_player:
			continue
		var slime := SmallSlimeEnemy.new()
		slime.name = "%sChild%d" % [name, _spawned_total + 1]
		slime.auto_reset_on_defeat = false
		get_parent().add_child(slime)
		slime.global_position = spawn_position
		_children.append(slime)
		_spawned_total += 1
		SignalBus.status_message_changed.emit("%s spawned %d / %d" % [name, _spawned_total, max_total_spawned])
		return


func _purge_children() -> void:
	var live_children: Array[SmallSlimeEnemy] = []
	for child in _children:
		if child != null and is_instance_valid(child) and not child.is_queued_for_deletion() and child.current_health > 0:
			live_children.append(child)
	_children = live_children


func _clear_children() -> void:
	for child in _children:
		if child != null and is_instance_valid(child):
			child.queue_free()
	_children.clear()


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	if _state == "warning":
		_visual.color = Color(0.92, 1.0, 0.32, 1.0)
	else:
		_visual.color = _base_visual_color
