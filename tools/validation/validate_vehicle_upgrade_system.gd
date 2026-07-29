extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := Catalog.new()
	for error in catalog.validate_contract(): failures.append(error)
	_expect(catalog.definitions.size() == 41, "catalog contains exactly 41 upgrades")
	for id in Catalog.SECONDARY_FAMILY_IDS:
		var definition := catalog.get_definition(id)
		_expect(definition != null and definition.max_level == 3 and definition.family == &"secondary", "%s is a three-level secondary" % id)
	var build := RunBuild.new(catalog)
	for run_seed in 24:
		for source_id in [&"level_up", &"boss", &"cache"]:
			var offer := catalog.offer(
				build,
				run_seed,
				run_seed % 5,
				source_id,
				run_seed
			)
			var offered_ids := {}
			for card in offer:
				offered_ids[card.id] = true
			_expect(
				offered_ids.size() == offer.size(),
				"one offer never repeats an upgrade card"
			)
	var stable_offer_a := catalog.offer(build, 0xCA4D, 1, &"level_up", 7)
	var stable_offer_b := catalog.offer(build, 0xCA4D, 1, &"level_up", 7)
	_expect(
		_offer_key(stable_offer_a) == _offer_key(stable_offer_b),
		"one reward transaction remains stable for the same run seed and serial"
	)
	var sequential_offers := {}
	for offer_serial in 12:
		sequential_offers[
			_offer_key(catalog.offer(build, 0xCA4D, 1, &"level_up", offer_serial))
		] = true
	_expect(
		sequential_offers.size() > 1,
		"successive reward transactions draw more than one constrained offer"
	)
	var expected := [280.0, 302.4, 324.8, 347.2]
	_expect(is_equal_approx(build.stat(&"move_speed_multiplier", 280.0), expected[0]), "base movement is 280")
	for level in 3:
		_expect(bool(build.apply(&"tuned_thrusters").get("applied", false)), "Tuned Thrusters level applies")
		_expect(is_equal_approx(build.stat(&"move_speed_multiplier", 280.0), expected[level + 1]), "Tuned Thrusters uses exact level speed")
	build.reset()
	build.apply(&"kinetic_rounds")
	var second_offer := catalog.offer(build, 0, 0, &"level_up", 1)
	_expect(second_offer.any(func(card): return card.id == &"tuned_thrusters"), "second level-up offers Tuned Thrusters")
	build.reset()
	_expect(bool(build.apply(&"incendiary_core").get("applied", false)), "fire root applies")
	_expect(bool(build.apply(&"toxin_core").get("applied", false)), "poison root stacks with fire")
	_expect(bool(build.apply(&"cryo_core").get("applied", false)), "chill root stacks with fire and poison")
	for deleted_id in [&"breach_round", &"fast_capacitor", &"shock_breach", &"flashover", &"shatter"]:
		_expect(catalog.get_definition(deleted_id) == null, "%s is absent from the live catalog" % deleted_id)
	build.apply(&"thermal_compound")
	var branch_offer := catalog.offer(build, 4, 1, &"level_up", 3)
	_expect(
		branch_offer.any(func(card): return card.id in [&"concentrated_toxin", &"deep_freeze"]),
		"level-up reserves an eligible child from an owned least-progressed branch"
	)
	build.reset()
	build.apply(&"ion_field")
	build.apply(&"orbit_blades")
	_expect(build.active_optional_secondaries() == 2, "two optional secondary slots are occupied")
	_expect(not catalog.compatible(catalog.get_definition(&"wake_mines"), build), "a fourth total family is blocked")
	_expect(catalog.compatible(catalog.get_definition(&"ion_field"), build), "owned family remains levelable")
	_finish()


func _offer_key(offer: Array[VehicleUpgradeDefinition]) -> String:
	var ids := PackedStringArray()
	for definition in offer:
		ids.append(String(definition.id))
	return "|".join(ids)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UPGRADE_SYSTEM_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
