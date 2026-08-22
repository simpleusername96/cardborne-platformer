extends SceneTree

const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const LayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const ProgressionCapture = preload(
	"res://scripts/diagnostics/vehicle_progression_telemetry_capture.gd"
)

var failures := PackedStringArray()


func _initialize() -> void:
	_validate_drop_values()
	_validate_stage_items()
	_validate_experience_runtime()
	_validate_route_level_cadence()
	_validate_level_up_cards()
	if failures.is_empty():
		print("VEHICLE_EXPERIENCE_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _validate_drop_values() -> void:
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"swarm", &"ordinary_edge_01")) == 5, "base swarm XP includes the 1.5x no-trait reward")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"standard", &"ordinary_edge_01")) == 8, "base standard XP includes the 1.5x no-trait reward")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"priority", &"ordinary_fixed_ranged_01")) == 15, "base priority XP includes the 1.5x no-trait reward")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"boss", &"boss")) == 24, "stage boss XP is 24")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"swarm", &"ordinary_edge_01", "carrier")) == 5, "summoned carrier children grant their normal XP")


func _validate_stage_items() -> void:
	var layout := LayoutGenerator.generate(0xC4A2B0, Catalog.STAGE_IDS)
	for stage_id in Catalog.STAGE_IDS:
		var pickups := layout.pickup_blueprint(stage_id)
		_expect(pickups.size() == 14, "%s has four recalls and ten authored XP shards" % stage_id)
		_expect(pickups.filter(func(item): return StringName(item["kind"]) == &"repair").is_empty(), "%s has no repair pickups" % stage_id)
		_expect(pickups.filter(func(item): return StringName(item["kind"]) == &"experience_recall").size() == 4, "%s keeps four direct recall pickups" % stage_id)
		_expect(pickups.filter(func(item): return StringName(item["kind"]) == &"experience_shard").size() == 10, "%s adds ten visible XP shards" % stage_id)


