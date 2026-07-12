class_name PlayerCardRuntime
extends Node

# Interprets generic card triggers/effects so shared player code never branches on card IDs.

@export var player_path: NodePath = NodePath("..")
@export var combat_controller_path: NodePath = NodePath("../CombatController")

@onready var player: Variant = get_node(player_path)
@onready var combat_controller: Variant = get_node(combat_controller_path)

var _aerial_attack_ready: bool = false
var _internal_cooldowns: Dictionary = {}
var _next_heavy_timer: float = 0.0
var _next_heavy_startup_scale: float = 1.0
var _next_heavy_uninterruptible: bool = false
var _stage_index: int = -1
var _positive_damage_serial: int = 0
var _last_required_clear_damage_serial: int = 0
var _required_room_damage_baselines: Dictionary = {}
var _cleared_required_rooms: Dictionary = {}
var _resolved_action_triggers: Dictionary = {}
var _last_stand_used: bool = false


func _ready() -> void:
	player.extra_jump_performed.connect(_on_extra_jump_performed)
	player.dash_completed.connect(_on_dash_completed)
	SignalBus.required_room_encounter_started.connect(_on_required_room_encounter_started)
	SignalBus.required_room_encounter_cleared.connect(_on_required_room_encounter_cleared)


func _exit_tree() -> void:
	if SignalBus.required_room_encounter_started.is_connected(_on_required_room_encounter_started):
		SignalBus.required_room_encounter_started.disconnect(_on_required_room_encounter_started)
	if SignalBus.required_room_encounter_cleared.is_connected(_on_required_room_encounter_cleared):
		SignalBus.required_room_encounter_cleared.disconnect(_on_required_room_encounter_cleared)


func begin_stage() -> void:
	_stage_index = RunState.current_stage_index
	_positive_damage_serial = 0
	_last_required_clear_damage_serial = 0
	_required_room_damage_baselines.clear()
	_cleared_required_rooms.clear()
	_resolved_action_triggers.clear()
	_last_stand_used = false
	_internal_cooldowns.clear()
	reset_transient_state()


func reset_transient_state() -> void:
	_aerial_attack_ready = false
	_internal_cooldowns.clear()
	_clear_next_heavy()


func _process(delta: float) -> void:
	_next_heavy_timer = maxf(_next_heavy_timer - delta, 0.0)
	if _next_heavy_timer <= 0.0:
		_clear_next_heavy()
	for card_id in _internal_cooldowns.keys():
		var remaining := maxf(float(_internal_cooldowns[card_id]) - delta, 0.0)
		if remaining <= 0.0:
			_internal_cooldowns.erase(card_id)
		else:
			_internal_cooldowns[card_id] = remaining


func prepare_attack(definition: AttackDefinition) -> Dictionary:
	var modifiers: Dictionary = {}
	if _aerial_attack_ready and definition.base_damage > 0:
		var contexts := _card_contexts(&"first_attack_after_extra_jump")
		for context in contexts:
			_apply_modifier_effects(context, modifiers)
		if not contexts.is_empty():
			_emit_status("Aerial Opener ready")
		_aerial_attack_ready = false
	if _next_heavy_timer > 0.0 and definition.tags.has(&"heavy"):
		modifiers["startup_time_scale"] = _next_heavy_startup_scale
		modifiers["uninterruptible_startup"] = _next_heavy_uninterruptible
		_clear_next_heavy()
	return modifiers


func notify_attack_activated(definition: AttackDefinition, context: Dictionary) -> void:
	if definition == null or not definition.tags.has(&"heavy"):
		return
	if not bool(context.get("supported_ground", false)):
		return
	for card_context in _card_contexts(&"heavy_ground_impact"):
		var card := card_context.get("definition") as CardDefinition
		if card == null or not _is_card_ready(card):
			continue
		for effect in card.effects:
			if effect.effect_type == &"ground_shockwave":
				combat_controller.spawn_secondary_shockwave(
					effect.damage,
					effect.stagger,
					effect.distance,
					effect.duration,
					card.id
				)
		if card.internal_cooldown > 0.0:
			_internal_cooldowns[String(card.id)] = card.internal_cooldown


func notify_guard_consumed() -> void:
	for context in _card_contexts(&"guard_consumed"):
		var card := context.get("definition") as CardDefinition
		if card == null or not _is_card_ready(card):
			continue
		for effect in card.effects:
			if effect.effect_type != &"arm_next_heavy":
				continue
			_next_heavy_timer = maxf(_next_heavy_timer, effect.duration)
			_next_heavy_startup_scale = minf(
				_next_heavy_startup_scale,
				effect.startup_scale
			)
			_next_heavy_uninterruptible = (
				_next_heavy_uninterruptible or effect.uninterruptible_startup
			)
		if card.internal_cooldown > 0.0:
			_internal_cooldowns[String(card.id)] = card.internal_cooldown


