extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	var catalog := Catalog.new()
	for error in catalog.validate_contract(): failures.append(error)
	_expect(catalog.definitions.size() == 46, "catalog contains exactly 46 upgrades")
	var new_ids: Array[StringName] = [&"burst_capacitor", &"relay_rounds", &"shock_breach", &"reserve_charge", &"marked_salvo", &"guardian_seeker", &"phase_shear", &"coolant_wake", &"static_aegis", &"relay_overload", &"emergency_vector", &"salvage_booster"]
	for upgrade_id in new_ids:
		var definition := catalog.get_definition(upgrade_id)
		_expect(definition != null and not definition.behavior_ids.is_empty(), "%s is a valid behavior card" % upgrade_id)
		_expect(&"calibration" not in definition.source_tags, "%s stays out of the first calibration pool" % upgrade_id)
	var build := RunBuild.new(catalog)
	var first_offer := catalog.offer(build, 0, 0, &"calibration")
	_expect(first_offer.size() == 3, "first calibration offer contains three choices")
	var first_families := first_offer.map(func(card): return card.family)
	_expect(&"primary" in first_families and &"element" in first_families and (&"passive" in first_families or &"mobility" in first_families), "first offer contains primary, element, and passive or mobility choices")
	var first_ids := {}
	for card in first_offer:
		first_ids[card.id] = true
	_expect(first_ids.size() == 3, "first calibration offer contains no duplicate IDs")
	_expect(first_offer.all(func(card): return card.id not in new_ids), "first calibration offer remains free of advanced cards")
	var surfaced := {}
	for seed in 160:
		for source_id in [&"relay", &"field_boss", &"boss"]:
			for card in catalog.offer(build, seed, 2, source_id):
				if card.id in new_ids:
					surfaced[card.id] = true
	_expect(surfaced.size() == new_ids.size(), "deterministic later offers can surface all twelve advanced cards")
	var relay_offer := catalog.offer(build, 0, 0, &"relay")
	_expect(relay_offer.any(func(card): return not card.behavior_ids.is_empty()), "relay offer guarantees a behavior-changing choice")
	var preview := build.preview(&"kinetic_rounds")
	_expect(bool(preview["valid"]) and build.levels.is_empty(), "preview is valid and non-mutating")
	for level in 3:
		var receipt := build.apply(&"kinetic_rounds")
		_expect(bool(receipt.get("applied", false)), "kinetic round stack applies")
	_expect(not bool(build.apply(&"kinetic_rounds").get("valid", false)), "maxed upgrade is rejected")
	_expect(build.stat(&"primary_damage_multiplier", 1.0) > 1.52, "stacked primary damage derives from resource modifiers")
	_expect(bool(build.apply(&"incendiary_core").get("applied", false)), "first element core applies")
	_expect(not bool(build.apply(&"toxin_core").get("valid", false)), "second element core is excluded")
	_expect(bool(build.apply(&"thermal_compound").get("applied", false)), "core-dependent mutation applies")
	var enemy := {"role": &"chaser"}
	StatusRuntime.apply(enemy, StatusRuntime.payload(build))
	_expect(enemy["statuses"].has(&"burn"), "incendiary build applies burn payload")
	_expect(StatusRuntime.tick(enemy, 0.5) > 0.0, "burn deals deterministic DOT")
	_expect(bool(build.apply(&"flashover").get("applied", false)), "burn follow-up applies")
	_expect(float(StatusRuntime.resolve_opening(enemy, build, 20.0)["bonus_damage"]) > 0.0, "flashover consumes burn for opening damage")
	build.reset()
	build.apply(&"toxin_core")
	build.apply(&"concentrated_toxin")
	enemy = {"role": &"chaser"}
	StatusRuntime.apply(enemy, StatusRuntime.payload(build))
	StatusRuntime.apply(enemy, StatusRuntime.payload(build))
	_expect(int(enemy["statuses"][&"poison"]["stacks"]) == 2, "poison stacks within its cap")
	_expect(StatusRuntime.tick(enemy, 0.5) > 0.0, "poison deals deterministic stacked DOT")
	build.reset()
	build.apply(&"cryo_core")
	build.apply(&"deep_freeze")
	enemy = {"role": &"chaser"}
	StatusRuntime.apply(enemy, StatusRuntime.payload(build))
	_expect(StatusRuntime.speed_multiplier(enemy) < 0.75, "deep freeze produces a readable slow")
	build.reset()
	for upgrade_id in [&"shock_breach", &"reserve_charge", &"static_aegis", &"relay_overload", &"salvage_booster"]:
		var definition := catalog.get_definition(upgrade_id)
		for level in definition.max_level:
			_expect(bool(build.apply(upgrade_id).get("applied", false)), "%s level %d applies" % [upgrade_id, level + 1])
		_expect(not bool(build.apply(upgrade_id).get("valid", false)), "%s respects max level" % upgrade_id)
	build.reset()
	_expect(build.levels.is_empty() and build.element_core == &"", "run reset clears upgrade levels and element core")
	if failures.is_empty():
		print("VEHICLE_UPGRADE_SYSTEM_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
