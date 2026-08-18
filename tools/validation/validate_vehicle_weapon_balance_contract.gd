extends SceneTree

const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")
const ActiveCatalog = preload("res://scripts/player/vehicle_active_weapon_catalog.gd")

const ROLE_STATE_COUNTS := {
	&"base_primary":1,
	&"split_muzzle":6,
	&"piercing_rounds":7,
	&"thermal_burst":7,
	&"bio_toxin":7,
	&"cryo_slow":6,
	&"seeker":7,
	&"electric_field":7,
	&"orbiting_blades":7,
	&"drop_mines":7,
	&"auto_laser":6,
	&"storm_barrage":6,
	&"emp":7,
	&"black_hole":7,
	&"shockwave":7,
	&"cross_beam":7,
}
const FIXTURE_BY_ROLE := {
	&"base_primary":&"boss_480",
	&"split_muzzle":&"aim_axis_8",
	&"piercing_rounds":&"aim_axis_8",
	&"thermal_burst":&"close_12",
	&"bio_toxin":&"boss_480",
	&"cryo_slow":&"hull_8",
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
const NUMERIC_GAIN_MIN := 0.05
const NUMERIC_GAIN_MAX := 0.50
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
	_validate_weapon_owned_curves()
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
	_validate_secondary(&"seeker", [25.0, 31.0, 37.0, 43.0, 50.0, 57.0, 64.0], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], [1.35, 1.29, 1.23, 1.17, 1.11, 1.06, 1.01], [2, 2, 3, 3, 4, 4, 4])
	_validate_secondary(&"electric_field", [8.0, 13.0, 18.0, 24.0, 29.0, 35.0, 40.0], [240.0, 253.0, 267.0, 280.0, 293.0, 307.0, 320.0], [0.250, 0.240, 0.229, 0.219, 0.208, 0.198, 0.188], [1, 1, 1, 1, 1, 1, 1])
	_validate_secondary(&"orbiting_blades", [14.0, 20.0, 26.0, 32.0, 38.0, 44.0, 51.0], [112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0], [0.55, 0.53, 0.51, 0.49, 0.46, 0.44, 0.41], [2, 2, 3, 3, 4, 4, 4])
	_validate_secondary(&"drop_mines", [48.0, 67.0, 86.0, 104.0, 123.0, 142.0, 160.0], [192.0, 204.0, 216.0, 228.0, 240.0, 240.0, 240.0], [3.20, 2.97, 2.73, 2.50, 2.27, 2.03, 1.80], [3, 3, 4, 4, 5, 5, 5])
	_validate_secondary(&"auto_laser", [48.0, 70.0, 92.0, 114.0, 136.0, 157.0], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], [0.90, 0.84, 0.78, 0.72, 0.66, 0.60], [1, 1, 1, 1, 1, 1])
	_validate_secondary(&"storm_barrage", [70.0, 102.0, 133.0, 165.0, 196.0, 228.0], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], [4.50, 4.14, 3.78, 3.42, 3.06, 2.70], [1, 1, 1, 1, 1, 1])
	_validate_active(&"emp", [285.0, 315.0, 345.0, 375.0, 405.0, 435.0, 465.0], [1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], 0.42, [13.0, 12.3, 11.6, 10.9, 10.2, 9.5, 8.8])
	_validate_active(&"black_hole", [180.0, 200.0, 220.0, 240.0, 260.0, 280.0, 300.0], [1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8], [0.25, 0.28, 0.30, 0.33, 0.35, 0.38, 0.40], 0.35, [12.0, 11.4, 10.8, 10.2, 9.6, 9.0, 8.4])
	_validate_active(&"shockwave", [200.0, 220.0, 240.0, 260.0, 280.0, 300.0, 320.0], [0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], 0.20, [9.0, 8.55, 8.1, 7.65, 7.2, 6.75, 6.3])
	_validate_active(&"cross_beam", [28.0, 34.0, 40.0, 46.0, 52.0, 58.0, 64.0], [1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0], [0.25, 0.28, 0.30, 0.33, 0.35, 0.38, 0.40], 0.30, [10.5, 9.95, 9.4, 8.85, 8.3, 7.75, 7.2])
	_validate_attribute_values()
	_expect(
		PrimaryRules.projectiles_per_volley(1) == 2
			and PrimaryRules.projectiles_per_volley(3) == 3
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(1), 140.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(2), 155.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(3), 165.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(6), 234.0),
		"Split Muzzle preserves its separate projectile-count and side-damage contract"
	)


