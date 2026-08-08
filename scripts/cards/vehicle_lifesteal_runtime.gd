class_name VehicleLifestealRuntime
extends RefCounted

## Owns baseline and upgrade Lifesteal rates plus their bounded recovery budget.
## Damage resolution stays with VehicleRun; this runtime only converts an
## accepted receipt to Hull.

const BASE_HEALING_PERCENT := 0.5
const MAX_RECOVERY_BUDGET := 6.0
const RECOVERY_BUDGET_PER_SECOND := 6.0

var _healing_percent := BASE_HEALING_PERCENT
var _remaining_budget := MAX_RECOVERY_BUDGET


func reset(healing_percent: float = 0.0) -> void:
	_healing_percent = maxf(BASE_HEALING_PERCENT, healing_percent)
	_remaining_budget = MAX_RECOVERY_BUDGET


func configure(healing_percent: float) -> void:
	_healing_percent = maxf(BASE_HEALING_PERCENT, healing_percent)


func advance(delta: float) -> void:
	if delta <= 0.0 or _remaining_budget >= MAX_RECOVERY_BUDGET:
		return
	_remaining_budget = minf(
		MAX_RECOVERY_BUDGET,
		_remaining_budget + RECOVERY_BUDGET_PER_SECOND * delta
	)


func consume(applied_damage: float, missing_hull: float) -> float:
	if (
		applied_damage <= 0.0
		or missing_hull <= 0.0
		or _healing_percent <= 0.0
		or _remaining_budget <= 0.0
	):
		return 0.0
	var healing := minf(
		minf(applied_damage * _healing_percent / 100.0, _remaining_budget),
		missing_hull
	)
	_remaining_budget -= healing
	return healing


func remaining_budget() -> float:
	return _remaining_budget
