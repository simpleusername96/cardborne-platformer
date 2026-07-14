extends SceneTree

const ShieldRuntime = preload("res://scripts/player/ShieldCombatRuntime.gd")

var _failures: PackedStringArray = []


func _initialize() -> void:
	_validate_round_shield_flow()
	_validate_attack_matrix()
	_validate_guard_break_and_recovery()
	_validate_worn_shield()
	if _failures.is_empty():
		print("SHIELD_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_round_shield_flow() -> void:
	var runtime: Variant = _runtime()
	runtime.update(0.04, true)
	_expect(runtime.get_state_snapshot()["phase"] == &"startup", "Guard needs startup.")
	var early: Variant = runtime.resolve_attack(_normal_attack(), Vector2.RIGHT)
	_expect(not early.blocked and early.reason == &"guard_startup", "Startup cannot block.")
	runtime.update(0.04, true)
	_expect(runtime.get_state_snapshot()["phase"] == &"active", "Guard should activate.")
	var precise: Variant = runtime.resolve_attack(_normal_attack(), Vector2.RIGHT)
	_expect(precise.blocked and precise.precise, "Initial active window should be precise.")
	_expect(precise.condition_cost == 0, "Precise guard must not cost condition.")
	runtime.update(0.15, true)
	var normal: Variant = runtime.resolve_attack(_normal_attack(), Vector2.RIGHT)
	_expect(normal.blocked and not normal.precise, "Held guard should block normally.")
	_expect(normal.condition_cost == 1, "Normal round-shield block costs one condition.")


func _validate_attack_matrix() -> void:
	var runtime: Variant = _active_runtime()
	var heavy: Variant = runtime.resolve_attack(_heavy_attack(), Vector2.RIGHT)
	_expect(heavy.blocked and heavy.condition_cost == 3, "Heavy block cost is incorrect.")
	var side: Variant = runtime.resolve_attack(
		_normal_attack().merged({"source_direction": Vector2.DOWN}, true),
		Vector2.RIGHT
	)
	_expect(not side.blocked and side.reason == &"outside_guard_angle", "Side hit was blocked.")
	var unblockable: Variant = runtime.resolve_attack(
		_normal_attack().merged({"unblockable": true}, true),
		Vector2.RIGHT
	)
	_expect(not unblockable.blocked and unblockable.reason == &"unblockable", "Unblockable hit was blocked.")


func _validate_guard_break_and_recovery() -> void:
	var runtime: Variant = _active_runtime()
	var result: Variant = runtime.resolve_attack(
		_normal_attack().merged({"stability_cost": 100}, true),
		Vector2.RIGHT
	)
	_expect(result.guard_broken and not result.blocked, "Depleted stability should break guard.")
	_expect(runtime.get_state_snapshot()["phase"] == &"recovery", "Break needs recovery.")
	runtime.update(0.14, false)
	var snapshot: Dictionary = runtime.get_state_snapshot()
	_expect(snapshot["phase"] == &"idle", "Released shield should finish recovery.")
	_expect(snapshot["stability"] == 100, "Recovery should restore stability.")


func _validate_worn_shield() -> void:
	var policy := _policy()
	policy["condition"] = 0
	var runtime: Variant = ShieldRuntime.new()
	runtime.configure(policy)
	runtime.update(0.08, true)
	var result: Variant = runtime.resolve_attack(_normal_attack(), Vector2.RIGHT)
	_expect(result.blocked, "Condition-zero shield must remain usable.")
	_expect(result.condition_cost == 0, "Condition cannot fall below zero.")


func _runtime() -> Variant:
	var runtime: Variant = ShieldRuntime.new()
	runtime.configure(_policy())
	return runtime


func _active_runtime() -> Variant:
	var runtime: Variant = _runtime()
	runtime.update(0.08, true)
	runtime.update(0.15, true)
	return runtime


func _policy() -> Dictionary:
	return {
		"startup_time": 0.08,
		"recovery_time": 0.14,
		"guard_angle_degrees": 120.0,
		"precise_window": 0.14,
		"stability": 100,
		"condition": 100,
		"normal_condition_cost": 1,
		"heavy_condition_cost": 3,
		"precise_condition_cost_scale": 0.0,
		"guard_move_speed_multiplier": 0.7,
		"blocks_jump_while_guarding": false,
	}


func _normal_attack() -> Dictionary:
	return {
		"source_direction": Vector2.RIGHT,
		"stability_cost": 20,
		"tags": [&"normal"],
	}


func _heavy_attack() -> Dictionary:
	return {
		"source_direction": Vector2.RIGHT,
		"stability_cost": 35,
		"tags": [&"heavy"],
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
