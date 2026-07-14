extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const CHARACTER_CATALOG := preload("res://data/characters/character_catalog.tres")

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
	await _check_profile_attack(0, "wide_slash", &"shared_hitbox")
	await _check_profile_attack(1, "arrow_projectile", &"projectile")
	await _check_profile_attack(2, "quick_slash", &"character_runtime")
	await _check_definition_presentations()
	await _check_projectile_bounds()

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	print("PLAYER_ATTACK_MOTION_VALIDATION_OK profiles=3 modes=3 definitions=6")
	quit()


func _check_profile_attack(
	profile_index: int,
	expected_style: String,
	activation_mode: StringName
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
	var combat := player.get_node_or_null("CombatController") as PlayerCombatController
	var legacy_profile := CHARACTER_CATALOG.profiles[profile_index] as CharacterProfile
	combat.configure(legacy_profile, legacy_profile.to_stats_dictionary(), [])
	if profile_index == 0:
		player.facing = -1

	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	await physics_frame

	var hitbox := player.get_node_or_null("AttackHitbox") as Hitbox
	var attack_visual := player.get_node_or_null("AttackMotionVisual") as Polygon2D
	var presenter := player.get_node_or_null("AttackPresenter") as PlayerAttackPresenter
	if combat == null or combat.current_attack == null:
		_failures.append("Profile %d did not start a combat action." % profile_index)
		world.queue_free()
		await process_frame
		return
	if not await _wait_for_attack_activation(combat, hitbox, world, activation_mode):
		_failures.append(
			"Profile %d did not reach %s activation before timeout."
			% [profile_index, activation_mode]
		)
		world.queue_free()
		await process_frame
		return
	if str(combat.current_attack.motion_style) != expected_style:
		_failures.append(
			"Profile %d expected style %s, got %s."
			% [profile_index, expected_style, str(combat.current_attack.motion_style)]
		)
	if presenter == null:
		_failures.append("Profile %d has no attack presenter." % profile_index)
	else:
		var contract := presenter.get_visual_contract()
		var expected_contact := Rect2(
			-combat.current_attack.hitbox_size * 0.5,
			combat.current_attack.hitbox_size
		)
		if not _rect_approx(contract["contact_bounds"], expected_contact):
			_failures.append("Profile %d contact visual does not match attack data." % profile_index)
		if not _rect_approx(contract["contact_outline_bounds"], expected_contact):
			_failures.append("Profile %d contact outline does not match attack data." % profile_index)
		if not _rect_contains(expected_contact, contract["transformed_motion_bounds"]):
			_failures.append("Profile %d motion implies reach outside contact bounds." % profile_index)
		var should_show_contact := activation_mode != &"projectile"
		if bool(contract["contact_visible"]) != should_show_contact:
			_failures.append("Profile %d active contact visibility is incorrect." % profile_index)
		if bool(contract["contact_outline_visible"]) != should_show_contact:
			_failures.append("Profile %d active contact outline visibility is incorrect." % profile_index)

	if hitbox == null:
		_failures.append("Profile %d has no attack hitbox." % profile_index)
	elif activation_mode == &"shared_hitbox" and not hitbox.visible:
		_failures.append("Profile %d melee hitbox was not visible during activation." % profile_index)

	if attack_visual == null or not attack_visual.visible:
		_failures.append("Profile %d attack visual is not visible after attack." % profile_index)
	elif profile_index == 0 and attack_visual.position.x >= 0.0:
		_failures.append("Warrior attack visual should follow a left-facing startup turn.")

	var projectile_count := _count_player_projectiles(world)
	if activation_mode == &"projectile":
		if hitbox != null and hitbox.active:
			_failures.append("Profile %d should not keep melee hitbox active for projectile attack." % profile_index)
		if projectile_count < 1:
			_failures.append("Profile %d did not spawn a player projectile." % profile_index)
	elif activation_mode == &"shared_hitbox":
		if hitbox == null or not hitbox.active:
			_failures.append("Profile %d did not activate melee hitbox." % profile_index)
		elif profile_index == 0 and hitbox.position.x >= 0.0:
			_failures.append("Warrior melee hitbox should follow a left-facing startup turn.")
		if projectile_count != 0:
			_failures.append("Profile %d unexpectedly spawned a projectile." % profile_index)
	elif activation_mode == &"character_runtime":
		if hitbox != null and hitbox.active:
			_failures.append("Profile %d runtime-owned attack activated the shared hitbox." % profile_index)
		if projectile_count != 0:
			_failures.append("Profile %d unexpectedly spawned a projectile." % profile_index)

	world.queue_free()
	await process_frame


func _check_definition_presentations() -> void:
	var packed_scene := load(PLAYER_SCENE) as PackedScene
	if packed_scene == null:
		_failures.append("Unable to load player scene for presentation contract checks.")
		return
	var world := Node2D.new()
	root.add_child(world)
	var player := packed_scene.instantiate()
	world.add_child(player)
	await process_frame
	var presenter := player.get_node_or_null("AttackPresenter") as PlayerAttackPresenter
	if presenter == null:
		_failures.append("Player scene has no attack presenter for definition checks.")
		world.queue_free()
		await process_frame
		return

	var signatures := {}
	for profile in CHARACTER_CATALOG.profiles:
		var definitions: Array[AttackDefinition] = [
			profile.combat_kit.basic_attack,
			profile.combat_kit.heavy_attack,
		]
		for definition in definitions:
			presenter.begin(definition, 1, definition.hitbox_offset)
			presenter.update(
				definition,
				&"active",
				definition.active_time * 0.5,
				definition.active_time,
				1
			)
			var contract := presenter.get_visual_contract()
			var expected_contact := Rect2(-definition.hitbox_size * 0.5, definition.hitbox_size)
			_expect(
				_rect_approx(contract["contact_bounds"], expected_contact),
				"Attack %s contact visual must exactly match hitbox_size." % definition.id
			)
			_expect(
				_rect_approx(contract["contact_outline_bounds"], expected_contact),
				"Attack %s contact outline must exactly match hitbox_size." % definition.id
			)
			_expect(
				_rect_contains(expected_contact, contract["transformed_motion_bounds"]),
				"Attack %s transformed motion must stay inside contact bounds." % definition.id
			)
			var projectile := definition.projectile_speed > 0.0 or definition.tags.has(&"projectile")
			_expect(
				bool(contract["contact_visible"]) != projectile,
				"Attack %s contact silhouette visibility is incorrect." % definition.id
			)
			_expect(
				bool(contract["contact_outline_visible"]) != projectile,
				"Attack %s contact outline visibility is incorrect." % definition.id
			)
			signatures[String(definition.motion_style)] = String(contract["motion_signature"])

	for required_style in [
		"wide_slash", "heavy_swing", "arrow_projectile", "quick_slash", "shadow_lunge",
	]:
		_expect(signatures.has(required_style), "Missing class motion style %s." % required_style)
	_expect(
		signatures.get("wide_slash", "") != signatures.get("quick_slash", ""),
		"Warrior and Assassin basic attacks need distinct motion silhouettes."
	)
	var assassin := CHARACTER_CATALOG.get_profile_by_id("assassin")
	presenter.begin(assassin.combat_kit.basic_attack, 1, assassin.combat_kit.basic_attack.hitbox_offset)
	presenter.show_runtime_pulse(2)
	_expect(
		int(presenter.get_visual_contract()["runtime_pulse_index"]) == 2,
		"Assassin Twin Cut should expose its second visual pulse."
	)

	world.queue_free()
	await process_frame


func _check_projectile_bounds() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var projectile := PlayerAttackProjectile.new()
	projectile.projectile_size = Vector2(34.0, 8.0)
	projectile.lifetime = 10.0
	world.add_child(projectile)
	await process_frame
	var visual := projectile.get_node_or_null("Visual") as Polygon2D
	var expected := Rect2(-projectile.projectile_size * 0.5, projectile.projectile_size)
	_expect(visual != null, "Player projectile needs a visible silhouette.")
	if visual != null:
		_expect(
			_rect_contains(expected, _polygon_bounds(visual.polygon)),
			"Projectile visual must stay inside its collision size."
		)
	world.queue_free()
	await process_frame


func _wait_for_attack_activation(
	combat: PlayerCombatController,
	hitbox: Hitbox,
	world: Node,
	activation_mode: StringName
) -> bool:
	var timing := combat.get_effective_timing(combat.current_attack)
	var timeout := float(timing.get("startup", 0.0)) + 0.2
	var elapsed := 0.0
	while elapsed <= timeout:
		match activation_mode:
			&"projectile":
				if _count_player_projectiles(world) > 0:
					return true
			&"shared_hitbox":
				if hitbox != null and hitbox.active:
					return true
			&"character_runtime":
				if String(combat.get_state_snapshot().get("phase", "")) != "startup":
					return true
		await physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
	return false


func _count_player_projectiles(node: Node) -> int:
	var count := 0
	if node is PlayerAttackProjectile:
		count += 1
	for child in node.get_children():
		count += _count_player_projectiles(child)
	return count


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for index in range(1, points.size()):
		bounds = bounds.expand(points[index])
	return bounds


func _rect_approx(actual: Rect2, expected: Rect2, tolerance: float = 0.01) -> bool:
	return (
		actual.position.distance_to(expected.position) <= tolerance
		and actual.size.distance_to(expected.size) <= tolerance
	)


func _rect_contains(outer: Rect2, inner: Rect2, tolerance: float = 0.05) -> bool:
	return (
		inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
