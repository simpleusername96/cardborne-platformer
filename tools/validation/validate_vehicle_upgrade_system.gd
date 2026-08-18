extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const RewardRuntime = preload("res://scripts/rewards/vehicle_reward_runtime.gd")

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
	&"active_amplifier", &"active_coolant", &"secondary_amplifier", &"secondary_coolant",
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
	_expect(catalog.definitions.size() == Catalog.EXPECTED_COUNT, "catalog contains the expected upgrades")
	_validate_presentation(catalog)
	_validate_progressive_level_contract(catalog)
	_validate_secondary_slots(catalog)
	_validate_element_lock(catalog)
	_validate_active_lock(catalog)
	_validate_offers(catalog)
	_validate_acquisition_order(catalog)
	for retired_id in RETIRED_IDS:
		_expect(
			catalog.get_definition(retired_id) == null,
			"%s is absent from the minimal catalog" % retired_id
		)
	_finish()


func _validate_presentation(catalog: Catalog) -> void:
	var state_count := 0
	var category_counts := {}
	var artwork_ids := {}
	for definition in catalog.all_definitions():
		var expected_artwork_id := StringName("upgrade/%s" % definition.id)
		_expect(
			definition.artwork_asset_id == expected_artwork_id,
			"%s owns its card-specific artwork ID" % definition.id
		)
		_expect(
			not artwork_ids.has(definition.artwork_asset_id),
			"%s does not share artwork with another card" % definition.id
		)
		artwork_ids[definition.artwork_asset_id] = true
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
			var effect_row_count := Array(snapshot["effect_rows"]).size()
			var maximum_rows := 3 if definition.category == &"activated" else 2
			_expect(
				effect_row_count <= maximum_rows
					and (effect_row_count >= 1 or definition.id in [&"miss_compensation", &"hit_chain", &"braced_fire"]),
				"%s level %d respects its effect-row budget or is a runtime-receipt card"
				% [definition.id, current_level + 1]
			)
			var expected_kind := (
				&"stats"
				if not definition.modifiers.is_empty() and definition.category != &"element"
				else (&"unlock" if current_level == 0 else &"enhance")
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
	_expect(state_count == Catalog.EXPECTED_LEVEL_STATES, "upgrade presentation covers all expected level states")
	_expect(artwork_ids.size() == Catalog.EXPECTED_COUNT, "all upgrades own unique artwork IDs")
	_expect(
		category_counts == {
			&"primary":2, &"secondary":6, &"element":3, &"activated":4,
			&"chassis":5, &"combat":7,
		},
		"six player-facing categories own the exact approved roster"
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
			"current":[[2.0, 2.0, 3.0, 4.0], [25.0, 25.0, 31.36, 40.0]],
			"next":[[2.0, 3.0, 4.0, 4.0], [25.0, 31.36, 40.0, 53.2]],
			"show":[false, true, true, true],
		},
		{
			"id":&"electric_field",
			"keys":["UPGRADE_EFFECT_DPS", "UPGRADE_EFFECT_RADIUS"],
			"current":[[8.0, 8.0, 14.311111, 24.390244], [240.0, 240.0, 280.0, 320.0]],
			"next":[[8.0, 14.311111, 24.390244, 41.066667], [240.0, 280.0, 320.0, 320.0]],
			"show":[false, true, true, true],
		},
		{
			"id":&"orbiting_blades",
			"keys":["UPGRADE_EFFECT_BLADE_COUNT", "UPGRADE_EFFECT_DAMAGE_PER_BLADE"],
			"current":[[2.0, 2.0, 3.0, 4.0], [14.0, 14.0, 20.16, 27.5]],
			"next":[[2.0, 3.0, 4.0, 4.0], [14.0, 20.16, 27.5, 39.2]],
			"show":[false, true, true, true],
		},
		{
			"id":&"drop_mines",
			"keys":["UPGRADE_EFFECT_DAMAGE", "UPGRADE_EFFECT_DEPLOYMENT_INTERVAL"],
			"current":[[48.0, 48.0, 67.2, 90.0], [3.2, 3.2, 2.52, 1.968]],
			"next":[[48.0, 67.2, 90.0, 123.2], [3.2, 2.52, 1.968, 1.8]],
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
	var automatic_ids: Array[StringName] = []
	for definition in catalog.all_definitions():
		if definition.category != &"secondary":
			continue
		automatic_ids.append(definition.id)
	automatic_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	_expect(
		_id_key(automatic_ids) == "auto_laser|drop_mines|electric_field|homing_missiles|orbiting_blades|storm_barrage",
		"six equal automatic weapons support a choose-three decision: %s"
		% _id_key(automatic_ids)
	)
	var build := RunBuild.new(catalog)
	build.apply(&"electric_field")
	build.apply(&"orbiting_blades")
	build.apply(&"homing_missiles")
	_expect(build.active_automatic_weapons() == 3, "three automatic slots are occupied")
	_expect(
		not catalog.compatible(catalog.get_definition(&"drop_mines"), build),
		"a fourth automatic weapon is blocked"
	)
	_expect(
		catalog.compatible(catalog.get_definition(&"electric_field"), build),
		"an owned automatic weapon remains levelable"
	)


func _validate_element_lock(catalog: Catalog) -> void:
	for pair_variant in [
		[&"thermal_burst", &"bio_toxin"],
		[&"thermal_burst", &"cryo_slow"],
		[&"bio_toxin", &"cryo_slow"],
	]:
		var pair := Array(pair_variant)
		var pair_build := RunBuild.new(catalog)
		_expect(
			bool(pair_build.apply(StringName(pair[0])).get("applied", false))
				and bool(pair_build.apply(StringName(pair[1])).get("applied", false))
				and pair_build.active_attribute_ids() == [pair[0], pair[1]]
				and pair_build.attribute_slot_key(StringName(pair[0])) == &"slot_0"
				and pair_build.attribute_slot_key(StringName(pair[1])) == &"slot_1",
			"any two attributes occupy acquisition-order slots: %s + %s" % pair
		)
	var build := RunBuild.new(catalog)
	_expect(
		catalog.compatible(catalog.get_definition(&"thermal_burst"), build)
			and catalog.compatible(catalog.get_definition(&"bio_toxin"), build)
			and catalog.compatible(catalog.get_definition(&"cryo_slow"), build),
		"all three attributes are legal before selection"
	)
	_expect(bool(build.apply(&"bio_toxin").get("applied", false)), "the first attribute can be selected")
	_expect(
		build.active_attribute_ids() == [&"bio_toxin"]
			and catalog.compatible(catalog.get_definition(&"thermal_burst"), build)
			and catalog.compatible(catalog.get_definition(&"cryo_slow"), build),
		"one selected attribute leaves either remaining attribute available"
	)
	_expect(bool(build.apply(&"cryo_slow").get("applied", false)), "a second distinct attribute can coexist")
	_expect(
		build.active_attribute_ids() == [&"bio_toxin", &"cryo_slow"]
			and catalog.compatible(catalog.get_definition(&"bio_toxin"), build)
			and catalog.compatible(catalog.get_definition(&"cryo_slow"), build)
			and not catalog.compatible(catalog.get_definition(&"thermal_burst"), build),
		"two selected attributes remain levelable and block only the third root"
	)
	for serial in 12:
		for definition in catalog.offer(build, 1701, 3, &"level_up", serial):
			_expect(
				definition.category != &"element"
					or definition.id in [&"bio_toxin", &"cryo_slow"],
				"post-selection offers contain only the two active attributes"
			)


func _validate_active_lock(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	_expect(build.active_weapon_id().is_empty(), "a fresh run has no active weapon")
	var rewards := RewardRuntime.new()
	var field_offer_serial := rewards.begin(&"stage_1", &"field_reward")
	_expect(field_offer_serial == 0, "a field reward can precede the first level-up")
	rewards.claim(&"stage_1")
	var level_offer_serial := rewards.begin(&"stage_1", &"level_up")
	_expect(
		level_offer_serial == 1 and rewards.current_level_up_offer_index() == 0,
		"reward runtime identifies the first level-up independently of global offer order"
	)
	var opening_offer := catalog.offer(
		build, 0xCA4D, 0, &"level_up", level_offer_serial,
		rewards.current_level_up_offer_index() == 0
	)
	var opening_active_ids: Array[StringName] = []
	for definition in opening_offer:
		if definition.category == &"activated":
			opening_active_ids.append(definition.id)
	var opening_auto_count := opening_offer.filter(func(definition: VehicleUpgradeDefinition) -> bool: return definition.category == &"secondary").size()
	_expect(
		opening_active_ids.size() == 1 and opening_auto_count == 1
			and opening_offer.size() == 3,
		"the first Stage 1 level-up offers one Active, one Auto, and one other card"
	)
	_expect(bool(build.apply(&"gravity_collapse").get("applied", false)), "one active weapon can be acquired")
	_expect(
		build.active_weapon_id() == &"black_hole"
			and catalog.compatible(catalog.get_definition(&"gravity_collapse"), build)
			and not catalog.compatible(catalog.get_definition(&"kinetic_shockwave"), build)
			and not catalog.compatible(catalog.get_definition(&"piercing_lance"), build)
			and not catalog.compatible(catalog.get_definition(&"emp"), build),
		"one selected active weapon remains levelable and excludes the other three"
	)


func _validate_offers(catalog: Catalog) -> void:
	var empty_build := RunBuild.new(catalog)
	var observed_all_sizes := {}
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
		for choice_index in 200:
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
			observed_all_sizes[offer.size()] = true
			legal_choices += 1
			build.apply(offer[run_seed % offer.size()].id)
		_expect(
			legal_choices >= 80
				and legal_choices < 200
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
		observed_all_sizes.has(1) and observed_all_sizes.has(2) and observed_all_sizes.has(3),
		"the seeded offer sweep exposes three-, two-, and one-card offers at reachable tails"
	)


func _validate_progressive_level_contract(catalog: Catalog) -> void:
	_expect(
		PrimaryRules.projectiles_per_volley(1) == 2
			and PrimaryRules.projectiles_per_volley(2) == 2
			and PrimaryRules.projectiles_per_volley(3) == 3
			and PrimaryRules.projectiles_per_volley(4) == 3
			and PrimaryRules.projectiles_per_volley(PrimaryRules.MAX_SPLIT_LEVEL) == 3,
		"Split keeps two-level projectile-count bands and a fixed three-projectile maximum"
	)
	_expect(
		PrimaryRules.additional_penetrations(1) == 1
			and PrimaryRules.additional_penetrations(2) == 1
			and PrimaryRules.additional_penetrations(3) == 2
			and PrimaryRules.additional_penetrations(4) == 2
			and PrimaryRules.additional_penetrations(PrimaryRules.MAX_PIERCE_LEVEL) == 4,
		"Pierce grows in paired bands and keeps its fixed penetration maximum"
	)
	for definition in catalog.all_definitions():
		_expect(definition.max_level >= 5, "%s gains at least three additional levels" % definition.id)
		for modifier in definition.modifiers:
			_expect(
				modifier.values_by_level.size() == definition.max_level,
				"%s owns one authored value per level" % definition.id
			)
			for level_index in range(1, modifier.values_by_level.size()):
				var previous := float(modifier.values_by_level[level_index - 1])
				var current := float(modifier.values_by_level[level_index])
				_expect(current >= previous, "%s changes %s progressively" % [definition.id, modifier.stat_id])
		var build := RunBuild.new(catalog)
		for _level in definition.max_level:
			_expect(bool(build.apply(definition.id).get("applied", false)), "%s applies every authored level" % definition.id)
		_expect(
			not bool(build.apply(definition.id).get("applied", false)),
			"%s stops only at its authored maximum" % definition.id
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


func _validate_acquisition_order(catalog: Catalog) -> void:
	var build := RunBuild.new(catalog)
	_expect(
		bool(build.apply(&"chassis_speed").get("applied", false))
			and bool(build.apply(&"lifesteal").get("applied", false))
			and bool(build.apply(&"chassis_speed").get("applied", false)),
		"fixture accepts first acquisitions and an owned-card level-up"
	)
	_expect(
		build.acquisition_order == [&"chassis_speed", &"lifesteal"],
		"first-acquisition order is stable and does not duplicate an upgraded card"
	)
	var rejected := build.apply(&"missing_upgrade")
	_expect(
		not bool(rejected.get("applied", false))
			and build.acquisition_order == [&"chassis_speed", &"lifesteal"],
		"rejected applications do not append a build-grid record"
	)
	build.reset()
	_expect(build.acquisition_order.is_empty(), "run reset clears build-grid acquisition order")


func _validate_element_stats(catalog: Catalog) -> void:
	var cases := [
		{
			"id":&"thermal_burst",
			"stat_a":&"thermal_burst_radius", "a":[72.0, 84.0, 96.0, 96.0],
			"stat_b":&"thermal_burst_damage", "b":[4.0, 5.75, 8.0, 11.0],
		},
		{
			"id":&"bio_toxin",
			"stat_a":&"toxin_dps_per_stack", "a":[2.0, 2.85, 4.0, 5.5],
			"stat_b":&"toxin_duration", "b":[5.0, 6.0, 7.0, 7.0],
		},
		{
			"id":&"cryo_slow",
			"stat_a":&"cryo_slow_per_stack", "a":[6.0, 8.0, 10.0],
			"stat_b":&"cryo_duration", "b":[2.0, 2.5, 3.0],
			"stat_c":&"cryo_shatter_damage", "c":[18.0, 28.0, 42.0],
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
			var profile := PrimaryPayload.from_build(build)
			var authored_values_match := (
				is_equal_approx(build.stat(StringName(case["stat_a"]), 0.0), float(case["a"][level]))
				and is_equal_approx(build.stat(StringName(case["stat_b"]), 0.0), float(case["b"][level]))
			)
			if case.has("stat_c"):
				authored_values_match = authored_values_match and is_equal_approx(
					build.stat(StringName(case["stat_c"]), 0.0), float(case["c"][level])
				)
			_expect(
				authored_values_match,
				"%s level %d keeps every authored card value" % [case["id"], level + 1]
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
						and is_equal_approx(profile.chill_duration, float(case["b"][level]))
						and is_equal_approx(profile.chill_shatter_damage, float(case["c"][level])),
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
