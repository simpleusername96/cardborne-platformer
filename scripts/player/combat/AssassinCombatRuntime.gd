class_name AssassinCombatRuntime
extends CharacterCombatRuntime

const TWIN_CUT_ID := &"assassin_twin_cut"
const SHADOW_LUNGE_ID := &"assassin_shadow_lunge"
const SMOKE_STEP_ID := &"assassin_smoke_step"
const KUNAI_FAN_ID := &"assassin_kunai_fan"
const DEATH_MARK_ID := &"assassin_death_mark"

const FLOW_MAX := 3
const FLOW_DURATION := 3.0
const FLOW_CONSUME_DAMAGE := 2.0
const TWIN_HOLD_GATE := 0.15
const TWIN_SECOND_HIT_OFFSET := 0.23
const LUNGE_DISTANCE := 150.0
const SMOKE_SLOW_DURATION := 0.6
const SMOKE_SLOW_SCALE := 0.65
const BLEED_DURATION := 2.0

const MOTION_NONE := &""
const MOTION_LUNGE := &"lunge"
const MOTION_SMOKE := &"smoke"

var _flow_stacks: int = 0
var _flow_timer: float = 0.0
var _last_primary_verb: StringName
# Reserve a consuming action before confirmation so multi-target hits cannot spend Flow twice.
var _flow_pending_action_serial: int = -1
var _flow_consumed_action_serial: int = -1
var _player_damage_serial: int = 0
var _slipstream_cooldown: float = 0.0

var _twin_elapsed: float = 0.0
var _twin_hold_valid: bool = false
var _twin_second_committed: bool = false
var _twin_second_fired: bool = false
var _twin_definition: AttackDefinition
var _twin_hit_ledgers: Dictionary = {}

var _motion_kind: StringName = MOTION_NONE
var _motion_definition: AttackDefinition
var _motion_total_distance: float = 0.0
var _motion_active_time: float = 0.0
var _motion_direction: int = 1
var _motion_travelled: float = 0.0
var _motion_last_position: Vector2 = Vector2.ZERO
var _motion_hit_wall: bool = false
var _last_motion_distance: float = 0.0
var _last_motion_hit_wall: bool = false
var _lunge_hit_targets: Dictionary = {}
var _lunge_hit_records: Array[Dictionary] = []

var _active_decoy: CombatDecoy
var _owned_projectiles: Array[Node] = []
# Activation caps and per-projectile return history are intentionally separate ledgers.
var _kunai_target_counts: Dictionary = {}
var _kunai_projectile_hits: Dictionary = {}
var _kunai_return_counts: Dictionary = {}
var _kunai_returns_spawned: int = 0

var _death_marks: Dictionary = {}
var _red_sequence_marks: Dictionary = {}


func begin_stage() -> void:
	reset()


func reset() -> void:
	_clear_flow()
	_player_damage_serial = 0
	_slipstream_cooldown = 0.0
	_clear_action_state()
	_clear_mark_dictionary(_death_marks)
	_clear_mark_dictionary(_red_sequence_marks)
	if _active_decoy != null and is_instance_valid(_active_decoy):
		_active_decoy.queue_free()
	_active_decoy = null
	for projectile in _owned_projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()
	_owned_projectiles.clear()
	_kunai_target_counts.clear()
	_kunai_projectile_hits.clear()
	_kunai_return_counts.clear()
	_kunai_returns_spawned = 0


func update(delta: float) -> void:
	_flow_timer = maxf(_flow_timer - delta, 0.0)
	if _flow_stacks > 0 and _flow_timer <= 0.0:
		_clear_flow()
	_slipstream_cooldown = maxf(_slipstream_cooldown - delta, 0.0)
	_update_twin_cut(delta)
	_update_marks(_death_marks, delta)
	_update_marks(_red_sequence_marks, delta)
	_prune_owned_projectiles()


func prepare_attack(definition: AttackDefinition, _modifiers: Dictionary) -> void:
	if definition == null:
		return
	match definition.id:
		TWIN_CUT_ID:
			_prepare_twin_cut(definition)
		SHADOW_LUNGE_ID:
			_lunge_hit_targets.clear()
			_lunge_hit_records.clear()
		SMOKE_STEP_ID:
			_last_motion_distance = 0.0
			_last_motion_hit_wall = false


