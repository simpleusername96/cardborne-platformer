extends SceneTree

const CATALOG := preload("res://data/items/field_pickup_catalog.tres")
const FIELD_PICKUP_SCENE := preload("res://scenes/stages/components/FieldPickup.tscn")

class CooldownTarget:
	extends Node

	var recovered_seconds: float = 0.0


	func apply_skill_cooldown_recovery(seconds: float) -> Dictionary:
		recovered_seconds += seconds
		return {
			"skill_ids": [&"fixture_short", &"fixture_long"],
			"skill_count": 2,
			"max_seconds": 0.4,
			"total_seconds": 0.65,
		}


var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_run_state != null, "field pickup fixture needs RunState")
	_expect(CATALOG.validate_catalog().is_empty(), "field pickup catalog should validate")
	if _run_state == null:
		_finish()
		return
	_validate_healing_and_retry()
	_validate_consumable_refill()
	_validate_cooldown_recovery()
	_validate_currency_and_replay()
	await _validate_actor_lifecycle()
	_finish()


func _validate_healing_and_retry() -> void:
	_expect(_run_state.start_new_run(0, 912), "healing fixture run should start")
	var vital := CATALOG.get_definition(&"vital_shard")
	var full_result: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(not bool(full_result.get("applied", false)), "full-health pickup should remain available")
	_run_state.damage_player(2)
	var health_before: int = _run_state.current_health
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(bool(result.get("applied", false)), "healing pickup should apply after damage")
	_expect(_run_state.current_health == health_before + 1, "healing pickup should restore one health")
	var duplicate: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(bool(duplicate.get("duplicate", false)), "healing pickup should settle exactly once")


func _validate_consumable_refill() -> void:
	_run_state.consumable_charges = 0
	var supply := CATALOG.get_definition(&"supply_charge")
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_supply", supply)
	_expect(bool(result.get("applied", false)), "supply pickup should refill an empty charge")
	_expect(_run_state.consumable_charges == 1, "supply pickup should respect one-charge cap")
	var capped: Dictionary = _run_state.apply_field_pickup(&"fixture_supply_full", supply)
	_expect(not bool(capped.get("applied", false)), "full consumable should not consume another supply pickup")


func _validate_cooldown_recovery() -> void:
	var target := CooldownTarget.new()
	root.add_child(target)
	var focus := CATALOG.get_definition(&"focus_shard")
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_focus", focus, target)
	_expect(bool(result.get("applied", false)), "focus pickup should recover active skill cooldowns")
	_expect(is_equal_approx(target.recovered_seconds, 1.25), "focus pickup should use catalog value")
	_expect(is_equal_approx(float(result.get("amount", 0.0)), 0.4), "focus receipt should use the largest applied recovery")
	_expect(int(result.get("affected_skill_count", 0)) == 2, "focus receipt should count affected skills")
	_expect(is_equal_approx(float(result.get("total_recovered_seconds", 0.0)), 0.65), "focus receipt should retain total recovery")
	target.queue_free()


func _validate_currency_and_replay() -> void:
	var coins_before: int = _run_state.coins
	var coin_bundle := CATALOG.get_definition(&"coin_bundle")
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_coins", coin_bundle)
	_expect(bool(result.get("applied", false)), "coin pickup should apply")
	_expect(_run_state.coins == coins_before + 3, "coin pickup should use RewardTransaction ownership")
	var duplicate: Dictionary = _run_state.apply_field_pickup(&"fixture_coins", coin_bundle)
	_expect(bool(duplicate.get("duplicate", false)), "coin pickup should reject replay")
	_expect(_run_state.coins == coins_before + 3, "replayed coin pickup must not grant twice")


func _validate_actor_lifecycle() -> void:
	_expect(_run_state.start_new_run(0, 913), "pickup actor fixture run should start")
	_run_state.damage_player(2)
	var health_before: int = _run_state.current_health
	var pickup := FIELD_PICKUP_SCENE.instantiate() as FieldPickup
	pickup.pickup_id = &"fixture_actor_vital"
	pickup.definition = CATALOG.get_definition(&"vital_shard")
	root.add_child(pickup)
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)
	var receipts: Array[Dictionary] = []
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	var receipt_handler := func(receipt: Dictionary) -> void: receipts.append(receipt)
	signal_bus.field_pickup_collected.connect(receipt_handler)
	pickup.call("_on_body_entered", player)
	pickup.call("_on_body_entered", player)
	await process_frame
	_expect(_run_state.current_health == health_before + 1, "pickup actor should apply its effect")
	_expect(receipts.size() == 1, "pickup actor should publish one collection receipt")
	await create_timer(0.25).timeout
	_expect(not is_instance_valid(pickup), "collected pickup actor should remove itself")
	if signal_bus.field_pickup_collected.is_connected(receipt_handler):
		signal_bus.field_pickup_collected.disconnect(receipt_handler)
	player.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FIELD_PICKUP_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
