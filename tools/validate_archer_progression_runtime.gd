extends SceneTree

const KIT := preload("res://data/characters/archer_kit.tres")
const SPLIT_SHAFT := preload("res://data/cards/archer_split_shaft.tres")
const STORM_MARK := preload("res://data/cards/archer_storm_mark.tres")
const FIELD_BOW := preload("res://data/equipment/items/field_bow.tres")
const TWINSTRING_BOW := preload("res://data/equipment/items/twinstring_bow.tres")
const QUICK_NOCK := preload("res://data/mastery/nodes/archer_quick_nock.tres")
const PIERCING_DRAW := preload("res://data/mastery/nodes/archer_piercing_draw.tres")
const SHARED_MARK := preload("res://data/mastery/nodes/archer_shared_mark.tres")
const AIRBORNE_HUNTER := preload("res://data/mastery/nodes/archer_airborne_hunter.tres")
const STORM_PATTERN := preload("res://data/mastery/nodes/archer_storm_pattern.tres")
const CLEAN_RELEASE := preload("res://data/mastery/nodes/archer_clean_release.tres")

class FakePlayer:
	extends Node2D

	var velocity := Vector2.ZERO
	var stats := {"deceleration": 2200.0, "move_speed": 230.0}
	var grounded := false
	var dash_charges_left := 0
	var extra_jumps_left := 0
	var air_control_calls: Array[Dictionary] = []


	func is_on_floor() -> bool:
		return grounded


	func restore_air_control(fraction: float, direction: int) -> void:
		air_control_calls.append({"fraction": fraction, "direction": direction})


class FakeTarget:
	extends Node2D

	var current_health := 40
	var lightweight := true
	var received: Array[DamageInfo] = []


	func receive_damage(info: DamageInfo) -> void:
		received.append(info)
		current_health = maxi(current_health - info.amount, 0)


	func get_combat_snapshot() -> Dictionary:
		return {
			"mitigation": 0.0,
			"lightweight": lightweight,
			"staggered": false,
		}


class FakeController:
	extends Node

	var runtime: ArcherCombatRuntime
	var attack_direction := 1
	var phase := PlayerCombatController.Phase.ACTIVE
	var current_attack: AttackDefinition
	var active_modifiers: Dictionary = {}
	var charge_fraction := 0.0
	var action_serial := 1
	var targets: Array[Node] = []
	var card_contexts: Dictionary = {}
	var spawn_calls: Array[Dictionary] = []
	var cooldown_reduction_count := 0
	var cooldown_reduction_seconds := 0.0
	var longest_skill_id: StringName = &"archer_threadline"


	func get_charge_fraction() -> float:
		return charge_fraction


	func get_action_serial() -> int:
		return action_serial


	func get_active_attack_modifiers() -> Dictionary:
		return active_modifiers.duplicate(true)


	func spawn_projectile(
		definition: AttackDefinition,
		direction: int,
		options: Dictionary
	) -> PlayerAttackProjectile:
		spawn_calls.append({
			"definition": definition,
			"direction": direction,
			"options": options.duplicate(true),
		})
		return null


	func apply_runtime_hit(
		target: Node,
		definition: AttackDefinition,
		modifiers: Dictionary = {},
		secondary_hit: bool = false,
		event_context: Dictionary = {}
	) -> DamageInfo:
		var target_state := target.call("get_combat_snapshot") as Dictionary
		var hit_context := {
			"secondary_hit": secondary_hit,
			"attack_direction": attack_direction,
			"source_position": Vector2.ZERO,
			"action_serial": int(event_context.get("action_serial", action_serial)),
			"verb_id": String(event_context.get("verb_id", definition.id)),
		}
		if event_context.get("hit_context") is Dictionary:
			hit_context.merge(event_context["hit_context"], true)
		var source_modifiers := {
			"direct_damage_multiplier": float(modifiers.get("direct_damage_multiplier", 1.0)),
			"direct_damage_additive": float(modifiers.get("direct_damage_additive", 0.0)),
			"stagger_additive": float(modifiers.get("stagger_additive", 0.0)),
		}
		var runtime_context := runtime.prepare_damage(
			definition,
			target,
			target_state,
			source_modifiers,
			secondary_hit,
			event_context
		)
		if runtime_context.get("hit_context") is Dictionary:
			hit_context.merge(runtime_context["hit_context"], true)
		var result := DamageResolver.resolve_attack(
			definition,
			target_state,
			hit_context,
			source_modifiers
		)
		var info := DamageInfo.new(
			result.final_damage,
			self,
			result.knockback,
			result.tags,
			definition.id,
			result.stagger,
			result.critical,
			secondary_hit
		)
		target.call("receive_damage", info)
		var event := {
			"definition": definition,
			"target": target,
			"target_state": target_state,
			"damage_info": info,
			"action_serial": int(event_context.get("action_serial", action_serial)),
			"verb_id": StringName(event_context.get("verb_id", definition.id)),
			"defeated": int(target.get("current_health")) <= 0,
		}
		event.merge(runtime_context, true)
		event.merge(event_context, true)
		runtime.notify_target_hit(event)
		return info


	func find_targets_in_radius(
		origin: Vector2,
		radius: float,
		max_targets: int = 16,
		excluded: Array[Node] = []
	) -> Array[Node]:
		var matches: Array[Dictionary] = []
		for target in targets:
			if excluded.has(target) or not is_instance_valid(target):
				continue
			if int(target.get("current_health")) <= 0:
				continue
			var distance := origin.distance_squared_to((target as Node2D).global_position)
			if distance <= radius * radius:
				matches.append({"target": target, "distance": distance})
		matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["distance"]) < float(b["distance"])
		)
		var result: Array[Node] = []
		for entry in matches.slice(0, mini(matches.size(), max_targets)):
			result.append(entry["target"] as Node)
		return result


	func get_card_contexts(trigger: StringName) -> Array:
		return card_contexts.get(trigger, [])


	func reduce_longest_skill_cooldown(seconds: float) -> StringName:
		if longest_skill_id.is_empty():
			return &""
		cooldown_reduction_count += 1
		cooldown_reduction_seconds = seconds
		return longest_skill_id


	func emit_status(_message: String) -> void:
		pass


