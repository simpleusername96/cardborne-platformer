class_name FeedbackHitBurst
extends Node2D

const DURATION_SECONDS := 0.13
const RAY_COUNT := 8

var _color := Color.WHITE
var _radius := 18.0
var _strength := 1.0
var _rotation_offset := 0.0
var _started_usec := 0


func configure(
	world_position: Vector2,
	color: Color,
	radius: float,
	strength: float,
	seed: int
) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	z_index = 100
	position = world_position
	_color = color
	_radius = clampf(radius, 4.0, 48.0)
	_strength = clampf(strength, 0.25, 2.0)
	_rotation_offset = deg_to_rad(float(abs(seed) % 360))
	_started_usec = Time.get_ticks_usec()
	queue_redraw()


func _process(_delta: float) -> void:
	if _started_usec == 0:
		return
	# Real time keeps the burst short even while gameplay time is slowed.
	if _age_seconds() >= DURATION_SECONDS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _started_usec == 0:
		return
	var progress := clampf(_age_seconds() / DURATION_SECONDS, 0.0, 1.0)
	var fade := pow(1.0 - progress, 1.35)
	var color := Color(_color.r, _color.g, _color.b, _color.a * fade)
	var inner_radius := lerpf(_radius * 0.12, _radius * 0.42, progress)
	var outer_radius := lerpf(_radius * 0.45, _radius * 1.25, progress)
	var width := maxf(1.0, 3.0 * _strength * fade)

	draw_circle(Vector2.ZERO, maxf(1.0, _radius * 0.18 * fade), color)
	for ray_index in RAY_COUNT:
		var angle := _rotation_offset + TAU * float(ray_index) / float(RAY_COUNT)
		var direction := Vector2.from_angle(angle)
		var ray_scale := 0.78 + 0.22 * float((ray_index * 5 + 3) % 7) / 6.0
		draw_line(
			direction * inner_radius,
			direction * outer_radius * ray_scale,
			color,
			width,
			true
		)
	draw_arc(
		Vector2.ZERO,
		lerpf(_radius * 0.18, _radius * 0.72, progress),
		0.0,
		TAU,
		24,
		Color(color.r, color.g, color.b, color.a * 0.55),
		maxf(1.0, width * 0.55),
		true
	)


func get_snapshot() -> Dictionary:
	return {
		"duration": DURATION_SECONDS,
		"ray_count": RAY_COUNT,
		"radius": _radius,
		"strength": _strength,
		"world_position": position,
		"age": _age_seconds(),
	}


func _age_seconds() -> float:
	return float(Time.get_ticks_usec() - _started_usec) / 1_000_000.0
