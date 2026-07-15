class_name RunSettlementService
extends RefCounted

const DEFAULT_BOSS_REWARD_TABLE_ID := &"boss_clear_slime_king"
const NORMAL_STAGE_COUNT := RunPhase.NORMAL_STAGE_COUNT
const REQUIRED_BOSS_CORE_COUNT := 1

var _settlement: RunSettlementSnapshot
var _profile_materials_at_start: Dictionary = {}


func reset(profile_state: Node = null) -> void:
	_settlement = null
	_profile_materials_at_start = _get_profile_materials(profile_state)


func has_settlement() -> bool:
	return _settlement != null


func get_snapshot() -> RunSettlementSnapshot:
	return _settlement


func settle_death(
	run_state: Node,
	profile_state: Node,
	reason: StringName = &"player_defeated"
) -> Dictionary:
	if _settlement != null:
		return _duplicate_result()
	var run_facts := _get_run_facts(run_state)
	if run_facts.is_empty():
		return _failure("Run facts are unavailable for death settlement.")
	_settlement = _build_snapshot(
		RunSettlementSnapshot.OUTCOME_DEATH,
		reason,
		run_facts,
		profile_state,
		_empty_boss_reward()
	)
	return _success(_settlement)


func settle_victory(
	run_state: Node,
	profile_state: Node,
	reward_table_id: StringName = DEFAULT_BOSS_REWARD_TABLE_ID
) -> Dictionary:
	if _settlement != null:
		return _duplicate_result()
	var run_facts := _get_run_facts(run_state)
	if run_facts.is_empty():
		return _failure("Run facts are unavailable for victory settlement.")
	if int(run_facts.get("stage_index", -1)) != NORMAL_STAGE_COUNT:
		return _failure("Boss victory requires the completed normal-stage boundary.")
	if reward_table_id == &"":
		return _failure("Boss clear reward table ID is missing.")
	var catalog_value: Variant = run_state.get("reward_catalog") if run_state != null else null
	if not catalog_value is RewardCatalog:
		return _failure("Boss clear reward catalog is unavailable.")
	var reward_catalog := catalog_value as RewardCatalog
	var reward_table := reward_catalog.get_table(reward_table_id)
	if reward_table == null:
		return _failure("Boss clear reward table '%s' is unavailable." % reward_table_id)

	var transaction_id := StringName(
		"%d:boss:%s:clear:0" % [int(run_facts.get("seed", 0)), reward_table_id]
	)
	var transaction := RewardService.resolve(
		reward_table,
		transaction_id,
		int(run_facts.get("seed", 0))
	)
	if transaction == null:
		return _failure("Boss clear reward transaction could not be resolved.")
	var expected_grants := transaction.get_grants()
	if int(expected_grants.get("boss_core", 0)) != REQUIRED_BOSS_CORE_COUNT:
		return _failure("Boss clear reward must resolve exactly one Boss Core.")

	var reward_result := RewardService.apply(transaction, run_state)
	if not reward_result.applied and not reward_result.duplicate:
		return _failure("Boss clear reward failed: %s" % reward_result.message)
	var boss_reward := {
		"table_id": String(reward_table_id),
		"transaction_id": String(transaction.id),
		"applied": reward_result.applied,
		"duplicate": reward_result.duplicate,
		"grants": expected_grants.duplicate(true),
		"equipment_discoveries": reward_result.equipment_discoveries.duplicate(true),
		"boss_core": REQUIRED_BOSS_CORE_COUNT,
	}
	_settlement = _build_snapshot(
		RunSettlementSnapshot.OUTCOME_VICTORY,
		&"boss_defeated",
		_get_run_facts(run_state),
		profile_state,
		boss_reward
	)
	return _success(_settlement)


