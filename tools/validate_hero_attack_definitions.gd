extends SceneTree

const ATTACKS: Array[AttackDefinition] = [
	preload("res://data/attacks/traveler_sword.tres"),
	preload("res://data/attacks/hunting_spear.tres"),
	preload("res://data/attacks/hunting_bow.tres"),
	preload("res://data/attacks/matchlock.tres"),
]

const EXPECTED: Dictionary = {
	&"traveler_sword_slash": {"damage": 2, "stagger": 18, "reach": 76.0, "startup": 0.10, "recovery": 0.22},
	&"hunting_spear_thrust": {"damage": 3, "stagger": 24, "reach": 118.0, "startup": 0.16, "recovery": 0.30},
	&"hunting_bow_shot": {"damage": 2, "stagger": 10, "range": 520.0, "startup": 0.12, "recovery": 0.44},
	&"matchlock_shot": {"damage": 5, "stagger": 42, "range": 680.0, "startup": 0.08, "recovery": 1.35},
}

var _failures: Array[String] = []


func _initialize() -> void:
	var seen: Dictionary = {}
	for attack in ATTACKS:
		for error in attack.validate_definition():
			_failures.append(error)
		_expect(not seen.has(attack.id), "hero attack IDs must be unique")
		seen[attack.id] = true
		var expected: Dictionary = EXPECTED.get(attack.id, {})
		_expect(not expected.is_empty(), "unexpected hero attack '%s'" % attack.id)
		_expect(attack.input_action == &"attack", "all combat tools use the contextual attack action")
		_expect(attack.base_damage == int(expected.get("damage", -1)), "%s damage drifted" % attack.id)
		_expect(attack.stagger == int(expected.get("stagger", -1)), "%s stagger drifted" % attack.id)
		_expect(is_equal_approx(attack.startup_time, float(expected.get("startup", -1.0))), "%s startup drifted" % attack.id)
		_expect(is_equal_approx(attack.recovery_time, float(expected.get("recovery", -1.0))), "%s recovery drifted" % attack.id)
		if expected.has("reach"):
			var reach := absf(attack.hitbox_offset.x) + attack.hitbox_size.x * 0.5
			_expect(is_equal_approx(reach, float(expected["reach"])), "%s reach drifted" % attack.id)
		if expected.has("range"):
			_expect(is_equal_approx(attack.projectile_range, float(expected["range"])), "%s range drifted" % attack.id)
	_expect(seen.size() == EXPECTED.size(), "hero attack catalog must contain exactly four actions")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("HERO_ATTACK_DEFINITION_VALIDATION_OK attacks=4")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
