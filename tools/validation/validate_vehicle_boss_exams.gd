extends SceneTree

const Catalog = preload("res://scripts/bosses/vehicle_boss_exam_catalog.gd")
const Runtime = preload("res://scripts/bosses/vehicle_boss_exam_runtime.gd")
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")

const BASE_PRIMARY_DAMAGE := 18.0
const BUILD_FIXTURES := {
	&"base_kit":{
		"damage_multiplier":1.0,
		"interval":PrimaryWeapon.BASE_INTERVAL,
	},
	&"reference_build":{
		"damage_multiplier":1.8,
		"interval":0.105,
	},
	&"high_output_build":{
		"damage_multiplier":3.2,
		"interval":PrimaryWeapon.MIN_INTERVAL,
	},
}

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_catalog()
	_validate_sequential_floors()
	_validate_build_fixtures()
	_validate_source_boundaries()
	_finish()


func _validate_catalog() -> void:
	_expect(
		Catalog.validate_contract().is_empty(),
		"five boss exam definitions satisfy the authored contract"
	)
	var objectives := {}
	var variants := {}
	var signatures := {}
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		var definition := Catalog.exam(stage_id)
		var objective := StringName(definition.get("objective", &""))
		var variant := StringName(definition.get("variant", &""))
		objectives[objective] = true
		variants[variant] = true
		var signature := String(
			AssetProvider.descriptor(StringName("boss/%s" % String(variant))).get(
				"path", ""
			)
		)
		_expect(
			not signatures.has(signature),
			"%s boss silhouette is unique" % stage_id
		)
		signatures[signature] = variant
		for phase in [2, 3]:
			_expect(
				Catalog.add_roles(stage_id, phase).size()
					<= Catalog.MAX_LIVE_ADDS,
				"%s phase %d add packet stays at or below twelve"
				% [stage_id, phase]
			)
	_expect(objectives.size() == 5, "all five bosses own distinct objective rules")
	_expect(variants.size() == 5, "all five bosses own distinct body variants")
	_expect(signatures.size() == 5, "all five boss outer contours are distinct")
	_expect(
		Catalog.MODULE_HEALTH_RATIO >= 0.08
			and Catalog.MODULE_HEALTH_RATIO <= 0.10,
		"objective module health remains within the eight-to-ten-percent contract"
	)
	_expect(
		is_equal_approx(Catalog.VULNERABILITY_SECONDS, 5.0),
		"objective success creates a five-second vulnerability window"
	)
	_expect(
		Catalog.BOSS_ENTRY_SLOT_RESERVE
			== 1 + 2 + Catalog.MAX_LIVE_ADDS
			and Catalog.BOSS_ENTRY_SLOT_RESERVE
				< 320,
		"boss entry reserves the boss, objective modules and finite add budget"
	)


func _validate_sequential_floors() -> void:
	for stage_number in 5:
		var stage_id := StringName("stage_%d" % (stage_number + 1))
		var runtime := Runtime.new()
		runtime.configure(stage_id)
		var payload := runtime.begin_phase(1000.0, 1)
		_expect(
			Array(payload["modules"]).size() == 2,
			"%s phase one starts with two actionable modules" % stage_id
		)
		_expect(
			runtime.core_state() == &"sealed"
				and is_equal_approx(runtime.boss_damage_multiplier(), 0.20),
			"%s sealed core takes the declared reduced damage" % stage_id
		)
		_expect(
			not runtime.take_state_entry_hint().is_empty()
				and runtime.take_state_entry_hint().is_empty(),
			"%s phase-entry hint is consumed exactly once" % stage_id
		)
		_solve_objective(runtime, stage_id, 1)
		_expect(
			runtime.core_state() == &"open"
				and is_equal_approx(runtime.boss_damage_multiplier(), 1.55),
			"%s success opens the declared damage multiplier" % stage_id
		)
		runtime.advance(Catalog.VULNERABILITY_SECONDS + 0.1)
		_expect(
			runtime.core_state() == &"stable"
				and is_equal_approx(runtime.boss_damage_multiplier(), 1.0),
			"%s vulnerability expires without relocking the solved objective" % stage_id
		)
		var transition := runtime.try_advance_phase(650.0, 1000.0)
		_expect(
			int(transition.get("phase", 0)) == 2,
			"%s phase-one threshold triggers phase two without clamping health" % stage_id
		)
		runtime.begin_phase(1000.0, 2)
		transition = runtime.try_advance_phase(300.0, 1000.0)
		_expect(
			int(transition.get("phase", 0)) == 3,
			"%s sealed phase-two threshold still triggers phase three" % stage_id
		)
		runtime.begin_phase(1000.0, 3)
		_solve_objective(runtime, stage_id, 3)
		var snapshot := runtime.snapshot()
		_expect(
			Array(snapshot["phase_history"]) == [1, 2, 3],
			"%s always experiences phases one, two and three in order" % stage_id
		)
		_expect(
			int(snapshot["phase_skip_count"]) == 0,
			"%s records zero phase skips" % stage_id
		)
		_expect(
			int(snapshot["objective_successes"]) == 2,
			"%s records only objectives actually resolved by the player" % stage_id
		)


