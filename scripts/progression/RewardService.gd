class_name RewardService
extends RefCounted


static func resolve(
	table: RewardTable,
	transaction_id: StringName,
	run_seed: int
) -> RewardTransaction:
	if table == null or transaction_id == &"":
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = stable_seed(run_seed, String(transaction_id))
	var grants: Dictionary = {}
	var equipment_discoveries: Array[StringName] = []
	var blueprint_unlocks: Array[StringName] = []
	var spirit_stone_unlocks: Array[StringName] = []
	for entry in table.entries:
		if entry == null:
			continue
		var amount := entry.resolve_amount(rng)
		if amount <= 0:
			continue
		match entry.reward_type:
			RewardEntry.TYPE_CURRENCY:
				var content_key := String(entry.content_id)
				grants[content_key] = int(grants.get(content_key, 0)) + amount
			RewardEntry.TYPE_EQUIPMENT_DISCOVERY:
				for _discovery in amount:
					equipment_discoveries.append(entry.content_id)
			RewardEntry.TYPE_BLUEPRINT_UNLOCK:
				blueprint_unlocks.append(entry.content_id)
			RewardEntry.TYPE_SPIRIT_STONE_UNLOCK:
				spirit_stone_unlocks.append(entry.content_id)
	return RewardTransaction.new(
		transaction_id,
		table.id,
		grants,
		equipment_discoveries,
		blueprint_unlocks,
		spirit_stone_unlocks
	)


static func resolve_with_context(
	table: RewardTable,
	transaction_id: StringName,
	run_seed: int,
	_context: Dictionary
) -> RewardTransaction:
	return resolve(table, transaction_id, run_seed)


static func apply(transaction: RewardTransaction, run_state: Node) -> RewardResult:
	if transaction == null or run_state == null or not run_state.has_method("apply_reward_transaction"):
		return RewardResult.new(false, false, &"", {}, "Reward target is unavailable.")
	var result: Variant = run_state.call("apply_reward_transaction", transaction)
	if result is RewardResult:
		return result
	return RewardResult.new(false, false, transaction.id, {}, "Reward target returned no result.")


static func stable_seed(base_seed: int, key: String) -> int:
	var value := base_seed & 0x7fffffff
	for byte in key.to_utf8_buffer():
		value = int((value * 1664525 + int(byte) + 1013904223) & 0x7fffffff)
	return value
