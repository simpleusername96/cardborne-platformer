extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const ENEMY_SCRIPT_PATH := "res://scripts/enemies/EnemyBase.gd"
const WARRIOR_KIT_PATH := "res://data/characters/warrior_kit.tres"

var _failures: Array[String] = []
var _run_state: Node
var _enemy_script: Script
var _kit: CharacterKit
var _world: Node2D
var _player: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_enemy_script = load(ENEMY_SCRIPT_PATH) as Script
	_kit = load(WARRIOR_KIT_PATH) as CharacterKit
	_expect(_run_state != null and _enemy_script != null and _kit != null, "card runtime fixture needs production resources")
	if _run_state == null or _enemy_script == null or _kit == null:
		_finish()
		return

	await _validate_aerial_opener()
	await _validate_perfect_punish()
	await _validate_echo_heavy()
	await _validate_chain_burst()
	await _validate_dash_wake()
	_finish()


func _validate_aerial_opener() -> void:
	_expect(_equip_card(&"aerial_opener"), "aerial opener should be obtainable from an offer")
	await _create_fixture()
	var runtime: Node = _player.get_node("CardRuntime")
	_player.extra_jump_performed.emit()
	var modifiers: Dictionary = runtime.call("prepare_attack", _kit.basic_attack)
	_expect(float(modifiers.get("direct_damage_additive", 0.0)) == 1.0, "aerial opener should add one damage")
	_expect(float(modifiers.get("stagger_additive", 0.0)) == 20.0, "aerial opener should add 20 stagger")
	var result := DamageResolver.resolve_attack(_kit.basic_attack, {}, {}, modifiers)
	_expect(result.final_damage == 3 and result.stagger == 40, "aerial opener should alter resolved Cleave behavior")
	var consumed: Dictionary = runtime.call("prepare_attack", _kit.basic_attack)
	_expect(consumed.is_empty(), "aerial opener should apply to only the first attack")
	await _clear_fixture()


func _validate_perfect_punish() -> void:
	_expect(_equip_card(&"perfect_punish"), "perfect punish should be obtainable from an offer")
	await _create_fixture()
	var runtime: Node = _player.get_node("CardRuntime")
	var combat: Node = _player.get_node("CombatController")
	var skill: SkillDefinition = _kit.get_skill_by_slot(1)
	combat.call("_begin_attack", skill)
	var prepared: Dictionary = runtime.call("prepare_target_hit", _kit.basic_attack, {"recovery": true})
	var modifiers: Dictionary = prepared.get("modifiers", {})
	_expect(float(modifiers.get("direct_damage_additive", 0.0)) == 1.0, "perfect punish should add one damage in recovery")
	var enemy: Variant = _spawn_enemy(Vector2(60.0, 100.0), 20)
	await _physics_steps(2)
	var before: float = _cooldown_for(combat, skill.id)
	runtime.call("notify_attack_hit", {
		"definition": _kit.basic_attack,
		"damage_info": DamageInfo.new(3, _player, Vector2.ZERO, ["basic"]),
		"target": enemy,
		"target_state": {"recovery": true},
		"activations": prepared.get("activations", []),
		"defeated": false,
	})
	var after: float = _cooldown_for(combat, skill.id)
	_expect(is_equal_approx(before - after, 0.75), "perfect punish should trim the longest skill cooldown by 0.75 seconds")
	var blocked: Dictionary = runtime.call("prepare_target_hit", _kit.basic_attack, {"recovery": true})
	_expect(blocked.get("modifiers", {}).is_empty(), "perfect punish internal cooldown should block immediate repetition")
	await _clear_fixture()


func _validate_echo_heavy() -> void:
	_expect(_equip_card(&"echo_heavy"), "echo heavy should be obtainable from an offer")
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(60.0, 100.0), 20)
	await _physics_steps(2)
	var runtime: Node = _player.get_node("CardRuntime")
	runtime.call("notify_attack_hit", {
		"definition": _kit.heavy_attack,
		"damage_info": DamageInfo.new(4, _player, Vector2.ZERO, ["heavy"], _kit.heavy_attack.id, 60),
		"target": enemy,
		"target_state": {},
		"activations": [],
		"defeated": false,
	})
	await create_timer(0.30).timeout
	_expect(int(enemy.current_health) == 18, "echo heavy should repeat 40% of four damage as two delayed damage")
	_expect(int(enemy.stagger_meter) == 24, "echo heavy should repeat 40% of 60 stagger")
	await _clear_fixture()


