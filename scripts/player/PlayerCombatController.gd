class_name PlayerCombatController
extends Node

enum Phase {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

const AFTERSHOCK_DELAY := 0.4
const RALLY_ECHO_DISTANCE := 180.0
const RALLY_ECHO_DURATION := 0.3

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
var _progression_effects: Array[ProgressionBehaviorEffect] = []
# Hitbox applies damage before target_hit, so the confirmed event reuses this context.
var _pending_hit_contexts: Dictionary = {}
var _carried_targets: Array[Node2D] = []
var _rally_heavy_timer: float = 0.0
var _rally_startup_scale: float = 1.0
var _rally_echo_damage_scale: float = 0.0
var _rally_echo_spawned: bool = false
var _post_double_jump_stagger_ready: bool = false
# Normal combat resets preserve this per-stage limit; begin_stage owns its reset.
var _last_bastion_used: bool = false
var _action_serial: int = 0


func _ready() -> void:
	attack_hitbox.set_active(false)
	attack_hitbox.visible = false
	attack_hitbox.target_hit.connect(_on_target_hit)
	attack_presenter.reset()
	if (
		player != null
		and player.has_signal("extra_jump_performed")
		and not player.is_connected("extra_jump_performed", notify_extra_jump_performed)
	):
		player.connect("extra_jump_performed", notify_extra_jump_performed)


func configure(
	profile: CharacterProfile,
	effective_stats: Dictionary,
	progression_effects: Array = []
) -> void:
	stats = effective_stats.duplicate(true)
	kit = profile.combat_kit if profile != null else null
	_progression_effects.clear()
	for value in progression_effects:
		var effect := value as ProgressionBehaviorEffect
		if effect != null:
			_progression_effects.append(effect)
	_fallback_basic = _make_fallback_basic(stats)
	reset_combat_state()
	begin_stage()


func begin_stage() -> void:
	_last_bastion_used = false
	_publish_state()


func update_stats(effective_stats: Dictionary) -> void:
	stats = effective_stats.duplicate(true)
	if kit == null:
		_fallback_basic = _make_fallback_basic(stats)
	_publish_state()


func update_combat(delta: float) -> void:
	_update_cooldowns(delta)
	guarded_timer = maxf(guarded_timer - delta, 0.0)
	guarded_rearm_timer = maxf(guarded_rearm_timer - delta, 0.0)
	_rally_heavy_timer = maxf(_rally_heavy_timer - delta, 0.0)
	if _rally_heavy_timer <= 0.0:
		_clear_rally_empowerment()
	if player != null and player.is_on_floor():
		_post_double_jump_stagger_ready = false
	_update_carried_targets()
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

