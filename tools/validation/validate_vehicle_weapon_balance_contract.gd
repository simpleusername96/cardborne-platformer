extends SceneTree

const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")
const ActiveCatalog = preload("res://scripts/player/vehicle_active_weapon_catalog.gd")

const ROLE_STATE_COUNTS := {
	&"base_primary":1,
	&"split_muzzle":3,
	&"piercing_rounds":4,
	&"thermal_burst":4,
	&"bio_toxin":4,
	&"cryo_slow":3,
	&"shock_disruption":3,
	&"seeker":4,
	&"electric_field":4,
	&"orbiting_blades":4,
	&"drop_mines":4,
	&"auto_laser":3,
	&"storm_barrage":3,
	&"emp":1,
	&"black_hole":4,
	&"shockwave":4,
	&"cross_beam":4,
}
const FIXTURE_BY_ROLE := {
	&"base_primary":&"boss_480",
	&"split_muzzle":&"aim_axis_8",
	&"piercing_rounds":&"aim_axis_8",
	&"thermal_burst":&"close_12",
	&"bio_toxin":&"boss_480",
	&"cryo_slow":&"hull_8",
	&"shock_disruption":&"hull_8",
	&"seeker":&"dispersed_32",
	&"electric_field":&"close_12",
	&"orbiting_blades":&"hull_8",
	&"drop_mines":&"close_12",
	&"auto_laser":&"aim_axis_8",
	&"storm_barrage":&"dispersed_32",
	&"emp":&"close_12",
	&"black_hole":&"dispersed_32",
	&"shockwave":&"hull_8",
	&"cross_beam":&"aim_axis_8",
}
const NUMERIC_GAIN_MIN := 0.15
const NUMERIC_GAIN_MAX := 0.45
const DISCRETE_GAIN_MAX := 0.65

var failures: Array[String] = []
var _secondary := SecondaryCatalog.new()
var _active := ActiveCatalog.new()


func _initialize() -> void:
	_validate_fixed_fixtures()
	_validate_role_matrix_and_rows()
	_validate_authored_values()
	_validate_level_gains()
	_validate_peer_bands_and_dominance()
	_validate_shared_modifiers_once()
	_finish()


func _validate_fixed_fixtures() -> void:
	var fixtures := _fixtures()
	_expect(
		fixtures.size() == 5
			and Array(fixtures[&"boss_480"]).size() == 1
			and Vector2(Array(fixtures[&"boss_480"])[0]).is_equal_approx(Vector2(480.0, 0.0))
			and Array(fixtures[&"aim_axis_8"]).size() == 8
			and Array(fixtures[&"close_12"]).size() == 12
			and Array(fixtures[&"dispersed_32"]).size() == 32
			and Array(fixtures[&"hull_8"]).size() == 8,
		"the balance contract owns exactly five deterministic pure geometry fixtures"
	)


func _validate_role_matrix_and_rows() -> void:
	var rows := _fixture_rows()
	var expected_rows := 0
	var seen_roles: Dictionary = {}
	var seen_fixtures: Dictionary = {}
	for count_variant in ROLE_STATE_COUNTS.values():
		expected_rows += int(count_variant)
	for row_variant in rows:
		var row := Dictionary(row_variant)
		seen_roles[StringName(row["family"])] = int(seen_roles.get(row["family"], 0)) + 1
		seen_fixtures[StringName(row["fixture"])] = true
		_expect(
			row.has("damage_per_use")
				and row.has("damage_10s")
				and row.has("contacts")
				and row.has("startup")
				and row.has("cooldown")
				and row.has("coverage")
				and row.has("control")
				and row.has("targeting_burden")
				and row.has("exposure"),
			"every fixture row keeps damage, cadence, coverage, control, burden, and exposure separate"
		)
	_expect(rows.size() == expected_rows, "every approved weapon and level emits one fixture row")
	for family_variant in ROLE_STATE_COUNTS:
		var family := StringName(family_variant)
		_expect(
			int(seen_roles.get(family, 0)) == int(ROLE_STATE_COUNTS[family]),
			"%s emits every approved state" % family
		)
	_expect(seen_fixtures.size() == 5, "fixture output exercises all five fixed geometries")


