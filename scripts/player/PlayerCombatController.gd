class_name PlayerCombatController
extends Node

enum Phase {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

@export var player_path: NodePath = NodePath("..")
@export var hitbox_path: NodePath = NodePath("../AttackHitbox")
@export var hitbox_shape_path: NodePath = NodePath("../AttackHitbox/CollisionShape2D")
@export var presenter_path: NodePath = NodePath("../AttackPresenter")
@export var card_runtime_path: NodePath = NodePath("../CardRuntime")

@onready var player: Variant = get_node(player_path)
@onready var attack_hitbox: Hitbox = get_node(hitbox_path) as Hitbox
@onready var attack_shape: CollisionShape2D = get_node(hitbox_shape_path) as CollisionShape2D
@onready var attack_presenter: PlayerAttackPresenter = get_node(presenter_path) as PlayerAttackPresenter
@onready var card_runtime: Variant = get_node_or_null(card_runtime_path)

var kit: CharacterKit
var stats: Dictionary = {}
var phase: Phase = Phase.IDLE
var current_attack: AttackDefinition
var attack_direction: int = 1
var phase_timer: float = 0.0
var action_elapsed: float = 0.0
var guarded_timer: float = 0.0
var guarded_rearm_timer: float = 0.0

var _cooldowns: Dictionary = {}
var _fallback_basic: AttackDefinition
var _active_target_count: int = 0
var _active_attack_modifiers: Dictionary = {}
# Hitbox applies damage before emitting target_hit, so retain the pre-hit target facts here.
var _pending_hit_contexts: Dictionary = {}


func _ready() -> void:
	attack_hitbox.set_active(false)
	attack_hitbox.visible = false
	attack_hitbox.target_hit.connect(_on_target_hit)
	attack_presenter.reset()


func configure(profile: CharacterProfile, effective_stats: Dictionary) -> void:
	stats = effective_stats.duplicate(true)
	kit = profile.combat_kit if profile != null else null
	_fallback_basic = _make_fallback_basic(stats)
	reset_combat_state()


func update_stats(effective_stats: Dictionary) -> void:
	stats = effective_stats.duplicate(true)
	if kit == null:
		_fallback_basic = _make_fallback_basic(stats)
	_publish_state()


func update_combat(delta: float) -> void:
	_update_cooldowns(delta)
	guarded_timer = maxf(guarded_timer - delta, 0.0)
	guarded_rearm_timer = maxf(guarded_rearm_timer - delta, 0.0)
	if current_attack == null:
		_publish_state()
		return

	action_elapsed += delta
	phase_timer -= delta
	if phase == Phase.STARTUP and not is_movement_locked():
		attack_direction = player.facing
	attack_presenter.update(
		current_attack,
		StringName(Phase.keys()[phase].to_lower()),
		phase_timer,
		_phase_duration(),
		attack_direction
	)
	while current_attack != null and phase_timer <= 0.0:
		_advance_phase()
	_publish_state()


func try_start_input() -> bool:
	if current_attack != null:
		return false

