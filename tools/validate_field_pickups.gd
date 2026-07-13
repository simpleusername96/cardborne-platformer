extends SceneTree

const CATALOG := preload("res://data/items/field_pickup_catalog.tres")

class CooldownTarget:
	extends Node

	var recovered_seconds: float = 0.0


	func apply_skill_cooldown_recovery(seconds: float) -> Array[StringName]:
		recovered_seconds += seconds
		return [&"fixture_skill"]


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