func _validate_experience_runtime() -> void:
	var runtime := ExperienceRuntime.new()
	_expect(
		is_equal_approx(ExperienceRuntime.BASE_ATTRACTION_RADIUS, 132.0)
			and is_equal_approx(ExperienceRuntime.BASE_PICKUP_RADIUS, 34.0)
			and is_equal_approx(ExperienceRuntime.ATTRACT_SPEED, 520.0),
		"XP attraction starts at 132 while collection radius and speed stay unchanged"
	)
	var expected_requirements := [
		14, 16, 18, 21, 25, 30, 34, 39, 44, 50,
		56, 62, 69, 76, 83, 91, 99, 107, 116, 125,
	]
	for level_index in expected_requirements.size():
		runtime.run_level = level_index + 1
		_expect(
			runtime.required_experience() == expected_requirements[level_index],
			"level %d requirement is %d" % [
				level_index + 1, expected_requirements[level_index]
			]
		)
	var previous_requirement: int = int(expected_requirements[4])
	var previous_growth := 0
	for level in range(6, 61):
		runtime.run_level = level
		var requirement := runtime.required_experience()
		var growth: int = requirement - previous_requirement
		_expect(growth > 0, "level %d requirement increases" % level)
		if level > 6:
			_expect(
				absi(growth - previous_growth) <= 2,
				"level %d requirement growth stays smooth" % level
			)
		previous_requirement = requirement
		previous_growth = growth
	runtime.run_level = 70
	_expect(runtime.required_experience() == 1030, "level 70 remains below the very-late cap")
	runtime.run_level = 90
	_expect(runtime.required_experience() == 1536, "very-late requirements respect the 1536-XP cap")
	runtime.reset()
	runtime.spawn_shard(Vector2(120.0, 0.0), 1)
	var attraction_result := runtime.advance(
		0.05, Vector2.ZERO, ExperienceRuntime.BASE_ATTRACTION_RADIUS, 0.0
	)
	_expect(
		int(attraction_result["experience"]) == 0
			and runtime.shards.size() == 1
			and runtime.shards[0].pos.x < 120.0,
		"base attraction reaches a shard outside the former 92-unit radius"
	)
	runtime.reset()
	runtime.spawn_shard(Vector2(133.0, 0.0), 1)
	runtime.advance(
		0.05, Vector2.ZERO, ExperienceRuntime.BASE_ATTRACTION_RADIUS, 0.0
	)
	_expect(
		runtime.shards.size() == 1
			and runtime.shards[0].pos.is_equal_approx(Vector2(133.0, 0.0)),
		"base attraction does not reach beyond its 132-unit boundary"
	)
	runtime.reset()
	var empty_receipt := runtime.advance(0.0, Vector2.ZERO, 0.0, 0.0)
	var source_buffer: Array = empty_receipt["reward_sources"]
	var repeated_empty_receipt := runtime.advance(
		0.0, Vector2.ZERO, 0.0, 0.0
	)
	_expect(
		is_same(empty_receipt, repeated_empty_receipt)
		and is_same(source_buffer, repeated_empty_receipt["reward_sources"]),
		"empty XP advances reuse one borrowed receipt and source buffer"
	)
	for index in ExperienceRuntime.MAX_SHARDS + 20:
		runtime.spawn_shard(Vector2(float(index), 0.0), 1)
	_expect(runtime.shards.size() == ExperienceRuntime.MAX_SHARDS, "shard cap merges overflow")
	_expect(runtime.total_uncollected_experience() == ExperienceRuntime.MAX_SHARDS + 20, "shard merging preserves XP")
	_expect(runtime.validate_capacity(), "live shards and the preallocated pool preserve fixed capacity")
	runtime.reset()
	_expect(
		runtime.validate_capacity()
		and int(runtime.snapshot()["shard_pool"]) == ExperienceRuntime.MAX_SHARDS,
		"reset retires every shard to the preallocated pool"
	)
	runtime.spawn_shard(Vector2.ZERO, 7, &"boss")
	var result := runtime.advance(0.016, Vector2.ZERO, 100.0, 0.0)
	_expect(
		is_same(result, empty_receipt)
		and is_same(result["reward_sources"], source_buffer),
		"non-empty XP collection reuses the borrowed receipt identity"
	)
	_expect(runtime.run_level == 1 and runtime.experience == 7, "7 XP remains below the first 14-XP threshold")
	runtime.spawn_shard(Vector2.ZERO, 7, &"boss")
	runtime.advance(0.016, Vector2.ZERO, 100.0, 0.0)
	_expect(runtime.run_level == 2 and runtime.experience == 0, "14 XP reaches level two without overflow")
	_expect(runtime.pending_level_ups == 1 and int(result["levels"]) == 1, "collected XP queues a level")
	_expect(&"boss" in result["reward_sources"], "boss reward source survives shard collection")
	_expect(runtime.consume_pending_level() and runtime.pending_level_ups == 0, "one confirmed card consumes one queued level")
	_expect(runtime.required_experience() == 16, "level two requirement follows the early locked curve")
	runtime.reset()
	runtime.spawn_shard(Vector2(900.0, 0.0), 2)
	_expect(
		int(runtime.advance(
			0.1, Vector2.ZERO, ExperienceRuntime.BASE_ATTRACTION_RADIUS, 0.0
		)["experience"]) == 0,
		"distant XP is not awarded before collection"
	)
	var recall_remaining := 0.65
	var recalled_experience := 0
	var moving_player := Vector2.ZERO
	var recall_frame := 0
	while recall_remaining > 0.0 and recall_frame < 60:
		if recall_frame == 9:
			moving_player += Vector2(240.0, -80.0)
		elif recall_frame == 24:
			moving_player += Vector2(180.0, 120.0)
		var recall_delta := minf(1.0 / 60.0, recall_remaining)
		var recall_result := runtime.advance(
			recall_delta,
			moving_player,
			92.0,
			recall_remaining
		)
		recalled_experience += int(recall_result["experience"])
		recall_remaining = maxf(0.0, recall_remaining - recall_delta)
		recall_frame += 1
	_expect(
		recalled_experience == 2 and runtime.shards.is_empty(),
		"experience recall reaches the ship's current position through dash-like movement"
	)
	runtime.reset()
	runtime.spawn_shard(Vector2.ZERO, 100, &"boss")
	result = runtime.advance(0.0, Vector2.ZERO, 92.0, 0.0)
	_expect(
		int(result["levels"]) == 5
			and runtime.pending_level_ups == 5
			and runtime.experience == 6,
		"100 XP safely queues five level-ups at the tuned early thresholds"
	)
	_expect(&"boss" in result["reward_sources"], "boss reward remains queued behind simultaneous levels")
	runtime.spawn_shard(Vector2(120.0, 0.0), 12)
	_expect(runtime.complete_progression(), "catalog exhaustion marks progression complete once")
	_expect(
		bool(runtime.snapshot()["complete"])
			and runtime.pending_level_ups == 0
			and runtime.experience == 0
			and runtime.shards.is_empty(),
		"MAX clears queued levels, carried XP, and live shards"
	)
	runtime.spawn_shard(Vector2.ZERO, 100, &"boss")
	result = runtime.advance(0.0, Vector2.ZERO, 100.0, 0.0)
	_expect(
		int(result["experience"]) == 0
			and int(result["levels"]) == 0
			and runtime.shards.is_empty(),
		"MAX suppresses future shard spawning and XP awards"
	)
	_expect(not runtime.complete_progression(), "progression completion receipt is emitted only once")
	runtime.reset()
	_expect(
		runtime.run_level == 1
			and runtime.experience == 0
			and runtime.pending_level_ups == 0
			and runtime.shards.is_empty()
			and not runtime.progression_complete,
		"run reset clears XP, levels, completion, choices, and shards"
	)