var _failures: Array[String] = []
var _fixtures: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_equipment_behaviors()
	_validate_mastery_behaviors()
	_validate_rain_cap_and_threadline()
	_validate_cards_and_cleanup()
	for fixture in _fixtures:
		var world := fixture.get("world") as Node
		if world != null:
			world.queue_free()
	await process_frame
	_finish()


func _validate_equipment_behaviors() -> void:
	var baseline := _fixture(FIELD_BOW.behavior_effects)
	var base_runtime := baseline["runtime"] as ArcherCombatRuntime
	var base_controller := baseline["controller"] as FakeController
	var quick := KIT.basic_attack as AttackDefinition
	base_controller.current_attack = quick
	base_runtime.activate_attack(quick)
	base_runtime.update(0.20)
	_expect(base_controller.spawn_calls.size() == 1, "Field Bow should leave Quick Shot as one projectile")
	var power := KIT.heavy_attack as AttackDefinition
	var base_modifiers: Dictionary = {}
	base_runtime.prepare_attack(power, base_modifiers)
	base_controller.active_modifiers = base_modifiers
	base_controller.charge_fraction = 1.0
	base_controller.current_attack = power
	base_runtime.activate_attack(power)
	var base_power_options: Dictionary = base_controller.spawn_calls[-1]["options"]
	_expect(is_equal_approx(float(base_power_options["modifiers"]["direct_damage_additive"]), 2.0), "Field Bow should retain 4-damage maximum Power Shot")

	var twin := _fixture(TWINSTRING_BOW.behavior_effects)
	var twin_runtime := twin["runtime"] as ArcherCombatRuntime
	var twin_controller := twin["controller"] as FakeController
	twin_controller.current_attack = quick
	twin_runtime.activate_attack(quick)
	twin_runtime.update(0.15)
	_expect(twin_controller.spawn_calls.size() == 1, "Twinstring repeat should wait 0.16 seconds")
	twin_runtime.update(0.02)
	_expect(twin_controller.spawn_calls.size() == 2, "Twinstring should repeat Quick Shot after 0.16 seconds")
	if twin_controller.spawn_calls.size() == 2:
		var repeat_options: Dictionary = twin_controller.spawn_calls[1]["options"]
		_expect(bool(repeat_options.get("secondary_hit", false)), "Twinstring repeat should be secondary and nonrecursive")
		_expect(is_equal_approx(float(repeat_options.get("damage_scale", 0.0)), 0.5), "Twinstring repeat should use 50 percent damage")
	var twin_modifiers: Dictionary = {}
	twin_runtime.prepare_attack(power, twin_modifiers)
	twin_controller.active_modifiers = twin_modifiers
	twin_controller.charge_fraction = 1.0
	twin_controller.current_attack = power
	twin_runtime.activate_attack(power)
	var twin_power_options: Dictionary = twin_controller.spawn_calls[-1]["options"]
	_expect(is_equal_approx(float(twin_power_options["modifiers"]["direct_damage_additive"]), 1.0), "Twinstring should lower maximum Power Shot damage from 4 to 3")


