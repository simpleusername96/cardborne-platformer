class_name PlayerAttackPresenter
extends Node

const CONTACT_ALPHA := 0.18
const CONTACT_OUTLINE_ALPHA := 0.68

@export var visual_path: NodePath = NodePath("../AttackMotionVisual")
@export var contact_visual_path: NodePath = NodePath("../AttackContactVisual")
@export var contact_outline_path: NodePath = NodePath("../AttackContactOutline")

@onready var visual: Polygon2D = get_node(visual_path) as Polygon2D
@onready var _contact_visual: Polygon2D = get_node(contact_visual_path) as Polygon2D
@onready var _contact_outline: Line2D = get_node(contact_outline_path) as Line2D

var _origin := Vector2.ZERO
var _runtime_pulse_index: int = 0
var _current_style: StringName = &""


func begin(definition: AttackDefinition, direction: int, origin: Vector2) -> void:
	_origin = Vector2(absf(origin.x), origin.y)
	_runtime_pulse_index = 0
	_current_style = definition.motion_style
	visual.position = _directional_origin(direction)
	visual.rotation = 0.0
	visual.scale = Vector2(float(direction), 1.0)
	visual.color = definition.visual_color
	visual.modulate = Color(1.0, 1.0, 1.0, 0.46)
	visual.z_index = 20
	_configure_motion(definition.motion_style, definition.hitbox_size)
	_configure_contact(definition.hitbox_size, definition.visual_color)
	visual.visible = true
	_contact_visual.visible = false
	_contact_outline.visible = false


func update(
	definition: AttackDefinition,
	phase_name: StringName,
	phase_timer: float,
	phase_duration: float,
	direction: int
) -> void:
	if definition == null or visual == null:
		return
	visual.scale = Vector2(float(direction), 1.0)
	visual.position = _directional_origin(direction)
	_contact_visual.position = _directional_origin(direction)
	_contact_outline.position = _directional_origin(direction)
	var progress := clampf(1.0 - phase_timer / maxf(phase_duration, 0.01), 0.0, 1.0)
	_contact_visual.visible = phase_name == &"active" and _uses_local_contact(definition)
	_contact_outline.visible = _contact_visual.visible
	match phase_name:
		&"startup":
			visual.modulate.a = lerpf(0.38, 0.86, progress)
			visual.rotation = _startup_rotation(definition.motion_style, progress)
		&"active":
			visual.modulate.a = 1.0
			visual.rotation = _active_rotation(definition.motion_style, progress)
			if definition.motion_style == &"shield_rush":
				visual.position += Vector2(6.0 * float(direction), 0.0)
			elif definition.motion_style == &"ground_splitter":
				visual.position.y += lerpf(0.0, 8.0, progress)
			elif definition.motion_style == &"rally":
				visual.scale *= lerpf(1.0, 1.12, progress)
		&"recovery":
			visual.modulate.a = lerpf(0.68, 0.0, progress)
			visual.rotation = _recovery_rotation(definition.motion_style)


func show_runtime_pulse(hit_index: int) -> void:
	_runtime_pulse_index = maxi(hit_index, 1)
	if visual != null:
		visual.visible = true
		visual.modulate.a = 1.0


func get_visual_contract() -> Dictionary:
	return {
		"motion_style": _current_style,
		"motion_bounds": _polygon_bounds(visual.polygon) if visual != null else Rect2(),
		"transformed_motion_bounds": _transformed_motion_bounds(),
		"contact_bounds": (
			_polygon_bounds(_contact_visual.polygon)
			if _contact_visual != null
			else Rect2()
		),
		"contact_outline_bounds": (
			_polygon_bounds(_contact_outline.points)
			if _contact_outline != null
			else Rect2()
		),
		"origin": _origin,
		"motion_position": visual.position if visual != null else Vector2.ZERO,
		"contact_position": (
			_contact_visual.position if _contact_visual != null else Vector2.ZERO
		),
		"motion_signature": str(visual.polygon) if visual != null else "",
		"runtime_pulse_index": _runtime_pulse_index,
		"contact_visible": _contact_visual != null and _contact_visual.visible,
		"contact_outline_visible": _contact_outline != null and _contact_outline.visible,
	}


func reset() -> void:
	if visual != null:
		visual.visible = false
		visual.position = Vector2.ZERO
		visual.rotation = 0.0
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE
	if _contact_visual != null:
		_contact_visual.visible = false
		_contact_visual.position = Vector2.ZERO
	if _contact_outline != null:
		_contact_outline.visible = false
		_contact_outline.position = Vector2.ZERO
	_runtime_pulse_index = 0
	_current_style = &""


func _configure_motion(style: StringName, size: Vector2) -> void:
	match style:
		&"wide_slash":
			_configure_wide_slash(size)
		&"quick_slash":
			_configure_quick_slash(size)
		&"shadow_lunge":
			_configure_shadow_lunge(size)
		&"heavy_swing":
			_configure_heavy(size)
		&"arrow_projectile":
			_configure_bow(size)
		&"shield_rush":
			_configure_shield(size)
		&"ground_splitter":
			_configure_ground_splitter(size)
		&"rally":
			_configure_rally(size)
		_:
			_configure_quick_slash(size)


func _configure_contact(size: Vector2, color: Color) -> void:
	# Contact layers mirror hitbox data exactly; only the motion layer is stylized.
	var half := size * 0.5
	_contact_visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	_contact_visual.color = Color(color, CONTACT_ALPHA)
	_contact_outline.points = _contact_visual.polygon
	_contact_outline.default_color = Color(color, CONTACT_OUTLINE_ALPHA)


