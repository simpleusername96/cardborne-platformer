class_name MovingPlatform
extends AnimatableBody2D

signal cycle_state_changed(state: StringName)

const STATE_WAIT_START := &"wait_start"
const STATE_TRAVEL_TO_END := &"travel_to_end"
const STATE_WAIT_END := &"wait_end"
const STATE_TRAVEL_TO_START := &"travel_to_start"
const TIME_EPSILON := 0.000001

@export var path_id: StringName
@export var travel_offset: Vector2 = Vector2(240.0, 0.0)
@export var travel_time: float = 1.8
@export var start_wait_time: float = 0.45
@export var end_wait_time: float = 0.45
@export var platform_size: Vector2 = Vector2(180.0, 24.0)
@export var platform_color: Color = Color(0.36, 0.62, 0.68, 1.0)

var _authored_start_position: Vector2
var _has_authored_start: bool = false
var _state: StringName = STATE_WAIT_START
var _state_elapsed: float = 0.0
var _shape: CollisionShape2D
var _visual: Polygon2D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_authored_start_position = position
	_has_authored_start = true
	_ensure_shape_and_visual()
	reset_platform()


func _physics_process(delta: float) -> void:
	advance_time(delta)


func advance_time(delta: float) -> void:
	var remaining := maxf(delta, 0.0)
	var transitions := 0
	while remaining > TIME_EPSILON and transitions < 16:
		var duration := _state_duration()
		var available := maxf(duration - _state_elapsed, 0.0)
		var consumed := minf(remaining, available)
		_state_elapsed += consumed
		remaining -= consumed
		_apply_state_position(duration)
		if duration - _state_elapsed > TIME_EPSILON:
			break
		_transition_state()
		transitions += 1


func reset_platform() -> void:
	if not _has_authored_start:
		_authored_start_position = position
		_has_authored_start = true
	_state = STATE_WAIT_START
	_state_elapsed = 0.0
	position = _authored_start_position
	cycle_state_changed.emit(_state)


func get_authored_start_position() -> Vector2:
	return _authored_start_position if _has_authored_start else position


func get_authored_end_position() -> Vector2:
	return get_authored_start_position() + travel_offset


func get_runtime_snapshot() -> Dictionary:
	return {
		"path_id": String(path_id),
		"state": String(_state),
		"state_elapsed": _state_elapsed,
		"position": position,
		"start_position": get_authored_start_position(),
		"end_position": get_authored_end_position(),
	}


func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Moving platform path ID", path_id)
	if (
		not is_finite(travel_offset.x)
		or not is_finite(travel_offset.y)
		or travel_offset.length_squared() <= TIME_EPSILON
	):
		errors.append("Moving platform '%s' needs distinct finite endpoints." % path_id)
	for duration in [travel_time, start_wait_time, end_wait_time]:
		if not is_finite(duration) or duration <= 0.0:
			errors.append("Moving platform '%s' needs positive travel and wait times." % path_id)
			break
	if (
		not is_finite(platform_size.x)
		or not is_finite(platform_size.y)
		or platform_size.x <= 0.0
		or platform_size.y <= 0.0
	):
		errors.append("Moving platform '%s' needs a positive platform size." % path_id)
	return errors


func _state_duration() -> float:
	match _state:
		STATE_WAIT_START:
			return maxf(start_wait_time, TIME_EPSILON)
		STATE_WAIT_END:
			return maxf(end_wait_time, TIME_EPSILON)
		_:
			return maxf(travel_time, TIME_EPSILON)


func _apply_state_position(duration: float) -> void:
	match _state:
		STATE_WAIT_START:
			position = get_authored_start_position()
		STATE_WAIT_END:
			position = get_authored_end_position()
		STATE_TRAVEL_TO_END:
			position = get_authored_start_position().lerp(
				get_authored_end_position(), clampf(_state_elapsed / duration, 0.0, 1.0)
			)
		STATE_TRAVEL_TO_START:
			position = get_authored_end_position().lerp(
				get_authored_start_position(), clampf(_state_elapsed / duration, 0.0, 1.0)
			)


func _transition_state() -> void:
	match _state:
		STATE_WAIT_START:
			_state = STATE_TRAVEL_TO_END
		STATE_TRAVEL_TO_END:
			_state = STATE_WAIT_END
		STATE_WAIT_END:
			_state = STATE_TRAVEL_TO_START
		_:
			_state = STATE_WAIT_START
	_state_elapsed = 0.0
	_apply_state_position(_state_duration())
	cycle_state_changed.emit(_state)


func _ensure_shape_and_visual() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		add_child(_shape)
	var rectangle := _shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		_shape.shape = rectangle
	rectangle.size = platform_size

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		add_child(_visual)
	var half := platform_size * 0.5
	_visual.color = platform_color
	_visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
