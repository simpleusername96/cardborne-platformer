class_name VehicleStageFlow
extends RefCounted

## Deterministic quota -> boss warning -> reward -> transition state owner.

enum State {
	ORDINARY,
	BOSS_WARNING,
	BOSS_ACTIVE,
	REWARDS,
	TRANSITION,
	COMPLETE,
}

var stage_index := 0
var quota := 96
var defeats := 0
var state := State.ORDINARY
var warning_remaining := 0.0


func configure(next_stage_index: int, next_quota: int) -> void:
	stage_index = next_stage_index
	quota = maxi(1, next_quota)
	defeats = 0
	state = State.ORDINARY
	warning_remaining = 0.0


func configure_transition(next_stage_index: int, next_quota: int) -> void:
	configure(next_stage_index, next_quota)
	state = State.TRANSITION


func record_countable_defeat() -> bool:
	if state not in [State.ORDINARY, State.TRANSITION]:
		return false
	defeats = mini(quota, defeats + 1)
	if defeats >= quota:
		state = State.BOSS_WARNING
		warning_remaining = 1.5
		return true
	return false


func tick(delta: float) -> bool:
	if state != State.BOSS_WARNING:
		return false
	warning_remaining = maxf(0.0, warning_remaining - maxf(0.0, delta))
	if warning_remaining <= 0.0:
		state = State.BOSS_ACTIVE
		return true
	return false


func boss_entry_ready() -> bool:
	return state == State.BOSS_ACTIVE and defeats >= quota


func record_boss_defeat() -> bool:
	if not boss_entry_ready():
		return false
	state = State.REWARDS
	return true


func record_rewards_complete(has_next_stage: bool = false) -> void:
	if state == State.REWARDS:
		state = State.TRANSITION if has_next_stage else State.COMPLETE


func record_transition_complete() -> void:
	if state == State.TRANSITION:
		state = State.ORDINARY


func stop_ordinary_spawning() -> bool:
	return state not in [State.ORDINARY, State.TRANSITION]


func snapshot() -> Dictionary:
	return {
		"stage_index":stage_index,
		"quota":quota,
		"defeats":defeats,
		"state":state,
		"warning_remaining":warning_remaining,
	}