	for action_name in [&"skill_3", &"skill_2", &"skill_1", &"heavy_attack", &"attack"]:
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
			_release_carried_targets(true)
			phase_timer = 0.0


func blocks_incoming_damage(damage_info: DamageInfo) -> bool:
	if current_attack is SkillDefinition and phase == Phase.ACTIVE:
		var skill := current_attack as SkillDefinition
		var rush_block := (
			skill.frontal_guard_during_active
			and _is_frontal_source(damage_info.source)
			and (
				damage_info.tags.has("enemy_contact")
				or damage_info.tags.has("enemy_projectile")
			)
		)
		if rush_block:
			_emit_status("Shield Rush blocked")
			return true
	if (
		guarded_timer > 0.0
		and damage_info.tags.has("enemy_projectile")
		and PlayerProgressionEffectQuery.has(_progression_effects, &"guard_blocks_projectile")
	):
		_consume_guard()
		_emit_status("Broad Guard blocked")
		return true
	return false


func resolve_incoming_damage(amount: int) -> Dictionary:
	var result := {
		"damage": maxi(amount, 0),
		"guard_consumed": false,
		"knockback_scale": 1.0,
	}
	if amount <= 0 or guarded_timer <= 0.0:
		return result
	result["damage"] = maxi(amount - 1, 0)
	result["guard_consumed"] = true
	var steady_feet := PlayerProgressionEffectQuery.first(
		_progression_effects,
		&"guard_knockback_scale"
	)
	if steady_feet != null:
		result["knockback_scale"] = steady_feet.value
	_consume_guard()
	return result


func reduce_incoming_damage(amount: int) -> int:
	return int(resolve_incoming_damage(amount).get("damage", amount))


func notify_health_changed(previous_health: int, current_health: int) -> void:
	if _last_bastion_used or previous_health <= 1 or current_health != 1:
		return
	var effect := PlayerProgressionEffectQuery.first(
		_progression_effects,
		&"once_per_stage_one_health_guard_and_skill_reset"
	)
	if effect == null:
		return
	_last_bastion_used = true
	_arm_guard()
	_cooldowns.erase(String(effect.target_id))
	_emit_status("Last Bastion")
	_publish_state()


func notify_player_damaged(resolved_damage: int) -> void:
	if resolved_damage <= 0 or current_attack == null or phase != Phase.STARTUP:
		return
	if bool(_active_attack_modifiers.get("uninterruptible_startup", false)):
		return
	_cancel_current_attack()


func notify_extra_jump_performed() -> void:
	if PlayerProgressionEffectQuery.first_post_double_jump_stagger(_progression_effects) > 0:
		_post_double_jump_stagger_ready = true


func reset_combat_state() -> void:
	_release_carried_targets(false)
	phase = Phase.IDLE
	current_attack = null
	phase_timer = 0.0
	action_elapsed = 0.0
	guarded_timer = 0.0
	guarded_rearm_timer = 0.0
	_cooldowns.clear()
	_active_attack_modifiers.clear()
	_pending_hit_contexts.clear()
	_clear_rally_empowerment()
	_post_double_jump_stagger_ready = false
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
		"rally_heavy_time": _rally_heavy_timer,
		"post_double_jump_stagger_ready": _post_double_jump_stagger_ready,
		"last_bastion_used": _last_bastion_used,
		"progression_effects": PlayerProgressionEffectQuery.effect_types(_progression_effects),
		"actions": actions,
	}


func get_effective_timing(definition: AttackDefinition) -> Dictionary:
	var modifiers := PlayerProgressionEffectQuery.attack_modifiers(
		_progression_effects,
		definition.id
	)
	return {
		"startup": _timing_value(definition.startup_time, "startup", modifiers),
		"active": _timing_value(definition.active_time, "active", modifiers),
		"recovery": _timing_value(definition.recovery_time, "recovery", modifiers),
	}


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


func spawn_secondary_shockwave(
	damage: int,
	stagger: int,
	distance: float,
	duration: float,
	source_id: StringName,
	direction: int = 0,
	origin: Variant = null
) -> bool:
	var resolved_direction := direction if direction != 0 else attack_direction
	var resolved_origin := player.global_position if origin == null else origin as Vector2
	if damage <= 0 or distance <= 0.0 or duration <= 0.0:
		return false
	if not _has_supported_ground(resolved_origin):
		return false
	var wave := _make_wave(
		resolved_direction,
		distance,
		duration,
		4,
		Color(1.0, 0.78, 0.22, 0.72)
	)
	wave.set_damage_info_provider(
		_fixed_shockwave_damage.bind(damage, stagger, resolved_direction, source_id)
	)
	# Fixed secondary waves intentionally omit target_hit to prevent recursive procs.
	return _add_wave(wave, resolved_origin, resolved_direction)


func _definition_for_action(action_name: StringName) -> AttackDefinition:
	if kit != null:
		return kit.get_attack_for_action(action_name)
	return _fallback_basic if action_name == &"attack" else null


func _available_attacks() -> Array[AttackDefinition]:
	if kit == null:
		return [_fallback_basic]
	var definitions: Array[AttackDefinition] = [kit.basic_attack, kit.heavy_attack]
	for skill in kit.skills:
		if skill != null:
			definitions.append(skill)
	return definitions


