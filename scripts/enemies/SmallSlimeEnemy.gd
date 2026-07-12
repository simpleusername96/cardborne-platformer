class_name SmallSlimeEnemy
extends EnemyBase

@export var patrol_half_width: float = 70.0
@export var move_speed: float = 52.0
@export var lifetime: float = 12.0

var direction: int = -1
var left_limit: float
var right_limit: float
var _life_timer: float = 0.0


func _ready() -> void:
	max_health = 2
	contact_damage = 1
	super._ready()
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_life_timer = lifetime
	_base_visual_color = Color(0.46, 0.90, 0.48, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	if hit_stun_timer <= 0.0:
		velocity.x = float(direction) * move_speed * get_external_speed_scale()
	super._physics_process(delta)

	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1

	if _visual != null:
		_visual.scale.x = float(direction)


func _ensure_body() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(28.0, 24.0)
		shape.position = Vector2(0.0, -12.0)
		shape.shape = rect
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.46, 0.90, 0.48, 1.0)
		_visual.polygon = PackedVector2Array([
			Vector2(-16.0, -24.0),
			Vector2(16.0, -24.0),
			Vector2(20.0, -8.0),
			Vector2(10.0, 0.0),
			Vector2(-10.0, 0.0),
			Vector2(-20.0, -8.0),
		])
		add_child(_visual)
