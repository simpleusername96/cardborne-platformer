class_name EnemyBase
extends CharacterBody2D

signal defeated(enemy: EnemyBase)
signal damaged(enemy: EnemyBase, damage_info: DamageInfo)

@export var max_health: int = 3
@export var contact_damage: int = 1
@export var contact_knockback: Vector2 = Vector2(220.0, -160.0)
@export var gravity: float = 1200.0
@export var hit_stun_time: float = 0.16
@export var hit_knockback_multiplier: float = 0.72
@export var auto_reset_on_defeat: bool = true
@export var defeat_reset_delay: float = 2.0

var current_health: int = 0
var spawn_position: Vector2
var hit_stun_timer: float = 0.0

var _visual: Polygon2D
var _base_visual_color: Color = Color(0.84, 0.34, 0.28, 1.0)


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1
	spawn_position = global_position
	current_health = max_health
	_ensure_body()
	_ensure_hurtbox()
	_ensure_contact_hitbox()
	if _visual != null:
		_base_visual_color = _visual.color


func receive_damage(damage_info: DamageInfo) -> void:
	if current_health <= 0:
		return

	current_health = maxi(current_health - damage_info.amount, 0)
	damaged.emit(self, damage_info)
	hit_stun_timer = hit_stun_time
	velocity.x = damage_info.knockback.x * hit_knockback_multiplier
	velocity.y = minf(velocity.y, damage_info.knockback.y * 0.55)
	SignalBus.status_message_changed.emit("%s HP %d / %d" % [name, current_health, max_health])
	_flash()
	if current_health <= 0:
		_defeat()


func _physics_process(delta: float) -> void:
	hit_stun_timer = maxf(hit_stun_timer - delta, 0.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 700.0)
	move_and_slide()


func _defeat() -> void:
	defeated.emit(self)
	SignalBus.status_message_changed.emit("%s defeated" % name)
	set_physics_process(false)
	_set_combat_enabled(false)
	visible = false
	if auto_reset_on_defeat:
		_reset_after_delay()


func _ensure_body() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(34.0, 44.0)
		shape.position = Vector2(0.0, -22.0)
		shape.shape = rect
		add_child(shape)

	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.84, 0.34, 0.28, 1.0)
		_visual.polygon = PackedVector2Array([
			Vector2(-18.0, -44.0),
			Vector2(18.0, -44.0),
			Vector2(18.0, 0.0),
			Vector2(-18.0, 0.0),
		])
		add_child(_visual)


func _ensure_hurtbox() -> void:
	if get_node_or_null("Hurtbox") != null:
		return

	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(0.0, -22.0)
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 16
	hurtbox.receiver_path = NodePath("..")
	add_child(hurtbox)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(38.0, 48.0)
	shape.shape = rect
	hurtbox.add_child(shape)


func _ensure_contact_hitbox() -> void:
	if get_node_or_null("ContactHitbox") != null:
		return

	var hitbox := Hitbox.new()
	hitbox.name = "ContactHitbox"
	hitbox.position = Vector2(0.0, -22.0)
	hitbox.collision_layer = 32
	hitbox.collision_mask = 4
	hitbox.damage_amount = contact_damage
	hitbox.knockback = contact_knockback
	hitbox.tags = ["enemy_contact"]
	hitbox.starts_active = true
	hitbox.repeat_hits = true
	add_child(hitbox)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 48.0)
	shape.shape = rect
	hitbox.add_child(shape)


func reset_enemy() -> void:
	current_health = max_health
	hit_stun_timer = 0.0
	global_position = spawn_position
	velocity = Vector2.ZERO
	visible = true
	set_physics_process(true)
	_set_combat_enabled(true)
	if _visual != null:
		_visual.color = _base_visual_color


func _reset_after_delay() -> void:
	await get_tree().create_timer(defeat_reset_delay).timeout
	if is_instance_valid(self):
		reset_enemy()


func _set_combat_enabled(enabled: bool) -> void:
	collision_layer = 8 if enabled else 0
	collision_mask = 1 if enabled else 0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", not enabled)

	var hurtbox := get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.collision_layer = 8 if enabled else 0
		hurtbox.collision_mask = 16 if enabled else 0
		hurtbox.monitorable = enabled
		hurtbox.monitoring = enabled
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				var shape := child as CollisionShape2D
				shape.set_deferred("disabled", not enabled)

	var contact_hitbox := get_node_or_null("ContactHitbox") as Hitbox
	if contact_hitbox != null:
		contact_hitbox.collision_layer = 32 if enabled else 0
		contact_hitbox.collision_mask = 4 if enabled else 0
		contact_hitbox.set_active(enabled)


func _flash() -> void:
	if _visual == null:
		return

	var original_color := _visual.color
	_visual.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_visual.color = original_color