func _begin_attack(definition: AttackDefinition) -> bool:
	if float(_cooldowns.get(String(definition.id), 0.0)) > 0.0:
		return false
	current_attack = definition
	attack_direction = player.facing
	phase = Phase.STARTUP
	action_elapsed = 0.0
	_active_target_count = 0
	_rally_echo_spawned = false
	_action_serial += 1
	_active_attack_modifiers = PlayerProgressionEffectQuery.attack_modifiers(
		_progression_effects,
		definition.id
	)
	if card_runtime != null:
		_merge_action_modifiers(_active_attack_modifiers, card_runtime.prepare_attack(definition))
	_apply_post_double_jump_stagger(definition)
	_apply_rally_to_heavy(definition)
	_apply_self_buff(definition)
	phase_timer = _timing_value(definition.startup_time, "startup", _active_attack_modifiers)
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
			phase_timer += _timing_value(
				current_attack.active_time,
				"active",
				_active_attack_modifiers
			)
			_activate_hit()
		Phase.ACTIVE:
			phase = Phase.RECOVERY
			phase_timer += _timing_value(
				current_attack.recovery_time,
				"recovery",
				_active_attack_modifiers
			)
			attack_hitbox.set_active(false, false)
			attack_hitbox.visible = false
		Phase.RECOVERY:
			_finish_attack()


func _activate_hit() -> void:
	attack_direction = player.facing if not is_movement_locked() else attack_direction
	attack_hitbox.position.x = absf(current_attack.hitbox_offset.x) * float(attack_direction)
	if card_runtime != null:
		card_runtime.notify_attack_activated(current_attack, {
			"supported_ground": _has_supported_ground(player.global_position),
			"action_serial": _action_serial,
		})
	if current_attack is SkillDefinition:
		var skill := current_attack as SkillDefinition
		match skill.execution_mode:
			SkillDefinition.EXECUTION_GROUND_SHOCKWAVE:
				attack_hitbox.set_active(false)
				attack_hitbox.visible = false
				_spawn_definition_shockwave(skill, attack_direction, player.global_position)
				_schedule_aftershock_if_enabled(skill, attack_direction, player.global_position)
				return
			SkillDefinition.EXECUTION_SELF_BUFF:
				attack_hitbox.set_active(false)
				attack_hitbox.visible = false
				return
	attack_hitbox.set_damage_info_provider(_damage_info_for_current_target)
	if current_attack.motion_style == &"arrow_projectile":
		attack_hitbox.set_active(false)
		_fire_projectile(current_attack, attack_direction)
		return
	attack_hitbox.set_active(true)
	attack_hitbox.visible = true


func _finish_attack() -> void:
	_release_carried_targets(false)
	attack_hitbox.clear_damage_info_provider()
	attack_hitbox.set_active(false, false)
	attack_hitbox.visible = false
	current_attack = null
	phase = Phase.IDLE
	phase_timer = 0.0
	action_elapsed = 0.0
	_active_attack_modifiers.clear()
	attack_presenter.reset()


func _cancel_current_attack() -> void:
	_release_carried_targets(false)
	attack_hitbox.clear_damage_info_provider()
	attack_hitbox.set_active(false, false)
	attack_hitbox.visible = false
	current_attack = null
	phase = Phase.IDLE
	phase_timer = 0.0
	action_elapsed = 0.0
	_active_attack_modifiers.clear()
	attack_presenter.reset()
	_emit_status("Attack interrupted")


func _damage_info_for_current_target(area: Area2D) -> DamageInfo:
	return _resolve_damage_info(
		area,
		current_attack,
		attack_direction,
		false,
		_active_attack_modifiers
	)


