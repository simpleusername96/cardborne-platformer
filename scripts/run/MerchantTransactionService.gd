class_name MerchantTransactionService
extends RefCounted

const BUY_POTION := &"buy_potion"
const SELL_ALL_SALVAGE := &"sell_all_salvage"
const POTION_PRICE := 10
const SALVAGE_UNIT_PRICE := 4


func preview(kind: StringName, run_facts: Dictionary) -> Dictionary:
	var coins := int(run_facts.get("coins", 0))
	var salvage := int(run_facts.get("run_salvage", 0))
	var charges := int(run_facts.get("consumable_charges", 0))
	var max_charges := int(run_facts.get("max_consumable_charges", 1))
	var active := bool(run_facts.get("active", false))
	var result := {
		"kind": String(kind),
		"eligible": false,
		"can_apply": false,
		"failure_code": "",
		"message": "",
		"unit_price": 0,
		"quantity": 0,
		"price": 0,
		"coins": coins,
		"run_salvage": salvage,
		"consumable_charges": charges,
		"projected_coins": coins,
		"projected_run_salvage": salvage,
		"projected_consumable_charges": charges,
	}
	if not active:
		return _reject_preview(result, &"run_inactive", "An active run is required.")
	if coins < 0 or salvage < 0 or charges < 0 or max_charges <= 0 or charges > max_charges:
		return _reject_preview(result, &"invalid_run_facts", "Merchant balances are invalid.")

	match kind:
		BUY_POTION:
			result["unit_price"] = POTION_PRICE
			result["quantity"] = 1
			result["price"] = POTION_PRICE
			result["coin_cost"] = POTION_PRICE
			if charges >= max_charges:
				return _reject_preview(result, &"potion_full", "Potion charge is already full.")
			if coins < POTION_PRICE:
				return _reject_preview(result, &"insufficient_coins", "Not enough coins.")
			result["eligible"] = true
			result["can_apply"] = true
			result["message"] = "Buy one Healing Potion charge."
			result["projected_coins"] = coins - POTION_PRICE
			result["projected_consumable_charges"] = max_charges
		SELL_ALL_SALVAGE:
			result["unit_price"] = SALVAGE_UNIT_PRICE
			result["quantity"] = salvage
			result["price"] = salvage * SALVAGE_UNIT_PRICE
			result["coin_gain"] = int(result["price"])
			result["total"] = int(result["price"])
			if salvage <= 0:
				return _reject_preview(result, &"no_run_salvage", "No run salvage to sell.")
			result["eligible"] = true
			result["can_apply"] = true
			result["message"] = "Sell all run salvage."
			result["projected_coins"] = coins + int(result["price"])
			result["projected_run_salvage"] = 0
		_:
			return _reject_preview(result, &"unknown_transaction", "Merchant action is unavailable.")
	return result.duplicate(true)


func execute(
	transaction_id: StringName,
	kind: StringName,
	run_facts: Dictionary,
	applied_transaction_ids: Dictionary
) -> MerchantTransactionReceipt:
	var transaction_key := String(transaction_id)
	if transaction_key.is_empty():
		return _receipt(
			false,
			false,
			transaction_id,
			kind,
			preview(kind, run_facts),
			&"missing_transaction_id",
			"Merchant transaction ID is missing."
		)
	if applied_transaction_ids.has(transaction_key):
		return _receipt(
			false,
			true,
			transaction_id,
			kind,
			preview(kind, run_facts),
			&"duplicate_transaction",
			"Merchant transaction was already applied."
		)
	var transaction_preview := preview(kind, run_facts)
	if not bool(transaction_preview.get("eligible", false)):
		return _receipt(
			false,
			false,
			transaction_id,
			kind,
			transaction_preview,
			StringName(transaction_preview.get("failure_code", "transaction_rejected")),
			String(transaction_preview.get("message", "Merchant transaction was rejected."))
		)
	return _receipt(
		true,
		false,
		transaction_id,
		kind,
		transaction_preview,
		&"",
		"Merchant transaction applied."
	)


func _reject_preview(result: Dictionary, failure_code: StringName, message: String) -> Dictionary:
	result["failure_code"] = String(failure_code)
	result["message"] = message
	return result.duplicate(true)


func _receipt(
	applied: bool,
	duplicate: bool,
	transaction_id: StringName,
	kind: StringName,
	transaction_preview: Dictionary,
	failure_code: StringName,
	message: String
) -> MerchantTransactionReceipt:
	return MerchantTransactionReceipt.new({
		"ok": applied,
		"applied": applied,
		"duplicate": duplicate,
		"transaction_id": String(transaction_id),
		"kind": String(kind),
		"failure_code": String(failure_code),
		"message": message,
		"unit_price": int(transaction_preview.get("unit_price", 0)),
		"quantity": int(transaction_preview.get("quantity", 0)),
		"price": int(transaction_preview.get("price", 0)),
		"before": {
			"coins": int(transaction_preview.get("coins", 0)),
			"run_salvage": int(transaction_preview.get("run_salvage", 0)),
			"consumable_charges": int(transaction_preview.get("consumable_charges", 0)),
		},
		"after": {
			"coins": int(transaction_preview.get("projected_coins", 0)),
			"run_salvage": int(transaction_preview.get("projected_run_salvage", 0)),
			"consumable_charges": int(
				transaction_preview.get("projected_consumable_charges", 0)
			),
		},
	})
