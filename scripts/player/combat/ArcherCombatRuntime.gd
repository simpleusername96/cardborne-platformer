class_name ArcherCombatRuntime
extends CharacterCombatRuntime

const QUICK_SHOT := &"archer_quick_shot"
const POWER_SHOT := &"archer_power_shot"
const VAULT_SHOT := &"archer_vault_shot"
const RAIN_FIELD := &"archer_rain_field"
const THREADLINE := &"archer_threadline"

const MARK_DURATION := 6.0
const MARK_BURST_RADIUS := 90.0
const RAIN_STRIKE_TIMES := [0.45, 0.60, 0.75, 0.90, 1.05, 1.20]
const RAIN_STRIKE_OFFSETS := [-0.72, 0.35, -0.18, 0.72, -0.42, 0.08]
const RAIN_STRIKE_RADIUS := 52.0
const PROJECTILE_LIFETIME_MARGIN := 0.08

var _marks: Dictionary = {}
var _scheduled_effects: Array[Dictionary] = []
var _rain_fields: Array[Dictionary] = []
var _owned_projectiles: Array[WeakRef] = []
var _split_triggered_actions: Dictionary = {}
var _secondary_definitions: Dictionary = {}
var _quick_nock_ready := false
var _clean_release_timer := 0.0
var _vault_active := false
var _vault_direction := 1
var _threadline_pull_active := false
var _threadline_pull_velocity := Vector2.ZERO
var _threadline_saved_velocity := Vector2.ZERO
var _threadline_pull_remaining := 0.0


func begin_stage() -> void:
	_clear_runtime_state()


func reset() -> void:
	_clear_runtime_state()


func update(delta: float) -> void:
	if delta <= 0.0:
		return
	_clean_release_timer = maxf(_clean_release_timer - delta, 0.0)
	_prune_projectiles()
	_update_marks(delta)
	_update_scheduled_effects(delta)
	_update_rain_fields(delta)


func apply_movement(delta: float) -> bool:
	var definition := controller.get("current_attack") as AttackDefinition
	if definition == null:
		return false
	var active := int(controller.get("phase")) == PlayerCombatController.Phase.ACTIVE
	match definition.id:
		VAULT_SHOT:
			if active and _vault_active:
				var velocity: Vector2 = player.get("velocity")
				velocity.x = -float(_vault_direction) * 400.0
				player.set("velocity", velocity)
			elif _vault_active:
				var velocity: Vector2 = player.get("velocity")
				velocity.x = 0.0
				player.set("velocity", velocity)
				_vault_active = false
			else:
				_decelerate_horizontal(delta)
			return true
		THREADLINE:
			if active and _threadline_pull_active and _threadline_pull_remaining > 0.0:
				player.set("velocity", _threadline_pull_velocity)
				_threadline_pull_remaining = maxf(
					_threadline_pull_remaining - _threadline_pull_velocity.length() * delta,
					0.0
				)
				if _threadline_pull_remaining <= 0.0:
					_stop_threadline_pull()
			elif _threadline_pull_active:
				_stop_threadline_pull()
			else:
				_decelerate_horizontal(delta)
			return true
	return false


func prepare_attack(definition: AttackDefinition, modifiers: Dictionary) -> void:
	if definition.id == QUICK_SHOT and _quick_nock_ready:
		var quick_nock := _first_effect(&"post_dash_quick_shot_startup_scale")
		if quick_nock != null:
			_multiply_modifier(modifiers, "startup_time_scale", quick_nock.value)
			_quick_nock_ready = false
	if definition.id != POWER_SHOT:
		return
	var power_penalty := _first_effect(&"power_shot_max_damage", POWER_SHOT)
	if power_penalty != null:
		_add_modifier(modifiers, "maximum_charge_damage_additive", power_penalty.damage_delta)
	var piercing_draw := _first_effect(&"full_charge_extra_pierce")
	if piercing_draw != null:
		_add_modifier(modifiers, "full_charge_target_additive", piercing_draw.value)