func _validate_mastery_behaviors() -> void:
	var fixture := _fixture(_all_mastery_effects())
	var runtime := fixture["runtime"] as ArcherCombatRuntime
	var controller := fixture["controller"] as FakeController
	var player := fixture["player"] as FakePlayer
	var quick := KIT.basic_attack as AttackDefinition
	var power := KIT.heavy_attack as AttackDefinition
	var vault := KIT.get_skill_by_slot(1)

	runtime.notify_dash_completed(Vector2.ZERO, Vector2(80.0, 0.0))
	var quick_modifiers: Dictionary = {}
	runtime.prepare_attack(quick, quick_modifiers)
	_expect(is_equal_approx(float(quick_modifiers.get("startup_time_scale", 1.0)), 0.75), "Quick Nock should make the next Quick Shot startup 25 percent faster")
	_expect(not bool(runtime.get_state_snapshot()["quick_nock_ready"]), "Quick Nock should be consumed by one Quick Shot")

	var power_modifiers: Dictionary = {}
	runtime.prepare_attack(power, power_modifiers)
	controller.active_modifiers = power_modifiers
	controller.charge_fraction = 1.0
	controller.current_attack = power
	runtime.activate_attack(power)
	var power_options: Dictionary = controller.spawn_calls[-1]["options"]
	_expect(int(power_options.get("max_targets", 0)) == 3, "Piercing Draw should add one full-charge Power Shot target")

	player.grounded = false
	controller.current_attack = vault
	var calls_before := controller.spawn_calls.size()
	runtime.activate_attack(vault)
	_expect(controller.spawn_calls.size() == calls_before + 3, "Vault Shot should create exactly three authored projectiles")
	_expect(player.air_control_calls.size() == 1, "Airborne Hunter should restore air control once")
	if not player.air_control_calls.is_empty():
		_expect(is_equal_approx(float(player.air_control_calls[0]["fraction"]), 0.25), "Airborne Hunter should restore 25 percent air control")

	var rain_target := _target(fixture, Vector2(100.0, 100.0))
	var rain := KIT.get_skill_by_slot(2)
	var final_center := rain_target.global_position - Vector2(0.08 * rain.effect_radius, 0.0)
	var field := {
		"skill": rain,
		"center": final_center,
		"target_hits": {},
		"action_serial": 9,
	}
	runtime.call("_execute_rain_strike", field, 5)
	_expect(not rain_target.received.is_empty(), "Storm Pattern fixture should land the final Rain strike")
	if not rain_target.received.is_empty():
		var final_hit := rain_target.received[-1]
		_expect(final_hit.amount == 2 and final_hit.stagger == 30, "Storm Pattern should add 1 damage and 30 stagger to the final strike")

	var mark_fixture := _fixture(_all_mastery_effects())
	var mark_runtime := mark_fixture["runtime"] as ArcherCombatRuntime
	var mark_controller := mark_fixture["controller"] as FakeController
	var marked_target := _target(mark_fixture, Vector2(300.0, 100.0))
	var transfer_target := _target(mark_fixture, Vector2(370.0, 100.0))
	mark_controller.apply_runtime_hit(marked_target, vault, {}, false, {"action_serial": 10})
	var marked_power := mark_controller.apply_runtime_hit(
		marked_target,
		power,
		{"direct_damage_additive": 2.0},
		false,
		{"action_serial": 11, "charge_fraction": 1.0, "hit_context": {"full_charge": true}}
	)
	_expect(marked_power.critical and marked_power.amount == 6, "Marked full-charge Power Shot should resolve as a 6-damage earned critical")
	_expect(not transfer_target.received.is_empty() and transfer_target.received[0].amount == 1, "Mark consumption should create a 1-damage 90-pixel secondary burst")
	var snapshot := mark_runtime.get_state_snapshot()
	_expect(int(snapshot["hunter_mark_count"]) >= 1, "Shared Mark should transfer a mark to a nearby unmarked target")
	_expect(is_equal_approx(float(snapshot["hunter_mark_time"]), 3.0), "Shared Mark should last 3 seconds")
	_expect(mark_controller.cooldown_reduction_count == 1, "Clean Release should reduce one active skill cooldown")
	_expect(is_equal_approx(mark_controller.cooldown_reduction_seconds, 1.0), "Clean Release should reduce that cooldown by 1 second")
	_expect(is_equal_approx(float(snapshot["clean_release_cooldown"]), 4.0), "Clean Release should start a 4-second internal cooldown")

	mark_runtime.call("_apply_mark", marked_target, 6.0)
	mark_controller.apply_runtime_hit(
		marked_target,
		power,
		{"direct_damage_additive": 2.0},
		false,
		{"action_serial": 12, "charge_fraction": 1.0, "hit_context": {"full_charge": true}}
	)
	_expect(mark_controller.cooldown_reduction_count == 1, "Clean Release should not retrigger during its internal cooldown")
	mark_runtime.update(4.0)
	mark_runtime.call("_apply_mark", marked_target, 6.0)
	mark_controller.apply_runtime_hit(
		marked_target,
		power,
		{"direct_damage_additive": 2.0},
		false,
		{"action_serial": 13, "charge_fraction": 1.0, "hit_context": {"full_charge": true}}
	)
	_expect(mark_controller.cooldown_reduction_count == 2, "Clean Release should rearm after 4 seconds")


