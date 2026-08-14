class_name VehicleStageFlow
extends RefCounted

## Owns deterministic quota and boss eligibility, and publishes narrow campaign receipts.

enum State {
	ORDINARY,
	BOSS_WARNING,
	BOSS_ACTIVE,
	COMPLETE,
}

const COMMAND_NONE: StringName = &""
const COMMAND_BEGIN_BOSS_WARNING: StringName = &"begin_boss_warning"
const COMMAND_ENTER_BOSS: StringName = &"enter_boss"
const COMMAND_COMPLETE_WITHOUT_BOSS: StringName = &"complete_without_boss"
const COMMAND_COMPLETE_AFTER_BOSS: StringName = &"complete_after_boss"
const VALID_COMMANDS: Array[StringName] = [
	COMMAND_NONE,
	COMMAND_BEGIN_BOSS_WARNING,
	COMMAND_ENTER_BOSS,
	COMMAND_COMPLETE_WITHOUT_BOSS,
	COMMAND_COMPLETE_AFTER_BOSS,
]

var stage_index := 0
var quota := 96
var defeats := 0
var state := State.ORDINARY
var warning_remaining := 0.0
var has_boss := true


func configure(
	next_stage_index: int,
	next_quota: int,
	next_has_boss: bool = true
) -> void:
	stage_index = next_stage_index
	quota = maxi(1, next_quota)
	has_boss = next_has_boss
	defeats = 0
	state = State.ORDINARY
	warning_remaining = 0.0


func record_countable_defeat() -> Dictionary:
	var command := COMMAND_NONE
	var accepted := false
	if state != State.ORDINARY:
		return _receipt(accepted, command)
	accepted = true
	defeats = mini(quota, defeats + 1)
	if defeats >= quota:
		if has_boss:
			state = State.BOSS_WARNING
			warning_remaining = 1.5
			command = COMMAND_BEGIN_BOSS_WARNING
		else:
			state = State.COMPLETE
			command = COMMAND_COMPLETE_WITHOUT_BOSS
	return _receipt(accepted, command)


func advance(delta: float) -> Dictionary:
	if boss_entry_ready():
		return _receipt(true, COMMAND_ENTER_BOSS)
	if state != State.BOSS_WARNING:
		return _receipt(false, COMMAND_NONE)
	warning_remaining = maxf(0.0, warning_remaining - maxf(0.0, delta))
	if warning_remaining <= 0.0:
		state = State.BOSS_ACTIVE
		return _receipt(true, COMMAND_ENTER_BOSS)
	return _receipt(true, COMMAND_NONE)


func boss_entry_ready() -> bool:
	return state == State.BOSS_ACTIVE and defeats >= quota


func record_boss_defeat() -> Dictionary:
	if not boss_entry_ready():
		return _receipt(false, COMMAND_NONE)
	state = State.COMPLETE
	return _receipt(true, COMMAND_COMPLETE_AFTER_BOSS)


static func valid_receipt(receipt: Dictionary) -> bool:
	if not (
		receipt.has("accepted")
		and receipt.has("command")
		and receipt.has("stage_index")
		and receipt.has("quota")
		and receipt.has("defeats")
		and receipt.has("state")
		and receipt.has("has_boss")
		and StringName(receipt["command"]) in VALID_COMMANDS
	):
		return false
	var receipt_state := int(receipt["state"])
	var command := StringName(receipt["command"])
	var receipt_has_boss := bool(receipt["has_boss"])
	if (
		int(receipt["stage_index"]) < 0
		or int(receipt["quota"]) <= 0
		or int(receipt["defeats"]) < 0
		or int(receipt["defeats"]) > int(receipt["quota"])
		or receipt_state < State.ORDINARY
		or receipt_state > State.COMPLETE
	):
		return false
	match command:
		COMMAND_BEGIN_BOSS_WARNING:
			return receipt_has_boss and receipt_state == State.BOSS_WARNING
		COMMAND_ENTER_BOSS:
			return receipt_has_boss and receipt_state == State.BOSS_ACTIVE
		COMMAND_COMPLETE_WITHOUT_BOSS:
			return not receipt_has_boss and receipt_state == State.COMPLETE
		COMMAND_COMPLETE_AFTER_BOSS:
			return receipt_has_boss and receipt_state == State.COMPLETE
	return true


func _receipt(accepted: bool, command: StringName) -> Dictionary:
	return {
		"accepted":accepted,
		"command":command,
		"stage_index":stage_index,
		"quota":quota,
		"defeats":defeats,
		"state":state,
		"has_boss":has_boss,
	}


func snapshot() -> Dictionary:
	return {
		"stage_index":stage_index,
		"quota":quota,
		"defeats":defeats,
		"state":state,
		"warning_remaining":warning_remaining,
		"has_boss":has_boss,
	}
