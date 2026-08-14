extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const Runtime = preload("res://scripts/player/vehicle_secondary_runtime.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)

var failures: Array[String] = []
var _seeker_targets: Array[EnemyState] = []
var _requested_seeker_count := 0
var _storm_targets: Array[EnemyState] = []
var _storm_query_calls := 0


func _initialize() -> void:
	_expect(
		SecondaryCatalog._source_resource_name("example.tres.remap") == "example.tres",
		"exported secondary remaps resolve to source resource paths"
	)
	_expect(
		SecondaryCatalog._source_resource_name("example.tres") == "example.tres",
		"source-tree secondary resources remain unchanged"
	)
	_expect(
		SecondaryCatalog._source_resource_name("example.png").is_empty(),
		"unrelated secondary files remain excluded"
	)
	var catalog := Catalog.new()
	var build := RunBuild.new(catalog)
	var runtime := Runtime.new()
	var expected_secondary_ids: Array[StringName] = [
		&"drop_mines", &"electric_field", &"orbiting_blades", &"seeker",
		&"auto_laser", &"storm_barrage",
	]
	_expect(
		runtime.catalog.definitions.size() == expected_secondary_ids.size(),
		"six equal automatic-weapon definitions load"
	)
	for secondary_id in expected_secondary_ids:
		_expect(
			runtime.catalog.get_definition(secondary_id) != null,
			"secondary definition %s loads" % secondary_id
		)
	for secondary_id in [&"electric_field", &"orbiting_blades", &"homing_missiles"]:
		var definition = runtime.catalog.get_by_upgrade_id(secondary_id)
		_expect(definition != null, "%s owns a runtime definition" % secondary_id)
		_expect(bool(build.apply(secondary_id).get("applied", false)), "%s acquisition applies" % secondary_id)
	var seeker = runtime.catalog.get_definition(&"seeker")
	_expect(
		seeker != null
			and seeker.upgrade_id == &"homing_missiles"
			and seeker.values_by_level == [25.0, 31.36, 40.0, 53.2]
			and seeker.cap_by_level == [2, 3, 4, 4],
		"Seeker definition owns four acquired card states"
	)
	_expect(build.active_automatic_weapons() == 3, "three automatic weapons fill the slot cap")
	var automatic_ids: Array[StringName] = []
	for definition in catalog.all_definitions():
		if definition.category == &"secondary":
			automatic_ids.append(definition.id)
	var blocked := automatic_ids.filter(func(id: StringName) -> bool: return not build.has(id))
	for upgrade_id in blocked:
		_expect(not catalog.compatible(catalog.get_definition(upgrade_id), build), "fourth automatic weapon is incompatible")
	var state := runtime.snapshot(build)
	_expect(Array(state["equipped"]).size() == 3, "runtime reports exactly three acquired automatic families")
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
	_expect(Array(result["damage"]).size() >= 1, "equipped automatic weapon emits bounded damage intent")
	for intent_variant in result["damage"]:
		var intent: Dictionary = intent_variant
		_expect(
			intent.get("damage_flags", -1) is int
				and int(intent.get("attack_serial", 0)) > 0,
			"secondary damage intent carries numeric flags and stable serial"
		)
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
			and presentation_first.size() >= 7
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
	_validate_auto_laser(catalog)
	_validate_storm_barrage(catalog)
	_validate_weapon_owned_endpoints(catalog)
	_finish()


func _validate_weapon_owned_endpoints(catalog: Catalog) -> void:
	var target := EnemyState.new()
	target.id = "weapon_endpoint_target"
	target.alive = true
	target.active = true
	target.radius = 18.0

	var seeker_build := _leveled_build(catalog, &"homing_missiles", 4)
	var seeker_runtime := Runtime.new()
	_seeker_targets.assign([target])
	target.pos = Vector2(120.0, 0.0)
	var result := seeker_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		seeker_build, [target], Callable(self, "_los"), Callable(),
		Callable(self, "_find_seeker_targets")
	)
	var seeker_projectile := Dictionary(Array(result["projectiles"])[0])
	_expect(
		is_equal_approx(float(seeker_projectile["damage"]), 53.2)
			and is_equal_approx(seeker_runtime.seeker_cooldown, 1.0125)
			and is_equal_approx(float(seeker_projectile["structure_damage"]), 35.0),
		"Seeker Level 4 owns damage, cadence, and structure damage"
	)

	var field_build := _leveled_build(catalog, &"electric_field", 4)
	var field_runtime := Runtime.new()
	target.pos = Vector2(100.0, 0.0)
	result = field_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		field_build, [target], Callable(self, "_los")
	)
	_expect(
		is_equal_approx(float(Dictionary(Array(result["damage"])[0])["damage"]), 7.7)
			and is_equal_approx(float(field_runtime.timers[&"electric_field"]), 0.1875),
		"Electric Field Level 4 owns damage and cadence"
	)

	var orbit_build := _leveled_build(catalog, &"orbiting_blades", 4)
	var orbit_runtime := Runtime.new()
	target.pos = Vector2(Runtime.ORBIT_RADIUS, 0.0)
	result = orbit_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		orbit_build, [target], Callable(self, "_los")
	)
	_expect(
		is_equal_approx(float(Dictionary(Array(result["damage"])[0])["damage"]), 39.2)
			and is_equal_approx(
				float(orbit_runtime.orbit_target_cooldowns[target.id]), 0.4125
			),
		"Orbiting Blades Level 4 owns damage and cadence"
	)
	orbit_runtime.update(
		0.5, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		orbit_build, [target], Callable(self, "_los")
	)
	_expect(
		is_equal_approx(orbit_runtime.orbit_angle, 1.7)
			and is_equal_approx(Runtime.ORBIT_RADIUS, 112.0)
			and is_equal_approx(Runtime.ORBIT_BLADE_RADIUS, 52.0),
		"Orbiting Blades uses the authored 3.4 rad/s wide orbit and fixed geometry"
	)

	var mine_build := _leveled_build(catalog, &"drop_mines", 4)
	var mine_runtime := Runtime.new()
	target.pos = Vector2(-48.0, 0.0)
	result = mine_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		mine_build, [target], Callable(self, "_los")
	)
	_expect(
		is_equal_approx(float(Dictionary(Array(result["damage"])[0])["damage"]), 123.2)
			and is_equal_approx(float(mine_runtime.timers[&"drop_mines"]), 1.8),
		"Drop Mine Level 4 owns damage and cadence"
	)

	var laser_build := _leveled_build(catalog, &"auto_laser", 3)
	var laser_runtime := Runtime.new()
	target.pos = Vector2(120.0, 0.0)
	laser_runtime.record_primary_success(Vector2.ZERO, Vector2.RIGHT)
	result = laser_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		laser_build, [target], Callable(self, "_los")
	)
	_expect(
		is_equal_approx(float(Dictionary(Array(result["damage"])[0])["damage"]), 120.4)
			and is_equal_approx(laser_runtime.auto_laser_cooldown, 0.675),
		"Auto Laser Level 3 owns damage and cooldown"
	)

	var storm_build := _leveled_build(catalog, &"storm_barrage", 3)
	var storm_runtime := Runtime.new()
	target.pos = Vector2(600.0, 0.0)
	storm_runtime.update(
		0.0, Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT,
		storm_build, [target], Callable(self, "_los")
	)
	result = storm_runtime.update(
		Runtime.STORM_WARNING_DURATION, Vector2.ZERO,
		Vector2.RIGHT, Vector2.RIGHT, storm_build, [target],
		Callable(self, "_los")
	)
	_expect(
		is_equal_approx(float(Dictionary(Array(result["damage"])[0])["damage"]), 175.0)
			and is_equal_approx(storm_runtime.storm_cooldown, 2.825),
		"Storm Barrage Level 3 owns damage and cooldown"
	)


