extends SceneTree

const CATALOG := preload("res://data/equipment/equipment_progression_catalog.tres")
const Resolver := preload("res://scripts/progression/EquipmentRuntimeResolver.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_melee_grade_and_wear()
	_validate_shield_grade_and_wear()
	_validate_ranged_and_armor_grade()
	_validate_rejections()
	_finish()


func _validate_melee_grade_and_wear() -> void:
	var sword := CATALOG.get_model(&"traveler_sword")
	var grade_one := Resolver.resolve(
		sword, {"grade_id": "grade_1", "condition": 100.0}
	)
	_expect(grade_one["damage"] == 2, "Grade 1 sword should keep 2 damage")
	_expect(grade_one["stagger_damage"] == 18, "Grade 1 sword should keep 18 stagger")
	_expect(grade_one["maximum_condition"] == 100, "Grade 1 sword should cap at 100 condition")
	_expect(not grade_one["worn"], "healthy sword should not be worn")

	var grade_two := Resolver.resolve(
		sword, {"grade_id": "grade_2", "condition": 120.0}
	)
	_expect(grade_two["damage"] == 3, "Grade 2 sword should add 1 damage")
	_expect(grade_two["stagger_damage"] == 21, "Grade 2 sword should add 15% stagger")
	_expect(grade_two["maximum_condition"] == 120, "Grade 2 sword should cap at 120 condition")

	var worn := Resolver.resolve(
		sword, {"grade_id": "grade_2", "condition": 0.0}
	)
	_expect(worn["worn"], "zero-condition sword should be worn")
	_expect(worn["damage"] == 2, "worn Grade 2 sword should apply the damage penalty")
	_expect(
		is_equal_approx(worn["recovery_seconds"], 0.242),
		"worn sword should add 10% recovery"
	)


func _validate_shield_grade_and_wear() -> void:
	var shield := CATALOG.get_model(&"round_shield")
	var grade_two := Resolver.resolve(
		shield, {"grade_id": "grade_2", "condition": 120.0}
	)
	_expect(grade_two["guard_stability"] == 115, "Grade 2 shield should add 15% stability")
	_expect(grade_two["normal_block_condition_cost"] == 1, "round normal guard cost should remain 1")
	_expect(grade_two["heavy_block_condition_cost"] == 3, "round heavy guard cost should remain 3")
	_expect(grade_two["precise_block_condition_cost"] == 0, "precise guard should preserve condition")

	var worn := Resolver.resolve(
		shield, {"grade_id": "grade_2", "condition": 0.0}
	)
	_expect(worn["guard_stability"] == 98, "worn Grade 2 shield should apply the stability penalty")
	_expect(
		is_equal_approx(worn["recovery_seconds"], 0.154),
		"worn shield should add 10% recovery"
	)


func _validate_ranged_and_armor_grade() -> void:
	var bow := Resolver.resolve(
		CATALOG.get_model(&"hunting_bow"),
		{"grade_id": "grade_2", "condition": 0.0}
	)
	_expect(bow["damage"] == 3, "Grade 2 bow should add 1 damage")
	_expect(bow["stagger_damage"] == 12, "Grade 2 bow should add 15% stagger")
	_expect(bow["maximum_condition"] == 0 and not bow["worn"], "bow should not own condition")
	_expect(bow["maximum_ranged_resource"] == 20, "grade should not change arrow capacity")
	_expect(bow["starting_ranged_resource"] == 12, "bow should expose starting arrows")
	_expect(bow["stage_minimum_ranged_resource"] == 8, "bow should expose stage-entry arrows")

	var coat := Resolver.resolve(
		CATALOG.get_model(&"reinforced_coat"),
		{"grade_id": "grade_2", "condition": 0.0}
	)
	_expect(coat["max_health_bonus"] == 3, "Grade 2 reinforced coat should add one health")
	_expect(
		is_equal_approx(coat["knockback_reduction_fraction"], 0.15),
		"grade should not change armor knockback identity"
	)


func _validate_rejections() -> void:
	var missing := Resolver.resolve(null, {})
	_expect(not missing["ok"] and missing["code"] == "missing_model", "missing model should fail closed")
	var invalid := Resolver.resolve(
		CATALOG.get_model(&"traveler_sword"),
		{"grade_id": "grade_3", "condition": 100.0}
	)
	_expect(not invalid["ok"] and invalid["code"] == "invalid_grade", "invalid grade should fail closed")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("EQUIPMENT_RUNTIME_RESOLVER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
