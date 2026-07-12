extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const PRODUCTION_STAGE := "res://scenes/stages/production/ProductionStageHost.tscn"
const REST_FORGE_SCENE := "res://scenes/ui/production/RestForge.tscn"

var _captures: Array[Dictionary] = [
	{
		"name": "desktop_main_menu",
		"size": Vector2i(1280, 720),
		"state": "main_menu",
	},
	{
		"name": "compact_main_menu",
		"size": Vector2i(960, 540),
		"state": "main_menu",
	},
	{
		"name": "desktop_character_select",
		"size": Vector2i(1280, 720),
		"state": "character_select",
	},
	{
		"name": "compact_character_select",
		"size": Vector2i(960, 540),
		"state": "character_select",
	},
	{
		"name": "desktop_mastery",
		"size": Vector2i(1280, 720),
		"state": "mastery",
	},
	{
		"name": "compact_mastery",
		"size": Vector2i(960, 540),
		"state": "mastery",
	},
	{
		"name": "desktop_production_stage",
		"size": Vector2i(1280, 720),
		"state": "production_stage",
	},
	{
		"name": "compact_production_stage",
		"size": Vector2i(960, 540),
		"state": "production_stage",
	},
	{
		"name": "desktop_charge_lane",
		"size": Vector2i(1280, 720),
		"state": "production_charge_lane",
	},
	{
		"name": "compact_charge_lane",
		"size": Vector2i(960, 540),
		"state": "production_charge_lane",
	},
	{
		"name": "desktop_level_reward",
		"size": Vector2i(1280, 720),
		"state": "level_reward",
	},
	{
		"name": "compact_level_reward",
		"size": Vector2i(960, 540),
		"state": "level_reward",
	},
	{
		"name": "desktop_card_reward",
		"size": Vector2i(1280, 720),
		"state": "card_reward",
	},
	{
		"name": "compact_card_reward",
		"size": Vector2i(960, 540),
		"state": "card_reward",
	},
	{
		"name": "desktop_rest_forge",
		"size": Vector2i(1280, 720),
		"state": "rest_forge",
	},
	{
		"name": "compact_rest_forge",
		"size": Vector2i(960, 540),
		"state": "rest_forge",
	},
	{
		"name": "desktop_flooded_rope",
		"size": Vector2i(1280, 720),
		"state": "flooded_rope",
	},
	{
		"name": "compact_flooded_hazard",
		"size": Vector2i(960, 540),
		"state": "flooded_hazard",
	},
	{
		"name": "desktop_flooded_safe",
		"size": Vector2i(1280, 720),
		"state": "flooded_safe",
	},
	{
		"name": "desktop_run_result",
		"size": Vector2i(1280, 720),
		"state": "run_result",
	},
	{
		"name": "compact_run_result",
		"size": Vector2i(960, 540),
		"state": "run_result",
	},
	{
		"name": "compact_settings_popup",
		"size": Vector2i(960, 540),
		"state": "settings",
	},
]
var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var capture_filter := OS.get_environment("CAPTURE_NAME")
	for capture in _captures:
		if not capture_filter.is_empty() and capture_filter != String(capture["name"]):
			continue
		await _capture(capture)
	quit(1 if _failed else 0)


