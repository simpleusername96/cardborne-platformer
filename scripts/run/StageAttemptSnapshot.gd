class_name StageAttemptSnapshot
extends RefCounted

const VERSION := 2

const REQUIRED_RUN_STATE_KEYS: PackedStringArray = [
	"run_seed",
	"stage_index",
	"current_health",
	"max_health",
	"run_level",
	"current_xp",
	"coins",
	"run_salvage",
	"unsettled_materials",
	"micro_upgrade_stacks",
	"card_stacks",
	"applied_reward_ids",
	"applied_field_pickup_ids",
	"applied_merchant_transaction_ids",
	"pending_level_choices",
	"pending_level_offer",
	"level_offer_sequence",
	"card_reward_pending",
	"pending_card_offer",
	"card_offer_sequence",
	"card_reroll_used",
	"card_reward_stage_index",
	"committed_card_id",
	"current_consumable_id",
	"consumable_charges",
	"hero_combat_loadout",
]

var _data: Dictionary
var _validation_errors: PackedStringArray


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)
	_validation_errors = _validate(_data)


func is_valid() -> bool:
	return _validation_errors.is_empty()


func get_validation_errors() -> PackedStringArray:
	return _validation_errors.duplicate()


func get_stage_path() -> String:
	return String(_data.get("stage_path", ""))


func get_stage_index() -> int:
	return int(_data.get("stage_index", -1))


func get_run_seed() -> int:
	return int(_data.get("run_seed", -1))


func is_boss_attempt() -> bool:
	return bool(_data.get("boss_attempt", false))


func get_run_state() -> Dictionary:
	var value: Variant = _data.get("run_state", {})
	return value.duplicate(true) if value is Dictionary else {}


func get_profile_resources() -> Dictionary:
	var value: Variant = _data.get("profile_resources", {})
	return value.duplicate(true) if value is Dictionary else {}


func to_dictionary() -> Dictionary:
	return _data.duplicate(true)