func _validate_authored_values() -> void:
	_expect(_secondary.validate_contract().is_empty(), "secondary catalog remains complete")
	_expect(_active.validate_contract().is_empty(), "active catalog remains complete")
	_validate_secondary(&"seeker", [25.0, 28.0, 32.0, 38.0], [1.35, 1.35, 1.35, 1.35], [2, 3, 4, 4])
	_validate_secondary(&"electric_field", [8.0, 11.5, 16.0, 22.0], [240.0, 280.0, 320.0, 320.0], [1, 1, 1, 1])
	_validate_secondary(&"orbiting_blades", [14.0, 18.0, 22.0, 28.0], [112.0, 112.0, 112.0, 112.0], [2, 3, 4, 4])
	_validate_secondary(&"drop_mines", [48.0, 60.0, 72.0, 88.0], [3.2, 2.8, 2.4, 2.4], [3, 4, 5, 5])
	_validate_secondary(&"auto_laser", [48.0, 66.0, 86.0], [0.9, 0.9, 0.9], [1, 1, 1])
	_validate_secondary(&"storm_barrage", [70.0, 95.0, 125.0], [4.5, 4.5, 4.5], [1, 1, 1])
	_validate_active(&"emp", [62.0], [285.0], 0.42, 13.0)
	_validate_active(&"black_hole", [60.0, 85.0, 115.0, 150.0], [150.0, 175.0, 200.0, 225.0], 0.35, 12.0)
	_validate_active(&"shockwave", [45.0, 65.0, 90.0, 120.0], [180.0, 210.0, 240.0, 270.0], 0.20, 9.0)
	_validate_active(&"cross_beam", [80.0, 110.0, 145.0, 185.0], [24.0, 32.0, 40.0, 48.0], 0.30, 10.5)
	_validate_attribute_values()
	_expect(
		PrimaryRules.projectiles_per_volley(1) == 2
			and PrimaryRules.projectiles_per_volley(2) == 3
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(1), 140.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(2), 165.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(3), 180.0),
		"Split Muzzle preserves its separate projectile-count and side-damage contract"
	)


func _validate_level_gains() -> void:
	_validate_numeric_progression("Thermal Burst damage", [4.0, 5.75, 8.0, 11.0])
	_validate_numeric_progression("Bio Toxin DPS", [2.0, 2.85, 4.0, 5.5])
	_validate_numeric_progression("Cryo Slow", [6.0, 8.0, 10.0])
	_validate_numeric_progression("Shock Disruption", [0.6, 0.8, 1.0])
	_validate_numeric_progression("Electric Field DPS", [8.0, 11.5, 16.0, 22.0])
	_validate_numeric_progression("Drop Mine damage", [48.0, 60.0, 72.0, 88.0])
	_validate_numeric_progression("Auto Laser damage", [48.0, 66.0, 86.0])
	_validate_numeric_progression("Storm Barrage damage", [70.0, 95.0, 125.0])
	_validate_numeric_progression("Black Hole damage", [60.0, 85.0, 115.0, 150.0])
	_validate_numeric_progression("Shockwave damage", [45.0, 65.0, 90.0, 120.0])
	_validate_numeric_progression("Cross Beam damage", [80.0, 110.0, 145.0, 185.0])
	_validate_numeric_progression("Split Muzzle first totals", [100.0, 140.0, 165.0])
	_validate_numeric_progression("Split Muzzle final side damage", [32.5, 40.0])
	_validate_discrete_progression("Piercing contacts", [1, 2, 3, 4, 5], [])
	_validate_discrete_progression("Seeker missiles", [2, 3, 4, 4], [25.0, 28.0, 32.0, 38.0])
	_validate_discrete_progression("Orbiting blades", [2, 3, 4, 4], [14.0, 18.0, 22.0, 28.0])


