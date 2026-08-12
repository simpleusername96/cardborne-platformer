class_name VehicleActiveRechargeRuntime
extends RefCounted

## Converts accepted combat actions into bounded active-weapon cooldown credits.
## VehicleRun owns damage truth; this owner only deduplicates action identities,
## applies the two outgoing budgets, and enforces the incoming-hit lockout.

const DIRECT_CREDIT_SECONDS := 0.10
const PERIODIC_CREDIT_SECONDS := 0.025
const OUTGOING_CAPACITY_SECONDS := 0.40
const PERIODIC_CAPACITY_SECONDS := 0.10
const INCOMING_CREDIT_SECONDS := 0.20
const INCOMING_LOCKOUT_SECONDS := 1.25
const RECENT_ACTION_CAPACITY := 512

var _outgoing_budget := OUTGOING_CAPACITY_SECONDS
var _periodic_budget := PERIODIC_CAPACITY_SECONDS
var _incoming_lockout_remaining := 0.0
var _recent_actions: Dictionary = {}
var _recent_action_order: Array[String] = []
var _recent_action_head := 0
var _credited_outgoing := 0.0
var _credited_incoming := 0.0


func reset() -> void:
	_outgoing_budget = OUTGOING_CAPACITY_SECONDS
	_periodic_budget = PERIODIC_CAPACITY_SECONDS
	_incoming_lockout_remaining = 0.0
	_recent_actions.clear()
	_recent_action_order.clear()
	_recent_action_head = 0
	_credited_outgoing = 0.0
	_credited_incoming = 0.0


func advance(delta: float) -> void:
	var elapsed := maxf(0.0, delta)
	_outgoing_budget = minf(
		OUTGOING_CAPACITY_SECONDS,
		_outgoing_budget + elapsed * OUTGOING_CAPACITY_SECONDS
	)
	_periodic_budget = minf(
		PERIODIC_CAPACITY_SECONDS,
		_periodic_budget + elapsed * PERIODIC_CAPACITY_SECONDS
	)
	_incoming_lockout_remaining = maxf(
		0.0, _incoming_lockout_remaining - elapsed
	)
	if _incoming_lockout_remaining <= 0.000001:
		_incoming_lockout_remaining = 0.0


func credit_outgoing(
	action_family: StringName,
	action_serial: int,
	periodic: bool
) -> float:
	if action_family == &"" or action_serial <= 0:
		return 0.0
	var action_key := "%s:%d" % [action_family, action_serial]
	if _recent_actions.has(action_key):
		return 0.0
	_remember_action(action_key)
	var requested := PERIODIC_CREDIT_SECONDS if periodic else DIRECT_CREDIT_SECONDS
	var credited := minf(requested, _outgoing_budget)
	if periodic:
		credited = minf(credited, _periodic_budget)
		_periodic_budget -= credited
	_outgoing_budget -= credited
	_credited_outgoing += credited
	return credited


func credit_incoming(barrier_loss: float, hull_loss: float) -> float:
	if barrier_loss <= 0.0 and hull_loss <= 0.0:
		return 0.0
	if _incoming_lockout_remaining > 0.0:
		return 0.0
	_incoming_lockout_remaining = INCOMING_LOCKOUT_SECONDS
	_credited_incoming += INCOMING_CREDIT_SECONDS
	return INCOMING_CREDIT_SECONDS


func debug_snapshot() -> Dictionary:
	return {
		"outgoing_budget":_outgoing_budget,
		"periodic_budget":_periodic_budget,
		"incoming_lockout_remaining":_incoming_lockout_remaining,
		"recent_action_count":_recent_actions.size(),
		"credited_outgoing":_credited_outgoing,
		"credited_incoming":_credited_incoming,
	}


func _remember_action(action_key: String) -> void:
	_recent_actions[action_key] = true
	_recent_action_order.append(action_key)
	while _recent_action_order.size() - _recent_action_head > RECENT_ACTION_CAPACITY:
		_recent_actions.erase(_recent_action_order[_recent_action_head])
		_recent_action_head += 1
	if _recent_action_head >= RECENT_ACTION_CAPACITY:
		var compacted: Array[String] = []
		for index in range(_recent_action_head, _recent_action_order.size()):
			compacted.append(_recent_action_order[index])
		_recent_action_order = compacted
		_recent_action_head = 0
