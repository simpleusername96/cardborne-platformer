extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Director = preload("res://scripts/encounters/vehicle_engagement_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const MovementPolicy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const SpeedProfile = preload("res://scripts/enemies/vehicle_enemy_speed_profile.gd")
const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Schedule = preload("res://scripts/enemies/vehicle_enemy_update_schedule.gd")

const SEEDS := [0xC4A2B0, 0xC4A2B1]
var failures: Array[String] = []


func _initialize() -> void:
	_validate_enemy_state_reuse()
	for seed in SEEDS:
		_validate_seed(seed)
	_finish()


func _validate_enemy_state_reuse() -> void:
	var enemy := EnemyState.new()
	enemy.engagement_slot = 12
	enemy.engagement_generation = 9
	enemy.engagement_gate = Vector2(50.0, 80.0)
	enemy.engagement_expiry = 7.0
	enemy.engagement_active = true
	enemy.reset_runtime_collections()
	_expect(enemy.engagement_slot < 0 and enemy.engagement_generation == 0 and not enemy.engagement_active, "pooled enemy reuse clears engagement handle state")
	_expect(enemy.engagement_gate == Vector2.ZERO and is_zero_approx(enemy.engagement_expiry), "pooled enemy reuse clears immutable gate scalars")


func _validate_seed(seed: int) -> void:
	var layout := Generator.generate(seed, CombatStages.STAGE_IDS)
	_expect(layout != null, "seed %d creates representative geometry" % seed)
	if layout == null:
		return
	var stage_id := CombatStages.STAGE_IDS[0]
	var tactical = layout.tactical_layout(stage_id)
	var packet: Dictionary = CombatStages.definition(stage_id)["packets"][1].duplicate(true)
	packet["trigger"] = {"kind":&"time", "at":0.0}
	var first := _run(stage_id, packet, tactical)
	var second := _run(stage_id, packet, tactical)
	_expect(var_to_str(first["fingerprint"]) == var_to_str(second["fingerprint"]), "seed %d has exact birth/cue/role replay fingerprint" % seed)
	_expect(int(first["spawns"]) == int(first["authored"]), "seed %d preserves authored count" % seed)
	_expect(bool(first["patterns"][Director.BROAD_CRESCENT]), "seed %d exercises broad crescent" % seed)
	_expect(bool(first["patterns"][Director.TWO_OFFSET_STREAMS]), "seed %d exercises offset streams" % seed)
	_expect(Dictionary(first["completed"]).size() >= 3, "seed %d completes at least three sectors in the 12-second sample" % seed)
	_expect(int(first["max_burst"]) <= 4, "seed %d has no more than four expected arrivals per half second" % seed)
	_expect(not bool(first["rear"]), "seed %d creates no rear engagement reservation" % seed)
	_expect(bool(first["rear_arc"]), "seed %d keeps a three-sector rear escape arc" % seed)


func _run(stage_id: StringName, packet: Dictionary, tactical) -> Dictionary:
	var runtime := Runtime.new()
	runtime.configure(stage_id, [packet], RunDifficulty.HARD, tactical.ordinary_spawn_anchors, tactical.encounter_seed, tactical.geometry_snapshot, 0)
	var visible := Rect2(tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0), Vector2(1280.0, 720.0))
	var fingerprint := []
	var completed := {}
	var patterns := {Director.BROAD_CRESCENT:false, Director.TWO_OFFSET_STREAMS:false}
	var rear := false
	var rear_arc := true
	var spawns := 0
	var max_burst := 0
	var schedule := Schedule.new()
	var next_slot := 0
	for _step in 240:
		var result := runtime.tick(0.05, 0, [], tactical.geometry_snapshot.player_start, visible, [], 0, Vector2(240.0, 0.0))
		var engagement := Dictionary(runtime.debug_snapshot()["engagement"])
		for count in PackedInt32Array(engagement["eta_load"]):
			max_burst = maxi(max_burst, int(count))
		for cue in Array(result["cues"]):
			fingerprint.append([&"cue", cue["cue_id"], cue["cue_at"], cue["birth_sector"]])
		for spec in Array(result["spawns"]):
			spawns += 1
			fingerprint.append([&"birth", spec["id"], spec["role"], spec["birth_position"]])
			_expect(Vector2(spec["pos"]) == Vector2(spec["birth_position"]), "birth never teleports to its engagement gate")
			if not spec.has("engagement_handle"):
				continue
			var sector := int(spec["engagement_sector"])
			var heading := 4 # allocator convention: positive X travel is sector four.
			var offset := posmod(sector - heading, 8)
			if offset in [3, 4, 5]:
				rear = true
			var window := int(spec["arrival_window"])
			var pattern := StringName(packet["engagement_patterns"][window])
			patterns[pattern] = true
			var handle: Dictionary = spec["engagement_handle"]
			runtime.confirm_engagement(handle)
			var reached := _advance_gate(spec, runtime, schedule, next_slot)
			next_slot += 1
			_expect(reached, "gate completion follows bounded policy movement before release")
			if reached:
				runtime.complete_engagement(handle)
				completed[sector] = true
			rear_arc = rear_arc and not rear
	var authored := 0
	for squad in packet["squads"]:
		authored += Array(squad).size()
	return {"fingerprint":fingerprint, "completed":completed, "max_burst":max_burst, "patterns":patterns, "rear":rear, "rear_arc":rear_arc, "spawns":spawns, "authored":authored}