func _build_snapshot(
	outcome: StringName,
	reason: StringName,
	run_facts: Dictionary,
	profile_state: Node,
	boss_reward: Dictionary
) -> RunSettlementSnapshot:
	var profile_id := String(run_facts.get("profile_id", ""))
	var stage_index := maxi(int(run_facts.get("stage_index", 0)), 0)
	var persistent_materials := _get_profile_materials(profile_state)
	return RunSettlementSnapshot.new({
		"outcome": String(outcome),
		"victory": outcome == RunSettlementSnapshot.OUTCOME_VICTORY,
		"terminal_reason": String(reason),
		"seed": int(run_facts.get("seed", 0)),
		"profile_id": profile_id,
		"profile": _get_profile_facts(profile_state, profile_id),
		"stage_index": stage_index,
		"stage_reached": clampi(stage_index + 1, 1, NORMAL_STAGE_COUNT),
		"boss_reached": stage_index >= NORMAL_STAGE_COUNT,
		"duration_seconds": maxf(float(run_facts.get("elapsed_seconds", 0.0)), 0.0),
		"health": int(run_facts.get("health", 0)),
		"max_health": int(run_facts.get("max_health", 0)),
		"run_build": {
			"level": int(run_facts.get("level", 1)),
			"cards": _copy_dictionary(run_facts.get("cards", {})),
			"micro_upgrades": _copy_dictionary(run_facts.get("micro_upgrades", {})),
			"effective_stats": _copy_dictionary(run_facts.get("effective_stats", {})),
			"consumable_id": String(run_facts.get("consumable_id", "")),
			"consumable_charges": int(run_facts.get("consumable_charges", 0)),
		},
		"run_economy": {
			"xp": int(run_facts.get("xp", 0)),
			"coins": int(run_facts.get("coins", 0)),
			"run_salvage": int(run_facts.get("run_salvage", 0)),
			"merchant_transaction_ids": _copy_array(
				run_facts.get("applied_merchant_transaction_ids", [])
			),
		},
		"run_material_rewards": _copy_dictionary(run_facts.get("materials", {})),
		"persistent_materials_before": _profile_materials_at_start.duplicate(true),
		"persistent_materials_after": persistent_materials,
		"persistent_material_delta": _material_delta(
			_profile_materials_at_start,
			persistent_materials
		),
		"boss_reward": boss_reward.duplicate(true),
	})


func _get_run_facts(run_state: Node) -> Dictionary:
	if run_state == null or not run_state.has_method("get_run_snapshot"):
		return {}
	var snapshot: Variant = run_state.call("get_run_snapshot")
	if snapshot is Dictionary:
		return snapshot.duplicate(true)
	if snapshot is Object and snapshot.has_method("to_dictionary"):
		var data: Variant = snapshot.call("to_dictionary")
		if data is Dictionary:
			return data.duplicate(true)
	return {}


func _get_profile_materials(profile_state: Node) -> Dictionary:
	if profile_state == null or not profile_state.has_method("get_materials"):
		return {}
	var materials: Variant = profile_state.call("get_materials")
	return materials.duplicate(true) if materials is Dictionary else {}


func _get_profile_facts(profile_state: Node, profile_id: String) -> Dictionary:
	var facts := {
		"id": profile_id,
		"hero_loadout": {},
		"crafted_equipment": {},
		"unlocked_blueprints": [],
		"unlocked_spirit_stones": [],
		"ranged_supplies": {},
	}
	if profile_state == null:
		return facts
	if not profile_state.has_method("get_profile_snapshot"):
		return facts
	var snapshot: Variant = profile_state.call("get_profile_snapshot")
	if not snapshot is Dictionary:
		return facts
	var profile := snapshot as Dictionary
	facts["hero_loadout"] = _copy_dictionary(profile.get("hero_loadout", {}))
	facts["crafted_equipment"] = _copy_dictionary(profile.get("crafted_equipment", {}))
	facts["unlocked_blueprints"] = _copy_array(profile.get("unlocked_blueprints", []))
	facts["unlocked_spirit_stones"] = _copy_array(
		profile.get("unlocked_spirit_stones", [])
	)
	facts["ranged_supplies"] = _copy_dictionary(profile.get("ranged_supplies", {}))
	return facts


func _material_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var material_ids := before.keys()
	for material_id in after:
		if not material_ids.has(material_id):
			material_ids.append(material_id)
	material_ids.sort()
	var delta: Dictionary = {}
	for material_id in material_ids:
		delta[String(material_id)] = (
			int(after.get(material_id, 0)) - int(before.get(material_id, 0))
		)
	return delta


func _copy_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _copy_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []


func _empty_boss_reward() -> Dictionary:
	return {
		"table_id": "",
		"transaction_id": "",
		"applied": false,
		"duplicate": false,
		"grants": {},
		"equipment_discoveries": [],
		"boss_core": 0,
	}


func _success(snapshot: RunSettlementSnapshot) -> Dictionary:
	return {
		"ok": true,
		"duplicate": false,
		"message": "Run settled.",
		"settlement": snapshot,
		"snapshot": snapshot.to_dictionary(),
	}


func _duplicate_result() -> Dictionary:
	return {
		"ok": true,
		"duplicate": true,
		"message": "Run was already settled.",
		"settlement": _settlement,
		"snapshot": _settlement.to_dictionary(),
	}


func _failure(message: String) -> Dictionary:
	return {
		"ok": false,
		"duplicate": false,
		"message": message,
		"settlement": null,
		"snapshot": {},
	}
