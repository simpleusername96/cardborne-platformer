extends SceneTree

const Catalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const Runtime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_validate_catalog()
	_validate_shield_cycle()
	_validate_source_boundaries()
	_finish()


func _validate_catalog() -> void:
	_expect(
		Catalog.validate_contract().is_empty(),
		"five boss phase definitions satisfy the authored contract"
	)
	var variants := {}
	var signatures := {}
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		var variant := Catalog.variant(stage_id)
		variants[variant] = true
		var signature := String(
			AssetProvider.descriptor(StringName("boss/%s" % String(variant))).get(
				"path", ""
			)
		)
		_expect(not signatures.has(signature), "%s boss silhouette is unique" % stage_id)
		signatures[signature] = variant
		for phase in [2, 3]:
			_expect(
				Catalog.add_roles(stage_id, phase).size() <= Catalog.MAX_LIVE_ADDS,
				"%s phase %d add packet stays at or below twelve" % [stage_id, phase]
			)
	_expect(variants.size() == 5 and signatures.size() == 5, "all five boss bodies remain distinct")
	_expect(
		Catalog.BOSS_ENTRY_SLOT_RESERVE == 1 + Catalog.MAX_LIVE_ADDS,
		"boss entry reserves only the boss body and bounded add budget"
	)


func _validate_shield_cycle() -> void:
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		var runtime := Runtime.new()
		runtime.configure(stage_id)
		var payload := runtime.begin_phase(1)
		_expect(
			runtime.state() == &"shield_up"
				and is_equal_approx(runtime.boss_damage_multiplier(), 0.25)
				and not payload.has("modules"),
			"%s starts with one boss-owned shield and no external objective" % stage_id
		)
		_expect(
			runtime.take_state_entry_hint() == "BOSS_SHIELD_UP_HINT"
				and runtime.take_state_entry_hint().is_empty(),
			"%s shield-up hint is consumed once" % stage_id
		)
		_expect(runtime.lower_after_direct_attack(), "%s direct attack lowers the shield" % stage_id)
		_expect(
			runtime.state() == &"shield_down"
				and is_equal_approx(runtime.boss_damage_multiplier(), 1.0)
				and is_equal_approx(runtime.shield_down_remaining, 4.0),
			"%s exposes one four-second full-damage window" % stage_id
		)
		runtime.advance(Runtime.SHIELD_DOWN_SECONDS + 0.01)
		_expect(
			runtime.state() == &"shield_up"
				and is_equal_approx(runtime.boss_damage_multiplier(), 0.25),
			"%s shield returns after the bounded window" % stage_id
		)
		var transition := runtime.try_advance_phase(650.0, 1000.0)
		_expect(int(transition.get("phase", 0)) == 2, "%s reaches phase two at 65 percent" % stage_id)
		runtime.begin_phase(2)
		transition = runtime.try_advance_phase(300.0, 1000.0)
		_expect(int(transition.get("phase", 0)) == 3, "%s reaches phase three at 30 percent" % stage_id)
		var snapshot := runtime.snapshot()
		_expect(
			Array(snapshot["phase_history"]) == [1, 2, 3]
				and int(snapshot["phase_skip_count"]) == 0
				and int(snapshot["shield_down_windows"]) == 1,
			"%s records sequential phases and actual shield windows" % stage_id
		)


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string(
		"res://scripts/bosses/vehicle_boss_shield_runtime.gd"
	)
	_expect(
		not runtime_source.contains("for enemy in enemies"),
		"boss shield runtime never scans the enemy store"
	)
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("boss_shield_runtime.boss_damage_multiplier")
			and run_source.contains("_spawn_boss_phase_adds")
			and not run_source.contains("boss_pylon")
			and not run_source.contains("boss_objective"),
		"production boss flow consumes one shield state without objective actors"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_SHIELDS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
