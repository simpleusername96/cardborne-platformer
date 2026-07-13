class_name FieldPickup
extends Area2D

@export var pickup_id: StringName
@export var definition: FieldPickupDefinition
@export_range(0.0, 12.0, 0.5) var idle_bob_height: float = 4.0
@export_range(0.1, 4.0, 0.1) var idle_bob_speed: float = 2.2

var _collecting: bool = false
var _idle_time: float = 0.0
var _visual_origin: Vector2
@onready var _visual_root: Node2D = $VisualRoot
@onready var _core: Polygon2D = $VisualRoot/Core
@onready var _halo: Polygon2D = $VisualRoot/Halo


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	_visual_origin = _visual_root.position
	_apply_presentation()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collecting:
		return
	_idle_time += delta * idle_bob_speed
	_visual_root.position = _visual_origin + Vector2(0.0, sin(_idle_time) * idle_bob_height)


func try_collect(player: Node) -> Dictionary:
	if _collecting:
		return {"ok": false, "message": "Pickup is already resolving."}
	if pickup_id == &"" or definition == null or not definition.validate_definition().is_empty():
		return {"ok": false, "message": "Pickup is unavailable."}
	var run_state := get_node_or_null("/root/RunState")
	if run_state == null or not run_state.has_method("apply_field_pickup"):
		return {"ok": false, "message": "Pickup target is unavailable."}
	_collecting = true
	var result: Dictionary = run_state.call("apply_field_pickup", pickup_id, definition, player)
	if bool(result.get("applied", false)) or bool(result.get("duplicate", false)):
		_finish_collection(result)
	else:
		_collecting = false
	return result


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		try_collect(body)


func _finish_collection(result: Dictionary) -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if bool(result.get("applied", false)):
		var signal_bus := get_node_or_null("/root/SignalBus")
		if signal_bus != null:
			signal_bus.emit_signal("field_pickup_collected", result.duplicate(true))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual_root, "position:y", _visual_root.position.y - 18.0, 0.16)
	tween.tween_property(_visual_root, "modulate:a", 0.0, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _apply_presentation() -> void:
	if definition == null:
		visible = false
		return
	visible = true
	_core.color = definition.visual_color
	_halo.color = Color(definition.visual_color, 0.22)
	_core.polygon = _shape_for_effect(definition.effect_type, 13.0)
	_halo.polygon = _shape_for_effect(definition.effect_type, 19.0)


func _shape_for_effect(effect_type: StringName, radius: float) -> PackedVector2Array:
	match effect_type:
		FieldPickupDefinition.EFFECT_HEAL:
			return PackedVector2Array([
				Vector2(0.0, -radius), Vector2(radius * 0.72, 0.0),
				Vector2(0.0, radius), Vector2(-radius * 0.72, 0.0),
			])
		FieldPickupDefinition.EFFECT_REFILL_CONSUMABLE:
			return _regular_polygon(6, radius)
		FieldPickupDefinition.EFFECT_REDUCE_SKILL_COOLDOWNS:
			return PackedVector2Array([
				Vector2(0.0, -radius), Vector2(radius * 0.34, -radius * 0.34),
				Vector2(radius, 0.0), Vector2(radius * 0.34, radius * 0.34),
				Vector2(0.0, radius), Vector2(-radius * 0.34, radius * 0.34),
				Vector2(-radius, 0.0), Vector2(-radius * 0.34, -radius * 0.34),
			])
		_:
			return _regular_polygon(8, radius)


func _regular_polygon(sides: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		var angle := -PI * 0.5 + TAU * float(index) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
