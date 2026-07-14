extends SceneTree

const PROGRESSION_CATALOG := preload(
	"res://data/equipment/equipment_progression_catalog.tres"
)

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_defaults_and_round_trip()
	_validate_invalid_contracts()
	_finish()


func _validate_defaults_and_round_trip() -> void:
	var data := ProfileData.new()
	_expect(data.schema_version == 2, "new profiles should use schema v2")
	_expect(data.hero_id == "traveler", "new profiles should use the shared hero")
	_expect(
		data.unlocked_blueprints == ProfileData.DEFAULT_BLUEPRINTS,
		"new profiles should unlock exactly the four baseline blueprints"
	)
	_expect(
		data.crafted_equipment.size() == 4,
		"new profiles should start with exactly four crafted equipment models"
	)
	_expect(
		data.unlocked_spirit_stones == ["ember_spirit_stone"],
		"new profiles should start with only the Ember Spirit Stone"
	)
	_expect(
		data.ranged_supplies == {"arrows": 12, "cartridges": 5},
		"new profiles should use the planned starting ranged supplies"
	)
	_expect_valid(data, "default profile")

	var round_trip := ProfileData.from_dictionary(data.to_dictionary())
	_expect_valid(round_trip, "round-trip profile")
	_expect(
		round_trip.to_dictionary() == data.to_dictionary(),
		"profile v2 should round-trip without changing values"
	)


func _validate_invalid_contracts() -> void:
	var invalid_slot := ProfileData.new()
	invalid_slot.hero_loadout["melee"] = "hunting_bow"
	_expect_invalid(invalid_slot, "does not fit hero slot", "wrong equipment slot")

	var missing_model := ProfileData.new()
	missing_model.hero_loadout["shield"] = "tower_shield"
	_expect_invalid(missing_model, "uncrafted equipment", "uncrafted equipped model")

	var invalid_grade := ProfileData.new()
	invalid_grade.crafted_equipment["traveler_sword"]["grade_id"] = "grade_3"
	_expect_invalid(invalid_grade, "invalid grade", "unsupported crafted grade")

	var invalid_condition := ProfileData.new()
	invalid_condition.crafted_equipment["traveler_sword"]["condition"] = 101.0
	_expect_invalid(invalid_condition, "outside 0-100", "condition above grade maximum")

	var conditionless := ProfileData.new()
	conditionless.crafted_equipment["hunting_bow"]["condition"] = 1.0
	_expect_invalid(conditionless, "does not own condition", "condition on a ranged model")

	var invalid_material := ProfileData.new()
	invalid_material.materials["mystery_dust"] = 1
	_expect_invalid(invalid_material, "unknown material", "unknown material ID")

	var invalid_supply := ProfileData.new()
	invalid_supply.ranged_supplies["arrows"] = 21
	_expect_invalid(invalid_supply, "within 0-20", "ranged supply above maximum")

	var invalid_tutorial := ProfileData.new()
	invalid_tutorial.tutorial_state = {
		"resolved": true,
		"completed": true,
		"skipped": true,
	}
	_expect_invalid(invalid_tutorial, "both completed and skipped", "conflicting tutorial result")


func _expect_valid(data: ProfileData, label: String) -> void:
	var errors := data.validate_data(null, null, PROGRESSION_CATALOG)
	_expect(errors.is_empty(), "%s should validate: %s" % [label, "; ".join(errors)])


func _expect_invalid(data: ProfileData, fragment: String, label: String) -> void:
	var errors := data.validate_data(null, null, PROGRESSION_CATALOG)
	var joined := "; ".join(errors)
	_expect(not errors.is_empty(), "%s should be rejected" % label)
	_expect(joined.contains(fragment), "%s should explain '%s': %s" % [label, fragment, joined])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PROFILE_V2_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
