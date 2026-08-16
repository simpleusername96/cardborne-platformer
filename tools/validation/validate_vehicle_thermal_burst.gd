extends SceneTree

const PrimaryPayload = preload("res://scripts/combat/vehicle_primary_payload_profile.gd")
const Scene = preload("res://scenes/run/VehicleRun.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run = Scene.instantiate()
	root.add_child(run)
	await process_frame
	run.call("_reset_run", false)
	run.call("_clear_enemies")
	var center := Vector2(3600.0, 2160.0)
	var direct = _append(run, &"chaser", "burst_direct", center)
	var nearby = _append(run, &"shooter", "burst_nearby", center + Vector2(70.0, 0.0))
	var boss = _append(run, &"stage_boss", "burst_boss", center - Vector2(60.0, 0.0))
	var structure = _append(run, &"turret", "burst_structure", center + Vector2(40.0, 0.0))
	var far = _append(run, &"controller", "burst_far", center + Vector2(120.0, 0.0))
	var profile := PrimaryPayload.new()
	profile.thermal_enabled = true
	profile.thermal_burst_radius = 72.0
	profile.thermal_burst_damage = 4.0
	var direct_before: float = direct.health
	var nearby_before: float = nearby.health
	var boss_before: float = boss.health
	var structure_before: float = structure.health
	var far_before: float = far.health
	var effect_count_before: int = run.effects.size()
	run.boss_shield_runtime.configure(&"stage_3")
	run.call("_apply_thermal_burst", direct, center, profile)
	_expect(direct.health == direct_before, "burst excludes its direct target")
	_expect(is_equal_approx(nearby_before - nearby.health, 4.0), "level-one burst deals four nearby damage")
	_expect(is_equal_approx(boss_before - boss.health, 0.40), "burst respects the Drydock frontal shield mitigation")
	_expect(structure.health == structure_before, "burst excludes fixed structures")
	_expect(far.health == far_before, "burst stops outside its radius")
	_expect(
		run.effects.size() == effect_count_before + 1
		and run.effects[-1].kind == &"thermal_burst_impact"
		and run.effects[-1].pos == center
		and is_equal_approx(run.effects[-1].duration, 0.18)
		and is_equal_approx(run.effects[-1].radius, 72.0),
		"burst adds one bounded radius-scaled receipt at the direct contact"
	)
	boss.presentation_facing = Vector2.LEFT
	boss_before = boss.health
	run.call("_apply_thermal_burst", direct, center, profile)
	_expect(is_equal_approx(boss_before - boss.health, 4.0), "a rear-side hit bypasses the Drydock frontal shield")
	_expect(
		run.effects.size() == effect_count_before + 2,
		"each eligible direct contact adds one receipt without adding splash receipts"
	)
	var telemetry: Dictionary = run.stage_telemetry.stage_snapshot()
	_expect(
		is_equal_approx(float(telemetry["outgoing"][&"thermal_burst"]), 12.40)
			and is_equal_approx(float(telemetry["attributes"][&"thermal"]), 12.40),
		"only applied splash damage is reported as thermal_burst/thermal"
	)
	_expect(
		profile.can_trigger_thermal_burst("player_primary", false)
			and not profile.can_trigger_thermal_burst("seeker", false)
			and not profile.can_trigger_thermal_burst("player_primary", true),
		"seeker, status, reflected, and splash sources cannot chain a burst"
	)
	run.queue_free()
	await process_frame
	_finish()


func _append(run, archetype: StringName, enemy_id: String, position: Vector2):
	var enemy = run.call("_make_enemy", {
		"id":enemy_id,
		"role":archetype,
		"pos":position,
		"active":true,
	})
	_expect(run.call("_append_enemy", enemy), "%s enters the burst fixture" % enemy_id)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_THERMAL_BURST_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