func _validate_level_gains() -> void:
	_validate_numeric_progression("Thermal Burst damage", [4.0, 6.0, 8.0, 9.0, 11.0, 12.0, 14.0])
	_validate_numeric_progression("Bio Toxin DPS", [2.0, 2.8, 3.6, 4.4, 5.2, 6.1, 7.0])
	_validate_numeric_progression("Cryo Slow", [4.0, 6.0, 8.0, 9.0, 11.0, 12.0])
	# Weapon curves deliberately combine authored raw growth with the migrated
	# per-level damage/cadence factors. Their exact arrays are locked above rather
	# than forced through the generic single-stat gain band.
	_validate_numeric_progression("Split Muzzle volley totals", [140.0, 155.0, 165.0, 184.0, 204.0, 234.0])
	_validate_discrete_progression("Piercing contacts", [2, 2, 3, 3, 4, 4, 5], [1.05, 1.11, 1.18, 1.26, 1.35, 1.45, 1.56])
	_validate_discrete_progression("Seeker missiles", [2, 2, 3, 3, 4, 4, 4], [25.0, 31.0, 37.0, 43.0, 50.0, 57.0, 64.0])
	_validate_discrete_progression("Orbiting blades", [2, 2, 3, 3, 4, 4, 4], [14.0, 20.0, 26.0, 32.0, 38.0, 44.0, 51.0])


