extends SceneTree

const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	var weapon := PrimaryWeapon.new()
	weapon.reset(false)
	weapon.tick(0.0, true, true)
	_expect(weapon.can_fire(), "fresh held input can always fire")
	var normal := weapon.consume_shot()
	_expect(is_equal_approx(float(normal["damage_scale"]), 1.0), "uncharged shot uses baseline damage")
	weapon.tick(PrimaryWeapon.BASE_INTERVAL, true, true)
	_expect(weapon.can_fire(), "held input repeats at base cadence")
	weapon.consume_shot()
	weapon.tick(0.24, false, true)
	weapon.tick(0.0, true, true)
	var brief := weapon.consume_shot()
	_expect(is_equal_approx(float(brief["damage_scale"]), 1.0), "brief release below 0.25 seconds grants no bonus")
	weapon.tick(PrimaryWeapon.FULL_OPENING_SECONDS, false, true)
	_expect(weapon.charge_ratio() >= PrimaryWeapon.FULL_EPSILON, "one idle second fills the opening charge")
	weapon.tick(0.0, true, true)
	var full := weapon.consume_shot()
	_expect(bool(full["full_opening"]), "full charge marks exactly one opening shot")
	_expect(is_equal_approx(float(full["damage_scale"]), 1.75), "full opening health multiplier is exact")
	_expect(is_equal_approx(float(full["structure_scale"]), 3.0), "full opening structure multiplier is exact")
	_expect(is_zero_approx(weapon.charge_ratio()), "opening charge is consumed by the shot")
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
