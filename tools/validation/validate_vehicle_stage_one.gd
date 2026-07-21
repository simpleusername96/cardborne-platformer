extends SceneTree

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
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
	_check_visual_contract(stage)
	_check_layout_contract(stage)
	_check_geometry_contract(stage)
	_check_upgrade_contract(stage)
	_check_pickup_contract(stage)
	_check_primary_charge_contract(stage)
	_check_dash_contract(stage)
	_check_progression_contract(stage)
	_check_multistage_contract(stage)
	_check_new_enemy_contract(stage)
	_check_projectile_cover_contract(stage)
	_check_passive_contract(stage)
	_check_reset_contract(stage)

	root_instance.free()
	stage = null
	await process_frame
	await process_frame
	_finish()


func _check_blueprint() -> void:
	var all_blueprints := Rules.validate_all_blueprints()
	for stage_id in all_blueprints.keys():
		var blueprint_errors: PackedStringArray = all_blueprints[stage_id]
		_expect(blueprint_errors.is_empty(), "%s landmarks, spawns, routes, and boss path are reachable" % stage_id)
		_expect(Rules.get_enemy_blueprint(stage_id).size() == EncounterDirector.target_count(stage_id), "%s uses the locked dense enemy population" % stage_id)
		for error_message in blueprint_errors:
			failures.append("%s blueprint: %s" % [stage_id, error_message])

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


func _check_visual_contract(stage: Node) -> void:
	var art_errors := Art.validate_contract()
	_expect(art_errors.is_empty(), "Sunken Ceramic Fresco semantic palette and scale contract is complete")
	for error_message in art_errors:
		failures.append("visual profile: %s" % error_message)
	var roles := Art.required_color_roles()
	_expect(roles["walkable"] != roles["blocked"], "walkable ground and blocked cover use distinct visual roles")
	_expect(roles["player_reward"] != roles["threat"], "player/reward and threat colors remain semantically distinct")
	_expect(Art.major_motifs().size() <= 4, "world decoration stays sparse at macro scale")

	var ui := stage.get_node_or_null("VehicleStageUI")
	_expect(ui != null, "vehicle UI exists for visual contract checks")
	if ui == null:
		return
	for viewport_width in [960.0, 1280.0, 1920.0]:
		var contract: Dictionary = ui.debug_ui_contract(viewport_width)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top HUD clusters do not overlap at %d px" % int(viewport_width))
		_expect(float(contract["command_min_height"]) >= 44.0, "command targets remain at least 44 px high")
		var rail_size := Vector2(contract["action_rail_size"])
		_expect(rail_size.x <= viewport_width - 36.0 and rail_size.y <= 88.0, "bottom action rail stays inside the combat safe frame")
		_expect(Vector2(contract["primary_slot_size"]).x > Vector2(contract["secondary_slot_size"]).x, "primary charge owns stronger visual hierarchy than utility actions")
		_expect(float(contract["body_font_weight"]) >= 600.0, "shared Korean and English body type uses a real medium-or-bolder variable weight")
		var minimum_map_width := 150.0 if viewport_width < 1100.0 else 176.0
		_expect(Vector2(contract["minimap_size"]).x >= minimum_map_width, "minimap plaque remains legible")
		_expect(
			String(contract["theme_path"]) == "res://art/ui/production/vehicle_stage_theme.tres",
			"vehicle UI uses the scoped ceramic theme"
		)
	_expect(int(ui.debug_ui_contract()["deployment_focusables"]) >= 3, "deployment exposes one launch action and both locale controls")
	_expect(int(ui.debug_ui_contract()["upgrade_focusables"]) >= 3, "upgrade exposes three focusable circuit choices")
	_expect(int(ui.debug_ui_contract()["pause_focusables"]) >= 5, "pause exposes commands and both volume controls")
	_expect(int(ui.debug_ui_contract()["result_focusables"]) >= 2, "result exposes garage and replay actions")
	_expect(int(ui.debug_ui_contract()["garage_focusables"]) >= 4, "garage exposes build summary, launch, locale, and both audio controls")
	_expect(int(ui.debug_ui_contract()["locale_controls"]) == 6, "deployment, pause, and garage each expose Korean/English controls")
	for surface in ["deployment", "upgrade", "pause", "result", "garage"]:
		var modal_contract: Dictionary = ui.debug_modal_contract(surface)
		_expect(bool(modal_contract["hud_hidden"]), "%s modal hides gameplay HUD" % surface)
		_expect(bool(modal_contract["dim_visible"]), "%s modal owns a dimmed focus layer" % surface)
	ui.show_gameplay()
	var boss_snapshot: Dictionary = stage.call("_build_hud_snapshot")
	boss_snapshot["boss"] = {"visible": true, "name": "Boss", "health": 1.0, "max_health": 1.0, "state": "Ready"}
	ui.update_hud(boss_snapshot)
	_expect(not ui._objective_panel.visible and not ui._minimap_panel.visible, "boss HUD replaces objective and minimap clusters")


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
	var attack: Dictionary = stage.debug_pickup_contract(&"attack_boost")
	_expect(float(attack["attack_timer"]) >= 7.9, "attack pickup exposes an active duration")
	var overdrive: Dictionary = stage.debug_pickup_contract(&"overdrive")
	_expect(float(overdrive["overdrive_timer"]) >= 7.9, "overdrive pickup exposes an active duration")
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


