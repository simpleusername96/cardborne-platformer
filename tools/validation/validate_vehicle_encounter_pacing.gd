extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const Allocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")

const EXPECTED_MOBILE_COUNTS := [520, 660, 816, 1026, 1260]
const EXPECTED_QUOTAS := [48, 64, 80, 96, 112]
const EXPECTED_HARD_MATERIALIZED_CAPS := [6, 40, 48, 48, 48]
const EXPECTED_HARD_AUTHORED_PRESSURE_CAPS := [6, 124, 172, 224, 276]

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
		_expect(opening_roles.size() == 6, "%s opens with six authored pursuit identities" % stage_id)
		_expect(bool(packets[0].get("nearest_safe_offscreen", false)), "%s opening reserve uses the nearest valid offscreen approach" % stage_id)
		for role_variant in opening_roles:
			var role := StringName(role_variant)
			_expect(not EnemyArchetypes.fires_projectiles(role) and StringName(EnemyArchetypes.definition(role)["threat_kind"]) not in [&"denial", &"support"], "%s opening uses only low-risk pursuit roles" % stage_id)
		for packet_index in range(1, packets.size()):
			_validate_surge_packet(packets[packet_index], stage_id)
		_validate_composition(blueprint, stage_id)
		_validate_opening_runtime(stage_id, packets, tactical)
	_validate_cap_curve(RunDifficulty.HARD, EXPECTED_HARD_MATERIALIZED_CAPS, EXPECTED_HARD_AUTHORED_PRESSURE_CAPS)
	_expect(Director.MAX_RANGED_COMMITS == 3, "ranged commit cap remains three")
	_expect(Director.MAX_DENIAL_COMMITS == 2, "denial commit cap remains two")
	_finish()


func _validate_surge_packet(packet: Dictionary, stage_id: StringName) -> void:
	var squads: Array = packet["squads"]
	_expect(int(packet.get("arrival_windows", 0)) == 3, "%s surge declares three timing windows" % stage_id)
	_expect(int(packet.get("squads_per_window", 0)) == 4, "%s surge declares four logical squads per window" % stage_id)
	_expect(float(packet.get("window_gap", 0.0)) == 1.20, "%s locks the 1.20-second window gap" % stage_id)
	_expect(float(packet.get("unit_spacing", 0.0)) == 0.16, "%s locks 0.16-second unit rounds" % stage_id)
	_expect(squads.size() == 12, "%s surge contains twelve squads" % stage_id)
	_expect(float(packet.get("cue_lead", 0.0)) >= 0.9, "%s cue lead is at least 0.9 seconds" % stage_id)
	for squad in squads:
		var size := Array(squad).size()
		_expect(size >= 4 and size <= 8, "%s squad size stays within four to eight" % stage_id)


func _validate_composition(blueprint: Array, stage_id: StringName) -> void:
	var pursuit := 0
	var direct := 0
	var denial := 0
	var support := 0
	for spec in blueprint:
		var role := StringName(spec["role"])
		var threat_kind := StringName(EnemyArchetypes.definition(role)["threat_kind"])
		if EnemyArchetypes.fires_projectiles(role):
			direct += 1
		elif threat_kind == &"denial":
			denial += 1
		elif threat_kind == &"support":
			support += 1
		else:
			pursuit += 1
	var total := float(maxi(1, blueprint.size()))
	_expect(float(pursuit) / total >= 0.65, "%s keeps at least 65%% pursuit pressure" % stage_id)
	_expect(float(direct) / total <= 0.15, "%s caps direct projectile roles at 15%%" % stage_id)
	_expect(float(denial) / total <= 0.08, "%s caps denial roles at 8%%" % stage_id)
	_expect(float(support) / total <= 0.12, "%s caps support roles at 12%%" % stage_id)


func _validate_opening_runtime(stage_id: StringName, packets: Array[Dictionary], tactical) -> void:
	var runtime := Runtime.new()
	runtime.configure(
		stage_id,
		packets,
		RunDifficulty.HARD,
		tactical.ordinary_spawn_anchors,
		tactical.encounter_seed,
		tactical.geometry_snapshot
	)
	var visible_world := Rect2(tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
	var opening_cue := runtime.tick(0.0, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	_expect(opening_cue["cues"].size() == 1 and opening_cue["spawns"].is_empty(), "%s cues the six-unit opening immediately" % stage_id)
	if not Array(opening_cue["cues"]).is_empty():
		_expect(bool(Dictionary(Array(opening_cue["cues"])[0]).get("outside_visible_margin", false)), "%s opening reserve remains outside the visible margin" % stage_id)
	runtime.tick(0.8, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	var first := runtime.tick(0.11, 0, [], tactical.geometry_snapshot.player_start, visible_world)
	_expect(first["spawns"].size() == 1, "%s begins with exactly one due birth (actual %d)" % [stage_id, Array(first["spawns"]).size()])
	if not first["spawns"].is_empty():
		var first_role := StringName(first["spawns"][0]["role"])
		_expect(not EnemyArchetypes.fires_projectiles(first_role) and StringName(EnemyArchetypes.definition(first_role)["threat_kind"]) not in [&"denial", &"support"], "%s begins with a low-risk pursuit identity" % stage_id)
	_expect(float(runtime.debug_snapshot()["first_spawn_time"]) <= 0.911, "%s begins the offscreen opening births within the configured 0.9-second lead" % stage_id)
	var opening_spawns := Array(first["spawns"]).size()
	for _opening_step in 20:
		opening_spawns += Array(runtime.tick(0.1, 0, [], tactical.geometry_snapshot.player_start, visible_world)["spawns"]).size()
		if opening_spawns == 6:
			break
	_expect(opening_spawns == 6, "%s emits all six opening identities before the normal surge" % stage_id)
	var cue_count := 0
	var maximum_tick_spawns := 0
	var first_surge_prefix := String(packets[1]["id"])
	for _step in 100:
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
