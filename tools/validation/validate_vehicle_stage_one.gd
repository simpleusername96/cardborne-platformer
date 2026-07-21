extends SceneTree

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const MAIN_SCENE := "res://scenes/main/PivotRoot.tscn"

var failures: PackedStringArray = []
var checks_run := 0


func _initialize() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	print("VEHICLE_STAGE_VALIDATION_BEGIN")
	_check_blueprint()
	var packed: PackedScene = load(MAIN_SCENE)
	_expect(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return

	var root_instance := packed.instantiate()
	get_root().add_child(root_instance)
	await process_frame
	await process_frame

	var stage := root_instance.get_node_or_null("VehicleStageOne")
	_expect(stage != null, "VehicleStageOne is the active main runtime")
	if stage == null:
		_finish()
		return

	_check_input_contract()
	_check_layout_contract(stage)
	_check_geometry_contract(stage)
	_check_upgrade_contract(stage)
	_check_pickup_contract(stage)
	_check_dash_contract(stage)
	_check_progression_contract(stage)
	_check_projectile_cover_contract(stage)
	_check_passive_contract(stage)
	_check_reset_contract(stage)

	root_instance.free()
	stage = null
	await process_frame
	await process_frame
	_finish()


func _check_blueprint() -> void:
	var blueprint_errors := Rules.validate_blueprint()
	_expect(blueprint_errors.is_empty(), "authored stage landmarks, spawns, routes, and boss path are reachable")
	for error_message in blueprint_errors:
		failures.append("blueprint: %s" % error_message)

	var start := Rules.PLAYER_START
	_expect(Rules.grid_reachable(start, Rules.GENERATOR_A_POSITION), "upper generator is reachable")
	_expect(Rules.grid_reachable(start, Rules.GENERATOR_B_POSITION), "lower generator is reachable")
	_expect(Rules.grid_reachable(start, Rules.CHEST_POSITION), "upgrade cache is reachable")
	_expect(
		Rules.grid_reachable(start, Rules.get_landmarks()["upper_route"])
		and Rules.grid_reachable(start, Rules.get_landmarks()["lower_route"]),
		"both risk routes are traversable"
	)


func _check_input_contract() -> void:
	_expect(_action_has_key(&"move_left", KEY_LEFT), "left arrow movement preserved")
	_expect(_action_has_key(&"move_left", KEY_A), "WASD movement supported")
	_expect(_action_has_key(&"move_right", KEY_RIGHT), "right arrow movement preserved")
	_expect(_action_has_key(&"move_up", KEY_W), "WASD vertical movement supported")
	_expect(_action_has_mouse(&"primary_fire", MOUSE_BUTTON_LEFT), "left mouse primary fire registered")
	_expect(_action_has_key(&"primary_fire", KEY_SHIFT), "Left Shift primary fallback registered")
	_expect(_action_has_key(&"dash", KEY_SPACE), "Space dash registered")
	_expect(_action_has_key(&"active_skill", KEY_Z), "Z active skill registered")
	_expect(_action_has_key(&"pause", KEY_ESCAPE), "Escape pause registered")


func _check_layout_contract(stage: Node) -> void:
	var ui := stage.get_node_or_null("VehicleStageUI")
	_expect(ui != null, "vehicle HUD exists")
	if ui == null:
		return
	var minimums: Dictionary = ui.debug_layout_minimums()
	for viewport_size in [Vector2(960.0, 540.0), Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)]:
		for surface_id in minimums.keys():
			var minimum: Vector2 = minimums[surface_id]
			_expect(
				minimum.x <= viewport_size.x and minimum.y <= viewport_size.y,
				"%s surface fits %dx%d" % [surface_id, int(viewport_size.x), int(viewport_size.y)]
			)


func _check_geometry_contract(stage: Node) -> void:
	var contract: Dictionary = stage.debug_projectile_cover_contract()
	_expect(bool(contract["hit"]), "segment collision identifies solid cover")
	_expect(not bool(contract["miss"]), "segment collision does not invent cover")
	_expect(Vector2(contract["normal"]).is_equal_approx(Vector2.LEFT), "cover hit reports a stable reflection normal")

	var movement_start := Vector2(900.0, 700.0)
	var movement_end := Rules.move_circle(movement_start, Vector2(220.0, 0.0), Rules.PLAYER_RADIUS)
	_expect(movement_end.x < 970.0, "vehicle cannot enter solid cover")
	_expect(movement_end.distance_to(movement_start) < 100.0, "blocked movement remains predictable")


func _check_upgrade_contract(stage: Node) -> void:
	stage.call("_reset_run", false)
	var first := bool(stage.debug_apply_upgrade(&"ricochet_matrix"))
	var second := bool(stage.debug_apply_upgrade(&"ricochet_matrix"))
	_expect(first, "upgrade applies on first selection")
	_expect(not second, "upgrade cannot apply twice")
	var snapshot: Dictionary = stage.debug_snapshot()
	_expect(snapshot["applied_upgrades"].size() == 1, "one card produces exactly one applied behavior")