func activate_attack(definition: AttackDefinition) -> bool:
	match definition.id:
		QUICK_SHOT:
			_activate_quick_shot(definition)
			return true
		POWER_SHOT:
			_activate_power_shot(definition)
			return true
		VAULT_SHOT:
			_activate_vault_shot(definition as SkillDefinition)
			return true
		RAIN_FIELD:
			_activate_rain_field(definition as SkillDefinition)
			return true
		THREADLINE:
			_activate_threadline(definition as SkillDefinition)
			return true
	return false


func prepare_damage(
	definition: AttackDefinition,
	target: Node,
	_target_state: Dictionary,
	_source_modifiers: Dictionary,
	secondary_hit: bool,
	event_context: Dictionary
) -> Dictionary:
	if secondary_hit or definition.id != POWER_SHOT or not _has_mark(target):
		return {}
	var hit_context: Dictionary = event_context.get("hit_context", {})
	var full_charge := (
		bool(hit_context.get("full_charge", false))
		or float(event_context.get("charge_fraction", 0.0)) >= 0.999
	)
	if not full_charge:
		return {}
	return {
		"hit_context": {"target_hunters_mark": true},
		"consume_hunters_mark": true,
	}


func notify_target_hit(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	var damage_info := event.get("damage_info") as DamageInfo
	var target := event.get("target") as Node
	if definition == null or damage_info == null or target == null or damage_info.secondary_hit:
		return
	if definition is SkillDefinition:
		_apply_mark(target, MARK_DURATION)
	if bool(event.get("consume_hunters_mark", false)):
		_consume_mark(target)
	if definition.id == POWER_SHOT:
		_trigger_split_shaft(
			int(event.get("action_serial", _action_serial())),
			_target_position(target)
		)


func notify_attack_finished(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	if definition == null:
		return
	if definition.id == VAULT_SHOT:
		_vault_active = false
		_decelerate_horizontal(1.0)
	elif definition.id == THREADLINE:
		_stop_threadline_pull()


func notify_attack_interrupted(event: Dictionary) -> void:
	notify_attack_finished(event)


func notify_projectile_terminated(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	if definition == null or definition.id != POWER_SHOT:
		return
	if StringName(event.get("reason", &"")) != &"max_range":
		return
	_trigger_split_shaft(
		int(event.get("action_serial", _action_serial())),
		event.get("position", _player_position()) as Vector2
	)


func notify_dash_completed(_start_position: Vector2, _end_position: Vector2) -> void:
	_quick_nock_ready = _first_effect(&"post_dash_quick_shot_startup_scale") != null


func get_state_snapshot() -> Dictionary:
	var longest_mark_time := 0.0
	for entry in _marks.values():
		longest_mark_time = maxf(
			longest_mark_time,
			float((entry as Dictionary).get("remaining", 0.0))
		)
	return {
		"hunter_mark_count": _marks.size(),
		"hunter_mark_time": longest_mark_time,
		"quick_nock_ready": _quick_nock_ready,
		"clean_release_cooldown": _clean_release_timer,
		"rain_field_count": _rain_fields.size(),
		"threadline_active": _threadline_pull_active,
	}


func _activate_quick_shot(definition: AttackDefinition) -> void:
	var modifiers := _active_modifiers()
	_spawn_projectile(definition, _attack_direction(), {
		"modifiers": modifiers,
		"max_targets": definition.projectile_target_cap,
		"lifetime": _projectile_lifetime(definition.projectile_speed, definition.projectile_range),
		"event_context": _primary_event_context(definition),
	})
	var repeat := _first_effect(&"quick_shot_repeat", QUICK_SHOT)
	if repeat == null:
		return
	_scheduled_effects.append({
		"type": &"quick_repeat",
		"remaining": repeat.delay,
		"definition": definition,
		"direction": _attack_direction(),
		"damage_scale": repeat.damage_scale,
		"action_serial": _action_serial(),
	})


func _activate_power_shot(definition: AttackDefinition) -> void:
	var modifiers := _active_modifiers()
	var charge_fraction := clampf(float(controller.call("get_charge_fraction")), 0.0, 1.0)
	var maximum_damage := (
		definition.maximum_charge_damage
		+ int(modifiers.get("maximum_charge_damage_additive", 0))
	)
	maximum_damage = maxi(maximum_damage, definition.base_damage)
	var charged_damage := lerpf(
		float(definition.base_damage),
		float(maximum_damage),
		charge_fraction
	)
	_add_modifier(
		modifiers,
		"direct_damage_additive",
		charged_damage - float(definition.base_damage)
	)
	var target_cap := definition.projectile_target_cap
	if charge_fraction >= 0.999:
		target_cap += int(modifiers.get("full_charge_target_additive", 0))
	var event_context := _primary_event_context(definition)
	event_context["charge_fraction"] = charge_fraction
	event_context["hit_context"] = {"full_charge": charge_fraction >= 0.999}
	_spawn_projectile(definition, _attack_direction(), {
		"modifiers": modifiers,
		"max_targets": target_cap,
		"lifetime": _projectile_lifetime(definition.projectile_speed, definition.projectile_range),
		"event_context": event_context,
	})


func _activate_vault_shot(skill: SkillDefinition) -> void:
	if skill == null:
		return
	_vault_active = true
	_vault_direction = _attack_direction()
	for angle in skill.projectile_angles:
		_spawn_projectile(skill, _vault_direction, {
			"angle_degrees": angle,
			"speed": skill.projectile_speed,
			"max_distance": skill.projectile_range,
			"max_targets": 1,
			"lifetime": _projectile_lifetime(skill.projectile_speed, skill.projectile_range),
			"event_context": _primary_event_context(skill),
		})
	var air_control := _first_effect(&"vault_air_control_restore")
	if air_control != null and player.has_method("restore_air_control"):
		player.call("restore_air_control", air_control.value, -_vault_direction)


func _activate_rain_field(skill: SkillDefinition) -> void:
	if skill == null:
		return
	var center := _choose_rain_center(skill, _attack_direction())
	_rain_fields.append({
		"skill": skill,
		"center": center,
		"elapsed": 0.0,
		"next_strike": 0,
		"target_hits": {},
		"action_serial": _action_serial(),
		"warning": _spawn_circle_visual(
			center + Vector2(0.0, -22.0),
			skill.effect_radius,
			Color(0.35, 0.78, 1.0, 0.24)
		),
	})


func _activate_threadline(skill: SkillDefinition) -> void:
	if skill == null:
		return
	_stop_threadline_pull()
	var target := _find_threadline_target(skill.targeting_range, _attack_direction())
	if target != null:
		_pull_light_target(target, skill.pull_distance)
		_apply_mark(target, MARK_DURATION)
		_spawn_tether_visual(_player_position(), _target_position(target))
		return
	var terrain_hit := _find_threadline_terrain(skill.targeting_range, _attack_direction())
	if terrain_hit.is_empty():
		_emit_status("Threadline missed")
		return
	var anchor: Vector2 = terrain_hit.get("position", _player_position())
	var pull_vector := anchor - _player_position()
	var pull_distance := minf(pull_vector.length(), skill.pull_distance)
	if pull_distance <= 1.0:
		return
	_threadline_saved_velocity = player.get("velocity") as Vector2
	_threadline_pull_remaining = pull_distance
	_threadline_pull_velocity = (
		pull_vector.normalized() * pull_distance / maxf(skill.active_time, 0.01)
	)
	_threadline_pull_active = true
	_spawn_tether_visual(_player_position(), anchor)


func _update_marks(delta: float) -> void:
	for target_id in _marks.keys():
		var entry: Dictionary = _marks[target_id]
		var target := _weak_node(entry.get("target"))
		entry["remaining"] = float(entry.get("remaining", 0.0)) - delta
		if target == null or not _is_target_active(target) or float(entry["remaining"]) <= 0.0:
			_remove_mark_by_id(int(target_id))
		else:
			_marks[target_id] = entry


func _update_scheduled_effects(delta: float) -> void:
	for index in range(_scheduled_effects.size() - 1, -1, -1):
		var scheduled := _scheduled_effects[index]
		scheduled["remaining"] = float(scheduled.get("remaining", 0.0)) - delta
		if float(scheduled["remaining"]) > 0.0:
			_scheduled_effects[index] = scheduled
			continue
		_scheduled_effects.remove_at(index)
		match StringName(scheduled.get("type", &"")):
			&"quick_repeat":
				_execute_quick_repeat(scheduled)
			&"delayed_strike":
				_execute_delayed_strike(scheduled)


func _update_rain_fields(delta: float) -> void:
	for field_index in range(_rain_fields.size() - 1, -1, -1):
		var field := _rain_fields[field_index]
		field["elapsed"] = float(field.get("elapsed", 0.0)) + delta
		var next_strike := int(field.get("next_strike", 0))
		while (
			next_strike < RAIN_STRIKE_TIMES.size()
			and float(field["elapsed"]) + 0.0001 >= RAIN_STRIKE_TIMES[next_strike]
		):
			_execute_rain_strike(field, next_strike)
			next_strike += 1
		field["next_strike"] = next_strike
		if next_strike >= RAIN_STRIKE_TIMES.size():
			_free_node(field.get("warning") as Node)
			_rain_fields.remove_at(field_index)
		else:
			_rain_fields[field_index] = field


func _execute_quick_repeat(scheduled: Dictionary) -> void:
	var definition := scheduled.get("definition") as AttackDefinition
	if definition == null:
		return
	_spawn_projectile(definition, int(scheduled.get("direction", 1)), {
		"damage_scale": float(scheduled.get("damage_scale", 0.5)),
		"max_targets": definition.projectile_target_cap,
		"lifetime": _projectile_lifetime(definition.projectile_speed, definition.projectile_range),
		"secondary_hit": true,
		"event_context": {
			"action_serial": int(scheduled.get("action_serial", 0)),
			"verb_id": definition.id,
			"twinstring_repeat": true,
		},
	})


func _execute_delayed_strike(scheduled: Dictionary) -> void:
	var target := _weak_node(scheduled.get("target"))
	var definition := scheduled.get("definition") as AttackDefinition
	if target == null or definition == null or not _is_target_active(target):
		return
	_spawn_strike_visual(_target_position(target), Color(0.52, 0.86, 1.0, 0.9))
	_apply_runtime_hit(target, definition, {}, true, {
		"verb_id": definition.id,
		"delayed_target_strike": true,
	})


func _execute_rain_strike(field: Dictionary, strike_index: int) -> void:
	var skill := field.get("skill") as SkillDefinition
	if skill == null:
		return
	var center: Vector2 = field.get("center", Vector2.ZERO)
	var strike_position := center + Vector2(
		RAIN_STRIKE_OFFSETS[strike_index] * skill.effect_radius,
		0.0
	)
	_spawn_strike_visual(strike_position, skill.visual_color)
	var target_hits: Dictionary = field.get("target_hits", {})
	var modifiers: Dictionary = {}
	if strike_index == RAIN_STRIKE_TIMES.size() - 1:
		var storm_pattern := _first_effect(&"rain_final_arrow_bonus")
		if storm_pattern != null:
			modifiers["direct_damage_additive"] = storm_pattern.damage
			modifiers["stagger_additive"] = storm_pattern.stagger
	for target in _find_targets(strike_position, RAIN_STRIKE_RADIUS, 16):
		if _target_position(target).distance_to(center) > skill.effect_radius:
			continue
		var target_id := target.get_instance_id()
		if int(target_hits.get(target_id, 0)) >= skill.per_target_hit_cap:
			continue
		target_hits[target_id] = int(target_hits.get(target_id, 0)) + 1
		_apply_runtime_hit(target, skill, modifiers, false, {
			"action_serial": int(field.get("action_serial", 0)),
			"verb_id": skill.id,
			"rain_strike_index": strike_index,
		})
	field["target_hits"] = target_hits


func _consume_mark(target: Node) -> void:
	if not _has_mark(target):
		return
	var position := _target_position(target)
	_remove_mark(target)
	_spawn_circle_visual(position + Vector2(0.0, -22.0), MARK_BURST_RADIUS, Color(0.3, 0.86, 1.0, 0.36), 0.22)
	var burst := _secondary_definition(&"archer_hunters_mark_burst", 1, 0)
	for candidate in _find_targets(position, MARK_BURST_RADIUS, 16, [target]):
		_apply_runtime_hit(candidate, burst, {}, true, {
			"verb_id": burst.id,
			"hunter_mark_burst": true,
		})
	_transfer_consumed_mark(target, position)
	_apply_clean_release()
	_schedule_storm_mark(target)
	_emit_status("Hunter's Mark consumed")


func _transfer_consumed_mark(consumed_target: Node, origin: Vector2) -> void:
	var transfer := _first_effect(&"transfer_consumed_mark")
	if transfer == null:
		return
	for candidate in _find_targets(origin, transfer.radius, 16, [consumed_target]):
		if not _has_mark(candidate):
			_apply_mark(candidate, transfer.duration)
			return


func _apply_clean_release() -> void:
	var clean_release := _first_effect(&"mark_consume_reduce_longest_skill")
	if clean_release == null or _clean_release_timer > 0.0:
		return
	var reduced: StringName = controller.call(
		"reduce_longest_skill_cooldown",
		clean_release.seconds
	)
	if not reduced.is_empty():
		_clean_release_timer = clean_release.internal_cooldown


func _schedule_storm_mark(target: Node) -> void:
	for context in _card_contexts(&"archer_mark_consumed"):
		var card := context.get("definition") as CardDefinition
		if card == null:
			continue
		for effect in card.effects:
			if effect.effect_type != &"delayed_target_strike":
				continue
			_scheduled_effects.append({
				"type": &"delayed_strike",
				"remaining": effect.delay,
				"target": weakref(target),
				"definition": _secondary_definition(card.id, effect.damage, effect.stagger),
			})


func _trigger_split_shaft(action_serial: int, origin: Vector2) -> void:
	if _split_triggered_actions.has(action_serial):
		return
	var contexts := _card_contexts(&"archer_power_shot_terminated")
	if contexts.is_empty():
		return
	_split_triggered_actions[action_serial] = true
	for context in contexts:
		var card := context.get("definition") as CardDefinition
		if card == null:
			continue
		for effect in card.effects:
			if effect.effect_type != &"split_projectile":
				continue
			var split_arrow := _secondary_definition(card.id, effect.damage, 0)
			for projectile_index in effect.projectile_count:
				var angle := (
					-effect.angle_degrees
					if projectile_index % 2 == 0
					else effect.angle_degrees
				)
				_spawn_projectile(split_arrow, _attack_direction(), {
					"angle_degrees": angle,
					"speed": 620.0,
					"max_distance": 420.0,
					"max_targets": 1,
					"lifetime": _projectile_lifetime(620.0, 420.0),
					"origin": origin,
					"secondary_hit": true,
					"event_context": {
						"action_serial": action_serial,
						"verb_id": card.id,
						"split_projectile": true,
					},
				})


func _apply_mark(target: Node, duration: float) -> void:
	if target == null or duration <= 0.0 or not _is_target_active(target):
		return
	var target_id := target.get_instance_id()
	var existing: Dictionary = _marks.get(target_id, {})
	if not existing.is_empty():
		existing["remaining"] = duration
		_marks[target_id] = existing
		return
	_marks[target_id] = {
		"target": weakref(target),
		"remaining": duration,
		"marker": _spawn_mark_visual(target),
	}


func _remove_mark(target: Node) -> void:
	if target != null:
		_remove_mark_by_id(target.get_instance_id())


func _remove_mark_by_id(target_id: int) -> void:
	if not _marks.has(target_id):
		return
	var entry: Dictionary = _marks[target_id]
	_free_node(_weak_node(entry.get("marker")))
	_marks.erase(target_id)


func _has_mark(target: Node) -> bool:
	return target != null and _marks.has(target.get_instance_id())


func _pull_light_target(target: Node, maximum_distance: float) -> void:
	var snapshot: Dictionary = {}
	if target.has_method("get_combat_snapshot"):
		var value: Variant = target.call("get_combat_snapshot")
		if value is Dictionary:
			snapshot = value
	if not bool(snapshot.get("lightweight", false)) or not target is Node2D:
		return
	var target_2d := target as Node2D
	var delta := _player_position() - target_2d.global_position
	var distance := minf(maxf(delta.length() - 44.0, 0.0), maximum_distance)
	if distance <= 0.0:
		return
	var displacement := delta.normalized() * distance
	if target is CharacterBody2D:
		(target as CharacterBody2D).move_and_collide(displacement)
	else:
		target_2d.global_position += displacement


func _find_threadline_target(distance: float, direction: int) -> Node:
	for target in _find_targets(_player_position(), distance, 16):
		var offset := _target_position(target) - _player_position()
		if offset.x * float(direction) > 0.0 and absf(offset.y) <= 90.0:
			return target
	return null


func _find_threadline_terrain(distance: float, direction: int) -> Dictionary:
	if not player is CollisionObject2D or not player.is_inside_tree():
		return {}
	var origin := _player_position() + Vector2(0.0, -24.0)
	var destination := origin + Vector2(float(direction) * distance, 0.0)
	var query := PhysicsRayQueryParameters2D.create(
		origin,
		destination,
		3,
		[(player as CollisionObject2D).get_rid()]
	)
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_ray(query)


func _choose_rain_center(skill: SkillDefinition, direction: int) -> Vector2:
	var targeting_range := skill.targeting_range if skill.targeting_range > 0.0 else 640.0
	var fallback := _player_position() + Vector2(float(direction) * 220.0, 0.0)
	for target in _find_targets(_player_position(), targeting_range, 16):
		if (_target_position(target).x - _player_position().x) * float(direction) >= 0.0:
			return _target_position(target)
	return fallback


func _find_targets(
	origin: Vector2,
	radius: float,
	max_targets: int,
	excluded: Array[Node] = []
) -> Array[Node]:
	var value: Variant = controller.call(
		"find_targets_in_radius",
		origin,
		radius,
		max_targets,
		excluded
	)
	var targets: Array[Node] = []
	if value is Array:
		for target in value:
			if target is Node:
				targets.append(target)
	return targets


func _spawn_projectile(
	definition: AttackDefinition,
	direction: int,
	options: Dictionary
) -> PlayerAttackProjectile:
	var projectile := controller.call(
		"spawn_projectile",
		definition,
		direction,
		options
	) as PlayerAttackProjectile
	if projectile == null:
		return null
	_owned_projectiles.append(weakref(projectile))
	# Enemy bodies must not stop piercing arrows; terrain layers still terminate them.
	var default_body_handler := Callable(projectile, "_on_body_entered")
	if projectile.body_entered.is_connected(default_body_handler):
		projectile.body_entered.disconnect(default_body_handler)
	projectile.body_entered.connect(_on_archer_projectile_body_entered.bind(projectile))
	return projectile


func _on_archer_projectile_body_entered(
	body: Node,
	projectile: PlayerAttackProjectile
) -> void:
	if not body is CollisionObject2D or not is_instance_valid(projectile):
		return
	if (body as CollisionObject2D).collision_layer & 3:
		projectile.call("_terminate", &"terrain")


func _apply_runtime_hit(
	target: Node,
	definition: AttackDefinition,
	modifiers: Dictionary,
	secondary_hit: bool,
	event_context: Dictionary
) -> DamageInfo:
	return controller.call(
		"apply_runtime_hit",
		target,
		definition,
		modifiers,
		secondary_hit,
		event_context
	) as DamageInfo


func _primary_event_context(definition: AttackDefinition) -> Dictionary:
	return {
		"action_serial": _action_serial(),
		"verb_id": definition.id,
	}


func _secondary_definition(source_id: StringName, damage: int, stagger: int) -> AttackDefinition:
	var key := "%s:%d:%d" % [source_id, damage, stagger]
	if _secondary_definitions.has(key):
		return _secondary_definitions[key] as AttackDefinition
	var definition := AttackDefinition.new()
	definition.id = source_id
	definition.display_name = String(source_id).replace("_", " ").capitalize()
	definition.input_action = &"attack"
	definition.tags = [&"player_attack", &"archer", &"secondary"]
	definition.startup_time = 0.0
	definition.active_time = 0.01
	definition.recovery_time = 0.0
	definition.cooldown = 0.01
	definition.base_damage = damage
	definition.stagger = stagger
	definition.knockback = Vector2.ZERO
	definition.projectile_speed = 620.0
	definition.projectile_range = 420.0
	definition.visual_color = Color(0.52, 0.86, 1.0, 0.95)
	_secondary_definitions[key] = definition
	return definition


func _first_effect(
	effect_type: StringName,
	target_id: StringName = &""
) -> ProgressionBehaviorEffect:
	return PlayerProgressionEffectQuery.first(progression_effects, effect_type, target_id)


func _card_contexts(trigger: StringName) -> Array:
	var contexts: Variant = controller.call("get_card_contexts", trigger)
	return contexts if contexts is Array else []


func _active_modifiers() -> Dictionary:
	var value: Variant = controller.call("get_active_attack_modifiers")
	return value if value is Dictionary else {}


func _attack_direction() -> int:
	var direction := int(controller.get("attack_direction"))
	return direction if direction != 0 else 1


func _action_serial() -> int:
	return int(controller.call("get_action_serial"))


func _projectile_lifetime(speed: float, distance: float) -> float:
	return distance / maxf(speed, 1.0) + PROJECTILE_LIFETIME_MARGIN


func _decelerate_horizontal(delta: float) -> void:
	var velocity: Vector2 = player.get("velocity")
	var stats_value: Variant = player.get("stats")
	var deceleration := 2200.0
	if stats_value is Dictionary:
		deceleration = float(stats_value.get("deceleration", deceleration))
	velocity.x = move_toward(velocity.x, 0.0, deceleration * maxf(delta, 0.0))
	player.set("velocity", velocity)


func _stop_threadline_pull() -> void:
	if _threadline_pull_active and player != null:
		player.set("velocity", _threadline_saved_velocity)
	_threadline_pull_active = false
	_threadline_pull_velocity = Vector2.ZERO
	_threadline_saved_velocity = Vector2.ZERO
	_threadline_pull_remaining = 0.0


func _clear_runtime_state() -> void:
	for target_id in _marks.keys():
		_remove_mark_by_id(int(target_id))
	for field in _rain_fields:
		_free_node(field.get("warning") as Node)
	for projectile_ref in _owned_projectiles:
		_free_node(projectile_ref.get_ref() as Node)
	_marks.clear()
	_scheduled_effects.clear()
	_rain_fields.clear()
	_owned_projectiles.clear()
	_split_triggered_actions.clear()
	_secondary_definitions.clear()
	_quick_nock_ready = false
	_clean_release_timer = 0.0
	_vault_active = false
	_stop_threadline_pull()


func _prune_projectiles() -> void:
	for index in range(_owned_projectiles.size() - 1, -1, -1):
		if _owned_projectiles[index].get_ref() == null:
			_owned_projectiles.remove_at(index)


func _spawn_mark_visual(target: Node) -> WeakRef:
	if not target is Node2D or not target.is_inside_tree():
		return null
	var marker := Polygon2D.new()
	marker.name = "HunterMark"
	marker.position = Vector2(0.0, -58.0)
	marker.z_index = 24
	marker.color = Color(0.35, 0.9, 1.0, 0.92)
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 7.0),
		Vector2(-7.0, 0.0),
	])
	target.add_child(marker)
	return weakref(marker)


