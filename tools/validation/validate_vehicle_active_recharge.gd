extends SceneTree

const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const ActiveRuntime = preload("res://scripts/player/vehicle_active_weapon_runtime.gd")
const RechargeRuntime = preload("res://scripts/player/vehicle_active_recharge_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_direct_action_deduplication()
	_validate_periodic_budget()
	_validate_incoming_lockout()
	_validate_ready_discard_and_shared_modifiers()
	_validate_reset()
	_finish()


func _validate_direct_action_deduplication() -> void:
	var recharge := RechargeRuntime.new()
	var active := ActiveRuntime.new()
	recharge.reset()
	active.cooldown_remaining = 5.0
	var first := recharge.credit_outgoing(&"primary", 1, false)
	var duplicate_target := recharge.credit_outgoing(&"primary", 1, false)
	active.reduce_cooldown(first + duplicate_target)
	_expect(
		is_equal_approx(first, 0.10)
			and is_zero_approx(duplicate_target)
			and is_equal_approx(active.cooldown_remaining, 4.90),
		"one accepted direct action credits 0.10 seconds once, independent of targets"
	)
	_expect(
		is_zero_approx(recharge.credit_outgoing(&"", 2, false))
			and is_zero_approx(recharge.credit_outgoing(&"active", 0, false)),
		"unidentified active self-damage and invalid actions cannot credit recharge"
	)
	for serial in range(2, 8):
		active.reduce_cooldown(recharge.credit_outgoing(&"secondary", serial, false))
	_expect(
		is_equal_approx(float(recharge.debug_snapshot()["credited_outgoing"]), 0.40),
		"direct actions cannot exceed the 0.40-second outgoing budget"
	)
	recharge.advance(0.25)
	_expect(
		is_equal_approx(recharge.credit_outgoing(&"primary", 8, false), 0.10),
		"the outgoing budget replenishes at 0.40 cooldown seconds per real second"
	)


func _validate_periodic_budget() -> void:
	var recharge := RechargeRuntime.new()
	recharge.reset()
	for serial in range(1, 8):
		recharge.credit_outgoing(&"dash", serial, true)
	_expect(
		is_equal_approx(float(recharge.debug_snapshot()["credited_outgoing"]), 0.10),
		"periodic actions credit 0.025 seconds and cannot exceed their 0.10-second sub-budget"
	)
	recharge.advance(0.50)
	_expect(
		is_equal_approx(recharge.credit_outgoing(&"field", 8, true), 0.025),
		"the periodic sub-budget replenishes at 0.10 cooldown seconds per real second"
	)


func _validate_incoming_lockout() -> void:
	var recharge := RechargeRuntime.new()
	recharge.reset()
	var barrier_and_hull := recharge.credit_incoming(20.0, 12.0)
	var locked := recharge.credit_incoming(0.0, 12.0)
	recharge.advance(1.24)
	var still_locked := recharge.credit_incoming(5.0, 0.0)
	recharge.advance(0.01)
	var after_lockout := recharge.credit_incoming(5.0, 10.0)
	_expect(
		is_equal_approx(barrier_and_hull, 0.20)
			and is_zero_approx(locked)
			and is_zero_approx(still_locked)
			and is_equal_approx(after_lockout, 0.20),
		"one received attack shares one 0.20-second credit and a 1.25-second lockout"
	)
	_expect(
		is_zero_approx(recharge.credit_incoming(0.0, 0.0)),
		"zero barrier and hull loss cannot credit recharge"
	)


func _validate_ready_discard_and_shared_modifiers() -> void:
	var catalog := UpgradeCatalog.new()
	var build := RunBuild.new(catalog)
	build.apply(&"active_coolant")
	var active := ActiveRuntime.new()
	var start := active.try_start(
		Vector2.ZERO,
		Vector2.RIGHT,
		Rect2(-600.0, -400.0, 1200.0, 800.0),
		build,
		2.0
	)
	_expect(
		bool(start.get("started", false))
			and is_equal_approx(active.cooldown_remaining, 9.9)
			and is_equal_approx(active.cooldown_max(build, 2.0), 9.9),
		"EMP relay reduction applies before the one coolant multiplier"
	)
	_expect(
		is_equal_approx(active.reduce_cooldown(0.10), 0.10)
			and is_equal_approx(active.cooldown_remaining, 9.8),
		"combat recharge subtracts its exact seconds after shared cooldown modifiers"
	)
	active.cooldown_remaining = 0.0
	var recharge := RechargeRuntime.new()
	recharge.reset()
	var discarded := recharge.credit_outgoing(&"primary", 700, false)
	_expect(
		is_equal_approx(discarded, 0.10)
			and is_zero_approx(active.reduce_cooldown(discarded)),
		"ready active weapons discard recharge instead of banking it"
	)
	active.cooldown_remaining = 1.0
	_expect(
		is_zero_approx(recharge.credit_outgoing(&"primary", 700, false))
			and is_equal_approx(active.cooldown_remaining, 1.0),
		"a ready-state action cannot apply later after cooldown starts"
	)


func _validate_reset() -> void:
	var recharge := RechargeRuntime.new()
	recharge.reset()
	recharge.credit_outgoing(&"primary", 99, false)
	recharge.credit_incoming(1.0, 0.0)
	recharge.reset()
	var snapshot := recharge.debug_snapshot()
	_expect(
		is_equal_approx(float(snapshot["outgoing_budget"]), 0.40)
			and is_equal_approx(float(snapshot["periodic_budget"]), 0.10)
			and is_zero_approx(float(snapshot["incoming_lockout_remaining"]))
			and int(snapshot["recent_action_count"]) == 0
			and is_zero_approx(float(snapshot["credited_outgoing"]))
			and is_zero_approx(float(snapshot["credited_incoming"])),
		"run reset clears budgets, lockout, action identities, and counters"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ACTIVE_RECHARGE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
