extends SceneTree

const WARRIOR_KIT_PATH := "res://data/characters/warrior_kit.tres"
const CHARGER_VARIANT_PATH := "res://data/enemies/charger_ruin.tres"
const CHARGER_SCENE_PATH := "res://scenes/enemies/ChargerRuin.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var kit := load(WARRIOR_KIT_PATH) as CharacterKit
	var charger := load(CHARGER_VARIANT_PATH) as EnemyVariantDefinition
	_expect(kit != null and charger != null, "M1 pacing resources should load")
	if kit != null and charger != null:
		_validate_pacing(kit, charger)
	await _validate_charger_cycle()
	_finish()


func _validate_pacing(kit: CharacterKit, charger: EnemyVariantDefinition) -> void:
	var cleave := kit.basic_attack
	var breaker := kit.heavy_attack
	var shield_rush := kit.get_skill_by_slot(1)
	var normal_cleave := DamageResolver.resolve_attack(cleave)
	var recovery_cleave := DamageResolver.resolve_attack(
		cleave,
		{"recovery": true, "incoming_stagger_additive": 20}
	)
	var critical_breaker := DamageResolver.resolve_attack(breaker, {"staggered": true})

	_expect(
		normal_cleave.stagger + recovery_cleave.stagger >= charger.stagger_capacity,
		"one normal and one recovery Cleave should set up a Charger stagger"
	)
	_expect(
		charger.recovery_time >= cleave.startup_time + cleave.active_time,
		"Charger recovery should fit one readable Cleave punish"
	)
	_expect(charger.warning_time >= 0.40, "Charger warning must preserve reaction floor")
	_expect(critical_breaker.critical, "Breaker should convert the stagger setup into a critical")
	_expect(
		float(critical_breaker.final_damage) / breaker.total_duration()
		> float(normal_cleave.final_damage) / cleave.total_duration(),
		"earned critical Breaker should outperform uninterrupted Basic spam"
	)
	_expect(
		shield_rush != null
		and shield_rush.frontal_guard_during_active
		and shield_rush.movement_distance >= 180.0,
		"Shield Rush should remain a spacing and defense verb"
	)


func _validate_charger_cycle() -> void:
	var packed_charger := load(CHARGER_SCENE_PATH) as PackedScene
	_expect(packed_charger != null, "Ruin Charger scene should load for pacing fixture")
	if packed_charger == null:
		return
	var world := Node2D.new()
	root.add_child(world)
	_add_floor(world)
	var player_marker := Node2D.new()
	player_marker.add_to_group("player")
	player_marker.position = Vector2(0.0, 100.0)
	world.add_child(player_marker)
	var charger: Variant = packed_charger.instantiate()
	charger.position = Vector2(300.0, 100.0)
	world.add_child(charger)
	await _physics_steps(70)
	_expect(charger.get("_state") == "warning", "Charger should enter warning from patrol")
	await _physics_steps(25)
	_expect(charger.get("_state") == "charge", "Charger should enter charge after warning")
	await _physics_steps(33)
	_expect(charger.get("_state") == "recovery", "Charger should expose a recovery state")
	var snapshot: Dictionary = charger.get_combat_snapshot()
	_expect(
		bool(snapshot.get("recovery", false))
		and int(snapshot.get("incoming_stagger_additive", 0)) == 20,
		"Charger recovery should expose its +20 stagger punish contract"
	)
	world.queue_free()
	await process_frame


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(150.0, 112.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(900.0, 24.0)
	collision.shape = rectangle
	floor.add_child(collision)


func _physics_steps(count: int) -> void:
	for _step in count:
		await physics_frame
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("M1_COMBAT_PACING_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
