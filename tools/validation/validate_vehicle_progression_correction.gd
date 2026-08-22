extends SceneTree

const Build = preload("res://scripts/cards/vehicle_run_build.gd")
const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const Conditional = preload("res://scripts/ui/vehicle_conditional_status_snapshot.gd")

const EXPECTED_PENETRATIONS := [0, 1, 1, 2, 2, 3, 3, 4]
const EXPECTED_DAMAGE := [1.0, 1.05, 1.11, 1.18, 1.26, 1.35, 1.45, 1.56]

var failures: Array[String] = []


func _initialize() -> void:
	var build := Build.new()
	for fallback_id in Build.FALLBACK_IDS:
		for rank in Build.FALLBACK_MAX_RANK:
			var preview := build.fallback_preview(fallback_id)
			_expect(bool(preview.get("valid", false)), "%s rank %d previews" % [fallback_id, rank + 1])
			_expect(int(preview.get("new_rank", 0)) == rank + 1, "%s preview publishes the next rank" % fallback_id)
			_expect(bool(build.apply_fallback(fallback_id).get("applied", false)), "%s rank %d applies" % [fallback_id, rank + 1])
		_expect(not bool(build.fallback_preview(fallback_id).get("valid", false)), "%s stops at rank 20" % fallback_id)
	_expect(build.fallback_complete(), "EXP completion requires all three fallback paths at rank 20")
	_expect(is_equal_approx(build.fallback_primary_damage_multiplier(), 1.60), "firepower rank 20 adds 60 percent")
	_expect(is_equal_approx(build.stat(&"max_health_bonus", 100.0), 130.0), "chassis rank 20 adds 30 Hull")
	_expect(is_equal_approx(build.stat(&"move_speed_multiplier", 300.0), 345.0), "chassis rank 20 adds 15 percent movement speed")
	_expect(
		is_equal_approx(
			build.stat(&"pickup_radius_bonus", 0.0),
			10.0 * Build.FALLBACK_OPERATIONS_PICKUP_RADIUS_BONUS
		),
		"operations rank 20 adds the authored pickup radius"
	)
	_expect(is_equal_approx(build.fallback_dash_cooldown_multiplier(), 0.85), "operations rank 20 reduces dash cooldown by 15 percent")

	for level in range(0, PrimaryRules.MAX_PIERCE_LEVEL + 1):
		_expect(PrimaryRules.additional_penetrations(level) == EXPECTED_PENETRATIONS[level], "piercing level %d has the authored penetration count" % level)
		_expect(is_equal_approx(PrimaryRules.piercing_damage_multiplier(level), EXPECTED_DAMAGE[level]), "piercing level %d has the authored damage multiplier" % level)
		if level > 0:
			_expect(
				PrimaryRules.additional_penetrations(level) > PrimaryRules.additional_penetrations(level - 1)
				or PrimaryRules.piercing_damage_multiplier(level) > PrimaryRules.piercing_damage_multiplier(level - 1),
				"piercing level %d is not a dead level" % level
			)

	var statuses := Conditional.build(1, 0.0, 0.0, 1, 0.0, 3, 2, 1.4, 3, 5, 3, 3, 1, 0.0)
	_expect(statuses.size() == 6, "all owned conditional upgrades remain visible while inactive")
	for status in statuses:
		for key in ["id", "phase", "current_stacks", "max_stacks", "bonus_percent", "remaining_seconds", "next_hit_bonus_percent"]:
			_expect(status.has(key), "conditional status publishes %s" % key)
	var braced := _status(statuses, &"braced_fire")
	var chain := _status(statuses, &"hit_chain")
	var miss := _status(statuses, &"miss_compensation")
	_expect(int(braced["current_stacks"]) == 2 and is_equal_approx(float(braced["remaining_seconds"]), 1.4), "braced state publishes stacks and remaining time")
	_expect(int(chain["current_stacks"]) == 5 and roundi(float(chain["bonus_percent"])) == 20, "hit chain publishes its actual bonus")
	_expect(int(miss["current_stacks"]) == 3 and roundi(float(miss["next_hit_bonus_percent"])) == 30, "miss correction publishes its next-hit bonus")
	_finish()


func _status(rows: Array[Dictionary], id: StringName) -> Dictionary:
	for row in rows:
		if StringName(row["id"]) == id:
			return row
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PROGRESSION_CORRECTION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
