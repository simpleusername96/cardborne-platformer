extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const ElementProfile = preload("res://scripts/combat/vehicle_element_profile.gd")
const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")

const RETIRED_IDS: Array[StringName] = [
	&"accelerator_coil", &"aegis_cycle", &"concentrated_toxin", &"contagion",
	&"coolant_wake", &"cryo_core", &"emp_aftershock", &"forked_muzzle",
	&"dash_capacitor", &"deep_freeze", &"emp_capacitor", &"emp_focus",
	&"escort_drone", &"hunter_firmware", &"incendiary_core", &"ion_field",
	&"ion_wake", &"kinetic_rounds", &"marked_salvo", &"mass_driver",
	&"orbit_blades", &"overclock_cycle", &"phase_lance", &"phase_seeker",
	&"phase_shear", &"pickup_magnet", &"ram_pulse", &"rapid_cycle",
	&"reinforced_hull", &"relay_overload", &"ricochet_matrix", &"seeker_cycle",
	&"seeker_warhead", &"siphon_matrix", &"stabilizer", &"static_aegis",
	&"thermal_compound", &"toxin_core", &"tuned_thrusters", &"twin_seekers",
	&"wake_mines",
]

var failures: Array[String] = []


func _initialize() -> void:
	_expect(
		Catalog._source_resource_name("example.tres.remap") == "example.tres",
		"exported remap entries resolve to source resource paths"
	)
	_expect(
		Catalog._source_resource_name("example.tres") == "example.tres",
		"source-tree resource entries remain unchanged"
	)
	_expect(
		Catalog._source_resource_name("example.png").is_empty(),
		"unrelated catalog files remain excluded"
	)
	var catalog := Catalog.new()
	for error in catalog.validate_contract():
		failures.append(error)
	_expect(catalog.definitions.size() == 21, "catalog contains exactly 21 upgrades")
	_validate_presentation(catalog)
	_validate_behavior_previews(catalog)
	_validate_secondary_slots(catalog)
	_validate_element_lock(catalog)
	_validate_offers(catalog)
	_validate_stats(catalog)
	for retired_id in RETIRED_IDS:
		_expect(
			catalog.get_definition(retired_id) == null,
			"%s is absent from the minimal catalog" % retired_id
		)
	_finish()


func _validate_presentation(catalog: Catalog) -> void:
	var state_count := 0
	var category_counts := {}
	for definition in catalog.all_definitions():
		category_counts[definition.category] = int(
			category_counts.get(definition.category, 0)
		) + 1
		for current_level in definition.max_level:
			var snapshot := OfferPresenter.snapshot(definition, current_level)
			_expect(
				not String(snapshot["description_key"]).is_empty()
					and not String(snapshot["category_key"]).is_empty(),
				"%s level %d has category and description text"
				% [definition.id, current_level + 1]
			)
			_expect(
				Array(snapshot["effect_rows"]).size() >= 1
					and Array(snapshot["effect_rows"]).size() <= 2,
				"%s level %d has one or two effect rows"
				% [definition.id, current_level + 1]
			)
			var expected_kind := (
				&"stats"
				if not definition.modifiers.is_empty() and definition.category != &"element"
				else (
					&"enhance"
					if definition.secondary_slot_kind == &"built_in"
					else (&"unlock" if current_level == 0 else &"enhance")
				)
			)
			_expect(
				StringName(snapshot["change_kind"]) == expected_kind,
				"%s level %d exposes its level-specific change kind"
				% [definition.id, current_level + 1]
			)
			if expected_kind != &"stats":
				_expect(
					not String(snapshot["change_label_key"]).is_empty(),
					"%s behavior level has a localized change label" % definition.id
				)
			state_count += 1
	_expect(state_count == 68, "upgrade presentation covers all 68 level states")
	_expect(
		category_counts == {
			&"primary":2, &"secondary":6, &"element":3, &"chassis":5,
			&"combat":5,
		},
		"five player-facing categories own the exact expanded roster"
	)