func get_state_snapshot() -> Dictionary:
	return {
		"next_heavy_time": _next_heavy_timer,
		"next_heavy_startup_scale": _next_heavy_startup_scale,
		"next_heavy_uninterruptible": _next_heavy_uninterruptible,
		"internal_cooldowns": _internal_cooldowns.duplicate(true),
		"stage_index": _stage_index,
		"positive_damage_serial": _positive_damage_serial,
		"required_room_damage_baselines": _required_room_damage_baselines.duplicate(true),
		"cleared_required_rooms": _sorted_keys(_cleared_required_rooms),
		"resolved_action_trigger_count": _resolved_action_triggers.size(),
		"last_stand_used": _last_stand_used,
	}


func notify_attack_completed(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	if (
		definition == null
		or StringName(event.get("reason", &"completed")) != &"completed"
		or int(event.get("target_count", 0)) < 2
		or not (definition.tags.has(&"heavy") or definition.tags.has(&"skill"))
	):
		return
	var action_serial := int(event.get("action_serial", 0))
	for context in _card_contexts(&"heavy_or_skill_multi_target_completed"):
		var card := context.get("definition") as CardDefinition
		if card == null:
			continue
		var action_key := "%s:%d" % [card.id, action_serial]
		if action_serial > 0 and _resolved_action_triggers.has(action_key):
			continue
		if action_serial > 0:
			_resolved_action_triggers[action_key] = true
		if not _is_card_ready(card):
			continue
		for effect in card.effects:
			if effect.effect_type == &"reduce_all_skill_cooldowns":
				combat_controller.reduce_all_skill_cooldowns(effect.seconds)
		if card.internal_cooldown > 0.0:
			_internal_cooldowns[String(card.id)] = card.internal_cooldown
		_emit_status("%s reduced active skill cooldowns" % card.display_name)


func notify_player_health_damage(event: Dictionary) -> void:
	var amount := int(event.get("amount", 0))
	var previous_health := int(event.get("previous_health", 0))
	var current_health := int(event.get("current_health", previous_health))
	if amount <= 0 or current_health >= previous_health:
		return
	_positive_damage_serial += 1
	if current_health != 1 or previous_health <= 1 or _last_stand_used:
		return
	for context in _card_contexts(&"damage_left_one_health"):
		var card := context.get("definition") as CardDefinition
		if card == null:
			continue
		_last_stand_used = true
		for effect in card.effects:
			match effect.effect_type:
				&"grant_invulnerability":
					player.grant_invulnerability(effect.seconds)
				&"reset_skill_slot":
					combat_controller.reset_skill_slot(effect.skill_slot)
		_emit_status("%s triggered" % card.display_name)
		break


func prepare_target_hit(
	_definition: AttackDefinition,
	target_state: Dictionary
) -> Dictionary:
	var modifiers: Dictionary = {}
	var activations: Array[StringName] = []
	if not bool(target_state.get("recovery", false)):
		return {"modifiers": modifiers, "activations": activations}
	for context in _card_contexts(&"hit_target_in_recovery"):
		var card := context.get("definition") as CardDefinition
		if card == null or not _is_card_ready(card):
			continue
		_apply_modifier_effects(context, modifiers)
		activations.append(card.id)
	return {"modifiers": modifiers, "activations": activations}


func notify_attack_hit(event: Dictionary) -> void:
	var definition := event.get("definition") as AttackDefinition
	var damage_info := event.get("damage_info") as DamageInfo
	if definition == null or damage_info == null or damage_info.secondary_hit:
		return
	var activations: Array[StringName] = []
	for activation_id in event.get("activations", []):
		activations.append(StringName(activation_id))
	for trigger in [
		&"heavy_hit_confirmed",
		&"hit_target_in_recovery",
		&"skill_kill",
	]:
		for context in _card_contexts(trigger):
			var card := context.get("definition") as CardDefinition
			if card == null or not _event_matches(card, definition, event, activations):
				continue
			if not _is_card_ready(card):
				continue
			_apply_confirmed_effects(card, int(context.get("stack", 1)), event)
			if card.internal_cooldown > 0.0:
				_internal_cooldowns[String(card.id)] = card.internal_cooldown


func _apply_modifier_effects(context: Dictionary, modifiers: Dictionary) -> void:
	var card := context.get("definition") as CardDefinition
	if card == null:
		return
	var stack := int(context.get("stack", 1))
	for effect in card.effects:
		match effect.effect_type:
			&"add_damage":
				_add_modifier(modifiers, "direct_damage_additive", effect.damage * stack)
			&"add_stagger":
				_add_modifier(modifiers, "stagger_additive", effect.stagger * stack)


func _apply_confirmed_effects(
	card: CardDefinition,
	stack: int,
	event: Dictionary
) -> void:
	for effect in card.effects:
		match effect.effect_type:
			&"repeat_hit":
				_schedule_repeat_hit(card, effect, event)
			&"reduce_longest_skill_cooldown":
				combat_controller.reduce_longest_skill_cooldown(effect.seconds)
			&"area_damage":
				_apply_area_damage(card, effect, stack, event)


func _event_matches(
	card: CardDefinition,
	definition: AttackDefinition,
	event: Dictionary,
	activations: Array[StringName]
) -> bool:
	match card.trigger:
		&"heavy_hit_confirmed":
			return definition.tags.has(&"heavy")
		&"hit_target_in_recovery":
			return activations.has(card.id) and bool(
				event.get("target_state", {}).get("recovery", false)
			)
		&"skill_kill":
			return definition.tags.has(&"skill") and bool(event.get("defeated", false))
	return false


func _schedule_repeat_hit(
	card: CardDefinition,
	effect: CardEffectDefinition,
	event: Dictionary
) -> void:
	var target := event.get("target") as Node
	var original := event.get("damage_info") as DamageInfo
	if target == null or original == null:
		return
	await get_tree().create_timer(effect.delay).timeout
	if not _is_target_active(target):
		return
	var damage := maxi(int(floor(float(original.amount) * effect.damage_scale + 0.5)), 1)
	var stagger := maxi(int(floor(float(original.stagger) * effect.stagger_scale + 0.5)), 0)
	target.call("receive_damage", DamageInfo.new(
		damage,
		player,
		original.knockback * 0.35,
		["player_card", "echo", "secondary"],
		card.id,
		stagger,
		false,
		true
	))
	_emit_status("%s echoed for %d" % [card.display_name, damage])


func _apply_area_damage(
	card: CardDefinition,
	effect: CardEffectDefinition,
	stack: int,
	event: Dictionary
) -> void:
	var target := event.get("target") as Node2D
	if target == null:
		return
	var radius_index := clampi(stack - 1, 0, effect.radius_by_stack.size() - 1)
	var radius := effect.radius_by_stack[radius_index]
	_spawn_pulse_visual(target.global_position, radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("receive_damage"):
			continue
		if effect.exclude_primary_target and candidate == target:
			continue
		if (candidate as Node2D).global_position.distance_to(target.global_position) > radius:
			continue
		if not _is_target_active(candidate):
			continue
		candidate.call("receive_damage", DamageInfo.new(
			effect.damage,
			player,
			Vector2.ZERO,
			["player_card", "area", "secondary"],
			card.id,
			0,
			false,
			true
		))
	_emit_status("%s burst" % card.display_name)


func _on_extra_jump_performed() -> void:
	if not _card_contexts(&"first_attack_after_extra_jump").is_empty():
		_aerial_attack_ready = true


func _on_dash_completed(start_position: Vector2, end_position: Vector2) -> void:
	for context in _card_contexts(&"dash_completed"):
		var card := context.get("definition") as CardDefinition
		var stack := int(context.get("stack", 1))
		if card == null or not _is_card_ready(card):
			continue
		for effect in card.effects:
			if effect.effect_type == &"spawn_damage_trail":
				_spawn_dash_trail(card, effect, stack, start_position, end_position)
		if card.internal_cooldown > 0.0:
			_internal_cooldowns[String(card.id)] = card.internal_cooldown


func _on_required_room_encounter_started(context: Dictionary) -> void:
	if not _matches_current_stage(context):
		return
	var room_id := String(context.get("room_id", "")).strip_edges()
	if room_id.is_empty() or _cleared_required_rooms.has(room_id):
		return
	if not _required_room_damage_baselines.has(room_id):
		_required_room_damage_baselines[room_id] = _positive_damage_serial


func _on_required_room_encounter_cleared(context: Dictionary) -> void:
	if not _matches_current_stage(context):
		return
	var room_id := String(context.get("room_id", "")).strip_edges()
	if room_id.is_empty() or _cleared_required_rooms.has(room_id):
		return
	var damage_baseline := int(_required_room_damage_baselines.get(
		room_id,
		_last_required_clear_damage_serial
	))
	var cleared_without_damage := damage_baseline == _positive_damage_serial
	_cleared_required_rooms[room_id] = true
	_required_room_damage_baselines.erase(room_id)
	_last_required_clear_damage_serial = _positive_damage_serial
	if not cleared_without_damage:
		return
	for card_context in _card_contexts(&"required_room_encounter_cleared_without_damage"):
		var card := card_context.get("definition") as CardDefinition
		if card == null:
			continue
		for effect in card.effects:
			if effect.effect_type == &"heal_player":
				player.heal_player(effect.health)
		_emit_status("%s restored health" % card.display_name)
		break


func _spawn_dash_trail(
	card: CardDefinition,
	effect: CardEffectDefinition,
	stack: int,
	start_position: Vector2,
	end_position: Vector2
) -> void:
	var world := player.get_parent() as Node
	if world == null:
		return
	var stack_index := clampi(stack - 1, 0, effect.damage_by_stack.size() - 1)
	var damage := effect.damage_by_stack[stack_index]
	var width := maxf(absf(end_position.x - start_position.x) + 42.0, 56.0)
	var trail := Hitbox.new()
	trail.name = "%sTrail" % card.display_name.replace(" ", "")
	trail.collision_layer = 16
	trail.collision_mask = 8
	trail.starts_active = true
	trail.repeat_hits = false
	trail.tags = ["player_card", "dash_trail", "secondary"]
	trail.set_damage_info_provider(func(_area: Area2D) -> DamageInfo:
		return DamageInfo.new(
			damage,
			player,
			Vector2.ZERO,
			trail.tags,
			card.id,
			0,
			false,
			true
		)
	)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 44.0)
	shape.shape = rectangle
	trail.add_child(shape)
	var visual := Polygon2D.new()
	visual.color = Color(0.22, 0.86, 0.9, 0.35)
	visual.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -22.0),
		Vector2(width * 0.5, -22.0),
		Vector2(width * 0.5, 22.0),
		Vector2(-width * 0.5, 22.0),
	])
	trail.add_child(visual)
	world.add_child(trail)
	trail.global_position = (start_position + end_position) * 0.5 + Vector2(0.0, -22.0)
	get_tree().create_timer(effect.duration).timeout.connect(trail.queue_free)