func _uses_local_contact(definition: AttackDefinition) -> bool:
	return (
		definition.base_damage > 0
		and definition.projectile_speed <= 0.0
		and not definition.tags.has(&"projectile")
		and definition.motion_style != &"ground_splitter"
	)


func _startup_rotation(style: StringName, progress: float) -> float:
	match style:
		&"heavy_swing":
			return lerpf(-0.72, -1.08, progress)
		&"wide_slash":
			return lerpf(-0.32, -0.48, progress)
		&"quick_slash":
			return lerpf(-0.46, -0.58, progress)
		&"ground_splitter":
			return lerpf(-0.28, 0.12, progress)
	return 0.0


func _active_rotation(style: StringName, progress: float) -> float:
	match style:
		&"heavy_swing":
			return lerpf(-1.08, 0.82, progress)
		&"wide_slash":
			return lerpf(-0.48, 0.44, progress)
		&"quick_slash":
			if _runtime_pulse_index >= 2:
				return lerpf(0.54, -0.42, clampf((progress - 0.70) / 0.30, 0.0, 1.0))
			return lerpf(-0.58, 0.34, minf(progress / 0.70, 1.0))
		&"shadow_lunge":
			return lerpf(-0.08, 0.08, progress)
	return 0.0


func _recovery_rotation(style: StringName) -> float:
	return 0.82 if style == &"heavy_swing" else 0.34 if style == &"wide_slash" else 0.0


func _directional_origin(direction: int) -> Vector2:
	return Vector2(_origin.x * float(direction), _origin.y)


func _configure_wide_slash(size: Vector2) -> void:
	var half := size * 0.5
	var reach := minf(half.x * 0.80, half.y * 1.05)
	visual.polygon = PackedVector2Array([
		Vector2(-reach, -half.y * 0.20),
		Vector2(-reach * 0.12, -half.y * 0.38),
		Vector2(reach, -half.y * 0.12),
		Vector2(reach, half.y * 0.12),
		Vector2(-reach * 0.12, half.y * 0.38),
		Vector2(-reach, half.y * 0.20),
	])


func _configure_quick_slash(size: Vector2) -> void:
	var half := size * 0.5
	var reach := minf(half.x * 0.78, half.y * 1.10)
	visual.polygon = PackedVector2Array([
		Vector2(-reach, -half.y * 0.16),
		Vector2(reach * 0.72, -half.y * 0.28),
		Vector2(reach, 0.0),
		Vector2(reach * 0.72, half.y * 0.28),
		Vector2(-reach, half.y * 0.16),
	])


func _configure_shadow_lunge(size: Vector2) -> void:
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y * 0.24),
		Vector2(half.x * 0.34, -half.y * 0.24),
		Vector2(half.x, 0.0),
		Vector2(half.x * 0.34, half.y * 0.24),
		Vector2(-half.x, half.y * 0.24),
		Vector2(-half.x * 0.72, 0.0),
	])


func _configure_heavy(size: Vector2) -> void:
	var half := size * 0.5
	var reach := minf(half.x, half.y) * 0.72
	visual.polygon = PackedVector2Array([
		Vector2(-reach * 0.26, -reach),
		Vector2(reach * 0.14, -reach),
		Vector2(reach, reach * 0.46),
		Vector2(reach * 0.72, reach),
		Vector2(reach * 0.34, reach * 0.54),
		Vector2(-reach * 0.46, -reach * 0.72),
	])


func _configure_shield(size: Vector2) -> void:
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x * 0.42, -half.y),
		Vector2(half.x * 0.48, -half.y * 0.82),
		Vector2(half.x, 0.0),
		Vector2(half.x * 0.48, half.y * 0.82),
		Vector2(-half.x * 0.42, half.y),
	])


func _configure_bow(size: Vector2) -> void:
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x * 0.16, -half.y * 0.70),
		Vector2(half.x, 0.0),
		Vector2(half.x * 0.16, half.y * 0.70),
		Vector2(-half.x, half.y),
		Vector2(-half.x * 0.28, 0.0),
	])


func _configure_ground_splitter(size: Vector2) -> void:
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x * 0.18, -half.y),
		Vector2(half.x * 0.18, -half.y),
		Vector2(half.x * 0.18, -half.y * 0.08),
		Vector2(half.x, -half.y * 0.08),
		Vector2(half.x, half.y * 0.28),
		Vector2(-half.x, half.y * 0.28),
		Vector2(-half.x, -half.y * 0.08),
		Vector2(-half.x * 0.18, -half.y * 0.08),
	])


func _configure_rally(size: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.5
	var points := PackedVector2Array()
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var point_scale := 1.0 if index % 2 == 0 else 0.72
		points.append(Vector2(cos(angle), sin(angle)) * radius * point_scale)
	visual.polygon = points


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for index in range(1, points.size()):
		bounds = bounds.expand(points[index])
	return bounds


func _transformed_motion_bounds() -> Rect2:
	if visual == null or visual.polygon.is_empty():
		return Rect2()
	var relative_origin := visual.position
	if _contact_visual != null:
		relative_origin -= _contact_visual.position
	var points := PackedVector2Array()
	for point in visual.polygon:
		var scaled := Vector2(point.x * visual.scale.x, point.y * visual.scale.y)
		points.append(scaled.rotated(visual.rotation) + relative_origin)
	return _polygon_bounds(points)