func _leveled_build(
	catalog: Catalog,
	weapon_card_id: StringName,
	weapon_level: int
) -> RunBuild:
	var build := RunBuild.new(catalog)
	for _level in weapon_level:
		build.apply(weapon_card_id)
	return build


func _validate_electric_field_radius(catalog: Catalog) -> void:
	var expected_radii := [240.0, 280.0, 320.0, 320.0]
	var build := RunBuild.new(catalog)
	var runtime := Runtime.new()
	var frame: Dictionary = {}
	for level_index in 4:
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
	var action_build := RunBuild.new(catalog)
	action_build.apply(&"electric_field")
	var action_runtime := Runtime.new()
	var targets: Array[EnemyState] = [
		_make_target("field_action_a", Vector2(60.0, 0.0)),
		_make_target("field_action_b", Vector2(90.0, 0.0)),
	]
	var action_damage: Array = action_runtime.update(
		0.25,
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.RIGHT,
		action_build,
		targets,
		Callable(self, "_los")
	)["damage"]
	_expect(
			action_damage.size() == 2
			and _shared_action_serial(action_damage) > 0
			and action_damage.all(
				func(intent_variant: Variant) -> bool: return int(
					Dictionary(intent_variant)["damage_flags"]
				) == OutgoingDamagePolicy.DAMAGE_PERIODIC
			),
		"one Electric Field tick shares one periodic action identity across targets"
	)


