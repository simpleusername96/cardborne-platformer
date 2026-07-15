extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/shell"
const MAIN_SCENE := "res://scenes/main/Main.tscn"
const RUN_RESULT_SCENE := "res://scenes/ui/production/RunResult.tscn"
const SETTLE_FRAMES := 10
const DRAW_PASSES := 3
const CLEANUP_FRAMES := 4
const VIEWPORTS: Array[Dictionary] = [
	{"prefix": "compact", "size": Vector2i(960, 540)},
	{"prefix": "desktop", "size": Vector2i(1280, 720)},
	{"prefix": "hd", "size": Vector2i(1920, 1080)},
]
const STATE_SUFFIXES: Array[String] = [
	"main_menu",
	"victory",
	"defeat",
	"pause",
	"pause_settings",
	"abandon",
	"settings",
	"remap",
]

var _failed := false
var _requested := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_requested = OS.get_environment("SHELL_UI_CAPTURE").strip_edges()
	if not _requested.is_empty() and not _is_known_capture(_requested):
		push_error("Unknown shell UI capture: %s" % _requested)
		quit(1)
		return
	for viewport in VIEWPORTS:
		var prefix := String(viewport["prefix"])
		if not _requested.is_empty() and not _requested.begins_with("%s_" % prefix):
			continue
		await _capture_viewport(prefix, viewport["size"] as Vector2i)
	if not _failed:
		print("SHELL_UI_CAPTURE_OK target=%s" % (_requested if not _requested.is_empty() else "all"))
	quit(1 if _failed else 0)


func _capture_viewport(prefix: String, viewport_size: Vector2i) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	await _wait_frames(2)
	var context := await _mount_main()
	if context.is_empty():
		return
	var main := context["main"] as Node
	var game := context["game"] as Node
	var run_director := context["run_director"] as Node
	var profile_state := context["profile_state"] as Node
	profile_state.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)

	await _save_current("%s_main_menu" % prefix)

	game.call("unload_current_stage")
	run_director.call("_clear_hud")
	var result := run_director.call("_show_screen", RUN_RESULT_SCENE) as Control
	if result == null:
		push_error("Run result scene failed to mount for capture.")
		_failed = true
		await _cleanup(main, game)
		return
	result.call("configure", true, "Traveler", _result_settlement(true))
	await _save_current("%s_victory" % prefix)
	result.call("configure", false, "Traveler", _result_settlement(false))
	await _save_current("%s_defeat" % prefix)

	run_director.call("show_main_menu")
	await _wait_frames(4)
	if not bool(run_director.call("start_production_run", 0)):
		push_error("Production stage failed to start for pause capture.")
		_failed = true
		await _cleanup(main, game)
		return
	await process_frame
	await physics_frame
	game.call("set_pause_menu_open", true)
	await _save_current("%s_pause" % prefix)
	game.call("set_settings_open", true)
	await _save_current("%s_pause_settings" % prefix)
	game.call("set_settings_open", false)
	await _wait_frames(2)
	var pause_menu := main.get_node_or_null("UILayer/PauseMenu") as Control
	if pause_menu == null:
		push_error("Pause menu is unavailable for abandon capture.")
		_failed = true
	else:
		pause_menu.call("_show_confirmation")
		await _save_current("%s_abandon" % prefix)

	game.call("close_overlays")
	run_director.call("show_main_menu")
	await _wait_frames(4)
	game.call("set_settings_open", true)
	await _save_current("%s_settings" % prefix)
	var settings := main.get_node_or_null("UILayer/SettingsPopup") as Control
	if settings == null:
		push_error("Settings popup is unavailable for remap capture.")
		_failed = true
	else:
		settings.call("_begin_capture", "jump", "Jump")
		await _save_current("%s_remap" % prefix)

	await _cleanup(main, game)


func _mount_main() -> Dictionary:
	var main_packed := load(MAIN_SCENE) as PackedScene
	var main := main_packed.instantiate() if main_packed != null else null
	if main == null:
		push_error("Main scene is unavailable for shell UI capture.")
		_failed = true
		return {}
	root.add_child(main)
	await _wait_frames(5)
	var game := root.get_node_or_null("Game")
	var run_director := root.get_node_or_null("RunDirector")
	var profile_state := root.get_node_or_null("ProfileState")
	if game == null or run_director == null or profile_state == null:
		push_error("Shell UI capture requires production autoloads.")
		_failed = true
		main.queue_free()
		return {}
	return {
		"main": main,
		"game": game,
		"run_director": run_director,
		"profile_state": profile_state,
	}


func _save_current(capture_name: String) -> void:
	await _wait_frames(SETTLE_FRAMES)
	await _flush_render_frames()
	if not _requested.is_empty() and _requested != capture_name:
		return
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture_name]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save shell UI capture: %s" % output_path)
		_failed = true


func _flush_render_frames() -> void:
	for _draw_pass in DRAW_PASSES:
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		await process_frame


func _cleanup(main: Node, game: Node) -> void:
	game.call("close_overlays")
	game.call("unload_current_stage")
	main.queue_free()
	await _wait_frames(CLEANUP_FRAMES)
	RenderingServer.force_draw(false)


func _is_known_capture(capture_name: String) -> bool:
	for viewport in VIEWPORTS:
		var prefix := String(viewport["prefix"])
		for suffix in STATE_SUFFIXES:
			if capture_name == "%s_%s" % [prefix, suffix]:
				return true
	return false


func _result_settlement(victory: bool) -> Dictionary:
	return {
		"victory": victory,
		"terminal_reason": "boss_defeated" if victory else "run_abandoned",
		"seed": 73021,
		"stage_reached": 3 if victory else 2,
		"boss_reached": victory,
		"duration_seconds": 845.0 if victory else 392.0,
		"profile": {"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true)},
		"run_build": {
			"level": 6 if victory else 3,
			"cards": {
				"dash_wake": 2,
				"perfect_punish": 1,
			},
		},
		"persistent_material_delta": {
			"sky_thread": 4,
			"slime_residue": 8,
			"boss_core": 1 if victory else 0,
		},
	}


func _wait_frames(count: int) -> void:
	for _frame in count:
		await process_frame
