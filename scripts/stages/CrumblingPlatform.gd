class_name CrumblingPlatform
extends StaticBody2D

@export var platform_size: Vector2 = Vector2(220.0, 28.0)
@export var shake_time: float = 0.45
@export var disabled_time: float = 1.8
@export var respawn_time: float = 0.25
@export var platform_color: Color = Color(0.58, 0.50, 0.38, 1.0)

var _state: String = "stable"
var _state_timer: float = 0.0
var _shape: CollisionShape2D
var _visual: Polygon2D
var _sensor: Area2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_ensure_shape_visual_and_sensor()


func _process(delta: float) -> void:
	if _state == "stable":
		return

	_state_timer -= delta
	if _state == "shake":
		_update_shake_visual()
		if _state_timer <= 0.0:
			_set_disabled()
	elif _state == "disabled":
		if _state_timer <= 0.0:
			_set_respawning()
	elif _state == "respawning":
		_update_respawn_visual()
		if _state_timer <= 0.0:
			_set_stable()


func _on_sensor_body_entered(body: Node) -> void:
	if _state != "stable" or not body.is_in_group("player"):
		return
	_state = "shake"
	_state_timer = shake_time
	SignalBus.status_message_changed.emit("%s crumbling" % name)


func _ensure_shape_visual_and_sensor() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = platform_size
		_shape.shape = rect
		add_child(_shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = platform_color
		var half := platform_size * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		add_child(_visual)

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
		var sensor_rect := RectangleShape2D.new()
		sensor_rect.size = Vector2(platform_size.x, 18.0)
		sensor_shape.position = Vector2(0.0, -platform_size.y * 0.5 - 8.0)
		sensor_shape.shape = sensor_rect
		_sensor.add_child(sensor_shape)


func _set_disabled() -> void:
	_state = "disabled"
	_state_timer = disabled_time
	collision_layer = 0
	if _shape != null:
		_shape.set_deferred("disabled", true)
	if _visual != null:
		_visual.visible = false


func _set_respawning() -> void:
	_state = "respawning"
	_state_timer = respawn_time
	if _visual != null:
		_visual.visible = true
		_visual.modulate.a = 0.35


func _set_stable() -> void:
	_state = "stable"
	_state_timer = 0.0
	collision_layer = 1
	if _shape != null:
		_shape.set_deferred("disabled", false)
	if _visual != null:
		_visual.position = Vector2.ZERO
		_visual.modulate = Color.WHITE
		_visual.color = platform_color


func _update_shake_visual() -> void:
	if _visual == null:
		return
	var wobble := sin(Time.get_ticks_msec() * 0.08) * 2.0
	_visual.position.x = wobble
	_visual.color = Color(0.90, 0.70, 0.34, 1.0)


func _update_respawn_visual() -> void:
	if _visual == null:
		return
	var progress := 1.0 - (_state_timer / maxf(respawn_time, 0.01))
	_visual.modulate.a = lerpf(0.35, 1.0, progress)
