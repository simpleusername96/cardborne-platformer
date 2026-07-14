extends SceneTree

const HERO := preload("res://data/hero/traveler.tres")
const HeroDefinitionScript := preload("res://scripts/player/HeroDefinition.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var hero: Resource = HERO
	_expect(hero != null, "traveler hero resource should load")
	_expect(hero != null and hero.get_script() == HeroDefinitionScript, "traveler should use HeroDefinition")
	if hero != null and hero.get_script() == HeroDefinitionScript:
		for error in hero.validate_definition():
			_failures.append(error)
		var stats: Dictionary = hero.to_base_stats_dictionary()
		_expect(hero.id == &"traveler", "production hero ID should be stable")
		_expect(int(stats.get("max_health", 0)) == 5, "baseline health should leave armor room to grow")
		_expect(int(stats.get("extra_jumps", 0)) == 1, "baseline should provide one extra jump")
		_expect(int(stats.get("dash_charges", 0)) == 1, "baseline should provide one dash")
		_expect(float(stats.get("jump_velocity", 0.0)) <= -435.0, "baseline jump must clear approved routes")
		stats["max_health"] = 999
		_expect(
			int(hero.base_stats.get("max_health", 0)) == 5,
			"hero stat snapshots must not mutate the definition"
		)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("HERO_DEFINITION_VALIDATION_OK id=traveler double_jump=1 dash=1")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
