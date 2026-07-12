class_name SwitchGate
extends Node2D

signal opened(gate: SwitchGate)
signal closed(gate: SwitchGate)

@export var gate_size: Vector2 = Vector2(58.0, 116.0)
@export var switch_offset: Vector2 = Vector2(-112.0, 0.0)
@export var opens_once: bool = true
@export var open_delay: float = 0.18

var is_open: bool = false

var _gate_body: StaticBody2D
var _gate_shape: CollisionShape2D
var _gate_visual: Polygon2D
var _switch: SwitchInteractable
var _busy: bool = false


func _ready() -> void:
	_ensure_gate()
	_ensure_switch()


func open_gate() -> void:
	if is_open or _busy:
		return
	_busy = true
	await get_tree().create_timer(open_delay).timeout
	is_open = true
	_busy = false
	_apply_gate_state()
	opened.emit(self)
	_publish_status("%s opened" % name)


func close_gate() -> void:
	if not is_open or _busy:
		return
	is_open = false
	_apply_gate_state()
	closed.emit(self)
	_publish_status("%s closed" % name)


func reset_gate() -> void:
	is_open = false
	_busy = false
	_apply_gate_state()


func _on_switch_interacted(_player: Node) -> void:
	if is_open and not opens_once:
		close_gate()
	else:
		open_gate()


func _ensure_gate() -> void:
	_gate_body = get_node_or_null("GateBody") as StaticBody2D
	if _gate_body == null:
		_gate_body = StaticBody2D.new()
		_gate_body.name = "GateBody"
		_gate_body.collision_layer = 1
		_gate_body.collision_mask = 0
		add_child(_gate_body)

	_gate_shape = _gate_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _gate_shape == null:
		_gate_shape = CollisionShape2D.new()
		_gate_shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = gate_size
		_gate_shape.position = Vector2(0.0, -gate_size.y * 0.5)
		_gate_shape.shape = rect
		_gate_body.add_child(_gate_shape)

	_gate_visual = get_node_or_null("Visual") as Polygon2D
	if _gate_visual == null:
		_gate_visual = Polygon2D.new()
		_gate_visual.name = "Visual"
		var half_x := gate_size.x * 0.5
		_gate_visual.polygon = PackedVector2Array([
			Vector2(-half_x, -gate_size.y),
			Vector2(half_x, -gate_size.y),
			Vector2(half_x, 0.0),
			Vector2(-half_x, 0.0),
		])
		add_child(_gate_visual)
	_apply_gate_state()


func _ensure_switch() -> void:
	_switch = get_node_or_null("Switch") as SwitchInteractable
	if _switch == null:
		_switch = SwitchInteractable.new()
		_switch.name = "Switch"
		_switch.prompt_text = "Activate switch"
		_switch.body_size = Vector2(44.0, 58.0)
		_switch.position = switch_offset
		add_child(_switch)
	_switch.interacted.connect(_on_switch_interacted)


func _apply_gate_state() -> void:
	if _gate_body != null:
		_gate_body.collision_layer = 0 if is_open else 1
	if _gate_shape != null:
		_gate_shape.set_deferred("disabled", is_open)
	if _gate_visual != null:
		if is_open:
			_gate_visual.color = Color(0.28, 0.55, 0.40, 0.35)
			_gate_visual.scale.y = 0.16
		else:
			_gate_visual.color = Color(0.32, 0.48, 0.72, 0.95)
			_gate_visual.scale.y = 1.0
	if _switch != null:
		_switch.set_active(is_open)


func _publish_status(message: String) -> void:
	var signal_bus := get_node_or_null("/root/SignalBus")
	if signal_bus != null:
		signal_bus.status_message_changed.emit(message)
