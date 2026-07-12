extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/boss"
const STAGE_SCENE := "res://scenes/stages/boss/SlimeCourt.tscn"
const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const INTRO_DURATION := 0.90

const CAPTURES := [
	{
		"name": "desktop_jump_startup",
		"size": Vector2i(1280, 720),
		"pattern": &"jump_slam",
		"elapsed": 0.42,
	},
	{
		"name": "compact_poison_active",
		"size": Vector2i(960, 540),
		"pattern": &"poison_bands",
		"elapsed": 1.18,
	},
	{
		"name": "hd_summon_startup",
		"size": Vector2i(1920, 1080),
		"pattern": &"small_slime_summon",
		"elapsed": 0.38,
	},
]

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var capture_filter := OS.get_environment("CAPTURE_NAME")
	for capture in CAPTURES:
		if not capture_filter.is_empty() and capture_filter != String(capture["name"]):
			continue
		await _capture(capture)
	quit(1 if _failed else 0)


func _capture(capture: Dictionary) -> void:
	root.size = capture["size"]
	DisplayServer.window_set_size(capture["size"])
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	if profile_state == null or run_state == null:
		push_error("Boss capture requires production state autoloads.")
		_failed = true
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	run_state.start_new_run(0, 73021)
	run_state.set("current_stage_index", 3)

	var hud_layer := CanvasLayer.new()
	root.add_child(hud_layer)
	var hud := (load(HUD_SCENE) as PackedScene).instantiate()
	hud_layer.add_child(hud)
	var stage := (load(STAGE_SCENE) as PackedScene).instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_manual_simulation(true)
	stage.advance_runtime(INTRO_DURATION)
	var boss: Variant = stage.get_boss()
	boss.set_scheduler_enabled(false)
	boss.execute_pattern(capture["pattern"], 2)
	stage.advance_runtime(float(capture["elapsed"]))
	for _frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save boss capture: %s" % output_path)
		_failed = true

	stage.queue_free()
	hud_layer.queue_free()
	await process_frame
