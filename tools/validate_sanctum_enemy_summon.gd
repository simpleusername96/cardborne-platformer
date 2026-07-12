extends SceneTree

const SUMMON_SCENE := "res://scenes/enemies/SummonNode.tscn"
const MAX_WAIT_FRAMES := 180

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var fixture := await _create_fixture()
	var world := fixture.get("world") as Node2D
	var player := fixture.get("player") as Node2D
	var summon: Variant = fixture.get("summon")
	_expect(world != null and player != null and summon != null, "Summon fixture should instantiate")
	if world != null and player != null and summon != null:
		await _validate_safe_warning_cancel(player, summon)
		await _validate_child_startup_and_caps(world, player, summon)
		await _validate_cleanup(world, player, summon)
		world.queue_free()
		await process_frame
	_finish()


func _create_fixture() -> Dictionary:
	var packed := load(SUMMON_SCENE) as PackedScene
	_expect(packed != null, "Summon Node production scene should load")
	if packed == null:
		return {}
	var world := Node2D.new()
	world.name = "SummonFixture"
	root.add_child(world)
	_add_floor(world)
	var player := Node2D.new()
	player.name = "PlayerMarker"
	player.add_to_group("player")
	player.position = Vector2(640.0, 300.0)
	world.add_child(player)
	var summon: Variant = packed.instantiate()
	summon.position = Vector2(640.0, 300.0)
	summon.encounter_bounds = Rect2(0.0, 0.0, 1280.0, 720.0)
	world.add_child(summon)
	await physics_frame
	await process_frame
	return {"world": world, "player": player, "summon": summon}


func _validate_safe_warning_cancel(player: Node2D, summon: Variant) -> void:
	_expect(summon.max_health == 8 and summon.current_health == 8, "Summon Node should have exact HP 8")
	_expect(summon.get_node_or_null("ContactHitbox") == null, "Summon Node should never deal contact damage")
	_expect(is_equal_approx(summon.spawn_warning_time, 0.45), "Summon warning should be exactly 0.45 s")
	_expect(is_equal_approx(summon.spawn_interval, 2.6), "Summon interval should be exactly 2.6 s")
	_expect(summon.max_active_children == 2 and summon.max_total_spawned == 6, "Summon caps should be exact")

	var warning_seen := false
	var pending_position := Vector2.ZERO
	for _frame in MAX_WAIT_FRAMES:
		await physics_frame
		var snapshot: Dictionary = summon.get_combat_snapshot()
		if bool(snapshot["warning"]):
			warning_seen = true
			pending_position = snapshot["pending_spawn_position"]
			var warning := summon.get_node_or_null("SpawnWarning") as Line2D
			_expect(warning != null and warning.visible, "Summon Node should show its authored spawn marker")
			break
	_expect(warning_seen, "Summon Node should warn before spawning")
	_expect(is_equal_approx(pending_position.y, 300.0), "Summon marker should resolve to stable floor support")
	_expect(
		is_equal_approx(pending_position.x, 472.0) or is_equal_approx(pending_position.x, 808.0),
		"Summon marker should use one of the two authored offsets"
	)
	if not warning_seen:
		return

	player.global_position = pending_position
	for _frame in 35:
		await physics_frame
	var canceled: Dictionary = summon.get_combat_snapshot()
	_expect(int(canceled["spawned_total"]) == 0, "Spawn should cancel when the player enters the 150 px exclusion zone")
	_expect(not bool(canceled["warning"]), "Canceled spawn warning should be removed")


