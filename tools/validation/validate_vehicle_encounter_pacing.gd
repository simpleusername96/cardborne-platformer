extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

const EXPECTED_MOBILE_COUNTS := [260, 300, 340, 390, 440, 500, 560, 630, 700, 770, 840, 910]
const EXPECTED_QUOTAS := [90, 99, 108, 117, 126, 135, 144, 153, 162, 171, 180, 189]
const EXPECTED_HARD_MATERIALIZED_CAPS := [6, 44, 56, 64, 72]
const EXPECTED_HARD_AUTHORED_PRESSURE_CAPS := [6, 124, 172, 224, 276]
const EXPECTED_STAGE_MATERIALIZED_CAPS := [72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72]
const EXPECTED_STAGE_REFILL_FLOORS := [56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56]
const EXPECTED_STAGE_THREAT_BUDGETS := [1.0, 2.0, 3.0, 3.75, 4.5, 5.0, 5.5, 6.0, 6.25, 6.5, 6.75, 7.0]
const EXPECTED_STAGE_RANGED_CAPS := [3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4]
const EXPECTED_STAGE_DENIAL_CAPS := [2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3]

var failures: Array[String] = []


func _initialize() -> void:
	var layout := Generator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	_expect(layout != null, "fixed layout exists for encounter pacing")
	if layout == null:
		_finish()
		return
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		var tactical = layout.tactical_layout(stage_id)
		var packets := Catalog.packets(stage_id)
		var blueprint := Catalog.packet_enemy_blueprint(stage_id)
		_expect(
			blueprint.size() == EXPECTED_MOBILE_COUNTS[stage_index],
			"%s authors the locked mobile reserve" % stage_id
		)
		_expect(
			Catalog.quota(stage_id) == EXPECTED_QUOTAS[stage_index],
			"%s preserves the defeat quota" % stage_id
		)
		var opening_roles: Array = Array(packets[0]["squads"])[0]
		_expect(
			opening_roles.size() == (5 if stage_index == 0 else 6),
			"%s opens with its authored teaching or continuation-safe reserve" % stage_id
		)
		_expect(bool(packets[0].get("nearest_safe_offscreen", false)), "%s opening reserve uses the nearest valid offscreen approach" % stage_id)
		var surge_start := 5 if stage_index == 0 else 1
		for packet_index in range(surge_start, packets.size()):
			_validate_surge_packet(packets[packet_index], stage_id)
		_validate_opening_runtime(stage_id, stage_index, packets, tactical)
	_validate_cap_curve(RunDifficulty.HARD, EXPECTED_HARD_MATERIALIZED_CAPS, EXPECTED_HARD_AUTHORED_PRESSURE_CAPS)
	_expect(Director.STAGE_MATERIALIZED_ACTIVE_CAPS == EXPECTED_STAGE_MATERIALIZED_CAPS, "stage materialized caps remain independent from encounter beats")
	_expect(Director.STAGE_REFILL_FLOORS == EXPECTED_STAGE_REFILL_FLOORS, "stage refill floors preserve a rising reserve-backed pressure baseline")
	_expect(Director.STAGE_THREAT_BUDGETS == EXPECTED_STAGE_THREAT_BUDGETS, "stage threat budgets remain independent from encounter beats")
	_expect(Director.STAGE_MAX_RANGED_COMMITS == EXPECTED_STAGE_RANGED_CAPS, "late-stage ranged commit ceilings are explicit")
	_expect(Director.STAGE_MAX_DENIAL_COMMITS == EXPECTED_STAGE_DENIAL_CAPS, "late-stage denial commit ceilings are explicit")
	_expect(Director.stage_materialized_active_cap(12) == 0 and is_zero_approx(Director.stage_threat_budget(12)), "invalid stage pressure lookup fails closed")
	_expect(Director.MAX_RANGED_COMMITS == 3, "ranged commit cap remains three")
	_expect(Director.MAX_DENIAL_COMMITS == 2, "denial commit cap remains two")
	_finish()


func _validate_surge_packet(packet: Dictionary, stage_id: StringName) -> void:
	var squads: Array = packet["squads"]
	var stage_one := stage_id == &"stage_1"
	_expect(int(packet.get("arrival_windows", 0)) == (12 if stage_one else 3), "%s declares its exact timing-window count" % stage_id)
	_expect(int(packet.get("squads_per_window", 0)) == (1 if stage_one else 4), "%s declares its exact logical squads per window" % stage_id)
	_expect(float(packet.get("window_gap", 0.0)) == 1.20, "%s locks the 1.20-second window gap" % stage_id)
	_expect(float(packet.get("unit_spacing", 0.0)) == 0.16, "%s locks 0.16-second unit rounds" % stage_id)
	_expect(squads.size() == 12, "%s surge contains twelve squads" % stage_id)
	_expect(float(packet.get("cue_lead", 0.0)) >= 0.9, "%s cue lead is at least 0.9 seconds" % stage_id)
	for squad in squads:
		var size := Array(squad).size()
		_expect(size >= 4 and size <= (6 if stage_one else 8), "%s squad size stays within its exact-cap-safe range" % stage_id)


