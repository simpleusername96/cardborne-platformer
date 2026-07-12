class_name Hitbox
extends Area2D

signal target_hit(area: Area2D, damage_info: DamageInfo)

@export var damage_amount: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var tags: Array[String] = []
@export var starts_active: bool = false
@export var repeat_hits: bool = false

var active: bool = false
var _hit_targets: Dictionary = {}
var _damage_info_provider: Callable


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_active(starts_active)


func set_active(is_active: bool, reset_hits: bool = true) -> void:
	active = is_active
	if reset_hits:
		_hit_targets.clear()

	# Area callbacks may stop a hitbox while the physics server is flushing overlaps.
	set_deferred("monitoring", active)
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not active)


func set_damage_info_provider(provider: Callable) -> void:
	_damage_info_provider = provider


func clear_damage_info_provider() -> void:
	_damage_info_provider = Callable()


func _on_area_entered(area: Area2D) -> void:
	if not active or not area.has_method("receive_damage"):
		return

	var target_id := area.get_instance_id()
	if not repeat_hits and _hit_targets.has(target_id):
		return

	if not repeat_hits:
		_hit_targets[target_id] = true
	var damage_info := _provide_damage_info(area)
	area.receive_damage(damage_info)
	target_hit.emit(area, damage_info)


func _provide_damage_info(area: Area2D) -> DamageInfo:
	if _damage_info_provider.is_valid():
		var provided: Variant = _damage_info_provider.call(area)
		if provided is DamageInfo:
			return provided
	return DamageInfo.new(damage_amount, self, knockback, tags)
