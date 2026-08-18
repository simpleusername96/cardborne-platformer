extends SceneTree

const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const LayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

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
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"swarm", &"ordinary_edge_01")) == 3, "swarm XP is 3")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"standard", &"ordinary_edge_01")) == 5, "standard XP is 5")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"priority", &"ordinary_fixed_ranged_01")) == 10, "priority XP is 10")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"boss", &"boss")) == 24, "stage boss XP is 24")
	_expect(FieldDropRules.experience_for_enemy(_enemy(&"swarm", &"ordinary_edge_01", "carrier")) == 3, "summoned carrier children grant their normal XP")


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
	var expected_requirements := [
		14, 16, 18, 21, 25, 30, 35, 40, 46, 53,
		53, 61, 70, 80, 90, 96, 96, 96, 96, 96,
	]
	for level_index in expected_requirements.size():
		runtime.run_level = level_index + 1
		_expect(
			runtime.required_experience() == expected_requirements[level_index],
			"level %d requirement is %d" % [
				level_index + 1, expected_requirements[level_index]
			]
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
	_expect(runtime.required_experience() == 16, "level two requirement follows the locked curve")
	runtime.reset()
	runtime.spawn_shard(Vector2(900.0, 0.0), 2)
	_expect(int(runtime.advance(0.1, Vector2.ZERO, 92.0, 0.0)["experience"]) == 0, "distant XP is not awarded before collection")
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
	var runtime := ExperienceRuntime.new()
	var total_experience := 0
	var total_levels := 0
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id := Catalog.STAGE_IDS[stage_index]
		var profile := Catalog.profile(stage_id)
		var stage_experience := 24 if bool(profile.get("has_boss", true)) else 0
		var counted_enemies := 0
		for spec in Catalog.enemy_blueprint(stage_id):
			if counted_enemies >= Catalog.quota(stage_id):
				break
			var definition := EnemyArchetypes.definition(StringName(spec["role"]))
			var enemy := _enemy(
				StringName(definition["health_class"]),
				StringName(definition["behavior"])
			)
			stage_experience += FieldDropRules.experience_for_enemy(enemy)
			counted_enemies += 1
		var level_before := runtime.run_level
		runtime.spawn_shard(Vector2.ZERO, stage_experience)
		runtime.advance(0.0, Vector2.ZERO, 100.0, 0.0)
		var levels_gained := runtime.run_level - level_before
		total_experience += stage_experience
		total_levels += levels_gained
		while runtime.consume_pending_level():
			pass
	_expect(Catalog.STAGE_IDS.size() == 12, "the campaign exposes twelve boss cycles")
	_expect(total_experience == 8947, "the corrected twelve-cycle minimum quota path yields 8947 total XP (actual %d)" % total_experience)
	_expect(total_levels == 101 and runtime.run_level == 102, "the corrected twelve-cycle quota path reaches level 102 with 101 rewards (actual %d / level %d)" % [total_levels, runtime.run_level])


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
			"Pickup Radius preserves three collection levels"
		)
	_expect(
		is_equal_approx(build.stat(&"pickup_radius_bonus", 0.0), 252.0),
		"Pickup Magnet reaches its exact final collection bonus"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