func _validate_behavior_previews(catalog: Catalog) -> void:
	_expect(
		PrimaryRules.projectiles_per_volley(0) == 1
			and PrimaryRules.projectiles_per_volley(1) == 2
			and PrimaryRules.projectiles_per_volley(2) == 3
			and PrimaryRules.projectiles_per_volley(3) == 3
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(0), 100.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(1), 140.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(2), 165.0)
			and is_equal_approx(PrimaryRules.total_volley_damage_percent(3), 180.0)
			and PrimaryRules.additional_penetrations(4) == 4,
		"primary gameplay rules own the exact Split and Pierce sequences"
	)
	var cases := [
		{
			"id":&"split_muzzle",
			"keys":["UPGRADE_EFFECT_PROJECTILES_PER_VOLLEY", "UPGRADE_EFFECT_TOTAL_VOLLEY_DAMAGE"],
			"current":[[1.0, 2.0, 3.0], [100.0, 140.0, 165.0]],
			"next":[[2.0, 3.0, 3.0], [140.0, 165.0, 180.0]],
			"show":[true, true, true],
		},
		{
			"id":&"piercing_rounds",
			"keys":["UPGRADE_EFFECT_ADDITIONAL_PENETRATIONS"],
			"current":[[0.0, 1.0, 2.0, 3.0]],
			"next":[[1.0, 2.0, 3.0, 4.0]],
			"show":[true, true, true, true],
		},
		{
			"id":&"homing_missiles",
			"keys":["UPGRADE_EFFECT_MISSILES_PER_VOLLEY", "UPGRADE_EFFECT_DAMAGE_PER_MISSILE"],
			"current":[[1.0, 2.0, 3.0], [25.0, 28.0, 32.0]],
			"next":[[2.0, 3.0, 3.0], [28.0, 32.0, 38.0]],
			"show":[true, true, true],
		},
		{
			"id":&"electric_field",
			"keys":["UPGRADE_EFFECT_DPS", "UPGRADE_EFFECT_RADIUS"],
			"current":[[8.0, 8.0, 12.0, 16.0], [120.0, 120.0, 140.0, 160.0]],
			"next":[[8.0, 12.0, 16.0, 22.0], [120.0, 140.0, 160.0, 160.0]],
			"show":[false, true, true, true],
		},
		{
			"id":&"orbiting_blades",
			"keys":["UPGRADE_EFFECT_BLADE_COUNT", "UPGRADE_EFFECT_DAMAGE_PER_BLADE"],
			"current":[[2.0, 2.0, 3.0, 4.0], [14.0, 14.0, 18.0, 22.0]],
			"next":[[2.0, 3.0, 4.0, 4.0], [14.0, 18.0, 22.0, 28.0]],
			"show":[false, true, true, true],
		},
		{
			"id":&"drop_mines",
			"keys":["UPGRADE_EFFECT_DAMAGE", "UPGRADE_EFFECT_DEPLOYMENT_INTERVAL"],
			"current":[[48.0, 48.0, 60.0, 72.0], [3.2, 3.2, 2.8, 2.4]],
			"next":[[48.0, 60.0, 72.0, 88.0], [3.2, 2.8, 2.4, 2.4]],
			"show":[false, true, true, true],
		},
	]
	for case_variant in cases:
		var case := Dictionary(case_variant)
		var definition := catalog.get_definition(StringName(case["id"]))
		for current_level in definition.max_level:
			var snapshot := OfferPresenter.snapshot(definition, current_level)
			var rows: Array = snapshot["effect_rows"]
			_expect(
				rows.size() == Array(case["keys"]).size(),
				"%s level %d publishes the expected row count"
				% [case["id"], current_level + 1]
			)
			for row_index in mini(rows.size(), Array(case["keys"]).size()):
				var row := Dictionary(rows[row_index])
				_expect(
					String(row["stat_key"]) == String(Array(case["keys"])[row_index])
						and is_equal_approx(
							float(row["current"]),
							float(Array(Array(case["current"])[row_index])[current_level])
						)
						and is_equal_approx(
							float(row["next"]),
							float(Array(Array(case["next"])[row_index])[current_level])
						)
						and bool(row["show_current"]) == bool(Array(case["show"])[current_level]),
					"%s level %d row %d matches gameplay-owned values"
					% [case["id"], current_level + 1, row_index + 1]
				)
	var enhancement_keys := {
		&"thermal_burst":"UPGRADE_THERMAL_BURST_ENHANCE_DESC",
		&"bio_toxin":"UPGRADE_BIO_TOXIN_ENHANCE_DESC",
		&"cryo_slow":"UPGRADE_CRYO_SLOW_ENHANCE_DESC",
	}
	for upgrade_id_variant in enhancement_keys:
		var upgrade_id := StringName(upgrade_id_variant)
		var definition := catalog.get_definition(upgrade_id)
		_expect(
			String(OfferPresenter.snapshot(definition, 0)["description_key"])
				== definition.description_key
				and String(OfferPresenter.snapshot(definition, 1)["description_key"])
					== String(enhancement_keys[upgrade_id]),
			"%s switches from unlock to enhancement summary" % upgrade_id
		)


