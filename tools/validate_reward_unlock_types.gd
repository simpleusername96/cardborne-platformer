extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_unlock_resolution()
	_validate_permanent_reward_cardinality()
	_finish()


func _validate_unlock_resolution() -> void:
	var blueprint := RewardEntry.new()
	blueprint.reward_type = RewardEntry.TYPE_BLUEPRINT_UNLOCK
	blueprint.content_id = &"hunting_spear"
	var spirit := RewardEntry.new()
	spirit.reward_type = RewardEntry.TYPE_SPIRIT_STONE_UNLOCK
	spirit.content_id = &"frost_spirit_stone"
	var table := RewardTable.new()
	table.id = &"fixture_permanent_unlocks"
	table.display_name = "Fixture Permanent Unlocks"
	table.entries = [blueprint, spirit]
	_expect(table.validate_definition().is_empty(), "valid permanent unlock table should validate")

	var first := RewardService.resolve(table, &"fixture:unlock:1", 44021)
	var replay := RewardService.resolve(table, &"fixture:unlock:1", 44021)
	_expect(first != null, "permanent unlock table should resolve")
	if first == null:
		return
	_expect(first.to_dictionary() == replay.to_dictionary(), "unlock resolution should be deterministic")
	_expect(
		first.get_blueprint_unlocks() == [&"hunting_spear"],
		"blueprint reward should retain its model ID"
	)
	_expect(
		first.get_spirit_stone_unlocks() == [&"frost_spirit_stone"],
		"Spirit Stone reward should retain its Stone ID"
	)
	var copied := first.get_blueprint_unlocks()
	copied.clear()
	_expect(not first.get_blueprint_unlocks().is_empty(), "transaction unlock arrays should be copy-safe")


func _validate_permanent_reward_cardinality() -> void:
	for reward_type in [
		RewardEntry.TYPE_BLUEPRINT_UNLOCK,
		RewardEntry.TYPE_SPIRIT_STONE_UNLOCK,
	]:
		var entry := RewardEntry.new()
		entry.reward_type = reward_type
		entry.content_id = &"fixture_unlock"
		entry.minimum_amount = 1
		entry.maximum_amount = 2
		var errors := entry.validate_definition()
		_expect(
			not errors.is_empty() and "; ".join(errors).contains("exactly once"),
			"permanent unlock rewards should reject amount ranges"
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REWARD_UNLOCK_TYPES_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
