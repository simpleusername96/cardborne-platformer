extends SceneTree

const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_validate_feature_contract()
	_validate_exposure_timing_and_damage()
	_validate_capacity_and_retirement()
	_validate_transit_survival()
	_finish()


func _validate_feature_contract() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure(_blueprint())
	var snapshot := runtime.snapshot()
	var features: Array = snapshot["features"]
	var hazard_rows := features.filter(
		func(value: Dictionary) -> bool:
			return StringName(value.get("kind", &"")) == &"hazard_zone"
	)
	_expect(hazard_rows.size() == 2, "runtime keeps both hazard-zone footprints")
	_expect(
		StringName(Dictionary(hazard_rows[0]).get("variant", &"")) == &"toxic_bog"
		and StringName(Dictionary(hazard_rows[0]).get("affinity", &"")) == &"toxin",
		"hazard snapshot preserves variant and affinity metadata"
	)
	_expect(
		not snapshot.has("support_fields")
		and not snapshot.has("overdrive_active"),
		"obsolete support terrain has no snapshot state"
	)
	_expect(
		not snapshot.has("field_exposure")
		and not snapshot.has("exposure_records"),
		"public snapshot does not leak actor exposure records"
	)
	var repeated := runtime.snapshot()
	_expect(
		var_to_str(snapshot) == var_to_str(repeated),
		"cold hazard snapshot remains stable"
	)


func _validate_exposure_timing_and_damage() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure(_blueprint())
	_expect(
		runtime.hazard_damage_for_actor(
			"outside_visible_edge",
			Vector2(80, 200),
			Vector2(80, 200),
			24.0,
			&"player",
			0.10
		) == 0.0,
		"actor radius cannot expand damage beyond the visible hazard footprint"
	)
	var player_entry := runtime.hazard_damage_for_actor(
		"player", Vector2(80, 200), Vector2(150, 200), 24.0, &"player", 0.10
	)
	_expect(
		player_entry == TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"first contact deals one immediate player tick"
	)
	_expect(
		runtime.hazard_damage_for_actor(
			"player", Vector2(150, 200), Vector2(150, 200), 0.0, &"player", 0.74
		) == 0.0,
		"sub-interval overlap does not tick early"
	)
	var continuous_tick := runtime.hazard_damage_for_actor(
		"player", Vector2(150, 200), Vector2(150, 200), 0.0, &"player", 0.01
	)
	_expect(
		continuous_tick == TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"continuous overlap ticks at the 0.75 second interval"
	)
	_expect(
		runtime.hazard_damage_for_actor(
			"ordinary", Vector2(0, 200), Vector2(150, 200), 0.0, &"ordinary", 0.10
		) == TerrainRuntime.HAZARD_ORDINARY_DAMAGE,
		"ordinary actor uses the neutral ordinary damage value"
	)
	_expect(
		runtime.hazard_damage_for_actor(
			"stage_boss", Vector2(0, 200), Vector2(150, 200), 0.0, &"boss", 0.10
		) == TerrainRuntime.HAZARD_BOSS_DAMAGE,
		"boss actor uses the reduced neutral boss damage value"
	)

	var linger := TerrainRuntime.new()
	linger.configure(_blueprint())
	linger.hazard_damage_for_actor(
		"player", Vector2(0, 200), Vector2(150, 200), 0.0, &"player", 0.10
	)
	_expect(
		linger.hazard_damage_for_actor(
			"player", Vector2(150, 200), Vector2(600, 200), 0.0, &"player", 0.75
		) == TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"leaving the zone keeps the exposure tick alive"
	)
	_expect(
		linger.hazard_damage_for_actor(
			"player", Vector2(600, 200), Vector2(600, 200), 0.0, &"player", 1.0
		) == TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"lingering exposure continues at its next interval"
	)
	_expect(
		linger.hazard_damage_for_actor(
			"player", Vector2(600, 200), Vector2(600, 200), 0.0, &"player", 0.75
		) == TerrainRuntime.HAZARD_PLAYER_DAMAGE
		and not linger.is_hazard_actor_tracked("player"),
		"the final due linger tick lands before exposure expires"
	)
	_expect(
		linger.hazard_damage_for_actor(
			"player", Vector2(600, 200), Vector2(600, 200), 0.0, &"player", 0.01
		) == 0.0,
		"expired exposure stops all later hazard damage"
	)

	var reentry := TerrainRuntime.new()
	reentry.configure(_blueprint())
	reentry.hazard_damage_for_actor(
		"player", Vector2(0, 200), Vector2(150, 200), 0.0, &"player", 0.10
	)
	reentry.hazard_damage_for_actor(
		"player", Vector2(150, 200), Vector2(600, 200), 0.0, &"player", 0.25
	)
	_expect(
		reentry.hazard_damage_for_actor(
			"player", Vector2(600, 200), Vector2(150, 200), 0.0, &"player", 0.10
		) == 0.0
		and int(reentry.hazard_runtime_snapshot()["tracked_actor_count"]) == 1,
		"re-entry refreshes one non-stacking exposure"
	)