func activate_attack(definition: AttackDefinition) -> bool:
	if definition == null:
		return false
	match definition.id:
		TWIN_CUT_ID:
			_activate_twin_cut(definition)
			return true
		SHADOW_LUNGE_ID:
			_activate_shadow_lunge(definition)
			return true
		SMOKE_STEP_ID:
			_activate_smoke_step(definition as SkillDefinition)
			return true
		KUNAI_FAN_ID:
			_activate_kunai_fan(definition as SkillDefinition)
			return true
		DEATH_MARK_ID:
			_activate_death_mark(definition as SkillDefinition)
			return true
	return false


func apply_movement(delta: float) -> bool:
	if _motion_kind == MOTION_NONE:
		return false
	var body := player as CharacterBody2D
	if body == null:
		return true
	_capture_motion_progress()
	if not _controller_is_active_phase() or _motion_hit_wall:
		body.velocity.x = 0.0
		return true

	if _motion_kind == MOTION_LUNGE:
		_pulse_lunge_targets()
	var remaining := maxf(_motion_total_distance - _motion_travelled, 0.0)
	if remaining <= 0.01:
		body.velocity.x = 0.0
		return true
	var speed := _motion_total_distance / maxf(_motion_active_time, 0.01)
	var distance := minf(speed * delta, remaining)
	distance = _camera_safe_distance(distance)
	var motion := Vector2(float(_motion_direction) * distance, 0.0)
	var collision := KinematicCollision2D.new()
	if body.test_move(body.global_transform, motion, collision):
		distance = minf(distance, absf(collision.get_travel().x))
		motion.x = float(_motion_direction) * distance
		_motion_hit_wall = true
	body.velocity.x = motion.x / maxf(delta, 0.0001)
	return true


func prepare_damage(
	definition: AttackDefinition,
	target: Node,
	target_state: Dictionary,
	source_modifiers: Dictionary,
	secondary_hit: bool,
	event_context: Dictionary
) -> Dictionary:
	var rear_hit := not secondary_hit and _is_rear_hit(target, target_state)
	var runtime_context := {
		"rear_hit": rear_hit,
		"hit_context": {"target_rear_arc": rear_hit},
	}
	if secondary_hit or definition == null:
		return runtime_context
	if definition.id == KUNAI_FAN_ID and not _kunai_hit_is_allowed(target, definition, event_context):
		source_modifiers["direct_damage_multiplier"] = 0.0
		runtime_context["runtime_rejected"] = true
		return runtime_context
	var action_serial := int(event_context.get("action_serial", _action_serial()))
	if (
		_flow_stacks == FLOW_MAX
		and definition.base_damage > 0
		and (definition.tags.has(&"heavy") or definition.tags.has(&"skill"))
		and action_serial != _flow_consumed_action_serial
		and action_serial != _flow_pending_action_serial
	):
		source_modifiers["direct_damage_additive"] = (
			float(source_modifiers.get("direct_damage_additive", 0.0))
			+ FLOW_CONSUME_DAMAGE
		)
		_flow_pending_action_serial = action_serial
		runtime_context["flow_should_consume"] = true
	return runtime_context


