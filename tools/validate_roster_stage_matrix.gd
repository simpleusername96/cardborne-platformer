extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const CURATED_SEEDS := [2207, 93117]
const EXPECTED_ACTION_IDS := {
	"warrior": ["warrior_cleave", "warrior_breaker", "warrior_shield_rush", "warrior_ground_splitter", "warrior_rally"],
	"archer": ["archer_quick_shot", "archer_power_shot", "archer_vault_shot", "archer_rain_field", "archer_threadline"],
	"assassin": ["assassin_twin_cut", "assassin_shadow_lunge", "assassin_smoke_step", "assassin_kunai_fan", "assassin_death_mark"],
}

var _failures: Array[String] = []
var _signatures: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "roster matrix needs production state")
	if profile_state == null or run_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	var packed := load(STAGE_PATH) as PackedScene
	_expect(packed != null, "production stage should load")
	if packed == null:
		_finish()
		return

	for profile_index in run_state.profiles.size():
		var profile: CharacterProfile = run_state.profiles[profile_index]
		for seed in CURATED_SEEDS:
			_expect(run_state.start_new_run(profile_index, seed), "%s seed %d should start" % [profile.id, seed])
			for stage_index in 2:
				run_state.current_stage_index = stage_index
				var stage: Variant = packed.instantiate()
				root.add_child(stage)
				await process_frame
				await physics_frame
				_validate_stage(stage, profile, seed, stage_index)
				stage.queue_free()
				await process_frame
	_finish()


func _validate_stage(
	stage: Variant,
	profile: CharacterProfile,
	seed: int,
	stage_index: int
) -> void:
	var label := "%s seed %d stage %d" % [profile.id, seed, stage_index + 1]
	_expect(stage != null and stage.is_setup_complete(), "%s should assemble" % label)
	if stage == null or not stage.is_setup_complete():
		return
	var plan: StagePlan = stage.get_stage_plan()
	_expect(plan != null, "%s should retain its StagePlan" % label)
	_expect(stage.get_generation_report() != null, "%s should retain generation evidence" % label)
	_expect(stage.player != null, "%s should spawn its player" % label)
	if plan == null or stage.player == null:
		return

	var combat: PlayerCombatController = stage.player.combat_controller
	_expect(combat.kit != null and combat.kit.profile_id == StringName(profile.id), "%s should use its typed kit" % label)
	var actual_ids: Array[String] = []
	for action in combat.get_state_snapshot().get("actions", []):
		actual_ids.append(String(action.get("id", "")))
	_expect(actual_ids == EXPECTED_ACTION_IDS[profile.id], "%s should expose the exact five-action kit" % label)
	_expect(int(stage.player.stats.get("extra_jumps", 0)) >= 1, "%s should retain shared double jump" % label)

	var signature := _plan_signature(plan)
	var signature_key := "%d:%d" % [seed, stage_index]
	if not _signatures.has(signature_key):
		_signatures[signature_key] = signature
	else:
		_expect(
			signature == String(_signatures[signature_key]),
			"%s generation should not vary by selected character" % label
		)
	var expected_room_count := 7 if stage_index == 0 else 8
	_expect(plan.get_rooms().size() == expected_room_count, "%s should preserve reviewed route size" % label)
	_expect(not stage.get_critical_surface_contract().is_empty(), "%s should expose critical route support" % label)


func _plan_signature(plan: StagePlan) -> String:
	var parts: Array[String] = []
	for room in plan.get_rooms():
		parts.append("r:%s:%s:%s" % [room.id, room.template_id, room.role])
	for encounter in plan.get_encounters():
		parts.append("e:%s:%s:%s" % [encounter.room_id, encounter.anchor_id, encounter.variant_id])
	for hazard in plan.get_hazards():
		parts.append("h:%s:%s:%s" % [hazard.room_id, hazard.anchor_id, hazard.hazard_id])
	for reward in plan.get_rewards():
		parts.append("w:%s:%s:%s" % [reward.room_id, reward.anchor_id, reward.reward_table_id])
	return "|".join(parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ROSTER_STAGE_MATRIX_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