func _validate_capacity_and_retirement() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure(_blueprint())
	for index in TerrainRuntime.MAX_TRACKED_ACTORS:
		var actor_id := "actor_%03d" % index
		runtime.hazard_damage_for_actor(
			actor_id,
			Vector2(0, 200),
			Vector2(150, 200),
			0.0,
			&"ordinary",
			0.0
		)
	_expect(
		int(runtime.hazard_runtime_snapshot()["tracked_actor_count"])
		== TerrainRuntime.MAX_TRACKED_ACTORS,
		"exposure storage caps at player plus 320 hostile actors"
	)
	var overflow := runtime.hazard_damage_for_actor(
		"overflow",
		Vector2(0, 200),
		Vector2(150, 200),
		0.0,
		&"ordinary",
		0.0
	)
	_expect(overflow == 0.0, "exposure overflow is rejected without growing state")
	var ids: Array[String] = []
	runtime.append_tracked_hazard_actor_ids(ids)
	_expect(ids.size() == TerrainRuntime.MAX_TRACKED_ACTORS, "tracked ID API uses caller storage")
	runtime.forget_hazard_actor("actor_000")
	_expect(
		int(runtime.hazard_runtime_snapshot()["tracked_actor_count"])
		== TerrainRuntime.MAX_TRACKED_ACTORS - 1,
		"actor retirement removes one exposure record"
	)
	runtime.configure(_blueprint())
	_expect(
		int(runtime.hazard_runtime_snapshot()["tracked_actor_count"]) == 0,
		"stage configure clears all exposure records"
	)


func _validate_transit_survival() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure([
		{
			"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a",
			"pos":Vector2.ZERO,
		},
		{
			"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a",
			"pos":Vector2(1600.0, 0.0),
		},
	])
	var events: Array[Dictionary] = []
	for _step in 4:
		events.append_array(runtime.advance(0.1, Vector2.ZERO))
	_expect(
		events.size() == 1
		and StringName(events[0]["kind"]) == &"transit"
		and Vector2(events[0]["destination"]) == Vector2(1600.0, 0.0),
		"transit gate still fires after its dwell"
	)


func _blueprint() -> Array[Dictionary]:
	return [
		{
			"id":&"hazard_a", "kind":&"hazard_zone",
			"variant":&"toxic_bog", "affinity":&"toxin",
			"rect":Rect2(100, 100, 300, 200),
		},
		{
			"id":&"hazard_b", "kind":&"hazard_zone",
			"variant":&"toxic_bog", "affinity":&"toxin",
			"rect":Rect2(1000, 100, 300, 200),
		},
		{
			"id":&"wall", "kind":&"structural_wall",
			"rect":Rect2(700, 700, 192, 576),
		},
	]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_HAZARD_ZONE_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
