extends SceneTree

const ExperienceRuntime = preload("res://scripts/progression/vehicle_experience_runtime.gd")
const FieldDropRules = preload("res://scripts/rewards/vehicle_field_drop_rules.gd")
const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const UpgradeCatalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const RunBuild = preload("res://scripts/cards/vehicle_run_build.gd")
const CycleRuntime = preload("res://scripts/cards/vehicle_cycle_runtime.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

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
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"swarm", "role":&"chaser"}) == 1, "swarm XP is 1")
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"standard", "role":&"chaser"}) == 2, "standard XP is 2")
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"priority", "role":&"turret"}) == 4, "priority XP is 4")
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"boss", "role":&"stage_boss"}) == 24, "stage boss XP is 24")
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"swarm", "role":&"chaser", "carrier_id":"carrier"}) == 0, "carrier children grant no XP")
	_expect(FieldDropRules.experience_for_enemy({"health_class":&"priority", "role":&"boss_pylon"}) == 0, "boss pylons grant no XP")


func _validate_stage_items() -> void:
	for stage_id in Catalog.STAGE_IDS:
		var pickups := Catalog.pickup_blueprint(stage_id)
		_expect(pickups.size() == 3, "%s has exactly three authored field pickups" % stage_id)
		_expect(pickups.filter(func(item): return StringName(item["kind"]) == &"repair").size() == 2, "%s has two repair pickups" % stage_id)
		_expect(pickups.filter(func(item): return StringName(item["kind"]) == &"experience_recall").size() == 1, "%s has one recall pickup" % stage_id)
		var crates := Catalog.crate_blueprint(stage_id)
		_expect(crates.size() == 5, "%s has five crates" % stage_id)
		_expect(crates.filter(func(item): return StringName(item["drop"]) == &"repair").size() == 4, "%s crates contain four repairs" % stage_id)
		_expect(crates.filter(func(item): return StringName(item["drop"]) == &"experience_recall").size() == 1, "%s crates contain one recall" % stage_id)


func _validate_experience_runtime() -> void:
	var runtime := ExperienceRuntime.new()
	for index in ExperienceRuntime.MAX_SHARDS + 20:
		runtime.spawn_shard(Vector2(float(index), 0.0), 1)
	_expect(runtime.shards.size() == ExperienceRuntime.MAX_SHARDS, "shard cap merges overflow")
	_expect(runtime.total_uncollected_experience() == ExperienceRuntime.MAX_SHARDS + 20, "shard merging preserves XP")
	runtime.reset()
	runtime.spawn_shard(Vector2.ZERO, 28, &"boss")
	var result := runtime.advance(0.016, Vector2.ZERO, 100.0, false)
	_expect(runtime.run_level == 2 and runtime.experience == 2, "level threshold carries excess XP")
	_expect(runtime.pending_level_ups == 1 and int(result["levels"]) == 1, "collected XP queues a level")
	_expect(&"boss" in result["reward_sources"], "boss reward source survives shard collection")
	_expect(runtime.consume_pending_level() and runtime.pending_level_ups == 0, "one confirmed card consumes one queued level")
	_expect(runtime.required_experience() == 29, "level two requirement follows the locked curve")
	runtime.reset()
	runtime.spawn_shard(Vector2(900.0, 0.0), 2)
	_expect(int(runtime.advance(0.1, Vector2.ZERO, 92.0, false)["experience"]) == 0, "distant XP is not awarded before collection")
	_expect(int(runtime.advance(0.65, Vector2.ZERO, 92.0, true)["experience"]) == 2, "experience recall collects distant XP without collecting other items")
	runtime.spawn_shard(Vector2.ZERO, 100, &"boss")
	result = runtime.advance(0.0, Vector2.ZERO, 92.0, false)
	_expect(int(result["levels"]) == 3 and runtime.pending_level_ups == 3, "one collection safely queues multiple level-ups")
	_expect(&"boss" in result["reward_sources"], "boss reward remains queued behind simultaneous levels")
	runtime.reset()
	_expect(runtime.run_level == 1 and runtime.experience == 0 and runtime.pending_level_ups == 0 and runtime.shards.is_empty(), "run reset clears XP, levels, choices, and shards")


func _validate_route_level_cadence() -> void:
	var runtime := ExperienceRuntime.new()
	for stage_id in Catalog.STAGE_IDS:
		var stage_experience := 24 # Stage-boss core plus the minimum quota path.
		var counted_enemies := 0
		for spec in Catalog.enemy_blueprint(stage_id):
			if counted_enemies >= Catalog.quota(stage_id):
				break
			var definition := EnemyArchetypes.definition(StringName(spec["role"]))
			var enemy := {
				"role":StringName(definition["behavior"]),
				"health_class":StringName(definition["health_class"]),
			}
			stage_experience += FieldDropRules.experience_for_enemy(enemy)
			counted_enemies += 1
		var level_before := runtime.run_level
		runtime.spawn_shard(Vector2.ZERO, stage_experience)
		runtime.advance(0.0, Vector2.ZERO, 100.0, false)
		var levels_gained := runtime.run_level - level_before
		_expect(levels_gained >= 3 and levels_gained <= 8, "%s extended quota-path XP yields %d level-ups" % [stage_id, levels_gained])
		while runtime.consume_pending_level():
			pass


func _validate_level_up_cards() -> void:
	var catalog := UpgradeCatalog.new()
	var build := RunBuild.new(catalog)
	var offer := catalog.offer(build, 0, 0, &"level_up")
	_expect(offer.size() == 3, "level-up source produces three choices")
	var cycles := CycleRuntime.new()
	build.apply(&"aegis_cycle")
	var activations := cycles.sync_build(build)
	_expect(activations.has(&"aegis_cycle") and cycles.is_active(&"aegis_cycle"), "new cycle activates immediately")
	_expect(is_equal_approx(float(cycles.states[&"aegis_cycle"]["active"]), 5.0), "Aegis level one demonstrates its five-second window")
	cycles.advance(5.0)
	_expect(is_equal_approx(float(cycles.states[&"aegis_cycle"]["recharge"]), 14.0), "Aegis enters its exact fourteen-second recharge")
	build.apply(&"aegis_cycle")
	activations = cycles.sync_build(build)
	_expect(activations.has(&"aegis_cycle") and cycles.states.size() == 1, "upgrading a cycle re-demonstrates it without duplicating orbit state")
	_expect(is_equal_approx(float(cycles.states[&"aegis_cycle"]["active"]), 6.0), "Aegis level two uses its six-second active window")


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
