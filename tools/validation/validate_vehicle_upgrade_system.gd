extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const StatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	var catalog := Catalog.new()
	for error in catalog.validate_contract(): failures.append(error)
	_expect(catalog.definitions.size() == 34, "catalog contains exactly 34 upgrades")
	var build := RunBuild.new(catalog)
	var first_offer := catalog.offer(build, 0, 0, &"calibration")
	_expect(first_offer.size() == 3, "first calibration offer contains three choices")
	var first_families := first_offer.map(func(card): return card.family)
	_expect(&"primary" in first_families and &"element" in first_families, "first offer contains primary and element choices")
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
	_expect(build.levels.is_empty() and build.element_core == &"", "run reset clears upgrade levels and element core")
	if failures.is_empty():
		print("VEHICLE_UPGRADE_SYSTEM_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
