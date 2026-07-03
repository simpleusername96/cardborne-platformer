class_name TimedPoisonVent
extends Hitbox

@export var vent_size: Vector2 = Vector2(180.0, 24.0)
@export var warning_time: float = 0.70
@export var active_time: float = 1.20
@export var cooldown_time: float = 1.50
@export var tick_interval: float = 0.65

var _state: String = "warning"
var _state_timer: float = 0.0
var _tick_timer: float = 0.0
var _visual: Polygon2D


func _ready() -> void:
	collision_layer = 64
	collision_mask = 4
	damage_amount = 1
	knockback = Vector2(-180.0, -170.0)
	tags = ["poison_vent", "hazard"]
	starts_active = false
	repeat_hits = true
	_ensure_shape_and_visual()
	super._ready()
	_set_state("warning", warning_time)


func _process(delta: float) -> void:
	_state_timer -= delta
	if _state == "active":
		_tick_timer -= delta
		if _tick_timer <= 0.0:
			_damage_overlapping_targets()
			_tick_timer = tick_interval

	if _state_timer > 0.0:
		return

	if _state == "warning":
		_set_state("active", active_time)
	elif _state == "active":
		_set_state("cooldown", cooldown_time)
	else:
		_set_state("warning", warning_time)


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = vent_size
		shape.shape = rect
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		var half := vent_size * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		add_child(_visual)


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	if next_state == "active":
		_tick_timer = tick_interval
		set_active(true)
	elif active:
		set_active(false)
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	if _state == "warning":
		_visual.visible = true
		_visual.color = Color(0.98, 0.78, 0.22, 0.62)
	elif _state == "active":
		_visual.visible = true
		_visual.color = Color(0.42, 0.95, 0.36, 0.88)
	else:
		_visual.visible = true
		_visual.color = Color(0.22, 0.34, 0.24, 0.45)


func _damage_overlapping_targets() -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		if not area.has_method("receive_damage"):
			continue
		var damage_info := DamageInfo.new(damage_amount, self, knockback, tags)
		area.receive_damage(damage_info)
		target_hit.emit(area, damage_info)
