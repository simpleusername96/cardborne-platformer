extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")

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
	_expect(catalog.definitions.size() == 12, "catalog contains exactly 12 upgrades")
	_validate_presentation(catalog)
	_validate_secondary_slots(catalog)
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
				Array(snapshot["effect_rows"]).size() <= 2,
				"%s level %d has at most two effect rows"
				% [definition.id, current_level + 1]
			)
			var expected_kind := &"stats" if not definition.modifiers.is_empty() else (
				&"unlock" if current_level == 0 else &"enhance"
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
	_expect(state_count == 34, "upgrade presentation covers all 34 level states")
	_expect(
		category_counts == {
			&"primary":2, &"secondary":4, &"element":3, &"chassis":3,
		},
		"four player-facing categories own the exact minimal roster"
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
		_id_key(optional_ids) == "drop_mines|electric_field|orbiting_blades",
		"three optional secondary identities support a choose-two decision: %s"
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


func _validate_offers(catalog: Catalog) -> void:
	var empty_build := RunBuild.new(catalog)
	for run_seed in 24:
		for source_id in [&"level_up", &"boss"]:
			var offer := catalog.offer(
				empty_build, run_seed, run_seed % 5, source_id, run_seed
			)
			_expect(_offer_is_legal(offer, empty_build, catalog), "fresh offer has three legal cards")
	var stable_offer_a := catalog.offer(empty_build, 0xCA4D, 1, &"level_up", 7)
	var stable_offer_b := catalog.offer(empty_build, 0xCA4D, 1, &"level_up", 7)
	_expect(
		_offer_key(stable_offer_a) == _offer_key(stable_offer_b),
		"one reward transaction remains stable for the same seed and serial"
	)
	for run_seed in 24:
		var build := RunBuild.new(catalog)
		for choice_index in 25:
			var source_id := &"boss" if choice_index in [4, 9, 14, 19, 24] else &"level_up"
			var offer := catalog.offer(
				build,
				0xCA4D + run_seed,
				mini(4, choice_index / 5),
				source_id,
				choice_index
			)
			_expect(
				_offer_is_legal(offer, build, catalog),
				"seed %d choice %d keeps the shipped 25-choice route legal"
				% [run_seed, choice_index + 1]
			)
			if offer.size() != 3:
				break
			build.apply(offer[run_seed % offer.size()].id)


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


func _offer_is_legal(
	offer: Array[VehicleUpgradeDefinition],
	build: RunBuild,
	catalog: Catalog
) -> bool:
	if offer.size() != 3:
		return false
	var ids := {}
	for definition in offer:
		if ids.has(definition.id) or not catalog.compatible(definition, build):
			return false
		ids[definition.id] = true
	return ids.size() == 3


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
