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
var _visual_root: Node2D
var _base_visual: Sprite2D
var _warning_overlay: Sprite2D
var _active_overlay: Sprite2D
var _cooldown_overlay: Sprite2D
var _fallback_visual: Polygon2D
var _raster_visual_ready := false


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


func get_visual_snapshot() -> Dictionary:
	return {
		"state": _state,
		"raster_visual_ready": _raster_visual_ready,
		"base_instance_id": _base_visual.get_instance_id() if _base_visual != null else 0,
		"base_texture_path": (
			_base_visual.texture.resource_path
			if _base_visual != null and _base_visual.texture != null
			else ""
		),
		"base_local_position": _base_visual.position if _base_visual != null else Vector2.ZERO,
		"visual_root_position": _visual_root.position if _visual_root != null else Vector2.ZERO,
		"base_visible": _base_visual.visible if _base_visual != null else false,
		"warning_overlay_visible": (
			_warning_overlay.visible if _warning_overlay != null else false
		),
		"active_overlay_visible": _active_overlay.visible if _active_overlay != null else false,
		"cooldown_overlay_visible": (
			_cooldown_overlay.visible if _cooldown_overlay != null else false
		),
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

	_visual_root = get_node_or_null("VisualRoot") as Node2D
	if _visual_root == null:
		_visual_root = Node2D.new()
		_visual_root.name = "VisualRoot"
		add_child(_visual_root)
	_base_visual = _visual_root.get_node_or_null("Base") as Sprite2D
	_warning_overlay = _visual_root.get_node_or_null("WarningOverlay") as Sprite2D
	_active_overlay = _visual_root.get_node_or_null("ActiveOverlay") as Sprite2D
	_cooldown_overlay = _visual_root.get_node_or_null("CooldownOverlay") as Sprite2D
	_raster_visual_ready = (
		_base_visual != null
		and _base_visual.texture != null
		and _warning_overlay != null
		and _active_overlay != null
		and _cooldown_overlay != null
	)

	_fallback_visual = get_node_or_null("Visual") as Polygon2D
	if _fallback_visual == null:
		_fallback_visual = Polygon2D.new()
		_fallback_visual.name = "Visual"
		add_child(_fallback_visual)
	var half := vent_size * 0.5
	_fallback_visual.polygon = PackedVector2Array([
		Vector2(-half.x, half.y),
		Vector2(-half.x * 0.72, -half.y * 0.3),
		Vector2(-half.x * 0.25, -half.y),
		Vector2(0.0, -half.y * 0.45),
		Vector2(half.x * 0.32, -half.y),
		Vector2(half.x * 0.78, -half.y * 0.2),
		Vector2(half.x, half.y),
	])
	_fallback_visual.visible = not _raster_visual_ready


func _update_visual() -> void:
	if _raster_visual_ready:
		_visual_root.position = Vector2.ZERO
		_base_visual.position = Vector2.ZERO
		_base_visual.visible = true
		_base_visual.modulate = Color.WHITE
		_warning_overlay.visible = _state == STATE_WARNING
		_active_overlay.visible = _state == STATE_ACTIVE
		_cooldown_overlay.visible = _state == STATE_COOLDOWN
		return
	if _fallback_visual == null:
		return
	if _state == STATE_WARNING:
		_fallback_visual.color = Color(0.98, 0.78, 0.22, 0.62)
	elif _state == STATE_ACTIVE:
		_fallback_visual.color = Color(0.42, 0.95, 0.36, 0.88)
	else:
		_fallback_visual.color = Color(0.22, 0.34, 0.24, 0.45)
