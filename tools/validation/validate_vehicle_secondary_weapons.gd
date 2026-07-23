extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Runtime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	var runtime := Runtime.new()
	_expect(runtime.definitions.size() == 5, "five secondary definitions load")
	for secondary_id in [&"ion_field", &"orbit_blades", &"wake_mines", &"escort_drone"]:
		var definition = runtime.definitions.get(secondary_id)
		_expect(definition != null and definition.values_by_level.size() == 3, "%s owns three bounded levels" % secondary_id)
		for level in 3:
			_expect(bool(build.apply(secondary_id).get("applied", false)), "%s level applies" % secondary_id)
		if build.active_optional_secondaries() >= 2:
			break
	_expect(build.active_optional_secondaries() == 2, "two optional families fill the three-family total cap")
	var blocked := Catalog.SECONDARY_FAMILY_IDS.filter(func(id: StringName) -> bool: return not build.has(id))
	for upgrade_id in blocked:
		_expect(not catalog.compatible(catalog.get_definition(upgrade_id), build), "fourth family is incompatible")
	var state := runtime.snapshot(build)
	_expect(Array(state["equipped"]).size() == 3, "runtime reports seeker plus two optional families")
	var target := EnemyState.new()
	target.id = "target"
	target.alive = true
	target.active = true
	target.pos = Vector2(100.0, 0.0)
	target.radius = 18.0
	var enemies: Array[EnemyState] = [target]
	var result := runtime.update(0.25, Vector2.ZERO, Vector2.RIGHT, build, enemies, Callable(self, "_los"))
	_expect(Array(result["damage"]).size() >= 1, "equipped passive simulation emits bounded damage intent")
	_finish()


func _los(_from: Vector2, _to: Vector2, _padding: float) -> bool:
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SECONDARY_WEAPONS_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