func _validate_rain_cap_and_threadline() -> void:
	var rain_fixture := _fixture([])
	var rain_runtime := rain_fixture["runtime"] as ArcherCombatRuntime
	var rain_target := _target(rain_fixture, Vector2.ZERO)
	var rain := KIT.get_skill_by_slot(2)
	var field := {
		"skill": rain,
		"center": Vector2(200.0, 100.0),
		"target_hits": {},
		"action_serial": 20,
	}
	var offsets := [-0.72, 0.35, -0.18, 0.72]
	for strike_index in 4:
		rain_target.global_position = Vector2(200.0 + offsets[strike_index] * rain.effect_radius, 100.0)
		rain_runtime.call("_execute_rain_strike", field, strike_index)
	_expect(rain_target.received.size() == 3, "Rain Field should enforce its activation-wide three-hit target cap")

	var tether_fixture := _fixture([])
	var tether_runtime := tether_fixture["runtime"] as ArcherCombatRuntime
	var tether_controller := tether_fixture["controller"] as FakeController
	var tether_player := tether_fixture["player"] as FakePlayer
	var tether_target := _target(tether_fixture, Vector2(220.0, 0.0))
	var threadline := KIT.get_skill_by_slot(3)
	tether_controller.current_attack = threadline
	tether_runtime.activate_attack(threadline)
	_expect(tether_target.global_position.x <= 70.0, "Threadline should pull a light enemy by up to 160 pixels")
	_expect(int(tether_runtime.get_state_snapshot()["hunter_mark_count"]) == 1, "Threadline enemy contact should mark its target")
	_expect(tether_player.dash_charges_left == 0 and tether_player.extra_jumps_left == 0, "Threadline should never refresh jump or dash resources")