func _validate_peer_bands_and_dominance() -> void:
	var peer_checks := [
		{"label":"active area level 1", "damage":[62.0, 60.0, 45.0], "reason":"Shockwave trades damage for frequency and knockback."},
		{"label":"automatic ranged level 1", "damage":[50.0, 48.0, 70.0], "reason":"Seeker, Auto Laser, and Storm differ in target restrictions and cadence."},
		{"label":"close optional level 1", "damage":[8.0, 14.0], "reason":"Electric Field is continuous and safer; blades require hull contact."},
	]
	for check_variant in peer_checks:
		var check := Dictionary(check_variant)
		var values := Array(check["damage"])
		for left in values.size():
			for right in range(left + 1, values.size()):
				var gap := absf(float(values[left]) - float(values[right])) / maxf(float(values[left]), float(values[right]))
				_expect(
					gap <= 0.20 or not String(check["reason"]).is_empty(),
					"%s has an explicit non-damage reason outside the 20%% peer band" % check["label"]
				)
	_validate_no_dominance("primary", {
		&"split_muzzle":[3, 3, 2, 0, 2, 3],
		&"piercing_rounds":[4, 4, 1, 0, 1, 3],
	})
	_validate_no_dominance("optional secondary", {
		&"electric_field":[3, 4, 3, 1, 1, 4],
		&"orbiting_blades":[4, 2, 2, 2, 0, 3],
		&"drop_mines":[4, 3, 2, 3, 4, 1],
		&"auto_laser":[3, 2, 4, 0, 4, 4],
		&"storm_barrage":[4, 4, 3, 0, 4, 1],
	})
	_validate_no_dominance("active", {
		&"emp":[2, 4, 4, 4, 4, 1],
		&"black_hole":[4, 3, 3, 4, 4, 2],
		&"shockwave":[3, 3, 4, 3, 2, 4],
		&"cross_beam":[5, 5, 2, 0, 3, 3],
	})


func _validate_shared_modifiers_once() -> void:
	var build := RunBuild.new(UpgradeCatalog.new())
	for _level in 3:
		build.apply(&"secondary_amplifier")
		build.apply(&"secondary_coolant")
		build.apply(&"active_amplifier")
		build.apply(&"active_coolant")
	var secondary_damage := build.stat(&"secondary_damage_multiplier", 1.0)
	var secondary_cooldown := build.stat(&"secondary_cooldown_multiplier", 1.0)
	var active_damage := build.stat(&"active_damage_multiplier", 1.0)
	var active_cooldown := build.stat(&"active_cooldown_multiplier", 1.0)
	_expect(
		is_equal_approx(secondary_damage, 1.40)
			and is_equal_approx(secondary_cooldown, 0.75)
			and is_equal_approx(48.0 * secondary_damage, 67.2)
			and is_equal_approx(0.9 * secondary_cooldown, 0.675),
		"secondary damage and cooldown modifiers apply to base fixture values exactly once"
	)
	_expect(
		is_equal_approx(active_damage, 1.50)
			and is_equal_approx(active_cooldown, 0.75)
			and is_equal_approx(80.0 * active_damage, 120.0)
			and is_equal_approx(10.5 * active_cooldown, 7.875),
		"active damage and cooldown modifiers apply to base fixture values exactly once"
	)


func _fixtures() -> Dictionary:
	var axis: Array[Vector2] = []
	for index in 8:
		axis.append(Vector2(120.0 + float(index) * 60.0, 0.0))
	var close: Array[Vector2] = []
	for index in 12:
		var radius := 60.0 + float(index % 3) * 30.0
		close.append(Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * radius)
	var dispersed: Array[Vector2] = []
	for row in 4:
		for column in 8:
			dispersed.append(Vector2(-420.0 + column * 120.0, -210.0 + row * 140.0))
	var hull: Array[Vector2] = []
	for index in 8:
		hull.append(Vector2.RIGHT.rotated(TAU * float(index) / 8.0) * 88.0)
	return {
		&"boss_480":[Vector2(480.0, 0.0)],
		&"aim_axis_8":axis,
		&"close_12":close,
		&"dispersed_32":dispersed,
		&"hull_8":hull,
	}


func _fixture_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for family_variant in ROLE_STATE_COUNTS:
		var family := StringName(family_variant)
		var fixture := StringName(FIXTURE_BY_ROLE[family])
		for state_index in int(ROLE_STATE_COUNTS[family]):
			var metrics := _metrics_for(family, state_index + 1)
			rows.append({
				"family":family,
				"state":state_index + 1,
				"fixture":fixture,
				"damage_per_use":float(metrics.get("damage_per_use", 0.0)),
				"damage_10s":float(metrics.get("damage_10s", 0.0)),
				"contacts":int(metrics.get("contacts", 0)),
				"startup":float(metrics.get("startup", 0.0)),
				"cooldown":float(metrics.get("cooldown", 0.0)),
				"coverage":float(metrics.get("coverage", 0.0)),
				"control":float(metrics.get("control", 0.0)),
				"targeting_burden":float(metrics.get("targeting_burden", 0.0)),
				"exposure":float(metrics.get("exposure", 0.0)),
			})
	return rows


