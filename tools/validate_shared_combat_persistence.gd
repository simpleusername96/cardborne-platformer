extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const TargetFixture = preload("res://tools/fixtures/SharedCombatTarget.gd")

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	if profile_state == null or run_state == null:
		_failures.append("Profile and run autoloads are required.")
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	profile_state.spend_ranged_supply(&"arrows", 10)
	if not bool(run_state.start_new_run(0, 1702)):
		_failures.append("Shared hero run could not start.")
		_finish()
		return
	_expect(
		int(profile_state.get_ranged_supplies().get("arrows", 0)) == 8,
		"Run start must restore the equipped bow's minimum arrow supply."
	)

	var world := Node2D.new()
	root.add_child(world)
	var packed_player := load(PLAYER_SCENE) as PackedScene
	var player := packed_player.instantiate() as CharacterBody2D
	var target: Variant = TargetFixture.new()
	target.add_to_group("enemies")
	world.add_child(player)
	world.add_child(target)
	player.global_position = Vector2(240.0, 320.0)
	target.global_position = player.global_position + Vector2(62.0, -24.0)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.make_current()
		camera.reset_smoothing()
	await process_frame
	var combat: Variant = player.get_node("CombatController")
	var loadout: Dictionary = run_state.get_hero_combat_loadout_snapshot()
	var melee_attack := (loadout["melee"] as Dictionary).get("attack") as AttackDefinition
	var before_condition := _equipment_condition(profile_state, "traveler_sword")

	for action_serial in range(1, 5):
		combat.apply_runtime_hit(
			target,
			melee_attack,
			{},
			false,
			{
				"action_serial": action_serial,
				"shared_intent_mode": &"melee",
				"shared_tool_id": &"traveler_sword",
			}
		)
		if action_serial == 1:
			_expect(
				is_equal_approx(
					_equipment_condition(profile_state, "traveler_sword"),
					before_condition - 1.0
				),
				"One confirmed melee action must consume one condition."
			)
	_expect(
		is_equal_approx(
			_equipment_condition(profile_state, "traveler_sword"),
			before_condition - 4.0
		),
		"Distinct melee actions must each settle condition exactly once."
	)
	_expect(
		target.delayed_damage_events.size() == 2,
		"The fourth direct attack must schedule two Ember burn ticks."
	)

	target.global_position = player.global_position + Vector2(280.0, -24.0)
	var arrows_before := int(profile_state.get_ranged_supplies().get("arrows", 0))
	var started := bool(combat.call("_try_start_contextual_attack"))
	var combat_snapshot: Dictionary = combat.get_state_snapshot()
	_expect(started, "A valid distant target should start the ranged action.")
	_expect(
		StringName((combat_snapshot.get("committed_intent", {}) as Dictionary).get("mode", &"")) == &"ranged",
		"Distant target should commit the ranged intent."
	)
	_expect(
		int(profile_state.get_ranged_supplies().get("arrows", 0)) == arrows_before - 1,
		"Committed ranged action must persist one arrow debit."
	)

	combat.reset_combat_state()
	var matchlock_loadout: Dictionary = run_state.get_hero_combat_loadout_snapshot()
	var matchlock_model := load("res://data/equipment/models/matchlock.tres") as EquipmentModelDefinition
	var matchlock_attack := matchlock_model.attack_definition.duplicate(true) as AttackDefinition
	(matchlock_loadout["ranged"] as Dictionary)["model"] = matchlock_model
	(matchlock_loadout["ranged"] as Dictionary)["attack"] = matchlock_attack
	combat.configure_shared_hero(matchlock_loadout, run_state.get_effective_stats())
	_expect(bool(combat.call("_begin_attack", matchlock_attack)), "Matchlock action should start.")
	combat.update_combat(0.13)
	_expect(combat.can_dash_cancel_reload(), "Matchlock recovery should allow dash cancellation.")
	_expect(combat.cancel_reload_for_dash(), "Dash cancellation should interrupt matchlock recovery.")
	_expect(combat.current_attack == null, "Canceled reload should release the action lock.")
	_expect(
		combat.get_cooldown_remaining(matchlock_attack.id) >= matchlock_model.reload_seconds - 0.001,
		"Canceled matchlock reload should restart its full reload timer."
	)

	world.queue_free()
	await process_frame
	_finish()


func _equipment_condition(profile_state: Node, model_id: String) -> float:
	return float(
		(profile_state.get_crafted_equipment().get(model_id, {}) as Dictionary).get(
			"condition", 0.0
		)
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SHARED_COMBAT_PERSISTENCE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