func _validate_secondary_slots(catalog: Catalog) -> void:
	var optional_ids: Array[StringName] = []
	var built_in_ids: Array[StringName] = []
	for definition in catalog.all_definitions():
		if definition.category != &"secondary":
			continue
		if definition.secondary_slot_kind == &"optional":
			optional_ids.append(definition.id)
		elif definition.secondary_slot_kind == &"built_in":
			built_in_ids.append(definition.id)
	optional_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	built_in_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	_expect(
		_id_key(optional_ids) == "drop_mines|electric_field|orbiting_blades|rear_laser|storm_barrage",
		"five optional secondary identities support a choose-two decision: %s"
		% _id_key(optional_ids)
	)
	_expect(
		_id_key(built_in_ids) == "homing_missiles",
		"one built-in homing behavior card does not consume a slot: %s"
		% _id_key(built_in_ids)
	)
	var build := RunBuild.new(catalog)
	build.apply(&"electric_field")
	build.apply(&"orbiting_blades")
	_expect(build.active_optional_secondaries() == 2, "two optional slots are occupied")
	_expect(
		not catalog.compatible(catalog.get_definition(&"drop_mines"), build),
		"a third optional secondary is blocked"
	)
	_expect(
		catalog.compatible(catalog.get_definition(&"electric_field"), build),
		"an owned optional secondary remains levelable"
	)