func _validate_homing_progression(catalog: Catalog) -> void:
	_seeker_targets.clear()
	for index in 4:
		var target := EnemyState.new()
		target.id = "homing_target_%d" % index
		target.alive = true
		target.active = true
		target.pos = Vector2(120.0 + float(index) * 40.0, 20.0 * float(index))
		_seeker_targets.append(target)
	var expected_damage := [25.0, 31.36, 40.0, 53.2]
	for upgrade_level in 5:
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
		var expected_count: int = 0 if upgrade_level == 0 else int([2, 3, 4, 4][upgrade_level - 1])
		_expect(
			_requested_seeker_count == expected_count
				and projectiles.size() == expected_count,
			"homing level %d requests and fires exactly %d distinct missiles"
			% [upgrade_level, expected_count]
		)
		var volley_action_serial := 0
		for projectile in projectiles:
			var action_serial := int(projectile.get("combat_action_serial", 0))
			if volley_action_serial <= 0:
				volley_action_serial = action_serial
			_expect(
				is_equal_approx(float(projectile["damage"]), expected_damage[upgrade_level - 1]),
				"homing level %d uses %.0f damage per missile"
				% [upgrade_level, expected_damage[upgrade_level - 1]]
			)
			_expect(
				projectile.get("damage_flags", -1)
					== OutgoingDamagePolicy.DAMAGE_DIRECT
					and projectile.has("spawn_origin")
					and int(projectile.get("attack_serial", 0)) > 0
					and projectile.get("combat_action_family", &"") == &"secondary"
					and action_serial == volley_action_serial,
				"one Seeker volley shares one direct secondary combat-action identity"
			)
			_expect(
				bool(projectile["explosive"]),
				"Seeker missiles publish their 95-unit explosive collision contract"
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
	var expected_damage := [48.0, 67.2, 90.0, 123.2]
	var expected_radius := [192.0, 216.0, 240.0, 240.0]
	for level_index in 4:
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
		var second_target := _make_target(
			"mine_second_target_%d" % level_index,
			target.pos + Vector2(28.0, 0.0)
		)
		var targets: Array[EnemyState] = [target, second_target]
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
		var effect_store := EffectStore.new()
		var detonation_effect = null
		if detonations.size() == 1:
			detonation_effect = effect_store.add_drop_mine_detonation(
				Vector2(detonations[0]["position"]),
				Color.WHITE,
				0.18,
				float(detonations[0]["radius"])
			)
		_expect(
			damage.size() == 2
			and is_equal_approx(float(damage[0]["damage"]), expected_damage[level_index])
			and damage[0].get("damage_flags", -1) == OutgoingDamagePolicy.DAMAGE_DIRECT
			and _shared_action_serial(damage) > 0
			and detonations.size() == 1
			and Vector2(detonations[0]["position"]) == target.pos
			and is_equal_approx(float(detonations[0]["radius"]), expected_radius[level_index])
			and int(detonations[0]["level"]) == level_index + 1
			and detonation_effect != null
			and is_equal_approx(
				float(detonation_effect.radius), expected_radius[level_index]
			),
			"Drop Mine level %d shares one action across targets and publishes one exact-radius effect receipt"
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
			float(Array(timeout_result["detonations"])[0]["radius"]), 192.0
		),
		"Drop Mine timeout emits its receipt even when it damages no target"
	)


