extends SceneTree

const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads for late-boss identity validation")
	if packed == null:
		_finish()
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active")
	if run == null:
		_finish()
		return
	run.call("_reset_run", false)
	_validate_crossing_weave(run)
	_validate_alternating_pulse(run)
	_validate_direct_preparation(run)
	run.call("_retire_denied_zones_by_owner", &"boss_actor")
	_expect(run.denied_zones.is_empty(), "boss-owned identity zones retire as one bounded owner")
	_finish()


func _validate_crossing_weave(run) -> void:
	run.denied_zones.clear()
	var event := _event("crossing_weave_a", 6)
	run.call("_execute_boss_autonomous", event)
	var primary := 0
	var orthogonal := 0
	for zone in run.denied_zones:
		primary += 1 if StringName(zone["weave_pass"]) == &"primary" else 0
		orthogonal += 1 if StringName(zone["weave_pass"]) == &"orthogonal" else 0
	_expect(
		run.denied_zones.size() == 8 and primary == 4 and orthogonal == 4,
		"Stage 7 Boss creates paired primary and orthogonal wall passes"
	)
	var valid_wall_zones := true
	for zone in run.denied_zones:
		valid_wall_zones = valid_wall_zones and (
			StringName(zone["shape"]) == &"corridor"
			and Vector2(zone["motion"]).length() > 0.0
			and is_equal_approx(float(zone["safe_gap"]), 200.0)
			and not zone.has("beam_emission_mode")
		)
	_expect(
		valid_wall_zones,
		"Stage 7 Boss walls expose collision-true moving gaps without beam semantics"
	)
	_expect(
		float(run.denied_zones[4]["warning"])
			> float(run.denied_zones[0]["warning"]),
		"Stage 7 Boss warns the orthogonal pass after the primary pass"
	)


func _validate_alternating_pulse(run) -> void:
	run.denied_zones.clear()
	run.projectile_store.clear()
	var event := _event("alternating_sectors_a", 7)
	run.call("_execute_boss_autonomous", event)
	_expect(
		run.denied_zones.size() == 2
			and run.denied_zones.all(
				func(zone): return StringName(zone["shape"]) == &"wedge_ring"
			),
		"Stage 8 Boss creates two collision-owned safe-sector pulses"
	)
	if run.denied_zones.size() != 2:
		return
	_expect(
		Vector2(run.denied_zones[0]["safe_axis"]).dot(
			Vector2(run.denied_zones[1]["safe_axis"])
		) < 0.0,
		"Stage 8 Boss alternates the safe sector between pulses"
	)
	var projectile_count: int = run.projectile_store.hostile_count()
	run.call("_activate_denied_zone_once", run.denied_zones[1])
	_expect(
		run.projectile_store.hostile_count() == projectile_count + 12,
		"Stage 8 Boss's second pulse emits one bounded sparse radial volley"
	)
	run.call("_activate_denied_zone_once", run.denied_zones[1])
	_expect(
		run.projectile_store.hostile_count() == projectile_count + 12,
		"Stage 8 Boss's radial volley cannot fire twice"
	)


func _validate_direct_preparation(run) -> void:
	for case in [
		{&"stage_index":6, &"pattern":"crossing_weave_b", &"zone_count":8},
		{&"stage_index":7, &"pattern":"alternating_sectors_b", &"zone_count":2},
	]:
		run.denied_zones.clear()
		run.current_stage_index = int(case[&"stage_index"])
		var boss := EnemyState.new()
		boss.id = "direct_identity_boss"
		boss.alive = true
		boss.pos = Vector2(1800.0, 1500.0)
		boss.committed_target = Vector2(2300.0, 1700.0)
		boss.pattern_index = 1
		run.call("_prepare_boss_identity_pattern", boss, String(case[&"pattern"]))
		var valid_direct_zones := true
		for zone in run.denied_zones:
			valid_direct_zones = valid_direct_zones and (
				StringName(zone["commit_mode"]) == &"committed"
				and String(zone["direct_boss_id"]) == boss.id
			)
		_expect(
			run.denied_zones.size() == int(case[&"zone_count"])
				and valid_direct_zones,
			"%s prepares direct collision geometry during startup" % String(case[&"pattern"])
		)
		run.call("_activate_boss_identity_pattern", boss, String(case[&"pattern"]))
		_expect(
			run.denied_zones.all(func(zone): return bool(zone.get("direct_active", false))),
			"%s activates its prepared direct geometry" % String(case[&"pattern"])
		)


func _event(pattern: String, stage_index: int) -> Dictionary:
	return {
		"id":"validation_%s" % pattern,
		"pattern":pattern,
		"kind":BossPatterns.kind(pattern),
		"origin":Vector2(1800.0, 1500.0),
		"target":Vector2(2300.0, 1700.0),
		"startup":BossPatterns.startup_seconds(pattern),
		"duration":BossPatterns.active_seconds(pattern),
		"damage":BossPatterns.damage(pattern, stage_index),
		"radius":BossPatterns.radius(pattern, stage_index),
		"width":BossPatterns.width(pattern, stage_index),
		"lane_spacing":BossPatterns.lane_spacing(stage_index),
		"affinity":BossPatterns.affinity(pattern),
		"commit_mode":&"autonomous",
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_LATE_BOSS_IDENTITIES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
