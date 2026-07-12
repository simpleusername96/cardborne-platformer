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
@export var stagger_capacity: int = 40
@export var stagger_duration: float = 1.4
@export var defeat_below_y: float = 900.0
@export var auto_reset_on_defeat: bool = true
@export var defeat_reset_delay: float = 2.0
@export var encounter_bounds: Rect2 = Rect2()
@export var lightweight: bool = true

@export_group("Resolved Enemy")
@export var enemy_catalog: EnemyCatalog
@export var archetype_id: StringName
@export var variant_id: StringName
@export var stage_id: StringName = &"ruin_approach"

var current_health: int = 0
var spawn_position: Vector2
var hit_stun_timer: float = 0.0
var stagger_meter: int = 0
var staggered_timer: float = 0.0
var fractured_timer: float = 0.0
var fractured_bonus_damage: int = 0
var external_slow_timer: float = 0.0
var external_speed_scale: float = 1.0
var resolved_spec: ResolvedEnemySpec

var _forced_carry_active: bool = false
var _forced_carry_position: Vector2 = Vector2.ZERO
var _delayed_damage: Dictionary = {}

var _visual: Polygon2D
var _base_visual_color: Color = Color(0.84, 0.34, 0.28, 1.0)
var _detail_overlay: EnemyDetailOverlay


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1
	spawn_position = global_position
	_resolve_enemy_spec()
	current_health = max_health
	_ensure_body()
	_ensure_hurtbox()
	_ensure_contact_hitbox()
	if _visual != null:
		_base_visual_color = _visual.color
	_ensure_detail_overlay()


func receive_damage(damage_info: DamageInfo) -> void:
	if current_health <= 0:
		return

	current_health = maxi(current_health - damage_info.amount, 0)
	if staggered_timer <= 0.0 and damage_info.stagger > 0:
		stagger_meter += damage_info.stagger
		if stagger_meter >= stagger_capacity:
			_enter_staggered_state()
	damaged.emit(self, damage_info)
	hit_stun_timer = hit_stun_time
	velocity.x = damage_info.knockback.x * hit_knockback_multiplier
	velocity.y = minf(velocity.y, damage_info.knockback.y * 0.55)
	SignalBus.status_message_changed.emit("%s HP %d / %d" % [name, current_health, max_health])
	_flash(damage_info.critical)
	_request_damage_feedback(damage_info, current_health <= 0)
	if current_health <= 0:
		_defeat()


func _physics_process(delta: float) -> void:
	hit_stun_timer = maxf(hit_stun_timer - delta, 0.0)
	external_slow_timer = maxf(external_slow_timer - delta, 0.0)
	if external_slow_timer <= 0.0:
		external_speed_scale = 1.0
	_update_delayed_damage(delta)
	fractured_timer = maxf(fractured_timer - delta, 0.0)
	if fractured_timer <= 0.0:
		fractured_bonus_damage = 0
	if _forced_carry_active:
		global_position = _forced_carry_position
		velocity = Vector2.ZERO
		return
	var was_staggered := staggered_timer > 0.0
	staggered_timer = maxf(staggered_timer - delta, 0.0)
	if staggered_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	elif was_staggered:
		_refresh_visual_color()
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 700.0)
	move_and_slide()
	if current_health > 0 and global_position.y > defeat_below_y:
		_defeat()


func _defeat() -> void:
	if not visible or not is_physics_processing():
		return
	current_health = 0
	_forced_carry_active = false
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


func _ensure_detail_overlay() -> void:
	_detail_overlay = get_node_or_null("EnemyDetailOverlay") as EnemyDetailOverlay
	if _detail_overlay == null:
		_detail_overlay = EnemyDetailOverlay.new()
		_detail_overlay.name = "EnemyDetailOverlay"
		_detail_overlay.z_index = 4
		add_child(_detail_overlay)
	_detail_overlay.configure(self, archetype_id, variant_id, stage_id)


func reset_enemy() -> void:
	current_health = max_health
	hit_stun_timer = 0.0
	stagger_meter = 0
	staggered_timer = 0.0
	fractured_timer = 0.0
	fractured_bonus_damage = 0
	external_slow_timer = 0.0
	external_speed_scale = 1.0
	_delayed_damage.clear()
	_forced_carry_active = false
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
		hurtbox.set_deferred("monitorable", enabled)
		hurtbox.set_deferred("monitoring", enabled)
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				var shape := child as CollisionShape2D
				shape.set_deferred("disabled", not enabled)

	var contact_hitbox := get_node_or_null("ContactHitbox") as Hitbox
	if contact_hitbox != null:
		contact_hitbox.collision_layer = 32 if enabled else 0
		contact_hitbox.collision_mask = 4 if enabled else 0
		contact_hitbox.set_active(enabled)


func get_combat_snapshot() -> Dictionary:
	return {
		"staggered": staggered_timer > 0.0,
		"mitigation": 0.0,
		"lightweight": lightweight,
		"facing_direction": get_facing_direction(),
		"external_speed_scale": external_speed_scale,
		"fractured_bonus_damage": fractured_bonus_damage if fractured_timer > 0.0 else 0,
	}


func is_staggered() -> bool:
	return staggered_timer > 0.0


func is_light_target() -> bool:
	return lightweight


func apply_fractured(duration: float, bonus_damage: int) -> void:
	if current_health <= 0 or duration <= 0.0 or bonus_damage <= 0:
		return
	fractured_timer = duration
	fractured_bonus_damage = bonus_damage


