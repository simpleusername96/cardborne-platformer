class_name ShooterEnemy
extends EnemyBase

@export var shoot_interval: float = 1.8
@export var warning_time: float = 0.38
@export var projectile_speed: float = 280.0
@export var projectile_lifetime: float = 2.6

var direction: int = -1
var _state: String = "idle"
var _state_timer: float = 1.0


func _ready() -> void:
	super._ready()
	_base_visual_color = Color(0.42, 0.68, 0.94, 1.0)
	if _visual != null:
		_visual.color = _base_visual_color


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	if hit_stun_timer > 0.0:
		super._physics_process(delta)
		return

	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	_state_timer -= delta
	match _state:
		"idle":
			_face_player()
			if _state_timer <= 0.0:
				_set_state("warning", warning_time)
		"warning":
			if _state_timer <= 0.0:
				_spawn_projectile()
				_set_state("idle", shoot_interval)

	super._physics_process(delta)
	_update_visual()


func reset_enemy() -> void:
	super.reset_enemy()
	_set_state("idle", shoot_interval)


func _face_player() -> void:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return
	var offset := target.global_position.x - global_position.x
	if not is_zero_approx(offset):
		direction = int(sign(offset))


func _spawn_projectile() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var shot := EnemyProjectile.new()
	shot.name = "%sProjectile" % name
	shot.damage_amount = contact_damage
	shot.knockback = Vector2(float(direction) * 220.0, -120.0)
	shot.lifetime = projectile_lifetime
	shot.velocity = Vector2(float(direction) * projectile_speed, 0.0)
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(float(direction) * 28.0, -28.0)
	if shot.get_node_or_null("Visual") != null:
		var visual := shot.get_node("Visual") as Polygon2D
		visual.scale.x = float(direction)


func _set_state(next_state: String, duration: float) -> void:
	_state = next_state
	_state_timer = duration
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale.x = float(direction)
	if _state == "warning":
		_visual.color = Color(0.98, 0.88, 0.30, 1.0)
	else:
		_visual.color = _base_visual_color
