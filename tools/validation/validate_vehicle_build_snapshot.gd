extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Builder = preload("res://scripts/cards/vehicle_build_snapshot_builder.gd")

var _failures: Array[String] = []


func _init() -> void:
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	_expect(bool(build.apply(&"tuned_thrusters").get("applied", false)), "fixture upgrade applies")
	var stats: Array[Dictionary] = [
		{"id":&"speed", "label_key":"SHIP_STAT_SPEED", "value":build.stat(&"move_speed_multiplier", 280.0), "decimals":0, "unit_key":"SHIP_UNIT_PX_S"},
	]
	var snapshot := Builder.build(
		build,
		catalog,
		stats,
		[{"id":&"seeker", "level":1, "name_key":"SECONDARY_SEEKER_NAME"}],
		{"health":100.0, "max_health":120.0, "level":2}
	)
	_expect(bool(snapshot["active"]), "build snapshot is explicitly active")
	_expect(snapshot["stats"].size() == 1, "effective stats are preserved")
	_expect(snapshot["upgrades"].size() == 1, "acquired upgrade appears once")
	var upgrade := Dictionary(snapshot["upgrades"][0])
	_expect(StringName(upgrade["id"]) == &"tuned_thrusters", "upgrade uses stable ID")
	_expect(int(upgrade["level"]) == 1 and int(upgrade["max_level"]) >= 1, "upgrade level and maximum are present")
	var original_value := float(snapshot["stats"][0]["value"])
	stats[0]["value"] = 1.0
	_expect(is_equal_approx(float(snapshot["stats"][0]["value"]), original_value), "snapshot does not alias gameplay input")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_BUILD_SNAPSHOT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