func _damage_info_for_traveling_target(
	area: Area2D,
	definition: AttackDefinition,
	direction: int,
	secondary_hit: bool,
	attack_modifiers: Dictionary
) -> DamageInfo:
	return _resolve_damage_info(
		area,
		definition,
		direction,
		secondary_hit,
		attack_modifiers
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
		"direct_damage_additive": float(attack_modifiers.get("direct_damage_additive", 0.0)),
		"stagger_additive": float(attack_modifiers.get("stagger_additive", 0.0)),
	}
	var consume_fracture := false
	if definition is SkillDefinition and not secondary_hit:
		var fracture_bonus := int(target_state.get("fractured_bonus_damage", 0))
		if fracture_bonus > 0:
			source_modifiers["direct_damage_additive"] += fracture_bonus
			consume_fracture = true
	var card_hit_context := {"modifiers": {}, "activations": []}
	if card_runtime != null and not secondary_hit:
		card_hit_context = card_runtime.prepare_target_hit(definition, target_state)
	_merge_damage_modifiers(source_modifiers, card_hit_context.get("modifiers", {}))
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
	if (
		definition is SkillDefinition
		and (definition as SkillDefinition).launch_light_targets
		and not bool(target_state.get("lightweight", false))
	):
		resolved_knockback.y = 0.0
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
		"consume_fracture": consume_fracture,
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
	if definition == null:
		return
	event["definition"] = definition
	event["damage_info"] = damage_info
	event["defeated"] = _target_is_defeated(event.get("target") as Node)
	_active_target_count += 1
	var target := event.get("target") as Node
	if bool(event.get("consume_fracture", false)) and target != null:
		if target.has_method("consume_fractured"):
			target.call("consume_fractured")
	_apply_mastery_on_hit(definition, target, event)
	if definition is SkillDefinition:
		var skill := definition as SkillDefinition
		if _active_target_count >= skill.max_targets:
			attack_hitbox.set_active(false, false)
	if (
		kit != null
		and guarded_timer <= 0.0
		and guarded_rearm_timer <= 0.0
		and not damage_info.secondary_hit
		and (damage_info.tags.has("heavy") or damage_info.tags.has("skill"))
	):
		_arm_guard()
	_spawn_rally_echo_if_ready(definition, damage_info)
	if damage_info.critical:
		_emit_status("Critical %d" % damage_info.amount)
	if card_runtime != null:
		card_runtime.notify_attack_hit(event)
	_publish_state()


func _apply_mastery_on_hit(
	definition: AttackDefinition,
	target: Node,
	_event: Dictionary
) -> void:
	if target == null:
		return
	if definition.tags.has(&"heavy"):
		var fracture := PlayerProgressionEffectQuery.first(
			_progression_effects,
			&"breaker_applies_fractured"
		)
		if fracture != null and target.has_method("apply_fractured"):
			target.call("apply_fractured", fracture.duration, fracture.damage)
	if (
		definition is SkillDefinition
		and definition.tags.has(&"shield_rush")
		and PlayerProgressionEffectQuery.has(
			_progression_effects,
			&"shield_rush_carries_light_targets"
		)
	):
		_begin_carry(target)


func _begin_carry(target: Node) -> void:
	if not target is Node2D or not target.has_method("is_light_target"):
		return
	if not bool(target.call("is_light_target")) or not target.has_method("begin_forced_carry"):
		return
	var target_2d := target as Node2D
	if _carried_targets.has(target_2d):
		return
	target.call("begin_forced_carry")
	_carried_targets.append(target_2d)
	_update_carried_targets()


func _update_carried_targets() -> void:
	for index in range(_carried_targets.size() - 1, -1, -1):
		var target := _carried_targets[index]
		if not is_instance_valid(target) or not target.has_method("set_forced_carry_position"):
			_carried_targets.remove_at(index)
			continue
		target.call(
			"set_forced_carry_position",
			player.global_position + Vector2(float(attack_direction) * 44.0, 0.0)
		)


func _release_carried_targets(wall_impact: bool) -> void:
	var wall_stagger := PlayerProgressionEffectQuery.first(
		_progression_effects,
		&"wall_impact_stagger"
	)
	var source_id := current_attack.id if current_attack != null else &""
	for target in _carried_targets:
		if not is_instance_valid(target):
			continue
		if wall_impact and wall_stagger != null and target.has_method("apply_external_stagger"):
			target.call("apply_external_stagger", wall_stagger.stagger, player, source_id)
		if target.has_method("end_forced_carry"):
			target.call("end_forced_carry")
	_carried_targets.clear()


