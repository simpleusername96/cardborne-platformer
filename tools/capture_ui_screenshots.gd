extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux"
const MAIN_SCENE := "res://scenes/main/Main.tscn"

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
	for capture in _captures:
		await _capture(capture)
	quit(1 if _failed else 0)


func _capture(capture: Dictionary) -> void:
	root.size = capture["size"]
	DisplayServer.window_set_size(capture["size"])

	var main_scene := load(MAIN_SCENE) as PackedScene
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame

	var game := root.get_node_or_null("Game")
	var run_director := root.get_node_or_null("RunDirector")
	if game == null or run_director == null:
		push_error("Production autoloads are unavailable; cannot capture UI state.")
		_failed = true
		return

	match String(capture["state"]):
		"character_select":
			run_director.show_character_select()
		"production_stage":
			run_director.start_production_run(0)
		"run_result":
			run_director.start_production_run(1)
			run_director.show_run_result(true)
		"settings":
			game.set_settings_open(true)
	await process_frame
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