func _validate_route_level_cadence() -> void:
	var identity := {
		"schema_version":1, "identity_status":"resolved",
		"commit":"a".repeat(40), "ref":"fixture", "source_cleanliness":"clean",
		"content_fingerprint":"b".repeat(64),
	}
	var bundle := ProgressionCapture.new().build("experience-validation", identity)
	var stages: Array = bundle.get("stages", [])
	var expected_stage_levels := [17, 23, 27, 31, 35, 38, 41, 44, 48, 51, 55, 58]
	var expected_stage_experience := [
		777, 741, 794, 855, 1063, 1094, 1197, 1274, 1788, 1867, 1938, 2122,
	]
	_expect(
		bool(Dictionary(bundle.get("acceptance", {})).get("capture_valid", false)),
		"the deterministic composed-identity progression trace is valid"
	)
	_expect(stages.size() == 12, "the campaign exposes twelve boss cycles")
	for stage_index in mini(stages.size(), expected_stage_levels.size()):
		var stage := Dictionary(stages[stage_index])
		_expect(
			int(stage.get("level_reached", 0)) == expected_stage_levels[stage_index],
			"stage %d reaches projected level %d (actual %d)" % [
				stage_index + 1, expected_stage_levels[stage_index],
				int(stage.get("level_reached", 0))
			]
		)
		_expect(
			int(stage.get("stage_xp", 0)) == expected_stage_experience[stage_index],
			"stage %d composed-identity trace yields %d XP" % [
				stage_index + 1, expected_stage_experience[stage_index]
			]
		)
	var run := Dictionary(bundle.get("run", {}))
	_expect(
		int(run.get("xp_collected", 0)) == 15510,
		"the current semantic-pack route yields 15510 total XP"
	)
	_expect(
		int(run.get("modal_opens", 0)) == 57
			and int(run.get("level_reached", 0)) == 58,
		"the semantic-pack XP trace reaches level 58 with 57 rewards"
	)


func _enemy(health_class: StringName, role: StringName, carrier_id: String = "") -> EnemyState:
	var enemy := EnemyState.new()
	enemy.health_class = health_class
	enemy.role = role
	enemy.carrier_id = carrier_id
	return enemy


func _validate_level_up_cards() -> void:
	var catalog := UpgradeCatalog.new()
	var build := RunBuild.new(catalog)
	var offer := catalog.offer(build, 0, 0, &"level_up", 0)
	_expect(offer.size() == 3, "level-up source produces three choices")
	for _level in 6:
		_expect(
			bool(build.apply(&"pickup_radius").get("applied", false)),
			"Pickup Magnet applies every authored collection level"
		)
	_expect(
		is_equal_approx(build.stat(&"pickup_radius_bonus", 0.0), 216.0)
			and is_equal_approx(
				ExperienceRuntime.BASE_ATTRACTION_RADIUS
					+ build.stat(&"pickup_radius_bonus", 0.0),
				348.0
			),
		"Pickup Magnet ends at +216 and a 348-unit effective attraction radius"
	)
	var first_operations_preview := build.fallback_preview(&"fallback_operations")
	_expect(
		StringName(first_operations_preview.get("effect_id", &"")) == &"pickup_radius"
			and is_equal_approx(float(first_operations_preview.get("value", 0.0)), 14.0),
		"Operations fallback previews its rebalanced +14 pickup radius"
	)
	for _rank in RunBuild.FALLBACK_MAX_RANK:
		_expect(
			bool(build.apply_fallback(&"fallback_operations").get("applied", false)),
			"Operations fallback applies every authored rank"
		)
	_expect(
		is_equal_approx(
			ExperienceRuntime.BASE_ATTRACTION_RADIUS
				+ build.stat(&"pickup_radius_bonus", 0.0),
			488.0
		)
			and is_equal_approx(build.fallback_dash_cooldown_multiplier(), 0.85),
		"full Operations fallback ends at 488 attraction without changing dash scaling"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