func _apply_post_double_jump_stagger(definition: AttackDefinition) -> void:
	if not _post_double_jump_stagger_ready or definition.base_damage <= 0:
		return
	if player != null and player.is_on_floor():
		_post_double_jump_stagger_ready = false
		return
	var bonus := PlayerProgressionEffectQuery.first_post_double_jump_stagger(
		_progression_effects
	)
	if bonus > 0:
		_add_modifier(_active_attack_modifiers, "stagger_additive", bonus)
	_post_double_jump_stagger_ready = false


func _apply_rally_to_heavy(definition: AttackDefinition) -> void:
	if _rally_heavy_timer <= 0.0 or not definition.tags.has(&"heavy"):
		return
	_multiply_modifier(_active_attack_modifiers, "startup_time_scale", _rally_startup_scale)
	_active_attack_modifiers["rally_echo_damage_scale"] = _rally_echo_damage_scale
	_clear_rally_empowerment()


func _apply_self_buff(definition: AttackDefinition) -> void:
	if not definition is SkillDefinition:
		return
	var skill := definition as SkillDefinition
	if skill.execution_mode != SkillDefinition.EXECUTION_SELF_BUFF:
		return
	if skill.grants_guard:
		_arm_guard()
	if skill.heavy_empower_window > 0.0:
		_rally_heavy_timer = skill.heavy_empower_window
		_rally_startup_scale = skill.heavy_startup_scale
		_rally_echo_damage_scale = skill.heavy_echo_damage_scale


func _clear_rally_empowerment() -> void:
	_rally_heavy_timer = 0.0
	_rally_startup_scale = 1.0
	_rally_echo_damage_scale = 0.0


func _spawn_rally_echo_if_ready(
	definition: AttackDefinition,
	damage_info: DamageInfo
) -> void:
	if (
		_rally_echo_spawned
		or damage_info.secondary_hit
		or not definition.tags.has(&"heavy")
	):
		return
	var scale := float(_active_attack_modifiers.get("rally_echo_damage_scale", 0.0))
	if scale <= 0.0:
		return
	_rally_echo_spawned = true
	var echo_damage := maxi(int(floor(float(damage_info.amount) * scale + 0.5)), 1)
	spawn_secondary_shockwave(
		echo_damage,
		0,
		RALLY_ECHO_DISTANCE,
		RALLY_ECHO_DURATION,
		definition.id,
		attack_direction,
		player.global_position
	)


func _spawn_definition_shockwave(
	skill: SkillDefinition,
	direction: int,
	origin: Vector2
) -> bool:
	if not _has_supported_ground(origin):
		return false
	var wave := _make_wave(
		direction,
		skill.effect_distance,
		skill.active_time,
		skill.max_targets,
		skill.visual_color
	)
	wave.ground_probe_depth = skill.ground_probe_depth
	wave.set_damage_info_provider(
		_damage_info_for_traveling_target.bind(
			skill,
			direction,
			false,
			_active_attack_modifiers.duplicate(true)
		)
	)
	wave.target_hit.connect(_on_target_hit)
	return _add_wave(wave, origin, direction)


func _schedule_aftershock_if_enabled(
	skill: SkillDefinition,
	direction: int,
	origin: Vector2
) -> void:
	var effect := PlayerProgressionEffectQuery.first(
		_progression_effects,
		&"ground_splitter_aftershock"
	)
	if effect == null:
		return
	_run_delayed_aftershock(skill, direction, origin, effect.damage)


func _run_delayed_aftershock(
	skill: SkillDefinition,
	direction: int,
	origin: Vector2,
	damage: int
) -> void:
	await get_tree().create_timer(AFTERSHOCK_DELAY).timeout
	if not is_instance_valid(player) or not is_inside_tree():
		return
	spawn_secondary_shockwave(
		damage,
		0,
		skill.effect_distance,
		skill.active_time,
		skill.id,
		direction,
		origin
	)