func _spawn_circle_visual(
	position: Vector2,
	radius: float,
	color: Color,
	lifetime: float = 0.0
) -> Node:
	var world := player.get_parent()
	if world == null:
		return null
	var visual := Polygon2D.new()
	visual.name = "ArcherArea"
	visual.z_index = 17
	visual.color = color
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points
	world.add_child(visual)
	visual.global_position = position
	if lifetime > 0.0:
		var tween := visual.create_tween()
		tween.tween_property(visual, "modulate:a", 0.0, lifetime)
		tween.finished.connect(visual.queue_free)
	return visual


func _spawn_strike_visual(position: Vector2, color: Color) -> void:
	var world := player.get_parent()
	if world == null:
		return
	var strike := Polygon2D.new()
	strike.name = "RainStrike"
	strike.z_index = 20
	strike.color = color
	strike.polygon = PackedVector2Array([
		Vector2(-3.0, -132.0),
		Vector2(3.0, -132.0),
		Vector2(3.0, -8.0),
		Vector2(9.0, -8.0),
		Vector2(0.0, 4.0),
		Vector2(-9.0, -8.0),
		Vector2(-3.0, -8.0),
	])
	world.add_child(strike)
	strike.global_position = position
	var tween := strike.create_tween()
	tween.tween_property(strike, "modulate:a", 0.0, 0.18)
	tween.finished.connect(strike.queue_free)


