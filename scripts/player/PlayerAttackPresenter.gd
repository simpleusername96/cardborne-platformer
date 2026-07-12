class_name PlayerAttackPresenter
extends Node

@export var visual_path: NodePath = NodePath("../AttackMotionVisual")

@onready var visual: Polygon2D = get_node(visual_path) as Polygon2D

var _origin: Vector2 = Vector2.ZERO


func begin(definition: AttackDefinition, direction: int, origin: Vector2) -> void:
	_origin = Vector2(absf(origin.x), origin.y)
	visual.position = _directional_origin(direction)
	visual.rotation = 0.0
	visual.scale = Vector2(float(direction), 1.0)
	visual.color = definition.visual_color
	visual.modulate.a = 0.46
	visual.z_index = 20
	match definition.motion_style:
		&"shield_rush":
			_configure_shield(definition.hitbox_size)
		&"heavy_swing":
			_configure_heavy(definition.hitbox_size)
		&"arrow_projectile":
			_configure_bow(definition.hitbox_size)
		_:
			_configure_slash(definition.hitbox_size)
	visual.visible = true


func update(
	definition: AttackDefinition,
	phase_name: StringName,
	phase_timer: float,
	phase_duration: float,
	direction: int
) -> void:
	if definition == null or visual == null:
		return
	visual.scale.x = float(direction)
	visual.position = _directional_origin(direction)
	var progress := clampf(1.0 - phase_timer / maxf(phase_duration, 0.01), 0.0, 1.0)
	match phase_name:
		&"startup":
			visual.modulate.a = lerpf(0.42, 0.88, progress)
			visual.rotation = (
				lerpf(-0.32, -0.74, progress)
				if definition.motion_style == &"heavy_swing"
				else 0.0
			)
		&"active":
			visual.modulate.a = 1.0
			if definition.motion_style == &"heavy_swing":
				visual.rotation = lerpf(-0.74, 0.96, progress)
			elif definition.motion_style == &"shield_rush":
				visual.position += Vector2(8.0 * float(direction), 0.0)
			else:
				visual.rotation = lerpf(-0.38, 0.34, progress)
		&"recovery":
			visual.modulate.a = lerpf(0.72, 0.0, progress)


func reset() -> void:
	if visual == null:
		return
	visual.visible = false
	visual.position = Vector2.ZERO
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	visual.modulate = Color.WHITE


func _directional_origin(direction: int) -> Vector2:
	return Vector2(_origin.x * float(direction), _origin.y)


func _configure_heavy(size: Vector2) -> void:
	var length := maxf(size.x * 1.05, 58.0)
	var width := maxf(size.y * 0.24, 14.0)
	visual.polygon = PackedVector2Array([
		Vector2(-8.0, -width), Vector2(length * 0.72, -width), Vector2(length, 0.0),
		Vector2(length * 0.72, width), Vector2(-8.0, width), Vector2(-14.0, 0.0),
	])


func _configure_slash(size: Vector2) -> void:
	var length := maxf(size.x, 48.0)
	var width := maxf(size.y * 0.20, 10.0)
	visual.polygon = PackedVector2Array([
		Vector2(-8.0, -width), Vector2(length, -width * 0.45), Vector2(length + 8.0, 0.0),
		Vector2(length, width * 0.45), Vector2(-8.0, width),
	])


func _configure_shield(size: Vector2) -> void:
	var width := maxf(size.x * 0.48, 26.0)
	var height := maxf(size.y * 0.72, 34.0)
	visual.polygon = PackedVector2Array([
		Vector2(-width * 0.4, -height * 0.5), Vector2(width * 0.5, -height * 0.42),
		Vector2(width * 0.72, 0.0), Vector2(width * 0.5, height * 0.42),
		Vector2(-width * 0.4, height * 0.5),
	])


func _configure_bow(size: Vector2) -> void:
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x * 0.2, -half.y * 0.72),
		Vector2(half.x, 0.0), Vector2(half.x * 0.2, half.y * 0.72),
		Vector2(-half.x, half.y), Vector2(-half.x * 0.24, 0.0),
	])