func _validate_element_lock(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	_expect(
		catalog.compatible(catalog.get_definition(&"thermal_burst"), build)
			and catalog.compatible(catalog.get_definition(&"bio_toxin"), build)
			and catalog.compatible(catalog.get_definition(&"cryo_slow"), build),
		"all three elemental roots are legal before selection"
	)
	_expect(bool(build.apply(&"bio_toxin").get("applied", false)), "one element can be selected")
	_expect(
		build.active_element_id() == &"bio_toxin"
			and catalog.compatible(catalog.get_definition(&"bio_toxin"), build)
			and not catalog.compatible(catalog.get_definition(&"thermal_burst"), build)
			and not catalog.compatible(catalog.get_definition(&"cryo_slow"), build),
		"the selected element remains levelable and excludes other roots"
	)
	for serial in 12:
		for definition in catalog.offer(build, 1701, 3, &"level_up", serial):
			_expect(
				definition.category != &"element" or definition.id == &"bio_toxin",
				"post-selection offers contain only the active element"
			)


func _validate_offers(catalog: Catalog) -> void:
	var empty_build := RunBuild.new(catalog)
	for run_seed in 24:
		for source_id in [&"level_up", &"boss"]:
			var offer := catalog.offer(
				empty_build, run_seed, run_seed % 5, source_id, run_seed
			)
			_expect(
				offer.size() == 3 and _offer_is_legal(offer, empty_build, catalog),
				"fresh offer has three legal cards"
			)
		var late_offer := catalog.offer(
			empty_build, run_seed, 2, &"level_up", run_seed
		)
		_expect(
			late_offer.any(func(definition: VehicleUpgradeDefinition) -> bool: return Catalog.ATTACK_UPGRADE_IDS.has(definition.id)),
			"Stage 3+ offer guarantees one legal unfinished attack upgrade"
		)
	var stable_offer_a := catalog.offer(empty_build, 0xCA4D, 1, &"level_up", 7)
	var stable_offer_b := catalog.offer(empty_build, 0xCA4D, 1, &"level_up", 7)
	_expect(
		_offer_key(stable_offer_a) == _offer_key(stable_offer_b),
		"one reward transaction remains stable for the same seed and serial"
	)
	for run_seed in 24:
		var build := RunBuild.new(catalog)
		var legal_choices := 0
		var observed_sizes := {}
		for choice_index in 60:
			var source_id := &"boss" if choice_index in [4, 9, 14, 19, 24] else &"level_up"
			var offer := catalog.offer(
				build,
				0xCA4D + run_seed,
				mini(4, choice_index / 5),
				source_id,
				choice_index
			)
			if offer.is_empty():
				break
			_expect(
				_offer_is_legal(offer, build, catalog),
				"seed %d choice %d contains one to three compatible cards"
				% [run_seed, choice_index + 1]
			)
			observed_sizes[offer.size()] = true
			legal_choices += 1
			build.apply(offer[run_seed % offer.size()].id)
		_expect(
			legal_choices >= 48
				and legal_choices <= 51
				and catalog.compatible_definitions(build).is_empty(),
			(
				"seed %d reaches catalog exhaustion after all legal choices "
					+ "(choices=%d, remaining=%d)"
			)
			% [
				run_seed,
				legal_choices,
				catalog.compatible_definitions(build).size(),
			]
		)
		_expect(
			observed_sizes.has(1) and observed_sizes.has(2) and observed_sizes.has(3),
			"seed %d exposes three-, two-, and one-card offers at the reachable tail"
			% run_seed
		)


func _validate_stats(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	var expected_speeds := [280.0, 302.4, 324.8, 347.2]
	_expect(
		is_equal_approx(build.stat(&"move_speed_multiplier", 280.0), expected_speeds[0]),
		"base movement is 280"
	)
	for level in 3:
		_expect(bool(build.apply(&"chassis_speed").get("applied", false)), "Movement Speed level applies")
		_expect(
			is_equal_approx(
				build.stat(&"move_speed_multiplier", 280.0),
				expected_speeds[level + 1]
			),
			"Movement Speed uses its exact level speed"
		)
	build.reset()
	for _level in 3:
		build.apply(&"pickup_radius")
	_expect(
		is_equal_approx(build.stat(&"pickup_radius_bonus", 0.0), 210.0),
		"Pickup Radius preserves the three-level +210 collection behavior"
	)
	build.reset()
	_expect(
		is_equal_approx(build.stat(&"lifesteal_percent", 0.0), 0.0),
		"the build stores no card bonus before Lifesteal is acquired"
	)
	var lifesteal_definition = catalog.get_definition(&"lifesteal")
	var lifesteal_snapshot := OfferPresenter.snapshot(lifesteal_definition, 0)
	_expect(
		is_equal_approx(
			float(lifesteal_snapshot["effect_rows"][0]["current"]),
			0.5
		),
		"Lifesteal presents the built-in half-percent rate before level one"
	)
	for expected_percent in [2.0, 3.5]:
		_expect(bool(build.apply(&"lifesteal").get("applied", false)), "Lifesteal level applies")
		_expect(
			is_equal_approx(
				build.stat(&"lifesteal_percent", 0.0),
				expected_percent
			),
			"Lifesteal exposes its exact damage-healing percentage"
		)
	_validate_element_stats(catalog)


func _validate_element_stats(catalog: Catalog) -> void:
	var cases := [
		{
			"id":&"thermal_burst",
			"stat_a":&"thermal_burst_radius", "a":[72.0, 84.0, 96.0, 96.0],
			"stat_b":&"thermal_burst_damage", "b":[4.0, 6.0, 8.0, 11.0],
		},
		{
			"id":&"bio_toxin",
			"stat_a":&"toxin_dps_per_stack", "a":[2.0, 3.0, 4.0, 5.5],
			"stat_b":&"toxin_duration", "b":[5.0, 6.0, 7.0, 7.0],
		},
		{
			"id":&"cryo_slow",
			"stat_a":&"cryo_slow_per_stack", "a":[6.0, 8.0, 10.0],
			"stat_b":&"cryo_duration", "b":[2.0, 2.5, 3.0],
		},
	]
	for case_variant in cases:
		var case := Dictionary(case_variant)
		var build := RunBuild.new(catalog)
		var definition := catalog.get_definition(StringName(case["id"]))
		var first_snapshot := OfferPresenter.snapshot(definition, 0)
		_expect(
			StringName(first_snapshot["change_kind"]) == &"unlock"
				and Array(first_snapshot["effect_rows"]).all(
					func(row: Dictionary) -> bool: return not bool(row["show_current"])
				),
			"%s first acquisition exposes initial values without false zero deltas"
			% case["id"]
		)
		for level in definition.max_level:
			build.apply(StringName(case["id"]))
			var profile := ElementProfile.from_build(build)
			_expect(
				is_equal_approx(build.stat(StringName(case["stat_a"]), 0.0), float(case["a"][level]))
					and is_equal_approx(build.stat(StringName(case["stat_b"]), 0.0), float(case["b"][level])),
				"%s level %d keeps both authored card values" % [case["id"], level + 1]
			)
			if StringName(case["id"]) == &"thermal_burst":
				_expect(
					is_equal_approx(profile.thermal_burst_radius, float(case["a"][level]))
						and is_equal_approx(profile.thermal_burst_damage, float(case["b"][level])),
					"Thermal runtime profile derives from build modifiers"
				)
			elif StringName(case["id"]) == &"bio_toxin":
				_expect(
					is_equal_approx(profile.poison_dps_per_stack, float(case["a"][level]))
						and is_equal_approx(profile.poison_duration, float(case["b"][level])),
					"Toxin runtime profile derives from build modifiers"
				)
			else:
				_expect(
					is_equal_approx(profile.chill_magnitude_per_stack, float(case["a"][level]) / 100.0)
						and is_equal_approx(profile.chill_duration, float(case["b"][level])),
					"Cryo runtime profile derives from build modifiers"
				)


func _offer_is_legal(
	offer: Array[VehicleUpgradeDefinition],
	build: RunBuild,
	catalog: Catalog
) -> bool:
	if offer.is_empty() or offer.size() > 3:
		return false
	var ids := {}
	for definition in offer:
		if ids.has(definition.id) or not catalog.compatible(definition, build):
			return false
		ids[definition.id] = true
	return ids.size() == offer.size()


func _offer_key(offer: Array[VehicleUpgradeDefinition]) -> String:
	var ids := PackedStringArray()
	for definition in offer:
		ids.append(String(definition.id))
	return "|".join(ids)


func _id_key(ids: Array[StringName]) -> String:
	var parts := PackedStringArray()
	for id in ids:
		parts.append(String(id))
	return "|".join(parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UPGRADE_SYSTEM_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
