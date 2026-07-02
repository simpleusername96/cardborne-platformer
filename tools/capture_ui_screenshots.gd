extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux"
const MAIN_SCENE := "res://scenes/main/Main.tscn"

var _captures: Array[Dictionary] = [
	{
		"name": "desktop_stage_hud",
		"size": Vector2i(1280, 720),
		"settings_open": false,
	},
	{
		"name": "narrow_stage_hud",
		"size": Vector2i(390, 720),
		"settings_open": false,
	},
	{
		"name": "narrow_settings_popup",
		"size": Vector2i(390, 720),
		"settings_open": true,
	},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for capture in _captures:
		await _capture(capture)
	quit()


func _capture(capture: Dictionary) -> void:
	root.size = capture["size"]
	DisplayServer.window_set_size(capture["size"])

	var main_scene := load(MAIN_SCENE) as PackedScene
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame

	var game := root.get_node_or_null("/root/Game")
	if game == null:
		push_error("Game autoload is unavailable; cannot capture UI state.")
		return

	if bool(capture["settings_open"]):
		game.set_settings_open(true)
		await process_frame
		await process_frame

	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("Viewport texture is unavailable for %s" % capture["name"])
		return

	var image := viewport_texture.get_image()
	if image == null:
		push_error("Viewport image is unavailable for %s" % capture["name"])
		return

	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	image.save_png(output_path)

	game.set_settings_open(false)
	main_instance.queue_free()
	await process_frame
