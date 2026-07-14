extends SceneTree

const CATALOG := preload("res://data/items/field_pickup_catalog.tres")
const FIELD_PICKUP_SCENE := preload("res://scenes/stages/components/FieldPickup.tscn")
const PLAYER_SCENE_PATH := "res://scenes/player/Player.tscn"

var _failures: Array[String] = []
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	var profile_state := root.get_node_or_null("/root/ProfileState")
	_expect(_run_state != null, "field pickup fixture needs RunState")
	_expect(profile_state != null, "field pickup fixture needs ProfileState")
	_expect(CATALOG.validate_catalog().is_empty(), "field pickup catalog should validate")
	if _run_state == null or profile_state == null:
		_finish()
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_validate_healing_and_retry()
	_validate_consumable_refill()
	_validate_currency_and_replay()
	_validate_material_and_ranged_supply(profile_state)
	await _validate_actor_lifecycle()
	_finish()


func _validate_healing_and_retry() -> void:
	_expect(_run_state.start_new_run(0, 912), "healing fixture run should start")
	var vital := CATALOG.get_definition(&"vital_shard")
	var full_result: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(not bool(full_result.get("applied", false)), "full-health pickup should remain available")
	_run_state.damage_player(2)
	var health_before: int = _run_state.current_health
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(bool(result.get("applied", false)), "healing pickup should apply after damage")
	_expect(_run_state.current_health == health_before + 1, "healing pickup should restore one health")
	var duplicate: Dictionary = _run_state.apply_field_pickup(&"fixture_vital", vital)
	_expect(bool(duplicate.get("duplicate", false)), "healing pickup should settle exactly once")


func _validate_consumable_refill() -> void:
	_run_state.consumable_charges = 0
	var supply := CATALOG.get_definition(&"supply_charge")
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_supply", supply)
	_expect(bool(result.get("applied", false)), "supply pickup should refill an empty charge")
	_expect(_run_state.consumable_charges == 1, "supply pickup should respect one-charge cap")
	var capped: Dictionary = _run_state.apply_field_pickup(&"fixture_supply_full", supply)
	_expect(not bool(capped.get("applied", false)), "full consumable should not consume another supply pickup")


func _validate_currency_and_replay() -> void:
	var coins_before: int = _run_state.coins
	var coin_bundle := CATALOG.get_definition(&"coin_bundle")
	var result: Dictionary = _run_state.apply_field_pickup(&"fixture_coins", coin_bundle)
	_expect(bool(result.get("applied", false)), "coin pickup should apply")
	_expect(_run_state.coins == coins_before + 3, "coin pickup should use RewardTransaction ownership")
	var duplicate: Dictionary = _run_state.apply_field_pickup(&"fixture_coins", coin_bundle)
	_expect(bool(duplicate.get("duplicate", false)), "coin pickup should reject replay")
	_expect(_run_state.coins == coins_before + 3, "replayed coin pickup must not grant twice")


func _validate_material_and_ranged_supply(profile_state: Node) -> void:
	var materials_before: Dictionary = profile_state.get_materials()
	var timber := CATALOG.get_definition(&"common_timber_bundle")
	var material_result: Dictionary = _run_state.apply_field_pickup(&"fixture_timber", timber)
	_expect(bool(material_result.get("applied", false)), "material bundle should apply")
	_expect(
		int(profile_state.get_materials().get("common_timber", 0))
		== int(materials_before.get("common_timber", 0)) + 3,
		"material bundle should persist its exact profile grant"
	)

	profile_state.spend_ranged_supply(&"arrows", 10)
	var arrows_before := int(profile_state.get_ranged_supplies().get("arrows", 0))
	var arrows := CATALOG.get_definition(&"arrow_bundle")
	var arrow_result: Dictionary = _run_state.apply_field_pickup(&"fixture_arrows", arrows)
	_expect(bool(arrow_result.get("applied", false)), "arrow bundle should apply below the cap")
	_expect(
		int(profile_state.get_ranged_supplies().get("arrows", 0)) == arrows_before + 4,
		"arrow bundle should persist four arrows"
	)
	_expect(arrow_result.get("supply_id") == "arrows", "arrow receipt should identify its supply")

	profile_state.grant_ranged_supply(&"cartridges", 99)
	var cartridges := CATALOG.get_definition(&"cartridge_pouch")
	var full_result: Dictionary = _run_state.apply_field_pickup(
		&"fixture_cartridges_full",
		cartridges
	)
	_expect(not bool(full_result.get("applied", false)), "full cartridges should leave the pouch available")


func _validate_actor_lifecycle() -> void:
	_expect(_run_state.start_new_run(0, 913), "pickup actor fixture run should start")
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	_expect(packed_player != null, "pickup collision fixture should load the production player")
	if packed_player == null:
		return
	_run_state.damage_player(2)
	var health_before: int = _run_state.current_health
	var world := Node2D.new()
	root.add_child(world)
	var floor := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rectangle := RectangleShape2D.new()
	floor_rectangle.size = Vector2(240.0, 40.0)
	floor_shape.shape = floor_rectangle
	floor.position = Vector2(100.0, 180.0)
	floor.add_child(floor_shape)
	world.add_child(floor)
	var pickup := FIELD_PICKUP_SCENE.instantiate() as FieldPickup
	pickup.pickup_id = &"fixture_actor_vital"
	pickup.definition = CATALOG.get_definition(&"vital_shard")
	pickup.position = Vector2(100.0, 110.0)
	world.add_child(pickup)
	var player := packed_player.instantiate() as CharacterBody2D
	_expect(player != null, "pickup collision fixture should instantiate the production player body")
	if player == null:
		world.queue_free()
		await process_frame
		return
	player.position = Vector2(100.0, 160.0)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = false
	world.add_child(player)
	var receipts: Array[Dictionary] = []
	var signal_bus := root.get_node_or_null("/root/SignalBus")
	var receipt_handler := func(receipt: Dictionary) -> void: receipts.append(receipt)
	signal_bus.field_pickup_collected.connect(receipt_handler)
	for _frame in 5:
		await physics_frame
		await process_frame
	_expect(_run_state.current_health == health_before + 1, "pickup actor should apply its effect")
	_expect(receipts.size() == 1, "player collision should publish one collection receipt")
	await create_timer(0.25).timeout
	_expect(not is_instance_valid(pickup), "collected pickup actor should remove itself")
	if signal_bus.field_pickup_collected.is_connected(receipt_handler):
		signal_bus.field_pickup_collected.disconnect(receipt_handler)
	world.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FIELD_PICKUP_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
