class_name TimedPoisonVent
extends Area2D

signal target_hit(area: Area2D, damage_info: DamageInfo)
signal state_changed(state: StringName)

const STATE_WARNING := &"warning"
const STATE_ACTIVE := &"active"
const STATE_COOLDOWN := &"cooldown"
const TIME_EPSILON := 0.000001

@export var vent_size: Vector2 = Vector2(180.0, 96.0)
@export var warning_time: float = 0.70
@export var active_time: float = 1.20
@export var cooldown_time: float = 1.50
@export var tick_interval: float = 0.65
@export var damage_amount: int = 1
@export var knockback: Vector2 = Vector2(-180.0, -170.0)

var _state: StringName = STATE_WARNING
var _state_timer: float = 0.0
var _tick_timer: float = 0.0
var _visual: Polygon2D


func _ready() -> void:
	collision_layer = 64
	collision_mask = 4
	monitoring = true
	monitorable = false
	_ensure_shape_and_visual()
	reset_hazard()


func _physics_process(delta: float) -> void:
	advance_time(delta)


func advance_time(delta: float) -> void:
	var remaining := maxf(delta, 0.0)
	while remaining > 0.0:
		var consumed := minf(remaining, _state_timer)
		if _state == STATE_ACTIVE:
			_advance_damage_ticks(consumed)
		_state_timer -= consumed
		remaining -= consumed
		if _state_timer > TIME_EPSILON:
			break
		_state_timer = 0.0
		_advance_state()


func reset_hazard() -> void:
	_set_state(STATE_WARNING, warning_time)


func get_runtime_snapshot() -> Dictionary:
	return {
		"state": _state,
		"state_time_remaining": _state_timer,
		"damage_active": _state == STATE_ACTIVE,
		"tick_time_remaining": _tick_timer,
	}


func _advance_state() -> void:
	match _state:
		STATE_WARNING:
			_set_state(STATE_ACTIVE, active_time)
		STATE_ACTIVE:
			_set_state(STATE_COOLDOWN, cooldown_time)
		_:
			_set_state(STATE_WARNING, warning_time)


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0001)
	_tick_timer = _effective_tick_interval() if _state == STATE_ACTIVE else 0.0
	_update_visual()
	state_changed.emit(_state)
	if _state == STATE_ACTIVE:
		_damage_overlapping_targets()


func _advance_damage_ticks(delta: float) -> void:
	_tick_timer -= delta
	while _tick_timer <= TIME_EPSILON:
		_damage_overlapping_targets()
		_tick_timer += _effective_tick_interval()


func _effective_tick_interval() -> float:
	return maxf(tick_interval, TIME_EPSILON)


func _damage_overlapping_targets() -> void:
	if _state != STATE_ACTIVE:
		return
	for area in get_overlapping_areas():
		if not area.has_method("receive_damage"):
			continue
		var damage_info := DamageInfo.new(
			damage_amount,
			self,
			knockback,
			["poison_vent", "hazard"]
		)
		area.receive_damage(damage_info)
		target_hit.emit(area, damage_info)


func _ensure_shape_and_visual() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
	if collision.shape == null:
		var rectangle := RectangleShape2D.new()
		rectangle.size = vent_size
		collision.shape = rectangle

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		add_child(_visual)
	var half := vent_size * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-half.x, half.y),
		Vector2(-half.x * 0.72, -half.y * 0.3),
		Vector2(-half.x * 0.25, -half.y),
		Vector2(0.0, -half.y * 0.45),
		Vector2(half.x * 0.32, -half.y),
		Vector2(half.x * 0.78, -half.y * 0.2),
		Vector2(half.x, half.y),
	])


func _update_visual() -> void:
	if _visual == null:
		return
	if _state == STATE_WARNING:
		_visual.color = Color(0.98, 0.78, 0.22, 0.62)
	elif _state == STATE_ACTIVE:
		_visual.color = Color(0.42, 0.95, 0.36, 0.88)
	else:
		_visual.color = Color(0.22, 0.34, 0.24, 0.45)
