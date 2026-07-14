extends SceneTree

const REWARD_CATALOG := preload("res://data/rewards/reward_catalog.tres")
const FIELD_PICKUPS := preload("res://data/items/field_pickup_catalog.tres")

var _failures: Array[String] = []
var _profile_state: Node
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_profile_state != null and _run_state != null, "Stage 1 reward fixture needs profile/run state")
	if _profile_state == null or _run_state == null:
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_expect(REWARD_CATALOG.validate_catalog().is_empty(), "Stage 1 reward catalog should validate")
	_expect(FIELD_PICKUPS.validate_catalog().is_empty(), "Stage 1 field pickup catalog should validate")
	_expect(_run_state.start_new_run(0, 91104), "Stage 1 reward fixture should start")

	_apply_pickup(&"fixture_stage1_iron", &"rusted_scrap_fragment")
	_apply_pickup(&"fixture_stage1_timber", &"common_timber_bundle")
	_apply_pickup(&"fixture_stage1_fiber", &"sky_thread_wisp")
	var npc := _apply_table(&"npc_hunting_spear", &"fixture:stage1:npc")
	var elite := _apply_table(&"drop_shield_guard", &"fixture:stage1:elite")
	var clear := _apply_table(&"stage_clear_ruin_approach", &"fixture:stage1:clear")
	_expect(npc.applied and elite.applied and clear.applied, "required Stage 1 rewards should settle")

	var materials: Dictionary = _profile_state.get_materials()
	var guaranteed := {
		"rusted_scrap": 12,
		"common_timber": 10,
		"sky_thread": 6,
		"steel_fragment": 6,
		"hardwood": 5,
		"reinforced_fabric": 5,
	}
	for material_id in guaranteed:
		_expect(
			int(materials.get(material_id, 0)) == int(guaranteed[material_id]),
			"Stage 1 required rewards should guarantee %d %s" % [guaranteed[material_id], material_id]
		)
	var snapshot: Dictionary = _profile_state.get_profile_snapshot()
	var blueprints: Array = snapshot.get("unlocked_blueprints", [])
	_expect(blueprints.has("hunting_spear"), "NPC request should unlock the Hunting Spear blueprint")
	_expect(blueprints.has("tower_shield"), "elite guard should unlock the Tower Shield blueprint")
	_expect(blueprints.has("reinforced_coat"), "stage clear should unlock the Reinforced Coat blueprint")
	_expect(not blueprints.has("matchlock"), "optional Matchlock blueprint should not be on the required route")

	var before_replay := materials.duplicate(true)
	var replay := _apply_table(&"npc_hunting_spear", &"fixture:stage1:npc")
	_expect(replay.duplicate, "replaying the same NPC transaction should be rejected as duplicate")
	_expect(_profile_state.get_materials() == before_replay, "duplicate NPC reward must not grant materials twice")

	var cache := _apply_table(&"cache_matchlock", &"fixture:stage1:cache")
	var shrine := _apply_table(&"shrine_frost_spirit", &"fixture:stage1:shrine")
	_expect(cache.applied and shrine.applied, "optional Stage 1 rewards should settle")
	snapshot = _profile_state.get_profile_snapshot()
	_expect(
		(snapshot.get("unlocked_blueprints", []) as Array).has("matchlock"),
		"optional cache should unlock the Matchlock blueprint"
	)
	_expect(
		(snapshot.get("unlocked_spirit_stones", []) as Array).has("frost_spirit_stone"),
		"optional shrine should unlock the Frost Spirit Stone"
	)
	_finish()


func _apply_pickup(instance_id: StringName, definition_id: StringName) -> void:
	var definition := FIELD_PICKUPS.get_definition(definition_id)
	var result: Dictionary = _run_state.apply_field_pickup(instance_id, definition)
	_expect(bool(result.get("applied", false)), "pickup %s should settle" % definition_id)


func _apply_table(table_id: StringName, transaction_id: StringName) -> RewardResult:
	var table := REWARD_CATALOG.get_table(table_id)
	_expect(table != null, "reward table %s should exist" % table_id)
	if table == null:
		return RewardResult.new()
	var transaction := RewardService.resolve(table, transaction_id, 91104)
	return RewardService.apply(transaction, _run_state)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE1_PROGRESSION_REWARDS_VALIDATION_OK required=6 unlock_sources=5")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
