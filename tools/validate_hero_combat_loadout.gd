extends SceneTree

const Resolver := preload("res://scripts/player/HeroCombatLoadoutResolver.gd")
const HERO := preload("res://data/hero/traveler.tres")
const CATALOG := preload("res://data/equipment/equipment_progression_catalog.tres")

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_default_loadout()
	_validate_grade_wear_and_armor()
	_validate_fail_closed_and_copy_safety()
	_finish()


func _validate_default_loadout() -> void:
	var result := Resolver.resolve(HERO, ProfileData.new(), CATALOG)
	_expect(result["ok"], "default shared-hero loadout should resolve")
	if not result["ok"]:
		return
	_expect(result["stats"]["max_health"] == 5, "Traveler Coat should preserve baseline health")
	_expect(result["stats"]["extra_jumps"] == 1, "shared hero should retain double jump")
	var melee: AttackDefinition = result["melee"]["attack"]
	var ranged: AttackDefinition = result["ranged"]["attack"]
	_expect(melee.base_damage == 2 and melee.hitbox_size == Vector2(72, 42), "sword attack should use authored definition")
	_expect(ranged.projectile_range == 520.0, "bow attack should use authored range")
	_expect(result["ranged"]["resource_count"] == 12, "bow should expose 12 starting arrows")
	_expect(result["ranged"]["intent_policy"]["resource_id"] == &"arrows", "bow should use canonical arrows ID")
	_expect(result["shield"]["defense_policy"]["stability"] == 100, "round shield should expose 100 stability")
	_expect(result["shield"]["defense_policy"]["heavy_condition_cost"] == 3, "round shield heavy block should cost 3 condition")


func _validate_grade_wear_and_armor() -> void:
	var data := ProfileData.new()
	for model_id in ["reinforced_coat"]:
		data.unlocked_blueprints.append(model_id)
	data.crafted_equipment["traveler_sword"] = {"grade_id": "grade_2", "condition": 0.0}
	data.crafted_equipment["reinforced_coat"] = {"grade_id": "grade_2", "condition": 0.0}
	data.hero_loadout["armor"] = "reinforced_coat"
	var result := Resolver.resolve(HERO, data, CATALOG)
	_expect(result["ok"], "Grade 2 worn loadout should remain playable")
	if not result["ok"]:
		return
	var melee: AttackDefinition = result["melee"]["attack"]
	_expect(melee.base_damage == 2, "worn Grade 2 sword should apply its damage penalty")
	_expect(is_equal_approx(melee.recovery_time, 0.242), "worn sword should add 10% recovery")
	_expect(result["stats"]["max_health"] == 8, "Grade 2 reinforced coat should add 3 health")
	_expect(is_equal_approx(result["stats"]["dash_cooldown"], 0.51), "reinforced coat should add dash recovery")


func _validate_fail_closed_and_copy_safety() -> void:
	var invalid := ProfileData.new()
	invalid.hero_loadout["melee"] = "hunting_spear"
	var rejected := Resolver.resolve(HERO, invalid, CATALOG)
	_expect(not rejected["ok"] and rejected["code"] == "invalid_equipment", "uncrafted loadout should fail closed")

	var data := ProfileData.new()
	var result := Resolver.resolve(HERO, data, CATALOG)
	var resolved_attack: AttackDefinition = result["melee"]["attack"]
	resolved_attack.base_damage = 99
	_expect(
		CATALOG.get_model(&"traveler_sword").attack_definition.base_damage == 2,
		"resolved runtime attack should not mutate catalog data"
	)
	result["stats"]["move_speed"] = 1.0
	_expect(HERO.base_stats["move_speed"] == 220.0, "resolved hero stats should be copy-safe")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("HERO_COMBAT_LOADOUT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