func _spawn_tether_visual(origin: Vector2, destination: Vector2) -> void:
	var world := player.get_parent()
	if world == null:
		return
	var tether := Line2D.new()
	tether.name = "ThreadlineTether"
	tether.z_index = 19
	tether.width = 3.0
	tether.default_color = Color(0.58, 0.9, 1.0, 0.9)
	tether.points = PackedVector2Array([origin + Vector2(0.0, -24.0), destination + Vector2(0.0, -22.0)])
	world.add_child(tether)
	var tween := tether.create_tween()
	tween.tween_property(tether, "modulate:a", 0.0, 0.24)
	tween.finished.connect(tether.queue_free)


func _target_position(target: Node) -> Vector2:
	return (target as Node2D).global_position if target is Node2D else Vector2.ZERO


func _player_position() -> Vector2:
	return (player as Node2D).global_position if player is Node2D else Vector2.ZERO


func _is_target_active(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.has_method("receive_damage"):
		return false
	var health: Variant = target.get("current_health")
	return not (health is int or health is float) or float(health) > 0.0


func _weak_node(value: Variant) -> Node:
	if value is WeakRef:
		return (value as WeakRef).get_ref() as Node
	return value as Node


func _free_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _emit_status(message: String) -> void:
	if controller.has_method("emit_status"):
		controller.call("emit_status", message)


func _add_modifier(destination: Dictionary, key: String, amount: float) -> void:
	destination[key] = float(destination.get(key, 0.0)) + amount


func _multiply_modifier(destination: Dictionary, key: String, factor: float) -> void:
	destination[key] = float(destination.get(key, 1.0)) * factor
