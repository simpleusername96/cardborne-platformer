extends SceneTree

const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var scavenger := _enemy(&"wreck_scavenger", Vector2.ZERO)
	var victim := _enemy(&"chaser", Vector2(360.0, 0.0))
	var receipt := SpecialistRuntime.wreck_scavenger_defeat_receipt(scavenger, victim, 0)
	_expect(bool(receipt["claimed"]) and int(receipt["stacks"]) == 1, "Wreck Scavenger claims a valid death at the exact 360-unit edge")
	var modifiers: Dictionary = receipt["modifiers"]
	_expect(
		is_equal_approx(float(modifiers["damage_multiplier"]), 1.12)
			and is_equal_approx(float(modifiers["speed_multiplier"]), 1.05)
			and is_equal_approx(float(modifiers["attack_interval_multiplier"]), 0.96),
		"one scavenged wreck applies the authored damage, speed, and interval modifiers"
	)
	receipt = SpecialistRuntime.wreck_scavenger_defeat_receipt(scavenger, victim, 5)
	_expect(not bool(receipt["claimed"]) and int(receipt["stacks"]) == 5, "Wreck Scavenger stack count remains capped at five")
	victim.pos = Vector2(360.1, 0.0)
	receipt = SpecialistRuntime.wreck_scavenger_defeat_receipt(scavenger, victim, 0)
	_expect(not bool(receipt["claimed"]), "Wreck Scavenger cannot claim a death outside its range")
	victim.pos = Vector2.ZERO
	for excluded in [&"stage_boss", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"generator", &"wreck_scavenger"]:
		victim.role = excluded
		receipt = SpecialistRuntime.wreck_scavenger_defeat_receipt(scavenger, victim, 0)
		_expect(not bool(receipt["claimed"]), "%s death cannot feed Wreck Scavenger" % excluded)
	victim.role = &"chaser"
	victim.summoned = true
	receipt = SpecialistRuntime.wreck_scavenger_defeat_receipt(scavenger, victim, 0)
	_expect(not bool(receipt["claimed"]), "summoned children cannot feed Wreck Scavenger")
	_finish()


func _enemy(role: StringName, position: Vector2) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.alive = true
	enemy.active = true
	enemy.role = role
	enemy.archetype = role
	enemy.pos = position
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_SPECIALIST_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