func _validate_chain_burst() -> void:
	_expect(_equip_card(&"chain_burst"), "chain burst should be obtainable from an offer")
	await _create_fixture()
	var primary: Variant = _spawn_enemy(Vector2(0.0, 100.0), 20)
	var nearby: Variant = _spawn_enemy(Vector2(70.0, 100.0), 20)
	var far: Variant = _spawn_enemy(Vector2(180.0, 100.0), 20)
	await _physics_steps(2)
	primary.current_health = 0
	var runtime: Node = _player.get_node("CardRuntime")
	runtime.call("notify_attack_hit", {
		"definition": _kit.get_skill_by_slot(1),
		"damage_info": DamageInfo.new(2, _player, Vector2.ZERO, ["skill"]),
		"target": primary,
		"target_state": {},
		"activations": [],
		"defeated": true,
	})
	_expect(int(nearby.current_health) == 18, "chain burst should damage a nearby secondary enemy")
	_expect(int(far.current_health) == 20, "chain burst should not damage enemies outside its radius")
	_expect(int(primary.current_health) == 0, "chain burst should exclude the primary defeated target")
	await _clear_fixture()


func _validate_dash_wake() -> void:
	_expect(_equip_card(&"dash_wake"), "dash wake should be obtainable from an offer")
	await _create_fixture()
	var enemy: Variant = _spawn_enemy(Vector2(60.0, 100.0), 20)
	await _physics_steps(2)
	_player.dash_completed.emit(Vector2(0.0, 100.0), Vector2(120.0, 100.0))
	await _physics_steps(3)
	_expect(int(enemy.current_health) == 19, "dash wake should damage an enemy in the completed dash path once")
	await _physics_steps(4)
	_expect(int(enemy.current_health) == 19, "dash wake should not repeat-hit the same enemy")
	await _clear_fixture()


func _equip_card(card_id: StringName) -> bool:
	for seed in range(1, 128):
		if not _run_state.call("start_new_run", 0, seed):
			continue
		var begin: Dictionary = _run_state.call("begin_stage_card_reward")
		if not bool(begin.get("ok", false)):
			continue
		var offer: Array[StringName] = _run_state.call("get_pending_card_offer")
		if offer.has(card_id):
			return bool(_run_state.call("choose_card", card_id).get("ok", false))
	return false


func _create_fixture() -> void:
	_world = Node2D.new()
	_world.name = "CardEffectFixture"
	root.add_child(_world)
	_add_floor()
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	_player = packed_player.instantiate()
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)


func _spawn_enemy(position: Vector2, health: int) -> Variant:
	var enemy: Variant = _enemy_script.new()
	enemy.position = position
	enemy.max_health = health
	enemy.stagger_capacity = 999
	enemy.hit_knockback_multiplier = 0.0
	enemy.auto_reset_on_defeat = false
	_world.add_child(enemy)
	var contact := enemy.get_node_or_null("ContactHitbox") as Hitbox
	if contact != null:
		contact.set_active(false)
	return enemy


func _add_floor() -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(100.0, 112.0)
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(700.0, 24.0)
	collision.shape = rectangle
	body.add_child(collision)


func _cooldown_for(combat: Node, attack_id: StringName) -> float:
	var state: Dictionary = combat.call("get_state_snapshot")
	for action in state.get("actions", []):
		if String(action.get("id", "")) == String(attack_id):
			return float(action.get("cooldown", 0.0))
	return 0.0


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _clear_fixture() -> void:
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	await process_frame
	_world = null
	_player = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _world != null and is_instance_valid(_world):
		_world.queue_free()
	if _failures.is_empty():
		print("CARD_EFFECT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