	for action_name in [&"skill_1", &"heavy_attack", &"attack"]:
		if not Input.is_action_just_pressed(String(action_name)):
			continue
		var definition := _definition_for_action(action_name)
		if definition == null:
			return false
		return _begin_attack(definition)
	return false


func is_action_committed() -> bool:
	return current_attack != null


func is_movement_locked() -> bool:
	if current_attack == null:
		return false
	if current_attack is SkillDefinition:
		var skill := current_attack as SkillDefinition
		if skill.movement_distance > 0.0:
			return true
	return (
		current_attack.movement_lock_delay >= 0.0
		and action_elapsed >= current_attack.movement_lock_delay
	)


func apply_movement(delta: float) -> void:
	if not is_movement_locked() or player == null:
		return
	if current_attack is SkillDefinition and phase == Phase.ACTIVE:
		var skill := current_attack as SkillDefinition
		if skill.movement_distance > 0.0:
			var speed := skill.movement_distance / maxf(skill.active_time, 0.01)
			player.velocity.x = float(attack_direction) * speed
			return
	var deceleration := float(stats.get("deceleration", 2200.0))
	player.velocity.x = move_toward(player.velocity.x, 0.0, deceleration * delta)


func notify_wall_collision() -> void:
	if current_attack is SkillDefinition and phase == Phase.ACTIVE:
		var skill := current_attack as SkillDefinition
		if skill.movement_distance > 0.0:
			phase_timer = 0.0


func blocks_incoming_damage(damage_info: DamageInfo) -> bool:
	if not current_attack is SkillDefinition or phase != Phase.ACTIVE:
		return false
	var skill := current_attack as SkillDefinition
	if not skill.frontal_guard_during_active or not _is_frontal_source(damage_info.source):
		return false
	var blockable := damage_info.tags.has("enemy_contact") or damage_info.tags.has("enemy_projectile")
	if blockable:
		_emit_status("Shield Rush blocked")
	return blockable


func reduce_incoming_damage(amount: int) -> int:
	if amount <= 0 or guarded_timer <= 0.0:
		return amount
	guarded_timer = 0.0
	guarded_rearm_timer = kit.guarded_rearm_cooldown if kit != null else 0.0
	_publish_state()
	return maxi(amount - 1, 0)


func reset_combat_state() -> void:
	phase = Phase.IDLE
	current_attack = null
	phase_timer = 0.0
	action_elapsed = 0.0
	guarded_timer = 0.0
	guarded_rearm_timer = 0.0
	_cooldowns.clear()
	_active_attack_modifiers.clear()
	_pending_hit_contexts.clear()
	attack_hitbox.clear_damage_info_provider()
	attack_hitbox.set_active(false)
	attack_hitbox.visible = false
	attack_presenter.reset()
	_publish_state()


func get_state_snapshot() -> Dictionary:
	var actions: Array[Dictionary] = []
	for definition in _available_attacks():
		if definition == null:
			continue
		actions.append({
			"id": String(definition.id),
			"label": definition.display_name,
			"input_action": String(definition.input_action),
			"cooldown": float(_cooldowns.get(String(definition.id), 0.0)),
		})
	return {
		"phase": Phase.keys()[phase].to_lower(),
		"current_attack_id": String(current_attack.id) if current_attack != null else "",
		"guarded_time": guarded_timer,
		"guarded_rearm_time": guarded_rearm_timer,
		"actions": actions,
	}


func _definition_for_action(action_name: StringName) -> AttackDefinition:
	if kit != null:
		return kit.get_attack_for_action(action_name)
	return _fallback_basic if action_name == &"attack" else null


func _available_attacks() -> Array[AttackDefinition]:
	if kit == null:
		return [_fallback_basic]
	var definitions: Array[AttackDefinition] = [kit.basic_attack, kit.heavy_attack]
	var skill_one := kit.get_skill_by_slot(1)
	if skill_one != null:
		definitions.append(skill_one)
	return definitions


func _begin_attack(definition: AttackDefinition) -> bool:
	if float(_cooldowns.get(String(definition.id), 0.0)) > 0.0:
		return false
	current_attack = definition
	attack_direction = player.facing
	phase = Phase.STARTUP
	phase_timer = definition.startup_time
	action_elapsed = 0.0
	_active_target_count = 0
	_active_attack_modifiers = (
		card_runtime.prepare_attack(definition) if card_runtime != null else {}
	)
	var cooldown_multiplier := (
		float(stats.get("skill_cooldown_multiplier", 1.0))
		if definition is SkillDefinition
		else 1.0
	)
	_cooldowns[String(definition.id)] = definition.cooldown * cooldown_multiplier
	_configure_attack_geometry(definition)
	attack_presenter.begin(definition, attack_direction, attack_hitbox.position)
	if phase_timer <= 0.0:
		_advance_phase()
	_publish_state()
	return true


func _advance_phase() -> void:
	match phase:
		Phase.STARTUP:
			phase = Phase.ACTIVE
			phase_timer += current_attack.active_time
			_activate_hit()
		Phase.ACTIVE:
			phase = Phase.RECOVERY
			phase_timer += current_attack.recovery_time
			attack_hitbox.set_active(false, false)
			attack_hitbox.visible = false
		Phase.RECOVERY:
			_finish_attack()


func _activate_hit() -> void:
	attack_direction = player.facing if not is_movement_locked() else attack_direction
	attack_hitbox.position.x = absf(current_attack.hitbox_offset.x) * float(attack_direction)
	attack_hitbox.set_damage_info_provider(_damage_info_for_current_target)
	if current_attack.motion_style == &"arrow_projectile":
		attack_hitbox.set_active(false)
		_fire_projectile(current_attack, attack_direction)
		return
	attack_hitbox.set_active(true)
	attack_hitbox.visible = true


func _finish_attack() -> void:
	attack_hitbox.clear_damage_info_provider()
	attack_hitbox.set_active(false, false)
	attack_hitbox.visible = false
	current_attack = null
	phase = Phase.IDLE
	phase_timer = 0.0
	action_elapsed = 0.0
	_active_attack_modifiers.clear()
	attack_presenter.reset()


func _damage_info_for_current_target(area: Area2D) -> DamageInfo:
	return _resolve_damage_info(
		area,
		current_attack,
		attack_direction,
		false,
		_active_attack_modifiers
	)


func _damage_info_for_projectile_target(
	area: Area2D,
	definition: AttackDefinition,
	direction: int,
	attack_modifiers: Dictionary
) -> DamageInfo:
	return _resolve_damage_info(area, definition, direction, false, attack_modifiers)


func _resolve_damage_info(
	area: Area2D,
	definition: AttackDefinition,
	direction: int,
	secondary_hit: bool,
	attack_modifiers: Dictionary
) -> DamageInfo:
	var target_state := _target_state(area)
	var receiver := _receiver_for_area(area)
	var hit_context := {
		"secondary_hit": secondary_hit,
		"attack_direction": direction,
		"source_position": player.global_position,
	}
	var source_modifiers := {
		"direct_damage_multiplier": float(stats.get("direct_damage_multiplier", 1.0)),
	}
	_merge_numeric_modifiers(source_modifiers, attack_modifiers)
	var card_hit_context := {"modifiers": {}, "activations": []}
	if card_runtime != null:
		card_hit_context = card_runtime.prepare_target_hit(definition, target_state)
	_merge_numeric_modifiers(source_modifiers, card_hit_context.get("modifiers", {}))
	var result := DamageResolver.resolve_attack(
		definition,
		target_state,
		hit_context,
		source_modifiers
	)
	var resolved_knockback := Vector2(
		absf(result.knockback.x) * float(direction),
		result.knockback.y
	)
	var damage_info := DamageInfo.new(
		result.final_damage,
		player,
		resolved_knockback,
		result.tags,
		definition.id,
		result.stagger,
		result.critical,
		secondary_hit
	)
	_pending_hit_contexts[area.get_instance_id()] = {
		"definition": definition,
		"target": receiver,
		"target_state": target_state,
		"activations": card_hit_context.get("activations", []),
	}
	return damage_info


func _target_state(area: Area2D) -> Dictionary:
	var receiver: Node = area
	if area is Hurtbox and (area as Hurtbox).receiver != null:
		receiver = (area as Hurtbox).receiver
	if receiver != null and receiver.has_method("get_combat_snapshot"):
		var snapshot: Variant = receiver.call("get_combat_snapshot")
		if snapshot is Dictionary:
			return snapshot
	return {}


func _on_target_hit(area: Area2D, damage_info: DamageInfo) -> void:
	var event: Dictionary = _pending_hit_contexts.get(area.get_instance_id(), {})
	_pending_hit_contexts.erase(area.get_instance_id())
	var definition := event.get("definition") as AttackDefinition
	if definition == null:
		definition = current_attack
	event["definition"] = definition
	event["damage_info"] = damage_info
	event["defeated"] = _target_is_defeated(event.get("target") as Node)
	_active_target_count += 1
	if definition is SkillDefinition:
		var skill := definition as SkillDefinition
		if _active_target_count >= skill.max_targets:
			attack_hitbox.set_active(false, false)
	if (
		kit != null
		and guarded_timer <= 0.0
		and guarded_rearm_timer <= 0.0
		and (damage_info.tags.has("heavy") or damage_info.tags.has("skill"))
	):
		guarded_timer = kit.guarded_duration
	if damage_info.critical:
		_emit_status("Critical %d" % damage_info.amount)
	if card_runtime != null:
		card_runtime.notify_attack_hit(event)
	_publish_state()


func reduce_longest_skill_cooldown(seconds: float) -> StringName:
	if seconds <= 0.0 or kit == null:
		return &""
	var longest_id: StringName
	var longest_remaining := 0.0
	for skill in kit.skills:
		if skill == null:
			continue
		var remaining := float(_cooldowns.get(String(skill.id), 0.0))
		if remaining > longest_remaining:
			longest_remaining = remaining
			longest_id = skill.id
	if longest_id == &"":
		return &""
	_cooldowns[String(longest_id)] = maxf(longest_remaining - seconds, 0.0)
	_publish_state()
	return longest_id


func _update_cooldowns(delta: float) -> void:
	for attack_id in _cooldowns.keys():
		var remaining := maxf(float(_cooldowns[attack_id]) - delta, 0.0)
		if remaining <= 0.0:
			_cooldowns.erase(attack_id)
		else:
			_cooldowns[attack_id] = remaining


func _is_frontal_source(source: Node) -> bool:
	if not source is Node2D:
		return false
	var delta_x: float = (source as Node2D).global_position.x - player.global_position.x
	if is_zero_approx(delta_x):
		return true
	return int(sign(delta_x)) == attack_direction


func _receiver_for_area(area: Area2D) -> Node:
	if area is Hurtbox and (area as Hurtbox).receiver != null:
		return (area as Hurtbox).receiver
	return area


func _target_is_defeated(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return true
	var health: Variant = target.get("current_health")
	return (health is int or health is float) and float(health) <= 0.0


func _merge_numeric_modifiers(destination: Dictionary, source: Dictionary) -> void:
	for key in source:
		var value: Variant = source[key]
		if not (value is int or value is float):
			continue
		destination[key] = float(destination.get(key, 0.0)) + float(value)


func _configure_attack_geometry(definition: AttackDefinition) -> void:
	if attack_shape.shape is RectangleShape2D:
		var rectangle := attack_shape.shape as RectangleShape2D
		rectangle.size = definition.hitbox_size
	attack_hitbox.position = Vector2(
		absf(definition.hitbox_offset.x) * float(attack_direction),
		definition.hitbox_offset.y
	)
	attack_hitbox.damage_amount = definition.base_damage
	attack_hitbox.knockback = definition.knockback
	attack_hitbox.tags = _string_tags(definition.tags)


func _phase_duration() -> float:
	if current_attack == null:
		return 0.0
	match phase:
		Phase.STARTUP:
			return current_attack.startup_time
		Phase.ACTIVE:
			return current_attack.active_time
		Phase.RECOVERY:
			return current_attack.recovery_time
	return 0.0


func _fire_projectile(definition: AttackDefinition, direction: int) -> void:
	var parent_node: Node = player.get_parent()
	if parent_node == null:
		return
	var projectile := PlayerAttackProjectile.new()
	projectile.name = "%sProjectile" % definition.display_name.replace(" ", "")
	projectile.damage_amount = definition.base_damage
	projectile.knockback = definition.knockback
	projectile.tags = _string_tags(definition.tags)
	projectile.direction = direction
	projectile.velocity = Vector2(
		float(direction) * float(stats.get("attack_projectile_speed", 560.0)), 0.0
	)
	projectile.lifetime = float(stats.get("attack_projectile_lifetime", 0.65))
	var size_value: Variant = stats.get("attack_projectile_size", Vector2(34.0, 8.0))
	projectile.projectile_size = size_value if size_value is Vector2 else Vector2(34.0, 8.0)
	projectile.projectile_color = definition.visual_color
	projectile.set_damage_info_provider(
		_damage_info_for_projectile_target.bind(
			definition,
			direction,
			_active_attack_modifiers.duplicate(true)
		)
	)
	projectile.target_hit.connect(_on_target_hit)
	parent_node.add_child(projectile)
	projectile.global_position = player.global_position + Vector2(
		float(direction) * maxf(absf(definition.hitbox_offset.x), 24.0),
		definition.hitbox_offset.y
	)


func _make_fallback_basic(effective_stats: Dictionary) -> AttackDefinition:
	var definition := AttackDefinition.new()
	definition.id = &"legacy_basic"
	definition.display_name = str(effective_stats.get("attack_label", "Attack"))
	definition.input_action = &"attack"
	definition.tags = [&"player_attack", &"basic"]
	definition.startup_time = 0.0
	definition.active_time = maxf(float(effective_stats.get("attack_active_time", 0.12)), 0.01)
	definition.cooldown = maxf(float(effective_stats.get("attack_cooldown", 0.35)), definition.active_time)
	definition.recovery_time = maxf(definition.cooldown - definition.active_time, 0.0)
	definition.base_damage = int(effective_stats.get("attack_damage", 1))
	definition.knockback = Vector2(
		float(effective_stats.get("attack_knockback_x", 160.0)),
		float(effective_stats.get("attack_knockback_y", -80.0))
	)
	definition.hitbox_size = Vector2(
		float(effective_stats.get("attack_range", 38.0)),
		float(effective_stats.get("attack_height", 30.0))
	)
	definition.hitbox_offset = Vector2(
		float(effective_stats.get("attack_offset_x", 30.0)),
		float(effective_stats.get("attack_offset_y", -26.0))
	)
	definition.motion_style = StringName(str(effective_stats.get("attack_motion_style", "quick_slash")))
	var color_value: Variant = effective_stats.get("attack_visual_color", Color(1.0, 0.86, 0.22, 1.0))
	definition.visual_color = color_value if color_value is Color else Color(1.0, 0.86, 0.22, 1.0)
	return definition


func _string_tags(source: Array[StringName]) -> Array[String]:
	var tags: Array[String] = []
	for tag in source:
		tags.append(String(tag))
	return tags


func _publish_state() -> void:
	if not is_inside_tree():
		return
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.emit_signal("combat_state_changed", get_state_snapshot())


func _emit_status(message: String) -> void:
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.emit_signal("status_message_changed", message)