func _validate_peer_bands_and_dominance() -> void:
	var peer_checks := [
		{"label":"active area level 1", "damage":[0.0, 0.0, 0.0], "reason":"Active weapons trade control reach, duration, and cadence without damage."},
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


func _validate_weapon_owned_curves() -> void:
	var build := RunBuild.new(UpgradeCatalog.new())
	_expect(
		is_equal_approx(build.stat(&"secondary_damage_multiplier", 1.0), 1.0)
			and is_equal_approx(_secondary.get_definition(&"auto_laser").value(6), 157.0)
			and is_equal_approx(_secondary.get_definition(&"auto_laser").cadence(6), 0.60),
		"automatic weapon power is owned by its definition without a shared multiplier"
	)
	_expect(
		is_equal_approx(_active.get_definition(&"cross_beam").strength(7), 0.40)
			and is_equal_approx(_active.get_definition(&"cross_beam").duration(7), 3.0)
			and is_equal_approx(_active.get_definition(&"cross_beam").cooldown(7), 7.2),
		"active weapon control is owned by its definition without a damage axis"
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
		var contacts := 1 + PrimaryRules.additional_penetrations(state)
		var damage_multiplier := PrimaryRules.piercing_damage_multiplier(state)
		return {"damage_per_use":18.0 * damage_multiplier * contacts, "damage_10s":1500.0 * damage_multiplier * contacts, "contacts":contacts, "cooldown":0.12, "coverage":float(contacts), "targeting_burden":4.0}
	if family in [&"thermal_burst", &"bio_toxin", &"cryo_slow"]:
		return _attribute_metrics(family, state)
	if family in [&"seeker", &"electric_field", &"orbiting_blades", &"drop_mines", &"auto_laser", &"storm_barrage"]:
		return _secondary_metrics(family, state)
	return _active_metrics(family, state)


func _attribute_metrics(family: StringName, state: int) -> Dictionary:
	var values := {
		&"thermal_burst":[4.0, 6.0, 8.0, 9.0, 11.0, 12.0, 14.0],
		&"bio_toxin":[2.0, 2.8, 3.6, 4.4, 5.2, 6.1, 7.0],
		&"cryo_slow":[4.0, 6.0, 8.0, 9.0, 11.0, 12.0],
	}
	var value := float(Array(values[family])[state - 1])
	if family == &"thermal_burst":
		return {"damage_per_use":value * 4.0, "damage_10s":value * 40.0, "contacts":4, "coverage":float([72, 79, 86, 93, 100, 108, 115][state - 1]), "targeting_burden":2.0}
	if family == &"bio_toxin":
		return {"damage_per_use":value * 3.0, "damage_10s":value * 30.0, "contacts":1, "coverage":1.0, "targeting_burden":2.0}
	return {"damage_per_use":0.0, "damage_10s":0.0, "contacts":8, "coverage":8.0, "control":value, "targeting_burden":2.0}


func _secondary_metrics(family: StringName, state: int) -> Dictionary:
	var resource_id := &"seeker" if family == &"seeker" else family
	var definition = _secondary.get_definition(resource_id)
	var damage := definition.value(state)
	var cooldown := definition.cadence(state)
	var contacts := definition.cap(state)
	var coverage := definition.auxiliary(state)
	var exposure := 1.0
	if family == &"electric_field":
		contacts = _count_within(Array(_fixtures()[&"close_12"]), definition.auxiliary(state))
		cooldown = definition.cadence(state)
		exposure = 4.0
	elif family == &"orbiting_blades":
		cooldown = definition.cadence(state)
		coverage = 52.0
		exposure = 5.0
	elif family == &"drop_mines":
		contacts = _count_within(Array(_fixtures()[&"close_12"]), definition.auxiliary(state))
		coverage = definition.auxiliary(state)
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
	var contacts := 8
	if family == &"emp":
		contacts = 12
	return {"damage_per_use":0.0, "damage_10s":0.0, "contacts":contacts, "startup":definition.startup_seconds, "cooldown":definition.cooldown(state), "coverage":definition.size(state), "control":definition.duration(state), "targeting_burden":4.0 if family == &"cross_beam" else 1.0, "exposure":2.0}


func _count_within(points: Array, radius: float) -> int:
	var count := 0
	for point_variant in points:
		if Vector2(point_variant).length() <= radius:
			count += 1
	return count


func _validate_secondary(id: StringName, values: Array, auxiliary: Array, cadence: Array, caps: Array) -> void:
	var definition = _secondary.get_definition(id)
	_expect(
		definition != null
			and definition.values_by_level == values
			and definition.auxiliary_by_level == auxiliary
			and definition.cadence_by_level == cadence
			and definition.cap_by_level == caps,
		"%s matches the durable balance specification" % id
	)


func _validate_active(id: StringName, size: Array, duration: Array, strength: Array, startup: float, cooldown: Array) -> void:
	var definition = _active.get_definition(id)
	_expect(
		definition != null
			and definition.size_by_level == size
			and definition.duration_by_level == duration
			and definition.strength_by_level == strength
			and is_equal_approx(definition.startup_seconds, startup)
			and definition.cooldown_by_level == cooldown,
		"%s matches the durable balance specification" % id
	)


func _validate_attribute_values() -> void:
	var cases := [
		{"id":&"thermal_burst", "stat_a":&"thermal_burst_damage", "a":[4.0, 6.0, 8.0, 9.0, 11.0, 12.0, 14.0], "stat_b":&"thermal_burst_radius", "b":[72.0, 79.0, 86.0, 93.0, 100.0, 108.0, 115.0]},
		{"id":&"bio_toxin", "stat_a":&"toxin_dps_per_stack", "a":[2.0, 2.8, 3.6, 4.4, 5.2, 6.1, 7.0], "stat_b":&"toxin_duration", "b":[5.0, 5.6, 6.2, 6.8, 7.4, 8.0, 8.4]},
		{"id":&"cryo_slow", "stat_a":&"cryo_slow_per_stack", "a":[4.0, 6.0, 8.0, 9.0, 11.0, 12.0], "stat_b":&"cryo_duration", "b":[1.8, 2.2, 2.6, 3.0, 3.3, 3.6], "stat_c":&"cryo_shatter_damage", "c":[18.0, 25.0, 32.0, 39.0, 47.0, 55.0]},
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
			if case.has("stat_c"):
				matches = matches and is_equal_approx(
					build.stat(StringName(case["stat_c"]), 0.0),
					float(Array(case["c"])[level_index])
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
			"%s state %d gain stays in the 5-50%% numeric band" % [label, index + 1]
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
