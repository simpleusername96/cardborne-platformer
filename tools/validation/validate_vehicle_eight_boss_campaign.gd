extends SceneTree

const Stages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Flow = preload("res://scripts/encounters/vehicle_stage_flow.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const Phases = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const DeathRuntime = preload("res://scripts/bosses/vehicle_boss_death_runtime.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_expect(Stages.STAGE_IDS.size() == 8 and Catalog.STAGE_IDS.size() == 8, "campaign exposes exactly eight cycles")
	for index in Stages.STAGE_IDS.size():
		var stage_id := Stages.STAGE_IDS[index]
		_expect(Stages.has_boss(stage_id), "%s is quota-gated by a boss" % stage_id)
		_expect(not Phases.definition(stage_id).is_empty(), "%s has a boss identity" % stage_id)
		_expect(Patterns.sequence(stage_id).size() == 5, "%s selects five direct patterns" % stage_id)
		_expect(Patterns.sequence(stage_id).count("common_charge") == 1 and Patterns.sequence(stage_id).count("common_broad_barrage") == 1, "%s has no more than two common selections" % stage_id)
		var rows := Patterns.broad_barrage_rows(index, Vector2.RIGHT, Patterns.barrage_mode(stage_id))
		var expected_count := 4 if index <= 2 else (5 if index <= 5 else 6)
		_expect(rows.size() == 3 and int(rows[0]["count"]) == expected_count and is_equal_approx(float(rows[1]["at"]), 0.38), "%s broad barrage has exact rows" % stage_id)
		if index > 0:
			_expect(Difficulty.boss_health(index) > Difficulty.boss_health(index - 1) and Difficulty.boss_damage_multiplier(index) > Difficulty.boss_damage_multiplier(index - 1) and Difficulty.boss_move_speed(index) > Difficulty.boss_move_speed(index - 1), "%s strengthens boss base stats" % stage_id)
	_expect(Phases.uses_shield(&"stage_3") and Phases.uses_shield(&"stage_5"), "Drydock and Crown retain offensive defenses")
	_expect(not Phases.uses_shield(&"stage_1") and not Phases.uses_shield(&"stage_8"), "other bosses do not inherit a global shield")
	var flow := Flow.new()
	flow.configure(0, 1, true)
	flow.record_countable_defeat()
	flow.advance(1.5)
	_expect(StringName(flow.record_boss_defeat()["command"]) == Flow.COMMAND_BEGIN_BOSS_CLEANUP, "boss defeat enters cleanup before transition")
	_expect(StringName(flow.record_boss_cleanup_complete()["command"]) == Flow.COMMAND_COMPLETE_AFTER_BOSS_CLEANUP, "transition unlocks only after cleanup")
	var death := DeathRuntime.new()
	var began := death.begin([&"summon_a", &"facility_a"])
	_expect(bool(began["accepted"]) and Dictionary(began["explosion"])["count"] == 1, "death begins with one explosion receipt")
	var cleanup_receipts := death.advance(1.10)
	_expect(death.snapshot()["owned_retired"] == 2, "owned cleanup retires without rewards")
	for receipt in cleanup_receipts:
		_expect(
			not bool(receipt.get("grant_experience", true))
				and not bool(receipt.get("grant_group_reward", true))
				and not bool(receipt.get("count_for_quota", true)),
			"boss cleanup receipts grant no XP, group reward, or quota"
		)
	death.advance(0.90)
	_expect(death.complete(), "death runtime completes exactly at two seconds")
	death.reset()
	_expect(not death.active() and not death.complete(), "death runtime resets for the next boss")
	_expect(bool(death.begin([&"summon_b"])["accepted"]), "reset death runtime accepts the next boss")
	for stage_id in Stages.STAGE_IDS:
		for pattern in Patterns.autonomous_sequence(stage_id):
			_expect(
				Patterns.kind(String(pattern)) in [&"area", &"lanes", &"beam", &"summon", &"long_banks", &"moving_walls", &"wedge_rings", &"spiral"],
				"%s autonomous pattern has a VehicleRun handler" % String(pattern)
			)
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_EIGHT_BOSS_CAMPAIGN_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
