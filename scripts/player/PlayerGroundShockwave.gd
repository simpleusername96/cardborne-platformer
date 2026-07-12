class_name PlayerGroundShockwave
extends Hitbox

var direction: int = 1
var max_distance: float = 220.0
var travel_duration: float = 0.35
var ground_probe_depth: float = 30.0
var max_targets: int = 4
var wave_size: Vector2 = Vector2(42.0, 18.0)
var wave_color: Color = Color(1.0, 0.68, 0.16, 0.82)
var travelled_distance: float = 0.0

var _targets_hit: int = 0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 8
	starts_active = true
	repeat_hits = false
	_ensure_shape_and_visual()
	target_hit.connect(_on_target_hit)
	super._ready()
	call_deferred("_validate_initial_support")


func _physics_process(delta: float) -> void:
	if not active or max_distance <= 0.0:
		return
	var speed := max_distance / maxf(travel_duration, 0.01)
	var step := minf(speed * delta, max_distance - travelled_distance)
	var next_position := global_position + Vector2(float(direction) * step, 0.0)
	if _wall_between(global_position, next_position) or not _has_support(next_position):
		queue_free()
		return
	global_position = next_position
	travelled_distance += step
	if travelled_distance + 0.001 >= max_distance:
		queue_free()


func _ensure_shape_and_visual() -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = wave_size
	collision.shape = rectangle
	add_child(collision)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = wave_color
	visual.scale.x = float(direction)
	var half := wave_size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, half.y),
		Vector2(-half.x * 0.65, -half.y * 0.3),
		Vector2(-half.x * 0.2, -half.y),
		Vector2(half.x * 0.18, -half.y * 0.35),
		Vector2(half.x * 0.58, -half.y * 0.9),
		Vector2(half.x, half.y),
	])
	add_child(visual)


func _validate_initial_support() -> void:
	if is_inside_tree() and not _has_support(global_position):
		queue_free()


func _has_support(position: Vector2) -> bool:
	if not is_inside_tree():
		return false
	var query := PhysicsRayQueryParameters2D.create(
		position + Vector2(0.0, -4.0),
		position + Vector2(0.0, ground_probe_depth),
		3
	)
	query.hit_from_inside = true
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _wall_between(from: Vector2, to: Vector2) -> bool:
	if not is_inside_tree() or from.is_equal_approx(to):
		return false
	var offset := Vector2(0.0, -wave_size.y * 0.55)
	var query := PhysicsRayQueryParameters2D.create(from + offset, to + offset, 1)
	query.hit_from_inside = true
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _on_target_hit(_area: Area2D, _damage_info: DamageInfo) -> void:
	_targets_hit += 1
	if _targets_hit >= max_targets:
		queue_free()