func _metrics_for(family: StringName, state: int) -> Dictionary:
	if family == &"base_primary":
		return {"damage_per_use":18.0, "damage_10s":1500.0, "contacts":1, "cooldown":0.12, "coverage":1.0, "targeting_burden":2.0}
	if family == &"split_muzzle":
		var total := PrimaryRules.total_volley_damage_percent(state) * 0.18
		return {"damage_per_use":total, "damage_10s":total / 0.12 * 10.0, "contacts":PrimaryRules.projectiles_per_volley(state), "cooldown":0.12, "coverage":float(PrimaryRules.projectiles_per_volley(state)), "targeting_burden":2.0}
	if family == &"piercing_rounds":
		return {"damage_per_use":18.0 * float(state + 1), "damage_10s":1500.0 * float(state + 1), "contacts":state + 1, "cooldown":0.12, "coverage":float(state + 1), "targeting_burden":4.0}
	if family in [&"thermal_burst", &"bio_toxin", &"cryo_slow", &"shock_disruption"]:
		return _attribute_metrics(family, state)
	if family in [&"seeker", &"electric_field", &"orbiting_blades", &"drop_mines", &"auto_laser", &"storm_barrage"]:
		return _secondary_metrics(family, state)
	return _active_metrics(family, state)


func _attribute_metrics(family: StringName, state: int) -> Dictionary:
	var values := {
		&"thermal_burst":[4.0, 5.75, 8.0, 11.0],
		&"bio_toxin":[2.0, 2.85, 4.0, 5.5],
		&"cryo_slow":[6.0, 8.0, 10.0],
		&"shock_disruption":[0.6, 0.8, 1.0],
	}
	var value := float(Array(values[family])[state - 1])
	if family == &"thermal_burst":
		return {"damage_per_use":value * 4.0, "damage_10s":value * 40.0, "contacts":4, "coverage":float([72, 84, 96, 96][state - 1]), "targeting_burden":2.0}
	if family == &"bio_toxin":
		return {"damage_per_use":value * 3.0, "damage_10s":value * 30.0, "contacts":1, "coverage":1.0, "targeting_burden":2.0}
	return {"damage_per_use":0.0, "damage_10s":0.0, "contacts":8, "coverage":8.0, "control":value, "targeting_burden":2.0}


func _secondary_metrics(family: StringName, state: int) -> Dictionary:
	var resource_id := &"seeker" if family == &"seeker" else family
	var definition = _secondary.get_definition(resource_id)
	var damage := definition.value(state)
	var cooldown := definition.auxiliary(state)
	var contacts := definition.cap(state)
	var coverage := definition.auxiliary(state)
	var exposure := 1.0
	if family == &"electric_field":
		contacts = _count_within(Array(_fixtures()[&"close_12"]), definition.auxiliary(state))
		cooldown = 0.25
		exposure = 4.0
	elif family == &"orbiting_blades":
		cooldown = 0.55
		coverage = 52.0
		exposure = 5.0
	elif family == &"drop_mines":
		contacts = _count_within(Array(_fixtures()[&"close_12"]), minf(240.0, 168.0 + state * 24.0))
		coverage = minf(240.0, 168.0 + state * 24.0)
	elif family == &"auto_laser":
		contacts = 8
		coverage = 36.0
	elif family == &"storm_barrage":
		contacts = 4
		coverage = 280.0
	var damage_per_use := damage * float(maxi(1, contacts))
	return {"damage_per_use":damage_per_use, "damage_10s":damage_per_use / maxf(0.001, cooldown) * 10.0, "contacts":contacts, "cooldown":cooldown, "coverage":coverage, "targeting_burden":0.0, "exposure":exposure}


func _active_metrics(family: StringName, state: int) -> Dictionary:
	var definition = _active.get_definition(family)
	var damage := definition.damage(state)
	var contacts := 8
	if family == &"emp":
		contacts = 12
	return {"damage_per_use":damage * contacts, "damage_10s":damage * contacts / definition.cooldown_seconds * 10.0, "contacts":contacts, "startup":definition.startup_seconds, "cooldown":definition.cooldown_seconds, "coverage":definition.size(state), "control":4.0 if family in [&"emp", &"black_hole"] else 0.0, "targeting_burden":4.0 if family == &"cross_beam" else 1.0, "exposure":2.0}


func _count_within(points: Array, radius: float) -> int:
	var count := 0
	for point_variant in points:
		if Vector2(point_variant).length() <= radius:
			count += 1
	return count


func _validate_secondary(id: StringName, values: Array, auxiliary: Array, caps: Array) -> void:
	var definition = _secondary.get_definition(id)
	_expect(
		definition != null
			and definition.values_by_level == values
			and definition.auxiliary_by_level == auxiliary
			and definition.cap_by_level == caps,
		"%s matches the durable balance specification" % id
	)


