extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Runtime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var failures: Array[String] = []
var _seeker_targets: Array[EnemyState] = []
var _requested_seeker_count := 0


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
	for secondary_id in [&"electric_field", &"orbiting_blades", &"drop_mines"]:
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
	_validate_homing_progression(catalog)
	var oracle := runtime.snapshot(build)
	var presentation_frame: Dictionary = {}
	var presentation_first := runtime.fill_presentation_snapshot(
		presentation_frame,
		build
	)
	var presentation_second := runtime.fill_presentation_snapshot(
		presentation_frame,
		build
	)
	_expect(
		is_same(presentation_first, presentation_second)
			and presentation_first.size() == 3
			and is_same(presentation_first["mines"], runtime.mines),
		"secondary presentation reuses caller scratch and borrows live mine state"
	)
	_expect(
		presentation_first["orbit_angle"] == oracle["orbit_angle"]
			and presentation_first["mines"] == oracle["mines"]
			and presentation_first["electric_field_radius"]
				== oracle["electric_field_radius"],
		"secondary presentation exposes the renderer-visible oracle fields and definition-owned field radius"
	)
	_validate_electric_field_radius(catalog)
	_validate_mine_direction(catalog)
	_validate_mine_detonation_receipts(catalog)
	_finish()


func _validate_electric_field_radius(catalog: Catalog) -> void:
	var expected_radii := [120.0, 140.0, 160.0]
	var build := RunBuild.new(catalog)
	var runtime := Runtime.new()
	var frame: Dictionary = {}
	for level_index in 3:
		build.apply(&"electric_field")
		runtime.fill_presentation_snapshot(frame, build)
		_expect(
			is_equal_approx(
				float(frame["electric_field_radius"]),
				expected_radii[level_index]
			),
			"Electric Field level %d publishes its exact definition radius"
			% (level_index + 1)
		)


func _validate_homing_progression(catalog: Catalog) -> void:
	_seeker_targets.clear()
	for index in 3:
		var target := EnemyState.new()
		target.id = "homing_target_%d" % index
		target.alive = true
		target.active = true
		target.pos = Vector2(120.0 + float(index) * 40.0, 20.0 * float(index))
		_seeker_targets.append(target)
	var expected_damage := [25.0, 28.0, 32.0]
	for upgrade_level in 3:
		var build := RunBuild.new(catalog)
		for _level in upgrade_level:
			build.apply(&"homing_missiles")
		var runtime := Runtime.new()
		runtime.reset(Vector2.ZERO)
		_requested_seeker_count = 0
		var result := runtime.update(
			0.1,
			Vector2.ZERO,
			Vector2.RIGHT,
			Vector2.RIGHT,
			build,
			_seeker_targets,
			Callable(self, "_los"),
			Callable(),
			Callable(self, "_find_seeker_targets")
		)
		var projectiles: Array = result["projectiles"]
		_expect(
			_requested_seeker_count == upgrade_level + 1
				and projectiles.size() == upgrade_level + 1,
			"homing level %d requests and fires exactly %d distinct missiles"
			% [upgrade_level, upgrade_level + 1]
		)
		for projectile in projectiles:
			_expect(
				is_equal_approx(float(projectile["damage"]), expected_damage[upgrade_level]),
				"homing level %d uses %.0f damage per missile"
				% [upgrade_level, expected_damage[upgrade_level]]
			)


func _find_seeker_targets(max_targets: int) -> Array[EnemyState]:
	_requested_seeker_count = max_targets
	var result: Array[EnemyState] = []
	for index in mini(max_targets, _seeker_targets.size()):
		result.append(_seeker_targets[index])
	return result


func _validate_mine_direction(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	_expect(
		bool(build.apply(&"drop_mines").get("applied", false)),
		"drop-mine fixture equips its secondary family"
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
		"drop mine uses actual movement direction before hull direction"
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
		"stationary drop mine falls back to hull direction"
	)


func _validate_mine_detonation_receipts(catalog: Catalog) -> void:
	var expected_damage := [48.0, 60.0, 72.0]
	var expected_radius := [96.0, 108.0, 120.0]
	for level_index in 3:
		var build := RunBuild.new(catalog)
		for _level in level_index + 1:
			build.apply(&"drop_mines")
		var runtime := Runtime.new()
		var origin := Vector2(320.0, 240.0)
		var target := EnemyState.new()
		target.id = "mine_target_%d" % level_index
		target.alive = true
		target.active = true
		target.pos = origin - Vector2.RIGHT * 48.0
		target.radius = 18.0
		var targets: Array[EnemyState] = [target]
		var result := runtime.update(
			0.1,
			origin,
			Vector2.RIGHT,
			Vector2.RIGHT,
			build,
			targets,
			Callable(self, "_los")
		)
		var damage: Array = result["damage"]
		var detonations: Array = result["detonations"]
		_expect(
			damage.size() == 1
			and is_equal_approx(float(damage[0]["damage"]), expected_damage[level_index])
			and detonations.size() == 1
			and Vector2(detonations[0]["position"]) == target.pos
			and is_equal_approx(float(detonations[0]["radius"]), expected_radius[level_index])
			and int(detonations[0]["level"]) == level_index + 1,
			"Drop Mine level %d resolves damage before one exact origin receipt"
			% (level_index + 1)
		)

	var timeout_build := RunBuild.new(catalog)
	timeout_build.apply(&"drop_mines")
	var timeout_runtime := Runtime.new()
	var no_targets: Array[EnemyState] = []
	timeout_runtime.update(
		0.1, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		timeout_build, no_targets, Callable(self, "_los")
	)
	timeout_runtime.mines[0]["life"] = 0.01
	var timeout_result := timeout_runtime.update(
		0.02, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		timeout_build, no_targets, Callable(self, "_los")
	)
	_expect(
		Array(timeout_result["damage"]).is_empty()
		and Array(timeout_result["detonations"]).size() == 1
		and is_equal_approx(
			float(Array(timeout_result["detonations"])[0]["radius"]), 96.0
		),
		"Drop Mine timeout emits its receipt even when it damages no target"
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
