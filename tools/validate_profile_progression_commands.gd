extends SceneTree

const LEGACY_EQUIPMENT := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY := preload("res://data/mastery/mastery_catalog.tres")
const PROGRESSION := preload(
	"res://data/equipment/equipment_progression_catalog.tres"
)

var _failures: Array[String] = []
var _commands := ProfileCommandService.new(
	LEGACY_EQUIPMENT,
	MASTERY,
	PROGRESSION
)


func _initialize() -> void:
	_validate_unlock_craft_recraft_repair()
	_validate_loadout_supply_and_maintenance()
	_validate_atomic_reward_settlement()
	_validate_tutorial_parity_and_rejections()
	_finish()


func _validate_unlock_craft_recraft_repair() -> void:
	var data := ProfileData.new()
	var unlocked := _commands.unlock_blueprint(data, &"hunting_spear", &"fixture:spear")
	_expect(unlocked.ok and unlocked.changed, "spear blueprint should unlock")
	var replay := _commands.unlock_blueprint(data, &"hunting_spear", &"fixture:spear")
	_expect(replay.ok and replay.duplicate and not replay.changed, "blueprint transaction should be idempotent")

	_commands.grant_material(data, "rusted_scrap", 3)
	_commands.grant_material(data, "common_timber", 4)
	var crafted := _commands.craft_equipment(data, &"hunting_spear")
	_expect(crafted.ok and crafted.changed, "unlocked spear should craft with exact Grade 1 materials")
	_expect(not data.materials.has("rusted_scrap"), "spear craft should consume 3 Iron Scrap")
	_expect(not data.materials.has("common_timber"), "spear craft should consume 4 Common Timber")
	_expect(data.crafted_equipment["hunting_spear"]["grade_id"] == "grade_1", "crafted spear should be Grade 1")
	_expect(data.crafted_equipment["hunting_spear"]["condition"] == 100.0, "crafted spear should start at full condition")
	var craft_repeat := _commands.craft_equipment(data, &"hunting_spear")
	_expect(not craft_repeat.ok and craft_repeat.code == &"already_crafted", "duplicate craft should fail closed")

	_commands.consume_equipment_condition(data, &"hunting_spear", 60.0)
	_commands.grant_material(data, "steel_fragment", 3)
	_commands.grant_material(data, "hardwood", 4)
	var recrafted := _commands.recraft_equipment(data, &"hunting_spear")
	_expect(recrafted.ok, "Grade 1 spear should recraft with exact Grade 2 materials")
	_expect(data.crafted_equipment["hunting_spear"]["grade_id"] == "grade_2", "recrafted spear should be Grade 2")
	_expect(data.crafted_equipment["hunting_spear"]["condition"] == 120.0, "newly recrafted spear should be full")

	_commands.consume_equipment_condition(data, &"hunting_spear", 80.0)
	_commands.grant_material(data, "hardwood", 1)
	var repaired := _commands.repair_equipment(data, &"hunting_spear")
	_expect(repaired.ok, "damaged Grade 2 spear should repair with one Hardwood")
	_expect(data.crafted_equipment["hunting_spear"]["condition"] == 82.0, "repair should restore 35% of 120")
	_expect(not data.materials.has("hardwood"), "repair should consume one primary same-grade material")
	_expect(data.validate_data(LEGACY_EQUIPMENT, MASTERY, PROGRESSION).is_empty(), "progression command result should validate")