func notify_target_hit(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	var damage_info := event.get("damage_info") as DamageInfo
	var target := event.get("target") as Node
	if (
		definition == null
		or damage_info == null
		or target == null
		or damage_info.secondary_hit
		or damage_info.amount <= 0
		or bool(event.get("runtime_rejected", false))
	):
		return

	var verb := StringName(event.get("verb_id", definition.id))
	if definition.id == KUNAI_FAN_ID:
		_record_kunai_hit(target, event)
	if definition.id == SHADOW_LUNGE_ID:
		_record_lunge_hit(target, damage_info)

	if bool(event.get("flow_should_consume", false)):
		_consume_flow(target, verb, int(event.get("action_serial", _action_serial())))
	else:
		_grant_flow_for_hit(verb, bool(event.get("rear_hit", false)))
	_last_primary_verb = verb

	if definition.id == TWIN_CUT_ID and int(event.get("hit_index", 0)) == 2:
		_apply_twin_cut_bleeds(target)
	if definition.id == SHADOW_LUNGE_ID and bool(event.get("defeated", false)):
		_try_slipstream_refund()
	_advance_death_mark(target, verb)
	_advance_red_sequence(target, verb)


func notify_wall_collision() -> void:
	if _motion_kind == MOTION_NONE:
		return
	_motion_hit_wall = true
	var body := player as CharacterBody2D
	if body != null:
		body.velocity.x = 0.0


func notify_attack_finished(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	if definition == null:
		_clear_action_state()
		return
	if definition.id == SHADOW_LUNGE_ID:
		_pulse_lunge_targets()
		_capture_motion_progress()
		_last_motion_distance = _motion_travelled
		_last_motion_hit_wall = _motion_hit_wall or bool(event.get("hit_wall", false))
		if not _last_motion_hit_wall:
			_apply_afterimage_card()
	elif definition.id == SMOKE_STEP_ID:
		_capture_motion_progress()
		_last_motion_distance = _motion_travelled
		_last_motion_hit_wall = _motion_hit_wall or bool(event.get("hit_wall", false))
	_clear_action_state(false)


func notify_attack_interrupted(_event: Dictionary) -> void:
	_clear_action_state(false)


func notify_projectile_terminated(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	if definition == null or definition.id != KUNAI_FAN_ID:
		return
	var context_value: Variant = event.get("event_context", {})
	var context: Dictionary = context_value if context_value is Dictionary else {}
	if (
		StringName(event.get("reason", &"")) != &"max_range"
		or StringName(context.get("projectile_phase", &"")) != &"outbound"
	):
		return
	var activation_id := int(context.get("activation_id", -1))
	var projectile_index := int(context.get("projectile_index", -1))
	var return_count := int(_kunai_return_counts.get(activation_id, 0))
	if projectile_index < 0 or projectile_index >= return_count:
		return
	var direction := int(context.get("direction", 1))
	var angle := float(context.get("angle_degrees", 0.0))
	var return_context := context.duplicate(true)
	return_context["projectile_phase"] = &"return"
	var projectile: Variant = controller.call("spawn_projectile", definition, -direction, {
		"angle_degrees": -angle,
		"max_targets": 16,
		"origin": event.get("position", Vector2.ZERO),
		"event_context": return_context,
	})
	if projectile is Node:
		_own_kunai_projectile(projectile)
		_kunai_returns_spawned += 1


func notify_player_damaged(resolved_damage: int) -> void:
	if resolved_damage > 0:
		_player_damage_serial += 1


func get_state_snapshot() -> Dictionary:
	var decoy_time := (
		_active_decoy.get_remaining_time()
		if _active_decoy != null and is_instance_valid(_active_decoy)
		else 0.0
	)
	return {
		"flow_stacks": _flow_stacks,
		"flow_time": _flow_timer,
		"death_mark_count": _death_marks.size(),
		"red_sequence_mark_count": _red_sequence_marks.size(),
		"decoy_time": decoy_time,
		"slipstream_cooldown": _slipstream_cooldown,
		"flow_last_verb": String(_last_primary_verb),
		"death_marks": _mark_snapshots(_death_marks, true),
		"red_sequence_marks": _mark_snapshots(_red_sequence_marks, false),
		"player_damage_serial": _player_damage_serial,
		"twin_second_committed": _twin_second_committed,
		"twin_second_fired": _twin_second_fired,
		"twin_hit_counts": {
			"1": _ledger_size(1),
			"2": _ledger_size(2),
		},
		"motion_kind": String(_motion_kind),
		"motion_distance": _motion_travelled if _motion_kind != MOTION_NONE else _last_motion_distance,
		"motion_hit_wall": _motion_hit_wall if _motion_kind != MOTION_NONE else _last_motion_hit_wall,
		"kunai_returns_spawned": _kunai_returns_spawned,
		"owned_projectiles": _valid_owned_projectile_count(),
	}


func _prepare_twin_cut(definition: AttackDefinition) -> void:
	_twin_definition = definition
	_twin_elapsed = 0.0
	_twin_hold_valid = false
	_twin_second_committed = false
	_twin_second_fired = false
	_twin_hit_ledgers = {1: {}, 2: {}}


func _activate_twin_cut(definition: AttackDefinition) -> void:
	_twin_definition = definition
	_twin_hold_valid = Input.is_action_pressed("attack")
	_pulse_melee(definition, 1)


func _update_twin_cut(delta: float) -> void:
	if _twin_definition == null or _current_attack_id() != TWIN_CUT_ID:
		return
	if not _controller_is_active_phase():
		return
	_twin_elapsed += delta
	if not _twin_second_committed and _twin_elapsed <= TWIN_HOLD_GATE:
		_twin_hold_valid = _twin_hold_valid and Input.is_action_pressed("attack")
	if not _twin_second_committed and _twin_elapsed >= TWIN_HOLD_GATE:
		_twin_second_committed = _twin_hold_valid and Input.is_action_pressed("attack")
	if (
		_twin_second_committed
		and not _twin_second_fired
		and _twin_elapsed >= TWIN_SECOND_HIT_OFFSET
	):
		_twin_second_fired = true
		_pulse_melee(_twin_definition, 2)


func _pulse_melee(definition: AttackDefinition, hit_index: int) -> void:
	var body := player as Node2D
	if body == null:
		return
	var direction := _attack_direction()
	var center := body.global_position + Vector2(
		absf(definition.hitbox_offset.x) * float(direction),
		definition.hitbox_offset.y
	)
	var ledger: Dictionary = _twin_hit_ledgers.get(hit_index, {})
	var targets: Variant = controller.call(
		"find_targets_in_box",
		center,
		definition.hitbox_size * 0.5 + Vector2(0.0, 28.0),
		16
	)
	if not targets is Array:
		return
	for target_value in targets:
		var target := target_value as Node
		if target == null:
			continue
		var key := _target_key(target)
		if ledger.has(key):
			continue
		ledger[key] = true
		controller.call("apply_runtime_hit", target, definition, _active_modifiers(), false, {
			"action_serial": _action_serial(),
			"verb_id": definition.id,
			"attack_direction": direction,
			"hit_index": hit_index,
		})
	_twin_hit_ledgers[hit_index] = ledger


func _activate_shadow_lunge(definition: AttackDefinition) -> void:
	var distance := LUNGE_DISTANCE
	for effect in PlayerProgressionEffectQuery.matching(
		progression_effects,
		&"shadow_lunge_distance",
		SHADOW_LUNGE_ID
	):
		distance += effect.distance_delta
	_begin_motion(MOTION_LUNGE, definition, maxf(distance, 0.0), definition.active_time)
	_pulse_lunge_targets()


func _pulse_lunge_targets() -> void:
	if _motion_kind != MOTION_LUNGE or _motion_definition == null:
		return
	var body := player as Node2D
	if body == null:
		return
	var center := body.global_position + Vector2(
		absf(_motion_definition.hitbox_offset.x) * float(_motion_direction),
		_motion_definition.hitbox_offset.y
	)
	var targets: Variant = controller.call(
		"find_targets_in_box",
		center,
		_motion_definition.hitbox_size * 0.5 + Vector2(0.0, 28.0),
		16
	)
	if not targets is Array:
		return
	for target_value in targets:
		var target := target_value as Node
		if target == null:
			continue
		var key := _target_key(target)
		if _lunge_hit_targets.has(key):
			continue
		_lunge_hit_targets[key] = true
		controller.call("apply_runtime_hit", target, _motion_definition, _active_modifiers(), false, {
			"action_serial": _action_serial(),
			"verb_id": _motion_definition.id,
			"attack_direction": _motion_direction,
			"lunge_path_hit": true,
		})
		var snapshot: Variant = target.call("get_combat_snapshot") if target.has_method("get_combat_snapshot") else {}
		if snapshot is Dictionary and not bool(snapshot.get("lightweight", false)):
			_motion_hit_wall = true


func _record_lunge_hit(target: Node, damage_info: DamageInfo) -> void:
	for record in _lunge_hit_records:
		if record.get("target") == target:
			return
	_lunge_hit_records.append({
		"target": target,
		"damage": damage_info.amount,
		"stagger": damage_info.stagger,
	})


func _activate_smoke_step(skill: SkillDefinition) -> void:
	if skill == null:
		return
	_begin_motion(MOTION_SMOKE, skill, skill.movement_distance, skill.active_time)
	if player.has_method("grant_invulnerability"):
		player.call("grant_invulnerability", skill.invulnerability_time)
	_spawn_decoy(skill)


func _spawn_decoy(skill: SkillDefinition) -> void:
	if _active_decoy != null and is_instance_valid(_active_decoy):
		_active_decoy.queue_free()
	var parent := player.get_parent()
	if parent == null:
		return
	var duration := skill.decoy_duration
	var duration_effect := PlayerProgressionEffectQuery.first(progression_effects, &"smoke_duration")
	if duration_effect != null:
		duration = duration_effect.value
	var decoy := CombatDecoy.new()
	decoy.name = "AssassinSmokeDecoy"
	decoy.duration = duration
	if PlayerProgressionEffectQuery.has(progression_effects, &"smoke_slow"):
		decoy.slow_duration = SMOKE_SLOW_DURATION
		decoy.slow_scale = SMOKE_SLOW_SCALE
	parent.add_child(decoy)
	decoy.global_position = (player as Node2D).global_position
	_active_decoy = decoy


func _activate_kunai_fan(skill: SkillDefinition) -> void:
	if skill == null:
		return
	var activation_id := _action_serial()
	_kunai_target_counts[activation_id] = {}
	var return_effect := PlayerProgressionEffectQuery.first(progression_effects, &"kunai_return_count")
	_kunai_return_counts[activation_id] = (
		clampi(roundi(return_effect.value), 0, skill.projectile_count)
		if return_effect != null
		else 0
	)
	var direction := _attack_direction()
	for projectile_index in skill.projectile_count:
		var angle := float(skill.projectile_angles[projectile_index])
		var event_context := {
			"action_serial": activation_id,
			"verb_id": skill.id,
			"assassin_projectile": true,
			"activation_id": activation_id,
			"projectile_index": projectile_index,
			"projectile_phase": &"outbound",
			"direction": direction,
			"angle_degrees": angle,
		}
		var projectile: Variant = controller.call("spawn_projectile", skill, direction, {
			"angle_degrees": angle,
			"max_targets": 16,
			"event_context": event_context,
		})
		if projectile is Node:
			_own_kunai_projectile(projectile)


func _own_kunai_projectile(projectile: Node) -> void:
	_owned_projectiles.append(projectile)
	var shot := projectile as PlayerAttackProjectile
	if shot == null:
		return
	# Enemy bodies share layer 8 with hurtboxes; only layer 1/2 bodies terminate Kunai.
	var default_body_callback := Callable(shot, "_on_body_entered")
	if shot.body_entered.is_connected(default_body_callback):
		shot.body_entered.disconnect(default_body_callback)
	shot.body_entered.connect(_on_kunai_body_entered.bind(shot))


func _on_kunai_body_entered(body: Node, projectile: PlayerAttackProjectile) -> void:
	if not body is CollisionObject2D or projectile == null or not is_instance_valid(projectile):
		return
	if ((body as CollisionObject2D).collision_layer & 3) != 0:
		projectile.call("_terminate", &"terrain")


func _kunai_hit_is_allowed(
	target: Node,
	definition: AttackDefinition,
	event_context: Dictionary
) -> bool:
	if not bool(event_context.get("assassin_projectile", false)):
		return true
	var activation_id := int(event_context.get("activation_id", -1))
	var target_key := _target_key(target)
	var counts: Dictionary = _kunai_target_counts.get(activation_id, {})
	var cap := (definition as SkillDefinition).per_target_hit_cap if definition is SkillDefinition else 3
	if int(counts.get(target_key, 0)) >= cap:
		return false
	var projectile_key := _projectile_key(
		activation_id,
		int(event_context.get("projectile_index", -1))
	)
	var projectile_hits: Dictionary = _kunai_projectile_hits.get(projectile_key, {})
	return not (
		StringName(event_context.get("projectile_phase", &"")) == &"return"
		and projectile_hits.has(target_key)
	)


func _record_kunai_hit(target: Node, event: Dictionary) -> void:
	var activation_id := int(event.get("activation_id", -1))
	if activation_id < 0:
		return
	var target_key := _target_key(target)
	var counts: Dictionary = _kunai_target_counts.get(activation_id, {})
	counts[target_key] = int(counts.get(target_key, 0)) + 1
	_kunai_target_counts[activation_id] = counts
	var projectile_key := _projectile_key(activation_id, int(event.get("projectile_index", -1)))
	var projectile_hits: Dictionary = _kunai_projectile_hits.get(projectile_key, {})
	projectile_hits[target_key] = true
	_kunai_projectile_hits[projectile_key] = projectile_hits


func _activate_death_mark(skill: SkillDefinition) -> void:
	if skill == null:
		return
	var body := player as Node2D
	if body == null:
		return
	var direction := _attack_direction()
	var targets: Variant = controller.call(
		"find_targets_in_radius",
		body.global_position,
		skill.targeting_range,
		16
	)
	if not targets is Array:
		return
	for target_value in targets:
		var target := target_value as Node2D
		if target == null:
			continue
		if (target.global_position.x - body.global_position.x) * float(direction) < 0.0:
			continue
		_arm_death_mark(target, skill)
		controller.call("emit_status", "Death Mark applied")
		return


func _arm_death_mark(target: Node, skill: SkillDefinition) -> void:
	var key := _target_key(target)
	_remove_mark(_death_marks, key)
	_death_marks[key] = {
		"target": target,
		"remaining": skill.status_duration,
		"required_verbs": skill.required_distinct_verbs,
		"verbs": {},
		"damage_serial": _player_damage_serial,
		"visual": _attach_marker(
			target,
			"AssassinDeathMark",
			Color(0.94, 0.18, 0.42, 0.9),
			-62.0
		),
	}


func _advance_death_mark(target: Node, verb: StringName) -> void:
	var key := _target_key(target)
	if not _death_marks.has(key):
		return
	var entry: Dictionary = _death_marks[key]
	var verbs: Dictionary = entry.get("verbs", {})
	verbs[String(verb)] = true
	entry["verbs"] = verbs
	_death_marks[key] = entry
	if verbs.size() < int(entry.get("required_verbs", 3)):
		return
	var damage_serial := int(entry.get("damage_serial", -1))
	_remove_mark(_death_marks, key)
	if _target_is_active(target):
		_apply_fixed_hit(target, &"assassin_death_mark_detonation", 4, 40, [&"player_attack", &"skill", &"mark_detonation", &"secondary"])
	if (
		damage_serial == _player_damage_serial
		and PlayerProgressionEffectQuery.has(
			progression_effects,
			&"no_damage_death_mark_resets_smoke_step"
		)
	):
		controller.call("reset_cooldown", SMOKE_STEP_ID)
	controller.call("emit_status", "Death Mark detonated")


func _grant_flow_for_hit(verb: StringName, rear_hit: bool) -> void:
	var grants := 0
	if _last_primary_verb.is_empty() or verb != _last_primary_verb:
		grants += 1
	if rear_hit:
		var opportunist := PlayerProgressionEffectQuery.first(
			progression_effects,
			&"back_hit_flow_stack"
		)
		if opportunist != null:
			grants += maxi(roundi(opportunist.value), 0)
	if grants <= 0:
		return
	_flow_stacks = mini(_flow_stacks + grants, FLOW_MAX)
	_flow_timer = FLOW_DURATION
	controller.call("emit_status", "Flow %d/%d" % [_flow_stacks, FLOW_MAX])


func _consume_flow(target: Node, verb: StringName, action_serial: int) -> void:
	_flow_stacks = 0
	_flow_timer = 0.0
	_flow_pending_action_serial = -1
	_flow_consumed_action_serial = action_serial
	_apply_red_sequence_card(target, verb)
	controller.call("emit_status", "Flow consumed")


func _apply_red_sequence_card(target: Node, verb: StringName) -> void:
	if not _target_is_active(target):
		return
	var contexts: Variant = controller.call("get_card_contexts", &"assassin_flow_consumed")
	if not contexts is Array:
		return
	for context_value in contexts:
		if not context_value is Dictionary:
			continue
		var card := context_value.get("definition") as CardDefinition
		if card == null:
			continue
		for effect in card.effects:
			if effect.effect_type != &"detonation_mark":
				continue
			var key := _target_key(target)
			_remove_mark(_red_sequence_marks, key)
			_red_sequence_marks[key] = {
				"target": target,
				"remaining": effect.duration,
				"source_verb": verb,
				"damage": effect.damage,
				"radius": effect.distance,
				"source_id": card.id,
				"visual": _attach_marker(
					target,
					"AssassinRedSequenceMark",
					Color(1.0, 0.56, 0.16, 0.88),
					-76.0
				),
			}
			return


func _advance_red_sequence(target: Node, verb: StringName) -> void:
	var key := _target_key(target)
	if not _red_sequence_marks.has(key):
		return
	var entry: Dictionary = _red_sequence_marks[key]
	if StringName(entry.get("source_verb", &"")) == verb:
		return
	var origin := (target as Node2D).global_position if target is Node2D else Vector2.ZERO
	var damage := int(entry.get("damage", 3))
	var radius := float(entry.get("radius", 90.0))
	var source_id := StringName(entry.get("source_id", &"assassin_red_sequence"))
	_remove_mark(_red_sequence_marks, key)
	var targets: Variant = controller.call("find_targets_in_radius", origin, radius, 16)
	if targets is Array:
		for candidate_value in targets:
			var candidate := candidate_value as Node
			if _target_is_active(candidate):
				_apply_fixed_hit(candidate, source_id, damage, 0, [&"player_card", &"area", &"secondary"])
	controller.call("emit_status", "Red Sequence detonated")


func _apply_afterimage_card() -> void:
	if _lunge_hit_records.is_empty():
		return
	var contexts: Variant = controller.call("get_card_contexts", &"assassin_shadow_lunge_completed")
	if not contexts is Array:
		return
	for context_value in contexts:
		if not context_value is Dictionary:
			continue
		var card := context_value.get("definition") as CardDefinition
		if card == null:
			continue
		for effect in card.effects:
			if effect.effect_type != &"repeat_attack_path":
				continue
			for record in _lunge_hit_records:
				var target := record.get("target") as Node
				if not _target_is_active(target):
					continue
				var damage := maxi(
					int(floor(float(record.get("damage", 0)) * effect.damage_scale + 0.5)),
					1
				)
				_apply_fixed_hit(target, card.id, damage, 0, [&"player_card", &"afterimage", &"secondary"])
			controller.call("emit_status", "Afterimage repeated")
			return


func _apply_twin_cut_bleeds(target: Node) -> void:
	if not target.has_method("apply_delayed_damage"):
		return
	for effect in PlayerProgressionEffectQuery.matching(
		progression_effects,
		&"twin_cut_second_bleed",
		TWIN_CUT_ID
	):
		target.call(
			"apply_delayed_damage",
			effect.source_id,
			effect.duration if effect.duration > 0.0 else BLEED_DURATION,
			effect.damage,
			player
		)


func _try_slipstream_refund() -> void:
	if _slipstream_cooldown > 0.0 or not player.has_method("refund_dash_charge"):
		return
	var effect := PlayerProgressionEffectQuery.first(
		progression_effects,
		&"lunge_kill_refund_dash"
	)
	if effect == null:
		return
	var refunded := int(player.call("refund_dash_charge", 1))
	if refunded > 0:
		_slipstream_cooldown = effect.internal_cooldown


func _begin_motion(
	kind: StringName,
	definition: AttackDefinition,
	distance: float,
	active_time: float
) -> void:
	_motion_kind = kind
	_motion_definition = definition
	_motion_total_distance = distance
	_motion_active_time = active_time
	_motion_direction = _attack_direction()
	_motion_travelled = 0.0
	_motion_last_position = (player as Node2D).global_position
	_motion_hit_wall = false
	_last_motion_distance = 0.0
	_last_motion_hit_wall = false


func _capture_motion_progress() -> void:
	var body := player as Node2D
	if body == null or _motion_kind == MOTION_NONE:
		return
	_motion_travelled += absf(body.global_position.x - _motion_last_position.x)
	_motion_last_position = body.global_position


func _camera_safe_distance(distance: float) -> float:
	var body := player as Node2D
	if body == null:
		return 0.0
	var camera := body.get_node_or_null("Camera2D") as Camera2D
	if camera == null or camera.limit_right <= camera.limit_left:
		return distance
	if float(camera.limit_right - camera.limit_left) > 1000000.0:
		return distance
	var desired_x := body.global_position.x + float(_motion_direction) * distance
	var clamped_x := clampf(
		desired_x,
		float(camera.limit_left) + 16.0,
		float(camera.limit_right) - 16.0
	)
	if not is_equal_approx(desired_x, clamped_x):
		_motion_hit_wall = true
	return absf(clamped_x - body.global_position.x)


func _is_rear_hit(target: Node, target_state: Dictionary) -> bool:
	if not target is Node2D or not player is Node2D:
		return false
	var target_facing := int(target_state.get("facing_direction", 0))
	if target_facing == 0:
		return false
	var source_delta := (player as Node2D).global_position.x - (target as Node2D).global_position.x
	return absf(source_delta) > 0.5 and int(sign(source_delta)) == -target_facing


func _apply_fixed_hit(
	target: Node,
	source_id: StringName,
	damage: int,
	stagger: int,
	tags: Array[StringName]
) -> void:
	if not _target_is_active(target):
		return
	var definition := AttackDefinition.new()
	definition.id = source_id
	definition.display_name = String(source_id).replace("_", " ").capitalize()
	definition.input_action = &"runtime_secondary"
	definition.tags = tags
	definition.startup_time = 0.0
	definition.active_time = 0.01
	definition.recovery_time = 0.0
	definition.cooldown = 0.01
	definition.base_damage = damage
	definition.stagger = stagger
	definition.knockback = Vector2.ZERO
	definition.hitbox_size = Vector2.ONE
	definition.hitbox_offset = Vector2.ZERO
	controller.call("apply_runtime_hit", target, definition, {}, true, {
		"action_serial": _action_serial(),
		"verb_id": source_id,
		"runtime_secondary": true,
	})


func _attach_marker(
	target: Node,
	marker_name: String,
	color: Color,
	y_offset: float
) -> Polygon2D:
	if not target is Node2D:
		return null
	var existing := target.get_node_or_null(marker_name)
	if existing != null:
		existing.queue_free()
	var marker := Polygon2D.new()
	marker.name = marker_name
	marker.position = Vector2(0.0, y_offset)
	marker.z_index = 16
	marker.color = color
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 8.0),
		Vector2(-8.0, 0.0),
	])
	target.add_child(marker)
	return marker


