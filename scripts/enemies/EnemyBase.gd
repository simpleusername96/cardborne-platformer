class_name EnemyBase
extends CharacterBody2D

signal defeated(enemy: EnemyBase)

@export var max_health: int = 3
@export var contact_damage: int = 1
@export var contact_knockback: Vector2 = Vector2(220.0, -160.0)
@export var gravity: float = 1200.0

var current_health: int = 0
var spawn_position: Vector2

var _visual: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1
	spawn_position = global_position
	current_health = max_health
	_ensure_body()
	_ensure_hurtbox()
	_ensure_contact_hitbox()


func receive_damage(damage_info: DamageInfo) -> void:
	if current_health <= 0:
		return

	current_health = maxi(current_health - damage_info.amount, 0)
	velocity.x = damage_info.knockback.x * 0.45
	velocity.y = minf(velocity.y, damage_info.knockback.y * 0.35)
	SignalBus.status_message_changed.emit("%s HP %d / %d" % [name, current_health, max_health])
	_flash()
	if current_health <= 0:
		_defeat()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 700.0)
	move_and_slide()


func _defeat() -> void:
	defeated.emit(self)
	SignalBus.status_message_changed.emit("%s defeated" % name)
	set_physics_process(false)
	_disable_collisions(self)
	visible = false


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


func _disable_collisions(node: Node) -> void:
	if node is CollisionObject2D:
		var object := node as CollisionObject2D
		object.collision_layer = 0
		object.collision_mask = 0
	if node is CollisionShape2D:
		var shape := node as CollisionShape2D
		shape.set_deferred("disabled", true)
	for child in node.get_children():
		_disable_collisions(child)


func _flash() -> void:
	if _visual == null:
		return

	var original_color := _visual.color
	_visual.color = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_visual.color = original_color
