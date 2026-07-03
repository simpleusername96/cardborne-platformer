class_name PlayerAttackProjectile
extends Hitbox

@export var projectile_size: Vector2 = Vector2(34.0, 8.0)
@export var projectile_color: Color = Color(0.9, 0.95, 1.0, 0.95)
@export var lifetime: float = 0.65

var velocity: Vector2 = Vector2.ZERO
var direction: int = 1
var _life_timer: float = 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 8
	starts_active = true
	repeat_hits = false
	if tags.is_empty():
		tags = ["player_projectile", "player_attack"]
	_life_timer = lifetime
	_ensure_shape_and_visual()
	target_hit.connect(_on_target_hit)
	super._ready()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = projectile_size
		shape.shape = rect
		add_child(shape)

	if get_node_or_null("Visual") == null:
		var visual := Polygon2D.new()
		visual.name = "Visual"
		visual.color = projectile_color
		visual.scale.x = float(direction)
		var half := projectile_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x - 6.0, -half.y),
			Vector2(half.x + 8.0, 0.0),
			Vector2(half.x - 6.0, half.y),
			Vector2(-half.x, half.y),
			Vector2(-half.x - 7.0, 0.0),
		])
		add_child(visual)


func _on_target_hit(_area: Area2D, _damage_info: DamageInfo) -> void:
	queue_free()
