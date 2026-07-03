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
	await _check_profile_attack(0, "heavy_swing", false)
	await _check_profile_attack(1, "arrow_projectile", true)
	await _check_profile_attack(2, "quick_slash", false)

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	quit()


func _check_profile_attack(profile_index: int, expected_style: String, expects_projectile: bool) -> void:
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

	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	await physics_frame

	if str(player.active_attack_motion_style) != expected_style:
		_failures.append("Profile %d expected style %s, got %s." % [profile_index, expected_style, str(player.active_attack_motion_style)])

	if not player.attack_hitbox.visible:
		_failures.append("Profile %d attack visual parent is not visible after attack." % profile_index)

	if player.attack_visual == null or not player.attack_visual.visible:
		_failures.append("Profile %d attack visual is not visible after attack." % profile_index)

	var projectile_count := _count_player_projectiles(world)
	if expects_projectile:
		if player.attack_hitbox.active:
			_failures.append("Profile %d should not keep melee hitbox active for projectile attack." % profile_index)
		if projectile_count < 1:
			_failures.append("Profile %d did not spawn a player projectile." % profile_index)
	else:
		if not player.attack_hitbox.active:
			_failures.append("Profile %d did not activate melee hitbox." % profile_index)
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