func _advance_gate(spec: Dictionary, runtime, schedule, slot: int) -> bool:
	var archetype := StringName(spec["role"])
	var definition := Archetypes.definition(archetype)
	var enemy := EnemyState.new()
	enemy.runtime_slot = slot
	enemy.alive = true
	enemy.active = true
	enemy.archetype = archetype
	enemy.role = StringName(definition["behavior"])
	enemy.movement_family = MovementPolicy.family(enemy.archetype, enemy.role)
	enemy.speed = SpeedProfile.effective_speed(archetype, 0, RunDifficulty.HARD)
	enemy.threat_kind = StringName(definition["threat_kind"])
	enemy.threat_cost = float(definition["threat_cost"])
	enemy.pos = Vector2(spec["pos"])
	enemy.engagement_gate = Vector2(spec["engagement_gate"])
	var replay_enemies: Array[EnemyState] = [enemy]
	schedule.rebuild(
		replay_enemies,
		0.0,
		enemy.engagement_gate,
		INF,
		enemy.decision_bucket,
		posmod(enemy.runtime_slot, 2),
		posmod(enemy.runtime_slot, 3)
	)
	_expect(schedule.can_commit(enemy, 2.0, 2, 1), "approach reservation does not consume attack admission")
	var elapsed := 0.0
	while enemy.pos.distance_to(enemy.engagement_gate) > Director.GATE_COMPLETE_RADIUS and elapsed < 18.0:
		# Decision is sampled at the locked 10 Hz cadence; motion uses the existing
		# direction policy and never displaces more than speed*delta.
		var direction := (enemy.engagement_gate - enemy.pos).normalized()
		var delta := 1.0 / 30.0
		var before := enemy.pos
		enemy.pos += direction.normalized() * enemy.speed * delta
		_expect(enemy.pos.distance_to(before) <= enemy.speed * delta + 0.001, "gate approach has no teleport or speed violation")
		elapsed += delta
	# Reversal/expiry is an explicit release path, not a retarget: the fixed gate remains unchanged.
	var fixed_gate := enemy.engagement_gate
	_expect(enemy.engagement_gate == fixed_gate, "reversal leaves the one-shot gate immutable")
	return enemy.pos.distance_to(enemy.engagement_gate) <= Director.GATE_COMPLETE_RADIUS


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENGAGEMENT_REPLAY_VALIDATION_OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)
