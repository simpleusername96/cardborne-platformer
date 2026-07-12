class_name SmallSlimeEnemy
extends EnemyBase

@export var patrol_half_width: float = 70.0
@export var move_speed: float = 52.0
@export var lifetime: float = 12.0
@export var spawn_startup_time: float = 0.35
@export var body_color: Color = Color(0.46, 0.90, 0.48, 1.0)
@export var warning_color: Color = Color(0.92, 1.0, 0.32, 1.0)

var direction: int = -1
var left_limit: float
var right_limit: float
var _life_timer: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_active: bool = false
var _spawn_warning: Line2D


func _ready() -> void:
	max_health = 2
	contact_damage = 1
	super._ready()
	left_limit = spawn_position.x - patrol_half_width
	right_limit = spawn_position.x + patrol_half_width
	_life_timer = lifetime
	_base_visual_color = body_color
	_spawn_warning = _ensure_spawn_warning()
	begin_spawn(spawn_startup_time)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	if not _spawn_active:
		_spawn_timer = maxf(_spawn_timer - delta, 0.0)
		velocity.x = 0.0
		if _spawn_timer <= 0.0:
			_spawn_active = true
			_set_spawn_combat_enabled(true)
	elif hit_stun_timer <= 0.0 and not is_staggered():
		velocity.x = float(direction) * move_speed * get_external_speed_scale()

	super._physics_process(delta)
	if global_position.x <= left_limit:
		direction = 1
	elif global_position.x >= right_limit:
		direction = -1
	_update_visual()


func begin_spawn(duration: float = -1.0) -> void:
	_spawn_timer = maxf(spawn_startup_time if duration < 0.0 else duration, 0.0)
	_spawn_active = _spawn_timer <= 0.0
	_set_spawn_combat_enabled(_spawn_active)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	direction = -1
	_life_timer = lifetime
	begin_spawn(spawn_startup_time)


func get_combat_snapshot() -> Dictionary:
	var snapshot := super.get_combat_snapshot()
	snapshot["spawn_warning"] = not _spawn_active
	snapshot["spawn_active"] = _spawn_active
	snapshot["spawn_time_remaining"] = _spawn_timer
	return snapshot


func _set_spawn_combat_enabled(enabled: bool) -> void:
	var hurtbox := get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.collision_layer = 8 if enabled else 0
		hurtbox.collision_mask = 16 if enabled else 0
		hurtbox.set_deferred("monitorable", enabled)
		hurtbox.set_deferred("monitoring", enabled)
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", not enabled)
	var contact := get_node_or_null("ContactHitbox") as Hitbox
	if contact != null:
		contact.collision_layer = 32 if enabled else 0
		contact.collision_mask = 4 if enabled else 0
		contact.set_active(enabled)


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
		_visual.color = body_color
		_visual.polygon = PackedVector2Array([
			Vector2(-16.0, -24.0),
			Vector2(16.0, -24.0),
			Vector2(20.0, -8.0),
			Vector2(10.0, 0.0),
			Vector2(-10.0, 0.0),
			Vector2(-20.0, -8.0),
		])
		add_child(_visual)


func _refresh_visual_color() -> void:
	_update_visual()


func _update_visual() -> void:
	if _visual != null:
		_visual.scale.x = float(direction)
		if is_staggered():
			_visual.color = Color(0.36, 0.88, 0.92, 1.0)
		else:
			_visual.color = _base_visual_color if _spawn_active else warning_color
	if _spawn_warning != null:
		_spawn_warning.visible = current_health > 0 and not _spawn_active


func _ensure_spawn_warning() -> Line2D:
	var line := get_node_or_null("SpawnWarning") as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "SpawnWarning"
		line.position = Vector2(0.0, -4.0)
		line.width = 5.0
		line.default_color = warning_color
		line.points = PackedVector2Array([
			Vector2(-24.0, 0.0),
			Vector2(0.0, -14.0),
			Vector2(24.0, 0.0),
			Vector2(0.0, 8.0),
			Vector2(-24.0, 0.0),
		])
		line.z_index = -1
		add_child(line)
	line.visible = false
	return line