func _make_wave(
	direction: int,
	distance: float,
	duration: float,
	max_targets: int,
	color: Color
) -> PlayerGroundShockwave:
	var wave := PlayerGroundShockwave.new()
	wave.name = "GroundShockwave"
	wave.direction = direction
	wave.max_distance = distance
	wave.travel_duration = duration
	wave.max_targets = max_targets
	wave.wave_color = color
	return wave


func _add_wave(
	wave: PlayerGroundShockwave,
	origin: Vector2,
	direction: int
) -> bool:
	var parent_node := player.get_parent() as Node
	if parent_node == null:
		return false
	call_deferred(
		"_deferred_add_wave",
		parent_node,
		wave,
		origin + Vector2(float(direction) * 28.0, -8.0)
	)
	return true


func _deferred_add_wave(
	parent_node: Node,
	wave: PlayerGroundShockwave,
	spawn_position: Vector2
) -> void:
	if not is_instance_valid(parent_node) or not is_instance_valid(wave):
		return
	parent_node.add_child(wave)
	wave.global_position = spawn_position


func _fixed_shockwave_damage(
	_area: Area2D,
	damage: int,
	stagger: int,
	direction: int,
	source_id: StringName
) -> DamageInfo:
	return DamageInfo.new(
		damage,
		player,
		Vector2(float(direction) * 180.0, -80.0),
		["player_attack", "shockwave", "secondary"],
		source_id,
		stagger,
		false,
		true
	)


func _has_supported_ground(origin: Vector2) -> bool:
	if not is_inside_tree():
		return false
	var query := PhysicsRayQueryParameters2D.create(
		origin + Vector2(0.0, -4.0),
		origin + Vector2(0.0, 30.0),
		3
	)
	query.hit_from_inside = true
	return not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _consume_guard() -> void:
	guarded_timer = 0.0
	guarded_rearm_timer = kit.guarded_rearm_cooldown if kit != null else 0.0
	if card_runtime != null:
		card_runtime.notify_guard_consumed()
	_publish_state()


func _arm_guard() -> void:
	if kit != null:
		guarded_timer = maxf(guarded_timer, kit.guarded_duration)


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


func _merge_action_modifiers(destination: Dictionary, source: Dictionary) -> void:
	for key in source:
		var value: Variant = source[key]
		if value is bool:
			destination[key] = bool(destination.get(key, false)) or bool(value)
		elif value is int or value is float:
			if String(key).ends_with("_scale") or String(key).ends_with("_multiplier"):
				_multiply_modifier(destination, String(key), float(value))
			else:
				_add_modifier(destination, String(key), float(value))


func _merge_damage_modifiers(destination: Dictionary, source: Dictionary) -> void:
	for key in source:
		var value: Variant = source[key]
		if not (value is int or value is float):
			continue
		if String(key).ends_with("_multiplier"):
			destination[key] = float(destination.get(key, 1.0)) * float(value)
		else:
			destination[key] = float(destination.get(key, 0.0)) + float(value)


func _add_modifier(destination: Dictionary, key: String, amount: float) -> void:
	destination[key] = float(destination.get(key, 0.0)) + amount


func _multiply_modifier(destination: Dictionary, key: String, amount: float) -> void:
	destination[key] = float(destination.get(key, 1.0)) * amount


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
			return _timing_value(
				current_attack.startup_time,
				"startup",
				_active_attack_modifiers
			)
		Phase.ACTIVE:
			return _timing_value(
				current_attack.active_time,
				"active",
				_active_attack_modifiers
			)
		Phase.RECOVERY:
			return _timing_value(
				current_attack.recovery_time,
				"recovery",
				_active_attack_modifiers
			)
	return 0.0


func _timing_value(base: float, phase_name: String, modifiers: Dictionary) -> float:
	var additive := float(modifiers.get("%s_time_additive" % phase_name, 0.0))
	var scale := float(modifiers.get("%s_time_scale" % phase_name, 1.0))
	return maxf((base + additive) * scale, 0.0)


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
