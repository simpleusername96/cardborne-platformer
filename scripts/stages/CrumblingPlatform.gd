class_name CrumblingPlatform
extends StaticBody2D

signal state_changed(state: StringName)

const STATE_STABLE := &"stable"
const STATE_WARNING := &"warning"
const STATE_DISABLED := &"disabled"
const STATE_RESPAWNING := &"respawning"
const TIME_EPSILON := 0.000001

@export var platform_size: Vector2 = Vector2(220.0, 28.0)
@export var warning_time: float = 0.45
@export var disabled_time: float = 1.8
@export var respawn_time: float = 0.25
@export var platform_color: Color = Color(0.38, 0.56, 0.58, 1.0)

var _state: StringName = STATE_STABLE
var _state_timer: float = 0.0
var _state_elapsed: float = 0.0
var _shape: CollisionShape2D
var _visual: Polygon2D
var _sensor: Area2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_ensure_shape_visual_and_sensor()
	reset_platform()


func _physics_process(delta: float) -> void:
	advance_time(delta)


func advance_time(delta: float) -> void:
	if _state == STATE_STABLE:
		return
	var remaining := maxf(delta, 0.0)
	while remaining > 0.0 and _state != STATE_STABLE:
		var consumed := minf(remaining, _state_timer)
		_state_timer -= consumed
		_state_elapsed += consumed
		remaining -= consumed
		_update_state_visual()
		if _state_timer > TIME_EPSILON:
			break
		_state_timer = 0.0
		_advance_state()


func trigger_collapse() -> bool:
	if _state != STATE_STABLE:
		return false
	_set_state(STATE_WARNING, warning_time)
	return true


func reset_platform() -> void:
	_set_state(STATE_STABLE, 0.0)


func get_runtime_snapshot() -> Dictionary:
	return {
		"state": _state,
		"state_time_remaining": _state_timer,
		"collision_enabled": _shape != null and not _shape.disabled,
	}


func _on_sensor_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		trigger_collapse()


func _advance_state() -> void:
	match _state:
		STATE_WARNING:
			_set_state(STATE_DISABLED, disabled_time)
		STATE_DISABLED:
			_set_state(STATE_RESPAWNING, respawn_time)
		_:
			_set_state(STATE_STABLE, 0.0)


func _set_state(next_state: StringName, duration: float) -> void:
	_state = next_state
	_state_timer = maxf(duration, 0.0)
	_state_elapsed = 0.0
	var enabled := _state != STATE_DISABLED and _state != STATE_RESPAWNING
	collision_layer = 1 if enabled else 0
	if _shape != null:
		_shape.set_deferred("disabled", not enabled)
	_update_state_visual()
	state_changed.emit(_state)


func _update_state_visual() -> void:
	if _visual == null:
		return
	match _state:
		STATE_STABLE:
			_visual.visible = true
			_visual.position = Vector2.ZERO
			_visual.modulate = Color.WHITE
			_visual.color = platform_color
		STATE_WARNING:
			_visual.visible = true
			_visual.position.x = sin(_state_elapsed * 45.0) * 2.0
			_visual.color = Color(0.90, 0.70, 0.34, 1.0)
		STATE_DISABLED:
			_visual.visible = false
		STATE_RESPAWNING:
			_visual.visible = true
			_visual.position = Vector2.ZERO
			var progress := 1.0 - (_state_timer / maxf(respawn_time, 0.01))
			_visual.modulate.a = lerpf(0.35, 1.0, progress)


func _ensure_shape_visual_and_sensor() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		add_child(_shape)
	if _shape.shape == null:
		var rectangle := RectangleShape2D.new()
		rectangle.size = platform_size
		_shape.shape = rectangle

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		add_child(_visual)
	var half := platform_size * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])

	_sensor = get_node_or_null("Sensor") as Area2D
	if _sensor == null:
		_sensor = Area2D.new()
		_sensor.name = "Sensor"
		_sensor.collision_layer = 0
		_sensor.collision_mask = 4
		_sensor.monitoring = true
		_sensor.body_entered.connect(_on_sensor_body_entered)
		add_child(_sensor)
		var sensor_shape := CollisionShape2D.new()
		var sensor_rectangle := RectangleShape2D.new()
		sensor_rectangle.size = Vector2(platform_size.x, 18.0)
		sensor_shape.position = Vector2(0.0, -platform_size.y * 0.5 - 8.0)
		sensor_shape.shape = sensor_rectangle
		_sensor.add_child(sensor_shape)