func _validate_opening_runtime(stage_id: StringName, stage_index: int, packets: Array[Dictionary], tactical) -> void:
	var runtime := Runtime.new()
	runtime.configure(
		stage_id,
		packets,
		RunDifficulty.HARD,
		tactical.ordinary_spawn_anchors,
		tactical.encounter_seed,
		tactical.geometry_snapshot,
		stage_index
	)
	_expect(runtime.materialized_active_cap() == EXPECTED_STAGE_MATERIALIZED_CAPS[stage_index], "%s applies its stage-owned materialized cap" % stage_id)
	_expect(runtime.refill_floor() == EXPECTED_STAGE_REFILL_FLOORS[stage_index], "%s applies its stage-owned refill floor" % stage_id)
	_expect(
		is_equal_approx(runtime.admission_gap_seconds(runtime.refill_floor() + 5, 0), Runtime.REFILL_WINDOW_GAP)
			and is_equal_approx(runtime.admission_gap_seconds(runtime.refill_floor() + 5, runtime.refill_floor()), Runtime.WINDOW_GAP),
		"%s accelerates reserve admission from engaged-visible count without exceeding the active cap" % stage_id
	)
	_expect(is_equal_approx(runtime.threat_budget(), EXPECTED_STAGE_THREAT_BUDGETS[stage_index]), "%s applies its stage-owned threat budget" % stage_id)
	runtime.current_beat = 4
	_expect(runtime.ranged_commit_cap() == EXPECTED_STAGE_RANGED_CAPS[stage_index], "%s applies its stage ranged ceiling" % stage_id)
	_expect(runtime.denial_commit_cap() == EXPECTED_STAGE_DENIAL_CAPS[stage_index], "%s applies its stage denial ceiling" % stage_id)
	runtime.current_beat = 0
	var visible_world := Rect2(tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
	var opening_cue := runtime.tick(0.0, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	_expect(opening_cue["cues"].size() == 1 and opening_cue["spawns"].is_empty(), "%s cues its opening lesson or reserve immediately" % stage_id)
	if not Array(opening_cue["cues"]).is_empty():
		_expect(bool(Dictionary(Array(opening_cue["cues"])[0]).get("outside_visible_margin", false)), "%s opening reserve remains outside the visible margin" % stage_id)
	runtime.tick(0.8, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	var first := runtime.tick(0.11, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	_expect(first["spawns"].size() == 1, "%s begins with exactly one due birth (actual %d)" % [stage_id, Array(first["spawns"]).size()])
	_expect(float(runtime.debug_snapshot()["first_spawn_time"]) <= 0.911, "%s begins the offscreen opening births within the configured 0.9-second lead" % stage_id)
	_expect(runtime.first_attack_preparation_time() < 0.0, "%s has no synthetic preparation before gameplay commits startup" % stage_id)
	runtime.record_attack_preparation()
	_expect(runtime.first_attack_preparation_time() <= 0.911, "%s records the first meaningful attack preparation on encounter time" % stage_id)
	var expected_opening_spawns := 15 if stage_index == 0 else 6
	var opening_spawns := Array(first["spawns"]).size()
	for _opening_step in 120:
		opening_spawns += Array(runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, visible_world)["spawns"]).size()
		if opening_spawns == expected_opening_spawns:
			break
	_expect(opening_spawns == expected_opening_spawns, "%s emits its complete opening packet before the next gate" % stage_id)
	if stage_index == 0:
		var emitted_before_gate := Array(runtime.debug_snapshot()["stage_emitted_packs"]).size()
		for _blocked_step in 30:
			runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, visible_world)
		_expect(
			emitted_before_gate == 3
				and Array(runtime.debug_snapshot()["stage_emitted_packs"]).size() == 3,
			"stage_1 holds the next lesson until the 15-defeat gate"
		)
		return
	var cue_count := 0
	var maximum_tick_spawns := 0
	var first_surge_prefix := String(packets[1]["id"])
	for _step in 300:
		var result := runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, visible_world)
		for cue in result["cues"]:
			if String(cue.get("cue_id", "")).begins_with(first_surge_prefix):
				cue_count += 1
		maximum_tick_spawns = maxi(maximum_tick_spawns, Array(result["spawns"]).size())
	_expect(cue_count == 12, "%s first surge emits four exact-position cues in each of three windows (actual %d)" % [stage_id, cue_count])
	_expect(maximum_tick_spawns <= Runtime.MAX_SPAWNS_PER_TICK, "%s dequeues at most four enemies per tick" % stage_id)
	runtime.stop_spawning()
	_expect(
		not runtime.spawning_enabled()
			and runtime.debug_snapshot()["queued_spawns"] == 0
			and runtime.debug_snapshot()["reserved_arrival_slots"] == 0,
		"%s explicit teardown can stop future arrivals" % stage_id
	)


func _validate_cap_curve(difficulty: StringName, expected_materialized: Array, expected_authored_pressure: Array) -> void:
	for beat in expected_materialized.size():
		var materialized := RunDifficulty.scaled_active_cap(Director.materialized_active_cap_for(beat), difficulty)
		var authored_pressure := RunDifficulty.scaled_active_cap(Director.authored_pressure_cap_for(beat), difficulty)
		_expect(materialized == int(expected_materialized[beat]), "%s beat %d materialized cap is locked" % [difficulty, beat])
		_expect(authored_pressure == int(expected_authored_pressure[beat]), "%s beat %d authored pressure cap is locked" % [difficulty, beat])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENCOUNTER_PACING_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
