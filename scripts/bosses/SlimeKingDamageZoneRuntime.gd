class_name SlimeKingDamageZoneRuntime
extends Area2D

signal contact_requested(area: Area2D, zone: SlimeKingDamageZoneRuntime)

var zone_id: StringName
var _active: bool = false
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 32
	collision_mask = 4
	monitorable = false
	monitoring = false
	area_entered.connect(_on_area_entered)


func configure(
	p_zone_id: StringName,
	size: Vector2,
	fill_color: Color,
	outline_color: Color
) -> void:
	zone_id = p_zone_id
	_shape = CollisionShape2D.new()
	_shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	add_child(_shape)

	var half := size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var fill := Polygon2D.new()
	fill.name = "Fill"
	fill.color = fill_color
	fill.polygon = corners
	add_child(fill)

	var outline := Line2D.new()
	outline.name = "Outline"
	outline.width = 4.0
	outline.default_color = outline_color
	outline.points = PackedVector2Array([
		corners[0], corners[1], corners[2], corners[3], corners[0],
	])
	add_child(outline)
	set_zone_active(false)


func set_zone_active(enabled: bool) -> void:
	_active = enabled
	visible = enabled
	set_deferred("monitoring", enabled)
	if _shape != null:
		_shape.set_deferred("disabled", not enabled)
	if enabled:
		call_deferred("request_overlapping_contacts")


func is_zone_active() -> bool:
	return _active


func request_overlapping_contacts() -> void:
	if not _active:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)


func _on_area_entered(area: Area2D) -> void:
	if _active and area.has_method("receive_damage"):
		contact_requested.emit(area, self)