func _validate_auto_laser(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	build.levels[&"auto_laser"] = 1
	var runtime := Runtime.new()
	var origin := Vector2(900.0, 640.0)
	var target := _make_target("rear_target", origin + Vector2.LEFT * 300.0)
	var second_target := _make_target(
		"rear_target_second", origin + Vector2.LEFT * 520.0
	)
	var targets: Array[EnemyState] = [target, second_target]
	runtime.reset(origin)
	runtime.record_primary_success(origin, Vector2.RIGHT)
	var result := runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		targets,
		Callable(self, "_los")
	)
	var beams: Array = result["beams"]
	var damage: Array = result["damage"]
	_expect(
		beams.size() == 1
			and Vector2(beams[0]["direction"]) == Vector2.LEFT
			and Vector2(beams[0]["origin"]) == origin
			and is_equal_approx(float(beams[0]["length"]), 760.0)
			and is_equal_approx(float(beams[0]["half_width"]), 18.0)
			and is_equal_approx(float(beams[0]["duration"]), 0.14)
			and Array(result["projectiles"]).is_empty(),
		"auto laser emits one best-direction 760-unit beam intent without a projectile"
	)
	_expect(
		damage.size() == 2
			and damage[0]["source"] == "Auto Laser"
			and damage[0].get("damage_flags", -1)
				== OutgoingDamagePolicy.DAMAGE_DIRECT
			and _shared_action_serial(damage) > 0
			and is_equal_approx(float(runtime.auto_laser_cooldown), 0.9),
		"one Auto Laser beam shares one direct action identity and owns a 0.9-second cooldown"
	)
	runtime.record_primary_success(origin, Vector2.RIGHT)
	var blocked := runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		targets,
		Callable(self, "_los")
	)
	_expect(Array(blocked["beams"]).is_empty(), "auto laser ignores primary success during cooldown")
	runtime.record_primary_success(origin, Vector2.RIGHT)
	var ready := runtime.update(
		0.9,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		targets,
		Callable(self, "_los")
	)
	_expect(Array(ready["beams"]).size() == 1, "auto laser fires again after its exact cooldown")
	runtime.reset(origin)
	target.pos = origin + Vector2.LEFT * 500.0
	second_target.pos = origin + Vector2.LEFT * 620.0
	runtime.record_primary_success(origin, Vector2.RIGHT)
	var clipped := runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		targets,
		Callable(self, "_los"),
		Callable(),
		Callable(),
		false,
		1.0,
		Callable(self, "_path_end"),
		Vector2.RIGHT
	)
	_expect(
		Array(clipped["beams"]).is_empty()
			and Array(clipped["damage"]).is_empty(),
		"auto laser rejects a direction whose targets are behind the first solid cover"
	)