static func _validate(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(data.get("version", -1)) != VERSION:
		errors.append("Stage attempt snapshot version is unsupported.")
	var run_seed_value: Variant = data.get("run_seed", null)
	var stage_index_value: Variant = data.get("stage_index", null)
	if not run_seed_value is int or int(run_seed_value) < 0:
		errors.append("Stage attempt run seed must be a non-negative integer.")
	if not stage_index_value is int or int(stage_index_value) < 0:
		errors.append("Stage attempt index must be a non-negative integer.")
	var stage_path := String(data.get("stage_path", ""))
	if not stage_path.begins_with("res://") or not stage_path.ends_with(".tscn"):
		errors.append("Stage attempt path must identify a project scene.")
	var boss_value: Variant = data.get("boss_attempt", null)
	if not boss_value is bool:
		errors.append("Stage attempt boss flag must be boolean.")
	elif stage_index_value is int:
		var stage_index := int(stage_index_value)
		if bool(boss_value) != (stage_index == RunPhase.NORMAL_STAGE_COUNT):
			errors.append("Stage attempt boss flag does not match its stage index.")
		if stage_index > RunPhase.NORMAL_STAGE_COUNT:
			errors.append("Stage attempt index is outside the fixed run.")

	var raw_run_state: Variant = data.get("run_state", null)
	if not raw_run_state is Dictionary:
		errors.append("Stage attempt run state is missing.")
	else:
		_validate_run_state(raw_run_state as Dictionary, data, errors)
	var raw_profile_resources: Variant = data.get("profile_resources", null)
	if not raw_profile_resources is Dictionary:
		errors.append("Stage attempt profile resources are missing.")
	else:
		_validate_profile_resources(raw_profile_resources as Dictionary, errors)
	return errors


static func _validate_run_state(
	run_state: Dictionary,
	top_level: Dictionary,
	errors: PackedStringArray
) -> void:
	for key in REQUIRED_RUN_STATE_KEYS:
		if not run_state.has(key):
			errors.append("Stage attempt run state is missing '%s'." % key)
	if not errors.is_empty():
		return
	if not run_state["run_seed"] is int or int(run_state["run_seed"]) != int(top_level["run_seed"]):
		errors.append("Stage attempt run seed is inconsistent.")
	if not run_state["stage_index"] is int or int(run_state["stage_index"]) != int(top_level["stage_index"]):
		errors.append("Stage attempt stage index is inconsistent.")
	for key in [
		"current_health", "max_health", "run_level", "current_xp", "coins", "run_salvage",
	]:
		if not run_state[key] is int:
			errors.append("Stage attempt '%s' must be an integer." % key)
	if run_state["current_health"] is int and run_state["max_health"] is int:
		var health := int(run_state["current_health"])
		var maximum := int(run_state["max_health"])
		if health <= 0 or maximum <= 0 or health > maximum:
			errors.append("Stage attempt health must be alive and within maximum health.")
	if run_state["run_level"] is int and int(run_state["run_level"]) < 1:
		errors.append("Stage attempt level must be positive.")
	for key in [
		"current_xp", "coins", "run_salvage", "pending_level_choices",
		"level_offer_sequence", "card_offer_sequence", "consumable_charges",
	]:
		if not run_state[key] is int or int(run_state[key]) < 0:
			errors.append("Stage attempt '%s' must be a non-negative integer." % key)
	for key in [
		"unsettled_materials", "micro_upgrade_stacks", "card_stacks",
		"applied_reward_ids", "applied_field_pickup_ids",
		"applied_merchant_transaction_ids", "hero_combat_loadout",
	]:
		if not run_state[key] is Dictionary:
			errors.append("Stage attempt '%s' must be a dictionary." % key)
	for key in ["unsettled_materials", "micro_upgrade_stacks", "card_stacks"]:
		if run_state[key] is Dictionary:
			_validate_non_negative_integer_dictionary(
				run_state[key] as Dictionary,
				"Stage attempt '%s'" % key,
				errors
			)
	for key in [
		"applied_reward_ids", "applied_field_pickup_ids",
		"applied_merchant_transaction_ids",
	]:
		if run_state[key] is Dictionary:
			for transaction_id in run_state[key]:
				if String(transaction_id).is_empty() or not run_state[key][transaction_id] is bool:
					errors.append("Stage attempt '%s' contains an invalid transaction." % key)
	for key in ["pending_level_offer", "pending_card_offer"]:
		if not run_state[key] is Array:
			errors.append("Stage attempt '%s' must be an array." % key)
		else:
			for value in run_state[key]:
				if not (value is String or value is StringName) or String(value).is_empty():
					errors.append("Stage attempt '%s' contains an invalid ID." % key)
	for key in ["card_reward_pending", "card_reroll_used"]:
		if not run_state[key] is bool:
			errors.append("Stage attempt '%s' must be boolean." % key)
	if not run_state["card_reward_stage_index"] is int:
		errors.append("Stage attempt card reward stage index must be an integer.")
	elif int(run_state["card_reward_stage_index"]) < -1:
		errors.append("Stage attempt card reward stage index is invalid.")
	if not (run_state["committed_card_id"] is String or run_state["committed_card_id"] is StringName):
		errors.append("Stage attempt committed card ID must be text.")
	if not (run_state["current_consumable_id"] is String or run_state["current_consumable_id"] is StringName):
		errors.append("Stage attempt consumable ID must be text.")
	elif String(run_state["current_consumable_id"]).is_empty():
		errors.append("Stage attempt consumable ID is missing.")
	if run_state["hero_combat_loadout"] is Dictionary and run_state["hero_combat_loadout"].is_empty():
		errors.append("Stage attempt hero combat loadout is missing.")


static func _validate_profile_resources(resources: Dictionary, errors: PackedStringArray) -> void:
	var raw_conditions: Variant = resources.get("equipment_conditions", null)
	var raw_supplies: Variant = resources.get("ranged_supplies", null)
	if not raw_conditions is Dictionary:
		errors.append("Stage attempt equipment conditions are missing.")
	else:
		for model_id in raw_conditions:
			var condition: Variant = raw_conditions[model_id]
			if (
				String(model_id).is_empty()
				or not (condition is int or condition is float)
				or not is_finite(float(condition))
				or float(condition) < 0.0
			):
				errors.append("Stage attempt equipment condition is invalid.")
	if not raw_supplies is Dictionary:
		errors.append("Stage attempt ranged supplies are missing.")
	else:
		_validate_non_negative_integer_dictionary(
			raw_supplies as Dictionary,
			"Stage attempt ranged supply",
			errors
		)


static func _validate_non_negative_integer_dictionary(
	values: Dictionary,
	label: String,
	errors: PackedStringArray
) -> void:
	for raw_key in values:
		var amount: Variant = values[raw_key]
		if String(raw_key).is_empty() or not amount is int or int(amount) < 0:
			errors.append("%s contains an invalid value." % label)
