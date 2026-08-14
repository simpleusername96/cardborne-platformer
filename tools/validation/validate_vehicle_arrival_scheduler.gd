extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EngagementDirector = preload("res://scripts/encounters/vehicle_engagement_director.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(FIXED_SEED, CombatStages.STAGE_IDS)
	_expect(layout != null, "fixed layout exists for arrival scheduling")
	if layout == null:
		_finish()
		return
	# Stage 1 deliberately uses one-squad windows so its exact six-unit live cap
	# can preserve atomic admission. Exercise the shared three-by-four scheduler
	# contract with the first standard packet shape instead.
	var stage_id := CombatStages.STAGE_IDS[1]
	var tactical = layout.tactical_layout(stage_id)
	var packet: Dictionary = CombatStages.definition(stage_id)["packets"][1].duplicate(true)
	packet["trigger"] = {"kind":&"time", "at":0.0}
	_validate_truthful_rounds(stage_id, packet, tactical)
	_validate_capacity_reservation(stage_id, packet, tactical)
	_validate_cued_window_never_reblocks(stage_id, packet, tactical)
	_validate_quota_seal_preserves_cued_window(stage_id, packet, tactical)
	_validate_quota_seal_cues_nearest_reserve_immediately(stage_id, packet, tactical)
	_validate_invisible_boss_pressure_bypasses_low_watermark(stage_id, packet, tactical)
	_validate_engagement_capacity_fallback(stage_id, packet, tactical)
	_validate_materialization_failure_accounting(stage_id, packet, tactical)
	_validate_continuation_lead(stage_id, packet, tactical)
	_finish()


func _validate_truthful_rounds(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var cue_positions := {}
	var cue_times: Array[float] = []
	var total_cues := 0
	var total_spawns := 0
	var gated_spawns := 0
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
			if spec.has("engagement_handle"):
				gated_spawns += 1
				_expect(not Vector2(spec.get("engagement_gate", Vector2.INF)).is_equal_approx(Vector2.INF), "reserved spawn carries a fixed gate")
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
	_expect(gated_spawns > 0, "multi-window packet attaches live engagement reservations")
	for index in range(1, cue_times.size()):
		_expect(cue_times[index] - cue_times[index - 1] >= 1.20 - 0.001, "actual cue windows stay at least 1.20 seconds apart")
	var snapshot := runtime.debug_snapshot()
	_expect(int(snapshot["scheduler_starvation"]) == 0, "nominal FIFO scheduler never starves an eligible round")
	_expect(int(snapshot["reserved_arrival_slots"]) == 0, "first-round reservations clear after emission")
	runtime.stop_spawning()
	_expect(int(runtime.debug_snapshot()["reserved_arrival_slots"]) == 0, "stop_spawning clears reservations")
	_expect(int(Dictionary(runtime.debug_snapshot()["engagement"])["live_count"]) == 0, "stop_spawning cancels queued engagement reservations")


func _validate_capacity_reservation(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var packet_cap := RunDifficulty.scaled_active_cap(
		Director.materialized_active_cap_for(int(packet["beat"])),
		RunDifficulty.HARD
	)
	var window_units := _window_unit_count(packet, 0)
	var blocked := runtime.tick(0.1, packet_cap - window_units + 1, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	_expect(Array(blocked["cues"]).is_empty(), "cue admission waits until the complete window fits")
	var blocked_snapshot := runtime.debug_snapshot()
	_expect(int(blocked_snapshot["reserved_arrival_slots"]) == 0, "blocked cue does not reserve partial capacity")
	_expect(
		int(blocked_snapshot["next_window_units"]) == window_units,
		"blocked cue reports the exact pending window size for diagnostics"
	)
	var admitted := runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	_expect(Array(admitted["cues"]).size() == 4, "capacity recovery admits one complete cue window")
	_expect(int(runtime.debug_snapshot()["reserved_arrival_slots"]) == window_units, "admitted cue reserves every unit in its window")


func _validate_cued_window_never_reblocks(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var authored_units := _packet_unit_count(packet)
	var packet_cap := RunDifficulty.scaled_active_cap(
		Director.materialized_active_cap_for(int(packet["beat"])),
		RunDifficulty.HARD
	)
	var window_units := _window_unit_count(packet, 0)
	var admission := runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	_expect(Array(admission["cues"]).size() == 4, "whole-window fixture receives one cue set")
	var emitted := 0
	for _step in 80:
		var result := runtime.tick(0.05, packet_cap, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		var spawns: Array = result["spawns"]
		_expect(spawns.size() <= Runtime.MAX_SPAWNS_PER_TICK, "reserved rounds keep the four-birth tick limit")
		emitted += spawns.size()
		if emitted >= window_units:
			break
	_expect(emitted == window_units, "every round of a cued window emits despite later capacity pressure")
	var snapshot := runtime.debug_snapshot()
	_expect(int(snapshot["reserved_arrival_slots"]) == 0, "whole-window reservation clears only after its final birth")
	_expect(
		int(snapshot["authored_population"]) == authored_units
			and int(snapshot["materialized_spawned"]) == window_units
			and int(snapshot["virtual_reserve"]) == authored_units - window_units,
		"event-owned reserve accounting conserves every authored unit after emission"
	)


func _validate_quota_seal_preserves_cued_window(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var admission := runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	var admitted_units := _window_unit_count(packet, 0)
	var authored_units := _packet_unit_count(packet)
	_expect(Array(admission["cues"]).size() == 4, "quota seal fixture first admits one visible cue window")
	runtime.seal_for_quota()
	_expect(runtime.quota_sealed() and runtime.spawning_enabled(), "quota seal preserves bounded boss maintenance admission")
	var emitted := 0
	var maintenance_cues := 0
	for _step in 160:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		emitted += Array(result["spawns"]).size()
		maintenance_cues += Array(result["cues"]).size()
		if runtime.debug_snapshot()["queued_spawns"] == 0 and maintenance_cues > 0:
			break
	var snapshot := runtime.debug_snapshot()
	_expect(emitted >= admitted_units, "quota seal fulfills every round from the already-cued window")
	_expect(maintenance_cues == 1, "boss maintenance admits one bounded group only after the promised window drains")
	_expect(bool(snapshot["boss_maintenance_active"]) and int(snapshot["boss_maintenance_reserve"]) < authored_units - admitted_units, "boss maintenance preserves and consumes uncued authored identities")
	_expect(int(snapshot["quota_canceled_reserve"]) == 0 and int(snapshot["reserved_arrival_slots"]) == 0, "quota seal no longer cancels authored reserve and clears fulfilled reservations")


func _validate_quota_seal_cues_nearest_reserve_immediately(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	runtime.set_pressure_observation_enabled(true)
	runtime.seal_for_quota()
	var result := runtime.tick(0.0, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
	var cues: Array = result["cues"]
	_expect(cues.size() == 1, "quota seal cues the existing authored reserve without a maintenance-delay gap")
	if not cues.is_empty():
		_expect(bool(Dictionary(cues[0]).get("outside_visible_margin", false)), "quota reserve cue remains offscreen")
	var snapshot := runtime.debug_snapshot()
	_expect(
		StringName(snapshot.get("scheduler_gap_reason", &"")) == &"awaiting_birth",
		"diagnostic gap reason identifies the cue-to-birth lead without changing admission"
	)


func _validate_invisible_boss_pressure_bypasses_low_watermark(
	stage_id: StringName,
	packet: Dictionary,
	tactical
) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	runtime.current_beat = 2
	runtime.seal_for_quota()
	var result := runtime.tick(
		0.0, 9, [], tactical.geometry_snapshot.player_start, _visible(tactical),
		[], 0, Vector2.ZERO, false
	)
	_expect(
		Array(result["cues"]).size() == 1,
		"an empty boss viewport admits nearest reserve even above the ordinary low watermark"
	)


func _validate_engagement_capacity_fallback(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var engagement: VehicleEngagementDirector = runtime.get("_engagement_director")
	for ordinal in EngagementDirector.CAPACITY:
		var expected := 100.0 + float(ordinal) * 0.5
		var request := {
			"id":"capacity_%03d" % ordinal,
			"ordinal":ordinal,
			"eligible_sectors":[0, 1, 2, 3, 4],
			"heading_sector":0,
			"expected_time":expected,
			"expiry_time":expected + 5.0,
			"anchor":Vector2(10.0, 20.0),
			"gate_radius":520.0,
			"validation_allow_eta_saturation":true,
		}
		_expect(not engagement.reserve(request).is_empty(), "engagement capacity prefill succeeds")
	var emitted := []
	for _step in 80:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		emitted = Array(result["spawns"])
		if not emitted.is_empty():
			break
	_expect(not emitted.is_empty(), "reservation overflow still permits safe births")
	for spec in emitted:
		_expect(not Dictionary(spec).has("engagement_handle"), "reservation overflow uses the documented no-gate fallback")
	runtime.stop_spawning()


func _validate_materialization_failure_accounting(stage_id: StringName, packet: Dictionary, tactical) -> void:
	var runtime := _runtime(stage_id, [packet], tactical)
	var emitted := []
	for _step in 80:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, _visible(tactical))
		emitted = Array(result["spawns"])
		if not emitted.is_empty():
			break
	_expect(not emitted.is_empty(), "materialization failure fixture emits a birth")
	if emitted.is_empty():
		return
	var rejected := Dictionary(emitted[0])
	var id := String(rejected["id"])
	var squad_id := String(rejected["squad_id"])
	var before := runtime.debug_snapshot()
	var before_squad_count := int(Dictionary(before["spawned_by_squad"]).get(squad_id, 0))
	runtime.note_spawn_materialization_failed(rejected)
	var after := runtime.debug_snapshot()
	_expect(int(after["spawn_materialization_failures"]) == 1, "store rejection is counted explicitly")
	_expect(
		int(after["authored_population"])
			!= int(after["materialized_spawned"]) + int(after["virtual_reserve"]),
		"a rejected materialization remains visible as lost authored work"
	)
	_expect(int(Dictionary(after["spawned_by_squad"]).get(squad_id, 0)) == before_squad_count - 1, "rejected actor is removed from successful squad births")
	var retains_spawn := false
	for entry in Array(after["timeline"]):
		var item := Dictionary(entry)
		if StringName(item.get("kind", &"")) == &"spawn" and String(item.get("id", "")) == id:
			retains_spawn = true
	_expect(not retains_spawn, "rejected actor is not retained as a successful timeline birth")


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


func _window_unit_count(packet: Dictionary, arrival_window: int) -> int:
	var squads: Array = packet["squads"]
	var squads_per_window := int(packet.get("squads_per_window", 4))
	var first_squad := arrival_window * squads_per_window
	var end_squad := mini(squads.size(), first_squad + squads_per_window)
	var total := 0
	for squad_index in range(first_squad, end_squad):
		total += Array(squads[squad_index]).size()
	return total


func _packet_unit_count(packet: Dictionary) -> int:
	var total := 0
	for squad in Array(packet.get("squads", [])):
		total += Array(squad).size()
	return total


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