func consume_fractured() -> int:
	if fractured_timer <= 0.0:
		return 0
	var bonus := fractured_bonus_damage
	fractured_timer = 0.0
	fractured_bonus_damage = 0
	return bonus


func get_facing_direction() -> int:
	for property in get_property_list():
		if String(property.get("name", "")) == "direction":
			var value: Variant = get("direction")
			if value is int and value != 0:
				return value
	if not is_zero_approx(velocity.x):
		return int(sign(velocity.x))
	return -1


func get_external_speed_scale() -> float:
	return external_speed_scale


func apply_external_slow(duration: float, speed_scale: float) -> void:
	if current_health <= 0 or duration <= 0.0:
		return
	external_slow_timer = maxf(external_slow_timer, duration)
	external_speed_scale = minf(external_speed_scale, clampf(speed_scale, 0.1, 1.0))


func apply_delayed_damage(
	source_id: StringName,
	duration: float,
	damage: int,
	source: Node
) -> void:
	if current_health <= 0 or source_id.is_empty() or duration <= 0.0 or damage <= 0:
		return
	_delayed_damage[String(source_id)] = {
		"remaining": duration,
		"damage": damage,
		"source": source,
	}


func get_priority_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemy_decoy"):
		if not candidate is Node2D or not is_instance_valid(candidate):
			continue
		var candidate_2d := candidate as Node2D
		if not is_target_within_encounter(candidate_2d):
			continue
		var distance := global_position.distance_squared_to(candidate_2d.global_position)
		if distance < nearest_distance:
			nearest = candidate_2d
			nearest_distance = distance
	if nearest != null:
		return nearest
	return get_tree().get_first_node_in_group("player") as Node2D


func begin_forced_carry() -> void:
	if lightweight and current_health > 0:
		_forced_carry_active = true


func set_forced_carry_position(position: Vector2) -> void:
	if _forced_carry_active:
		_forced_carry_position = position


func end_forced_carry() -> void:
	_forced_carry_active = false
	velocity = Vector2.ZERO


func apply_external_stagger(amount: int, source: Node, source_id: StringName) -> void:
	if amount <= 0 or current_health <= 0:
		return
	receive_damage(DamageInfo.new(
		0,
		source,
		Vector2.ZERO,
		["player_attack", "wall_impact", "secondary"],
		source_id,
		amount,
		false,
		true
	))


func is_target_within_encounter(target: Node2D) -> bool:
	if target == null:
		return false
	return encounter_bounds.size == Vector2.ZERO or encounter_bounds.has_point(target.global_position)


func is_player_within_encounter() -> bool:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	return is_target_within_encounter(target)


func _resolve_enemy_spec() -> void:
	if enemy_catalog == null:
		return
	var errors := enemy_catalog.get_resolution_errors(archetype_id, variant_id, stage_id)
	if not errors.is_empty():
		for error in errors:
			push_error("%s enemy resolution failed: %s" % [name, error])
		return
	resolved_spec = enemy_catalog.resolve(archetype_id, variant_id, stage_id)
	if resolved_spec == null:
		push_error("%s enemy resolution returned no spec." % name)
		return
	var script := get_script() as Script
	if script != null and script.get_global_name() != String(resolved_spec.behavior_owner):
		push_error(
			"%s uses %s but resolved archetype requires %s."
			% [name, script.get_global_name(), resolved_spec.behavior_owner]
		)
		resolved_spec = null
		return
	max_health = resolved_spec.health
	contact_damage = resolved_spec.damage
	stagger_capacity = resolved_spec.stagger_capacity


func _enter_staggered_state() -> void:
	stagger_meter = 0
	staggered_timer = stagger_duration
	hit_stun_timer = maxf(hit_stun_timer, stagger_duration)
	velocity.x = 0.0
	_refresh_visual_color()


func _refresh_visual_color() -> void:
	if _visual == null:
		return
	_visual.color = Color(0.36, 0.88, 0.92, 1.0) if is_staggered() else _base_visual_color


func _flash(critical: bool = false) -> void:
	if _visual == null:
		return

	_visual.color = Color(1.0, 0.76, 0.16, 1.0) if critical else Color.WHITE
	await get_tree().create_timer(0.12 if critical else 0.08).timeout
	if is_instance_valid(_visual) and current_health > 0:
		_refresh_visual_color()


func _request_damage_feedback(damage_info: DamageInfo, defeated_now: bool) -> void:
	var cue_id := &"enemy_defeat" if defeated_now else (
		&"critical_hit" if damage_info.critical else &"enemy_hit"
	)
	var strength := clampf(0.7 + float(damage_info.amount) * 0.16, 0.7, 1.5)
	SignalBus.gameplay_feedback_requested.emit({
		"cue_id": cue_id,
		"strength": strength,
		"world_position": global_position + Vector2(0.0, -22.0),
		"context": {
			"source": "enemy",
			"archetype_id": String(archetype_id),
			"variant_id": String(variant_id),
			"damage": damage_info.amount,
		},
	})


func _update_delayed_damage(delta: float) -> void:
	for source_key in _delayed_damage.keys():
		var entry: Dictionary = _delayed_damage[source_key]
		entry["remaining"] = float(entry.get("remaining", 0.0)) - delta
		if float(entry["remaining"]) > 0.0:
			_delayed_damage[source_key] = entry
			continue
		_delayed_damage.erase(source_key)
		if current_health <= 0:
			continue
		receive_damage(DamageInfo.new(
			int(entry.get("damage", 0)),
			entry.get("source") as Node,
			Vector2.ZERO,
			["player_attack", "damage_over_time", "secondary"],
			StringName(source_key),
			0,
			false,
			true
		))
