extends SceneTree

const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "profile/run integration needs autoloads")
	if profile_state == null or run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	profile_state.grant_material("rusted_scrap", 5)
	_expect(
		bool(profile_state.purchase_equipment(&"patched_mail").get("ok", false)),
		"integration fixture should unlock Patched Mail"
	)
	_expect(
		bool(profile_state.equip_item(&"warrior", &"armor", &"patched_mail").get("ok", false)),
		"integration fixture should equip Patched Mail"
	)
	var warrior: CharacterProfile = run_state.character_catalog.get_profile_by_id("warrior")
	var preview: PlayerBuildSnapshot = profile_state.preview_build(warrior)
	_expect(run_state.start_new_run(0, 4404), "equipped Warrior run should start")
	var runtime: PlayerBuildSnapshot = run_state.get_effective_build_snapshot()
	_expect(runtime.get_values() == preview.get_values(), "loadout preview and runtime values should match")
	_expect(
		runtime.get_source_breakdown() == preview.get_source_breakdown(),
		"loadout preview and runtime source breakdown should match"
	)

	var before_materials: int = profile_state.get_material_count("rusted_scrap")
	var transaction := RewardTransaction.new(
		&"profile-run-integration:material:1", &"integration_material", {"rusted_scrap": 2}
	)
	var first: RewardResult = run_state.apply_reward_transaction(transaction)
	_expect(first.applied, "run material reward should apply")
	_expect(
		profile_state.get_material_count("rusted_scrap") == before_materials + 2,
		"run material reward should settle immediately into the persistent wallet"
	)
	var duplicate: RewardResult = run_state.apply_reward_transaction(transaction)
	_expect(duplicate.duplicate, "replayed run material reward should be duplicate")
	_expect(
		profile_state.get_material_count("rusted_scrap") == before_materials + 2,
		"replayed material reward should not persist twice"
	)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("PROFILE_RUN_INTEGRATION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