func _spawn_pulse_visual(position: Vector2, radius: float) -> void:
	var world := player.get_parent() as Node
	if world == null:
		return
	var pulse := Polygon2D.new()
	pulse.name = "CardBurst"
	pulse.z_index = 18
	pulse.color = Color(1.0, 0.72, 0.18, 0.42)
	var points := PackedVector2Array()
	for index in 20:
		var angle := TAU * float(index) / 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	pulse.polygon = points
	world.add_child(pulse)
	pulse.global_position = position + Vector2(0.0, -22.0)
	var tween := pulse.create_tween()
	tween.tween_property(pulse, "modulate:a", 0.0, 0.22)
	tween.finished.connect(pulse.queue_free)


func _add_modifier(modifiers: Dictionary, key: String, amount: float) -> void:
	modifiers[key] = float(modifiers.get(key, 0.0)) + amount


func _clear_next_heavy() -> void:
	_next_heavy_timer = 0.0
	_next_heavy_startup_scale = 1.0
	_next_heavy_uninterruptible = false


func _matches_current_stage(context: Dictionary) -> bool:
	return int(context.get("stage_index", _stage_index)) == _stage_index


func _sorted_keys(source: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in source:
		keys.append(String(key))
	keys.sort()
	return keys


func _card_contexts(trigger: StringName) -> Array:
	if not is_inside_tree():
		return []
	var run_state := get_node_or_null("/root/RunState")
	if run_state == null or not run_state.has_method("get_card_effect_contexts"):
		return []
	var contexts: Variant = run_state.call("get_card_effect_contexts", trigger)
	return contexts if contexts is Array else []


func _is_card_ready(card: CardDefinition) -> bool:
	return float(_internal_cooldowns.get(String(card.id), 0.0)) <= 0.0


func _is_target_active(target: Node) -> bool:
	if not is_instance_valid(target) or not target.has_method("receive_damage"):
		return false
	var health: Variant = target.get("current_health")
	return not (health is int or health is float) or float(health) > 0.0


func _emit_status(message: String) -> void:
	if not is_inside_tree():
		return
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.emit_signal("status_message_changed", message)