func _capture(capture: Dictionary) -> void:
	root.size = capture["size"]
	DisplayServer.window_set_size(capture["size"])
	await process_frame
	await process_frame

	var main_scene := load(MAIN_SCENE) as PackedScene
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	for _frame in 4:
		await process_frame

	var game := root.get_node_or_null("Game")
	var run_director := root.get_node_or_null("RunDirector")
	var run_state := root.get_node_or_null("RunState")
	var profile_state := root.get_node_or_null("ProfileState")
	if game == null or run_director == null or run_state == null or profile_state == null:
		push_error("Production autoloads are unavailable; cannot capture UI state.")
		_failed = true
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)

	match String(capture["state"]):
		"character_select":
			run_director.show_character_select()
		"mastery":
			run_director.show_character_select()
			await process_frame
			if run_director.current_screen != null:
				run_director.current_screen.call("_toggle_mode")
		"production_stage":
			run_director.start_production_run(0)
		"production_charge_lane":
			run_director.start_production_run(0)
			await process_frame
			var stage: Variant = game.current_stage
			if stage != null and stage.player != null:
				stage.player.global_position = Vector2(1800.0, 600.0)
				if stage.player.camera != null:
					stage.player.camera.reset_smoothing()
		"level_reward":
			run_director.start_production_run(0)
			RewardService.apply(
				RewardTransaction.new(&"capture_level_reward", &"fixture", {"xp": 20}),
				run_state
			)
			game.unload_current_stage()
			run_director.call("_clear_hud")
			run_director.call("_show_level_reward")
		"card_reward":
			run_director.start_production_run(0)
			RewardService.apply(
				RewardTransaction.new(&"capture_card_reward", &"fixture", {"coin": 20}),
				run_state
			)
			game.unload_current_stage()
			run_director.call("_clear_hud")
			run_director.call("_show_card_reward")
		"rest_forge":
			run_director.start_production_run(0)
			RewardService.apply(
				RewardTransaction.new(&"capture_rest_forge", &"fixture", {"coin": 60}),
				run_state
			)
			run_state.damage_player(2)
			run_state.begin_rest_forge()
			var snapshot: Dictionary = run_state.get_rest_forge_snapshot()
			var items: Array = snapshot.get("items", [])
			if not items.is_empty():
				run_state.begin_forge_offer(StringName(items[0]["id"]))
				snapshot = run_state.get_rest_forge_snapshot()
			game.unload_current_stage()
			run_director.call("_clear_hud")
			var rest_forge := run_director.call("_show_screen", REST_FORGE_SCENE) as Control
			if rest_forge != null:
				rest_forge.call("configure", snapshot)
		"flooded_rope", "flooded_hazard", "flooded_safe":
			await _load_flooded_capture(
				String(capture["state"]),
				run_director,
				game,
				run_state
			)
		"run_result":
			run_director.start_production_run(1)
			run_director.show_run_result(true)
		"settings":
			game.set_settings_open(true)
	for _frame in 4:
		await process_frame

	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Viewport texture is unavailable for %s" % capture["name"])
		_failed = true
		return

	var image := viewport_texture.get_image()
	if image == null:
		push_error("Viewport image is unavailable for %s" % capture["name"])
		_failed = true
		return

	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("Unable to save %s (error %d)" % [output_path, save_error])
		_failed = true

	game.set_settings_open(false)
	game.unload_current_stage()
	main_instance.queue_free()
	await process_frame


func _load_flooded_capture(
	state: String,
	run_director: Node,
	game: Node,
	run_state: Node
) -> void:
	run_director.start_production_run(0)
	await process_frame
	game.unload_current_stage()
	run_state.current_stage_index = 1
	var stage: Variant = game.load_stage(PRODUCTION_STAGE)
	await process_frame
	await physics_frame
	if stage == null or not stage.is_setup_complete():
		push_error("Flooded stage is unavailable for %s." % state)
		_failed = true
		return
	var target_host: RoomTemplateHost
	var local_position := Vector2(640.0, 560.0)
	match state:
		"flooded_rope":
			target_host = stage.get_room_host(&"fw_rope_shaft")
			local_position = Vector2(640.0, 680.0)
		"flooded_hazard":
			for room in stage.get_stage_plan().get_rooms():
				if room.role == &"hazard":
					target_host = stage.get_room_host(room.id)
					break
		"flooded_safe":
			for room in stage.get_stage_plan().get_rooms():
				if room.role == &"safe":
					target_host = stage.get_room_host(room.id)
					break
	if target_host == null:
		push_error("Flooded capture target is unavailable for %s." % state)
		_failed = true
		return
	stage.player.global_position = target_host.global_position + local_position
	if stage.player.camera != null:
		stage.player.camera.reset_smoothing()
