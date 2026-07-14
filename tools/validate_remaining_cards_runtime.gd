extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const PROGRESSION_CATALOG := preload(
	"res://data/equipment/equipment_progression_catalog.tres"
)
const CARD_IDS: Array[StringName] = [&"second_wind", &"last_stand"]

var _failures: Array[String] = []
var _run_state: Node
var _signal_bus: Node
var _world: Node2D
var _player: Variant
var _combat: Variant
var _runtime: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _prepare_run_state():
		_finish()
		return
	await _create_fixture()
	if _player != null:
		_validate_second_wind()
		_validate_last_stand()
	await _clear_fixture()
	_finish()


func _prepare_run_state() -> bool:
	_run_state = root.get_node_or_null("/root/RunState")
	_signal_bus = root.get_node_or_null("/root/SignalBus")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	if _run_state == null or _signal_bus == null or profile_state == null:
		_expect(false, "card fixture needs profile, run, and signal autoloads")
		return false
	profile_state.initialize_for_tests(
		EQUIPMENT_CATALOG,
		MASTERY_CATALOG,
		"",
		false,
		PROGRESSION_CATALOG
	)
	if not _run_state.start_new_run(0, 74017):
		_expect(false, "fixture should start a Traveler run")
		return false
	var stacks: Dictionary = {}
	for card_id in CARD_IDS:
		var card := _run_state.call("get_card_definition", card_id) as CardDefinition
		_expect(card != null, "production catalog should own %s" % card_id)
		stacks[String(card_id)] = 1
	_run_state.set("_card_stacks", stacks)
	return true


func _create_fixture() -> void:
	_world = Node2D.new()
	_world.name = "SurvivalCardsFixture"
	root.add_child(_world)
	_add_floor()
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	_player = player_scene.instantiate() if player_scene != null else null
	_expect(_player != null, "player fixture should instantiate")
	if _player == null:
		return
	_player.position = Vector2(0.0, 100.0)
	_world.add_child(_player)
	await _physics_steps(2)
	_combat = _player.get_node("CombatController")
	_runtime = _player.get_node("CardRuntime")
	_expect(_combat != null and _runtime != null, "player should expose card runtime contracts")


func _validate_second_wind() -> void:
	_combat.reset_combat_state()
	_combat.begin_stage()
	_run_state.max_health = 6
	_run_state.current_health = 3
	var room_a := _room_context(&"room_a")
	_signal_bus.emit_signal("required_room_encounter_started", room_a)
	_signal_bus.emit_signal("required_room_encounter_cleared", room_a)
	_expect(_run_state.current_health == 4, "Second Wind should heal a damage-free room once")
	_signal_bus.emit_signal("required_room_encounter_cleared", room_a)
	_expect(_run_state.current_health == 4, "Second Wind should not repeat in one room")

	var room_b := _room_context(&"room_b")
	_signal_bus.emit_signal("required_room_encounter_started", room_b)
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(1, null, Vector2.ZERO, [&"fixture"]))
	_signal_bus.emit_signal("required_room_encounter_cleared", room_b)
	_expect(_run_state.current_health == 3, "Second Wind should reject a damaged room")


func _validate_last_stand() -> void:
	_combat.reset_combat_state()
	_combat.begin_stage()
	_run_state.max_health = 6
	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, [&"fixture"]))
	_expect(_run_state.current_health == 1, "Last Stand should require damage ending at one health")
	_expect(_player.invulnerability_timer >= 1.19, "Last Stand should grant 1.2 seconds")
	_expect(bool(_runtime.get_state_snapshot().get("last_stand_used", false)), "Last Stand should record its stage use")

	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, [&"fixture"]))
	_expect(_player.invulnerability_timer < 1.19, "Last Stand should trigger once per stage")

	_combat.begin_stage()
	_run_state.current_health = 3
	_player.invulnerability_timer = 0.0
	_player.receive_damage(DamageInfo.new(2, null, Vector2.ZERO, [&"fixture"]))
	_expect(_player.invulnerability_timer >= 1.19, "a new stage should reset Last Stand")


func _room_context(room_id: StringName) -> Dictionary:
	return {"room_id": room_id, "stage_id": &"fixture_stage", "required_route": true}


func _add_floor() -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(100.0, 112.0)
	body.collision_layer = 1
	_world.add_child(body)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(700.0, 24.0)
	collision.shape = rectangle
	body.add_child(collision)


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
	if _run_state != null:
		_run_state.start_new_run(0, 74018)
	if _failures.is_empty():
		print("REMAINING_CARDS_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