func _validate_loadout_supply_and_maintenance() -> void:
	var data := ProfileData.new()
	_commands.unlock_blueprint(data, &"hunting_spear", &"fixture:spear:loadout")
	_commands.grant_material(data, "rusted_scrap", 3)
	_commands.grant_material(data, "common_timber", 4)
	_commands.craft_equipment(data, &"hunting_spear")
	var equipped := _commands.equip_hero_item(data, &"melee", &"hunting_spear")
	_expect(equipped.ok and data.hero_loadout["melee"] == "hunting_spear", "crafted spear should equip in melee slot")
	var wrong_slot := _commands.equip_hero_item(data, &"shield", &"hunting_spear")
	_expect(not wrong_slot.ok and wrong_slot.code == &"incompatible_equipment", "spear should not equip as a shield")

	var frost := _commands.unlock_spirit_stone(
		data,
		&"frost_spirit_stone",
		&"fixture:frost"
	)
	_expect(frost.ok and not frost.duplicate, "Frost Spirit Stone should unlock")
	_expect(_commands.equip_hero_item(data, &"spirit_stone", &"frost_spirit_stone").ok, "unlocked Stone should equip")

	_commands.spend_ranged_supply(data, &"arrows", 11)
	var supply := _commands.grant_ranged_supply(data, &"arrows", 4)
	_expect(supply.ok and data.ranged_supplies["arrows"] == 5, "arrow bundle should add four supplies")
	_commands.grant_ranged_supply(data, &"arrows", 99)
	_expect(data.ranged_supplies["arrows"] == 20, "ranged supply should clamp to its model maximum")

	data.crafted_equipment["hunting_spear"]["condition"] = 10.0
	data.crafted_equipment["round_shield"]["condition"] = 5.0
	data.ranged_supplies["arrows"] = 2
	var maintenance := _commands.apply_stage_entry_maintenance(data)
	_expect(maintenance.ok and maintenance.changed, "low equipped condition should receive free maintenance")
	_expect(data.crafted_equipment["hunting_spear"]["condition"] == 25.0, "melee maintenance should reach 25%")
	_expect(data.crafted_equipment["round_shield"]["condition"] == 25.0, "shield maintenance should reach 25%")
	_expect(data.ranged_supplies["arrows"] == 8, "stage entry should guarantee eight equipped bow arrows")


func _validate_tutorial_parity_and_rejections() -> void:
	var completed := ProfileData.new()
	var skipped := ProfileData.new()
	var complete_result := _commands.resolve_tutorial(completed, true, &"tutorial:baseline")
	var skip_result := _commands.resolve_tutorial(skipped, false, &"tutorial:baseline")
	_expect(complete_result.ok and skip_result.ok, "tutorial complete and skip should both resolve")
	_expect(completed.crafted_equipment == skipped.crafted_equipment, "tutorial paths should grant identical equipment")
	_expect(completed.hero_loadout == skipped.hero_loadout, "tutorial paths should keep identical loadouts")
	_expect(completed.ranged_supplies == skipped.ranged_supplies, "tutorial paths should keep identical supplies")
	_expect(completed.tutorial_state["completed"] and skipped.tutorial_state["skipped"], "tutorial telemetry should distinguish paths")

	var shortage := ProfileData.new()
	_commands.unlock_blueprint(shortage, &"matchlock", &"fixture:matchlock")
	var rejected := _commands.craft_equipment(shortage, &"matchlock")
	_expect(not rejected.ok and rejected.code == &"insufficient_materials", "crafting should reject material shortage")
	_expect(not shortage.crafted_equipment.has("matchlock"), "rejected craft should not mutate equipment")


func _validate_atomic_reward_settlement() -> void:
	var data := ProfileData.new()
	var settled := _commands.settle_progression_reward(
		data,
		&"fixture:progression_reward",
		{"steel_fragment": 2, "hardwood": 1},
		[&"hunting_spear"],
		[&"frost_spirit_stone"]
	)
	_expect(settled.ok and settled.changed, "valid progression reward should settle atomically")
	_expect(data.materials["steel_fragment"] == 2, "atomic reward should grant materials")
	_expect(data.unlocked_blueprints.has("hunting_spear"), "atomic reward should unlock blueprint")
	_expect(data.unlocked_spirit_stones.has("frost_spirit_stone"), "atomic reward should unlock Spirit Stone")
	var replay := _commands.settle_progression_reward(
		data,
		&"fixture:progression_reward",
		{"steel_fragment": 2},
		[&"hunting_spear"],
		[&"frost_spirit_stone"]
	)
	_expect(replay.ok and replay.duplicate and not replay.changed, "progression reward replay should be idempotent")
	_expect(data.materials["steel_fragment"] == 2, "replayed reward should not duplicate materials")

	var before := data.to_dictionary()
	var invalid := _commands.settle_progression_reward(
		data,
		&"fixture:invalid_reward",
		{"steel_fragment": 1},
		[&"missing_model"],
		[]
	)
	_expect(not invalid.ok, "invalid progression reward should be rejected")
	_expect(data.to_dictionary() == before, "rejected progression reward should not partially mutate profile")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PROFILE_PROGRESSION_COMMANDS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