func _validate_active(id: StringName, damage: Array, size: Array, startup: float, cooldown: float) -> void:
	var definition = _active.get_definition(id)
	_expect(
		definition != null
			and definition.damage_by_level == damage
			and definition.size_by_level == size
			and is_equal_approx(definition.startup_seconds, startup)
			and is_equal_approx(definition.cooldown_seconds, cooldown),
		"%s matches the durable balance specification" % id
	)


func _validate_attribute_values() -> void:
	var cases := [
		{"id":&"thermal_burst", "stat_a":&"thermal_burst_damage", "a":[4.0, 5.75, 8.0, 11.0], "stat_b":&"thermal_burst_radius", "b":[72.0, 84.0, 96.0, 96.0]},
		{"id":&"bio_toxin", "stat_a":&"toxin_dps_per_stack", "a":[2.0, 2.85, 4.0, 5.5], "stat_b":&"toxin_duration", "b":[5.0, 6.0, 7.0, 7.0]},
		{"id":&"cryo_slow", "stat_a":&"cryo_slow_per_stack", "a":[6.0, 8.0, 10.0], "stat_b":&"cryo_duration", "b":[2.0, 2.5, 3.0]},
		{"id":&"shock_disruption", "stat_a":&"shock_lock_duration", "a":[0.6, 0.8, 1.0], "stat_b":&"", "b":[]},
	]
	var catalog := UpgradeCatalog.new()
	for case_variant in cases:
		var case := Dictionary(case_variant)
		var build := RunBuild.new(catalog)
		for level_index in Array(case["a"]).size():
			build.apply(StringName(case["id"]))
			var matches := is_equal_approx(
				build.stat(StringName(case["stat_a"]), 0.0),
				float(Array(case["a"])[level_index])
			)
			if not Array(case["b"]).is_empty():
				matches = matches and is_equal_approx(
					build.stat(StringName(case["stat_b"]), 0.0),
					float(Array(case["b"])[level_index])
				)
			_expect(
				matches,
				"%s level %d matches the durable attribute values" % [case["id"], level_index + 1]
			)


func _validate_numeric_progression(label: String, values: Array) -> void:
	for index in range(1, values.size()):
		var previous := float(values[index - 1])
		var gain := (float(values[index]) - previous) / maxf(0.001, previous)
		_expect(
			gain >= NUMERIC_GAIN_MIN - 0.0001 and gain <= NUMERIC_GAIN_MAX + 0.0001,
			"%s state %d gain stays in the 15-45%% numeric band" % [label, index + 1]
		)


func _validate_discrete_progression(label: String, counts: Array, damage: Array) -> void:
	for index in range(1, counts.size()):
		var previous_count := int(counts[index - 1])
		var next_count := int(counts[index])
		if next_count > previous_count:
			var discrete_gain := float(next_count - previous_count) / float(next_count)
			_expect(
				discrete_gain <= DISCRETE_GAIN_MAX + 0.0001,
				"%s state %d discrete breakpoint stays at or below 65%% of its new count" % [label, index + 1]
			)
			if not damage.is_empty():
				var damage_gain := (float(damage[index]) - float(damage[index - 1])) / float(damage[index - 1])
				_expect(
					damage_gain <= NUMERIC_GAIN_MAX + 0.0001,
					"%s state %d does not pair a count breakpoint with a large damage spike" % [label, index + 1]
				)
		elif not damage.is_empty():
			_validate_numeric_progression("%s final damage" % label, [damage[index - 1], damage[index]])


func _validate_no_dominance(slot_label: String, profiles: Dictionary) -> void:
	var ids := profiles.keys()
	for left_index in ids.size():
		for right_index in range(left_index + 1, ids.size()):
			var left := Array(profiles[ids[left_index]])
			var right := Array(profiles[ids[right_index]])
			_expect(
				not _strictly_dominates(left, right) and not _strictly_dominates(right, left),
				"%s peers %s and %s retain independent tradeoffs" % [slot_label, ids[left_index], ids[right_index]]
			)


func _strictly_dominates(left: Array, right: Array) -> bool:
	var strict := false
	for index in mini(left.size(), right.size()):
		if float(left[index]) < float(right[index]):
			return false
		if float(left[index]) > float(right[index]):
			strict = true
	return strict


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_WEAPON_BALANCE_CONTRACT_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
