extends SceneTree

const STAGE_SCENE := "res://scenes/stages/boss/SlimeCourt.tscn"
const INTRO_DURATION := 0.90
const PHASE_TRANSITION_DURATION := 0.75
const STAGGER_DURATION := 1.40

var _failures: Array[String] = []
var _run_state: Node
var _profile_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_expect(_run_state != null and _profile_state != null, "boss roster matrix needs production state")
	if _run_state == null or _profile_state == null:
		_finish()
		return
	_profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	for profile_index in _run_state.profiles.size():
		await _validate_profile_build(profile_index, false)
		await _validate_profile_build(profile_index, true)
		await _validate_profile_death(profile_index)
	_finish()


func _validate_profile_build(profile_index: int, representative: bool) -> void:
	var seed := 94000 + profile_index * 20 + (1 if representative else 0)
	_expect(_run_state.start_new_run(profile_index, seed), "boss roster run should start")
	var profile: Variant = _run_state.selected_profile
	var label := "%s %s" % [profile.id, "card build" if representative else "base build"]
	if representative:
		var offer_result: Dictionary = _run_state.begin_stage_card_reward()
		_expect(bool(offer_result.get("ok", false)), "%s should receive a card offer" % label)
		var offer: Array[StringName] = _run_state.get_pending_card_offer()
		if not offer.is_empty():
			var choice: Dictionary = _run_state.choose_card(offer[0])
			_expect(bool(choice.get("ok", false)), "%s should commit a representative card" % label)
		_expect(not _run_state.get_card_stacks().is_empty(), "%s should retain its selected card" % label)
	_run_state.current_stage_index = 3
	var stage: Variant = await _spawn_stage()
	if stage == null:
		return
	var player: Variant = stage.player
	var boss: Variant = stage.get_boss()
	var combat: Variant = player.combat_controller
	_expect(int(player.stats.get("extra_jumps", 0)) >= 1, "%s should retain shared double jump" % label)
	_expect(float(player.stats.get("jump_velocity", 0.0)) <= -420.0, "%s should retain reviewed jump height" % label)
	_expect(combat.kit != null and combat.kit.profile_id == StringName(profile.id), "%s should use its typed combat kit" % label)
	boss.set_scheduler_enabled(false)
	var basic: Variant = combat.kit.basic_attack
	var hit_count := 0
	var positive_hits := 0
	while int(boss.get_runtime_snapshot().get("health", 0)) > 0 and hit_count < 160:
		var actor_state := StringName(boss.get_runtime_snapshot().get("actor_state", &"active"))
		if actor_state == &"phase_transition":
			stage.advance_runtime(PHASE_TRANSITION_DURATION)
			continue
		if actor_state == &"staggered":
			stage.advance_runtime(STAGGER_DURATION)
			continue
		var damage_info: Variant = combat.apply_runtime_hit(
			boss,
			basic,
			{},
			false,
			{"action_serial": hit_count + 1, "attack_direction": 1}
		)
		if damage_info != null and int(damage_info.amount) > 0:
			positive_hits += 1
		hit_count += 1
	var final_snapshot: Dictionary = boss.get_runtime_snapshot()
	_expect(positive_hits > 0, "%s should produce positive resolved damage" % label)
	_expect(final_snapshot.get("actor_state") == &"defeated", "%s should defeat both boss phases" % label)
	_expect(int(final_snapshot.get("health", -1)) == 0, "%s victory should end at zero boss health" % label)
	_expect(hit_count < 160, "%s should finish within the bounded damage matrix" % label)
	stage.queue_free()
	await process_frame


func _validate_profile_death(profile_index: int) -> void:
	var seed := 94900 + profile_index
	_expect(_run_state.start_new_run(profile_index, seed), "boss death fixture should start")
	var profile_id := String(_run_state.selected_profile.id)
	_run_state.current_stage_index = 3
	var core_before := int(_profile_state.get_material_count("boss_core"))
	var stage: Variant = await _spawn_stage()
	if stage == null:
		return
	var boss: Variant = stage.get_boss()
	_run_state.damage_player(_run_state.max_health)
	await process_frame
	var snapshot: Dictionary = boss.get_runtime_snapshot()
	_expect(snapshot.get("actor_state") == &"cancelled", "%s death should cancel boss execution" % profile_id)
	_expect(not bool(snapshot.get("defeat_emitted", false)), "%s death must not emit boss defeat" % profile_id)
	_expect(
		int(_profile_state.get_material_count("boss_core")) == core_before,
		"%s death must not grant a Boss Core" % profile_id
	)
	stage.queue_free()
	await process_frame


func _spawn_stage() -> Variant:
	var packed := load(STAGE_SCENE) as PackedScene
	_expect(packed != null, "Slime Court should load for roster matrix")
	if packed == null:
		return null
	var stage: Variant = packed.instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_manual_simulation(true)
	_expect(stage.is_setup_complete(), "Slime Court should complete roster setup")
	if not stage.is_setup_complete():
		stage.queue_free()
		return null
	stage.advance_runtime(INTRO_DURATION)
	_expect(stage.is_intro_complete(), "Slime Court intro should complete for roster matrix")
	return stage


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BOSS_ROSTER_MATRIX_VALIDATION_OK profiles=3 builds=6 death_paths=3")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
