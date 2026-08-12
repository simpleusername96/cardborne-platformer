extends SceneTree

const DamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)
const RecoveryPolicy = preload(
	"res://scripts/player/vehicle_player_recovery_policy.gd"
)
const DashRuntime = preload(
	"res://scripts/player/vehicle_dash_upgrade_runtime.gd"
)
const PrimaryRules = preload(
	"res://scripts/player/vehicle_primary_upgrade_rules.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_validate_primary_final_levels()
	_validate_conditional_damage()
	_validate_recovery_split()
	_validate_dash_path_runtime()
	if failures.is_empty():
		print("VEHICLE_CONDITIONAL_UPGRADES_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_primary_final_levels() -> void:
	_expect(
		PrimaryRules.projectiles_per_volley(3) == 3
			and is_equal_approx(
				PrimaryRules.total_volley_damage_percent(3), 180.0
			)
			and PrimaryRules.additional_penetrations(4) == 4,
		"final Split keeps three shots at 180 percent and Pierce reaches four"
	)


func _validate_conditional_damage() -> void:
	_expect(
		is_zero_approx(DamagePolicy.crisis_bonus(3, 0.60))
			and is_equal_approx(DamagePolicy.crisis_bonus(3, 0.25), 0.20)
			and is_equal_approx(DamagePolicy.crisis_bonus(3, 0.425), 0.10),
		"crisis bonus follows the exact 60-to-25-percent linear curve"
	)
	var combined := DamagePolicy.resolve_damage(
		100.0, 0, 3, 3, 0.25, true,
		DamagePolicy.DAMAGE_DIRECT,
		7, 9, 11, 13
	)
	_expect(
		is_equal_approx(combined, 155.0),
		"dash and low-hull bonuses add before damage resolution"
	)
	var critical_serial := 0
	for serial in range(1, 512):
		if DamagePolicy.deterministic_unit(17, serial, 23, 29) < 0.16:
			critical_serial = serial
			break
	_expect(critical_serial > 0, "deterministic fixture finds a critical receipt")
	if critical_serial > 0:
		var direct := DamagePolicy.resolve_damage(
			10.0, 3, 0, 0, 1.0, false,
			DamagePolicy.DAMAGE_DIRECT, 17, critical_serial, 23, 29
		)
		var periodic := DamagePolicy.resolve_damage(
			10.0, 3, 0, 0, 1.0, false,
			DamagePolicy.DAMAGE_PERIODIC, 17, critical_serial, 23, 29
		)
		_expect(
			is_equal_approx(direct, 20.0)
				and is_equal_approx(periodic, 10.0),
			"critical doubles direct damage and never applies to periodic damage"
		)


func _validate_recovery_split() -> void:
	var full_hull := RecoveryPolicy.split(50.0, 1, 120.0, 120.0, 0.0)
	_expect(
		is_zero_approx(full_hull.x)
			and is_equal_approx(full_hull.y, 18.0)
			and is_equal_approx(full_hull.z, 36.0),
		"level-one overflow converts accepted gross recovery at 50 percent"
	)
	var mixed := RecoveryPolicy.split(50.0, 2, 100.0, 120.0, 0.0)
	_expect(
		is_equal_approx(mixed.x, 20.0)
			and is_equal_approx(mixed.y, 22.5)
			and is_equal_approx(mixed.z, 50.0),
		"recovery fills Hull before converting the accepted overflow"
	)
	var capped := RecoveryPolicy.split(100.0, 3, 120.0, 120.0, 0.0)
	_expect(
		is_equal_approx(capped.y, 42.0)
			and is_equal_approx(capped.z, 42.0),
		"level-three overflow barrier stops at 35 percent of max Hull"
	)


func _validate_dash_path_runtime() -> void:
	var runtime := DashRuntime.new()
	runtime.begin_dash(Vector2(100.0, 100.0))
	runtime.complete_dash(Vector2(220.0, 100.0), 3, 3)
	_expect(
		runtime.overdrive_active() and runtime.trails.size() == 1,
		"one completed dash starts one overdrive timer and one path field"
	)
	var trail = runtime.trails[0]
	_expect(
		DashRuntime.contains(trail, Vector2(100.0, 172.0))
			and DashRuntime.contains(trail, Vector2(220.0, 172.0))
			and not DashRuntime.contains(trail, Vector2(160.0, 173.0)),
		"dash field is one capsule including both actual path endpoints"
	)
	var ticks := 0
	for _step in 6:
		ticks += runtime.advance(0.5).size()
	_expect(
		ticks == 6 and runtime.trails.is_empty(),
		"three-second field produces six half-second ticks then retires"
	)
	for index in 3:
		runtime.begin_dash(Vector2(float(index) * 10.0, 0.0))
		runtime.complete_dash(Vector2(float(index) * 10.0 + 5.0, 0.0), 0, 1)
	_expect(runtime.trails.size() == 2, "dash fields keep the newest two paths")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
