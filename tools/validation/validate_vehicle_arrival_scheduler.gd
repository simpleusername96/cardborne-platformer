extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(FIXED_SEED, CombatStages.STAGE_IDS)
	_expect(layout != null, "fixed layout exists for arrival scheduling")
	if layout == null:
		_finish()
		return
	var stage_id := CombatStages.STAGE_IDS[0]
	var tactical = layout.tactical_layout(stage_id)
	var packet: Dictionary = CombatStages.definition(stage_id)["packets"][1].duplicate(true)
	packet["trigger"] = {"kind":&"time", "at":0.0}
	_validate_truthful_rounds(stage_id, packet, tactical)
	_validate_capacity_reservation(stage_id, packet, tactical)
	_validate_continuation_lead(stage_id, packet, tactical)
	_finish()


func _validate_truthful_rounds(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var cue_positions := {}
	var cue_times: Array[float] = []
	var total_cues := 0
	var total_spawns := 0
	for _step in 240:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		var cues: Array = result["cues"]
		var spawns: Array = result["spawns"]
		_expect(cues.size() <= 4, "a scheduler tick exposes at most four warning markers")
		_expect(spawns.size() <= Runtime.MAX_SPAWNS_PER_TICK, "an atomic round contains at most four births")
		if not cues.is_empty():
			cue_times.append(float(cues[0]["cue_at"]))
		for cue in cues:
			total_cues += 1
			cue_positions[String(cue["squad_id"])] = Vector2(cue["birth_position"])
		for spec in spawns:
			total_spawns += 1
			if int(spec["unit_index"]) == 0:
				_expect(cue_positions.has(String(spec["squad_id"])), "every first birth has a prior exact cue")
				_expect(Vector2(spec["pos"]) == Vector2(cue_positions.get(String(spec["squad_id"]), Vector2.INF)), "first birth uses its exact cue position")
		if runtime.debug_snapshot()["queued_spawns"] == 0 and runtime.debug_snapshot()["queued_windows"] == 0 and total_spawns > 0:
			break
	_expect(total_cues == 12, "three windows emit four first-unit cues each")
	var authored_units := 0
	for squad in packet["squads"]:
		authored_units += Array(squad).size()
	_expect(total_spawns == authored_units, "scheduler emits the complete authored packet")
	for index in range(1, cue_times.size()):
		_expect(cue_times[index] - cue_times[index - 1] >= 1.20 - 0.001, "actual cue windows stay at least 1.20 seconds apart")
	var snapshot := runtime.debug_snapshot()
	_expect(int(snapshot["scheduler_starvation"]) == 0, "nominal FIFO scheduler never starves an eligible round")
	_expect(int(snapshot["reserved_arrival_slots"]) == 0, "first-round reservations clear after emission")
	runtime.stop_spawning()
	_expect(int(runtime.debug_snapshot()["reserved_arrival_slots"]) == 0, "stop_spawning clears reservations")


func _validate_capacity_reservation(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var packet_cap := RunDifficulty.scaled_active_cap(
		Director.active_cap_for(int(packet["beat"])),
		RunDifficulty.HARD
	)
	var blocked := runtime.tick(0.1, packet_cap - 3, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	_expect(Array(blocked["cues"]).is_empty(), "cue admission waits until four first-round slots exist")
	_expect(int(runtime.debug_snapshot()["reserved_arrival_slots"]) == 0, "blocked cue does not reserve partial capacity")
	var admitted := runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	_expect(Array(admitted["cues"]).size() == 4, "capacity recovery admits one complete cue window")
	_expect(int(runtime.debug_snapshot()["reserved_arrival_slots"]) == 4, "admitted cue reserves its complete first round")


func _validate_continuation_lead(stage_id: StringName, source_packet: Dictionary, tactical) -> void:
	var packet := source_packet.duplicate(true)
	packet["cue_lead"] = 0.9
	var runtime := _runtime(stage_id, [packet], tactical)
	var cue_at := -1.0
	var first_spawn_at := -1.0
	for _step in 80:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		if cue_at < 0.0 and not Array(result["cues"]).is_empty():
			cue_at = float(result["cues"][0]["cue_at"])
		if first_spawn_at < 0.0 and not Array(result["spawns"]).is_empty():
			first_spawn_at = runtime.elapsed
			break
	_expect(is_equal_approx(first_spawn_at - cue_at, 0.9), "continuation opening preserves its exact 0.9-second cue lead")


func _runtime(stage_id: StringName, packets: Array[Dictionary], tactical) -> VehicleEncounterRuntime:
	var runtime := Runtime.new()
	runtime.configure(
		stage_id,
		packets,
		RunDifficulty.HARD,
		tactical.ordinary_spawn_anchors,
		tactical.encounter_seed,
		tactical.geometry_snapshot
	)
	return runtime


func _visible(tactical) -> Rect2:
	return Rect2(tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ARRIVAL_SCHEDULER_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
