extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Runtime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_expect(
		Runtime._source_resource_name("example.tres.remap") == "example.tres",
		"exported secondary remaps resolve to source resource paths"
	)
	_expect(
		Runtime._source_resource_name("example.tres") == "example.tres",
		"source-tree secondary resources remain unchanged"
	)
	_expect(
		Runtime._source_resource_name("example.png").is_empty(),
		"unrelated secondary files remain excluded"
	)
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	var runtime := Runtime.new()
	_expect(runtime.definitions.size() == 4, "built-in Seeker and three optional secondary definitions load")
	for secondary_id in [&"ion_field", &"orbit_blades", &"wake_mines"]:
		var definition = runtime.definitions.get(secondary_id)
		_expect(definition != null and definition.values_by_level.size() == 3, "%s owns three bounded levels" % secondary_id)
		for level in 3:
			_expect(bool(build.apply(secondary_id).get("applied", false)), "%s level applies" % secondary_id)
		if build.active_optional_secondaries() >= 2:
			break
	_expect(build.active_optional_secondaries() == 2, "two optional weapons fill the slot cap")
	var optional_ids: Array[StringName] = []
	for definition in catalog.all_definitions():
		if definition.category == &"secondary" and definition.secondary_slot_kind == &"optional":
			optional_ids.append(definition.id)
	var blocked := optional_ids.filter(func(id: StringName) -> bool: return not build.has(id))
	for upgrade_id in blocked:
		_expect(not catalog.compatible(catalog.get_definition(upgrade_id), build), "third optional weapon is incompatible")
	var state := runtime.snapshot(build)
	_expect(Array(state["equipped"]).size() == 3, "runtime reports seeker plus two optional families")
	var target := EnemyState.new()
	target.id = "target"
	target.alive = true
	target.active = true
	target.pos = Vector2(100.0, 0.0)
	target.radius = 18.0
	var enemies: Array[EnemyState] = [target]
	var result := runtime.update(
		0.25,
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.RIGHT,
		build,
		enemies,
		Callable(self, "_los")
	)
	_expect(Array(result["damage"]).size() >= 1, "equipped optional secondary emits bounded damage intent")
	var oracle := runtime.snapshot(build)
	var presentation_frame: Dictionary = {}
	var presentation_first := runtime.fill_presentation_snapshot(
		presentation_frame
	)
	var presentation_second := runtime.fill_presentation_snapshot(
		presentation_frame
	)
	_expect(
		is_same(presentation_first, presentation_second)
			and presentation_first.size() == 2
			and is_same(presentation_first["mines"], runtime.mines),
		"secondary presentation reuses caller scratch and borrows live mine state"
	)
	_expect(
		presentation_first["orbit_angle"] == oracle["orbit_angle"]
			and presentation_first["mines"] == oracle["mines"],
		"secondary presentation exposes exactly the renderer-visible oracle fields"
	)
	_validate_mine_direction(catalog)
	_finish()


func _validate_mine_direction(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	_expect(
		bool(build.apply(&"wake_mines").get("applied", false)),
		"wake mine fixture equips its secondary family"
	)
	var origin := Vector2(220.0, 180.0)
	var runtime := Runtime.new()
	runtime.reset(origin)
	var no_enemies: Array[EnemyState] = []
	runtime.update(
		0.1,
		origin,
		Vector2.UP,
		Vector2.RIGHT,
		build,
		no_enemies,
		Callable(self, "_los")
	)
	var mines: Array = runtime.snapshot(build)["mines"]
	_expect(
		mines.size() == 1
			and Vector2(mines[0]["pos"]).distance_to(origin - Vector2.UP * 48.0) <= 0.001,
		"wake mine uses actual movement direction before hull direction"
	)
	runtime.reset(origin)
	runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.LEFT,
		build,
		no_enemies,
		Callable(self, "_los")
	)
	mines = runtime.snapshot(build)["mines"]
	_expect(
		mines.size() == 1
			and Vector2(mines[0]["pos"]).distance_to(origin - Vector2.LEFT * 48.0) <= 0.001,
		"stationary wake mine falls back to hull direction"
	)


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