func _validate_storm_barrage(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	build.levels[&"storm_barrage"] = 1
	_storm_targets.clear()
	for index in 20:
		var offset := Vector2(
			float(index % 5) * 12.0,
			float(floori(float(index) / 5.0)) * 12.0 - 24.0
		)
		_storm_targets.append(_make_target("storm_target_%02d" % index, Vector2(600.0, 0.0) + offset))
	var origin := Vector2.ZERO
	var runtime := Runtime.new()
	runtime.reset(origin)
	_storm_query_calls = 0
	var reserved := runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		_storm_targets,
		Callable(self, "_los"),
		Callable(self, "_query_storm_targets"),
		Callable(),
		false,
		1.0,
		Callable(),
		Vector2.RIGHT
	)
	_expect(
		Array(reserved["warnings"]).size() == 1
			and Array(reserved["damage"]).is_empty()
			and is_equal_approx(float(Dictionary(Array(reserved["warnings"])[0])["radius"]), 280.0)
			and runtime.storm_pending
			and is_equal_approx(runtime.storm_warning_remaining, 0.55)
			and is_equal_approx(runtime.storm_cooldown, 4.5)
			and _storm_query_calls == 1,
		"storm barrage reserves one 0.55-second warning only when 480-960 candidates exist"
	)
	var during := runtime.update(
		0.54,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		_storm_targets,
		Callable(self, "_los"),
		Callable(self, "_query_storm_targets")
	)
	_expect(
		runtime.storm_pending
			and Array(during["warnings"]).is_empty()
			and Array(during["damage"]).is_empty()
			and _storm_query_calls == 1,
		"storm barrage keeps one pending warning without rescanning before impact"
	)
	var impact := runtime.update(
		0.01,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		_storm_targets,
		Callable(self, "_los"),
		Callable(self, "_query_storm_targets")
	)
	var impact_damage: Array = impact["damage"]
	_expect(
		not runtime.storm_pending
			and Array(impact["impacts"]).size() == 1
			and is_equal_approx(float(Dictionary(Array(impact["impacts"])[0])["radius"]), 280.0)
			and impact_damage.size() == 12
			and _storm_query_calls == 2,
		"storm barrage performs one impact query and caps damage intents at twelve targets"
	)
	for intent_variant in impact_damage:
		var intent: Dictionary = intent_variant
		_expect(
			intent.get("damage_flags", -1)
				== OutgoingDamagePolicy.DAMAGE_DIRECT
			and int(intent.get("attack_serial", 0)) > 0,
			"storm damage intent carries direct flags and a stable serial"
		)
	_expect(
		_shared_action_serial(impact_damage) > 0,
		"one Storm Barrage impact shares one direct action identity across twelve targets"
	)
	var empty_runtime := Runtime.new()
	empty_runtime.reset(origin)
	_storm_targets.clear()
	var empty := empty_runtime.update(
		0.1,
		origin,
		Vector2.ZERO,
		Vector2.RIGHT,
		build,
		_storm_targets,
		Callable(self, "_los"),
		Callable(self, "_query_storm_targets")
	)
	_expect(
		not empty_runtime.storm_pending
			and is_zero_approx(empty_runtime.storm_cooldown)
			and Array(empty["warnings"]).is_empty(),
		"storm barrage remains cooldown-ready when no eligible candidate exists"
	)


func _make_target(target_id: String, position: Vector2, role: StringName = &"chaser") -> EnemyState:
	var target := EnemyState.new()
	target.id = target_id
	target.role = role
	target.alive = true
	target.active = true
	target.pos = position
	target.radius = 18.0
	return target


func _shared_action_serial(intents: Array) -> int:
	if intents.is_empty():
		return 0
	var serial := int(Dictionary(intents[0]).get("attack_serial", 0))
	if serial <= 0:
		return 0
	for intent_variant in intents:
		if int(Dictionary(intent_variant).get("attack_serial", 0)) != serial:
			return 0
	return serial


func _query_storm_targets(
	_center: Vector2,
	_radius: float,
	output: Array[EnemyState]
) -> void:
	_storm_query_calls += 1
	output.clear()
	for target in _storm_targets:
		output.append(target)


func _path_end(
	origin: Vector2,
	direction: Vector2,
	distance: float,
	_padding: float
) -> Vector2:
	return origin + direction.normalized() * minf(distance, 320.0)


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
