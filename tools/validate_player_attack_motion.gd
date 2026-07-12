extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("/root/Game")
	if game == null:
		_failures.append("Game autoload is unavailable.")
		quit(1)
		return

	game.ensure_input_map()
	await _check_profile_attack(0, "wide_slash", false, 0.18)
	await _check_profile_attack(1, "arrow_projectile", true)
	await _check_profile_attack(2, "quick_slash", false)

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	quit()


func _check_profile_attack(
	profile_index: int,
	expected_style: String,
	expects_projectile: bool,
	startup_wait: float = 0.0
) -> void:
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null:
		_failures.append("RunState autoload is unavailable.")
		return
	run_state.start_new_run(profile_index)

	var packed_scene := load(PLAYER_SCENE) as PackedScene
	if packed_scene == null:
		_failures.append("Unable to load player scene.")
		return

	var world := Node2D.new()
	world.name = "AttackValidationWorld"
	root.add_child(world)

	var player := packed_scene.instantiate()
	world.add_child(player)
	await process_frame
	if profile_index == 0:
		player.facing = -1

	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	if startup_wait > 0.0:
		await create_timer(startup_wait).timeout
	await physics_frame

	var combat := player.get_node_or_null("CombatController") as PlayerCombatController
	var hitbox := player.get_node_or_null("AttackHitbox") as Hitbox
	var attack_visual := player.get_node_or_null("AttackMotionVisual") as Polygon2D
	if combat == null or combat.current_attack == null:
		_failures.append("Profile %d did not start a combat action." % profile_index)
		world.queue_free()
		await process_frame
		return
	if str(combat.current_attack.motion_style) != expected_style:
		_failures.append(
			"Profile %d expected style %s, got %s."
			% [profile_index, expected_style, str(combat.current_attack.motion_style)]
		)

	if hitbox == null:
		_failures.append("Profile %d has no attack hitbox." % profile_index)
	elif not expects_projectile and not hitbox.visible:
		_failures.append("Profile %d attack visual parent is not visible after attack." % profile_index)

	if attack_visual == null or not attack_visual.visible:
		_failures.append("Profile %d attack visual is not visible after attack." % profile_index)
	elif profile_index == 0 and attack_visual.position.x >= 0.0:
		_failures.append("Warrior attack visual should follow a left-facing startup turn.")

	var projectile_count := _count_player_projectiles(world)
	if expects_projectile:
		if hitbox != null and hitbox.active:
			_failures.append("Profile %d should not keep melee hitbox active for projectile attack." % profile_index)
		if projectile_count < 1:
			_failures.append("Profile %d did not spawn a player projectile." % profile_index)
	else:
		if hitbox == null or not hitbox.active:
			_failures.append("Profile %d did not activate melee hitbox." % profile_index)
		elif profile_index == 0 and hitbox.position.x >= 0.0:
			_failures.append("Warrior melee hitbox should follow a left-facing startup turn.")
		if projectile_count != 0:
			_failures.append("Profile %d unexpectedly spawned a projectile." % profile_index)

	world.queue_free()
	await process_frame


func _count_player_projectiles(node: Node) -> int:
	var count := 0
	if node is PlayerAttackProjectile:
		count += 1
	for child in node.get_children():
		count += _count_player_projectiles(child)
	return count