func _validate_cards_and_cleanup() -> void:
	var split_fixture := _fixture([], {
		&"archer_power_shot_terminated": [{"definition": SPLIT_SHAFT, "stack": 1}],
	})
	var split_runtime := split_fixture["runtime"] as ArcherCombatRuntime
	var split_controller := split_fixture["controller"] as FakeController
	var power := KIT.heavy_attack as AttackDefinition
	split_runtime.notify_projectile_terminated({
		"definition": power,
		"reason": &"max_range",
		"position": Vector2(500.0, 100.0),
		"action_serial": 30,
	})
	_expect(split_controller.spawn_calls.size() == 2, "Split Shaft should spawn exactly two arrows at maximum range")
	if split_controller.spawn_calls.size() == 2:
		var first_options: Dictionary = split_controller.spawn_calls[0]["options"]
		var second_options: Dictionary = split_controller.spawn_calls[1]["options"]
		_expect(is_equal_approx(float(first_options["angle_degrees"]), -18.0), "First split arrow should use -18 degrees")
		_expect(is_equal_approx(float(second_options["angle_degrees"]), 18.0), "Second split arrow should use +18 degrees")
		_expect(bool(first_options["secondary_hit"]) and bool(second_options["secondary_hit"]), "Split arrows should be secondary and nonrecursive")
	split_runtime.notify_projectile_terminated({
		"definition": power,
		"reason": &"max_range",
		"position": Vector2(500.0, 100.0),
		"action_serial": 30,
	})
	_expect(split_controller.spawn_calls.size() == 2, "Split Shaft should trigger only once per Power Shot")
	var split_target := _target(split_fixture, Vector2(300.0, 100.0))
	split_runtime.notify_target_hit({
		"definition": power,
		"target": split_target,
		"damage_info": DamageInfo.new(2, split_controller, Vector2.ZERO, ["player_attack"], power.id),
		"action_serial": 31,
	})
	_expect(split_controller.spawn_calls.size() == 4, "Split Shaft should also trigger on a Power Shot hit")

	var storm_fixture := _fixture([], {
		&"archer_mark_consumed": [{"definition": STORM_MARK, "stack": 1}],
	})
	var storm_runtime := storm_fixture["runtime"] as ArcherCombatRuntime
	var storm_controller := storm_fixture["controller"] as FakeController
	var storm_target := _target(storm_fixture, Vector2(180.0, 100.0))
	var vault := KIT.get_skill_by_slot(1)
	storm_controller.apply_runtime_hit(storm_target, vault, {}, false, {"action_serial": 40})
	storm_controller.apply_runtime_hit(
		storm_target,
		power,
		{"direct_damage_additive": 2.0},
		false,
		{"action_serial": 41, "charge_fraction": 1.0, "hit_context": {"full_charge": true}}
	)
	var health_before_delay := storm_target.current_health
	storm_runtime.update(0.34)
	_expect(storm_target.current_health == health_before_delay, "Storm Mark should wait the full 0.35-second delay")
	storm_runtime.update(0.02)
	_expect(storm_target.current_health == health_before_delay - 2, "Storm Mark should deal exactly 2 delayed damage")
	_expect(storm_target.received[-1].secondary_hit, "Storm Mark damage should be secondary and nonrecursive")

	storm_runtime.call("_apply_mark", storm_target, 6.0)
	storm_controller.apply_runtime_hit(
		storm_target,
		power,
		{"direct_damage_additive": 2.0},
		false,
		{"action_serial": 42, "charge_fraction": 1.0, "hit_context": {"full_charge": true}}
	)
	var health_before_reset := storm_target.current_health
	storm_runtime.reset()
	storm_runtime.update(0.5)
	var snapshot := storm_runtime.get_state_snapshot()
	_expect(storm_target.current_health == health_before_reset, "Runtime reset should cancel delayed Archer card damage")
	_expect(int(snapshot["hunter_mark_count"]) == 0, "Runtime reset should clear every Hunter's Mark")
	_expect(int(snapshot["rain_field_count"]) == 0, "Runtime reset should clear every Rain field")
	_expect(not bool(snapshot["threadline_active"]), "Runtime reset should stop Threadline")
	for key in snapshot:
		var value: Variant = snapshot[key]
		_expect(value is bool or value is int or value is float, "Archer snapshot '%s' should remain a scalar HUD value" % key)


func _fixture(
	effects: Array,
	card_contexts: Dictionary = {}
) -> Dictionary:
	var world := Node2D.new()
	world.name = "ArcherProgressionFixture%d" % _fixtures.size()
	root.add_child(world)
	var player := FakePlayer.new()
	world.add_child(player)
	var controller := FakeController.new()
	world.add_child(controller)
	var runtime := ArcherCombatRuntime.new()
	controller.runtime = runtime
	controller.card_contexts = card_contexts.duplicate(true)
	var typed_effects: Array[ProgressionBehaviorEffect] = []
	for value in effects:
		var effect := value as ProgressionBehaviorEffect
		if effect != null:
			typed_effects.append(effect)
	runtime.configure(controller, player, KIT, typed_effects)
	runtime.begin_stage()
	var fixture := {
		"world": world,
		"player": player,
		"controller": controller,
		"runtime": runtime,
	}
	_fixtures.append(fixture)
	return fixture


func _target(fixture: Dictionary, position: Vector2) -> FakeTarget:
	var target := FakeTarget.new()
	target.global_position = position
	(fixture["world"] as Node).add_child(target)
	(fixture["controller"] as FakeController).targets.append(target)
	return target


func _all_mastery_effects() -> Array:
	var effects: Array = []
	for node in [
		QUICK_NOCK,
		PIERCING_DRAW,
		SHARED_MARK,
		AIRBORNE_HUNTER,
		STORM_PATTERN,
		CLEAN_RELEASE,
	]:
		effects.append_array(node.behavior_effects)
	return effects


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ARCHER_PROGRESSION_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