func _check_pickup_contract(stage: Node) -> void:
	var repair: Dictionary = stage.debug_pickup_contract(&"repair")
	_expect(bool(repair["collected_once"]) and float(repair["health"]) > 50.0, "repair pickup heals immediately")
	var attack: Dictionary = stage.debug_pickup_contract(&"attack")
	_expect(float(attack["attack_timer"]) >= 8.9, "attack pickup exposes an active duration")
	var overdrive: Dictionary = stage.debug_pickup_contract(&"overdrive")
	_expect(float(overdrive["overdrive_timer"]) >= 8.9, "overdrive pickup exposes an active duration")
	var barrier: Dictionary = stage.debug_pickup_contract(&"barrier")
	_expect(float(barrier["barrier"]) >= 48.0, "barrier pickup grants readable strength")


func _check_dash_contract(stage: Node) -> void:
	stage.call("_reset_run", false)
	var dash: Dictionary = stage.debug_dash_contract()
	var displacement := float(dash["displacement"])
	_expect(displacement >= 200.0 and displacement <= 270.0, "dash has predictable meaningful displacement")
	_expect(float(dash["cooldown"]) > 1.0, "dash exposes a real recharge state")
	_expect(bool(dash["invulnerable"]), "dash provides a reliable defensive window")
	stage.debug_apply_upgrade(&"ram_pulse")
	_expect(stage.applied_upgrades.has(&"ram_pulse"), "dash has an offensive behavior upgrade")


func _check_progression_contract(stage: Node) -> void:
	var result: Dictionary = stage.debug_full_run()
	_expect(int(result["living_before"]) >= 6, "stage starts with a role-rich ordinary roster")
	_expect(bool(result["boss_started_with_living"]), "ordinary exit works while enemies remain alive")
	_expect(bool(result["complete"]), "automated complete run reaches stage result")
	_expect(int(result["mode"]) == 4, "boss defeat enters result flow")
	_expect(int(result["upgrade_count"]) == 1, "complete run applies one chest card")


func _check_projectile_cover_contract(stage: Node) -> void:
	stage.call("_reset_run", false)
	stage.mode = 1
	stage.player_position = Vector2(900.0, 700.0)
	stage.projectiles.clear()
	stage.call("_spawn_player_projectile", Vector2(900.0, 700.0), Vector2.RIGHT, 12.0, 1000.0, 0)
	stage.call("_update_projectiles", 0.35)
	_expect(stage.projectiles.is_empty(), "primary projectile stops at ordinary solid cover")

	stage.projectiles.clear()
	stage.call(
		"_spawn_hostile_projectile",
		Vector2(1250.0, 700.0),
		Vector2.LEFT,
		10.0,
		1000.0,
		"validation enemy bolt",
		Rules.CORAL
	)
	var health_before := float(stage.player_health)
	stage.call("_update_projectiles", 0.35)
	_expect(stage.projectiles.is_empty(), "enemy projectile stops at ordinary solid cover")
	_expect(is_equal_approx(float(stage.player_health), health_before), "cover prevents enemy projectile damage")


func _check_passive_contract(stage: Node) -> void:
	var contract: Dictionary = stage.debug_passive_line_of_sight_contract()
	_expect(bool(contract["open"]), "passive secondary can detect an unobstructed target")
	_expect(not bool(contract["blocked"]), "passive secondary line of sight respects solid cover")


func _check_reset_contract(stage: Node) -> void:
	var contract: Dictionary = stage.debug_reset_contract()
	_expect(int(contract["before"]) == 1, "reset check begins with an applied card")
	_expect(int(contract["after"]) == 0, "run upgrades reset on replay")
	_expect(not bool(contract["chest_claimed"]), "chest state resets on replay")
	_expect(int(contract["generators"]) == 0, "installation objective resets on replay")


func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false


func _action_has_mouse(action: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == button:
			return true
	return false


func _expect(condition: bool, description: String) -> void:
	checks_run += 1
	if condition:
		print("PASS %s" % description)
	else:
		print("FAIL %s" % description)
		failures.append(description)


func _finish() -> void:
	var summary := {
		"checks": checks_run,
		"failures": failures.size(),
		"failure_messages": Array(failures),
	}
	print("VEHICLE_STAGE_VALIDATION_SUMMARY %s" % JSON.stringify(summary))
	if failures.is_empty():
		print("VEHICLE_STAGE_VALIDATION_OK")
		quit(0)
	else:
		push_error("Vehicle Stage 1 validation failed with %d issue(s)" % failures.size())
		quit(1)