func _check_primary_charge_contract(stage: Node) -> void:
	stage.call("_reset_run", false)
	var contract: Dictionary = stage.debug_primary_charge_contract()
	_expect(is_equal_approx(float(contract["full_charge_seconds"]), 1.0), "opening shot reaches full power after one idle second")
	_expect(bool(contract["immediate_fired"]), "ordinary primary fire is never charge-gated")
	_expect(bool(contract["held_second_fired"]), "held fire repeats after the base cadence")
	_expect(bool(contract["full_fired"]), "a full opening charge produces one shot")
	_expect(float(contract["full_damage"]) >= float(contract["normal_damage"]) * 1.74, "full opening shot materially increases health damage")
	_expect(float(contract["full_structure"]) >= float(contract["normal_damage"]) * 2.99, "full opening shot triples structure damage")
	_expect(int(contract["full_pierce"]) >= 1, "full opening shot gains one temporary pierce")
	_expect(bool(contract["normal_fire_available"]), "opening charge never disables normal fire")


func _check_progression_contract(stage: Node) -> void:
	var result: Dictionary = stage.debug_full_run()
	_expect(int(result["living_before"]) >= 6, "stage starts with a role-rich ordinary roster")
	_expect(bool(result["boss_started_with_living"]), "ordinary exit works while enemies remain alive")
	_expect(bool(result["complete"]), "automated complete run reaches stage result")
	_expect(int(result["mode"]) == 4, "boss defeat enters result flow")
	_expect(int(result["upgrade_count"]) == 3, "complete stage applies calibration, relay, and boss upgrades")


func _check_multistage_contract(stage: Node) -> void:
	var result: Dictionary = stage.debug_multistage_contract()
	_expect(result["stage_ids"] == [&"flooded_works", &"tidal_archive", &"storm_drydock"], "one run advances through three authored stages in order")
	_expect(&"artillery_spotter" in result["role_sets"][1] and &"interceptor_tower" in result["role_sets"][1], "Tidal Archive deploys artillery and interception roles")
	_expect(&"shield_escort" in result["role_sets"][2], "Storm Drydock deploys shield escorts")
	_expect(result["upgrade_counts"] == [0, 3, 6], "stage transitions preserve the accumulated run upgrades")
	_expect(int(result["final_stage_index"]) == 2 and bool(result["final_complete"]), "the third boss resolves the final stage")


func _check_new_enemy_contract(stage: Node) -> void:
	var result: Dictionary = stage.debug_new_enemy_contract()
	_expect(bool(result["intercepted"]) and int(result["charges_after"]) == int(result["charges_before"]) - 1, "Interceptor Tower visibly spends one charge to stop a player shot")
	_expect(bool(result["artillery_zone_created"]), "Artillery Spotter resolves its warned attack into a denial zone")
	_expect(bool(result["escort_shielded_ally"]), "Shield Escort protects a nearby ordinary ally")


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