func _validate_build_fixtures() -> void:
	_expect(
		BUILD_FIXTURES.keys() == [
			&"base_kit",
			&"reference_build",
			&"high_output_build",
		],
		"boss exams publish base, reference and high-output build fixtures"
	)
	for fixture_id in BUILD_FIXTURES:
		var fixture := Dictionary(BUILD_FIXTURES[fixture_id])
		var shot_damage := (
			BASE_PRIMARY_DAMAGE * float(fixture["damage_multiplier"])
		)
		var interval := float(fixture["interval"])
		_expect(
			shot_damage > 0.0
				and interval >= PrimaryWeapon.MIN_INTERVAL
				and interval <= PrimaryWeapon.BASE_INTERVAL,
			"%s fixture stays inside the production primary-weapon contract"
			% fixture_id
		)
		for stage_number in 5:
			var stage_id := StringName("stage_%d" % (stage_number + 1))
			var runtime := Runtime.new()
			runtime.configure(stage_id)
			runtime.begin_phase(1000.0, 1)
			_expect(
				is_equal_approx(
					shot_damage * runtime.boss_damage_multiplier(),
					shot_damage * 0.20
				),
				"%s deals reduced but nonzero sealed damage to %s"
				% [fixture_id, stage_id]
			)
			_solve_objective(runtime, stage_id, 1)
			var requested_burst := shot_damage * runtime.boss_damage_multiplier()
			_expect(
				requested_burst > shot_damage,
				"%s receives the open-window reward against %s"
				% [fixture_id, stage_id]
			)
			var transition := runtime.try_advance_phase(650.0, 1000.0)
			_expect(
				int(transition.get("phase", 0)) == 2
					and runtime.phase == 2,
				"%s advances %s at the threshold without a damage floor"
				% [fixture_id, stage_id]
			)


func _solve_objective(
	runtime: VehicleBossExamRuntime,
	stage_id: StringName,
	phase: int
) -> void:
	var safety := 0
	while runtime.objective_locked and safety < 4:
		var active := runtime.active_module_ids()
		_expect(
			not active.is_empty(),
			"%s phase %d always exposes an immediate base-kit target"
			% [stage_id, phase]
		)
		if active.is_empty():
			return
		runtime.register_module_defeat(active[0])
		safety += 1
	_expect(
		not runtime.objective_locked,
		"%s phase %d objective resolves without a fixed wait"
		% [stage_id, phase]
	)


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string(
		"res://scripts/bosses/vehicle_boss_exam_runtime.gd"
	)
	_expect(
		not runtime_source.contains("for enemy in enemies"),
		"boss exam runtime never scans the complete enemy array"
	)
	var run_source := FileAccess.get_file_as_string(
		"res://scripts/vehicle/vehicle_run.gd"
	)
	_expect(
		run_source.contains("boss_exam_runtime.boss_damage_multiplier")
			and not run_source.contains("boss_exam_runtime.damage_allowance")
			and run_source.contains("_spawn_boss_exam_adds")
			and run_source.contains(
				"BossExamCatalog.BOSS_ENTRY_SLOT_RESERVE"
			),
		"production damage consumes multipliers without a phase-floor clamp"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 96:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_BOSS_EXAMS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
