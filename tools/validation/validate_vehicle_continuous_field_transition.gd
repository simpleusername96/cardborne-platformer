extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")

const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads")
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
		root.queue_free()
		_finish()
		return

	run.call("_reset_run", false)
	run.capture_set_mode(&"playing")
	var survivor = run.call("_make_enemy", {
		"id":"continuous_field_survivor",
		"role":&"chaser",
		"pos":run.player_position + Vector2(480.0, 0.0),
		"active":true,
	})
	_expect(survivor != null and bool(run.call("_append_enemy", survivor)), "survivor fixture enters the field")
	if survivor == null:
		root.queue_free()
		_finish()
		return
	survivor.health = minf(survivor.max_health, 123.0)
	survivor.statuses[&"fixture"] = {"time":7.0, "stacks":2}
	run.visited_cells[Vector2i(3, 4)] = true
	run.discovered_markers["persistent_marker"] = true
	var next_only_role := StringName(CombatStages.MOBILE_ROLES[1][-1])
	var cycle_one_probe = run.call("_make_enemy", {
		"id":"continuous_field_cycle_one_probe",
		"role":next_only_role,
		"pos":run.player_position,
		"active":false,
	})
	_expect(cycle_one_probe != null, "cycle 1 stat probe is available")

	var layout_before = run._active_tactical_layout
	var field_fingerprint_before := int(run.field_layout.fingerprint)
	var facility_before: Dictionary = run.mystery_device_runtime.snapshot().duplicate(true)
	var pickup_before: Array = run.pickups.duplicate(true)
	var experience_before: Dictionary = run.experience_runtime.snapshot().duplicate(true)
	var terrain_before: Dictionary = run.terrain_runtime.snapshot().duplicate(true)
	var survivor_before := {
		"role":survivor.role,
		"archetype":survivor.archetype,
		"health":survivor.health,
		"max_health":survivor.max_health,
		"speed":survivor.speed,
		"pos":survivor.pos,
		"statuses":survivor.statuses.duplicate(true),
	}

	run.call("_prepare_next_stage_continuation", 1)
	run.call("_configure_next_stage_world")
	run.call("_finalize_next_stage_continuation")

	_expect(run.current_stage_index == 1 and run.current_stage_id == Catalog.STAGE_IDS[1], "cycle profile advances to cycle 2")
	_expect(is_same(run._active_tactical_layout, layout_before), "cycle advancement keeps the exact tactical layout owner")
	_expect(int(run.field_layout.fingerprint) == field_fingerprint_before, "field geometry fingerprint does not change")
	_expect(run.mystery_device_runtime.snapshot() == facility_before, "facilities do not refresh or move")
	_expect(run.pickups == pickup_before, "direct pickups do not refresh or move")
	_expect(run.experience_runtime.snapshot() == experience_before, "experience shards remain unchanged")
	_expect(run.terrain_runtime.snapshot() == terrain_before, "terrain state remains unchanged")
	_expect(run.visited_cells.has(Vector2i(3, 4)) and run.discovered_markers.has("persistent_marker"), "exploration and discovered markers remain unchanged")
	var same_survivor = run.call("_find_enemy_by_id", "continuous_field_survivor")
	_expect(
		same_survivor == survivor
			and survivor.alive
			and survivor.role == survivor_before["role"]
			and survivor.archetype == survivor_before["archetype"]
			and is_equal_approx(survivor.health, float(survivor_before["health"]))
			and is_equal_approx(survivor.max_health, float(survivor_before["max_health"]))
			and is_equal_approx(survivor.speed, float(survivor_before["speed"]))
			and survivor.pos == survivor_before["pos"]
			and survivor.statuses == survivor_before["statuses"],
		"a live ordinary enemy keeps identity, stats, position, and statuses"
	)
	var encounter: Dictionary = run.encounter_runtime.debug_snapshot()
	_expect(
		StringName(encounter["stage_id"]) == Catalog.STAGE_IDS[1]
			and int(encounter["authored_population"]) > 0,
		"only the future encounter admission profile advances"
	)
	var admitted = run.call("_make_enemy", {
		"id":"continuous_field_new_admission",
		"role":next_only_role,
		"pos":run.player_position + Vector2(-480.0, 0.0),
		"active":true,
	})
	_expect(
		admitted != null and cycle_one_probe != null
			and admitted.archetype == next_only_role
			and is_equal_approx(
				admitted.max_health / cycle_one_probe.max_health,
				StageDifficulty.ordinary_health_multiplier(1)
					/ StageDifficulty.ordinary_health_multiplier(0)
			),
		"a newly created ordinary enemy snapshots the advanced cycle profile"
	)

	root.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_CONTINUOUS_FIELD_TRANSITION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
