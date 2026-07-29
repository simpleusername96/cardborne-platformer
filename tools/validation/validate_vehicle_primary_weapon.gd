extends SceneTree

const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	var weapon := PrimaryWeapon.new()
	weapon.reset()
	weapon.tick(0.0, true)
	_expect(weapon.can_fire(), "fresh held input can always fire")
	weapon.consume_shot()
	_expect(not weapon.can_fire(), "a fired shot starts the cadence cooldown")
	weapon.tick(PrimaryWeapon.BASE_INTERVAL, true)
	_expect(weapon.can_fire(), "held input repeats at base cadence")
	weapon.consume_shot()
	weapon.tick(2.0, false)
	_expect(not weapon.can_fire(), "released input stops firing even after cooldown")
	weapon.tick(0.0, true)
	_expect(weapon.can_fire(), "resuming after a long release fires without a separate mode")
	weapon.consume_shot(0.20)
	_expect(is_equal_approx(weapon.cooldown, 0.20), "every resumed shot uses the requested cadence")
	weapon.tick(0.20, true)
	_expect(
		not weapon.can_fire(false),
		"external firing gates still suppress held fire without changing weapon state"
	)
	if failures.is_empty():
		print("VEHICLE_PRIMARY_WEAPON_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
