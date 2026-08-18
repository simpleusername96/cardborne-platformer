extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, CombatStages.STAGE_IDS)
	var stage_id := &"stage_1"
	var tactical = layout.tactical_layout(stage_id)
	var runtime := Runtime.new()
	runtime.configure(
		stage_id, CombatStages.definition(stage_id)["packets"], RunDifficulty.HARD,
		tactical.ordinary_spawn_anchors, tactical.encounter_seed,
		tactical.geometry_snapshot, 0
	)
	runtime.seal_for_quota()
	var active_count := 0
	var empty_seconds := 0.0
	var maximum_empty_seconds := 0.0
	var defeat_timer := 1.25
	var total_spawns := 0
	var visible := Rect2(
		tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0),
		Vector2(1280.0, 720.0)
	)
	for _step in 3600:
		var delta := 0.05
		defeat_timer -= delta
		if defeat_timer <= 0.0 and active_count > 0:
			active_count -= 1
			defeat_timer += 1.25
		var result := runtime.tick(
			delta, active_count, [], tactical.geometry_snapshot.player_start,
			visible, [], 0, Vector2.ZERO, active_count > 0, active_count
		)
		var births := Array(result["spawns"]).size()
		active_count += births
		total_spawns += births
		if active_count <= 0:
			empty_seconds += delta
			maximum_empty_seconds = maxf(maximum_empty_seconds, empty_seconds)
		else:
			empty_seconds = 0.0
	_expect(total_spawns > 20, "maintenance continues after the authored reserve is exhausted")
	_expect(maximum_empty_seconds <= 3.0, "a living stage-1 boss never has more than a three-second visible ordinary-threat gap")
	var snapshot := runtime.debug_snapshot()
	_expect(bool(snapshot["boss_maintenance_active"]), "maintenance remains active while the boss is alive")
	_expect(Array(snapshot["boss_maintenance_roster"]).size() == 3, "maintenance cycles the stage three-role roster")
	if failures.is_empty():
		print("VEHICLE_BOSS_MAINTENANCE_180S_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