func _update_marks(marks: Dictionary, delta: float) -> void:
	for key in marks.keys():
		var entry: Dictionary = marks[key]
		var target := entry.get("target") as Node
		if target == null or not is_instance_valid(target):
			_remove_mark(marks, key)
			continue
		entry["remaining"] = maxf(float(entry.get("remaining", 0.0)) - delta, 0.0)
		if float(entry["remaining"]) <= 0.0 or not _target_is_active(target):
			_remove_mark(marks, key)
			continue
		marks[key] = entry


func _remove_mark(marks: Dictionary, key: Variant) -> void:
	if not marks.has(key):
		return
	var entry: Dictionary = marks[key]
	var visual := entry.get("visual") as Node
	if visual != null and is_instance_valid(visual):
		visual.queue_free()
	marks.erase(key)


func _clear_mark_dictionary(marks: Dictionary) -> void:
	for key in marks.keys():
		_remove_mark(marks, key)


func _mark_snapshots(marks: Dictionary, include_verbs: bool) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var keys := marks.keys()
	keys.sort()
	for key in keys:
		var entry: Dictionary = marks[key]
		var snapshot := {
			"target_instance_id": key,
			"remaining": float(entry.get("remaining", 0.0)),
		}
		if include_verbs:
			snapshot["distinct_verbs"] = (entry.get("verbs", {}) as Dictionary).size()
			snapshot["required_verbs"] = int(entry.get("required_verbs", 0))
		snapshots.append(snapshot)
	return snapshots