func _validate_child_startup_and_caps(world: Node2D, player: Node2D, summon: Variant) -> void:
	player.global_position = Vector2(640.0, 300.0)
	summon.initial_spawn_delay = 0.04
	summon.spawn_interval = 0.04
	summon.spawn_warning_time = 0.06
	summon.child_startup_time = 0.12
	summon.reset_enemy()

	var first_spawned := await _wait_for_total(summon, 1)
	_expect(first_spawned, "Accelerated fixture should spawn the first Small Slime")
	var slimes := _slimes_in(world)
	_expect(slimes.size() == 1, "First summon should own one Small Slime")
	if slimes.is_empty():
		return
	var first: Variant = slimes[0]
	var first_snapshot: Dictionary = first.get_combat_snapshot()
	var first_contact := first.get_node_or_null("ContactHitbox") as Hitbox
	var spawn_warning := first.get_node_or_null("SpawnWarning") as Line2D
	_expect(bool(first_snapshot["spawn_warning"]), "Small Slime should begin with a spawn warning")
	_expect(first_contact != null and not first_contact.active, "Small Slime warning must be non-damaging")
	_expect(spawn_warning != null and spawn_warning.visible, "Small Slime warning should be visible")

	var activated := false
	for _frame in 20:
		await physics_frame
		if bool(first.get_combat_snapshot()["spawn_active"]):
			activated = true
			break
	_expect(activated, "Small Slime should activate after its startup delay")
	_expect(first_contact != null and first_contact.active, "Small Slime contact should activate only after warning")

	_expect(await _wait_for_total(summon, 2), "Summon Node should reach two active children")
	for _frame in 90:
		await physics_frame
		var snapshot: Dictionary = summon.get_combat_snapshot()
		_expect(int(snapshot["active_children"]) <= 2, "Summon Node must never exceed two active children")
	_expect(int(summon.get_combat_snapshot()["spawned_total"]) == 2, "Active cap should stop additional spawns")

	for target_total in range(3, 7):
		var active_child: Variant = _first_active_slime(world)
		_expect(active_child != null, "Cap fixture needs an active child to defeat")
		if active_child == null:
			break
		active_child.receive_damage(DamageInfo.new(99))
		await process_frame
		_expect(await _wait_for_total(summon, target_total), "Summon Node should refill through total %d" % target_total)
		_expect(int(summon.get_combat_snapshot()["active_children"]) <= 2, "Refill must preserve the active cap")

	var capped: Dictionary = summon.get_combat_snapshot()
	_expect(int(capped["spawned_total"]) == 6, "Summon Node should stop at six total children")
	_expect(int(capped["owned_children"]) == 6, "Summon Node should retain defeated children for owner cleanup")
	for _frame in 90:
		await physics_frame
	_expect(int(summon.get_combat_snapshot()["spawned_total"]) == 6, "Total cap should prevent a seventh child")


func _validate_cleanup(world: Node2D, player: Node2D, summon: Variant) -> void:
	summon.reset_enemy()
	await process_frame
	await process_frame
	var reset_snapshot: Dictionary = summon.get_combat_snapshot()
	_expect(int(reset_snapshot["spawned_total"]) == 0, "Summon reset should reset total count")
	_expect(int(reset_snapshot["owned_children"]) == 0, "Summon reset should clear its child registry")
	_expect(_slimes_in(world).is_empty(), "Summon reset should remove live and defeated child nodes")

	player.global_position = Vector2(640.0, 300.0)
	_expect(await _wait_for_total(summon, 1), "Defeat cleanup fixture should spawn a child")
	summon.receive_damage(DamageInfo.new(99))
	await process_frame
	await process_frame
	_expect(int(summon.get_combat_snapshot()["owned_children"]) == 0, "Summon defeat should clear its child registry")
	_expect(_slimes_in(world).is_empty(), "Summon defeat should remove every child node")


func _wait_for_total(summon: Variant, expected_total: int) -> bool:
	for _frame in MAX_WAIT_FRAMES:
		await physics_frame
		if int(summon.get_combat_snapshot()["spawned_total"]) >= expected_total:
			return true
	return false


func _slimes_in(world: Node2D) -> Array:
	var slimes: Array = []
	for child in world.get_children():
		if child is CharacterBody2D and child.has_method("begin_spawn"):
			slimes.append(child)
	return slimes


func _first_active_slime(world: Node2D) -> Variant:
	for slime in _slimes_in(world):
		if slime.current_health > 0 and slime.visible and not slime.is_queued_for_deletion():
			return slime
	return null


func _add_floor(world: Node2D) -> void:
	var floor := StaticBody2D.new()
	floor.position = Vector2(640.0, 312.0)
	floor.collision_layer = 1
	floor.collision_mask = 0
	world.add_child(floor)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1200.0, 24.0)
	collision.shape = shape
	floor.add_child(collision)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SANCTUM_ENEMY_SUMMON_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