func _clear_flow() -> void:
	_flow_stacks = 0
	_flow_timer = 0.0
	_last_primary_verb = &""
	_flow_pending_action_serial = -1
	_flow_consumed_action_serial = -1


func _clear_action_state(clear_records: bool = true) -> void:
	var body := player as CharacterBody2D
	if body != null and _motion_kind != MOTION_NONE:
		body.velocity.x = 0.0
	_twin_definition = null
	_twin_elapsed = 0.0
	_twin_hold_valid = false
	_motion_kind = MOTION_NONE
	_motion_definition = null
	_motion_total_distance = 0.0
	_motion_active_time = 0.0
	_motion_travelled = 0.0
	_motion_hit_wall = false
	_lunge_hit_targets.clear()
	if clear_records:
		_twin_second_committed = false
		_twin_second_fired = false
		_twin_hit_ledgers.clear()
		_lunge_hit_records.clear()


func _prune_owned_projectiles() -> void:
	var active: Array[Node] = []
	for projectile in _owned_projectiles:
		if projectile != null and is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			active.append(projectile)
	_owned_projectiles = active


func _valid_owned_projectile_count() -> int:
	var count := 0
	for projectile in _owned_projectiles:
		if projectile != null and is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			count += 1
	return count


func _target_is_active(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.has_method("receive_damage"):
		return false
	var health: Variant = target.get("current_health")
	return not (health is int or health is float) or float(health) > 0.0


func _target_key(target: Node) -> String:
	return String.num_int64(target.get_instance_id()) if target != null else ""


func _projectile_key(activation_id: int, projectile_index: int) -> String:
	return "%d:%d" % [activation_id, projectile_index]


func _ledger_size(hit_index: int) -> int:
	var ledger_value: Variant = _twin_hit_ledgers.get(hit_index, {})
	return (ledger_value as Dictionary).size() if ledger_value is Dictionary else 0


func _action_serial() -> int:
	return int(controller.call("get_action_serial")) if controller != null else 0


func _attack_direction() -> int:
	return int(controller.get("attack_direction")) if controller != null else 1


func _current_attack_id() -> StringName:
	var definition := controller.get("current_attack") as AttackDefinition if controller != null else null
	return definition.id if definition != null else &""


func _controller_is_active_phase() -> bool:
	return (
		controller != null
		and int(controller.get("phase")) == PlayerCombatController.Phase.ACTIVE
	)


func _active_modifiers() -> Dictionary:
	if controller == null:
		return {}
	var value: Variant = controller.call("get_active_attack_modifiers")
	return value if value is Dictionary else {}
